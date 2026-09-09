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

- [ ] Every Program/Class/membership/assignment/merge-split mutation made
      through this plan's UI produces a corresponding, correctly-attributed
      `AuditLog` row, visible on `/host/audit-log`.
- [ ] The audit log's UI clearly indicates it does not cover
      exam-session/enrollment activity (per the documented scope limit),
      rather than silently appearing incomplete.
- [ ] Exporting a Class roster produces a `.xlsx` file that, re-imported
      through the existing parser, round-trips to the same set of
      students.
- [ ] The Program dashboard's class/student counts match the real
      underlying data after a create/archive/transfer sequence (not just
      on first load).
- [ ] `mvn -pl services/admin test` — full suite, including every
      Phase 2/3/5/12 test file — passes unmodified in intent (only the new
      audit-assertion additions change), confirming the retrofit is
      genuinely additive.
- [ ] `pnpm --filter tenant-web lint`/`build` clean.
- [ ] **Every `@PreAuthorize`-bearing file across the entire repo that is
      NOT in Phase 4's original 26-file list is individually reviewed and
      classified here** (append the list/table to this file once done) —
      zero new controllers from Phases 2/3/5/12/13 left unreviewed.
- [ ] **Zero newly-added controllers found with an exclusion-style
      (`!hasRole`) check or any other pattern that would unintentionally
      admit `LECTURER`/`PROGRAM_COORDINATOR`** — or, if one is found, it's
      fixed and documented here before this phase is considered done.
- [ ] The combined before/after `@PreAuthorize` grep diff (Phase 4's
      original 26 vs. this phase's full-repo count) is recorded here, so
      `plan.md`'s Verification tổng thể step 4 has a concrete artifact to
      point at rather than an unverified claim.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after
  implementing this phase).
- Testing: not started.

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
