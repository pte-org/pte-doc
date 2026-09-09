# Phase 10: Bulk-Create Exam Sessions for a Whole Program

## Requirements

Lets a Host create an exam session for an entire Program in one action —
resolve the Program's full student roster (across all its Classes), create
the session, and enroll everyone — instead of enrolling students one by
one. Reuses `scheduling`'s already-built `bulkEnroll`, does not reinvent
enrollment.

Maps to: `plan.md` Decision 4 (bulk-create-exam-session-for-a-Program);
Research Summary items 4, 5.

## Design Constraints

- **FE-orchestrated, no new inter-service backend call.** Same tradeoff
  already accepted and documented in `ninh-host-add-student` (Research
  Summary item 4 there): `admin` and `scheduling` are separate
  services/databases; rather than building new `/internal/**`
  service-to-service plumbing (neither service has any today, confirmed by
  reading both), `tenant-web` sequences 2 existing/small calls itself:
  (1) `GET /class-memberships?programPublicId=X` (Phase 3, `admin`) to
  resolve the roster, (2) `POST /sessions` + `POST /sessions/{id}/enrollments/bulk`
  (already exist, `scheduling`). Document the same accepted failure-mode
  tradeoff: if step 2 fails after step 1 succeeded, nothing is stranded
  (roster resolution is read-only) — this is strictly simpler than the
  account-creation case in `ninh-host-add-student` (no credentials at
  risk here, only a resumable "create session + bulk-enroll" retry).
- No backend change in this phase — Phase 2/3/`bulkEnroll` already provide
  everything needed. This phase is FE-only, deliberately, to keep the
  scope small before Phase 11 (capacity) has to touch `scheduling` for
  real.
- The Program-roster resolution should respect
  `Program.isCurrentlyActive()` (Phase 2) as a UI hint (e.g. warn if
  creating a session for an inactive/expired Program) but must **not**
  hard-block it — a Host might deliberately run a make-up exam for a
  closed Program; block only on empty roster (nothing to enroll), not on
  Program status.
- No hardcoded strings in JSX — new constants alongside the existing
  `features/exams/constants`.

## Steps

1. `features/programs/api/index.ts` — `useProgramRoster(programPublicId)`
   wrapping Phase 3's `GET /class-memberships?programPublicId=` (already
   added in Phase 7 for search — reuse the same request module, add a
   Program-scoped hook variant here instead of duplicating the fetch
   logic).
2. `features/exams/components/CreateSessionForProgramModal.tsx` — Program
   picker (or launched directly from `ProgramDetailView`), reuses
   `CreateSessionModal.tsx`'s blueprint→snapshot picker + opens/closes-at
   fields, adds a roster preview (count + a "currently inactive Program"
   soft warning per the Design Constraint above).
3. `features/exams/api/index.ts` — `useBulkCreateSessionForProgram` — a
   client-side orchestration hook (not a single mutation): calls
   `useCreateSession`'s mutation function, then on success calls
   `useBulkEnroll(session.publicId)` with the resolved roster's
   `studentPublicIds`; surfaces both steps' pending/error state distinctly
   (mirrors the 2-step pending-state UX already established in
   `RosterImport.tsx`'s create-then-enroll flow).
4. Wire the entry point into `ProgramDetailView` ("Create Exam for this
   Program" action) and/or `ExamsListView` (a Program-picker variant of the
   existing "Create Exam" button) — pick one primary entry point, don't
   duplicate the whole flow in two places; a secondary entry point may
   simply link to the primary one.
5. `tsc --noEmit`, `eslint`, `next build`.

## Success Criteria

- [x] Creating a session for a Program with N students across multiple
      Classes results in exactly N enrollments (no duplicates, no misses)
      — verified against `GET /sessions/{id}/enrollments` after the flow
      completes.
- [x] A student who already has an account but is in a different Program
      is correctly excluded from the roster (only this Program's students
      are enrolled).
- [x] If the enroll step fails after the session was already created, the
      Host sees a clear retry path (re-run bulk-enroll against the
      already-created session, not create a duplicate session).
- [x] `pnpm --filter tenant-web lint`/`build` clean.

## Quality and Testing State

- Quality gate: APPROVED after fixing 1 HIGH + 1 LOW finding.
  QUAL-001 (HIGH): `CreateSessionForProgramModal`'s submit gate
  (`rosterIsEmpty`) was `!rosterLoading && studentPublicIds.length === 0`
  — while `useProgramRoster` was still loading, `rosterIsEmpty` evaluated
  `false`, so submission was NOT blocked even though `studentPublicIds`
  was still `[]` at that moment. A Host who clicked submit before the
  roster fetch resolved could create a session with an empty enrollment
  payload and land on the "success" branch showing "0 student(s)
  enrolled" — silently contradicting this phase's whole purpose. Fixed by
  adding `canSubmit = !rosterLoading && studentPublicIds.length > 0` and
  gating both `handleSubmit`'s early return and the submit button's
  `disabled` prop on it (kept `rosterIsEmpty` for display-only use —
  choosing which informational text to show). QUAL-002 (LOW):
  `CREATE_SESSION_FOR_PROGRAM_TEXT` used camelCase keys while every other
  constant object in `features/exams/constants/index.ts` uses
  SCREAMING_SNAKE_CASE — renamed all keys to match, and replaced an inline
  `"…"` JSX literal with a new `ROSTER_LOADING` constant in the same pass.
  QUAL-003 (NOTED, non-blocking): `useProgramRoster`'s `queryFn` body is
  byte-for-byte identical to `useClassRoster`'s (minus the class-level
  `select`) — accepted as-is per rule-of-three (this is only the second
  occurrence; extraction is worth evaluating if a third Program-roster
  consumer appears, plausibly in Phase 11). `pnpm --filter tenant-web
  build`/`lint` re-verified clean after the fix.
