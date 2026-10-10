# Phase 01: Domain contract and permissions

**Status:** Implemented in source; focused validation skipped by user request
**Surface:** `pte-api`, API contract documentation
**Depends on:** Approved UX in `brainstorm.md`
**Blocks:** All implementation phases

## Goal

Turn the approved UX into an explicit, source-compatible contract before code is changed. Resolve ownership, authorization, historical relationship, report visibility, and testing decisions that could otherwise force a backend/frontend rewrite.

## Inputs

- `brainstorm.md` and `spec.md` in this plan folder.
- Existing identity, enrollment, attempt, session, and reporting public service boundaries.
- Existing tenant roster and report API contracts.
- Existing API response, validation, paging, and error conventions.

## Outputs

- Final endpoint/resource names and DTO fields.
- Permission matrix for `HOST_ADMIN` current-tenant access; platform-admin cross-tenant access is explicitly out of scope.
- Field ownership matrix for profile, current assignment, attempt, and report data.
- Defined report visibility and score aggregation scope.
- V1 detail history scope: date/status filters only; the roster remains responsible for program discovery/filtering.
- Backend/frontend test matrix and explicit acceptance examples.

## Work items

1. Trace the current controller/service boundary for user detail and all existing student actions.
2. Confirm the tenant-scoped lookup used for every student public ID.
3. Decide whether the composite detail read belongs in an existing public application boundary or a new read/query facade.
4. Define the profile PATCH allowlist and validation rules. Keep username, role, password, class, and program out of the baseline mutation.
5. Define attempt-history row fields, sort/filter allowlist, bounded page size, and report-state labels.
6. Define performance response fields, date scope, sample counts, insufficient-data behavior, and the fixed published-immutable report scope.
7. Confirm that V1 detail history does not require a historical program relation or snapshot migration. Record program-level detail analytics as future scope.
8. Confirm that history/performance queries are read-only and cannot trigger lazy report creation.
9. Add contract examples for success, validation failure, forbidden, cross-tenant/not-found, empty, and insufficient-data cases.
10. Record unresolved decisions in the plan before Phase 02 starts.

## Design Constraints

- Do not invent a second response envelope; follow the existing PTE API response/page/error conventions.
- Authorization is part of the contract, not a frontend capability flag.
- Keep identity, membership, attempt, and report ownership separate.
- A current program cannot stand in for an historical program.
- V1 detail history exposes date/status filters only; do not infer historical program from current membership.
- The contract must support a bounded history page and a batch aggregate without requiring one report request per attempt.
- A GET must not mutate reporting state.
- Keep new student-workspace reads and mutations restricted to `HOST_ADMIN` in the current tenant. Existing platform user-management routes are outside this feature.
- Treat unpublished/live reports as history state only; exclude them from official performance averages.

## Quality and Testing State

Contract decisions were applied to the implementation. Focused tests and the independent quality gate were skipped by explicit user request; the backend compile and frontend type/build gates are recorded in the master plan. Manual UI review remains pending.

## Blocking gate

Phase 02 cannot start until endpoint ownership, host-only tenant permission scope, profile field allowlist, published-immutable score scope, score semantics, and the V1 omission of detail-page program filtering are recorded as decisions.

## Acceptance criteria

- A reviewer can identify the authoritative source for every field rendered by the new page.
- The contract contains no password/hash field and no assignment mutation hidden inside profile update.
- Every proposed endpoint has a tenant/role rule and bounded query parameters.
- The performance contract explicitly handles missing/untested/insufficient skills.
- The detail history filter set is explicitly date/status-only for V1; program filtering remains on the roster.
