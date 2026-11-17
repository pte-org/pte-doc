# Plan: One username = one organization (drop organization_members)
Status: 🟡 In Progress
Date: 2026-11-14
Mode: Hard
Owner/slug: Phat, `phat-single-org-accounts`
Scope: pte-api (identity, notification, tenancy, billing, session/enrollment views), pte-web (api-client, tenant-web, vendor-web, packages/ui), pte-app (Flutter)
Git: the user commits everything. No phase of this plan commits, pushes or opens a PR.

## Overview
Every organization issues its own accounts. A person at two organizations has two usernames. Staff move to the student model (generated `{tenant.code}.{random}` username, e-mail unique per organization), the login-organization picker goes away, and the tables `organization_members` and `organization_member_roles` are folded into `users` and `user_roles`.

## Goal and target model
- `users.organization_id uuid NULL` (soft reference to `organizations.public_id`; NULL = platform account or free practice student).
- `user_roles` holds ALL roles of an account; one `status` on `users`.
- Username stays globally unique (`uk_users_username` unchanged). E-mail unique only inside one organization: `UNIQUE (organization_id, lower(email)) WHERE deleted = false`.
- Views `identity_staff_student_search_view` and `identity_student_directory` are rewritten on `users` with the exact same column list, order and types. The search view keeps returning every organization account, not only students.

## Decisions (made by the user, not re-opened)
1. Staff get a generated username like students, sent by e-mail. Staff e-mail only has to be unique inside the organization.
2. Scope is API, web (tenant-web, vendor-web, api-client) and Flutter. `POST /login-options` and both organization pickers are removed.
3. Target model as above.
4. Reset asks for e-mail AND username (changed 2026-11-14, replaces "one e-mail listing every account"): the server finds the one account with that username, checks its e-mail matches and sends that account one link. Same generic HTTP response in every case. Throttled per e-mail, per IP and per username. Forgotten username: the person asks their Host (no separate flow).
5. Phase order: a, b, c, d. Each phase is shippable alone and leaves the build green.
6. Local data only; data-rewriting migrations are fine, but a pg_dump backup (folder `D:\FPT\9thSemester\pte\db-backups`) is taken before each migration phase and the user is asked before any DB write. V1 is never edited. Dev-seed files are updated in the same phase as the code switch.

## Assumptions made by this plan (please confirm or overrule)
- A1. Platform accounts (PLATFORM_ADMIN, PLATFORM_MANAGER, PLATFORM_AUTHOR, ...) keep username = e-mail, unique platform-wide, `organization_id` NULL. See open question Q1.
- A2. The next Flyway version is **V48**, not V47. `V47__allow_exam_incident_reported_notification.sql` already exists in the repo (verified by file listing). The schema dump used for this plan is V46, so it predates V47; V47 only touches a notification constraint, so the users/roles analysis still holds.
- A3. Phase 4 removes the API endpoint after the web clients stop calling it. Until then login still accepts an optional organization id and the endpoint stays (it returns at most one organization after phase 3).
- A4. This plan reverses part of the multi-organization story of `quang-entity-consolidation` phase 2 (which introduced `/auth/login-options`). Its tests and docs that promise "one user in 2+ organizations" must be changed, not just deleted silently.

## Phases
- [x] Phase 1: Staff username and e-mail rules — [phase-01-staff-username-email-rules.md](./phase-01-staff-username-email-rules.md): new staff get generated usernames, e-mail unique per organization, welcome e-mail shows the username, web login stops demanding an e-mail shape.
- [x] Phase 2: Reset by e-mail + username — [phase-02-reset-by-email.md](./phase-02-reset-by-email.md): request takes e-mail and username, one account, one link, generic response; API first (username optional), then web forms, then required. Step 1 of the two-step rollout is done (API accepts an optional username, web form sends both); step 2 (make `username` required, drop the e-mail-only branch and the blank-username case in the throttle) is a follow-up after the web release is live.
- [x] Phase 3: Merge members into users — [phase-03-merge-members-into-users.md](./phase-03-merge-members-into-users.md): expand (V48), backfill and split (V49), views (V50), code switch, contract (V51). Step 6 (V51, R3c) applied to the local DB on 2026-11-15 after phase 4; no pg_dump or split-log export was taken (user: test data only, and the log had 0 rows).
- [x] Phase 4: Clients and login-options removal — [phase-04-clients-and-login-options-removal.md](./phase-04-clients-and-login-options-removal.md): remove pickers in web, check Flutter, then delete the API endpoint. Done (R4a web + Flutter, R4b API), approved by the user on 2026-11-15; V51 followed.

