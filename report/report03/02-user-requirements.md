# 2. User Requirements

This section maps the original DOCX heading **2. User Requirements**. It describes what each approved actor needs to accomplish, what information may be seen or changed, and how the main and alternate flows behave. Detailed requirement IDs are defined in Sections 3–5.

## 2.1 Actor responsibilities and working context

### 2.1.1 Platform Admin

The Platform Admin operates the platform as a whole. The role reviews organization registrations, approves or rejects onboarding, supports controlled account recovery, governs shared questions/media and Score Templates, manages package definitions, reviews platform audit information, and handles exceptional integration or publication states.

- **Channel:** platform administration portal.
- **Expected knowledge:** organization operations, content approval, package and audit policy; no programming knowledge is required.
- **Data scope:** platform-wide administrative data, with sensitive Student answers and reports shown only when an authorized operational or audit purpose exists.
- **Can change:** organization approval state, shared content approval/publication, package state, controlled account support actions, and platform configuration permitted by policy.
- **Cannot claim:** official PTE Academic authority, a Student’s personal identity, or a score that has not passed the scoring/publication rules.
- **User need:** every consequential action should show the affected organization/content/package, the resulting status, and an audit reference.

### 2.1.2 Platform Author

The Platform Author prepares shared question, image/audio media, task-type, and Score Template drafts. The role needs preview and validation feedback, revision history, and a clear submission-to-approval status. The Platform Author cannot publish or activate shared content alone.

- **Channel:** platform administration portal.
- **Expected knowledge:** PTE-style task content and rubric preparation.
- **Data scope:** shared drafts and revisions assigned to the author.
- **Can change:** draft content, media references, task metadata, and draft scoring configuration.
- **Cannot change:** a locked exam snapshot, another organization’s operational data, or the final publication state without Platform Admin approval.
- **User need:** missing media, invalid task structure, and incomplete scoring information must be visible before submission.

### 2.1.3 Host

The Host operates one organization. The role activates packages after the organization has been approved, creates/imports Students, manages programs and classes, assigns Proctors and Examiners, prepares and schedules exams, reviews score sources, publishes reports, and inspects organization audit history.

- **Channel:** organization web portal.
- **Expected knowledge:** organization and exam operations; no database or code knowledge is required.
- **Data scope:** one organization’s Students, classes, exams, assignments, subscriptions, scores, reports, and audit entries.
- **Can change:** organization-owned operational records while their lifecycle permits it.
- **Cannot change:** the shared question bank or common Score Template rules directly; another organization’s data; a Student’s answer as if the Student had submitted it.
- **User need:** validation results must explain which Student, package, content, timing, assignment, or score condition blocks an action.

### 2.1.4 Proctor

The Proctor monitors an assigned exam. The role observes Student and attempt states, gives permitted assistance, records violations, and follows the configured practice or mock-exam policy. The Proctor does not publish a report, change packages, or score an Examiner queue.

- **Channel:** assigned monitoring workspace.
- **Expected knowledge:** exam procedure, permitted assistance, and violation handling.
- **Data scope:** assigned exams, assigned Students/attempts, monitor status, assistance events, and violation records.
- **Can change:** permitted monitoring actions and violation records for assigned exams.
- **Cannot change:** shared content, package ownership, final score source, or another Proctor’s unassigned session.
- **User need:** status must not rely on color alone; each violation or warning needs a time, affected attempt, severity/policy, and next action.

### 2.1.5 Examiner

The Examiner scores answers assigned by a Host. The role needs a queue, prompt and response context, the applicable rubric, a draft/submitted state, and a way to request correction or reassignment when the answer is not scoreable.

- **Channel:** assigned scoring workspace.
- **Expected knowledge:** the organization’s approved scoring rubric for the task.
- **Data scope:** assigned answers, prompt/media revision, rubric, score drafts/submissions, and review messages.
- **Can change:** scores for assigned work until the configured submission state.
- **Cannot change:** a Host’s final score-source decision, a Student’s answer, publication state, or another Examiner’s unassigned work.
- **User need:** a submitted score must show who submitted it, when, which rubric version was used, and whether Host review is pending.

### 2.1.6 Student

The Student completes an assigned exam using the Windows-first client. The Student must see only eligible assigned exams, pass the device check, follow timed task windows, receive clear save/synchronization state, submit once according to policy, and view only a published own report.

