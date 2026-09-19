# Brainstorm: Tenant users, exam staff, and production pagination

**Date:** 2026-09-19  
**Status:** Iteration 2 planned; implementation in progress

## Ideas explored

1. **Merge every account type into one Users screen.** This was considered,
   but rejected for the current scope because Students already have a mature
   roster/import workflow and different data requirements.
2. **Keep Proctor and Examiner as separate screens.** Rejected because both
   are exam-delivery staff and share the same create/list/lifecycle behavior.
3. **Create one Exam Staff screen.** Selected: one role selector creates either
   a Proctor or Examiner, while the table can filter both roles.
4. **Reuse `GET /users` and paginate in the browser.** Rejected for Exam Staff:
   the existing endpoint returns every tenant user and is also used by
   assignment flows. A dedicated tenant-scoped paged query avoids changing
   that contract.
5. **Paginate the primary tables with the existing common page contract.**
   Selected: use `PagedResult`/`PageMeta` on the backend and
   `PaginationControls` on the tenant web.

## User direction

- Students stay on the existing Students screen.
- Student Excel import remains available.
- Proctor and Examiner are managed together as Exam Staff.
- Email and full name are required for Exam Staff.
- Student profile fields remain optional in the bulk/create workflow.
- The navigation group is renamed from Learners to Users. Users contains
  Learners and Exam Staff. Delivery contains Program and Exams.
- Existing screens that load potentially large primary lists should use proper
  server-side pagination where the backend contract supports it.

## Resolved decisions

- Exam Staff default page size is 20, with 20/50/100 options and a backend
  maximum of 100.
- Exam Staff supports search, role filter, status filter, and deterministic
  sort options.
- The current create-user contract still requires a temporary password, so the
  Exam Staff form keeps that field in addition to the required email and full
  name.
- The existing unpaged `GET /users` contract is preserved for assignment
  consumers.

## Open follow-ups

- A real Exam Staff account was not created in production during smoke testing;
  the valid create payload was intercepted to avoid leaving test data.
- A real Excel file was not uploaded in production for the same reason.
- The deployed tenant had zero Exam Staff accounts, so real-row
  Suspend/Reactivate actions were not exercised against a persisted row.
- Contextual assignment lookups and smaller Program/Class/Session list
  contracts remain candidates for a later pagination pass.

## Risks

- Changing the existing `GET /users` response shape would regress assignment
  flows; the dedicated Exam Staff endpoint avoids that risk.
- Page/filter state must reset to page zero when a query changes.
- Tenant scope must always come from the authenticated caller, never from a
  client-supplied tenant id.
- Production smoke tests must avoid creating accounts or importing files unless
  the operator explicitly authorizes test data mutation.

## Iteration 2: common row actions, staff email, and account visibility

**Date:** 2026-09-19

### User direction

- Keep this plan updated before and during every subsequent user-management or
  CRUD/action-menu change.
- Add a row action to send an Exam Staff account email alongside the existing
  lifecycle actions.
- Build one reusable three-dot action menu, based on the current tenant/vendor
  interaction pattern, and apply it to suitable CRUD/lifecycle tables across
  `pte-web`.
- Let a Host inspect the accounts in its own organization so that the login
  username and credential state can be verified.

### Exploration and decisions

1. `@pte/ui` already has a portal-based `Dropdown` and a three-dot trigger.
   Evolve it into the common action-menu primitive instead of introducing a
   second incompatible menu implementation.
2. The menu item contract needs optional icons, danger styling, disabled state,
   hidden items, and separators. It must remain domain-neutral so vendor and
   tenant screens can share it.
3. The existing password reset endpoint accepts an operator-chosen password
   and returns no credential. A send-email action cannot recover the old
   password because only a hash is stored. It will therefore generate a fresh
   readable temporary password, replace the hash, mark first-login change, and
   queue a credential email.
4. The generated password may be returned only in the immediate authenticated
   action response for the operator to save once. It must never be included in
   `UserResponse`, notification history, database columns, or subsequent GETs.
5. Account details expose safe account metadata (`username`, email, roles,
   status, and first-login state). They never expose a password or password
   hash. A new temporary password is the only supported way to verify a login
   credential.
6. Existing inline actions will be converted where the row represents a
   manageable resource: Students, Exam Staff, tenant/vendor tenancy records,
   plans, license codes, applications, and other CRUD/lifecycle tables found
   by the audit. Assignment/unassignment and answer-review controls remain
   contextual controls unless a menu improves clarity without hiding a
   frequent operation.

### Security boundary

- Tenant scope continues to come from the authenticated Host context.
- Sending credentials requires a non-empty user email and the same target-role
  authorization as password reset.
- Passwords are generated with the server `SecureRandom` generator and are
  delivered over the authenticated response/email queue only once.
- Production smoke tests must intercept all credential-changing requests.