| # | Phase | Repo | Depends on | Ships |
|---|---|---|---|---|
| 1 | Staff username and e-mail rules | pte-api, pte-web (small) | 2 (ships after or with R2) | release R1 |
| 2 | Reset by e-mail | pte-api, pte-web (copy only) | none | release R2 |
| 3 | Merge members into users | pte-api | 1, 2 | R3b (V48+V49+V50+code), R3c (V51, later) |
| 4 | Clients and login-options removal | pte-web, pte-app, pte-api | 3b | release R4 (web first, API endpoint removal after) |

Ship order: **R2, R1, R3b, R4, R3c** (changed after the red-team review). R2 goes first (or in the same deploy as R1) because it is small and self-contained. Note: after the 2026-11-14 decision, reset no longer recovers a forgotten username; staff who lose the welcome e-mail ask their Host (Q8). V48 is folded into R3b because the column is unused until V49. R3c (dropping the tables) is last on purpose: it is the only step that cannot be undone without a backup restore, so it waits until R4 has run cleanly.

## Research Summary
- Chosen approach: fold into `users` in expand / backfill / split / views / code switch / contract order (primary research).
- Rejected: only adding `UNIQUE(user_id)` on `organization_members`. Cheap, but keeps a redundant join table and the two-table role model.
- Rejected: per-organization username uniqueness. Login would need an organization again, which is exactly what this plan removes.
- Facts checked in the repo: `OrganizationMember` is referenced from identity main code only (no other module imports it); other modules read memberships through the two views via native SQL (`StudentRosterRepository`, `AttendanceQueryService`) and through `IdentityService` facades. Access tokens carry the user public id as subject and the organization id as `tenant_id`; no membership id is in the token. Seeds that insert into the two tables: `db/dev-seed/000`, `020`, `040` and four manual scripts under `pte-api/scripts/seed/` (`seed-local-tenant-roles.sql`, `seed-local-role-ui-week.sql`, `seed-local-role-ui-incidents.sql`, `seed-local-role-ui-audit.sql`).
- Web blocker found: `packages/ui` sign-in validation rejects any username that is not an e-mail, and both login screens label the field "Email". New staff usernames would not pass, so phase 1 carries a minimal web fix.

## Dependencies
- Docker compose Postgres for the local DB (3-file compose + env file) for every Postgres-backed test and every migration run.
- Phase 2 needs read permission for the files whose names contain the blocked word (see phase 2).
- Phase 3b needs the user's go-ahead for the DB write and a fresh pg_dump.

