# Phase 05: Vendor/admin core pilot migration

## Objective

Use vendor/admin as the first real migration wave and prove the common system
on overview, tenancy, applications, settings, and notifications.

## Files and Areas

- `pte-web/apps/vendor-web/features/dashboard/**`
- `pte-web/apps/vendor-web/features/tenancy/**`
- `pte-web/apps/vendor-web/features/notifications/**`
- `pte-web/apps/vendor-web/features/auth/components/DashboardChrome.tsx`
- `pte-web/apps/vendor-web/app/(dashboard)/admin/**` for the listed routes

## Inputs

- Phase 04 common-component contract and visual checklist.
- Phase 01 route, actor, behavior, density, and failure-state artifacts.
- Frozen pilot set: `/admin`, `/admin/tenants`, and related vendor core routes.

## Outputs

- `phase-05-pilot-verification.md`: role/theme/locale/responsive evidence,
  behavior-manifest review, screenshots, and limitations.
- Updated route and failure-state rows for every pilot surface.

## Steps

1. Migrate `/admin/tenants` and `/admin` first, preserving all existing hooks,
   filters, modal entry points, actions, API values, and the logo.
2. Apply the common shell/theme/locale patterns to tenant detail and
   notification list/detail surfaces. Support tickets remain owned by phase 06.
3. Keep feature composition thin: feature components own data and events;
   common components own presentation.
4. Exercise the density proposal for `TenantDetailView` only if the audit
   confirms it is function-heavy; otherwise use section hierarchy without
   introducing extra state.
5. Verify vendor roles and existing admin/host navigation remain unchanged.

## Design Constraints

- This is a presentation migration, not a vendor workflow redesign.
- Keep current `/admin/*` and `/host` route targets and role restrictions.
- Do not change tenant creation, suspend/reactivate, branding, notification,
  or support API behavior.

## Quality and Testing State

- Quality: not evaluated.
- Testing: not started; run vendor lint/typecheck/build plus authenticated
  desktop/mobile smoke in both themes and locales.

## Blocking Gate

- **PASS** when the pilot uses common primitives, the actor/permission and
  behavior manifests show no URL/role/API/payload/validation/callback drift,
  and vendor checks cover light/dark, vi/en, desktop, 390px, and 320px.
- **UNVERIFIED** when authenticated local accounts/data prevent a role or
  failure scenario; record it without claiming the scenario passed. This
  blocks phase 06 and phase 09 unless a written waiver follows the master-plan
  gate policy.
- **BLOCKED** when a pilot migration changes an action contract, permission
  boundary, or shared provider contract.

## Exit Criteria

- Vendor/admin pilot is visibly NextAdmin-inspired in both themes and locales.
- Existing tenant-management actions remain reachable and behaviorally wired.
- Pilot screenshots and exact verification limitations are recorded.

## Cook Record 2026-10-07

- Implementation: completed for the vendor/admin shell and navigation plus the
  route-preserving tenant-detail tabs pilot.
- Verification: vendor typecheck, lint, and production build passed; the
  existing tenant action contracts were not browser-tested in this run.
- Blocking Gate: **UNVERIFIED** because authenticated browser checks and
  `ck:quality` were skipped at the user's request.
