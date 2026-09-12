# Phase 3: Migrate Single-Select Screens (FR-12, FR-13, FR-16, FR-19)

## Requirements

Migrate the four single-answer task screens to `SingleSelectTemplate` while
preserving the existing cubit/answer payload behavior and reproducing the
screen-specific stimulus composition.

## Design Constraints

- `SingleSelectTemplate` owns the complete task composition and receives
  `StimulusSpec`/`StimulusSlot` plus a props-based `ChoiceList` response.
- `StimulusSpec` must support passage, audio, image, no stimulus and compound
  audio+text content. The stimulus model describes parts; the template chooses
  the layout.
- Preserve design affordances: selected state, `Clear Selection`, item count,
  task metadata, A-/A+ where shown, and disabled/active navigation states.
- Screens must not import `reading_passage_layout`, `reading_content_card` or
  `listening_audio_bar`.
- Do not modify answer cubits or payload serialization.

## Steps

1. Implement/refine `SingleSelectTemplate` on the Phase 2 shell and design
   components.
2. Migrate these exact files:
   - `reading/presentation/pages/mc_reading_single_screen.dart`
   - `listening/presentation/pages/mc_listening_single_screen.dart`
   - `listening/presentation/pages/select_missing_word_screen.dart`
   - `listening/presentation/pages/highlight_correct_summary_screen.dart`
3. Bind each existing cubit state to stimulus parts, option labels, selected
   state and callbacks. Keep `TaskView`/outbox behavior unchanged.
4. Route the four task types through the existing dispatcher temporarily, so
   the old screen remains available for comparison.
5. Run the four preview fixtures through the real screen path and perform
   fixed-viewport visual comparison against references 24, 29, 30 and 31.
6. Replay the family action sequences and diff exact payload strings against
   `baseline-payloads.json`.

## Success Criteria

- [ ] Four screens render complete design regions through the common shell.
- [ ] Reading single-answer uses the reference passage layout; listening tasks
  use the reference audio/column or compound layout.
- [ ] No legacy layout imports remain in the four migrated screens.
- [ ] Selected, clear, focus/hover and disabled states match the references.
- [ ] Payload diff is zero for all four action sequences.
- [ ] Visual result is recorded per screen; no placeholder response or missing
  chrome is accepted.
- [ ] `flutter analyze` passes except explicitly recorded baseline findings.

## Quality and Testing State

- **Quality gate:** not evaluated. Cook runs `/ck:quality --gate` after this
  phase. Checks imports, template size, complete regions, visual evidence and
  payload preservation.
- **Testing:** not started. Run focused selection/clear behavior tests and the
  four fixture golden/smoke tests.

## File Ownership

**Files exclusively owned by this phase:**

- `lib/core/widgets/templates/single_select_template.dart`
- `lib/features/exam_attempt/reading/presentation/pages/mc_reading_single_screen.dart`
- `lib/features/exam_attempt/listening/presentation/pages/mc_listening_single_screen.dart`
- `lib/features/exam_attempt/listening/presentation/pages/select_missing_word_screen.dart`
- `lib/features/exam_attempt/listening/presentation/pages/highlight_correct_summary_screen.dart`

**Files affected:**

- `lib/features/exam_attempt/presentation/widgets/task_type_dispatcher.dart`
  (temporary dispatch wiring only)

**Legacy layout files are not deleted until Phase 7.**

## Cook State

- **Status:** completed.
- **Testing:** existing single-select tests plus final full suite passed.
- **Quality:** migrated screens use the shared single-select template while preserving feature state ownership.
