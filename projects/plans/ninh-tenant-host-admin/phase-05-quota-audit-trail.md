# Phase 5: Package/Quota Audit Trail

## Requirements

Business rule 5: admin allocates Packages/Slots to a Host with no payment
processing, and the allocation must be traceable, not just a mutable
counter. Today `Tenant.packageName`/`studentLimit` are two plain columns
with no history of who granted what, when. Replace this with a proper
ledger and wire the existing `LicensingView` UI shell (currently a
hardcoded-empty stub) to it.

Maps to: **Business rule 5 (Quota Management, traceable, no billing).**

## Design Constraints

- Depends on Phase 4 (reuses the `CurrentUser caller` and outbox
  conventions established there).
- No audit-trail/grant-history entity exists anywhere in this codebase —
  confirmed via repo-wide search. Design this fresh, but built entirely on
  existing conventions (`BaseEntity`, outbox, `CurrentUser`) — no new
  plumbing invented for its own sake.
- Entity name: `QuotaTransaction`, not `QuotaGrant` — the slot lifecycle
  has a reverse direction too (deducting a slot when a student starts an
  exam), so the ledger shouldn't be named only for the "grant" half from
  day one. `actionType` (`@Enumerated(EnumType.STRING)`, enum
  `QuotaActionType { GRANTED, DEDUCTED, REVOKED }`) — **this phase
  implements `GRANTED` only**; `DEDUCTED`/`REVOKED` are declared now purely
  so the future deduct-on-exam-start flow reuses this table instead of
  needing a second migration. Do not implement deduct/revoke logic here —
  out of scope.
- `amount` is a **signed delta** per transaction (positive for `GRANTED`),
  never a running total — the total is derived by summing transactions for
  a tenant. That's what makes this an actual audit trail rather than a
  renamed counter.
- `actorUserId` populated from `CurrentUser.userId()` via the same
  controller-helper-then-explicit-parameter convention as Phase 4's
  `OrganizationService`.
- **Concurrency on the cached counter (real risk, not hypothetical)**:
  `Tenant` keeps `packageName`/`studentLimit` as a cached/denormalized
  current-state snapshot (avoids summing `QuotaTransaction` on every `GET
  /tenants`), but concurrent grant requests for the same tenant can race
  when updating that cache. Add `@Version private Long version;`
  (optimistic locking) to `Tenant.java`. `QuotaTransactionService` must
  catch `OptimisticLockException` on the cache update and surface a clear
  409 to the caller — never let a lost update silently corrupt the cached
  count. This is explicitly preparation for the future high-frequency
  `DEDUCTED` flow (many students starting an exam at once), even though
  that flow isn't implemented here.
- Stay a pure ledger — nothing that smells like invoicing/pricing/billing
  (business rule 2 explicitly excludes payment gateways). If a "package
  catalog" concept seems tempting, it's scope creep unless the user
  explicitly asks for it — keep `packageName` a plain string for now.
- `TenantController` gets its first-ever need for `CurrentUser` here (Phase
  4 added it to `OrganizationController`, not `TenantController` itself) —
  add the same `currentUser()` helper pattern.
- Event name `QuotaGrantedEvent` (specific to the `GRANTED` action), not a
  generic `QuotaTransactionEvent` — makes future consumers unambiguous
  about which action they're reacting to.

## Steps

1. `domain/QuotaTransaction.java`, `QuotaActionType` enum,
   `QuotaTransactionRepository`
   (`findByTenant_PublicIdOrderByCreatedAtDesc`).
2. `Tenant.java`: add `@Version private Long version;`.
3. `GrantQuotaRequest`/`QuotaTransactionResponse` DTOs.
4. `QuotaTransactionService.grant(...)` + `.history(...)` — `@Transactional`,
   creates the transaction row, updates `Tenant`'s cached
   `packageName`/`studentLimit` in the same transaction, catches
   `OptimisticLockException` and rethrows/maps to a 409, writes the
   `QuotaGrantedEvent` outbox entry.
5. `TenantController`: `currentUser()` helper; `POST/GET
   /tenants/{publicId}/quota-transactions`.
6. `AdminConstants.EVENT_QUOTA_GRANTED` + `QuotaGrantedEvent` record.
7. Frontend: `QuotaTransaction` types + request module.
8. `features/licensing/api.ts`: replace the hardcoded
   `EMPTY_LICENSE_STATS`/`[]` in `useLicenseStats`/`useLicenses` with real
   queries; compare `License`'s current type shape against `TenantResponse`
   to see whether the 7-column table needs a new aggregate endpoint or
   already has enough.
9. `_LicenseTable.tsx`: wire the no-op "Renew" action to a grant-quota
   modal → mutation → `invalidateQueries(["licenses"])` +
   `invalidateQueries(["tenants"])`; handle a 409 (optimistic-lock
   conflict) with a specific "data just changed, try again" message, not a
   generic error. Leave "Export PDF" untouched — out of scope.
10. Add a grant-history view (a `QuotaTransaction` list, filterable by
    `actionType`) — this is what makes "traceable" a real, visible UI
    property, not just a backend implementation detail.

## Steps (as actually implemented)

