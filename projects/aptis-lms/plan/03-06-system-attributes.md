# Plan File 03-06 — System Attributes (SRS §3.6)
Project: APTIS LMS  
Date: 2026-06-16

System attributes describe the quality properties that the system must exhibit beyond functional correctness.

---

## §3.6.1 Reliability

**SA-REL-01: Exam Session Data Integrity (NFR-X)**
The system shall never lose a student's exam answers that have been acknowledged by the server. This is the #1 reliability requirement. Achieved through: per-answer persistence (FR-105), server-authoritative timer (FR-104), audio local buffer (FR-108), resume on reconnect (FR-106), and crash recovery (FR-111).

**SA-REL-02: Scoring Pipeline Fault Tolerance**
The AI scoring pipeline (STT + LLM) shall be fault-tolerant: if an AI API call fails, the pipeline shall retry with exponential backoff (FR-30, FR-31) and flag the attempt for manual teacher review rather than silently failing or producing incorrect scores.

**SA-REL-03: Notification Retry**
Email notification sends shall be retried once on failure (FR-83); failed sends shall be logged but shall not block other system operations. A batch of failed notifications must not prevent subsequent notifications from being sent.

**SA-REL-04: No Single Point of Failure for Exam Delivery**
The exam-serving component (Backend API + Database) must not have a single point of failure during exam hours. TechLead to design for: database replica failover, load-balanced API instances, and health-check-based routing.

---

## §3.6.2 Availability

**SA-AVL-01: Exam Hour Availability ≥ 99.9% (NFR-03)**
The system shall achieve ≥ 99.9% availability during any time window where at least one exam session is in progress. Planned maintenance must be scheduled outside exam windows.

**SA-AVL-02: Graceful Degradation for Non-critical Components**
If non-critical services (email delivery, analytics reporting, AI scoring pipeline) become unavailable, the core exam delivery service (FR-17 through FR-26, FR-104 through FR-111) must continue operating. Design must isolate exam delivery from analytics and scoring queues.

**SA-AVL-03: Maintenance Window Communication**
Planned maintenance windows must be announced to Tenant Admins via email at least 48 hours in advance. Maintenance shall not occur during peak exam hours [TBD: define peak hours — typically school hour windows 7:00–22:00 VN time].

---

## §3.6.3 Security

