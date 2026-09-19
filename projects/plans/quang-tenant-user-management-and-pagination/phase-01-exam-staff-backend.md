# Phase 01: Exam Staff backend

## Goal

Expose a tenant-scoped, bounded, filterable page of Proctor and Examiner
accounts without changing the existing all-user endpoint.

## Implemented work

1. Added `InvalidExamStaffQueryException` and a machine-readable identity error
   code.
2. Added `ExamStaffQueryService` with normalization for page, size, role,
   status, sort, direction, and search.
3. Added a repository query that joins user roles, limits records to the
   caller tenant, excludes deleted users, and returns a Spring `Page<User>`.
4. Added `GET /api/v1/users/exam-staff` to `UserController`.
5. Kept `GET /api/v1/users` unchanged because assignment consumers depend on
   its list response.

## Contract

- Default page: `0`.
- Default size: `20`.
- Maximum size: `100`.
- Supported roles: `PROCTOR`, `EXAMINER`.
- Supported statuses: `ACTIVE`, `SUSPENDED`.
- Supported sort fields: `CREATED_AT`, `FULL_NAME`, `EMAIL`.
- Response: `ApiResponse<PagedResult<UserResponse>>`.

## Tests

- `ExamStaffQueryServiceTest` covers filtering, mapping, bounded page input,
  and invalid Student-role queries.
- `UserRepositoryTest` covers tenant, role, search, and status filtering with
  H2.
- Full backend suite passed with 670 tests and zero failures/errors.
