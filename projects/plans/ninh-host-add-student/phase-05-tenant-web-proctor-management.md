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

## Implementation Deviations

- **`useCreateProctorAccount` uses single `POST /users` with a
  Host-supplied password**, not the bulk endpoint Phase 4's
  `useAddStudent` deviated to. Reasoning is the opposite of Phase 4's:
  `bulkCreateUsers` is hardcoded STUDENT-only by design (Phase 0's own
  Design Constraint explicitly rules out a generic multi-role bulk
  endpoint), so it cannot be reused for PROCTOR at all — and unlike the
  Excel-import path (many accounts, no per-account password input
  available), this is a one-at-a-time form where the existing
  "admin sets a password directly" pattern (mirroring vendor-web's
  `useCreateLoginAccount`) already fits with no format-duplication concern.
- **`AssignProctorModal` is one component with an internal tab switch**
  (`"existing" | "new"`), not two separate flows — picking an existing
  proctor and creating-then-assigning a new one share the same modal
  chrome/footer, differing only in the form body. When "Create New" is
  submitted, `useCreateProctorAccount` and `useAssignProctor` are chained
  directly in the submit handler (create, then assign with the returned
  publicId) rather than via a combined hook — same reasoning as Phase 4's
  `useCreateRosterAccounts`/`useEnrollRosterAccounts` split.
- **`useTenantProctors` and examoperations' `useTenantStudents` share the
  same `TENANT_USERS_QUERY_KEY` cache entry** — both call the identical
  `GET /users`, differing only in which role they filter to client-side.
  **Correction (this bullet originally claimed the two hooks "aren't
  mounted at once" — that was wrong, and the resulting design was a real
  bug caught by this phase's own quality gate, HIGH severity — see Quality
  and Testing State below.)** `StudentRosterTable` and
  `ProctorAssignmentSection` genuinely co-mount on every session detail
  page. The fix: both hooks now share the identical `queryKey` **and**
  identical `queryFn` (the raw, unfiltered `listUsers` call), applying
  their STUDENT/PROCTOR split via react-query's `select` option instead of
  via two different `queryFn` bodies under one key — `select` is what
  actually makes "same cached data, different per-observer view" safe;
  two different `queryFn`s racing under one key is not.

## Success Criteria

- [ ] From a session's detail page, creating a new Proctor account and
      assigning them to the session in one flow works end to end; the
      created account authenticates via `POST /auth/login`.
- [ ] Assigning an already-existing Proctor (created earlier, for a
      different session) to this session works without recreating the
      account.
- [ ] Unassigning removes them from the list; re-assigning afterward
      succeeds (no leftover conflict).
- [x] `tsc --noEmit`, `eslint`, and `next build` clean for `tenant-web` and
      `@pte/api-client`.

## Quality and Testing State

- Frontend: `tsc --noEmit`/`eslint`/`next build` all clean for `tenant-web`,
  `@pte/api-client`, and `@pte/ui`.
- Quality gate (`ck:quality`, `quality-reviewer` agent, scoped to this
  phase's files): first pass found 1 HIGH, 2 MEDIUM, 1 NOTED, 0 BLOCKER —
  fixed:
  - HIGH (real query-cache collision, not just a theoretical one — this
    phase's own Implementation Deviations note had incorrectly asserted
    `useTenantProctors`/`useTenantStudents` "aren't mounted at once,"
    which the reviewer disproved directly against `SessionDetailView.tsx`:
    `StudentRosterTable` and `ProctorAssignmentSection` genuinely co-mount
    on every session detail page load. Both hooks shared one `queryKey`
    with two DIFFERENT `queryFn` bodies — react-query keys a cache entry
    by `queryKey` alone, so whichever query resolved first silently
    populated the shared entry for BOTH observers, meaning the Proctors
    section could end up backed by STUDENT records with no backend guard
    rejecting it (`EnrollmentService.assignProctor` performs no
    server-side role check on `proctorPublicId`, confirmed by the
    reviewer against the real Phase 2 code)): fixed by keeping the
    `queryKey` genuinely shared (correct, avoids a duplicate network
    call) but moving the STUDENT/PROCTOR split into react-query's
    `select` option instead of two different `queryFn` bodies — the
    correct mechanism for "same underlying data, different per-observer
    view."
  - MEDIUM (stale error shown across tab switches in
    `AssignProctorModal` — `assignProctor`/`createProctor` are two
    independent mutations whose errors were never reset when switching
    tabs): fixed with a `handleTabChange` that calls `.reset()` on both
    mutations before switching.
  - MEDIUM (undocumented partial-failure branch: `createProctor` succeeds
    but the chained `assignProctor` fails, leaving the account created
    but not assigned, with the form still showing the same email — a
    plain retry would hit an email-conflict instead of the real problem):
    fixed by routing the Host to the "Pick Existing" tab, pre-selected on
    the just-created proctor, when this specific failure occurs — so
    resubmitting assigns the existing account instead of re-attempting
    creation.
  - NOTED (second occurrence of Phase 4's client-side join pattern,
    `useProctorAssignments` vs `useSessionRoster`): not extracted — per
    this contract's own rule-of-three convention, a second occurrence is
    tracked, not yet refactored; noted for whenever a third similar hook
    appears.
  Re-verified: `tsc`/`eslint`/`next build` all clean after fixes —
  APPROVED.
- Manual E2E (create+assign new proctor; assign existing proctor to a
  second session; unassign then re-assign; verify Students/Proctors
  sections both load correctly with the right role's data on the same
  page): not yet run — deferred to the user running the stack.
