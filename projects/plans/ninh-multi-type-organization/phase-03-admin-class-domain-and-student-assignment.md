# Phase 3: admin — Class Domain Model + Student Assignment

## Requirements

Below `Program` sits the leaf level of the hierarchy — "Lớp" (Class) for
both School and Center org types (same term either way, only Khối/Khóa
differ by type). This phase adds the Class entity, its own lifecycle, the
student↔Class membership (1-N, per Decision 1), transfer between classes
with a pending-exam-request warning, and a tenant-wide membership listing
endpoint that later phases (search, dashboard, bulk exam-session creation)
all reuse instead of each adding their own.

Maps to: `plan.md` Decision 1 (1-N student↔Class), Decision 4 (Class CRUD,
status, soft-delete, transfer-preserving-exam-history, org-wide search
data source), Decision 6 (tenant-scoping); Research Summary items 3, 5, 13.

## Design Constraints

- **Entity is named `StudentClass`, not `Class`** — `Class` would shadow
  `java.lang.Class` in every file that imports it (Research Summary item
  13). User-facing strings/labels still say "Class"/"Lớp" everywhere; only
  the Java type name differs.
- Same self-service (`caller.tenantId()`-scoped, never a path param)
  pattern as Phase 2's `ProgramService`. `StudentClass`'s tenant-scope
  chain is now 3 hops (`StudentClass → Program → Organization → Tenant`) —
  fine for a single `findOwned`-style fetch, but **every list endpoint
  must be a single joined repository query**
  (`findByProgram_Organization_Tenant_PublicIdAndDeletedFalse(...)`), never
  per-row lazy navigation — same N+1 discipline as Phase 2, called out
  again here because the chain is one hop longer and therefore riskier to
  get wrong.
