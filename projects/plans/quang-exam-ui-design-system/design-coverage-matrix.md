# Exam UI Design Coverage Matrix

This matrix is the Phase 0 source of truth for the 23 task types. A direct
reference means the bundle contains a usable task screen asset. A fallback is
implemented with the nearest approved pattern and is not reported as pixel
parity. Fixture keys are the stable keys to expose from the offline catalog.

| # | Task type | Family | Current page | Fixture key | Design reference | Coverage |
|---:|---|---|---|---|---|---|
| 1 | `PERSONAL_INTRODUCTION` | record | `speaking_writing/presentation/pages/personal_introduction_screen.dart` | `personalIntroduction` | `11-personal-introduction-*` | direct |
| 2 | `READ_ALOUD` | record | `speaking_writing/presentation/pages/read_aloud_screen.dart` | `readAloud` | `01-read-aloud-*` | direct; canonical |
| 3 | `REPEAT_SENTENCE` | record | `speaking_writing/presentation/pages/repeat_sentence_screen.dart` | `repeatSentence` | `13-repeat-sentence-*` | direct |
| 4 | `DESCRIBE_IMAGE` | record | `speaking_writing/presentation/pages/describe_image_screen.dart` | `describeImage` | `14-describe-image-*` | direct |
| 5 | `RE_TELL_LECTURE` | record | `speaking_writing/presentation/pages/retell_lecture_screen.dart` | `reTellLecture` | `15-re-tell-lecture-*` | direct |
| 6 | `ANSWER_SHORT_QUESTION` | record | `speaking_writing/presentation/pages/answer_short_question_screen.dart` | `answerShortQuestion` | `16-answer-short-question-*` | direct |
| 7 | `SUMMARIZE_GROUP_DISCUSSION` | record | `speaking_writing/presentation/pages/summarize_group_discussion_screen.dart` | `summarizeGroupDiscussion` | nearest audio-prompt pattern | derived fallback |
| 8 | `RESPOND_TO_A_SITUATION` | record | `speaking_writing/presentation/pages/respond_to_a_situation_screen.dart` | `respondToASituation` | nearest audio-prompt pattern | derived fallback |
| 9 | `SUMMARIZE_WRITTEN_TEXT` | free text | `speaking_writing/presentation/pages/summarize_written_text_screen.dart` | `summarizeWrittenText` | `17-summarize-written-text-*` | direct |
| 10 | `WRITE_ESSAY` | free text | `speaking_writing/presentation/pages/write_essay_screen.dart` (canonical rename) | `writeEssay` | `18-write-essay-*` | direct |
| 11 | `SUMMARIZE_SPOKEN_TEXT` | free text | `listening/presentation/pages/summarize_spoken_text_screen.dart` | `summarizeSpokenText` | `26-summarize-spoken-text-*` | direct |
| 12 | `WRITE_FROM_DICTATION` | free text | `listening/presentation/pages/write_from_dictation_screen.dart` | `writeFromDictation` | `33-write-from-dictation-listening-*` | direct |
| 13 | `FILL_BLANKS_READING_WRITING` | fill blanks | `reading/presentation/pages/fill_blanks_dropdown_screen.dart` (canonical rename) | `fillBlanksReadingWriting` | `20-reading-writing-fill-in-the-blanks-*` | direct |
| 14 | `MC_READING_MULTIPLE` | multi select | `reading/presentation/pages/mc_reading_multiple_screen.dart` | `mcReadingMultiple` | `21-multiple-choice-multiple-answer-*` | direct |
| 15 | `RE_ORDER_PARAGRAPHS` | ordering | `reading/presentation/pages/re_order_paragraphs_screen.dart` | `reOrderParagraphs` | `22-re-order-paragraphs-*` | direct |
| 16 | `FILL_BLANKS_READING` | fill blanks | `reading/presentation/pages/fill_blanks_drag_drop_screen.dart` (canonical rename) | `fillBlanksReading` | `23-reading-fill-in-the-blanks-*` | direct |
| 17 | `MC_READING_SINGLE` | single select | `reading/presentation/pages/mc_reading_single_screen.dart` | `mcReadingSingle` | `24-multiple-choice-single-answer-*` | direct |
| 18 | `MC_LISTENING_MULTIPLE` | multi select | `listening/presentation/pages/mc_listening_multiple_screen.dart` | `mcListeningMultiple` | `27-multiple-choice-multiple-answer-listening-*` | direct |
| 19 | `FILL_BLANKS_LISTENING` | fill blanks | `listening/presentation/pages/fill_blanks_listening_screen.dart` | `fillBlanksListening` | `28-fill-in-the-blanks-listening-*` | direct |
| 20 | `HIGHLIGHT_CORRECT_SUMMARY` | single select | `listening/presentation/pages/highlight_correct_summary_screen.dart` | `highlightCorrectSummary` | `29-highlight-correct-summary-*` | direct |
| 21 | `MC_LISTENING_SINGLE` | single select | `listening/presentation/pages/mc_listening_single_screen.dart` | `mcListeningSingle` | `30-multiple-choice-single-answer-listening-*` | direct |
| 22 | `SELECT_MISSING_WORD` | single select | `listening/presentation/pages/select_missing_word_screen.dart` | `selectMissingWord` | `31-select-missing-word-listening-*` | direct |
| 23 | `HIGHLIGHT_INCORRECT_WORDS` | token toggle | `listening/presentation/pages/highlight_incorrect_words_screen.dart` | `highlightIncorrectWords` | `32-highlight-incorrect-words-listening-*` | direct |

## Asset and visual-state notes

- The bundle has 34 screen directories because it includes lifecycle screens,
  transitions and completion in addition to the 23 task types.
- Read Aloud has two visual assets: `01-read-aloud-*` is canonical and
  `12-read-aloud-*` supplies a duplicate PNG/state reference. Its HTML is a
  Google sign-in capture and must not be used as implementation source.
- `04-terms-conditions-*/screen.html` is also invalid, but Terms & Conditions is
  outside this refactor.
- Required states per family are recorded in the phase files: shell/default,
  hover/focus/disabled, selected/clear, audio lifecycle, recording/upload,
  fill-blank variants, highlight normal/hover/active, editor metrics/limits and
  ordering initial/reordered.
- `SUMMARIZE_GROUP_DISCUSSION` and `RESPOND_TO_A_SITUATION` have no direct
  screen asset. Keep their derived fallback status visible in visual reports;
  exact pixel parity waits for design assets.

