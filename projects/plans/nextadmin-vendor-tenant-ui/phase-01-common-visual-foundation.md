# Phase 1: Common visual and motion foundation

## Objective

Translate the NextAdmin dashboard feel into reusable `@pte/ui` presentation
without changing any feature behavior.

## Files

- `pte-web/packages/ui/src/styles/design-tokens.css`
- `pte-web/packages/ui/src/components/MotionReveal.tsx`
- `pte-web/packages/ui/src/components/index.ts`
- `pte-web/packages/ui/src/layouts/DashboardShell.tsx`
- `pte-web/packages/ui/src/components/PageHeader.tsx`
- `pte-web/packages/ui/src/components/StatCard.tsx`
- `pte-web/packages/ui/src/components/CollapsibleSection.tsx`
- `pte-web/packages/ui/src/components/DataTable.tsx`
- `pte-web/packages/ui/src/components/Dropdown.tsx`
- `pte-web/packages/ui/src/components/Modal.tsx`

## Steps

1. Add shared reveal/dropdown/modal motion tokens and keyframes with a
   reduced-motion-safe contract.
2. Add and export a layout-neutral `MotionReveal` common primitive.
3. Refine shell, page-header, stat-card, section, table, dropdown, and modal
   presentation to match the NextAdmin surface hierarchy and interaction
   feedback.
4. Do not alter component props, event contracts, hooks, data, or navigation.

## Design Constraints

- Preflight: use existing `@pte/ui` token names and class conventions from
  `design-tokens.css`, `DashboardShell.tsx`, `StatCard.tsx`, and `Dropdown.tsx`.
- No new npm package.
- No hardcoded feature-specific colors; use semantic tokens already exposed by
  the stylesheet.
- Motion must be CSS-only, short, and disabled for reduced-motion users.

## Quality and Testing State

- Quality: manual diff review found no changes to public behavior contracts;
  formal `ck:quality` receipt was not run for this UI-only pilot.
- Testing: `corepack pnpm --filter @pte/ui typecheck` passed.
- Build gate: passed.

## Success Criteria

- Common components compile with unchanged public behavior.
- New motion classes are opt-in or shared and respect reduced motion.
- No logo or feature data changes.
