# Phase 2: Vendor tenant-management pilot

## Objective

Compose the common foundation in `/admin/tenants` and refine the pilot's
filters/table surface without duplicating common UI or changing behavior.

## Files

- `pte-web/apps/vendor-web/features/tenancy/components/TenantManagementView.tsx`
- `pte-web/apps/vendor-web/features/tenancy/components/_TenantFilters.tsx`
- `pte-web/apps/vendor-web/features/tenancy/components/_TenantTable.tsx`

## Steps

1. Wrap existing page sections with the common motion primitive using neutral
   layout wrappers and fixed presentation delays only.
2. Refine filter-card and table classes to use the shared surface, border,
   spacing, hover, focus, and responsive patterns.
3. Preserve every existing hook, callback, action label, modal, API-driven
   value, table column, and navigation target.

## Design Constraints

- Preflight: follow the existing tenant feature composition and `@pte/ui`
  imports; do not move domain logic into common components.
- No new route, API request, state variable, validation rule, or data mapping.
- Keep intentional table horizontal scrolling; prevent page-level overflow.
- Keep PTE logo untouched; this phase does not edit `DashboardChrome` branding.

## Quality and Testing State

- Quality: manual diff review confirmed the existing hooks, callbacks, action
  labels, modal entry points, and navigation targets remain intact; formal
  `ck:quality` receipt was not run for this UI-only pilot.
- Testing: vendor typecheck, lint, and build passed. Lint retains two
  pre-existing `@next/next/no-img-element` warnings in question-bank files.
- Build gate: passed with the repository's existing absolute
  `turbopack.root` warning.

## Success Criteria

- The pilot composes common UI instead of introducing duplicate dashboard
  primitives.
- Existing tenant workflows remain represented in the JSX.
- The screen has the NextAdmin-like hierarchy: neutral page canvas, elevated
  white surfaces, compact controls, readable table rows, and subtle motion.
