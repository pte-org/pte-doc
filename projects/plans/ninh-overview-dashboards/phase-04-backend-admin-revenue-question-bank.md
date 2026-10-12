# Phase 4: Backend Admin Revenue + Question Bank

## Requirements
The admin dashboard gains per-currency online revenue (with a 12-month series) and extended question bank stats (visible to all four platform roles, the content-health panel). Priority: question bank P2; revenue P2. Templates and platform-health sections are intentionally NOT built (no widget consumes them).

## Design Constraints
- Revenue is per currency, paid orders only, labelled online revenue; never summed across currencies, never mixed with license-code activations; commercial-read permission only.
- Question bank section is visible to any valid platform caller; the existing question-stats endpoint keeps its contract and is untouched.
- Month series use Asia/Ho_Chi_Minh with the partial current month flagged; queries are portable JPQL/derived.
- This phase adds the questionBank and revenue rows to the Phase 3 section-to-permission table. Sections go through the Phase 3 gating, runner and visibility-bucket cache; the new sections must not change bucket semantics.
- Do not promise an approval-time trend unless the provenance data is verified to contain a timestamp.
- Extend existing billing and item bank facades; no new module dependencies or cycles.

## Steps
1. Add the billing revenue summary: paid orders per currency for current vs previous window, paid order count trend and a 12-month series.
2. Decide from an EXPLAIN whether a paid-at index is needed and add it in V97 only if so; extend the Postgres-gated migration test.
3. Extend the item bank facade with an overview: counts by status, skill section and pool, created-in-window trend; keep the old stats method intact; verify and record whether approval timestamps exist.
4. Wire both sections into the admin dashboard service with gating (commercial read; platform caller) and verify the cache bucket still separates operations from academic payloads.
5. Add tests: per-currency math with fixed clock and month boundary, question bank visibility for all four roles, old stats endpoint unchanged, revenue FORBIDDEN for academic roles, controller tests, architecture diff.

## Success Criteria
- `mvnw -pl app test -Dtest='com/pte/overview/**/*Test,com/pte/billing/**/*Test,com/pte/itembank/**/*Test' -Dsurefire.failIfNoSpecifiedTests=true` passes.
- `mvnw -pl app test -Dtest=ModuleStructureTest,RouteContractTest -Dsurefire.failIfNoSpecifiedTests=true`: no new violations versus the Phase 1 baseline, none involving `overview`.
- MockMvc/JWT test: ACADEMIC_MANAGER receives question bank OK and every operations section (incl. revenue) FORBIDDEN; PLATFORM_ADMIN receives revenue OK.
- If V97 was added: Postgres-gated migration test passes with the same command as Phase 3; EXPLAIN for the revenue query recorded in handoff.

## Quality and Testing State
- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

## Risks
- Revenue covers online payments only: label clearly to avoid misreporting.
- Question bank counts include practice-pool items: expose the pool split so the UI can label correctly.
- Order table lacks a paid-at index: decide from evidence, not assumption.
