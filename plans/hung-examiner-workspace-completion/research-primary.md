# Examiner completion — primary backend research

Date: 2026-10-12. Source audit only; no production edits or runtime verification. Scope: actual `pte-api/app` implementation and migrations through V97. No applicable backend AGENTS.md found at repository/parent root. Framework confirmed: Java 21, Spring Boot 4.0.5, JPA, PostgreSQL/Flyway, modular monolith; public module facades separate internal repositories/controllers.

## Existing versus missing

| Capability | Actual implementation | Gap / proposed ownership |
|---|---|---|
| Examiner authorization | `ExaminerWorkController` role EXAMINER; service requires active tenant Examiner; queries scoped to authenticated examiner; details require assignment and reject published sessions | Reuse checks for every new command/read; never accept examiner ID as owner from input |
| Assignments | Host preview/confirm in `ExaminerAssignmentService`, transactional session lock, active examiner validation; `ExaminerAttemptAssignment` unique session+attempt and immutable | One Examiner owns WHOLE attempt. No parallel independent markers, section ownership, reassign or grading deadline. Preserve these constraints |
| Queue/Overview | `/api/v1/examiner/work`, `/overview`; shared native CTE `ExaminerWorkspaceReadRepository`; page size 20 max100; session/status filters; priority capped5; counts/progress and asOf | No search, task-type filter or configurable sorting. Queue status comes ONLY from finalized answer count; no explicit start or ready state |
| Detail | GET `/work/{session}/{attempt}`; pinned prompt from Attempt facade, media presigned URLs, answer payload, AI reference, immutable decision, hashed reviewVersion, canFinalize/block reason | No draft/comment/criteria state, attempt workflow metadata or issue records. GET currently read-only and does not start grading—preserve |
| Final decisions | POST `/work/answers/{answer}/score`; `SubmitExaminerScoreRequest`: integer score0–100, CONFIRM_AI/MANUAL, expectedReviewVersion, reviewedAiVersion, requestPublicId | Finalization PER ANSWER, not whole attempt; immutable after submission; no edit/reopen. User must choose whether new atomic attempt finalize replaces this for workspace |
| AI assistance | CONFIRM_AI validates exact AI score/version; MANUAL preserves reviewed AI snapshot; Examiner chooses source EXAMINER; no access to model/provider secrets | Reuse AI/reviewVersion contracts, do not make AI final automatically in MANUAL_EXAMINER |
| Drafts/start/history | None in Examiner API/domain. Immutable final rows retain actor/submission/request/AI snapshot | Add separate mutable work and draft entities, append-only event/receipt table. Do NOT turn immutable assignments/final rows mutable |
| Rubric | No criterion/rubric registry, criterion scales, descriptors, Examiner rubric API or human rubric snapshots found. `ScoringProfileRegistry` maps AI_SPEECH/AI_TEXT/OBJECTIVE/UNSCORED runtime strategies; essay vendor requests rawScore0–100 and optional subScores0–100 | Existing executable scoring profile is NOT criterion rubric. Retain explicit0–100 total unless approved new rubric policy supplied. Do not invent criterion scales/conversion or claim system already defines them |
| Aggregation | `ScoreAggregationService`: mean selected answer scores by normalized task type, existing template skill weights, existing scaling constants and rounding | No change to report formula. Do not compute replacement final score in frontend |
| Publication | Host-only `ReportPublishController`; CLOSED session lock, scoring answer/state locks, readiness, immutable snapshots. MANUAL_EXAMINER Host source selection prohibited | If attempt finalize introduced, ensure partial drafts/Ready do not appear publishable; retain Host sole publication authority |
| Completed/history | Queue, Overview and GET detail exclude published sessions; approved earlier scope ASSIGNED_UNPUBLISHED | Broaden only if user explicitly confirms. Separate History can expose own submitted records across publication with assignment/tenant checks |
| Exceptions/reopen | No Examiner issue/review request/reopen process; no Flagged/Reopened assignment state | New flag workflow needs Host ownership/resolve decisions. No reopen menu/API without approved score revision model |
| Audit | Shared `AuditLogService.record` transactional append; generic list is tenant-scoped, not assignment-scoped; score receipts retained by final entity; Host source audit separate | Do not expose generic tenant audit endpoint to Examiner. Own-scoped grading history/event projection with bounded safe before/after values |
| Tests | Spring Boot test + Modulith test; existing ExaminerScoringServiceTest, ExaminerAssignmentDatabaseIntegrationTest, ExaminerWorkQueueRepositoryTest, ExaminerWorkQueryServiceTest, workflow entity tests | Extend existing test conventions; PostgreSQL transaction/migration integration essential for atomic finalize/idempotency/locking |

