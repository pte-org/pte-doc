# Plan: Proctor tenant workspace

> Current scope, 2026-10-12: **PLAN ONLY**. Do not activate implementation agents, edit source, run checks or execute ck:cook automatically. Earlier implementation wording is superseded by the user's explicit clarification. Existing user code and completed work remain untouched; this document describes proposed future work.

## Current functional phase mapping

| Phase | Proposed work | Existing plan inputs |
|---|---|---|
| 1 — Sidebar & Overview | Separate overview from monitoring list; role-aware sidebar/card parity, real counts, loading/error/retry and stable query navigation | Client/role routing and screens phases; staff overview and attendance-sidebar plans |
| 2 — Monitoring | Assigned sessions, student status and connection state, existing STOMP realtime, authoritative snapshots and student attempt detail | Public projections, scoped APIs/security and room transport phases |
| 3 — Attendance | Current roster, manual presence/absence; proposed LATE and explicit manual identity verification, backend permissions/versioning/receipts and change history | proctor-attendance-sidebar plan; new status/identity contracts require additive migration in future implementation |
| 4 — Incidents & Audit | Existing classified immutable violation logs and scoped audit; proposed separate OPEN/RESOLVED follow-up state with Host resolution, preserving original log | Scoped API/security and screen phases; no unsupported automatic escalation |
| 5 — UI/UX | Shared design system, responsive views, real search/filter/pagination, confirmations/toasts, skeleton/empty/error and authoritative state | Existing screen/client phases |

These are functional planning groups mapped onto the existing technical phase files; no new analysis document or source implementation is required by this task. No testing/quality phase is selected. Feature rollout remains off under the prior decision. Attendance remains informational and does not change exam-start eligibility; Host post-close correction still requires a reason and history.

Date: originally 2026-10-11, scope clarified 2026-10-12. Status: planning only for the functional scope above. Existing user implementation is preserved; no assistant source changes are retained.

## Scope Challenge

- Exists: disabled Proctor routes/profile and stub monitoring/audit views; REST projections and safe transport authorization are incomplete.
- Minimum: approved P1 only, three bounded read endpoints, existing STOMP controls, localized assigned-list/monitoring/history/audit screens, additive role routing.
- Complexity: **Hard** planning, because this spans two repositories, module boundaries, authorization races and token lifecycle.
- Tests: **default**, not TDD yet. Recommend `--tdd` because spec acceptance criteria provide behavioral anchors. No optional test/quality consent has been inferred.
- Spec Quality Check: **PASS** after role/attempt/correlation clarifications captured in spec and research. No `[NEEDS CLARIFICATION]` remains. Rollout/check/profile choices below affect execution, not approved P1 scope.

## Inputs

- [Approved spec](spec.md)
- [Primary research](research-primary.md)
- [Alternative research](research-alternative.md)
- [Brainstorm report](../reports/261011-proctor-tenant-workspace-brainstorm.md)

Repo paths below are relative to `D:/GitHub/PTE-org/pte-api` or `D:/GitHub/PTE-org/pte-web`, explicitly labelled in phases. Documents live here in `pte-doc`, not application source roots.

## Architecture Decisions

