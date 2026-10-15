# Plan: NextAdmin visual skin for vendor tenant management

**Date:** 2026-10-07  
**Status:** Implemented; authenticated admin smoke passed  
**Repository scope:** `pte-web` (implementation), `pte-doc` (plan/spec)  
**Mode:** Hard-equivalent review for a multi-file UI change  
**Source spec:** `spec.md`

## Scope Challenge

- **Exists?** Yes. The route and tenant-management behavior already exist.
- **Minimum?** Refine shared `@pte/ui` visual primitives and compose them in
  `vendor-web /admin/tenants`.
- **Complexity?** Multi-file UI change with shared package consumers; common
  styling and build verification are required.
- **Logic boundary:** no API, auth, route, state, validation, or business-rule
  changes.

## Architecture Decisions

1. `@pte/ui` owns tokens, shell styling, reusable motion, surface, control,
   table, menu, and modal presentation.
2. `TenantManagementView` remains the behavior owner. It only composes common
   presentation primitives and keeps its existing hooks/callbacks.
3. The existing `/logo.png` PTE asset and brand copy remain unchanged.
4. CSS keyframes and `motion-safe`/reduced-motion behavior are preferred over
   a new animation dependency.

## Phase Map

| Phase | Outcome | Status |
|---|---|---|
| 1 | Common NextAdmin visual/motion foundation in `@pte/ui` | Implemented |
| 2 | Tenant-management pilot composition and responsive styling | Implemented |
| 3 | Build, lint, typecheck, diff, and browser verification | Verified with authenticated admin smoke |

## Risks and Mitigations

- Shared changes could affect other pages. Keep class changes semantic and run
  package/vendor checks before finalizing.
- Motion wrappers could alter layout. Use neutral block wrappers only around
  page sections, never inside table rows or form controls.
- Existing styles already include a PTE palette. Reuse tokens and avoid a
  parallel NextAdmin stylesheet.

## Session Notes

- Pilot route resolved to `apps/vendor-web/app/(dashboard)/admin/tenants/page.tsx`.
- Existing behavior owner is `features/tenancy/components/TenantManagementView.tsx`.
- Existing common boundary is `packages/ui`.
- User requested cook-now execution; test/build checks will be run after each
  implementation group where practical.
- Phase 1 added shared motion tokens, `MotionReveal`, shell/page primitive
  polish, and reduced-motion-safe CSS animation without changing public
  behavior.
- Phase 2 composes the shared `DataTable` in the tenant pilot and keeps the
  existing tenant hooks, actions, modal flows, navigation, and logo intact.
- Verification passed: `@pte/ui` typecheck, vendor lint, vendor typecheck,
  vendor build, and `git diff --check`. Lint reports only two pre-existing
  `@next/next/no-img-element` warnings in the question-bank feature.
- Authenticated browser smoke with `admin@test` opened `/admin/tenants`, found
  the expected heading/search/table/Add Tenant controls, exercised local search
  filtering and opened/closed the Add Tenant modal without submitting a
  mutation; no console/page errors occurred.
- The same authenticated route passed a 390px mobile smoke: search/filters
  remained visible, table overflow stayed inside its scroll container, and
  page-level horizontal overflow was false.
- The local API accepted all seven supplied usernames with the provided local
  test password and returned access tokens; tokens were not written to the
  repository or included in this record. Role-specific page coverage beyond
  the platform-admin tenant screen remains out of this pilot's scope.
- After visual feedback that the first pass was too subtle, the common shell
  was brought closer to the reference: inset rounded dashboard frame, neutral
  canvas/sidebar, in-frame header, larger page title, border-first stat cards,
  and neutral active navigation. The existing PTE logo and behavior remain
  unchanged.
- The follow-up pass ports the NextAdmin component boundaries into PTE common
  code: `DashboardHeader`, `DashboardSidebar`, and `DashboardCard` now live in
  `@pte/ui`; `DashboardShell`, `StatCard`, and tenant filters compose them.
  This is source adaptation inside `pte-web`, not a runtime link to the
  reference repository.
