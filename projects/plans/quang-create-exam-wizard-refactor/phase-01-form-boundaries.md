# Phase 01 — Form boundaries and pure wizard contracts

**Status:** Completed after human checkpoint
**Unit tests:** yes (hard-mode default; deterministic fallback required because tenant-web has no test runner)
**Quality gate:** yes (hard-mode default)

## Goal

Move initial form creation, template-skill derivation, mode transitions, step navigation, error ownership, and reset behavior out of the monolithic component while keeping the existing validation utility authoritative.

## Files owned by this phase

This phase must first create `tests/phase-01-pre-refactor-baseline.json`. It records
the current status/changed paths, protected-file hashes, serialized initial/reset
form, mode-transition resets, step field groups, one valid serialized
`CreateExamWorkflowInput`, query enablement/argument notes, submit request count,
and visible VI/EN/theme labels. The baseline is the comparison source for Phases
02–04.

Create:

- `apps/tenant-web/features/exams/utils/createExamWizard.ts`
- `apps/tenant-web/features/exams/hooks/useCreateExamWizardForm.ts`
- Feature-level pure tests only if an existing test runner is already configured; otherwise record test cases in the phase report and defer browser coverage to Phase 04.

Read-only dependencies:

- `apps/tenant-web/features/exams/types/index.ts`
- `apps/tenant-web/features/exams/constants/index.ts`
- `apps/tenant-web/features/exams/utils/validateCreateExamWorkflow.ts`
- `apps/tenant-web/features/exams/utils/examPolicy.ts`

Do not edit `CreateExamWizard.tsx` until ownership is confirmed at the phase start; wiring belongs to Phase 03.

## Implementation steps

Before any source write, re-check ownership and hashes. If `CreateExamWizard.tsx`,
`features/exams/constants/index.ts`, or a protected concurrent-agent file changed
outside this task, stop and request direction.

1. Add pure helpers for empty form creation, template skill derivation, step IDs/field groups, localized option mapping, and error filtering.
2. Add `useCreateExamWizardForm` with focused state or a small reducer for form, step, errors, reset, update, mode transition, next/back, step validation, and final validation.
3. Keep domain values separate from translated labels; accept a translation resolver rather than importing or changing `LocaleProvider`.
4. Keep `validateCreateExamWorkflow` as the single rule implementation and preserve its arguments/defaults/messages.
5. Define the hook API so the future shell can submit the same `effectiveForm` exactly once.

The hook API must explicitly expose the form's single `sources` value and a typed
`onSourcesChange(nextSources)` boundary for the future audience hook; it must not
create a second audience store. Testing is mandatory: use focused tests when a
runner exists, otherwise produce the deterministic fallback contract artifact with
exact inputs/outputs and command/result before phase completion.

## Acceptance checks

- Initial values and reset match the current wizard.
- Practice ↔ Official mode transitions preserve the current reset semantics.
- Step validation only exposes errors for the visible step; final validation checks the complete form and audience rule.
- Next/back changes only the step and never resets form values or calls an API.
- No full state machine or component-level field extraction is introduced.

## Design Constraints

Preflight: repository conventions were checked in `CreateSessionModal.tsx`,
`ExamDetailTabs.tsx`, and `examPolicy.ts`. The tenant app has no unit-test script or
local test runner; Phase 01 therefore requires the deterministic fallback contract
artifact in addition to typecheck/diff evidence. The current protected worktree
changes were observed and will be hash-checked, not edited. Protected files include
`apps/vendor-web/**`, `packages/ui/src/hooks/index.ts`,
`packages/ui/src/hooks/sessionStorage.ts`, and
`packages/ui/src/i18n/LocaleProvider.tsx`.

- No payload, validation rule, translation key, or public prop changes.
- No API imports in the pure utility.
- No query or mutation logic in the form hook.
- Use existing semantic UI/domain types and preserve TypeScript inference.
- Preserve the current defensive step-4 submit contract for Phase 03 to wire.

## Quality and Testing State

- Quality: APPROVED. Report: `quality/phase-01-form-boundaries-quality-report.json`. Receipt: `quality/phase-01-form-boundaries-receipt.json` (verified valid).
- Testing: PASSED. Report: `tests/phase-01-test-report.json`. Deterministic fallback artifact: `tests/phase-01-form-contract-fallback.json`.
- Required before phase completion: explicit human checkpoint after the hard-mode quality/testing gates.
- Gate: `ck:quality --gate` must report no BLOCKER/HIGH/current-change MEDIUM findings.
