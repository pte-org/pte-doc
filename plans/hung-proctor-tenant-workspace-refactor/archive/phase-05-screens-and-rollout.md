# Phase 05 — Product screens and verified rollout

Status: completed. Dependency: 04 completed. Coverage: remaining P1 list/room/audit/profile UX, integrated FR-01–15; P2/P3 deferred.

## Design Constraints

- Existing DashboardChrome/UI kit, Tailwind, locale, real API data. Respect file/component size conventions; split table/panel/forms rather than monolithic view.
- One enrolled-student row, explicit target attempt drawer and paged history. No camera/audio feed, fictional progress %, online promises, global client search or actor/action log.
- Sources labelled security audit; manual count separately “Ghi nhận của giám thị”. Audit ascending cursor refresh/load-more, keep previous data on failed refresh.
- Flag default off until real security/integration/browser evidence; local opt-in and pilot profile remain pending user choices. Mocked browser pass cannot unlock live deployment.

## Files

Paths relative to pte-web unless labelled.

Existing:

- `apps/tenant-web/features/proctor/components/{LiveMonitoringView,AuditLogView,ProctorProfileView}.tsx`
- `apps/tenant-web/app/(dashboard)/proctor/sessions/[publicId]/page.tsx`
- `apps/tenant-web/app/(dashboard)/proctor/audit-log/[publicId]/page.tsx`
- `packages/ui/src/i18n/LocaleProvider.tsx`
- `apps/tenant-web/package.json`

Proposed:

- `apps/tenant-web/app/(dashboard)/proctor/sessions/page.tsx`
- `apps/tenant-web/features/proctor/components/{AssignedSessionsView,MonitoringStudentTable,MonitoringStudentPanel,ViolationForm,ForceSubmitDialog,MonitoringConnectionBanner}.tsx`
- `apps/tenant-web/playwright.config.ts`
- `apps/tenant-web/e2e/proctor-workspace.spec.ts`
- `apps/tenant-web/e2e/proctor-live.spec.ts` (explicit opt-in real-service credentials, secrets not committed)
- `pte-doc/plans/proctor-tenant-workspace/verification.md` and `rollout.md`

## Steps

1. Add bounded browser harness deliberately (stable @playwright/test dev dependency scoped tenant app plus explicit scripts). Current Vitest remains Node pure tests. Configure mocked smoke separately from opt-in authenticated live tests; support baseURL and dedicated PROCTOR/HOST_ADMIN test credentials through environment only. Resolve browser runtime availability before claiming execution.
2. If TDD selected prepare RED_READY UI behavioral acceptance now: list real loading/empty/error, explicit target confirmation, saved acknowledgement, audit cursor refresh and disabled controls. Fixture-backed browser RED tests are valid for this phase; they do not substitute backend integration.
3. Build assigned-list from real hooks with metadata/status/role/paging, no optional global filters. Route exact session UUID; all actual states DRAFT/PREPARING/READY/SCHEDULED/OPEN/CLOSED/CANCELLED supported. Read-only before OPEN/after CLOSED.
4. Replace LiveMonitoringView stub with snapshot summary/table, persistent selection, paged attempt history panel, lastSeenAt label and manual count. Open controls only when allowed; readonly snapshots render without creating monitoring session. Violation form enum labels/detail, explicit target; force dialog and pending status via phase04 adapter; close confirmation distinct from exam close.
5. Replace fictional audit tabs/types with real combined audit source/severity/type/time/target/detail and backend ascending cursor. Resolve names only from safe available roster/history context; otherwise show UUID fallback, never HOST_ADMIN directory. Refresh resets cursor only after successful first-page response; load-more dedupes event UUID. Keep profile and locale intact.
6. Implement initial loading/background refresh, retry/empty/ForbiddenState/stale/connection banner, keyboard form focus/restore, responsive table/panel at 320/768/1024. No success toast from a topic request broadcast; unrelated save events cannot acknowledge another request.
7. Run final module/backend suites and client tests/typecheck/lint/build. Run mocked browser smoke and separately real backend flows with two Proctors plus HOST_ADMIN revocation, wrong-tenant/attempt negatives, scheduled/closed reads, audit refresh after tail, close monitoring exam state invariant. Record actual environments/results and unexecuted checks precisely.
8. Run pilot-selected 100/1–3 or 500/5 fixture with retry/orphan/no-attempt cases; query count fixed for page25/page100, report latency/payload/query plans and per-recipient authorization cost. No SLA until measured. If any real acceptance/external prerequisite blocked, keep flag off and preserve verification diagnostics.
9. Document local opt-in/deployment-off configuration and rollback flag in rollout.md; enable only environments explicitly selected by user after all gates. No production deployment/credential changes implied by implementation scope.

## Success Criteria

- All P1 screens operate on real hooks/endpoints; no stub `[]` data or fictional audit fields. Role routing/flag-off/multi-role verified.
- Active snapshot count/page/history semantics correct; controls explicit scoped attempt, all error/reconnect/timeout states honest. Saved violation appears once after audit refresh; close never changes exam state.
- Browser keyboard and widths320/768/1024 pass; product strings localized and existing profile works.
- Scoped backend tests and live security/integration evidence recorded separately from mocks; bounded queries/measurements and flag state documented. A blocked real environment does not become a passing gate.

## Build and Test Commands

From pte-api: `.\mvnw.cmd -pl app test` (record integration profile and DB prerequisite). From pte-web declared pnpm: `pnpm.cmd --filter @pte/api-client test`; `pnpm.cmd --filter @pte/api-client typecheck`; `pnpm.cmd --filter tenant-web test`; `pnpm.cmd --filter tenant-web lint`; `pnpm.cmd --filter tenant-web exec tsc --noEmit`; `pnpm.cmd --filter tenant-web build`. After harness exists: `pnpm.cmd --filter tenant-web exec playwright test e2e/proctor-workspace.spec.ts`; live opt-in `pnpm.cmd --filter tenant-web exec playwright test e2e/proctor-live.spec.ts` with dedicated runtime services/accounts, never echoed secrets. Do not run every broad suite repeatedly after no changes.

## Quality and Testing State

- Quality: skipped_by_user. Decision: user_confirmed_skip. Profile: recorded in Preflight.
- Testing: not_started (skipped by user via --no-tests).
- Risks: external services/test identities/browser runtime, visual accessibility defects, demo versus live evidence confusion, pilot authorization fanout costs.
