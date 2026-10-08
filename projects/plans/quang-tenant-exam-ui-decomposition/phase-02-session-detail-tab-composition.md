# Phase 02 — Session detail tab composition

**Plan:** [plan.md](plan.md) · **Spec:** [spec.md](spec.md)
**Depends on:** Phase 01
**Outcome:** the existing Exam detail route presents six task-oriented tabs while
preserving every existing behavior.

## Tab mapping

| Tab | Existing content owner |
|---|---|
| Tổng quan | header, lifecycle actions, exam code, schedule, preview, compact summaries |
| Cài đặt kỳ thi | current configuration and schedule presentation |
| Người dự thi & coi thi | `ClassAssignmentSection`, `StudentRosterTable`, student modals, `ProctorAssignmentSection` |
| Bài nộp | `AnswersSection`, `AnswerDetailModal` |
| Examiner | `ExaminerAssignmentSection`, assignment history/load/progress |
| Kết quả & phát hành | `HostScoreReviewPanel`, `GradingCohortSection`, `ReportPublicationPanel` |

## Files to inspect/change

- `pte-web/apps/tenant-web/features/exams/components/SessionDetailView.tsx`
- `SessionTable.tsx` only if the detail entry affordance needs a presentation-only
  alignment; no list contract change.
- Existing tabbed compositions/components listed in the table above.
- Feature constants for concise Vietnamese/English labels and accessibility names.
- Existing route loading/error files only if a local tab skeleton contract needs a
  presentation update.

## Steps

1. Extract the detail header/action rail without changing lifecycle mutation ownership.
2. Create a tenant feature-level Exam detail shell that renders the six approved tabs,
   reads the active tab, and retains visited panels/local state.
3. Move existing JSX blocks into tab compositions. Pass the existing `sessionPublicId`
   and status/permissions; do not rewrite child API hooks.
4. Keep the first tab compact: no duplicate long descriptions, no duplicate settings
   editor, and no result tables on Overview.
5. Add local tab skeleton/empty/error framing around existing child states. Do not hide
   API errors or replace existing status guards.
6. Verify Host-only result controls remain absent from the Examiner role surface and the
   `/examiner/work` route is unchanged.
7. Verify class assignment remains available after Exam creation and retains the
   existing `SCHEDULED` guard.

## Design Constraints

- This is a presentation decomposition; all child component query/mutation ownership
  remains in `apps/tenant-web/features/exams` or the existing examoperations feature.
- Student submissions and Examiner workflow must remain visibly and technically
  separate.
- Keep lifecycle actions in one header rail; do not duplicate Open/Close/Cancel buttons
  in multiple tabs.
- Use existing `Tabs`/`TabPanel` accessibility semantics and preserve responsive
  horizontal scrolling.
- Avoid nested primary tabs. Use cards/accordions inside a tab only where an existing
  section is already independently collapsible.

## Quality and Testing State

- Preflight: `SessionDetailView` owns lifecycle mutations; existing child sections own their
  queries and mutations; the shared `Tabs`/`TabPanel` contract now supports explicit ids,
  labelling, and visited-panel retention; no API contract change is planned.
- Quality: approved. Report: [phase-02-session-detail-tab-composition-quality-report.json](quality/phase-02-session-detail-tab-composition-quality-report.json)
- Testing: passed with browser interaction checks deferred to Phase 04. Report: [phase-02-session-detail-tab-composition-test-report.json](tests/phase-02-session-detail-tab-composition-test-report.json)
- Planned checks: typecheck, lint, build, keyboard tab traversal, tab deep-link/back-
  forward behavior if enabled, retained filters/selection after switching, and browser
  smoke for all six tabs in both themes.

## Current cook state

- Implemented the six-tab detail composition and moved the existing child sections without
  changing their API hooks, lifecycle mutations, status guards, or route contracts.
- Stateful Submissions and Examiner panels retain local state after first visit; lightweight
  Settings, Participants, and Results panels unmount when inactive, and modal overlays render
  outside hidden tab panels.
- Build Gate passed: `@pte/ui` typecheck, tenant TypeScript, lint, production build, and
  `git diff --check`.
- Quality gate approved and receipt issued at
  `quality/phase-02-session-detail-tab-composition-receipt.json`.
- Hard-mode human confirmation received on 2026-10-08; this phase is complete and Phase 03 is now active.

## Acceptance criteria

- The long vertical SessionDetailView sequence is replaced by the six approved tabs.
- All existing actions remain reachable and preserve their disabled/confirmation rules.
- Returning to a visited Bài nộp or Examiner tab does not reset its local filter,
  pagination, or selected detail state.
- Switching tabs never blanks the global dashboard shell.
- No API/backend/API-client changes are present in the diff.
