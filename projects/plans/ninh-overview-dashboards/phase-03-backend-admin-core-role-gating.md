# Phase 3: Backend Admin Core + Role Gating

## Requirements
A platform admin dashboard endpoint returns tenants (with a 12-month growth series), learners (with top seat utilisation), recent tenants, pending applications, licenses, subscriptions, plans and support, each gated by an explicit permission. Priority: tenants, learners, recent tenants, applications, growth series P1; licenses, subscriptions, support, utilisation P2; plans P3.

## Design Constraints
- Depends on Phase 2: extend the billing and support facades created there; do not create parallel facades.
- Section-to-permission table (authoritative; each section is checked independently, a failed check returns forbidden status with no data and HTTP stays 200):

| Section | Required permission |
|---|---|
| tenants, learners, recentTenants | tenant read |
| applications | application read |
| licenses | masked license read (counts only, no secrets) |
| subscriptions, plans | commercial read / plan read-all |
| support | support read |
| questionBank (row added by Phase 4) | any valid platform caller (platform-caller check) |
| revenue (row added by Phase 4) | commercial read |
| map (row added by Phase 10) | tenant read |

This phase implements only the rows for tenants, learners, recentTenants, applications, licenses, subscriptions, plans and support; the table is extended, not rewritten, by Phases 4 and 10.

- The controller itself rejects callers carrying a tenant id (HOST_ADMIN gets 403) and non-platform callers; it does not rely on a bare role annotation alone.
- Cache TTL 60s; key = visibility bucket + window + schema version, where the bucket is the COMPUTED visibility set (operations vs academic) derived from the permission checks, not the raw role (legacy PLATFORM_AUTHOR canonicalizes to ACADEMIC_STAFF). Mutations may show after up to one TTL (documented).
- Recent tenants, plan names, student counts, seat limits and expiries use batched/grouped queries; the per-tenant quota lookup is never called in a loop.
- Distinct-student query shape: one grouped count of students per tenant joined in memory with seat limits; active learners = count of distinct student identifiers with an attempt started in [window start, now) (and the previous window), not deleted, using the started_at index.
- License counts reuse the derived-expired rule for issued codes past expiry.
- Month growth series bucketed in Asia/Ho_Chi_Minh, partial current month flagged. All queries portable JPQL/derived. Tenant status and seat utilisation have no trend.
- Facades must not extend the pre-existing cycle; DTOs at module root or named interface.
- Preflight: sibling conventions read (Phase 1/2 `HostDashboardService`, `HostOperationsSections`, `DashboardCache(+Keys)`, `Memo`, `TrendCalculator`, `MonthBuckets`, `DashboardSectionRunner`, `HostDashboardController`; `BillingOverviewService`, `SupportOverviewService`, `IdentityOverviewService`, `AttemptOverviewService`, `TenancyService`; `PlatformOperationPolicy`/`SecurityPolicy`/`ResourceServerJwt`; quality reports of Phases 1-2). Rules applied: billing/support facades EXTENDED (nested root records, no domain-enum leak, license data = counts only, support list = ids/category/age only), tenancy extended on `TenancyService` with root records (`PlatformTenantCounts`, `RecentTenantView`, `TenantSeatLimit` via JPQL constructor expression), identity gets one grouped students-per-tenant query (own module-local 2s hint constant), attempt gets a platform-wide distinct-student count reusing `ExamAttemptRepository.OVERVIEW_QUERY_TIMEOUT_MS`; no new `allowedDependencies` on any module (overview already lists tenancy/identity/attempt/billing/support); section->permission table is the `AdminSection` enum (one predicate per section over `PlatformOperationPolicy`), visibility is computed once per request (`AdminVisibility`) and its sorted allowed-section set is the cache bucket; admin cache = per-section, 60s, key `dash:admin:v1:{bucket}:{window}:{section}`, permission check precedes any cache/query so a FORBIDDEN section is never cached or computed; controller rejects non-platform callers via `PlatformOperationPolicy.isPlatformCaller` (HOST_ADMIN with a tenant id -> 403); the one grouped student count is a per-request `Memo` shared by learners and recentTenants; V96 indexes only, idempotent, partial on `deleted = false`; BillingOverviewService constructor gained two repositories, so the single fixture `BillingOverviewQueriesTest` was updated minimally.

