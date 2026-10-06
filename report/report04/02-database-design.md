# 2. Database Design

This section maps the original DOCX heading **2. Database Design**. It describes the relational ownership and invariants needed for PTE Prep. It does not invent columns that were not supported by the reviewed source. Detailed table/column migrations remain implementation evidence or TBD items.

## 2.1 Data ownership principles

1. Every organization-owned row carries an organization/tenant ownership path that the owning service checks on read and write.
2. Assignment-owned Proctor and Examiner data carries both the exam/attempt scope and the assigned actor scope.
3. A published or running exam references immutable content/template revisions rather than current mutable drafts.
4. Attempt answers are append/update controlled by attempt/task state and an idempotent client correlation key.
5. Score sources remain separate until Host source selection; the report stores the selected source and provenance.
6. Audit events are append-oriented and reference the action target without copying unnecessary sensitive payloads.
7. Retention classification is contract-based; no universal period is encoded in this document (`TBD-RETENTION-001`).

**Evidence/status:** Entity ownership follows the approved requirement and repository domain inventory (`EVD-FOUNDATION-001`, `EVD-FOUNDATION-003`). Exact schema support is Current only where source/migration evidence confirms it; future relationships are Planned/Future or TBD.

## 2.2 Conceptual entity catalogue

| ID | Entity/concept | Owner | Key relationships | Lifecycle/invariant |
|---|---|---|---|---|
| `DB-ORGANIZATION` | Organization/tenant | `PKG-TENANCY` | Has registrations, users, Students, packages, exams | Only approved organization can operate; tenant ID is required for private data. |
| `DB-REGISTRATION` | Public organization registration | `PKG-TENANCY` | May materialize one organization and first Host | `PENDING`/approved/rejected state; approval is idempotent. |
| `DB-USER` | Account/principal | `PKG-IDENTITY` | Role/membership links, assignments | Account status and role are separate from organization data. |
| `DB-USER-MEMBERSHIP` | User-to-organization role/scope | `PKG-IDENTITY`/`PKG-TENANCY` | User, organization, role | Role must be one approved human role; scope is enforced. |
| `DB-STUDENT` | Organization Student profile | `PKG-TENANCY` | Organization, classes, enrollments, attempts | One organization in this release; duplicates/capacity checked before commit. |
| `DB-PROGRAM` | Organization program | `PKG-TENANCY` | Organization, classes/Students | Active state controls selection. |
| `DB-CLASS` | Organization class | `PKG-TENANCY` | Program, Student membership | Membership changes are explicit/auditable. |
| `DB-REGISTRATION-MEMBERSHIP` | Student/program/class membership | `PKG-TENANCY` | Student, class/program | No duplicate active membership; published audience is independent snapshot. |
| `DB-PACKAGE` | Package definition | `PKG-BILLING` | Subscription/license/order | Platform-controlled version/effective state. |
| `DB-ORDER` | Organization package order | `PKG-BILLING` | Organization, provider correlation | Callback/browser distinction; idempotent status. |
| `DB-SUBSCRIPTION` | Activated organization package/license | `PKG-BILLING` | Organization, package, license, usage | Active/date/limit checked before exam. |
| `DB-QUESTION` | Logical shared question | `PKG-ITEMBANK` | Revisions, task type, media | Logical identity persists across revisions. |
| `DB-QUESTION-REVISION` | Immutable question revision | `PKG-ITEMBANK` | Question, media, Score Template use | Locked exam references do not change. |
| `DB-MEDIA-REFERENCE` | Image/audio metadata/provider reference | `PKG-ITEMBANK`/media boundary | Revision, provider status | Completion/access state and safe renewal. |
| `DB-SCORE-TEMPLATE` | Logical Score Template | `PKG-SCORETEMPLATE` | Revisions, task catalog | Active/retired lifecycle; historical versions remain readable. |
| `DB-SCORE-TEMPLATE-REVISION` | Fixed task/weight/timing/source configuration | `PKG-SCORETEMPLATE` | Task rows, exam version | Version is immutable after exam lock. |
| `DB-EXAM` | Exam/session business aggregate | `PKG-SESSION` | Organization, package, version, audience | Draft/validated/generated/published/open/closed/cancelled states. |
| `DB-EXAM-CANDIDATE-SNAPSHOT` | Frozen audience membership | `PKG-SESSION` | Exam, Student | Changes after publication do not rewrite snapshot. |
| `DB-EXAM-VERSION` | Fixed content/policy snapshot | `PKG-ASSESSMENT` | Exam, revisions, template | Contains provenance/form mode and cannot mutate for active attempt. |
| `DB-EXAM-FORM` | Shared/unique form assignment | `PKG-ASSESSMENT` | Exam version, Student/attempt | Form mode and no-duplicate rule are enforced. |
| `DB-EXAM-STAFF-ASSIGNMENT` | Proctor/Examiner assignment | `PKG-SESSION` | Exam, user, scope | Assignment checked before action. |
| `DB-EXAM-ATTEMPT` | Student delivery instance | `PKG-ATTEMPT` | Student, exam, form, answers | One active/final attempt per policy; state transition explicit. |
| `DB-ATTEMPT-ANSWER` | Task response and sync state | `PKG-ATTEMPT` | Attempt, task/revision | Local correlation/idempotency and accepted/retry/rejected state. |
| `DB-ATTEMPT-HEARTBEAT` | Client liveness/status signal | `PKG-ATTEMPT` | Attempt, time | Does not replace answer acceptance or submission. |
| `DB-SECURITY-EVENT` | Device/lockdown/attempt security event | `PKG-ATTEMPT` | Attempt, policy | Sensitive event is auditable and retention-classified. |
| `DB-PROCTOR-SESSION` | Proctor monitoring session | `PKG-PROCTORING` | Exam, Proctor | Only assigned Proctor; pending/error state allowed. |
| `DB-VIOLATION-EVENT` | Integrity violation/assistance record | `PKG-PROCTORING` | Proctor session, attempt | Actor/time/policy/detail preserved; outcome is policy-driven. |
| `DB-SCORING-ASSIGNMENT` | Examiner work assignment | `PKG-SCORING` | Exam/attempt/answer, Examiner | One active owner unless review policy permits otherwise. |
| `DB-SCORE-SOURCE` | Objective/AI/Examiner result | `PKG-SCORING` | Answer, source, provider/rubric | Source status and provenance retained separately. |
| `DB-SCORE-SELECTION` | Host final source decision | `PKG-REPORTING` | Report/task/section/source | Narrower scope overrides broader only by policy. |
| `DB-REPORT` | Aggregated result/readiness | `PKG-REPORTING` | Attempt, exam version, template | Not visible to Student until published. |
| `DB-PUBLICATION` | Host publication action/state | `PKG-REPORTING` | Report/exam, Host | Idempotent and auditable. |
| `DB-NOTIFICATION` | Notification attempt/status | `PKG-NOTIFICATION` | Source business event, recipient | Failure does not roll back source action. |
| `DB-AUDIT-EVENT` | Sensitive operation audit | Owning package/audit surface | Actor, tenant/assignment, target | Append-oriented, protected, contract-retained. |

