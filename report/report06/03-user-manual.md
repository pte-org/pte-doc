# 3. User Manual

This section maps the original DOCX heading **3. User Manual**. It provides role-specific workflows for the six approved human roles. Every workflow records a stable ID, purpose, prerequisites, steps, expected result, error/recovery path, visibility/audit effect, and linked requirements/tests. External Integration Services is described as a service boundary rather than a human manual role.

## 3.1 Common language and status

| Status | Meaning for the user |
|---|---|
| Draft | Still being prepared; not available for the next business step. |
| Pending | Waiting for review/provider/background work; do not assume success. |
| Ready | Required checks are complete for the next permitted action. |
| Published | Made available to the authorized next actor. |
| Retryable/Error | The action needs correction or safe retry; existing state is preserved where the policy supports it. |
| Locked | Content/policy/audience is fixed for the exam/attempt. |
| TBD | The product policy or evidence is not fixed; contact the owner rather than guessing. |

The product is independent from PTE Academic and is used for practice/mock-exam simulation. A PTE Prep report is not an official PTE Academic result.

## 3.2 Platform Admin workflows

### `WF-ADMIN-ONBOARD-001` — Review an organization registration

**Purpose:** Decide whether a pending organization can receive an active workspace.  
**Prerequisites:** Platform Admin account is active; registration is visible as `PENDING`.

**Steps**

1. Open the platform administration portal through the approved public URL.
2. Open the pending registration list.
3. Review organization/contact details and duplicate indicators.
4. Select **Approve** when the request meets policy, or **Reject** and enter a reason.
5. Confirm the decision and open the resulting status/audit reference.

**Expected result:** Approval creates/activates the organization and first Host according to the onboarding contract; rejection keeps the request outside an active workspace. Registration does not activate a package or charge a Student.

**Error/recovery:** If the request is incomplete, return it with the missing fields. If approval appears to fail, refresh/retry only after checking the recorded status; do not approve repeatedly or create a duplicate organization manually.

**Visibility/audit:** Platform Admin sees the registration decision; the resulting Host sees only the approved organization scope. Actor, time, decision, reason, and organization reference are audited.

**Traceability:** `WF-ADMIN-ONBOARD-001`, `FR-ONBOARD-001`–`FR-ONBOARD-003`, `BR-ACCESS-007`–`BR-ACCESS-008`, `TC-ACCESS-001`–`TC-ACCESS-002`.

### `WF-ADMIN-CONTENT-001` — Approve shared question/media content

**Prerequisites:** Platform Author submitted a draft; required media/status is visible.

**Steps:** Open draft → inspect task type/content/media → validate required fields → approve/publish or reject with a reason → confirm revision status.

**Expected result:** A complete revision becomes available to active templates; an incomplete/rejected revision remains unavailable with a correction reason. Published content is revised rather than overwritten.

**Error/recovery:** Expired media or missing answer/rubric stays non-published. Ask Platform Author to correct and resubmit; do not mark incomplete content active.

**Visibility/audit:** Platform Author sees draft/rejection; Host sees published selectable content only. Approval/publication/rejection is audited.

**Traceability:** `WF-ADMIN-CONTENT-001`, `FR-CONTENT-003`–`FR-CONTENT-005`, `BR-CONTENT-012`–`BR-CONTENT-016`, `TC-CONTENT-001`–`TC-CONTENT-002`.

### `WF-ADMIN-PACKAGE-001` — Manage package/license state

**Prerequisites:** Platform Admin has the approved package policy and provider status.

**Steps:** Open package catalog → create/update/activate/retire package definition → review dates/limits/mode → issue/revoke license code where permitted → inspect order/subscription/audit state.

**Expected result:** Host sees only eligible package/license state and limits. A revoked/expired package cannot authorize a new exam.

**Error/recovery:** Duplicate callback or code redemption returns existing state; do not create a second subscription. Provider failure remains pending/error with correlation.

