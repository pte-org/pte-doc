# Phase 2: Backend Host Commercial and Ops Sections

## Requirements
The host dashboard endpoint additionally returns grading backlog, subscription/expiry state, pending order count, own support tickets and recent audit activity, completing the host contract. Priority: subscription/expiry and grading backlog P1; recent activity P2; support and order cards P3 (compact widgets).

## Design Constraints
- This phase creates the billing and support summary facades; Phase 3 extends them (one facade owner per module).
- The support module has no public root service today; add one thin facade there without making support depend on billing or scoring.
- Grading and answer queries are grouped counts only, portable JPQL/derived (run on H2).
- Plan names are resolved inside billing in a batch, never per row.
- Pending orders are returned as a count only: payment links are NEVER returned or cached; the UI links to the existing billing page.
- Recent activity reuses the existing tenant-scoped audit listing (page size 8); no new audit storage. Only the grading backlog is cached (30s host cache key from Phase 1); the reporting-awaiting-publication count, recent activity, subscription, order and support sections are UNCACHED.
- New facades must not create or extend module cycles; DTOs at module root or a named interface.
- The host contract is frozen at the end of this phase; later changes are additive.
- Preflight: sibling conventions read (Phase 1 `SessionOverviewService`/`EnrollmentOverviewService`/`IdentityOverviewService`, `HostDashboardService`, `DashboardCache(+Keys)`, `AuditLogService`). Rules applied: new root `@Service` facades `ScoringOverviewService`, `ReportingOverviewService`, `BillingOverviewService` (+ root `CurrentSubscriptionView`), `SupportOverviewService` (self-contained, own repository only) using only their own module's repositories and returning nested/root records or strings (no domain enum leak); scoring/reporting/billing declare no `allowedDependencies` and support's list is untouched (no outbound dependency added); `overview` allowedDependencies extended with exactly scoring, reporting, billing, support (audit lives in OPEN `shared`, already allowed); grouped counts via portable JPQL with `deleted = false`; plan names in one `findByPublicIdIn` batch; days-to-expiry from the injected `Clock`; `AuditLogService.recent(tenantId, size)` added (no count query, soft-delete filtered) and mapped to action/actor id/target type/time only; only the grading backlog is cached (30s, `DashboardCacheKeys.host(..., "grading")`); `billing` kept as its own section (pendingOrders only) per the plan's section map; V95 added for the two uncached per-request queries that had no usable index (reports unpublished by tenant, audit newest-by-tenant).

## Steps
1. Add a scoring summary facade: pending, AI-scoring and failed answer counts for a tenant and the number of closed sessions awaiting grading finalisation.
2. Add a reporting summary (reports awaiting publication); decide from an EXPLAIN whether a tenant+published index is needed and add it in V95 only if so.
3. Add the billing summary for a tenant: current subscriptions with plan name, type and expiry, nearest expiry, days to expiry, expiring-soon flag, and pending order count.
4. Add the support summary facade at the support module root: open, in-progress and resolved-awaiting-close counts for the tenant.
5. Wire recent activity and the new sections into the host dashboard service with per-section isolation.
6. Add tests: repository tests (H2) for each new query, subscription expiry boundaries with a fixed clock, tenant isolation per facade, a failing scoring section leaving others OK, plan-name batching, an assertion that the response contains no payment link field, and the architecture diff.

## Success Criteria
- `mvnw -pl app test -Dtest='com/pte/overview/**/*Test,com/pte/billing/**/*Test,com/pte/support/**/*Test,com/pte/scoring/**/*Test,com/pte/reporting/**/*Test' -Dsurefire.failIfNoSpecifiedTests=true` passes.
- `mvnw -pl app test -Dtest=ModuleStructureTest,RouteContractTest -Dsurefire.failIfNoSpecifiedTests=true`: violation output diffed against the Phase 1 baseline shows no new violations and none involving `overview`, `billing` or `support` additions.
- A MockMvc controller test using a named seeded fixture asserts HOST_ADMIN gets all eleven sections OK and tenant B data never appears in tenant A's response.
- If V95 was added, the Postgres-gated migration test from Phase 1 still passes; EXPLAIN for the grading counts is recorded in the handoff (index scan).

## Quality and Testing State
- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: passed (2026-10-13, `/ck:test --unit`; re-verified after the QUAL-001 fix and the LOW cleanups: latest FULL suite 1610 tests, 1559 passed, 1 pre-existing error, 50 skipped; overview+shared 204 tests green; architecture diff 0; Postgres not re-run, no migration or query change): 84 new tests (80 H2/Mockito/MockMvc + 4 Postgres-gated), including `AuditLogServiceRecentNullTenantTest` (recent(null) throws NPE, repository untouched), `MemoTest` and the academicCounts once-per-build tests; full suite 1600 tests = 1549 passed, 1 pre-existing error (ModuleStructureTest.modules_have_no_boundary_violations, violation set identical to baseline, 0 new, none involving overview/billing/support), 50 skipped (46 earlier + 4 new Postgres-gated, which were run separately and passed 9/9 through V95 on a scratch PG17, since removed). EXPLAIN: all Phase 2 queries use an index, V95 indexes used by the default planner. NOT run: the user's `pte-postgres` (host port 5432 is held by a native Windows postgres; scratch container used instead). Report: tests/phase-02-test-report.json; plans: tests/phase-02-explain-plans.txt.

## Risks
- Closed-session grading finalisation spans modules: expose only a count from facades, no cross-module joins.
- Order and subscription status flipped by scheduled jobs may lag: eventually consistent, documented.
- Support facade tempts a dependency on other modules: keep it self-contained.
