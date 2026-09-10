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

- [x] A Host can assign an existing `LECTURER` user to a Class, see them
      listed, and unassign — the same user can be reassigned to a
      different Class afterward.
- [x] A Host can create a brand-new Lecturer account inline and have it
      assigned in one flow; if the assignment step fails after account
      creation, the Host is routed to "pick existing" pre-selected on that
      new account, not left stuck.
- [x] The same 2 behaviors work identically for Program Coordinator on a
      Program.
- [x] `pnpm --filter tenant-web lint`/`build` clean.

## Quality and Testing State

- Quality gate: APPROVED, 0 findings on first pass. Reviewer independently
  verified: (1) `useLecturerAssignments`/`useCoordinatorAssignments` read
  `queryClient.getQueryData(TENANT_USERS_QUERY_KEY)` directly inside
  `queryFn` rather than closing over a stale `.data` snapshot, matching
  `useProctorAssignments`'s race-avoidance pattern exactly; (2) cache
  invalidation is correctly scoped per-Class (Lecturer) and per-Program
  (Coordinator); (3) the partial-failure "create succeeds, assign fails ->
  route to Existing tab pre-selected on the new account" handling is wired
  correctly in both `AssignLecturerModal` and `AssignCoordinatorModal`,
  reproducing the fix for the bug class already hit once in
  `ninh-host-add-student` Phase 5 (QUAL-001); (4) no hardcoded JSX strings;
  (5) all new api-client types/paths match the real backend DTOs/
  `@RequestMapping`s in `services/admin` field-for-field and path-for-path.
- Testing: no automated test framework runs in `tenant-web` (same
  no-precedent finding as Phases 6-8). Verified via
  `pnpm --filter tenant-web lint` (clean), `pnpm --filter tenant-web build`
  (clean, all 6 routes present, unchanged route list from Phase 8 —
  Lecturer/Coordinator UI is wired into existing
  `/host/programs/[publicId]` and
  `/host/programs/[publicId]/classes/[classPublicId]` routes, no new
  routes needed), and `pnpm --filter @pte/api-client typecheck` (clean,
  since this phase also added `types/admin/assignment.ts` and 2 new
  request modules).
- **Design decisions made during implementation, not fully specified by
  the phase's literal Steps**:
  - Backend's `LecturerAssignmentResponse`/`ProgramCoordinatorAssignmentResponse`
    (Phase 5) carry a generic `assigneePublicId` field (not
    `lecturerPublicId`/`coordinatorPublicId`) — read directly from
    `services/admin/.../dto/response/{LecturerAssignmentResponse,ProgramCoordinatorAssignmentResponse}.java`
    rather than assumed, and mirrored verbatim into the new
    `packages/api-client/src/types/admin/assignment.ts` types.
  - `useTenantLecturers()`/`useTenantCoordinators()` reuse the exact same
    `TENANT_USERS_QUERY_KEY` (`["tenantUsers"]`, imported from
    `features/exams/constants`) and `queryFn` as `useTenantProctors`
    (exams) and `useTenantStudents` (examoperations) — one shared
    `GET /users` cache entry per tenant, split four ways via `select`, per
    this repo's established convention (see `useTenantProctors`'s doc
    comment). No new endpoint or query key needed.
  - Per the Design Constraints, `LecturerAssignmentSection`/
    `CoordinatorAssignmentSection` omit the roles-legend block that
    `ProctorAssignmentSection` has — there's no `role` sub-field on either
    assignment table (Phase 5 confirmed), so that section has no
    equivalent here.
  - Wired `LecturerAssignmentSection` into `ClassDetailView` (below the
    existing roster table) and `CoordinatorAssignmentSection` into
    `ProgramDetailView` (below the existing `ClassesSection`) — both
    existing detail views from Phases 7/8, no new routes required.

## Risks

- None beyond what's already flagged in Phase 5 (no server-side role-match
  validation) — this phase is the FE-side mitigation for that, so the risk
  is closed here, not deferred further.