## Exact files to extend/reuse

- `app/src/main/java/com/pte/scoring/internal/controller/ExaminerWorkController.java`: keep role guards; add explicit start, draft, submission/reconciliation, history routes.
- `.../internal/service/ExaminerScoringService.java`: existing ownership/eligibility/AI/final-score behavior. Extract cohesive new workflow command service rather than enlarging already long class. Reuse private policy via deliberate shared service, not duplicate validation.
- `.../internal/service/ExaminerReviewVersionService.java`: existing canonical hash/fingerprint encodings; add draft revision/rubric metadata when applicable without breaking existing immutable receipts.
- `.../internal/service/ExaminerWorkspaceQueryService.java`, `.../internal/repository/ExaminerWorkspaceReadRepository.java`: shared counts/list status predicate; persistent work-state projection instead of counting drafts as final scores.
- `.../internal/repository/ExaminerWorkQueueRepository.java`: fallback query semantics also need parity if retained; tests currently exercise older repository.
- `.../domain/ExaminerAttemptAssignment.java`: retain immutable assignment identity and existing uniqueness/FKs.
- `.../domain/ExaminerAnswerScore.java`: retain immutable score + request identity; new finalized comments/approved rubric snapshot must be additive and immutable.
- `.../dto/request/SubmitExaminerScoreRequest.java` and response DTOs: preserve existing callers or version/deprecate endpoint deliberately; never silently reinterpret final submit as Save Draft.
- `.../internal/service/ScoringEligibilityQueryService.java`: whole assigned pool is pinned-template AI-eligible answers only. OBJECTIVE/UNSCORED not newly manually scored.
- `.../internal/service/ScoreSourceSelectionService.java`, `ScorePublicationLockService.java`, `scoring/ScoringService.java`, `reporting/internal/service/ReportPublishService.java`: gate/new readiness only if introducing atomic attempt completion; no formula change.
- `attempt/internal/service/AttemptExaminerPromptQueryService.java`, media facade: reuse safe prompt/media mapping rather than traverse other modules' private entities.

## Recommended schema (conditional on pending decisions)

Allocate migration version AFTER actual current highest at implementation time: V97 is existing uncommitted attendance work; never rewrite or collide with it.

1. `examiner_grading_work`: separate row unique assignment; tenant/session/attempt/examiner owner reference via existing composite assignment FK; workflow status, started_at, finalized_at, optimistic version. Assignment stays immutable. Derived READY only when every required answer is valid; no empty-pool automatic completion without explicit policy.
2. `examiner_answer_drafts`: unique work+answer; total nullable0–100, examiner comment bounded, decision kind/reviewed AI version, draft revision; proper answer owner FK. Do not persist autosave to `examiner_answer_scores` or selected-score source.
3. `examiner_grading_events` / command receipts: owner-scoped immutable event with assignment/work/answer IDs, action/actor/time, revision, safe score/comment before-after, request ID and canonical fingerprint. Exact retry must include same payload and immutable outcome. Structured events can serve history; generic shared audit may also receive concise summary.
4. Issue table only on approval: owner-scoped answer/work reference, issue type/description/creator/time, OPEN/RESOLVED, blocking flag, Host resolver/reason/time. Blocking issue is orthogonal to progress state; no automatic Completed.
5. Optional additive finalized comment/rubric snapshot columns. Criterion JSON/model absent today; do NOT seed invented rubric. New criterion policy is blocked until supplied and approved.

