# Phase 4: tenant-web — Student Roster (Excel Import + Add Individually)

## Requirements

Wire the existing (dead) Excel-upload UI and add a new "add one person"
form to the real backend built in Phase 0 (`iam` bulk/single create) +
Phase 1 (`scheduling` bulk/single enroll), attached to a session picked via
Phase 3's UI. Delete the fictitious `/api/v1/host/**` code this replaces.

Maps to: `plan.md` Decisions #1, #2, #3; Research Summary items 3, 4.

## Design Constraints

- **Reuse, don't rewrite, the working parts.** `cleanRosterFile.ts` (xlsx
  parsing: strip empty columns/rows, dedupe headers) and
  `_RosterDropzone.tsx` (drag/drop `.xlsx` input) are real, functional,
  backend-agnostic — keep them. Only the request/response shape they feed
  into changes (from the fictitious `PrepareImportRequest`/
  `RosterImportResponse` to Phase 0's real `BulkCreateUsersRequest`/
  `BulkCreateUsersResponse`).
- **Two-step orchestration, surfaced to the user, not hidden** (per
  `plan.md`'s accepted MEDIUM risk): step 1 calls `POST /users/bulk`
  (Phase 0) with rows parsed from the Excel file, scoped to the session's
  tenant; step 2, on success, calls `POST /sessions/{id}/enrollments/bulk`
  (Phase 1) with the returned `publicId`s. If step 2 fails, the UI must
  say "accounts created but not yet enrolled — retry enrolling" (not a
  generic error), and offer a retry button that re-calls just step 2 with
  the already-known publicIds (don't re-run step 1 and risk duplicate
  accounts).
- **Credentials must be downloadable/persisted the instant step 1 returns,
  never gated on step 2 (HIGH finding from this plan's own red-team
  review, fixed here rather than left as the original MEDIUM-risk
  framing).** `Phase 0`'s `generatedPassword` is write/return-once —
  `POST /users/bulk`'s response is the ONLY place it ever exists in
  retrievable form; if the UI waits until step 2 (bulk-enroll) also
  succeeds before offering the credentials download, an abandoned tab,
  browser crash, or step-2 failure the Host doesn't immediately retry to
  completion permanently strands those passwords — not recoverable by any
  admin action, since `POST /users/{publicId}/reset-password` requires a
  NEW password to be set, it can't reveal the old generated one. Fix,
  concretely: (1) immediately on step 1's response, persist
  `{publicId, email, generatedPassword}[]` to `sessionStorage` (cleared
  only once step 2 confirms success, or once the Host explicitly
  downloads and dismisses); (2) offer the `student-credentials.xlsx`
  download right after step 1 returns, independent of step 2's outcome —
  the download button is not disabled/hidden while step 2 is pending or
  retrying; (3) if the page is reloaded/reopened with an unresolved
  `sessionStorage` entry (step 1 succeeded, step 2 never confirmed), show
  a banner offering both "re-download credentials" and "retry enrolling"
  from that persisted list, rather than losing the state.
- **Delete the fictitious modules outright**, don't leave them as dead
  code alongside the new ones: `packages/api-client/src/requests/host/{imports,studentImport,students}.ts`
  + their barrel export in `requests/host/index.ts` and
  `requests/index.ts`; `packages/api-client/src/types/host/{import,student}.ts`
  + their barrel exports. Grep first to confirm nothing else references
  them (expected: nothing, per Research Summary item 3 — only
  `examoperations/api.ts` and the dead `_ExamAssignment.tsx` do).
- **`_ExamAssignment.tsx`**: repurpose into the "which session am I
  importing into" step (a session picker, reusing Phase 3's
  `useSessions()`) rather than writing a new component from scratch — read
  it first to see how much of its existing shape survives; rename away the
  leading `_` once it's wired into `components/index.ts`.
  **`_ValidationReport.tsx`**: repurpose into rendering Phase 0's
  `BulkCreateUsersResponse.skipped` (per-row conflict list) — same
  reasoning.
