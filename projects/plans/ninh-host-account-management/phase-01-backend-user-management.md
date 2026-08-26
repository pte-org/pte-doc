# Phase 1: Backend — Reset Password + Tenant-Scoped User Lookup

## Requirements

Two capabilities `iam` doesn't have today:
1. A `PLATFORM_ADMIN` needs to look up whether a given tenant already has
   a login account, to drive the Phase 2 UI's "Create Login" vs. "account
   exists, show Reset Password" branch.
2. A `PLATFORM_ADMIN` needs to set a new password directly on a Host's
   account (admin-assisted recovery — confirmed via AskUserQuestion, no
   email flow).

Maps to: the two decisions recorded in `plan.md`'s Overview.

## Design Constraints

- **Do not touch `POST /users`.** It already does exactly what account
  creation needs (`UserService.create`, platform caller can target any
  `tenantId`, `UserProvisioningHelper.resolveTargetTenant`). Phase 2 calls
  it as-is.
- **`GET /users` stays untouched too** — it's tenant-caller-scoped
  (`listByTenant` reads `caller.tenantId()`), and nothing in this plan
  needs to change that semantic for tenant-scoped callers. Confirmed via
  grep that no FE code calls it today (nothing to break).
- **New lookup: `GET /users/by-tenant/{tenantId}`.** Platform-admin-only
  (`@PreAuthorize("hasRole('PLATFORM_ADMIN')")` at the method level,
  overriding the controller's class-level `hasAnyRole('PLATFORM_ADMIN',
  'HOST_ADMIN')` — Spring Security lets a method-level `@PreAuthorize`
  narrow a class-level one). Returns `List<UserResponse>` via
  `userRepository.findByTenantId(tenantId)` (repository method already
  exists, used by `listByTenant`). Deliberately a separate endpoint rather
  than widening `GET /users` with a query param — keeps the existing
  endpoint's caller-scoped meaning unambiguous instead of overloading it.
- **New mutation: `POST /users/{publicId}/reset-password`.**
  Platform-admin-only (same per-method `@PreAuthorize` override — a
  `HOST_ADMIN` caller does NOT get this power, including over their own
  tenant's users; this is specifically the "admin rescues a locked-out
  Host" path, not host-self-service, matching the AskUserQuestion answer).
  Request: `ResetPasswordRequest(String newPassword)`, same
  `@NotBlank`/`@Size(min = 8)` validation as `CreateUserRequest.password`.
  Response: `UserResponse` (never the password — it's write-only, exactly
  like creation's response today).
- **Outbox, no exception (ADR-002).** Write `EVENT_USER_PASSWORD_RESET` in
  the same transaction as the `LoginHash` update. Payload carries no
  password material — just `userPublicId`, `resetByUserId` (the caller,
  for audit — "who rescued this account"), `tenantId`.
- User lookup for reset: `userRepository.findByPublicId(publicId)`
  (platform caller can target any user — no tenant-scoping needed since
  the whole endpoint is platform-admin-only) `.orElseThrow(UserNotFoundException::new)`.
- Password must never be logged. No request-body logging middleware exists
  in this codebase today (confirmed) — nothing to add, just don't
  introduce any in this phase.

## Steps

1. `dto/request/ResetPasswordRequest.java` — `record ResetPasswordRequest(@NotBlank @Size(min = 8, message = "Password must be at least 8 characters") String newPassword)`.
2. `domain/event/UserPasswordResetEvent.java` — `record UserPasswordResetEvent(UUID userPublicId, UUID resetByUserId, UUID tenantId)`.
3. `IamConstants` — add `EVENT_USER_PASSWORD_RESET = "UserPasswordReset"`.
4. `UserService`:
   - `resetPassword(UUID publicId, ResetPasswordRequest request, CurrentUser caller)` — `@Transactional`. Load user by `publicId` (404 via `UserNotFoundException` if missing). Load its `LoginHash` by `userId` (same lookup pattern `AuthService.login` uses), overwrite `hash` with `passwordEncoder.encode(request.newPassword())`, save. Write the outbox event. Return `UserMapper.toResponse(user)`.
   - `listForTenant(UUID tenantId)` — `@Transactional(readOnly = true)`. `userRepository.findByTenantId(tenantId).stream().map(UserMapper::toResponse).toList()`. No `CurrentUser` param needed — the controller's `@PreAuthorize` already guarantees only a platform admin reaches this method, so there's no per-call authorization decision left for the service to make (unlike `findScoped`, which branches on caller type).
5. `UserController`:
   - `@GetMapping("/by-tenant/{tenantId}") @PreAuthorize("hasRole('PLATFORM_ADMIN')") list(@PathVariable UUID tenantId)`.
   - `@PostMapping("/{publicId}/reset-password") @PreAuthorize("hasRole('PLATFORM_ADMIN')") resetPassword(@PathVariable UUID publicId, @Valid @RequestBody ResetPasswordRequest request)` — calls `userService.resetPassword(publicId, request, currentUser())`.
6. Unit tests: `UserServiceTest.java` (new, or extend if one already exists — check first) covering: `resetPassword` overwrites the hash and the old password no longer matches (verify via `passwordEncoder.matches`); `resetPassword` on a non-existent `publicId` throws `UserNotFoundException`; outbox write happens exactly once per successful reset; `listForTenant` returns only users for the given tenant (not other tenants' users, not platform users).

## Success Criteria

- [ ] `POST /users/{publicId}/reset-password` as a `HOST_ADMIN` caller is
      rejected (403) — this endpoint is platform-admin-only, full stop.
- [ ] `POST /users/{publicId}/reset-password` as a `PLATFORM_ADMIN` caller
      changes the password; the old password no longer authenticates via
      `POST /auth/login`, the new one does.
- [ ] `GET /users/by-tenant/{tenantId}` as `PLATFORM_ADMIN` returns exactly
      that tenant's users; returns `[]` for a tenant with none.
- [ ] `mvn -pl services/iam -am test` passes, including the new tests.

## Quality-and-Testing-State

- Backend: `mvn -pl services/iam -am test` — full suite passing (9 tests:
  5 `TenantEventConsumerTest` + 4 new `UserServiceTest`).
- Quality gate (`ck:quality`, `quality-reviewer` agent, scoped to this
  phase's files): **0 BLOCKER, 0 HIGH, 0 MEDIUM, 0 LOW — APPROVED**.
  Verified method-level `@PreAuthorize` correctly narrows the class-level
  one (not ANDed), password never appears in any response DTO/log/outbox
  payload, `GET /users`'s existing `listByTenant` is untouched (`listForTenant`
  is a genuinely separate method), outbox write is transactional and uses
  the right constants, and the reset test proves the behavior via real
  `BCryptPasswordEncoder.matches()` assertions rather than mock-call checks.
- Manual E2E (login with old/new password via `POST /auth/login`): not yet
  run — deferred alongside Phase 2/3, same pattern as every phase in the
  prior plan.