1. Session owns assignment/enrollment/metadata; Attempt owns latest attempt/history/heartbeat; Identity owns minimal display names and current PROCTOR membership; Proctoring coordinates. Public facades/exported records only. No other-module `internal` imports, entity traversal, answer/score projection or HOST_ADMIN directory access.
2. All lists use page 0, size 25, cap 100, stable ordering; reject invalid paging using current error convention. MVP omits optional global name/status/search controls. Prototype search is demonstrative only. No filtering an enriched page while claiming global totals.
3. Latest means highest immutable `attemptNumber`, tenant/session/student, nondeleted. One enrollment row with nullable latest attempt and attemptCount; history is separately paged. Whole-session counts count enrolled students by their latest attempt; no-attempt rows count only as registered/no-attempt. `manualViolationCount` counts nondeleted Proctor violation records for that explicit attempt, not lockdown events.
4. **Explicit exported SQL read boundary:** add a Session-owned Flyway view `session_monitoring_enrollment_membership` with tenantId, examSessionPublicId, studentPublicId for current nondeleted enrollments in nondeleted sessions, requiring enrollment tenantId = session tenantId. View reads owner-only Session tables; Attempt queries join only this documented membership projection, never raw Session tables/internal entities/repositories. This is a narrow deliberate SQL export: required to exclude legacy orphan/removed enrollment attempts without loading every student ID or attempt history. Session owns view evolution; Attempt consumes it read-only. Map physical columns after inspecting current migrations. Add contract/integration tests and document this export beside the Java facade. Freeze of manual enrollment after OPEN is a useful invariant, not a substitute for correct scheduled/history counts. Duplicate active membership or latest-number ties are integrity failures; preflight reports them and blocks rollout. Historical orphan attempts are excluded, reported, and never silently counted.
5. Monitoring coordinator uses a read-only **REPEATABLE_READ** transaction for metadata/page/count/latest aggregates, so each snapshot is internally coherent despite concurrent submit/enrollment updates. Return `snapshotAt` plus full-session counts and page totals. Shared datasource is current architecture; if modules split later, replace this explicit read export/transaction boundary deliberately.
6. REST snapshot every 5 seconds is authoritative, paused hidden. Topic events only invalidate snapshots. Audit is explicit refresh/load-more, ascending server cursor; it is not a tail feed. FORCE_SUBMIT confirms only from actual SUBMITTED snapshot, timeout 10 seconds; private command receipt is not proof of current attempt state.
7. Exact inbound allowlist below plus recipient-specific `clientOutboundChannel` **ExecutorChannelInterceptor.beforeHandle**, keyed by authenticated `simpSessionId` registry. Fresh role/tenant/assignment and token-expiry checks; no positive authorization cache. **Linearization is the database snapshot of the recipient authorization read immediately before the handler**, with an independent READ_COMMITTED transaction and no reuse of the monitoring REPEATABLE_READ transaction. A delivery whose authorization read begins after revocation commits is denied. A dispatch authorized before commit is already in flight and may finish afterward, even if the handler has not written bytes yet. Do not hold a DB lock across network writes or claim atomic check-and-send. Test pauses both before and after authorization. This is an explicit technical interpretation of revocation, not a retroactive confidentiality promise.
8. Mutation lock order: **Session row → owned ProctorSession row (when needed) → target ExamAttempt row**. Assignment removal locks the same Session row. Open/resume, command and flag authorize within the locked transaction; target validation/mutation stay in one scoped Attempt operation. Student/timer submit paths must retain compatible ordering; review touched force-submit path specifically. Violation append serializes chain sequence on locked ProctorSession. Publish success/broadcast only after commit.
9. Preserve legacy topic command/violation DTOs and `/user/queue/errors` `{status,code}`. New clients send optional native `requestId` UUID header. Add `/user/queue/proctor-results` and `/user/queue/proctor-errors`, **originating socket only**, never all sockets for principal. Success `{requestId,operation,targetPublicId,outcome,eventPublicId?,occurredAt}`: operations OPEN/FORCE_SUBMIT/FLAG_VIOLATION; outcomes OPENED/APPLIED/NO_OP/SAVED. Error `{requestId,operation,targetPublicId,status,code}`. Open keeps existing `/user/queue/proctor-session` DTO and carries requestId in native reply header for clients that supplied it. New error/result endpoints require current owned connection, but denial responses do not require a surviving assignment. Missing requestId retains legacy behavior. Malformed header rejects safely; transport-level failures terminate pending via ERROR/disconnect rather than assuming controller exception handlers run.
10. WS adapter is feature-owned using stable `@stomp/stompjs`, plain `/ws`, Authorization at CONNECT, no SockJS. Use shared HTTP refresh single-flight and separate token-update notifications; do not create a second token store. Reconnect 1/2/4/8/16/30 seconds, get current token in beforeConnect, resubscribe queues before open, never replay mutations. Identity change invalidates old async generations; token-only update does not clear query data.
11. Actual administrator role is **HOST_ADMIN**. Add role resolver without changing existing combinations lacking PROCTOR. With PROCTOR plus existing valid workspace preserve default and expose allowed workspace links. PROCTOR-only routes to list when enabled; flag-off shows workspace-unavailable, never a login/404 loop. Default flag remains off until gates pass.
12. Keep actual tenant app paths `apps/tenant-web/app`, `features`, `lib`, no `src` root. Read local Next guides at `apps/tenant-web/node_modules/next/dist/docs` before coding. All product copy uses `packages/ui/src/i18n/LocaleProvider.tsx`; reusable UI uses exported ToastProvider/useToast rather than fictional Toast export.

