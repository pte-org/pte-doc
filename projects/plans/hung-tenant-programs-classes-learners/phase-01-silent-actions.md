# Phase 1 — Silent Destructive Actions

**Status**: completed (2026-10-04)
**Surface**: Programs (`ProgramDetailView`), Classes (`ClassRowActions`),
Roster (`ClassRosterTable` row `RowActions`), Transfer (`TransferStudentModal`),
Merge (`MergeClassesModal`)
**ACs covered**: AC1, AC2, AC3, AC4, AC5, AC6
**Stories**: S1, S2, S3, S4, S5
**Risk**: medium — touches 4 components, all with existing data flow
**Quality**: skipped_by_user; decision: user_confirmed_skip
**Testing**: not started — user declined tests (chose "code only, no tests")
**Build Gate**: PASS — `pnpm --filter tenant-web build` (TypeScript OK, 23 routes);
`eslint features/classes features/programs` → 0 problems.
  Pre-existing unrelated lint error in `features/exams/components/CreateExamWizard.tsx`
  (`react-hooks/set-state-in-effect`, from commit `c436e6a`) was NOT introduced here and
  is out of this phase's scope.

**Files written (Phase 1)**:
- Modified: `features/programs/components/ProgramDetailView.tsx`,
  `features/programs/constants/index.ts`,
  `features/classes/components/ClassesSection.tsx`,
  `features/classes/components/ClassRosterTable.tsx`,
  `features/classes/components/TransferStudentModal.tsx`,
  `features/classes/components/MergeClassesModal.tsx`,
  `features/classes/constants/index.ts`
- Created: `features/classes/components/ClassRowActions.tsx`,
  `features/classes/components/ClassStatusConfirmDialogs.tsx`,
  `features/classes/components/NonActiveTargetConfirm.tsx`,
  `features/classes/constants/confirmText.ts`,
  `features/classes/utils/nonActiveTarget.ts`

**Task status**:
- [x] 1.1 — Program archive description with counts
- [x] 1.2 — Class archive confirm
- [x] 1.3 — 3 other status changes confirm
- [x] 1.4 — Unassign confirm
- [x] 1.5 — Transfer non-active chip + typed-confirm (inline)
- [x] 1.6 — Merge non-active chip + typed-confirm (inline)
- [x] 1.7 — Lint / typecheck / build (tests skipped by user)

---

## Design Constraints

- **No new shared abstraction**: use raw `ConfirmDialog` from
  `packages/ui/` (matches existing pattern in `ProgramDetailView`,
  `ExamStaffView`, `StudentSearchView`).
- **Counts frozen at dialog-open** by reading from the
  `useProgramDashboard.classes[].studentCount` map and passing it as a prop
  to `ClassRowActions`. **No new query per row** (per spec §6 stability
  rule).
- **No `packages/ui/` changes** in this phase — `TypedConfirmInput`
  primitive is created in Phase 2 as a prerequisite for AC4/AC5 consumer
  wiring. **Workaround for AC4/AC5 in this phase**: inline a small
  `typed-confirm` input element inside `TransferStudentModal` and
  `MergeClassesModal` bodies. Once Phase 2's primitive lands, replace
  inline with `<TypedConfirmInput .../>` in a follow-up commit.
- **Each destructive action** (archive, suspend, deactivate, activate,
  unassign, transfer-to-non-active, merge-into-non-active) opens a
  `ConfirmDialog` with `tone="danger"`. No silent mutation paths remain.
- **No double-fire**: `isConfirming={mutation.isPending}` on the confirm
  button; existing `lifecyclePending`/`pending` aggregate preserved.
- **File size rule** (≤300 lines, component ≤150): if `ClassRowActions`
  grows past 150 lines after adding 4 status confirms, extract
  `ClassStatusConfirmDialogs` to a sibling file. Same for `RowActions` in
  `ClassRosterTable` → `RosterRowConfirmDialogs`.

