# Phase 08: Safe generated credentials and email delivery

## Objective

Allow an authorized Host to send a fresh temporary credential to a user without
ever exposing or attempting to recover the stored password hash.

## API behavior

- Scope target by authenticated tenant and manageable role.
- Require a target email; reject accounts without one.
- Generate a readable password server-side with `SecureRandom`.
- Replace the login hash and set `mustChangePassword=true`.
- Queue a sensitive email; retain only redacted notification history.
- Return the credential once to the authenticated operator response.

## Design constraints

- No plaintext credential persistence.
- No credential in `UserResponse`, ordinary GET endpoints, audit text, or
  notification log body.
- Email delivery is asynchronous; the response reports that it was queued, not
  that SMTP delivery has completed.
- Existing manual reset behavior remains compatible.

## Quality/testing state

- Service authorization and hash replacement tests: passed in targeted identity
  tests.
- Notification redaction/dispatch tests: passed in targeted listener tests.
- API-client contract tests: passed; controller integration is covered by the
  full backend suite (693 tests passed).
