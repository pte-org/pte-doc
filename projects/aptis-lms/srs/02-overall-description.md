# SRS §2 — Overall Description
## APTIS LMS
**Version:** 1.0 | **Date:** 2026-06-16 | **Status:** DRAFT

---

## 2.1 Product Perspective

APTIS LMS is a new, standalone SaaS product with no predecessor system. It is not a module or extension of any existing platform.

### 2.1.1 System Context

```
┌──────────────────────────────────────────────────────────────────┐
│                      APTIS LMS Platform                          │
│                                                                  │
│  ┌───────────────┐  ┌───────────────┐  ┌──────────────────┐    │
│  │ Vendor Portal │  │ Tenant Portal │  │   Exam Client    │    │
│  │   (Flutter    │  │   (Flutter    │  │   (Flutter       │    │
│  │    Web)       │  │    Web)       │  │ Desktop/Web/Mob) │    │
│  └──────┬────────┘  └──────┬────────┘  └────────┬─────────┘    │
│         └──────────────────┼──────────────────────┘             │
│                            │                                     │
│               ┌────────────▼──────────────┐                     │
│               │        Backend API         │                     │
│               │   REST + WebSocket/SSE     │                     │
│               └───┬──────────┬────────────┘                     │
│                   │          │                                   │
│          ┌────────▼──┐  ┌───▼──────────────┐                   │
│          │ Relational │  │  Async Job Queue  │                   │
│          │  Database  │  │ (AI Scoring +     │                   │
│          └────────────┘  │  Notifications)   │                   │
│                          └───────────────────┘                   │
└──────────────────────────────────────────────────────────────────┘
         │                 │                  │
   ┌─────▼──────┐  ┌───────▼──────┐  ┌───────▼───────┐
   │   Cloud    │  │ Email / Push │  │   AI APIs     │
   │  Storage   │  │   Service    │  │  STT + LLM    │
   │ (S3 / GCS) │  │(SendGrid/FCM)│  │    [TBD]      │
   └────────────┘  └──────────────┘  └───────────────┘
```

### 2.1.2 Multi-tenant Architecture

Each tenant is identified by a unique subdomain:

- `admin.aptis-lms.vn` → Vendor Portal (no tenant scoping)
- `{slug}.aptis-lms.vn` → Tenant Portal + Exam Client login
- Wildcard SSL certificate covers `*.aptis-lms.vn`
- All Backend API requests carry a `tenant_id` resolved from the subdomain; every database query is scoped to that tenant

### 2.1.3 External System Interfaces

| External System | Direction | Purpose |
|---|---|---|
| Cloud Object Storage (S3/GCS) | Read + Write | Audio recordings, Listening audio, images, report exports |
| Email Service (SendGrid/SES — TBD) | Outbound | All email notifications |
| Firebase Cloud Messaging | Outbound | Push notifications (Flutter mobile, if in scope) |
| STT API (TBD — OI-02) | Outbound | Speech-to-text for Speaking recordings |
| LLM API (TBD — OI-02) | Outbound | Writing and Speaking AI scoring |

---

## 2.2 Product Functions

### 2.2.1 Vendor Portal Functions
- Manage tenant lifecycle (create, configure, suspend, reactivate)
- Maintain APTIS question bank (all 4 skills, 16 parts, audio, images, exam templates)
- Manage seat-based licenses (Sales Team creates; system enforces quota and expiry)
- Monitor cross-tenant usage and provide Support Staff read-only access
- View item analysis metrics aggregated globally

### 2.2.2 Tenant Portal Functions
- Manage learner roster: bulk enrollment, CSV import, auto-generated credentials, Excel export
- Create and deploy exam sessions: schedule, notify, monitor live, intervene
- Review and confirm AI-generated Writing/Speaking scores
- Access analytics: individual student results, class reports, school KPI dashboard, report export
- Manage Tenant users and multi-role assignments

### 2.2.3 Exam Client Functions
- Authenticate as a Tenant student and join an assigned exam session
- Complete a full APTIS simulation across all four skills and sixteen parts
- Resume from the last saved answer after network disconnection
- View personal results and teacher feedback after scoring is complete

### 2.2.4 Cross-cutting System Functions
- Enforce exam integrity: question/answer randomization, kiosk mode, violation detection and logging
- Maintain exam continuity: server-authoritative timer, per-answer persistence, local audio buffer, crash recovery
- Execute AI scoring pipeline asynchronously: STT transcription → LLM draft score → teacher review queue
- Deliver notifications: email and optional push on all defined trigger events

---

## 2.3 User Characteristics

### Super Admin (Vendor)
Expert-level technical user; manages the platform as a whole. Expects direct data access, batch operations, and full observability. Tolerates developer-style interfaces for rarely-performed operations.

### Content Manager (Vendor)
Domain expert in APTIS pedagogy; non-developer. Works in a rich-text CMS-style interface. Requires: clear form validation, audio preview before saving, bulk import with error feedback. High task frequency during content authoring sprints; lower during steady state.

### Support Staff (Vendor)
Basic-to-intermediate technical proficiency. Works from a support ticket context. Needs: tenant lookup by name/slug, read-only view of tenant data, guided escalation path to Super Admin. No raw data manipulation access.

### Sales Team (Vendor)
Non-technical. Works from a customer-list mental model similar to a CRM. Needs: simple license creation form, clear customer status at a glance, one-click renewal. Does not interact with exam or student data.

