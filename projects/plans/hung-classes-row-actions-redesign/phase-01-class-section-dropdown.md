# Phase 01: ClassesSection + ClassesListView — single common dropdown

**Date:** 2026-09-29
**Slug:** `hung-classes-row-actions-redesign`
**Phase:** 01

## Goal

Replace the current 3-control row action layout with a single `Dropdown` in both `ClassesSection` and `ClassesListView`. Both use the same `ClassRowActions` pattern but with different item sets.

## Design Constraints

- `ChevronDownIcon` imported from `@pte/ui` (already exported at `packages/ui/src/components/icons.tsx:183`)
- All labels from `CLASS_ROW_ACTIONS_TEXT` constants
- `Dropdown` trigger: `triggerClassName` override required — default `h-10 w-10 grid place-items-center` is replaced entirely, so hover styles (`hover:bg-slate-50 hover:text-slate-700`) must be re-added manually
- `ClassesListView` dropdown: only 2 items (Edit + Assign Students), **no divider** rendered
- `ClassesSection` dropdown: 6 items + 2 separators (navigation group / status group)
- `Assign Students` disabled when `status === "INACTIVE" || status === "SUSPENDED"`
- `ClassesListView.tsx` constraint: must stay ≤ 300 lines — see mitigation below

### ClassesListView Line Count Mitigation

Current file: 293 lines. `ClassRowActions` grows ~20 lines. To stay ≤ 300, extract `PickProgramToAddClass` (41 lines, lines 252–293) to its own file `PickProgramToAddClass.tsx`:

1. Move `PickProgramToAddClassProps` interface and `PickProgramToAddClass` component to `PickProgramToAddClass.tsx`
2. Export `PickProgramToAddClass` from the new file
3. In `ClassesListView.tsx`: replace the local definitions with `import { PickProgramToAddClass } from "./PickProgramToAddClass"`
4. Result: `ClassesListView.tsx` ends at line ~252 (PickProgramToAddClass removed), new file ~45 lines, total code unchanged

## Changes

### 1. `apps/tenant-web/features/classes/constants/index.ts`

Add `actions` to `CLASS_ROW_ACTIONS_TEXT` (add as the first key to match natural reading order of the trigger label):

```typescript
export const CLASS_ROW_ACTIONS_TEXT = {
  actions: "Actions",
  edit: "Edit",
  // ... existing fields
};
```

### 2. `apps/tenant-web/features/classes/components/ClassesSection.tsx`

**`ClassRowActions` — replace entire component body (lines 34–132):**

**Before:** Three controls side-by-side — Edit pill, Assign Students pill, ⋮ kebab `Dropdown` with status mutations only.

**After:** Single `Dropdown` with:
- `trigger`: `{CLASS_ROW_ACTIONS_TEXT.actions} <ChevronDownIcon className="h-4 w-4" />`
- `triggerClassName`: `"rounded-full border border-slate-300 bg-transparent px-4 py-1.5 text-sm font-medium text-slate-700 transition-colors hover:bg-slate-50 hover:text-slate-700"`
- 8 items (2 separators):
  1. `CLASS_ROW_ACTIONS_TEXT.edit` → `onEdit()`
  2. `CLASS_ROW_ACTIONS_TEXT.assignStudents` → navigate to assign URL, `disabled: !isActive`
  3. separator `key="nav-status-divider"`
  4. `CLASS_ROW_ACTIONS_TEXT.activate` → `mutations.activate.mutate()`, `hidden: isActive`
  5. `CLASS_ROW_ACTIONS_TEXT.suspend` → `mutations.suspend.mutate()`, `hidden: !isActive`
  6. `CLASS_ROW_ACTIONS_TEXT.deactivate` → `mutations.deactivate.mutate()`, `hidden: studentClass.status === "INACTIVE"`
  7. separator `key="danger-divider"`
  8. `CLASS_ROW_ACTIONS_TEXT.archive` → `mutations.archive.mutate()`, `danger: true`

Keep outer `<div className="flex flex-col gap-1">` wrapper (for `rowError` display). Remove inner `<div className="flex flex-wrap items-center gap-2">` — replaced by `Dropdown`.

**Imports to add:** `ChevronDownIcon` from `@pte/ui`.

**Line count:** `ClassRowActions` shrinks from ~98 lines to ~70 lines. Total file: ~258 lines.

### 3. `apps/tenant-web/features/classes/components/ClassesListView.tsx`

**`ClassRowActions` — replace entire component body (lines 57–86):**

**Before:** Two pills side-by-side — Edit `Link` + Assign Students `button`.

