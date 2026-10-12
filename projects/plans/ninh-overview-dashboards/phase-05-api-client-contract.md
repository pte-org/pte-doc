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
- Testing: not started

## Risks
- Pre-existing type errors surface once typecheck exists: record baseline, do not fix unrelated code.
- Contract drift between backend and types: derive names from backend response records and re-check in Phase 9.
- Path rename later (Open Question 6): isolated to endpoint constants.
