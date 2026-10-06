# Brainstorm: PTE Org SRS

Date: 2026-09-27  
Slug: `pte-org-srs`  
Status: Brainstorm complete; ready for the specification phase

## Topic

"hãy đọc các thông tin chi tiết của dự án, để nắm đầy đủ nghiệp vụ hiện có cũng như là tượng lai nên có của dự án nay"

The normalized topic is a complete software requirements baseline for PTE Org: a platform that lets organizations manage learners and PTE examinations, while platform staff manage shared content, scoring rules, plans and the overall service.

## Domain / Scale

- **Domain:** Education technology, organization-based exam management and PTE assessment.
- **Business model:** B2B. The customer is an organization. A student does not buy a personal package from the platform.
- **Scale:** Production-oriented product currently operated on a single hosted stack, with a target of supporting bursty examination periods and about 1,000 active attempts.
- **Primary channels:** Organization web portal, platform administration portal and a Windows-first exam client.

## Evidence and interpretation rules

The current source code is the reference for what already exists. ADRs, plans and earlier brainstorms are used to identify intended future behavior. Some older plans describe a feature as planned even though the current branch already contains part of it; those features are marked **partial** rather than being claimed as complete.

The SRS will use plain business language. Technical names may appear in a glossary or a technical appendix, but the main requirements will describe people, actions, information and outcomes. For example:

- `Tenant` is written as **organization using the platform**.
- `Session` is written as **exam** or **exam sitting**.
- `Attempt` is written as **student attempt** or **student answer sheet**.
- `Audience` is written as **student list**.
- `Preflight` is written as **pre-exam validation**.
- `Snapshot` is written as **the fixed version of an exam**.

## Actors

### [ACTOR] Platform Admin

The global platform administrator. This actor can read and change platform-wide information, approve or reject organization onboarding, manage plans and license codes, approve and publish shared questions, activate scoring templates, manage platform settings and review audit records.

**Access level:** global administration; read/write/approve.

### [ACTOR] Platform Author

The person who creates and maintains shared PTE questions, question revisions and scoring-template drafts. This actor can submit content for approval but cannot activate production content without Platform Admin approval.

**Access level:** global content authoring; read/write drafts, submit for approval; no production activation.

### [ACTOR] Host

The administrator of an organization using the platform. This actor manages the organization, students, programs, classes, exam staff, billing, exam setup, student enrollment, scoring review and report publication for that organization.

**Access level:** organization-scoped read/write; no access to another organization and no direct editing of the shared question bank.

### [ACTOR] Proctor

The person who supervises an assigned exam. This actor can view the status of assigned students, record or review violations and perform permitted assistance actions for the assigned exam.

**Access level:** assigned-exam read/operate; no global administration and no access to unrelated exams.

### [ACTOR] Examiner

The person who scores assigned student answers, especially answers that require human review. This actor can view assigned work and submit scores, but does not publish the final student report.

**Access level:** assigned-attempt read/score; no final publication authority.

### [ACTOR] Student

The learner who takes an exam. This actor can start an eligible exam, answer tasks, save and submit answers, resume when allowed and view a report after the Host publishes it.

**Access level:** own-attempt read/write; own published reports only.

### [INTEGRATION ACTOR] External Integration Services

Services outside the core platform boundary that exchange controlled information with it. The initial group includes the PayOS payment service, Cloudinary media storage, an AI scoring provider, email/notification delivery and other approved integration endpoints.

**Access level:** limited service-to-service actions through authenticated requests or signed callbacks; no general user administration.

The initial integration boundaries are:

- **PayOS:** receives payment-order requests and sends payment confirmation callbacks. It does not receive the platform's user administration data.
- **Cloudinary:** receives signed media-upload requests and returns media status or preview information. It does not decide whether a question is publishable.
- **AI scoring provider:** receives eligible answer material and returns a score or a failure status. It does not publish a student report.
- **Email and notification delivery:** receives a prepared message and delivery destination. It does not change exam or billing records.

These services are integration actors, not user roles. The six human roles above are the only user roles in this SRS.

The onboarding applicant is treated as the pre-tenant state of **Host**, not as an additional actor. Lecturer, Program Coordinator, Tenant Owner and similar roles are not separate actors in this SRS.

