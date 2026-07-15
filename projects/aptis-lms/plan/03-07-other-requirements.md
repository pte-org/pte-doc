# Plan File 03-07 — Other Requirements (SRS §3.7)
Project: APTIS LMS  
Date: 2026-06-16

---

## §3.7.1 Internationalization (i18n)

**OR-I18N-01: Primary Language — Vietnamese**
The exam client UI, error messages, instructions, and all student-facing notifications must be in Vietnamese as the default language. The system must not assume English as the default for student-facing surfaces.

**OR-I18N-02: Secondary Language — English**
All student-facing surfaces must support English as an alternative language. Students may switch between Vietnamese and English; the selection persists in their account preferences.

**OR-I18N-03: APTIS Exam Content Language**
APTIS exam content (questions, passages, prompts) is in English by definition — this is an English proficiency test. The content language cannot be changed. Only the UI shell (instructions, labels, navigation, error messages) is localized.

**OR-I18N-04: Teacher and Admin Interfaces**
Tenant Portal and Vendor Portal: Vietnamese primary, English secondary. Same language switching capability as student-facing surfaces.

**OR-I18N-05: Email Notification Language**
Notification emails are sent in the language configured for the tenant (default: Vietnamese). Per-user language preference overrides tenant default for student-facing notifications.

**OR-I18N-06: i18n Implementation**
All UI strings must be defined in locale files (e.g., `intl` package in Flutter); no hardcoded UI strings in Dart code. Date/time display must respect tenant timezone configuration (FR-72). Number formatting must use Vietnamese conventions where applicable (e.g., decimal separator).

---

## §3.7.2 Legal Requirements

**OR-LGL-01: Non-official Exam Disclaimer**
The system must display on all result screens and the trial landing page: "Đây là kết quả thi thử mô phỏng. APTIS LMS không phải là đơn vị được British Council ủy quyền và không cấp chứng chỉ APTIS chính thức." (English: "This is a practice exam result. APTIS LMS is not affiliated with or authorized by British Council and does not issue official APTIS certificates.")

**OR-LGL-02: Vietnamese Personal Data Protection (NĐ 13/2023/NĐ-CP)**
[TBD — OI-07: Legal must confirm scope of applicability]

If applicable, the system must comply with the following requirements of Nghị định 13/2023/NĐ-CP:
- User consent: At registration, users must consent to data collection and processing; consent is explicit (opt-in checkbox, not pre-checked)
- Right to access: Users can request a copy of their personal data stored in the system
- Right to deletion: Users or their representatives (Tenant Admin on behalf of minors) can request deletion of personal data; system must support data deletion workflows
- Data breach notification: System must have a process to notify affected users and authorities within the required timeframe in case of a breach
- Data localization: If required, personal data of Vietnamese citizens must be stored on servers located in Vietnam or with a Vietnamese data-handling entity [TBD: requires Legal + TechLead decision on cloud region]

**OR-LGL-03: Audio Recording Consent**
Speaking audio recordings constitute personal data (voice recording). Users (or their guardians for minors) must be informed that audio is recorded and stored. Consent mechanism: covered by contract between Vendor and Tenant, and by Tenant's enrollment terms with students. No in-app consent flow required if contract covers this (assumption A-09). If Legal determines in-app consent is required, this becomes a new FR.

**OR-LGL-04: Terms of Service and Privacy Policy**
The system must display links to: Terms of Service (Điều khoản sử dụng) and Privacy Policy (Chính sách bảo mật) on: the login page (all portals), the trial landing page, and the account creation screen. These documents are authored by Vendor Legal and hosted externally; the system provides links only.

---

## §3.7.3 Operational Requirements

**OR-OPS-01: Monitoring and Alerting**
The system must expose health check endpoints for all services (backend API, AI scoring queue, notification service). Infrastructure monitoring must alert on: service downtime, error rate spikes (> X% 5xx responses in 5 minutes), database CPU/storage thresholds, and queue depth growth (AI scoring queue backlog > N items). TechLead to define specific thresholds.

**OR-OPS-02: Application Performance Monitoring (APM)**
Distributed tracing must be enabled for all API requests and background jobs. Key traces: exam-answer-persist, auto-score-pipeline, AI-scoring-pipeline, notification-send. This enables debugging of latency issues per request.

**OR-OPS-03: Database Backups**
Database backups must run at minimum daily; preferably continuous (PITR — Point-in-Time Recovery with ≤ 1 hour RPO). Backup retention: [TBD — OI-07]. Backup restore must be tested at least quarterly.

**OR-OPS-04: Scheduled Jobs**
The following scheduled jobs must be implemented and monitored for failures:
- License expiry alert: daily check at 08:00 VN time (NFR-74)
- Guest data purge: daily (FR-92)
- Speaking audio CDN pre-caching: trigger before session start time (for Listening audio delivery)
- Notification SLA reminder: periodic check for pending reviews past SLA [TBD — OI-03]
- Seat quota alert: on every enrollment event (event-driven, not scheduled)

**OR-OPS-05: Deployment Strategy**
Zero-downtime deployments are required (blue-green or rolling update). Migrations must be backward-compatible with the running application version during rollout (expand-then-contract migration pattern). No breaking schema changes may be deployed without a migration plan.

**OR-OPS-06: Logging Retention**
Application logs: retain for [TBD — OI-07] days. Structured JSON format (SA-MNT-05). Access to production logs is restricted to authorized engineering team only.

---

## §3.7.4 Transition Requirements

**OR-TRN-01: Tenant Onboarding Process**
A new tenant can be fully onboarded without code deployment. The onboarding steps are:
1. Sales creates tenant record (FR-71) and license (FR-78)
2. Sales or Super Admin creates Tenant Admin account
3. Tenant Admin receives welcome email with login credentials and portal URL
4. Tenant Admin logs in and begins managing their portal
Estimated time from Sales contract to first login: < 1 business day.

**OR-TRN-02: Question Bank Seed Data**
Before the first tenant can run exams, the Vendor Content Manager must populate the question bank with at least one complete exam template (all 4 skills, all parts). This is a data migration/seed task — not a system feature. The question bank management system (FR-09 to FR-16) must be functional before any tenant goes live.

**OR-TRN-03: Data Migration from Legacy Systems**
As a new product (no predecessor system), there is no data migration from a legacy system. If any tenant has an existing roster (e.g., from a spreadsheet), they use the CSV import feature (FR-47). No ETL pipeline for legacy data is required.

---

## §3.7.5 Training Requirements

**OR-TRN-04: In-system Onboarding for Students**
The Exam Client must provide self-guided onboarding for students before their first exam:
- Per-skill instruction screens with visual examples (FR-18)
- Microphone test screen with visual feedback (FR-18)
- A short practice question (non-scored, not timed) for each interaction type on first encounter

**OR-TRN-05: User Documentation**
The system must include an in-app help section accessible from all portals with:
- Tenant Admin: guide for bulk import, license monitoring, user management
- Teacher: guide for creating exam sessions, using the scoring queue, reading analytics
- Student: guide for pre-exam setup, exam interface, viewing results
Documentation is in Vietnamese (primary) and English (secondary). Rich text, no video tutorials required for v1.

**OR-TRN-06: Vendor Staff Training**
Training for Vendor-side staff (Content Manager, Support Staff, Sales Team) is out of scope for this SRS — handled by the Vendor's internal onboarding. The system must provide a clear admin interface that is self-explanatory for trained Vendor staff.
