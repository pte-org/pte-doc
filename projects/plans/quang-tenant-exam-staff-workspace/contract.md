# Phase 01 — Exam Staff implementation contract

Status: technical baseline prepared; authoritative quality and human-checkpoint states are tracked in phase-01-contracts-and-security.md.
Scope of this document: implementation decisions, not evidence of working APIs/UI.

## Ownership and source constraints

Sources inspected live under pte-api/app/src/main/java/com/pte:

- identity/internal/service/UserProvisioningHelper.java: canManageTarget requires every target role to be manageable; HOST_ADMIN check also requires valid security scope.
- identity/internal/service/UserService.java: staff credential email rejects a target with STUDENT; Student profile PATCH cannot edit staff.
- identity/domain/User.java: login is username, separate from profile email. Existing DB uniqueness protects tenant/username, not tenant/canonical email.
- identity/internal/controller/UserController.java: existing lifecycle/credential actions remain identity-owned and preserve their permission semantics.
- session/domain/ExamSession.java and domain/enums/SessionStatus.java: ca has name, code, opensAt/closesAt, templatePublicId/snapshotPublicId, seven lifecycle states.
- session/domain/ProctorAssignment.java: tenant/session/proctor/duty assignment; removed assignments are not a complete duty audit.
- scoring/domain/ExaminerAttemptAssignment.java: immutable owner/count/assignedAt; no draft assignment records, allocation preview is separate.
- scoring/domain/ExaminerAnswerScore.java: immutable SUBMITTED status, submittedAt, examiner, answer ID and unique answer key; distinct from AI/teacher scores.
- scoring/internal/service/ScoringEligibilityQueryService.java: AI-eligible answers are resolved through ScoringMethodResolver against each answer's pinned template.
- scoring/internal/service/ScoringMethodResolver.java: pinned templates immutable/cached; reuse it, no parallel task-type list.
- scoring/internal/repository/ExaminerWorkQueueRepository.java: caller-owned queue excludes publication; do not reuse that exclusion or ownership model.
- application.yml: Flyway enabled, Hibernate validate. Any required additive index belongs in a new, uniquely numbered migration; never modify old migrations.

New examstaff composition depends on public Identity/Session/Scoring read contracts only.
Identity never depends on Scoring. Controllers never import repositories.
Public staff account DTO exposes only publicId, fullName, username, email, phone, dateOfBirth, roles, status and mustChangePassword.
Internal UserResponse/ORM User is not the new cross-module contract.

## Authorization matrix

| Caller / target | Behavior |
| --- | --- |
| Valid HOST_ADMIN / same-tenant nondeleted PROCTOR or EXAMINER | Detail and relevant work reads allowed |
| Same target suspended | Read allowed, no requirement to be ACTIVE |
| Both PROCTOR and EXAMINER | One account, both work sections |
| Other tenant, deleted, missing or nonstaff target | Uniform safe not-found response; no profile/session metadata |
| Non-Host caller or invalid security scope | Forbidden before resolving target |
| Target has privileged roles outside existing manageable role set | Forbidden; no widening from merely having EXAMINER |
| Requested work section not in target role set | Forbidden, not a successful empty workload |
| Mixed staff + STUDENT roles | Preserve existing policy. Credential email remains unavailable because identity currently rejects STUDENT; do not bypass through new route |

Lifecycle and credentials use existing identity authorization; profile read permission does not grant mutation permission.
Safe profile projection may expose capabilities so UI hides unsupported actions without deriving a new permission policy.
Every metadata batch verifies session tenant and nondeleted session; malformed assignment tenant references cannot leak labels.

## Endpoint and filter contract

New HOST_ADMIN routes:

- GET /api/v1/exam-staff/{staffPublicId}: safe detail projection.
- GET /api/v1/exam-staff/{staffPublicId}/overview: role-specific Proctor/Examiner summaries.
- GET /api/v1/exam-staff/{staffPublicId}/proctor-sessions: PagedResult<ProctorSessionView>.
- GET /api/v1/exam-staff/{staffPublicId}/examiner-sessions: PagedResult<ExaminerSessionView> plus totalByStatus for the same base predicate.
- PATCH /api/v1/users/{staffPublicId}/exam-staff-profile: identity-owned whitelisted update.

