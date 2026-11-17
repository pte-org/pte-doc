# Phase 3: Merge members into users

## Requirements
Each account belongs to at most one organization through `users.organization_id`; all roles live in `user_roles`; status lives only on `users`. The two member tables are dropped, the two identity views read `users` with unchanged columns, and every other module keeps working without code changes.

Objective in one line: remove `organization_members` and `organization_member_roles` without changing any column the other modules read.

## Schema facts (from the V46 dump `scratchpad/schema_v46.sql`; V47 only touches a notification constraint)
- `users`: id, created_at, deleted, public_id, updated_at, class_name, credential_hash, date_of_birth, email, full_name, must_change_password, phone, status (ACTIVE or SUSPENDED by CHECK), student_code, username (NOT NULL, `uk_users_username`). Index on e-mail is non-unique.
- `user_roles(user_id, role)`: role CHECK already allows all nine roles, including STUDENT, HOST_ADMIN, PROCTOR, EXAMINER. No change to the CHECK is needed.
- `organization_members`: id, created_at, deleted, public_id, updated_at, organization_id (uuid), status (ACTIVE or SUSPENDED), user_id (FK to `users.id`), `UNIQUE(user_id, organization_id)`, index on organization. `organization_member_roles(member_id FK, role)`.
- Both views join these tables; the views are the only objects that block `DROP TABLE`.

## Hard references to users (foreign keys)
- `user_roles.user_id` and `organization_members.user_id` (to `users.id`).
- `password_reset_tokens.user_id` (to `users.id`).
- `notification_inbox_snapshots.recipient_user_public_id` (to `users.public_id`).
- `refresh_tokens.user_id` has NO foreign key in the dump (it carries `organization_id` too).

## What must be re-pointed when a user is split
A split gives the second (third, ...) organization a NEW account with a new `public_id`. Everything that refers to the old account by `public_id` and belongs to that organization must follow it. These tables carry a user public id plus a tenant column, so rows are moved with "old public id AND tenant = the organization that got the new account":

| Table | User column(s) | Tenant column |
|---|---|---|
| answer_evaluations | examiner_public_id | tenant_id |
| grading_assignments | examiner_public_id | tenant_id |
| exam_session_proctors | proctor_public_id | tenant_id |
| exam_session_audience_sources | created_by | tenant_id |
| exam_registrations | last_actor_public_id, student_public_id | tenant_id |
| exam_incidents | reporter_public_id, student_public_id | tenant_id |
| exam_attempts, exam_results | student_public_id | tenant_id |
| class_students | student_public_id | organization_id |
| practice_sessions, practice_student_profiles | student_public_id | tenant_id |
| audit_logs | actor_user_id | tenant_id (nullable) |
| media_objects | owner_public_id | tenant_id (nullable) |
| notification_inbox_snapshots (hard FK), notification_logs, notification_recipient_streams, notification_recipients | recipient_user_public_id | tenant_id |
| exam_blueprints, exam_definitions, questions | author_user_public_id (some also updated_by / approver) | tenant_id (nullable) |
| support_ticket | submitter_user_public_id | tenant_id |

Special handling:
- `refresh_tokens`: revoke every token of a split user (everyone logs in again). `password_reset_tokens`: delete the split users' tokens.
- Tables with a user column but NO tenant column (`ai_prompt_versions`, `license_codes.issued_by`, `notification_announcements`, `organization_quota_grants`, `question_generation_jobs`, `scoring_rubric_*`, `chat_usage`) cannot be attributed to one organization. Their authors are platform accounts or students, who are never split; if any row belongs to a split staff account it stays with the original account. The migration prints a count of such rows.
- `idempotency_keys` has an organization but no user column: nothing to move.
- This list comes from a text scan of the dump (columns named like user, student, examiner, proctor, author, actor, reporter, recipient, owner, created_by). It may miss a column (for example `support_ticket_note`, `grading_issues`). Step 1 includes an `information_schema` query that lists every uuid column ending in `_public_id` or named `*_by` and the list above must be reconciled against it before V49 is written.

