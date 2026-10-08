# Phase 01 Output — Task Coverage Matrix

Status values are release evidence, not UI copy:

- `canonical-contract`: the backend profile/answer contract exists.
- `renderer-status`: the `pte-practice` renderer is `not-started`, `implemented` or `verified`.
- `content-status`: content is `seeded`, `fixture-only`, `reference-verified` or `reference-unverified`.
- `release-status`: `not-releasable`, `production-supported` or `blocked-contract`.

Because Phase 01 runs before the new web is implemented, no row is called
`production-supported` yet. A row can only receive that label after backend
content, renderer and first-question/skip/submit evidence all exist.

| Canonical task type | Interaction family | Media | Canonical contract | Renderer | Content | Release | Boundary |
|---|---|---|---|---|---|---|---|
| `PERSONAL_INTRODUCTION` | speech recording | microphone | available | not-started | reference-unverified | not-releasable | unscored; never show as a scored result |
| `READ_ALOUD` | speech recording | image/audio/microphone | available | not-started | reference-unverified | not-releasable | readiness and recording required |
| `REPEAT_SENTENCE` | speech recording | audio/microphone | available | not-started | reference-unverified | not-releasable | no silent empty recording |
| `DESCRIBE_IMAGE` | speech recording | image/microphone | available | not-started | reference-unverified | not-releasable | image must be pinned safely |
| `RE_TELL_LECTURE` | speech recording | audio/microphone | available | not-started | reference-unverified | not-releasable | audio readiness before record |
| `ANSWER_SHORT_QUESTION` | speech recording | audio/microphone | available | not-started | reference-unverified | not-releasable | no answer key in delivery |
| `RESPOND_TO_A_SITUATION` | speech recording | image/microphone | available | not-started | reference-unverified | not-releasable | text prompt remains safe |
| `SUMMARIZE_GROUP_DISCUSSION` | speech recording | audio/microphone | available | not-started | reference-unverified | not-releasable | deferred until media contract is ready |
| `SUMMARIZE_WRITTEN_TEXT` | text input | none | available | not-started | fixture-only | not-releasable | scoring display depends on scorer contract |
| `WRITE_ESSAY` | text input | none | available | not-started | fixture-only | not-releasable | preserve word count and draft |
| `MC_READING_SINGLE` | single choice | none | available | not-started | reference-verified | not-releasable | first question verified in reference |
| `MC_READING_MULTIPLE` | multiple choice | none | available | not-started | reference-verified | not-releasable | checkbox semantics |
| `RE_ORDER_PARAGRAPHS` | reorder | none | available | not-started | reference-verified | not-releasable | keyboard alternative required |
| `FILL_IN_THE_BLANKS_DRAG_AND_DROP` | drag to blank | none | available | not-started | reference-verified | not-releasable | stable option identity |
| `FILL_IN_THE_BLANKS_DROPDOWN` | dropdown | none | available | not-started | reference-verified | not-releasable | selected value is schema-validated |
| `SUMMARIZE_SPOKEN_TEXT` | text input | audio | available | not-started | reference-unverified | not-releasable | audio readiness before text entry |
| `MC_LISTENING_SINGLE` | single choice | audio | available | not-started | reference-verified | not-releasable | video-like reference is not a video contract |
| `MC_LISTENING_MULTIPLE` | multiple choice | audio | available | not-started | reference-verified | not-releasable | playback failure blocks submit |
| `FILL_IN_THE_BLANKS_TYPE_IN` | text input | none | available | not-started | reference-verified | not-releasable | typed blank payload |
| `HIGHLIGHT_CORRECT_SUMMARY` | text marking | none | available | not-started | fixture-only | not-releasable | selected ranges need stable offsets |
| `SELECT_MISSING_WORD` | single choice | audio | available | not-started | reference-verified | not-releasable | missing phrase remains content-driven |
| `HIGHLIGHT_INCORRECT_WORDS` | transcript marking | audio | available | not-started | reference-verified | not-releasable | word identity, not visual index, is submitted |
| `WRITE_FROM_DICTATION` | text input | audio | available | not-started | reference-verified | not-releasable | audio readiness and word counter |
| `WRITE_EMAIL` | text input | none | missing | not-started | reference-unverified | blocked-contract | backend canonical enum/runtime is absent |
| Explicit video capability | media modifier | video | missing | not-started | reference-unverified | blocked-contract | never silently mapped to audio |

Canonical contract availability here means the interaction family and safe
payload contract exist; it does not mean the new web renderer or production
question content has shipped.
