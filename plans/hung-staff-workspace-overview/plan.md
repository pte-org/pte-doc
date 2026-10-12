# Plan: Tổng quan công việc Proctor và Examiner

Date: 2026-10-12 (Asia/Saigon). Mode: Fast (--fast). Status: completed (all 4 phases implemented and verified with zero compile/typecheck errors). Quality & tests skipped per user preference.

## Outcome and scope

Nâng cấp `/proctor/sessions` và `/examiner/work` trong tenant web: mỗi trang có đúng 3 thẻ tổng quan, tối đa 5 mục ưu tiên và danh sách công việc hiện hữu. Backend tính toàn bộ phân công được phép xem; frontend không tải mọi trang để đếm. Không tạo route dashboard/sidebar mới.

Nguồn: [spec](spec.md), [primary research](research-primary.md), [alternative research](research-alternative.md). Quyết định validation của user được ưu tiên: 3 thẻ mỗi role, Proctor OPEN + access window, TODAY theo thời điểm mở ca trong ngày của timezone browser.

## Phase dependencies and coverage

| Phase | Deliverable | Stories / FR | Dependency |
|---|---|---|---|
| [01](phase-01-overview-contracts-and-queries.md) | Hai API overview, aggregate/priority và list filters/readiness thống nhất | P1 actor, Proctor, Examiner; FR01–08, FR12 | None |
| [02](phase-02-api-client-and-query-cache.md) | Typed client, identity-scoped keys, invalidation | P1 actor; FR01, FR09–10, FR12 | 01 |
| [03](phase-03-proctor-overview.md) | Proctor cards, priority, lịch hôm nay đầy đủ qua phân trang | P1 Proctor, P2; FR02–04, FR09–12 | 01–02 |
| [04](phase-04-examiner-overview-and-handoff.md) | Examiner cards/progress/readiness, delivery checks | P1 Examiner, P2; FR05–12 | 01–02; delivery after 03 |

## Shared decisions

- Proctor own scope: current tenant/actor, assignment and session undeleted; require joined session tenant to match. Access count requires status OPEN and `opensAt <= asOf < closesAt`; upcoming = SCHEDULED/OPEN with future opensAt. Today = noncancelled session whose `dayStart <= opensAt < dayEnd`; ca mở hôm qua không nằm trong TODAY dù vẫn đang diễn ra. Cards overlap. READY is not silently treated as SCHEDULED/OPEN. Null times do not qualify for temporal buckets.
- Validated timezone: browser IANA timezone resolved with `Intl.DateTimeFormat().resolvedOptions().timeZone`; send it in overview and date-filter requests, validate backend ZoneId with controlled400, include timezone in cache keys and response. SSR waits for client timezone resolution; injected UTC Clock supplies one asOf per request.
- Examiner scope `ASSIGNED_UNPUBLISHED`: current active Examiner's undeleted own assignments and no publication. Counts use existing status formula: eligible=0 → COMPLETED; positive eligible/no committed score → PENDING; positive submitted below eligible → IN_PROGRESS; otherwise COMPLETED. Completed is current unpublished assignment progress, not history or proof that a person reviewed zero-answer work.
- Examiner readiness and progress are separate axes. Preserve exact cohort/member rules from detail. `canFinalize` denotes policy permission; `hasOutstandingAnswers` denotes actual remaining eligible work. Priority requires both, excludes eligible=0 and completed rows. No AI readiness predicate.
- Current queue score subqueries omit score-owner/deleted checks. Phase01 shares existing queue score semantics across queue SELECT/filter/count, summary and priority; it may not quietly tighten summary alone. Scope is enforced on assignment owner/tenant; grouped scores remain bound to that exact tenant/session/attempt. Immutable ownership/schema assumptions must be checked. Any legacy score-owner/deletion anomaly is documented as a separate issue, not silently repaired or used to introduce a new scoring policy in this feature.
- Overview and list are independent reads; transient concurrent differences are allowed. `asOf` is observation time, not a historical snapshot promise. Server detail/write checks remain authoritative.
- No schema changes by default. Bounded query count, no N+1 detail/media reads, no automatic monitoring/session opening and no extra subscriptions/polling.

## Quality and Testing State

- Quality: not evaluated. Prior user preference to skip quality runs is retained; no ck:quality execution is scheduled.
- Testing: not started. Prior user preference to skip tests/E2E is retained; acceptance cases are documented, not tests to create/run automatically.
- Compile/typecheck: planned after implementation, not executed in this planning task. Backend compile with tests skipped; API-client and tenant-web TypeScript checks. No startup, SQL runtime or security behavior claim based on compile alone.
- TDD remains optional if the user later changes the check choice. Do not ask again for already declined optional test/quality checks.

## Risks and implementation readiness

1. Browser timezone validated by user; handle unavailable/invalid timezone explicitly instead of silently falling back to host timezone.
2. User confirmed “Đã chốt” counts unpublished assigned work, including legacy eligible=0 COMPLETED with explanatory text. Published history is out of scope.
3. Record score ownership/deletion anomalies if source inspection identifies them; preserve current queue read semantics throughout this feature. No speculative migration or production audit query is executed during planning.
4. Current Proctor list lacks URL filters and current Examiner queue uses hardcoded English text; localized work must remain within touched surfaces.
5. Aggregate correctness and Spring/query startup require runtime checks if later authorized. Compilation alone cannot establish those facts. No performance SLA is promised without measurements.

## Delivery boundaries

No deployment, flag activation, default login routing change, host publication change, grading receipt/version change, draft persistence, or SQL index migration unless separately justified/authorized. Keep Proctor feature flag state unchanged. Rollback consists of reverting overview UI/client/controller reads; existing task routes stay usable. Plan execution state is tracked in phase checklists.

## Plan review adjudication

[Review](plan-review.md): no BLOCK/HIGH; two MEDIUM clarifications accepted and incorporated.

- PR01 ACCEPTED: Phase01 fixes additive Proctor list payload data/meta/asOf/timezone/day bounds, preserves legacy ALL and keeps list rendering independent of overview failure.
- PR02 ACCEPTED: Phase02/03 add browser-zone re-resolution on focus and one foreground midnight-boundary invalidation (not polling); hidden tabs defer to focus.
- Product validation: browser IANA timezone, TODAY by opensAt local start date, Examiner completed own unpublished work. No remaining product clarification.
- Spec quality: PASS after alignment; numbered requirements, prioritized stories, measurable acceptance and scope boundaries present. All phase implementation checklists remain unchecked.

Hand off with:

```text
$ck:cook --hard D:/GitHub/PTE-org/pte-doc/plans/staff-workspace-overview/plan.md
```

The plan-only request does not start implementation.
