# Phase 5: Enrollment & Proctor Assignment

## Requirements

Let a Host administrator find eligible users, enroll a student into a selected
session, and assign a proctor while keeping `HOST_AUTHOR` behavior aligned with
the stricter IAM/scheduling permissions.

Maps to: **P1 Story #6 (enrollment and proctor assignment) | FR-11, FR-17,
FR-18**

## Design Constraints

- Extend `scheduling` for enrollment/assignment commands; introduce a narrow IAM
  user-lookup repository/data source without moving IAM administration into the
  scheduling domain.
- IAM `/api/iam/users` lookup and scheduling proctor assignment are
  `HOST_ADMIN` operations. Hide or disable those controls for `HOST_AUTHOR`.
- UI role gates use `HostAccessPolicy`; the backend still validates every
  command and tenant relationship.
- Enrollment and proctor assignment currently expose POST commands only. Phase
  5 does not add list endpoints unless runtime/UI evidence proves the approved
  workflow cannot be completed from session/user context plus command response.
- User search results expose only fields returned by the current IAM response;
  no client-side tenant override or cross-tenant lookup is supported.
- Commands are single-flight and handle duplicate/conflict/not-found/
  forbidden outcomes without clearing the selected session/user unnecessarily.

## Steps

1. Re-check IAM user-list response/filter capability and role annotations plus
   scheduling enrollment/proctor request/response DTOs and service validation.
2. Define minimal user-summary, enrollment input/result, and proctor-assignment
   input/result domain types.
3. Add a focused IAM user lookup interface owned at the Host boundary and extend
   `SchedulingRepository` with enroll/assign commands.
4. Implement data models/repositories with exact gateway request tests, tenant
   omission assertions, and 403/404/409 propagation.
5. Implement admin-only user lookup BLoC with search/loading/empty/loaded/failure
   states and cancellation/debounce if the backend supports query filtering.
6. Implement enrollment and proctor-assignment BLoCs as separate command flows
   with idle/submitting/success/failure states.
7. Build participant/proctor action panels on session detail; show a clear
   permission explanation or omit actions for `HOST_AUTHOR`.
8. Build user selection and explicit confirmation before enrollment/assignment;
   prevent duplicate requests and preserve selection on recoverable failure.
9. Evaluate the approved workflow using POST responses. If an assignment cannot
   be re-rendered after success, document concrete evidence and obtain approval
   before planning any backend GET endpoint.
10. Add role, repository, BLoC, and widget tests for admin success, Host-author
    denial, conflict/not-found, duplicate submission, and selection
    preservation.
11. Run all scheduling/Host regressions, analysis, full suite, and runtime
    admin-versus-author contract checks.

## Success Criteria

- [x] `HOST_ADMIN` can select an eligible student and successfully enroll them
      in a session.
- [x] `HOST_ADMIN` can select an eligible proctor and successfully assign them
      to a session.
- [x] `HOST_AUTHOR` is never presented with an action that predictably fails
      due to current IAM/proctor-assignment authorization.
- [x] Requests contain no client-selected tenant override and cross-tenant
      resources are not exposed.
- [x] Duplicate/conflict/not-found/forbidden states preserve useful UI context
      and do not cause false logout.
- [x] No new enrollment/proctor GET endpoint is added without evidence and Hung
      approval.
- [x] Phase-5 tests, prior regressions, analysis, and full suite pass; role
      contract evidence is recorded.

## Quality and Testing State

- Quality gate: approved. Report:
  `quality/phase-05-enrollment-and-proctor-quality-report.json`.
- Testing: passed with runtime role checks pending. Evidence:
  `tests/phase-05-enrollment-and-proctor-test-report.json`.

## Risks

- **HIGH:** Scheduling permits some Host-author actions while IAM lookup and
  proctor assignment are admin-only, creating an asymmetric role experience.
  Mitigation: align each action independently with its owning backend
  authorization rather than treating “Host” as one capability set.
- **MEDIUM:** POST-only assignment contracts make later session-detail
  reconstruction less convenient. Mitigation: complete the approved command
  workflow first and require runtime evidence before expanding backend scope.
- **MEDIUM:** User-list responses may be large or lack server-side search.
  Mitigation: consume only available filters and avoid client pagination claims
  the backend cannot honor.
