# Phase 02: Semantic tokens and light/dark theme foundation

## Objective

Make the existing PTE-adapted visual palette semantic and add a shared,
behavior-neutral light/dark runtime that both web apps can consume.

## Files and Areas

- `pte-web/packages/ui/src/styles/design-tokens.css`
- New `pte-web/packages/ui/src/theme/**` provider, hook, types, and toggle
- `pte-web/packages/ui/src/index.ts`
- `pte-web/apps/vendor-web/app/layout.tsx`
- `pte-web/apps/tenant-web/app/layout.tsx`
- `pte-web/apps/*/app/globals.css`
- `pte-web/apps/*/app/providers.tsx`

## Inputs

- Phase 01 route, behavior, and visual-consumer inventories.
- Existing token stylesheet and current light-mode screenshots.
- NextAdmin reference theme patterns, adapted without importing its runtime.

## Outputs

- `theme-contract.md`: valid values, storage key, initialization/fallback,
  root attribute, hydration/FOUC expectation, and token ownership.
- `phase-02-verification.md`: typecheck/build evidence, theme screenshots,
  logo comparison, and known limitations.

## Steps

1. Map page, shell, surface, text, border, control, focus, status, overlay,
   chart, and navigation roles to light and dark values.
2. Define a typed theme contract (`light`/`dark`) and apply a stable
   `data-theme` or equivalent root attribute without changing routes or auth.
3. Add persistence under `pte-web.theme`; accept only `light`/`dark`, fall
   back to `light` for missing/invalid values, and use a pre-paint/bootstrap
   strategy that avoids hydration mismatch and minimizes flash without a
   business request.
4. Add a common accessible `ThemeToggle` and compose it in the dashboard header
   without removing existing header actions.
5. Convert common `@pte/ui` styles from literal light-only colors to semantic
   tokens; leave feature-local migration for later phases.
6. Verify the existing PTE logo remains visually unchanged in both modes.

## Design Constraints

- No new dependency without explicit approval; prefer native React/browser
  state and existing Tailwind v4 setup.
- No API request, auth/session effect, route change, or business-state update.
- Do not globally override arbitrary Tailwind utilities in a way that hides
  incomplete feature migration.
- Preserve `prefers-reduced-motion` behavior and focus-visible styling.

## Quality and Testing State

- Quality: not evaluated.
- Testing: not started; run `@pte/ui` typecheck and both app typechecks/builds
  after implementation.

## Blocking Gate

- **PASS** when both apps use one typed theme contract, invalid storage falls
  back to light, the common shell/primitives pass light/dark checks at desktop,
  390px, and 320px, the logo is unchanged, and no auth/query behavior diff is
  found.
- **UNVERIFIED** when authenticated browser evidence is unavailable; record
  the exact route/data limitation in `phase-02-verification.md`; this blocks
  phase 03/04 unless a written waiver follows the master-plan gate policy.
- **BLOCKED** when the provider changes session/auth/query behavior, leaves
  invalid theme values undefined, or requires an unapproved dependency.

## Exit Criteria

- Both apps mount the same theme contract.
- Common shell/primitives render in light and dark at desktop, 390px, and 320px.
- Theme preference survives reload and does not affect auth/query behavior.

## Cook Record 2026-10-07

- Implementation: completed in the shared `@pte/ui` layer and both app
  layouts/providers.
- Verification: package/app typechecks and both production builds passed;
  browser theme persistence and responsive matrix were not run.
- Blocking Gate: **UNVERIFIED** because authenticated browser evidence and
  `ck:quality` were skipped at the user's request.
