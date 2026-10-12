# Examiner Workspace Completion — Alternative Research

Date: 2026-10-12. Scope: frontend code audit and minimum compatible refactor; source inspection only, no production changes or tests executed.

## Ground truth

The web workspace is Next.js 16.2.9 App Router / React 19.2.4, TypeScript, TanStack Query v5, pnpm/Turborepo. Feature code lives directly under `apps/tenant-web/features`, not `src/features`. Applicable rules: `pte-web/AGENTS.md` and `docs/CODING_STANDARDS_WEB.md`. Routes remain thin; components/functions below 300/150 lines, feature hooks in `api.ts`, contracts in `@pte/api-client`, locale copy in catalogs, common `@pte/ui` components without visual overrides.

## Existing vs missing functionality

| Area | Existing evidence | Gap / change |
|---|---|---|
| Routes | `app/(dashboard)/examiner/work/page.tsx` -> `ExaminerWorkView` -> `ExaminerQueueView`; detail at `/work/[sessionPublicId]/[attemptPublicId]` | Overview and all three filtered links render the same composite screen. `ExaminerWorkView` also has unused local selected-detail state. |
| Sidebar | `lib/navigation.tsx` links overview and `?status=PENDING/IN_PROGRESS/COMPLETED`; `features/auth/utils/resolveActiveNavItem.ts` handles exact status and detail `fromStatus` | Existing query-aware navigation already works. Add resources only when real authorized endpoints/content exist. Preserve Host classes override and Proctor routes. |
| Overview | `ExaminerWorkspaceOverview`, `ExaminerPriorityWork`, `useExaminerOverview`; counts, answer progress, priority preview, asOf | `ExaminerQueueView.tsx:44-45,127-147` requests and renders overview + priority + queue for every status. Extract overview-only composition; add assigned total only with documented backend scope. Priority errors currently become empty preview via `?? []`. |
| Queue | Server pagination and URL page/status; status filter; attempt/session IDs, assignedAt, submitted/eligible counts | No search, sort, section/task filter, deadline or human-readable attempt/session metadata in current examiner contract. These require backend-supported fields/filters; do not fake local filtering of one page. Different page titles, descriptions, empty states and actions needed. |
| Start | Priority button says start; clicking only navigates to read detail | Client has no start command. Add explicit backend transition; a GET remains side-effect free. Opening Pending detail must not count as started. |
| Detail | Prompt/audio/image/text/options renderer, answer navigation, AI availability/score/version, read-only submitted decision, media failure/refresh handling | No task rubric descriptors/criteria, criterion inputs, examiner comments, score summary before attempt completion, server draft status or previous/next buttons. Existing navigator can be reused. |
| AI and decisions | `DecisionPanel.tsx` validates integer 0–100; `AiReferencePanel` applies AI to local draft; final submit carries kind, reviewed AI version, review version and request UUID | Current scalar normalized score is existing business contract, not a rubric. Do not invent per-task scoring conversion or replace aggregation. Preserve Examiner final authority and Host publication. |
| Drafts | `useExaminerSubmissions.ts:55` stores drafts in React state keyed answer ID, preserving edits during same-mount question changes; beforeunload and explicit Back warning | No server save endpoint; no persistent comments; reload/new tab/SPA sidebar navigation loses edits. Add versioned server draft DTO/hooks and unsaved-navigation coordination; local state alone does not satisfy Save Draft. |
| Retry | Exact retained per-answer finalization payload and request UUID; stale review refetch; unknown outcome reconcile | Preserve these protections when adding draft/start/attempt review. Distinguish authoritative rejection from unknown outcome; do not clear unsaved/retained state on unrelated response. Current retained state is mount-local. |
| History / exceptions | Decision response exposes score/kind/finalizedAt and reviewed AI version | Examiner client exposes only queue/overview/detail/score. No grading-history, guidelines, flags, review request or reopen request. Existing Host score-source audit is a different domain and must not masquerade as Examiner grading history. |
| Permissions | `TenantDashboardLayoutChrome.tsx` restricts Examiner area to EXAMINER; query keys scoped by token subject + tenant | Browser restrictions are presentation only. Every new backend command/read must independently enforce current assignment and scope. No standalone blind multi-grader workflow in current examiner contracts. |
| Error UI | Queue/detail retry; overview skeleton/error; media retries | Overview displays raw `error.message`; detail uses static English constants; headers default missing counts to zero during loading; priority lacks error state. Use safe translated error catalog and separate initial load/refetch/stale/partial error states. |

## Alternative routing approaches

**Recommended: preserve existing query-aware canonical route with separate views.** `/examiner/work` renders only `ExaminerOverviewView`; `?status=PENDING`, `IN_PROGRESS`, `COMPLETED` renders status-scoped `ExaminerQueueView`. A thin workspace controller parses/normalizes URL and chooses one component. Each view owns only its required query. Reuse queue row/table primitives across statuses while supplying status-specific columns/actions/messages. Keep detail `fromStatus/fromPage` navigation and bookmarks; when origin is overview, return to overview. Handle legacy `?status=ALL` explicitly by normalization or an agreed migration rather than accidentally showing full queue on Overview.

**Alternative: separate `/examiner/pending`, `/in-progress`, `/completed` routes.** Easier conventional breadcrumbs but requires redirects for existing `?status` links, nav resolver changes, detail return-path migration and extra route boundary files. Four routes must share queue composition, not copy it. No business benefit currently justifies this wider change unless explicit URLs are required.

