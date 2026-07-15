# Plan File 03-05 — Design Constraints (SRS §3.5)
Project: APTIS LMS  
Date: 2026-06-16

Design constraints are non-negotiable restrictions on how the system must be built, imposed by technology decisions, compliance requirements, or stakeholder mandates — not feature preferences.

---

## DC-01: Flutter as Mandated Client Framework

**Constraint:** All client-facing applications (Vendor Portal, Tenant Portal, Exam Client) must be implemented using Flutter (Dart). No alternative frontend framework is permitted for client UIs.

**Imposed by:** Stakeholder decision (cross-platform deployment goal)

**Implications:**
- Backend API must be designed as a pure REST (+ WebSocket) API; no server-rendered HTML
- UI components and business logic must be Dart; no React, Vue, or Angular components
- Platform targets (Web, Desktop Windows/macOS, Mobile iOS/Android) are all achievable from a single Flutter codebase with platform-specific adaptations
- Third-party Flutter packages must be evaluated for compatibility with all target platforms (a package that works on Web may not work on Desktop or vice versa)
- Kiosk mode implementation (FR-95, FR-102) must use Flutter Desktop window management APIs

---

## DC-02: Multi-tenant Subdomain Architecture (Mandated)

**Constraint:** Tenant isolation must be implemented via subdomain routing. Each tenant receives a unique subdomain `{slug}.aptis-lms.vn`. The system must resolve `tenant_id` from the subdomain at the API layer and apply it to all data operations.

**Imposed by:** Stakeholder decision (branding and isolation requirements)

**Implications:**
- Backend must validate `tenant_id` on every request — no request may bypass tenant scoping
- A wildcard SSL certificate (`*.aptis-lms.vn`) is required
- DNS must be configured with wildcard CNAME to the load balancer
- Vendor Portal operates on a separate domain (`admin.aptis-lms.vn`) with no tenant scoping
- Cross-tenant data access is a security violation and must be enforced at both application and database layer

---

## DC-03: HTTPS-Only Communication

**Constraint:** No HTTP (unencrypted) endpoints may be exposed. All client-to-server and server-to-external-service communication must use HTTPS (TLS 1.2 minimum, TLS 1.3 preferred).

**Imposed by:** Security baseline (spec §5.6)

**Implications:**
- All API endpoints return HTTPS URLs only; HTTP requests are redirected to HTTPS
- Audio/image CDN delivery uses HTTPS (CDN must support HTTPS)
- Presigned URLs for Cloud Storage are HTTPS
- No mixed-content warnings permitted in web client

---

## DC-04: Server-authoritative Exam Timer (Mandated)

**Constraint:** Exam timers must be computed and stored on the server. Client-side timer display is derived from server-provided values. The client cannot extend, reset, or pause the server timer under any circumstances.

**Imposed by:** Exam integrity requirement (BR-02, FR-104)

**Implications:**
- API must expose a timer-sync endpoint that returns `time_remaining` per part
- Client polling interval: ≤ 10 seconds (or server-push via WebSocket)
- The server closes parts when time_remaining ≤ 0 regardless of client state
- Any answer submitted after server-side part close returns HTTP 409 (Conflict)
- Backend must never trust client-provided timestamps for exam timing

---

## DC-05: Per-answer Server-side Persistence (Mandated)

**Constraint:** Every student answer must be written to the server database before the student is considered to have "answered" a question. There is no single "submit exam" data transfer at the end. Finalization is metadata only.

