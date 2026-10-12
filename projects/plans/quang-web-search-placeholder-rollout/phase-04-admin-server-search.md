# Phase 04 — Admin Server-Paginated Search

## Goal

Make admin search truthful across the complete dataset for announcements, support tickets, and license codes.

## Scope

- Admin announcements.
- Admin support tickets.
- Admin license codes.
- Existing platform-user server search remains the reference implementation and should not be regressed.

## Implementation steps

1. Confirm the admin endpoint fields that may be searched: announcement title/body, ticket identifier/subject/requester/tenant, and license code/tenant identifier as supported by the API contract.
2. Extend `@pte/api-client` request params and tests.
3. Update vendor query hooks and query keys with search.
4. Add controlled, debounced search state and reset pagination on change.
5. Keep status/plan/tenant filters separate from free-text search and include all active filters in the query key.
6. Use `clientSideFiltering={false}` and retain external pagination.
7. If license-code search cannot be safely supported because of sensitive-code rules, use a precise placeholder for the supported tenant/identifier fields or hide the free-text search.

## Acceptance checks

- Search works across pages for each admin route.
- Status/plan/tenant filters combine correctly with search.
- No license secret is placed in query keys, logs, or UI copy.
- Empty, clear, loading, error, and no-result states remain consistent.

## Design Constraints

- Use existing `useAdminCopy`, constants, and `DataTable` props.
- Preserve authorization boundaries and do not broaden admin endpoints.
- Avoid adding a second filter toolbar implementation.

## Quality and Testing State

- **Preflight:** reviewed the vendor hooks, `adminCopy`, `DataTable`, and pte-api contracts for announcements, admin support tickets, and masked license-code pages; free-text license search will be limited to safe public/tenant identifiers and never raw bearer codes.
- **Quality:** approved — announcements and support tickets search their server datasets; license-code search is restricted to safe UUID identifiers and invalid free text short-circuits without a request or secret-bearing cache key. Report: `pte-doc/projects/plans/quang-web-search-placeholder-rollout/quality/phase-04-admin-server-search-quality-report.json`.
- **Testing:** passed — API-client suite 442/442, license HTTP contract 8/8, targeted pte-api search-service suite 74/74, vendor typecheck/lint, and vendor production build. Report: `pte-doc/projects/plans/quang-web-search-placeholder-rollout/tests/phase-04-admin-server-search-test-report.json`.
- Planned checks: completed; vendor lint retains two pre-existing `@next/next/no-img-element` warnings in question-bank detail/editor files.

Phase status: completed after safe-license and controller compatibility checks.
