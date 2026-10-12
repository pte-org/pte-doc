# Phase 6: @pte/ui Dashboard Primitives

## Requirements
`@pte/ui` gains domain-neutral building blocks: a real trend delta on stat cards, a panel with loading/error/empty slots, bar and line trend charts, an activity/attention list, missing icons and an overview loading skeleton. Priority: P1 delta, panel, bar chart, activity list, skeleton; P2 line chart and extra icons; P3 sparkline (not built here).

## Design Constraints
- Strictly additive: existing StatCard trend props, default variants of the loading state and all other defaults keep behaviour for the 6 current StatCard consumers.
- Do not modify DataTable (711 lines) or grow the shared locale provider; component text arrives via props.
- Charts use theme CSS variables only, no animation, sized parent via Tailwind, client-only, with an accessible text alternative.
- Delta meaning is not conveyed by color alone (arrow, sign and screen-reader text); null change renders a dash.
- No domain logic in the package; file <= 300 lines, component <= 150 lines.
- Verification relies on the app typecheck scripts from Phase 5 step 1.

## Steps
1. Grep all StatCard consumers and record their current usage as the regression reference.
2. Extend StatCard with optional direction, tone (good/bad/neutral) and comparison-label props, rendering an accessible delta only when supplied.
3. Add the dashboard panel: titled surface with actions plus loading, error (retry action) and empty states, props-only.
4. Extract the donut's tone color map into a shared chart tone module and add bar and line trend charts (multi-series, optional stacking, empty label, accessible fallback) on recharts.
5. Add the activity list (timeline and action-with-count variants) and the missing icons (calendar, clock, trend up/down, chart, activity).
6. Add an "overview" variant to the dashboard loading state without changing the default variant; export everything from the package barrels.
7. Run typecheck and build for both apps to confirm no regression in existing consumers.

## Success Criteria
- `pnpm --filter @pte/ui typecheck` passes.
- `pnpm --filter tenant-web lint` passes.
- `pnpm --filter vendor-web lint` passes.
- `pnpm --filter tenant-web typecheck` and `pnpm --filter vendor-web typecheck` pass (or match the Phase 5 baseline) without edits to the 6 StatCard consumer files.
- `pnpm --filter tenant-web build` and `pnpm --filter vendor-web build` succeed.
- DataTable is unchanged: `git diff --exit-code -- packages/ui/src/components/DataTable.tsx` exits 0 (run inside the pte-web repo). If that directory is not a git repository, instead compare the file hash and line count (711 lines) before and after.

## Quality and Testing State
- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

## Risks
- Chart renders zero-size on first paint: component contract requires an explicit height on the container.
- Donut regression while extracting tones: keep exports identical and check existing donut screens in the browser.
- @pte/ui has no lint script: lint is exercised through the app lint runs that import it.
- No DOM test infrastructure: visual behaviour verified in Phase 9.
