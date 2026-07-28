# Phase 3: Blueprint & Immutable Snapshot

## Requirements

Let a Host list/create blueprints, choose eligible questions and composition
settings, inspect blueprint detail, and publish a blueprint into an immutable
snapshot that later sessions can reference.

Maps to: **P1 Story #4 (blueprint and immutable snapshot) | FR-09, FR-17,
FR-18**

## Design Constraints

- Blueprint and snapshot behavior remains in `authoring`; do not create a
  scheduling dependency before Phase 4.
- Use existing `/api/authoring/blueprints`,
  `/api/authoring/blueprints/{publicId}/publish`, and
  `/api/authoring/snapshots/{publicId}` contracts.
- The builder selects only question public IDs returned by the accessible
  question list; it never accepts a tenant ID or arbitrary hidden question ID
  from user input.
- Blueprint edit/update is not invented when the backend exposes create/list/
  detail only. A user creates a new blueprint when a different composition is
  required.
- Snapshot publication is an explicit non-auto-retried mutation with confirmation
  and loading-disabled controls.
- A published snapshot is rendered read-only. No UI path mutates snapshot
  questions or metadata.
- Blueprint list, builder, and snapshot detail use separate BLoC flows to keep
  files and state machines focused.

## Steps

1. Re-check blueprint create/response and snapshot response DTOs, including
   composition fields, item ordering, status, and public IDs.
2. Add immutable blueprint, blueprint-item/composition, snapshot, and
   snapshot-item domain entities plus JSON model tests.
3. Extend `AuthoringRepository` with blueprint list/create/detail and snapshot
   publish/detail interfaces using explicit typed inputs.
4. Implement repository calls and exact request-shape tests for blueprint
   composition and publish gateway paths.
5. Build `BlueprintListBloc` with loading/empty/loaded/failure states and
   `BlueprintBuilderBloc` with validation/submitting/success/failure states.
6. Build a builder page that loads accessible questions, supports deterministic
   selection/order, validates nonempty composition, and summarizes task/skill
   coverage before submission.
7. Build blueprint list/detail pages and a publish confirmation flow; prevent
   duplicate publish commands while in flight.
8. Build a read-only snapshot detail page that renders the backend snapshot
   version/identity and pinned item composition.
9. Register new use cases/BLoCs in `authoring_module.dart`; ensure no scheduling
   import is added.
10. Add unit, repository, BLoC, and widget tests for selection, ordering,
    invalid composition, publish success/failure, and immutable rendering.
11. Run all authoring tests, prior-phase regressions, `flutter analyze`, full
    Flutter tests, and a runtime create → publish → fetch contract check.

## Success Criteria

- [x] Host can list accessible blueprints and create one from accessible
      questions with deterministic ordering/composition.
- [x] Invalid or empty composition is rejected before an API call.
- [x] Publish is explicit, single-flight, and returns a snapshot rendered as
      read-only.
- [x] The Flutter client exposes no snapshot update/delete mutation.
- [x] No scheduling dependency exists in the authoring feature.
- [ ] Create → publish → fetch succeeds against the gateway or any runtime block
      is recorded without marking the phase passed.
- [x] Authoring regressions, Phase-3 tests, analysis, and full suite pass.

## Quality and Testing State

- Quality gate: approved. Report:
  `quality/phase-03-blueprint-and-snapshot-quality-report.json`.
- Testing: passed with the runtime gateway check pending. Evidence:
  `tests/phase-03-blueprint-and-snapshot-test-report.json`.

## Risks

- **MEDIUM:** Blueprint DTO composition may encode ordering/sections differently
  from the UI model. Mitigation: capture exact controller DTOs and test the
  serialized request rather than inferring from entity names.
- **MEDIUM:** Accessible question data can change between builder load and
  submit. Mitigation: treat backend validation as authoritative and preserve the
  draft selection when a referenced item is rejected.
- **LOW:** Users may interpret “publish” as editable publication. Mitigation:
  confirmation copy explicitly states that the snapshot is immutable and a new
  blueprint/snapshot is required for changes.
