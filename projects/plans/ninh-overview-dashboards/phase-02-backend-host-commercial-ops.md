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
- Testing: not started

## Risks
- Closed-session grading finalisation spans modules: expose only a count from facades, no cross-module joins.
- Order and subscription status flipped by scheduled jobs may lag: eventually consistent, documented.
- Support facade tempts a dependency on other modules: keep it self-contained.