- **`LearnersOverview.tsx`**: rewrite to call `GET /users` (iam,
  `UserController.list()` → `UserService.listByTenant(caller)`, already
  exists, class-level `hasAnyRole('PLATFORM_ADMIN','HOST_ADMIN')`,
  tenant-scoped via the caller's own JWT — **not**
  `GET /users/by-tenant/{tenantId}`, which is `PLATFORM_ADMIN`-only and
  used by `vendor-web`'s login-account feature for exactly that reason;
  using it here would 403 for every real `HOST_ADMIN` caller — caught by
  this plan's own red-team pass before implementation; add a new request
  function for `GET /users` to `packages/api-client/src/requests/user/index.ts`
  if one doesn't already exist there) filtered/joined against the
  session-scoped enrollment
  list from Phase 1's `GET /sessions/{id}/enrollments` when viewed from a
  session's detail page, or shown as an all-students-in-tenant view when
  viewed from the standalone `/host/dashboard` overview — table columns
  become the real fields: email, fullName, studentCode, className, phone,
  status (all now real, from Phase 0's `UserResponse` extension — the
  fictitious numeric `id` and `username` fields this component used before
  are gone). Each row gets a "Reset Password" action (mirrors
  `vendor-web`'s `TenantDetailView` reset-password button precedent
  exactly — same `ResetPasswordModal` shape, admin sets a new password
  directly, no email) calling Phase 0's now-widened
  `POST /users/{publicId}/reset-password`; only rendered for rows whose
  `roles` is `STUDENT`/`PROCTOR` (matches Phase 0's server-side
  restriction — don't show a button for a target role the backend will
  403 on anyway).
- **"Add individually" is new, small**: a form (email, fullName,
  studentCode, className, phone, dateOfBirth) that calls the existing
  single `POST /users` (Phase 0-extended) with `roles: ["STUDENT"]`, then
  `POST /sessions/{id}/enrollments` (Phase 1, single, already existed) —
  no new backend endpoint needed for this path at all, confirmed in
  `plan.md`'s Research Summary.
- Both the Excel-import flow and the add-individually form live on the
  session detail page's "Students" section (the placeholder Phase 3 left),
  not as a separate top-level nav item — keeps "which exam am I adding to"
  unambiguous by construction (matches this repo's established pattern of
  keeping an action visibly scoped to its owning entity, same reasoning as
  keeping "Create Login" inside `TenantDetailView` rather than a
  standalone page in the earlier `ninh-host-account-management` plan).
  `/host/roster` becomes a thin redirect/entry point into "pick a session"
  if reached directly (e.g. from the existing nav item), rather than a
  second competing UI.

## Steps

1. Delete: `packages/api-client/src/requests/host/{imports,studentImport,students}.ts`,
   `packages/api-client/src/requests/host/index.ts`,
   `packages/api-client/src/types/host/{import,student}.ts` and their
   barrel entries in `requests/index.ts`/`types/index.ts`. Grep to confirm
   zero remaining references before deleting.
2. `packages/api-client/src/requests/user/index.ts` — extend with
   `bulkCreateUsers` (Phase 0's `POST /users/bulk`) alongside the existing
   `createUser`/`listUsersByTenant`/`resetPassword` (already added by the
   earlier `ninh-host-account-management` plan — `resetPassword`'s
   frontend call site doesn't change in this phase, only which caller
   roles the backend now accepts, per Phase 0). New
   `packages/api-client/src/requests/scheduling/enrollments.ts` — `bulkEnroll`,
   `enrollStudent` (single), `listEnrollments`, `unenroll`, under
   `/api/scheduling/sessions/{id}/enrollments...`.
3. `apps/tenant-web/features/examoperations/types.ts` — replace
   `RosterValidationRow`/`ExamOption` with real types built on Phase 0/1's
   response shapes; delete the numeric-`id`-based `HostStudentResponse`
   usage entirely (now imports `UserResponse` from `@pte/api-client`).
4. `apps/tenant-web/features/examoperations/api.ts` — rewrite
   `useParseRosterImport`/`useConfirmRosterImport` into the two-step
   orchestration described in Design Constraints (a single
   `useImportRoster()` hook that runs both calls and exposes which step
   failed, if any); `useHostStudents` → rewritten to call
   `listUsersByTenant`/`listEnrollments` as appropriate.
5. `components/RosterImport.tsx` — update to the new hook's
   success/partial-failure/error states (three distinct UI states now,
   not two).
6. `components/_ExamAssignment.tsx` → rename to `SessionPicker.tsx`,
   wire into `RosterImport.tsx` as the first step, using Phase 3's
   `useSessions()`.
7. `components/_ValidationReport.tsx` → rename to `SkippedRowsReport.tsx`,
   renders `BulkCreateUsersResponse.skipped`.
8. New `components/AddStudentForm.tsx` — the single-add form described in
   Design Constraints.
9. `components/LearnersOverview.tsx` — rewrite columns/data-source per
   Design Constraints; add the per-row "Reset Password" action (new
   `ResetPasswordModal` reuse or a `tenant-web`-local copy of
   `vendor-web`'s — check whether it's worth promoting to `@pte/ui` at
   this point, since it would now be used by two apps, versus keeping two
   copies; decide based on how much tenant-specific text/copy it needs).
10. `SessionDetailView.tsx` (from Phase 3) — fill in the "Students"
    placeholder section with `RosterImport` (or a link into it) +
    `AddStudentForm` + the roster list.
11. `components/index.ts` — update exports (remove the `_`-prefixed dead
    names, add the renamed/new ones).
12. `apps/tenant-web/app/(dashboard)/host/roster/page.tsx` — becomes the
    "pick a session to manage its roster" entry point (redirects to
    `/host/exams` if that's simpler than duplicating a picker here — check
    against Phase 3's actual list page before deciding).

## Success Criteria

- [ ] Uploading a valid `.xlsx` roster creates real `STUDENT` accounts
      (verify via `POST /auth/login` with one generated password) AND
      enrolls them in the chosen session; a downloaded credentials file
      matches the created accounts.
- [ ] A roster row whose email already exists is skipped (reported, not
      silently dropped, not blocking the rest of the batch).
- [ ] "Add individually" creates one account + enrollment without touching
      the Excel path at all.
- [ ] Simulating step-2 failure (e.g. temporarily point the enroll call at
      a bad session id) shows the "accounts created, retry enrolling"
      state, and the retry button succeeds without creating duplicate
      accounts.
- [ ] The credentials file is downloadable immediately after step 1
      succeeds, even while step 2 is still pending/failing/retrying —
      verify by simulating step-2 failure and confirming the download
      button is available and produces the correct file before ever
      retrying step 2.
- [ ] Reloading the page mid-way (step 1 succeeded, step 2 not yet
      confirmed) shows the recovery banner with both re-download and
      retry-enrolling actions, sourced from `sessionStorage`, not lost.
- [ ] Grep confirms zero remaining references to the deleted
      `host/{imports,studentImport,students}` modules anywhere in the repo.
- [ ] From the roster list, "Reset Password" on a Student row succeeds and
      the student can log in with the new password, the old one no longer
      working; the same action is not offered/succeeds-403 for a
      `HOST_ADMIN`/`HOST_AUTHOR` row (matches Phase 0's server-side
      restriction).
- [ ] `tsc --noEmit`, `eslint`, and `next build` clean for `tenant-web` and
      `@pte/api-client`.

## Quality and Testing State

- Not started.
