# Remaining admin unhappy cases — implementation plan

Date: 2026-10-05. Mode: HARD. Test mode: default; TDD recommended, not enabled. Status: phase01 in progress; backend baseline repaired, PostgreSQL evidence/checkpoint pending. Source HEADs: pte-api f070e38, pte-web eafe3c8. User authorized ck:cook --hard and separately approved repair of the11 baseline failures/errors. Repair changes are uncommitted and documented separately; no commercialization feature implementation, commit, push or deployment yet.

## Authority and scope challenge

[implementation-spec.md](implementation-spec.md) is authoritative. Main-agent [research.md](research.md) supplies both researcher findings and adjudication; [coverage-ledger.md](coverage-ledger.md) owns case allocation. [spec.md](spec.md), [unhappy-cases.md](unhappy-cases.md), and [solutions.md](solutions.md) provide historical IDs and candidate solutions. Reject superseded suggestions for snapshots, Archive DRAFT, durable email/invitations, quota compensation, new organization enums/reserved codes, and global pending-tax uniqueness.

Exists: Plan pessimistic write locks, ACTIVE-family immutability, outstanding-code guard, referenced-draft soft Delete, and pending-modal protection already exist. `LicenseCodePersistenceService.save` rechecks ACTIVE under the Plan lock inside REQUIRES_NEW. Redeem already uses conditional `markRedeemed` in its activation transaction. Preserve these capabilities; 45 IDs do not imply 45 missing patches.

Minimum: targeted review serialization, stale-write contract, issue-intent deduplication, atomic previewed revoke, bounded admin access, truthful recovery, and regression evidence. Capacity catalog Plans and legacy capacity redemption remain valid; only new license issuance becomes EXAM-only. HARD is warranted by cross-module transactions, bearer secrets, compatibility, and seven dependent gates.

Spec quality: PASS for approved policy and testable acceptance; technical choices below require validation at implementation readiness. No additional product-policy interview is required. No new code or test has run during planning. The historical 27-test receipt and lifecycle receipts are not evidence of these implementations.

## Source-backed findings and gap review

Paths below are relative to `D:/GitHub/pte-org`. Main source anchors: `pte-api/app/src/main/java/com/pte/billing/internal/service/{TenantApplicationService,PlanService,LicenseCodeService,LicenseCodePersistenceService}.java`; `pte-api/app/src/main/java/com/pte/session/internal/{listener/SubscriptionRevokedSessionListener,service/SessionLifecycleService}.java`; `pte-web/apps/vendor-web/features/commercialization/{api.ts,components/AdminApplicationDetailView.tsx,components/PlanCatalogView.tsx,components/LicenseCodesView.tsx}`.

- Approved US-01/02/03 require committed races and >=10 repetitions. Translate these into executable lock-order scenarios, not a generic concurrency paragraph.
- Evidence requires independent fixtures, zero real secrets, no unauthorized production mutation, and persisted readback. Latency SLO is deliberately unset; use bounded page/query budgets and deterministic clocks, recording measured latency without inventing a production SLO.
- Pattern 7 contradiction: historical issue/archive gap is already addressed by inner locked eligibility. Extend that same transaction for idempotency rather than adding another lock framework.
- Pattern 7 contradiction: historical snapshot/durable-mail proposals conflict with approved DEC-01/03. Retain guards and partial email recovery.
- Semantic gap: Plan server locks serialize requests but cannot detect a stale form submitted later. Require explicit expectedVersion on existing writers.
- Semantic gap: AFTER_COMMIT session bridge is not an atomic revocation proof. BEFORE_COMMIT alone is insufficient while `changeSubscription` locks session before subscription and open lacks a locked-subscription usability check. `ExamSessionRepository.findBySubscriptionIdAndStatus` already has PESSIMISTIC_WRITE; reuse it with deterministic ordering/status reread. Inventory create/schedule/publish paths to retain existing subscription-first protection and close any uncovered writer.
- Semantic gap: legacy String-token revoke paths conflict with naive UUID overloads and leak secrets in URLs. Use a separate admin namespace and prevent legacy write bypasses.
- Semantic gap: uncertain issue must resolve to the same public resource, while secret reveal must bypass React Query and logs. Define tombstones, canonical payloads, and response/reveal separation.
- Semantic gap: reset flow exists, but `UserService.resetPassword` itself does not record an audit entry in the inspected method. Verify cross-cutting audit; add minimal identity-owned audit if absent before exposing recovery guidance.

