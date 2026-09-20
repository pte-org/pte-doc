# Phase 12: Student credential-email scope

**Status:** Implemented locally; deployment smoke pending

## Objective

Ensure Students do not have a credential-email action while Proctor and
Examiner workflows retain it.

## Requirements

- Remove Student Search's `Send email` menu item, confirmation dialog, and
  generated-credential result modal.
- Keep Student account details, username, first-login state, and
  suspend/reactivate actions.
- Reject direct backend credential-email requests for Student targets before
  loading or replacing the login hash.

## Quality/testing state

- Backend test: Student rejection case proves no hash lookup/save or event
  publication; targeted UserService suite passed 21 tests.
- Frontend: Prettier, tenant-web typecheck, lint, and build passed.
- Review: Exam Staff still exposes `Send email`; Student rows do not.
