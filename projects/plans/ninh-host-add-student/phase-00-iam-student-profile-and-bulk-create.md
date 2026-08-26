# Phase 0: iam — Student Profile Fields + Bulk Account Creation + Host-Assisted Student Password Reset

## Requirements

Three capabilities `iam` doesn't have today:
1. `User` needs optional profile fields (`studentCode`, `className`,
   `phone`, `dateOfBirth`) — currently identity is email/fullName only.
2. A caller who can already create one user (`POST /users`, `HOST_ADMIN`/
   `PLATFORM_ADMIN`) needs to create many in one request, for the Excel
   import path (avoids N sequential round-trips for a 100+-row roster) —
   with a server-generated, structured/readable password per row (Excel
   rows don't carry passwords) returned once in the response so the FE can
   build the existing "download credentials" file.
3. When a Student forgets their password, their Host needs to be able to
   reset it directly — today `POST /users/{publicId}/reset-password`
   exists but is `PLATFORM_ADMIN`-only (added in the earlier
   `ninh-host-account-management` plan for the narrower "admin rescues a
   locked-out Host" case). This phase widens it for the Host-rescues-a-
   locked-out-Student/Proctor case, without opening it up to
   Host-vs-Host account takeover (see Design Constraints).

Maps to: `plan.md` Decisions #1, #2, #6, #7.

## Design Constraints

- **Extend, don't fork, the existing single-create path.** `CreateUserRequest`
  gains the four new fields as optional (`@Nullable`, no `@NotBlank`) —
  they apply to any role (a Host or Proctor account could theoretically
  set a phone number too), not gated to `STUDENT` only; nothing in this
  phase restricts which role can carry them.
- **No role/authorization change.** `UserProvisioningHelper.HOST_ASSIGNABLE_ROLES`
  already includes `STUDENT` and `PROCTOR` — confirmed, not touched.
  `UserController`'s class-level `@PreAuthorize("hasAnyRole('PLATFORM_ADMIN',
  'HOST_ADMIN')")` already covers the new bulk endpoint too.
- **New endpoint: `POST /users/bulk`.** Same authorization as `POST /users`
  (class-level, not method-narrowed — a `HOST_ADMIN` caller can bulk-create
  same as they can single-create). Request:
  `BulkCreateUsersRequest(List<BulkCreateUserRow> rows, UUID tenantId)`
  where `BulkCreateUserRow` mirrors `CreateUserRequest` minus `password`
  (server-generated, minus `tenantId` — one shared value for the whole
  batch, not per-row) and minus `roles` (this endpoint is
  Excel-roster-import-only in this plan's scope, so every row is created
  as `STUDENT` — do not build a generic multi-role bulk endpoint here,
  that's speculative scope beyond what Phase 4 needs).
- **All-or-nothing.** Validate every row (email format, fullName present,
  no duplicate email within the same batch) before writing anything — same
  discipline as the `quang-exam-session-ops` bulk-import precedent
  (`phase-03-bulk-import-excel-zip.md`: pre-commit validation pass, then a
  single transaction). If any row fails validation, return 400 with a
  per-row error list (`row index`, `field`, `message`) and write nothing.
  A duplicate email against an EXISTING user (not just within-batch) is a
  per-row conflict, not a whole-batch abort — that specific row is skipped
  and reported (a re-imported roster with one already-onboarded student
  shouldn't block the other 99 new rows); everything else still commits in
  the same transaction.
- **Concurrency fallback around the batch save (HIGH finding from this
  plan's own red-team review, fixed here).** The per-row existing-email
  check followed by an unguarded save is a check-then-act race: `User.email`
  has a DB `unique = true` constraint, so a genuine concurrent conflict
  (two overlapping imports, or an import racing a plain `POST /users`,
  targeting the same email) can pass both existence checks before either
  commits, then throw `DataIntegrityViolationException` on save — which,
  unguarded, would roll back the ENTIRE batch's transaction, including
  every legitimately-new row, directly contradicting this phase's own
  stated per-row-skip behavior. Fix: wrap the batch save in
  `try/catch(DataIntegrityViolationException)`, same fallback pattern
  Phase 1/2 use for their own bulk operations — on catch, fall back to a
  per-row save loop (each in its own `try/catch`, moving any row that
  fails at save-time into `skipped` rather than aborting), so the rare
  true race degrades to "that one row skipped" instead of "whole batch
  lost."
- **Password generation, structured/readable format (Decision #6 — not
  fully opaque random, per user request).** Fixed shape: 8 characters,
  grouped `XXXX-XXXX`, drawn from a curated unambiguous alphanumeric
  charset (uppercase `A–Z` minus `O`/`I`, lowercase `a–z` minus `l`/`o`,
  digits `2–9` — excludes glyphs that are commonly confused when printed
  on a credentials handout and typed back by a student: `0`/`O`, `1`/`l`/`I`).
  Every character independently drawn via `java.security.SecureRandom`
  (not `Random`, not derived from the row's other fields — a fixed
  *shape* is fine to standardize on; the *content* must stay
  unpredictable, since a shape-only pattern with guessable content is not
  meaningfully more secure than no pattern at all). This keeps the
  8-character minimum (`@Size(min = 8)` precedent on manual creation) and
  is easy to read/type from a printed handout, without adding a wordlist
  dependency this codebase doesn't have. Centralize this generator as one
  method (e.g. `PasswordGenerator.generateReadable()`) so both bulk-create
  (this phase) and any future single-add-with-generated-password path
  reuse the exact same format — not reimplemented per call site.
- Include the generated password in the response DTO only once
  (`BulkCreateUsersResponse` — see Steps) — this is the one legitimate
  place a plaintext password appears in an iam response, and it's
  write/return-once, never retrievable again afterward (mirrors how
  `resetPassword`'s response deliberately never echoes the password back —
  the difference here is the FE explicitly needs it once, to build the
  credentials file for distribution, which is the entire point of this
  endpoint). Never log it.
- **Outbox, no exception (ADR-002).** One `EVENT_USER_CREATED` per row
  written in the same transaction as the batch insert (matches the
  existing single-create path's event, reused as-is — not a new
  `EVENT_USERS_BULK_CREATED`, since each row is still semantically one
  user-created fact for any downstream consumer).
- Password must never be logged — same standing rule as every other
  password-touching endpoint in this service.
- **Widen `POST /users/{publicId}/reset-password` for Host-assisted
  Student/Proctor recovery (Decision #7), scoped narrowly — not a blanket
  same-tenant grant.** Today it's method-level `@PreAuthorize("hasRole
  ('PLATFORM_ADMIN')")`, narrower than the controller's class-level
  `hasAnyRole('PLATFORM_ADMIN','HOST_ADMIN')`, and the service method
  looks the target up unscoped (`userRepository.findByPublicId`, no tenant
  check at all). Two changes, both required together:
  1. Remove the method-level `@PreAuthorize` override so it falls back to
     the class-level `hasAnyRole('PLATFORM_ADMIN','HOST_ADMIN')` — mirrors
     `suspend`, which already has no method-level override for exactly
     this reason.
  2. In `UserService.resetPassword`, replace the unscoped lookup with the
     existing `findScoped(publicId, caller)` helper (already used by
     `suspend`/`get` — a platform caller can target any user, a
     tenant-scoped caller only their own tenant's, 404 rather than 403 on
     a cross-tenant attempt so tenant existence isn't leaked). **Then add
     one more check found by this phase's own review, not present in
     `findScoped`**: when the caller is NOT a platform user, the target's
     `roles` must be a subset of `{STUDENT, PROCTOR}` — a `HOST_ADMIN`
     must not be able to reset a fellow `HOST_ADMIN`/`HOST_AUTHOR`
     account's password, even within their own tenant. Reasoning: the
     user's request was specifically "student quên mật khẩu," not
     Host-vs-Host account recovery; without this check, `findScoped`
     alone would let one Host silently take over a colleague's admin
     session (same tenant, so it clears the tenant check, but it's a
     materially different, unrequested capability — peer account
     takeover, auditable only after the fact via the existing
     `resetByUserId` outbox field, not prevented). Throw a new
     `ForbiddenPasswordResetException` (403) when this check fails.
  Update the existing code comment on the controller method (it currently
  documents the OLD platform-only reasoning — "the admin-rescues-a-
  locked-out-Host path, not self-service" — which is now half-obsolete
  and must be corrected to describe both cases, not left stale).

## Steps

1. `domain/User.java` — add nullable columns `studentCode`, `className`,
   `phone` (String), `dateOfBirth` (`LocalDate`).
2. `dto/request/CreateUserRequest.java` — add the same four fields,
   optional (no `@NotBlank`/`@NotNull`).
3. `dto/request/BulkCreateUsersRequest.java` (new) —
   `record BulkCreateUsersRequest(@NotEmpty List<@Valid BulkCreateUserRow> rows, UUID tenantId)`.
   `dto/request/BulkCreateUserRow.java` (new) — `record BulkCreateUserRow(
   @NotBlank @Email String email, @NotBlank String fullName, String
   studentCode, String className, String phone, LocalDate dateOfBirth)`.
4. `dto/response/UserResponse.java` — add the four new fields.
5. `dto/response/BulkCreateUsersResponse.java` (new) — `record
   BulkCreateUsersResponse(List<CreatedUser> created, List<RowError> skipped)`
   where `CreatedUser(UUID publicId, String email, String fullName, String
   generatedPassword)` and `RowError(int rowIndex, String email, String
   reason)`.
6. `repository/UserRepository.java` — add
   `List<User> findByEmailIn(List<String> emails)` (batched existing-email
   lookup for `createBulk`, see below — avoids N sequential queries).
7. `UserService`:
   - `create(...)` — thread the four new fields through to the saved
     `User` (existing method, extended, not duplicated).
   - `createBulk(BulkCreateUsersRequest request, CurrentUser caller)` —
     `@Transactional`. Resolve target tenant the same way
     `UserProvisioningHelper.resolveTargetTenant` does for the single-create
     path (reuse that helper, don't reimplement tenant resolution). Pre-pass:
     validate each row (format checks + within-batch duplicate emails →
     400 with full error list, no writes). Second pass: one batched
     `userRepository.findByEmailIn(emails)` call (not N individual
     `existsByEmail` queries) to find existing-email conflicts up front;
     rows in that result go straight to `skipped`. For the remainder,
     generate a password (`SecureRandom`-backed helper) and build the
     `User`+`LoginHash` pairs, then attempt `saveAll` inside
     `try/catch(DataIntegrityViolationException)`; on the (rare) exception,
     fall back to saving that remainder one row at a time, each in its own
     `try/catch`, moving any row that fails at save-time into `skipped`
     instead of failing the whole batch (concurrency fallback, see Design
     Constraints). Write one outbox event per row that actually committed,
     add each to `created`. Return `BulkCreateUsersResponse`.
8. `UserController` — `@PostMapping("/bulk") createBulk(@Valid @RequestBody
   BulkCreateUsersRequest request)` — no extra `@PreAuthorize` (class-level
   already correct, matches `POST /users`).
9. `util/PasswordGenerator.java` (new) — `generateReadable()`: 8-char
   `XXXX-XXXX` from the unambiguous charset described above, backed by
   `SecureRandom`. Used by `createBulk`.
10. `domain/exception/ForbiddenPasswordResetException.java` (new) — 403,
    mirrors `ForbiddenRoleAssignmentException`'s shape.
11. `UserController.resetPassword` — remove the method-level
    `@PreAuthorize("hasRole('PLATFORM_ADMIN')")` override; correct the
    stale doc comment to describe both the platform-rescues-Host and
    Host-rescues-Student/Proctor cases.
12. `UserService.resetPassword` — replace the unscoped
    `userRepository.findByPublicId(publicId)` lookup with
    `findScoped(publicId, caller)`; after loading, if
    `!caller.isPlatformUser()` and the loaded user's `roles` contains
    anything outside `{STUDENT, PROCTOR}`, throw
    `ForbiddenPasswordResetException` before touching the `LoginHash`.
13. Unit tests (`UserServiceTest.java`, extend): `createBulk` creates all
    rows when none conflict, returns correct `generatedPassword` per row
    (verify via `passwordEncoder.matches`, not by comparing stored hash
    text; also assert the returned password matches the `XXXX-XXXX`
    shape); `createBulk` skips an existing-email row but still creates the
    others, in the same call; `createBulk` rejects (400, no writes at all)
    when two rows in the same batch share an email; `create` (single)
    still round-trips the four new profile fields into the saved entity
    and `UserResponse`; `resetPassword` as `HOST_ADMIN` succeeds against a
    same-tenant `STUDENT`; `resetPassword` as `HOST_ADMIN` against a
    same-tenant `HOST_ADMIN`/`HOST_AUTHOR` target throws
    `ForbiddenPasswordResetException`; `resetPassword` as `HOST_ADMIN`
    against a different tenant's `STUDENT` throws `UserNotFoundException`
    (via `findScoped`, unchanged 404-not-403 behavior); `resetPassword` as
    `PLATFORM_ADMIN` still works against any role in any tenant
    (regression test — this phase must not narrow the existing platform
    path); `createBulk`, when the batch `saveAll` is forced to throw
    `DataIntegrityViolationException` (simulate via a pre-inserted
    colliding email that bypassed the pre-check, e.g. inserted directly
    via the repository in the test setup, not through `createBulk` itself),
    falls back to per-row saves and still creates every non-colliding row
    instead of losing the whole batch.

## Success Criteria

- [ ] `POST /users/bulk` as `HOST_ADMIN` creates N users scoped to the
      caller's own tenant, returns N `generatedPassword` values, each of
      which authenticates via `POST /auth/login`.
- [ ] A batch containing one row with an email that already exists creates
      every other row and reports that one row in `skipped`, not a 400 for
      the whole batch.
- [ ] A batch with two rows sharing the same email within itself is
      rejected wholesale (400, zero rows created).
- [ ] `POST /users` (single) accepts and returns `studentCode`/`className`/
      `phone`/`dateOfBirth`.
- [ ] Every `generatedPassword` returned by `POST /users/bulk` matches the
      `XXXX-XXXX` unambiguous-charset shape.
- [ ] `POST /users/{publicId}/reset-password` as `HOST_ADMIN` against a
      `STUDENT` in their own tenant succeeds; the old password stops
      working, the new one logs in.
- [ ] `POST /users/{publicId}/reset-password` as `HOST_ADMIN` against a
      `HOST_ADMIN`/`HOST_AUTHOR` account (even in their own tenant) is
      rejected (403).
- [ ] `POST /users/{publicId}/reset-password` as `HOST_ADMIN` against a
      user in a different tenant is rejected (404, not 403 — matches
      `findScoped`'s existing tenant-hiding behavior).
- [ ] `POST /users/{publicId}/reset-password` as `PLATFORM_ADMIN` is
      unaffected — still works against any role, any tenant.
- [ ] `mvn -pl services/iam -am test` passes, including the new tests.

## Quality and Testing State

- Not started.