## Risks
- HIGH: Splitting users (phase 3b) is irreversible in place and must re-point per-account rows in other tables, which refer to the user by `public_id` without foreign keys. Mitigation: a split log table, a documented per-table re-point list, mismatch queries that must return 0, backup first, restore as the rollback.
- HIGH: Old code run against migrated data (or new code against unmigrated data) breaks login. Mitigation: V48, V49, V50 and the code switch ship in one release (R3b).
- HIGH: Views block `DROP TABLE`. Mitigation: V50 replaces both views before V51 drops tables; column lists compared against the live catalog before and after.
- MEDIUM: New staff cannot log in on the web because the form demands an e-mail. Mitigation: fixed inside phase 1.
- MEDIUM: A split user keeps the same credential hash but gets a new username; the person must be told. Local data only, so the split log is the mapping; no e-mails are sent by the migration.
- MEDIUM: Platform role plus organization membership on one account (A1). Mitigation: split rule in phase 3b keeps the platform account separate.
- MEDIUM: Free practice students (no organization) must keep entitlement working. Mitigation: dedicated test in phase 3.
- LOW: `created_at` in `identity_student_directory` shifts from membership time to account time. Mitigation: split/backfill copies the membership creation time into the account row it becomes.
- HIGH (review H1): clones must not re-activate a globally suspended or deleted user. Mitigation: clone status = SUSPENDED if the user OR the membership is suspended; memberships of deleted users are skipped (phase 3 rules).
- HIGH (review H3): checks that run after V49 commits cannot undo a wrong split. Mitigation: assertions inside V49 (`RAISE EXCEPTION`) roll the whole transaction back.
- HIGH (review H7): turning member queries into `users` queries drops the tenant predicate the membership join gave. A missing `organization_id = :tenant` is a cross-tenant IDOR. Mitigation: a negative cross-tenant test for every converted by-id query.
- HIGH (review H4, H5): the reset e-mail is built from attacker-influenced data (organization names, e-mails registered by any organization admin) and the request path can leak existence by timing. Mitigation in phase 2.
- NOTED (review, MEDIUM): access tokens issued before V49 stay valid for up to 15 minutes (stateless RS256 JWT, TTL 900 s) with the old subject and `tenant_id`; refresh-token revocation does not touch them. Accepted: local data only. Alternative if it ever matters: rotate the signing key in the R3b deploy.
- NOTED (review, MEDIUM): accounts with only deleted memberships are marked deleted (Q2 resolved; local data only, 0 such rows today).
- NOTED (review, MEDIUM): the split log table is the only mapping from old to new usernames and V51 drops it. Export it to a file in `D:\FPT\9thSemester\pte\db-backups` before V51 and list split accounts with no e-mail.

## Red-team review (2026-11-14) — adjudication
Verdict of the reviewer: WARN, no CRITICAL. Accepted and applied: H1 clone status and deleted users, H2 explicit column list for clones (including `must_change_password`, `student_code`, `class_name`, `date_of_birth`), H3 assertions inside V49 and the `information_schema` reconciliation including text, varchar and jsonb columns and nullable-tenant tables, H4 reset e-mail hardening, H5 reset timing and enumeration, H6 ship order, H7 tenant predicate tests and `organization_id IS NOT NULL` in both views, e-mail audit with `lower(btrim(email))`, row-by-row clone username generation with an organization-existence check, per-account link base and token invalidation after confirm. Noted in Risks above: the 15-minute token window, Q2 default, the mapping export, and folding R3a into R3b (applied).

