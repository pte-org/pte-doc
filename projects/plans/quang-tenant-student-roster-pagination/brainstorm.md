# Brainstorm: Tenant student roster pagination

**Date:** 2026-09-15

## Ideas explored

1. Client-side filtering and pagination over `GET /api/iam/users` plus the full
   class-membership list. Rejected as the production design: it transfers the
   entire tenant roster, produces weak total counts, and becomes slow as the
   roster grows.
2. Add Program/Class filters directly to IAM. Rejected because IAM owns users
   while Admin owns Programs, Classes, and memberships; this would blur the
   database/service boundary.
3. A server-side tenant-roster query/read model owned by Admin. Selected: it
   can query local Program/Class/membership data, include unassigned students,
   and return one authoritative paged result without cross-database joins.
4. Cursor pagination. Kept as a future option for exports or very large data
   sets; offset pagination is the better fit for an interactive table with
   numbered pages and a total count.

## User's direction

- The Students page must show the roster by default.
- The default order is newest-created first.
- The user can change sorting and filter by Program, Class, and assignment
  status.
- Program and Class are real API/domain data, not free-text values on the
  student form.
- Pagination must be server-side and production-quality.
- No automatic commit or push.
- Existing preference: unit tests are not required; quality review is required.

## Open questions

- Confirm default page size (recommended: 20; maximum: 100).
- Confirm whether Class is a dependent filter that requires selecting a
  Program first (recommended to avoid loading every Class for every Program).
- Confirm the one-time projection backfill mechanism for users already present
  in IAM (recommended: an idempotent, authenticated rebuild operation after
  deployment).

## Risks

- The read model is eventually consistent with IAM events. The UI needs a
  bounded refetch/sync state after creating a student.
- Existing `class_name` profile text is not an assignment. It must not be used
  as the source for Program/Class filters.
- Production currently documents `ddl-auto=update` as dev-only; the projection
  table requires an explicit, idempotent deployment migration.
