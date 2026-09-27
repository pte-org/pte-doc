# Phase 6: API client and vendor/host workflows

## Goal

Expose the backend contract through typed shared requests and deliver an
understandable authoring/host workflow without leaking implementation details.

## Vendor workflow

1. Keep navigation and existing question-bank screens intact. Add/complete
   approval queue, revision status, pool readiness and template feasibility
   affordances.
2. In the score-template editor, show slot requirements and availability
   warnings; enforce draft-only editing in the UI while retaining server
   enforcement.
3. If author drafts are enabled, show `Draft`, `Awaiting approval`, `Active`,
   and `Retired` labels with role-appropriate actions. Activation is never shown
   as an author action.
4. Do not render question content in tenant host screens before the exam opens.

## Host workflow

Build a stepper rather than one oversized modal:

1. Basic details and exam mode.
2. Choose active template and valid subscription/package; show date window and
   remaining per-session capacity.
3. Schedule and exam policy/form mode.
4. Add individual students, classes, and programs; display union/dedupe counts.
5. Select series/reuse policy; show existing conflicts and reasons.
6. Run preflight; render all slot/package/audience issues with actions to fix.
7. Confirm generation/publish; show persistent job progress and a safe summary.
8. Exam detail shows lifecycle, schedule, package lane (friendly name/license
   masking), audience counts/exclusions, form count, proctors, and operations.

## Shared API client

Add typed modules for:

- session draft/update/publish/cancel
- audience sources and preview
- preflight/conflict report
- generation job status/retry/cancel
- forms and safe assignment summary
- template feasibility and approval if that contract is enabled

Update `packages/api-client/src/index.ts` exports and keep request payloads
aligned with Spring DTOs. Use TanStack Query hooks in feature `api.ts` files;
do not add raw `fetch` calls in TSX.

## Frontend locations

- `apps/tenant-web/features/exams/api/index.ts`
- `apps/tenant-web/features/exams/types/index.ts`
- `apps/tenant-web/features/exams/components/CreateSessionModal.tsx` (replace
  with or delegate to a stepper)
- `apps/tenant-web/features/exams/components/ExamsListView.tsx`
- `apps/tenant-web/features/exams/components/SessionDetailView.tsx`
- `apps/tenant-web/features/exams/components/ClassAssignmentSection.tsx`
- `apps/tenant-web/features/examoperations/`
- `apps/vendor-web/features/questionbank/`
- `apps/vendor-web/features/scoretemplate/`
- `apps/*/features/**/constants.ts` and error formatters.

## Design Constraints

- Preserve existing routing and home-page UI structure.
- Use shared `@pte/ui` Modal semantics that do not discard dirty forms on an
  accidental outside click; closing a dirty stepper requires explicit confirm.
- All labels, alerts, confirmation text and error mappings live in feature
  constants, not inline TSX literals.
- Format date/time consistently and avoid SSR/client locale mismatches.
- The UI may hide unavailable actions, but every mutation still handles a
  server-side 401/403/409/422 response.
- Polling a generation job must stop on terminal state and not create duplicate
  requests on remount.
- Show excluded students as reviewable data, not as an unexplained absence.

## Quality and Testing State

- Unit-test expansion: enabled per the latest user instruction; API-client
  tests, typed workflow wrappers and role-aware template UI were verified.
- Quality gate: mandatory and approved; report and receipt are stored under
  `quality/phase-06-api-client-and-web-workflows-*`.
- Testing: passed; the final regression evidence is recorded in
  `tests/phase-08-verification-test-report.json`.
- Required checks during cook: API-client typecheck, tenant/vendor lint and
  build, Prettier/diff check, manual responsive/keyboard form walkthrough,
  browser smoke for draft→preflight→generation→detail, and role-based UI
  action visibility.

## Exit criteria

- A non-technical host can complete the workflow without seeing machine error
  codes or question answers.
- Vendor/admin roles see only authorized template/question actions.
- UI handles pending, failed, excluded and conflict states with recovery paths.
