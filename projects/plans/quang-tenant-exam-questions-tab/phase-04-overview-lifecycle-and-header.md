# Phase 04: Move lifecycle presentation into Overview and simplify the header

**Status:** Completed after hard-mode confirmation  
**Stories:** P1 Overview actions; P1 clean header  
**Unit tests:** yes (default hard-mode testing; no TDD)  
**Quality gate:** yes (hard-mode default)  
**Dependencies:** Phase 03 Questions tab integrated; Phase 01 lifecycle baseline

## Goal / outcome

Make Overview the single place where a Host sees Exam status and operates valid lifecycle
actions. Keep lifecycle mutation ownership and behavior in `SessionDetailView`, while the
header retains identity/back context and no longer duplicates View/Open/Close/Cancel/status.

## Exact files owned

### Modify

- `pte-web/apps/tenant-web/features/exams/components/SessionDetailView.tsx`
  - Keep `useOpenSession`, `useCloseSession`, and `useCancelSession`; remove header action
    rail and standalone preview modal state/rendering; remove the global lifecycle
    `<Alert>` from this shell; pass lifecycle view-model/error to the tab composition.
- `pte-web/apps/tenant-web/features/exams/components/ExamDetailTabs.tsx`
  - Accept/pass lifecycle state and callbacks to Overview while preserving seven-tab
    navigation, Questions retention, and participant modal wiring.
- `pte-web/apps/tenant-web/features/exams/components/ExamOverviewTab.tsx`
  - Render status card and one state-aware lifecycle action area using the passed hooks/
    callbacks/pending/error state; retain schedule, capacity, policy, code, and metrics.

### Create

- `tests/phase-04-lifecycle-contract.json`
  - Evidence receipt for lifecycle guard parity, single Overview error surface, and
    header action removal.

### Read-only

- `pte-web/apps/tenant-web/features/exams/constants/index.ts`
- `tests/phase-01-contract-check.ps1`
- `pte-web/apps/tenant-web/features/exams/api/index.ts`
- `pte-web/apps/tenant-web/features/exams/components/ExamQuestionsTab.tsx`
- `pte-web/packages/ui/src/components/PageHeader.tsx`
- `pte-web/packages/ui/src/components/Badge.tsx`
- `pte-web/packages/ui/src/i18n/LocaleProvider.tsx` (protected)
- Backend lifecycle service/controller evidence from Phase 01

### Never modify

- Lifecycle hooks/API client/backend contracts, authentication/role boundaries, vendor-web,
  protected locale provider, old decomposition plan, and unrelated feature files.

## Implementation steps

1. Define a narrow Overview lifecycle prop/view-model shape containing status, Open/Close/
   Cancel callbacks, pending flags, and lifecycle error; keep the mutation instances in
   `SessionDetailView`.
2. Preserve exact guards and confirmation behavior: Open only for `SCHEDULED`, Close only
   for `OPEN`, Cancel only for `DRAFT/PREPARING/READY/SCHEDULED`.
3. Remove `previewOpen`, `ExamPreviewModal` header rendering, and the standalone View Exam
   action from `SessionDetailView`. Questions is now the preview entry point.
4. Leave PageHeader identity/back navigation intact. If an overflow action is necessary,
   it must be compact and contain no duplicate lifecycle controls; do not add one merely
   to replace the old button row.
5. Render the current status badge and a single lifecycle action area in Overview. Keep
   mutation errors adjacent to that area with accessible alert semantics. The Overview
   component is the only lifecycle-error renderer; `SessionDetailView` must not render a
   second global lifecycle `<Alert>`.
6. Verify buttons retain disabled/pending behavior, confirmations, invalidation, and role
   boundary. Do not move mutation hooks into `ExamOverviewTab`.
7. Resolve moved/new visible status, action, confirmation, and error labels through the
   existing `useLocale().t` contract and the Phase 01 locale handoff. Do not import raw
   English `SESSION_DETAIL_TEXT`/status labels for the new Overview/header path.
8. Add a static assertion that the lifecycle error is rendered exactly once in
   `ExamOverviewTab` and that the shell no longer renders the global lifecycle error.
9. Run the reusable Phase 01 contract-check script in `final` mode and record the
   result in `tests/phase-04-lifecycle-contract.json`. Ensure there is no duplicate
   status/action rendering in the header or tab content.

## Acceptance checks

- Header contains identity/back context only, with zero View Exam and zero lifecycle action
  rail/status duplicates.
- Overview contains exactly one status card and one state-aware lifecycle area.
- Existing guards, confirmation messages, pending disabled state, errors, and successful
  cache invalidation remain behaviorally equivalent.
- Questions remains the only generated snapshot preview entry point in the detail tabs.
- `SessionDetailView` contains no global lifecycle error alert; `ExamOverviewTab` contains
  exactly one lifecycle error surface adjacent to the action area.
- Existing Overview schedule/capacity/policy/code/metrics and all other tabs remain intact.
- Host authorization boundary remains unchanged; no Examiner work route is touched.
- Typecheck/lint and focused lifecycle contract assertions pass.

## Design Constraints

- Presentation moves; business ownership does not. `SessionDetailView` remains the only
  mutation owner.
- Do not duplicate hooks in Overview or introduce a second status guard.
- Use existing semantic tokens and localized labels; no light-only action colors.
- Keep Overview scannable: lifecycle action grouping must not recreate the old crowded
  header row or duplicate full settings/result workflows.
- Preserve existing modal reachability except the intentionally replaced header preview
  entry, which is now the Questions tab.

## Cook State

- **Phase:** 04 completed
- **Unit tests:** yes (hard-mode default)
- **Quality gate:** APPROVED
- **TDD:** not enabled
- **Current step:** handed off to Phase 05 after user continuation confirmation

## Quality and Testing State

- **Quality:** APPROVED. The current-tree gate found zero blocking or advisory findings;
  receipt: quality/phase-04-overview-lifecycle-and-header-receipt.json.
- **Testing:** PASSED. Final lifecycle contract, focused static assertions, tenant
  typecheck, scoped lint, Prettier, production build, protected-file hash, and quality
  receipt verification passed. Browser smoke was skipped because no authenticated tenant
  browser session/server was available. Report: tests/phase-04-test-report.json.

## Concurrent-agent safety

- Recheck all protected paths before editing the three owned tenant files.
- Never alter `LocaleProvider.tsx`; coordinate any missing action/status labels with its
  owner.
- Do not begin this phase if the Phase 01 locale handoff is blocked or untriaged.
- Keep unrelated existing changes in `SessionDetailView.tsx` or Overview if present; stop
  and reconcile ownership if a concurrent diff overlaps these exact files.

## Handoff state

Phase 04 hands off when the header is clean, Overview owns the visible lifecycle controls,
and live/static evidence shows the existing mutation behavior and guards are preserved.
Phase 05 then performs the complete seven-tab and browser regression gate.
