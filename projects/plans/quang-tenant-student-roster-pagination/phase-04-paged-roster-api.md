# Phase 04: Paged roster API

## Goal

Expose one tenant-scoped server-side query that searches, sorts, filters by
Program/Class/assignment, and paginates — without cross-database queries and
without an unbounded result.

## Work items

1. Add the paged response contract to `pte-common`, matching the frontend's
   existing `PagedResult` / `PageMeta` shape in
   `packages/api-client/src/client/client.ts:61-75`: rows in `data`, and `page`,
   `size`, `totalElements`, `totalPages`, `first`, `last`, `hasNext`,
   `hasPrevious` in `meta`. It nests inside the frozen `ApiResponse`
   `{ success, data, message }` envelope — do not alter that envelope.
2. Note the existing near-duplicate: `scoring`'s `AnswerListResponse` has a
   flattened variant of the same idea. Do not refactor it in this phase; just
   make the new common type the one future endpoints use.
3. Add `GET /api/admin/student-roster` with bounded parameters: `page=0`
   (negatives resolve to 0), `size=20` with maximum `100`, `search`,
   `programPublicId`, `classPublicId`, `assignmentStatus=ALL|ASSIGNED|UNASSIGNED`,
   `sort=CREATED_AT|FULL_NAME|STUDENT_CODE`, `direction=ASC|DESC`.
4. Implement the query as a tenant-scoped left join from
   `student_roster_entries` to `class_memberships -> student_classes ->
   programs`. The left join is safe from fan-out: `class_memberships` is unique
   on `student_public_id` globally (`ClassMembership.java:30`), so each student
   contributes at most one row and `totalElements` stays correct.
5. Validate that a supplied `classPublicId` belongs to the caller's tenant, and
   to the supplied `programPublicId` when both are present. Reject or return
   empty consistently — decide once and document it.
6. Make ordering deterministic: requested sort followed by a fixed
   `studentPublicId` tie-breaker. A page past the last page returns an empty
   `data` with correct `meta`, not an error.
7. Map sort/direction through an enum whitelist. A request value must never
   reach the order-by clause as a string fragment.
8. Return `status` on every row. There is no status filter parameter — suspended
   students appear and the client badges them (see spec rationale).
9. Leave `GET /api/admin/class-memberships` in place. It is still consumed by
   `features/classes`' `ImportOrAssignModal` through `useClassMemberships()`.

## Design constraints

- Tenant scope comes from `CurrentUser.tenantId()` only, never from a query
  parameter.
- `size` is bounded server-side; no code path returns an unbounded tenant roster.
- Search inputs are parameterized and normalized — no string concatenation into
  JPQL or native SQL.
- Invalid sort, direction, or assignment-status values produce a standard
  envelope error, not a 500 and not a silent default.
- `student_class.class_name` and IAM's profile `class_name` are not assignment
  sources.
- No gateway change is required; `Path=/api/admin/**` already routes here.

## Quality and testing state

- Unit tests: not started; user preference is `unitest: ko`.
- Quality: approved with 0 findings; see `quality/phase-04-paged-roster-api-quality-report.json`.
- Required non-unit verification: `pte-common` and `admin` compile; inspect the
  generated SQL and query plan for tenant predicate and index usage; run
  authenticated API checks for default page, boundary page, search, each filter,
  and cross-tenant ids.

## Acceptance criteria

- With 45 projection rows and `size=20`, the API returns 20, 20, and 5 rows with
  `totalElements=45`, and no row appears on two adjacent pages.
- Default response is `createdAt DESC, studentPublicId DESC`, stable across
  repeat requests with unchanged data.
- Search matches full name, email, phone, and student code.
- Program, Class, `ASSIGNED`, and `UNASSIGNED` filters are tenant-safe and
  composable, with correct `totalElements` for each combination.
- A student with no `class_memberships` row is returned under `ALL` and under
  `UNASSIGNED`.
- `size=1000` cannot produce an unbounded query.
- A Class id from another tenant returns no data and leaks no existence
  information.
- An unauthenticated caller is rejected.

## Cook status

- Implemented and compiled on 2026-09-15; unit tests skipped by explicit user preference.
- Admin container startup, unauthenticated rejection, and authenticated page,
  filter, boundary, size-cap, tie-order, and cross-tenant checks passed against
  the local Docker deployment; no commit or push was made.
