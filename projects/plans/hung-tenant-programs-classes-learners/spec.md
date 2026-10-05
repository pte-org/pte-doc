# Spec: Tenant Programs / Classes / Learners — Destructive UX Guards + Form/Import Hygiene

**Slug**: `tenant-programs-classes-learners`
**Branch**: `hung/tenant-programs-classes-learners` (in `pte-doc`, branch created 2026-10-02 from `dev`)
**Code branch**: `pte-web` @ `hung/feat/classes-entry`
**Date**: 2026-10-02

## 1. Problem Statement

`apps/tenant-web` exposes three flows (Program / Class / Learner) where a single
click silently mutates state with no chance to undo, or silently fails. Static
scan (`unhappy-cases-survey.md`, 50 cases) surfaced **8 confirmed bugs and 7
items needing backend answers**. This spec covers the fixes we agreed to do now.

## 2. Scope (in)

Five destructive-name changes only (deferred for later: bulk-import routing,
lecturer-password reset, "Students" column).

- **P7**: Archive Program — add confirm with class/student counts.
- **C7, C8**: Archive Class — add confirm with student count.
- **C19**: Unassign student — add confirm naming the student + class.
- **C13, C14**: Transfer / Merge into INACTIVE or SUSPENDED class — keep
  selectable but show in-picker warning + typed-name confirmation.
- **C9, C10** (deactivate+suspend log): every status change (activate/deactivate/suspend/archive)
  opens a `ConfirmDialog` — covered by archive-scope decision.

### Form / validator hygiene

- **P2, P4**: Program date validator permits `endDate == startDate` and permits
  both `null` (always-active).
- **P5**: When user changes startDate after endDate was set, re-validate and
  clear endDate if it falls before new startDate.
- **C2, C17**: Backend class-name uniqueness within program — surface friendly
  message on 409 (`DUPLICATE_CLASS_NAME`).
- **C31**: Add Student tab — required-field validator mirroring
  `validateCreateLecturer` (email + fullName; backend may dedupe by email).

### Import hygiene

- **C28**: Add help text in Import tab: "If you set a `className` column it
  overrides the target class — leave blank to assign into the current class."
- **C27 / L5**: Skipped rows already surface via `SkippedRowsReport`. No client
  change; flagged as backend-confirmation only.

### UI dead states

- **X8**: Drop the always-placeholder "Students" column in `/host/classes` table
  (counts only known per-program, not tenant-wide). Replace with the program
  filter as the only filter affordance.

## 3. Out of Scope (deferred)

- C25 (lecturer password reset location) — confirm with team.
- C32 (search filter on Pick Existing) — perf scale.
- L4 (suspend learner) — confirm scope.
- All 7 "?" items needing backend answers — see Section 7.
- C27 (bulk import dedup), C28 routing — backend-confirmation pending.

## 4. User Stories (P1/P2/P3)

### P1 — must-have

- **S1**. As a Host, before archiving a Program I see a confirm dialog naming
  the program, the number of classes, and the number of students. Only after I
  confirm does the archive proceed.
- **S2**. As a Host, before archiving a Class I see a confirm dialog naming
  the class and the number of students currently assigned. Cancel is one click.
