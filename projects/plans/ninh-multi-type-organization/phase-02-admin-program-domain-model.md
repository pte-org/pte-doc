# Phase 2: admin — Program Domain Model (Host Self-Service CRUD)

## Requirements

A Host needs a `Program` layer under its existing `Organization` (branch) —
the top level of the new academic hierarchy ("Khối" for a School, "Khóa" for
a Center — same entity, label-only difference driven by Phase 6). This phase
builds the entity, its lifecycle (Active/Inactive/Suspended + archive), and
the first-ever `HOST_ADMIN`/`HOST_AUTHOR`-scoped self-service endpoints in
`services/admin` — today every endpoint in this service is
`PLATFORM_ADMIN`-only.

Maps to: `plan.md` Decision 3 (minimal term dates), Decision 4 (Program
CRUD, status, soft-delete), Decision 6 (tenant-scoping); Research Summary
items 2, 3.

## Design Constraints

- **New self-service surface, not an extension of `OrganizationController`**:
  `TenantController`/`OrganizationController` are
  `@PreAuthorize("hasRole('PLATFORM_ADMIN')")` and trust an explicit
  `tenantPublicId` path segment (safe only because only a platform admin
  calls them). Every endpoint this phase adds is
  `@PreAuthorize("hasAnyRole('HOST_ADMIN','HOST_AUTHOR')")` and resolves
  tenant scope from `caller.tenantId()` (JWT) only — mirrors
  `scheduling.SessionService.findOwned`'s self-service pattern, never a
  path param a caller could tamper with.
- A Host has no way to see its own Organizations today — add a small
  self-service `GET /organizations` (list) + `GET /organizations/{publicId}`
  (get) first, as a prerequisite for picking which Organization a Program
  belongs to. New controller (`HostOrganizationController`), reuses
  `OrganizationService`/`OrganizationMapper` (add 2 new caller-scoped
  methods there — `listForCaller`/`getForCaller` — do not duplicate the
  mapper or repository query logic).
- **Soft-delete reuses `BaseEntity.deleted`** (inherited `isDeleted()`/
  `setDeleted()`), not a new `isArchived` column — this is the first real
  usage of that field anywhere in the repo (Research Summary item 3).
  Every repository query added in this phase (`existsBy...`, `findBy...`)
  must explicitly filter `DeletedFalse` — there is no automatic `@Where`
  clause.
