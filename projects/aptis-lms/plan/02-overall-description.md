# Plan File 02 — Overall Description (SRS §2)
Project: APTIS LMS  
Date: 2026-06-16

---

## §2.1 Product Perspective

**What to write in SRS:**

APTIS LMS is a new, standalone SaaS product. It does not replace or extend any existing system. It operates as a multi-tenant platform where each tenant (school/training center) is isolated via subdomain routing.

### System Context Diagram (described in text)

```
┌────────────────────────────────────────────────────────────────────┐
│                        APTIS LMS Platform                          │
│                                                                    │
│  ┌─────────────────┐   ┌─────────────────┐   ┌────────────────┐  │
│  │  Vendor Portal  │   │  Tenant Portal  │   │  Exam Client   │  │
│  │  (Web)          │   │  (Web)          │   │  (Flutter)     │  │
│  └────────┬────────┘   └────────┬────────┘   └───────┬────────┘  │
│           │                     │                     │            │
│           └─────────────────────┼─────────────────────┘            │
│                                 │                                   │
│                    ┌────────────▼────────────┐                     │
│                    │      Backend API         │                     │
│                    │  (REST + WebSocket/SSE)  │                     │
│                    └──┬──────────┬───────────┘                     │
│                       │          │                                  │
│              ┌────────▼──┐  ┌───▼──────────────┐                 │
│              │  Database  │  │  AI Scoring Queue │                 │
│              └────────────┘  └───────────────────┘                 │
└────────────────────────────────────────────────────────────────────┘
         │                  │                  │
    ┌────▼────┐      ┌──────▼──────┐   ┌──────▼──────┐
    │  Cloud  │      │ Email/Push  │   │  AI APIs    │
    │ Storage │      │  Service    │   │ STT + LLM   │
    │ (S3/GCS)│      │(SendGrid/   │   │ [TBD]       │
    └─────────┘      │  FCM)       │   └─────────────┘
                     └─────────────┘
```

### Multi-tenant Architecture

Each tenant identified by subdomain: `{slug}.aptis-lms.vn`

- `admin.aptis-lms.vn` → Vendor Portal
- `{tenant-slug}.aptis-lms.vn` → Tenant Portal + Exam Client login
- All API requests carry tenant_id resolved from subdomain; all data queries scoped to tenant_id

### Interface to External Systems

| External System | Direction | Protocol | Purpose |
|---|---|---|---|
| Cloud Object Storage (S3/GCS) | Bidirectional | HTTPS SDK | Store/retrieve audio recordings, images, CSV exports |
| Email Service (SendGrid/SES) | Outbound | REST API | Send notification emails |
| Firebase Cloud Messaging | Outbound | REST API | Push notifications (Flutter mobile) |
| STT API (Whisper/Google STT — TBD) | Outbound | REST API / SDK | Transcribe Speaking audio |
| LLM API (Claude/GPT-4 — TBD) | Outbound | REST API | Score Writing and Speaking |

---

## §2.2 Product Functions

**What to write in SRS:** High-level function summary grouped by subsystem.

### Vendor Portal Functions
1. Manage tenants (create, configure, suspend, reactivate)
2. Manage APTIS question bank (16 parts, audio, images, exam templates)
3. Manage licenses (seat-based, expiry-dated, sales-created)
4. Monitor all-tenant usage and support tickets
5. View item analysis across all tenants

### Tenant Portal Functions
1. Manage learners: enrollment, class grouping, bulk account generation, seat tracking
2. Create and deploy exam sessions: scheduling, notifications, live monitoring
3. Score Writing and Speaking: review AI drafts, confirm or override
4. View analytics: student results, class reports, school dashboard, report export
5. Manage tenant users (add/remove/assign roles)

### Exam Client Functions (Flutter)
1. Authenticate and join an assigned exam session
2. Complete full APTIS simulation: Reading, Writing, Listening, Speaking
3. Resume from last position after disconnect
4. View personal exam results and feedback (post-scoring)

### System-level (Cross-cutting) Functions
1. Enforce exam integrity: shuffle, kiosk, violation detection and logging
2. Maintain exam continuity: server-side timer, per-answer persistence, audio buffering
3. Deliver AI scoring: async STT → LLM pipeline
4. Send notifications: email + push on all triggers

---

## §2.3 User Characteristics

**What to write in SRS:**

### Super Admin
Technical expert; daily system operations; expects admin UI with full data visibility and control. Tolerates technical interfaces.

### Content Manager
Domain expert (APTIS pedagogy), non-developer. Needs a rich-text editor for question content, file upload for audio/images, and clear form-based workflow. No code or API interaction.

### Support Staff
Basic-intermediate technical. Needs ticket view + read-only tenant data access. Guided workflows, no raw data access.

### Sales Team
Non-technical. Needs a clean CRM-like interface: customer list, one-click license creation. Minimal fields, clear status indicators.

