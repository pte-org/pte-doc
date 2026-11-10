# Phase 02 — Backend: import validation and cleanup

**Repo:** pte-api · **Depends on:** 01 · **Status:** Done

## Changes

1. Row validation on `POST /api/v1/users/bulk` (server re-checks what the web preview shows; never trust the client):
   | Field | Rule | Code |
   |---|---|---|
   | Email | required, valid, ≤ 254, unique in file | `EMAIL_REQUIRED`, `EMAIL_INVALID`, `DUPLICATE_EMAIL_IN_BATCH` |
   | Full Name | required, ≤ 100 | `FULL_NAME_REQUIRED`, `FULL_NAME_TOO_LONG` |
   | Student Code | optional, ≤ 50 | `STUDENT_CODE_TOO_LONG` |
   | Program Name, Class Name | optional, ≤ 100 each; not validated against real programs/classes and not used for placement (D9 deferred) | `PROGRAM_NAME_TOO_LONG`, `CLASS_NAME_TOO_LONG` |
   | Phone | optional, digits only (leading + allowed), 9–15 digits | `PHONE_INVALID` |
   | Date of Birth | optional, ISO date in the past | `DATE_OF_BIRTH_INVALID` |
   Any format error rejects the whole request (400) with `data = [{ row, field, code }]`, so nothing is created.
   Quota and "already in this organization" keep their current behaviour.
2. Response rows carry `username`, `email`, `fullName`, `generatedPassword` (credentials file and optional e-mail).
3. Optional `sendCredentialsEmail` flag on the request: after commit, publish one credentials e-mail per created
   Student through the existing credentials e-mail path (`/users/{id}/credentials/send-email` service), outside the
   creation transaction; failures are reported per row, not rolled back.
4. Remove the legacy endpoint: `StudentRosterImportController`, `StudentRosterImportService`, `RosterFileService`,
   `InvalidRosterFileException` and their tests, plus constants used only by them (`ROSTER_*` file/row/credential
   constants that have no other reference). Keep `GET /students/import/preview` (quota preview in `tenancy`).
5. Update `ApiInventoryExportTest` expectations / inventory snapshot (one endpoint fewer).

## Tests

- Validation table above: one test per rule; mixed valid/invalid file creates nothing.
- `sendCredentialsEmail=true` publishes N e-mails; a failing send does not undo account creation.
- Architecture ratchets still pass (package density after deletions).

## Validation

`.\mvnw.cmd -pl app test`; rebuild and restart the local `app` container.
