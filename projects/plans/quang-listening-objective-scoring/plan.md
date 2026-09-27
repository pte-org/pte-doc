# Plan: Listening Objective Scoring — Deterministic Listening Slice

**Date:** 2026-09-12
**Status:** Phase 1-2 complete; deferred scoring slices remain
**Mode:** Hard
**Scope:** `pte-api/services/scoring`

## Objective

Extend the existing synchronous `ObjectiveScoringService` to cover all seven
deterministically scorable Listening task types whose payload and answer-key
shapes are frozen in the shared contract: the four option-based types plus
`FILL_BLANKS_LISTENING`, `HIGHLIGHT_INCORRECT_WORDS`, and
`WRITE_FROM_DICTATION`. The existing `ScoringCommandConsumer` already routes
any supported objective type, so this slice must not change the event,
persistence, or state-machine contract.

The slice also fixes an existing fail-closed defect where malformed or empty
Re-order Paragraph options could be treated as a one-item task and score 100.

## Phases

- [x] Phase 1: Option-Based Listening Scoring — add constants, support routing,
  regression tests for all four Listening types, and the Re-order malformed
  options guard. [quality: approved; testing: passed]
- [x] Phase 2: Typed/Token/Dictation Reference Scoring — freeze the
  `correctAnswerText` reference encodings for FBL/HIW/WFD, add deterministic
  partial-credit scoring and tests. [quality: approved; testing: passed]

## Explicitly Deferred

- Production content migration remains deferred until authoring fixtures use
  the frozen FBL/HIW/WFD answer-key encodings. Malformed references fail
  closed at zero.
- `SUMMARIZE_SPOKEN_TEXT`, six Speaking types, and
  `SUMMARIZE_WRITTEN_TEXT` until the AI scoring contract/provider work is done.
- Late answer-ingestion reconciliation, duplicate command serialization, seed
  data, score aggregation, and real AI providers. These are separate phases;
  this slice does not pretend to make the full exam scoring-complete.

## Design Constraints

- Reuse the existing `optionsJson` frozen option shape and the v1 payload
  contract: `correct=true` identifies answer keys and payload contains decimal
  `orderIndex` values.
- Single-answer Listening types score binary 0 or 100. Multiple-answer uses
  the existing PTE-style `+1` correct / `-1` incorrect, floored at zero, then
  normalizes to the service's shared 0–100 raw-score scale.
- `supports(null)` must return false rather than throwing. Unsupported task
  types continue to fail fast from `score()` and remain outside this slice.
- Malformed/empty Re-order options must never receive automatic full credit.
- No `Question`, `ScoringAnswer`, event, database, API, or frontend schema
  changes are permitted.
- Pearson's current Listening format describes single-answer,
  Highlight Correct Summary, and Select Missing Word as correct/incorrect
  scoring, and Multiple Answer as partial credit with deductions for incorrect
  selections. The implementation follows those rules at the existing 0–100
  internal scale.

## Success Criteria

- `ObjectiveScoringService.supports()` returns true for all seven new types and
  false for unsupported/null values.
- All seven new types are scored through the existing `score()` entry point,
  with correct/incorrect/empty, malformed-reference, and partial-credit cases covered.
- Existing Reading scoring tests remain green.
- Malformed or empty Re-order options score 0 rather than 100.
- Full scoring Maven reactor passes with no skipped tests.

## Risks

- The service currently stores a 0–100 raw score, while older plan prose says
  0/1. This slice preserves the established implementation scale and tests it;
  report aggregation remains a separate audit item.
- A scoring command can still race late answer ingestion; no safe fix is
  included here because it changes command lifecycle semantics.

## Quality and Testing State

- Phase 1 quality gate: approved, 0 blocking findings. Report:
  `quality/phase-01-option-based-scoring-quality-report.json`.
- Phase 1 testing: passed, 29 focused tests and 65 full scoring-reactor tests. Report:
  `tests/phase-01-option-based-scoring-test-report.json`.
- Phase 2 quality gate: approved, 0 blocking findings. Report:
  `quality/phase-02-reference-scoring-quality-report.json`.
- Phase 2 testing: passed, 40 focused tests and 78 full scoring-reactor tests. Report:
  `tests/phase-02-reference-scoring-test-report.json`.

## File Ownership

- `pte-api/services/scoring/src/main/java/com/pte/scoring/constant/ScoringConstants.java`
- `pte-api/services/scoring/src/main/java/com/pte/scoring/service/ObjectiveScoringService.java`
- `pte-api/services/scoring/src/main/java/com/pte/scoring/domain/event/AnswerScoredEvent.java` (JavaDoc contract correction)
- `pte-api/services/scoring/src/test/java/com/pte/scoring/service/ObjectiveScoringServiceTest.java`
