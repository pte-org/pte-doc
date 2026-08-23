# Phase 1: Promote `AudioPromptRecordBody`'s private pieces to public

## Requirements
`_elapsedPrepSeconds`, `_ListeningCard`, and `_RecordCard` inside `lib/features/exam_attempt/speaking_writing/presentation/widgets/audio_prompt_record_body.dart` become public (`elapsedPrepSeconds`, `AudioListeningPrepCard`, `RecordedAnswerPrepCard`) with zero behavior change, so a future screen can compose them directly without duplicating their logic. All 4 existing consumer screens (Repeat Sentence, Retell Lecture, Answer Short Question, Summarize Group Discussion) keep working exactly as before, proven by their existing test suites passing unmodified.

## Steps
1. Grep the repo for `_ListeningCard`, `_RecordCard`, and `_elapsedPrepSeconds` to confirm every reference — both real code and doc-comment mentions in other files — before touching anything, so nothing is missed or wrongly assumed absent.
2. In `audio_prompt_record_body.dart`, rename the three private members to their public equivalents (drop the leading underscore, rename the two classes as specified) — a pure identifier rename, not a rewrite: no reformatting, no reordering, no changes to the clamp math, countdown-label construction, or upload-status handling inside them.
3. Update `AudioPromptRecordBody.build()`'s own references to the renamed classes so it still calls them exactly the same way, just under the new public names.
4. Update the doc comments on the renamed classes/function (and the module-level doc comment above `AudioPromptRecordBody`) to reflect their new public names and to explain, briefly, how they differ from the existing public leaf widgets `AudioListeningStatusCard`/`RecordedAnswerStatusCard` (these promoted classes are the parametrized wrappers around those leaves, not the leaves themselves).
5. Fix the two files whose doc comments mention the old private names in prose (`test/widget/features/exam_attempt/audio_prompt_record_body_test.dart` and `auto_record_status_card.dart`) — comment-only edits, no test-assertion changes, since neither file references the private names in actual code (both only import/call the already-public `AudioPromptRecordBody`).
6. Run the 4 existing consumer screens' test files plus `audio_prompt_record_body_test.dart` unmodified and confirm every one passes — this is the correctness gate for the rename, proving no behavior changed.

## Success Criteria
- `flutter analyze` reports 0 issues on `audio_prompt_record_body.dart` and the two comment-edited files.
- `flutter test test/widget/features/exam_attempt/repeat_sentence_screen_test.dart test/widget/features/exam_attempt/retell_lecture_screen_test.dart test/widget/features/exam_attempt/answer_short_question_screen_test.dart test/widget/features/exam_attempt/summarize_group_discussion_screen_test.dart test/widget/features/exam_attempt/audio_prompt_record_body_test.dart` passes 100%, with none of those 5 test files' source modified (only the two comment-only doc changes, and only inside prose, not test code).
- Grep for `_ListeningCard`, `_RecordCard`, `_elapsedPrepSeconds` (leading underscore, exact names) returns zero matches anywhere in the repo after the rename.

## Risks
- Accidentally changing behavior while renaming (e.g. touching the clamp expressions): mitigate by diffing the change and confirming it is textually identical apart from identifier names.
- Missing a reference during the rename causing a compile error: mitigate by running `flutter analyze` immediately after the rename, before running tests.