## 2.3 Entity relationship model

```mermaid
erDiagram
    ORGANIZATION ||--o{ REGISTRATION : receives
    ORGANIZATION ||--o{ USER_MEMBERSHIP : has
    ORGANIZATION ||--o{ STUDENT : owns
    ORGANIZATION ||--o{ PROGRAM : owns
    PROGRAM ||--o{ CLASS : groups
    CLASS ||--o{ MEMBERSHIP : contains
    STUDENT ||--o{ MEMBERSHIP : joins
    ORGANIZATION ||--o{ SUBSCRIPTION : activates
    SUBSCRIPTION ||--o{ ORDER : supports
    ORGANIZATION ||--o{ EXAM : schedules
    EXAM ||--o{ CANDIDATE_SNAPSHOT : freezes
    STUDENT ||--o{ CANDIDATE_SNAPSHOT : selected
    EXAM ||--|| EXAM_VERSION : locks
    SCORE_TEMPLATE ||--o{ SCORE_TEMPLATE_REVISION : versions
    EXAM_VERSION }o--|| SCORE_TEMPLATE_REVISION : uses
    QUESTION ||--o{ QUESTION_REVISION : versions
    QUESTION_REVISION ||--o{ MEDIA_REFERENCE : attaches
    EXAM_VERSION ||--o{ QUESTION_REVISION : snapshots
    EXAM ||--o{ EXAM_FORM : provides
    EXAM_FORM ||--o{ EXAM_ATTEMPT : starts
    STUDENT ||--o{ EXAM_ATTEMPT : makes
    EXAM_ATTEMPT ||--o{ ATTEMPT_ANSWER : contains
    ATTEMPT_ANSWER ||--o{ SCORE_SOURCE : receives
    EXAM_ATTEMPT ||--|| REPORT : produces
    REPORT ||--o{ SCORE_SELECTION : chooses
    REPORT ||--o{ PUBLICATION : has
    EXAM ||--o{ PROCTOR_SESSION : monitored
    PROCTOR_SESSION ||--o{ VIOLATION_EVENT : records
    EXAM ||--o{ SCORING_ASSIGNMENT : assigns
    SCORING_ASSIGNMENT ||--o{ SCORE_SOURCE : creates
    AUDIT_EVENT }o--|| ORGANIZATION : scoped_to
```

**ERD ID:** `DB-ERD-001`  
**Caption:** PTE Prep organization, fixed exam, attempt, scoring, and publication relationships  
**Status:** Planned/Future conceptual design; exact columns and migrations require source/schema evidence.  
**Evidence/source:** `EVD-FOUNDATION-003`, `EVD-FOUNDATION-005`.  
**Related Report 3 IDs:** `FR-EXAM-004`, `FR-EXAM-009`, `FR-DELIVERY-005`–`FR-DELIVERY-008`, `FR-SCORE-007`, `FR-REPORT-003`–`FR-REPORT-005`, `NFR-09`, `NFR-13`.