**Traceability:** `WF-ADMIN-PACKAGE-001`, `FR-PACKAGE-001`–`FR-PACKAGE-004`, `BR-PACKAGE-018`–`BR-PACKAGE-022`, `TC-PACKAGE-002`.

## 3.3 Platform Author workflows

### `WF-AUTHOR-DRAFT-001` — Create a question/media draft

**Prerequisites:** Platform Author has content scope; task catalog row and required media are known.

**Steps:** Open question authoring → choose the catalog task type → enter prompt/response/rubric fields → attach image/audio through the signed media flow → preview → validate → save draft.

**Expected result:** Draft has a revision/status, required response form, media completion state, and Score Template compatibility information. It is not production-published by the author.

**Error/recovery:** Missing/expired media, invalid response field, or unsupported task combination appears beside the relevant item. Correct and validate again; do not bypass a required media check.

**Visibility/audit:** Author sees assigned drafts/revisions; Platform Admin sees submitted drafts; Host sees only published content. Draft submission and revision actions are auditable.

**Traceability:** `WF-AUTHOR-DRAFT-001`, `FR-CONTENT-001`–`FR-CONTENT-003`, `FR-INTEGRATION-002`, `TC-CONTENT-001`.

### `WF-AUTHOR-TEMPLATE-001` — Prepare a Score Template draft

**Prerequisites:** Task rows, section weights, timing, and score-source policy are available.

**Steps:** Create template draft → select task rows from the 23-row catalog → specify task count/timing/weight/source eligibility → explicitly mark Personal Introduction unscored when included → validate → submit for Platform Admin approval.

**Expected result:** Template status is submitted/pending approval; no new Host exam can select it until it is active.

**Error/recovery:** Invalid timing/weight/task combination remains draft with correction guidance. Do not alter a locked exam by editing the template.

**Traceability:** `WF-AUTHOR-TEMPLATE-001`, `FR-TEMPLATE-001`–`FR-TEMPLATE-002`, `BR-CONTENT-014`–`BR-CONTENT-016`, `TC-EXAM-002`.

## 3.4 Host workflows

### `WF-HOST-PACKAGE-001` — Activate an organization package

**Prerequisites:** Organization registration is approved; Host is signed in; eligible order/license is available.

**Steps:** Open package area → review package limits/dates → create order or enter license code → wait for verified callback/activation state → confirm subscription/license is active.

**Expected result:** Organization package state and available capacity are visible. Student is not asked to pay or own the package.

**Error/recovery:** Browser return without verified callback is not success. For pending/failed/duplicate state, keep the correlation reference and contact Platform Admin/integration support.

**Visibility/audit:** Host sees organization package data; Platform Admin sees platform/package audit. Payment/license status changes are audited.

**Traceability:** `WF-HOST-PACKAGE-001`, `FR-PACKAGE-002`–`FR-PACKAGE-006`, `BR-PACKAGE-017`–`BR-PACKAGE-021`, `TC-PACKAGE-001`–`TC-PACKAGE-002`.

### `WF-HOST-ROSTER-001` — Prepare Students, classes, and staff

**Prerequisites:** Host has an active organization and sufficient Student capacity.

**Steps:** Create/import Students → review row-level validation → resolve duplicates/missing data → create programs/classes → assign memberships → add Proctors/Examiners with appropriate scope → review roster.

**Expected result:** Roster is tenant-scoped; membership and staff assignments are visible and ready for exam selection.

**Error/recovery:** Invalid import rows remain uncommitted or clearly separated. A duplicate/conflicting Student is not silently added. Ask Platform Admin/support for account issues.

**Visibility/audit:** Host sees own organization; Proctor/Examiner later see assigned work only. Import, membership, and staff assignment changes are audited.

**Traceability:** `WF-HOST-ROSTER-001`, `FR-ORG-001`–`FR-ORG-004`, `FR-ENROLL-001`–`FR-ENROLL-002`, `TC-ROSTER-001`, `NFR-09`.

### `WF-HOST-CREATE-EXAM` — Create, validate, generate, and schedule

