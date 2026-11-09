# Phase 03 — Tenant web: template, strict check, preview

**Repo:** pte-web (`apps/tenant-web`, `packages/api-client`) · **Depends on:** 02 · **Status:** Done

## Changes

1. Template (`features/examoperations/constants.ts`, `rosterTemplate.ts`): columns in this order —
   Email (required), Full Name (required), Student Code, Program Name, Class Name, Phone, Date of Birth.
   - Row 2 of the Students sheet is a sample row, marked in the first cell (for example
     `example@student.com  ← sample row, ignored on import`) and carrying the notes: Program Name / Class Name are
     for reference and can be left blank if the Student is not in a program or class yet; the e-mail receives scores
     and account details; the system creates the username.
   - The parser skips row 2 when it is the sample row (matched on the sample marker), so an untouched template
     imports nothing; this replaces the old "header-only Students sheet" rule.
   - Instructions sheet: same notes plus the format table. Remove the incorrect note "a filled Class Name overrides
     the class you are importing into"; class placement keeps today's behaviour (class page import assigns all
     created Students to that class).
2. Strict structure check (`cleanRosterFile.ts`): the file must have a `Students` sheet whose row 1 matches the
   template headers exactly (case and spacing tolerant, no aliases such as `name`/`dob`); missing required column or
   unknown column → reject the whole file with the column names and a "download template" action. Keep the
   existing-account matching flow (`allowUsername`) on its own header rules.
3. Preview table: client-side checks with the same rules as phase 02; invalid cells highlighted with row number and
   reason; Confirm disabled while any error remains; server errors (`data[]` from phase 02) mapped back onto rows.
4. Single "add Student" form: Email and Full Name required; the result dialog shows the generated username.
5. Credentials download (`downloadCredentials.ts`): columns Email, Full Name, Username, Temporary password; checkbox
   "E-mail account details to each Student" sending `sendCredentialsEmail`.
6. `packages/api-client`: remove `requests/admin/studentRosterImport.ts` and its export; update request/response
   types for `bulkCreateUsers`.
7. Messages (vi/en) for every new error code.

## Tests

Vitest: header check (exact, missing, extra, alias rejected), row rules, Confirm disabled with errors, credentials
file columns, api-client types. `pnpm` typecheck + eslint for tenant-web and api-client. No browser testing
(user checks UI).
