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

- [ ] Creating a session for a Program with N students across multiple
      Classes results in exactly N enrollments (no duplicates, no misses)
      — verified against `GET /sessions/{id}/enrollments` after the flow
      completes.
- [ ] A student who already has an account but is in a different Program
      is correctly excluded from the roster (only this Program's students
      are enrolled).
- [ ] If the enroll step fails after the session was already created, the
      Host sees a clear retry path (re-run bulk-enroll against the
      already-created session, not create a duplicate session).
- [ ] `pnpm --filter tenant-web lint`/`build` clean.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after
  implementing this phase).
- Testing: not started.

## Risks

- No capacity awareness yet in this phase — a Program with more students
  than any sane single exam room could hold is enrolled into one session
  regardless. Phase 11 is where this gets addressed; not silently ignored,
  just sequenced next.
