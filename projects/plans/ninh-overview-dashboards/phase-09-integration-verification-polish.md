# Phase 9: Integration Verification, States and Polish

## Requirements
Both dashboards are verified end to end against the real backend per role, with route-appropriate loading and error states, a responsive and accessibility pass, and the typed contract confirmed against real responses. Priority: P1 (release gate).

## Design Constraints
- Only fixes and polish; no new widgets or contract changes beyond additive corrections.
- Inspect existing route files first and add or override only where needed. Existing area-wide loading files (host area loading, admin area loading) and the app-level dashboard error files serve many pages: do not change them for dashboard-specific skeletons; add dashboard-specific files only where a dedicated route segment exists (the host dashboard segment), and use the in-view overview skeleton on query loading for the admin root.
- Route error boundaries use the retry mechanism documented for Next.js 16 and fixed recovery copy, no technical details.
- Verification is lint, typecheck, unit tests, build and a documented browser pass; no new DOM test infrastructure.
- Do not modify shared defaults other screens rely on.
- Preflight: read AGENTS.md/CODING_STANDARDS_WEB.md and Next 16 docs in node_modules/next/dist/docs/01-app/03-api-reference/03-file-conventions/ (loading.md Suspense boundary, error.md Client Component error boundary with reset/retry); existing route file inventory: area-wide loading files (apps/tenant-web/app/(dashboard)/host/loading.tsx with detail variant, apps/vendor-web/app/(dashboard)/admin/loading.tsx) serve multiple subpages and remain untouched; app-level dashboard error files (apps/tenant-web/app/(dashboard)/error.tsx and apps/vendor-web/app/(dashboard)/error.tsx) serve broad dashboard routes and remain untouched; segment-specific loading.tsx and error.tsx added to dedicated host dashboard route segment app/(dashboard)/host/dashboard; admin root route app/(dashboard)/admin uses in-view overview skeleton and error state inside AdminDashboardView with query retry; verification across all workspaces via pte-web and pte-api suites.

## Steps
1. Inventory the existing loading and error files (vendor app dashboard error, vendor admin loading, tenant host loading, both app-level dashboard errors) and decide per file: keep, or add a segment-specific file for the host dashboard route (loading with the overview skeleton, error with retry).
2. Run backend and frontend together and compare each live response with the typed contract (all sections, nullable change values, forbidden sections, partial-month flag, bucketing zone); apply additive fixes.
3. Verify roles: HOST_ADMIN, PLATFORM_ADMIN, PLATFORM_MANAGER, ACADEMIC_MANAGER, ACADEMIC_STAFF (and the legacy author alias), including a tenant with no data, a forced section failure, and a real Redis-down case (stop the cache container, confirm degraded but successful responses, restart).
4. Responsive check at mobile, tablet and desktop widths plus dark-mode check for charts and deltas; confirm one dashboard-endpoint request per load.
5. Accessibility pass: heading order, chart text alternatives, delta not by color alone, keyboard focus, link target sizes, reduced motion.
6. Run the complete verification suites and record exactly what passed, the baseline diff for architecture tests, and known limitations (including pre-existing cycles and the optional province phase).

## Success Criteria
- Backend: `mvnw -pl app test` full run compared with the Phase 1 baseline (1356 tests, exactly 2 pre-existing failures, both in the module-structure test): the only failures are those same 2, all added tests are green, and the architecture violation set (lines starting `- Module`, `- Cycle detected`, `Allowed targets`, timestamps/line numbers stripped) has no new lines and none involving `overview`; Postgres-gated migration test passes.
- Frontend, each as its own command: `pnpm --filter @pte/api-client test`, `pnpm --filter @pte/api-client typecheck`, `pnpm --filter @pte/ui typecheck`, and for both `tenant-web` and `vendor-web`: `lint`, `typecheck`, `test`, `build`.
- File check: `apps/tenant-web/app/(dashboard)/host/dashboard/loading.tsx` and `error.tsx` exist (if step 1 decided to add them) and area-wide `host/loading.tsx` and both app-level `(dashboard)/error.tsx` files are unchanged; the admin root uses the in-view overview skeleton.
- Browser pass documented for the six role cases and three widths: no horizontal page scroll, no console errors, exactly one dashboard-endpoint request per load (LearnersOverview roster request excluded); forced failure shows the retry boundary and retry works.

## Quality and Testing State
- Quality gate: APPROVED (reviewed in quality/phase-09-integration-verification-polish-quality-report.json)
- Testing: passed (unit; documented in tests/phase-09-test-report.json and tests/phase-09-integration-checklist.md)

## Risks
- Seed data may not cover all states (expiring subscriptions, failed scoring): use local fixtures or temporary mocked responses for visual checks only, not committed.
- Cross-role manual verification is slow: use a role checklist and record results in the handoff.
- Findings may need backend changes: treat them as additive fixes within the earlier phase's scope.
