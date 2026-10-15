# Phase 08 Output - Runtime Coverage and Deferred Contracts

Date: 2026-10-08

The table records implementation evidence, not a promise of parity with the
reference product. A task is release-ready only after canonical content,
renderer, first-question, skip, submit and browser evidence are all present.

| Task or capability | Server contract | Client renderer | Current state | Release boundary |
|---|---|---|---|---|
| PERSONAL_INTRODUCTION | response recording + WAV binding | recording renderer | implemented, fixture-backed | not release-proven; reference content unverified |
| READ_ALOUD | response recording + WAV binding | recording renderer | implemented, fixture-backed | not release-proven; prompt media contract not delivered |
| REPEAT_SENTENCE | canonical profile exists | no runtime entry | deferred | audio prompt and speaking evidence required |
| DESCRIBE_IMAGE | canonical profile exists | no runtime entry | deferred | pinned image and speaking evidence required |
| RE_TELL_LECTURE | canonical profile exists | no runtime entry | deferred | audio prompt and speaking evidence required |
| ANSWER_SHORT_QUESTION | canonical profile exists | no runtime entry | deferred | audio prompt and speaking evidence required |
| RESPOND_TO_A_SITUATION | canonical profile exists | no runtime entry | deferred | speaking content evidence required |
| SUMMARIZE_GROUP_DISCUSSION | canonical profile exists | no runtime entry | deferred | audio prompt and speaking evidence required |
| SUMMARIZE_WRITTEN_TEXT | text schema | text renderer + Unicode word count | implemented, fixture-backed | scorer/content/browser evidence required |
| WRITE_ESSAY | text schema | text renderer + Unicode word count | implemented, fixture-backed | scorer/content/browser evidence required |
| MC_READING_SINGLE | choice schema | choice renderer | implemented | first-question browser evidence pending |
| MC_READING_MULTIPLE | choice schema | choice renderer | implemented | first-question browser evidence pending |
| RE_ORDER_PARAGRAPHS | order schema | order renderer | implemented | keyboard/browser evidence pending |
| FILL_IN_THE_BLANKS_DRAG_AND_DROP | placements schema | blank renderer | implemented | keyboard alternative/browser evidence pending |
| FILL_IN_THE_BLANKS_DROPDOWN | selections schema | blank renderer | implemented | browser evidence pending |
| SUMMARIZE_SPOKEN_TEXT | canonical profile exists | no runtime entry | deferred | prompt audio field/readiness contract required |
| MC_LISTENING_SINGLE | canonical profile exists | no runtime entry | deferred | prompt audio field/readiness contract required |
| MC_LISTENING_MULTIPLE | canonical profile exists | no runtime entry | deferred | prompt audio field/readiness contract required |
| FILL_IN_THE_BLANKS_TYPE_IN | canonical profile exists | no runtime entry | deferred | prompt audio and typed-blank schema evidence required |
| HIGHLIGHT_CORRECT_SUMMARY | canonical profile exists | no runtime entry | deferred | stable range/token schema required |
| SELECT_MISSING_WORD | canonical profile exists | no runtime entry | deferred | prompt audio field/readiness contract required |
| HIGHLIGHT_INCORRECT_WORDS | canonical profile exists | no runtime entry | deferred | stable token identity and audio required |
| WRITE_FROM_DICTATION | canonical profile exists | no runtime entry | deferred | prompt audio field/readiness contract required |
| WRITE_EMAIL | missing canonical enum/runtime | none | blocked contract | never map to essay |
| Explicit video | missing media field/capability | none | blocked contract | never map to audio |

## Known contract boundary

`PracticeTaskResponse` currently carries renderer metadata and the student's
saved answer, but no protected prompt-media reference/readiness contract.
Therefore listening/audio-prompt rows remain visible in catalog research but are
not made runnable by this implementation. This is intentional fail-closed
behavior, not a hidden client limitation.