## Open questions
- Q1. Platform accounts: keep username = e-mail platform-wide (assumed, A1) or generate usernames too?
- Q2. RESOLVED (2026-11-14, user: local test data only, any choice is fine): an account whose only memberships are deleted is simply marked `deleted = true` by V49, with no data audit. Local DB currently has 0 deleted memberships, so this rule is not exercised on real rows; it is covered by the seeded migration test only.
- Q3. Keep one release with the old tables present but unwritten (R3b) before dropping them (R3c)? This plan assumes yes (R3b then R3c after R4). Say if you prefer to drop in the same release.
- Q4. Which membership stays on the original user row when one user has several (oldest by creation time is the default)? Matters only for which person's history keeps the old `public_id`.
- Q5. Should suspended accounts receive reset links (phase 2)? Default: no, they are listed neither in the e-mail nor counted.
- Q6. Does the generic reset response also need a fixed response time (not only a fixed body)? Default (review H5): token creation moves to the async worker so the request does the same work whether or not accounts exist.
- Q7. RESOLVED (2026-11-14): the user granted read access. Existing code already sends one link per account with a generic async response and per-e-mail / per-IP throttle. The user then chose e-mail + username on the form, so phase 2 became: add `username` to the request, match one account, add a per-username throttle, always show the username in the mail. The multi-account listing and the organization name in the e-mail are dropped, which also removes review item H4 (organization-name phishing); H5 (timing) was already satisfied.
- Q8. RESOLVED (2026-11-15, read from code, not run): `UserController` is `PLATFORM_ADMIN` or `HOST_ADMIN`. `send-email` (`UserCredentialRotation.sendGeneratedCredentials`) works on any account the caller may manage, needs a non-blank e-mail on the account, and rotates a temporary password. A Host manages only accounts in its own organization whose roles are all within {PROCTOR, EXAMINER, STUDENT}; a platform admin manages only accounts whose roles are all {HOST_ADMIN} (`UserProvisioningHelper.canManageTarget`). So a Host cannot reach another Host or itself: a Host who forgot their username goes to the platform admin. `generate` is for STUDENT targets only. An account holding a mix such as HOST_ADMIN + EXAMINER fits neither set (`containsAll`), so nobody can use these endpoints on it. Not checked: platform staff accounts (PLATFORM_MANAGER, ACADEMIC_*) and whether the web UI exposes the buttons.
- Q9. For the cook step the user must add the blocked web file names to the allowList (tenant-web and vendor-web `ForgotPasswordView.tsx`, `ResetPasswordView.tsx`, `packages/ui` `PasswordResetForms.tsx`, `passwordReset.ts` and their tests, `passwordResetCopy.test.ts`, api-client `passwordReset.test.ts`).

## Session Notes (overwritten by /ck:cook after each phase)
- 2026-11-15: phase 1 implemented (API + web + tests). Review = REQUEST CHANGES; fixes applied and the HIGH item resolved by the user's choice: single-created accounts get a generated temporary password (no password field in the forms, `CreateUserRequest` has none) and an e-mail with username + temporary password. Not committed (the user commits). Not re-reviewed after the fixes.
- Phase 2 (2026-11-15): implemented and reviewed (APPROVE WITH NOTES), see its Execution Log.
- Verified (phase 1): API unit + architecture tests green (UserService 34, PlatformUser 8, ExamStaffAccount 3, IdentityService 14, TenantApplication 13); web tenant-web 1033 and vendor-web 611 tests green, tsc/eslint clean for touched areas.
- Not verified: manual UI, Flutter, whole-repo `mvn test`, Docker/Postgres tests (incl. `TenantApplicationReviewPostgresIntegrationTest`), Q8, SRS text for the account/reset flows.
- 2026-11-15: phases 1-4 are coded; V48-V51 applied locally; full `mvn test` = 5284 tests, 0 failures; the 47 errors in `*PostgresTest` came from stale files in `target/classes/db/migration` and pass (92 tests) after cleaning that folder. Phase 2 step 2 (username required in the reset request) done, see phase 2 log.
- Final full `mvn test` (2026-11-15, after the cleanup and a clean `target/classes/db/migration`): 5328 tests, 0 failures, 0 errors, 82 skipped, exit 0.
- Next: remaining follow-ups only (below).
- Cleanup done 2026-11-15: removed `UserRepository.findByEmailIgnoreCaseAndDeletedFalse` (its test now checks two accounts of different organizations share an e-mail) and `User.hasPlatformRole()`; `StudentRosterRepositoryTest` already used `users.organization_id`, nothing to change. Q8 is resolved above (no account holds two roles locally, user confirmed).
- Follow-ups: rename `OrganizationMemberDirectory` and the `membership/` package (the user chose to skip it); MEDIUM-3 (platform admins not notified through `findActiveRoleMembers(PLATFORM_ADMIN)`), LOW-2 (V49 edge case, memberships of nonexistent organizations).

## Facts not verified
See the end of each phase file for its own list. The main ones: contents of everything under the reset-by-e-mail package (blocked), whether membership public ids leak through identity DTOs, which e-mail templates show the username, Flutter widget tests, and the full list of per-account soft references (a regex scan of the dump was used, an `information_schema` query must confirm it).