1. Backend: `QuotaActionType` enum, `QuotaTransaction` entity (deliberately
   **no** `Tenant.quotaTransactions` back-reference collection — see Quality
   notes below for why), `QuotaTransactionRepository`
   (`findByTenant_PublicIdOrderByCreatedAtDesc`), `GrantQuotaRequest`/
   `QuotaTransactionResponse` DTOs, `QuotaTransactionMapper` (takes
   `tenantPublicId` explicitly, same N+1-avoidance reasoning as Phase 4's
   `OrganizationMapper`).
2. `Tenant.java`: added `@Version private Long version;` — no other change.
3. `QuotaTransactionService.grant(...)`: loads Tenant, updates cached
   `packageName`/`studentLimit`, `saveAndFlush`s the Tenant inside a
   try/catch for `OptimisticLockingFailureException` → `QuotaConflictException`
   (409), then persists the new `QuotaTransaction` **directly via its own
   repository** (not cascaded through Tenant), writes `QuotaGrantedEvent` to
   the outbox under its own `AGGREGATE_QUOTA_TRANSACTION` aggregate.
   `.history(...)` lists a tenant's transactions, newest first.
4. `TenantController`: added its first-ever `currentUser()` helper (Phase 4
   added this to `OrganizationController`, not here) + `POST/GET
   /tenants/{publicId}/quota-transactions`.
5. `AdminConstants`: `AGGREGATE_QUOTA_TRANSACTION`, `EVENT_QUOTA_GRANTED`,
   `QUOTA_CONFLICT`.
6. Frontend: `packages/api-client` gained `types/quota` +
   `requests/quota` (`grantQuota`, `listQuotaHistory`). `features/licensing`
   largely rewritten: `License` type shrunk to only the fields the real
   `TenantResponse` backs (`tenantId, tenantName, plan, status
   ["active"|"suspended"], seatsTotal`) — dropped the old fictitious
   `issuedAt`/`expiresAt`/`seatsUsed`/`"expiring"|"expired"` statuses
   entirely (confirmed via grep this type has no cross-feature consumer
   forcing placeholder fields to stay, unlike Phase 2's `Tenant` type which
   the dashboard still needs). `useLicenses()` fetches tenants
   independently (own `["licenses"]` query key) rather than reading
   tenancy's cache, to avoid exporting tenancy's private mapping internals
   for a second consumer. New `GrantQuotaModal.tsx` (Renew action wired to
   it) and `QuotaHistoryModal.tsx` (View History action, filterable by
   `actionType`) — both reach into `tenancy/components/_TenantFormField`
   and `tenancy/constants` (`PLAN_SELECT_OPTIONS`), matching an existing,
   heavier cross-feature-import precedent already in `features/dashboard`.
   "Export PDF" left as an explicit no-op, per this phase's own instruction
   not to touch it.

## Success Criteria

- [x] Granting quota to a Host records a `QuotaTransaction` row with the
      correct `actorUserId`, updates `Tenant`'s cached
      `packageName`/`studentLimit`, and writes the outbox event.
- [x] A concurrent-update test proves the `@Version` guard actually fires —
      scoped to what this codebase's test infrastructure can actually
      verify (see Quality notes: no DB-integration-test harness exists
      anywhere in the repo, so this is a Mockito-level translation test,
      not a literal two-thread race against a real database).
- [x] `LicenseTable` shows real data, not the hardcoded empty stub.
- [x] Granting quota through the UI updates seats and appears in the grant
      history view — **partially**: the grantor's raw `actorUserId` (UUID)
      is present in the API response but deliberately not rendered in the
      history table, since admin has no user-identity lookup (that lives in
      iam) to turn a UUID into a readable name; showing a bare UUID would
      be noise, not a real "who granted this" answer. Flagged during the
      quality gate as a scope note, not fixed — a real fix needs a
      cross-service identity lookup, out of this phase's scope.
- [x] `QuotaTransactionServiceTest.java` passes (5 tests), including the
      concurrency test.

## Quality and Testing State

- Backend: `mvn -pl services/admin test` — 29/29 passing (5 new
  `QuotaTransactionServiceTest`).
- Frontend: `tsc --noEmit` clean on `@aptis/api-client` and `vendor-web`;
  `eslint` clean; `next build` clean.
- Quality gate (`ck:quality`, `quality-reviewer` agent, scoped to this
  phase's files, explicitly asked to check whether Phase 4's merge/persist
  bug class recurred): **0 BLOCKER, 0 HIGH, 0 MEDIUM — APPROVED**.
  - Explicitly verified the Phase 4 lesson was structurally avoided, not
    just patched: `QuotaTransaction` has no owned back-reference collection
    on `Tenant` at all (unlike `Organization`), so the ledger row is always
    persisted directly via its own repository — the merge()-creates-a-copy
    footgun cannot recur here by construction, not just by discipline.
  - Verified `saveAndFlush` (not plain `save`) is what makes the
    `OptimisticLockingFailureException` catchable inside the service method
    rather than surfacing uncatchably at outer transaction commit.
  - Verified the `QuotaGranted` outbox routing key (`QuotaTransaction.*`)
    provably cannot reach iam's `Tenant.*`-bound consumer queue.
  - 2 informational (non-blocking) notes, no code change required: (1) the
    missing grantor-name-in-UI gap above, flagged as a documented scope
    decision, not a defect; (2) `history()`'s list endpoint is unpaginated,
    consistent with every other list endpoint in this codebase today, but
    worth revisiting once the future high-frequency `DEDUCTED` flow lands.
- Manual E2E: not yet run — same deferred gap as every prior phase.
