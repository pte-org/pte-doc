# Phase 5: tenant-web — Proctor Management UI

## Requirements

Host can create Proctor accounts and assign/unassign them to a specific
Exam Session — this is the entirety of "Host chỉnh sửa quyền của Giám thị"
per Decision #4. Wires Phase 0's profile-extended `POST /users` (role
`PROCTOR`) and Phase 2's completed `ProctorAssignment` CRUD to a new UI
section on the session detail page.

Maps to: `plan.md` Decision #4; Research Summary items 1, 2.

## Design Constraints

- **No new backend work** — everything this phase needs already exists as
  of Phase 0 (role already assignable) and Phase 2 (list/assign/unassign).
- **Two related but distinct actions, don't conflate them**: "create a
  Proctor account" (a tenant-wide identity, via `POST /users`,
  `roles: ["PROCTOR"]` — a Proctor can exist without being assigned to
  anything yet) vs. "assign an existing Proctor to this session" (via
  `POST /sessions/{id}/proctors`). A Host managing a session should be
  able to do the latter against an already-existing Proctor (picked from
  a list) without recreating the account, and also be able to create a
  brand-new one inline if none fits — same "create OR pick existing"
  pattern Phase 4's session picker doesn't need but this one does, since
  Proctors are commonly reused across many sessions (unlike students, who
  in this plan's flow are created per-import-batch).
- **List of assignable Proctors**: `GET /users` (the same
  caller-tenant-scoped endpoint Phase 4's `LearnersOverview` rewrite uses
  — **not** `GET /users/by-tenant/{tenantId}`, which is `PLATFORM_ADMIN`-only
  and would 403 for the `HOST_ADMIN` caller this section is built for;
  caught by this plan's own red-team pass before implementation) filtered
  client-side to `roles.includes("PROCTOR")` — no new backend query
  needed; reuse the existing request function, don't add a role-filtering
  query param to an endpoint that doesn't need one for this scale.
- **This section lives on the session detail page's "Proctors"
  placeholder** (from Phase 3), same "scoped to its owning entity"
  reasoning as Phase 4's Students section — not a standalone top-level
  page.
- Query keys for the new hooks follow the established named-constant
  convention (`PROCTOR_ASSIGNMENTS_QUERY_KEY` etc. in
  `features/exams/constants/index.ts` — same file Phase 3 created, this
  phase adds to it rather than starting a second constants file for the
  same feature folder).

## Steps

1. `packages/api-client/src/requests/scheduling/proctorAssignments.ts`
   (new) — `assignProctor`, `listProctorAssignments`, `unassignProctor`,
   under `/api/scheduling/sessions/{id}/proctors...`.
2. `apps/tenant-web/features/exams/types/index.ts` — add
   `ProctorAssignment`/`AssignProctorInput` types.
3. `apps/tenant-web/features/exams/constants/index.ts` — add
   `PROCTOR_ASSIGNMENTS_QUERY_KEY`, UI text constants.
4. `apps/tenant-web/features/exams/api/index.ts` — add
   `useProctorAssignments(sessionPublicId)`, `useAssignProctor`,
   `useUnassignProctor`, `useCreateProctorAccount` (thin wrapper over the
   existing `createUser` request with `roles: ["PROCTOR"]` fixed, mirroring
   how `vendor-web`'s `useCreateLoginAccount` hardcodes its role today).
5. `apps/tenant-web/features/exams/components/`:
   `ProctorAssignmentSection.tsx` (list of assigned proctors +
   assign/unassign actions), `AssignProctorModal.tsx` (pick-existing OR
   create-new, key-based remount convention).
6. `SessionDetailView.tsx` — fill in the "Proctors" placeholder section
   with `ProctorAssignmentSection`.
7. `components/index.ts` — export the new components.

## Success Criteria

- [ ] From a session's detail page, creating a new Proctor account and
      assigning them to the session in one flow works end to end; the
      created account authenticates via `POST /auth/login`.
- [ ] Assigning an already-existing Proctor (created earlier, for a
      different session) to this session works without recreating the
      account.
- [ ] Unassigning removes them from the list; re-assigning afterward
      succeeds (no leftover conflict).
- [ ] `tsc --noEmit`, `eslint`, and `next build` clean for `tenant-web` and
      `@pte/api-client`.

## Quality and Testing State

- Not started.