## Legacy/data compatibility

- Migrations V58–62 define ownership/reference/report snapshot foundation. V95 adds immutable decision metadata and request key uniqueness; V96 conditionally aligns LEGACY_IMPORTED unpublished MANUAL_EXAMINER records. Respect their exact exclusions; never edit or discard score receipts.
- Inventory before backfill: assignment answer count versus real eligible pool; 0/partial/all finalized scores; MANUAL_EXAMINER vs AI_ONLY/cohort-less; excluded membership; published states/report snapshots; orphan/mismatched owner rows.
- Suggested mapping subject to user approval: zero finals => Pending; partial legacy immutable finals => In Progress retaining read-only finalized answers plus drafts for remainder; all finals => Completed preserving actual latest submittedAt, **not** inventing explicit start actor/time/history. Unknown startedAt remains unknown unless real evidence exists.
- Whole-attempt submit inserts missing immutable scores and selects EXAMINER atomically, while preserving existing legacy finals. Do not duplicate them or overwrite. Reject changed payload for already finalized answers.
- Rollback: disable new feature/commands, retain additive tables and receipts; destructive schema rollback after writes is unsafe. A software rollback must not reactivate old per-answer path such that new Pending/Draft bypasses attempt completion semantics.

## Lock/concurrency matrix

Current session facade obtains session lock before score mutations. Then per-answer pessimistic locks and publication state; report publish locks CLOSED session, all answers, state. Assignment confirm also uses session lock. These provide existing shared serialization anchor.

| Operation | Required order / checks |
|---|---|
| Start/draft | Active Examiner + tenant/assignment; session mutation lock when checking cohort/publication; work lock or revision compare; verify unpublished/manual/nonexcluded; no side effects on GET |
| Atomic finalize | Session mutation lock => work lock => all eligible scoring answers in stable existing ordering => publication state; refresh/revalidate assignment/cohort/member/draft versions/AI versions/mandatory answers/issues; insert immutable finals + selected EXAMINER + Completed + receipt/event ONE transaction |
| Host source changes | Keep session => answer locks; MANUAL_EXAMINER Host override forbidden |
| Host publish | Existing session => answer => state order; add readiness check to same transaction/snapshot if work state required; never publish drafts |
| Flag/resolve | Same session/work serialization where blocking state can race finalize; Host scope validated; append event |
| History/receipt | Current active identity/tenant/assignment permission BEFORE exposing own receipt/history; publication policy explicit; no need write locks for read-only |

Do not invert answer-before-session or work/answer order between draft/finalize/Host issue resolution. Check actual `ScoringAnswerRepository.findSessionAnswersForUpdate` ordering before extending. Carry precise request snapshots for unknown outcomes; stale revision/AI changes => conflict, not last-writer-wins. Only emit progress event after commit-compatible existing transaction behavior, invalidate both Overview and queues.

## Pending business decisions sent to parent

1. Atomic whole-attempt finalization versus current per-answer immutable decisions. Recommendation: explicit Start + mutable drafts + whole-attempt atomic Submit, with legacy partial finals read-only and compatibility adapter consciously restricted.
2. Real human criteria/rubric definitions are missing. Recommendation: preserve existing0–100 total and approved system guidance; do not add criterion-weight formula until defined.
3. Completed/Overview scope: retain assigned unpublished operational workload and put published completed records in own History, unless user explicitly requests unified completed scope.
4. New issue workflow handled by Host, no reopen in MVP; or use existing support integration only. Reopen cannot be small UI addition: immutable score uniqueness/FKs and publication snapshots require revision/version design.
5. Deadline is absent in existing assignment schema. Hide deadline UI; add only if business source/ownership agreed. Multiple Examiner independent/blind grading is unsupported by current model and outside this completion refactor.

## Verification limits

Source audit only. No build/test/db inventory executed by this researcher. Findings above distinguish verified current code from conditional proposed design. Parent must fold confirmed answers into final plan and retain phase Quality/Testing State.