- **List queries must be single-query joins, never per-row lazy
  navigation.** `Program`'s tenant-scope chain is `Program → Organization →
  Tenant` (2 hops). A single `findOwned`-style fetch-by-publicId doing 2
  lazy loads is fine (mirrors `OrganizationService.loadUnderTenant`'s
  1-hop precedent); a **list** of Programs for the caller's tenant must use
  `findByOrganization_Tenant_PublicIdAndDeletedFalse(...)` (one JPQL join),
  never `program.getOrganization().getTenant()` inside a per-row mapper
  loop. This directly avoids repeating the N+1 bug class already caught
  once in `ninh-tenant-host-admin` Phase 4.
- `Program.name` unique **within its Organization** (not globally, not even
  tenant-wide) — enforced at the service layer, only considering
  non-deleted rows (a deleted Program's name becomes reusable).
- Status model: `ProgramStatus { ACTIVE, INACTIVE, SUSPENDED }` — its own
  enum, not reused from `OrganizationStatus`/`TenantStatus`, same reasoning
  as the existing precedent (independent lifecycles for independent
  aggregates, even with overlapping value names).
- `startDate`/`endDate` are both nullable `LocalDate`; add a
  `Program.isCurrentlyActive(LocalDate today)` helper (date range covers
  `today`, or both null = always active) — used by later phases (Phase 10's
  roster resolution, Phase 13's dashboard), not consumed by anything in
  this phase itself.
- Action-suffix REST style for status transitions
  (`/activate`/`/deactivate`/`/suspend`, `/archive`), matching
  `/suspend`/`/reactivate` elsewhere in this service — not a PATCH-on-resource.
- **`archive()` does NOT yet check for active children in this phase** —
  `StudentClass` (the child entity that would need checking) doesn't exist
  until Phase 3. This is a deliberate, temporary, and fully closed gap, not
  an oversight left dangling: Phase 3 retrofits a guard directly into this
  phase's `ProgramService.archive()` (reject if any non-deleted
  `StudentClass` exists under the Program) as soon as `StudentClass` is
  introduced, in the same phase that makes the check meaningful. Do not
  ship this plan's Phase 3 without confirming that retrofit landed — see
  Phase 3's own Design Constraints/Steps for the exact check.
- `ddl-auto: update` handles the new table — no Flyway migration.

## Steps

1. `services/admin/src/main/java/com/pte/admin/domain/Program.java` —
   `@ManyToOne Organization organization` (indexed FK), `name`,
   `description` (nullable), `startDate`/`endDate` (nullable `LocalDate`),
   `status` (`ProgramStatus`, default `ACTIVE`), extends `BaseEntity`
   (reuses inherited `deleted` for archive). `domain/enums/ProgramStatus.java`.
2. `repository/ProgramRepository.java` —
   `findByOrganization_PublicIdAndDeletedFalseOrderByCreatedAtAsc`,
   `findByOrganization_Tenant_PublicIdAndDeletedFalse` (tenant-wide, single
   join — used by Phase 13's dashboard later, add now while touching this
   file), `existsByOrganization_PublicIdAndNameIgnoreCaseAndDeletedFalse`,
   `findByPublicId`.
3. `domain/exception/{ProgramNotFoundException,ProgramNameAlreadyUsedException}.java`;
   `dto/request/{CreateProgramRequest,UpdateProgramRequest}.java`;
   `dto/response/ProgramResponse.java`; `mapper/ProgramMapper.java`
   (takes the owning `organizationPublicId` as an explicit parameter, same
   reasoning as `OrganizationMapper.toResponse(org, tenantPublicId)` — no
   call site should ever need `program.getOrganization()` in a list loop).
4. `service/OrganizationService.java` — add `listForCaller(CurrentUser caller)`
   / `getForCaller(UUID publicId, CurrentUser caller)`, both scoped by
   `caller.tenantId()` instead of a path param.
5. `service/ProgramService.java` — `create`/`list` (by Organization)/`get`/
   `update` (name/description/dates)/`activate`/`deactivate`/`suspend`/
   `archive`, all taking `CurrentUser caller`, all verifying
   `organization.getTenant().getPublicId().equals(caller.tenantId())`
   before allowing any read/write (throw `ProgramNotFoundException` on
   mismatch, same "wrong tenant looks like not-found" pattern as
   `OrganizationService.loadUnderTenant`). `archive()` in this phase has no
   children to check yet (see Design Constraints) — implement it as a plain
   status/`deleted` flip for now; leave an explicit `// Phase 3 retrofits an
   active-children guard here` comment so the follow-up isn't missed.
6. `controller/HostOrganizationController.java` (`/organizations`,
   `hasAnyRole('HOST_ADMIN','HOST_AUTHOR')`) — list/get.
   `controller/ProgramController.java`
   (`/organizations/{organizationPublicId}/programs`, same roles) — create/
   list/get/update/activate/deactivate/suspend/archive.
7. `constant/AdminConstants.java` — `AGGREGATE_PROGRAM`,
   `EVENT_PROGRAM_CREATED`, `EVENT_PROGRAM_UPDATED`,
   `EVENT_PROGRAM_STATUS_CHANGED`, `EVENT_PROGRAM_ARCHIVED`;
   `domain/event/{ProgramCreatedEvent,ProgramUpdatedEvent,ProgramStatusChangedEvent,ProgramArchivedEvent}.java`.
   Every write method in `ProgramService` writes its event in the same
   transaction as the entity save (ADR-002, no exceptions).
8. Tests: `ProgramServiceTest.java` (create/name-uniqueness-within-org/
   status transitions/archive/tenant-mismatch-404/list excludes archived),
   `ProgramMapperTest.java`, extend `OrganizationServiceTest.java` for the
   2 new caller-scoped methods.

## Success Criteria

- [ ] A `HOST_ADMIN` can list its own tenant's Organizations
      (`GET /organizations`) without any platform-admin involvement.
- [ ] Creating 2 Programs with the same name under 2 *different*
      Organizations of the same tenant both succeed; the same name twice
      under the *same* Organization is rejected.
- [ ] Archiving a Program removes it from `GET .../programs` (list) but it
      remains fetchable by `GET .../programs/{publicId}` (get-by-id still
      works — archive is a visibility/lifecycle flag, not a hard delete).
- [ ] A Host from Tenant A requesting a Program that belongs to Tenant B's
      Organization gets 404, not the Program's data.
- [ ] `mvn -pl services/admin test` passes, including all new tests from
      Step 8.
- [ ] (Cross-phase — verify once Phase 3 has landed, not blocking this
      phase's own completion): `ProgramService.archive()` rejects when the
      Program has any non-archived `StudentClass` underneath it. Tracked
      here so it isn't lost between phases; the actual test lives in
      Phase 3.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after
  implementing this phase).
- Testing: not started.

## Risks

- First real usage of `BaseEntity.deleted` in the repo — mitigated by an
  explicit regression test proving deleted rows are excluded from list
  queries (not just "looks fine").
- New self-service surface in `admin` — mitigated by mirroring
  `scheduling`'s already-reviewed `findOwned` tenant-scoping pattern
  exactly rather than inventing a new one.
- `archive()` ships in this phase without an active-children guard
  (`StudentClass` doesn't exist yet) — accepted as a short-lived,
  explicitly tracked gap closed by Phase 3's retrofit, not a silent hole;
  do not consider this phase's `archive()` production-ready in isolation.
