# Phase 08: Tenant exam, examiner, student, public, and auth migration

## Objective

Complete visual/theme/locale migration for exam workflows, examiner/student
role surfaces, public home, and authentication screens after the host shell is
stable.

## Files and Areas

- `pte-web/apps/tenant-web/features/exams/**`
- `pte-web/apps/tenant-web/features/examiner/**`
- `pte-web/apps/tenant-web/features/reports/**`
- `pte-web/apps/tenant-web/features/public/**`
- Authentication screens under `features/auth/**`, excluding the shared
  dashboard shell composition owned by phase 04/07
- Tenant routes under `app/(dashboard)/examiner`, `student`, `host/exams`, and
  public/auth route groups

## Inputs

- Phase 07 host verification and the Phase 01 actor/behavior/failure matrices.
- Approved mini-plans for `CreateExamWizard`, `SessionDetailView`,
  `ExaminerAssignmentSection`, `HostScoreReviewPanel`, and `ExaminerWorkView`.
- Common theme/locale and browser-navigation contracts.

## Outputs

- Mini-plan records for each P1/P2 exam or role surface implemented here.
- `phase-08-verification.md`: role matrix, navigation semantics, scoring/
  assignment/recovery scenarios, theme/locale/responsive evidence, and limits.

## Steps

1. Migrate exam list, create wizard, session detail, preview, assignments,
   scoring, answers, and publication panels to common surfaces.
2. Treat `CreateExamWizard` as a P1 candidate: use explicit Setup, Audience,
   Policy, and Review steps inside the current modal/route contract.
3. Treat `SessionDetailView` as a P1 candidate: group lifecycle/configuration,
   participants, staff/scoring, and answers/publication into in-route tabs.
4. Treat examiner assignment and host score review as P2 sub-panel candidates;
   keep scoring and assignment state in the exam feature.
5. Migrate `ExaminerWorkView` as a master-detail role surface; use a mobile
   detail drawer while keeping `/examiner/work`.
6. Migrate examiner work and student results with role-specific labels and
   accessible empty/loading/error states.
7. Migrate public home/login/register last so bilingual copy and theme behavior
   are consistent with the dashboard but do not force dashboard navigation into
   public pages.

## Design Constraints

- Do not change exam lifecycle, scoring, publication, examiner/proctor
  assignment, or student result behavior.
- Do not turn the public landing page into an authenticated dashboard.
- Do not include the Flutter exam-taking client in this phase.
- Preserve existing auth redirects and role gates.
- Verify pathname/query/hash, refresh/deep-link, browser back/forward, Escape,
  close, focus return, and existing modal/action entry points for every
  tab/step/drawer/master-detail treatment.

## Quality and Testing State

- Quality: not evaluated.
- Testing: not started; verify each role separately where local accounts/data
  permit, and distinguish static checks from authenticated browser evidence.

## Blocking Gate

- **PASS** when exam and role surfaces preserve role gates, route/browser
  semantics, scoring/assignment/publication behavior, and all required visual
  checks in both themes/locales.
- **UNVERIFIED** when an examiner, proctor, student, public, or auth scenario
  cannot be exercised locally; record the exact limitation. This blocks phase
  09 unless a written waiver follows the master-plan gate policy.
- **BLOCKED** when a tab/step/drawer changes a route/action contract, removes a
  role-protected action, or loses stale/conflict/recovery behavior.

## Exit Criteria

- Exam and role-specific surfaces render in both themes and both locales.
- P1 exam density candidates are grouped without route/API/business behavior
  changes.
- Public/auth screens retain their distinct information architecture.

## Cook Record 2026-10-07

- Implementation: common theme/locale/auth/public surfaces were integrated and
  the existing tenant exam wizard received a common stepper presentation.
- Verification: tenant typecheck, lint, and build passed; examiner/proctor/
  student role, exam flow, and responsive browser checks were not run.
- Blocking Gate: **UNVERIFIED** because runtime evidence and `ck:quality` were
  skipped at the user's request.
