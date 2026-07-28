# Phase 4: Session & Composition

## Requirements

Build the Host scheduling workspace for listing and creating full/practice
sessions, assigning an immutable snapshot composition, viewing session detail,
and exposing only lifecycle actions currently valid according to backend state.

Maps to: **P1 Story #5 (full/practice session composition) | FR-10, FR-17,
FR-18**

## Design Constraints

- Create a standalone `scheduling` feature. It may consume snapshot identifiers
  through typed navigation/input but must not import authoring BLoCs or repository
  implementations.
- Use existing `/api/scheduling/sessions` list/create/detail,
  `/composition`, `/open`, and `/close` contracts. Scoring/publish actions remain
  Phase 6 even though they share the session controller.
- Session status from the backend is authoritative. UI action visibility is a
  convenience and cannot replace server transition validation.
- Full/practice session type is represented by backend-supported values captured
  from the current DTO; no client-only session mode is invented.
- Composition accepts an existing immutable snapshot public ID. The session
  does not embed mutable question drafts.
- Open/close are explicit, single-flight, non-auto-retried mutations. A 409
  triggers authoritative detail reload and state-transition feedback.
- List/detail/create/composition states remain separate enough to avoid one
  scheduling god BLoC.

## Steps

1. Re-check session create/response/composition DTOs, enums, validation, role
   annotations, and allowed open/close transitions.
2. Define immutable session, composition, session status/type, and typed create/
   composition input domain models.
3. Define `SchedulingRepository` plus list/create/get/update-composition/open/
   close use cases.
4. Implement DTO parsing and request serialization with repository tests for
   full/practice types, snapshot IDs, date/time fields, status, and errors.
5. Implement session list and detail BLoCs with explicit loading/empty/loaded/
   failure/transition states.
6. Build session list cards and filters limited to backend-supported data;
   include create navigation and retry.
7. Build session create form with task-independent metadata, session type, and
   backend-required time/availability validation.
8. Build composition selection using published snapshot inputs and a read-only
   summary before saving.
9. Build detail actions for open/close, gated by role and current status, with
   confirmation, duplicate-submit prevention, 409 reload, and failure feedback.
10. Register the scheduling feature and expose it through Host navigation
    without importing authoring implementation types.
11. Add domain/data/BLoC/widget tests and run all previous Flutter regressions,
    analysis, full suite, and runtime create → compose → detail check.

## Success Criteria

- [ ] Host can list, create, and view backend-supported full/practice sessions.
- [ ] A published snapshot can be assigned as session composition and reloaded
      from authoritative session detail.
- [ ] Invalid dates/type/composition are rejected before submission.
- [ ] Open/close controls appear only for role/status combinations supported by
      the backend and handle a backend 409 by reloading state.
- [ ] Scheduling has no dependency on authoring presentation/data
      implementations.
- [ ] Phase-4 tests, all prior regressions, analysis, and full suite pass; runtime
      contract evidence is recorded.

## Quality and Testing State

- Quality gate: not run. Planned report:
  `quality/phase-04-session-and-composition-quality-report.json`.
- Testing: not run. Planned evidence:
  `tests/phase-04-session-and-composition-test-report.json`.

## Risks

- **HIGH:** UI assumptions about allowed status transitions can drift from
  scheduling-service. Mitigation: backend remains authoritative; conflicts
  reload detail instead of forcing local state.
- **MEDIUM:** Date/time interpretation may differ between local Windows time and
  backend UTC/offset fields. Mitigation: record the DTO format explicitly and
  add serialization tests around timezone boundaries.
- **MEDIUM:** Snapshot discovery belongs to authoring but session composition
  belongs to scheduling. Mitigation: pass selected snapshot public IDs through a
  narrow navigation result/domain input, never cross-import BLoCs.