## Confirmed Features (IN Scope)

All feature groups below are included in the SRS. Each item is classified so the SRS can distinguish current behavior from the agreed future direction.

### 1. Account and organization onboarding — current/partial

- Public organization registration.
- Platform Admin review, approval and rejection.
- Creation of an organization and its first Host account after approval.
- Login, logout, token renewal, password change and administrator-assisted password reset.
- Organization status, branding and organization-level access checks.

### 2. Organization, learners and enrollment — current/partial

- Organization, program and class management.
- Student creation, bulk import, roster search, filtering and pagination.
- Student membership and transfer operations; class merge and split operations.
- Exam enrollment by student, class or program.
- Student capacity checks and conflict-aware enrollment.

### 3. Shared question bank and media — current/partial

- Platform question creation, editing, revision, approval, publication, archive and recovery.
- PTE task-type catalog and task capability information.
- Image and audio media upload through a controlled media service.
- Publication checks that prevent incomplete media from being used.
- Shared question content is platform-owned; Host does not create a private production bank.

### 4. Scoring and task templates — current/partial

- Scoring templates with skill weights, task counts, timing and AI eligibility.
- Template draft, approval, activation and retirement lifecycle.
- Versioned task behavior and delivery information.
- A published exam keeps the scoring rules that were valid when it was created.

### 5. Plans, payments and limits — current/partial

- Plan catalog for exam packages and student-capacity additions.
- PayOS order and payment callback handling.
- License-code issue, redeem and revoke flows.
- Organization subscriptions, license keys and expiration windows.
- Organization-wide student limit and per-exam student limit.
- Payment and license activation must use one consistent activation rule.

### 6. Exam setup and scheduling — current/partial

- Exam draft creation and editing.
- Template, package, policy, date and capacity selection.
- Student-list sources from individual students, classes and programs.
- Student-list preview and duplicate removal.
- Pre-exam validation for missing questions, capacity, package dates and conflicts.
- Exam generation, publication, opening, closing and cancellation.
- Practice, Mock Test and Official Exam policies.
- Fixed exam content after publication/opening according to the exam lifecycle.

### 7. Student exam delivery — current/partial

- Student login and eligible-exam entry.
- Windows-first Flutter exam client.
- The 23 PTE task types represented by the current product direction: 22 scored types and Personal Introduction as an unscored type.
- Per-task preparation and response timing.
- Local-first answer saving and retry after connectivity loss.
- Text, audio and image task delivery.
- Normal and protected answer submission paths.
- Heartbeat and recovery behavior while an attempt is in progress.
- Student report access after publication.

### 8. Proctoring and exam integrity — current/partial/future

- Proctor assignment to an exam.
- Student and attempt status monitoring.
- Violation recording and audit visibility.
- Exam policy for unrestricted Practice, controlled Practice and strict Official delivery.
- Windows fullscreen, shortcut, clipboard and related controls where the selected policy requires them.
- Future improvements for reliable audit delivery and stronger integrity controls.

### 9. Examiner work and score review — current/partial

- Examiner assignment by exam and student-attempt pool.
- Examiner work queue and answer scoring.
- Host review of automated and examiner scores.
- Selection of the score source by task, section or group of answers.
- Blocking report publication until required scores and source decisions are complete.

### 10. Reports, publication and audit — current/partial

- Objective, automated and examiner score aggregation.
- PTE-style overall and skill results on the 10–90 scale where the selected skills support them.
- Host-controlled report publication.
- Student result viewing after publication.
- Organization audit log for important changes and privileged actions.
- Notifications for supported enrollment, application, credentials, violation, cancellation and result-publication events. Payment and conflict notifications remain future work unless added to the notification catalog.

### 11. External integrations — current/partial

- PayOS payment order and callback integration.
- Cloudinary media upload and preview integration.
- AI scoring provider abstraction and asynchronous scoring work.
- Email/notification delivery.
- Controlled retry and duplicate-callback handling.

### 12. Exam generation and platform hardening — current/partial/future

