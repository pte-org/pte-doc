# Phase 1: Staff username and e-mail rules

## Requirements
New staff accounts (HOST_ADMIN, PROCTOR, EXAMINER, ACADEMIC_MANAGER, ACADEMIC_STAFF) get a generated `{tenant.code}.{random}` username and a separate account per organization; their e-mail only has to be unique inside the organization. Existing accounts are not touched, so the phase works on the current multi-organization tables and ships alone.

Objective in one line: stop creating or reusing staff accounts by e-mail across organizations.

Ordering: this phase ships AFTER or IN THE SAME DEPLOY as phase 2 (reset by e-mail + username), so the forgot form already asks for the username when generated staff usernames appear. Staff who lose the welcome e-mail ask their Host for the username (plan Q8); the welcome e-mail must therefore show the username clearly (step 4).

## Files to change (verified to exist unless marked)
API, under `pte-api/app/src/main/java/com/pte/`:
- `identity/internal/service/user/UserAccountProvisioner.java` — staff branch (~lines 77-86) reuses an account by e-mail across organizations; make it always create a new account with a generated username and check e-mail only inside the organization.
- `identity/internal/service/membership/HostAdminProvisioner.java` — username = e-mail (~lines 32/41); switch to generated username, no reuse of an existing account from another organization.
- `identity/internal/service/ExamStaffAccountService.java` — the e-mail change check (~lines 47-54) is platform-wide through the user repository; scope it to the organization. This file edits an account, it is not the creation path (the creation path is the provisioner above).
- `identity/internal/util/UsernameGenerator.java` — Javadoc says STUDENT only and "not called yet"; make it role-neutral. Random part is 8 characters from a 31-letter alphabet (about 40 bits): enough, but the caller must retry on a username collision.
- `identity/internal/service/PlatformUserService.java` — username = e-mail (~lines 68/73). **Unchanged by assumption A1**; only add a test that locks the behavior in.
- `identity/UserCredentialsEmailRequestedEvent.java`, `notification/internal/listener/UserCredentialsNotificationListener.java` — welcome/credentials e-mail must show the generated username (unverified whether the event already carries it).
- `identity/domain/HostAdminCreated.java` and `billing/internal/service/TenantApplicationService.java` — the Host created on tenant approval must also receive the generated username (unverified how the e-mail is built).
- `identity/internal/repository/OrganizationMemberRepository.java` — an existing bulk "active members by organization and e-mails" lookup (used by the student path) is the likely base for the per-organization e-mail check (verify its fit).

Web (minimal, needed so new usernames can log in), under `pte-web/`:
- `packages/ui/src/hooks/useSignInValidation.ts` — forces the username field to match an e-mail pattern. Relax to "required".
- `packages/ui/tests/unit/hooks/useSignInValidation.test.ts` — update the expectation that a non-e-mail username is rejected.
- `apps/tenant-web/features/auth/constants.ts` and `apps/vendor-web/features/auth/constants.ts` — label "Email" and the invalid-e-mail message; change label/hint to "Username or e-mail" (final copy to be agreed).

## Steps
1. Decide the generated-username rule for staff (tenant code + random, same as students) and make the generator role-neutral with collision retry.
2. Switch staff creation (single create and Host creation on tenant approval) to always make a new account per organization, never reusing an account of another organization.
3. Enforce "e-mail unique inside the organization" for creation and for e-mail edits, replacing the platform-wide check; keep case-insensitive matching.
4. Make the welcome/credentials e-mails (staff and Host) show the generated username.
5. Relax the web sign-in field so usernames that are not e-mails are accepted, and update its label and hint copy in tenant-web and vendor-web.
6. Add or update tests and run the identity, billing and notification module tests plus the web unit tests for the touched packages.

## Tests to write or update
- `identity/internal/service/UserServiceTest.java`, `UserCredentialPolicyTest.java` — staff created with generated username; same e-mail in two organizations gives two accounts; same e-mail twice in one organization is rejected; the old "reuse existing account" expectations are replaced.
- `identity/internal/service/PlatformUserServiceTest.java` — platform account still gets username = e-mail.
- `billing/.../TenantApplicationServiceTest.java` and `TenantApplicationReviewPostgresIntegrationTest.java` — Host approved with an e-mail that already exists in another organization gets a new account; Host e-mail shows the generated username.
- `notification/internal/listener/UserCredentialsNotificationListenerTest.java` — body contains the username.
- New small test for the username generator (none exists today): format `{code}.{8 chars}`, no ambiguous characters, collision retry.
- Web: `useSignInValidation.test.ts` updated; vendor-web and tenant-web auth unit tests still green.

## Checkpoints
- No migration and no DB write in this phase. No backup needed.
- Postgres integration tests use the local compose Postgres; ask the user before running anything that writes to the local DB.

