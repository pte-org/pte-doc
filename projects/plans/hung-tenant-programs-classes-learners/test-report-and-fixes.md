# Test Report & Fix Log — tenant-programs-classes-learners

**Date**: 2026-10-04 (verification + remediation pass)
**Code branch**: `pte-web` @ `hung/feat/classes-entry`
**Verifier**: MCP browser (`cursor-ide-browser`) + Node unit harness + Postgres direct query
**Test data prefix**: `ZZ%` / `zz.%@test.local` — all removed after each run (verified `0|0|0`)

This file records the verification pass that the three cook phases left open
(all three shipped with "Testing: not started — user declined tests").

---

## 1. Acceptance Criteria results

| AC | Criterion | Result | Evidence |
|----|-----------|--------|----------|
| AC1 | Program archive confirm shows class + student counts | **PASS** | Program with 3 classes / 2 students → "archive its 3 classes and unassign 2 students" — matched DB exactly |
| AC2 | Class archive confirm shows student count | **PASS** | Verified in earlier session |
| AC3 | Unassign confirm names student **and class** | **FAIL → fixed** | Showed `from this class` (no class name). Now shows `from "ZZ No Program Picked"` |
| AC4 | Transfer: non-ACTIVE chip + typed-confirm | **PASS** | Option text `ZZAC4 Suspended (Local seed program PTE_LOCAL) — Suspended`; "Not active" heading; `TYPE ZZAC4 SUSPENDED TO CONFIRM`; wrong name → disabled, exact name → enabled |
| AC5 | Merge: non-ACTIVE chip + typed-confirm | **PASS** | Chip "Suspended" on radio, "Not active" heading, `Type ZZ C3 to confirm`; wrong name → disabled, exact name → enabled |
| AC6 | All 4 class status changes open ConfirmDialog | **PASS** | Verified in earlier session |
| AC7 | Program dates: same-day OK, both-null OK, reversed rejected | **PASS** | 8/8 unit cases + live create persisted `start=2026-05-20, end=2026-05-20` |
| AC8 | Changing startDate surfaces error on endDate | **PASS** | Error appeared immediately, `aria-invalid=true`, red border |
| AC9 | 409 duplicate class name → friendly message | **PASS** | Backend returns `CLASS_NAME_ALREADY_USED`; UI showed "A class with this name already exists in this program." |
| AC10 | Import tab shows `className`-override help text | **PASS** | Text present directly under dropzone |
| AC11 | Add Student blocks empty email / fullName | **PASS** | "Email is required." + "Full name is required." shown together |
| AC12 | "Students" column removed, layout intact | **PASS** | Playwright at 640/768/1024/1280px: headers `[Name \| Program \| Status \| Actions]` (no Students), no page-level horizontal scroll, no clipped body cells at any width |

**Score: 11 PASS, 1 FAIL (now fixed), 0 skipped, 0 blocked.**

### Backend answers resolved

- **Q1** (`DUPLICATE_CLASS_NAME`?): No — backend emits `CLASS_NAME_ALREADY_USED` with HTTP 409. That key was already in the catalog, so no change was needed. Phase 2's "no-op" note was correct.

---

## 2. Bugs found and fixed

### Bug 1 — Header "+ Create Class" silently did nothing (HIGH)

`onConfirmCreate` bailed out with `if (!selectedProgramPublicId) return;`. The header
entry point opens the modal with **no Program selected**, so a Host who typed a name
and clicked "Create Class" got no request, no error, and no closing modal.

Only the per-row "+ Add Class" entry point worked, because it pre-selects a Program.

**Fix** — `CreateClassModal.handleSubmit` now validates the picker first and renders a
field error; the parent guard stays as defence-in-depth against an un-scoped request.

```ts
if (showPicker && !selectedProgramPublicId) {
  setProgramError(CREATE_CLASS_ERRORS.programRequired(programLabel));
  return;
}
```

New copy: `CREATE_CLASS_ERRORS.programRequired` → `"Select a Program first."`
Error clears on picker change.

