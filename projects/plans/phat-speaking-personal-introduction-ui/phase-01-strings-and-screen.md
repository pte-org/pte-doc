# Phase 1: Strings + PersonalIntroductionScreen

## Requirements
A new `PersonalIntroductionScreen` renders the Personal Introduction instruction text (interpolating the task's prep/response seconds), the existing single-card `AutoRecordStatusCard`, and the scrollable prompt body — fully automatic prep→response→recorded flow, no manual advance control, structurally identical to `ReadAloudScreen`.

## Steps
1. Re-verify the `PERSONAL_INTRODUCTION` backend enum name via grep against `pte-api/services/authoring/.../PteTaskType.java` before writing any code (do not rely solely on this plan).
2. Read `ReadAloudScreen` in full (already done during planning, re-confirm at implementation time) as the literal structural template for lifecycle/scaffold/state-management — **but not** for the instruction-text function shape (see step 3's correction).
3. Add the 3 new instruction-string constants (`personalIntroductionInstructionPrefix/Middle/Suffix`) to `SpeakingWritingStrings`, following the existing `readAloudInstructionPrefix/Middle/Suffix` STRING-NAMING pattern — but **not** `ReadAloudScreen`'s `_instructionText(int responseSeconds)` FUNCTION shape. `ReadAloudScreen._instructionText` takes a single parameter and interpolates `task.responseSeconds` into both the prefix and suffix slots (Read Aloud's prompt has no separate prep-seconds mention). Personal Introduction's target string interpolates two DISTINCT values — `task.prepSeconds` (25) into the first slot and `task.responseSeconds` (30) into the second — which is `DescribeImageScreen._instructionText(int prepSeconds, int responseSeconds)`'s shape, not `ReadAloudScreen`'s. Read `describe_image_screen.dart`'s `_instructionText` alongside `read_aloud_screen.dart`'s and use the 2-parameter version. Verify the fully-interpolated string (with prepSeconds=25, responseSeconds=30) matches the mockup's exact wording — get this wrong and the screen would silently read "In 30 seconds..." instead of "In 25 seconds...".
4. Create `PersonalIntroductionScreen` as a new file, cloning `ReadAloudScreen`'s constructor shape (task, attemptPublicId, recorder, mediaDao, coordinator, syncEngine), `State`/`initState`/`dispose` boilerplate, `AutoRecordCubit` creation, `AutoRecordTimerBridgeMixin` usage, and `ExamScaffold` + `AutoAdvanceOnUploadReady<AutoRecordCubit, AutoRecordState>` wiring.
5. Build the screen's body widget: `InstructionText` using the new interpolated string, `AutoRecordStatusCard(task, recordingState, snapshot)` reused unmodified, and a scrollable `Text(task.promptText ?? '')` for the prompt — no other widgets, no manual advance button.
6. Update class-level and constructor doc comments to describe Personal Introduction's specific behavior (no audio-listening sub-stage, fully automatic), following `ReadAloudScreen`'s doc-comment style.
7. Run `flutter analyze` against the two touched/new files to catch import/lint issues before moving to Phase 2.

## Success Criteria
- `flutter analyze` reports 0 issues for `speaking_writing_strings.dart` and `personal_introduction_screen.dart`.
- The interpolated instruction string, with prepSeconds=25/responseSeconds=30, reads exactly: "Read the prompt below. In 25 seconds, you must reply in your own words, as naturally and clearly as possible. You have 30 seconds to record your response."
- No `Text('literal')` — all user-facing strings come from `SpeakingWritingStrings`.
- The new screen contains no reference to `AudioPromptRecordBody`, `TaskAdvanceButton`, or `FlushableAnswerCubit`.

## Risks
- Deviating from `ReadAloudScreen`'s exact shape (e.g., adding a manual advance button per the screenshot) — mitigated by treating the confirmed architecture, not the screenshot, as authoritative and cross-checking against `ReadAloudScreen` line-by-line.
- HIGH (plan-reviewer ACCEPTED finding): cloning `ReadAloudScreen`'s `_instructionText(int responseSeconds)` single-parameter/double-interpolation shape instead of `DescribeImageScreen`'s 2-parameter shape would silently produce "In 30 seconds... You have 30 seconds..." instead of "In 25 seconds... You have 30 seconds..." — mitigated by step 3's explicit correction and the Success Criteria's literal expected-string check.
- Off-by-one or mismatched wording in the interpolated instruction string versus the mockup — mitigated by an explicit string-match verification step.
