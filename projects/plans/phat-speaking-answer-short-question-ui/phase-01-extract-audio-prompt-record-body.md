# Phase 1: Extract `AudioPromptRecordBody`

## Requirements
`RepeatSentenceScreen` and `RetellLectureScreen` render exactly as before (identical text, progress values, and widget tree), now sourced from one shared widget instead of two duplicated private-class trees — proven by both screens' existing widget-test files passing unmodified.

## Steps
1. Re-read `repeat_sentence_screen.dart` and `retell_lecture_screen.dart` in full and re-confirm `_elapsedPrepSeconds`, `_ListeningCard`, and `_RecordCard` are structurally identical between the two files (already confirmed during plan-writing) before moving anything — stop and escalate if a real logic divergence, not just a formatting difference, turns up.
2. Create `lib/features/exam_attempt/speaking_writing/presentation/widgets/audio_prompt_record_body.dart` with a public `AudioPromptRecordBody extends StatelessWidget` (constructor params: `task`, `preListenSeconds`, `preRecordSeconds`, `instructionText`) whose `build()` reproduces `_RepeatSentenceBody.build()`'s exact `Padding` → `BlocSelector<ExamAttemptBloc, ExamAttemptState, TimerSnapshot?>` → `BlocBuilder<AutoRecordCubit, AutoRecordState>` → `Column` tree, using `instructionText` in place of the old hardcoded string constant.
3. Move `_elapsedPrepSeconds`, `_ListeningCard`, and `_RecordCard` into the new file as module-private members, changing only what's necessary to take `preListenSeconds`/`preRecordSeconds` as parameters on `_ListeningCard`/`_RecordCard` instead of reading module-level constants (`_elapsedPrepSeconds` itself needs no new params — it only uses `task.prepSeconds`).
4. Update `repeat_sentence_screen.dart`: delete the now-moved private classes/function, collapse `_RepeatSentenceBody.build()` to a single `return AudioPromptRecordBody(...)` call passing `SpeakingWritingStrings.repeatSentenceInstructionText`, keep the file's own `_preListenSeconds`/`_preRecordSeconds` module constants (screen-specific config, not duplicated logic) and its doc comments.
5. Update `retell_lecture_screen.dart` the same way — collapse `_RetellLectureBody.build()` to a single `AudioPromptRecordBody(...)` call, keep its own `_instructionText(task.responseSeconds)` helper and `_preListenSeconds`/`_preRecordSeconds` constants in-file.
6. Run `flutter test test/widget/features/exam_attempt/repeat_sentence_screen_test.dart test/widget/features/exam_attempt/retell_lecture_screen_test.dart` without editing either test file and confirm both pass in full.
7. Run `flutter analyze` scoped to the three touched/created files and resolve any new issues before moving on.

## Success Criteria
- `lib/features/exam_attempt/speaking_writing/presentation/widgets/audio_prompt_record_body.dart` exists, exports `AudioPromptRecordBody`, and the app compiles.
- `repeat_sentence_screen.dart` and `retell_lecture_screen.dart` no longer define `_ListeningCard`, `_RecordCard`, or `_elapsedPrepSeconds`.
- `test/widget/features/exam_attempt/repeat_sentence_screen_test.dart` and `retell_lecture_screen_test.dart` pass 100%, with neither file's content changed.
- `flutter analyze` reports 0 new issues on the touched/created files.

## Risks
- Subtle divergence between the two screens' private classes only surfaces once the merge is attempted (e.g. one had a since-fixed bug the other didn't) — mitigation: if found, stop and resolve the divergence explicitly (pick the correct behavior, don't silently favor whichever file was read first) rather than merging blindly.
- Changing the `Padding`/`BlocSelector`/`BlocBuilder`/`Column` nesting order while moving code silently breaks both existing test files — mitigation: keep the `build()` method's structure byte-for-byte identical aside from the `instructionText` parameterization, and let step 6 be the actual proof, not an assumption.
