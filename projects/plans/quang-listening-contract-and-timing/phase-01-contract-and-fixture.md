# Phase 1: Contract Ratification & Shared Fixture

**Covers:** FR-01 · Listening payload contract design and documentation
**Depends on:** nothing — can start immediately

---

## Requirements

Document the payload encoding contract for all 8 Listening types (7 unconfigured + the already working MC_LISTENING_SINGLE), recording how each type encodes its answer on the wire. Create a shared JSON fixture file in `pte-doc/projects/fixtures/listening-payload-contract.json` containing one record per type with taskType, optionsJson value, raw payload string, description, and a `contractVersion` integer field (top-level). Ratify that (a) trailing-empty commas are normative for positional payloads, (b) only multi-selection indices are numerically sorted, while single-selection payloads contain exactly one orderIndex, (c) the payload is always a string (never a JSON object), and (d) the delimiter policy for typed gap text is explicit before the contract is frozen. Update `pte-api/services/exam-delivery/src/main/java/com/pte/examdelivery/dto/request/SubmitAnswerRequest.java`'s javadoc to document all 8 Listening payload encodings in the same style as its existing Reading documentation.

---

## Design Constraints

- Preflight: the eight encoder paths exist. `MC_LISTENING_SINGLE`, `HIGHLIGHT_CORRECT_SUMMARY`, and `SELECT_MISSING_WORD` persist one `orderIndex`; `MC_LISTENING_MULTIPLE` and `HIGHLIGHT_INCORRECT_WORDS` persist numerically sorted comma-joined indices; `FILL_BLANKS_LISTENING` uses the shared comma positional serializer; `SUMMARIZE_SPOKEN_TEXT` and `WRITE_FROM_DICTATION` persist raw draft text. `pte-api` keeps `payload` opaque in this phase; only its DTO JavaDoc changes. No decoder, scoring, or timing behavior changes belong here.
- The fixture file must be immutable source-of-truth JSON (not generated); if the encoding contract changes, fixture entries must be manually updated and version bumped.
- Every fixture entry must include a `description` field explaining the encoding for human readers; it must capture the trailing-empty and sorted-index semantics explicitly so a reader doesn't have to infer them.
- The fixture file's schema must be simple: array of objects with string fields, parseable by Dart and Java without special schema libraries.
- The fixture file must carry a top-level `contractVersion: 1` integer field; each repo will vendor its own copy (Phase 2) and assert the version in tests.
- The current FE positional helper joins typed gap values with commas. Before ratification, explicitly decide whether commas inside a typed value are escaped, forbidden/validated, or replaced by a different encoding; do not hide this ambiguity in the fixture.
- FE encoder files are the source of truth: if an encoder file is missing, stop and escalate rather than guessing the fixture payload — inaccurate fixtures are worse than incomplete ones.

---

## Steps

1. Enumerate the 8 Listening task types and their FE source-of-truth encoder locations:

   | Task Type | FE Cubit File | Encoding Method |
   |---|---|---|
   | SUMMARIZE_SPOKEN_TEXT | `pte-app/lib/features/exam_attempt/listening/presentation/cubit/summarize_spoken_text_cubit.dart` | Raw `draftText` |
   | WRITE_FROM_DICTATION | `pte-app/lib/features/exam_attempt/listening/presentation/cubit/write_from_dictation_cubit.dart` | Raw `draftText` |
   | MC_LISTENING_MULTIPLE | `pte-app/lib/features/exam_attempt/listening/presentation/cubit/mc_listening_multiple_cubit.dart` | Comma-joined sorted orderIndexes |
   | HIGHLIGHT_CORRECT_SUMMARY | `pte-app/lib/features/exam_attempt/listening/presentation/cubit/highlight_correct_summary_cubit.dart` | Single orderIndex string |
   | SELECT_MISSING_WORD | `pte-app/lib/features/exam_attempt/listening/presentation/cubit/select_missing_word_cubit.dart` | Single orderIndex string |
   | FILL_BLANKS_LISTENING | `pte-app/lib/features/exam_attempt/listening/presentation/cubit/fill_blanks_listening_cubit.dart` | Positional payload (comma-join, trailing empties for unfilled gaps) — uses `positional_payload.dart` helper |
   | HIGHLIGHT_INCORRECT_WORDS | `pte-app/lib/features/exam_attempt/listening/presentation/cubit/highlight_incorrect_words_cubit.dart` | Comma-joined word indices over transcript |
   | MC_LISTENING_SINGLE | `pte-app/lib/features/exam_attempt/listening/presentation/cubit/mc_listening_single_cubit.dart` | Single `orderIndex` string |

   If any of these encoder files do not exist at the expected path, STOP and escalate to the user with the missing file name and expected path.

2. Create a markdown contract document (`pte-doc/projects/fixtures/listening-payload-contract.md`) describing all 8 Listening payload encodings: for each type, state whether it is free-form text, single option selection, multi-option selection, positional typed text, or transcript word-index selection; for positional typed text, explain the trailing-empty-commas rule, gap-index order and the chosen delimiter policy; for multi-selection, state that orderIndex values are sorted and comma-joined; for single selection, state that exactly one orderIndex string is sent; if transcript word indices are used, explain that indices refer to token positions in the transcript, not option orderIndexes.

