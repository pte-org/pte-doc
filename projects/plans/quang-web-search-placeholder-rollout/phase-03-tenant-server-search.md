# Phase 03 — Tenant Server-Paginated Search

## Goal

Make tenant search truthful across the complete dataset for learners, tickets, audit logs, orders, answers, and examiner assignment batches.

## Scope

- Learners overview using the existing student-roster search contract rather than a fixed `search: ""`.
- Tenant support tickets.
- Tenant audit log.
- Tenant orders.
- Exam answers.
- Examiner assignment batches.
- Preserve the already-correct student roster and exam-staff patterns.

## Implementation steps

1. Confirm searchable fields and backend support for each endpoint.
2. Extend API-client parameter types/request builders with optional trimmed `search` only where the endpoint supports it.
3. Update feature API hooks and query keys to include search.
4. Add controlled search state with the existing debounce convention.
5. Reset page to 0 on committed search and preserve server pagination (`clientSidePagination={false}`).
6. Disable local filtering (`clientSideFiltering={false}`) for server-owned result sets.
7. If an endpoint cannot support a complete search, explicitly hide its search control and document the reason in the feature constants/comments.

## Acceptance checks

- Search for a value known to exist on a later page returns it without manually paging first.
- Search empty restores the original total and page count.
- Changing search while on a later page never leaves the table on an invalid page.
- Network query contains the trimmed search term and no stale term is displayed as current data.
- API request tests cover encoded search parameters.

## Design Constraints

- Reuse `StudentSearchView`/`ExamStaffView` controlled-search behavior.
- Do not duplicate debounce logic in every screen if an existing feature hook/helper covers it.
- Do not expose raw API errors in the UI.
- Backend changes, if required, must remain within the endpoint’s existing authorization and tenant boundary.

## Quality and Testing State

- **Preflight:** reviewed the tenant API-client request builders and hooks, the existing controlled search patterns, and the pte-api controllers/services/repositories for roster, tickets, audit logs, orders, answers, and examiner batches; backend filters will remain tenant-scoped and UI query keys will include trimmed search.
- **Quality:** approved — six tenant server-paginated search flows use trimmed query-key state, server predicates, tenant boundaries, page reset, and disabled local filtering/pagination. Report: `pte-doc/projects/plans/quang-web-search-placeholder-rollout/quality/phase-03-tenant-server-search-quality-report.json`.
- **Testing:** passed — API-client suite 442/442, targeted pte-api search-service suite 74/74, pte-api compile, tenant typecheck/lint/tests, and tenant production build. Report: `pte-doc/projects/plans/quang-web-search-placeholder-rollout/tests/phase-03-tenant-server-search-test-report.json`.
- Planned checks: completed; interactive authenticated browser automation was unavailable in the repository tooling, so route-level HTTP smoke is recorded in Phase 05.

Phase status: completed after backend compatibility verification and tenant build checks.
