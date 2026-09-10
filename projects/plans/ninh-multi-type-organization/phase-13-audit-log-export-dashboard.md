# Phase 13: admin + tenant-web — Audit Log + Excel Export + Program Dashboard

## Requirements

Closes out the plan with 3 smaller, read-oriented capabilities: an
append-only audit trail of who did what to Program/Class/membership/
assignment/merge-split, client-side Excel export of a Class roster
(reverse of the existing import), and a per-Program dashboard (class/
student counts). As the last phase in the plan, it also performs the
**final consolidated `@PreAuthorize` re-audit** that Phase 4 explicitly
deferred to here.

Maps to: `plan.md` Decision 4 (audit log, export, dashboard); Research
Summary items 10, 15; Phase 4's Design Constraints (deferred final audit).

## Design Constraints

- **Audit log is a genuine new ledger table, not derived from the outbox.**
  `admin`'s `OutboxEntry` rows are transport-only and get pruned daily by
  `AdminOutboxCleanupJob` (confirmed by reading it) — not a durable audit
  trail. Mirrors `QuotaTransaction`'s existing pattern instead: a dedicated
  `AuditLog` entity, written explicitly (`actorUserId` from
  `caller.userId()`, same as `QuotaTransactionService.grant()` already
  does) at each mutation site, in the same transaction as the entity
  change and the outbox write.
- **Scoped to `admin`'s own mutations only** (Research Summary item 15) —
  Program/Class/ClassMembership/LecturerAssignment/ProgramCoordinatorAssignment/
  merge-split, per Decision 4's "at minimum" phrasing. `scheduling`'s
  bulk-enrollment-for-Program events (Phases 10/11) are **not** surfaced
  here — `ExamSession` carries no `programPublicId` today, so there's no
  clean way to attribute a `StudentEnrolled` event back to the Program
  that triggered it without a new cross-service tag this plan doesn't
  otherwise need. Document this explicitly as an accepted scope limit in
  the audit log's own empty-state/help text, not silently.
- **Retrofit, not foundation-first** — per the plan's own explicit
  sequencing (audit log is "toward the end", not blocking earlier phases
  like the unrelated `mock-test-security-performance` plan's Track 4 Phase
  1 was). This means Phases 2/3/5/12's services get a new
  `auditLogService.record(...)` call added beside their existing
  `outboxWriter.write(...)` call — additive only, same transaction, and
  every touched service's **existing** test suite must still pass
  unmodified after the retrofit (a real regression-risk phase, called out
  in `plan.md` Risks as MEDIUM).
- Excel export is entirely client-side (`XLSX.utils.json_to_sheet` +
  `XLSX.writeFile`, same `xlsx` library as `cleanRosterFile.ts`) — no new
  backend endpoint, reuses the existing Class roster
  (`GET /class-memberships`) response.
- Dashboard is a single new backend aggregation endpoint
  (`GET .../programs/{id}/dashboard`) computed via a grouped `COUNT` query
  (class count, student count, per-Class breakdown) — not client-side
  aggregation over a potentially large membership list, and not N+1
  (one query, matching every other list-endpoint N+1 discipline already
  established in this plan).