**Preflight (ck-cook Step 1, 2026-10-04)** — repo `pte-web` @ `hung/feat/classes-entry`:
- **Repository conventions** (read from `ProgramDetailView.tsx`, `ClassesSection.tsx`,
  `ClassRosterTable.tsx`, `TransferStudentModal.tsx`, `MergeClassesModal.tsx`,
  `features/classes/constants/index.ts`, `packages/ui/src/components/{ConfirmDialog,Input}.tsx`):
  `ConfirmDialog` already exists in `@pte/ui` with `tone` + `isConfirming`; all copy
  lives in `features/{name}/constants/index.ts` as `XXX_TEXT` / `XXX_ERRORS` objects
  using label-taking arrow functions; queries live in `features/*/api/index.ts`.
- **Boundaries**: UI-only. No `packages/ui` export changes needed (ConfirmDialog and
  Input already exported). No api-client type changes.
- **Applicable rules**: no hardcoded strings in JSX; no inline styles; no `any`;
  file ≤300 lines; component ≤150 lines; dynamic-route loading/error already present.
- **Allowed exceptions**: none.
- **Plan-vs-code drift (plan is stale, code wins)**:
  1. `ClassRowActions` is an **inline component inside `ClassesSection.tsx`**, not a
     separate file. `ClassesSection.tsx` is already 268 lines → confirm dialogs MUST be
     extracted to a new sibling `ClassStatusConfirmDialogs.tsx`.
  2. `ProgramDetailContent` is an **inline component inside `ProgramDetailView.tsx`**,
     not a separate file. `ProgramDetailView.tsx` is 227 lines → keep the dashboard read
     there; do not create a new file.
  3. `ClassResponse` has **no `studentCount` field**. Per-class counts come from
     `useProgramDashboard(...).classes[]` (`ClassStudentCountResponse.studentCount`).
     Counts are already cached under the same query key the dashboard uses, so reading
     them in `ProgramDetailView` adds **no new network request** — pass them down to
     `ClassesSection` → `ClassRowActions` as a prop.

## Quality and Testing State

- **Quality**: not evaluated
- **Testing**: not started

> `ck:cook` will update this section as the user runs quality + test
> gates per phase.

---

## Tasks (in order)

### 1.1 — Program Archive: add counts to existing ConfirmDialog (P7, AC1)

**File**: `apps/tenant-web/features/programs/components/ProgramDetailView.tsx`

The Program Archive button at `ProgramDetailView.tsx:174` already opens a
`ConfirmDialog`. Today the `description` only names the program.

**Change**: read `useProgramDashboard(organizationPublicId, programPublicId)`
in the same component (or hoist from the sibling `ProgramDashboard`),
build a description like:

```
"Archiving <Program name> will also archive its 3 classes and unassign 22 students. This cannot be undone."
```

Use `dashboard.data.classCount` and `dashboard.data.studentCount`. If
`dashboard.data` is `undefined`, show "Loading…" and keep the dialog open.

Add unit test (or a small integration test if a test harness exists) for
the description builder.

### 1.2 — Class Archive: add `ConfirmDialog` to `ClassRowActions` (C7/C8, AC2)

**Files**:
- `apps/tenant-web/features/classes/components/ClassRowActions.tsx` (add dialog)
- `apps/tenant-web/features/classes/components/ClassesSection.tsx` (pass `studentCount` prop)
- `apps/tenant-web/features/programs/components/ProgramDetailContent.tsx` (compute `classStudentCounts` map and pass to `ClassesSection`)

`ClassRowActions` currently has 4 dropdown actions (activate, deactivate,
suspend, archive) that call mutations directly. Per S5, **all four** open
a `ConfirmDialog`. Per S2, the archive dialog shows student count.

**Changes**:
1. Add `studentCount: number` to `ClassRowActions` props.
2. Replace `archive`'s `onSelect` with `setArchiveConfirmOpen(true)`.
3. Add `useState<boolean>` for each of: `archiveConfirmOpen`,
   `activateConfirmOpen`, `deactivateConfirmOpen`, `suspendConfirmOpen`.
4. Render 4 `<ConfirmDialog>` instances at the bottom of the component.
5. Pass `studentCount` into the archive dialog's description.

**File-size guard**: if `ClassRowActions` exceeds 150 lines after edits,
extract confirm dialogs to `ClassStatusConfirmDialogs.tsx` in the same
folder. **Expected outcome**: 4 dialogs likely fit; 4 dropdown items + 4
dialogs + a few useStates = ~120 lines.

