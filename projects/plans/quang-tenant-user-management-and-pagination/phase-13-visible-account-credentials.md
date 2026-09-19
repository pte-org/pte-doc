# Phase 13: Visible account and one-time password verification

**Status:** Implemented locally; deployment smoke pending

## Objective

Make the login account visible in the user tables and give Host a safe way to
verify a Student temporary password without adding Student email delivery.

## Requirements

- Add `Account`/username columns to Student and Exam Staff tables.
- Add Student-only `Generate password`; it rotates the hash, sets first-login
  change, returns the password once, and does not publish an email event.
- Keep Exam Staff `Send email` unchanged.
- Never expose an existing password or persist plaintext credentials.

## Implementation

- Added `POST /api/v1/users/{publicId}/credentials/generate` for an authorized
  Host to rotate a Student password without email delivery.
- Added `Account` columns to Student Search and Exam Staff, using the existing
  tenant-scoped `username` metadata.
- Reused the one-time credentials modal for the Student result and made its
  email field nullable so Students can receive the result without an email.
- Kept Student `Send email` rejected in the backend and absent from the Student
  action menu.

## Quality/testing state

- Backend service coverage: 22 `UserServiceTest` tests passed; full app suite
  passed with 695 tests and no failures/errors/skips.
- API-client suite passed with 228 tests.
- Tenant typecheck, lint, and production build passed.
- Manual review confirmed one-time secret handling, tenant/role authorization,
  no Student email event, and preserved Student create/import results.
- Deployment smoke is still pending for the newly deployed API/frontend pair.
