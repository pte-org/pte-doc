# Phase 1: Screen and strings

## Requirements
A `SummarizeGroupDiscussionScreen` exists that renders the shared audio-prompt/record body with fixed 5s pre-listen / 10s pre-record sub-stage timing and a fixed instruction sentence, structurally identical to `AnswerShortQuestionScreen`.

## Steps
1. Re-confirm the `SUMMARIZE_GROUP_DISCUSSION` backend enum name and its `scored`/`requiresAudioPrompt`/`requiresPromptText` flags via a fresh grep of `PteTaskType.java`, not by trusting this plan.
2. Read `answer_short_question_screen.dart` and `repeat_sentence_screen.dart` in full to confirm the current exact structural template before writing anything.
3. Add `summarizeGroupDiscussionInstructionText` to `SpeakingWritingStrings` as a single fixed string constant, placed alongside the other fixed instruction-text constants and following their exact naming/doc pattern. Use this EXACT, user-confirmed text (confirmed via Step 4 validation before cook — do not invent alternate wording):
   ```dart
   static const String summarizeGroupDiscussionInstructionText =
       'You will hear a group discussion. Please summarize the discussion, including the key points and '
       'opinions expressed by each speaker.';
   ```
4. Create `summarize_group_discussion_screen.dart` mirroring `AnswerShortQuestionScreen`'s exact shape: same constructor params, same `State` class using `AutoRecordTimerBridgeMixin` and an internally-built `AutoRecordCubit`, same `ExamScaffold`/`AutoAdvanceOnUploadReady` body, and a private body widget that calls `AudioPromptRecordBody` with local module constants `_preListenSeconds = 5` and `_preRecordSeconds = 10`.
5. Write doc comments on the new screen and its module-level constants that state the 5/185/10 = 200 split and reference the same poll-boundary rounding rationale as `RetellLectureScreen`'s fixture, so a future reader understands why 185 was chosen over a rounder number.
6. Update `AudioPromptRecordBody`'s doc comment to add the new screen to its consumer enumeration and to its fixed-vs-interpolated instruction-text parenthetical — verify current wording first, change nothing else in that file.
7. Run `flutter analyze` on the touched files to catch import/naming issues before moving to wiring.

## Success Criteria
- `flutter analyze` reports 0 issues on the new and edited files.
- `SummarizeGroupDiscussionScreen` compiles standalone and its body renders `AudioPromptRecordBody` with `preListenSeconds: 5`, `preRecordSeconds: 10`, and the new fixed instruction string.
- No `Text('literal')` usage was introduced — all user-facing text routes through `SpeakingWritingStrings`.
- `audio_prompt_record_body.dart` has no logic changes — only its doc comment differs (verifiable via diff review).

## Risks
- Copying `AnswerShortQuestionScreen` too literally and leaving stale doc-comment references to "Answer Short Question" in the new file: proofread the new file's own comments before finishing this phase.
- Picking a preListen/preRecord split that doesn't match the plan's stated 5s/10s values, breaking the intended 200-boundary alignment: cross-check the module constants against `5 + 185 + 10 = 200` before moving to Phase 2's fixture.
