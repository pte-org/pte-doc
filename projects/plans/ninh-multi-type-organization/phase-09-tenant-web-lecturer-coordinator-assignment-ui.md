# Phase 9: tenant-web — Lecturer/Coordinator Assignment UI

## Requirements

The Host-facing UI for Phase 5's assignment endpoints — assign/unassign a
`LECTURER` to a Class, a `PROGRAM_COORDINATOR` to a Program, on each
entity's detail view.

Maps to: `plan.md` Decision 2; Research Summary items 6, 9.

## Design Constraints

- **Mirrors `ProctorAssignmentSection.tsx`/`AssignProctorModal.tsx`
  almost exactly** — existing/new tabs, react-query
  mutate→invalidate, a section listing current assignees with an unassign
  action. No new interaction pattern invented; this is explicitly the
  closest FE precedent in the repo (Research Summary item 9).
- **No role sub-classification/legend needed** (unlike Proctor's Lead/
  Assistant split) — per Phase 5's Design Constraints, there's no `role`
  field on either assignment table, so the "roles legend" section from
  `ProctorAssignmentSection.tsx` has no equivalent here; keep the component
  simpler, don't invent a sub-role UI that doesn't exist server-side.
- **Filtering the "pick existing" list by role client-side**: fetch
  `GET /users` (already tenant-scoped) and filter to
  `roles.includes("LECTURER")` / `roles.includes("PROGRAM_COORDINATOR")`
  respectively — same pattern `AssignProctorModal.tsx`'s
  `useTenantProctors` already establishes for `PROCTOR`.
- New account creation (the "new" tab) creates the user with the
  corresponding role directly via `POST /users` (single, not bulk) —
  mirrors `useCreateProctorAccount`'s shape exactly, just a different role
  value in the request body.
- Same partial-failure handling as `AssignProctorModal.tsx`: if account
  creation succeeds but the assignment call fails, route the Host to
  "pick existing" pre-selected on the newly created account rather than a
  confusing blind retry (this is a real, already-hit bug class in this
  repo per `ninh-host-add-student` Phase 5's QUAL-001 — don't reintroduce
  it here by building a naive version from scratch).
- No hardcoded strings in JSX — new constants in
  `features/classes/constants/` (Lecturer) and `features/programs/constants/`
  (Coordinator).

## Steps

1. `features/classes/api/index.ts` — `useLecturerAssignments(classPublicId)`,
   `useAssignLecturer`, `useUnassignLecturer`, `useTenantLecturers()`
   (filtered `GET /users` by role). `features/programs/api/index.ts` —
   the same 3 for Coordinator.
2. `features/classes/components/LecturerAssignmentSection.tsx` +
   `AssignLecturerModal.tsx` (mirrors `ProctorAssignmentSection.tsx`/
   `AssignProctorModal.tsx` minus the role-select/legend). Wired into the
   Class detail view (Phase 7/8's `ClassDetailView` or per-Class roster
   page).
3. `features/programs/components/CoordinatorAssignmentSection.tsx` +
   `AssignCoordinatorModal.tsx` — same shape, wired into `ProgramDetailView`.
4. `tsc --noEmit`, `eslint`, `next build`.

## Success Criteria

- [ ] A Host can assign an existing `LECTURER` user to a Class, see them
      listed, and unassign — the same user can be reassigned to a
      different Class afterward.
- [ ] A Host can create a brand-new Lecturer account inline and have it
      assigned in one flow; if the assignment step fails after account
      creation, the Host is routed to "pick existing" pre-selected on that
      new account, not left stuck.
- [ ] The same 2 behaviors work identically for Program Coordinator on a
      Program.
- [ ] `pnpm --filter tenant-web lint`/`build` clean.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after
  implementing this phase).
- Testing: not started.

## Risks

- None beyond what's already flagged in Phase 5 (no server-side role-match
  validation) — this phase is the FE-side mitigation for that, so the risk
  is closed here, not deferred further.
