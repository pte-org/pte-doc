# Plan: Tenant user management and pagination

**Date:** 2026-09-19  
**Status:** Iteration 4 implemented locally; deployment smoke pending  
**Repository scope:** `pte-api`, `pte-web`, `pte-doc`

## Delivery summary

This session delivered a combined Exam Staff workflow for Proctors and
Examiners, added server-side pagination to the identified primary tables, and
reorganized the tenant navigation.

## Architecture decisions

1. Add `ExamStaffQueryService` rather than modifying the existing
   `UserService.listByTenant` contract.
2. Query Exam Staff directly from the tenant-scoped user repository with a
   role join and bounded `Pageable` parameters.
3. Keep Students on the dedicated student-roster API, which already provides
   server-side paging and filters.
4. Adapt Audit Log and Orders to the common paged response shape.
5. Keep compatibility hooks for checkout/payment-status consumers that still
   need a bounded order array.
6. Reorder navigation items so section headings are contiguous in the existing
   `SidebarNav` renderer.

## Phase map

| Phase | Outcome | Status |
|---|---|---|
| 1 | Exam Staff backend query, endpoint, validation, and tests | Implemented |
| 2 | API-client contract and tenant-web Exam Staff screen | Implemented |
| 3 | Pagination for learner overview, Audit Log, and Orders | Implemented |
| 4 | Users/Delivery navigation hierarchy | Implemented |
| 5 | Local verification and deployed smoke test | Implemented |

## Key implementation files

### Backend

- `pte-api/app/src/main/java/com/pte/identity/internal/service/ExamStaffQueryService.java`
- `pte-api/app/src/main/java/com/pte/identity/internal/controller/UserController.java`
- `pte-api/app/src/main/java/com/pte/identity/internal/repository/UserRepository.java`
- `pte-api/app/src/main/java/com/pte/shared/audit/AuditLogService.java`
- `pte-api/app/src/main/java/com/pte/billing/internal/service/OrderService.java`

### Frontend

- `pte-web/apps/tenant-web/features/examStaff/`
- `pte-web/apps/tenant-web/app/(dashboard)/host/exam-staff/page.tsx`
- `pte-web/apps/tenant-web/features/examoperations/components/LearnersOverview.tsx`
- `pte-web/apps/tenant-web/features/auditLog/`
- `pte-web/apps/tenant-web/features/commercialization/components/OrdersView.tsx`
- `pte-web/apps/tenant-web/lib/navigation.tsx`

### API client

- `pte-web/packages/api-client/src/requests/user/index.ts`
- `pte-web/packages/api-client/src/types/user/index.ts`
- `pte-web/packages/api-client/src/requests/admin/auditLogs.ts`
- `pte-web/packages/api-client/src/requests/billing/orders.ts`

## Delivery constraints

- No automatic commit or push was created.
- Existing user/import and assignment contracts were preserved.
- No production account or Excel import was created during browser validation.

## Plan maintenance rule

Every subsequent user-management, account, credential, CRUD, or action-menu
change MUST update this plan folder before implementation. The update records
the requested behavior, affected screens/contracts, design constraints, and
verification state. This keeps implementation and future continuation aligned
with the user's latest direction.

## Iteration 2 phase map

| Phase | Outcome | Status |
|---|---|---|
| 6 | Audit tenant/vendor CRUD rows and define common action-menu adoption | Implemented |
| 7 | Extend `@pte/ui` Dropdown into the shared action-menu contract | Implemented |
| 8 | Add safe generated-credential email endpoint and account metadata | Implemented |
| 9 | Add Exam Staff details/send-email actions and one-time credential UI | Implemented |
| 10 | Apply the common menu to audited suitable screens | Implemented |
| 11 | Run backend/frontend tests, quality review, and update this plan | Implemented locally |
| 12 | Remove Student credential-email action and enforce backend boundary | Implemented locally |
| 13 | Display account usernames and add one-time Student password generation | Implemented locally |

## Iteration 2 design constraints

- Never attempt to retrieve a password from a password hash.
- Never add plaintext passwords to `UserResponse`, notification logs, or
  persistent account records.
- A send-email action rotates the credential before queueing the email; it does
  not resend an unknown existing password.
- Preserve tenant isolation and role authorization for every account action.
- Preserve existing assignment consumers and current Student import behavior.
- Prefer the existing `Dropdown` portal/focus behavior and extend its contract
  rather than creating competing menu primitives.
- Do not convert contextual assignment/review buttons solely for visual
  consistency; keep the action discoverable and task-appropriate.
- Students retain account details and lifecycle actions but never receive the
  credential-email action; the backend enforces this independently of the UI.
- Password visibility is write/return-once only: no existing password or hash is
  exposed in list/detail responses or persisted as plaintext.

## Iteration 2 quality/testing state

- Design review: complete; no blocker found in the manual security/action audit.
- Backend targeted tests: passed; full app suite passed (694 tests, 0 failures,
  0 errors, 0 skipped).
- API-client tests: passed (225 tests).
- Tenant/vendor typecheck, lint, and build: passed; vendor lint retains one
  existing Next image warning in vendor question editor.
- `git diff --check`: passed in both repositories; only existing line-ending
  normalization warnings were reported.
- New-feature production browser smoke: pending deployment; all
  credential-changing calls must be intercepted and no persistent test data may
  be created.

## Iteration 2 implementation record

- Added `ActionMenu` as the shared row-action facade over the existing portal
  dropdown, with separator, disabled, and hidden item support.
- Applied the common menu to tenant Student Search, Exam Staff, Learners
  Overview/student roster, Orders, vendor tenancy/organization, licenses,
  license codes, plans, applications, and question bank rows. Assignment and
  answer-review controls remain contextual inline exceptions.
- Added `POST /api/v1/users/{publicId}/credentials/send-email`, which rotates a
  fresh server-generated password, sets first-login change, publishes a
  sensitive email event, and returns the credential once to the authorized
  operator.
- Added safe `username` and `mustChangePassword` metadata to user responses and
  student roster rows; no password/hash is returned by account details.
- Added Host account details and one-time credential result modals.
- Completed the manual code review with no blocker/high finding; tenant scope,
  role authorization, one-time secret handling, and action callbacks were
  checked.

## Iteration 3 implementation record

- Removed Student `Send email` UI, confirmation dialog, and generated-credential
  result flow while retaining safe account details and lifecycle actions.
- Added backend rejection before hash lookup/rotation or event publication for
  Student credential-email requests.
- Kept the credential-email action available for Proctor and Examiner rows.
- Iteration 3 targeted test passed (21 tests) and the full backend suite passed
  (694 tests); tenant typecheck, lint, and build passed.

## Iteration 4 implementation record

- Added visible `Account` columns backed by the login `username` for Student
  Search and Exam Staff.
- Added a Student-only `Generate password` action that rotates the login hash,
  marks first-login password change, and returns the fresh password once without
  publishing an email event.
- Kept Exam Staff `Send email` unchanged and retained the existing Student
  create/import one-time credential result.
- Verified no password or password hash is included in normal account/list
  responses or persisted as plaintext.
- Local verification: backend 695/695 tests passed, API client 228 tests passed,
  tenant typecheck/lint/build passed, and `git diff --check` passed in both
  repositories.
- Deployment smoke remains pending because the new credential action rotates a
  real account credential and must be tested with the production mutation
  intercepted.