## Phase sequence and dependencies

| Phase | Document | Stories | Depends on |
|---|---|---|---|
| 01 | [Baseline, contracts, coverage](phase-01-baseline-contract-coverage.md) | US-06 P1; contracts for US-01..05 | approved spec |
| 02 | [Applications and minimal email recovery](phase-02-applications-review-recovery.md) | US-01 P1, US-05 P2 | 01 |
| 03 | [Plan validation and stale forms](phase-03-plan-validation-version.md) | US-02 P1 | 01 |
| 04 | [Issue idempotency, redeem, expiry](phase-04-license-issue-redeem-expiry.md) | US-03 P1 | 01, 03 |
| 05 | [Preview and atomic revoke](phase-05-revoke-preview-atomic-cancellation.md) | US-03 P1 | 01, 04 |
| 06 | [Admin access and session isolation](phase-06-admin-pagination-secret-cache-isolation.md) | US-04 P2; COM P1/P2 | 02..05 |
| 07 | [Regression and handoff](phase-07-regression-handoff.md) | US-06 P1; all story exits | 01..06 |

02 and 03 may be developed independently after contract approval; shared client/type edits must be coordinated. Every later phase preserves earlier transaction and lifecycle invariants. No phase is release-ready in isolation.

### Execution checklist (phase01 in progress)

- [ ] 01 — Backend baseline repaired:0 failures/errors,26 PostgreSQL tests skipped; migration/race evidence and hard checkpoint pending. No phase02 activation.
- [ ] 02 — Atomic application review and truthful credential recovery.
- [ ] 03 — Plan validation and expectedVersion.
- [ ] 04 — Issue idempotency, redeem and expiry.
- [ ] 05 — Confirmed-scope atomic revoke.
- [ ] 06 — Admin pagination, secret and session isolation.
- [ ] 07 — Full regression, evidence reconciliation and handoff.

Each phase records test/quality choices before implementation and actual receipts afterwards. This file is the task tracker for handoff; no execution checkbox is checked by completing planning.

## Coverage allocation, not an execution ledger

Main agent owns the separate research and 45-case coverage artifacts. This plan does not create them. Assign one primary phase per ID; link secondary checks and residual scope there during cook:

| Primary phase | IDs | Disposition |
|---|---|---|
| 02 | APP-01..APP-12 (12) | targeted implementation + retained rollback guards; APP-07 Partial because durable delivery is deferred |
| 03 | PLN-01..PLN-08, PLN-11/12 (10) | validation/version changes; preservation and regression of existing lifecycle/modal work |
| 04 | LIC-02/03/04/11/12/14 (6) | idempotency/expiry/new EXAM-only issuance; preserve capacity legacy semantics; compensation Deferred |
| 05 | LIC-05/08/09/13 (4) | scope-confirmed atomic EXAM revoke; state/reason/error boundaries |
| 06 | LIC-01/10/15, COM-01..COM-06 (9) | operational access, masking, errors, auth/cache lifecycle |
| 07 | PLN-09/10, LIC-06/07 (4) | inherited guard regression and inconsistent legacy fixture verification |

Total: 45 distinct IDs, 12 APP + 12 PLN + 15 LIC + 6 COM. All current execution results remain Not run. 01 establishes ownership; 07 reconciles evidence. Implementation disposition Partial/Deferred is separate from execution Not run/Passed/Failed/Blocked.

## Chosen architecture proposals

