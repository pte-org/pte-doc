# 5. Requirement Appendix

This section maps the original DOCX heading **5. Requirement Appendix**. It contains common requirements, business rules, message expectations, assumptions, open decisions, task catalog reference, and explicit out-of-scope boundaries.

## 5.1 Business rules

The rules below are the business interpretation of the functional requirements. A design or implementation may use a different internal structure, but it must preserve the observable rule or raise a reviewed change to the SRS.

### Access and data ownership

| ID | Rule | Related requirements |
|---|---|---|
| `BR-ACCESS-001` | A person may use only the approved human roles assigned to the account; External Integration Services is not a human login role. | `FR-ONBOARD-004`, `CR-AUTH-001` |
| `BR-ACCESS-002` | Platform Admin controls platform-wide administrative data and approval actions. | `FR-ONBOARD-002`, `FR-CONTENT-005` |
| `BR-ACCESS-003` | Platform Author may create/edit/submit drafts but cannot self-activate shared production content. | `FR-CONTENT-001`, `FR-CONTENT-005` |
| `BR-ACCESS-004` | Host may read and change only the organization’s permitted operational data. | `FR-HARDENING-002`, `NFR-09` |
| `BR-ACCESS-005` | Proctor and Examiner may work only in their assigned exam/answer scope. | `FR-INTEGRITY-001`, `FR-SCORE-001` |
| `BR-ACCESS-006` | Student may write own active attempt data and view own published report only. | `FR-DELIVERY-001`, `FR-REPORT-004` |
| `BR-ACCESS-007` | An organization becomes active only after Platform Admin approval. | `FR-ONBOARD-002`, `FR-ONBOARD-003` |
| `BR-ACCESS-008` | Pending or rejected registration cannot open an active organization workspace. | `FR-ONBOARD-001`, `FR-ONBOARD-002` |
| `BR-ACCESS-009` | A Student belongs to one organization in this release. | `FR-ORG-001`, `FR-ENROLL-001` |
| `BR-ACCESS-010` | Student creation/import checks organization capacity, duplicates, and required data before commit. | `FR-ORG-001`, `FR-ORG-002` |
| `BR-ACCESS-011` | Membership transfer/removal is explicit and auditable; it does not rewrite a published exam audience. | `FR-ORG-004`, `FR-ENROLL-002` |

### Shared content and Score Templates

| ID | Rule | Related requirements |
|---|---|---|
| `BR-CONTENT-012` | A question is not publishable while required content or media is incomplete. | `FR-CONTENT-003` |
| `BR-CONTENT-013` | Editing published content creates a revision; a locked exam keeps the referenced revision. | `FR-CONTENT-004` |
| `BR-CONTENT-014` | Host can select only an active Score Template. | `FR-TEMPLATE-003` |
| `BR-CONTENT-015` | Host cannot change common task count, weights, timing, or source rules inside a shared template. | `FR-TEMPLATE-003` |
| `BR-CONTENT-016` | The selected Score Template revision is fixed for a generated exam. | `FR-TEMPLATE-004`, `FR-EXAM-009` |

### Packages and limits

| ID | Rule | Related requirements |
|---|---|---|
| `BR-PACKAGE-017` | Student is not the payer or owner of an organization package. | `FR-PACKAGE-006` |
| `BR-PACKAGE-018` | Each successful package purchase or license activation creates one independently traceable subscription/license record. | `FR-PACKAGE-002`–`FR-PACKAGE-004` |
| `BR-PACKAGE-019` | A subscription is usable only while active and while the exam window is inside its allowed dates. | `FR-PACKAGE-005` |
| `BR-PACKAGE-020` | Candidate count cannot exceed the active package limit for the exam. | `FR-PACKAGE-005`, `FR-ENROLL-002` |
| `BR-PACKAGE-021` | A license code is redeemable once; duplicate payment callbacks do not create a second activation. | `FR-PACKAGE-003`, `FR-PACKAGE-004` |
| `BR-PACKAGE-022` | Revocation removes use rights according to the published package policy and leaves history auditable. | `FR-PACKAGE-004`, `FR-REPORT-005` |

### Exam preparation and scheduling