## Success Criteria
- `mvn test` for module identity, billing and notification is green.
- `pnpm` typecheck, lint and unit tests for `packages/ui`, `apps/tenant-web`, `apps/vendor-web` are green.
- A staff account created through the API has a username matching `^{code}\.[a-z2-9]{8}$` and different from its e-mail.
- Creating a staff member with an e-mail that exists in another organization returns a new account (new username, new public id); creating it twice in the same organization returns the existing "e-mail already used" error.
- A Host approved through the tenant application flow can log in on tenant-web with the generated username (manual check by the user).

## Rollback
Code-only: redeploy the previous image. Accounts created by this phase keep working because the schema did not change.

## Risks
- Existing staff who already belong to several organizations stay as they are until phase 3: this phase only stops new sharing.
- The same person re-added to the same organization after being deleted from it: depends on open question Q2; the phase keeps current behavior for deleted memberships and the test says so.
- Relaxing the sign-in validation weakens client-side feedback only; the server already validates.

## Not verified
- Whether `UserCredentialsEmailRequestedEvent` and the Host e-mail already contain the username.
- Whether other web screens (staff forms in tenant-web, vendor-web tenancy) display "username = e-mail" copy; grep for it during the phase.
- Whether `OrganizationMemberRepository`'s bulk e-mail lookup returns what the per-organization check needs.

## Execution Log
<!-- Filled by /ck:cook at the end of this phase — leave placeholders when planning -->

### Errors Encountered
- Stale surefire reports (old Postgres/Chat runs) gave a misleading error count; only reports newer than ~15 min were counted.
- `tsc` in tenant-web / vendor-web prints errors from stale `.next/types`; filtered out, none from this change.
- Code review = REQUEST CHANGES: single-created staff were never told their generated username (HIGH), plus duplicated username helper, constant name, stale `User` comment, missing tests.

### Root Cause
- The single-create path (`POST /users`) kept the old flow where the Host typed a password and no e-mail was sent, which only worked while username = e-mail.

### Resolution
- Generated usernames for every organization account: `UsernameGenerator.generateUnused(tenantCode, taken)` (shared by single-create, Host admin and the bulk retry via `COLLISION_RETRIES`); `HostAdminProvisioner` / `IdentityService.createHostAdmin(tenantId, tenantCode, email)` always create a new account.
- E-mail unique only inside the organization (`findActiveByOrganizationAndEmails`, `existsCanonicalEmail`); `ExamStaffAccountService` no longer checks e-mail across organizations.
- User decision (2026-11-15): drop the password field. `CreateUserRequest` has no password; `UserAccountProvisioner.createAccount` generates a temporary password (`mustChangePassword = true`) and publishes `UserCredentialsEmailRequestedEvent` (username + temporary password, sent after commit). Web: tenant-web `AddExamStaffModal` and vendor-web `CreateLoginAccountModal` lose the password input and show a note; `api-client` `CreateUserRequest` loses `password`. Login forms (tenant-web, vendor-web, `useSignInValidation`) no longer require an e-mail shape.
- Re-review = APPROVE WITH NOTES (2026-11-15). Applied: `scripts/seed-local-exam-ready.ps1` no longer sends a password, always resets to the seed secret and logs in with the returned username; removed the dead "existing account" branch of `BrandedEmailTemplate.applicationApproved` and its test; `UserService` Javadoc; tenant-web login hint ("...or your email if your account predates usernames"). Left for later: store normalized (lower-case) e-mail, `mustChangePassword` for Host accounts, record `toString` of the credentials event includes the secret, unused repository methods, dangling comment in tenant-web `features/exams/api/index.ts`.
- Review fixes: shared helper, stale `User` comment, new tests (`ExamStaffAccountServiceTest`, platform-user username = e-mail and duplicate, retry exhaustion, credentials event on single-create).

### Test Results After Fix
- API (unit, no Docker): UserServiceTest 34, PlatformUserServiceTest 8, ExamStaffAccountServiceTest 3, IdentityServiceTest 14, TenantApplicationServiceTest 13, UsernameGeneratorTest 2, plus SourceFileSizeTest, PackageDensityTest, ModuleStructureTest — 0 failures.
- Web: tenant-web 1033 and vendor-web 611 tests green; tsc and eslint clean for touched areas (ignoring stale `.next`); packages/ui sign-in validation tests rewritten and green earlier.
- Not run: `TenantApplicationReviewPostgresIntegrationTest` and other Docker/Postgres tests, manual UI check, Flutter, whole-repo `mvn test`, a repository-level test of per-organization e-mail uniqueness (DB constraint only arrives in phase 3).
- Notes: repository methods `existsByEmailIgnoreCaseAndDeletedFalse`, `...AndIdNot`, `findByEmailIgnoreCaseAndDeletedFalse` (maybe `findByUsername`) are now unused; a soft-deleted membership no longer blocks reusing an e-mail in that organization.
