# Phase 1: Commercial plan catalog and public plans

## Scope

The commercial model was clarified and exercised locally with the platform
admin and host-admin accounts.

## Delivered behavior

- Vendor admin uses **Plan catalog** for `EXAM_PACKAGE` and
  `STUDENT_CAPACITY` definitions.
- The create-plan form is hidden initially and appears after `+ Add plan`, in
  line with other add flows.
- The published catalog supports an `All` filter in addition to exam packages
  and capacity add-ons.
- Plan overview counts remain API-derived: total, active, and draft plans.
- Tenant public home uses `useTenantPlansQuery()` and renders only `ACTIVE`
  plans. It groups them into:
  - Exam packages
  - Student capacity add-ons
- Public cards use API name, price, currency, duration/capacity, description,
  and the appropriate registration or purchase link. Seeded plan cards are no
  longer the source of truth.
- Tenant billing/quota pages consume the same plan/quota APIs and now expose
  collapsible overview statistics.

## Important product boundary

The admin catalog defines what can be sold. A tenant's purchased access is a
different concern. The session deliberately did not add another
`Active subscriptions` or `Active access` screen.

## Main files

- `pte-web/apps/vendor-web/features/commercialization/components/PlanCatalogView.tsx`
- `pte-web/apps/tenant-web/features/public/components/HomeView.tsx`
- `pte-web/apps/tenant-web/features/commercialization/components/PlanCatalogView.tsx`
- `pte-web/apps/tenant-web/features/commercialization/components/QuotaView.tsx`

## Local test accounts

- Platform admin: `admin@test`
- Host admin: `host@test`

Both were used against the local Docker-backed environment before the frontend
verification pass.