- **Final consolidated `@PreAuthorize` re-audit (closes Phase 4's
  deliberately-deferred gap).** Phase 4's audit only covered the 26 files
  that existed at that point in the repo; every phase since (2, 3, 5, 12,
  and this phase's own new `AuditLogController`/dashboard endpoint) added
  new `@PreAuthorize`-bearing controllers that were never folded back into
  a "dedicated, complete" review — each self-certified inline in its own
  phase instead. This phase, being last, is where the full picture finally
  exists: re-run `grep -r "@PreAuthorize" services/*/src/main/java
  pte-common/src/main/java` across the **whole repo**, diff the result
  against Phase 4's original 26-file list, and for every file **not** in
  that original list (expected: `HostOrganizationController`,
  `ProgramController`, `ClassController`, `ClassMembershipController`,
  `StudentEnrollmentController`, `LecturerAssignmentController`,
  `ProgramCoordinatorAssignmentController`, plus this phase's own
  `AuditLogController` and the dashboard endpoint — confirm the actual
  final list against the real repo state, don't just assume this exact
  set) apply Phase 4's same classification method: (a) explicit
  `hasRole`/`hasAnyRole` allow-list, (b) any exclusion-style check, (c)
  anything unusual — and confirm each one's role-check is intentional and
  correctly scoped now that `LECTURER`/`PROGRAM_COORDINATOR` are live
  values in the system, not accidentally over- or under-permissive. This
  is a **distinct deliverable from the Program/Class audit-log feature
  work above** — do not conflate the two just because they land in the
  same phase file; call it out as its own explicit step and its own
  Success Criteria items.
- `ddl-auto: update` — no Flyway migration for the new `AuditLog` table.

## Steps

1. `services/admin`: `domain/AuditLog.java` (`actorUserId`, `tenantId`,
   `aggregateType`, `aggregateId`, `action`, `summary` — extends
   `BaseEntity`); `repository/AuditLogRepository.java`
   (`findByTenantIdOrderByCreatedAtDesc`, optionally filtered by
   `aggregateType`); `service/AuditLogService.java` — one `record(caller,
   aggregateType, aggregateId, action, summary)` method, `@Transactional`
   (joins whatever transaction is already open at the call site — verify
   Spring's default propagation is correct for this, don't assume).
2. Retrofit `record(...)` calls into: `ProgramService` (create/update/
   status-change/archive), `ClassService` (create/status-change/archive/
   assign/unassign/transfer/merge/split), `AssignmentService`
   (assign/unassign for both Lecturer and Coordinator) — one call per
   existing write method, beside the existing `outboxWriter.write(...)`
   call.
3. `controller/AuditLogController.java` (`GET /audit-logs`,
   `hasRole('HOST_ADMIN')`, tenant-scoped, optional `aggregateType` filter).
4. `service/ProgramService.java` (or a new small `DashboardService.java` if
   `ProgramService` is already large enough that this would violate this
   repo's method-budget convention — check its current size first) —
   `getDashboard(programPublicId, caller)`: one grouped query for
   class/student counts.
   `controller/ProgramController.java` — `GET .../programs/{id}/dashboard`.
5. Tests: `AuditLogServiceTest.java`; extend
   `ProgramServiceTest.java`/`ClassServiceTest.java`/`AssignmentServiceTest.java`
   with "writes an audit log row" assertions (regression tests for the
   retrofit, matching the precedent already established when
   `ninh-host-add-student` Phase 2 retrofitted an outbox write onto
   `assignProctor`); `DashboardServiceTest.java` (or wherever it lands).
6. `tenant-web`: `features/auditLog/` (new folder) — `AuditLogView.tsx`,
   list with actor/action/timestamp columns, filter by type; wired into a
   new `/host/audit-log` route + nav entry.
   `features/classes/exportClassRoster.ts` (mirrors `cleanRosterFile.ts`'s
   file location convention) — client-side `.xlsx` generation; an "Export"
   button on the Class roster view (Phase 7/8).
   `features/programs/components/ProgramDashboard.tsx` — wired into
   `ProgramDetailView`.
7. **Final consolidated `@PreAuthorize` audit** (see Design Constraints) —
   re-grep the whole repo, diff against Phase 4's original 26-file list,
   classify every new file, document the result inline in this phase's own
   Success Criteria (a new list/table, mirroring Phase 4's format exactly).
   Fix and document any file found with an unintended widening (same
   standard as Phase 4 — an exclusion-style check that would now
   unintentionally admit `LECTURER`/`PROGRAM_COORDINATOR`).
8. `tsc --noEmit`, `eslint`, `next build`; `mvn -pl services/admin test`
   (full suite — confirms the retrofit didn't break anything upstream).

## Success Criteria

- [x] Every Program/Class/membership/assignment/merge-split mutation made
      through this plan's UI produces a corresponding, correctly-attributed
      `AuditLog` row, visible on `/host/audit-log`.
- [x] The audit log's UI clearly indicates it does not cover
      exam-session/enrollment activity (per the documented scope limit),
      rather than silently appearing incomplete.
- [x] Exporting a Class roster produces a `.xlsx` file that, re-imported
      through the existing parser, round-trips to the same set of
      students.
- [x] The Program dashboard's class/student counts match the real
      underlying data after a create/archive/transfer sequence (not just
      on first load).
- [x] `mvn -pl services/admin test` — full suite, including every
      Phase 2/3/5/12 test file — passes unmodified in intent (only the new
      audit-assertion additions change), confirming the retrofit is
      genuinely additive.
- [x] `pnpm --filter tenant-web lint`/`build` clean.
- [x] **Every `@PreAuthorize`-bearing file across the entire repo that is
      NOT in Phase 4's original 26-file list is individually reviewed and
      classified here** (append the list/table to this file once done) —
      zero new controllers from Phases 2/3/5/12/13 left unreviewed.
- [x] **Zero newly-added controllers found with an exclusion-style
      (`!hasRole`) check or any other pattern that would unintentionally
      admit `LECTURER`/`PROGRAM_COORDINATOR`** — or, if one is found, it's
      fixed and documented here before this phase is considered done.
- [x] The combined before/after `@PreAuthorize` grep diff (Phase 4's
      original 26 vs. this phase's full-repo count) is recorded here, so
      `plan.md`'s Verification tổng thể step 4 has a concrete artifact to
      point at rather than an unverified claim.

### Final consolidated `@PreAuthorize` audit (Step 7)

Re-ran `grep -rl "@PreAuthorize" services/*/src/main/java pte-common/src/main/java`
against the tree as it stands at the end of this plan (not trusting Phase 4's
"31" as a given baseline, per that phase's own Risks note) — **34 files
total**, vs. Phase 4's 31 (which itself corrected an original 26-file
plan-writing-time snapshot). The 3 new files beyond Phase 4's 31, each read
in full and classified with Phase 4's own method:

| # | File | Service | Expression(s) | Class |
|---|------|---------|----------------|-------|
| 32 | `AuditLogController` | admin (Phase 13, this phase) | `hasRole('HOST_ADMIN')` | (a) |
| 33 | `LecturerAssignmentController` | admin (Phase 9) | class: `hasAnyRole('HOST_ADMIN','HOST_AUTHOR')`; 2 methods (`assign`, `unassign`): `hasRole('HOST_ADMIN')` | (a) |
| 34 | `ProgramCoordinatorAssignmentController` | admin (Phase 9) | class: `hasAnyRole('HOST_ADMIN','HOST_AUTHOR')`; 2 methods (`assign`, `unassign`): `hasRole('HOST_ADMIN')` | (a) |

**Result: zero files in category (b)** across all 34 — no exclusion-style
(`!hasRole`) check exists anywhere in the repo (confirmed by the same
repo-wide `!.*hasRole` grep Phase 4 ran, re-run here with the same empty
result). Every `@PreAuthorize`-bearing file added since Phase 4, across
Phases 5/9/12/13, is the same safe `hasRole`/`hasAnyRole` allow-list
pattern — no unintended widening exists that would let `LECTURER`/
`PROGRAM_COORDINATOR` reach an endpoint not explicitly designed for them.
Combined with Phase 4's own 31-file table, this closes out the plan's
full-repo `@PreAuthorize` coverage: **34/34 files reviewed across the
entire plan, 0 unresolved findings.**

## Quality and Testing State

- Quality gate: **APPROVED, 0 findings** after round 2 (round 1 was
  CHANGES_REQUIRED: 0 BLOCKER, 0 HIGH, 2 MEDIUM, 1 LOW — all 3 fixed and
  independently re-verified by the same reviewer agent, which re-read every
  changed file directly rather than trusting the fix summary, and re-ran
  both `mvn -pl services/admin -am test` (107/107) and
  `pnpm --filter tenant-web build`/`lint` itself):
  - **QUAL-001 (MEDIUM)**: `buildHostNav` added "Audit Log" unconditionally
    to every Host's sidebar, but the page itself is `HOST_ADMIN`-only
    (mirroring the backend's `AuditLogController`) — a `HOST_AUTHOR` would
    see the link, click it, and be silently bounced to the login screen by
    `RequireAuth` (which has no distinct "insufficient permissions" state,
    only a redirect to login), indistinguishable from an unexpected logout.
    Fixed by adding an optional `requiredRoles?: SessionRole[]` field to
    `NavItem`, setting it on the "Audit Log" entry, and filtering in
    `DashboardChrome`'s `SidebarNav` against `useCurrentUser()`'s roles —
    no changes needed to any of the 9 page.tsx call sites of `buildHostNav`.
  - **QUAL-002 (LOW)**: the pre-existing `useProgramRoster` docblock was
    left orphaned above the newly-inserted `useProgramDashboard` (which got
    its own new docblock immediately after it), so the old comment now
    visually described the wrong function and `useProgramRoster` had no
    docstring at all. Fixed by moving the orphaned block back down to
    directly precede `useProgramRoster`.
  - **QUAL-003 (MEDIUM, "phase file's own completion criteria not yet
    satisfied")**: raised against an intermediate state of this file (the
    Step 7 audit table and Success Criteria had already been added by the
    time this note is being written) — the reviewer's independent
    verification of the underlying `@PreAuthorize` audit work (34 files, 3
    new beyond Phase 4's 31, all category (a), zero (b)) confirmed it
    substantively correct; no further action needed beyond what's already
    recorded below.
  - **Also addressed (not a filed finding, a reviewer note)**: `mergeClasses`
    was writing its `AuditLog` summary row unconditionally, including for
    the true no-op case (every `sourceClassPublicId` equals the target, so
    nothing moves) — this produced a confusing "Merged 1 Class(es) into X
    (0 student(s) moved)" row. Fixed by skipping the audit write (not the
    outbox summary write, which correctly stays unconditional per existing
    Phase 12 test expectations) when `movedStudentPublicIds` is empty,
    mirroring `bulkAssign`'s existing empty-result skip. Added
    `verify(auditLogService, never()).record(...)` to the existing
    `mergeClasses_sourceEqualsTarget_skippedAsNoOp` test to lock this in.
- Testing:
  - Backend: `mvn -pl services/admin -am test` — BUILD SUCCESS, 107/107
    (was 102 before this phase; +5: `AuditLogServiceTest` — 3 new — plus 2
    new dashboard tests in `ProgramServiceTest`). Every pre-existing
    `ProgramServiceTest`/`ClassServiceTest`/`AssignmentServiceTest` test
    still passes with only additive changes (constructor's new
    `AuditLogService` mock parameter, plus new `verify(auditLogService)...`
    assertions appended to existing happy-path tests) — no existing
    assertion was weakened or removed, confirming the retrofit is genuinely
    additive per the plan's own Risks note.
  - Frontend: `pnpm --filter @pte/api-client typecheck` (clean),
    `pnpm --filter @pte/ui typecheck` (clean), `pnpm --filter tenant-web build`
    (clean — new `/host/audit-log` route present in the route list),
    `pnpm --filter tenant-web lint` (clean, 0 warnings after fixing one
    unused-prop warning on `ProgramDashboard`).
- **Design decisions made during implementation, not fully specified by the
  phase's literal Steps**:
  - **Audit granularity is per-API-call, not per-outbox-event.** `mergeClasses`/
    `splitClass`/`bulkAssign` each write exactly ONE summary `AuditLog` row
    (with a count baked into the human-readable `summary` text), even though
    they write multiple individual outbox events internally (one per moved/
    assigned student) plus one outbox summary event. This deliberately
    diverges from the "N individual + 1 summary" shape used for the outbox
    in earlier phases — the audit log is a human-reviewed ledger, not an
    event-sourcing feed, so per-call rows avoid flooding the UI for a large
    bulk action while still being fully traceable (each row names the
    actor, the aggregate, and the affected count).
  - `AuditLogService.record(...)` is plain `@Transactional` (Spring's
    default `REQUIRED` propagation) specifically so it always joins
    whichever transaction is already open at the call site — every caller
    is itself an `@Transactional` write method, so the audit row commits or
    rolls back atomically with the entity change and the outbox write.
  - FE dashboard cache staleness: `useProgramDashboard`'s query key is
    nested under the existing `CLASS_MEMBERSHIPS_QUERY_KEY` prefix
    (`[...CLASS_MEMBERSHIPS_QUERY_KEY, programPublicId, "dashboard"]`) so
    it's invalidated for free by every existing
    `invalidateClassMemberships(queryClient)` call (assign/bulkAssign/
    unassign/transfer/merge/split); `useCreateClass`/
    `useClassStatusMutations` (in `features/classes/api/index.ts`) each got
    one additional `invalidateClassMemberships(queryClient)` call in their
    `onSuccess` specifically to cover Class create/archive/activate/
    suspend/deactivate changing the dashboard's class count — a small,
    well-justified addition to already-approved Phase 7/8 code rather than
    a parallel invalidation mechanism.
  - Excel export column headers (`Email`, `Full Name`, `Student Code`,
    `Class`, `Phone`, `Date of Birth`) were chosen to exactly match
    `cleanRosterFile.ts`'s `HEADER_ALIASES` normalization (lowercased,
    non-alphanumeric stripped) so a re-imported export round-trips to the
    same students without any parser changes.
  - `AuditLogController` is `hasRole('HOST_ADMIN')` only (not
    `HOST_AUTHOR`); the FE route (`/host/audit-log`) deliberately passes
    `allowedRoles={["HOST_ADMIN"]}` instead of the app's usual broader
    `HOST_ROLES` constant, to mirror that backend restriction exactly
    rather than letting a `HOST_AUTHOR` see a nav link that then 403s.

## Risks

- Retrofit risk into 4 prior phases' services — this is `plan.md`'s own
  flagged MEDIUM risk; quality review for this phase should specifically
  re-run every touched service's pre-existing test file, not just the new
  audit-specific tests, to catch any accidental behavior change.
- Audit log's `scheduling`-side scope gap (Research Summary item 15) is an
  accepted, documented limitation — not something this phase should try to
  silently patch over with a partial/misleading solution.
- The final consolidated `@PreAuthorize` audit (Step 7) is this phase's
  second, distinct deliverable, easy to under-invest in relative to the
  audit-log/export/dashboard feature work above since it produces no new
  UI — quality review for this phase should verify it actually happened
  with real per-file rigor (same standard as Phase 4), not just a grep
  count comparison.
