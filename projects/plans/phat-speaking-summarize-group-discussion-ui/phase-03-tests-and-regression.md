# Phase 3: Tests and regression gate

## Requirements
The new screen and its dispatcher routing are covered by widget tests matching the codebase's existing test conventions, and the full test/analyze/standards suite passes clean with no regressions introduced.

## Steps
1. Create `test/widget/features/exam_attempt/summarize_group_discussion_screen_test.dart`, mirroring `answer_short_question_screen_test.dart`'s structure exactly: the same 5 mock classes, `_FakePathProviderPlatform`, and a task-builder helper using `prepSeconds: 200, responseSeconds: 120`.
2. Independently re-derive each test case's `remaining`/expected-label values from first principles (`audioSeconds = 200 - 5 - 10 = 185`; `remaining = prepSeconds - elapsed`) rather than copying the plan's pre-derived numbers verbatim, and write the following cases: fixed instruction text renders; elapsed 0s ("Beginning in 5 seconds", Record blank, `recorder.start` never called); elapsed 5s ("Playing 185 seconds left"); elapsed 190s (Listening frozen "Playing 0 seconds left", Record "Beginning in 10 seconds"); elapsed 199s (Record "Beginning in 1 seconds"); response phase (`recorder.start` called once, "Recording 120 seconds left", Listening frozen); full prep→response→recorded transition (`recorder.stop` called once, upload-status card replaces the recording card); `pinnedItemPublicId` mismatch identity-guard case (`recorder.start` never called).
3. Add a `SUMMARIZE_GROUP_DISCUSSION routing` group to `task_type_dispatcher_test.dart`, checking the file's current tail for the exact pattern and helper-naming convention (task builder, mediaDao stub, distinct `pinnedItemPublicId`) before writing it, matching the `ANSWER_SHORT_QUESTION routing` group's shape.
4. Run the full `flutter test` suite and record the fresh baseline pass/fail count — do not assume any prior session's count is still accurate.
5. Run `flutter analyze` across the whole project and confirm 0 issues.
6. Run `.github/scripts/check-standards.sh` and review its output for any new findings, especially hardcoded `Text('literal')` strings introduced by this feature.
7. Fix any failures/findings surfaced by steps 4-6 before considering this phase (and the plan) complete.

## Success Criteria
- `flutter test` passes 100% with no regressions versus the freshly-measured pre-change baseline.
- `flutter analyze` reports 0 issues.
- `.github/scripts/check-standards.sh` reports no new findings attributable to this feature's changes.
- The new screen test file and dispatcher routing group both exist and pass, covering every case listed in Step 2.

## Risks
- Off-by-one errors in hand-derived elapsed/remaining test values causing false failures or, worse, false passes that don't actually exercise the intended sub-stage boundary: recompute each value from the `prepSeconds`/`preListenSeconds`/`preRecordSeconds` constants rather than trusting arithmetic performed during planning.
- `check-standards.sh` flagging an unrelated pre-existing issue that looks like a regression: diff its output against a pre-Phase-1 run (or check file paths) to confirm any finding is actually caused by this feature's files before treating it as a blocker.
