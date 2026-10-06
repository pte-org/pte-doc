# Phase 3 — Import Help Text + Drop Dead Column

**Status**: completed (2026-10-04)
**Surface**: `ImportOrAssignModal` (help text), `ClassesListView` (column
removal)
**ACs covered**: AC10, AC12
**Stories**: S9, S10
**Risk**: low — copy + small layout change
**Quality**: skipped_by_user; decision: user_confirmed_skip
**Testing**: not started — user declined tests (chose "code only, no tests")
**Build Gate**: PASS — `pnpm --filter tenant-web build` (TypeScript OK);
`eslint features/classes features/programs` → 0 problems.

**Preflight (ck-cook Step 1, 2026-10-04)** — repo `pte-web` @ `hung/feat/classes-entry`:
- **Repository conventions**: per-feature copy in `constants/index.ts` as
  `XXX_TEXT` / `XXX_HELP` objects; `_`-prefixed components are feature-private;
  `DataTableColumn[]` drives the table, so removing a column means removing one entry
  from that array.
- **Boundaries**: `apps/tenant-web` only. No backend, no package changes.
- **Applicable rules**: no hardcoded strings in JSX; no `any`; file ≤300 lines.
- **Allowed exceptions**: none.
- **Notes**: `_RosterDropzone.tsx` had no way to render secondary copy, so a
  `helperText` prop was added rather than hardcoding a `<p>` in the modal — it keeps the
  dropzone the owner of its own layout. The now-unused
  `CLASSES_LIST_TEXT.studentCountPlaceholder` was deleted along with the column, so no
  dead constant is left behind.

**Files written (Phase 3)**:
- Modified: `features/classes/components/ClassesListView.tsx`,
  `features/classes/components/ImportOrAssignModal.tsx`,
  `features/classes/components/_RosterDropzone.tsx`,
  `features/classes/constants/index.ts`,
  `unhappy-cases-survey.md` (C28, X8 marked fixed)

---

## Design Constraints

- **Help text** is a single line of copy. Add it under the dropzone in
  the Import tab. Per spec §6, all new copy lives in
  `features/{name}/constants/index.ts`.
- **Drop the "Students" column** from `/host/classes` table. The
  placeholder `—` is hardcoded; column removal is the cleanest fix per
  Researcher D2. **Verify the layout still aligns** at `xl` breakpoint
  (per AC12).
- **No backend changes**.

## Quality and Testing State

- **Quality**: not evaluated
- **Testing**: not started

---

## Tasks (in order)

### 3.1 — Import tab help text (C28, S9, AC10)

**File**: `apps/tenant-web/features/classes/components/ImportOrAssignModal.tsx`

Find the dropzone area in the Import tab. Add a one-liner of help text
immediately below it (between the dropzone and the file list):

> "If your file has a `className` column, it overrides the target class.
> Leave it blank to assign rows into the current class."

Add the copy to `features/classes/constants/index.ts` as a new key, e.g.
`IMPORT_HELP.classNameOverride`. No hardcoded strings in JSX.

### 3.2 — Drop the "Students" column (X8, S10, AC12)

**File**: `apps/tenant-web/features/classes/components/ClassesListView.tsx`

Remove the column definition that renders
`CLASSES_LIST_TEXT.studentCountPlaceholder`. This affects:
- The `columns` array
- The `ColumnDef<...>` type if the column has a unique generic
- The header labels array (if it exists separately)

Verify the table renders correctly at:
- `sm` (mobile)
- `md` (tablet)
- `lg` (desktop)
- `xl` (large desktop) — **explicit AC12 check**

If layout breaks at any breakpoint because of a leftover cell or header,
fix it. The program filter dropdown is the only filter affordance for
this table.

### 3.3 — Update survey

**File**: `plans/hung/tenant-programs-classes-learners/unhappy-cases-survey.md`

Mark C28, X8 with `**[fixed 2026-10-02]**` in the Notes column. Add a
short line under each row's Notes: "Phase 3 of
`tenant-programs-classes-learners` plan".

### 3.4 — Verify

- `pnpm lint`
- `pnpm typecheck`
- `pnpm build`

Manual:
- Open `/host/classes` Import tab → see help text under dropzone.
- Open `/host/classes` table → "Students" column is gone; layout is
  clean at all 4 breakpoints.
- Hover over rows / open kebab / archive → still works (regression
  check from Phase 1).

## Sub-tasks checklist

- [x] 3.1 — Import help text + constants key
- [x] 3.2 — Drop Students column + layout verification (manual breakpoint check pending)
- [x] 3.3 — Update survey
- [x] 3.4 — Lint / typecheck / build (manual smoke pending)

## Notes

- This phase is intentionally short. It can be merged independently of
  Phases 1 and 2.
- If Phase 1 hasn't shipped yet, AC1/AC2 dialogs won't be visible during
  the manual smoke — that's fine, the regression check is just for the
  column removal.