Both options provide distinct pages in user behavior. Query parameters are already the codebase convention for these status views; the bug is shared composition, not URL shape.

## Safe implementation outline

1. Centralize status/view parsing, origin navigation, query parameter serialization and localized page metadata; unit-test pure functions.
2. Split Overview and Queue compositions. Overview uses aggregate + bounded priority data only; queues use selected server status/page/search/sort/filter. No overview request on every queue page. Remove dead wrapper state.
3. Add backend contracts before UI start/draft/rubric/history integration. Do not relabel final score POST as draft save or implicitly start on GET. Queue progress must separately represent started/draft/finalized where approved.
4. Refactor submission hook into focused draft and finalization controllers; versioned server snapshots plus local dirty revision counters protect edits from late responses. Save only the captured revision; mark Saved only after server acknowledgement. Persist drafts scoped to tenant/examiner/current assignment/answer. Treat revoked assignment, auth expiry and conflicts explicitly.
5. Completed detail remains read-only. Current finalized answer decisions can be read safely; attempt-wide completion/reopen and rubric snapshots require authoritative backend representation. No client-only finalization aggregation.
6. Add history/guidelines resources only after backend-owned history and verified grading definitions exist. Flags/reopen/review requests need confirmed owner, permitted transitions and publication restrictions; omit nonfunctional menu entries while dependencies are unresolved.

## Reuse and affected files

Reuse `@pte/ui` PageHeader, DataTable/Table, TableFilters, Pagination, Skeleton, EmptyState, Alert, Button, Input, FormField, DescriptionList, ConfirmDialog and Toast. Domain-specific rubric/AI/answer/media UI stays under Examiner feature. Existing `components/AnswerContentRenderer.tsx`, `QuestionNavigator.tsx`, `ConfirmDecisionDialog.tsx`, `ExaminerWorkspaceOverview.tsx`, `ExaminerPriorityWork.tsx` are starting points, not replacement mockups.

Likely changes: Examiner route wrapper and feature views; `api.ts`, `queryKeys.ts`, `useExaminerSubmissions.ts`; focused new hooks/types/constants/components; `messages/vi.ts`, `messages/en.ts`, `hooks/useExaminerWorkspaceText.ts`; examiner request/type contracts in `packages/api-client/src/requests/scoring/examiner.ts` and `types/scoring/examiner.ts`; nav constants/catalogs and resources routes when implemented. `resolveActiveNavItem.ts` is currently untracked user attendance work: preserve and extend narrowly, do not overwrite it. Avoid modifying Proctor/Host common behavior.

## Verification infrastructure

- Root scripts: `turbo build`, `turbo lint`, `turbo test`; tenant scripts: `next build`, `eslint`, `vitest run`; api-client: `tsc --noEmit`, `vitest run`.
- Tenant Vitest currently uses Node environment and `features/**/*.test.ts`; existing tests are pure utilities. No React DOM Testing Library/DOM environment is declared. A component-test plan must explicitly add compatible tooling or use pure controller tests plus installed browser tooling; do not assume JSX component tests work today.
- Existing examiner tests: `packages/api-client/src/requests/scoring/examiner.test.ts` checks URL/body wiring only. Add tests for start/save/history contracts, URL view selection, state transitions/revision protection and error categorization. Backend integration remains necessary for IDOR/concurrency/finalization protections.
- Tenant has no typecheck script; use direct installed `tsc.cmd --noEmit --incremental false`, scoped installed eslint, then relevant scripts/build. Avoid package-manager auto-install or rewriting existing modified `pnpm-lock.yaml` just to inspect.
- Attachment explicitly requires tests, overriding earlier skip-test preference for unrelated tasks. Cover the specified behavior matrix; unsupported flags/reopen/multiple independent examiners need conditional cases, not fabricated success claims.

## Decisions needing confirmation / backend audit

1. Are true per-task rubric criterion scores mandatory for this delivery, and what existing authoritative rubric + conversion feeds the current normalized 0–100 examiner score? Current examiner DTO has neither criteria nor rubric identifiers. Do not define new scoring math without approved source.
2. Should Completed include previously published assignments? Prior approved overview scope was current assigned finalized but unpublished queue. Attachment's historical completion/history requirement may broaden that; separate active queue counts from retained history if approved.
3. Flags/reopen/review require explicit Host/Admin owner, permissions, blocking semantics and behavior after publication. Attachment asks for proposal when unsupported, not unilateral invention.
4. Deadline fields are absent from examiner DTO. Only show deadline/overdue UI after a genuine backend deadline is found or approved, never infer it from exam closesAt.

Backend research must confirm assignment granularity and scoring rules, lifecycle status persistence, migration/backfill/rollback and existing audit ownership before these front-end assumptions become a final implementation plan.

## Score template provenance check

`packages/api-client/src/types/assessment/index.ts:38-47` exposes snapshot `scoreTemplatePublicId` and `scoreTemplateVersion`. `types/scoretemplate/index.ts:12-30` exposes task type/section, scoringMethod, timing, and overall/four-skill weights; template response adds code/name/version/policy. These fields can support factual grading guidelines and scoring context **from the pinned snapshot version** once authorized backend projections expose them. They do not contain rubric criterion descriptors, discrete score bands or a criterion-to-0–100 conversion. Do not fetch current active template and imply it is the one used by an old attempt. Expose only minimal pinned context to Examiner rather than broad administrative template access. No new rubric definition should be inferred from skill weights.