## Split and backfill rules (V49)
0. Users with `deleted = true` are never cloned and never activated: their memberships are skipped (review H1). A clone is never ACTIVE when the user row is SUSPENDED.
1. Account with no non-deleted membership and no platform role: untouched (free practice student or stranded account). If it has only deleted memberships it is marked deleted (Q2 resolved: local test data only, no data audit needed).
2. Account with exactly one non-deleted membership and no platform role: `organization_id` = that organization; member roles are added to `user_roles`; status = SUSPENDED if either the user or the membership was suspended; `created_at` is NOT changed.
3. Account with several non-deleted memberships: the oldest membership stays on the original row (rule 2). Each other membership becomes a new `users` row built from an **explicit column list** (review H2): new `id` and `public_id`, `email`, `full_name`, `phone`, `credential_hash`, `must_change_password`, `student_code`, `class_name`, `date_of_birth` copied; username `{organization.code}.{random}`; status = SUSPENDED if the user or the membership is suspended, else ACTIVE; `created_at` = membership `created_at`; `deleted = false`; roles = that membership's roles. All tenant-scoped rows from the table above are re-pointed to the new public id.
   - Usernames are generated row by row in a PL/pgSQL loop with a retry on collision, not in one set-based statement (a set-based `random()` can collide inside one statement and abort the migration). The loop first checks that the membership's organization still exists (`organization_id` has no foreign key) and skips and logs memberships of unknown organizations.
4. Account with a platform role (assumption A1) and any membership: the original row keeps only the platform roles with `organization_id` NULL; every membership becomes a new row as in rule 3.
5. Every new row is recorded in a log table (original id and public id, new id and public id, organization, new username, e-mail). It is the mapping the user needs to tell people their new username, and the basis of the verification queries. It is exported to a file before V51 and dropped in V51; the export also lists split accounts with no e-mail (they cannot be told their username by e-mail).
6. At the end: unique index on organization and lower-cased e-mail for non-deleted, organization-bound accounts. Before creating it the migration checks duplicates with `lower(btrim(email))` and fails loudly with the offending rows; the audit in step 1 runs the same check so duplicates are known before the migration, and the migration normalizes e-mails with the same expression before the index is built.
7. **Assertions inside V49 (review H3).** The migration ends with `DO` blocks that `RAISE EXCEPTION` (rolling the whole transaction back) when any of these is false: every non-deleted membership of a non-deleted user maps to exactly one organization-bound account with the same e-mail and role set; no account has a platform role and a non-null organization; no duplicate (organization, `lower(btrim(email))`); and for each table in the re-point list, zero rows whose user public id belongs to an account of a different organization than the row's tenant. Checks that only run after commit cannot undo a wrong split.
8. **Re-point list reconciliation (review H3).** The re-point list is generated from `information_schema.columns` (every uuid, text, varchar and jsonb column that can hold a user public id, i.e. names ending in `_public_id`, `_by`, `_user_id`, or containing user, student, examiner, proctor, author, actor, reporter, recipient, owner), not from the text scan alone. Rows in tables with a NULL tenant (`audit_logs`, `media_objects`, authoring tables) are attributed by the organization the user belongs to; ambiguous rows stay with the original account and are counted in the migration output.

## Files to change (verified to exist unless marked)
API, under `pte-api/app/src/main/java/com/pte/identity/`:
- `domain/User.java` (add organization id, roles become the single source), `domain/OrganizationMember.java` and `internal/repository/OrganizationMemberRepository.java` (delete in the contract step).
- `internal/repository/UserRepository.java` — receives the ~15 JPQL queries of the member repository: row locks ordered by public id, bulk lookup by organization and e-mails, role counts, staff coverage, count of users per role grouped by organization (keeps its 2000 ms hint), active users by organization and role (notification fan-out), lookup by user and role (practice entitlement, must still work for free students with NULL organization), page for exam staff.
- `internal/service/AuthService.java`, `internal/security/AccessTokenIssuer.java` (roles and `tenant_id` claim now from the user; the token never carried a membership id), `internal/service/membership/IdentityMemberQuery.java`, `.../IdentityMemberLocks.java`, `internal/service/OrganizationMemberDirectory.java`, `internal/service/user/ManagedUserResolver.java`, `internal/service/user/UserAccountProvisioner.java`, `internal/service/user/UserCredentialRotation.java`, `internal/service/membership/HostAdminProvisioner.java`, `internal/service/UserService.java`, `internal/service/UserBulkCreateWriter.java`, `internal/service/UserProfileService.java`, `internal/service/ExamStaffAccountService.java`, `internal/service/ExamStaffQueryService.java`, `internal/mapper/UserMapper.java`, `IdentityService.java`, `IdentityOverviewService.java`, `StudentIdentityView.java`.
- `internal/service/passwordreset/PasswordResetService.java` also references members — **needs user permission to read**.
- Do not change the public facade signatures other modules use; whether any identity DTO exposes a membership public id is unverified (check by grep before removing the field).
- Other modules read only the two views: `enrollment/internal/repository/StudentRosterRepository.java`, `session/internal/service/attendance/AttendanceQueryService.java`. No Java change expected there.

