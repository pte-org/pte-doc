# Phase 8: Vendor Admin Dashboard UI

## Requirements
`/admin` renders from the single admin aggregate with real trends, role-aware sections (full for platform admin/manager, content health only for academic roles incl. the legacy author alias), keeping the Vietnam map (empty-state until Phase 10) and recent tenants, and no longer downloading the full tenant list. Priority: P1 KPI row, tenant growth, status/org-type splits, needs-attention, recent tenants, greeting; P2 revenue, seat utilisation list, applications and tickets lists, licenses/subscriptions cards, content health, role-filtered quick actions; P3 plans card.

## Design Constraints
- Remove every fabricated value: fake percentage trends, progress shown as a trend, placeholder seat usage, hardcoded greeting, and the hardcoded "operating normally" system notice banner (no data source; dropped). Map shows only backend data and an empty state otherwise.
- Every admin backend section has a consumer (see plan.md map); no widget for templates, platform health, exam volume or AI queue depth.
- Sections arrive with status; forbidden hidden; error shows its own error state; academic roles (and legacy PLATFORM_AUTHOR still present in the frontend role type) get a compact content-only layout.
- Exactly one request to the dashboard endpoint per load; the detail modal fetches a single tenant on open.
- Copy in a sibling messages file (vi/en) for the dashboard, not the 1005-line admin copy dictionary; every displayed enum has both keys.
- Reuse @pte/ui as shipped; no inline styles or raw colors; component <= 150, file <= 300. vendor-web tests are `.test.ts` files.
- Role visibility uses existing permission helpers on top of (never instead of) backend section status.
- Preflight: read AGENTS.md/CODING_STANDARDS_WEB.md and Next 16 docs in node_modules/next/dist/docs/01-app/ (page.md, loading.md, error.md: page stays thin server component rendering client view, no 'use client' in page.tsx); siblings read: features/auth/permissions.ts (hasAnyRole, canManagePlatformOperations, canReviewAcademic, roleLabel), features/auth/api.ts (useCurrentUser query, CURRENT_USER_QUERY_KEY), features/tenancy/api (useTenants, getTenant), features/i18n/adminCopy.ts (63KB catalog bypassed in favour of sibling messages en.ts/vi.ts), tenant-web hostDashboard pattern (api.ts single query, typed en/vi messages, pure format/sections/trend mappers, SectionPanel error/hidden handling); vitest installed in vendor-web mirroring tenant-web node environment.

## Steps
1. Read the Next.js 16 docs, then add the dashboard api hook (query key, stale time) and install vitest in vendor-web: dev dependency, minimal node-environment config mirroring tenant-web, a `test` script, lockfile update and the package-manager build-script allowance for esbuild.
2. Add pure mappers/formatters (sections to view models, delta direction/tone, chart series) with `.test.ts` tests.
3. Replace the stat grid with the KPI row using real deltas; add tenant growth chart, status and org-type donuts, and the needs-attention list.
4. Rework recent tenants and the detail modal to use the aggregate slice plus a single-tenant fetch; feed the map from the optional map section with an empty state.
5. Add P2/P3 panels: revenue per currency, seat utilisation list, oldest applications and tickets, licenses and subscriptions cards, plans card, content health, role-filtered quick actions, greeting from the current user and locale.
6. Compose the responsive layout and the compact academic variant; delete dead fields, types and the system-notice banner from the old dashboard model.
7. Run lint, typecheck, tests and build for vendor-web, one command at a time, and fix issues.

## Success Criteria
- `pnpm --filter vendor-web lint`, `pnpm --filter vendor-web typecheck`, `pnpm --filter vendor-web test` (new setup, mapper tests pass) and `pnpm --filter vendor-web build` each pass.
- Grep confirms the old fake values (hardcoded plus-percent strings, the hardcoded greeting, the system notice banner, full tenant-list hook usage in the dashboard feature) are gone.
- Browser as PLATFORM_ADMIN shows real KPI deltas; as ACADEMIC_STAFF shows only content health with no tenants-list request in the network panel; exactly one dashboard-endpoint request per load (plus one tenant fetch when the modal opens).
- Every admin section in the plan.md map has a rendered consumer (checklist in handoff).

## Quality and Testing State
- Quality gate: approved (quality/phase-08-vendor-admin-dashboard-ui-quality-report.json)
- Testing: passed (tests/phase-08-test-report.json; 10 files / 66 passed in vendor-web)

## Risks
- Province map empty until Phase 10: empty state, no fake locations.
- Hiding the full tenant list may break widgets that silently relied on it: grep dashboard feature for remaining consumers.
- Installing vitest changes the lockfile and may need the esbuild build-script approval: do it as an isolated step.
