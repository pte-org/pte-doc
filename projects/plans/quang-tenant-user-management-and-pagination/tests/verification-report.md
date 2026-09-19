# Verification report: Tenant user management and pagination

**Date:** 2026-09-19

## Automated local checks

| Check | Result |
|---|---|
| `./mvnw.cmd -pl app test` | 695 passed, 0 failures, 0 errors, 0 skipped |
| `corepack pnpm --filter @pte/api-client test` | 228 passed |
| `corepack pnpm --filter tenant-web exec tsc --noEmit` | Passed |
| `corepack pnpm --filter vendor-web exec tsc --noEmit` | Passed |
| `corepack pnpm --filter tenant-web lint` | Passed |
| `corepack pnpm --filter vendor-web lint` | Passed; 1 pre-existing Next `<img>` warning |
| `corepack pnpm --filter tenant-web build` | Passed |
| `corepack pnpm --filter vendor-web build` | Passed |
| `git diff --check` | No whitespace errors |

## Deployed checks

Target: `https://pte-tenant.duckdns.org`

- `/actuator/health`: HTTP 200.
- Tenant home: HTTP 200.
- Admin home: HTTP 200.
- Browser smoke suite: 27/27 passed.

The browser suite verified login, dashboard pagination, Exam Staff list
pagination/filter/sort/search/page-size behavior, create-form validation,
non-mutating create payload construction, Students pagination, Student import
modal behavior, optional Student fields, and non-mutating empty bulk payload
construction.

## Data-safety note

The browser suite intercepted create/bulk requests before they reached the
production database. It did not create an account or upload an Excel file.

The new ActionMenu and credential-rotation changes were verified locally. They
were not exercised against the deployed environment in this iteration because
the new frontend/backend build has not been deployed and the credential action
would mutate a real account and send an external email. A future deployed
smoke must intercept that request and assert the UI contract without allowing
the mutation through.

Iteration 3 additionally verified that Student Search has no credential-email
action and that a direct Student credential-email request is rejected before
hash lookup, hash rotation, or notification publication.

Iteration 4 additionally verified locally that Student `Generate password`
rotates the hash, returns the username and fresh password once, does not publish
an email event, and that both Student and Exam Staff tables display `Account`.
