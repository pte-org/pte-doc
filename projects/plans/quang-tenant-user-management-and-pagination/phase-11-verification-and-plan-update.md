# Phase 11: Verification and plan maintenance

## Objective

Verify the full change and leave the plan ready for the next continuation.

## Required checks

- Backend targeted identity/notification tests, then the appropriate full app
  test suite if practical.
- API-client tests.
- Tenant-web and vendor-web typecheck, lint, and production build.
- `git diff --check` in each repository.
- Manual code review of security, tenant scope, action callbacks, and password
  handling.
- Production smoke only with write interception; do not create accounts or
  send real credential email during the check.

## Plan update

Record completed phases, exact commands/results, known gaps, and any deferred
screen in `plan.md`, `quality/`, and `tests/` before reporting completion.