**Imposed by:** Exam continuity NFR-X (stakeholder's #1 priority), FR-105

**Implications:**
- The exam state API endpoint must support high-frequency upsert operations (potentially hundreds of concurrent students each submitting every 5–30 seconds)
- Database schema must support upsert-on-conflict for exam_state (attempt_id, question_id) as the key
- The exam submission endpoint (FR-26) only writes attempt.status=submitted and triggers the scoring pipeline; it does not transmit answer data
- Write latency for the per-answer endpoint is a critical NFR (NFR-06)

---

## DC-06: AI Scoring via Third-party API Only (No Custom ML Training)

**Constraint:** AI scoring (STT + LLM evaluation) must use commercially available third-party APIs. Training custom machine learning models is out of scope.

**Imposed by:** Cost and timeline constraints (spec §5.5)

**Implications:**
- API provider selection determines: accuracy, language support, pricing model, rate limits, latency
- System must implement: retry logic, fallback behavior on API failure, async queue (scoring is not synchronous with exam submission)
- Prompt engineering for APTIS rubric evaluation is a required deliverable (not in this SRS, but must be planned for)
- Provider change must be possible without schema changes (scoring job reads from a configuration table for which provider to call)

---

## DC-07: No Payment Processing In-system

**Constraint:** The system must not implement any payment gateway, invoice management, or billing automation. License creation and renewal are manual operations performed by the Sales Team.

**Imposed by:** Business decision (stakeholder confirmed)

**Implications:**
- No Stripe, VNPay, MoMo, or any payment SDK in the system
- License records are created manually via the Sales Portal (FR-78)
- No PCI-DSS compliance requirements (no payment card data)
- The system tracks license validity only (seat_count and expiry_date); it does not know about payment status

---

## DC-08: Cloud Hosting (No On-premise for v1)

**Constraint:** All system components (backend API, database, Cloud Storage, AI scoring queue) must be deployed on a managed cloud platform (AWS, GCP, or Azure). On-premise deployment is not supported in v1.

**Imposed by:** Stakeholder decision (spec §5.4)

**Implications:**
- Infrastructure as Code must target a cloud provider's managed services (RDS/Cloud SQL, S3/GCS, managed container orchestration)
- Multi-region deployment is optional for v1 but cloud architecture must not preclude it
- Data residency: if NĐ 13/2023/NĐ-CP requires data localization, the cloud region must include Vietnam or an approved alternative [TBD — OI-07]

---

## DC-09: RBAC Must Support Multi-role per User (Tenant Side)

**Constraint:** The permission system for Tenant-side users must support assigning multiple roles to a single user simultaneously. Effective permissions = union of all assigned roles.

**Imposed by:** Stakeholder requirement (spec BR-01; real-world scenario: Teacher also acts as Exam Coordinator or Giám thị)

**Implications:**
- Permission checks must query user_roles (all active roles) and compute union; no single-role assumption
- UI must render appropriate controls based on the union of permissions
- Tenant Admin can assign/revoke individual roles without affecting other roles the user holds
- Audit logging must attribute actions to both the user_id and the active role at the time of action

---

## DC-10: Immutable Anti-cheat and Audit Logs

**Constraint:** The following tables must be immutable at application level (no UPDATE or DELETE by application roles): `violation_events`, `exam_events`, `impersonation_log`, `license` history.

**Imposed by:** Audit and academic integrity requirements (FR-101, §3.6 Security)

**Implications:**
- Application database user must not have DELETE permission on these tables
- Data retention purge for violation_events must be initiated by a privileged system process (not application-layer DELETE), or implemented as archiving to cold storage
- Audit trails cannot be modified to cover up interventions

---

## DC-11: Disclaimer Requirement — Non-official Test

**Constraint:** The system UI must display a clear disclaimer on all result screens and the trial landing page stating that APTIS LMS is a practice/simulation platform and not an official APTIS test administered by British Council.

**Imposed by:** Legal/compliance (spec §5.7 — not a British Council partner)

**Implications:**
- Disclaimer text must be visible and not dismissible on result screens
- Trial landing page must include the disclaimer prominently (before the user starts)
- Marketing materials (outside this SRS scope) must also not claim official affiliation

---

## DC-12: Password Never Stored in Plaintext

**Constraint:** User passwords must never be stored in plaintext anywhere in the system — database, logs, exports, or backups.

**Imposed by:** Security baseline (NFR-12, spec §5.6)

**Implications:**
- Bulk account export (FR-48) must generate and transmit passwords at creation time only — the bcrypt hash stored in DB cannot be reversed; the export file is the only time the plaintext appears and must be generated at creation time, not retrieved later
- Backup encryption must be enabled for database backups
- Logging middleware must strip password fields from request logs
