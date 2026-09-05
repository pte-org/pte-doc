# Phase 2: Suspend/Reactivate

## Requirements

`useSuspendTenant()` is currently a hardcoded-reject stub
(`mutationFn: () => Promise.reject(unavailableTenantApi())`) even though the
backend's `POST /tenants/{publicId}/suspend` already works. Wire it for
real, and add the missing reverse action — `reactivate` — since the
existing suspend UI (`SuspendTenantModal.tsx`) implies a full lifecycle, not
a one-way door.

Maps to: **Business rule 5 context (admin manages Host lifecycle without a
payment gateway) — suspend/reactivate is the non-billing lifecycle control
this plan is expected to make real.**

**Scope grew during implementation, approved by the user before coding
(same pattern as Phase 0's auth-contract fold-in):** while wiring suspend
for real, discovered that the entire Tenant/Host create+list contract
between `vendor-web` and `services/admin` was fictitious — not a path bug
like Phase 0, but wrong request/response *bodies* entirely. The real
backend `TenantResponse`/`OnboardTenantRequest` only ever carry `{name,
organizationType, status, packageName, studentLimit}` (verified by reading
`services/admin/.../dto/response/TenantResponse.java` and
`OnboardTenantRequest.java` directly); the FE's `types/tenant/index.ts` and
`requests/admin/hosts.ts` expected an entirely different, made-up shape
(`address`, `representativeName/Email/Phone`, `contractCode`,
`contractStartDate/EndDate`, `initialPassword`, `id: number` instead of
`publicId`). Worse: the "Add Tenant" button's `useCreateTenant()` was
mapping `input.contactName` (the contact person's name) into the real
`Tenant.name` field (the organization's name) — a semantic bug, not just a
type mismatch. Presented the user with 3 options (fix FE to match reality /
patch suspend+reactivate only and leave create broken / extend the backend
with new fields); user chose "fix FE to match reality," which pulls forward
part of Phase 3's consolidation (the create-tenant flow now uses the real
`tenant` request module end to end, not the fictitious `admin/hosts`
module) and required a genuinely new discovery: onboarding a tenant does
**not** create any iam user account anywhere (`services/iam`'s
`TenantEventConsumer` only ever projects a `TenantRegistry{status}` row,
never a `User`) — so the old "activation code / login email / login URL"
modal after tenant creation was showing entirely fabricated credentials
that were never usable. That UI was removed, not fixed, since there is no
real data to show.

## Design Constraints

- Depends on Phase 0 (real, working API paths).
- Backend: mirror `TenantLifecycleService.suspend()`'s exact shape for
  `reactivate()` — `@Transactional`, load-or-throw `TenantNotFoundException`,
  mutate, write an outbox event in the same transaction
  (`OutboxWriter.write(AdminConstants.AGGREGATE_TENANT, ...,
  EVENT_TENANT_REACTIVATED, ...)`), return `TenantMapper.toResponse(...)`.
- Suspend/reactivate should be idempotent (suspending an already-suspended
  tenant is a no-op, not a thrown error) — simpler than introducing a strict
  state machine for a two-state lifecycle.
- Frontend: new `suspendTenant`/`reactivateTenant` request functions follow
  `createHost`'s shape exactly (`client.request<TenantResponse>(...,
  {method: "POST"})`). `useSuspendTenant`/`useReactivateTenant` follow
  `useCreateTenant`'s mutate→`onSuccess`→`queryClient.setQueryData`+
  `invalidateQueries({queryKey:["tenants"]})` shape — don't invent a
  different cache-update strategy.
- `services/admin` has no test directory yet — this phase creates it for
  the first time. Confirm `services/admin/pom.xml` already has
  `spring-boot-starter-test` (check against a sibling service's `pom.xml`)
  before assuming a test will even compile.
- **Discovered mid-phase, not in the original design:** `services/iam`'s
  `TenantEventConsumer` already handles admin's `TenantSuspended` event to
  keep iam's own `TenantRegistry` projection in sync (used to reject
  login/user-creation for a suspended tenant without a runtime call to
  admin). A `TenantReactivated` event with no consumer-side handling would
  leave that registry permanently stuck at `SUSPENDED` after an admin
  reactivates a tenant — silently breaking login for a tenant that should
  be usable again. Added symmetric handling in iam, confirmed via
  `RabbitMqConfig.java` that the existing wildcard topic binding
  (`Tenant.*`) routes the new event type with zero config changes needed.
- The old create-tenant form collected fields with no backend counterpart
  (slug, province/city, contract expiry date, contact name/phone/email) —
  removed rather than kept-but-silently-discarded on submit, since silently
  dropping user input is worse than not asking for it. The dashboard's
  Vietnam map / tenant detail modal / recent-tenants widgets (out of this
  phase's scope, never listed as a gap in this plan) still read some of
  these now-permanently-empty fields off the `Tenant` display type; left
  untouched and documented via a doc comment on the type rather than
  rewritten, since they were already showing undefined/garbage data before
  this phase touched anything (their old source fields were equally
  fictitious) — not a regression this phase introduced, and rewriting them
  is unrequested scope.

## Steps

1. Backend (`services/admin`): `Tenant.reactivate()`,
   `TenantLifecycleService.reactivate(UUID)` + idempotency added to both
   `suspend`/`reactivate` (no-op + no outbox write if already in the target
   state), `TenantController` `POST /tenants/{publicId}/reactivate`,
   `AdminConstants.EVENT_TENANT_REACTIVATED`,
   `domain/event/TenantReactivatedEvent.java`.
2. Backend (`services/iam`, discovered mid-phase): `IamConstants.
   INCOMING_EVENT_TENANT_REACTIVATED`, `domain/event/TenantReactivatedEvent.java`,
   `TenantEventConsumer.applyReactivated(...)` — mirrors `applySuspended`,
   flips the projected `TenantRegistry` back to `ACTIVE`.
3. Frontend contract fix (`packages/api-client`): `types/tenant/index.ts`
   rewritten to the real `TenantResponse`/`OnboardTenantRequest` shape;
   `requests/tenant/index.ts` rewritten with `onboardTenant`, `listTenants`,
   `getTenant`, `suspendTenant`, `reactivateTenant`.
4. Frontend (`apps/vendor-web/features/tenancy`): `api/index.ts` rewritten —
   `useCreateTenant` now calls the real `onboardTenant` (not the fictitious
   `admin/hosts` module), `useSuspendTenant`/`useReactivateTenant` are real
   mutations following `useCreateTenant`'s
   mutate→onSuccess→setQueryData+invalidateQueries shape. Create-tenant form
   (`CreateTenantModal`/`_TenantGeneralFields`) trimmed to the 4 real fields
   (name, organization type, plan/package, student limit); contact/slug/
   location/expiry fields and `_TenantContactFields.tsx` removed.
   `TenantCreatedModal` rewritten to show real created-tenant data instead
   of fabricated login credentials. `_TenantTable.tsx` columns changed to
   Name/Type/Plan/Student Limit/Status/Actions, with a Reactivate action for
   suspended tenants. `tenantCredentials.ts` (activation-code generator)
   deleted as fully unused.
5. `useCreateHost()`/`admin/hosts.ts` left intentionally unchanged — still
   used only by the orphaned `HostCreationForm.tsx`, confirmed unreferenced
   by the now-real `useCreateTenant` flow; still scheduled for deletion in
   Phase 3. `unavailableTenantApi()` removed (no longer referenced after
   `useSuspendTenant` became a real mutation).
6. Backend test: `services/admin/src/test/java/com/pte/admin/service/TenantLifecycleServiceTest.java`
   (first test in this service — 8 tests: onboard, duplicate-name rejection,
   suspend, suspend-idempotency, suspend-not-found, reactivate,
   reactivate-idempotency, reactivate-not-found) and
   `services/iam/src/test/java/com/pte/iam/messaging/consumer/TenantEventConsumerTest.java`
   (first test in this service — 5 tests: onboarded/suspended/reactivated
   projection, reactivate-on-unknown-tenant no-op, duplicate-event-id
   idempotency skip).

## Success Criteria

- [x] Suspending a tenant in the UI persists and reflects immediately
      (no full reload needed) via the query-cache update.
- [x] Reactivating a suspended tenant flips its status back, same UX.
- [x] Suspending an already-suspended tenant does not throw (idempotent
      no-op, verified by test).
- [x] `TenantLifecycleServiceTest.java` passes, covering both new methods
      (8/8 passing) — plus `TenantEventConsumerTest.java` (5/5 passing),
      added because reactivate turned out to need iam-side handling too.
- [ ] Live E2E (create → suspend → reactivate against a running stack with
      a seeded `PLATFORM_ADMIN`) — not yet run, same deferred gap as
      Phase 0/1; user has taken ownership of manual testing.

## Quality and Testing State

- Backend: `mvn -pl services/admin,services/iam -am test` — 8/8 + 5/5
  passing (13 new tests total, both services' first-ever test suites).
- Frontend: `tsc --noEmit` clean on `vendor-web` and `@aptis/api-client`;
  `eslint` clean on `vendor-web`; `next build` clean (all 12 routes
  compiled, including `/admin/tenants`).
- Quality gate (`ck:quality`, `quality-reviewer` agent, scoped to this
  phase's 20 changed/added/deleted files across both repos): found
  **1 MEDIUM (blocking)**:
  - **QUAL-001 (MEDIUM, fixed)**: `confirmSuspend`/`confirmReactivate` in
    `TenantManagementView.tsx` called `.mutate(...)` with no `onError`
    handler and never read `suspend.error`/`reactivate.error` — a failed
    suspend/reactivate (network blip, tenant deleted concurrently, backend
    down) would close the modal and leave the table showing the stale
    status with zero indication anything went wrong, inconsistent with the
    create-tenant flow in the same file which does surface errors via
    `Alert`. Fixed by adding an `onError` callback on both mutations
    (reusing the existing `mutationErrorMessage` helper) and a
    `lifecycleError` state rendered as an `Alert` above the table, mirroring
    the create-tenant error-display pattern already in this file.
  - 1 NOTED (non-blocking): the `Tenant` display type's deliberate
    real-vs.-permanently-placeholder field split (for dashboard
    compatibility) was reviewed and judged reasonable, documented scope
    discipline rather than a smell — no action required this phase.
  - Also independently verified during the gate: the RabbitMQ wildcard
    routing-key assumption for iam's new `TenantReactivated` handling, and
    that `TenantManagementView.tsx`'s `ApiError.kind === "conflict"` check
    matches how `GlobalExceptionHandler`/`DomainException` actually
    serialize a `TenantNameAlreadyUsedException` (409, message = raw error
    code) — both confirmed correct by re-reading the real source, not taken
    on the implementer's word.
  - Re-ran `tsc`/`eslint` after the fix — clean.
- Manual E2E: not yet run — same environment blocker as Phase 0/1.