**SA-SEC-01: Authentication**
All protected API endpoints require a valid JWT access token. Unauthenticated requests receive HTTP 401. Invalid tenant-scope requests receive HTTP 403. Token validation occurs on every request (no caching of permission decisions beyond the token's lifetime).

**SA-SEC-02: Authorization — Tenant Data Isolation**
No user may read or write data belonging to a different tenant. The system enforces tenant scoping at: (a) application layer — every query includes tenant_id constraint; (b) database layer — row-level security or equivalent. Cross-tenant data leakage is treated as a Critical security defect.

**SA-SEC-03: Authorization — Role-based Access**
Each API endpoint must declare the minimum required role(s). The authorization middleware verifies the requesting user holds at least one of the required roles (union of multi-role). Endpoint authorization must be enforced server-side; client-side UI-only restrictions are insufficient.

**SA-SEC-04: Input Validation and Injection Prevention**
All user-supplied input must be validated and sanitized server-side. Parameterized queries or ORM-level query building must be used exclusively — no string interpolation in SQL. HTML content (question content, feedback) must be sanitized with an allowlist sanitizer before rendering to prevent XSS.

**SA-SEC-05: Sensitive Data in Transit and at Rest**
- In transit: HTTPS (TLS 1.2+) for all client-server and server-to-service communication (DC-03)
- At rest: Database encryption enabled; Cloud Storage objects encrypted at rest; audio recordings are private objects (no public access — accessed via pre-signed URLs or server proxy)
- Logs: no PII or credentials in application logs; password fields are stripped before logging

**SA-SEC-06: Exam Integrity**
The exam integrity system (FR-93 to FR-103) is a security sub-system. Violation events (FR-101) are immutable at application level (DC-10). Timer manipulation by client is structurally prevented (DC-04).

**SA-SEC-07: Credential Export Security**
The bulk password export (FR-48) displays plaintext passwords only once (within 24 hours of account creation). After this window, passwords are no longer retrievable (bcrypt hash in DB is non-reversible). This is a by-design security constraint, not a limitation.

**SA-SEC-08: Rate Limiting**
Authentication endpoints (login, forgot password) must implement rate limiting to prevent brute-force attacks. Exam state write endpoints must be rate-limited per attempt to prevent abuse. TechLead to define specific limits.

---

## §3.6.4 Maintainability

**SA-MNT-01: Tenant Onboarding via Admin Portal**
Adding a new tenant requires only: creating a tenant record (FR-71), configuring DNS (wildcard handles routing automatically), and creating a license (FR-73). No code deployment required per tenant.

**SA-MNT-02: AI Provider Configurability**
The AI scoring pipeline must be able to switch between STT providers and LLM providers via configuration (not code change). The provider selection reads from a system configuration table. Changing provider requires only updating the config, not redeploying the service.

**SA-MNT-03: Email Template Management via Admin UI**
Email templates must be editable by Super Admin via the Vendor Portal (FR-85), without code deployment. Template variables are documented; new trigger types require a code change to add the trigger but not to change existing template content.

**SA-MNT-04: Feature Flags for Conditional Features**
Guest/Trial (FR-88–92), Flutter Mobile push notifications (FR-84), and PDF export (FR-66 partial) must be feature-flaggable. Enabling/disabling them must not require code deployment — controlled via system configuration.

**SA-MNT-05: Structured Logging**
All application logs must be structured (JSON format) with fields: timestamp, level, request_id, tenant_id (when applicable), user_id (when applicable), event_type. This enables filtering and alerting on specific tenant or user activity.

---

## §3.6.5 Portability

**SA-PRT-01: Flutter Cross-platform**
The Flutter codebase must be structured so that platform-specific code (kiosk mode, microphone access, file system access) is isolated in platform-specific adapters. Shared business logic and UI must be reusable across Web, Desktop, and Mobile targets.

**SA-PRT-02: Cloud Provider Independence**
The Backend API must use abstractions for cloud-specific services (storage, queue, email) so that migrating from AWS to GCP or Azure requires only changing the infrastructure adapter layer, not the domain logic. Service interfaces (e.g., `StorageService`, `QueueService`) must be defined independently of provider SDK.

**SA-PRT-03: Database Schema Independence**
The data access layer must use an ORM or query builder that can target multiple RDBMS (e.g., PostgreSQL, MySQL). This does not require multi-DB support in v1, but avoids locking to DB-specific syntax that would prevent future migration.

---

## §3.6.6 Usability

**SA-USA-01: Exam Client — Zero Training for Students**
Students must be able to complete the pre-exam flow (login → exam selection → pre-exam checks → exam start) without any training other than the instruction screens displayed by the system itself. All instructions must be in Vietnamese (primary) with English option.

**SA-USA-02: Exam Interface — APTIS Familiarity**
The exam UI must match the visual layout and interaction style of the actual APTIS online exam as closely as possible. The purpose is to reduce cognitive load for students who have already seen APTIS exam instructions.

**SA-USA-03: Error Messages — Actionable**
All error messages presented to users must include: what happened, why it happened (when safe to disclose), and what the user should do next. Generic "Something went wrong" messages without guidance are not acceptable.

**SA-USA-04: Bulk Operations — Feedback**
All bulk operations (CSV import, bulk account generation, mass notifications) must show progress indicators and result summaries (N succeeded, M failed, K errors with details). Users must not have to wait blindly for long-running operations.

**SA-USA-05: Responsive Design (Web)**
Flutter Web views for Tenant Portal and Vendor Portal must be usable on screens ≥ 1024px wide. Mobile-responsive web is not required for admin portals in v1 (Exam Client is the mobile-primary surface).

**SA-USA-06: Exam Coordinator Monitor — Real-time**
The live monitor dashboard (FR-39) must update without page refresh. Stale data on the monitor screen during an exam is a usability failure that can cause Coordinators to miss student problems.