- **Already present in the current source:** deterministic generation inputs, a saved generation seed, algorithm version, form mode, form assignment, idempotent generation requests and a generation-status record.
- **Already present in the current source:** shared-form and one-form-per-student modes, with Practice and non-Practice defaults.
- **Already present in the current source:** exam-series reuse rules and schedule-conflict checks in the audience preview and publication gate.
- **Still being completed:** larger-audience background processing, clearer progress and failure recovery, stronger score and question provenance, and operator-level observability.
- **Future hardening:** database-level tenant isolation, better burst handling, backup and recovery, complete pre-exam transition screens, and real AI scoring providers.

## OUT of Scope

- Student self-service payment or personal student packages.
- Cross-organization student identity or membership.
- Host-owned private question banks and Host publication of shared questions.
- Reusable multi-sitting exam definitions in the first SRS release.
- Adaptive testing, IRT selection and official certification results.
- A permanent no-repeat rule across all exams, organizations or forms.
- A mobile delivery redesign; the first delivery target remains Windows desktop.
- Replacing Cloudinary or adding a new media provider in this release.
- Separate actors for Lecturer, Program Coordinator, Applicant or Tenant Owner.
- Advanced anti-cheat such as virtual-machine detection, screen recording detection or automatic invalidation of every Practice violation.

## Technical Constraints

### Existing product structure

- One backend application is divided into clearly named business areas instead of many independently deployed backends.
- The backend uses Java and Spring Boot. PostgreSQL stores business data; Redis supports short-lived shared state; RabbitMQ handles background work.
- Tenant and vendor portals use Next.js and React.
- The exam client uses Flutter and targets Windows first.
- Public traffic enters through Nginx. The application uses versioned paths beginning with `/api/v1`.

### Deployment and operations

- The current hosted stack runs in Docker on one Oracle VPS.
- The SRS describes a path to additional application copies and better queue handling, but does not introduce Kubernetes or a new deployment platform.
- All stored times use UTC; the user interface converts times for the person viewing them.
- Secrets, private keys and environment values are not part of the SRS or source documentation.

### Data access and isolation

- Platform Admin can work across organizations.
- Host, Proctor, Examiner and Student are restricted to their organization or assignment.
- The current application checks the organization on every relevant read and write. Database-level isolation is a future hardening layer, not a claim about the current deployment.

### Integration constraints

- PayOS is the payment confirmation source; a browser return page is not treated as payment proof.
- Cloudinary receives media through signed upload parameters.
- AI scoring and notifications may finish after the original request, so the product must show an understandable pending or failed state.
- External callbacks and background retries must not create a second payment, score, report or media record.

## Business Rules

### Access and ownership

1. Every user has one or more of the six approved human roles, and every protected action checks both the role and the organization or assignment. External integration services are not user roles.
2. Platform Admin is the only actor with global administrative authority.
3. Platform Author may submit content for approval but cannot activate it for production use.
4. Host can manage only its own organization and cannot directly alter shared published questions.
5. Proctor and Examiner can work only with exams or attempts assigned to them.
6. Student can read or change only their own in-progress attempt and published result.

### Onboarding and organization data

1. An organization becomes active only after Platform Admin approval.
2. A rejected or pending organization must not appear as an active workspace.
3. Student accounts belong to one organization in the current product model.
4. Student creation and import must respect the organization student limit.
5. An active class membership cannot be silently duplicated; transfer and removal must be explicit and auditable.

### Question bank and templates

1. A question must pass its required content and media checks before publication.
2. Editing a published question creates a new revision; an already published exam keeps its existing revision.
3. A scoring template must be active before a Host can use it for a new exam.
4. A Host chooses an active template but cannot change its shared scoring definition.
5. Exam content and scoring rules are fixed for students after the exam reaches its publication lock point.

### Billing and limits

1. Student never pays the platform directly.
2. An exam package creates an independent exam license; different licenses may be used at the same time.
3. An exam license can be used only while active and within its allowed dates.
4. An exam cannot exceed the student capacity attached to its license.
5. A license code can be redeemed only once and a repeated payment callback cannot create a second subscription.
6. Revoking a redeemed license removes the future right to use the subscription created by that license.

### Exam setup and scheduling

1. A Host must pass pre-exam validation before publishing an exam.
2. The student list is deduplicated before capacity and conflict checks.
3. A student already assigned to an overlapping exam is either skipped with a reason or rejected according to the selected policy; the platform must not silently enroll the student.
4. Exams using the same license cannot overlap in time; exams using different licenses may overlap.
5. The published student list and exam content do not change because a class or program changes later.
6. Official and Mock Test defaults may use one separate form per student in the future workflow; Practice may use one shared form.