**Prerequisites:** Active content/media and Score Template; active package; roster; required Proctor/Examiner policy known.

**Steps**

1. Create an exam draft and choose mode/policy/date.
2. Select active Score Template and package.
3. Select Students/classes/programs; inspect deduplicated candidate preview.
4. Review capacity, date, content/media, conflict, assignment, and policy validation.
5. Resolve all blocking items.
6. Request generation and inspect fixed version/form/provenance status.
7. Publish/schedule only when the generated version is ready.

**Expected result:** Exam is published with frozen audience, task/media/template revisions, form mode, policy, and schedule. Student can enter only when open and eligible.

**Error/recovery:** If generation is pending/error, wait or use the approved retry/cancel action; do not publish partial forms. If validation identifies capacity/conflict, correct the draft and revalidate.

**Visibility/audit:** Host sees full organization exam state; assigned Proctor/Examiner see only their scope; Student sees an eligible assignment. Validation, generation, publication, and policy actions are audited.

**Traceability:** `WF-HOST-CREATE-EXAM`, `FR-EXAM-001`–`FR-EXAM-009`, `FR-HARDENING-001`, `SD-EXAM-STATE-001`, `TC-EXAM-001`–`TC-EXAM-003`, `TBD-GENERATION-001`, `TBD-VERSION-001`.

### `WF-HOST-PUBLISH-REPORT` — Review scores and publish a report

**Prerequisites:** Attempt submitted; objective/AI/Examiner sources available or their pending/error state understood.

**Steps:** Open scoring/report workspace → review source/status per task/section → assign/reassign Examiner work if allowed → choose permitted final source → run readiness check → resolve blockers → publish report → verify publication/audit state.

**Expected result:** Report is published only when required sources and decisions are ready. Student sees only the own published report.

**Error/recovery:** Pending/failed score blocks publication and identifies the source. Notification failure does not undo publication. Escalate AI policy/provider gaps under `TBD-AI-001`/`TBD-AI-002`.

**Visibility/audit:** Host sees organization reports; Examiner sees assigned scoring context; Student sees own report after publication. Source selection and publication are audited.

**Traceability:** `WF-HOST-PUBLISH-REPORT`, `FR-SCORE-001`–`FR-SCORE-007`, `FR-REPORT-001`–`FR-REPORT-005`, `SEQ-SCORE-PUBLISH-001`, `TC-SCORE-001`–`TC-REPORT-001`.

## 3.5 Proctor workflows

### `WF-PROCTOR-MONITOR-001` — Monitor an assigned exam

**Prerequisites:** Proctor account is active and assigned to the exam; exam policy is visible.

**Steps:** Open assigned monitoring workspace → select exam → review Student/attempt/device/sync status → assist only within policy → record warning/violation with type/detail/severity → confirm event status.

**Expected result:** Proctor sees assigned data and records a traceable event. Practice policy warnings/audit do not automatically invalidate an attempt unless the fixed policy says so.

**Error/recovery:** Unassigned exam is denied. If event synchronization is pending/error, do not claim delivery; retain the visible event reference and escalate under `TBD-PROCTOR-001`.

**Visibility/audit:** Host can review organization policy/event state; Student sees only what policy allows; Examiner does not receive unrelated Proctor details. Assignment, assistance, violation, and intervention actions are audited.

**Traceability:** `WF-PROCTOR-MONITOR-001`, `FR-INTEGRITY-001`–`FR-INTEGRITY-005`, `SEQ-PROCTOR-AUDIT`, `TC-PROCTOR-001`, `NFR-10`.

## 3.6 Examiner workflows

### `WF-EXAMINER-SCORE-001` — Score assigned answers

**Prerequisites:** Examiner account is active; Host assigned answer/attempt; rubric and prompt/media revision are available.

**Steps:** Open assigned queue → select work item → review prompt/response/rubric → enter criterion/score/note → save draft if allowed → submit score → confirm submitted/read-only state.

**Expected result:** Score source identifies Examiner, time, rubric/revision, and status. Host can review; Examiner cannot publish the report.

