# Phase 5: pte-app Runtime Registry and No-Silent-Skip Delivery

## Objective

Extend the existing `TaskTypeMeta`, family templates and dispatcher into a
versioned renderer registry. Normalize legacy task codes at the API boundary and
make an unsupported frozen task a visible, non-navigable update state.

## Files

- `pte-app/lib/core/constants/task_type_meta.dart`
- `pte-app/lib/features/exam_attempt/presentation/widgets/task_type_dispatcher.dart`
- `pte-app/lib/features/exam_attempt/domain/task_view.dart`
- `pte-app/lib/features/exam_attempt/data/repositories/exam_attempt_repository_impl.dart`
- exam-attempt UI adapter, capability request model, renderer registry and
  widget/parser tests

## Implementation steps

1. Update `task_type_meta.dart` and related constants to use the canonical
   post-V40 `FILL_IN_THE_BLANKS_*` names. Add one legacy alias map for reading
   old responses/snapshots; do not create duplicate renderer implementations.
2. Define immutable renderer registrations containing `rendererKey`, supported
   schema versions, canonical task codes, answer serializer/parser and a
   user-facing task title. Keep concrete screens in their existing feature and
   family ownership.
3. Make `TaskTypeDispatcher` resolve the server runtime profile first, then
   use the legacy `taskType` field only for old responses. Unknown renderer or
   schema returns a typed unsupported result instead of the current placeholder
   that could permit navigation.
4. Generate the capability manifest from registered renderer/schema support and
   include it in the start/preflight request. The manifest contains bounded
   keys/versions only, never implementation details or secrets. This dual-read
   app release must be available before BE changes any existing wire value from
   legacy to canonical; it must consume both `taskTypeCode`/`runtime` and the
   old `taskType` field.
5. Make `TaskView` and UI adapters tolerant of missing optional fields and
   unknown task codes. Preserve old timing, outbox, lockdown and answer
   serialization boundaries.
6. Add a friendly update-required/unsupported screen and map BE machine codes
   to feature constants. The screen cannot submit a fabricated answer or
   auto-next to change the exam's item count.
7. Verify all existing record-response, free-text, selection, ordering, fill
   and highlight interactions against their current answer payload contract.

## Acceptance criteria

- The app advertises exactly the capabilities it has registered.
- All current supported tasks, including the three canonical FILL variants,
  resolve intentionally to registered renderers.
- Legacy FILL values normalize to the canonical identity at one boundary.
- Unknown renderer/schema cannot auto-next, submit or show a misleading generic
  task; it presents the update/configuration state.
- Existing task-screen behavior and answer payloads remain unchanged for
  supported profiles.
- A genuinely new interaction remains blocked until BE and app capability
  support are released together.

## Design Constraints

- Flutter must not depend on Java enum names, database IDs or implementation
  class names.
- Server data cannot contain executable widget names, scripts or dynamic code.
- Do not rewrite the completed exam UI design-system screens; extend the
  dispatcher/metadata seam.
- Do not silently skip a task from a frozen exam.
- Keep technical identifiers in diagnostics; user copy comes from app constants.

## Quality and Testing State

Status at plan creation: testing not started; quality not evaluated.

Required before phase completion:

- Dart parser/model tests, canonical/legacy FILL alias tests, registry lookup
  and capability-manifest tests.
- Widget tests for each renderer family and fail-closed unknown renderer/schema
  tests; answer serialization and start-error UX regression tests.
- Run `flutter analyze` and the focused/full `flutter test` suite as practical.
- Mandatory `ck:quality --gate` receipt covering API compatibility, navigation
  safety, timer/answer behavior and unsupported-task UX.
