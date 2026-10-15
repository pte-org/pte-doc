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
- Preflight: sibling conventions read (Phase 3 `AdminDashboardService`, `AdminTenantSections`, `AdminCommercialSections`, `AdminSection`, `AdminVisibility`, `OverviewConstants`, `DashboardCacheKeys`, `MonthBuckets`, `TrendCalculator`, `AdminSectionData`; `BillingOverviewService`, `TenancyService`, `SupportOverviewService`, `ItembankService`, `QuestionRepository`, `OrderRepository`, `Order`; V24 and V96 migrations; Phase 3 quality report QUAL-004/011). Rules applied: QUAL-004 prep refactor first (platform tenant reads moved verbatim from `TenancyService` to a new root facade `TenancyOverviewService`; revenue goes to a new root facade `BillingRevenueOverviewService` and `BillingOverviewService` is untouched; itembank gets a new root `ItembankOverviewService` because `ItembankService` is already 806 lines and its `stats` contract stays untouched); facades are self-contained (own repository only, nested/root records, no enum or entity leak, amounts exact as `BigDecimal`, no customer/payment-provider/question-text data); revenue = status PAID + deleted false + `paidAt` half-open range grouped by currency in one portable JPQL query reused for the two windows and the 12 monthly buckets (never summed across currencies, never mixed with license activations); `AdminSection` extended by two rows (`revenue` = COMMERCIAL_READ, `questionBank` = `PlatformOperationPolicy.isPlatformCaller`) so the permission check still precedes cache and query and the visibility bucket stays the computed set (operations = every section, academic = `questionBank` only); `overview` `allowedDependencies` gains `itembank` (itembank declares no allowed list and depends on nothing that depends on overview, so no cycle); `TrendCalculator` literals 100 and 1 became named constants while `percentChange` was added for exact amounts; new classes are small (`AdminRevenueSections`, `AdminQuestionBankSections`) instead of growing the Phase 3 ones; V97 judged from the query shape (see handoff).

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
- Testing: passed (`/ck:test --unit`, 2026-10-13). Full suite 2049 tests: 1992 passed, 1 failed (pre-existing `ModuleStructureTest.modules_have_no_boundary_violations`, same 18 violations as the Phase 1 baseline, none involving overview, billing, tenancy or itembank), 56 skipped (53 earlier + 3 new Postgres-gated). 130 net-new tests; 29 tests updated for the intentional contract change (8 -> 10 sections, academic bucket none -> questionBank). Postgres-gated migration IT run on a scratch PostgreSQL 17 (15/15, through V97). EXPLAIN on 100k orders: `idx_orders_paid_at` is used by the default planner, about 6x faster for the 14-statement revenue load, so V97 is kept. Not run: frontend/Playwright, live Spring Security filter chain request, mutation testing. Report: `tests/phase-04-test-report.json`, plans: `tests/phase-04-explain-plans.txt`, architecture diff: `tests/arch/after-arch-p4-violations.txt` (identical to baseline).

## Risks
- Revenue covers online payments only: label clearly to avoid misreporting.
- Question bank counts include practice-pool items: expose the pool split so the UI can label correctly.
- Order table lacks a paid-at index: decide from evidence, not assumption.