### Exam delivery and answer safety

1. The answer is written to the device before the application tries to send it to the server.
2. A connectivity failure leaves the answer retryable and visible as pending; it must not silently discard the answer.
3. The server remains the source of truth for whether an answer belongs to the student and the current attempt.
4. The selected exam policy is fixed for an attempt after it starts.
5. A submitted attempt cannot be restarted as a second attempt in the same exam unless an explicit future retake rule allows it.

### Proctoring and examiner work

1. Proctor actions are limited to the assigned exam and are recorded in audit data.
2. Examiner scores do not become final student scores until Host review completes.
3. Host may choose automated or examiner scoring only for answers that have a valid score from the chosen source.
4. The platform does not publish a partial report when a required score is missing.
5. A Practice violation produces a warning and an audit record under the agreed first release; it does not automatically invalidate the attempt.

### Reports and audit

1. A student sees a report only after Host publication and only for that student.
2. A published report must remain traceable to the exam version, question revision, scoring template and selected score source.
3. Changes to access, payment, exam policy, enrollment, scoring approval and publication are audit-worthy actions.
4. Reports, answer data and audit records are retained according to the contract with each organization. The exact period and deletion/export process must be written into that contract.

### External service failures

1. A payment callback may be retried without producing duplicate activation.
2. A failed AI score remains visibly pending or failed and can be retried or routed to Examiner review.
3. An expired media link is renewed through the media service instead of being treated as a lost answer.
4. Email or notification failure must not roll back a successful exam, payment or score operation.
5. The platform must show a useful status to the user when an external service is unavailable.

## NFR Baselines

These are the agreed baseline targets for the first SRS. They are targets, not evidence that the current single-VPS environment already meets them.

### Performance and capacity

- At least 95% of ordinary requests should receive a response within **0.5 seconds**.
- The platform should support at least **1,000 active student attempts** during an examination period.
- The answer service should absorb a burst of at least **100 submitted answers per second** without losing answers.
- A pre-exam validation for a list of up to **500 students** should return a usable result within **5 seconds**; large generation may continue in the background.

### Availability and recovery

- Target monthly availability: **99.9%**.
- Maximum acceptable data loss after a serious incident: **15 minutes**.
- Target recovery time after a serious incident: **1 hour**.

### Security

- No account or organization may read another organization's private data through a normal user action.
- **100% of privileged changes** to access, payment, exam publication, scoring approval and report publication must be recorded in audit data.
- Login protection should allow no more than **5 failed attempts per account or source within 15 minutes** before temporary protection is applied.
- Confidential student data, answers and reports must use protected transport and must not be written to ordinary logs.

### Growth and language

- The product should support **2–5 times** the initial active-user volume without changing the business rules.
- User-facing content should support **Vietnamese and English**.

### Privacy and compliance

- No formal healthcare, banking or government certification is selected for this SRS.
- The product handles educational and personal data as confidential information.
- Payment-card handling is delegated to PayOS; the platform should not store raw card data.
- Retention and deletion are governed by the contract with each organization.

## Open Items

1. Each organization contract must state the exact retention period and the process for deletion, export and legal hold.
2. The final AI scoring provider, score quality threshold and fallback to Examiner review need approval.
3. The authenticated transport for student lockdown-violation audit delivery must be verified end to end.
4. The remaining release boundary for large-audience processing, generation failure recovery and the level of provenance shown to Hosts must be confirmed during specification planning.
5. The remaining pre-exam screens and the way a Student receives an exam identifier need a final product decision.
6. The 99.9% availability, 1,000-active-attempt and recovery targets need an operations plan before production sign-off.
7. The exact legal privacy jurisdiction and organization-specific data-processing terms remain to be confirmed.

## Completeness Check

- [x] Every actor has a name, description and access level.
- [x] All twelve feature groups are confirmed as IN scope.
- [x] OUT scope contains more than three explicit items.
- [x] Numeric baselines exist for performance, availability and security.
- [x] Business rules are recorded for every feature group.
- [x] Privacy/compliance position is stated.
- [x] External integrations are listed.
