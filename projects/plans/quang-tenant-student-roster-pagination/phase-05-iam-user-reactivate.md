# Phase 05: IAM user reactivate

## Goal

Close the one-way door in IAM's user lifecycle. `User.suspend()` exists with no
counterpart, so a suspended student is permanently unusable today.

## Why this is in scope

Adding reactivate does not change the roster contract — it justifies it. The
roster deliberately returns suspended students with a badge rather than
filtering them out, and that only pays off if the host can act on what they see.
Without reactivate, a suspended row is an epitaph; with it, the roster is the
place you find someone to restore.

Cost is genuinely small: `UserStatus` has two values, `suspend()` is a
one-liner (`User.java:77-79`), and `isSuspended()` is consulted at exactly two
places, both in `AuthService` (lines 46 and 62).

## Work items

1. Add `User.reactivate()` next to `suspend()`, setting status back to
   `UserStatus.ACTIVE`. Keep the same style — a domain method, not a setter call
   from the service.
2. Add `UserReactivatedEvent` in `com.pte.iam.domain.event`, mirroring
   `UserSuspendedEvent`'s shape (`userPublicId`, `tenantId`).
3. Add `EVENT_USER_REACTIVATED = "UserReactivated"` to `IamConstants` beside the
   existing `EVENT_USER_SUSPENDED` (line 23), and the matching audit-action
   constant beside `USER_SUSPENDED` (line 15).
4. Add `UserService.reactivate(publicId, caller)` following `suspend()`
   (`UserService.java:174-181`) exactly: `findScoped` for tenant isolation,
   domain call, outbox write, mapped response.
5. Apply the same authorization rule `suspend` uses. A host must not be able to
   reactivate a user outside their tenant, and role restrictions equivalent to
   `HOST_RESETTABLE_ROLES` should be considered for consistency with
   `resetPassword`.
6. Add `POST /users/{publicId}/reactivate` to `UserController`, mirroring the
   existing `POST /users/{publicId}/suspend` (line 59) including its security
   annotations.
7. Extend the Phase 2 Admin consumer with a `UserReactivated` branch that sets
   the projection status back to `ACTIVE`.
8. Decide and document whether reactivating is a no-op or an error when the user
   is already `ACTIVE`. Prefer idempotent no-op, matching how the projection
   consumer must behave anyway.

## Design constraints

- Reactivate is the inverse of suspend and nothing more. It does not reset a
  password, does not change roles, and does not touch `LoginHash`.
- Tenant scoping comes from `findScoped`/`CurrentUser`, never from a request
  body.
- The event must be published through the outbox in the same transaction as the
  status change, like every other IAM event.
- `AuthService`'s two `isSuspended()` checks are the only auth-path consumers of
  status; do not add a third status concept.
- Do not widen `UserStatus` with new values in this phase.

## Quality and testing state

- Unit tests: not started; user preference is `unitest: ko`.
- Quality: approved with 0 findings; see `quality/phase-05-iam-user-reactivate-quality-report.json`.
- Required non-unit verification: `iam` and `admin` compile; suspend a test
  student, confirm login is rejected, reactivate, confirm login succeeds;
  confirm the projection status follows both transitions; confirm a cross-tenant
  reactivate is rejected.

## Acceptance criteria

- `POST /users/{publicId}/reactivate` restores a suspended user to `ACTIVE`.
- A reactivated user can log in again; a suspended one still cannot.
- A host cannot reactivate a user in another tenant.
- Reactivating an already-active user is idempotent and does not error.
- The roster projection reflects both suspend and reactivate.
- No change to password, roles, or login hash results from reactivate.

## Cook status

- Implemented and compiled on 2026-09-15; unit tests skipped by explicit user preference.
- IAM/Admin runtime transition checks passed locally: suspend blocked login and
  updated the projection; reactivate restored login and projection; no commit or
  push was made.