## Steps
1. Extend facades: tenancy (counts by status and organization type, new in window, 12-month creation series, most recent N tenants), identity (grouped students per tenant and platform total), billing (license state counts incl. expiring soon and redeemed in window; subscriptions active/expiring/activated with source split; plan counts; applications pending with oldest-first list and received-in-window), support (platform-wide open/in-progress, opened in window, oldest open tickets).
2. Add the platform-wide active-learner count with trend and the top-utilisation list (students vs seat limit) built from the grouped counts.
3. Add migration V96 with idempotent platform-wide indexes: attempts by started_at and by submitted_at (partial on not deleted), subscriptions (status, expires_at), support (status, created_at), applications (status, created_at), tenants created_at; extend the Postgres-gated migration test.
4. Build the admin dashboard service with per-section permission checks following the table, and the controller with the tenant-id rejection, window validation and visibility-bucket cache.
5. Compose recent tenants (plan name, student count, seat limit, subscription expiry) via the batched facades.
6. Add tests: role matrix per section (platform admin full, manager per its operations, academic manager/staff and legacy author alias see only allowed sections), controller tests (200 platform roles, 403 HOST_ADMIN and anonymous), cache key uniqueness and bucket isolation (academic never receives an operations payload), batched query count for recent tenants, license derived-expiry rule, month boundary with fixed clock, architecture diff; record EXPLAIN for the platform-wide attempt, subscription and user-role counts.

## Success Criteria
- `mvnw -pl app test -Dtest='com/pte/overview/**/*Test,com/pte/tenancy/**/*Test,com/pte/billing/**/*Test,com/pte/support/**/*Test,com/pte/identity/**/*Test,com/pte/attempt/**/*Test' -Dsurefire.failIfNoSpecifiedTests=true` passes.
- `mvnw -pl app test -Dtest=ModuleStructureTest,RouteContractTest -Dsurefire.failIfNoSpecifiedTests=true`: violation output diffed against the Phase 1 baseline has no new violations and none involving `overview`.
- MockMvc/JWT controller tests: PLATFORM_ADMIN all Phase 3 sections OK; ACADEMIC_STAFF gets them FORBIDDEN with null data and status 200; HOST_ADMIN gets 403.
- Postgres-gated migration test with V96 passes: `mvnw -pl app test -Dtest=OverviewMigrationPostgresIntegrationTest -Dlifecycle.test.db.url=jdbc:postgresql://localhost:5432/<db> -Dsurefire.failIfNoSpecifiedTests=true`; EXPLAIN evidence (index scan) for each heavy platform-wide query is in the handoff.

## Quality and Testing State
- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: passed (`/ck:test --unit`, report `tests/phase-03-test-report.json`): 309 new tests, 0 failed. Full suite 1919 tests = 1865 passed, 1 failed (pre-existing `ModuleStructureTest.modules_have_no_boundary_violations`, 18 normalized violations identical to the Phase 1 baseline, none in overview/billing/support), 53 skipped (Postgres-gated). Postgres IT run and passed 12/12 on a fresh empty scratch PG17 through V96 (six V96 indexes verified partial and idempotent; scratch container removed); EXPLAIN in `tests/phase-03-explain-plans.txt`: every V96-targeted query uses its index, and the grouped students-per-tenant query (PERF-001) is RESOLVED by `count(u.id)`: it still seq-scans both tables (inherent) but is now a HashAggregate with no sort/spill, 56 ms vs 108 ms at 100k students (exactness relies on no duplicate (user_id, role) row); re-run on a fresh scratch PG17 after the cook edits (platform-wide attempt method renamed `countDistinctActiveStudentsPlatformWide`, tests updated). Remaining: four status-less created_at/redeemed_at range counts are seq scans at current volumes (PERF-002, LOW). Phase 1 EXPLAIN seed changed to 20 tenants (assertions unchanged). NOT run: pte-postgres (host port 5432 is a native Windows postgres), frontend/Playwright, a full-context HTTP request through the real filter chain, mutation testing.

## Risks
- Platform-wide user/role counts are the heaviest query: single grouped query, timeout hint, cache, EXPLAIN.
- Admin contract drift once the frontend starts: freeze section field names at the end of this phase; later phases only add sections.
- Operation policy semantics for managers: follow the existing policy exactly, covered by the role matrix test.
