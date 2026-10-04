# Gap analysis and planning adjudication

Date: 2026-10-03. Research inputs: primary backend and alternative frontend source reviews supplied in parent context, plus current spec, brainstorm and manifests. No implementation/testing claims.

## Scanner adjudication

| Finding | Disposition | Evidence / plan action |
| --- | --- | --- |
| P2 coordination: recovery/tests/exit unspecified | Accepted as planning-detail gap | Every phase now assigns owner, prerequisites, recovery cases, test list and measurable exit |
| P2 coordination: arrivals/keyset or stable paging | Accepted | Choose anchored page-number history and a recipient serialization watermark, not unspecified alternatives |
| P2 no concurrency found | Rejected as blanket claim | Spec FR-04/11/12/20 and recovery NFR explicitly cover races; this plan adds exact locks, leases and tests |
| Earlier permission/NFR absence | Rejected | FR-14 and measurable NFR exist; broaden contract detail rather than duplicate requirements |

## Semantic and contradiction checks

1. AFTER_COMMIT reliability versus durable delivery: accepted. Originating business transaction persists intent; after-commit callbacks may wake the worker but are not authoritative.
2. Null admin tenant versus self-only inbox: accepted. Query by recipient and null-safe tenant equality; role alone never grants cross-admin visibility.
3. Existing email logs versus personal inbox: accepted. Separate APIs/tables and independent read state.
4. Publication <=1 second versus atomic recipient snapshot: accepted as benchmark risk. Include full snapshot/intents in measured transaction; no misleading job-only latency.
5. Mark-all timestamp versus late commits: accepted. Timestamp/sequence IDs alone cannot distinguish a delayed committing insert. Per-recipient delivery/read-all serialization and committed watermark are required.
6. Grading complete versus selected-source publish-ready: accepted. Freeze required-lane policy, use full pinned inventory; publication remains independent.
7. CLOSED versus outstanding attempts: accepted. Add HOST_ADMIN cohort preview/finalize; all submitted papers included, outstanding attempts explicitly excluded with reasons/audit for this cohort only. No impossible post-CLOSED force-submit or attempt-status mutation.
8. Required AI versus optional comparison: accepted. Optional AI failure does not block submitted human work; required REAL AI cannot be satisfied by stub output.
9. Subscription REQUIRES_NEW versus commercial atomicity: accepted prerequisite. Narrow transaction repair and rollback/replay tests before success intents.
10. Exact-order fallback/inactive subscription lookup: accepted. Tenant-owned exact detail APIs and explicit missing state; never open unrelated order.
11. Shared admin shell includes PLATFORM_AUTHOR: accepted. Exact admin roles on management/inbox; no inherited broad admin constant.
12. Reminder window versus reschedule/cancellation: accepted. Revalidate under owning session lock at delivery, dedupe by schedule identity.
13. Broadcast frozen audience versus recipient deactivation: accepted. Snapshot preserved; invalid recipients suppressed at delivery, never replaced.
14. Audit logging versus user content: accepted. Record identifiers/actions, not duplicated plaintext sensitive content.

## Alternatives considered

- SSE/WebSocket versus 30-second polling: polling selected for P1. Realtime adds auth reconnect/replay/connection maintenance and still needs persisted inbox.
- Copied announcement body per recipient versus shared immutable content: shared content selected; recipient records own read state and delivery.
- RabbitMQ-dependent inbox dispatch versus database intent worker: database worker selected; no dual-write atomicity requirement or generic outbox rewrite.
- OPEN versioned cohorts versus CLOSED finalized cohort: CLOSED/frozen cohort confirmed on 2026-10-03. Reasoned outstanding cohort-only disposition is the proposed runnable engineering mechanism, not a separately user-approved exclusion policy.
- Scoring callbacks only versus event-triggered evaluator plus reconciliation: reconciliation required for replay/restart/missed wake-up recovery.

## Source anchors

Backend: shared/domain/BaseEntity.java; shared/web/ApiResponse.java; shared/exception/DomainException.java; notification/internal/service/NotificationDispatchService.java; billing/internal/service/SubscriptionPersistenceService.java; PayOsWebhookService.java; OrderPersistenceService.java; session/internal/service/SessionLifecycleService.java; scoring/internal/service/ScorePublicationLockService.java; reporting/internal/service/ReportPublishService.java.

Frontend: pte-web/packages/ui/src/components/index.ts; packages/api-client/src/client/index.ts; apps/tenant-web/features/commercialization/components/PaymentStatusView.tsx; both apps/features/auth/components/DashboardChrome.tsx; apps/vendor-web/features/auth/constants.ts; both apps/lib/navigation.tsx.

## Confirmed product validation

User confirmed 15-minute reminder, CLOSED frozen cohort and manual-workflow required examiner lanes on 2026-10-03. Optional AI comparison does not block; AI-only requires valid REAL result. Scheduling stays P2. No force-submit, source selection or auto-publication is authorized.

All feature test/quality states remain not started/not evaluated. No unresolved scanner finding is being disguised as a passed runtime check.