**Error/recovery:** Unassigned work is denied. Invalid score range or incomplete rubric remains unsaved/submitted with a correction message. If an answer cannot be evaluated, use the permitted review/reassignment path instead of inventing a score.

**Visibility/audit:** Examiner sees assigned work only; Host sees score source; Student sees no unpublished Examiner detail unless policy explicitly permits. Score submission is audited.

**Traceability:** `WF-EXAMINER-SCORE-001`, `FR-SCORE-001`–`FR-SCORE-003`, `BR-SCORE-036`, `TC-SCORE-001`–`TC-SCORE-002`.

## 3.7 Student workflows

### `WF-STUDENT-TAKE-001` — Take an assigned timed exam

**Prerequisites:** Student account is active; exam is published/open; Student is in the frozen audience; Windows client is installed.

**Steps**

1. Sign in through the approved client.
2. Open the assigned exam and review exam/mode instructions.
3. Complete microphone/audio/device/network check.
4. Start the fixed task sequence when the client indicates readiness.
5. Read/listen/respond within the displayed preparation/response timer.
6. Confirm each answer shows local saved/sync status.
7. If connectivity is interrupted, continue only when the client policy allows and watch the retry queue.
8. Submit once when the client indicates required work is complete.

**Expected result:** The client renders the fixed content, saves responses locally before sync, shows retry state when needed, and acknowledges final submission only after accepted/safe final state.

**Error/recovery:** Device check failure stops or warns before timed work according to policy. A queued answer remains visible; do not close/delete local data before support confirms recovery. A submitted attempt cannot be restarted without an approved retake policy.

**Visibility/audit:** Student sees own attempt state; Proctor sees permitted monitoring state; Host sees submission/scoring state. Device/security/submission events are auditable; raw answers/audio are not placed in ordinary logs.

**Traceability:** `WF-STUDENT-TAKE-001`, `FR-DELIVERY-001`–`FR-DELIVERY-009`, `SEQ-ANSWER-SYNC`, `TC-DELIVERY-001`–`TC-DELIVERY-005`, `NFR-12`, `TBD-CLIENT-001`.

### `WF-STUDENT-VIEW-001` — View a published result

**Prerequisites:** Host has published the report; Student is signed in to the same organization assignment.

**Steps:** Open results → select own published attempt → review task/section/Overall values that the Score Template permits → read publication time/source status shown by policy.

**Expected result:** Student sees only the own report after publication. A missing or unpublished report is not replaced with a partial/fake result.

**Error/recovery:** If report is not visible, the message explains whether scoring is pending or Host publication is incomplete. Contact Host; do not attempt to access another Student’s report.

**Visibility/audit:** Student view is own-scope; Host publication and Student access are traceable. 

**Traceability:** `WF-STUDENT-VIEW-001`, `FR-REPORT-002`–`FR-REPORT-004`, `BR-REPORT-040`–`BR-REPORT-041`, `TC-REPORT-001`.

## 3.8 External Integration Services boundary

External Integration Services has no user manual login. Its operational contract is documented through provider adapters and support runbooks:

- Payment: verify callback/correlation, process once, expose pending/error, and never treat browser return as proof.
- Media: use signed access/upload, validate completion, renew expired link, and preserve revision identity.
- AI scoring: expose pending/success/failure/retry/review state; provider and threshold remain TBD.
- Notification: retry bounded delivery and do not roll back the originating business result.

**Traceability:** `FR-INTEGRATION-001`–`FR-INTEGRATION-006`, `BR-INTEGRATION-044`–`BR-INTEGRATION-048`, `NFR-19`, `TC-INTEGRATION-001`.

## 3.9 Troubleshooting and FAQ

### Login or session problem

Check account status, organization approval, role/scope, and session expiry. Sign out/sign in or follow controlled reset. Platform Admin handles administrator-assisted recovery. Never share passwords or tokens in a support message.

### Package/capacity problem

