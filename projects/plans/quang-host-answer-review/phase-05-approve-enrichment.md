# Phase 5: Remove Approve Gate, Add Independent Teacher Score

## Requirements

Remove the existing "host must approve an AI score before it counts" workflow entirely (user decision, 2026-09-08: no approval function wanted). Today, only `WRITE_ESSAY` is a "review-required" task type (`AiScoringWorker.REVIEW_REQUIRED_TASK_TYPES`): its AI score lands in status `AI_SCORED_PENDING_REVIEW` and stays non-final until `ScoringReviewService.approve()` copies `rawScore` verbatim into `SCORED` — the host cannot currently enter a different number at all, it is a rubber stamp, not real grading. After this phase, `WRITE_ESSAY` finalizes automatically like every other task type (straight to `SCORED`, no host gate).

In its place, add a new, completely independent **teacher score**: a host can record their own score for any answer, at any time, regardless of the answer's AI-scoring status. This is stored in a new `teacherScore` column alongside the existing AI score column, purely so a future feature can compare "how AI graded vs. how the teacher graded" in aggregate. This plan does **not** decide which score (AI's or teacher's) is authoritative for student-facing reports — that is explicitly deferred.

## Design Constraints

- **No approval semantics anywhere.** Do not rename this into a softer version of approve (e.g., "confirm", "acknowledge") — the host's score is independent data, not a gate on the AI score's finality.
- **AI score always finalizes on its own.** Delete `AiScoringWorker`'s `REVIEW_REQUIRED_TASK_TYPES` branch (lines ~36, 70-84) so `WRITE_ESSAY` takes the exact same straight-to-`SCORED` + `AnswerScored` outbox-write path that `READ_ALOUD` and every objectively-scored type already use.
- **Remove dead code, don't deprecate-in-place.** Delete `ScoringReviewService.approve()`, `ReviewNotPendingException`, the `POST /answers/{id}/review` controller method, and the `AI_SCORED_PENDING_REVIEW` enum value (confirm nothing else references it first — see plan.md Risks). This codebase's own convention (per CLAUDE.md-level guidance) is to delete unused code outright, not leave renamed shims.
- **teacherScore is never gated by AI status.** A host can submit a teacher score whether the answer is `PENDING`, `AI_SCORING`, or `SCORED` — no precondition check beyond RBAC + tenant match (reuse Phase 4's `getAnswerForReview`-style tenant check).
- **teacherScore never triggers `AnswerScored` or `AttemptCompletionService`.** It's parallel statistics data, not part of the scoring pipeline. Submitting it must not affect attempt completion, reporting, or any existing event flow.
- **RBAC via @PreAuthorize:** `@PreAuthorize("hasAnyRole('HOST_ADMIN','HOST_AUTHOR')")`, same as the rest of `ScoringReviewController`.

## Steps

1. **Add `teacherScore` and `teacherScoredAt` fields to `ScoringAnswer`** — nullable `Integer teacherScore`, nullable `Instant teacherScoredAt`. This project uses Hibernate-managed schema (no Flyway, per `phat-remove-flyway-hibernate-only`), so no manual migration script is needed in dev — verify this assumption holds for the target environment before considering the step done.

2. **Remove `AI_SCORED_PENDING_REVIEW` from `ScoringAnswerStatus`** — after confirming (via grep) that nothing besides `AiScoringWorker` and `ScoringReviewService` references it. Update the enum's own doc comment to drop the removed value's description.

3. **Simplify `AiScoringWorker.onAiScoringJob`** — delete the `REVIEW_REQUIRED_TASK_TYPES` set and the `if (REVIEW_REQUIRED_TASK_TYPES.contains(...))` branch; every path now calls `answer.markScored(result.rawScore())` + writes `AnswerScored` + calls `attemptCompletionService.checkAndEmitIfComplete(...)`, unconditionally.

4. **Delete `ScoringReviewService.approve()` and `ReviewNotPendingException`** — remove the method, the now-dead `findOwned` helper if nothing else uses it (check first), and the exception class + its exception-handler mapping if one exists.

5. **Delete `POST /answers/{id}/review` from `ScoringReviewController`** — remove the controller method and its import of `EncryptedSubmissionRequest`-adjacent types if unused elsewhere. Confirm (per plan.md's LOW risk) that no other codebase in this workspace (pte-app, pte-web) calls this endpoint before deleting; if one does, coordinate removal there too in this same phase.

6. **Add `POST /answers/{answerPublicId}/teacher-score` endpoint** — request body `{ score: int }` (reuse the `0-100` scale convention documented in `ObjectiveScoringService`'s javadoc, so `teacherScore` is comparable to `rawScore` on the same axis). Service method `ScoringReviewService.submitTeacherScore(answerPublicId, score, caller)`: tenant-scoped fetch (reuse Phase 4's pattern, 404 on cross-tenant or missing), set `teacherScore` + `teacherScoredAt = Instant.now()`, save — no status change, no outbox event.

7. **Include both scores in the Phase 2/4 response DTOs** — `AnswerReviewResponse`/`AnswerReviewDetailResponse` (from Phases 2 and 4) must expose both `rawScore` (AI) and `teacherScore` (nullable) side by side, so a host viewing the detail endpoint sees both numbers when comparing.

8. **Add tests** — unit test that `AiScoringWorker` now finalizes `WRITE_ESSAY` straight to `SCORED` (replacing the old "lands in AI_SCORED_PENDING_REVIEW" test); integration test for `POST /answers/{id}/teacher-score` covering: submitting a teacher score on a `PENDING` answer (no AI score yet) succeeds, submitting on an already-`SCORED` answer succeeds and doesn't alter `rawScore` or status, RBAC denial, and cross-tenant denial (404).

## Success Criteria

- `WRITE_ESSAY` answers finalize to `SCORED` automatically, with no host action, same as every other task type.
- `AI_SCORED_PENDING_REVIEW`, `ScoringReviewService.approve()`, `ReviewNotPendingException`, and `POST /answers/{id}/review` no longer exist in the codebase.
- `POST /answers/{answerPublicId}/teacher-score` lets a host record a score independent of `rawScore`, at any answer status, without side effects on attempt completion or reporting.
- Detail/list responses show both `rawScore` (AI) and `teacherScore` (nullable) for every answer.
- All new and updated tests pass; no test still asserts the old approve-gate behavior.

## Quality and Testing State

- Quality gate: **approved** (0 findings). Verified (not assumed): grep confirmed all 5 files referencing the removed status/exception were updated; `mvn test-compile` passed clean (no test constructed the old 3-arg `ScoringReviewService` constructor); deployed to local Docker — Hibernate auto-added `teacher_score`/`teacher_scored_at` columns + new index cleanly, container healthy; queried the live `scoring_answers` table pre-deploy and confirmed 0 rows (no in-flight `AI_SCORED_PENDING_REVIEW` backfill needed in this environment). Report: `quality/phase-05-approve-enrichment-quality-report.json`. Receipt skipped (cross-repo boundary).
- Testing: **not started** — user declined unit tests for this phase onward.

## Risks

- **MEDIUM: Deleting `AI_SCORED_PENDING_REVIEW` breaks any in-flight rows** — if any `ScoringAnswer` row is already sitting in that status in a real database when this phase deploys, it will be stuck (nothing transitions it anymore once the enum value and its handling are gone). Mitigation: before deploying, run a one-time check/backfill query that finalizes any row still in `AI_SCORED_PENDING_REVIEW` to `SCORED` using its existing `rawScore`, then deploy the code that removes the enum value.

- **LOW: 0-100 scale mismatch between AI and teacher input** — if the teacher-score endpoint doesn't validate the incoming score is within the same 0-100 percentage scale `ObjectiveScoringService`/AI scoring uses, future comparison stats will be comparing incompatible units. Mitigation: validate `0 <= score <= 100` in the request DTO or service layer.

- **LOW: Future comparison feature is unscoped** — this phase only stores the two numbers side by side; building the actual "AI vs teacher" statistics/report is explicitly out of scope here ("nếu cần" — build later, if needed). Don't over-build an aggregation endpoint in this phase.
