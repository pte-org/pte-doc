# SRS §3.5 — Design Constraints
## APTIS LMS
**Version:** 1.0 | **Date:** 2026-06-16 | **Status:** DRAFT

---

Design constraints are non-negotiable restrictions on how the system must be designed and built. They are imposed by technology mandates, security requirements, legal obligations, or stakeholder decisions — not by feature preferences. Violating a design constraint is not a trade-off; it is an out-of-compliance implementation.

---

### DC-01: Flutter as Mandated Client Framework

**Amended by ADR-006 (2026-06-23, `projects/aptis-mvp/team/techlead/ADR-006.md`):** this constraint now applies to the **Exam Client only**. Vendor Portal and Tenant Portal are built in Next.js (React), not Flutter. Read ADR-006 before implementing any portal UI.

The system shall implement all client-facing applications — Vendor Portal, Tenant Portal, and Exam Client — exclusively in Flutter (Dart). No alternative frontend framework (React, Vue, Angular, etc.) is permitted for any client UI component.

**Imposed by:** Stakeholder mandate — cross-platform deployment goal (Web, Desktop, Mobile from single codebase).

**Implications for implementation:**
- The Backend API must be a pure REST and WebSocket API; no server-rendered HTML is produced
- All UI components, navigation logic, and client-side business rules must be written in Dart
- Platform-specific behavior (kiosk mode, microphone API, fullscreen control, local file system) must be implemented via Flutter platform channels or approved Flutter packages, with the platform-specific adapter isolated from shared business logic (SA-PRT-01)
- All selected Flutter packages must be evaluated for compatibility with each target platform (a package supporting Flutter Web may not support Flutter Desktop or Mobile); incompatible packages require platform-conditional alternatives

---

### DC-02: Multi-tenant Subdomain Architecture

The system shall implement tenant isolation via subdomain routing. Each tenant is assigned a unique subdomain `{slug}.aptis-lms.vn`. The API gateway must resolve `tenant_id` from the `Host` header subdomain on every incoming request and scope all data operations to that tenant's namespace. Cross-tenant data access is structurally prohibited.

**Imposed by:** Stakeholder mandate — tenant isolation and branding requirements.

**Implications for implementation:**
- A wildcard SSL certificate covering `*.aptis-lms.vn` and `aptis-lms.vn` is required
- DNS must be configured with a wildcard CNAME pointing `*.aptis-lms.vn` to the load balancer
- The API gateway middleware resolves `slug → tenant_id` on every request before routing to any handler; no handler may bypass this resolution
- Every database query must include a `WHERE tenant_id = {resolved_id}` constraint (or row-level security equivalent); any query that omits tenant scoping is a Critical security defect
- The Vendor Portal operates on `admin.aptis-lms.vn` with no tenant scoping; its handlers must not accept a `tenant_id` from the request context

---

### DC-03: HTTPS-Only Communication

The system shall not expose or use any unencrypted HTTP endpoints. All client-to-server communication, server-to-external-service calls (SI-01 through SI-06), and CDN delivery must use HTTPS with TLS 1.2 as the minimum protocol version and TLS 1.3 preferred.

**Imposed by:** Security baseline.

**Implications for implementation:**
- HTTP requests to the platform are permanently redirected (HTTP 301) to the HTTPS equivalent
- Audio and image CDN delivery URLs use HTTPS; no mixed-content warnings are permitted in Flutter Web
- Presigned URLs for Cloud Storage (SI-01) are HTTPS URLs
- TLS certificate configuration must enforce the minimum version and disable deprecated cipher suites

---

### DC-04: Server-authoritative Exam Timer

Exam part timers must be computed and stored exclusively on the server. The client displays a countdown derived from server-provided values. The client cannot extend, reset, pause, or manipulate the server-side timer under any circumstances.

**Imposed by:** Exam integrity requirement — prevents client-side timer manipulation.

**Implications for implementation:**
- A timer-sync API endpoint returns `time_remaining` computed as `part_duration_seconds + extended_by_seconds − (CURRENT_TIMESTAMP − part_timers.started_at)`
- The client polls this endpoint every ≤ 10 seconds (or receives server-push via WebSocket); client-side countdown is a visual interpolation between syncs, not the authoritative value
- When the server determines `time_remaining ≤ 0`, the server closes the part and sets `part_timers.completed_at`; client state is irrelevant to this transition
- Any answer submission for a closed part returns HTTP 409 Conflict regardless of what the client displays
- The Backend must never use client-provided timestamps for timer computation

---

### DC-05: Per-answer Server-side Persistence

Every student answer must be written to the server database and acknowledged before it is considered saved. There is no deferred batch transmission at exam end. The exam submission endpoint finalizes metadata only; it does not transfer student answer data.

**Imposed by:** Exam continuity mandate — stakeholder's #1 priority (NFR-14).

**Implications for implementation:**
- The exam state write endpoint (`PATCH /api/v1/exam/attempts/{id}/answers`) must support high-frequency upsert operations; the `exam_state` table uses `(attempt_id, question_id)` as a composite upsert key
- Database write throughput for `exam_state` is a critical scaling concern (NFR-06); write-through caching or batching with acknowledgment semantics may be required at scale
- The exam submission endpoint (`POST /api/v1/exam/attempts/{id}/submit`) sets `attempt.status = submitted` and triggers the scoring pipeline; it does not accept answer data in the request body
- The client must handle write failures with retry logic (up to 3 retries, FR-105) and buffer unacknowledged answers in memory

---

### DC-06: AI Scoring via Third-party APIs Only

