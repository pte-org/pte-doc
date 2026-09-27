# Phase 2: Complete Exam Chrome & Shared Components (FR-05, FR-06, FR-07, FR-09, FR-10, FR-21)

## Requirements

Build the shared presentation layer that reproduces the persistent chrome and
the reusable visual primitives in the design bundle. This phase creates the
complete shell; migration phases only provide task-specific content and
response slots.

## Design Constraints

- `ExamShell` is a fixed desktop frame. Header and footer are `56px`, matching
  `DESIGN.md` and the valid canonical screen HTML; the generated `64px` token is
  not used by the exam shell.
- Keep both content frames: generic `960px` and reading workstation `1160px`.
- Shell must support the visible design regions: candidate/brand header,
  audio/check utility, item counter, timer, task banner/meta, instruction and
  scoring blocks, content area, fixed navigation footer and optional chrome
  strip. Do not reduce every screen to only a two-column Row.
- Components are props-based and do not read Cubit/BLoC. No `context.read`,
  `context.watch`, `BlocBuilder` or `BlocListener` in shared components/shell.
- Use design token styles and state variants: default, hover, focus, selected,
  disabled, warning, error, success, empty and populated.
- No legacy file is deleted in this phase; migration uses the old screens as a
  comparison reference until Phase 7.

## Steps

1. Implement `ExamShell`, `ExamHeaderBar`, `ExamFooterBar` and the task chrome
   regions with the Phase 0 measured dimensions and design typography.
2. Implement the shared components from `component-spec.md`: instruction card,
   audio stimulus player, choice row/list, fill-blank chip, inline select,
   highlightable word, textarea with live metric, subheader/banner and status
   blocks needed by the screen references.
3. Implement a presentation-only `ExamTaskUiModel` under
   `lib/features/exam_attempt/presentation/model/` and
   `TaskViewUiAdapter` beside it. Include task content, compound stimulus
   parts, response model, timing/media state and `DataOrigin` (`api`, `fixture`,
   `derived`, `unavailable`). Do not change `TaskView` or invent a backend
   contract. Core widgets receive only this model/props and never import the
   exam domain adapter.
4. Implement a data-only stimulus model that can represent compound content
   such as audio + transcript/text. Do not force every task through a single
   enum that cannot represent the design.
5. Implement `TaskTypeMeta` as the single registry for title, instruction,
   section, family, stimulus parts, scoring mode and design reference.
6. Consolidate duplicate choice/word-count/header presentation logic behind the
   new props-based components, but keep old files until Phase 7.
7. Verify all 23 entries from `ExamUiPreviewCatalog` can be hosted by the shell
   without API calls and without placeholder content.
8. Replay the Phase 0 payload baseline and confirm this shared-layer change does
   not alter the serialized answer strings.

## Success Criteria

- [ ] Shell chrome matches the reference geometry: fixed header/footer, correct
  content frame per screen family and footer actions.
- [ ] Shared components implement the required design variants and are
  props-based with no state-layer imports.
- [ ] Compound stimulus data is supported for audio + transcript/text screens.
- [ ] The adapter carries provenance and missing API fields are explicit; no
      production constructor silently uses preview fixture content.
- [ ] `TaskTypeMeta` resolves all 23 task types.
- [ ] All 23 preview fixtures render a complete shell with non-empty task content
  and the correct family-specific response region.
- [ ] Legacy files remain available for side-by-side comparison; no deletion is
  claimed in this phase.
- [ ] Baseline payloads remain byte-for-byte identical.
- [ ] `flutter analyze` passes except explicitly recorded pre-existing baseline
  findings.

## Quality and Testing State

- **Quality gate:** not evaluated. Cook runs `/ck:quality --gate` after this
  phase. Checks shell geometry, visual regions, props-only rule, registry
  coverage, file size and design token usage.
- **Testing:** not started. Run shell resize/widget tests, 23-task preview
  smoke test and baseline payload replay.

## File Ownership

**Files exclusively owned by this phase:**

- `lib/core/widgets/exam/exam_shell.dart`
- `lib/core/widgets/exam/exam_header_bar.dart`
- `lib/core/widgets/exam/exam_footer_bar.dart`
- `lib/core/widgets/exam/stimulus_spec.dart` (or the equivalent compound model)
- `lib/core/widgets/components/choice_row.dart`
- `lib/core/widgets/components/choice_list.dart`
- `lib/core/widgets/components/instruction_card.dart`
- `lib/core/widgets/components/audio_stimulus_player.dart`
- `lib/core/widgets/components/fib_chip.dart`
- `lib/core/widgets/components/in_text_select.dart`
- `lib/core/widgets/components/highlightable_word_span.dart`
- `lib/core/widgets/components/exam_textarea.dart`
- `lib/core/widgets/components/subheader_banner.dart`
- `lib/core/widgets/components/exam_status_block.dart` (if required by mockups)
- `lib/core/constants/task_type_meta.dart`
- `lib/features/exam_attempt/presentation/model/exam_task_ui_model.dart`
- `lib/features/exam_attempt/presentation/model/task_view_ui_adapter.dart`

**Legacy files remain until Phase 7.**

## Cook State

- **Status:** completed.
- **Testing:** focused preview widget tests and final full suite passed.
- **Quality:** core widgets are props-based and contain no exam BLoC imports.
