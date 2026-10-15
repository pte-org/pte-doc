# Phase 03 — Create Exam wizard layout

**Plan:** [plan.md](plan.md) · **Spec:** [spec.md](spec.md)
**Depends on:** Phase 01; can be implemented after Phase 02 composition is stable
**Outcome:** a less dense four-step create flow using the same input, validation, and
mutation contract.

## Step mapping

| Step | Existing fields/behavior |
|---|---|
| Thông tin & nội dung | name, template/subscription, mode, capacity, skills, existing content fields |
| Thời gian & chính sách | opens/closes, retry, anti-cheat, and existing policy-related values |
| Audience | Student/Class/Program source search, add/remove, current source validation |
| Review & tạo | existing review summary and `onSubmit(effectiveForm)` |

## Files to inspect/change

- `pte-web/apps/tenant-web/features/exams/components/CreateExamWizard.tsx`
- `pte-web/apps/tenant-web/features/exams/constants/index.ts`
- `pte-web/apps/tenant-web/features/exams/utils/validateCreateExamWorkflow.ts` only
  if field errors need regrouping without changing rule semantics.
- `pte-web/apps/tenant-web/features/exams/components/ExamsListView.tsx` only for the
  presentation wrapper/trigger; keep the existing create mutation.

## Steps

1. Replace the two-step visual grouping with four steps while keeping one form state
   object and the existing `CreateExamWorkflowInput` shape.
2. Use the shared wizard shell/Stepper from Phase 01 with a spacious responsive layout;
   on narrow screens stack the step indicator and keep footer actions reachable.
3. Preserve the existing review validation behavior: moving forward may validate the
   relevant current section; final submit must use the existing full validation call.
4. Keep audience source selection available when the current contract requires it.
   Do not convert Class assignment after creation into a create-time mutation.
5. Keep loading/error/submit states and `onClose`/reset semantics unchanged.
6. Ensure the form can be closed or moved back without leaking stale state into the next
   create attempt, matching the current key/reset behavior.

## Design Constraints

- No new draft lifecycle, endpoint, payload field, or audience rule.
- No new exam settings may be presented unless already backed by the current input and
  server contract.
- The form remains one client flow; step changes must not perform route navigation or
  cause a global page flash.
- The user must be able to review the selected template/mode/policy/audience before the
  existing create request is submitted.

## Quality and Testing State

- Preflight: `CreateExamWizard` owns the single form state and current
  submit/validation contract; `Stepper` is a shared presentation primitive;
  the existing `CreateExamWorkflowInput`, validator, query hooks, and
  `ExamsListView` create mutation are established; no API change is planned.
- Quality: approved. Report: `pte-doc/projects/plans/quang-tenant-exam-ui-decomposition/quality/phase-03-create-exam-wizard-layout-quality-report.json`; receipt: `pte-doc/projects/plans/quang-tenant-exam-ui-decomposition/quality/phase-03-create-exam-wizard-layout-receipt.json`.
- Testing: passed with one skipped item; no applicable unit-test runner/file exists for this presentation-only wizard. Static/type/lint/build/diff checks passed; browser interaction and visual verification are deferred to Phase 04. Report: `pte-doc/projects/plans/quang-tenant-exam-ui-decomposition/tests/phase-03-create-exam-wizard-layout-test-report.json`.
- Planned checks: validation regression cases, create cancel/reopen reset, keyboard
  stepper navigation, responsive screenshots, light/dark rendering, locale labels, and
  tenant-web typecheck/lint/build.

## Acceptance criteria

- The create flow visibly has four focused steps and is not a dense single scroll.
- The submitted `CreateExamWorkflowInput` is unchanged for equivalent user input.
- Current audience-required validation and error messages remain effective.
- No Class is automatically assigned as a side effect of the UI refactor.
- Existing create success/error/close behavior remains intact.

## Current cook state

- Implementation complete: the create flow now has four focused steps—details,
  schedule/policy, audience, and review/create—using the shared `Stepper` and a
  spacious responsive modal layout.
- The existing `CreateExamWorkflowInput`, query hooks, validator, mutation callback,
  loading/error states, audience rule, and key-based reset semantics are preserved.
- Build Gate passed: `@pte/ui` typecheck, tenant TypeScript, lint, production build,
  and `git diff --check`. Lint retains one pre-existing warning in
  `supportTickets/CreateTicketModal.tsx` for an unused `E` import; the build retains
  the existing non-blocking absolute `turbopack.root` warning.
- Quality gate approved and receipt issued at
  `quality/phase-03-create-exam-wizard-layout-receipt.json`.
- Hard-mode human confirmation received on 2026-10-08; this phase is complete and Phase 04 is active.