- **Channel:** Windows-first exam client and published result view.
- **Expected knowledge:** basic computer use and the exam instructions supplied by the organization.
- **Data scope:** own assigned exam, own answers, own attempt state, own device-check state, and own published report.
- **Can change:** own answer while the task and attempt are open; retryable synchronization state is managed by the client/system.
- **Cannot change:** exam content, timing policy, score source, publication, another Student’s data, or a submitted answer unless an approved recovery policy explicitly permits it.
- **User need:** the client must explain whether an answer is locally saved, queued, synchronized, rejected, or awaiting retry.

### 2.1.7 External Integration Services

External Integration Services represents controlled boundaries for payment, media storage, AI scoring, email/notification, and other approved services. It is not a human account. Each integration receives only the data needed for its contract and must expose success, pending, retry, duplicate, or failure status without creating a second business result.

## 2.2 Access, ownership, and visibility requirements

1. A person may hold one or more of the six approved human roles only when assigned by the platform’s authorization rules.
2. Platform Admin is platform-wide; Platform Author is content-authoring scoped; Host is organization-scoped; Proctor and Examiner are assignment-scoped; Student is own-attempt/report scoped.
3. External Integration Services has no interactive workspace and no permission to administer PTE Prep data.
4. A registration in `PENDING` or `REJECTED` state cannot open an active organization workspace.
5. A Student belongs to one organization in this release. Cross-organization Student identity is outside scope.
6. A published report contains only data that the viewer is allowed to see. Student report visibility starts only after Host publication.
7. Important changes to permission, package, enrollment, exam policy, scoring approval, publication, and violation records must be traceable to actor, time, affected record, and outcome.

**Status/evidence:** These are approved requirement constraints supported by `EVD-FOUNDATION-001` and `EVD-FOUNDATION-002` (verified 2026-10-06). Implementation completeness is assessed by Report 5.

## 2.3 Main user journeys

### Main journey A — Organization onboarding and activation

Organization registrant submits required details → Platform Admin reviews the registration → Platform Admin approves or rejects with a reason → approved organization and first Host are created → Host signs in → Host activates or redeems an organization package → organization workspace is ready.

Alternate paths:

- incomplete registration returns a correction message and does not create an active workspace;
- rejected registration remains non-operational and can be reviewed by an authorized Platform Admin;
- payment or license activation failure leaves the organization approved but package-inactive;
- password reset is controlled by Platform Admin support rules and does not change organization ownership.

### Main journey B — Content and Score Template preparation

Platform Author creates a draft → attaches required image/audio media → validates task fields → submits for approval → Platform Admin reviews → approves and publishes or rejects with reason → active content/Score Template becomes selectable for an eligible exam.

Alternate paths:

- missing media blocks submission/publication;
- a published revision is edited as a new revision;
- a retired template remains referenced by locked historical exams but is unavailable for new exams;
- an external media service failure leaves a retryable media state.

### Main journey C — Student, class, and staff management

Host creates/imports Students → resolves duplicates and missing data → creates programs/classes → assigns Students → assigns Proctors/Examiners with the required scope → roster is ready for exam selection.

Alternate paths:

- an invalid row in a bulk import is reported without silently creating a partial Student;
- a Student already enrolled or scheduled is shown as a conflict;
- a class transfer is recorded and does not rewrite a published exam audience.

### Main journey D — Exam creation and scheduling

Host creates a draft → selects active Score Template/package/mode/policy → selects Students, classes, or programs → system removes or explains duplicates → system checks capacity, package dates, content completeness, and schedule conflicts → system generates fixed forms/version → Host publishes and schedules → eligible Students can enter when the exam opens.

Alternate paths:

- a failed validation keeps the exam in draft and identifies each blocking condition;
- a generation interruption leaves a generation-error/pending state that can be safely retried or cancelled;
- after publication lock, roster/content/policy changes are not silently applied to the running exam;
- shared-license time overlap is rejected according to package rules.

### Main journey E — Student delivery and answer recovery

Student signs in → opens an assigned eligible exam → completes device check → performs timed PTE-style tasks → client saves each answer locally → client synchronizes or queues an answer → client retries after connectivity recovery → Student submits the attempt → final state is acknowledged.

Alternate paths:

- device or microphone failure blocks or warns before timed work according to policy;
- an answer rejected by the server remains visible with a reason and a retry path;
- duplicate submission is idempotent or rejected with a clear final-state message;
- Proctor may perform an allowed intervention; the intervention is auditable.