## Inbound STOMP Contract

All actor/session/subscription identity comes from server-generated transport metadata and the authenticated registry. Native client headers never populate trusted `simp*`, Principal/user, session or subscription ownership fields; reject spoofed native `simp*`, `user`, `sessionId`/`simpSessionId` and foreign user selectors. Validate destination as one canonical exact string, never wildcard, encoded slash, prefix match or duplicate header. UUID path segments use canonical UUID parsing. Bound application headers; optional `requestId` is exactly one UUID of 36 characters, duplicates/malformed values reject safely. CONNECT requires one Authorization Bearer header; do not accept a token update via SEND. Standard STOMP `accept-version`, `heart-beat`, `host`, `id`, `destination`, `ack`, `receipt`, `content-type`/`content-length` remain protocol headers validated for their command, never identity.

| Command | Exact logical destination | Authorization |
| --- | --- | --- |
| CONNECT | none | Validate JWT/expiry/current identity, derive CurrentUser and trusted transport session ID, initialize registry. |
| SEND | `/app/sessions/{examSessionId}/open` | Current PROCTOR/tenant + assignment + OPEN window. |
| SEND | `/app/proctor-sessions/{monitoringId}/commands` | Current PROCTOR/tenant, owned ACTIVE session, current assignment/window and exact target session. |
| SEND | `/app/proctor-sessions/{monitoringId}/violations` | Same owned/current scope plus valid target/category. |
| SUBSCRIBE | `/topic/proctor-sessions/{examSessionId}` | Current PROCTOR/tenant + assigned read scope; exact UUID. |
| SUBSCRIBE | `/user/queue/proctor-session` | Own authenticated connection only. |
| SUBSCRIBE | `/user/queue/errors` | Own authenticated connection only; legacy payload retained. |
| SUBSCRIBE | `/user/queue/proctor-results` | Own authenticated connection only. |
| SUBSCRIBE | `/user/queue/proctor-errors` | Own authenticated connection only. |
| UNSUBSCRIBE | none; one registered subscription `id` | ID owned by same trusted transport session; remove registry subscription. |
| DISCONNECT | none | Cleanup same server transport session; cleanup idempotent even expired. |
| Heartbeat | no application destination/body | Transport liveness only for known session; expired connection terminates. |

Every other destination/command is rejected, including direct broker SEND, foreign `/user/{id}/...`, wildcard subscriptions, client MESSAGE/CONNECTED/ERROR, BEGIN/COMMIT/ABORT and unsupported ACK/NACK (new client uses auto ack). Duplicate identity/destination/requestId headers fail closed. Outbound recipient is resolved by trusted simpSessionId + subscription ID mapped to the registered logical destination, including broker-resolved user queue names; never by message producer Principal or a native header. Transport-level rejections use sanitized ERROR/disconnect; they must end pending operations without automatic replay. Private diagnostic denial can reach the same valid connection without surviving assignment, but contains no roster data or tokens.

## Progress and Dependencies