1. Plan-only `@Version`; dedicated update and transition DTOs require nonnegative expectedVersion. Keep existing paths; missing version is 400, stale version 409. Check under existing write lock and flush before mapping the returned version. No unguarded old DTO or server-read-current-version fallback. Draft Delete retains its current idempotent guarded contract; it is not an edit/activation/archive bypass.
2. New `/api/v1/admin/license-codes` namespace supports safe issue, pagination, UUID detail, preview, revoke, reveal, and token lookup in POST body. Selected controlled cutover: old GET returns410 with refresh/update instructions after the web switches to new pages; never change its successful array shape into a page envelope. Before cutover, the authorized legacy raw array is explicitly no-store with redacted logs and LIC-15 remains Partial. Old issue delegates to mandatory-key safe issuance; old revoke fails closed with actionable409 and no token echo. No unguarded REDEEMED bypass. Log redaction for legacy token paths is required even when rejected.
3. Issue key scope `(platform user publicId, ISSUE_LICENSE_CODE, UUID key)`. Retain mapping as long as the code/audit history exists; no key cleanup in this release and no expired-key reuse. Same canonical payload returns the same publicId and safe receipt, even after code expiry/revocation; changed payload409. Failed transactions leave no successful intent. If a future separately authorized retention action deletes the code but keeps audit, keep a minimal tombstone and return410 referencing the original publicId rather than issuing again. No response-TTL cleanup job is proposed.
4. Fingerprint canonical plan UUID and nullable UTC expiry at PostgreSQL microsecond precision; distinguish null from a timestamp, reject unsupported sub-microsecond values with 400 rather than rounding expiry silently. Current authorization is checked on every replay; no raw token is stored in intent rows. Record inserted and license created in the same REQUIRES_NEW transaction. Retry only recognized unique-key collisions after that transaction has rolled back; bounded whole-transaction retry, never inside rollback-only state.
5. Resource-specific revoke preview returns effective state, subscription identity/status, tenant scope and SCHEDULED/OPEN/CLOSED recap. A server-authenticated, short-lived scope digest binds actor/resource, effective code state, subscription identity/status/tenant and sorted SCHEDULED session publicIds. Confirmation includes that digest, expected identity/state fields and explicit subscription/SCHEDULED cancellation acknowledgements. Recompute the scope under coherent locks; any changed SCHEDULED membership (including same count with different IDs), state or subscription scope returns409 and requires fresh preview/confirmation. OPEN/CLOSED are informational and preserved; their count changes alone do not invalidate consent. No generic preview-token platform or durable preview table. Reason is trimmed1..255; expired preview cannot authorize a mutation.
6. Preferred atomic bridge: synchronous public billing events with session-owned listeners/public facade; cancellation listener BEFORE_COMMIT joins the originating transaction and propagates failure. Preview contribution uses a public, transient impact-query event with a typed result collector so billing imports no session internals and session retains dependency on billing. Missing/duplicate responder fails closed. Review this small event contract against module verification before implementation; do not claim it is already available.
7. Coherent writer order: code where needed, Plan only for issuance/redeem, subscriptions sorted by publicId, sessions sorted by publicId. Session writers must never acquire a subscription after holding a session lock. Read current linkage without lock, lock needed subscriptions, lock/re-read session, and abort 409 if linkage changed. Revoke locks subscription before collecting/canceling sessions. Re-evaluate SQL predicates and flush persistence context to avoid cached stale entities after lock waits/bulk updates.

## Compatibility, migrations, rollback

Expand-first migrations after the current maximum version; preserve V77 lifecycle migration and all unrelated changes. No fixed migration number is allocated by this plan. Add only Plan version, issue-intent metadata/indexes, and page indexes justified by query plans. Do not rewrite currency/duration/family or reconstruct historical snapshots. Legacy Plan repair is manual, reviewed, and guard-aware; outstanding codes may block entitlement repair and require an operator decision rather than bypass.

Stage client support, migrate consumers, then enforce mandatory write protection in a coordinated future release. During mixed versions, protected writes fail closed with instructions to reload/update; do not retain a grace endpoint that silently accepts stale payloads. Deployment is not authorized here. If reverting UI, retain backend version/key/preview checks. Disable affected writes when old binaries cannot honor expanded schema/protections. Preserve tombstones, audit, code/subscription/session state and named volumes; repair committed business actions only through separately authorized operations.

## Quality and testing state

