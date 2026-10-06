# Phase 06: Shared frontend and admin/host UI

Status: completed. Priority: P1 only. Date: 2026-10-03.

## Scope and dependencies

Mapping: FR-01–08, FR-10, FR-14–17, FR-21–22; all P1 surfaces.

Prerequisites: Phases 02–05 API contracts. Phase owner is the implementer for the owning modules below; final quality review is independent. Do not advance past unmet schema/security/transaction prerequisites.

## Design Constraints

Mandatory common-first: inspect [inventory](common-reuse-inventory.md), reuse existing symbols, extend public contracts minimally, justify any new capability in the phase log. No duplicate common response, pagination, errors, security, transport or UI primitives. No cross-module internal repository imports. Existing email audit/listeners remain separate. All errors use module constants plus shared safe HTTP handling; 400 invalid input, 401 unauthenticated, 403 wrong role, 404 foreign/missing personal target, 409 lifecycle/version conflict.

Use transaction-scoped intent persistence, database-enforced idempotency and bounded recoverable work. Preserve user changes and existing business side effects. No new violation/submission/per-examiner completion notification; no automatic score publication or force submission. P2/P3 work is deferred.

Preflight: 2026-10-04. Read `pte-web/AGENTS.md` and the installed Next.js 16.2.9 Server/Client Components, navigation, and error-handling guides. Reuse `@pte/api-client` `ApiClient`/`ApiError`/`PagedResult`/`PageMeta` and existing request/type barrel exports; reuse `createSessionApiClient`, `useTokenManager`, `useCurrentUser`, the existing app `QueryClientProvider`/`lib/apiClient.ts`, and `getUserFacingApiErrorMessage`. Reuse `@pte/ui` `BellIcon`, `Badge`, `Button`, `PageHeader`, `DataTable`, `PaginationControls`, `LoadingState`, `EmptyState`, `ErrorState`, `Alert`, `Modal`, and form primitives. Existing `Dropdown` is action-only and lacks the required rich-popover focus/Escape/return-focus behavior, so a new shared notification presentation component is justified in `packages/ui`; it will not own routes, auth, or transport. Portal adapters remain responsible for authenticated query keys, cache cleanup, and role-specific routes. Existing dashboard bells are decorative and will be replaced in both portal shells.

## Implementation steps

1. Read pte-web/AGENTS.md and relevant installed Next.js guides. Inventory @pte/ui and @pte/api-client first. Add typed notification/announcement/cohort requests to existing api-client transport, not direct fetch/token/error handling.
2. Add one presentational shared NotificationBell/panel/history composition using BellIcon, Badge, Button, states and table/pagination. Existing Dropdown is action-only; justify a rich popover, with keyboard activation, Escape, focus return, outside click and readable unread semantics. Respect client boundaries; shared components do not own app routes/auth.
3. Each portal adapter uses its lib/apiClient, QueryClientProvider and auth hooks. Query keys include authenticated subject and tenant. Cancel/purge queries at logout/account change; stop polling on 401 and clear protected content. Poll unread count every 30 seconds only when visible/authenticated; focus refresh; body fetch on demand.
4. Opening bell does not read. Opening item issues own read mutation with failure feedback; mark-all uses server watermark. Invalidate count/recent/history/detail appropriately. Stable history snapshot resets on explicit refresh or filter change; no cross-account tokens.
5. Replace both decorative bells and unconditional dots. Show no badge for zero, count to99/99+, five recent entries and View all. Add /host/notifications and /admin/notifications and notification detail routes with exact role guards.
6. Add /admin/announcements list/draft composer/preview/detail. Reuse form fields, modal, confirm, table, toast; admin-only nav and routes, not PLATFORM_AUTHOR broad shell permission. Display immutable publication counts including suppressed; draft conflict supports reload without silent overwrite.
7. Host session detail adds minimal cohort preview/finalize confirmation after CLOSED with required outstanding reasons and safe blocked summary. Reuse existing manual/AI mode display; only narrow explicit mode input if existing contract absent. Include all submitted papers; never selectable exclusion checkbox for submitted work.
8. Wire exact application/order/inactive-subscription targets. Missing/foreign/deleted targets show safe unavailable state while notice remains readable. Render plain text, no arbitrary HTML/external redirect.
9. Handle loading/empty/error/retry and stale cached data explicitly. Shared getUserFacingApiErrorMessage supplies safe copy; don't show raw codes/exceptions. Network polling failure does not trap modal in endless loading.

## Concrete file targets and ownership

Unread pagination is live: reset to page 1 when recipient read revision changes after local mutations, cross-tab invalidation or focus refresh. Do not treat arrival watermark as frozen Unread membership. Composer first publish submits expectedDraftVersion; stale preview prompts reload, while retry after committed publication shows the original result. Cohort mode controls obey session serialization and reject replacing already committed manual workflow with AI-only.

packages/api-client/src/types, requests and exports; packages/ui/src/components justified notification presentation; tenant/vendor features/notifications; both DashboardChrome.tsx and lib/navigation.tsx; admin announcement pages; host SessionDetailView and commercial detail views.

File names for new types are proposed; confirm existing equivalents first. Migration numbering must be resolved from current repository, not guessed.

## Permissions, failures, concurrency and recovery

Bind principal/tenant on every personal operation. Sanitize display errors and logs; never include passwords, signed media, answers or provider secrets. Retry only committed logical work with original identity. Recover expired leases and missed evaluator wake-ups; do not retry invalid authorization/business transitions as delivery successes. Document lock ordering and transactional boundaries for this phase and test overlaps, not just sequential happy paths.

## Tests and acceptance evidence

Independent read state across hosts; admin/application and host/session deep links; author denied; identity switch clears panel; hidden tab stops polling; 401 cleans cache; focus and Escape; zero/99+ badges; conflict recovery; failed read feedback; outstanding finalize confirmation; Next client/server build checks.

## Exit criteria

Both portals consume shared presentation/transport; no decorative unread dot; all seven types have correct destinations/states; cohort action usable; role/cache/a11y browser evidence captured.

## Quality and Testing State

- Implementation: complete for the Phase 06 scope; shared transport/types/presentation, tenant notification/history/detail routes, host closed-session grading-cohort control, vendor notification/history/detail routes, and platform-admin announcement CRUD are implemented.
- Common-first evidence: recorded in [common-reuse-inventory.md](common-reuse-inventory.md), including the identity/tenant cache-key correction made during review.
- Unit/integration testing: TDD RED was recorded before production implementation; the green API-client suite passed 14 files and 357 tests with zero failures. Full evidence is in [phase-06-shared-frontend-portals-test-report.json](tests/phase-06-shared-frontend-portals-test-report.json).
- Build/type gates: API client and UI typechecks, tenant/vendor typechecks, tenant/vendor lint, tenant/vendor production builds, and `git diff --check` passed. Vendor lint retains two pre-existing QuestionBank `<img>` warnings and no errors.
- PostgreSQL/browser/performance checks: not run; live HTTP authorization, browser interaction, database/restart and performance evidence remain Phase 07 scope.
- Quality gate: APPROVED with zero blocker/high/medium/low findings; receipt is [phase-06-shared-frontend-portals-receipt.json](quality/phase-06-shared-frontend-portals-receipt.json).
- Code review: [phase-06-shared-frontend-portals-code-review.md](quality/phase-06-shared-frontend-portals-code-review.md) records the independent review and non-blocking limits.
- Hard-mode checkpoint: confirmed by the user with “tiếp tục” on 2026-10-04; Phase 06 is complete and Phase 07 is now active.
