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
- Preflight: read StatCard, StatusDonutChart, CircularProgressChart, DashboardCard, EmptyState, ErrorState, Skeleton, DashboardLoadingState, Button, Badge, BackButton/Breadcrumbs/SidebarNav and design-tokens.css first. @pte/ui does not import next/link (siblings take a `renderLink` adapter with a native `<a>` default), uses theme CSS variables only (`var(--action|sky-action|mint-action|cream-action|blush-action|ink-*|shell-border|surface-*)`), `cn()` does not merge conflicting Tailwind classes, `icons.tsx` is already 331 lines so new icons live in `dashboardIcons.tsx`, and lint does not cover packages/ui (it is only reachable through the app builds).

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
- Remediation cycle 1 (2026-10-13, after quality CHANGES_REQUIRED QUAL-001..011): QUAL-001 `accessibilityLayer={false}` on BarChart/LineChart (svg no longer a role=application tab stop inside role=img); QUAL-002 trend-chart empty state is now plain `role="status"` text (donut untouched); QUAL-003 `buildRows` exported, partial in the middle reconnects to the next complete point, lone/any partial point gets a hollow marker on the dashed line; QUAL-004/005 JSDoc (`label` unique per datum, untoned series = brand tone) + additive `allowDecimals?: boolean` (default false = unchanged); QUAL-007 JSDoc (tone is colour only, put evaluative text in `changeDirectionLabel`/`title`). Deferred to the user: QUAL-006 (vendor-web tsconfig rewritten by `next build`), QUAL-008..011. Re-test: @pte/ui 12 files / 271 tests passed; quality `--verify` pending. Details: tests/phase-06-test-report.json `remediation_cycle_1`.
- Testing: passed (unit, 2026-10-13; counts below are the original 250 and were 271 after remediation cycle 1). @pte/ui gained its first test infrastructure (vitest ^3.2.7 + @types/node ^20 devDependencies, `test` script, node-environment `vitest.config.ts`; components rendered with `renderToStaticMarkup`, no DOM library): 0 -> 11 files / 250 tests, 0 failed, 0 skipped (StatCard regression + delta, DashboardPanel, ActivityList, TrendBarChart/TrendLineChart server render + recharts-stubbed prop/partial-segment checks, chartTones/StatusDonutChart alias, icons, DashboardLoadingState default-vs-overview, barrel). Mutation sanity: 6 deliberately broken copies (delta always shown, swapped tones, sr-only table formatter/partial/caption, line partial split) each failed the intended tests. @pte/ui typecheck (tests included), tenant-web typecheck/test (37)/lint, vendor-web lint (same 2 warnings), vendor-web typecheck (0 errors; `next build` regenerated the corrupted `.next/dev` reference, so the 28-error baseline no longer reproduces) and @pte/api-client test (571) pass; the 6 StatCard consumers and DataTable.tsx (711 lines) are SHA256-identical. Not run: real browser rendering of recharts (sizing, hover tooltip, dashed/lighter partial paint) and visual donut regression -> Phase 9. Report: tests/phase-06-test-report.json

## Risks
- Chart renders zero-size on first paint: component contract requires an explicit height on the container.
- Donut regression while extracting tones: keep exports identical and check existing donut screens in the browser.
- @pte/ui has no lint script: lint is exercised through the app lint runs that import it.
- No DOM test infrastructure: visual behaviour verified in Phase 9.
