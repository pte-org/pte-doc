# Spec: Tenant user management and pagination

**Date:** 2026-09-19  
**Status:** Iteration 4 implemented locally; deployment smoke pending

## Problem

The tenant application had a Students workflow but no dedicated host screen
for creating and managing Proctors and Examiners. Several primary tables also
loaded unbounded result lists or did not expose pagination consistently.

## User stories

- As a host administrator, I can open one Exam Staff screen and see Proctor and
  Examiner accounts together.
- As a host administrator, I can create an Exam Staff account by choosing its
  role and entering the required identity and credential fields.
- As a host administrator, I can search, filter, sort, and page through Exam
  Staff without downloading every tenant user.
- As a host administrator, I can keep using the existing Students screen and
  Student Excel import workflow.
- As a host administrator, I can see pagination on the dashboard learner
  overview, Audit Log, and Order history screens.
- As a host administrator, I can see a consistent Users/Delivery navigation
  hierarchy.

## Scope

### In scope

- A tenant-scoped `GET /api/v1/users/exam-staff` endpoint.
- Server-side Exam Staff search, role/status filtering, sorting, and paging.
- A tenant-web Exam Staff route, list, create modal, and lifecycle actions.
- API-client types and request helpers for Exam Staff paging.
- Pagination for LearnersOverview, Audit Log, and Order history.
- Navigation grouping changes in tenant-web.
- Automated backend, API-client, type-check, lint, build, and deployed-browser
  verification.

### Out of scope

- Renaming the Students route or replacing the existing Student import flow.
- Changing the response shape of the existing `GET /api/v1/users` endpoint.
- Creating or importing persistent production test data.
- A new password-generation policy for single-account Exam Staff creation.
- Pagination changes to every contextual assignment lookup or every small list
  endpoint.

## Functional requirements

### Exam Staff API

```text
GET /api/v1/users/exam-staff
  ?page=0
  &size=20
  &search=
  &role=ALL|PROCTOR|EXAMINER
  &status=ALL|ACTIVE|SUSPENDED
  &sort=CREATED_AT|FULL_NAME|EMAIL
  &direction=ASC|DESC
```

Rules:

- The caller tenant is derived from the authenticated context.
- Only `PROCTOR` and `EXAMINER` role records are returned.
- Negative pages normalize to zero.
- Non-positive sizes use the default size; sizes above 100 are capped at 100.
- Search matches normalized full name, email, or username.
- Sorting adds a public-id tie-breaker for deterministic page boundaries.
- Invalid role, status, sort, or direction values return a domain validation
  error.

### Exam Staff form

- Role: Proctor or Examiner.
- Email: required and validated as an email address.
- Full name: required.
- Temporary password: required by the current backend create-user contract;
  minimum length eight.
- The form sends the selected role as the only requested role.

### Student behavior

- Students remain on `/host/students`.
- Existing roster search/filter/sort/page behavior remains unchanged.
- Student create/import fields are not marked required in the frontend bulk
  workflow.
- Student import still requires selecting an `.xlsx` file before submission.

### Navigation

```text
Users
  Learners
  Exam Staff

Delivery
  Program
  Exams
```

## Non-functional requirements

- Preserve tenant isolation and existing authorization boundaries.
- Preserve the old unpaged user-list contract for assignment consumers.
- Reuse the shared `PagedResult`/`PageMeta` response shape.
- Keep browser smoke checks non-mutating by intercepting write requests when
  running against production.

## Iteration 2 requirements

### Common row action menu

- `@pte/ui` SHALL expose one accessible, portal-positioned three-dot action
  menu for row actions.
- Items SHALL support label, optional icon, danger tone, disabled state,
  conditional visibility, and optional separators.
- The menu SHALL close after selection and retain keyboard/focus-visible
  accessibility of the existing dropdown.
- The tenant and vendor CRUD/lifecycle tables audited in this iteration SHALL
  use the common menu where actions are currently duplicated as inline buttons
  or ad-hoc dropdowns.
- Contextual assignment/review controls MAY remain inline when the menu would
  add friction or obscure a high-frequency action; the plan records each
  exception.

### Exam Staff actions

- Each Exam Staff row SHALL expose `View details`.
- Each Exam Staff row with an email SHALL expose `Send email`.
- `Send email` SHALL generate a new temporary password, invalidate the previous
  password, set first-login password change, and enqueue an email containing
  the username and temporary password.
- The UI SHALL show the newly generated password once in the authenticated
  action result with a copy affordance and an explicit one-time warning.
- Suspended/reactivated state actions SHALL remain available through the same
  menu and retain confirmation for suspension.

### Student action boundary

- Student rows SHALL NOT expose `Send email`.
- Student account details SHALL continue to expose only safe metadata and
  first-login state.
- The credential-email endpoint SHALL reject Student targets before reading or
  changing the login hash.
- Proctor and Examiner targets SHALL retain the credential-email action.

### Account and password visibility

- Student and Exam Staff tables SHALL display the login username in an
  `Account` column.
- Existing passwords SHALL NOT be returned from GET endpoints or persisted in
  plaintext.
- Student `Generate password` SHALL rotate a fresh temporary password without
  sending email and return it once to the authorized Host.
- The one-time result SHALL include the username and password with copy support
  and an explicit warning that closing it loses the plaintext credential.
- Student create/import SHALL continue to show/download generated credentials
  only in the existing one-time result flow.

### Host account visibility

- Host user listings and details SHALL include the login `username` and
  `mustChangePassword` state.
- They SHALL NOT include a password, password hash, or historical generated
  credential.
- A Host can verify a credential only by using the one-time result from create
  or the fresh temporary password result from the send/reset flow.

### Backend contract

```text
POST /api/v1/users/{publicId}/credentials/send-email
  -> { publicId, username, email, temporaryPassword, emailQueued }
```

The endpoint is tenant-scoped, role-authorized, and does not accept a password
from the browser. The returned temporary password is write/return-once and is
not persisted in notification logs.

### Audit scope

The implementation audit covers all `pte-web/apps/tenant-web` and
`pte-web/apps/vendor-web` table/list screens with row-level create, update,
delete, suspend/reactivate, activate/archive, revoke, view, or credential
actions. Assignment and answer-review tables are documented as contextual
exceptions when they do not represent CRUD resources.
