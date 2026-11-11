# Phase 2: On-demand scoring in the practice module

## Goal

Speech and writing answers are saved without scoring. The student starts scoring for one item (TASK/SKILL) or for the whole submitted mock test.

## Work

- `PracticeAnswerScoringRouter.scoreOrQueue`:
  - `OBJECTIVE` is scored inline, unchanged.
  - `AI_SPEECH` / `AI_TEXT` now only record the answer. `scoringStatus` stays `NONE`, which means "ready to score".
- New endpoint `POST /practice-sessions/{publicId}/items/{itemPublicId}/scoring` for TASK/SKILL items.
  - It is allowed only for an answered AI item in `NONE`.
  - `SCORING` / `SCORED` with the same answer returns `409 PRACTICE_SCORING_ALREADY_REQUESTED`.
  - On success: `startScoring`, which uses the existing worker queue.
- New endpoint `POST /practice-sessions/{publicId}/scoring` for MOCK_TEST.
  - It is allowed after the test is submitted.
  - It queues every answered AI item still in `NONE` and returns how many were queued. Calling it again queues nothing new.
- Re-doing an item:
  - Any new answer to an item (new recording or text) resets `scoringStatus` to `NONE` and clears the previous evaluation.
  - That is the only way to score an item again.
  - The existing `scoring/retry` stays for `FAILED`.
- Session and progress summaries:
  - An unscored AI item counts as "chưa chấm", not as 0.
  - The mock test report is final only when no item is in `NONE` or `SCORING`.
- Tenant and ownership checks are the same as the answer endpoint: only the session owner.
- Error codes and messages go in `PracticeConstants`.

## Files

- `practice/internal/service/PracticeAnswerScoringRouter.java`, `PracticeScoringStateService.java`, `PracticeResponseService.java`
- `practice/internal/controller/PracticeSessionController.java` (2 endpoints)
- `practice/internal/constant/PracticeConstants.java`
- The API inventory (`ApiInventoryExportTest`) is updated with the 2 new endpoints.

## Tests

- An AI answer is saved with `NONE` and nothing is queued.
- The request moves it to `SCORING` and queues one job.
- A second request returns 409.
- A new answer resets to `NONE`.
- The mock test request queues only the `NONE` AI items and is idempotent.
- Another user's session is rejected.
