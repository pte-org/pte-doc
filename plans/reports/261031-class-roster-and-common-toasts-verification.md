# Class roster and common error toasts

## Scope and cause

The class management membership endpoint reused exam eligibility queries. Those queries correctly limit exam audiences to active classes/programs within the program date range, but incorrectly hid existing class assignments before a program started. The independent assignment check still found those rows, producing a duplicate error while the class roster appeared empty.

Management memberships now use a separate tenant-scoped query with optional program filtering and deletion guards, independent of start/end dates and active status. Exam eligibility queries remain unchanged. No production program dates or membership rows were changed.

Duplicate assignment retains HTTP 409 and `STUDENT_ALREADY_IN_CLASS`, adding `data.existingClassPublicId`. The tenant client distinguishes same-class, other-class, and missing-context conflicts and shows common error toasts. Account credentials remain persisted before assignment when creating a student.

The roster cache now stores raw API memberships; the selected roster is derived again when student data changes, rather than caching a joined snapshot.

Checkout failures now use the common `@pte/ui` toast instead of an error banner; rejected mutations are caught and retry/payment navigation is preserved. Admin AI usage query failures use common toasts with duplicate suppression across rerenders and effect replay. Informational and validation states remain visible in their existing context.

## Standards and review

Applicable reading: `docs/CODING_STANDARDS_API.md`, `docs/CODING_STANDARDS_WEB.md`, `docs/API_RESPONSE_SETUP.md`, `docs/COMMON_EXCEPTION_SETUP.md`, `docs/HOST_STUDENT_IMPORT_FLOW.md`, and `docs/TEST_SCENARIOS_IAM.md`.

Independent review found a frontend/backend error-data key mismatch; the client and test fixtures were corrected to `existingClassPublicId`. Final review reported no remaining findings in this scope.

## Verification

- API `mvnw.cmd -pl app -DskipTests test-compile`: passed.
- Focused API tests: ClassServiceTest (30), ClassStudentRepositoryTest (13), ClassStudentServiceTenantIsolationTest (1), EnrollmentModuleServiceTest (6): 50 passed, zero skipped.
- Repository tests used isolated PostgreSQL 17.11 with a Hibernate-generated schema and Flyway disabled; temporary container removed. This does not validate production migrations.
- Tenant full Vitest suite: 560 passed before the three checkout tests were added.
- Final focused tenant run: membership.test.ts (8) and CheckoutView.test.ts (3): 11 passed.
- Final focused vendor run: useChatUsageErrorToast.test.ts: 3 passed.
- Tenant and vendor TypeScript checks: passed.
- ESLint for modified class, checkout, and chat usage source/tests: passed.
- `pnpm --filter tenant-web build` and `pnpm --filter vendor-web build`: passed. Both emitted the existing nonfatal warning about relative `turbopack.root`.
- Git diff whitespace checks: passed.

No browser end-to-end smoke, commit, push, or production deployment was performed for this change. The existing untracked V15 order sequence repair migration was preserved and is separate from this fix.
