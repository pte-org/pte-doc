# Phase 3: Tests and Full Regression Gate

## Requirements
`AnswerShortQuestionScreen` has widget-test coverage matching the depth of `RepeatSentenceScreen`'s, dispatcher routing is tested, and the whole suite (including the two refactored screens' pre-existing tests) is proven to pass with no regressions from the Phase 1 extraction.

## Steps
1. Create `test/widget/features/exam_attempt/answer_short_question_screen_test.dart`, mirroring `repeat_sentence_screen_test.dart`'s exact structure (`_FakePathProviderPlatform`, all 5 mock classes, `buildSubject`/`stubBlocState` helpers) with an `_answerShortQuestionTask({String pinnedItemPublicId = 'item-1'})` helper using `prepSeconds: 14, responseSeconds: 10`.
2. Add these test cases, using the precomputed values below (audioSeconds = 14 − 3 − 3 = 8):
   - Fixed instruction text (`SpeakingWritingStrings.answerShortQuestionInstructionText`) renders.
   - Elapsed 0s (snapshot remaining = 14, phase prep) → Listening shows "Beginning in 3 seconds", Record still blank, `recorder.start` never called.
   - Elapsed 5s (snapshot remaining = 9, phase prep) → audioElapsed = 5 − 3 = 2, audioRemaining = 8 − 2 = 6 → Listening shows "Playing 6 seconds left", Record still blank.
   - Elapsed 13s (snapshot remaining = 1, phase prep) → audioElapsed clamps to 8 → Listening frozen at "Playing 0 seconds left"; preRecordStart = 14 − 3 = 11, elapsed(13) ≥ 11 → Record shows "Beginning in 1 seconds".
   - Response phase (snapshot remaining = 10, phase response) delivered via the bloc stream → `recorder.start` called once, Record shows "Recording 10 seconds left", Listening still frozen at "Playing 0 seconds left".
   - Full transition: prep → response (remaining 10) → expired response (remaining 0) → `recorder.stop` called once, "Still uploading…" (or ready label) replaces the "Recording" text, "Recording 10 seconds left" no longer found.
   - `pinnedItemPublicId` mismatch: a response-phase snapshot for a different task's `pinnedItemPublicId` is never forwarded — `recorder.start` never called.
3. Add an `'ANSWER_SHORT_QUESTION routing'` group to `task_type_dispatcher_test.dart`, mirroring the existing `'REPEAT_SENTENCE routing'`/`'RE_TELL_LECTURE routing'` groups, with its own `_answerShortQuestionTask({required String pinnedItemPublicId})` helper (`prepSeconds: 14`, `responseSeconds: 10`) and an assertion on the fixed instruction text.
4. Re-run `repeat_sentence_screen_test.dart` and `retell_lecture_screen_test.dart` once more, unmodified, to confirm they still pass after all Phase 2 additions — this is the final proof the extraction stayed behavior-neutral end-to-end.
5. Run the full `flutter test` suite and record the exact total pass count against the pre-feature baseline. Treat "286" as a snapshot recorded at plan-writing time, not a hardcoded truth — if other work has landed since, re-measure the actual pre-Phase-1 count (e.g. via `git stash`/checking the prior session's recorded count) rather than flagging a mismatch against a stale number. Expect baseline + the count of tests added in this phase, 0 failures.
6. Run `flutter analyze` across the whole app (expect 0 issues) and `.github/scripts/check-standards.sh`, reviewing the output for any new findings — in particular hardcoded `Text('literal')` strings and file line-count thresholds on `answer_short_question_screen.dart` and `audio_prompt_record_body.dart` (flag either if it risks exceeding ~300 lines; `answer_short_question_screen.dart` should be small since most logic lives in the shared widget).

## Success Criteria
- `answer_short_question_screen_test.dart` passes 100%, with all 7 documented cases present and using the exact precomputed numbers above.
- The new `'ANSWER_SHORT_QUESTION routing'` group in `task_type_dispatcher_test.dart` passes.
- `repeat_sentence_screen_test.dart` and `retell_lecture_screen_test.dart` pass unmodified.
- Full `flutter test` run: 100% pass, exact new total recorded and compared to the 286 baseline.
- `flutter analyze`: 0 issues.
- `.github/scripts/check-standards.sh`: no new findings (or any findings explicitly triaged and justified, e.g. a documented line-count flag).

## Risks
- Arithmetic error in the new test's expected countdown text — mitigation: the numbers in step 2 are pre-derived in this plan (audioSeconds = 8, elapsed5 → "Playing 6", elapsed13 → "Beginning in 1", response remaining=10 → "Recording 10 seconds left"); re-verify against actual rendered output during implementation rather than trusting the plan blindly.
- `audio_prompt_record_body.dart` or `answer_short_question_screen.dart` creeping past the project's line-count discipline — mitigation: `check-standards.sh`'s output is the actual gate; only split further if it fires, don't pre-emptively over-split.
