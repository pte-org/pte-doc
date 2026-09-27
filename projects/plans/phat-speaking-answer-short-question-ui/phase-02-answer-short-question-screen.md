# Phase 2: New `AnswerShortQuestionScreen`

## Requirements
Selecting an `ANSWER_SHORT_QUESTION` task (from the dispatcher or the Speaking/Writing dev-preview picker) renders a working screen with the fixed instruction text and the user's literal 3s pre-listen / ~8s audio / 3s pre-record / 10s response timing, built on top of Phase 1's shared `AudioPromptRecordBody`.

## Steps
1. Re-verify the `ANSWER_SHORT_QUESTION` backend enum name via grep against `pte-api/services/authoring/src/main/java/com/pte/authoring/domain/enums/PteTaskType.java` before wiring any string constant — do not trust this plan document alone.
2. Add `answerShortQuestionInstructionText` — a fixed, non-interpolated string constant — to `SpeakingWritingStrings`, placed near `repeatSentenceInstructionText`.
3. Create `lib/features/exam_attempt/speaking_writing/presentation/pages/answer_short_question_screen.dart`, mirroring `RepeatSentenceScreen`'s `StatefulWidget`/`State`/`initState`/`dispose`/`AutoRecordCubit`/`AutoRecordTimerBridgeMixin`/`ExamScaffold`/`AutoAdvanceOnUploadReady` boilerplate exactly, with local `_preListenSeconds = 3` / `_preRecordSeconds = 3` constants and a one-line `_AnswerShortQuestionBody.build()` that returns `AudioPromptRecordBody(task: task, preListenSeconds: _preListenSeconds, preRecordSeconds: _preRecordSeconds, instructionText: SpeakingWritingStrings.answerShortQuestionInstructionText)`.
4. Wire the new screen into `task_type_dispatcher.dart`: add a `_taskTypeAnswerShortQuestion = 'ANSWER_SHORT_QUESTION'` constant, import the new screen, and add a switch arm shaped identically to `_taskTypeRepeatSentence`'s (`task`, `attemptPublicId`, `recorder`, `mediaDao`, `coordinator`, `syncEngine` — no `audioPlayerService`).
5. Add an `answerShortQuestion` getter to the EXISTING file `lib/features/exam_attempt/reading/dev/speaking_writing_task_fixtures.dart` (note the path — it lives nested under `reading/dev/` despite being Speaking/Writing-only content; do not create a new fixtures file under `speaking_writing/dev/`, that directory only holds `SpeakingWritingTaskPreviewScreen`) (`pinnedItemPublicId: 'fixture-ANSWER_SHORT_QUESTION'`, `taskType: 'ANSWER_SHORT_QUESTION'`, `prepSeconds: 14`, `responseSeconds: 10`), with a doc comment explaining the 3+8+3=14 split and stating explicitly that `14` and `24` (`prepSeconds + responseSeconds`) do **not** land on the dev-preview poll boundary — mirroring `describeImage`'s comment style — then add it to `SpeakingWritingTaskFixtures.all`. Confirm the only consumer of this list is `SpeakingWritingTaskPreviewScreen`; do not touch `ReadingTaskPreviewScreen`'s picker.
6. Update `auto_record_timer_bridge_mixin.dart`'s doc comment consumer list to read "Read Aloud, Repeat Sentence, Describe Image, Retell Lecture, Answer Short Question" — doc-comment-only change, no logic touched.
7. Run `flutter analyze` on all newly created/touched files and resolve any issues before moving to Phase 3.

## Success Criteria
- Grep confirms `ANSWER_SHORT_QUESTION` is still the exact backend enum name before it's wired anywhere.
- `answer_short_question_screen.dart` exists, compiles, and contains no hardcoded `Text('literal')` strings (per `docs/CODING_STANDARDS_APP.md`).
- `task_type_dispatcher.dart` routes `'ANSWER_SHORT_QUESTION'` to `AnswerShortQuestionScreen` with the same 6 constructor args as the Repeat Sentence arm.
- `SpeakingWritingTaskFixtures.all` includes the new `answerShortQuestion` fixture; `ReadingTaskPreviewScreen`'s picker list is untouched.
- `flutter analyze` reports 0 new issues.

## Risks
- Enum name drift between plan-writing time and implementation time — mitigation: step 1's grep re-check is mandatory, not optional.
- Miscopying the audio-duration math (`14 - 3 - 3 = 8`, matching the user's "~8s" spec) into the fixture or screen constants — mitigation: the doc comment states the arithmetic explicitly so any future edit re-derives it rather than guessing.
- Accidentally re-adding the fixture to `ReadingTaskPreviewScreen`'s picker, regressing the prior split-out fix — mitigation: only edit `speaking_writing_task_fixtures.dart`'s `all` list; never open `reading_task_preview_screen.dart` in this phase.
