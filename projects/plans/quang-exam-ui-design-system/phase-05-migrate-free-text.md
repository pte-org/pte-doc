# Phase 5: Migrate Free-Text Screens (FR-12, FR-13, FR-16, FR-19)

## Requirements

Migrate the four free-text task screens to one template with the full design
composition: instruction/scoring block, prompt or audio stimulus, editor
toolbar, textarea, live word/character metrics, range validation, helper/error
states and fixed navigation chrome.

## Design Constraints

- `FreeTextResponseTemplate` owns layout only and receives props-based stimulus
  and response widgets. It does not read a Cubit/BLoC.
- `ExamTextarea` owns no answer state. The existing screen/cubit remains the
  source of text and submission events.
- Normalize the canonical task type to `WRITE_ESSAY`; `WRITE_ESSAY_V2` must not
  appear in the dispatcher or preview contract.
- Preserve raw text whitespace and exact payload serialization.
- Correct runtime paths are listening for `SUMMARIZE_SPOKEN_TEXT` and
  `WRITE_FROM_DICTATION`, and speaking_writing for the two writing tasks.

## Steps

1. Implement `FreeTextResponseTemplate` using the complete shell and the
   design's editor/validation regions.
2. Normalize the writing fixture from `WRITE_ESSAY_V2` to `WRITE_ESSAY` and
   keep one canonical `write_essay_screen.dart` implementation. Do not delete
   or rename a file until imports and dispatcher compile.
   Also normalize the dev-only `lib/dev/writing_preview_web.dart` reference.
3. Migrate these exact pages:
   - `speaking_writing/presentation/pages/summarize_written_text_screen.dart`
   - `speaking_writing/presentation/pages/write_essay_screen.dart`
   - `listening/presentation/pages/summarize_spoken_text_screen.dart`
   - `listening/presentation/pages/write_from_dictation_screen.dart`
4. Bind existing cubit states to passage/audio/no-stimulus stimulus parts,
   editor text, word limits, live metrics and submit callbacks.
5. Render all four fixtures through the real dispatcher and compare against
   references 17, 18, 26 and 33.
6. Replay type/clear/submit sequences and diff exact payload strings against
   the Phase 0 baseline, including whitespace and empty text.

## Success Criteria

- [ ] Four screens render complete design regions and all editor affordances.
- [ ] Only one canonical `write_essay_screen.dart` and task type
  `WRITE_ESSAY` remain.
- [ ] Listening screens use their actual listening paths and stimulus behavior.
- [ ] Word/character counters and min/max validation match the reference.
- [ ] Payload diff is zero for all four action sequences.
- [ ] Visual result is recorded per screen; no placeholder editor/prompt.
- [ ] `flutter analyze` passes except explicitly recorded baseline findings.

## Quality and Testing State

- **Quality gate:** not evaluated. Cook runs `/ck:quality --gate` after this
  phase. Checks canonical naming, controller disposal, full editor UI, visual
  states and payload preservation.
- **Testing:** not started. Run focused text/controller lifecycle tests,
  validation/counter tests and four fixture visual smoke tests.

## File Ownership

**Files exclusively owned by this phase:**

- `lib/core/widgets/templates/free_text_response_template.dart`
- `lib/features/exam_attempt/speaking_writing/presentation/pages/summarize_written_text_screen.dart`
- `lib/features/exam_attempt/speaking_writing/presentation/pages/write_essay_screen.dart`
- `lib/features/exam_attempt/listening/presentation/pages/summarize_spoken_text_screen.dart`
- `lib/features/exam_attempt/listening/presentation/pages/write_from_dictation_screen.dart`
- Writing fixture canonical-name correction.

**Files affected:**

- `lib/features/exam_attempt/presentation/widgets/task_type_dispatcher.dart`
- Existing `write_essay_v2_*` files only during safe rename, before Phase 7
  cleanup.

**Legacy layout files remain until Phase 7.**

## Cook State

- **Status:** completed.
- **Testing:** free-text preview/editor coverage and final full suite passed.
- **Quality:** free-text layout is stacked and uses shared textarea/toolbar presentation without API changes.
