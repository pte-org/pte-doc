# Phase 1: Template generator + strict header validation

## Requirements

Provide a function that produces the system's student-import workbook, and make
`parseRosterFile` accept only files that use recognised headers, so "download
template → fill → upload" is the one supported path.

## Design Constraints

- Lives in `apps/tenant-web/features/examoperations/` next to `cleanRosterFile.ts` and
  `downloadCredentials.ts` (the `classes` feature already imports from here; do not
  move to `@pte/ui` — it is roster-specific, not generic UI).
- New file `rosterTemplate.ts`: `downloadRosterTemplate(fileName?: string): void`,
  same shape as `downloadCredentials` (`XLSX.utils.*` + `XLSX.writeFile`).
- Workbook layout:
  - Sheet 1 `Students`: header row only, **no example row** (a left-behind example
    would be imported as a real student). Headers must normalise (via the parser's
    `normalizeHeader`) to existing `HEADER_ALIASES` keys: `Email`, `Full Name`,
    `Student Code`, `Class Name`, `Phone`, `Date of Birth`.
  - Sheet 2 `Instructions`: column | required? | format | example; limits (.xlsx,
    ≤ 5 MB); note that `Class Name` overrides the target class when filled.
- Header labels, sheet names and instruction text come from a `constants.ts` object
  (no hardcoded strings), and the header list is the **single source of truth**
  shared by the template and a parser self-check (so the two cannot drift).
- Parser change (`cleanRosterFile.ts`):
  - A sheet is only eligible if its header row maps ≥ 1 header to a field.
  - Rows with no mapped field values are dropped (fixes the blank-`{}` row bug).
  - If no sheet is eligible, throw `UserFacingError` with a message that tells the
    user to download the system template (constant, not inline).
  - Keep `HEADER_ALIASES` as is — loosening or tightening aliases is not part of this
    task.
- File ≤ 300 lines, no `any`, return types on exports, no `// @ts-ignore`.

## Files

- `features/examoperations/rosterTemplate.ts` (new)
- `features/examoperations/constants.ts` or `components/constants.ts` (template text — put
  with the other examoperations constants; check which file already owns roster text)
- `features/examoperations/cleanRosterFile.ts` (edit)

## Success Criteria

- Downloaded file opens in Excel with a `Students` sheet containing exactly the header
  row and an `Instructions` sheet.
- Uploading the untouched template reports the "no data rows" error, **not** a
  parse of the `Instructions` sheet.
- Uploading a file whose headers are all unrecognised reports the "use the system
  template" error instead of N blank rows.
- Uploading a template with 2 filled rows yields exactly 2 `RosterRow`s with the right
  fields (including an Excel date cell → `yyyy-MM-dd`).

## Quality and Testing State

- Quality: not evaluated
- Testing: not started (no unit-test runner in `tenant-web`; verified via tsc + eslint +
  Phase 2 manual checklist)
