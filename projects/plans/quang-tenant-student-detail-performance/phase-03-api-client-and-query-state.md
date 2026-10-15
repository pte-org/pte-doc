# Phase 03: API client and query state

**Status:** Implemented; API-client typecheck passed; tests/quality skipped by user request
**Surface:** `pte-web/packages/api-client`, tenant-web data hooks/state
**Depends on:** Phase 02 stable API contract
**Blocks:** Route and tab implementation

## Goal

Expose the backend contract through typed API-client requests and predictable React Query state without hiding server-owned filters, authorization, or stale-data behavior.

## Work items

1. Add typed request/response models for detail, profile update, history, and performance using existing package conventions.
2. Add request functions and query keys scoped by tenant context, student public ID, date/status filters, date range, and pagination.
3. Add mutations for profile update and any retained status/credential actions, reusing existing action clients where possible.
4. Define invalidation rules: profile update/detail, suspend/reactivate/list row, credential action, history/performance refresh.
5. Normalize filters at the client boundary without implementing filtering locally. Debounce free-text/date input only where the existing app convention supports it.
6. Preserve API error codes/messages required by form and action feedback.
7. Add focused request serialization and response mapping tests, including omitted optional parameters and empty/insufficient states.

## Design Constraints

- API-client types mirror the final backend contract; do not create frontend-only score semantics.
- Query keys must prevent one student's data from being shown for another student while navigating between tabs.
- Do not fetch all attempts to calculate overview values.
- Do not make one report request per history row.
- Do not add a detail-page program filter in the client; the roster owns program discovery/filtering in V1.
- Keep existing student roster request types and unrelated user/platform API changes intact.
- Use the current React Query conventions and do not add a new state library.
- Profile form state is local to the account tab; server state remains the source of truth.

## Quality and Testing State

Implementation evidence: `@pte/api-client` typecheck passed. The following planned checks were skipped by explicit user request:

- request URL/parameter serialization tests;
- mutation payload allowlist tests;
- query-key/invalidation review;
- package typecheck and relevant unit tests;
- tenant-web typecheck after integration.

## Blocking gate

Phase 04 cannot start until the route can load each required resource through typed client functions and all mutation invalidation behavior is documented.

## Acceptance criteria

- No new API call is assembled ad hoc in a page component.
- History pagination and filters appear in the request exactly as the server contract defines.
- Detail history serializes only the approved date/status filters and does not duplicate the roster's program filter.
- Account mutations refresh the relevant detail/list state without clearing unrelated tab data.
- API errors can be rendered as field, action, forbidden, empty, or general errors.