## 2.4 Fixed-version and provenance invariants

### `DB-INV-001` — Exam version immutability

Once a published exam has a generated version or an attempt has started, the version cannot be changed in place. A correction creates a new draft/version according to the lifecycle policy.

### `DB-INV-002` — Revision provenance

Each fixed task stores or references the logical question, question revision, media reference/revision, Score Template revision, and effective policy used for delivery. The current question-bank row is not enough to reconstruct an old attempt.

### `DB-INV-003` — Audience snapshot

The exam stores the Student set used for publication. Later class/program membership changes do not add/remove a Student from the published exam automatically.

### `DB-INV-004` — Form uniqueness

The selected form policy is stored for the exam. A form cannot contain the same question revision twice under the current business rule. Unique per-Student assignments use the exam/form/Student key to prevent duplicate assignment.

### `DB-INV-005` — Attempt state

An attempt moves through explicit states such as eligible, in progress, submitting, submitted, scored/pending, published/closed according to the approved state model. An invalid transition is rejected with a business message.

### `DB-INV-006` — Answer correlation

An answer includes task identity, attempt identity, client correlation/idempotency key, local/server sync state, and accepted/rejected reason where applicable. A repeated request returns the existing accepted/rejected outcome.

### `DB-INV-007` — Score-source separation

Objective, AI, and Examiner results are stored as separate source records. Host selection creates/updates a separate selection decision; it does not erase unselected source history.

### `DB-INV-008` — Publication gate

Publication requires required score sources and source-selection conditions to be ready. A report may exist in pending/draft form but is not Student-visible until a publication record exists.

## 2.5 Keys, uniqueness, and query needs

The following logical constraints are required even when physical names differ:

| Constraint | Purpose | Failure message |
|---|---|---|
| Organization name/code uniqueness within platform policy | Prevent duplicate tenant identity. | Organization already exists or needs review. |
| User/Student identity uniqueness within organization policy | Prevent duplicate roster entries. | Student matches an existing record. |
| Active membership uniqueness | Prevent duplicate class/program membership. | Student is already assigned. |
| Order/provider correlation uniqueness | Prevent duplicate payment activation. | Payment result was already processed. |
| License redemption uniqueness | Prevent code reuse. | License code is unavailable/already used. |
| Exam/package overlap constraint | Enforce same-license schedule policy. | Exam time conflicts with an existing package use. |
| Exam candidate uniqueness | Prevent repeated Student in one audience. | Candidate was listed more than once. |
| Exam version one-to-one lock | Make fixed snapshot explainable. | Exam version is already locked. |
| Attempt/exam/Student policy uniqueness | Prevent unauthorized duplicate attempt. | An attempt already exists or retake is not allowed. |
| Answer/attempt/task/correlation idempotency | Prevent duplicate accepted answer. | Answer was already accepted or rejected. |
| Active scoring assignment uniqueness | Avoid conflicting Examiner ownership. | Answer is assigned to another Examiner. |
| Report/publication idempotency | Prevent duplicate publication. | Report already has the requested publication state. |

Large roster, candidate, queue, report, and audit queries must be paginated or bounded. The query boundary must carry organization/assignment scope and must not expose the entire table by default (`NFR-04`, `NFR-09`).

## 2.6 Lifecycle and retention classification

| Data family | Active use | Historical use | Retention statement |
|---|---|---|---|
| Registration/account | Onboarding/access | Decision/support audit | Contract and platform policy; do not retain secrets in notes. |
| Questions/media/revisions | Content/exam generation | Fixed-version provenance | Retain revisions needed to explain locked exams; provider media deletion policy is TBD. |
| Package/order/subscription | Activation/limits | Billing/audit | Contract and payment record policy; provider payload minimization. |
| Exam/version/audience | Scheduling/delivery | Report/provenance | Retain according to organization contract. |
| Answers/audio/attempt state | Delivery/scoring | Review/report | Contract-based retention; local client recovery has separate device risk. |
| Scores/reports/publication | Review/Student visibility | Audit/export | Contract-based retention; exact period and legal hold TBD. |
| Proctor/Examiner/audit events | Integrity/scoring/publication | Investigation | Contract-based retention; append/tamper evidence policy TBD. |

`TBD-RETENTION-001` is a blocking policy decision before a production data-lifecycle guide can promise a universal deletion date. The database design must support future deletion/export/legal hold without weakening the fixed-version/report provenance requirement.

## 2.7 Data protection rules

- Do not store provider credentials, tokens, or passwords in business tables.
- Mask Student identity, audio, answers, and reports in test fixtures and screenshots.
- Keep raw provider payloads only when the contract and data policy permit, and minimize fields otherwise.
- Restrict audit access separately from ordinary Host/Student views.
- Include time zone/offset meaning for exam scheduling and audit timestamps.
- Treat local client answer storage as sensitive and document device cleanup/recovery boundaries.