### Main journey F — Proctoring and integrity

Host assigns Proctor → Proctor opens the assigned monitoring workspace → observes Student/attempt state → assists or warns according to exam mode → records a violation if needed → system preserves the event and audit context → attempt continues or is closed only when policy permits.

Practice violations in the first release warn and audit rather than automatically invalidating an attempt. Strict behavior is policy-dependent and must be explicit in the fixed attempt policy. Advanced virtual-machine detection, screen recording, and secondary-device blocking are out of scope.

### Main journey G — Scoring and report publication

Student submits → objective tasks are scored where supported → AI and/or Examiner scores are received where configured → Host reviews available sources → Host selects the permitted final source → system checks report readiness → Host publishes → Student views the own published report.

Alternate paths:

- a pending or failed external score remains pending/failed and does not become a fake zero or fake pass;
- an Examiner score is not final until Host review;
- missing required scores block publication and identify the missing source;
- a notification failure does not roll back a successful publication.

## 2.4 Use cases

Each use case below has a stable ID, a primary actor, preconditions, main flow, alternate/error flow, and result. Detailed FR/BR links are provided so that a later design or test document can trace the business intent.

#### UC-ONBOARD-001 — Submit and review organization registration

| Item | Requirement |
|---|---|
| Primary actor | Organization registrant before Host account creation; Platform Admin reviews. |
| Preconditions | Public registration is available; required organization and contact information is known. |
| Main flow | Submit registration → validate required fields and duplicate organization information → store `PENDING` request → Platform Admin opens request → approves or rejects with reason. |
| Alternate/error flow | Missing/duplicate data returns correction feedback; rejected request remains non-operational; repeated review does not create a second organization. |
| Result | Approved request creates an organization and first Host account, or rejected request remains outside the active workspace. |
| Related IDs | `FR-ONBOARD-001`–`FR-ONBOARD-004`, `BR-ACCESS-007`–`BR-ACCESS-008`, `NFR-SEC-001`. |

#### UC-ACCESS-001 — Sign in and maintain a safe session

| Item | Requirement |
|---|---|
| Primary actor | Any approved human role. |
| Preconditions | Account is active and belongs to an approved organization/platform scope. |
| Main flow | Enter credentials → verify account/organization status → create session → display role-appropriate workspace → renew or end session safely. |
| Alternate/error flow | Invalid credentials are throttled; locked/suspended account cannot perform business actions; expired session requires sign-in again; controlled password reset follows support policy. |
| Result | The user sees only authorized navigation and data. |
| Related IDs | `FR-ACCESS-001`–`FR-ACCESS-004`, `BR-ACCESS-001`–`BR-ACCESS-006`, `NFR-SEC-001`–`NFR-SEC-003`. |

#### UC-CONTENT-001 — Prepare and approve shared question content

| Item | Requirement |
|---|---|
| Primary actor | Platform Author; Platform Admin approves. |
| Preconditions | Author has content scope; task type and required media rules are known. |
| Main flow | Create draft → enter prompt/task fields → attach media → validate → submit → Platform Admin reviews → approve/publish or reject with reason. |
| Alternate/error flow | Invalid task fields or missing media block submission; media link expiration requests a new signed link; published content is revised rather than overwritten. |
| Result | A published revision is available to an active Score Template, or a reasoned rejection remains visible. |
| Related IDs | `FR-CONTENT-001`–`FR-CONTENT-005`, `BR-CONTENT-012`–`BR-CONTENT-016`, `NFR-DATA-003`. |

#### UC-TEMPLATE-001 — Approve and activate a Score Template

| Item | Requirement |
|---|---|
| Primary actor | Platform Author prepares; Platform Admin activates. |
| Preconditions | Task catalog, weights, timing, score sources, and required content rules are available. |
| Main flow | Create draft → select task rows from the 23-task catalog → define sections/timing/weights/source eligibility → validate → approve → activate. |
| Alternate/error flow | Invalid weight/timing/task combination remains draft; retirement prevents new selection but does not rewrite locked exams. |
| Result | Host can select the active version; a locked exam retains the selected version. |
| Related IDs | `FR-TEMPLATE-001`–`FR-TEMPLATE-004`, `BR-CONTENT-014`–`BR-CONTENT-016`, `NFR-REQ-002`. |

