# Phase 09: Exam Staff account actions

## Objective

Expose a common row menu on Exam Staff with account details, credential email,
and lifecycle operations.

## User flow

1. Host opens the three-dot menu for a Proctor or Examiner.
2. `View details` shows username, email, full name, role, status, and first-login
   state.
3. `Send email` confirms that the current password will be replaced, then calls
   the generated-credential endpoint.
4. The one-time temporary password is shown with copy support and a warning;
   the same credential is sent to the user's email.
5. Suspend/reactivate keeps the existing confirmation and cache invalidation.

## Design constraints

- No password field is added to account details.
- Send-email is unavailable when email is absent.
- Do not create persistent test accounts during production smoke testing.

## Quality/testing state

- UI mutation and error states: implemented and typechecked.
- One-time credential display: implemented via the shared credential display
  component and one-time API response contract.
- Deployed non-mutating smoke: pending deployment; no credential-changing
  request may be allowed through production smoke.
