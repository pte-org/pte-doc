# Phase 04: Examiner overview and delivery handoff

Status: completed [quality: skipped_by_user; decision: user_confirmed_skip; tests: not_started_user_declined]. Dependencies: 01–02; final delivery after03. Covers P1 Examiner and P2; FR05–12.

## Design Constraints

Upgrade `/examiner/work`; no write/receipt/reviewVersion/uncertain submission logic changes. Exactly3 progress cards; readiness remains separate from status. Completed counts are unpublished assignment progress, not released results. Zero-eligible COMPLETED is explicitly non-actionable. AI unavailability does not prohibit otherwise-valid manual scoring.

## Files

In `pte-web/apps/tenant-web`: extend `features/examiner/ExaminerQueueView.tsx`; add `features/examiner/components/ExaminerWorkspaceOverview.tsx`, `components/ExaminerPriorityWork.tsx`, `messages/vi.ts`, `messages/en.ts`, `hooks/useExaminerWorkspaceText.ts`. Existing `features/examiner/api.ts` / `constants.ts` provide new hooks/keys from02. Existing `app/(dashboard)/examiner/work/page.tsx` keeps mount. Read `ExaminerAttemptDetailView.tsx` only to preserve return params; do not rework grading/media controls.

## Steps

- [x] Cards “Chưa bắt đầu”, “Đang chấm”, “Đã chốt” use full overview counts. Card clicks choose existing PENDING/IN_PROGRESS/COMPLETED URL filter page0. Add text clarifying own unpublished assignments; completed includes rows with no eligible questions and does not mean Host published.
- [x] Show eligible/finalized totals with explicit unit “câu phải chấm / câu đã chốt” and denominator; 0/0 shows no eligible questions rather than100% human-reviewed. Numerator counts human decisions only.
- [x] Display priority maximum5 rows returned by backend, actionable IN_PROGRESS first then PENDING. CTA “Tiếp tục chấm” means unfinished assigned attempt, not recovering local draft after reload. No completed/eligible0/blocked row in actionable preview.
- [x] Enhance list row labels with progress badge plus readiness reason. “Chờ Host chốt danh sách” only for WAITING_FOR_HOST_FREEZE; other mode/excluded reasons distinct. Policy-blocked attempt may keep a safe read-only/detail link, but not a misleading finalize CTA. Zero-eligible row avoids the existing detail route that returns404; label no eligible work explicitly.
- [x] Priority and list navigation use existing `/examiner/work/{sessionPublicId}/{attemptPublicId}` with current `fromStatus/fromPage`; preserve active list state and no auto-open. Submission retry/drafts remain exclusively controlled by existing detail logic.
- [x] Preserve validated status/page URL behavior, empty/error/loading separation, manual refresh and asOf. Overview errors don't hide existing queue; fake0 on failure forbidden. Existing list defaults stay unchanged unless product explicitly approves a default-filter adjustment.
- [x] Localize all touched queue/overview strings vi/en using useLocale conventions; theme semantics/accessibility same as03. No AI score/provider/model fields exposed in overview; wait/freeze labels do not depend on AI state.
- [x] Review final diff against scope: default routing/flags/STOMP/finalization/publication unchanged, no schema changes, no unintended Host/Proctor permission expansion, exact frontend/backend DTO names and count predicate parity.
- [x] Run authorized compile-only checks: backend Maven `-pl app -am -DskipTests compile` (record incremental vs fresh and fallback if wrapper environment fails); `pnpm.cmd --filter @pte/api-client typecheck`; `pnpm.cmd --filter tenant-web exec tsc --noEmit --incremental false`. No tests/E2E/quality invocation under current preference. Record command output and unverified startup/query/runtime limitations.
- [x] Produce implementation handoff note under this plan directory with modified paths, checks/results, unresolved scope/policy decisions and rollback steps. No deployment/rollout; preserve existing Proctor flag. Update phase status based on actual evidence, not compile success alone.

## Acceptance evidence

Counts include work beyond page0; exact status/card parity including eligible0; pending blocked separate from pending actionable; manual permission unaffected by AI pending; successful chốt invalidates queue/overview; other actor cache never reused; priority links preserve return state. Independent card/queue errors and theme/locale responsive behavior. These are acceptance cases, not test results.

## Quality and Testing State

Quality: not evaluated; prior preference skip. Testing: not started; prior preference skip tests/E2E. Compile/typecheck planned; runtime/startup/migration/browser checks not authorized as part of current compile-only scope and must remain reported unverified. No production-ready or fully-passing claim without the necessary evidence.