### Tenant Admin
School/center office staff. Basic-intermediate. Familiar with basic web apps (Google Forms, spreadsheets). Needs clear guided workflows for bulk import, license tracking, report generation.

### Teacher / Instructor
Teachers familiar with educational platforms (Google Classroom equivalent). Basic web users. Need simple class management, clear scoring queue, visual analytics.

### Exam Coordinator
Intermediate technical during exam sessions (used to monitoring dashboards). Needs real-time updates, quick intervention controls (extend time, force submit).

### Viewer / Report Only
Non-technical leadership (school principal, director). Reads charts and summary tables. Needs clean, exportable reports. No operational controls.

### Student (Registered)
Mixed age group (secondary students to working adults). Basic web/app users. Unfamiliar with APTIS system UI — needs onboarding guidance per skill. Must work on devices they already own.

### Guest / Trial Taker
First-time visitors; no prior knowledge of the system. Need zero-friction access (no account setup). Clear trial scope ("you are taking a sample, not the real exam").

---

## §2.4 Constraints

**What to write in SRS:**

### Technical Constraints
- **Client framework:** Flutter (Dart) is mandated. All client applications (Vendor Portal, Tenant Portal, Exam Client) must be built using Flutter.
- **Platform targets:** [TBD — OI-01]. Pending TechLead platform split decision. Plan assumes: Web for admin portals, Desktop + Web for Exam Client.
- **Cloud hosting:** AWS, GCP, or Azure — no on-premise deployment for v1.
- **Multi-tenant isolation:** All data must be strictly tenant-scoped at application and database layer.
- **HTTPS-only:** No unencrypted HTTP endpoints exposed to public.
- **No AI model training:** AI scoring uses third-party APIs only (STT + LLM). No custom ML training.

### Business Constraints
- **No payment processing in-system:** Vendor does not handle payments via the platform. License creation is manual by Sales Team.
- **Exam content is Vendor-owned:** Tenants cannot create or modify questions in v1.
- **Not an official test center:** Disclaimer required in UI and legal terms. Cannot claim official APTIS certification.

### Regulatory Constraints
- Vietnamese Nghị định 13/2023/NĐ-CP (Personal Data Protection): [TBD — OI-07]. Potential requirements: user consent, right to deletion, data residency consideration.
- No payment card data → PCI-DSS not applicable.
- No health data → HIPAA not applicable.

### Exam Integrity Constraints
- Exam timer must be server-authoritative (cannot be controlled by client).
- Exam state must persist server-side after each answered question (no client-only buffering for answers).
- Speaking audio may be buffered locally but must upload within session window.

---

## §2.5 Assumptions and Dependencies

**What to write in SRS:** Reference spec §8 assumptions with full text.

| ID | Assumption | Risk if Wrong |
|---|---|---|
| A-01 | Students have compatible device + working microphone | Students cannot complete Speaking → teacher must handle manual case |
| A-02 | APTIS exam structure stable for v1 lifetime | Major content/UI refactor needed if British Council changes format |
| A-03 | Tenants have teachers available to review Speaking/Writing | Scoring backlog grows; students wait indefinitely for results |
| A-04 | Vendor manages all question bank content | Question quality is entirely Vendor's responsibility; no tenant customization |
| A-05 | Network at exam location stable enough for audio upload | Speaking audio may not upload; F-13 continuity features mitigate but don't eliminate |
| A-06 | Payment is external to system | No payment status tracking needed; Sales manages manually |
| A-07 | 1 subdomain = 1 tenant (no sharing) | Multi-subdomain tenants would need redesign of tenant routing |
| A-08 | Content Manager has APTIS expertise | System cannot validate pedagogical quality of questions |
| A-09 | Audio storage consent covered by contract | No in-app consent flow needed for audio; if wrong, PDPA consent UI required |
| A-10 | Band mapping table provided by Vendor | Scoring accuracy depends on Vendor's band conversion table |

---

## §2.6 Apportioning of Requirements

**What to write in SRS:** Requirements to defer if timeline or resources constrain v1.

| Deferred Requirement | Planned For | Condition |
|---|---|---|
| F-11: Guest/Trial Flow (FR-88 – FR-92) | v1.5 | Deprioritized if launch deadline requires cuts; system functions without it |
| Flutter Mobile (iOS/Android) for Exam Client | v1.5 | If Flutter Web + Desktop covers v1 use cases |
| Push Notifications (FR-84) | v1.5 | Only needed if mobile client exists; email covers v1 |
| Report Export PDF (FR-66 partial) | v1.5 | Excel export is sufficient for v1; PDF is enhancement |
| FR-76: Support Staff Impersonation | v1.5 | Nice-to-have for support; Super Admin can handle urgent cases in v1 |
| Nghị định 13 full compliance (if applicable) | v1.5 | Assess legal obligation before v1 launch |