| ID | Rule | Related requirements |
|---|---|---|
| `BR-EXAM-023` | Host must pass pre-exam validation before publication. | `FR-EXAM-003`, `FR-EXAM-006` |
| `BR-EXAM-024` | Candidate duplicates are removed or explained before capacity/conflict evaluation. | `FR-ENROLL-002`, `FR-EXAM-003` |
| `BR-EXAM-025` | A Student already assigned, conflicting, or otherwise blocked is excluded or stopped with a reason; the system does not silently accept the conflict. | `FR-ENROLL-002`, `FR-EXAM-003` |
| `BR-EXAM-026` | Exams using one license cannot overlap when the package rule forbids it; different licenses may overlap if permitted. | `FR-EXAM-008` |
| `BR-EXAM-027` | Changes to class/program membership after publication do not rewrite the frozen audience. | `FR-ORG-003`, `FR-EXAM-006` |
| `BR-EXAM-028` | Practice defaults to `SHARED_FORM`; Mock Test and Official-like modes default to `UNIQUE_FORM_PER_STUDENT` unless an approved policy overrides it. | `FR-EXAM-002`, `FR-EXAM-005` |
| `BR-EXAM-029` | A generated form cannot contain the same question revision more than once unless a future approved policy explicitly allows it. | `FR-EXAM-004`, `FR-EXAM-009` |

### Delivery and answer safety

| ID | Rule | Related requirements |
|---|---|---|
| `BR-DELIVERY-030` | The exam client stores a response locally before treating network transmission as complete. | `FR-DELIVERY-005` |
| `BR-DELIVERY-031` | A connectivity failure leaves a visible retryable answer state and does not silently discard the response. | `FR-DELIVERY-006` |
| `BR-DELIVERY-032` | The service validates Student, exam, form, task revision, response shape, and attempt state before accepting an answer. | `FR-DELIVERY-007` |
| `BR-DELIVERY-033` | The effective exam policy is fixed for an attempt after delivery begins. | `FR-DELIVERY-004`, `FR-INTEGRITY-004` |
| `BR-DELIVERY-034` | A submitted attempt cannot create a second attempt in the same exam unless an approved retake policy exists. | `FR-DELIVERY-008` |

### Proctoring and scoring

| ID | Rule | Related requirements |
|---|---|---|
| `BR-INTEGRITY-035` | A Proctor action must be attached to an assigned exam and recorded in audit context. | `FR-INTEGRITY-001`, `FR-INTEGRITY-003` |
| `BR-SCORE-036` | An Examiner score becomes an eligible final source only after Host review. | `FR-SCORE-003`, `FR-SCORE-005` |
| `BR-SCORE-037` | Host may select a source only when that source has a valid score for the chosen task/section/report scope. | `FR-SCORE-005`, `FR-SCORE-006` |
| `BR-SCORE-038` | A report cannot be published while required scores or source decisions are missing. | `FR-SCORE-006`, `FR-REPORT-003` |
| `BR-INTEGRITY-039` | In the initial Practice policy, a violation warns and audits; it does not automatically pause, force-submit, invalidate, or terminate without an approved rule. | `FR-INTEGRITY-004` |

### Reports and audit

| ID | Rule | Related requirements |
|---|---|---|
| `BR-REPORT-040` | Student sees a report only after Host publication and only for the Student’s own attempt. | `FR-REPORT-003`, `FR-REPORT-004` |
| `BR-REPORT-041` | A published report is traceable to exam version, question/media revision, Score Template revision, and selected score source. | `FR-EXAM-009`, `FR-SCORE-007`, `FR-REPORT-005` |
| `BR-REPORT-042` | Permission, payment, enrollment, exam policy, scoring approval/source selection, violation, and publication changes require audit records. | `FR-REPORT-005`, `NFR-10` |
| `BR-REPORT-043` | Attempts, answers, scores, reports, and audit logs follow the organization contract; deletion, export, and legal-hold rules remain TBD. | `NFR-13`, `TBD-RETENTION-001` |

### External service failure and retry

| ID | Rule | Related requirements |
|---|---|---|
| `BR-INTEGRATION-044` | Payment callbacks are safely retryable and cannot create duplicate activation. | `FR-INTEGRATION-001` |
| `BR-INTEGRATION-045` | An AI scoring failure is visible and may be retried or routed to the approved review path; it is not silently treated as a valid score. | `FR-INTEGRATION-003`, `FR-SCORE-004` |
| `BR-INTEGRATION-046` | An expired media link is renewed through the provider boundary and is not treated as lost Student answer data. | `FR-INTEGRATION-002` |
| `BR-INTEGRATION-047` | Notification failure does not roll back a successful payment, enrollment, exam, score, or publication. | `FR-INTEGRATION-004` |
| `BR-INTEGRATION-048` | A provider outage exposes pending/error state and a safe next action to the permitted user. | `FR-INTEGRATION-005`, `FR-INTEGRATION-006` |