- **`ClassMembership` is a pure join-table fact** (student is/isn't in a
  Class), same category as `scheduling.Enrollment`/`ProctorAssignment` —
  denormalized `tenantId` column (mirrors that convention exactly, even
  though `StudentClass` itself doesn't denormalize `tenantId` — the
  membership row is queried tenant-wide far more often, e.g. by this
  phase's own search-support endpoint). Bare `studentPublicId` (`UUID`),
  never a cross-service FK to iam's `User` — same rule as `Enrollment.studentPublicId`.
- **1-N enforced by a DB unique constraint on `studentPublicId` alone**
  (not `(class_id, student_public_id)`) — a student can only ever have one
  membership row, period. This is the concurrency guard (same
  "unique-constraint-over-check-then-act" convention as
  `Enrollment`/`ProctorAssignment`), and it's what makes "transfer" a
  simple update-in-place rather than a delete+recreate.
- **Transfer = update the existing membership row's `studentClass` FK**,
  not delete+recreate — this is precisely how "preserving exam history" is
  trivially true: `scheduling.Enrollment` has no reference to
  `ClassMembership`/`StudentClass` at all (Decision 1 — they're
  deliberately decoupled), so a transfer never touches `scheduling` data by
  construction. The **warning** about a pending exam request is a
  read-only check, not a hard block — the Host can still transfer; the old
  exam session is simply never touched either way.
- **Pending-exam-request warning needs a new `scheduling` read endpoint** —
  `EnrollmentRepository` today only supports session-keyed queries
  (confirmed by reading the file). Add
  `GET /students/{studentPublicId}/enrollments` (new top-level controller,
  `hasAnyRole('HOST_ADMIN','HOST_AUTHOR')`, tenant-scoped by matching
  `enrollment.getTenantId() == caller.tenantId()`), returning each
  enrollment's session name/status/opensAt/closesAt via a join to
  `ExamSession` (avoid N+1 — one query, not "fetch session per enrollment
  in a loop").
- Unassign (`DELETE`) is a hard delete, same reasoning as
  `Enrollment`/`ProctorAssignment` (a join-table fact with no independent
  identity worth preserving).
- New tenant-wide `GET /class-memberships` endpoint (optionally filtered by
  `programPublicId`) returns `{studentPublicId, classPublicId, className,
  programPublicId, programName}[]` for the caller's whole tenant in one
  query — this is the shared data source Phase 7 (search), Phase 10 (bulk
  exam-session roster resolution), and Phase 13 (dashboard) all reuse
  instead of each adding their own variant. Build it once, here.
- **`GET /class-memberships`'s tenant+program scoping is a hard security
  requirement with an exact required query shape, not just "tenant-scoped"
  in prose.** The repository query MUST AND both the tenant and (when a
  `programPublicId` filter is supplied) the program in a **single** query
  — never two separate existence/permission checks that a refactor could
  accidentally decouple. Required signatures on
  `ClassMembershipRepository`:
  `findByStudentClass_Program_Organization_Tenant_PublicId(UUID tenantPublicId)`
  (unfiltered, tenant-wide) and
  `findByStudentClass_Program_Organization_Tenant_PublicIdAndStudentClass_Program_PublicId(UUID tenantPublicId, UUID programPublicId)`
  (filtered variant). `ClassMembershipService`'s list method must **always**
  pass `caller.tenantId()` into whichever query it calls — a
  `programPublicId`-only lookup method (e.g. anything shaped like
  `findByStudentClass_Program_PublicId(programPublicId)` alone, with no
  tenant argument) must never exist anywhere on this repository. This
  matters more than the usual N+1 discipline: Phase 10 feeds this
  endpoint's output straight into `scheduling.bulkEnroll` — a missing
  tenant AND-clause here would let a Host cross-enroll another tenant's
  students into their own exam session, not just view another tenant's
  data.
- **Archiving/deactivating must check for active children, not silently
  orphan them — this applies both to `Program` (retrofitted here) and to
  `StudentClass` itself (new in this phase).**
  - `ProgramService.archive()` (built in Phase 2 without this check, since
    `StudentClass` didn't exist yet) is retrofitted in this phase: reject
    (409, new `ProgramHasActiveClassesException`) if any non-deleted
    `StudentClass` exists under the Program
    (`existsByProgram_PublicIdAndDeletedFalse`) — the Host must
    archive/move the Classes first.
  - `StudentClass`'s own archive/deactivate path rejects (409, new
    `ClassHasActiveMembersException`) if any `ClassMembership` row still
    references it (`existsByStudentClass_PublicId`) — the Host must
    unassign or transfer every student out first.
  - Neither check has a `force`-flag bypass in v1 — simplest safe default;
    a force-override can be added later if this proves too rigid in
    practice, but silently orphaning students/sub-resources on archive is
    not an acceptable default.
- `ddl-auto: update` — no Flyway migration.

## Steps

1. `domain/StudentClass.java` (`@ManyToOne Program`, `name`, `status`
   [`ClassStatus{ACTIVE,INACTIVE,SUSPENDED}`, its own enum per the
   independent-lifecycle precedent], extends `BaseEntity` — reuses
   `deleted` for archive). `domain/ClassMembership.java` (`@ManyToOne
   StudentClass`, `studentPublicId` [unique], `tenantId`, extends
   `BaseEntity`).
2. `repository/StudentClassRepository.java` — the join-query list methods
   described in Design Constraints, plus
   `existsByProgram_PublicIdAndDeletedFalse` (for the Program-archive
   retrofit below).
   `repository/ClassMembershipRepository.java` — the exact tenant+program
   AND-scoped signatures specified in Design Constraints, plus
   `findByStudentPublicId`, `existsByStudentPublicId`,
   `findByStudentClass_PublicId`, `existsByStudentClass_PublicId` (for the
   Class-archive guard below).
3. Exceptions/DTOs/mapper: `StudentClassNotFoundException`,
   `StudentClassNameAlreadyUsedException`, `StudentAlreadyInClassException`,
   `ClassMembershipNotFoundException`, `ProgramHasActiveClassesException`,
   `ClassHasActiveMembersException`; `CreateClassRequest`/
   `UpdateClassRequest`/`AssignStudentRequest`/`BulkAssignStudentsRequest`/
   `TransferStudentRequest`; `ClassResponse`/`ClassMembershipResponse`/
   `BulkAssignStudentsResponse` (mirrors `BulkEnrollResponse`'s
   `{assigned, alreadyInClass}` shape); `StudentClassMapper`,
   `ClassMembershipMapper`.
4. `service/ClassService.java` — owns both `StudentClass` CRUD/lifecycle
   AND `ClassMembership` CRUD (assign/bulkAssign/unassign/transfer), same
   "one service, two join-CRUDs" shape as `scheduling.EnrollmentService`
   (deliberate, documented, not accidental scope creep). `bulkAssign`
   mirrors `bulkEnroll`'s dedupe/already-assigned-reporting logic exactly.
   `transfer(membershipPublicId, targetClassPublicId, caller)` verifies the
   target Class belongs to the same tenant (may be a different Program —
   transfer isn't restricted to within-Program) before updating the FK.
   `archive()`/`deactivate()` call
   `classMembershipRepository.existsByStudentClass_PublicId(...)` first and
   throw `ClassHasActiveMembersException` if true.
5. `service/ProgramService.java` (Phase 2 file, touched again here) —
   `archive()` now calls
   `studentClassRepository.existsByProgram_PublicIdAndDeletedFalse(...)`
   first and throws `ProgramHasActiveClassesException` if true, replacing
   the `// Phase 3 retrofits an active-children guard here` placeholder
   left in Phase 2. Extend `ProgramServiceTest.java` (Phase 2's test file)
   with this rejection case in the same change.
6. `controller/ClassController.java`
   (`/organizations/{orgId}/programs/{programId}/classes`,
   `hasAnyRole('HOST_ADMIN','HOST_AUTHOR')`) — CRUD + status transitions +
   archive + assign/bulk-assign/unassign/transfer sub-routes.
   `controller/ClassMembershipController.java` (`/class-memberships`, same
   roles) — the tenant-wide listing endpoint, always forwarding
   `caller.tenantId()` into the service call per the Design Constraint
   above.
7. `services/scheduling`: `repository/EnrollmentRepository.java` — add
   `findByStudentPublicIdAndTenantId(UUID, UUID)` with a join fetch to
   `ExamSession` (or a dedicated JPQL projection) to avoid N+1;
   `dto/response/StudentEnrollmentResponse.java`;
   `controller/StudentEnrollmentController.java`
   (`/students/{studentPublicId}/enrollments`,
   `hasAnyRole('HOST_ADMIN','HOST_AUTHOR')`).
8. `constant/AdminConstants.java` — `AGGREGATE_CLASS`, `EVENT_CLASS_CREATED`,
   `EVENT_CLASS_STATUS_CHANGED`, `EVENT_CLASS_ARCHIVED`,
   `EVENT_STUDENT_ASSIGNED_TO_CLASS`, `EVENT_STUDENT_UNASSIGNED_FROM_CLASS`,
   `EVENT_STUDENT_TRANSFERRED_CLASS`; matching event records under
   `domain/event/`. Every write method writes its event in the same
   transaction (ADR-002).
9. Tests: `ClassServiceTest.java` (create/name-uniqueness-within-program/
   status/archive/archive-rejected-with-active-members/assign/bulk-assign-dedupe/
   unassign/transfer-updates-FK-not-recreates-row/tenant-mismatch-404/
   1-N-violation-rejected), `ClassMembershipMapperTest.java`,
   `StudentClassMapperTest.java`,
   `ClassMembershipServiceTest.java` (or wherever the list method lands) —
   **explicit cross-tenant test**: Tenant A's `GET /class-memberships` with
   a `programPublicId` belonging to Tenant B returns an empty list, never
   Tenant B's rows, new `StudentEnrollmentControllerTest`-equivalent in
   `services/scheduling` (or extend `EnrollmentServiceTest.java` if the new
   query lives in that service class — check first).

## Success Criteria

- [ ] Assigning a student who's already in another Class (in this tenant)
      to a new Class is rejected with a clear error, not silently moved —
      transfer is the explicit, separate operation for that.
- [ ] Transferring a student updates the *same* `ClassMembership` row's
      `publicId` (doesn't create a new row / doesn't delete the old one) —
      verified by asserting the `publicId` is unchanged before/after in a
      test, not just eyeballed.
- [ ] Transferring a student who has a pending (future `opensAt`, not yet
      `CLOSED`) exam enrollment surfaces the enrollment via the new
      `scheduling` endpoint; the transfer still succeeds; the enrollment
      itself is provably untouched (same `publicId`, same `session`) after
      the transfer.
- [ ] `GET /class-memberships?programPublicId=X` returns exactly the
      students in Program X's classes, tenant-scoped, in one query (no
      N+1 — verified by a test asserting query count, or by code
      inspection confirming a single JPQL join, matching this repo's
      existing N+1-regression-test convention).
- [ ] **`GET /class-memberships?programPublicId=<Tenant-B-program>` called
      by a Tenant-A `HOST_ADMIN` returns an empty list — never Tenant B's
      roster — verified by a dedicated cross-tenant test, not inferred
      from the query signature alone.**
- [ ] Archiving a Program that still has a non-archived `StudentClass`
      under it is rejected (409), not silently allowed; archiving succeeds
      once every child Class is archived/removed first.
- [ ] Archiving/deactivating a `StudentClass` that still has active
      `ClassMembership` rows is rejected (409); succeeds once every student
      is unassigned or transferred out.
- [ ] `mvn -pl services/admin test` and `mvn -pl services/scheduling test`
      both pass, including all new tests from Step 9.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after
  implementing this phase).
- Testing: not started.

## Risks

- Transfer across Programs (not just within one Program) is allowed by
  design — flag this explicitly to the user during quality review as an
  intentional choice, not an oversight, in case the real business rule
  turns out to be narrower.
- The new `scheduling` endpoint is a small scope expansion into a service
  this plan otherwise treats as "already built, just call it" — kept
  deliberately minimal (one read endpoint, one new query) to avoid growing
  into a second bulk-enrollment rework.
- The tenant+program AND-scoping on `GET /class-memberships` is the single
  highest-severity correctness requirement in this phase (a miss here is a
  cross-tenant data leak that also poisons Phase 10's bulk-enroll input) —
  called out with an exact required repository signature above specifically
  so an implementer can't quietly satisfy "tenant-scoped" with a
  program-only query and a separate, decoupled tenant check elsewhere.
