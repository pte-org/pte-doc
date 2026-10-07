# Spec: NextAdmin visual skin for vendor tenant management

**Date:** 2026-10-07  
**Status:** Ready

---

## Problem Statement

The vendor tenant-management screen has the required data and actions but does
not yet consistently express the polished surface hierarchy, spacing, motion,
and dashboard shell style of `nextjs-admin-dashboard`. The UI needs a focused
visual refresh without changing any domain behavior or existing PTE branding.

---

## User Stories

- **[P1]** As a vendor/admin user, I want the tenant-management screen to use a
  consistent dashboard shell, card elevation, spacing, typography, and control
  treatment so that the screen feels like one coherent admin product.
  Accepted when: `/admin/tenants` uses the shared `@pte/ui` shell/tokens and
  has no page-local duplicate implementation of the shell or card primitives.

- **[P1]** As a vendor/admin user, I want the existing tenant statistics,
  filters, table, and row actions to remain available in the refreshed UI so
  that the visual change does not alter my workflow.
  Accepted when: the existing Add, search, filter, view-details, quota,
  suspend, and reactivate entry points remain rendered with their existing
  callback/API contracts.

- **[P1]** As a vendor/admin user, I want motion to make the screen feel
  responsive without slowing me down.
  Accepted when: common page/card/menu/modal transitions use short CSS motion,
  no new timers or data-fetching are introduced, and reduced-motion users see
  no non-essential animation.

- **[P2]** As a vendor/admin user on a smaller viewport, I want the refreshed
  screen to remain usable without horizontal page overflow.
  Accepted when: the page shell, filters, and table keep their existing
  responsive behavior and only the table's intentional horizontal scroll can
  overflow.

- **[P3]** Future: extend the same visual foundation to the remaining vendor and
  tenant routes. This pilot does not redesign those routes.

---

## Functional Requirements

1. Preserve the current `DashboardChrome` auth boundary, navigation URLs, role
   restrictions, data hooks, mutation callbacks, and modal open/close flows.
2. Keep the existing PTE logo asset and brand text.
3. Build/reuse shared visual primitives in `@pte/ui` before changing the pilot
   screen composition.
4. Use the existing semantic design tokens; do not create a second palette or
   hardcode new hex colors in feature components.
5. Keep tenant-management copy and API-driven values unchanged.
6. Add only presentation-level motion. Do not add business-state timers,
   asynchronous effects, or new navigation behavior.

---

## Non-Functional Requirements

- **Accessibility:** preserve existing labels, focus-visible behavior, modal
  semantics, menu semantics, table semantics, and keyboard actions.
- **Performance:** use CSS transitions/keyframes only; no animation library or
  repeated render loop.
- **Maintainability:** common visual decisions belong in `@pte/ui` or its
  shared token stylesheet; pilot code only composes them.
- **Verification:** run `@pte/ui` typecheck, vendor lint, vendor typecheck,
  vendor production build, `git diff --check`, and a browser smoke check when
  local auth/API state permits.

---

## Success Criteria

- [ ] Shared dashboard shell, surface, motion, and control styling is changed
  before pilot-only styling.
- [ ] `/admin/tenants` keeps all existing tenant actions and API/state wiring.
- [ ] Existing PTE logo remains unchanged.
- [ ] `prefers-reduced-motion: reduce` disables non-essential new motion.
- [ ] No new page-level business logic or API calls are introduced.
- [ ] `corepack pnpm --filter @pte/ui typecheck` passes.
- [ ] `corepack pnpm --filter vendor-web lint` has no new errors.
- [ ] `corepack pnpm --filter vendor-web exec tsc --noEmit` passes.
- [ ] `corepack pnpm --filter vendor-web build` passes.

---

## Out of Scope

- Vendor/admin route changes outside `/admin/tenants`.
- Tenant-web changes.
- Logo replacement, brand identity changes, or new assets.
- API, auth, route, state, validation, data-model, or business-rule changes.
- New filtering, sorting, pagination, bulk actions, or tenant-management
  capabilities.
- Full dark-mode parity or a new animation library.

---

## Assumptions

- `@pte/ui` is the common ownership boundary for the dashboard shell and
  reusable controls.
- The existing PTE-adapted design tokens are the starting point and already
  encode the intended neutral/blue/pastel palette.
- Short reveal/hover/menu/modal motion is acceptable without a new product
  decision; reduced-motion behavior is mandatory.

---

## [NEEDS CLARIFICATION]

None.
