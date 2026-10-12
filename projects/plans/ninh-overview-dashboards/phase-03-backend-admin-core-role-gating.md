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
- Testing: not started

## Risks
- Platform-wide user/role counts are the heaviest query: single grouped query, timeout hint, cache, EXPLAIN.
- Admin contract drift once the frontend starts: freeze section field names at the end of this phase; later phases only add sections.
- Operation policy semantics for managers: follow the existing policy exactly, covered by the role matrix test.