## 5.2 Common requirements

| ID | Common requirement | Acceptance condition |
|---|---|---|
| `CR-AUTH-001` | Check role, organization scope, assignment scope, object state, and action permission together. | An authenticated but unassigned user is denied without a data mutation. |
| `CR-AUTH-002` | Return business-readable status and message for every blocked state. | User can identify the affected record and next permitted action. |
| `CR-TENANT-001` | Carry organization ownership through Student, exam, attempt, answer, score, report, and audit reads/writes. | Cross-organization positive/negative tests are traceable. |
| `CR-IDEMPOTENCY-001` | Use a safe correlation key or existing-state response for retryable actions. | Retry cannot duplicate payment, generation, answer, score, or publication. |
| `CR-PROVENANCE-001` | Preserve revision, policy, template, source, actor, and time for material result decisions. | A reviewer can reconstruct what the Student received and how the report was chosen. |
| `CR-MESSAGE-001` | Messages explain state without exposing credentials, provider secrets, or unnecessary personal data. | Safe message and audit payload are distinct. |
| `CR-STATUS-001` | Use Current, Partial, Planned/Future, Out of scope, and TBD consistently across documents. | A reviewer can follow the evidence record and limitation. |

## 5.3 Message catalogue

Messages are examples of required business meaning. Exact localization and UI wording can vary while preserving the trigger, audience, severity, and next action.

| ID | Trigger | Audience | Severity | Required message meaning | Next action |
|---|---|---|---|---|---|
| `MSG-ACCESS-001` | Registration pending/rejected | Registrant/Platform Admin | Information/Warning | Registration is not an active workspace; show status/reason. | Correct, wait for review, or contact authorized support. |
| `MSG-ACCESS-002` | Account locked/suspended | Account holder | Warning | Sign-in/business action is temporarily unavailable. | Follow controlled recovery path. |
| `MSG-CONTENT-001` | Required media missing | Platform Author/Admin/Host | Error | Content cannot be approved/published because named media is incomplete. | Attach/renew media and validate again. |
| `MSG-CONTENT-002` | Template inactive/retired | Host | Error | Selected Score Template cannot be used for a new exam. | Select an active version or ask Platform Admin. |
| `MSG-PACKAGE-001` | Package inactive/expired/over limit | Host | Error | Package does not permit this exam/date/capacity. | Activate/choose an eligible package or adjust draft. |
| `MSG-EXAM-001` | Candidate conflict/duplicate | Host | Warning/Error | Named Student is duplicated, conflicting, or blocked. | Review list and resolve before publication. |
| `MSG-EXAM-002` | Generation pending/failed | Host | Warning/Error | Exam version is not ready; partial forms cannot be published. | Wait, retry safely, or cancel. |
| `MSG-DELIVERY-001` | Device check failed | Student/Proctor | Error | Named device/audio requirement is not ready for timed work. | Correct device or escalate before starting. |
| `MSG-DELIVERY-002` | Answer queued/rejected | Student | Information/Error | Answer is locally saved but not yet accepted, or was rejected with reason. | Keep working if allowed and retry/follow support. |
| `MSG-INTEGRITY-001` | Violation recorded | Proctor/Host/Student as policy allows | Warning | Event was recorded with policy effect; no unsupported automatic consequence is implied. | Follow the fixed exam policy. |
| `MSG-SCORE-001` | Score pending/failed | Host/Examiner | Information/Error | Required source is not ready or failed; report readiness is affected. | Retry, complete Examiner work, or escalate. |
| `MSG-REPORT-001` | Report not published | Student | Information | Report is not visible because Host publication or required scoring is incomplete. | Contact Host; do not expose another report. |
| `MSG-INTEGRATION-001` | Provider timeout/duplicate callback | Host/Platform Admin | Warning/Error | External result is pending/duplicate/failed and is being handled safely. | Wait, retry, or escalate with correlation reference. |

## 5.4 Complete PTE task catalogue reference

The canonical catalog contains exactly 23 rows at [`../_foundation/pte-task-catalog.md`](../_foundation/pte-task-catalog.md): 22 scored task types plus unscored Personal Introduction. Every row records response type, timing rule, default score source, Score Template relationship, and fixed-version relationship. Report 3 must not introduce an additional task name outside that catalog without updating the catalog and ledger.

