# Phase 03: Primary-table pagination

## Goal

Remove unbounded primary-table reads identified during the pagination audit.

## Implemented work

### LearnersOverview

- Reused `useStudentRoster` instead of loading the full tenant user list.
- Added the existing `PaginationControls` component.
- Kept reset-password behavior using the student roster public id.

### Audit Log

- Changed repository/service/controller reads to accept `page` and `size`.
- Returned `PagedResult<AuditLogResponse>`.
- Added page state and filter reset behavior in the tenant UI.

### Order history

- Changed the backend order query to return a bounded `Page<Order>`.
- Added `useOrdersPage` for the paginated history screen.
- Preserved a bounded array hook for checkout/payment-status consumers.

### Existing paged screens

- The main Students screen already had server-side pagination, filters, sort,
  and page-size controls; it was preserved.
- The Answers review screen already had pagination; it was preserved.

## Deliberate boundaries

Small contextual assignment lookups and legacy list endpoints were not changed
in this phase because they are not the primary large table surfaces and their
current array contracts are shared by assignment workflows.
