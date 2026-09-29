# Plan: ClassesSection + ClassesListView row actions → single dropdown

**Date:** 2026-09-29
**Status:** Phase 01 completed
**Slug:** `hung-classes-row-actions-redesign`

## Goal

Replace the current 3-control row action layout (Edit pill + Assign Students pill + ⋮ kebab) in both `ClassesSection` (program detail) and `ClassesListView` (tenant-wide) with **one shared `Dropdown` component** whose trigger is a labeled "Actions ▾" button.

## Design Constraints

| Constraint | Detail |
|---|---|
| Max component size | ≤ 300 lines per file (CLAUDE.md rule) |
| `ClassesListView.tsx` | Currently 293 lines → must stay ≤ 300 after changes |
| Primitives | Use only existing `Dropdown` from `@pte/ui` — no new primitives |
| Strings | All labels via `CLASS_ROW_ACTIONS_TEXT` constants |
| Trigger style | Outlined-neutral pill (gray border, hover `bg-slate-50`, text `text-slate-700`) |
| Trigger class override | `Dropdown`'s default trigger is `h-10 w-10 grid place-items-center` (icon-only); must override via `triggerClassName` and manually re-add hover styles |
| Divider placement | Between navigation group (Edit, Assign Students) and status group (Activate/Suspend/Deactivate, Archive) |
| ClassesListView scope | Only Edit + Assign Students (no status mutations) → dropdown with 2 items, **no divider** when only 1 group |
| ClassesSection scope | Edit + Assign Students + 4 status mutations → 6 items + 2 separators |
| Disabled handling | Assign Students visible-but-disabled when `status === "INACTIVE" || status === "SUSPENDED"` |
| Icon | `ChevronDownIcon` already exported from `packages/ui/src/components/icons.tsx` |
| New constant | `CLASS_ROW_ACTIONS_TEXT.actions` = `"Actions"` needs to be added to constants |

## Phases

| Phase | Description | Files |
|---|---|---|
| 01 | Replace 3 controls with single `Dropdown` in both `ClassesSection.tsx` and `ClassesListView.tsx` | `constants/index.ts` (add `actions`), `ClassesSection.tsx`, `ClassesListView.tsx`, `PickProgramToAddClass.tsx` (new) | ✅ completed (Phase 01) |

## Quality and Testing State

- Quality: skipped_by_user (Phase 01)
- Testing: skipped by_user (Phase 01)

## Risks

1. **Line count creep in `ClassesListView.tsx`** — current 293 lines, change adds ~20 lines; mitigated by extracting `PickProgramToAddClass` (41 lines) to its own file, leaving `ClassesListView.tsx` at ~252 lines.
2. **Trigger hover style loss** — overriding `triggerClassName` replaces the entire `className` string; hover styles from the default must be manually included in the override.