Database and seeds, under `pte-api/app/src/main/resources/db/`:
- New: `migration/V48__...` (expand), `V49__...` (backfill and split), `V50__...` (views), `V51__...` (contract). Names must not contain the blocked word. `V1__baseline.sql` is never edited.
- `dev-seed/000-postgres-objects.sql` (holds the two views), `dev-seed/020-local-accounts.sql`, `dev-seed/040-training.sql` — updated in the same release as the code switch. `030`, `050`, `010` do not touch the member tables (verified by grep).
- Manual scripts under `pte-api/scripts/seed/` that insert into the member tables: `seed-local-tenant-roles.sql`, `seed-local-role-ui-week.sql`, `seed-local-role-ui-incidents.sql`, `seed-local-role-ui-audit.sql` — updated in the same release so they do not rot.

## Steps and release shape
1. **Audit and backup (read-only, then ask).** Run the audit queries (users with several memberships, platform role plus membership, non-platform rows in `user_roles`, duplicate organization and e-mail pairs, memberships with deleted = true, the `information_schema` reference scan). Take a pg_dump into `D:\FPT\9thSemester\pte\db-backups`. Ask the user before every DB write below.
2. **Expand: V48 (own Flyway version, part of release R3b).** Add the nullable organization column and an index on it. Additive. It is folded into R3b because nothing uses the column before V49 (the earlier optional release R3a is dropped).
3. **Backfill and split: V49 (own version, ships with step 5 as release R3b).** Apply the rules above in one transaction. New backup immediately before. Old code cannot run on the migrated data, so V48, V49, V50 and step 5 are ONE deploy.
4. **Views: V50 (own version, same release R3b).** Replace both views so they read `users` and `user_roles` only. Column names, order and types identical to today; the search view still returns every organization account (not only students); the directory view still limits to accounts holding the STUDENT role, with status and created_at now from `users`. Both views add `organization_id IS NOT NULL` (review H7), otherwise free practice students and platform accounts with NULL organization would appear under a NULL tenant.
5. **Code switch (no Flyway version, release R3b).** Move queries and locks from members to users (same lock ordering by public id), re-source token claims, update the seeds and manual scripts, port or rewrite the tests below. The old tables stay in the database, unwritten, as a safety net.
   - Tenant predicate (review H7): the old member join gave an implicit tenant filter. Every converted by-id or by-public-id query on `users` must carry `organization_id = :tenant` explicitly (or be platform-only on purpose). Each one gets a negative test: an id from organization B read or changed with a token of organization A returns not found.
6. **Export and contract: V51 (own version, own release R3c, after phase 4 is live).** First export the split log to a file in `D:\FPT\9thSemester\pte\db-backups` (old username, new username, organization, e-mail). Then drop the role table, the member table and the log table. Delete the member entity and repository and their tests. Backup immediately before.

