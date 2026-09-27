# Phase 7: Dispatcher Registry & Legacy Cleanup

## Goal

Switch runtime routing to the seven family templates only after the migrated
screens have rendered through the offline catalog. Remove obsolete skill-based
screens and widgets only after the new route compiles and the old behavior has
been compared.

## Design constraints

- The dispatcher must route exactly the 23 scored/task-preview types listed in
  `design-coverage-matrix.md`; `WRITE_ESSAY` is canonical and
  `WRITE_ESSAY_V2` must not remain as a runtime type.
- `READING_INSTRUCTIONS` and `SECTION_COMPLETED` remain lifecycle pages, not
  task-template entries.
- The family registry may choose template and metadata, but it must not own
  BLoC/Cubit state or invent API data.
- No legacy file is deleted until `flutter analyze` succeeds with the new
  imports and the preview catalog can route every task type.

## Steps

1. Create small family registries under the existing
   `lib/features/exam_attempt/presentation/dispatch/` (or the established
   equivalent), covering record, free text, single select, multi select, fill
   blanks, ordering and token toggle.
2. Reduce `lib/features/exam_attempt/presentation/widgets/task_type_dispatcher.dart`
   to a registry lookup/delegation layer. Preserve lifecycle routing, lockdown
   banner placement, `TaskView` injection and existing answer callbacks.
3. Run the 23-entry preview catalog through the dispatcher. Assert every entry
   returns a non-placeholder task screen and the normalized type is stable.
4. Verify imports and route ownership against the actual current paths before
   deleting anything. In particular, the current legacy files include:
   `reading/.../mc_option_list.dart`,
   `reading/.../mc_multiple_option_list.dart`,
   `reading/.../reading_task_header_labels.dart`,
   `listening/.../listening_option_list.dart`,
   `listening/.../listening_multiple_option_list.dart`,
   `listening/.../listening_task_header_labels.dart`,
   `listening/.../listening_word_count_label.dart`,
   `speaking_writing/.../word_count_label.dart`, and
   `speaking_writing/.../writing_task_header.dart`.
5. Delete only superseded task pages and duplicate Essay implementation after
   the compile gate. Rename the surviving Essay page/body to the canonical
   `write_essay_screen.dart`/`write_essay_body.dart` (or the chosen canonical
   equivalent) and update all imports and fixtures together.
   Include the dev-only `lib/dev/writing_preview_web.dart` in the normalization
   check; it currently contains the obsolete type string.
6. Remove deprecated token aliases only when `rg` confirms no consumers. Keep
   `auto_advance_on_upload_ready.dart`; it is behavior, not a disposable UI
   mixin. Remove `auto_record_timer_bridge_mixin.dart` only after the feature
   layer has an equivalent tested bridge and no import remains.
7. Remove empty directories only after source-control and analyzer checks show
   they contain no required asset or test.

## Acceptance

- [ ] Every one of the 23 task types routes to exactly one family template.
- [ ] `WRITE_ESSAY_V2` is absent from dispatcher, fixtures and route metadata.
- [ ] Lifecycle pages still route and lockdown behavior is unchanged.
- [ ] No migrated screen imports a superseded option list, header-label mapper,
      duplicate word-count implementation or old Essay page.
- [ ] `AutoAdvanceOnUploadReady` behavior and record-task timer ownership remain
      covered by tests.
- [ ] Legacy deletion is reflected in `git diff`; no deletion happened before
      the new route/analyzer gate.

## Quality and testing state

- **Quality gate:** run `/ck:quality --gate` after the phase. Block on any
  finding affecting routing, lifecycle, answer behavior or cleanup safety.
- **Testing:** run dispatcher coverage, preview smoke, lifecycle and payload
  regression tests. Compare against `baseline-payloads.json`; existing baseline
  failures remain classified rather than silently ignored.

## File ownership

**Files exclusively owned by this phase:**

- family dispatcher/registry files introduced in this phase;
- `lib/features/exam_attempt/presentation/widgets/task_type_dispatcher.dart`;
- imports and deletion/rename set for superseded task pages/widgets;
- dispatcher and route tests.

**Files not modified by this phase:**

- `pte-api`;
- `ExamAttemptBloc`, answer cubits, timer service, lockdown service and outbox
  serialization.

## Cook State

- **Status:** completed.
- **Testing:** dispatcher-compatible runtime routes and full regression suite passed.
- **Quality:** no legacy `WRITE_ESSAY_V2` or removed reading-passage identifier remains in active scope.
