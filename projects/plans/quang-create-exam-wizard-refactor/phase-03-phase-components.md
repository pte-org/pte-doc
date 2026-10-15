# Phase 03 — Phase components and thin wizard shell

**Depends on:** Completed Phases 01–02 and their test/quality artifacts

**Status:** Completed after human checkpoint
**Unit tests:** yes (hard-mode default; browser smoke required for this phase)
**Quality gate:** yes (hard-mode default)

## Goal

Extract the four existing UI phases into focused presentation components and reduce `CreateExamWizard.tsx` to modal lifecycle, orchestration, step map, footer, and final submit boundary.

## Files owned by this phase

Create:

- `apps/tenant-web/features/exams/components/create-exam/ExamDetailsStep.tsx`
- `apps/tenant-web/features/exams/components/create-exam/SchedulePolicyStep.tsx`
- `apps/tenant-web/features/exams/components/create-exam/AudienceStep.tsx`
- `apps/tenant-web/features/exams/components/create-exam/ReviewStep.tsx`
- `apps/tenant-web/features/exams/hooks/useCreateExamWizardViewModel.ts`

Modify only after concurrent ownership is clear:

- `apps/tenant-web/features/exams/components/CreateExamWizard.tsx`
- `apps/tenant-web/features/exams/components/index.ts` only if an export is required by the existing convention

Read-only:

- `apps/tenant-web/features/exams/constants/index.ts`
- `apps/tenant-web/features/exams/utils/examPolicy.ts`
- `apps/tenant-web/features/exams/utils/validateCreateExamWorkflow.ts`
- `packages/ui/src/i18n/LocaleProvider.tsx`

## Implementation steps

1. Define focused props for each phase: values, translated text/options, field errors, loading/options, and callbacks only.
2. Move the existing JSX into the corresponding phase component without changing field names, IDs, classes, semantic tokens, or accessibility relationships.
3. Keep all four phase components free of API calls, mutation calls, and nested native forms.
4. Wire the shell through an explicit step map/branch and preserve `Stepper`, modal full/sticky-footer behavior, responsive layout, and locale/theme resolution. Keep locale/options/policy mapping in the wizard view-model hook so the shell remains a composition boundary.
5. Keep navigation buttons `type="button"`; only the final review button is `type="submit"` and `handleSubmit` rejects non-step-4 submissions.
6. Keep the shell at or below the spec target of 180 lines, primarily coordinating hooks and phase props.

## Acceptance checks

- Four phase files exist and the shell no longer contains the full four-phase JSX.
- Existing browser behavior is unchanged: details → schedule/policy → audience → review/create.
- Back/next retains values; close/reopen resets according to the current contract.
- VI default, EN switch, light/dark semantic tokens, and mobile sticky footer remain intact.
- Intermediate navigation produces zero create-session requests; final submit preserves payload and mutation count.

## Design Constraints

- No micro-components for individual inputs or labels.
- No changes to common `Modal`, `Stepper`, `Input`, `Select`, global locale, theme, vendor-web, or session-storage code.
- Do not duplicate `form.sources`, query state, or validation rules in phase components.
- Preserve existing labels and locale fallback behavior through `useLocale`; do not edit `LocaleProvider`.

## Quality and Testing State

- Quality: APPROVED; `quality/phase-03-phase-components-receipt.json` is valid.
- Testing: PASSED; deterministic fallback contract 27/27 and authenticated browser smoke passed.
- Required before phase completion: satisfied by explicit human checkpoint after review of the local UI.
- Gate: `ck:quality --gate` must report no BLOCKER/HIGH/current-change MEDIUM findings.