### Tenant Admin (School/Center)
Office staff or IT coordinator at a school. Basic-to-intermediate technical proficiency; comfortable with Google Forms and Excel. Needs: guided bulk import flow, clear license status display, comprehensive but readable reports. Primary concern: managing large cohorts of students efficiently.

### Teacher / Instructor
Classroom teacher; basic web user. Familiar with Google Classroom or similar. Needs: simple exam session creation, clear scoring queue with AI draft pre-populated, visual class analytics. Key pain point: reviewing Writing/Speaking quickly without reviewing each response from scratch.

### Exam Coordinator
Manages exam rooms; intermediate technical proficiency. Works intensively only during active exam sessions. Needs: real-time status dashboard with no page refresh, quick per-student intervention controls, clear violation log.

### Viewer / Report Only
Non-technical school leadership (principal, department head). Views summary dashboards and exports. Needs: clean KPI cards, downloadable Excel/PDF reports. No operational interaction with the system.

### Student (Registered)
Mixed demographic: secondary students to working adults. Basic-to-intermediate app/web users. Unfamiliar with the APTIS LMS interface but familiar with taking online tests. Needs: zero-training onboarding through in-app instructions, clear timer display, visual feedback for recording/upload. Critical accessibility: requires working microphone for Speaking; requires audio output for Listening.

### Guest / Trial Taker
First-time visitor with no prior account. May not know what APTIS is. Needs zero-friction access — no signup, no download. The trial is a marketing conversion tool as much as a product demonstration.

---

## 2.4 Constraints

### 2.4.1 Technology Constraints
- **Client framework mandate:** Flutter (Dart) for all client applications. No alternative frontend framework permitted (DC-01).
- **Platform targets:** Determined by TechLead (OI-01). Baseline assumption: Flutter Web for admin portals; Flutter Desktop (Windows/macOS) + Flutter Web for Exam Client.
- **Hosting mandate:** Cloud-only (AWS, GCP, or Azure). No on-premise deployment for v1 (DC-08).
- **Tenant isolation mandate:** All data strictly scoped to `tenant_id` at application and database layer (DC-02).
- **HTTPS mandate:** No unencrypted HTTP endpoints (DC-03).
- **Timer mandate:** Exam timers are server-authoritative; client-side manipulation is architecturally prevented (DC-04).
- **Persistence mandate:** Per-answer server-side persistence for exam state (DC-05).
- **AI mandate:** Third-party APIs only; no custom ML model training (DC-06).

### 2.4.2 Business Constraints
- No payment processing in the system; Sales manages contracts externally (DC-07).
- Tenants cannot create or modify exam questions in v1; all content is Vendor-managed (Assumption A-04).
- The system is not an official APTIS test center; a disclaimer must be displayed on all result screens (DC-11, OR-LGL-01).

### 2.4.3 Regulatory Constraints
- Vietnamese Nghị định 13/2023/NĐ-CP (Personal Data Protection): applicability and required obligations are TBD — Legal to confirm (OI-07).
- PCI-DSS: Not applicable (no payment card data).
- HIPAA: Not applicable (no health data).

---

## 2.5 Assumptions and Dependencies

| ID | Assumption | Risk if Wrong |
|---|---|---|
| A-01 | Students have a compatible device with a working microphone | Students cannot complete Speaking; teacher must handle each case manually per FR-110 |
| A-02 | APTIS exam structure (skills, parts, format) is stable for the v1 product lifetime | Major content and UI refactor required if British Council changes the exam format |
| A-03 | Tenants have teachers available to review Writing/Speaking within an acceptable SLA | Scoring backlog accumulates; student results are delayed indefinitely |
| A-04 | All question bank content is created and maintained by the Vendor Content Manager | Question pedagogical quality is entirely Vendor's responsibility |
| A-05 | Network at exam locations is sufficiently stable for audio upload within the session window | F-13 continuity features mitigate short drops but cannot handle sustained disconnection |
| A-06 | Payment between Vendor and Tenant is managed entirely outside the system | No payment status tracking needed in the platform |
| A-07 | One subdomain maps exactly to one tenant (no subdomain sharing) | Tenant routing architecture would require redesign |
| A-08 | The Content Manager has APTIS pedagogical expertise to author valid questions | System validates structure but not pedagogical correctness |
| A-09 | Audio recording consent is covered by the Vendor–Tenant contract and Tenant enrollment terms | No in-app consent flow is required for audio; if wrong, a consent FR must be added |
| A-10 | The band mapping table (raw score → APTIS band) is provided by the Vendor and configured statically | Scoring accuracy depends entirely on the correctness of the Vendor-supplied table |

---

## 2.6 Apportioning of Requirements

The following requirements are included in this SRS but are explicitly deferred to v1.5 if timeline or resource constraints require scope reduction. They may be cut from v1 without affecting the viability of core exam delivery.

| Deferred Requirement | Deferred to | Condition for Cut |
|---|---|---|
| F-11: Guest/Trial Flow (FR-88–FR-92) | v1.5 | Core product operates without trial; marketing impact only |
| Flutter Mobile (iOS/Android) for Exam Client | v1.5 | Flutter Web + Desktop sufficient for exam rooms |
| Push Notifications (FR-84) | v1.5 | Requires mobile client; email notifications cover v1 |
| PDF Report Export (FR-66 — PDF portion) | v1.5 | Excel export sufficient for v1 |
| Support Staff Impersonation (FR-76) | v1.5 | Super Admin can handle urgent tenant support directly |
| Full NĐ 13/2023 compliance (if applicable) | v1.5 | Pending Legal determination (OI-07) |
