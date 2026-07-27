# Phase 2: admin — Control Plane

## Requirements

Low-traffic, high-privilege control plane where a platform admin onboards and suspends organizations (tenants) and manages subscriptions/config. It owns tenant *governance*, not tenant *identity* (identity lives in iam and is read from the JWT). Nothing on a critical runtime path depends on admin.

## Design Constraints

- `com.pte.admin`, DB `admin`, uniform layout.
- Only `PLATFORM_ADMIN` role may call these endpoints (method security).
- Admin does NOT own tenant identity — on tenant onboard it emits an event; iam consumes it to seed the registry that becomes JWT claims.
- No synchronous dependency from data-plane services to admin (ADR-001 principle 4).

## Steps

1. Entities: `Tenant` (name, status, publicId), `Subscription`, `PlatformConfig`, `FeatureFlag`. Flyway `V1__admin.sql`.
2. `TenantLifecycleService`: onboard (create tenant + emit `TenantOnboarded`), suspend (emit `TenantSuspended`). `SubscriptionService`, `FeatureFlagService`.
3. `TenantController`: `POST /admin/tenants` (onboard org), `POST /admin/tenants/{id}/suspend`, list/get. `@Valid`, `ApiResponse<T>`, `PLATFORM_ADMIN` guard.
4. `messaging/outbox`+`publisher`: `TenantOnboarded`, `TenantSuspended`.
5. iam-side (small addition in Phase 1 module): `consumer` for `TenantOnboarded` → seed tenant registry row so subsequent host users get the right tenant claim. (Cross-phase note: activate when Phase 6 backbone is wired; until then, direct seeding for local dev.)
6. Tests: onboard emits event to outbox; non-admin role rejected; suspend flips status.

## Success Criteria

- Admin onboards an organization; a `TenantOnboarded` event is written to the outbox in the same TX.
- A non-`PLATFORM_ADMIN` caller is rejected (403).
- No data-plane service imports or calls admin synchronously (verified by dependency check).

## Quality and Testing State

- Quality gate: **approved** (2026-07-24). 0 findings. Report + receipt: `pte-api/plans/quang-pte-microservice-platform/quality/phase-02-admin-control-plane-{quality-report,receipt}.json`.
- Testing: not started — **declined by user** (quality-only cook run). Build Gate green: `mvn install -pl admin -am` compiles.

## Scope note
- Milestone 1 implements Tenant lifecycle (onboard/suspend/get/list) + outbox events. `Subscription`/`PlatformConfig`/`FeatureFlag`/kill-switch deferred (YAGNI — package/studentLimit folded onto Tenant; add when a real subscription/feature-flag flow exists).
- iam-side consumer of `TenantOnboarded` activates in Phase 6 (event backbone); until then seed the registry directly for local dev.
- `OutboxEntry`/`OutboxWriter`/resource-server JWT converter duplicated from iam (2nd occurrence); extract to pte-common at the 3rd service (scheduling), per DRY "3+" threshold.

## Risks

- **LOW: Event-timing coupling** — host user creation needs the tenant to exist. *Mitigation:* onboarding completes before host provisioning in the flow; for local dev before Phase 6, seed registry directly.