Cook started2026-10-05 under --hard. Phase01 blocked on fresh backend baseline:1124 tests,4 failures,7 errors,26 skipped; API-client381 tests and typecheck passed, backend incremental compile passed using Java21. No application/test source changes. Phase01 tests=yes/quality=yes, TDD not enabled; later phases unstarted. Quality approved only for phase01 reporting artifacts, not an implementation; baseline/runtime gates remain failed/incomplete. See [baseline receipt](phase-01-baseline-receipt.md); no full-suite or phase completion claim.

Current update: separate user-authorized [baseline repair](../quang-admin-baseline-repair/repair-report.md) reran the full app suite under Java21:1127 tests,1101 passed,0 failures/errors,26 skipped; targeted31 passed. The preceding paragraph is the initial run's historical evidence. Baseline failure blocker resolved; PostgreSQL migration/committed-race evidence and hard-mode human confirmation still pending. Phase01 stays unchecked, phase02..07 unstarted. Current reporting-state quality receipt lives in the repair folder because this progress update invalidates the initial reporting fingerprint; it is not production approval.

When authorized, use Java 21 and `pte-api/.\mvnw.cmd -pl app -DskipTests compile`, scoped `-Dtest=<named suites> test`, then full `-pl app test`. Web: `pnpm --filter @pte/api-client test`, `pnpm --filter @pte/api-client typecheck`, `pnpm --filter vendor-web exec tsc --noEmit`, `pnpm --filter vendor-web lint`, `pnpm --filter vendor-web build` from pte-web. Inspect package scripts/runtime afresh at cook; run tenant checks where redemption/session client contracts change.

Real isolated PostgreSQL races run >=10 times per interleaving with separate transactions, start barriers, commits, and new-transaction readback. Unit mocks and rollback-only Spring tests do not establish atomicity. Mocked browser acceptance is reported separately from authenticated local E2E; no production mutations or real secret artifacts. Capture HTTP/error code, sanitized correlation ID, database invariant and exact fault point. Quality review and final code review are separate receipts.

Historical lifecycle full regression: 11 failures reportedly also reproduced on clean HEAD `906345c`; current planning HEADs are f070e38/eafe3c8. The earlier failures are not confirmed current failures and no tests were rerun by this planner. Establish fresh baseline and compare logs in01/07. Do not relabel historical failures new bugs, waive a currently failing gate, or expand scope to fix them. Any fresh full-suite failure blocks release-ready claims even when scoped checks pass.

## Risks and validation handoff

- Retained mappings require storage sizing and future retention coordination; no cleanup in this release may enable key reuse or erase intent history while code/audit remains.
- BEFORE_COMMIT callbacks run at transaction completion: preview-check-before-write must hold the subscription lock through listener execution, and listener errors must roll back flushed billing writes. PostgreSQL fault tests are the decision evidence.
- Preview event result collection is a new public contract. Validate module direction, tenant scoping, one responder, synchronous invocation, and that expected-state/impact fields contain no secret.
- Legacy String routes may still appear in historical proxies/traces. Masking new lists alone is insufficient; validate access-log redaction and remove old client use.
- Existing reset workflow rotates credentials. Verify target binding and audit before wiring; never auto-rotate after timeout or assume SMTP delivery.
- Offset pagination has deterministic ordering but no snapshot guarantee under concurrent inserts. Test eventual locate/access and disclose this limit.
- Both independent researcher findings and policy adjudication are recorded in research.md. Independent HARD red-team review returned documentation PASS after revision; approved business policies were validated through the four answered questions. Implementation/runtime readiness remains subject to phase01 and subsequent gates.
- Independent planning review and adjudication are recorded in [design-review.md](design-review.md); that receipt is documentation evidence, not runtime or release evidence.

Validate at main-agent handoff/phase01: retained-key storage sizing; resource-specific preview contribution and acknowledged impact categories; fail-closed stale-client cutover; identity audit/exact host-target binding. These are technical review decisions with proposed defaults, not policy BLOCKs or reopened approved business policies. Do not wait for further policy answers to deliver these documents.

Resume command: `/ck:cook --hard pte-doc/projects/plans/quang-admin-commercialization-unhappy-cases/plan.md`. Add `--tdd` only after explicit consent. Continue phase01 PostgreSQL evidence and checkpoint; phase02 and later remain unstarted. Neither baseline repair approval nor this command waives remaining gates.
