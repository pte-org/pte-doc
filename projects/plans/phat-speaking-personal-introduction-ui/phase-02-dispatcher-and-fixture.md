# Phase 2: Dispatcher + Dev Fixture Wiring

## Requirements
`TaskTypeDispatcher` routes `PERSONAL_INTRODUCTION` tasks to `PersonalIntroductionScreen`, the dev-preview picker lists a Personal Introduction fixture reproducing the mockup's bulleted prompt, and the timer-bridge mixin's doc comment accurately reflects the new consumer.

## Steps
1. In `task_type_dispatcher.dart`, add `const String _taskTypePersonalIntroduction = 'PERSONAL_INTRODUCTION';` alongside the other Speaking task-type constants, and import `PersonalIntroductionScreen`.
2. Add a switch arm for `_taskTypePersonalIntroduction` in the dispatcher's `switch`, identical in shape to the `_taskTypeReadAloud` arm (task, attemptPublicId, recorder, mediaDao, coordinator, syncEngine — no audioPlayerService).
3. In `speaking_writing_task_fixtures.dart`, add a `personalIntroduction` getter with `pinnedItemPublicId: 'fixture-PERSONAL_INTRODUCTION'`, `taskType: 'PERSONAL_INTRODUCTION'`, `prepSeconds: 25`, `responseSeconds: 30`, and the mockup's bulleted `promptText`.
4. Document, in the new getter's doc comment, that 25/30 (and their sum, 55) do not land on the dev-preview `ExamAttemptBloc`'s 10-second poll boundary and why the literal values are kept anyway — mirroring `describeImage`'s doc comment precedent exactly, including the "no sub-stage slack to redistribute" reasoning specific to this non-sub-staged screen.
5. Add `personalIntroduction` to `SpeakingWritingTaskFixtures.all`.
6. Read `auto_record_timer_bridge_mixin.dart`'s current class doc comment; if it enumerates consumer screens by name, add Personal Introduction to that list (if it already reads generically, e.g. "every auto-record speaking screen", leave it unchanged).
7. Confirm `ReadingTaskPreviewScreen`'s picker is untouched (Personal Introduction is only reachable via `SpeakingWritingTaskPreviewScreen`).
8. Run `flutter analyze` on all touched files.

## Success Criteria
- Launching the dev Speaking/Writing preview and selecting "PERSONAL_INTRODUCTION" renders `PersonalIntroductionScreen` via the real `TaskTypeDispatcher`, not the unsupported-task-type placeholder.
- `SpeakingWritingTaskFixtures.all` contains exactly one Personal Introduction entry with the specified field values and bulleted prompt text.
- `flutter analyze` reports 0 issues for all files touched in this phase.

## Risks
- Fixture prep/response values causing dev-preview-only lag at phase transitions — accepted and documented per the plan's explicit instruction, not a defect to "fix" by rounding.
- Missing the dispatcher's `ValueKey(task.pinnedItemPublicId)` convention when adding the new arm — mitigated by copying the `_taskTypeReadAloud` arm verbatim and only changing the screen class name.
