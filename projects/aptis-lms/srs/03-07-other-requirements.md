# SRS §3.7 — Other Requirements
## APTIS LMS
**Version:** 1.0 | **Date:** 2026-06-16 | **Status:** DRAFT

---

## 3.7.1 Internationalization (i18n)

**OR-I18N-01: Primary Language — Vietnamese**

Vietnamese (vi-VN) is the primary language for all student-facing surfaces: the Exam Client UI, all in-app instruction text, error messages, system notifications, and the trial landing page (UI-10). The system must not default to English for any student-facing surface.

**OR-I18N-02: Secondary Language — English**

All student-facing surfaces must support English (en) as an alternative language. A student may switch between Vietnamese and English from their account settings; the language preference is persisted in the user profile and applied to all subsequent sessions.

**OR-I18N-03: APTIS Exam Content Language**

APTIS exam content (question text, reading passages, Listening audio, Writing prompts, Speaking prompts) is in English by the nature of the test — APTIS is an English proficiency assessment. This content cannot be translated or localized. Only the UI shell (labels, navigation elements, instruction text, error messages, countdown text) is subject to OR-I18N-01 and OR-I18N-02.

**OR-I18N-04: Tenant Portal and Vendor Portal Language**

The Tenant Portal (Tenant Admin, Teacher, Exam Coordinator, Viewer) and Vendor Portal must support Vietnamese as the primary language and English as the secondary language, with the same language-switching mechanism as the student-facing surfaces. The language preference for staff users is stored per user account.

**OR-I18N-05: Email Notification Language**

Notification emails are rendered in the language configured for the tenant (default: Vietnamese). A per-user language preference overrides the tenant default for student-facing notifications (e.g., score available email). Email templates must exist in both Vietnamese and English versions for all notification types (FR-85).

**OR-I18N-06: i18n Technical Implementation**

The following technical requirements apply to the i18n implementation:
- All UI strings must be externalized in locale files (e.g., using the Flutter `intl` package with ARB files); no UI string may be hardcoded as a Dart string literal in widget code
- Date and time display must respect the tenant's configured timezone (FR-72, OR-OPS-04); all server-side timestamps are stored in UTC and converted to the tenant timezone for display
- Number formatting (e.g., decimal separators, thousand separators) must use Vietnamese conventions (e.g., `1.234,56` rather than `1,234.56`) when the active locale is `vi-VN`
- The language selection UI must be accessible before login (login screen language toggle) so that students can read login instructions in their preferred language

---

## 3.7.2 Legal Requirements

**OR-LGL-01: Non-official Exam Disclaimer**

The system must display a clear, non-dismissible disclaimer on all result screens, attempt summary screens, and the trial landing page. The disclaimer must include the following text (or a legally approved equivalent):

*Vietnamese:* "Đây là kết quả bài thi thử mô phỏng. APTIS LMS không phải là đơn vị được British Council ủy quyền. Điểm và band ước tính chỉ có tính tham khảo và không phải là chứng chỉ APTIS chính thức."

*English:* "This is a practice exam simulation result. APTIS LMS is not affiliated with or authorized by British Council. Scores and band estimates are for learning reference only and do not constitute official APTIS certification."

The disclaimer must render as part of the page content, not as a dismissible modal. It must be visible without scrolling on the result screen.

---

**OR-LGL-02: Vietnamese Personal Data Protection — NĐ 13/2023/NĐ-CP**

`[TBD — OI-07: Legal must confirm applicability and specific obligations before this requirement can be finalized. The following obligations apply IF Legal determines the decree applies to APTIS LMS.]`

If Nghị định 13/2023/NĐ-CP applies, the system must implement:

1. **Consent at account creation:** At first login or registration, users must provide explicit consent (opt-in checkbox, not pre-checked) for data collection and processing. Consent records must be stored with timestamp and version of the privacy policy accepted.

2. **Right to access:** Any registered user may request an export of their personal data stored in the system (name, email, exam history, feedback). The system or Vendor must fulfill such requests within the timeframe required by the decree.

3. **Right to deletion:** Users or their authorized representatives (Tenant Admin for minors) may request deletion of personal data. The system must support a data deletion workflow; deleted personal data must be purged from all storage including backups within the decree-specified timeframe.

