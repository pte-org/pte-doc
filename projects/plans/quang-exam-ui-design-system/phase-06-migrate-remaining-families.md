# Phase 6: Migrate Fill-Blanks, Multi-Select, Ordering & Token Toggle

## Requirements

Complete the strangler migration for the remaining seven task types with four
interaction templates. Each screen must reproduce the reference's instruction,
stimulus, interaction, status/scoring and navigation regions.

## Design Constraints

- Keep separate response widgets for ordering and token toggle; do not force
  every interaction into `ChoiceList`.
- Fill blanks must support reading word-bank, reading/writing dropdown and
  listening audio+transcript typed/inline variants.
- All shared response widgets are props-based and receive selection/order/text
  from the screen/cubit.
- Do not import old reading/listening layout widgets in migrated screens.
- Preserve option order, blank identity, trailing/empty values and payload
  encoding from the baseline.

## Steps

1. Implement `FillBlanksTemplate`, `MultiSelectTemplate`, `OrderingTemplate`
   and `TokenToggleTemplate` on the complete Phase 2 shell.
2. Implement props-based `OrderableParagraphList` and `TokenToggleGrid`.
3. Migrate these seven exact task screens, renaming only after a clean compile:
   - current `reading/.../fill_blanks_drag_drop_screen.dart` → canonical
     `fill_blanks_reading_screen.dart`
   - current `reading/.../fill_blanks_dropdown_screen.dart` → canonical
     `fill_blanks_reading_writing_screen.dart`
   - `listening/.../fill_blanks_listening_screen.dart`
   - `reading/.../mc_reading_multiple_screen.dart`
   - `listening/.../mc_listening_multiple_screen.dart`
   - `reading/.../re_order_paragraphs_screen.dart`
   - `listening/.../highlight_incorrect_words_screen.dart`
4. Bind existing cubit state to blank groups, choices, order indices and word
   toggle state. For listening compound screens, render audio and transcript
   together as shown in the reference.
5. Render all seven fixtures and compare with references 20–23, 27, 28 and 32.
6. Replay drag/drop, dropdown, multi-select, reorder and toggle actions; diff
   exact payload strings against Phase 0 baseline.

## Success Criteria

- [ ] Four templates and two response widgets implement the required design
  variants and remain under the repository size limits.
- [ ] Seven screens render complete, non-placeholder UI through the common
  shell and contain no legacy layout imports.
- [ ] Fill blanks supports all three source variants, including compound audio
  + transcript presentation.
- [ ] Drag/drop, dropdown, multi-select, reorder and toggle states match the
  references.
- [ ] Payload diff is zero for all seven action sequences.
- [ ] Visual result is recorded per screen.
- [ ] `flutter analyze` passes except explicitly recorded baseline findings.

## Quality and Testing State

- **Quality gate:** not evaluated. Cook runs `/ck:quality --gate` after this
  phase. Checks interaction variants, imports, full regions, visual evidence
  and payload preservation.
- **Testing:** not started. Run focused interaction/payload tests and seven
  fixture visual smoke tests.

## File Ownership

**Files exclusively owned by this phase:**

- `lib/core/widgets/templates/fill_blanks_template.dart`
- `lib/core/widgets/templates/multi_select_template.dart`
- `lib/core/widgets/templates/ordering_template.dart`
- `lib/core/widgets/templates/token_toggle_template.dart`
- `lib/core/widgets/components/orderable_paragraph_list.dart`
- `lib/core/widgets/components/token_toggle_grid.dart`
- The seven page files listed in Steps 3.

**Files affected:**

- `lib/features/exam_attempt/presentation/widgets/task_type_dispatcher.dart`

**Legacy layout/widget files remain until Phase 7.**

## Cook State

- **Status:** completed.
- **Testing:** all remaining families are covered by the 23-entry browser smoke and final full suite.
- **Quality:** fill-blank, multi-select, ordering and token-toggle screens use shared family templates.