**After:** Single `Dropdown` with:
- `trigger`: `{CLASS_ROW_ACTIONS_TEXT.actions} <ChevronDownIcon className="h-4 w-4" />`
- `triggerClassName`: `"rounded-full border border-slate-300 bg-transparent px-4 py-1.5 text-sm font-medium text-slate-700 transition-colors hover:bg-slate-50 hover:text-slate-700"`
- 2 items only (no separators):
  1. `CLASS_ROW_ACTIONS_TEXT.edit` → `router.push()` to class detail URL
  2. `CLASS_ROW_ACTIONS_TEXT.assignStudents` → `onAssignStudents()` callback, `disabled: option.status === "INACTIVE" || option.status === "SUSPENDED"`

**No conditional separator logic needed** — with only 2 items and no separator items, there is nothing to group, so no divider renders.

**Imports to add:** `Dropdown`, `ChevronDownIcon`, `type DropdownItem` from `@pte/ui`. `useRouter` from `next/navigation`.

### 4. New file: `apps/tenant-web/features/classes/components/PickProgramToAddClass.tsx`

Extract `PickProgramToAddClassProps` interface and `PickProgramToAddClass` component from `ClassesListView.tsx` (lines 252–293) to keep that file ≤ 300 lines:

```typescript
"use client";

import { type ReactElement } from "react";
import { Button } from "@pte/ui";
import { CLASSES_LIST_TEXT } from "../constants";

export interface PickProgramToAddClassProps {
  programs: { value: string; label: string }[];
  classLabel: string;
  programLabel: string;
  onRequestCreateClass: (programPublicId: string) => void;
}

export const PickProgramToAddClass = ({
  programs,
  classLabel,
  programLabel,
  onRequestCreateClass,
}: PickProgramToAddClassProps): ReactElement => (
  // ... content from ClassesListView lines 265-292
);
```

Update `ClassesListView.tsx` imports to add:
```typescript
import { PickProgramToAddClass } from "./PickProgramToAddClass";
```

Remove the local `PickProgramToAddClassProps` interface and `PickProgramToAddClass` component from `ClassesListView.tsx`.

Also add `PickProgramToAddClass` to the exports in `components/index.ts`.

## Quality and Testing State

- Quality: not evaluated
- Testing: not started

**Preflight:** Repository conventions confirmed — `Dropdown` from `@pte/ui` is the established primitive for kebab-style menus (used in `ClassesSection.tsx` lines 122-127). `ChevronDownIcon` already exported from `packages/ui/src/components/icons.tsx:183` (re-exported via `components/index.ts:58`). `CLASS_ROW_ACTIONS_TEXT.assignStudentsDisabledTitle` already defined in constants for the disabled-state tooltip. `TenantClassOption.status: ClassResponse["status"]` exists in API types so disabled-state check is valid for `ClassesListView` row too. PickProgramToAddClass extraction keeps `ClassesListView.tsx` ≤ 300 lines per CLAUDE.md rule.

**Tests:** skipped by user. **Quality gate:** skipped by user. `--no-tests --no-quality`

**Build gate:** PASS (tsc --noEmit clean, eslint clean on all Phase 01 files, full `pnpm --filter tenant-web build` PASS in 40s).

**File sizes:**
| File | Target | Actual |
|------|--------|--------|
| `ClassesSection.tsx` | ≤ 300 | 275 ✅ |
| `ClassesListView.tsx` | ≤ 300 | 263 ✅ |
| `PickProgramToAddClass.tsx` | small | 52 ✅ |

**Quality:** skipped_by_user; decision: user_confirmed_skip
**Testing:** not_started; user declined

**Acceptance Criteria:**
- [x] `ClassesSection` row: single "Actions ▾" button, all 5 actions present, divider between navigation and status groups
- [x] `ClassesListView` row: single "Actions ▾" button, Edit + Assign Students only, no divider
- [x] Assign Students disabled (visibly grayed) when class is INACTIVE or SUSPENDED
- [x] `ChevronDownIcon` renders beside "Actions" label in trigger button
- [x] `ClassesListView.tsx` ≤ 300 lines after refactor
- [x] No hardcoded strings — all labels from `CLASS_ROW_ACTIONS_TEXT`

## Acceptance Criteria

- [ ] `ClassesSection` row: single "Actions ▾" button, all 5 actions present, divider between navigation and status groups
- [ ] `ClassesListView` row: single "Actions ▾" button, Edit + Assign Students only, no divider
- [ ] Assign Students disabled (visibly grayed) when class is INACTIVE or SUSPENDED
- [ ] `ChevronDownIcon` renders beside "Actions" label in trigger button
- [ ] `ClassesListView.tsx` ≤ 300 lines after refactor
- [ ] No hardcoded strings — all labels from `CLASS_ROW_ACTIONS_TEXT`
