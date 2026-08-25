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

## Success Criteria

- [ ] Granting quota to a Host records a `QuotaTransaction` row with the
      correct `actorUserId`, updates `Tenant`'s cached
      `packageName`/`studentLimit`, and writes the outbox event.
- [ ] A concurrent-update test proves the `@Version` guard actually fires
      (`OptimisticLockException` on the second of two racing saves), not
      just that the happy path works.
- [ ] `LicenseTable` shows real data, not the hardcoded empty stub.
- [ ] Granting quota through the UI updates seats and appears in the grant
      history view with the correct grantor.
- [ ] `QuotaTransactionServiceTest.java` passes, including the concurrency
      test.

## Quality and Testing State

- Not started — depends on Phase 4 landing first.
