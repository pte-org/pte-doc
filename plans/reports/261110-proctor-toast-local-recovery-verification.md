# Proctor toast and local backend verification

Date: 2026-11-10 (Asia/Bangkok). Local environment only; no deployment.

## UI changes

- Common toast replaces transient session-refresh and Proctor action error banners.
- Continuous polling failures notify once until recovery; closed forms do not replay stale errors on reopening.
- Initial loading failures retain a persistent error state and retry action.
- Attendance version conflicts and other business warnings remain in context.
- Vendor organization application refresh failures also use the common toast.

## Local backend recovery

V11 and V14 migration resources were restored to their historical contents. The previous recovery work backed up the local database to the private workstation PTE directory, compared it with a reference schema, reconciled missing constraints/indexes and migration effects, archived legacy chat tables, and registered verified migration history through V40. No production database was involved.

Current checks independently confirm:

- App container reports `healthy`.
- Health endpoints on localhost ports 8091 and 8080 return HTTP 200.
- Proctor login and assigned session API succeed through port 8080.
- UI-WEEK-3 violations API returns 6 records.
- Security audit returns 20 records on page one and 14 on page two using the returned cursor.
- Incident search for `tai nghe` returns one result.
- Examiner login succeeds; its work queue returns 4 items.
- Tenant Proctor route on localhost port 3000 returns HTTP 200.
- Tenant and vendor TypeScript checks and 52 focused Proctor tests pass.

Previous full tenant verification in this task: 100 files / 1,002 tests passed. No browser or Playwright verification was performed.

## Remaining observation

The app log contains a separate scheduled-task `TransactionRequiredException` for an update/delete query. This does not prevent the health, login, or role APIs verified above. That background-job issue has not been changed in this task.