page defaults 0, size defaults 20, accepted size 1..100; negative/oversized/invalid enum/range => 400 through centralized stable query code.
Sort schedule opensAt descending with stable publicId tie-breaker; Proctor schedule UI may request ascending as an explicit allowlisted sort direction.
Session filter uses sessionPublicId. The inspected model has no separate examPublicId field/resource on ExamSession: ca/kỳ thi selector maps directly to sessionPublicId, never silently interprets an exam ID as template/snapshot ID.
Template filter is not added to V1 merely to fulfill a speculative examPublicId name. Final option labels come from scoped session API, not page-derived local options.
Date inputs are from/to UTC Instant boundaries, transmitted with offset. UI displays Asia/Ho_Chi_Minh unless a legitimate existing organization timezone is available.
Session overlap: opensAt < toExclusive AND closesAt > fromInclusive. Absent bounds omit predicates. Date-only inclusive end converts next day's start in display zone, not fixed 24h arithmetic.
Reversed interval rejected. Missing schedule remains visible without date filter and excluded when a date interval is supplied.
Same schedule predicate applies to Examiner overview/list/board/counts, never assignedAt/submittedAt fallback.
Proctor accepts sessionStatus from current SessionStatus. Examiner accepts workStatus ALL/PENDING/IN_PROGRESS/COMPLETED/UNAVAILABLE and publicationStatus ALL/PUBLISHED/UNPUBLISHED.
UNAVAILABLE is a read-query bucket, not a persisted workflow enum. Invalid session IDs from another tenant cannot broaden lookup.

## Proctor summary rules

Counts are distinct remaining assigned sessions, not attendance.
CLOSED => ended; CANCELLED => cancelled; OPEN => ongoing; SCHEDULED with future opensAt => upcoming.
SCHEDULED already past its opening => awaiting-open/stale, not ongoing or ended.
DRAFT/PREPARING/READY => preparing; invalid/missing schedule => unscheduled except CLOSED/CANCELLED lifecycle truth retained.
These buckets reconcile to totalAssignedSessions; distinct exams are not reported until a real separate exam identity exists.
No mutation of session lifecycle from a statistics GET.

## Examiner validity and progress rules

Group immutable committed assignments by tenant/examiner/session, never batch.
For each assigned attempt, load eligible answer identities with the scoring-owned pinned eligibility rule, exclude deleted rows, and compare distinct eligible-answer count with frozen assignment eligibleAnswerCount.
Mismatch or invalid pinned template/assignment data => UNAVAILABLE with safe diagnostic reason, not recalculated denominator or invented completion.
Submitted count uses distinct answerPublicId with matching tenant/session/attempt/examiner, nondeleted score, SUBMITTED status, nonnull submittedAt, valid 0..100 score, and membership in the eligible answer set.
Unrelated/duplicated/malformed score rows cannot numerically simulate completion; invalid scope/count data is surfaced as unavailable, not silently ignored as healthy.
Zero eligible, with consistent pinned eligibility => completed attempt with no-work flag; positive eligible and zero submitted => pending; partial => in progress; exactly full => completed.
Ca: unavailable if any attempt unavailable; otherwise completed if all complete, pending if all pending, else in progress. No assignments => no card.
Return assignedAttemptCount, batchCount, eligibleAnswerCount, submittedAnswerCount, pendingAttemptCount, inProgressAttemptCount, completedAttemptCount, workStatus, publicationStatus and schedule metadata.
No answer payload or individual student scores in the tracking projection.
Keep published ca. Publication derives from ScoringSessionState publication reference, not work completion.

### Field presence for unavailable progress

Use explicit JSON null, never omission or zero, for unverifiable progress. The typed client must preserve this distinction and render the existing unavailable placeholder rather than a zero-progress bar.

| ExaminerSessionView field | Valid session | UNAVAILABLE session |
| --- | --- | --- |
| assignedAttemptCount, batchCount | Required integers from scoped committed assignments | Required integers from the same verified assignment identities, independent of score eligibility |
| frozenEligibleAnswerCount | Sum of valid frozen assignment denominators | Same sum if every denominator is valid; otherwise null. This is allocation metadata, never a substitute for verified eligibility |
| eligibleAnswerCount, submittedAnswerCount | Required verified integers | Both null whenever any assigned attempt cannot be verified; do not expose partial totals as whole-session progress |
| pendingAttemptCount, inProgressAttemptCount, completedAttemptCount | Required verified attempt subtotals | Required integers counting only attempts whose complete progress was verified |
| unavailableAttemptCount | 0 | Required integer counting attempts that cannot be verified |
| progressPercent | Verified percentage; 100 for consistent zero-work completion | null |
| diagnosticCodes | Empty array | Required nonempty deduplicated array of safe stable codes |

