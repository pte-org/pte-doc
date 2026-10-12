# Direct plan review and adjudication

Date:2026-10-12. Reviewer: root. Independent agent review unavailable because workspace credits exhausted. This is a direct design review, not an independent quality/test receipt.

Verdict: ready for handoff after the following accepted clarifications. No implementation verified.

- PR01 ACCEPTED — actual unenroll path lacks session mutex. Phase02 aligns it and assignment mutations with close/unassign locks while preserving delete behavior; transaction rechecks after lock.
- PR02 ACCEPTED — pathname-only nav cannot select query entries. Phase03 shares one query-aware winner across sidebar/breadcrumb and preserves Host Classes overrides.
- PR03 ACCEPTED — missing-row version0 vs first saved version0 causes ABA. Plan fixes first write1, monotonic reset/version and enrollment UUID validation; no delete/reset or read repair.
- PR04 ACCEPTED — receipts/audit cannot be mutable-current fields only. Two tables with immutable command log, changed=false no-op receipt, strict raw-intent fingerprints and original receipt vs current snapshot avoid duplicates/false replay.
- PR05 ACCEPTED — full roster name/email search must occur before pagination without Session→Attempt/Proctoring cycles. Phase01 declares Identity-owned safe read view; Proctoring activity/display enriches returned page only.
- PR06 ACCEPTED — product validation overrides research's unrestricted SCHEDULED preflight. Proctor earliest opensAt-30minutes; reason optional for initial absence; reset permitted with reason/history. Host CLOSED only correction authority retained.
- PR07 NOTED — query/runtime/concurrency behavior unverified under compile-only preference. Acceptance cases remain mandatory product behavior, not claims of tests passing. Historical missing attendance stays UNMARKED, not inferred ABSENT.

Every phase includes Design Constraints and Quality and Testing State; implementation tasks are pending. No rollout, start gate, grade changes or automatic SQL repair included.
