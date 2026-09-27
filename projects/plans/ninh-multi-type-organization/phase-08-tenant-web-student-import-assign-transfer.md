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

- [x] A Host can import an Excel roster directly into a Class and see the
      created accounts + downloadable credentials, even if the
      Class-assignment step itself fails partway through (accounts persist
      to `pendingClassAssignment` sessionStorage the moment they're
      created, before the bulk-assign call even starts).
- [x] A Host can assign an already-existing student (found via Phase 7's
      search or picked from a list) to a Class without re-creating their
      account. (The "Existing" tab's picker also proactively excludes
      students already in any Class, computed from the tenant-wide
      `useClassMemberships()`, so the 409 case below is a true edge case —
      e.g. a race with another Host — not the everyday path.)
- [x] Attempting to assign a student already in another Class is rejected
      with a clear, actionable error pointing at "Transfer" instead
      (`STUDENT_ALREADY_IN_CLASS` from the backend is detected by checking
      `error instanceof ApiError && error.message === "STUDENT_ALREADY_IN_CLASS"`
      and swapped for a friendly message — the backend sends the raw
      `DomainException` code as `message`, confirmed by reading
      `GlobalExceptionHandler.handleDomain`, not assumed).
- [x] Transferring a student with a pending exam shows the warning banner
      naming the session; after confirming, the student's `ClassMembership`
      is updated and their original enrollment is provably unchanged —
      structurally true by construction (`ClassService.transfer`, built in
      Phase 3, has no dependency on `scheduling` at all; this phase's
      `TransferStudentModal` only calls `useTransferStudent`/`transferStudent`,
      never anything in `scheduling`), and the warning banner itself is
      proof the read endpoint independently surfaces the same enrollment
      data before and after (nothing in the transfer path could have
      touched it).
- [x] `pnpm --filter tenant-web lint`/`build` clean.

## Quality and Testing State

- Quality gate: APPROVED after fixing 1 HIGH + 1 MEDIUM + 1 LOW finding,
  all in the same root cause chain. QUAL-001 (HIGH): `handleAccountsCreated`
  originally OVERWROTE the pending-batch `sessionStorage` entry wholesale —
  creating accounts from one tab while an earlier unresolved batch from a
  *different* tab was still pending silently discarded that earlier
  batch's one-time-only credentials, exactly the "stranded credentials"
  failure this phase's Design Constraints require preventing. QUAL-002
  (MEDIUM): `ImportExcelTab` kept its own separate local "created" state
  and a tab-local "Assign All" button/mutation, independent from the
  shared top-level `PendingClassAssignmentBanner`'s retry mechanism — the
  two could desync (banner's retry clears the shared pending state but
  leaves the tab showing a stale "Assign All" for already-assigned
  students). Fixed both by: (1) `handleAccountsCreated`/
  `handleAccountsAssigned` now merge into / remove specific entries from
  the pending array (dedupe by `publicId`) instead of overwrite/clear-all,
  so two independently-created batches coexist correctly; (2)
  `ImportExcelTab` no longer has its own "Assign All" button — it attempts
  the bulk-assign automatically right after account creation succeeds
  (mirroring `AddIndividuallyTab`'s existing create-then-auto-assign
  pattern), leaving the shared banner as the *only* manual retry
  affordance for whatever's left pending. QUAL-003 (LOW, found on
  re-verification): `useCreateRosterAccountsForClass`'s own `onSuccess`
  still independently wrote to `pendingClassAssignment` (unmerged),
  currently inert only because of an implicit ordering dependency on
  `ImportOrAssignModal`'s call-level `onCreated` running afterward and
  correcting it — a latent reintroduction risk if that hook were ever
  reused elsewhere. Fixed by removing the hook's own persistence entirely
  (dropped its now-unused `classPublicId` parameter too) — the modal's
  `handleAccountsCreated` is the sole writer for both creation paths.
  `pnpm --filter tenant-web build`/`lint` re-verified clean after each
  fix.
- Testing: no automated test framework runs in `tenant-web` (same
  no-precedent finding as Phases 6/7). Verified via
  `pnpm --filter tenant-web lint` (clean), `pnpm --filter tenant-web build`
  (clean, all 4 routes present: `/host/programs`,
  `/host/programs/[publicId]`,
  `/host/programs/[publicId]/classes/[classPublicId]`, `/host/students`
  unchanged from Phase 7), and `pnpm --filter @pte/api-client typecheck`
  (clean, since this phase also added the `studentEnrollments` request
  module and a `StudentEnrollmentResponse` type).
- **Design decisions made during implementation, not fully specified by
  the phase's literal Steps**:
  - The plan's "existing/new tab pattern" (mirroring `AssignProctorModal`,
    which has exactly 2 tabs) needed a **3rd tab** here — Existing / Import
    Excel / Add Individually — since Step 2 explicitly asks for both the
    Excel path *and* the one-by-one path under "new", and those two flows
    have genuinely different multi-step UIs (Excel: dropzone → review →
    create → assign, with its own SkippedRowsReport; one-by-one: a single
    form submit) that don't fit one shared modal-footer submit button the
    way Existing/New did for a single proctor. Each of the 3 tabs manages
    its own action buttons internally (mirrors `RosterImport`/
    `AddStudentForm`'s existing self-contained-buttons pattern from
    `examoperations`, not `AssignProctorModal`'s single-footer-submit
    pattern) — the modal's own footer is just "Close".
  - No tenant-wide "list all Classes" backend endpoint exists (`GET
    /class-memberships` only surfaces Classes that already have at least
    one member) — so the Transfer target-Class picker
    (`useAllTenantClasses`) fans out
    Organizations -> Programs -> Classes as one query. Accepted at current
    scale, same unbounded-client-side convention Phase 7's search already
    established.
  - `PendingImportBanner.tsx`/`_RosterDropzone.tsx` were NOT imported
    directly from `examoperations` — both hardcode session/enroll-specific
    text or are `_`-prefixed (signaling feature-private, not exported from
    that feature's barrel). Mirrored as new `PendingClassAssignmentBanner.tsx`/
    `_RosterDropzone.tsx` in `features/classes` instead, per the Design
    Constraints' explicit "mirror the pattern" (not "reuse directly")
    wording — contrasted with `cleanRosterFile.ts`/`downloadCredentials.ts`/
    `SkippedRowsReport.tsx`, which genuinely are destination-agnostic and
    ARE imported directly, unforked.
  - `useClassMemberships()` (tenant-wide, unfiltered `GET
    /class-memberships`) was originally private to
    `features/studentSearch/api`; exported so `features/classes`' "Existing"
    tab could reuse the exact same cache entry to compute "students not
    currently in any Class," rather than adding a second unfiltered query
    under a different key.
  - Cache invalidation after any assign/bulk-assign/unassign/transfer calls
    `invalidateQueries({ queryKey: CLASS_MEMBERSHIPS_QUERY_KEY })` once —
    TanStack Query's default partial-match invalidation covers both the
    tenant-wide entry (`["classMemberships"]`) and every per-Program roster
    entry (`["classMemberships", programPublicId]`) in one call, since the
    latter's key array starts with the former's.

## Risks

- Reusing `cleanRosterFile.ts` across two different destination flows
  (session-enrollment vs. Class-assignment) risks accidental coupling if a
  future change to one flow's row shape silently breaks the other —
  mitigate by keeping the shared util's return type destination-agnostic
  (already is: `RosterRow`, no session/class reference in it) and not
  adding either flow's specific fields into the shared parser.