#### UC-ROSTER-001 — Manage Students, classes, and enrollment

| Item | Requirement |
|---|---|
| Primary actor | Host. |
| Preconditions | Organization is approved and Host session is active. |
| Main flow | Create/import Students → validate duplicates and limits → create programs/classes → assign Students → search/filter/paginate roster → select Students for an exam. |
| Alternate/error flow | Invalid import rows return row-level reasons; duplicates are not silently created; class/program changes after exam publication do not change the frozen audience. |
| Result | Organization roster and exam candidate list are consistent and auditable. |
| Related IDs | `FR-ORG-001`–`FR-ORG-006`, `FR-ENROLL-001`–`FR-ENROLL-004`, `BR-ACCESS-009`–`BR-ACCESS-011`, `BR-EXAM-024`–`BR-EXAM-027`. |

#### UC-PACKAGE-001 — Activate an organization package

| Item | Requirement |
|---|---|
| Primary actor | Host; Platform Admin and External Integration Services support the flow. |
| Preconditions | Organization has been approved; an eligible package or license code exists. |
| Main flow | Host views package options/status → creates order or enters a license code → system validates callback/code → creates one subscription/license record → displays limits and dates. |
| Alternate/error flow | Browser return without verified callback is not payment proof; duplicate callback/code does not create a second subscription; expired/revoked package cannot enable a new exam. |
| Result | Package state and limit are visible to Host; Student is never the package owner or payer in this model. |
| Related IDs | `FR-PACKAGE-001`–`FR-PACKAGE-006`, `BR-PACKAGE-017`–`BR-PACKAGE-022`, `NFR-INT-001`. |

#### UC-EXAM-001 — Create, validate, generate, and schedule an exam

| Item | Requirement |
|---|---|
| Primary actor | Host. |
| Preconditions | Active Score Template/content and usable package are available; roster exists. |
| Main flow | Create draft → select template/package/mode/policy/date → select Students/class/program → deduplicate → validate → generate fixed form/version → publish/schedule. |
| Alternate/error flow | Capacity/date/content/conflict errors block publication; generation interruption is retryable or cancellable; a published exam is locked against unsafe changes. |
| Result | A scheduled exam has a fixed audience, content, scoring policy, form mode, and audit trail. |
| Related IDs | `FR-EXAM-001`–`FR-EXAM-009`, `BR-EXAM-023`–`BR-EXAM-029`, `NFR-PERF-004`, `NFR-DATA-004`. |

#### UC-DELIVERY-001 — Complete and submit a Student attempt

| Item | Requirement |
|---|---|
| Primary actor | Student; Proctor may assist within assignment scope. |
| Preconditions | Exam is published/open, Student is assigned and eligible, client/device check is ready. |
| Main flow | Sign in → open eligible exam → device check → receive fixed task/prompt → answer within timer → save locally → synchronize/retry → submit → receive final state. |
| Alternate/error flow | Device failure, offline state, rejected answer, timer expiry, or duplicate submission is shown with a safe recovery path; no silent answer loss. |
| Result | Attempt is submitted once according to policy and is available for scoring. |
| Related IDs | `FR-DELIVERY-001`–`FR-DELIVERY-009`, `BR-DELIVERY-030`–`BR-DELIVERY-034`, `NFR-PERF-001`–`NFR-PERF-003`, `NFR-SEC-004`. |

#### UC-PROCTOR-001 — Monitor and record an integrity event

| Item | Requirement |
|---|---|
| Primary actor | Proctor; Host owns exam policy. |
| Preconditions | Proctor is assigned to the exam and monitoring session is authorized. |
| Main flow | Open assigned session → view Student/attempt status → assist or warn → record violation with type/severity/detail → preserve audit state. |
| Alternate/error flow | Unassigned Proctor is denied; connectivity interruption leaves pending/error state; practice policy warns/audits without automatic invalidation in the initial release. |
| Result | The event is attached to the correct exam/attempt and is visible to authorized reviewers. |
| Related IDs | `FR-INTEGRITY-001`–`FR-INTEGRITY-005`, `BR-INTEGRITY-035`, `BR-INTEGRITY-039`, `NFR-SEC-005`. |

#### UC-SCORING-001 — Assign, score, review, and publish

