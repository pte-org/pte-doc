# Phase 3: AnswerPayloadDecoder Enhancements

**Covers:** FR-03 · Decoder support for FILL_BLANKS_LISTENING and HIGHLIGHT_INCORRECT_WORDS
**Depends on:** Phase 1 (contract document), Phase 2 (tests establish expected behavior)

---

## Requirements

Extend `AnswerPayloadDecoder` to recognize and decode FILL_BLANKS_LISTENING (positional typed-gap values via comma-separated text entries with trailing-empty entries for unfilled gaps) and HIGHLIGHT_INCORRECT_WORDS (comma-separated word indices over the transcript text, not option indices). Add new `AnswerPayloadKind` enum values POSITIONAL_SELECTION (for typed-gap values) and WORD_INDICES (for transcript word-index selections); add corresponding new nullable fields to `DecodedAnswerPayload`; update the decoder logic to recognize these via task-type set checks (following the existing `AUDIO_ANSWER_TASK_TYPES` pattern); update `AnswerPayloadKind` javadoc to remove the note about "7 Listening types whose encoding is unverified" — Phase 3 tests verify the 2 new shapes end-to-end; preserve the existing generic TEXT/SELECTION fallback for the 5 remaining types and use UNRECOGNIZED only for malformed or unparseable payloads.

---

## Design Constraints

- Preflight: `ScoringConstants` does not yet define the two structured Listening task-type constants, so Phase 3 adds them. `DecodedAnswerPayload` is constructed in `AnswerPayloadDecoder` and `ScoringReviewService`; both ownership sites must preserve the new nullable fields. The decoder must keep typed gap text verbatim, preserve empty positional entries as `null`, reject malformed word-index tokens, and leave the five remaining Listening types on the existing generic TEXT/SELECTION paths.
- **Shape-driven by default, with named task-type sets for disambiguation.** The decoder's logic branches on (a) task type via named sets like `AUDIO_ANSWER_TASK_TYPES` (8 Speaking types), (b) `optionsJson` non-nullness → SELECTION, (c) else → TEXT. This is NOT a per-task-type switch (one arm per type) — it is shape-driven with explicit task-type sets for cases where shape alone is insufficient. Adding `HIGHLIGHT_INCORRECT_WORDS_TASK_TYPES` and `FILL_BLANKS_LISTENING_TASK_TYPES` sets follows this exact precedent.

- **Task-type checks are necessary for the 2 new kinds** because their payload shapes are ambiguous:
  - `HIGHLIGHT_INCORRECT_WORDS` payload `3,7,11` is byte-identical in shape to `MC_LISTENING_MULTIPLE`'s `0,2,3` (both are comma-separated integers). Only the task type distinguishes transcript-word indices from option orderIndexes. Shape alone is provably insufficient.
  - `FILL_BLANKS_LISTENING` payload `rapid,,forest,` contains typed text values, commas and trailing empties, but so could a hypothetical TEXT answer with commas in it (e.g., "yes, no, maybe"). The trailing-empty-commas convention is too weak to key on without task type. Shape alone cannot reliably disambiguate.

- `DecodedAnswerPayload` must add new nullable fields (not reuse existing ones like `options`). The record's own javadoc codifies the convention: flat nullable fields, mutually exclusive per `kind`, explicitly "not a polymorphic subtype hierarchy." Reusing `options` would violate this and break existing SELECTION consumers' assumption that entries are `AnswerOptionView` objects.

- The decoder's class-level and `AnswerPayloadKind` enum-level javadoc must be updated to reflect that 2 of the 7 previously-unverified types (FILL_BLANKS_LISTENING, HIGHLIGHT_INCORRECT_WORDS) are now verified end-to-end. The 5 remaining types may continue through generic TEXT/SELECTION fallback; UNRECOGNIZED remains for malformed or unparseable payloads.

- All construction sites of `DecodedAnswerPayload` must be audited and updated; adding record components breaks all callers at compile time — say so explicitly in steps.

---

## Steps

1. Review the current `DecodedAnswerPayload` record definition (services/scoring/src/main/java/com/pte/scoring/dto/response/DecodedAnswerPayload.java); record its current fields and javadoc. Typically: `(AnswerPayloadKind kind, String text, UUID mediaPublicId, List<AnswerOptionView> options, String mediaUrl)`.