TodoWrite is unavailable in this environment; these checkboxes are the durable task hydration. Update phase state first, then master progress, after build and chosen checks.

- [x] [Phase 01 — Public projections and query contracts](phase-01-public-projections.md) — P1 list/roster foundation, FR-02/03/04. Dependency: none. [quality: skipped_by_user; decision: user_confirmed_skip]
- [x] [Phase 02 — Scoped REST and safe control transport](phase-02-scoped-api-and-security.md) — P1 read/control/audit/close, FR-02–11. Dependency: 01. [quality: skipped_by_user; decision: user_confirmed_skip]
- [x] [Phase 03 — Shared client and role routing](phase-03-client-and-role-routing.md) — P1 access, FR-01/04/14/15. Dependency: 02. [quality: skipped_by_user; decision: user_confirmed_skip]
- [x] [Phase 04 — Room lifecycle and reliable operations](phase-04-room-transport.md) — P1 controls, FR-05–09/11–13. Dependency: 03. [quality: skipped_by_user; decision: user_confirmed_skip]
- [x] [Phase 05 — Product screens and verified rollout](phase-05-screens-and-rollout.md) — remaining P1 UI/acceptance, FR-01–15. Dependency: 04. [quality: skipped_by_user; decision: user_confirmed_skip]

Every phase changes behavior and can own RED tests if TDD is selected; there is no verification-only phase pretending to produce RED_READY. P2 durable actor/command journal and all P3 streaming/AI/chat remain deferred.

## Coverage and Validation

| Acceptance area | Phase | Evidence required |
| --- | --- | --- |
| Assigned-only/tenant reads, latest/no-attempt/history/correct aggregate | 01–02 | Facade/repository/PostgreSQL fixtures, REST contract/scope tests, bounded query count |
| Revoke/resume/target/ownership/legacy reads and fanout confidentiality | 02 | Negative policy cases, real executor revoke-before-dispatch and transaction races |
| Role matrix, flag-off availability, request paths | 03 | Pure resolver matrix, shared request contract tests |
| Correlation, no replay, token race, disposal, SUBMITTED confirmation | 04 | Controlled transport/clock tests, HTTP+WS refresh race |
| Real UI, keyboard/mobile, audit refresh, close semantics | 05 | Browser smoke plus distinct real backend authenticated integration evidence |

Build gates always apply. Optional unit creation/runs and quality gates are resolved by user check flags; security/integration acceptance remains a rollout requirement even if optional per-phase unit checks are declined. Never mark a skipped check approved.

## Tooling Preflight and Commands

- Java 21 and `mvnw.cmd` exist; `mvn` is absent. From pte-api: `.\mvnw.cmd -pl app -DskipTests compile`; targeted `.\mvnw.cmd -pl app '-Dtest=<actual phase classes>' test`; final `.\mvnw.cmd -pl app test`. If adding `-am` to selected tests also use `-Dsurefire.failIfNoSpecifiedTests=false`.
- Root pte-web declares `pnpm@11.8.0`; installed global pnpm is 12.4.1. Prefer Corepack using manifest-pinned pnpm, fallback `npx.cmd --yes pnpm@11.8.0 --version`, then use that version for dependency mutation/checks. Do not rewrite packageManager/lockfile or upgrade global pnpm to match tooling. Below `pnpm.cmd` means the resolved declared-version runner; record exact invocation used.
- From pte-web: `pnpm.cmd --filter @pte/api-client test`; `pnpm.cmd --filter @pte/api-client typecheck`; `pnpm.cmd --filter tenant-web test`; `pnpm.cmd --filter tenant-web lint`; `pnpm.cmd --filter tenant-web exec tsc --noEmit`; `pnpm.cmd --filter tenant-web build`. Shared UI build/typecheck script must be inspected before selecting the exact command.
- Tenant Vitest currently runs Node `features/**/*.test.ts`; DOM/browser infrastructure is absent. Add bounded browser harness in phase 05, without replacing current pure tests. PostgreSQL concurrency/native query tests need an actual PostgreSQL fixture; H2 create-drop with Flyway off is not equivalent. Reuse `app/src/test/java/com/pte/identity/internal/migration/PlatformRoleMigrationPostgresIntegrationTest.java` opt-in system-property/dedicated localhost allowlist/unique schema Flyway pattern and billing `LicenseIssuePostgresIntegrationTest.java` explicit transaction concurrency convention. New tests opt in with `-Dpte.proctor.postgres.integration=true`; add safe dedicated localhost test URL/property using those existing conventions, never a production datasource. Cleanup only schema created by that test. Skipped opt-in tests are not migration/race evidence. Docker daemon is available if a temporary isolated test PostgreSQL is needed; no Testcontainers dependency by default.
- Python is currently an unavailable Windows alias. Before any skill receipt/validator hook resolve real interpreter (`py` or installed executable) and use that path; do not assume `python` succeeded. Markdown input does not require JSON bundle validation, but selected test/quality skill receipt gates must be honored.

