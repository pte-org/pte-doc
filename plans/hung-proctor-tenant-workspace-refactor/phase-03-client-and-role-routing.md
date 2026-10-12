# Phase 03 — Shared client and role routing

Status: pending. Dependency: 02 completed. Coverage: P1 workspace entry/list contracts; FR-01/04/14/15.

## Design Constraints

- Read pte-web AGENTS.md/CODING_STANDARDS_WEB and local Next guides before Next source edits. Actual app has no src root.
- DTO/raw REST requests in @pte/api-client; feature TanStack hooks in features/proctor. ApiResponse/page/cursor shapes match backend, no bare fetch in views.
- Administrator role HOST_ADMIN, no HOST alias. Preserve destination behavior without PROCTOR; feature capability shared by login/layout/navigation.
- Product strings through locale; flag-off PROCTOR-only lands in unavailable view rather than 404/login loop. Default flag off.

## Files

Paths relative to pte-web.

Existing:

- `packages/api-client/src/requests/endpoints.test.ts`
- `packages/api-client/src/types/index.ts`, `packages/api-client/src/requests/index.ts` (verify export barrel form)
- `apps/tenant-web/features/auth/{constants.ts,components/LoginView.tsx,components/RequireAuth.tsx}`
- `apps/tenant-web/features/proctor/{api.ts,types.ts}`
- `apps/tenant-web/lib/{navigation.tsx,navigationConstants.ts}`
- `apps/tenant-web/app/(dashboard)/proctor/{layout.tsx,page.tsx}`
- `packages/ui/src/i18n/LocaleProvider.tsx`

Proposed:

- `packages/api-client/src/types/proctoring/index.ts`
- `packages/api-client/src/requests/proctoring.ts`
- `packages/api-client/src/requests/proctoring.test.ts`
- `apps/tenant-web/features/auth/{resolveWorkspace.ts,resolveWorkspace.test.ts,components/WorkspaceSwitcher.tsx}`
- `apps/tenant-web/features/proctor/{constants.ts,queryKeys.ts,components/ProctorUnavailableView.tsx}`

## Steps

1. Resolve pnpm declared version before dependency/lockfile edits. Inspect 2–3 sibling resource exports and locale/guard conventions; encode backend contracts with correct enums/nullability and descriptive examSessionPublicId/proctorSessionPublicId naming.
2. Add assigned list, monitoring, history, close and security-audit raw requests, safe URL encoding/query options and endpoint tests. No `/api/v1/proctor/...`. Type requestId/result separately from legacy topic DTOs.
3. Replace stub hook contracts with TanStack queries using stable tenant/auth generation/session/page keys and existing HTTP session client. Disable denied polling and cancel on logout/identity lifecycle; loading versus background fetching distinct. Audit infinite paging refresh behavior preserves previous data until successful reset.
4. Add centralized allowed-workspace/destination resolver and flag capability. Exact current no-PROCTOR role matrix retained. PROCTOR-only enabled → list; disabled → unavailable authenticated state. Multi-role uses current legitimate default, allowed switcher links (no role mutation). Invalid guard target shows ForbiddenState/safe route, no login cycle.
5. Wire new Proctor nav/list landing and locale keys; keep profile intact. List page itself ships in phase 05; intermediate route can use explicit loading/availability placeholder, never fake data.
6. Run shared-client/tenant typecheck/lint/build and selected resolver/request tests if chosen. Any route references must compile and profile still accessible under capability rules.

## Success Criteria

- Endpoint and DTO contracts match backend; all retired route/stub response expectations removed or explicitly reserved presentation-only.
- Role matrix covers HOST_ADMIN/STUDENT/EXAMINER/PROCTOR singles and combinations, authenticated flag-off state and denied route behavior without loops.
- No application src root added, no hardcoded JSX product strings; existing routes unaffected for no-PROCTOR combinations.

## Build and Test Commands

From pte-web using declared pnpm: `pnpm.cmd --filter @pte/api-client typecheck`; `pnpm.cmd --filter tenant-web exec tsc --noEmit`; `pnpm.cmd --filter tenant-web lint`; build when Next route changes warrant it. Authorized tests: `pnpm.cmd --filter @pte/api-client test`; `pnpm.cmd --filter tenant-web test` (new pure tests use existing Node pattern).

## Quality and Testing State

- Quality: not evaluated. Decision: pending flags. Profile: not recorded.
- Testing: not started. Decision: pending; TDD not selected.
- If TDD selected: RED_READY role matrix + forbidden/disabled destinations + real resource request URLs/page/cursor handling.
- Risks: shared locale/API export regressions, no-PROCTOR precedence drift, flag-off redirect loop.
