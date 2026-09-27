# Phase 06: API client and tenant-web query state

## Goal

Expose the paged roster contract to tenant web with typed request/response
models and predictable query/cache behavior.

## Work items

1. Resolve the duplicate `PageMeta` first. It is declared in
   `packages/ui/src/components/PaginationControls.tsx` (4 fields) and in
   `packages/api-client/src/client/client.ts:61` (8 fields). Make
   `@pte/api-client` the single definition and have `@pte/ui` accept a
   structural subset, or re-export — one source, no silent divergence.
2. Add `StudentRosterRow`, `StudentRosterQuery`, and the paged result types to
   `@pte/api-client`, including `createdAt`, `status`, authoritative
   Program/Class fields, and assignment state.
3. Add a typed request for `GET /api/admin/student-roster`, encoding optional
   filters and sort values safely. Keep page index conversion explicit if the UI
   displays pages as one-based.
4. Add `suspendUser` and `reactivateUser` request functions. Neither exists in
   `@pte/api-client` today — the current `suspend*` functions cover Class,
   Program, Organization, and Tenant only, so the IAM user endpoints have never
   had a client.
5. Add hooks/query keys whose key includes every query input: search, page, size,
   Program, Class, assignment, sort, and direction. This prevents stale pages
   from being reused under a different filter.
6. Reuse existing Program and Class API hooks for filter options. Use a
   dependent Program → Class selection; reset Class and page when Program
   changes. Avoid one request per Program merely to populate a Class dropdown.
7. Keep the query disabled only while required organization context is absent;
   once the page opens with no search text, query the first roster page.
8. Preserve the existing tenant-session API client and auth handling; do not
   introduce a second base URL or bypass the gateway.

## Design constraints

- Do not fetch all tenant users or all memberships for the Students table.
- `useClassMemberships()` stays exported and working — `features/classes`'
  `ImportOrAssignModal` depends on it to compute unassigned students.
- Query key changes must reset to page 0 for search/filter/sort changes.
- Debounce free-text search and never apply a late response to a newer query.
- Program/Class options are API data; IAM's free-text `className` is not an
  option source.
- Suspend/reactivate mutations invalidate the roster query so the badge updates
  without a reload.
- All labels and option text remain in constants for future localization.

## Quality and testing state

- Unit tests: not started; user preference is `unitest: ko`.
- Quality: approved with 0 findings; see `quality/phase-06-api-client-and-query-state-quality-report.json`.
- Required non-unit verification: `@pte/api-client` and `@pte/ui` typecheck,
  vendor-web still typechecks after the `PageMeta` change, tenant-web
  lint/typecheck, and browser network inspection proving one paged roster
  request per query.

## Acceptance criteria

- `PageMeta` has exactly one definition and both apps typecheck against it.
- Initial page calls the paged endpoint with default page, size, and sort.
- Changing page changes only the page parameter and renders returned metadata.
- Changing search/filter/sort requests page 0 and cannot display a previous
  query's rows.
- Program selection limits the Class options to the selected Program.
- Suspend and reactivate mutations refresh the roster.
- API errors and empty pages render explicit states without crashing the page.

## Cook status

- Implemented and verified with package/app typecheck and lint on 2026-09-15; unit tests skipped by explicit user preference.
- No commit or push was made.
