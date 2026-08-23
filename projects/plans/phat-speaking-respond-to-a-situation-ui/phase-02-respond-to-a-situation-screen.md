# Phase 2: `RespondToASituationScreen` — screen, strings, dispatcher, fixture

## Requirements
A new `RespondToASituationScreen` renders `InstructionText`, then the scrollable situation text (`task.promptText`), then the reused Listening/Record cards (20s "Beginning in" → 10s "Playing" → 10s "Beginning in" → 40s "Recording" → upload status), fully wired into the exam shell's auto-record lifecycle. The task type is routable from `TaskTypeDispatcher` and previewable from the Speaking/Writing dev fixture picker.

## Steps
1. Re-verify `RESPOND_TO_A_SITUATION` against `PteTaskType.java` by grep (do not just trust the plan document), then confirm the exact instruction-text and dev-fixture situation-text wording with the user before writing either into source. Use these EXACT, complete drafts (confirmed via Step 4 validation before cook — do not invent alternate wording, and do not leave either as a fragment):
   - Instruction text: "Read the situation below. You will then hear it described again. Please respond appropriately, as you would in the actual situation."
   - Fixture situation text (`promptText`), complete: "You are a student at a university. You have realized that you will miss an important exam because of a family emergency. Explain the situation to your professor and ask what you should do."
2. Add the confirmed instruction text as `SpeakingWritingStrings.respondToASituationInstructionText` in `speaking_writing_strings.dart`, following the existing fixed-constant pattern used by `answerShortQuestionInstructionText`/`summarizeGroupDiscussionInstructionText`.
3. Create `respond_to_a_situation_screen.dart` in `lib/features/exam_attempt/speaking_writing/presentation/pages/`, copying `AnswerShortQuestionScreen`'s `StatefulWidget`/`State`/`initState`/`dispose`/`AutoRecordCubit`/`AutoRecordTimerBridgeMixin`/`ExamScaffold`/`AutoAdvanceOnUploadReady` boilerplate verbatim in shape, with module-level `_preListenSeconds = 20`/`_preRecordSeconds = 10` constants carrying a doc comment explaining the 15s-read+5s-pre-audio merge decision.
4. Build the private body widget to compose, in order, `InstructionText`, the scrollable `task.promptText` display (styling copied from `ReadAloudScreen`'s passage snippet), the promoted `AudioListeningPrepCard`, and the promoted `RecordedAnswerPrepCard` — wrapped in the same `Padding` → `BlocSelector<ExamAttemptBloc, ExamAttemptState, TimerSnapshot?>` → `BlocBuilder<AutoRecordCubit, AutoRecordState>` shell `AudioPromptRecordBody.build()` uses, composing the promoted pieces directly rather than calling `AudioPromptRecordBody` (whose fixed internal layout can't interleave the situation text between the instruction and the cards).
5. Wire `TaskTypeDispatcher`: add the `_taskTypeRespondToASituation` constant, import the new screen, and add a switch arm shaped identically to `_taskTypeAnswerShortQuestion`'s (task, attemptPublicId, recorder, mediaDao, coordinator, syncEngine — no audioPlayerService).
6. Add a `respondToASituation` getter to `SpeakingWritingTaskFixtures` (`prepSeconds: 40`, `responseSeconds: 40`, the confirmed situation-text `promptText`) with a doc comment noting both `40` and `80` already land on the dev-preview 10s poll boundary with no rounding needed, then add it to `SpeakingWritingTaskFixtures.all`.
7. Append "Respond to a Situation" to `AutoRecordTimerBridgeMixin`'s doc-comment list of screens it serves — a doc-comment-only edit.

## Success Criteria
- `flutter analyze` reports 0 issues across all new/edited files in this phase.
- The dev Speaking/Writing preview picker lists and can render the new fixture without error (manual or automated smoke check).
- `TaskTypeDispatcher`'s switch compiles with the new arm and no `_ => _UnsupportedTaskTypePlaceholder` fallback is hit for `RESPOND_TO_A_SITUATION` in a manual trace.
- Instruction text and fixture situation text used in source exactly match what the user confirmed in step 1 (no placeholder/draft wording left in committed code).

## Risks
- Content wording (instruction text, fixture scenario) is not yet user-confirmed: mitigate by treating step 1's confirmation as a hard gate before any string lands in `speaking_writing_strings.dart` or the fixture file — do not proceed to Phase 3 tests until confirmed, since tests will hardcode these strings next.
- Situation-text `Text` widget risks violating the no-hardcoded-`Text('literal')` standard if `task.promptText` handling is done carelessly: mitigate by confirming the pattern matches `ReadAloudScreen`'s existing (already-approved) `Text(task.promptText ?? '', ...)` usage, which reads from task data, not a literal.
