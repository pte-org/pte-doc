# Phase 1: iam — Org-Type Signal Projection (Tenant Registry + `/auth/me`)

## Requirements

Every later phase (label-driven UI in particular) needs to know a Host's
`organizationType` (`SCHOOL`/`UNIVERSITY`/`TRAINING_CENTER`/`CORPORATE`,
already stored on `admin`'s `Tenant`) from the Host's own session, without
`tenant-web` ever calling `admin` directly (data-plane services never call
`admin` per request — ADR-001, already established). `admin` already emits
`organizationType` in its `TenantOnboarded` event payload; iam's mirror of
that event throws it away. This phase closes that gap end to end: iam's
`TenantRegistry` projection gains the field, and `GET /auth/me` (already the
FE's `getCurrentUser()` source, `apps/tenant-web/features/auth/api.ts`)
returns it.

Maps to: `plan.md` Decision 4 (org-type label config), Decision 5 (label
source must be live, not stale localStorage); Research Summary items 1, 14.

## Design Constraints

- `TenantRegistry` is a **projection, never written by a human-facing
  endpoint** (existing doc comment on the entity) — this phase only extends
  what the existing `TenantEventConsumer` writes into it on
  `TenantOnboarded`, it does not add a new write path.
- `organizationType` on `TenantRegistry` must be **nullable** — existing
  rows (tenants onboarded before this phase ships) will have `null` here
  forever, since there is no event-replay mechanism in this repo (Research
  Summary item 14). Do not add a NOT NULL constraint; do not attempt a
  backfill migration (no Flyway in this repo).
- `UserResponse.organizationType` is populated **only in `UserService.me()`**
  (one extra `TenantRegistryRepository` lookup, only for the calling user's
  own tenant, only on this one endpoint) — not in `get()`/`listByTenant()`/
  `createBulk()`'s response paths, to avoid adding a registry lookup to
  every user-list call for no reason. Null for platform users
  (`caller.tenantId() == null`).
- Keep iam's own `TenantOnboardedEvent` record `@JsonIgnoreProperties(ignoreUnknown = true)`
  (unchanged) — admin's payload may carry more fields than iam needs;
  iam only ever declares the ones it actually consumes (§3 of the
  cross-service DTO convention, already documented on the existing record).
- `ddl-auto: update` adds the new nullable column automatically — no Flyway
  migration.
- Outbox/event convention doesn't apply here — this phase only widens an
  existing *consumed* event and an existing *read* endpoint, it adds no new
  write path of its own.

## Steps

1. `services/iam/src/main/java/com/pte/iam/domain/event/TenantOnboardedEvent.java`
   — add `organizationType` field: `record TenantOnboardedEvent(UUID tenantPublicId, String organizationType)`.
2. `services/iam/src/main/java/com/pte/iam/domain/TenantRegistry.java` — add
   nullable `organizationType` (String) column.
3. `services/iam/src/main/java/com/pte/iam/messaging/consumer/TenantEventConsumer.java`
   — `applyOnboarded(...)` sets `registry.setOrganizationType(event.organizationType())`
   in addition to what it already sets.
4. `services/iam/src/main/java/com/pte/iam/dto/response/UserResponse.java` —
   add nullable `String organizationType` field (last field, after
   `dateOfBirth`, to minimize positional-arg churn at call sites that
   already exist).
5. `services/iam/src/main/java/com/pte/iam/mapper/UserMapper.java` — add an
   overload `toResponse(User user, String organizationType)`; keep the
   existing `toResponse(User user)` overload calling the new one with
   `null` so every other call site (`get`, `listByTenant`, `create`,
   `createBulk`) is unaffected.
6. `services/iam/src/main/java/com/pte/iam/service/UserService.java` —
   `me(CurrentUser caller)`: after loading the user, if
   `caller.tenantId() != null`, look up
   `tenantRegistryRepository.findByTenantPublicId(caller.tenantId())` and
   pass its `organizationType` (or `null` if the registry row itself is
   missing/not yet projected) into `UserMapper.toResponse(user, organizationType)`.
   Inject `TenantRegistryRepository` into `UserService`'s constructor.
7. Tests: extend `TenantEventConsumerTest.java` (new assertion —
   `applyOnboarded` persists `organizationType`), extend `UserServiceTest.java`
   (`me()` returns the tenant's `organizationType`; `me()` for a platform
   user returns `null`; `me()` when no registry row exists yet returns
   `null` without throwing).
8. `packages/api-client/src/types/account/index.ts` — add
   `organizationType: string | null` to the `CurrentUser` interface
   (mirrors the new `UserResponse` field 1:1, matching this file's existing
   doc-comment convention of citing the backend response it mirrors).

## Success Criteria

- [x] A newly-onboarded tenant's `GET /auth/me` (as that tenant's
      `HOST_ADMIN`) returns the same `organizationType` string the platform
      admin set at onboarding.
- [x] `GET /auth/me` for a `PLATFORM_ADMIN`/`PLATFORM_AUTHOR` (no tenant)
      returns `organizationType: null`, not an error.
- [x] `GET /auth/me` for a user whose tenant was onboarded before this
      phase (no registry row / null `organizationType`) returns
      `organizationType: null`, not a 500.
- [x] `mvn -pl services/iam test` passes, including the 2+ new tests from
      Step 7.

## Quality and Testing State

- Quality gate: APPROVED (0 findings — see `ck:quality --gate` run).
- Testing: done — `TenantEventConsumerTest.onboarded_persistsOrganizationType`,
  `UserServiceTest.me_returnsTenantsOrganizationType`,
  `me_platformUser_returnsNullOrganizationTypeWithoutRegistryLookup`,
  `me_noRegistryRowYet_returnsNullWithoutThrowing`. `mvn -pl services/iam
  -am test` — BUILD SUCCESS.

## Risks

- Existing tenants have no `organizationType` in the registry until
  onboarded again or manually backfilled — accepted, documented in
  `plan.md` Risks (HIGH, accepted). FE (Phase 6) must have a safe default,
  this phase does not attempt one server-side.