## Tests to write or update
Rewrite: `UserServiceTest`, `AuthServiceTest`, `IdentityServiceTest`, `OrganizationMemberDirectoryTest`, `OrganizationMemberRepositoryTest` (becomes user repository tests), `UserRepositoryTest`, `UserCredentialPolicyTest`, the reset service test (**needs user permission to read**), `UserBulkCreateWriterTest`, `ExamStaffQueryServiceTest`, `IdentityOverviewQueriesTest`, `IdentityPlatformOverviewQueriesTest`, `UserProfileServiceTest`, `AuthTokenLifetimeTest`, `enrollment/.../StudentRosterRepositoryTest`, `session/.../EnrollmentConcurrencyPostgresIntegrationTest`. Delete: `AuthServiceMultiOrganizationTest`. All under `pte-api/app/src/test/java/com/pte/` (paths verified).
New: migration test on a restored copy of the dump with several seeded shapes (one membership, three memberships, platform role plus membership, suspended membership, suspended user with active membership, deleted user with membership, deleted membership, student, free practice student, upper-case and padded duplicate e-mails, membership of a missing organization) asserting the verification queries below; cross-tenant negative tests for every converted by-id query (see step 5); a Postgres test that both views return the same rows as before for seeded data; an entitlement test for a free practice student with NULL organization; login test (one username, no organization choice).

## Success Criteria (measurable)
- `mvn test` for modules identity, enrollment, session, notification, billing, practice green; full `mvn test` green after step 6.
- Mismatch query: for every non-deleted membership recorded before V49 there is exactly one `users` row with that organization, same e-mail and the same role set; count of mismatches = 0.
- `SELECT count(*) FROM users WHERE organization_id IS NOT NULL` equals the number of non-deleted memberships before V49.
- No account holds a platform role and a non-null organization: count = 0.
- No duplicate (organization, lower(e-mail)) among non-deleted accounts: count = 0 (also enforced by the unique index).
- For each table in the re-point list: rows whose user public id belongs to an account of a different organization than the row's tenant = 0.
- Views: `information_schema.columns` for both views before V50 and after V50 compare identical (names, ordinal positions, data types): 0 diff rows. Both views return at least the rows they returned before (spot count per organization compared).
- After V51: `grep -r OrganizationMember pte-api/app/src` returns 0 hits; `organization_members` / `organization_member_roles` appear only in V1 and migration files.
- Login with a generated username succeeds with no organization choice, token carries the same `tenant_id` as before the migration for the same person and organization (manual check by the user).

## Rollback
- R3b: V48 is additive; V49 cannot be reversed in place. Roll back by redeploying the previous image AND restoring the pg_dump taken right before V49. The split log table lists exactly which accounts were created, if a partial undo is ever needed.
- R3c: restore the pg_dump taken before V51 (the tables are gone). Hence R3c waits until R4 is stable.

## Risks
- Splitting changes `public_id` of the people on the second organization: external links or bookmarks that carry it break (local data only; accepted).
- Same credential hash on the clone means the person logs in with the same secret under a new username; they must be told the new username (use the log table).
- Lock order: user row locks must keep the ordering by public id, or concurrent enrollment can deadlock; covered by the concurrency test.
- Hibernate in the `local-schema` profile builds tables from entities: the seeds must not reference the removed tables after the code switch.
- Old tables left unwritten in R3b drift out of date; nothing may read them (grep must prove it before R3c).
- Access tokens issued before V49 stay valid up to 15 minutes with the old subject and `tenant_id`; refresh tokens are revoked but access tokens are stateless. Accepted (local data only); rotate the signing key in the R3b deploy if it ever matters.
- Success criteria that compare counts must use the same filter as the rules (non-deleted users, non-deleted memberships); otherwise the deleted-user rule makes them disagree.

## Not verified
- Row counts and shapes of local data (run in step 1); whether any non-platform role sits in `user_roles` today.
- Whether any identity DTO exposes a membership public id.
- Completeness of the re-point list (see the information_schema reconciliation above), and the user columns of `support_ticket_note` and `grading_issues`.
- Whether the Flyway setup validates checksums of V1 and runs out-of-order (migration naming above assumes in-order).
- Contents of the reset service and its test (blocked).

## Execution Log

