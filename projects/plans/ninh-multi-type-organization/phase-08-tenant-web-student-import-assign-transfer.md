# Phase 8: tenant-web — Student Import/Assign-to-Class + Transfer UI

## Requirements

Lets a Host import students (Excel or one-by-one) directly into a Class,
and transfer an already-assigned student to a different Class, with the
pending-exam-request warning from Phase 3 surfaced before confirming.

Maps to: `plan.md` Decision 1 (1-N), Decision 4 (import/assign, transfer);
Research Summary items 5, 10.

## Design Constraints

- **This is a related-but-different action from the existing
  `features/examoperations/RosterImport.tsx`** — that flow creates accounts
  and enrolls them into an *ExamSession*. This phase's flow creates/finds
  accounts and assigns them to a *Class* (Phase 3's `ClassMembership`).
  They are deliberately decoupled (Decision 1) — do not make this phase
  call `scheduling`'s enrollment endpoints, and do not make the existing
  roster-import flow call Class-assignment endpoints. Reuse
  `cleanRosterFile.ts`'s parsing utility directly (import it, don't fork
  it) since the Excel shape (email/fullName/studentCode/phone/dateOfBirth)
  is identical.
- Account creation still goes through iam's existing bulk-create
  (`POST /users/bulk`) — this phase does not add a new account-creation
  endpoint, only a new *destination* for already-created/existing accounts
  (Class assignment instead of session enrollment).
- **Assign-to-Class must offer "assign an existing student" as a first path**,
  not only "import new" — a student may already exist (created via the
  existing roster-import-into-a-session flow, or via the org-wide search
  from Phase 7) and just needs a `ClassMembership` row. Mirror
  `AssignProctorModal.tsx`'s existing/new tab pattern for this, rather than
  building only an Excel-first UI.
- Transfer flow: before submitting, call Phase 3's
  `GET /students/{studentPublicId}/enrollments`; if any enrollment has a
  future `opensAt` and status other than `CLOSED`, show a non-blocking
  warning banner (`Alert tone="warning"`, not an error) naming the
  session(s) — the Host can still confirm the transfer. After transfer,
  re-fetch the same endpoint in a regression-style manual check (Success
  Criteria below) to confirm nothing about the enrollment changed.
- Same credential-handling discipline as the existing roster-import flow:
  if creating a new account succeeds but assigning to a Class fails, the
  credentials must already be surfaced/downloadable (not stranded) —
  mirror `PendingImportBanner.tsx`'s pattern exactly (persist to
  `sessionStorage` keyed by the target Class, offer retry-assign).
- No hardcoded strings in JSX — new `constants.ts` entries in
  `features/classes/constants/`.

## Steps

1. `features/classes/api/index.ts` — add `useAssignStudent`,
   `useBulkAssignStudents`, `useUnassignStudent`, `useTransferStudent`,
   `useStudentEnrollments(studentPublicId)` (Phase 3's new `scheduling`
   endpoint — new request module `packages/api-client/src/requests/scheduling/studentEnrollments.ts`).
2. `features/classes/components/ImportOrAssignModal.tsx` — existing/new
   tabs (mirrors `AssignProctorModal.tsx`); "new" tab reuses
   `RosterDropzone`/`parseRosterFile` for the Excel path, plus a
   single-student form for the one-by-one path (mirrors
   `AddStudentForm.tsx` if its shape fits, otherwise a lean equivalent).
3. Pending-import resilience: `pendingClassAssignment.ts` (new, mirrors
   `examoperations`'s `loadPendingImport`/`clearPendingImport` +
   `downloadCredentials.ts` reuse) keyed by `classPublicId`.
4. `features/classes/components/TransferStudentModal.tsx` —
   target-Class picker (any Class in the tenant, per Phase 3's
   cross-Program-allowed design) + the pending-enrollment warning banner
   sourced from `useStudentEnrollments`.
5. Wire `ImportOrAssignModal`/`TransferStudentModal` into
   `ClassesSection`/a per-Class roster table (Phase 7's `ClassDetailView`
   or equivalent — add a Class detail page if Phase 7 only went one level
   deep to Program; check Phase 7's actual routes before assuming).
6. `tsc --noEmit`, `eslint`, `next build`.

## Success Criteria

- [ ] A Host can import an Excel roster directly into a Class and see the
      created accounts + downloadable credentials, even if the
      Class-assignment step itself fails partway through.
- [ ] A Host can assign an already-existing student (found via Phase 7's
      search or picked from a list) to a Class without re-creating their
      account.
- [ ] Attempting to assign a student already in another Class is rejected
      with a clear, actionable error pointing at "Transfer" instead.
- [ ] Transferring a student with a pending exam shows the warning banner
      naming the session; after confirming, the student's `ClassMembership`
      is updated and their original enrollment is provably unchanged
      (manually verified via `GET /students/{id}/enrollments` before/after).
- [ ] `pnpm --filter tenant-web lint`/`build` clean.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after
  implementing this phase).
- Testing: not started.

## Risks

- Reusing `cleanRosterFile.ts` across two different destination flows
  (session-enrollment vs. Class-assignment) risks accidental coupling if a
  future change to one flow's row shape silently breaks the other —
  mitigate by keeping the shared util's return type destination-agnostic
  (already is: `RosterRow`, no session/class reference in it) and not
  adding either flow's specific fields into the shared parser.
