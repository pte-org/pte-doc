# Phase 1: Shared Groundwork + Regression Gate

## Requirements
Generalize the two Read-Aloud-only pieces that a second auto-record task type needs to reuse (upload-ready auto-advance, instruction text) and rename the label/dimension constants they share, with zero observable change to the already-shipped Read Aloud screen.

## Steps
1. Add a thin upload-tracking marker interface (one getter: `uploadStatus`) and have `ReadAloudState` implement it — additive, no behavior change.
2. Replace the Read-Aloud-specific auto-advance widget with a generic version parameterized over any bloc/state pair that exposes upload-tracking status, preserving its exact internal guard/listen logic.
3. Replace the Read-Aloud-specific instruction-text widget with a plain text-driven version; `ReadAloudScreen` now computes and passes its own templated string.
4. Relocate the shared recording-phase enum to its own file so a second consumer can import it without going through `read_aloud_state.dart`.
5. Rename these specific `AppStrings`/`AppDimensions` identifiers to neutral names (all reused by Repeat Sentence's listening card and/or "Recorded Answer" card, per the confirmed layout — the listening card's status label during prep is literally "Beginning in N seconds", the same wording Read Aloud's prep phase already uses) and update every call site: `readAloudBeginningInPrefix`, `readAloudBeginningInSuffix`, `readAloudCurrentStatusLabel`, `readAloudRecordingStatusPrefix`, `readAloudRecordingStatusSuffix`, `readAloudStillUploadingLabel`, `readAloudUploadReadyLabel`, `readAloudProgressBarHeight`, `readAloudProgressBarRadius`. Leave the instruction-template strings (`readAloudInstructionPrefix`/`Middle`/`Suffix`) and the `readAloudAnswerCardTitle` ("Recorded Answer") name as-is — the template is genuinely Read-Aloud-only (Repeat Sentence's instruction is a fixed string, not templated), and the card title's literal text is reused by Repeat Sentence but the constant name itself doesn't need to change since "Recorded Answer" is correct for both.
6. Update `ReadAloudScreen` to use both generalized widgets; rename the affected auto-advance test file to match the generic widget and update its type arguments; verify the screen test's asserted literal text is unaffected by the constant renames.
7. Run `flutter analyze` and the full `test/unit test/widget` suite; confirm the baseline 252/252 passing count is preserved exactly (only file/name changes, no new or removed test cases in this phase).

## Success Criteria
- `flutter analyze` reports zero issues.
- `flutter test test/unit test/widget` passes with exactly the pre-existing test count green (252/252 baseline), no failures, no skips.
- `ReadAloudScreen` compiles against `AutoAdvanceOnUploadReady<ReadAloudCubit, ReadAloudState>` and a plain `InstructionText`; no file still references the old `ReadAloudAutoAdvance`/`ReadAloudInstructionText` class names.
- No `AppStrings`/`AppDimensions` identifier named `readAloud*` remains for the entries that were renamed as reused (verifiable via a repo-wide search).

## Risks
- Renamed constants leave a stale reference that only surfaces at compile time in a rarely-built file (e.g. a dev-only preview screen): mitigate with `flutter analyze` across the whole project, not just the touched files.
- The generic `AutoAdvanceOnUploadReady` widget's type inference silently picks the wrong bound and compiles but behaves incorrectly: mitigate by keeping the internal `listenWhen`/`_isAdvancing` logic byte-for-byte identical to the original, only changing the class-level generics.