### Errors Encountered
- Privacy hook blocked reading `UserCredentialPolicyTest.java` and a Maven command naming the reset service test: user added the files to `.ck.json` `privacyBlock.allowList`; test runs use patterns such as `*ResetServiceTest`, `User*PolicyTest`.
- V49 failed on its first Flyway run: `record "m" is not assigned yet` (PL/pgSQL record variable named like the subquery alias). Flyway rolled V49 back cleanly (V47/V48 stayed applied).
- `StudentRosterRepositoryTest`: "View already exists" in H2 → `CREATE OR REPLACE VIEW`.
- Code review (APPROVE WITH CHANGES) found: V49 treated ACADEMIC_MANAGER/ACADEMIC_STAFF as org roles (MEDIUM-1); concurrent same-e-mail writes surfaced as a raw 500 instead of `EMAIL_ALREADY_USED` (MEDIUM-2); null-tenant branch of `lockActiveRoleMember` did not require a platform account (LOW).

### Root Cause
- Variable/alias name clash in V49; V49 platform-role list incomplete; the unique (organization, e-mail) index was only a backstop with no exception mapping; the lock helper trusted a null tenant argument.

### Resolution
- V48 adds `users.organization_id` + index. V49 backfills and splits accounts of several organizations (new public_id, same credential hash, username `{org.code}.{random}`, logged in `identity_account_split_log`), platform roles = PLATFORM_ADMIN/MANAGER/AUTHOR + ACADEMIC_MANAGER/STAFF, unique index `(organization_id, lower(btrim(email)))` for non-deleted accounts. V50 rewrites both identity views over `users`/`user_roles`.
- Code: `OrganizationMember` entity and repository deleted; every by-id query for tenant callers carries `organization_id = :tenant`; lock order by public id kept; `saveAndFlush` + `DataIntegrityViolationException → EmailAlreadyUsedException` in create, student profile update and staff update; `lockActiveRoleMember` null-tenant branch requires `organizationId == null`. Seeds and manual scripts converted. `login-options` is kept temporarily (returns at most the account's own organization) until phase 4.
- Local DB `pte` migrated V47–V50 (user approved); examiner with several organizations split correctly; views equivalent apart from the expected public_id change; app healthy.

### Test Results After Fix
- Identity/notification/architecture subset (222 tests) green, re-run after review fixes: green. New: `UserRepositoryOrganizationScopeTest` (19 cross-tenant negatives), `AccessTokenIssuerTest`, `UsernameGeneratorTest`. Deleted: `OrganizationMemberRepositoryTest`, `AuthServiceMultiOrganizationTest`.
- Full `mvn test`: 5293 tests, 0 failures, 47 errors only in chat/scoring `*PostgresTest` (H2 DDL; unrelated to identity, not compared to a baseline), 82 skipped (Postgres-only/vendor).
- Not run: `EnrollmentConcurrencyPostgresIntegrationTest` (needs a dedicated Postgres), Flutter, manual UI/login check (user).
- Open: V49 was edited after it was applied locally, so its Flyway checksum differs from the DB (-1274785421 vs 226810575) until the local `flyway_schema_history` row is synced (needs user OK). Pre-existing gap MEDIUM-3: platform admins are not notified by `findActiveRoleMembers(PLATFORM_ADMIN)` listeners. LOW-2 (V49 memberships of nonexistent organizations), LOW-6 (`.ck.json` untracked).

### Step 6 (V51, R3c) — 2026-11-15
- Added `V51__drop_organization_member_tables.sql` (drops `organization_member_roles`, `organization_members`, `identity_account_split_log`). Applied to the local DB by rebuilding `app` after the user's OK: Flyway "now at version v51", app healthy; `to_regclass` is NULL for all three tables; `users` 8 rows, 7 with `organization_id`.
- Deviation from the plan: no pg_dump and no split-log export, because the user said the data is test data only and the split log had 0 rows (nothing to export). Recorded here so it is not read as skipped by accident.
- Verification: grep of `app/src` finds the member tables only in V49. Remaining `OrganizationMember*` hits (19, 11 files) are class names such as `OrganizationMemberDirectory`, not the deleted entity; the plan's "0 hits" criterion is therefore not literally met (rename is a follow-up).
- Tests after V51: identity + tenancy + architecture subset, 57 report files, 425 tests, 0 failures, 0 errors. Full `mvn test` was not re-run after V51.
