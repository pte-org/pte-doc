# Plan: Multi-Type Organization — Program/Class Hierarchy, Org-Type Label Config, Lecturer/Coordinator Roles

Status: 🟡 Planned — design complete via codebase investigation, no code written yet
Date: 2026-09-09
Mode: Hard
Created by: Ninh
Target platform: `pte-api` services `iam` + `admin` + `scheduling` + `pte-web` app `tenant-web`

## Overview

Today a Host (`Tenant`) is flat: `Tenant` → `Organization` (branch/facility,
already fully built by `ninh-tenant-host-admin` Phase 4) and nothing below
that. `Tenant.organizationType` is already a free-text field set at
onboarding (`SCHOOL`/`UNIVERSITY`/`TRAINING_CENTER`/`CORPORATE` today, per
vendor-web's `ORGANIZATION_TYPE_OPTIONS`) but nothing in the system reads it
— every Host sees the same generic UI regardless of type. This plan (1) adds
a real `Program → Class` academic hierarchy under the existing
`Organization`, (2) makes the entire Host UI's terminology adapt to
`organizationType` (School → Khối/Lớp, Center → Khóa/Lớp) from one
label-lookup dictionary instead of scattered if/else, (3) adds `LECTURER`
and `PROGRAM_COORDINATOR` as first-class roles with their own
Proctor-assignment-shaped assignment tables, and (4) lets a Host bulk-create
exam sessions for an entire Program by resolving its roster and reusing
`scheduling`'s already-built `bulkEnroll`, instead of enrolling students one
by one. Class merge/split, capacity-aware session-splitting, an audit log,
Excel export, and a Program dashboard are explicitly in scope for this pass
too (full v1, not phased out) per the user's own decision below.

## Decisions (gathered/confirmed before phase design — do not re-litigate)

1. **Student↔Class is 1-N** (a student belongs to at most one Class at a
   time). A student in several concurrent exam programs is handled by
   separate `scheduling` Enrollments (already exists), never by a
   many-to-many Class membership.
2. **`LECTURER` and `PROGRAM_COORDINATOR` are genuine new `Role` enum
   values** (mirroring `PROCTOR`, not folded into an existing role), each
   with its own assignment table shaped exactly like
   `scheduling.ProctorAssignment` (target entity + assignee's `publicId` +
   `tenantId`) — `LecturerAssignment` scoped to a Class, `ProgramCoordinatorAssignment`
   scoped to a Program. Because this touches a shared enum consumed by
   `@PreAuthorize` across every service, one phase is a dedicated,
   non-hand-waved audit of all 26 `@PreAuthorize`-bearing controllers in the
   repo — and, since 8 later phases add their own new `@PreAuthorize`-bearing
   controllers after that audit runs, the last phase (13) performs a
   second, final consolidated re-audit covering everything added since
   (see Phase 4 and Phase 13's own Design Constraints).
3. **Term/Batch is minimal**: nullable `startDate`/`endDate` directly on
   `Program`, no separate `Term`/`Batch` table. "Currently active" = date
   range covers now, or null dates = always active.
4. **Full v1 scope, nothing deferred**: org-type label config, Program/Class
   CRUD, Lecturer/Coordinator roles + assignment, student
   import/assign-to-class, bulk-create-exam-session-for-a-Program (via
   existing `bulkEnroll`), transfer between classes (preserving exam
   history, warning on pending exam requests), Active/Inactive/Suspended
   status + soft-delete/archive on Program/Class, organization-wide student
   search, Excel export, a Program dashboard, an audit log, and
   capacity-aware batch-splitting for bulk exam-session creation are **all**
   in this plan, sequenced by risk (foundation first, exploratory last), not
   cut.
5. **FE org-type label source is always the live session, never stale
   localStorage** — re-fetched/validated from `/auth/me` on every app load
   (F5-safe), per the spec's own explicit warning.
6. **Every Program/Class-scoped write endpoint validates server-side that
   the referenced parent (Organization/Program) belongs to the caller's own
   tenant** — a real IDOR-class requirement, not optional, called out in
   every relevant phase's Success Criteria. This includes list/read
   endpoints that feed into a later mutation (e.g. Phase 3's
   `GET /class-memberships`, whose output Phase 10 feeds straight into
   `bulkEnroll`) — a missing tenant AND-clause on a read endpoint is just as
   serious as one missing on a write endpoint when its output drives a
   downstream write. Phase 3 specifies the exact required repository query
   shape for this reason, not just "tenant-scoped" in prose.
7. **Archiving a Program/Class must reject if it still has active children**
   (a non-archived Class under a Program; a student still assigned to a
   Class) rather than silently orphaning them — enforced server-side in
   Phase 2 (retrofitted once children exist) and Phase 3, no `force`-flag
   bypass in v1.
8. **The capacity check in Phase 11's `bulkEnroll` extension must be
   race-safe** (a pessimistic lock on the session row, not a plain
   read-then-write), since two concurrent bulk-enroll calls against the
   same session could otherwise both pass a stale capacity check and
   jointly overshoot it.

## Phases

- [x] Phase 1: `iam` — Org-Type Signal Projection (Tenant Registry +
      `/auth/me`) — extends iam's existing `TenantRegistry` projection with
      `organizationType` (already carried in admin's `TenantOnboarded`
      event payload today, just never consumed) and exposes it on
      `GET /auth/me` so the Host FE has a live, re-fetchable source for
      label selection.
- [x] Phase 2: `admin` — Program Domain Model (Host self-service CRUD under
      Organization) — new `Program` entity + status lifecycle + soft-delete
      (first real use of `BaseEntity.deleted`, currently unused anywhere in
      the repo) + the first-ever HOST_ADMIN-scoped self-service endpoints in
      `admin` (today `TenantController`/`OrganizationController` are
      PLATFORM_ADMIN-only). Ships `archive()` without an active-children
      guard (nothing to check yet); Phase 3 retrofits that guard.
- [x] Phase 3: `admin` (+small `scheduling` addition) — Class Domain Model +
      Student Assignment — `StudentClass` entity under Program,
      `ClassMembership` join entity (1-N enforced by a DB unique constraint
      on `studentPublicId`), assign/unassign/transfer, a new tenant-wide
      class-membership listing endpoint with an explicit tenant+program
      AND-scoped query shape (reused by search/dashboard/bulk features
      later), retrofits Phase 2's Program-archive active-children guard and
      adds the matching guard to Class archive/deactivate, and a new small
      `scheduling` read endpoint (a student's current enrollments) so the
      transfer flow can warn about a pending exam request.
- [x] Phase 4: `iam` — `LECTURER` + `PROGRAM_COORDINATOR` Roles + Cross-Service
      `@PreAuthorize` Audit (Pass 1 of 2) — adds the 2 enum values, widens
      `UserProvisioningHelper.HOST_ASSIGNABLE_ROLES`, and reviews the 26
      `@PreAuthorize`-bearing controllers that exist at this point in the
      plan for unintended widening. Deliberately does not (cannot) cover
      controllers added by later phases — Phase 13 closes that out.
- [x] Phase 5: `admin` — Lecturer/Coordinator Assignment CRUD — mirrors
      `scheduling.EnrollmentService`'s pattern of one service class owning
      two join-entity CRUDs (assign/list/unassign), scoped to Class and
      Program respectively.
- [ ] Phase 6: `tenant-web` — Org-Type Label Dictionary + Label-Driven
      Navigation — a single keyed lookup (never if/else) driving every
      Program/Class-facing label (menu items, filter drill-down order,
      section headings), sourced from Phase 1's live `/auth/me` field.
- [ ] Phase 7: `tenant-web` — Program/Class CRUD UI + Organization-Wide
      Student Search — list/create/edit/archive Program and Class, plus a
      name/phone search across the whole tenant without drilling through
      Program→Class.
- [ ] Phase 8: `tenant-web` — Student Import/Assign-to-Class + Transfer UI —
      reuses the existing `xlsx` roster-parsing utility and bulk-account
      creation flow, targets Class assignment instead of session
      enrollment, adds the transfer-with-pending-exam-warning flow.
- [ ] Phase 9: `tenant-web` — Lecturer/Coordinator Assignment UI — mirrors
      the existing `ProctorAssignmentSection`/`AssignProctorModal` pattern
      almost exactly.
- [ ] Phase 10: `scheduling` + `admin` + `tenant-web` — Bulk-Create Exam
      Sessions for a Whole Program — FE-orchestrated: resolve the Program's
      roster (Phase 3's endpoint), create session(s), call the existing
      `bulkEnroll`. No new inter-service call.
- [ ] Phase 11: `scheduling` — Capacity-Aware Batch Splitting — the riskiest,
      most exploratory phase. `scheduling` has zero capacity concept today;
      this phase introduces a minimal `capacity` field on `ExamSession`,
      enforces it in `bulkEnroll` under a pessimistic lock (race-safe, not
      a plain read-then-write), and teaches Phase 10's orchestration to
      split a Program's roster into capacity-sized batches, each its own
      session.
- [ ] Phase 12: `admin` + `tenant-web` — Class Merge/Split — bulk-move all
      students from one Class into another, or split one Class into two,
      building on Phase 3's transfer primitive.
- [ ] Phase 13: `admin` + `tenant-web` — Audit Log + Excel Export + Program
      Dashboard + Final Consolidated `@PreAuthorize` Audit (Pass 2 of 2) —
      a new append-only `AuditLog` table retrofitted into every prior
      phase's mutation path (Program/Class/membership/assignment/merge-split),
      client-side Excel export (reverse of the existing import), a
      lightweight per-Program dashboard (class/student counts), and — as a
      distinct closing deliverable — a full-repo re-grep/re-classification
      of every `@PreAuthorize`-bearing file added since Phase 4's Pass 1.

## Research Summary

Facts established by direct codebase inspection before writing phases (not
re-derived per-phase):

1. **`Tenant.organizationType` is already a free-text `String`**
   (`services/admin/.../domain/Tenant.java`), set once at onboarding, never
   read anywhere downstream. `admin`'s own `TenantOnboardedEvent` payload
   record already carries `organizationType` — but iam's *mirror* of that
   event (`services/iam/.../domain/event/TenantOnboardedEvent.java`) is
   `@JsonIgnoreProperties(ignoreUnknown = true) record(UUID tenantPublicId)`
   — it deliberately drops the field because nothing needed it before now.
   Phase 1 is the first real consumer.
2. **`TenantController` and `OrganizationController` in `admin` are 100%
   `@PreAuthorize("hasRole('PLATFORM_ADMIN')")`** — confirmed by reading
   both files directly. There is currently **no HOST_ADMIN-accessible
   endpoint anywhere in `admin`.** Every new Program/Class/assignment
   endpoint this plan adds is therefore the *first* self-service
   (`HOST_ADMIN`/`HOST_AUTHOR`) surface in this service — tenant scope comes
   from `caller.tenantId()` (JWT), never a path param, mirroring
   `scheduling.SessionService.findOwned`'s pattern rather than
   `admin`'s own `OrganizationController` (which trusts an explicit
   `tenantPublicId` path segment because only `PLATFORM_ADMIN` calls it).
   Phase 2 also has to add a first self-service Organization list/get
   endpoint (`GET /organizations`) since a Host currently has no way to
   even see its own branches.
3. **`BaseEntity.deleted` exists on every entity in the repo today and is
   never set or queried anywhere** (`pte-common/.../domain/BaseEntity.java`,
   confirmed via a repo-wide grep for `.isDeleted()`/`setDeleted`/`@Where`
   — zero matches). Program/Class soft-delete/"archive" reuses this
   existing field instead of adding a redundant new `isArchived` column —
   this plan is its first real usage anywhere, so it needs its own
   regression test (repository queries must explicitly filter
   `deleted = false`; there's no automatic `@Where` clause today).
4. **`EnrollmentService.bulkEnroll(sessionPublicId, List<UUID>
   studentPublicIds, caller)`** (`services/scheduling`) already dedupes
   in-batch, skips already-enrolled ids, and writes one outbox event per new
   enrollment — exactly the primitive Phase 10 needs. It has no notion of
   capacity; `ExamSession` has no `capacity` field anywhere in the schema
   today (confirmed by reading `ExamSession.java` in full) — Phase 11
   introduces the minimal version, enforced under a pessimistic lock
   (mirroring `SessionService`'s existing lock pattern for its own
   pre-open composition/policy race) rather than a plain read-then-write,
   to close a TOCTOU race a red-team review of this plan's first draft
   flagged.
5. **No per-student reverse enrollment lookup exists in `scheduling`**
   (`EnrollmentRepository` only has session-keyed queries) — Phase 3 adds a
   small new endpoint (`GET /students/{studentPublicId}/enrollments`,
   tenant-scoped) purely so the Class-transfer flow can detect and warn
   about a pending exam request, per the user's explicit rule.
6. **`ProctorAssignment` is the mirror pattern for Lecturer/Coordinator**:
   `@ManyToOne` target entity + a bare assignee `publicId` (no cross-service
   FK) + denormalized `tenantId` + a DB unique constraint as the
   concurrency guard, all owned by one service class alongside its sibling
   join-entity CRUD (`EnrollmentService` owns both `Enrollment` and
   `ProctorAssignment` — a documented, deliberate choice from
   `ninh-host-add-student` Phase 2). Phase 5 follows the same "one service,
   two join-CRUDs" shape for `LecturerAssignment`/`ProgramCoordinatorAssignment`.
7. **`ResourceServerJwt.rolesConverter()` and `AccessTokenIssuer` are fully
   generic** — the `roles` JWT claim is built from `user.getRoles()`
   dynamically and mapped to `ROLE_*` authorities with no hardcoded enum
   whitelist anywhere in the chain. Adding 2 new `Role` values is
   structurally safe by construction; Phase 4's audit is about confirming
   no controller's `@PreAuthorize` expression *unintentionally widens*
   (e.g. an exclusion-style check), not about the JWT plumbing itself. This
   only covers the 26 controllers that exist when Phase 4 runs — Phase 13
   performs the same check again against everything the rest of this plan
   adds afterward (Research Summary item 2's new self-service controllers
   included).
8. **`packages/ui/src/hooks/sessionStorage.ts`'s `SessionRole` union and
   `PteSession.roles`/`hasRole()` are already array/multi-role-capable** —
   confirmed no rework needed beyond adding the 2 new string literals.
   `RequireAuth`/`DashboardChrome`'s `allowedRoles` prop is already a
   required per-call-site array, not hardcoded.
9. **`apps/tenant-web/features/exams`'s `ProctorAssignmentSection.tsx` +
   `AssignProctorModal.tsx`** (existing-tab / create-new-tab, role
   select with an inline description legend, react-query
   mutate→invalidate) is the closest FE precedent for Phase 9's
   Lecturer/Coordinator assignment UI — mirrored, not reinvented.
10. **`apps/tenant-web/features/examoperations/cleanRosterFile.ts`** (SheetJS
    `xlsx`, client-side only, ISO-date-safe parsing) is reusable as-is for
    Phase 8's class-assignment import; Phase 13's Excel export is the
    reverse direction with the same library, entirely client-side, no new
    backend endpoint.
11. **No Flyway anywhere** — every service uses `ddl-auto: update`; every
    new table/column across all 13 phases relies on that, no migration
    files.
12. **Outbox convention (ADR-002), no exceptions**: every new write path in
    every phase, including small ones (archive, unassign, transfer),
    writes its own outbox event in the same transaction via each service's
    existing `OutboxWriter`.
13. **`Class` as an entity name would shadow `java.lang.Class`** — named
    `StudentClass` instead throughout the schema/code (Phase 3), flagged so
    it doesn't read as an inconsistency with the feature's own "Class"
    vocabulary (still `class` in every user-facing string/label).
14. **Existing tenants onboarded *before* Phase 1 lands won't have
    `organizationType` in iam's projection** — there is no event-replay
    mechanism in this repo (confirmed: `TenantEventConsumer` only reacts to
    live RabbitMQ deliveries, nothing re-publishes `TenantOnboarded` for
    already-onboarded tenants). Accepted as a known dev-stage gap (see
    Risks) — FE must have a safe generic default for a null/unmapped
    `organizationType`, not crash or silently show blank labels.
15. **Audit Log (Phase 13) is scoped to `admin`'s own mutations only** —
    `scheduling`'s bulk-enrollment events (Phase 10/11) are not surfaced in
    the new Host-facing audit trail, because associating a
    `StudentEnrolled` event back to the Program that triggered it would
    require a new cross-service tag this plan doesn't otherwise need
    (`ExamSession` has no `programPublicId` field). Documented as an
    accepted "at minimum" scope limit per the user's own phrasing, not an
    oversight.

## Dependencies

- `pte-api` running locally (gateway + `iam` + `admin` + `scheduling` +
  `authoring` at minimum) for any end-to-end verification.
- A seeded `HOST_ADMIN` user whose tenant has `organizationType` set to both
  a School-family and a Center-family value, to exercise label switching
  (Phase 6+) — may need two separate seeded tenants.
- Phase 2/3 depend on Phase 1 only loosely (different services) but Phase 6
  (FE labels) hard-depends on Phase 1's `/auth/me` field existing. Phase 2
  and Phase 3 have a two-way dependency of their own: Phase 3 retrofits an
  active-children guard into Phase 2's `ProgramService.archive()`, so Phase
  3 cannot be considered complete (and Phase 2's `archive()` should not be
  treated as production-ready) until both have landed. Phase 5 depends on
  Phase 4 (roles must exist before assignment rows can reference them
  meaningfully, though the FK itself is a bare `publicId`, not enforced at
  the DB level). Phase 7/8/9 depend on Phases 2/3/5 respectively (need real
  endpoints to call). Phase 10 depends on Phase 3 (roster resolution) and
  the existing `bulkEnroll`. Phase 11 depends on Phase 10 landing first
  (extends its orchestration). Phase 12 depends on Phase 3's transfer
  primitive. Phase 13 depends on essentially everything before it
  (retrofits audit calls into Phases 2/3/5/12's services, and its final
  `@PreAuthorize` audit needs every other phase's controllers to already
  exist to be meaningful — it is intentionally the last phase in the plan
  for this reason, not just by convention).

## Risks

- **HIGH (accepted, documented — Research Summary item 14)**: pre-existing
  tenants onboarded before Phase 1 ships have no `organizationType` in
  iam's registry projection until a manual DB backfill or a future
  replay/reconciliation job is built (out of this plan's scope). Mitigation:
  FE label dictionary has an explicit, documented default (Center-style
  generic terms) for a null/unrecognized `organizationType`, never a crash
  or blank UI.
- **CRITICAL → mitigated**: Phase 3's shared `GET /class-memberships`
  endpoint (reused by Phase 7 search, Phase 10 bulk exam-session creation,
  and Phase 13's dashboard) is the single highest-severity spot in this
  plan — a missing tenant AND-clause on its `programPublicId`-filtered
  query path would let a Host pull another tenant's roster, and since
  Phase 10 feeds its output straight into `scheduling.bulkEnroll`, would
  let a Host cross-enroll another tenant's students into their own exam
  session. Mitigation: Phase 3's Design Constraints now specify the exact
  required repository query signature (tenant AND program, always in one
  query, never a program-only lookup method) plus a dedicated cross-tenant
  Success Criterion/test, rather than relying on "tenant-scoped" prose
  alone.
- **HIGH → mitigated**: archiving a Program/Class with active children
  (a non-archived Class under a Program; a student still in a Class) was
  originally unspecified — would have silently orphaned students/Classes
  while removing them from active lists (dashboard counts, search, Phase
  10's roster resolution). Mitigation: Phase 2/3 now specify an explicit
  server-side rejection (409) with no `force`-flag bypass in v1, each with
  its own Success Criteria test.
- **HIGH → mitigated**: Phase 11's capacity check was originally a plain
  read-then-write (TOCTOU race — two concurrent `bulkEnroll` calls against
  the same session could both pass a stale check and jointly overshoot
  capacity, undermining the phase's own "backend enforces the ceiling even
  if the FE has a bug" guarantee). Mitigation: a pessimistic write lock on
  the session row for the duration of the count-check-then-insert,
  mirroring `SessionService`'s existing lock pattern, with a dedicated
  concurrency regression test.
- **HIGH → mitigated**: Phase 4's `@PreAuthorize` audit runs before 8 later
  phases add their own new `@PreAuthorize`-bearing controllers, so those
  were never folded into a "dedicated, complete" audit — each phase was
  self-certifying its own role-check in isolation. Mitigation: Phase 13
  (the last phase) now performs an explicit second, final consolidated
  re-audit covering everything added since Phase 4, using the same
  per-file classification method — see Phase 4 and Phase 13's Design
  Constraints.
- **MEDIUM**: `Tenant.organizationType` is free text with 4 existing values
  (`SCHOOL`, `UNIVERSITY`, `TRAINING_CENTER`, `CORPORATE`) but the feature
  spec only defines a binary School-vs-Center label split. Phase 6 must
  define an explicit bucket mapping (e.g. SCHOOL/UNIVERSITY →
  School-family, TRAINING_CENTER/CORPORATE → Center-family) with a
  documented fallback, not silently treat unmapped values as a crash — flag
  for the user to confirm the exact bucketing before Phase 6 ships to
  production.
- **MEDIUM**: Phase 13's audit-log retrofit touches every write method
  across Phases 2/3/5/12's already-built services — real regression risk if
  done carelessly late in the plan. Mitigation: each retrofit call is
  additive only (a new `auditLogService.record(...)` line beside the
  existing `outboxWriter.write(...)` call, same transaction), and Phase 13's
  own test pass re-runs every touched service's existing test suite, not
  just the new audit tests.
- **MEDIUM**: Phase 11 (capacity-aware splitting) is explicitly the most
  exploratory phase — no existing precedent for capacity or splitting logic
  anywhere in the repo. Mitigation: scoped deliberately small (a nullable
  `capacity` field + a server-side enforcement check + FE-side batch
  splitting, no new backend orchestration endpoint), with the "why not a
  dedicated backend bulk-orchestration endpoint" tradeoff documented in the
  phase file itself rather than silently expanding scope.
- **LOW**: `StudentClass`↔`Program`↔`Organization`↔`Tenant` is a 3-hop lazy
  association chain for `findOwned`-style single-entity tenant-scope checks
  — acceptable for single-row fetches (mirrors the already-accepted
  1-hop pattern in `OrganizationService.loadUnderTenant`), but every
  **list** endpoint must use a direct repository join query
  (`findByProgram_Organization_Tenant_PublicId...`), never per-row lazy
  navigation, to avoid repeating the N+1 bug class already caught once in
  `ninh-tenant-host-admin` Phase 4 (QUAL-001-adjacent). Called out
  explicitly in every phase's Design Constraints, not just noted once here.
- **LOW**: Class merge/split (Phase 12) may need multi-row selection in the
  shared `DataTable` component (`@pte/ui`) that doesn't exist yet — not
  confirmed either way before this plan was written; flagged as a
  first-step research/verification item inside Phase 12 itself rather than
  assumed.

## Verification tổng thể

Sau khi tất cả 13 phase đã cook xong, chạy verification tổng thể sau (không
chỉ verify từng phase riêng lẻ):

1. Backend, từng service đã đổi: `mvn -pl services/iam test`,
   `mvn -pl services/admin test`, `mvn -pl services/scheduling test` (hoặc
   `-am` nếu cần build lại `pte-common` trước) — tất cả phải xanh, không
   skip test nào.
2. Backend, full repo compile check: `mvn -pl gateway,services/iam,services/admin,services/scheduling -am install`
   để chắc `pte-common`'s shared `CurrentUser`/`BaseEntity`/`AbstractOutboxWriter`
   không bị phá vỡ bởi bất kỳ service nào.
3. Frontend: `pnpm --filter tenant-web lint`, `pnpm --filter tenant-web build`
   (phải build sạch, bao gồm mọi route/dynamic-route mới của Phase 6-13),
   `pnpm --filter @pte/api-client lint` (nếu package này có script lint
   riêng — kiểm tra `package.json` trước khi chạy), `pnpm --filter @pte/ui lint`
   nếu `SessionRole` union bị đổi ở Phase 4.
4. **`@PreAuthorize` completeness check — two-pass, not one.** Confirm
   Phase 4's original 26-file classification is on record (in Phase 4's own
   Success Criteria), AND confirm Phase 13's final consolidated re-audit
   (its own Step 7/Success Criteria) actually ran against the **whole**
   repo as it exists after all 13 phases — re-run
   `grep -rl "@PreAuthorize" services/*/src/main/java pte-common/src/main/java`
   yourself at this point, diff it against Phase 4's original 26-file list,
   and confirm every file in the diff (every controller Phases 2/3/5/12/13
   added) has a recorded classification in Phase 13's file, not just a
   passing build. Do not accept "no unintended changes" as verified unless
   this diff was actually produced and reviewed, not assumed clean because
   nothing crashed.
5. **Cross-tenant isolation spot-check on `GET /class-memberships`**
   (Phase 3's CRITICAL fix): with two seeded tenants, call
   `GET /class-memberships?programPublicId=<Tenant-B's-program>` as a
   Tenant-A `HOST_ADMIN` and confirm the response is an empty list, not
   Tenant B's roster — do this manually here even if Phase 3's own
   automated test already covers it, since this is the plan's single
   highest-severity finding.
6. **Archive-with-active-children spot-check** (Phase 2/3 fix): attempt to
   archive a Program that still has a Class, and a Class that still has an
   assigned student; confirm both are rejected (409), then confirm both
   succeed once the children are archived/unassigned first.
7. **Capacity-race spot-check** (Phase 11 fix): if feasible against the
   running stack, fire two near-simultaneous `bulkEnroll` requests at a
   session close to its capacity and confirm the committed total never
   exceeds `capacity` — otherwise rely on Phase 11's own automated
   concurrency regression test and note here that the manual spot-check
   was skipped and why.
8. Manual E2E walkthrough (cần stack chạy thật + 2 tenant đã seed, 1
   School-type + 1 Center-type):
   - Đăng nhập Host của tenant School-type → xác nhận menu/label hiển thị
     "Khối"/"Lớp" đúng, F5 lại trang vẫn đúng (không rớt về label cũ từ
     localStorage).
   - Đăng nhập Host của tenant Center-type → xác nhận label là
     "Khóa"/"Lớp".
   - Tạo Program → tạo StudentClass dưới Program đó → import Excel học
     sinh và assign vào Class → search học sinh theo tên/sđt ở cấp
     Organization mà không cần drill qua Program→Class.
   - Gán 1 Lecturer vào Class, 1 Program Coordinator vào Program → xác
     nhận UI hiển thị đúng, unassign hoạt động.
   - Transfer 1 học sinh đang có lịch thi pending sang Class khác → xác
     nhận cảnh báo hiện ra, exam session cũ của học sinh đó KHÔNG bị đổi.
   - Bulk-create exam session cho cả Program với số học sinh vượt quá 1
     capacity → xác nhận hệ thống tự split thành nhiều session, không có
     học sinh nào bị enroll trùng hoặc bị bỏ sót.
   - Merge 2 Class lại, sau đó split 1 Class ra làm 2 → xác nhận sĩ số học
     sinh trước/sau khớp nhau.
   - Xuất Excel roster của 1 Class → mở file, đối chiếu đúng danh sách học
     sinh hiện tại của Class đó.
   - Mở Program dashboard → xác nhận số liệu class/student count khớp với
     dữ liệu thật.
   - Mở Audit Log → xác nhận toàn bộ các thao tác ở trên (trừ phần liên
     quan `scheduling`, theo Research Summary item 15) đều xuất hiện, đúng
     actor, đúng thời gian.