3. Design the shared JSON fixture schema as an array of objects with a top-level `contractVersion` field: `{ "contractVersion": 1, "fixtures": [ { "taskType": "...", "optionsJson": "...", "payload": "...", "description": "..." }, ... ] }`. Each fixture object has taskType (string), optionsJson (string or null), payload (string, the raw answer), and description (string, explains the encoding).

4. Populate the fixture file with concrete entries for all 8 types by reading each FE cubit file to derive accurate encodings:
   - SUMMARIZE_SPOKEN_TEXT: `optionsJson: null`, `payload: "The student's summary text"`
   - WRITE_FROM_DICTATION: `optionsJson: null`, `payload: "The dictated text"`
   - MC_LISTENING_MULTIPLE: `optionsJson: "[{\"text\": \"...\", \"orderIndex\": 0}, ...]"`, `payload: "0,2,3"` (sorted indices)
   - HIGHLIGHT_CORRECT_SUMMARY: `optionsJson: "[...]"`, `payload: "1"` (single index)
   - SELECT_MISSING_WORD: `optionsJson: "[...]"`, `payload: "2"` (single index)
   - FILL_BLANKS_LISTENING: `optionsJson: null`, `payload: "rapid,,forest,"` (3 gaps: filled, empty, filled, empty — trailing comma required)
   - HIGHLIGHT_INCORRECT_WORDS: `optionsJson: null`, `payload: "3,7,11"` (word indices, not option indices)
   - MC_LISTENING_SINGLE: `optionsJson: "[...]"`, `payload: "2"` (one orderIndex string)

5. Create the JSON fixture file at `pte-doc/projects/fixtures/listening-payload-contract.json` with `contractVersion: 1` at top level and all 8 entries under a `fixtures` array; add a `_comment` field explaining this is immutable source-of-truth for cross-repo contract tests and should not be forked (both repos vendor copies in Phase 2, but edits go here first, then version bump).

6. Add version/date stamp to both the markdown contract and JSON fixture (e.g., `version: 1`, `date: 2026-09-12`, `lastUpdated: 2026-09-12`).

7. Update `pte-api/services/exam-delivery/src/main/java/com/pte/examdelivery/dto/request/SubmitAnswerRequest.java` to add javadoc documenting all 8 Listening payload encodings, mirroring the style of the existing Reading documentation (which is already present in that file). State the trailing-empty and sorted-index semantics explicitly. Do not change the Java code itself, only the javadoc comment.

8. Verify the fixture file parses correctly by hand-checking JSON syntax and ensuring every taskType value matches a real task type; verify the concrete payload examples against the FE encoders, especially single-choice and typed-gap values; verify SubmitAnswerRequest javadoc compiles (no syntax errors in the comment).

---

## Success Criteria

- A markdown file `pte-doc/projects/fixtures/listening-payload-contract.md` exists, documents all 8 types with explicit trailing-empty and sorted-index rules, and cites cubit file paths.
- A JSON file `pte-doc/projects/fixtures/listening-payload-contract.json` exists with `contractVersion: 1` at top level, 8 fixture entries (one per type), each with taskType, optionsJson, payload, and description fields populated.
- The JSON is valid (parseable by standard JSON tools with no errors).
- The fixture file contains a `_comment` noting it is source-of-truth and should not be forked.
- `SubmitAnswerRequest` javadoc includes documentation for all 8 Listening encodings (not just summary — state the actual format for each type).
- The phase diff contains both fixture files and the `SubmitAnswerRequest` documentation update together; committing is handled by the repository owner outside this phase.

---

## Quality and Testing State

- Quality gate: **approved**, 0 blocking findings and 1 NOTED pre-existing delimiter-enforcement gap. Cryptographic receipt skipped because the plan/report and reviewed source span separate git repositories. Report: `quality/phase-01-contract-and-fixture-quality-report.json`.
- Testing: **passed**, 115/115 Maven tests passed (24 `pte-common` + 91 `exam-delivery`), plus fixture JSON/schema validation and compile. Report: `tests/phase-01-contract-and-fixture-test-report.json`.

---

## Risks

- **Encoding mismatch risk**: If an FE encoder has changed since last delivery, the fixture will be outdated. Mitigation: Phase 1 Step 1 explicitly reads each cubit file to derive fixture values; if discrepancies found, stop and escalate (do not guess).
- **Fixture schema parsing errors**: If the fixture file has a trailing comma or missing field, both repos' tests will fail to load it. Mitigation: Phase 1 Step 8 validates JSON syntax before committing.
- **taskType string typos**: If a fixture entry uses a misspelled task type, tests will silently fail to find it. Mitigation: Phase 1 Step 8 validates every taskType against known types.
- **SubmitAnswerRequest javadoc sync**: If SubmitAnswerRequest is later refactored and its javadoc is lost, the documentation is gone. Mitigation: Phase 1 targets a stable location (class-level javadoc on the request DTO); document this assumption in commit message.

---

## File Ownership

- `pte-doc/projects/fixtures/listening-payload-contract.md` — Phase 1 creates and owns
- `pte-doc/projects/fixtures/listening-payload-contract.json` — Phase 1 creates and owns (both repos vendor copies in Phase 2)
- `pte-api/services/exam-delivery/src/main/java/com/pte/examdelivery/dto/request/SubmitAnswerRequest.java` — Phase 1 updates javadoc only
