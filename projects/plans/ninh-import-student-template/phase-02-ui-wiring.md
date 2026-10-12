# Phase 2: Wire "Download template" into the import UIs

## Requirements

Every place a tenant uploads a student Excel file offers the system template next to
the dropzone, with a one-line explanation.

## Design Constraints

- Depends on Phase 1 (`downloadRosterTemplate`, parser behaviour).
- One small presentational component `RosterTemplateButton` in
  `features/examoperations/components/` (exported from the barrel). `classes` already
  imports `SkippedRowsReport` from `@/features/examoperations/components`, so reuse
  follows existing precedent. Props: none beyond an optional `className`; label text
  from constants.
- Wire into the three entry points:
  - `classes/components/_ImportExcelTab.tsx` — above/below `RosterDropzone`; extend
    `IMPORT_HELP` text to mention the template.
  - `examoperations/components/RosterImport.tsx`
  - `examoperations/components/ExistingStudentImportModal.tsx` — same shared template
    (decided); its helper text should say only Email / Username / Student Code are used
    for matching.
- Use the existing `Button` from `@pte/ui` (`variant="secondary"`), no inline styles, no
  hardcoded JSX strings, Tailwind only.
- Do not change create/assign behaviour — this phase is additive UI.

## Files

- `features/examoperations/components/RosterTemplateButton.tsx` (new)
- `features/examoperations/components/index.ts` (export)
- `features/classes/components/_ImportExcelTab.tsx`
- `features/classes/constants/index.ts` (`IMPORT_HELP`, button label if not shared)
- `features/examoperations/components/RosterImport.tsx`
- `features/examoperations/components/ExistingStudentImportModal.tsx`
- `features/examoperations/components/constants.ts`

## Manual Verification Checklist

1. Class detail → import modal: button visible, downloads `.xlsx`; open it and confirm
   sheets/headers.
2. Fill 2 students (one with a Date of Birth typed as a real Excel date), upload → "Rows
   found: 2" → create → 2 accounts, credentials download works, students assigned to
   the class.
3. Upload the untouched template → clear "no data rows" error (not Instructions parsed).
4. Upload an unrelated spreadsheet → "use the system template" error.
5. Repeat 1–4 from the exam-session roster import and the existing-student modal.
6. `pnpm --filter tenant-web exec tsc --noEmit` and `eslint` clean.

## Quality and Testing State

- Quality: not evaluated
- Testing: not started
