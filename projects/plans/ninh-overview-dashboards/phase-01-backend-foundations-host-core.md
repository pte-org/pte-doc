# Phase 1: Backend Foundations + Host Core

## Requirements
A new `overview` module in pte-api serves an authenticated HOST_ADMIN-only host dashboard endpoint with the shared sectioned envelope, real trends and core sections (learners, quota, academics, staff, exams, attempts incl. a 12-month series). Priority: P1 for learners, quota, exams and attempts; P3 for academics and staff (consumed by compact cards).

## Design Constraints
- The `overview` module is a leaf: it depends on other modules' public roots; no module depends on it. New facades must not extend the pre-existing attempt/session/enrollment cycle and must not add dependencies that are not already allowed.
- Facade result types live at the module root or in a declared named interface, never in internal packages.
- Cross-module reads go only through public facades; never internal repositories or entities.
- Tenant id comes only from the token; callers without a tenant are rejected; no tenant parameter exists.
- New aggregate queries are portable JPQL/derived queries (they must run on the H2 test database) with soft-delete filtering; counts and grouped counts only, never entity lists.
- Never return a percentage the backend did not compute; change is null when previous is zero.
- Month buckets use Asia/Ho_Chi_Minh (zone echoed in response meta); the current partial month is included and flagged partial.
- Caching: host core counts are NOT cached (fresh after mutations); only the heavy series is cached, TTL 30s, key = tenant id + window + schema version; cache failure never fails the request.
- Do not loosen the module-list assertion; the one-line addition of the missing exam-staff module is in scope, fixing pre-existing cycles is not.
- Migration contains indexes only and is idempotent; no entity index annotations are required (schema validation does not check indexes).
- Preflight: found module roots hold `@Service` facades with constructor DI, `@Transactional(readOnly = true)` reads, repos/entities in `internal`/`domain`, views as root records (TenancyService, StaffScheduleService, StudentQuota); `package-info` uses `@ApplicationModule(displayName, allowedDependencies)` (enrollment is restricted to shared/identity/tenancy/tenancy::domain, session/attempt/identity are open); controllers are `@RestController @RequestMapping("/api/v1...") @PreAuthorize` with a private `currentUser()` -> `CurrentUserContext.required()` and return `ApiResponse.success(..)`; 400s are `DomainException` subclasses with codes in per-module `internal/constant/<Module>Constants`; Redis is hand-rolled (`StringRedisTemplate` + Jackson-3 `tools.jackson.JsonMapper`, see PinnedSnapshotCacheService); `Clock` bean from `shared.config.ClockConfig`; tenant id in enrollment/session/attempt is the tenant public UUID from the token. Rules applied: new root facades `IdentityOverviewService`, `EnrollmentOverviewService`, `SessionOverviewService`, `AttemptOverviewService` (+ `TenancyService.countOrganizations`) returning primitives/root records/Strings only (no `identity::domain`/`session::domain` enum leakage, no new allowed dependency for enrollment); `overview` is a leaf with a unit-testable `DashboardWindow`, `TrendCalculator`, `MonthBuckets`, `DashboardSectionRunner`, `DashboardCacheKeys`, `DashboardCache`; the `windowDays` param is read as a String so a non-numeric value yields 400 (not the generic 500 handler).