AI-based evaluation of Writing and Speaking responses must use commercially available third-party APIs (STT for transcription, LLM for rubric-based scoring). Training, fine-tuning, or hosting custom machine learning models is out of scope for v1.

**Imposed by:** Cost and timeline constraints — custom model training requires data labeling, infrastructure, and ML expertise beyond v1 scope.

**Implications for implementation:**
- The AI scoring pipeline is a configurable adapter; the specific STT provider (OI-02) and LLM provider (OI-02) are read from a system configuration table at runtime
- Switching between providers requires only a configuration change, not a code change or redeployment (SA-MNT-02)
- APTIS rubric prompts for each skill and part are a required implementation deliverable outside this SRS; prompt quality directly determines scoring accuracy
- The pipeline must implement retry logic (FR-30, FR-31) and graceful degradation (flag for manual review on permanent API failure)

---

### DC-07: No Payment Processing In-system

The system must not implement any payment gateway integration, invoice management, subscription billing, or payment card data handling. License creation and renewal are manual operations performed by Sales Team members via the Sales Portal.

**Imposed by:** Business decision — payment is handled by contract outside the platform.

**Implications for implementation:**
- No Stripe, VNPay, MoMo, PayPal, or any payment SDK is included in any system component
- No payment card numbers, bank account numbers, or payment credentials are stored or transmitted
- PCI-DSS compliance is not required and must not be cited as a constraint
- The system tracks only license validity (`seat_count` and `expiry_date`); it has no knowledge of whether the Vendor has been paid

---

### DC-08: Cloud Hosting Only (No On-premise for v1)

All system components — Backend API, relational database, job queue, Cloud Storage, and observability tooling — must be deployed on managed cloud infrastructure (AWS, GCP, or Azure). On-premise deployment is not supported in v1.

**Imposed by:** Stakeholder decision.

**Implications for implementation:**
- Infrastructure as Code must target managed cloud services (e.g., RDS/Cloud SQL, S3/GCS, managed container orchestration, managed queue)
- The cloud architecture must not preclude future multi-region deployment (even if v1 is single-region)
- If NĐ 13/2023/NĐ-CP (OI-07) requires data localization in Vietnam, the deployment region must include Vietnam or a legally equivalent alternative; the cloud provider must be selected before architecture is finalized

---

### DC-09: RBAC Must Support Multi-role Assignment (Tenant Side)

The permission system for Tenant-side users must support assigning multiple roles simultaneously to a single user. Effective permissions are the union of all currently assigned roles' permission sets. The system must never assume a Tenant user holds only one role.

**Imposed by:** Stakeholder requirement — real-world scenario: a Teacher who also serves as Exam Coordinator (Giám thị) must hold both roles.

**Implications for implementation:**
- Permission checks query `user_roles` for all active (non-revoked) rows for the requesting user and compute the permission union
- No API handler may assume a user has exactly one role; single-role assumptions in authorization middleware are a logic defect
- UI renders the union of all role-based controls; a Teacher+Coordinator sees both Teacher menus and Coordinator menus
- Audit log entries must record `user_id` and the role under which the action was taken (or all active roles, per TechLead decision — OI-05 adjacent)

---

### DC-10: Immutable Audit and Integrity Logs

The following tables must be immutable at the application layer: `violation_events`, `exam_events`, `impersonation_log`, and license history records. No application role may issue `DELETE` or `UPDATE` statements against these tables via the Backend API.

**Imposed by:** Academic integrity and audit requirements.

**Implications for implementation:**
- The database application user account must not have `DELETE` or `UPDATE` privileges on these tables
- Data retention purge for `violation_events` must be executed by a dedicated privileged system job (not an ad-hoc API call) and only when records exceed the retention period (OI-07)
- Archiving to cold storage (rather than deletion) is an acceptable alternative to satisfy retention policy while preserving the integrity audit trail

---

### DC-11: Disclaimer on All Result Screens

The system must display a clear, non-dismissible disclaimer on every result screen, trial result page, and trial landing page stating that APTIS LMS is a practice simulation platform and is not affiliated with, authorized by, or endorsed by British Council, and that results are approximations for learning purposes and do not constitute official APTIS scores.

**Imposed by:** Legal protection — APTIS LMS is not a British Council authorized test center.

**Required disclaimer text (Vietnamese):** "Đây là bài thi thử mô phỏng. Điểm số và band ước tính từ hệ thống này chỉ mang tính chất tham khảo và không phải là kết quả APTIS chính thức của British Council."

**Implications for implementation:**
- The disclaimer must be rendered as part of the page content, not as a cookie banner or modal that can be dismissed permanently
- The disclaimer must appear on: student attempt results screen (FR-34), trial result display (FR-90), and trial landing page (FR-88)
- Marketing materials (outside SRS scope) must also not imply official British Council affiliation

---

### DC-12: Password Never Stored in Plaintext

User passwords must never be stored, logged, exported, cached, or transmitted in plaintext. The only permitted storage form is a bcrypt hash with cost factor ≥ 12 (NFR-12).

**Imposed by:** Security baseline.

**Implications for implementation:**
- The bulk credential export (FR-48) generates the plaintext password at account creation time, transmits it once to the requesting client, and stores only the bcrypt hash in the database; the plaintext is not stored anywhere
- Database backups must be encrypted; the encryption key must be stored separately from the backup
- Application logging middleware must strip any field named `password`, `password_hash`, `plaintext_password`, or equivalent from request and response logs before writing
- Password reset (FR-05) issues a time-limited token, not the existing password; the existing hash is never reversed
