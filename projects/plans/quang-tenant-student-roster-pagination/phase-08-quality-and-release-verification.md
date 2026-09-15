# Phase 08: Quality and release verification

## Goal

Prove the complete API-to-browser flow and document the safe deployment order.

## Work items

1. Run the affected backend compile/build and frontend lint/typecheck/build
   checks. Record commands and exit codes.
2. Run the required `ck:quality` audit for the changed scope: Admin messaging,
   the projection, the IAM event and reactivate changes, the internal export and
   backfill, the roster API, `@pte/api-client`, `@pte/ui`, and tenant-web.
   Resolve any BLOCKER/HIGH findings before release; do not auto-commit.
3. Execute authenticated API acceptance checks:
   - default page and newest-first order;
   - page-size cap and past-last-page behavior;
   - search across all four fields;
   - Program/Class/Assigned/Unassigned filters;
   - stable tie ordering across repeat requests;
   - cross-tenant ids rejected or returning no data;
   - unauthorized caller rejected;
   - internal export rejected without service auth;
   - suspend then reactivate, with login blocked and restored accordingly.
4. Execute a browser walkthrough:
   - initial page load;
   - next/previous page and page-size change;
   - changing sort and filters;
   - creating and importing a student;
   - seeing an unassigned student;
   - assigning/transferring a Class and seeing the row update;
   - suspending and reactivating a student from the row;
   - loading, empty, error, and narrow viewport states;
   - vendor-web regression check on the shared pagination component.
5. Deployment runbook, in this order:
   - apply the idempotent schema migrations (`processed_events`, then
     `student_roster_entries` and its indexes);
   - deploy IAM and Admin, wait for healthchecks, confirm the Admin queue, DLQ,
     and binding to `outbox.iam.exchange` are declared;
   - run the projection backfill once and confirm row counts per tenant;
   - deploy/rebuild tenant web;
   - smoke-test the tenant Students route and the paged endpoint;
   - inspect logs for consumer failures, DLQ arrivals, or repeated query errors.
6. Record rollback notes: frontend rolls back independently; the projection
   table and event consumers must remain backward-compatible; the widened
   `UserCreatedEvent` is additive so an older Admin build still parses it; no
   user or data deletion is part of rollback.

## Design constraints

- No unit-test command unless the user changes the existing `unitest: ko` choice.
- Quality review is mandatory (`quality: có`).
- Do not mark deployment successful from a build alone; verify the live API and
  browser behavior against the VPS.
- Do not expose credentials, tokens, private keys, or database passwords in
  logs, reports, or the runbook.
- No automatic commit or push.

## Quality and testing state

- Unit tests: skipped by user preference unless explicitly changed.
- Quality: approved with 0 findings; see
  `quality/phase-08-quality-and-release-verification-quality-report.json`.
- Manual/API verification: passed against the local Docker deployment.
- Browser walkthrough: passed at desktop and narrow viewport sizes.

## Acceptance criteria

- All required build/lint/typecheck checks pass.
- Quality audit has no unresolved BLOCKER/HIGH finding.
- Live VPS endpoint returns a bounded paged response and remains tenant-scoped.
- The Admin consumer processes live events with no DLQ arrivals during the smoke
  test.
- Browser walkthrough confirms default visibility, sort, filters, pagination,
  create/import refresh, and suspend/reactivate.
- vendor-web shows no visual or type regression from the shared-package changes.
- No commit or push is created automatically.

## Cook status

- Implemented and verified locally on 2026-09-15.
- Unit tests skipped by explicit user preference.
- Live VPS deployment and live-domain smoke testing remain pending as release
  operator steps; this cook did not claim them as successful.
- No commit or push created.