For every session, assignedAttemptCount = pendingAttemptCount + inProgressAttemptCount + completedAttemptCount + unavailableAttemptCount. A failed validation classifies that attempt exclusively as unavailable, never also pending/completed. Verified subtotals in an unavailable session describe the known attempts only, not the whole session's status.

Diagnostic code allowlist: ASSIGNMENT_DATA_INVALID, ELIGIBILITY_TEMPLATE_UNAVAILABLE, ELIGIBLE_COUNT_MISMATCH, SUBMITTED_SCORE_DATA_INVALID. Responses contain codes only, not raw exception messages, student identities, template contents or database values. Feature-owned i18n constants supply user-facing descriptions. Structurally invalid assignment rows with a resolvable scoped session/attempt are retained as unavailable; unresolved/cross-tenant/deleted references do not become exposed assignments or metadata.

Examiner overview session buckets always include unavailable and reconcile through totalSessions. Overview assignedAttemptCount and batchCount include all visible assignments; verified attempt subtotals plus unavailableAttemptCount reconcile to the assignment total. Whole-workload eligibleAnswerCount, submittedAnswerCount and progressPercent are null if any included session is unavailable. Separately named verifiedEligibleAnswerCount and verifiedSubmittedAnswerCount sum only fully verified sessions; progressCoverageComplete is false when any session is unavailable. These partial counters must be labeled as verified coverage and cannot be displayed as whole-workload completion. With no assignments, counts are zero, progressPercent is null, progressCoverageComplete is true, and the UI shows its empty state rather than completed work.

## Pagination, counts and bounded composition

TotalByStatus is calculated before workStatus paging, after shared base date/session/publication predicates. Table ALL includes unavailable; each board column has independent page and same total/count semantics.
totalSessions = pending + inProgress + completed + unavailable.
Do not aggregate all answers/attempts/session history into one Java/browser list.
Use database aggregation or bounded server cursor batches through owner-module public projections. If eligibility resolution needs pinned template inspection, stream owned work in bounded batches, reuse the existing resolver cache and aggregate counters while retaining only requested page records.
No query-per-session/answer or frontend fan-out. Public Session context queries are batched and scoped; bounded scans are not a performance-pass claim, query cost must be reviewed at the Phase 02 gate.
Count/page computations run in one consistent read-only transaction snapshot. They may not expire previews/create reports/advance scoring state.

## Profile update and email integrity

Editable fields: fullName/email/phone/dateOfBirth only. username/roles/status/studentCode are not update fields.
Full name and email required for staff. Trim fullName/email/phone; blank optional phone becomes null; DOB nullable and not in future. String length limits must match actual mapped DB columns and existing validations, not arbitrary UI-only limits.
Email canonical comparison lower(trim(email)) scoped to nondeleted tenant users; login username does not change when email changes.
Existing username unique index is not enough once email differs. Phase 02 must add a database uniqueness mechanism plus friendly conflict mapping, not just an application pre-check.
Flyway additive canonical-email index must preflight conflicting existing rows and fail safely rather than delete/merge/normalize unrelated records. Do not run migration against a live DB in this task.
Migration scope must be checked against existing profile/provisioning semantics; if existing collisions need remediation, report them without exposing PII and ask before altering user data.

## Frontend contract and implementation state

Route /host/exam-staff/[staff-id], same-tab client navigation. Overview first, applicable work tabs, Account last.
Shared presentation slots compose existing common; no font/size/menu-trigger override, no Student DTO/hooks inside @pte/ui.
Staff credential action uses existing generate-and-send email workflow; no new Student credential route.
Split rendering/query/draft/actions/messages/types; component functions <150 lines, files <300 lines.
Tests: user declined writing/running. Quality: enabled every phase. No production code, build, HTTP/database/UI validation in Phase 01.
