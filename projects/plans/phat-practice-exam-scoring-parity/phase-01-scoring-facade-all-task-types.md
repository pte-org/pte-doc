# Phase 1: Scoring Facade for All Task Types

Dependencies: none. Blocks Phase 2.

## Requirements
The scoring module exposes one public, persistence-free entry that scores a single answer of any of the 23 task types with the same scorers the exam uses, returning a public result or a public failure reason instead of swallowing errors.

## Files
Base: `d:\FPT\9thSemester\pte\pte-api\app\src\main\java\com\pte\scoring\` (and test mirror under `app\src\test\java\com\pte\scoring\`).
- Add: public result and failure-enum types next to the existing `PracticeAiEvaluation` (generalize it additively; the old speech adapter stays compiling and in use until Phase 2 switches over); a public request type carrying task type, canonical payload, prompt text, reference answer, correct answer, image ref, word limits, tenant and the frozen options needed by objective scoring.
- Change: `ScoringService.java` (add the practice scoring method); `internal/service/PracticeAiScoringService.java` (generalize from speech-only to AI speech plus AI text, route objective types to `ObjectiveScoringService`, expose failure reasons); `PracticeAiEvaluation.java` (extend with score status, failure code).
- Read-only references: `internal/vendor/AiScoringRequest.java`, `internal/vendor/AiScoreResult.java`, `internal/service/ObjectiveScoringService.java`, `internal/service/AnswerPayloadDecoder.java`, `TaskRuntimeProfileRegistry` (itembank).
- Tests add/update: `PracticeAiScoringServiceTest` (new or extended), a parity test iterating all 23 task types, `src/test/java/com/pte/ModuleStructureTest.java` (no change yet).

## Steps
1. Define the public request, result and failure vocabulary (provider unavailable, invalid payload, unsupported type, budget exceeded, internal) in the scoring module's public package.
2. Resolve the scoring route per task type from the same profile table the exam uses, so AI speech, AI text, objective and unscored types are classified identically.
3. Extend the practice scoring service to run AI text types through their scorers and objective types through the objective service, reusing exam payload conventions and 0-100 scale.
4. Stop swallowing scorer errors: translate them into the public failure reasons and keep the candidate content out of logs.
5. Keep the result hash and fallback marking so a stored practice result can be compared and flagged like an exam result.
6. Expose the entry through the scoring facade only; confirm no practice code needs scoring internals.
7. Write unit tests per route (speech, text, objective, unscored, unsupported) and a parity test that every one of the 23 types maps to a route with a scorer or an explicit "unscored".

## Success Criteria
- Running the scoring module tests passes, including a parity test that fails if any of the 23 types has no route.
- A grep for `com.pte.scoring.internal` inside `com/pte/practice` shows no new matches.
- A scorer exception yields a failure reason, never an empty result with no cause.
- Objective scoring through the facade matches exam scoring for the same inputs (same raw score).

## Risks
- Objective option snapshots differ between practice questions and exam answers: build the objective input from the same frozen-option shape; cover with fixtures for each objective type.
- Public enum becomes a contract Phase 2 persists: keep names stable and string-persistable.
- Hidden coupling to exam entities in the objective service: if it needs an exam answer object, add a thin adapter inside the scoring module rather than leaking entities.
- Rollback: the change is additive; revert the facade method and keep the old speech adapter until Phase 2 switches over.

## Execution Log
<!-- Filled by /ck:cook at the end of this phase — leave placeholders when planning -->

### Errors Encountered
- No test or build failures during implementation. Stale surefire reports in `app/target/surefire-reports` gave inflated totals (2595 tests); filtered by modification time to get real numbers.
- Process deviation: the 12 `PracticeAiScoringServiceTest` tests were written together with the implementation, so no separate red run was observed for them. The three `ScoringServiceTest` facade tests were run red first (compile error: `scorePracticeAnswer` / `practiceScoringRoute` not found), then green.
- code-reviewer verdict PASS-WITH-NOTES (no CRITICAL/HIGH): test gaps, null request NPE, `retryAfter` dropped, any non-`AiProviderException` mapped to non-retryable `INTERNAL`.

### Root Cause
- Review items came from the first cut covering only the happy paths and route parity. `score(null)` had no guard; hash determinism, the speech-only adapter contract and `toString` log-safety had no tests.
- `INTERNAL` for unclassified exceptions matches the exam: `AiScoringWorker` has no container retry and fails the job on the DLQ with `INTERNAL_ERROR`, so this is parity, not a regression.

### Resolution
- Added a null-request guard (`INVALID_PAYLOAD`) and 4 tests: hash stable/sensitive, null request, `toString` never prints answer/transcript/detail, `evaluateSpeech` contract kept.
- Simplify pass: runtime profile resolved once per score, dead `default` arm removed (`ScoringMethod` has exactly 4 values), hash helper tightened, failure-mapping test now covers all 11 `AiFailureReason` values.
- Deliberately not done: shared vendor dispatcher with `AiScoringWorker` (would touch the exam worker); merging with `ScoringService.evaluatePracticeObjective` (removed in Phase 2/3).
- Carry to Phase 2: `AiProviderException.retryAfter` is dropped by the facade; never log a `PracticeScoringException` cause message/stack (vendor text may echo content); `evaluateSpeech` now runs inside the 90 s `AiJobBudget`; `resultHash` format changed (no production data, do not compare with old hashes).

### Test Results After Fix
- `./mvnw -q -pl app test '-Dtest=com.pte.scoring.**.*Test,ModuleStructureTest'`: 646 run, 0 failures, 0 errors, 16 skipped (baseline before the phase: 624 / 0 / 16). `PracticeAiScoringServiceTest` 16/16, `ScoringServiceTest` 7/7.
- `grep com.pte.scoring.internal` under `com/pte/practice`: 0 matches.
