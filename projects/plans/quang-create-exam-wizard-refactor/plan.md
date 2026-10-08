# Create Exam Wizard maintainability refactor

**Status:** Phase 04 gates passed; awaiting final human checkpoint
**Mode:** Hard
**Source spec:** `spec.md`

## Objective

Refactor the current tenant-web `CreateExamWizard` into a small orchestration shell, four phase components, and focused form/audience utilities without changing UI behavior, payloads, API calls, routes, permissions, locale behavior, or theme tokens.

## Scope check

- The feature exists and currently concentrates four phases, form state, validation, audience queries, mapping, and submit behavior in `CreateExamWizard.tsx`.
- The smallest safe implementation is a boundary refactor, not a new workflow or state machine.
- Hard mode is required because this is a multi-file refactor with concurrent FE work and submit/query regression risk.
- Spec quality: PASS. No unresolved clarification remains; acceptance criteria are measurable.

## Approved structure

```text
apps/tenant-web/features/exams/
├─ components/CreateExamWizard.tsx                 # orchestration only
├─ components/create-exam/
│  ├─ ExamDetailsStep.tsx
│  ├─ SchedulePolicyStep.tsx
│  ├─ AudienceStep.tsx
│  └─ ReviewStep.tsx
├─ hooks/
│  ├─ useCreateExamWizardForm.ts
│  ├─ useCreateExamAudience.ts
│  └─ useCreateExamWizardViewModel.ts
└─ utils/
   └─ createExamWizard.ts
```

Existing `utils/validateCreateExamWorkflow.ts` and `utils/examPolicy.ts` remain the validation/policy boundaries. They are not replaced by a reducer or state machine.

## Phase map

| Phase | Outcome | Main ownership |
|---|---|---|
| 01 | Pure wizard contracts and form state extracted | `createExamWizard.ts`, `useCreateExamWizardForm.ts`, focused tests |
| 02 | Audience query/search/add/remove ownership extracted | `useCreateExamAudience.ts`, focused tests |
| 03 | Four phase components wired through a thin shell | `components/create-exam/*`, `CreateExamWizard.tsx` |
| 04 | Regression verification, quality gate, and handoff | plan reports only; no new production behavior |

Dependencies are explicit: Phase 01 is the baseline/form contract; Phase 02 starts
only after Phase 01's implementation and test/baseline artifacts pass; Phase 03
starts only after Phases 01–02 pass their quality/testing gates; Phase 04 starts only
after Phases 01–03 and all of their test/quality artifacts are available.

## Concurrent-agent safety

Before Phase 01, create a pre-refactor baseline artifact with `git status --short`,
`git diff --name-only`, SHA-256 hashes for protected concurrent-agent files, and the
current Create Exam/locale behavior snapshot. Re-run this ownership checkpoint before
each phase and compare protected hashes after each phase.

- Before each implementation phase, record `git status --short` and the phase baseline.
- Only files listed in that phase may be changed.
- Do not touch `apps/vendor-web/**`, `packages/ui/src/hooks/index.ts`, `packages/ui/src/hooks/sessionStorage.ts`, or `packages/ui/src/i18n/LocaleProvider.tsx`. These are existing concurrent changes and read-only dependencies for this refactor.
- Do not overwrite, reset, stash, or manually reconcile another agent's changes.
- If another agent starts editing a listed tenant exam file, stop before touching the overlap and request direction.
- Before editing `CreateExamWizard.tsx` or `features/exams/constants/index.ts`, compare
  their status and hashes with the phase baseline. If either file changed outside this
  task, stop before writing and request direction. Verify the protected hashes remain
  unchanged after the phase and record the changed-path audit.
- No backend, API client, auth, route, database, scoring, or common component changes.

## Invariants to preserve

- Public `CreateExamWizard` props and `CreateExamWorkflowInput` payload stay identical.
- `changeExamMode` keeps its existing resets for anti-cheat, skills, retry, form mode, reuse policy, and series key.
- Active-only subscription/class/student/program filtering, `open`-controlled loading, search, duplicate protection, remove, and empty/loading states stay equivalent.
- Existing `validateCreateExamWorkflow.ts` remains the source of validation messages and full-form rules; step validation only filters its result by visible fields.
- Only the final review submit may invoke `onSubmit`; Next and Review must remain `type="button"` and produce zero create-session requests.
- Locale resolution continues through `useLocale`, Vietnamese remains default, English remains switchable, and light/dark semantic tokens remain unchanged.
- No micro-components, full finite-state machine, or business workflow redesign.

## Cross-phase validation commands

Run from `D:/DOCUMENTFPT/Github/pte-org/pte-web` after the relevant phase:

```powershell
corepack pnpm --filter @pte/ui typecheck
corepack pnpm --filter tenant-web exec tsc --noEmit
corepack pnpm --filter tenant-web lint
corepack pnpm --filter tenant-web build
git diff --check
```

Phase 04 additionally runs the authenticated Playwright smoke matrix at desktop and 390px: all four steps, back/next retention, submit guard/network count, reset/reopen, VI/EN, light/dark, no browser errors, and no horizontal overflow. Use the existing local seeded tenant data; do not commit credentials or temporary browser scripts.

Every phase must produce test evidence. If no suitable unit/hook runner exists, the
phase must include a deterministic fallback contract artifact with exact inputs,
expected outputs, command, and result; an unavailable runner alone is not a passing
test result. The current LocaleProvider key set/hash is part of the baseline and is a
read-only dependency of this refactor.

## Hard-mode review notes

- Accepted recommendation: phase components plus focused hooks/utils.
- Rejected for this scope: a full finite-state machine, per-input micro-components, and changes to global localization/common UI.
- Main red-team risks are accidental submit during navigation, duplicated audience state, changed mode-reset semantics, query enablement drift, and conflict with the parallel FE agent. Each is an explicit acceptance check in Phases 02–04.

## Completion gate

After Phase 04, write the test report and `ck:quality` gate receipt under this plan directory, then stop for human inspection. Do not mark the plan complete until the user confirms the refactor checkpoint.
