# Phase 01 — Common Exam shell and tab-state contract

**Plan:** [plan.md](plan.md) · **Spec:** [spec.md](spec.md)
**Depends on:** none
**Outcome:** a reusable, theme-safe presentation contract for tabs, tab-local loading,
and wizard framing; no Exam behavior changes.

## Goal

Audit and reuse the existing shared primitives (`Tabs`, `TabPanel`, `Stepper`,
`PageHeader`, `CollapsibleSection`, `LoadingState`, `DataTable`, and semantic tokens).
Add only generic missing presentation primitives that are genuinely reusable, then
define the tenant Exam adapter/state strategy before moving feature content.

## Files to inspect/change

- `pte-web/packages/ui/src/components/Tabs.tsx`
- `pte-web/packages/ui/src/components/Stepper.tsx`
- `pte-web/packages/ui/src/components/index.ts`
- `pte-web/packages/ui/src/styles/design-tokens.css`
- `pte-web/apps/tenant-web/features/exams/components/SessionDetailView.tsx`
- `pte-web/apps/tenant-web/features/exams/components/CreateExamWizard.tsx`
- Add a generic shared shell only if the audit proves it is needed by more than one
  feature; otherwise keep the composition in tenant-web.

## Steps

1. Confirm existing Tabs keyboard behavior, ARIA relationships, horizontal overflow,
   count rendering, and dark-mode tokens. Fix only contract-level issues needed by the
   new Exam tabs.
2. Define the tab state contract: default `overview`, optional URL/query synchronization
   without a full route reload, invalid-tab fallback, and a visited-tab retention map.
3. Define the local loading contract: first-visit tab skeleton, no global shell reset,
   and stale content retained during background revalidation.
4. Define the wizard shell contract: responsive full-screen dialog/layout, step indicator,
   sticky footer actions, error placement, and mobile behavior. The shell receives
   children/callbacks and owns no Exam API or form validation.
5. Verify all new labels pass through the existing locale boundary and all colors use
   semantic tokens that render in both light and dark modes.

## Design Constraints

- **Preflight:** `@pte/ui` already owns the accessible `Tabs`/`TabPanel`, `Stepper`,
  semantic design tokens, `Skeleton`, and `LoadingState` primitives. Existing feature
  consumers use exported components rather than importing implementation internals.
  Phase 01 may extend these backwards-compatibly, but must not add Exam API imports or
  duplicate generic card/loading primitives in tenant-web.
- Do not copy the reference dashboard at runtime; adapt its visual boundaries into
  `@pte/ui`.
- Do not move Exam hooks, mutations, validation, or role logic into common UI.
- Do not add a generic abstraction used by only one screen unless it materially reduces
  state/accessibility duplication and is documented.
- Do not change the global DashboardChrome, logo, authentication, or navigation.

## Quality and Testing State

- Quality: approved. Report: `pte-doc/projects/plans/quang-tenant-exam-ui-decomposition/quality/phase-01-common-exam-shell-and-tab-state-quality-report.json`.
- Testing: passed with one skipped item; no applicable unit-test runner/file exists for
  the shared Tabs scope. Static/type/build checks passed; browser interaction is deferred
  to Phase 04. Report: `pte-doc/projects/plans/quang-tenant-exam-ui-decomposition/tests/phase-01-common-exam-shell-and-tab-state-test-report.json`.
- Planned checks: package typecheck/build as applicable, shared-component lint, keyboard
  tab behavior review, light/dark visual review, and `git diff --check`.

## Acceptance criteria

- Existing shared Tabs/Stepper behavior remains compatible with current consumers.
- The Exam shell contract supports six tabs and four wizard steps without API imports.
- Tab changes do not require a full-page loading state.
- No production business logic or API-client file is changed.

## Current cook state

- Implementation complete for this phase: `Tabs` accepts an optional ARIA label;
  `TabPanel` supports opt-in mounted retention and explicit labelling; the public barrel
  exports `TabPanelProps`.
- Build Gate passed: `@pte/ui` typecheck, tenant TypeScript, lint, and production build.
- Hard-mode human confirmation received on 2026-10-08; this phase is complete and Phase 02 is active.
