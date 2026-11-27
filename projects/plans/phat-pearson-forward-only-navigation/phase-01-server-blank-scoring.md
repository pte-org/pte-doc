# Phase 1: Server Blank Scoring Short-Circuit

## Requirements
A blank answer (null/empty payload) in the host scoring path scores 0 without calling Azure or Gemini and without marking scoring as failed.

## Why
Skipped tasks are stored as real `attempt_answer` rows with a null payload. `ScoringIngestService` opens an `AiEvaluation` for every row, and `AiScoringWorker.callVendor` passes `answer.payload()` straight to `speechScoringClient.score` (`AI_SPEECH`) and `essayScoringClient.score` (`AI_TEXT`) (`app/src/main/java/com/pte/scoring/internal/messaging/consumer/AiScoringWorker.java` lines ~163-193). Only the practice path guards blanks (`PracticeAiScoringService`). Result today: wasted vendor credit or `markScoringFailed`.

## Files to touch (pte-api)
- `app/src/main/java/com/pte/scoring/internal/messaging/consumer/AiScoringWorker.java` — blank short-circuit before any vendor call (decide the exact spot after reading `~L130-L200`).
- `app/src/main/java/com/pte/scoring/internal/...ScoringIngestService` — read; only change if the blank check belongs at ingest (e.g. mark evaluation complete with score 0 instead of queuing a job). Locate with Grep.
- Reference only: `PracticeAiScoringService` blank handling (reuse the same definition of "blank" if it exists).

## Steps
1. Read the practice path's blank handling and reuse its definition (null, empty, whitespace-only; for speech also a missing media reference).
2. Read `ScoringIngestService` and `AiScoringWorker` end to end; choose the single place where a blank answer becomes a completed evaluation with score 0 and no vendor call.
3. Implement it without changing scoring of non-blank answers or objective (non-AI) scorers.
4. Check how the host result view reads a 0/blank evaluation (no new status values unless unavoidable).
5. Note (do not fix): how a task with no row at all is treated (plan Unresolved 1).

## Tests
- Unit test: blank `AI_SPEECH` and blank `AI_TEXT` answers → evaluation completed with 0, `speechScoringClient`/`essayScoringClient` never invoked (verify with mocks).
- Unit test: non-blank answers still reach the vendor clients exactly as before.
- Existing scoring tests (`./mvnw -pl app -am test -Dtest='com.pte.scoring.**.*Test'`) stay green.

## Success Criteria
- Both new tests pass; no existing scoring test changes expectation.
- No change in files outside the scoring package (plus tests).

## Risks
- Different task types encode "no answer" differently (e.g. empty JSON for choices): only AI-scored types are in scope; objective scorers already score empty as wrong.
- Real vendor runs are forbidden without the credit estimate; tests use mocks only.

## Execution Log

### Errors Encountered
- `./gradlew: No such file or directory` — the plan named Gradle commands, but pte-api builds with Maven.
- My first wait loop matched `DB_CLOSE_ON_EXIT=` in the Maven log and reported 1563 tests before the run had finished (false "done" signal, not a code error).

### Root Cause
- The plan was written without checking the build tool. The wait loop grepped for `EXIT=` unanchored.

### Resolution
- Used `./mvnw`; fixed the commands in plan.md, phase-01 and phase-04. Re-waited on the anchored `^EXIT=` marker.
- Implementation: `AiScoringWorker.onAiScoringJob` returns a constant 0-score result (REAL category, provider `blank-answer-rule`) when the payload is null or blank, after the stale-token, publication-lock and content-gone checks and before `callVendor`; two constants added to `ScoringConstants`; three tests plus assertion helper added to `AiScoringWorkerTest`.
- Code review (hard mode): APPROVED 7.5/10, 0 critical/high. Tests extended per review (empty-string case, `markScoringFailed` never called, empty sub-scores, null rubric version, feedback).
- Not changed, left for user decision (see plan Risks): "legacy/old data" label for the zero in report explanations.
- Hướng A (user decision at the review gate, fixes the examiner-mode burden): `ScoringIngestService.scoreIfBlank` scores a blank AI row 0 at ingest via `AiEvaluation.markBlankAnswer` (REAL, provider `blank-answer-rule`); the three `isAiEligible` predicates (`ScoringEligibilityQueryService`, `ScoringReviewReadQueryService`, `ScoreSourceSelectionService`) exclude `isScoredAsBlankAnswer()` rows; `GradingCompletionEvaluator` counts them as satisfied like a missing row; the provider/feedback constants moved to `ScoringDomainConstants`. The worker guard stays as a backstop. New tests: 3 in `ScoringIngestServiceTest`, 1 in `GradingCompletionEvaluatorTest`, 1 in `ScoringEligibilityQueryServiceTest`.

- Report label (user asked to fix): added `ItemTraceKind.BLANK_ANSWER`; `RubricRescoreService.traceOf` returns it for provider `blank-answer-rule` with no trait scores (after the examiner and not-scored checks, before the legacy check). Test `aBlankAnswerScoredZeroIsExplainedAsBlankNotAsLegacyData` added to `RubricRescoreServiceTest`.

### Test Results After Fix
- After the label fix: `./mvnw -q -pl app -am test -Dtest='com.pte.scoring.**.*Test,com.pte.reporting.**.*Test'` → EXIT=0; scoring + reporting reports: 1688 tests, 0 failures, 0 errors (RubricRescoreServiceTest 10).
- After Hướng A: `./mvnw -q -pl app -am test -Dtest='com.pte.scoring.**.*Test'` → EXIT=0, 1575 tests, 0 failures, 0 errors (ScoringIngestServiceTest 11, GradingCompletionEvaluatorTest 4, ScoringEligibilityQueryServiceTest 3, AiScoringWorkerTest 25).
- `./mvnw -pl app -am test -Dtest='com.pte.scoring.**.*Test'` → EXIT=0, 1569 tests, 0 failures, 0 errors, 29 skipped (before the review tweaks).
- `./mvnw -pl app -am test -Dtest='AiScoringWorkerTest'` (after the tweaks) → EXIT=0, 25 tests, 0 failures, 0 errors.
- Full `./mvnw test` not run; it belongs to Phase 4.
