# Phase 01 — Backend: Student account rules

**Repo:** pte-api · **Module:** identity · **Depends on:** — · **Status:** Done

## Changes

1. Row rules (e-mail and full name required, lengths, phone, date) are checked by `RosterRowValidator` for the whole
   roster instead of bean-validation annotations on `BulkCreateUserRow`, because the shared handler returns only the
   first bean-validation message and the Host needs every row error (implementation note, 2026-11-09).
   Codes and limits in `IdentityConstants` (`ROSTER_*`).
2. `UserAccountProvisioner.createBulk`: every row goes through `createGeneratedStudentWithRetry` (username from
   `UsernameGenerator`, e-mail stored on the account). Remove the `email == null` branch and the call to
   `UserBulkCreateWriter.createOne`.
3. Duplicate rules:
   - same e-mail twice in one request → `DuplicateEmailInBatchException` (unchanged);
   - e-mail already used by an active Student member of **this** organization → row skipped, reported
     `EMAIL_ALREADY_USED` (existing `findActiveByOrganizationAndEmails`);
   - e-mail used in another organization → allowed, new account.
4. `UserBulkCreateWriter`: remove `createOne` and `joinExisting` (no shared Student accounts); keep
   `createGeneratedStudent(username, row, tenantId)`; remove the two-argument overload once phase 02 deletes its caller.
5. Single "add Student" path (`UserAccountProvisioner.create` for role STUDENT): generate the username as in step 2
   instead of `username = email`; keep `username = email` for Host and exam staff.
6. Student profile edit (`UserService` e-mail change, line ~112): uniqueness check scoped to the organization for
   Students, global for other roles.
7. Login is unchanged (`username` + password; `tenantId` only for legacy multi-membership accounts).

## Tests

- Unit: provisioner creates generated usernames for rows with e-mail; missing/invalid e-mail rejected at validation;
  same e-mail in two organizations → two accounts; same e-mail twice in one organization → skipped.
- Update `UserBulkCreateWriterTest`, `UserServiceTest`, `UserAccountProvisioner*Test` for removed branches.
- Login test: generated username signs in; e-mail does not (for a new Student).

## Validation

`.\mvnw.cmd -pl app -DskipTests compile`, then `.\mvnw.cmd -pl app test` (identity + architecture ratchets).
