# Phase 04: Common shell, primitives, motion, and accessibility baseline

## Objective

Finish the common-first visual layer by adapting NextAdmin-inspired component
boundaries into `@pte/ui`, before migrating domain screens.

## Files and Areas

- `pte-web/packages/ui/src/layouts/**`
- `pte-web/packages/ui/src/components/**`
- `pte-web/packages/ui/src/styles/design-tokens.css`
- Shared exports in `packages/ui/src/index.ts` and component/layout barrels
- App dashboard chrome composition in both apps

## Inputs

- Phase 02 theme contract and Phase 03 locale contract.
- Phase 01 route, behavior, failure, and visual-consumer inventories.
- Pinned local reference snapshot:
  `D:\DOCUMENTFPT\Github\pte-org\nextjs-admin-dashboard`, inspected on
  2026-10-07, especially `src/app/css/default.css`, `dark.css`, the common
  shell/header toggle, cards, and tables.

## Outputs

- `nextadmin-visual-checklist.md`: shell, sidebar, header, cards, tables,
  dialogs, action menus, spacing/density, responsive states, and theme-control
  checks, with explicit PTE logo/brand exceptions.
- `common-component-contract.md`: ownership and state/accessibility contracts
  for the shared primitives.
- `phase-04-verification.md`: common package/app checks and browser matrix.

## Steps

1. Normalize shell/header/sidebar composition while keeping app-owned nav items
   and role filters.
2. Refine `DashboardCard`, `PageHeader`, buttons, fields, selects, badges,
   alerts, data tables, pagination, dropdown/action menus, dialogs, and
   loading/empty/error states around semantic tokens.
3. Add or refine shared success, stale, conflict, and presentational forbidden
   states without changing auth redirects, retry/recovery semantics, or API
   error ownership.
4. Add or refine shared tabs, stepper, drawer, section, and filter-bar
   primitives only where the density audit needs them.
5. Port short CSS-only reveal, hover, menu, and dialog motion with reduced
   motion support; do not add a motion dependency.
6. Validate focus rings, keyboard paths, dialog/menu semantics, table labels,
   state reachability, and mobile behavior at 320px and 390px in both
   themes/locales.

## Design Constraints

- Common components remain presentational; no domain queries or mutations.
- Common state components render supplied state and callbacks; they do not
  decide authorization, redirect, retry, conflict resolution, or recovery
  policy.
- Preserve existing public props unless a compatibility adapter is required.
- Do not copy NextAdmin mock data, product links, or unrelated dependencies.
- Keep the existing logo and brand copy.
- The visual checklist is acceptance evidence, not a pixel-copy requirement:
  PTE branding, navigation, route contracts, and existing data density are
  explicit exceptions to reference styling.

## Quality and Testing State

- Quality: not evaluated.
- Testing: not started; run `@pte/ui` typecheck and component/browser smoke
  checks before the first feature migration.

## Blocking Gate

- **PASS** when both apps compose the common shell/primitives, every common
  state is presentation-only, chart/overlay/status consumers are either
  token-migrated or assigned to a later owner, and the visual checklist passes
  for light/dark, vi/en, keyboard, reduced motion, 390px, and 320px.
- **UNVERIFIED** when browser or authenticated data prevents a check; name the
  missing evidence in `phase-04-verification.md`; this blocks phases 05 and 07
  unless a written waiver follows the master-plan gate policy.
- **BLOCKED** when common components acquire domain queries/mutations, change
  auth redirects/retry policy, or require an unapproved visual dependency.

## Exit Criteria

- Both apps compose one common shell and primitive layer.
- Common components pass light/dark, vi/en, keyboard, reduced-motion, and
  390px and 320px smoke checks.
- No feature behavior or route contract changes are present.

## Cook Record 2026-10-07

- Implementation: completed for the common shell, header/sidebar, auth shell,
  common surfaces, tabs, drawer, stepper, and forbidden state.
- Verification: typechecks, lint, builds, and diff checks passed; browser
  keyboard, focus, reduced-motion, theme/locale, and 320/390px checks were
  not run.
- Blocking Gate: **UNVERIFIED** because `ck:quality` and browser evidence were
  skipped at the user's request.