**Verified**: submit with no Program → *"Select a Program first."* + `aria-invalid` on the
combobox; selecting a Program clears it; submit then creates the class (`ZZ No Program
Picked` landed in the DB).

### Bug 2 — Stale validation errors survived correction (MEDIUM)

Field errors were stored at submit time and never released. A Host who submitted an
invalid form, then corrected the field, still saw the red border and the message on a
now-valid value.

Phase 2 introduced derived `dateError` for `CreateProgramModal` but never cleared the
stored `errors` object, so the same stale message survived a successful submit.

**Fix** — every form now drops a field's stored error the moment that field is edited.

- `CreateProgramModal.handleChange` (4 fields share one handler)
- `ImportOrAssignModal.handleChange` (Add Individually tab)
- `CreateClassModal` / `EditClassModal` / `SplitClassModal` — new `handleNameChange`
- `ResetStudentPasswordModal` — new `handlePasswordChange`

Keyed on `keyof Errors`, not `keyof Input`, because most inputs never carry an error
(`description`, `phone`, `studentCode`, `dateOfBirth` have no error slot) — indexing the
error object with the input key is a `TS7053`.

**Verified**: submit with inverted dates → error; correct the date → `aria-invalid` clears
with no submit. Same for the Add Student form with both fields empty.

### Bug 3 — Unassign confirm did not name the class (MEDIUM)

`CLASS_ROSTER_UNASSIGN_CONFIRM_TEXT.description` hardcoded `"from this class"`. AC3 requires
naming the class, and the Host may have several rosters open.

**Fix** — signature is now `description(studentFullName, className)`. Threaded a new
`className` prop: `ClassDetailView` (which already resolves `studentClass.name`) →
`ClassRosterTable` → `RowActions`.

**Verified**: *"Unassign ZZ Unassign Probe from "ZZ No Program Picked"?"*

### Bug 4 — "Classs" / "classs" typo everywhere (LOW)

Naive `` `${label}s` `` on the label `"Class"` produced `Classs`. Surfaced as
"3 classs", "Merge Classs", "0 classs", and in program copy.

**Fix** — added `pluralize(label, count?)` to `features/orgLabels/constants.ts`
(suffix rules: `-es` after s/x/z/ch/sh, `-ies` after consonant+y, else `-s`) and routed
all affected builders through it: `CLASSES_SECTION_TEXT`, `CLASSES_LIST_TEXT`,
`MERGE_CLASSES_SELECTION_TEXT`, `MERGE_CLASSES_TEXT`, `PROGRAM_DETAIL_TEXT.back`,
`PROGRAM_DETAIL_TEXT.backToList`, `PROGRAM_DASHBOARD_TEXT.classCount`, and the
`ClassesListView` load-failure string.

**Verified**: "0 classes", "2 classes", "3 classes", "Merge Classes".

---

## 3. Gates

| Gate | Command | Result |
|------|---------|--------|
| Typecheck | `pnpm --filter tenant-web exec tsc --noEmit` | clean |
| Lint | `eslint features/classes features/programs features/orgLabels features/examoperations app` | 0 problems |
| Build | `pnpm --filter tenant-web build` | 23 routes, OK |

Regression spot-checks after the fixes: program archive dialog still reports
"2 classes and unassign 1 student"; class creation via the header path works end to end.

### Refactor — split `ImportOrAssignModal.tsx`

`features/classes/components/ImportOrAssignModal.tsx` was **480 lines**, over the
300-line rule in `CLAUDE.md`. It was already 462 lines at `HEAD`, so the violation
predates this plan — but since this plan already touched the file, it was worth fixing.

Split along the existing seam (one file per tab, matching the `_`-prefixed
"private to this feature" convention already used by `_RosterDropzone.tsx`):

