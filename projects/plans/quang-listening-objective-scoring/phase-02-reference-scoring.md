# Phase 2: Typed, Token and Dictation Reference Scoring

## Requirements

Implement deterministic scoring for `FILL_BLANKS_LISTENING`,
`HIGHLIGHT_INCORRECT_WORDS`, and `WRITE_FROM_DICTATION`. Their answer-key
encodings are stored in the existing opaque `ScoringAnswer.correctAnswerText`
field and are frozen before code consumes them.

## Reference Contract

- `FILL_BLANKS_LISTENING`: `correctAnswerText` is a JSON string array with one
  expected answer per gap, in gap-index order, for example
  `["rapid","forest"]`. Each value is a non-blank expected word/phrase;
  scoring compares case-insensitively after trimming and collapsing internal
  whitespace. No fuzzy or alternate-answer matching is introduced here.
- `HIGHLIGHT_INCORRECT_WORDS`: `correctAnswerText` is a JSON integer array of
  zero-based transcript token positions, for example `[3,7,11]`. Values must
  be non-negative and unique; the student payload remains the v1 sorted,
  comma-joined index string.
- `WRITE_FROM_DICTATION`: `correctAnswerText` is the canonical sentence in
  plain text. Both reference and submitted text are tokenized deterministically
  with case folding and boundary punctuation removal; ordered matching uses
  the longest common subsequence. Score is the percentage of reference words
  matched, rounded to the nearest integer.

These are application reference conventions, not a claim that the current
authoring UI already produces valid reference JSON. Malformed references score
0 and never throw or silently receive credit.

## Design Constraints

- Extend `ObjectiveScoringService`; do not add columns or change events/API
  shapes. `ScoringCommandConsumer` already routes supported objective types.
- FBL and WFD award one unit per correctly matched word with no negative
  marking. HIW uses Pearson's +1/-1 partial-credit rule, floored at zero and
  normalized against the number of expected incorrect tokens.
- Empty student answers score 0. Empty/malformed answer keys score 0.
- Preserve the established 0-100 raw-score scale.
- Keep parsing helpers private to scoring until a second consumer proves a
  shared abstraction is justified.

## Steps

1. Add `WRITE_FROM_DICTATION` to scoring constants and supported objective
   types.
2. Add strict reference parsers for FBL JSON string arrays and HIW JSON integer
   arrays; reject malformed, negative, duplicate, or empty reference data.
3. Add FBL positional word scoring with trailing-empty payload preservation.
4. Add HIW set scoring with correct-selection credit and wrong-selection
   deductions.
5. Add WFD deterministic tokenization and ordered LCS word scoring.
6. Add unit tests for full, partial, empty, malformed-reference, punctuation,
   repeated-word, missing-word, extra-word, and deduction cases.

## Success Criteria

- All three task types return true from `supports()` and are reachable through
  `score()`.
- FBL, HIW and WFD tests cover the reference contract and partial-credit edge
  cases.
- Malformed reference data always scores 0.
- Full scoring Maven reactor passes with no skipped tests.

## Quality and Testing State

- Quality gate: **approved**, 0 blocking findings. Report:
  `quality/phase-02-reference-scoring-quality-report.json`.
- Testing: **passed**, 40 focused tests and 78 full scoring-reactor tests. Report:
  `tests/phase-02-reference-scoring-test-report.json`.

## File Ownership

- `pte-doc/projects/fixtures/listening-payload-contract.md`
- `pte-api/services/scoring/src/main/java/com/pte/scoring/constant/ScoringConstants.java`
- `pte-api/services/scoring/src/main/java/com/pte/scoring/service/ObjectiveScoringService.java`
- `pte-api/services/scoring/src/test/java/com/pte/scoring/service/ObjectiveScoringServiceTest.java`