4. **Data breach notification:** The system must have an operational process to notify affected users and regulatory authorities within the timeframe specified by the decree in the event of a data breach.

5. **Data localization:** If the decree requires personal data of Vietnamese citizens to reside on servers in Vietnam, the cloud deployment region must include Vietnam. TechLead and Legal must confirm the cloud provider region before finalization of deployment architecture (OI-07, DC-08).

---

**OR-LGL-03: Audio Recording Disclosure**

Speaking audio recordings are personal data (voice recordings) under most privacy frameworks. Users — or their guardians for minor students — must be informed that audio is recorded and stored as part of the exam process.

For v1, disclosure is handled at the contract level (Vendor–Tenant contract and Tenant enrollment terms cover this per Assumption A-09). No in-app audio consent flow is required in v1. If Legal determines that in-app consent is required (e.g., due to NĐ 13/2023 obligations), a new functional requirement must be added to this SRS.

---

**OR-LGL-04: Terms of Service and Privacy Policy Links**

The system must display links to the Vendor's Terms of Service (Điều khoản sử dụng) and Privacy Policy (Chính sách bảo mật) on:
- The login page of all portals (Vendor Portal, Tenant Portal, Exam Client)
- The trial landing page (FR-88)
- The account creation confirmation screen (for newly created accounts)

These documents are authored by Vendor Legal, hosted externally, and may be updated without a system deployment. The system provides navigable hyperlinks only; it does not host the document content.

---

## 3.7.3 Operational Requirements

**OR-OPS-01: Health Check Endpoints and Monitoring**

The system must expose HTTP health check endpoints for each service component:
- `GET /health` on the Backend API: returns HTTP 200 with `{"status":"ok","db":"ok","queue":"ok"}` when all dependencies are reachable; returns HTTP 503 with failing component indicated when degraded
- AI scoring queue health: exposes queue depth metric
- Notification service health: exposes pending send count

Infrastructure monitoring must alert on:
- Any service instance returning non-200 health check for > 30 seconds
- API error rate (5xx responses) exceeding a configurable threshold (TechLead to define during OI-05 resolution)
- Database CPU, storage, and connection pool metrics exceeding warning thresholds
- AI scoring queue depth growing beyond a backlog threshold (indicating processing stall)

---

**OR-OPS-02: Application Performance Monitoring**

Distributed tracing must be enabled for all API requests and all background job executions. The following traces must be instrumented as named spans:
- `exam.answer.persist` — per-answer write (FR-105)
- `exam.timer.sync` — timer sync endpoint (FR-104)
- `scoring.auto` — auto-scoring job (FR-27, FR-28)
- `scoring.stt` — STT API call (FR-30)
- `scoring.llm` — LLM API call (FR-31)
- `notification.send` — email send (FR-83)

Traces must be queryable by `tenant_id`, `attempt_id`, and `request_id`. p95 latency per trace type must be visible in the APM dashboard.

---

**OR-OPS-03: Database Backup and Recovery**

Database backups must meet the following requirements:
- Backup frequency: Point-in-Time Recovery (PITR) with Recovery Point Objective (RPO) ≤ 1 hour preferred; daily snapshot as minimum
- Backup retention period: `[TBD — OI-07]`
- Backup encryption: required; encryption key stored separately from the backup (managed KMS)
- Recovery test: automated or manual restore test performed at minimum quarterly; results documented
- Backup storage: geographically separate from the primary database region

---

**OR-OPS-04: Scheduled Job Inventory**

The following scheduled jobs must be implemented, monitored, and alerted on failure:

| Job | Schedule | Purpose | FR Reference |
|-----|----------|---------|-------------|
| License expiry alert check | Daily at 08:00 VNT | Send 30-day and 7-day expiry alerts | FR-74 |
| Seat quota alert check | Event-driven (on enrollment) | Send 80% and 90% usage alerts | FR-74 |
| Guest/Trial data purge | Daily | Purge expired anonymous session data | FR-92 |
| Listening audio CDN pre-warm | Before each session start_time − 15 min | Ensure audio is cached at CDN edge | SI-01 |
| Review SLA reminder check | Periodic [TBD — OI-03] | Alert Teacher if review exceeds SLA | FR-83 |
| Expired refresh token cleanup | Daily | Remove expired/revoked tokens older than 90 days | §3.4.4 |
| Item analysis recomputation | Nightly | Recompute p-value and discrimination index | FR-68, FR-69 |

