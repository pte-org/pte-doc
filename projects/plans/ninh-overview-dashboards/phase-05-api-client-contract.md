# Phase 5: Frontend api-client Contract + App Typecheck Scripts

## Requirements
Both apps gain a `typecheck` script, and `@pte/api-client` exposes typed dashboard contracts and request functions for both dashboards matching the backend envelope. Priority: P1 (blocking for Phases 6-9 verification and for 7 and 8).

## Design Constraints
- Today neither app has a typecheck script (tenant-web: dev/build/start/lint/test; vendor-web: dev/build/start/lint). Adding the script is additive and mirrors the compiler-only check used by the packages.
- Types and request functions only; no TanStack hooks in the shared package.
- Follow the existing request module pattern: endpoint constant object, barrel re-exports.
- Sections not yet delivered by the backend are typed optional/nullable; section status is an explicit union; the percentage change is nullable.
- The contract contains no templates, platform-health, payment-link or system-notice fields; the map section is optional until Phase 10.
- Tests do not require a running backend.
- Preflight: read `requests/quota/index.ts`, `requests/billing/platformCommercial.ts` (+ its test), `requests/endpoints.test.ts`, `types/quota|support|scheduling|billing` and the backend `overview` DTO records; conventions confirmed: types folders hold type-only barrels (no runtime constants, so window constants live in `requests/dashboard`), `*_ENDPOINTS` objects already carry the full `/api/v1/...` path (client baseUrl is origin only), request functions take `client` first and return the already-unwrapped payload, and per-request tests use a fake `ApiClient` (existing enum types SessionStatus/PlanType/SubscriptionStatus/ActivationSource/QuestionStatus/QuestionPool/TicketCategory/TenantStatusResponse are reused; `AuditLogResponse` does not match the recent-activity item so `DashboardActivityItem` is dedicated).

## Steps
1. Add a `typecheck` script (compiler check without emit) to tenant-web and vendor-web and run it once to expose any pre-existing errors, and also run lint once per app, recording both typecheck errors and lint results as baselines so they are not attributed to this work.
2. Freeze the contract from the backend DTOs of Phases 1-3 (and the Phase 2 and 4 drafts): envelope, trend, meta (with bucketing zone and partial-month flag), host response, admin response and nested row types.
3. Add the dashboard types module, export it from the types barrel, and reuse existing audit-log and session-status types.
4. Add the dashboard requests module with endpoint constants (host, admin) and request functions that append the optional window parameter; export from the requests barrel.
5. Add unit tests for the request functions (path, query string, envelope unwrap) following the existing per-request tests, and make sure the endpoints test discovers the new constant.
6. Re-verify types against the live backend responses as Phases 2, 3 and 4 land and adjust additively.

## Success Criteria
- `pnpm --filter @pte/api-client test` passes (incl. endpoints test and the new request tests).
- `pnpm --filter @pte/api-client typecheck` passes.
- `pnpm --filter tenant-web typecheck` runs (script exists) and passes or matches the recorded baseline.
- `pnpm --filter vendor-web typecheck` runs (script exists) and passes or matches the recorded baseline.
- `pnpm --filter tenant-web lint` and `pnpm --filter vendor-web lint` still pass or match the recorded lint baseline.

## Quality and Testing State
- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: passed (unit, 2026-10-13; re-verified after quality remediation cycle 1: @pte/api-client now 28 files / 571 tests, 0 skipped; `DashboardSection<T>` is a discriminated union, whole-VND fixtures and precision doc comments, `@types/node` declared, conformance Java parsing moved to `beforeAll`; QUAL-002/006 deferred). @pte/api-client 28 files / 570 tests passed before the remediation (was 22 / 455; +115 new: window/endpoint/envelope/error edge cases, typed host+admin fixtures, backend contract conformance against the pte-api overview Java records, facade mapping, type-level and nullability checks); typecheck, tenant-web typecheck/test (37)/lint and vendor-web lint match baseline; vendor-web typecheck only shows the recorded corrupted `.next/dev/types/routes.d.ts` (28 errors, 0 when that file is excluded). No contract mismatch found. NOT run: live backend request (Phase 9), `next build`, @pte/ui typecheck re-run. Backend conformance tests skip (visibly) when the pte-api sources are absent; set `PTE_API_JAVA_DIR` or `PTE_API_REQUIRED=1`. Report: tests/phase-05-test-report.json

## Risks
- Pre-existing type errors surface once typecheck exists: record baseline, do not fix unrelated code.
- Contract drift between backend and types: derive names from backend response records and re-check in Phase 9.
- Path rename later (Open Question 6): isolated to endpoint constants.
