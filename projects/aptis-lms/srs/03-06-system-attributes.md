# SRS §3.6 — System Attributes
## APTIS LMS
**Version:** 1.0 | **Date:** 2026-06-16 | **Status:** DRAFT

---

System attributes describe quality properties the system must exhibit beyond functional correctness. They define how the system behaves under stress, failure, attack, and change over time.

---

## 3.6.1 Reliability

**SA-REL-01: Exam Session Data Integrity**

The system shall not lose any student exam answer that has been acknowledged by the server (HTTP 200 returned to the client). This is the #1 reliability requirement of the entire system.

This property is achieved through the composite behavior of the F-13 cluster (FR-104 through FR-111): per-answer server-side persistence (FR-105), server-authoritative timer (FR-104), Speaking audio local buffer with retry (FR-108), resume on reconnect (FR-106), and crash recovery (FR-111). No single component failure shall result in a student losing submitted answers.

**Acceptance:** Post-session audit shows zero instances of an attempt where `exam_answers` record count is less than the number of answers the student's client reported submitting.

---

**SA-REL-02: AI Scoring Pipeline Fault Tolerance**

The AI scoring pipeline (STT transcription FR-30 + LLM draft scoring FR-31) shall be fault-tolerant with respect to third-party API failures. A failed AI API call shall not produce a silently incorrect score, corrupt an attempt record, or block the pipeline for other attempts.

Behavior on failure:
- STT failure: retry up to 3 times with exponential backoff; on permanent failure set `stt_status = failed` and alert the Teacher
- LLM failure: same retry and flag behavior; set `llm_status = failed`
- Any AI failure result: the Teacher's review queue displays the failure clearly; the Teacher reviews the raw audio or text directly

The pipeline must process each attempt independently; a failure for one student must not delay or block scoring for other students.

---

**SA-REL-03: Notification System Non-blocking**

The notification subsystem (F-10) shall operate independently of exam delivery. A failure in the email provider (SI-02) or a backlog of notification jobs must not affect the responsiveness of exam state writes (FR-105) or the live monitor (FR-39).

Failed notifications are retried once after 5 minutes (FR-83) and then logged as failed. Batch notification failures must not cascade; individual send failures are isolated.

---

**SA-REL-04: No Single Point of Failure During Exam Hours**

The exam delivery path (Backend API + database + WebSocket/SSE server) must not be designed with a single point of failure. During any active exam session, at least one replica of each component must be available to serve requests.

Required design considerations (to be confirmed by TechLead during architecture session):
- Database: read replica + automated failover for primary
- Backend API: minimum 2 instances behind a load balancer
- WebSocket server: session affinity or shared session state (Redis) to survive instance failure
- Health checks: load balancer removes unhealthy instances within 30 seconds

---

## 3.6.2 Availability

**SA-AVL-01: Exam Hour Availability Target**

The system shall achieve ≥ 99.9% availability during any window where at least one exam session is in progress (NFR-03). This translates to ≤ 43 seconds of downtime per exam session.

Planned maintenance must be scheduled outside exam hours. If an emergency deployment is required during an active session, the TechLead must authorize it with full awareness of the exam continuity risk.

---

**SA-AVL-02: Graceful Degradation for Non-critical Services**

If any of the following non-critical services become unavailable, the core exam delivery service must continue operating without interruption:
- Email notification service (SI-02): exam delivery continues; emails are queued and sent on recovery
- AI scoring pipeline (SI-04, SI-05): exam delivery continues; scoring is queued and processed on recovery
- Analytics reporting queries: exam delivery continues; analytics are stale but available once the reporting service recovers
- Impersonation / Support Staff features: unavailability does not affect student or teacher exam workflows

Core exam delivery (FR-17 through FR-26, FR-104 through FR-111) must be architecturally isolated from analytics, AI scoring, and notification processing.

---

**SA-AVL-03: Maintenance Window Communication**

Planned maintenance windows must be announced to all Tenant Admins via email at least 48 hours before the maintenance begins. Maintenance must not be scheduled during peak exam hours.

Peak exam hours are defined as `07:00–22:00 Vietnam Standard Time (UTC+7)` on school days [subject to OI-05 adjustment by Vendor Operations]. Maintenance windows default to `02:00–06:00 VNT`.

---

## 3.6.3 Security

**SA-SEC-01: Authentication on All Protected Endpoints**

Every API endpoint except the public trial landing page (FR-88), login (FR-01), forgot password (FR-05), and token refresh (FR-02) must require a valid JWT access token in the `Authorization: Bearer {token}` header. Requests without a valid token return HTTP 401. Requests with a valid token but insufficient permissions return HTTP 403.

Token validation occurs on every request. Permission decisions are not cached beyond the token's own TTL (15 minutes, NFR-13).

---