All scheduled jobs must: (1) run within a maintenance window that avoids peak exam hours (07:00–22:00 VNT), (2) log start time, completion time, and record counts, (3) be monitored with an alert if the job fails or does not complete within 2× its historical average runtime.

---

**OR-OPS-05: Zero-downtime Deployment**

All production deployments must use a zero-downtime strategy (blue-green deployment or rolling update). Database schema migrations must follow the expand-then-contract pattern:
1. **Expand:** Add new column/table without removing old structures (old and new code versions can coexist)
2. **Migrate:** Backfill data if necessary
3. **Contract:** Remove old columns/tables only after the new version is fully deployed and verified

No breaking schema changes may be applied directly to a running production database. A migration rollback plan must be prepared for every schema change.

---

**OR-OPS-06: Log Retention**

Application logs (structured JSON per SA-MNT-05) must be retained for `[TBD — OI-07]` days. Access to production log streams is restricted to authorized engineering personnel; no PII or credential data may appear in log output (SA-SEC-05). Log storage must be separate from application database storage.

---

## 3.7.4 Transition Requirements

**OR-TRN-01: Tenant Onboarding Process**

A new tenant can be fully activated without any code deployment. The complete onboarding sequence is:

1. Sales Team member creates the tenant record in the Vendor Portal (FR-71) with slug, display name, contact email, and timezone
2. Sales Team member creates a seat-based license for the tenant (FR-78)
3. Sales Team member (or Super Admin) creates the Tenant Admin user account
4. Tenant Admin receives a welcome email with portal URL (`{slug}.aptis-lms.vn`) and temporary login credentials
5. Tenant Admin logs in, is prompted to change password (FR-06), and begins managing their portal

Target time from signed contract to first Tenant Admin login: less than 1 business day, assuming no infrastructure changes required.

---

**OR-TRN-02: Question Bank Seed Data Prerequisite**

Before the first tenant exam session can be run, the Vendor Content Manager must have populated the question bank with at least one complete, published exam template covering all 4 skills and all 16 parts. This is a data population task performed via the Content Management interface (FR-09 through FR-16), not a system feature. The question bank must be seeded before any tenant goes live with student exams.

---

**OR-TRN-03: No Legacy Data Migration**

APTIS LMS is a new product with no predecessor system. There is no legacy database to migrate. If a tenant joins with an existing student roster (e.g., from an Excel spreadsheet or a previous provider's export), they use the CSV bulk import feature (FR-47) to onboard their students. No custom ETL pipeline, API integration, or data mapping service is required for v1 transitions.

---

## 3.7.5 Training Requirements

**OR-TRN-04: Self-guided Student Onboarding**

The Exam Client must provide sufficient in-app guidance for a student to complete their first exam without external training. Required in-app onboarding elements:
- Per-skill instruction screens with example questions and time limits (FR-18)
- Microphone test screen with visual audio level feedback before Speaking (FR-18)
- Clear timer display always visible during exam (UI-09)
- Navigation panel with answered/unanswered indicators per question
- Contextual error messages and recovery instructions (SA-USA-03)

---

**OR-TRN-05: In-app Help Documentation**

The system must include an in-app help section accessible from all portals, providing:
- **For Tenant Admins:** step-by-step guides for CSV bulk import, license status monitoring, user management, and course creation
- **For Teachers:** guides for creating exam sessions, using the scoring review queue, and interpreting class analytics
- **For Students:** guides for completing pre-exam setup, navigating the exam interface, and viewing results

Help content must be in Vietnamese (primary) and English (secondary), displayed in rich text format within the application. Video tutorials are not required for v1.

---

**OR-TRN-06: Vendor Staff Training (Out of Scope)**

Training for Vendor-side staff (Content Manager, Support Staff, Sales Team, Super Admin) is outside the scope of this SRS. It is addressed by the Vendor's internal onboarding process. The Vendor Portal must be self-explanatory for staff who have received internal training; it need not include guided onboarding flows for Vendor-side users.
