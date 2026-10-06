# 1. Deliverable Package

This section maps the original DOCX heading **1. Deliverable Package**. It defines what the PTE Prep release package contains, how each item is identified, what is supported, and what evidence is still required before a release handoff.

## 1.1 Product boundary

PTE Prep is an independent organization-based PTE-style practice and mock-exam simulation platform. It is not connected to, representative of, endorsed by, or a certification service for PTE Academic. A report produced by PTE Prep is an organization practice/mock result, not an official PTE Academic result.

## 1.2 Package contents

| Package ID | Deliverable | Purpose | Status/evidence |
|---|---|---|---|
| `REL-WEB-TENANT` | Organization web portal | Host, Proctor, Examiner operations: roster, packages, exams, monitoring, scoring, reports, audit. | Current channel boundary; individual workflows are Current/Partial only when route/UI evidence is verified (`EVD-FOUNDATION-004`). |
| `REL-WEB-PLATFORM` | Platform administration portal | Platform Admin and Platform Author onboarding/content/template/package governance. | Current channel boundary; end-to-end slices are evidence-dependent. |
| `REL-CLIENT-WINDOWS` | Windows-first exam client | Student sign-in, device check, timed tasks, local answer save, synchronization, submission, result view. | Windows-first requirement; complete device/offline matrix is `TBD-CLIENT-001`. |
| `REL-APP` | PTE Prep backend application | Identity, tenancy, content, template, billing, exam, attempt, proctoring, scoring, reporting, notification, support, and audit package boundaries. | Current modular-monolith topology (`EVD-FOUNDATION-003`). |
| `REL-DATABASE` | PostgreSQL data store | Relational organization, exam, attempt, scoring, report, and audit data. | Current infrastructure boundary; retention is contract-based TBD. |
| `REL-SUPPORT-INFRA` | Redis and RabbitMQ support services | Cache/rate-limit/coordination and asynchronous work where configured. | Current infrastructure boundary; feature use is evidence-dependent. |
| `REL-EDGE` | Public edge/proxy and TLS boundary | Routes users to supported web/API entry points. | Current deployment topology (`EVD-FOUNDATION-006`). |
| `REL-MEDIA` | Cloudinary or approved media integration | Signed image/audio upload/access for question revisions. | External boundary; provider status and credentials are not included. |
| `REL-PAYMENT` | PayOS or approved payment integration | Organization package order/callback/license activation where enabled. | External boundary; registration remains separate from payment. |
| `REL-AI` | Approved AI scoring boundary | Optional asynchronous scoring for eligible task types. | Partial/Planned/TBD provider/threshold (`TBD-AI-001`). |
| `REL-NOTIFICATION` | Email/notification boundary | Supported status notifications and retry state. | External boundary; failure does not roll back business state. |
| `REL-DOCS` | Reports 3–6 Markdown set | Requirements, design, testing documentation, release package, and user guides. | This documentation work package; Report 7/Vietnamese copies deferred. |

## 1.3 Release identification

Every handoff should include:

- release identifier and date;
- backend/web/client build identifiers;
- database migration/configuration version;
- supported browser and Windows/device matrix;
- enabled external providers and simulation mode, without credentials;
- test run/report IDs and open defects/TBD decisions;
- rollback/recovery owner and contact path;
- document version and record-of-changes entry.

The package must not contain `.env` files, tokens, private keys, passwords, raw provider secrets, or unmasked Student/audio/answer/report data.

## 1.4 Supported release scope

The release scope is organization-first practice/mock-exam operation: approved onboarding, shared content/template governance, roster and package preparation, fixed exam setup, Windows-first Student delivery, assignment-scoped Proctor/Examiner work, Host score-source review, report publication, and audit. Current/Partial/Planned/Future labels must follow the foundation evidence matrix.

The release does not promise official certification, Student self-payment, mobile delivery, adaptive/IRT testing, universal no-repeat content, advanced anti-cheat, or a universal retention period.

## 1.5 Handoff evidence checklist

| Area | Required evidence | Related IDs |
|---|---|---|
| Onboarding | Registration/approval/Host access result and audit reference | `FR-ONBOARD-002`, `TC-ACCESS-002` |
| Content/template | Approved revision, complete media, active template/version | `FR-CONTENT-003`, `FR-TEMPLATE-002`, `TC-CONTENT-001` |
| Package/roster | Package status, limit/capacity result, deduplicated candidate preview | `FR-PACKAGE-005`, `FR-ENROLL-002`, `TC-PACKAGE-001` |
| Exam generation | Fixed version, form mode, provenance, generation state | `FR-EXAM-004`, `FR-HARDENING-001`, `TC-EXAM-002` |
| Delivery | Device check, local save/sync state, submission acknowledgement | `FR-DELIVERY-002`, `FR-DELIVERY-006`, `TC-DELIVERY-003` |
| Integrity | Assignment, violation/assistance event, policy effect | `FR-INTEGRITY-003`, `TC-PROCTOR-001` |
| Scoring/publication | Examiner/provider source, Host selection, readiness, publication, Student visibility | `FR-SCORE-005`, `FR-REPORT-003`, `TC-SCORE-003`, `TC-REPORT-001` |
| Operations | Health, backup/recovery, performance and integration evidence | `NFR-01`–`NFR-08`, `NFR-19`, `TC-OPS-001` |

## 1.6 Known partial and TBD items

- Complete Windows device/audio matrix and offline recovery proof: `TBD-CLIENT-001`.
- Exact generation retry/cancel/idempotency state machine: `TBD-GENERATION-001`.
- Per-mode audience/form policy approval: `TBD-VERSION-001`.
- Proctor violation synchronization timing and recovery: `TBD-PROCTOR-001`.
- AI provider, thresholds, and Examiner review policy: `TBD-AI-001`, `TBD-AI-002`.
- Retention, export/delete/legal hold and jurisdiction: `TBD-RETENTION-001`, `TBD-DATA-001`.