2. Determine the exact new nullable fields to add for POSITIONAL_SELECTION and WORD_INDICES kinds:
   - For POSITIONAL_SELECTION (FILL_BLANKS_LISTENING): add `List<String> gapValues` (nullable, contains one string per gap — the typed value for filled gaps, null for unfilled gaps with trailing-empty semantics). Do not parse these values as integers; the FE encoder sends typed text, not option indices.
   - For WORD_INDICES (HIGHLIGHT_INCORRECT_WORDS): add `List<Integer> wordIndices` (nullable, contains the transcript word indices as integers).
   - Update `DecodedAnswerPayload`'s javadoc to document all fields and their per-kind usage (e.g., "kind=POSITIONAL_SELECTION → gapValues is set, all others null"; "kind=WORD_INDICES → wordIndices is set, all others null").

3. Add two new `AnswerPayloadKind` enum values to `pte-api/services/scoring/src/main/java/com/pte/scoring/dto/response/AnswerPayloadKind.java`: POSITIONAL_SELECTION (for gap-based encoding) and WORD_INDICES (for transcript word-index selections); add javadoc to each explaining what the `DecodedAnswerPayload` response contains.

4. Update `AnswerPayloadDecoder.java` class-level javadoc to document the design: "Deliberately NOT a 23-way switch over PteTaskType — instead, logic is shape-driven: (a) task type in AUDIO_ANSWER_TASK_TYPES → AUDIO kind; (b) optionsJson non-null → SELECTION kind; (c) task type in HIGHLIGHT_INCORRECT_WORDS_TASK_TYPES → WORD_INDICES kind; (d) task type in FILL_BLANKS_LISTENING_TASK_TYPES → POSITIONAL_SELECTION kind; (e) else → TEXT kind. Task-type sets are used only where shape is insufficient to disambiguate (transcript word indices vs. option indices; gap values vs. free text). The 5 remaining Listening types are not yet verified end-to-end and continue through the existing generic TEXT/SELECTION fallback; malformed payloads use UNRECOGNIZED."

5. Add static final Set fields to `AnswerPayloadDecoder` (after the existing `AUDIO_ANSWER_TASK_TYPES`):
   ```java
   private static final Set<String> HIGHLIGHT_INCORRECT_WORDS_TASK_TYPES = Set.of(ScoringConstants.TASK_TYPE_HIGHLIGHT_INCORRECT_WORDS); // or just the string
   private static final Set<String> FILL_BLANKS_LISTENING_TASK_TYPES = Set.of(ScoringConstants.TASK_TYPE_FILL_BLANKS_LISTENING);
   ```
   (or equivalent if ScoringConstants already has these; check the file first.)

6. Update `AnswerPayloadDecoder.decode()` method to add new branches (in order, before the final TEXT fallback):
   - After the AUDIO branch, add a FILL_BLANKS_LISTENING branch: `if (FILL_BLANKS_LISTENING_TASK_TYPES.contains(answer.getTaskType()) && answer.getOptionsJson() == null) { return decodePositionalSelection(answer); }`
   - After the SELECTION branch, add a HIGHLIGHT_INCORRECT_WORDS branch: `if (HIGHLIGHT_INCORRECT_WORDS_TASK_TYPES.contains(answer.getTaskType()) && answer.getOptionsJson() == null) { return decodeWordIndices(answer); }`

7. Implement two new private methods in `AnswerPayloadDecoder`:
   - `decodePositionalSelection(ScoringAnswer answer)`: parse comma-separated text values from payload with `split(",", -1)`, preserving trailing-empty entries as null; return `new DecodedAnswerPayload(AnswerPayloadKind.POSITIONAL_SELECTION, null, null, null, null, gapValues, null)` (the extra `null` preserves the existing `mediaUrl` position).
   - `decodeWordIndices(ScoringAnswer answer)`: parse comma-separated integers from payload; return `new DecodedAnswerPayload(AnswerPayloadKind.WORD_INDICES, null, null, null, null, null, wordIndices)`.

8. Audit every constructor/creation site of `DecodedAnswerPayload` in the decoder:
   - Line ~70 (AUDIO branch)
   - Line ~75 (SELECTION branch)
   - Line ~75 (TEXT fallback, line numbers are approximate — verify in actual file)
   - And the two new branches created in Step 6.
   Update all sites to pass the new nullable fields (null, null) or (gapValues, null) or (null, wordIndices) as appropriate; all sites will fail to compile until updated (this is expected).

9. Update `AnswerPayloadKind.java` javadoc (enum-level comment) to:
   - Remove/revise the phrase "7 Listening task types whose encoding has never been implemented/verified".
   - State "5 remaining Listening task types (SUMMARIZE_SPOKEN_TEXT, MC_LISTENING_MULTIPLE, HIGHLIGHT_CORRECT_SUMMARY, SELECT_MISSING_WORD, WRITE_FROM_DICTATION) are not yet verified end-to-end; FILL_BLANKS_LISTENING and HIGHLIGHT_INCORRECT_WORDS were verified in phase 3 of the listening contract plan."
   - Update UNRECOGNIZED's javadoc to say "Payload did not match a known shape or was malformed"; do not describe valid but unverified task types as UNRECOGNIZED when the existing generic TEXT/SELECTION path can represent them.

