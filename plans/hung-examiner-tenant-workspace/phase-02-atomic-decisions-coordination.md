# Phase 02 — Atomic final decisions and session coordination

Status: completed. Dependency: Phase01 contract/schema.
Stories: P1 explicit AI confirm/manual finalization, timeout resilience and late-AI safety.
Requirements: FR04–08,13–14.

## Inputs and output paths

Relative to `pte-api/app/src/main/java/com/pte/`:

- `scoring/internal/service/{ExaminerScoringService,ExaminerAssignmentService,ScoreSourceSelectionService,ScoringReviewService,AiScoringResultPersistenceService,ScoringCommandService,ScoringIngestService,GradingCohortService}.java`.
- `scoring/internal/listener/GradingProgressListener.java`; existing SessionService facade and `lockForScoreReviewMutation`.
- New small transactional grading reconciliation worker in `scoring/internal/service/`, separate from nontransactional scheduler loop.
- `scoring/internal/controller/ExaminerWorkController.java`; request/response/errors from Phase01.
- Existing/new focused tests under `pte-api/app/src/test/java/com/pte/scoring/` if selected.

## Design Constraints

- Common tenant/session mutex precedes all cohort/member/answer/state writes; no reverse answer→session acquisition. Locks remain local DB work only.
- One scheduled session per proxied transaction, no self-invocation reliance, no multiple session mutexes held by a sweep.
- New decisions require FROZEN or COMPLETED MANUAL cohort and nonexcluded exact member; COMPLETED is not a prerequisite for first score.
- Existing immutable decision cannot be amended; same score with a different kind/viewed version is a different intent.
- Current read authorization precedes receipt replay. Replay precedes optimistic checks, but never restores revoked/published access.
- Preflight: conventions=pte-api sessionService.lockForScoreReviewMutation for mutex; boundaries=session-first locking across scoring/cohort/reporting, atomic finalize (immutable score + selectScoreSource(EXAMINER) atomically); applicable_rules=common session mutex before cohort/answer/state locks, validate FROZEN MANUAL_EXAMINER cohort and nonexcluded member, verify expectedReviewVersion and reviewedAiVersion, reject legacy score-only payload, prevent Host source selection / teacher score in MANUAL_EXAMINER; allowed_exceptions=AI_ONLY sessions retain existing source-selection behavior.

## Implementation steps

1. Inventory every mutation and ingest caller. Record one lock matrix covering Examiner, AI success/failure, objective dispatch/ingest, assignment confirm, Host selection/teacher score, cohort freeze/reconcile and publication.
2. Preserve existing session-first callers; add session mutex before any write locks to other callers using SessionService rather than cross-module repositories. Nonlocking target lookup may resolve session identity, but revalidate locked entities afterward.
3. Split scheduler into unlocked identifier enumeration and separate Spring-proxied per-session transactional worker. BEFORE_COMMIT progress listener may remain only with the mutex already held; standalone reconciliation acquires it first.
4. Within Examiner transaction revalidate active actor/tenant/owned assignment and current access, then lookup scoped receipt. Same fingerprint returns original decision; same key/different fingerprint returns409 even on another answer.
5. For new intent check manual policy, nonexcluded member, immutable assignment owner, publication state, no existing immutable decision and modern payload completeness. Reject legacy score-only manual writes explicitly.
6. Verify exact expectedReviewVersion and reviewedAiVersion. CONFIRM_AI requires AVAILABLE and exact score. MANUAL can finalize with unavailable/pending AI; available viewed snapshot must still match. Store only the snapshot actually validated.
7. Insert immutable score including its embedded receipt metadata; flush before existing selectScoreSource(EXAMINER) sets pointer/actor/time. Commit score/source atomically, emit progress after aligned state, compute response version after flush.
8. Across different sessions a tenant/actor request-key collision may still reach the unique index. The losing transaction must roll back before a supported outer boundary performs fresh authorization/scoped lookup and returns replay/conflict. Never query or continue inside a rollback-only transaction; no separate receipt table is needed.
9. AI result/failure persistence keeps provider work outside transaction and cannot reset EXAMINER pointer/final score. It may update reference metadata independently when a valid late result arrives.
10. Reject source-selection preview/apply and teacher-score mutation in explicit MANUAL_EXAMINER, including bulk ALL/SECTION/TASK_TYPE and direct API callers. Preserve AI_ONLY behavior and current teacherScore exclusion from report.
11. Reject assignment confirmation against AI_ONLY cohort and excluded/frozen-incompatible targets; never silently change frozen mode. Keep pre-cohort assignment workflow intact.

## Planned verification

From pte-api: `.\mvnw.cmd -pl app -am -DskipTests compile`.
If selected: `.\mvnw.cmd -pl app -am '-Dtest=ExaminerScoringServiceTest,AiScoringResultPersistenceServiceTest,ScoreSourceSelectionServiceTest,ScoringReviewServiceTest,ScoringReviewReadQueryServiceTest,GradingCohortServiceTest' -Dsurefire.failIfNoSpecifiedTests=false test`.

- CONFIRM_AI and MANUAL atomically produce EXAMINER source; a failure rolls back score/receipt/pointer together.
- Exact retry after committed version changes returns original; equal score/different kind or cross-answer key reuse conflicts.
- Stale AI/manual viewed snapshot conflicts; no cohort/AI_ONLY/excluded member cannot finalize.
- Concurrent different decisions yield one immutable result; concurrent last decision/publication and AI completion do not deadlock on PostgreSQL.
- Scheduled reconcile and BEFORE_COMMIT listener follow session-first transaction boundaries; provider latency does not hold session mutex.
- Direct Host/bulk mutation cannot replace a manual final; late AI leaves final source untouched.

## Acceptance and handoff

New decision mutation has one atomic authority and exact retry semantics. Canonical writer coordination is implemented across the full matrix before Phase03 relies on it for publication.

## Quality and Testing State

- Quality: not evaluated; user choice pending.
- Testing: not started; user choice pending; no --tdd selected.
- PostgreSQL concurrency evidence is distinct from Mockito ordering checks; report unperformed checks explicitly.
