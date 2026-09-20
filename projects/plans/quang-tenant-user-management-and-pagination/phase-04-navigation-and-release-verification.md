# Phase 04: Navigation and release verification

## Navigation result

The tenant sidebar now renders the following contiguous groups:

```text
Users
  Learners
  Exam Staff

Delivery
  Program
  Exams
```

The existing unrelated working-tree changes in `navigation.tsx` were
preserved.

## Local verification

- Backend full Maven suite: 670 tests passed, 0 failures, 0 errors.
- API-client test suite: 218 tests passed.
- Tenant-web TypeScript check: passed.
- Tenant-web ESLint: passed.
- Tenant-web production build: passed.
- `git diff --check`: no whitespace errors; only existing CRLF conversion
  warnings were reported by Git.

## Deployed verification

The deployment runbook domains were checked:

- Tenant health endpoint: HTTP 200.
- Tenant root: HTTP 200.
- Admin root: HTTP 200.

Playwright smoke testing used the deployed tenant portal and completed 27/27
checks:

- Login and dashboard navigation.
- Dashboard learner pagination.
- Exam Staff screen and paged response.
- Role, status, search, sort, and page-size query propagation.
- Exam Staff modal fields and required-field validation.
- Valid Exam Staff payload shape, intercepted before production mutation.
- Students screen and roster pagination.
- Student import modal and file-input state.
- Student fields optionality and empty bulk payload shape, intercepted before
  production mutation.

## Release-test limitations

- The deployed tenant had zero Exam Staff records, so persisted row actions
  could not be exercised.
- No real Proctor/Examiner account was created.
- No real Excel file was uploaded.
- No production data was intentionally changed by the smoke test.