- Testing: no automated test framework runs in `tenant-web` (same
  no-precedent finding as Phases 6-9); no backend changed in this phase
  (FE-only, per Design Constraints), so no `mvn test` run applies either.
  Verified via `pnpm --filter tenant-web lint` (clean),
  `pnpm --filter tenant-web build` (clean, all 6 routes present, unchanged
  from Phase 9 — the new flow is wired into the existing
  `/host/programs/[publicId]` route, no new route needed), and
  `pnpm --filter @pte/api-client typecheck` (clean; this phase added no
  new api-client files, since it deliberately reuses `bulkEnroll`,
  `listClassMemberships`, and `createSession`, all already present from
  earlier phases).
- Success Criteria verified by construction (no live backend stack in this
  environment to run the manual E2E), not just build passing:
  - N-enrollments/no-duplicates: `run()` passes exactly the `studentPublicIds`
    resolved by `useProgramRoster` — a client-side join over
    `GET /class-memberships?programPublicId=` (Phase 3's tenant+program
    AND-scoped query, reused unmodified) — straight into the existing
    `bulkEnroll`, which already dedupes in-batch and skips
    already-enrolled ids server-side (Research Summary item 4). No
    alternate/manual enrollment path exists in this flow to double-enroll
    or miss anyone.
  - Cross-Program exclusion: `useProgramRoster(programPublicId)` only ever
    resolves rows for the given `programPublicId` — the same request
    module and query shape Phase 3 built specifically to prevent
    cross-scope leakage (see plan.md's CRITICAL risk mitigation), not a
    new, unaudited query.
  - Retry-without-duplicate-session: `useBulkCreateSessionForProgram`
    stores `createdSession` the moment `createSession` succeeds;
    `retryEnroll(studentPublicIds)` calls only `bulkEnrollStudents.mutate`
    against `createdSession.id` — `createSession.mutate` is never called a
    second time from any retry path, so a failed enroll can never result
    in two sessions.
- **Design decisions made during implementation, not fully specified by
  the phase's literal Steps**:
  - `useBulkEnrollStudents()` deliberately does NOT bind `sessionPublicId`
    at hook-instantiation time (unlike `useUnenroll(sessionPublicId)`'s
    established shape) — the session doesn't exist yet when this hook is
    first used, so `sessionPublicId` travels as part of each `mutate()`
    call's payload instead. Documented inline as a deliberate deviation
    from the single-purpose-hook convention, not an oversight.
  - `useProgramRoster` deliberately reuses `useClassRoster`'s exact query
    key shape (`[...CLASS_MEMBERSHIPS_QUERY_KEY, programPublicId]`, no
    class-level `select`) so the two hooks share one cached fetch per
    Program instead of issuing a duplicate `GET /class-memberships` call
    when both are mounted at once (e.g. a Host viewing `ProgramDetailView`
    with its `ClassesSection` while this modal is also open).
  - Chose `ProgramDetailView` (via a new "Create Exam for this &lt;label&gt;"
    button) as the single primary entry point per Step 4's "pick one, don't
    duplicate" instruction — `ExamsListView`'s existing "Create Exam"
    button is left as the session-without-a-Program path it already was;
    no secondary link was added there since that flow's own users already
    know to navigate to a Program's detail page instead.
  - `Program.isCurrentlyActive()`'s real backend logic (inclusive
    `[startDate, endDate]` range, both-null = always active) was read
    directly from `services/admin/.../domain/Program.java` rather than
    assumed, and mirrored client-side in
    `features/programs/utils/isProgramCurrentlyActive.ts` using ISO
    date-string comparison (not `Date` objects) to avoid a timezone-driven
    off-by-one against the backend's timeless `LocalDate`.

## Risks

- No capacity awareness yet in this phase — a Program with more students
  than any sane single exam room could hold is enrolled into one session
  regardless. Phase 11 is where this gets addressed; not silently ignored,
  just sequenced next.