### 1.3 — Class Status Changes (activate/deactivate/suspend) (C9/C10, AC6)

Same file as 1.2. Each dropdown item opens a `ConfirmDialog`:

| Action | Title | Description | Tone |
|--------|-------|-------------|------|
| Activate | Activate class? | "This class will become available for new exam assignments." | `default` |
| Deactivate | Deactivate class? | "Students cannot be assigned to this class while deactivated. Existing assignments remain." | `danger` |
| Suspend | Suspend class? | "All scheduled exams for this class will be paused. Students retain their assignments." | `danger` |
| Archive | Archive class? | "This class will be archived along with its N students. This cannot be undone." | `danger` |

The `lifecyclePending` aggregate (already in the parent) disables all
dropdown items while any status mutation is in flight.

### 1.4 — Unassign Confirm (C19, AC3)

**File**: `apps/tenant-web/features/classes/components/ClassRosterTable.tsx` (the inline `RowActions` sub-component)

Add `useState<ClassRosterEntry | null>` for `unassignTarget` and
`useState<boolean>` for `unassignConfirmOpen`. Wire the Unassign button to
`setUnassignTarget(entry); setUnassignConfirmOpen(true)`. Render a
`ConfirmDialog` at the bottom of the component with description
"Unassign <Student full name> from <Class label>? They will lose access
to any future exams scheduled for this roster."

**File-size guard**: if `RowActions` grows past 150 lines, extract
confirm dialogs to `RosterRowConfirmDialogs.tsx`.

### 1.5 — Transfer to non-ACTIVE target: warning chip + inline typed-confirm (C13, AC4)

**File**: `apps/tenant-web/features/classes/components/TransferStudentModal.tsx`

`targetOptions` today includes all classes regardless of status. Add a
status badge/chip beside each non-ACTIVE option (SUSPENDED, INACTIVE).
For non-ACTIVE targets, render an inline typed-confirm input below the
target picker (Phase 1 workaround for `TypedConfirmInput` primitive — see
Design Constraints). The submit button is disabled until the typed
string matches the target class name.

State: `useState<string>` for typed value, `useState<string>` for
selected target publicId. Helper:
`isTargetNonActive(targetClass) = targetClass.status !== "ACTIVE"`.

### 1.6 — Merge into non-ACTIVE target: warning chip + inline typed-confirm (C14, AC5)

**File**: `apps/tenant-web/features/classes/components/MergeClassesModal.tsx`

Same pattern as 1.5. The target picker lists classes; non-ACTIVE
destinations show a warning chip. An inline typed-confirm input gates
the merge button when the target is non-ACTIVE.

### 1.7 — Verify

Run in `apps/tenant-web/`:
- `pnpm lint`
- `pnpm typecheck`
- `pnpm build`
- `pnpm test` (any new test added for the description builder)

Manual smoke (per AC table):
- Program archive: 3 classes / 22 students → dialog shows those counts.
- Class archive: with roster → dialog shows student count.
- Each of 4 status changes on a class → dialog opens.
- Unassign a student → dialog names student + class.
- Transfer to a SUSPENDED class → chip visible; typed-confirm gates submit.
- Merge into INACTIVE class → chip visible; typed-confirm gates submit.

## Sub-tasks checklist

- [x] 1.1 — Program archive description with counts
- [x] 1.2 — Class archive confirm
- [x] 1.3 — 3 other status changes confirm
- [x] 1.4 — Unassign confirm
- [x] 1.5 — Transfer non-active chip + typed-confirm (inline)
- [x] 1.6 — Merge non-active chip + typed-confirm (inline)
- [x] 1.7 — Lint / typecheck / build (tests skipped by user)

## Notes

- The 5 "?" survey items (P8, C9 backend state machine, etc.) are NOT in
  this phase — out of scope per spec §3.
- Manual test plan: see "Verify" section. Use a tenant with at least
  2 programs and 3 classes for representative data.
- Migration note: when Phase 2's `TypedConfirmInput` lands, the inline
  typed-confirm in 1.5 and 1.6 should be replaced — track in a follow-up
  task.