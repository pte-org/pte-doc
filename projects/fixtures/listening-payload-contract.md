# PTE Listening Payload Contract

**Contract version:** 1  
**Last updated:** 2026-09-12  
**Source of truth:** `listening-payload-contract.json`

This document defines the raw `payload` string submitted by `pte-app` for the
eight Listening task types currently covered by the contract. `payload` is
always a string in the request JSON. It is never a nested JSON object. The
exam-delivery service stores it as an opaque value; scoring and review decode
it according to `taskType` and the frozen task content.

The FE cubits below are the encoding source of truth:

- `pte-app/lib/features/exam_attempt/listening/presentation/cubit/summarize_spoken_text_cubit.dart`
- `pte-app/lib/features/exam_attempt/listening/presentation/cubit/write_from_dictation_cubit.dart`
- `pte-app/lib/features/exam_attempt/listening/presentation/cubit/mc_listening_multiple_cubit.dart`
- `pte-app/lib/features/exam_attempt/listening/presentation/cubit/highlight_correct_summary_cubit.dart`
- `pte-app/lib/features/exam_attempt/listening/presentation/cubit/select_missing_word_cubit.dart`
- `pte-app/lib/features/exam_attempt/listening/presentation/cubit/fill_blanks_listening_cubit.dart`
- `pte-app/lib/features/exam_attempt/listening/presentation/cubit/highlight_incorrect_words_cubit.dart`
- `pte-app/lib/features/exam_attempt/listening/presentation/cubit/mc_listening_single_cubit.dart`

## Encoding rules

| Task type | Shape | Wire encoding |
|---|---|---|
| `SUMMARIZE_SPOKEN_TEXT` | Free-form text | Raw `draftText`, unchanged by the cubit. |
| `WRITE_FROM_DICTATION` | Free-form text | Raw `draftText`, unchanged by the cubit. |
| `MC_LISTENING_SINGLE` | Single option selection | Exactly one selected option `orderIndex` as a decimal string, for example `"2"`. It is not comma-joined. |
| `HIGHLIGHT_CORRECT_SUMMARY` | Single option selection | Exactly one selected option `orderIndex` as a decimal string. |
| `SELECT_MISSING_WORD` | Single option selection | Exactly one selected option `orderIndex` as a decimal string. |
| `MC_LISTENING_MULTIPLE` | Multi-option selection | Selected option `orderIndex` values, numerically sorted ascending and comma-joined, for example `"0,2,3"`. The payload order is independent of toggle order. |
| `FILL_BLANKS_LISTENING` | Positional typed text | One typed value per gap in gap-index order, comma-joined. An unanswered gap is an empty entry. Empty entries, including the final one, are normative; `"rapid,,forest,"` represents four gaps: filled, unanswered, filled, unanswered. |
| `HIGHLIGHT_INCORRECT_WORDS` | Transcript word-index selection | Selected transcript token positions, numerically sorted ascending and comma-joined, for example `"3,7,11"`. These are positions in the displayed transcript, not option `orderIndex` values. |

### Positional typed text delimiter policy

Contract version 1 forbids a comma inside an individual typed gap value. The
comma is reserved as the positional separator, and values must be validated or
restricted by the FE interaction before they reach `positionalPayload`. No
escaping, quoting, trimming, or alternate encoding is defined in v1. This
keeps the existing serializer deterministic:

```dart
values.map((value) => value ?? '').join(',')
```

The policy applies to `FILL_BLANKS_LISTENING`'s gap values; it does not change
the raw text contract for `SUMMARIZE_SPOKEN_TEXT` or
`WRITE_FROM_DICTATION`.

### Empty answers

An untouched task may submit an empty string. For positional tasks, the number
and position of empty entries must still be preserved when a non-empty gap
exists later in the answer. For multi-selection and transcript word-index
selection, an empty string represents no selected values.

## Change control

This contract and its JSON fixture are manually maintained cross-repository
source-of-truth artifacts. Any wire-format change requires updating both files
and incrementing `contractVersion`; each repository then updates its vendored
copy and contract tests in the same change.
