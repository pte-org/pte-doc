# Phase 2: Dispatcher wiring and dev fixture

## Requirements
Selecting a `SUMMARIZE_GROUP_DISCUSSION` task routes to the new screen in both the real dispatcher and the Speaking/Writing dev preview, and the shared timer-bridge mixin's doc comment reflects the new consumer.

## Steps
1. In `task_type_dispatcher.dart`, add `const String _taskTypeSummarizeGroupDiscussion = 'SUMMARIZE_GROUP_DISCUSSION';` next to the other Speaking task-type constants, import the new screen, and add a switch arm identical in shape to `_taskTypeAnswerShortQuestion`'s (task, attemptPublicId, recorder, mediaDao, coordinator, syncEngine — no `audioPlayerService`).
2. In `speaking_writing_task_fixtures.dart`, add a `summarizeGroupDiscussion` getter with `pinnedItemPublicId: 'fixture-SUMMARIZE_GROUP_DISCUSSION'`, `taskType: 'SUMMARIZE_GROUP_DISCUSSION'`, `prepSeconds: 200`, `responseSeconds: 120`, matching the existing getters' `TaskView` construction pattern (`prepDeadline`/`responseDeadline`/`serverNow` derived the same way).
3. Write the new fixture's doc comment mirroring `retellLecture`'s style exactly: explain the `5 + 185 + 10 = 200` sub-stage split and the deliberate rounding decision (185s, not a rounder ~180s) made to land `prepSeconds` and `prepSeconds + responseSeconds` on the dev-preview `ExamAttemptBloc`'s 10-second poll boundary.
4. Add the new getter to `SpeakingWritingTaskFixtures.all`.
5. Confirm `ReadingTaskPreviewScreen` is untouched — the sole consumer of this fixtures file remains `SpeakingWritingTaskPreviewScreen`.
6. Update `AutoRecordTimerBridgeMixin`'s doc comment to append "Summarize Group Discussion" to its enumerated list of auto-record speaking screens — doc-comment-only change, no logic edits.
7. Manually smoke-check the dev preview (or read through the fixture/dispatcher wiring) to confirm the new fixture's `taskType` string exactly matches the dispatcher's new constant, character for character.

## Success Criteria
- `flutter analyze` reports 0 issues on all touched files.
- The dispatcher's switch statement routes `'SUMMARIZE_GROUP_DISCUSSION'` to `SummarizeGroupDiscussionScreen` and falls through to the unsupported-type placeholder for nothing else changed.
- `SpeakingWritingTaskFixtures.all` includes the new fixture and its `prepSeconds`/`responseSeconds` are exactly 200/120.
- `AutoRecordTimerBridgeMixin`'s doc comment lists Summarize Group Discussion alongside the other six auto-record screens.

## Risks
- Fixture `taskType` string and dispatcher constant string diverging by a typo (e.g. missing underscore), silently falling through to the unsupported-task-type placeholder instead of routing correctly: cross-check both strings against the verified backend enum name from Phase 1, not against each other.
- Accidentally editing `ReadingTaskPreviewScreen` or another unrelated preview screen while wiring the fixture in: touch only `speaking_writing_task_fixtures.dart` and confirm no other file changed.
