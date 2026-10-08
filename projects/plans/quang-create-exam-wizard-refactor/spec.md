# Spec: Create Exam Wizard maintainability refactor

**Date:** 2026-10-08
**Status:** Ready

---

## Problem Statement

`CreateExamWizard.tsx` hiện chứa toàn bộ JSX của bốn phase, form state, validation,
audience queries, policy/locale mapping và submit boundary trong một file lớn. Điều
này làm việc đọc, kiểm thử và mở rộng wizard khó hơn, dù chức năng hiện tại đã đúng.

Refactor chỉ thay đổi ownership và cấu trúc file trong feature Create Exam; không
thay đổi business logic, API contract, route, payload, quyền truy cập hoặc giao diện
đã được duyệt. LocaleProvider và các file common hiện có là dependency đọc-only của
refactor; task này không mở rộng sang chỉnh sửa chúng.

## User Stories

- **[P1]** As a frontend developer, I want each wizard phase to own its presentation
  so that I can modify one phase without navigating through the entire wizard file.
  Accepted when: four phase components exist and the shell renders them through an
  explicit step map/branch.

- **[P1]** As a frontend developer, I want state, validation, audience data and
  policy mapping to have explicit ownership so that logic can be tested and reused
  without duplicating API behavior.
  Accepted when: the shell does not own the detailed audience query composition or
  field-level validation implementation, and no query/mutation contract changes.

- **[P1]** As a product owner, I want the current create flow to behave exactly as
  before so that the refactor does not introduce a functional regression.
  Accepted when: the existing browser smoke flow passes for all four steps, VI/EN,
  light/dark mode, audience retention, reset, submit guard and responsive layout.

- **[P2]** As a frontend developer, I want phase-level tests to be possible without
  mounting the complete wizard so that future changes can be validated faster.
  Accepted when: step components accept focused props and pure mapping/validation
  helpers have isolated call boundaries.

- **[P3]** _(out of scope — noted for future)_
  Redesigning the create-exam business workflow or introducing a new route.

---

## Functional Requirements

1. **FR-01:** Preserve the existing four UI phases: exam details, schedule/policy,
   audience, and review/create.
2. **FR-02:** Keep `CreateExamWizard.tsx` as the orchestration boundary for modal
   lifecycle, current step, step navigation, and final submit callback; it must not
   contain the full JSX implementation of all four phases.
3. **FR-03:** Create one presentation component per phase under the exam feature;
   do not split individual labels/inputs into a large collection of micro-components.
4. **FR-04:** Move form state/update/reset behavior into a focused hook or feature
   state module without changing initial values or reset semantics.
5. **FR-05:** Move step-aware and full-form validation into a focused validation
   boundary while preserving the current validation messages and required audience
   rule.
6. **FR-06:** Keep audience student/class/program loading, search, add, duplicate
   protection, remove, and loading/empty states behaviorally equivalent.
7. **FR-07:** Keep policy, option-label, locale and theme behavior equivalent:
   Vietnamese remains the default, English remains switchable, and semantic light/
   dark tokens remain unchanged.
8. **FR-08:** Keep the defensive submit boundary: only the final review submit can
   invoke `onSubmit`; intermediate navigation must not create a session.
9. **FR-09:** Before editing, inspect the worktree. Changes belonging to the parallel
   FE agent must remain untouched; overlapping edits in the same file require a stop
   and user direction.

---

## Non-Functional Requirements

- **Maintainability:** `CreateExamWizard.tsx` should be no more than 180 lines after
  refactor and should primarily coordinate shell/step composition rather than render
  field groups.
- **Scope safety:** Production changes are limited to the tenant-web Create Exam
  feature and explicitly required locale/constants boundaries. Vendor-web files and
  unrelated parallel-agent files are excluded.
- **Regression safety:** Existing typecheck, lint, production build and browser smoke
  checks must remain passing; the existing lint warning in `CreateTicketModal.tsx`
  is tracked but not part of this refactor.

## Success Criteria

- [ ] The wizard shell is at most 180 lines and four phase components are present.
- [ ] No file outside the approved Create Exam refactor scope is modified; the
  parallel agent's `vendor-web`, session-storage, and current LocaleProvider changes
  remain byte-for-byte untouched and their hashes match the pre-refactor baseline.
- [ ] The final create payload and API/mutation call count are unchanged for the same
  valid input; intermediate steps produce zero create-session requests.
- [ ] Browser smoke passes at desktop and 390px viewport with zero browser errors,
  no horizontal overflow, VI/EN labels, light/dark toggle, tab retention and reset.
- [ ] `@pte/ui` typecheck, tenant-web typecheck, tenant-web lint, tenant-web build,
  and `git diff --check` pass.

---

## Out of Scope

- Backend, database, API-client, authentication, scoring, session lifecycle or route
  changes.
- New Create Exam business capabilities or changes to validation/payload semantics.
- Redesigning common `Modal`, `Stepper`, `Input`, `Select` or the global dashboard
  shell unless a later approved scope explicitly requires it.
- Editing `apps/vendor-web/features/auth/*`, `packages/ui/src/hooks/sessionStorage.ts`,
  or any other unrelated parallel-agent file.
- Splitting every input into a separate component.

## Assumptions

- The current four-step wizard and the latest Vietnamese/English localization are the
  baseline behavior to preserve.
- `CreateExamWizard` remains the parent-owned modal and continues receiving the same
  public props and `onSubmit` callback contract.
- A new overlap with the parallel FE agent is a stop condition, not permission to
  overwrite or manually reconcile their changes.

---

## [NEEDS CLARIFICATION]

None. The user approved the hybrid structure and explicitly supplied the parallel-
agent safety constraint.