Check subscription/license status, effective dates, Student capacity, and exam overlap. Registration approval does not prove package activation. Host contacts Platform Admin with the order/license correlation.

### Missing question/media or template

Check content revision status, required media completion, active Score Template, and approval state. Platform Author corrects the draft; Platform Admin approves/publishes. Host cannot bypass the shared content gate.

### Exam conflict or generation error

Review duplicate/conflicting candidates, package window, content completeness, assignments, and generation state. Use safe retry/cancel when available. Do not publish a pending/error or partial form. Escalate with exam draft/version reference.

### Microphone/audio/device check failure

Confirm Windows permissions, selected device, microphone input, audio playback, network, and client build. Re-run the check before the timer. If still blocked, contact Host/Proctor support and preserve the error reference.

### Offline answer synchronization

Look for **locally saved**, **queued**, **retrying**, **synchronized**, or **rejected** state. Keep the client open and follow the approved retry path. Do not claim submission or delete local data before support confirms recovery. `SEQ-ANSWER-SYNC` and `TC-DELIVERY-003` define the evidence expected.

### Proctoring/violation question

The Proctor follows the fixed exam policy. A Practice warning/audit does not automatically invalidate the attempt in the initial policy. Unassigned actions are denied. If event state is pending/error, record the reference and escalate under `TBD-PROCTOR-001`.

### AI or Examiner score pending/failed

Host checks source status, assignment, rubric, provider correlation, and retry/review policy. Do not substitute a placeholder as a valid final score. Publication remains blocked when required scores are incomplete.

### Report not visible after scoring

Check report readiness, Host source selection, publication state, Student ownership, and notification status. Notification failure does not necessarily mean publication failed; Host verifies the report state directly.

### External service outage

Record provider/correlation/status, wait for bounded retry if appropriate, and escalate to the integration owner. Do not repeat a payment/license/exam/publication action blindly.

## 3.10 Screenshot and guide asset inventory

The current baseline does not embed screenshots because routes/client states and real data must be verified and masked first. Future assets use this inventory:

| Asset ID | Intended capture | Status/source | Related IDs |
|---|---|---|---|
| `IMG-ADMIN-ONBOARD-001` | Platform Admin registration review with synthetic organization | TBD — capture after route/evidence verification | `WF-ADMIN-ONBOARD-001`, `FR-ONBOARD-002` |
| `IMG-HOST-EXAM-001` | Host exam validation/candidate preview | TBD — capture after UI verification | `WF-HOST-CREATE-EXAM`, `FR-EXAM-003` |
| `IMG-STUDENT-CHECK-001` | Windows client device check and save/sync status | TBD — `TBD-CLIENT-001` | `WF-STUDENT-TAKE-001`, `TC-DELIVERY-002`–`TC-DELIVERY-003` |
| `IMG-PROCTOR-EVENT-001` | Proctor assigned monitoring/violation record | TBD — `TBD-PROCTOR-001` | `WF-PROCTOR-MONITOR-001`, `FR-INTEGRITY-003` |
| `IMG-REPORT-PUBLISH-001` | Host readiness/source selection/publication | TBD — verify score/report UI | `WF-HOST-PUBLISH-REPORT`, `FR-REPORT-003`, `TC-REPORT-001` |

Every image must use synthetic/masked data and include status, source/capture date, and related workflow/requirement/test IDs. Missing screenshots remain TBD rather than fabricated.

## 3.11 Guide review checklist

- Product is named PTE Prep; PTE Academic independence boundary is visible.
- Only Platform Admin, Platform Author, Host, Proctor, Examiner, Student, and External Integration Services appear as product actors.
- Registration and package activation are separate instructions.
- Windows-first client and device/offline limitations are explicit.
- Every role workflow has prerequisites, steps, expected result, error/recovery, visibility, audit, and traceability.
- Planned/Partial/TBD behavior is not written as a guaranteed Current workflow.
- Internal service ports and secret values are not presented to end users.
- Retention remains contract-based/TBD.
- Screenshots/assets are masked or explicitly TBD.

