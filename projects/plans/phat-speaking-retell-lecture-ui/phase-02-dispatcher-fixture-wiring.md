# Phase 2: Dispatcher Wiring + Dev Fixture + Mixin Doc Update

## Requirements
`RE_TELL_LECTURE` tasks route correctly through `TaskTypeDispatcher` to `RetellLectureScreen`, a matching dev-preview fixture is selectable and correctly timed, and the shared timer-bridge mixin's doc comment accurately lists its consumers.

## Steps
1. Re-grep `pte-api/services/authoring/src/main/java/com/pte/authoring/domain/enums/PteTaskType.java` for the task-type enum entry to reconfirm the exact spelling `RE_TELL_LECTURE` (with the internal underscore split) before wiring the dispatcher string constant — do not rely on this plan's text alone.
2. In `lib/features/exam_attempt/presentation/widgets/task_type_dispatcher.dart`: add `const String _taskTypeRetellLecture = 'RE_TELL_LECTURE';` near the other Speaking task-type constants, import `retell_lecture_screen.dart`, and add a switch arm mirroring `_taskTypeRepeatSentence`'s exact shape and constructor arguments (`key`, `task`, `attemptPublicId`, `recorder: audioRecorderService`, `mediaDao`, `coordinator: mediaUploadCoordinator`, `syncEngine`) — do **not** pass `audioPlayerService`, since this is a Speaking task, not a Listening task.
3. Add a `retellLecture` getter to `lib/features/exam_attempt/reading/dev/speaking_writing_task_fixtures.dart`, pattern-matched against `repeatSentence`'s/`describeImage`'s existing getters: `pinnedItemPublicId: 'fixture-RE_TELL_LECTURE'`, `taskType: 'RE_TELL_LECTURE'`, `prepSeconds: 70`, `responseSeconds: 40`.
4. Write the fixture's doc comment explaining: `70` is the sum of a 3-second pre-listen "Beginning in" delay, 57-second mocked lecture-audio playback, and the 10-second pre-record "chuẩn bị" window (`3 + 57 + 10 = 70`) — same 3-stage shape as `repeatSentence`'s split, just with a longer audio stage and a longer pre-record stage. Note the audio duration (57s) is a rounding-down from the originally-discussed ~60s, kept deliberately to land `prepSeconds` on `70`; both `70` (prep→response) and `110` (response→recorded, `prepSeconds + responseSeconds`) land exactly on the dev-preview `ExamAttemptBloc`'s 10-second poll boundary, avoiding the "Beginning in 0 seconds" stuck-UI lag described on `repeatSentence`'s own fixture doc comment — contrast this explicitly against `describeImage`'s fixture, which deliberately keeps its literal, non-boundary-aligned `25`/`40` values and accepts the resulting dev-preview-only lag.
5. Add `retellLecture` to `SpeakingWritingTaskFixtures.all`.
6. Update `lib/features/exam_attempt/speaking_writing/presentation/widgets/auto_record_timer_bridge_mixin.dart`'s doc comment: change the consumer list "(Read Aloud, Repeat Sentence, Describe Image)" to add Retell Lecture. This is a doc-only change — do not touch `startAutoRecordBridge`/`_forwardIfCurrentTask`/`disposeAutoRecordBridge`'s logic, including the `pinnedItemPublicId` identity guard.
7. Run `flutter analyze` and confirm the dev-preview fixture picker (via whichever screen sources `SpeakingWritingTaskFixtures.all`) now lists the new `RE_TELL_LECTURE` fixture without a build error.

## Success Criteria
- `flutter analyze` is clean.
- `grep -n "RE_TELL_LECTURE" lib/features/exam_attempt/presentation/widgets/task_type_dispatcher.dart` shows the new constant and its switch arm.
- `SpeakingWritingTaskFixtures.all` includes the new `retellLecture` fixture (verifiable by reading the file).
- `auto_record_timer_bridge_mixin.dart`'s doc comment lists Retell Lecture; a diff of the file shows no change outside that comment.
- Manual trace: `retellLecture.prepSeconds` (70) and `retellLecture.prepSeconds + retellLecture.responseSeconds` (110) are both multiples of 10.

## Risks
- Typo'ing the enum string (`RETELL_LECTURE` instead of `RE_TELL_LECTURE`) causes silent misrouting to `TaskTypeDispatcher`'s unsupported-task-type placeholder rather than a build error — Mitigation: Step 1's re-grep against the actual backend source is a hard prerequisite before Step 2; Phase 3's dispatcher routing test is the final automated gate.
- Accidentally passing `audioPlayerService` (copy-paste from a Listening task-type arm instead of `_taskTypeRepeatSentence`'s) — Mitigation: Step 2 explicitly names `_taskTypeRepeatSentence` as the pattern to mirror, not any Listening arm.
- Fixture doc comment drifting from the actual chosen values if `prepSeconds`/`responseSeconds` are tweaked later without updating the comment — Mitigation: Step 4's doc comment states the derivation (60 + 10 = 70) explicitly, not just the raw numbers, so a future edit is self-checking.
