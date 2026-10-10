# Plan: Student Import — System Excel Template (Task #63)

Status: 🟢 Planned and validated, not started
Date: 2026-10-08
Mode: Fast
Test: default (no `--tdd`)
Created by: Ninh
Target platform: Web (`pte-web` `apps/tenant-web`). No `pte-api` change.

## Task

> #63 — Chỉnh sửa import student phải có 1 form excel mẫu của hệ thống để
> tenant tải về và upload lên.

## Scope Challenge

```
# Exists?     → Import exists in 3 UIs, all fed by one parser (`parseRosterFile`
#               in features/examoperations/cleanRosterFile.ts). NO template
#               download exists anywhere (grep "template" in classes /
#               examoperations / studentSearch / programs = 0 hits).
# Minimum?    → Generate a .xlsx template client-side (SheetJS is already a
#               dependency; downloadCredentials.ts is the precedent), add a
#               "Download template" button to the 3 import UIs, and make the
#               parser reject files that don't use the template's headers.
# Complexity? → Fast — familiar pattern, one app, no backend, no security surface.
#               (≈6 files across 2 features, so it brushes the "multi-file"
#               Hard trigger; kept Fast because nothing is unfamiliar and there is
#               no alternative architecture worth researching. Re-run with --hard
#               if you want research + red-team.)
```

### Findings that shape the plan

1. **Three import entry points, one parser.**
   - `classes/components/_ImportExcelTab.tsx` (Class detail → ImportOrAssignModal) — creates accounts via `bulkCreateUsers`, then assigns to the class.
   - `examoperations/components/RosterImport.tsx` — creates accounts for an exam session.
   - `examoperations/components/ExistingStudentImportModal.tsx` — does NOT create accounts; matches rows to *existing* students by email → username → studentCode.
2. **The parser is permissive, and that is a latent bug, not just a missing feature.**
   `extractRosterRows` maps headers through `HEADER_ALIASES`, but a row with data in
   *unrecognised* columns still becomes an empty `{}` row (`hasData` is checked on raw
   cells, not on mapped fields). A random spreadsheet therefore "imports" N blank
   rows. The bulk-create row DTO has no required field, so the backend accepts them
   and generates anonymous accounts that consume tenant quota. A system template is
   only meaningful if the parser then *enforces* it.
3. **Parser scans up to 20 sheets and returns the first with rows.** If the template
   ships an "Instructions" sheet, a template left otherwise empty would fall through
   and parse the Instructions sheet as data. Must be guarded by finding 2's fix.
4. **Columns the create flows actually send** (`useCreateRosterAccountsForClass`):
   `email, fullName, studentCode, className, phone, dateOfBirth`. `username` is parsed
   but dropped on create (it is only used by the existing-student matching flow).
5. **Date handling is already solved**: parser converts Excel date cells to ISO
   `yyyy-MM-dd`; strings pass through. Template just documents the format.
6. **Limits to state in the template**: `.xlsx` only, client max 5 MB
   (`MAX_FILE_SIZE_BYTES`), backend `/students/import` allows 10 MB / 10 000 rows
   (that endpoint has no frontend consumer — out of scope).
7. `tenant-web` has no test runner (only `packages/api-client` has `*.test.ts`).
   Adding test infra is out of scope (YAGNI); verification = `tsc` + `eslint` +
   manual round-trip.

## Decisions (validated with Ninh, 2026-10-08)

1. **One shared template** for all 3 import UIs, including the existing-student modal
   (extra columns are simply ignored there).
2. **`Full Name` is marked required** in the `Instructions` sheet; every other column
   optional. Guidance only — the parser does not enforce it.
3. **Strict header check**: a file with no recognised header is rejected with a
   "use the system template" error instead of importing blank rows.
4. **Template generated client-side with SheetJS**; no `pte-api` change.

## Out of scope

- Backend template endpoint / changing `POST /api/v1/students/import`.
- ~~Adding a unit-test runner to `tenant-web`.~~ **Reversed at cook time (Ninh asked for
  unit tests):** `vitest ^3.2.7` + `vitest.config.ts` + `"test": "vitest run"` added,
  mirroring `packages/api-client`.
- Vietnamese header aliases (`normalizeHeader` strips non `[a-z0-9]`, so diacritics
  would not match anyway).

## Phases

- [x] Phase 1: Template generator + strict header validation in the parser
      (`features/examoperations`) — see `phase-01-template-and-parser.md`
      [quality: see Cook Notes; testing: 29 vitest tests passing]
- [x] Phase 2: "Download template" button wired into the 3 import UIs + help text
      + manual E2E — see `phase-02-ui-wiring.md`
      [quality: see Cook Notes; testing: automated parser/template tests pass;
      **manual browser checklist not yet run**]

## Cook Notes (2026-10-08)

- Cooked with `--fast`, then Ninh asked for unit tests + the quality gate on top.
- Independent reviewer returned `CHANGES_REQUIRED` once. Fixed: F1 (MEDIUM, blocking —
  Excel stores a typed `0901234567` as a number, dropping the leading zero; Phone and
  Student Code are now documented as Text in the template), F2 (username-only rows
  slipped through for the create flows; `parseRosterFile(file, { allowUsername })`, only
  the existing-student modal passes `true`), F3 copy, F4 prettier, F5 type moved to
  `types.ts` + magic number named. New tests cover F1/F2.
- Deviations from the plan: constants live in a new `features/examoperations/constants.ts`
  (CLAUDE.md feature layout) rather than `components/constants.ts`, so the feature now has
  two `constants.ts` files; the `IMPORT_HELP` text in `features/classes` was **not**
  changed — the button's own hint covers it.
- Known residual items (not fixed, not introduced here): CI runs only lint+build so the
  new tests run on `pnpm test` / `turbo test` only; `SkippedRowsReport` "Row" numbers
  index the compacted rows array, not Excel row numbers; `RosterImport` was already over the
  150-line component limit; `xlsx@0.18.5` has known CVEs on untrusted files.

## Risks

- **Existing users with their own spreadsheet headers** (e.g. a column called
  "Họ tên" or "Mã SV") currently "work" only by accident — they produce blank rows.
  After Phase 1 they get a clear error pointing to the template. Intended, but call
  it out in the PR description.
- **Example data in the template would be imported as real students if left in.**
  Mitigation: the `Students` sheet contains the header row only; examples live on the
  `Instructions` sheet.
- **No automated tests** for the parser change (see finding 7) — residual gap,
  mitigated by the manual checklist in Phase 2.

## Ready to cook

```
/ck:cook --fast plans/ninh-import-student-template/plan.md
```
