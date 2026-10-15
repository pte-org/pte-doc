# Spec: Tenant Exam UI decomposition

**Date:** 2026-10-08
**Status:** User direction approved; ready for phased planning
**Target:** `pte-web/apps/tenant-web` and reusable presentation primitives in `pte-web/packages/ui`

## Problem

The tenant Exam detail screen currently renders lifecycle controls, exam configuration,
audience management, proctor assignment, examiner assignment, submitted answers, score
review, grading finalization, and report publication as one long vertical page. The
screen is difficult to scan and forces unrelated workflows into one scroll context.

The create flow is also dense: the existing `CreateExamWizard` is a large modal with
setup, policy, schedule, audience-source selection, and review concerns mixed into two
steps.

## User direction

- Group the Exam detail screen by task, not by implementation component.
- Do not require assigning a Class immediately after the Exam is created.
- Keep the Examiner workflow distinct from the generic student Submission list.
- Preserve existing API contracts, business rules, role boundaries, mutations, and
  routes unless a later product decision explicitly changes them.
- Build reusable/common presentation primitives before composing the tenant Exam screen.
- Preserve the PTE logo and the existing visual-system direction: Vietnamese default,
  English secondary locale, light/dark semantic theme support, and smooth loading/motion.

## Proposed information architecture

### Exam detail tabs

1. **Tổng quan** — status, lifecycle actions, schedule, exam code, preview, compact
   metrics, and next actions.
2. **Cài đặt kỳ thi** — existing configuration and schedule information presented as
   focused cards/sections.
3. **Người dự thi & coi thi** — assigned Classes, enrolled Students, and Proctors.
4. **Bài nộp** — student submitted-answer list, filters, pagination, and answer detail.
5. **Examiner** — Examiner assignment method, scope mapping, preview/confirm history,
   examiner loads, and progress. The actual blind marking workspace remains the
   existing role-specific `/examiner/work` surface.
6. **Kết quả & phát hành** — Host score-source review, grading-cohort finalization,
   publication readiness, and report publication.

The lifecycle action rail remains in the Exam header and is not duplicated inside each
tab. The six-tab limit is intentional; lower-frequency audit/history content should be
added later only if a real API-backed need is approved.

### Create Exam flow

Keep the existing create route and mutation flow, but present the form as a spacious
wizard/full-screen dialog rather than a cramped large modal. The UI steps are:

1. **Thông tin & nội dung** — existing name, template/subscription, mode, capacity,
   skill scope, and currently supported content fields.
2. **Thời gian & chính sách** — existing schedule, retry, anti-cheat, and policy fields;
   do not invent new API-backed settings.
3. **Audience** — existing Student/Class/Program source selection when required by the
   current contract. Class assignment after creation remains in the detail tab.
4. **Review & tạo** — existing review information and the existing submit payload.

This is a presentation reorganization. If the product later wants an Exam with no
audience source at all, that is a separate lifecycle/API decision because the current
validator requires at least one source before generation.

## Functional boundaries

- `AnswersSection` represents student submissions; it must not become the Examiner
  scoring workspace.
- `ExaminerAssignmentSection` represents Host-side assignment/progress; it must not
  expose Host-only score-source metadata to the Examiner role.
- `HostScoreReviewPanel`, `GradingCohortSection`, and `ReportPublicationPanel` remain
  Host-owned result/publishing operations.
- Existing permissions, disabled-state rules, status guards, concurrency/preflight
  behavior, query keys, mutation invalidation, and modal entry points remain intact.
- No backend, database, API-client contract, scoring rule, or authentication change is
  part of this UI decomposition.

## Common-first component boundary

Presentation primitives that are reused by more than one tenant Exam tab belong in
`packages/ui` or the existing common layer:

- detail shell/header and compact action rail
- accessible tabs/tab panels with counts and horizontal overflow
- summary metric grid and section card
- tab-level loading/skeleton shell
- wizard shell, step indicator, and sticky footer actions
- empty/error/notice states compatible with light and dark themes

Exam-specific composition and all data-fetching/mutation ownership stay in
`apps/tenant-web/features/exams`. Common components receive data and callbacks; they do
not import Exam APIs.

## UX and motion requirements

- Switching tabs must not blank the entire dashboard or remount the global shell.
- A visited tab should retain its filters, pagination, and selected detail state when
  the user switches away and returns.
- The first visit to a tab may show a local tab skeleton; subsequent visits should keep
  existing content visible while data revalidates.
- Tab navigation must remain keyboard accessible and horizontally scrollable on narrow
  screens.
- Use existing semantic theme tokens and motion primitives. New Exam UI must not add
  light-only hard-coded colors that reproduce the existing dark-mode bug.
- Prefer concise labels and remove redundant explanatory paragraphs from the page;
  use contextual helper text only where an action or validation needs it.

## Acceptance criteria

1. The current Exam detail route exposes the six approved task tabs and no longer
   renders all major workflows in one vertical sequence.
2. Existing lifecycle actions, Preview, copy-code, class/student management, proctor
   assignment, Examiner assignment, answer detail/scoring, grading finalization, and
   report publication remain reachable and behave as before.
3. Student submissions, Examiner assignment/progress, and Host result publication are
   visibly separate workflows.
4. Create Exam uses the approved four-step presentation while sending the same existing
   create input and preserving current audience validation.
5. No API-client or backend file changes are required for this phase.
6. Tab switching preserves the global shell and does not show a full-page loading flash;
   local skeletons are used where data is first loaded.
7. New shared primitives are theme-safe in light/dark mode and have Vietnamese/English
   labels through the existing locale boundary.
8. Tenant-web lint, TypeScript no-emit check, production build, and `git diff --check`
   pass; existing vendor-web behavior remains untouched.

## Out of scope

- Creating a new backend draft lifecycle that allows an empty audience.
- Moving the Examiner work queue to the Host Exam detail route.
- New analytics, audit APIs, bulk examiner scoring, or result-calculation changes.
- Rewriting unrelated tenant screens, vendor/admin screens, or the global auth model.

## Risks

- Unmounting inactive tabs would reset filters and trigger a poor return experience;
  use a visited-tab retention strategy or an equivalent state-preserving composition.
- Moving sections without preserving their local query/mutation ownership can alter
  invalidation or authorization behavior; decomposition must remain presentation-only.
- The current create validator requires an audience source. Hiding that requirement
  behind a new optional UI would create a misleading flow and is prohibited here.
- Some existing feature classes still use literal light-palette utilities. New shared
  primitives must use semantic tokens, while legacy migration remains separately
  tracked.