## 5.5 Assumptions and constraints

| ID | Assumption/constraint | Owner if changed | Impact |
|---|---|---|---|
| `ASM-001` | Host creates/imports Students; no Student self-registration in this release. | Product owner | Changes onboarding, identity, tenant and capacity flows. |
| `ASM-002` | Windows-first is the initial exam delivery channel. | Exam-client owner | Changes device matrix, timing, media, and test scope. |
| `ASM-003` | Organization activation and package/payment activation are separate steps. | Product owner | Changes registration and billing contract. |
| `ASM-004` | Fixed exam version preserves selected revisions and policy. | Exam workflow owner | Changes report provenance and recovery. |
| `ASM-005` | Scores and notifications may be asynchronous. | Scoring/operations owner | Changes pending/readiness and publication timing. |
| `ASM-006` | Contract-based retention is the interim safe statement. | Platform Admin/legal owner | Changes NFR, export/delete, legal hold, and guide content. |

## 5.6 Open decisions and evidence gaps

| Register ID | Decision/evidence needed | Owner | Impact |
|---|---|---|---|
| `TBD-RETENTION-001` | Exact retention period and deletion/export/legal-hold process. | Platform Admin + organization/legal owner | `NFR-13`, `BR-REPORT-043`, Reports 4–6. |
| `TBD-AI-001` | AI provider, supported task types, threshold, timeout, retry, and fallback. | Platform Admin + scoring owner | `FR-INTEGRATION-003`, `FR-SCORE-004`, publication readiness. |
| `TBD-AI-002` | Task-level requirement for Examiner review of AI output. | Scoring policy owner | `BR-SCORE-036`–`BR-SCORE-038`. |
| `TBD-PROCTOR-001` | Exact violation synchronization and recovery contract. | Integrity/technical owner | `FR-INTEGRITY-003`, `NFR-19`. |
| `TBD-GENERATION-001` | Exact generation retry/cancel/idempotency state machine. | Exam workflow owner | `FR-EXAM-004`, `FR-EXAM-007`. |
| `TBD-VERSION-001` | Per-mode audience snapshot and shared/unique form policy approval. | Product owner | `FR-EXAM-005`, `BR-EXAM-028`. |
| `TBD-CLIENT-001` | Supported Windows/browser/audio/microphone/device matrix. | Exam-client owner | `FR-DELIVERY-002`, `NFR-18`. |
| `TBD-DATA-001` | Jurisdiction and data protection obligations. | Platform Admin + legal owner | `NFR-14`, retention and integration contracts. |

## 5.7 Out-of-scope register

| ID | Explicit boundary | Reason/status |
|---|---|---|
| `OOS-001` | PTE Academic connection, representation, official certification, or official score reporting. | Independent practice/mock-exam product boundary. |
| `OOS-002` | Student self-payment, personal package ownership, and consumer subscription flow. | Organization-first package model. |
| `OOS-003` | Research-based learning claims, scientific contribution, or a new scoring model. | Product development scope, not academic research. |
| `OOS-004` | Adaptive testing, IRT, and a universal permanent no-repeat guarantee. | Requires separate research/data/policy scope. |
| `OOS-005` | Mobile exam delivery redesign. | Windows-first release constraint. |
| `OOS-006` | Host-owned private question bank separate from shared platform content. | Shared platform content governance. |
| `OOS-007` | Virtual-machine detection, screen recording, and complete secondary-device blocking. | Advanced anti-cheat privacy/technical scope deferred. |
| `OOS-008` | Unverified AI quality guarantee or provider threshold. | Provider and quality decision remains TBD. |
| `OOS-009` | Report 7 and Vietnamese Markdown copies in this English-first package. | Deferred deliverable scope. |

## 5.8 Requirement acceptance checklist

- Product name is **PTE Prep** and the PTE Academic independence boundary is present.
- Only the six approved human roles and External Integration Services appear as actors.
- Registration is separate from package/payment activation.
- The complete 23-task catalog is linked without adding a hidden task type.
- Current/Partial/Planned/Future/Out of scope/TBD wording follows the evidence matrix.
- NFR numbers are targets/baselines until Report 5 supplies measured evidence.
- Retention is contract-based and remains linked to `TBD-RETENTION-001`.
- Out-of-scope boundaries are explicit and do not appear as current features.
- No credentials, private keys, environment values, or personal test data are included.