## Steps
1. Record the baselines on the untouched tree: run `./mvnw -pl app test -Dtest=ModuleStructureTest > baseline-arch.txt` (stored next to the plan); the "violation set" used by every later diff is the set of lines starting `- Module`, `- Cycle detected` or `Allowed targets`, with timestamps and line numbers stripped. Also run the full suite once (`./mvnw -pl app test`) and record its totals: 1356 tests with exactly 2 pre-existing failures, both in the module-structure test, so "all new tests green" is checkable later.
2. Create the leaf `overview` module with its dependency declaration; add the missing exam-staff module and the new module to the asserted module list.
3. Define the shared envelope: per-section status (ok / error / forbidden), the period-over-period trend value, meta (generated time, validated 7/30/90-day window from the injected clock, bucketing zone), and a section runner isolating failures per section with correlation-id logging and a per-query timeout hint on heavy counts.
4. Add the cache helper (host key and 30s TTL for the heavy series, graceful fallback) with a key builder that is unit-testable for uniqueness.
5. Add read-only summary facades at module roots: identity (students by status, new in window, staff by role), enrollment (organizations, programs, active classes, unassigned learners), session (counts by status, created in window, next upcoming with enrolled vs capacity), attempt (submitted in window, in progress now, distinct active students, 12-month submitted series); reuse the existing tenancy quota lookup.
6. Add the migration (V94) with tenant-leading composite indexes for the new period queries, and a Postgres-gated migration integration test that reads its database URL from the `lifecycle.test.db.url` property (not a hard-coded host/port), enables Flyway with schema validation, and migrates from an empty schema through all migrations including the ones added by this plan (V94 now; V96 and V98 appended by later phases). Note the existing Postgres-gated test hard-codes its own address and uses the property only as an enable flag, so do not copy that pattern.
7. Compose the host dashboard service and thin controller (HOST_ADMIN only, versioned API prefix) returning learners, quota, academics, staff, exams and attempts sections.
8. Add tests: repository tests for each new query (H2), tenant isolation, trend math and month-boundary bucketing with a fixed clock (incl. zero previous and partial month), per-section failure isolation, cache key uniqueness and cross-tenant cache isolation, cache-down fallback, controller tests (200 for HOST_ADMIN, 403 for platform user, 400 for invalid window) and the architecture diff; record an EXPLAIN (index scan) for each heavy query in the phase handoff.

## Success Criteria
- Baselines exist: `baseline-arch.txt` and the recorded full-suite totals (1356 tests, 2 pre-existing failures in the module-structure test).
- Architecture: `mvnw -pl app test -Dtest=ModuleStructureTest,RouteContractTest -Dsurefire.failIfNoSpecifiedTests=true`; module-list test now passes; the violation set (lines starting `- Module`, `- Cycle detected`, `Allowed targets`, timestamps/line numbers stripped), diffed against the baseline, shows no new lines and none mentioning `overview`.
- `mvnw -pl app test -Dtest='com/pte/overview/**/*Test' -Dsurefire.failIfNoSpecifiedTests=true` passes (isolation, trend math, month boundary, section failure, cache key and cache isolation, controller tests via MockMvc with JWT: 200/403/400).
- Repository tests for new facades pass: `mvnw -pl app test -Dtest='com/pte/identity/**/*Test,com/pte/enrollment/**/*Test,com/pte/session/**/*Test,com/pte/attempt/**/*Test' -Dsurefire.failIfNoSpecifiedTests=true`.
- Migration applies on Postgres: `mvnw -pl app test -Dtest=OverviewMigrationPostgresIntegrationTest -Dlifecycle.test.db.url=jdbc:postgresql://localhost:5432/<db> -Dsurefire.failIfNoSpecifiedTests=true` passes (or compose boot with a healthy `/actuator/health`).
- Handoff contains one EXPLAIN per heavy query showing an index scan.

## Quality and Testing State
- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: passed (2026-10-13) - 170 new tests, all green (165 unit/H2 + 5 Postgres IT); full suite (without the Postgres property) 1526 tests, 0 failures, 1 pre-existing error (ModuleStructureTest.modules_have_no_boundary_violations), 46 skipped; arch violation set identical to baseline (18 lines, none mention overview). Postgres RUN against scratch PG17 (port 55439): OverviewMigrationPostgresIntegrationTest 5/5 pass (empty schema through V94, ddl-auto=validate, V94 idempotent); EXPLAIN on 7 heavy queries all use V94 indexes (Bitmap Index Scan), no seq scan - tests/phase-01-explain-plans.txt. Report: tests/phase-01-test-report.json

## Risks
- Pre-existing red architecture test hides regressions: the baseline diff is the only gate; pre-existing violations stay and are reported.
- H2/Postgres divergence in aggregate queries: keep queries to JPQL/derived forms and rely on the Postgres-gated test for migration only.
- Rolling-window "previous" overlaps data deleted since: documented limitation (no deleted-at history).