10. Verify that Phase 3's Java decoder fixture test passes for FILL_BLANKS_LISTENING and HIGHLIGHT_INCORRECT_WORDS entries; if the test fails, iterate on the decoder implementation (check field names, null handling, text parsing and integer parsing).

---

## Success Criteria

- `AnswerPayloadKind` enum has two new values (POSITIONAL_SELECTION, WORD_INDICES) with clear javadoc.
- `DecodedAnswerPayload` has new fields `gapValues: List<String>` and `wordIndices: List<Integer>` (both nullable; `gapValues` may contain null entries for unanswered gaps).
- Decoder successfully decodes FILL_BLANKS_LISTENING fixtures: parses comma-separated text values, preserves trailing nulls for unfilled gaps, returns POSITIONAL_SELECTION kind with gapValues populated.
- Decoder successfully decodes HIGHLIGHT_INCORRECT_WORDS fixtures: parses comma-separated word indices, returns WORD_INDICES kind with wordIndices populated.
- All existing `DecodedAnswerPayload` construction sites (at least 4 in decoder) are updated to provide values for new fields.
- Phase 2's Java test passes for FILL_BLANKS_LISTENING and HIGHLIGHT_INCORRECT_WORDS fixture entries.
- Existing decoder tests (TEXT, SELECTION, AUDIO) still pass (no regressions).
- Javadoc in `AnswerPayloadDecoder` and `AnswerPayloadKind` updated; references to "7 unverified Listening types" removed and replaced with "5 remaining types" and the list of which 2 were verified, while keeping UNRECOGNIZED reserved for malformed payloads.

---

## Quality and Testing State

- Quality gate: **approved**, 0 blocking findings. Cryptographic receipt skipped because reviewed files live in the separate `pte-api` repository while the plan/report lives in `pte-doc`. Report: `quality/phase-03-decoder-enhancements-quality-report.json`.
- Testing: **passed**, 57/57 full scoring reactor tests passed (24 `pte-common` + 33 scoring), including 5/5 decoder fixture/regression tests. Report: `tests/phase-03-decoder-enhancements-test-report.json`.

---

## Risks

- **Record field addition breaks all callers**: Adding `gapValues` and `wordIndices` to the `DecodedAnswerPayload` record changes its signature; all sites constructing it must provide values for the new fields or compilation fails. Mitigation: Step 8 audits all sites; compilation failure is the desired signal to update them. Estimated: 4–6 sites in the decoder itself; any external constructors will also fail (search for "new DecodedAnswerPayload" across the codebase before committing).
- **Trailing-empty gap parsing edge cases**: FILL_BLANKS_LISTENING with 3 gaps, all unfilled, should yield `[null, null, null]`. If the parser incorrectly handles empty strings between commas, it will produce wrong results. Mitigation: Phase 3's Java decoder test includes an all-empty case; `split(",", -1)` preserves trailing empties and the parser maps empty values to null without integer conversion.
- **Task-type constant names**: If ScoringConstants doesn't already have `TASK_TYPE_HIGHLIGHT_INCORRECT_WORDS` or `TASK_TYPE_FILL_BLANKS_LISTENING`, they must be added. Mitigation: Step 5 checks the file first; if constants are missing, add them (or hardcode the string literals in the Set, though constants are preferred for consistency).

---

## File Ownership

- `pte-api/services/scoring/src/main/java/com/pte/scoring/service/ScoringReviewService.java` — Phase 3 updates its reconstructed `DecodedAnswerPayload` to preserve new fields

- `pte-api/services/scoring/src/main/java/com/pte/scoring/dto/response/AnswerPayloadKind.java` — Phase 3 owns enum update
- `pte-api/services/scoring/src/main/java/com/pte/scoring/dto/response/DecodedAnswerPayload.java` — Phase 3 owns new field addition and record rewrite
- `pte-api/services/scoring/src/main/java/com/pte/scoring/service/AnswerPayloadDecoder.java` — Phase 3 owns decoder branch additions and all construction site updates
- `pte-api/services/scoring/src/main/java/com/pte/scoring/constant/ScoringConstants.java` — Phase 3 may add new TASK_TYPE constants if missing
- `pte-api/services/scoring/src/test/java/com/pte/scoring/service/AnswerPayloadDecoderFixtureTest.java` — Phase 3 owns decoder fixture assertions for the two new response kinds