- **S3**. As a Host, before unassigning a student from a Class I see a confirm
  dialog naming the student and the destination action ("unassign from this
  class — they will lose access to future exams scheduled for this roster").
- **S4**. As a Host, I can still pick a SUSPENDED or INACTIVE class as the
  target of a transfer/merge, with an in-picker banner and a typed-name
  confirmation step before submission.
- **S5**. As a Host, every status change on a Class (activate/deactivate/
  suspend/archive) opens a confirm dialog. The status-change pending lock
  remains (no double-fire).
- **S6**. As a Host, I can submit a Program form with startDate == endDate
  (single-day program), or both dates empty (always-active). Validator no
  longer blocks them.

### P2 — should-have

- **S7**. As a Host, when I change startDate after endDate was set, the
  endDate either auto-clears or shows a clear error so I don't submit an
  inverted range.
- **S8**. As a Host, when the backend returns 409 on duplicate class name, I
  see "A class with this name already exists in this Program" — not a generic
  error.
- **S9**. As a Host importing an Excel roster, I see a help line under the
  dropzone that explains the `className` column override behavior.

### P3 — nice-to-have

- **S10**. As a Host, the "Students" column on `/host/classes` is removed
  (it was always "—"); the row becomes cleaner.
- **S11**. As a Host using the Add Student form, missing email or fullName is
  flagged client-side before the request leaves.

## 5. Acceptance Criteria (testable)

| ID | Criterion | How to verify |
|----|-----------|----------------|
| AC1 | Confirm dialog appears on Program archive with class + student counts matching backend snapshot at dialog-open time | Manual + e2e: open Program w/ 3 classes / 22 students → click Archive → dialog shows "3 classes, 22 students". Counts must update if state changed while dialog was open |
| AC2 | Confirm dialog appears on Class archive with student count from current roster | Manual + e2e |
| AC3 | Unassign confirm shows student full name + class name | Manual |
| AC4 | Transfer modal: SUSPENDED target class option shows a banner chip beside the label; submit requires typing the target class name | Manual |
| AC5 | Merge modal: SUSPENDED target option shows warning chip + typed-name confirmation | Manual |
| AC6 | Class status change dropdown items (activate/deactivate/suspend/archive) all open a `ConfirmDialog` with the relevant label | Manual |
| AC7 | Create Program: `startDate == endDate` is accepted; `startDate > endDate` is still rejected. Both empty is accepted | Unit test on `validateCreateProgram` |
| AC8 | Create Program: changing `startDate` after `endDate` was set triggers re-validation; if new `startDate > endDate`, error appears on `endDate` field | Manual |
| AC9 | Class create/edit returns friendly message on backend `409 DUPLICATE_CLASS_NAME` | Manual (depends on backend) |
| AC10 | Excel-import tab shows the `className`-override help text | Manual |
| AC11 | Add Student form: empty email or empty fullName blocks submission with field error | Manual |
| AC12 | `/host/classes` table no longer shows the "Students" column; layout still aligns on `xl` breakpoint | Manual |

## 6. Constraints & Non-Goals

- No backend changes — frontend only. (Backend confirmation questions go to
  `#api-team` channel.)
- No DB / migration.
- Touch only `apps/tenant-web/**`. Do not modify `packages/ui/**` unless a
  shared confirm primitive is missing — and if so, do it in a separate PR.
- Existing TanStack Query cache keys must stay stable (no renaming) so
  `useProgramDashboard`, `useClassRoster`, etc. keep working.
- File-size rule (≤300 lines / component ≤150 lines) per workspace rules —
  extract sub-components as needed.
- All new copy lives in the relevant `constants/index.ts` (no hardcoded
  strings in JSX).

## 7. Open Questions (NEEDS CLARIFICATION — answer before cook)

| # | Question | Owner | Blocks |
|---|----------|-------|--------|
| Q1 | Does backend reject class-name duplicates within a Program? If so, what error code (`DUPLICATE_CLASS_NAME`? `409`?) | backend | AC9 |
| Q2 | Does backend accept Program with `startDate == endDate` AND both null? Frontend now allows both — what does backend say? | backend | AC7 |
| Q3 | Does backend allow `transfer` / `merge` / `unassign` into a `SUSPENDED` / `INACTIVE` class? If yes, frontend just warns; if no, frontend must block. | backend | AC4 / AC5 |
| Q4 | Is "suspend learner" a Host capability at all (L4)? If yes, where is the API? | backend | out of scope unless yes |
| Q5 | Bulk-import dedup behavior — `bulkCreateUsers` skips duplicates silently or merges them into existing? | backend | deferred (out of scope this phase) |

## 8. Risks

1. **Risk**: Adding a `ConfirmDialog` around every archive/unassign/status change
   may annoy power users doing rapid cleanup.
   **Mitigation**: bulk-select → merge flow is unchanged; rapid-click flow still
   works for "activate/deactivate/suspend" between **non-destructive** transitions.
   The dialog only adds friction on **destructive** actions.

2. **Risk**: Typed-name confirmation for transfer/merge adds two clicks per
   operation in a common flow.
   **Mitigation**: only required when target is SUSPENDED/INACTIVE. Normal case
   stays zero-friction.

3. **Risk**: Backend errors mapped to friendly messages may diverge from
   reality if backend doesn't use the codes we assume (Q1).
   **Mitigation**: fallback to generic message; friendly path is best-effort.

4. **Risk**: Auto-clearing `endDate` when `startDate` moves past it (P5) may
   surprise the user who had a deliberate value.
   **Mitigation**: prefer "show error on endDate, keep both values" over auto-clear.

## 9. Definition of Done

- All AC1–AC12 pass manually + automated where applicable.
- `pnpm lint`, `pnpm typecheck`, `pnpm build` pass in `apps/tenant-web`.
- Existing happy-path Program/Class/Learner e2e/manual smoke not regressed.
- Survey file updated to mark each fixed item.
- One PR per logical phase (see plan.md).