## Recorded choices for this task

1. Scope: plan only; do not execute source implementation or ck:cook automatically.
2. Checks: no tests, test files, lint, typecheck, build or quality audit for this task. Historical verification commands elsewhere in this plan are reference material, not authorized actions.
3. Rollout: retain the prior choice to keep every environment off; no deployment or database migration execution.
4. Prior pilot sizing: 100 enrolled students / 1–3 Proctors remains a future reference, not a load check to execute now.

## Risks

- Exported membership view is intentional DB read coupling; review its narrow contract, migration portability and future compatibility. Do not replace it with hidden all-ID scans or unreviewed cross-module joins.
- Assignment revocation/command races and delayed outbound dispatch require actual concurrent tests, not mocked preliminary checks. Positive-cache optimizations are deferred.
- Token refresh rotates credentials; two independent HTTP/WS refresh paths or stale generation writes can invalidate a user's session.
- Need real DB/JWKS/services and authorized test accounts for live end-to-end evidence. If unavailable, report blocker explicitly and keep default flag off; mocked smoke is never labelled live integration.
- Browser runtime/package downloads, declared pnpm and Python receipt interpreter may need setup; resolve without destructive global changes.
- Counts/query costs measured before pilot; add indexes only after EXPLAIN warrants them, in a fresh migration with next available version.

## Red-Team Adjudication

- **ACCEPTED / resolved — HIGH:** recipient authorization linearization and in-flight delivery exception aligned in master/spec/phase02; tests cover both sides of the authorization boundary.
- **ACCEPTED / resolved — HIGH:** exact inbound destination table, trusted server transport identity, native header spoofing/duplication rejection and protocol cleanup rules recorded.
- **ACCEPTED / resolved — MEDIUM:** phase04 now includes api-client client.ts/client.test.ts and an additive same-instance refresh seam covering request/upload/download retries.
- Focused re-review: **PASS**, [review](plan-review.md). This verifies plan coherence, not implemented behavior or passing application tests.

## Execution Handoff

After the three validation choices, copy explicit selected flags. Recommended Standard Cook command (conditional on user choosing TDD/tests/quality):

```text
/ck:cook --tdd --tests --quality --checks-all-phases --plan D:/GitHub/PTE-org/pte-doc/plans/proctor-tenant-workspace/plan.md
```

Planning Hard is independent of Cook Standard. Standard with explicit all-phase check flags auto-continues, matching authorization to implement after planning; Cook `--hard` would impose repeated human checkpoint confirmations. If TDD is declined omit `--tdd`; if checks differ use the matching explicit flags. Resolve flags before phase activation, do not ask to approve scope again.

## Session Notes

- 2026-10-11: approved design; Hard research, 5-phase plan and red-team review completed. All three findings accepted and resolved; focused review PASS. Static checks verified 5 phase state/constraint sections and local document links. API/web source working trees remain clean. Implementation, tests and quality remain not started/not evaluated; three execution validation choices pending.