| Item | Requirement |
|---|---|
| Primary actor | Host assigns/reviews/publishes; Examiner scores; External Integration Services may provide an eligible score. |
| Preconditions | Attempt is submitted; required objective/AI/Examiner path is configured. |
| Main flow | Host selects assignment pool → Examiner opens assigned queue → submits score → system keeps source/version → Host compares allowed sources → selects final source → readiness check → publishes report. |
| Alternate/error flow | Missing/pending/failed score blocks publication; duplicate scoring/submission is idempotent or rejected; notification failure does not undo publication. |
| Result | Report is traceable to task, revision, Score Template, source, and publication actor; Student sees own report only after publication. |
| Related IDs | `FR-SCORE-001`–`FR-SCORE-007`, `FR-REPORT-001`–`FR-REPORT-005`, `BR-SCORE-036`–`BR-SCORE-038`, `BR-REPORT-040`–`BR-REPORT-043`, `NFR-AUDIT-001`. |

#### UC-INTEGRATION-001 — Handle an external service result

| Item | Requirement |
|---|---|
| Primary actor | External Integration Services; Platform/Host/Student observes the result. |
| Preconditions | A business action has created a provider request with a safe correlation key. |
| Main flow | Send or receive signed/authorized request → validate correlation and status → persist outcome → update business state once → expose user-readable status. |
| Alternate/error flow | Timeout, duplicate callback, expired media link, provider rejection, or AI failure becomes retryable/pending/failed; it cannot duplicate activation, score, exam, or report. |
| Result | Business state is consistent and the next operator action is visible. |
| Related IDs | `FR-INTEGRATION-001`–`FR-INTEGRATION-006`, `BR-INTEGRATION-044`–`BR-INTEGRATION-048`, `NFR-INT-001`–`NFR-INT-004`. |

## 2.5 User-facing error and recovery expectations

The system should explain the problem in business language, identify the affected object, and offer the next permitted action. Examples include:

| Situation | User-facing expectation | Recovery owner |
|---|---|---|
| Registration incomplete | Show missing/invalid fields and keep the request non-active. | Registrant or Platform Admin |
| Package not active/expired | Explain that registration and package activation are separate; do not create a new exam. | Host / Platform Admin |
| Candidate duplicate/conflict | Identify the Student and conflict reason before enrollment. | Host |
| Missing question/media | Identify the task/content item and keep exam/content unpublished. | Platform Author / Platform Admin / Host |
| Generation interrupted | Show pending/error status and allow safe retry/cancel; never publish partial forms. | Host / Platform support |
| Device/audio check failure | Show the device item and permitted correction before timed work. | Student / Proctor / Host |
| Answer not synchronized | Show local save and retry state; do not say “submitted” until accepted. | Student / exam client / support |
| Examiner/AI score pending or failed | Keep source state visible and block publication when required. | Examiner / Host / Platform support |
| Report not visible | Explain whether scores are incomplete or publication is not done. | Host |
| Integration failure | Show pending/error/correlation state without rolling back unrelated success. | Platform support / provider owner |

## 2.6 Requirements traceability summary

| User concern | Use cases | Report 3 requirement area | Later evidence |
|---|---|---|---|
| Safe onboarding and access | `UC-ONBOARD-001`, `UC-ACCESS-001` | `FR-ONBOARD-*`, `FR-ACCESS-*` | Report 4 authorization design; Report 5 security cases; Report 6 access workflow |
| Trusted shared content | `UC-CONTENT-001`, `UC-TEMPLATE-001` | `FR-CONTENT-*`, `FR-TEMPLATE-*` | Content revision and publication tests |
| Reliable roster and package use | `UC-ROSTER-001`, `UC-PACKAGE-001` | `FR-ORG-*`, `FR-ENROLL-*`, `FR-PACKAGE-*` | Tenant/limit/conflict tests |
| Reproducible exam | `UC-EXAM-001` | `FR-EXAM-*` | Fixed-version design, generation tests, Host guide |
| Safe timed delivery | `UC-DELIVERY-001` | `FR-DELIVERY-*` | Client sequence, retry/recovery cases, Student guide |
| Controlled integrity | `UC-PROCTOR-001` | `FR-INTEGRITY-*` | Proctor design and audit tests |
| Correct score publication | `UC-SCORING-001` | `FR-SCORE-*`, `FR-REPORT-*` | Scoring/publication cases and Host/Student guide |
| Resilient dependencies | `UC-INTEGRATION-001` | `FR-INTEGRATION-*` | Integration failure tests and troubleshooting |