| File | Lines | Role |
|---|---|---|
| `ImportOrAssignModal.tsx` | 169 | Shell: tab switcher + the cross-tab pending-credentials batch |
| `_ImportExcelTab.tsx` | 138 | Excel upload → parse → create → auto-assign |
| `_AddIndividuallyTab.tsx` | 130 | Create one account and assign it |
| `_ExistingStudentTab.tsx` | 71 | Assign an already-created learner |
| `assignErrorMessage.ts` | 17 | `STUDENT_ALREADY_IN_CLASS` → friendly copy, shared by two tabs |
| `tabScopeProps.ts` | 7 | The org/program/class triple every tab receives |

Pure code motion — no behaviour change. The three tabs are not exported from the
feature barrel, so nothing outside the modal can reach them.

**Verified after the split**: all three tabs render; the AC10 `className`-override
help text is still under the dropzone; empty submit still marks Email and Full name
`aria-invalid`; editing Email clears only Email's error (the Bug 2 fix survived the
move); a valid submit creates the account *and* the membership, confirmed in Postgres;
switching back to Pick Existing still lists unassigned learners only.

---

## 4. Still outstanding

All twelve acceptance criteria are now verified. What remains:

1. **Open questions Q2–Q5** from `spec.md` §7 — still unanswered by the backend team.
   - Q1 is answered empirically: the backend emits `CLASS_NAME_ALREADY_USED` / 409.
   - Q2 is answered empirically: the backend accepts `start == end` and both-null, and
     persists them.
   - Q3 is answered by reading the source: `ClassService.transfer` and
     `ClassService.mergeClasses` both check ownership/tenant only and never inspect
     the target Class's `status`, so the backend accepts a transfer/merge into a
     `SUSPENDED`/`INACTIVE`/`ARCHIVED` Class. The frontend warning + typed-confirm
     matches the spec's stated intent, but the guard does not exist server-side.
     **Deferred: backend work is out of scope for this pass.**
   - Q4, Q5 out of scope for this phase.
2. **No automated regression coverage.** Everything here was verified by hand-driving a
   live app. `validateCreateProgram` and `pluralize` are pure functions and would take
   unit tests in seconds; the transfer/merge typed-confirm and the stale-error-clearing
   behaviour would take component tests. Nothing prevents these bugs from coming back.
   `packages/api-client` shows the precedent (vitest, `environment: "node"`), but
   `apps/tenant-web` has no test runner configured at all.
3. **Pre-existing, out of scope** — ten files in `apps/tenant-web` exceed the 300-line
   rule in `CLAUDE.md`, none of them introduced by this plan:
   | Lines | File | Feature |
   |---|---|---|
   | 611 | `features/exams/api/index.ts` | exams |
   | 605 | `features/exams/components/CreateExamWizard.tsx` | exams |
   | 568 | `features/exams/components/ExaminerAssignmentSection.tsx` | exams |
   | 546 | `features/studentSearch/components/StudentSearchView.tsx` | studentSearch |
   | 439 | `features/exams/constants/index.ts` | exams |
   | 431 | `features/public/components/HomeView.tsx` | public |
   | 350 | `features/examiner/ExaminerWorkView.tsx` | examiner |
   | 339 | `features/exams/components/HostScoreReviewPanel.tsx` | exams |
   | 310 | `features/examStaff/components/ExamStaffView.tsx` | examStaff |
   
   `CreateExamWizard.tsx` also fails the repo's `react-hooks/set-state-in-effect` rule
   (from commit `c436e6a`, not introduced here).

---

## 5. Reproducing this run

`verify-ac12.js` and `verify-ac4.js` live in
`%USERPROFILE%\.cursor\skills\playwright-skill\`. They must run from that directory
(Playwright resolves from the skill's `node_modules`):

```powershell
cd "$env:USERPROFILE\.cursor\skills\playwright-skill"
node run.js "ac12-test.js"
node run.js "ac4-test.js"
```

Both seed their own fixtures through the API and log in as the local Host user.
`ac4-test.js` still creates its student through the UI rather than the API — the
`bulkCreateUsers` payload shape was not confirmed, and a wrong guess returned 500.