**SA-SEC-02: Tenant Data Isolation**

No user may read or write data belonging to a different tenant under any circumstances. Tenant isolation is enforced at two layers:
1. **Application layer:** Every database query generated by the Backend API includes `WHERE tenant_id = {resolved_id}` (resolved from the request subdomain, FR-03)
2. **Database layer:** Row-level security (RLS) policies or equivalent database-level enforcement as a defense-in-depth measure

A cross-tenant data leak (any response returning data from a different tenant's namespace) is classified as a Critical security defect and requires immediate remediation.

---

**SA-SEC-03: Server-side Role Authorization**

Every API endpoint must declare the minimum required role(s) for access. Authorization is enforced server-side by the Backend middleware. Client-side access control (hiding buttons or routes in Flutter) is a UX enhancement only and is not a security control.

Role authorization must use the union of all active roles for the requesting user (DC-09). A user with Teacher + Exam Coordinator roles can call any endpoint permitted by either role.

---

**SA-SEC-04: Input Validation and Injection Prevention**

All user-supplied input must be validated server-side before being used in any operation. The following rules apply without exception:
- **SQL injection:** Parameterized queries or ORM-level query building only; no string interpolation in database queries
- **XSS prevention:** HTML content from user input (question content, feedback narratives, email bodies) must be sanitized with an allowlist-based sanitizer (permitted tags: `<b>`, `<i>`, `<p>`, `<br>`, `<ul>`, `<li>`) before rendering; no raw user HTML is rendered unsanitized
- **Mass assignment:** API endpoints must whitelist permitted request fields; extra fields must be ignored, not applied
- **File upload validation:** MIME type and file extension must both be validated server-side (not just client-side); files must be scanned before storage

---

**SA-SEC-05: Data Protection in Transit and at Rest**

- **In transit:** HTTPS (TLS 1.2 minimum, TLS 1.3 preferred) for all communication (DC-03); no plaintext HTTP connections are permitted
- **At rest:** Database encryption enabled via provider-managed encryption (e.g., AWS RDS encryption); Cloud Storage objects encrypted at rest with provider-managed keys
- **Audio recordings:** Speaking audio files are private objects in Cloud Storage; public access is disabled; access requires a time-limited presigned URL or server-proxy
- **Application logs:** No PII (student names, email addresses, exam answers) or credentials appear in log output; password fields are stripped by logging middleware before writing

---

**SA-SEC-06: Exam Integrity as Security Subsystem**

The anti-cheat system (F-12, FR-93–FR-103) is classified as a security subsystem. Its controls must be implemented server-side where possible:
- Timer manipulation is prevented structurally (DC-04); client-side timer display is read-only
- Violation events are immutable at the application level (DC-10); no user role can delete or modify them
- Question/answer shuffle seeds are generated server-side and stored server-side; the client cannot influence the shuffle

---

**SA-SEC-07: Credential Export Security**

The bulk credential export (FR-48) displays plaintext passwords for newly created accounts within a 24-hour window only. After this window, passwords are not retrievable in any form (the bcrypt hash in the database is not reversible). This is by design.

The export file must be served over HTTPS. The Backend must not log the plaintext password at any point during generation or transmission.

---

**SA-SEC-08: Rate Limiting**

The following endpoint categories must implement rate limiting to prevent brute-force and abuse:
- Login endpoint (FR-01): 10 requests per minute per IP address (CI-01)
- Forgot password endpoint (FR-05): 5 requests per minute per IP address
- Exam state write endpoint (FR-105): 120 requests per minute per `attempt_id` (CI-01)
- Token refresh endpoint (FR-02): 30 requests per minute per user

Requests exceeding rate limits receive HTTP 429 with a `Retry-After` header indicating when the rate window resets.

---

## 3.6.4 Maintainability

**SA-MNT-01: Zero-code Tenant Onboarding**

Adding a new tenant to the system requires only: (1) creating a tenant record in the Vendor Portal (FR-71), (2) verifying wildcard DNS routing (wildcard CNAME handles all new slugs automatically), and (3) creating a license (FR-73). No code deployment, configuration file change, or infrastructure provisioning is required per new tenant.

---

**SA-MNT-02: AI Provider Configurability Without Code Change**

The AI scoring pipeline must be configurable to switch between STT providers and LLM providers via a system configuration change, with no code change and no redeployment. The pipeline reads `ai_config.stt_provider` and `ai_config.llm_provider` from a system configuration table at job execution time (FR-31, SI-05 provider-switch requirement).

---

**SA-MNT-03: Email Template Editability via Admin UI**

All email notification templates must be editable by a Super Admin via the Vendor Portal (FR-85) without any code deployment. Adding support for a new notification trigger type requires a code change (to add the trigger event), but editing existing templates requires only the Admin UI.

---

**SA-MNT-04: Feature Flags for Conditional Features**

The following features must be controllable via system-level feature flags without code deployment:
- Guest/Trial Flow (F-11, FR-88–FR-92): enabled/disabled globally
- Flutter Mobile push notifications (FR-84): enabled/disabled globally
- PDF export (FR-66, Conditional): enabled/disabled per tenant or globally

Feature flags are stored in a system configuration table editable by Super Admin. Disabling a feature must gracefully hide or disable all related UI controls and API endpoints (not crash).

---

**SA-MNT-05: Structured Logging**

All application log entries must be in structured JSON format with standardized fields:

```json
{
  "timestamp": "ISO8601",
  "level": "INFO|WARN|ERROR",
  "request_id": "UUID",
  "tenant_id": "UUID or null",
  "user_id": "UUID or null",
  "event_type": "string",
  "message": "string",
  "metadata": {}
}
```

No PII may appear in log output. Logs must be queryable by `tenant_id`, `user_id`, `event_type`, and `request_id` for debugging and incident investigation.

---

## 3.6.5 Portability

**SA-PRT-01: Flutter Platform Adapter Pattern**

The Flutter codebase must separate platform-specific code from shared business logic using the adapter pattern. Platform-specific implementations (microphone access, kiosk window management, local file system, fullscreen control) must be encapsulated in platform-specific adapter classes. The shared exam engine must call adapter interfaces, not platform SDKs directly.

This ensures that adding support for a new platform (e.g., Flutter Mobile added in v1.5) requires only implementing the adapter layer, not rewriting exam logic.

---

**SA-PRT-02: Cloud Provider Abstraction**

The Backend API must define service interfaces for all cloud-provider-specific services:
- `StorageService` (interface for S3/GCS object operations)
- `QueueService` (interface for job queue — SQS/Pub-Sub/equivalent)
- `EmailService` (interface for SendGrid/SES API)

Domain logic must call these interfaces; provider SDKs must be used only in concrete adapter implementations. Migrating from one cloud provider to another requires changing adapter implementations, not domain logic.

---

**SA-PRT-03: Database Schema Portability**

The data access layer must use parameterized queries or an ORM that targets standard SQL without provider-specific extensions wherever possible. PostgreSQL-specific features (e.g., `JSONB`, `UUID` native type) may be used where they provide significant benefit, but the ORM abstraction layer must document any portability assumptions.

---

## 3.6.6 Usability

**SA-USA-01: Zero-training Exam Flow for Students**

A student must be able to complete the full exam flow — login → My Exams → pre-exam checks → exam parts → results — without any external training, using only the in-app instruction screens provided by the system. All instructions must be in Vietnamese as the primary language with an English language option.

Assessment criterion: a student who has never used the platform before can complete a test exam in a controlled usability session without asking for help from the proctor.

---

**SA-USA-02: APTIS-Familiar Exam Interface**

The exam client UI (UI-09) must match the visual layout and interaction idioms of the actual APTIS online exam as closely as technically feasible. The goal is to reduce cognitive overhead for students who have taken or practiced for the official APTIS exam. Deviations from APTIS interface conventions must be documented and justified.

---

**SA-USA-03: Actionable Error Messages**

Every error message presented to any user must include three elements: (1) what happened, (2) why it happened (to the extent safe to disclose without leaking system internals), and (3) what the user should do next. Generic messages such as "Something went wrong" or "An error occurred" without guidance are not acceptable.

Examples of acceptable error messages:
- "Your session has expired. Please log in again to continue."
- "Seat quota reached (200 of 200 seats used). Please contact your account manager to add more seats."
- "The audio file format is not supported. Accepted formats: MP3, WAV."

---

**SA-USA-04: Bulk Operation Progress and Result Feedback**

All bulk operations — CSV import (FR-47), bulk account generation, mass notifications — must show a progress indicator while the operation is running and a result summary on completion. The summary must include: number of records successfully processed, number of records failed or skipped, and a per-record error description for any failure. Users must not wait blindly without feedback for operations that may take more than 2 seconds.

---

**SA-USA-05: Minimum Screen Width for Admin Portals**

Flutter Web views for the Vendor Portal and Tenant Portal must be functional and correctly rendered on screens with a minimum width of 1024 pixels. Mobile-responsive layouts for admin portals are not required in v1. The Exam Client is the mobile-primary surface and handles smaller screens.

---

**SA-USA-06: Live Monitor Real-time Update Requirement**

The Exam Coordinator live monitor dashboard (FR-39) must update student status without requiring a manual page refresh. Stale data on the monitor screen during an active exam session is a usability failure that can cause coordinators to miss student problems (disconnection, violations) and delay intervention.

Updates must arrive via WebSocket push (primary) or SSE (fallback) within 5 seconds of the underlying event occurring on the student's side.
