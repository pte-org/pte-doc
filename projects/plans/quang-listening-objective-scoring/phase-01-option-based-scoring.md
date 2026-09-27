# Phase 1: Option-Based Listening Scoring

## Requirements

Add the four option-based Listening task types to the existing objective
scorer. Use the same frozen option JSON and `orderIndex` payload semantics as
Reading. Add regression coverage and close the malformed Re-order Paragraphs
full-credit path found during review.

## Design Constraints

- Change only scoring constants, `ObjectiveScoringService`, the raw-score event
  JavaDoc, and the objective-scoring unit test.
- `MC_LISTENING_SINGLE`, `HIGHLIGHT_CORRECT_SUMMARY`, and
  `SELECT_MISSING_WORD` use the existing binary single-choice evaluator.
- `MC_LISTENING_MULTIPLE` uses the existing negative-marking evaluator and
  its 0–100 score scale.
- No new persistence field or event field is required because
  `ScoringAnswer.optionsJson` already carries the frozen correct flags.
- Treat null task type as unsupported in `supports()`.
- A malformed/empty Re-order options list must return 0, not 100.

## Steps

1. Add constants for the four Listening option-based task types.
2. Add those constants to `SUPPORTED_TASK_TYPES` and route them through the
   existing single/multiple scoring branches.
3. Make `supports()` null-safe.
4. Make Re-order scoring fail closed when options are missing/malformed; keep
   the valid one-item behavior bounded to a valid submitted position.
5. Add tests for support routing, binary Listening scoring, multiple-answer
   full/partial/incorrect scoring, empty submissions, and malformed Re-order
   options.

## Success Criteria

- Every step is implemented without changing the answer/event schema.
- New tests prove the four types use the expected branches and score scale.
- Existing objective tests and the full scoring reactor pass.

## Quality and Testing State

- Quality gate: **approved**, 0 blocking findings. Report:
  `quality/phase-01-option-based-scoring-quality-report.json`.
- Testing: **passed**, 29 focused tests and 65 full scoring-reactor tests. Report:
  `tests/phase-01-option-based-scoring-test-report.json`.

## File Ownership

- `pte-api/services/scoring/src/main/java/com/pte/scoring/constant/ScoringConstants.java`
- `pte-api/services/scoring/src/main/java/com/pte/scoring/service/ObjectiveScoringService.java`
- `pte-api/services/scoring/src/test/java/com/pte/scoring/service/ObjectiveScoringServiceTest.java`
