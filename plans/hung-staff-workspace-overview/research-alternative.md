# Alternative research: staff workspace overview

Date: 2026-10-12 (Asia/Saigon)
Scope: read-only research of the existing Proctor assignments and Examiner queue. No production source edits or tests performed.

## Recommendation

Upgrade `/proctor/sessions` and `/examiner/work` in place. Add a small server-computed overview above the existing work list, with card clicks selecting useful list filters. Do not create another dashboard route, another navigation item, a cross-tenant reporting service, or a materialized analytics subsystem.

Use separate progress and readiness dimensions for Examiner. A pending attempt is not necessarily allowed to finalize; AI readiness is not the permission to mark manually. Preserve detail/submit authorization as the authority, even when the overview suggests a next action.

## Evidence from current code

| Location | Observed behavior | Consequence for this feature |
|---|---|---|
| `pte-api/app/src/main/java/com/pte/session/internal/controller/ProctorAssignmentQueryController.java` | `GET /api/v1/proctor-assignments/mine`, role PROCTOR, tenant and actor taken from `CurrentUserContext` | Extend this owner-derived read surface; never accept arbitrary proctor or tenant IDs for the overview. |
| `pte-api/app/src/main/java/com/pte/session/internal/repository/ProctorAssignmentRepository.java:23` | Active assignments/session rows scoped by actor and tenant, page + independent count | Overview must use the same ownership/deletion predicate over all assignments. |
| `pte-api/app/src/main/java/com/pte/session/internal/service/ProctorMonitoringQueryService.java:67` | Existing list sorted `session.opensAt ASC`, then public ID | Historical sessions can precede today's open sessions. Priority order must be applied in the database before pagination, not by sorting the current page in React. |
| `pte-web/apps/tenant-web/features/proctor/components/AssignedSessionsView.tsx` | Table and pagination, page size 20, OPEN enables primary monitoring action | Retain table as the work list; summary cards and filters are a focused extension. |
| `pte-api/app/src/main/java/com/pte/scoring/internal/repository/ExaminerWorkQueueRepository.java:37` | Attempt progress derives from saved score count vs immutable assigned eligible answer count; zero eligible answers is COMPLETED | Count attempts, not answers. A zero-answer row must not become a false actionable “ready to mark” row. |
| `ExaminerWorkQueueRepository.java:56` | Published sessions excluded, assignment deleted rows excluded | MVP totals should be described as current unpublished work, not lifetime completed work. Keep published-history expansion out of this change. |
| `ExaminerWorkQueueRepository.java:79` | Queue sorted newest assignment first; no cohort/freeze/member predicate in queue query | An actionable priority list needs a readiness projection and database ordering. PENDING alone cannot select “next ready attempt.” |
| `pte-api/app/src/main/java/com/pte/scoring/internal/service/ExaminerScoringService.java:214` | Finalization requires unpublished, MANUAL_EXAMINER cohort, FROZEN/COMPLETED cohort, included membership | Reuse this rule in queue/overview projection rather than inventing a freeze flag from AI state. Detail and submit continue to recheck it. |
| `pte-api/app/src/main/java/com/pte/scoring/internal/service/StaffScoringQueryService.java` | Host/staff progress scans bounded batches and canonical pinned eligibility, including published work | Useful semantic reference, but invoking its full session/answer scan on every personal overview request is heavier and not equivalent to the existing Examiner queue. |
| `pte-web/apps/tenant-web/features/examiner/ExaminerQueueView.tsx` | Status/page stored in URL; navigate to attempt route with return status/page | Overview actions should preserve this routing pattern. Server-known IN_PROGRESS means saved scores, not an unsaved browser draft. |
| `pte-web/apps/tenant-web/features/examiner/api.ts` | Queue cache keyed tenant/status/page; score success invalidates queue prefix | Add overview key with tenant + actor and invalidate it on successful score submission. Do not derive cards from `queue.data.items`. |

## Minimal card semantics

### Proctor

Three cards are sufficient:

1. **Đang diễn ra**: owned session status OPEN, regardless of today's date. Do not infer OPEN from the clock; session workflow state remains authoritative.
2. **Sắp tới**: owned SCHEDULED session with `opensAt > asOf`; exclude CANCELLED/CLOSED. If showing READY as upcoming is desired, make that an explicit product decision, not a hidden alias.
3. **Lịch hôm nay**: owned noncancelled sessions whose `opensAt` falls inside today's half-open date interval in the agreed display timezone. A CLOSED session can remain on today's personal schedule; exclude DRAFT/PREPARING from the operational schedule.

Cards can overlap: an OPEN session that starts today belongs to both OPEN and today. Explain this through labels; do not claim a sum equals total assignments. Null/invalid opensAt cannot belong to a date bucket, but OPEN can still be counted by status.

Default list order: OPEN first; then future SCHEDULED by nearest opensAt; then remaining rows with stable public ID tie-break. Filtering and priority apply before pagination. Keep history reachable through an explicit all/history filter.

### Examiner

Four cards:

1. **Cần chấm**: positive-eligible PENDING attempts under existing unpublished/owner scope, with actionable readiness visible on each row.
2. **Đang chấm**: IN_PROGRESS attempts under the same scope; this means at least one committed decision, not a draft.
3. **Đã chốt**: COMPLETED attempts in current unpublished work. Include zero-eligible behavior only if clearly documented; safest label is “Hoàn tất theo phân công” rather than claiming human-reviewed work when no subjective answers existed.
4. **Chờ Host chốt danh sách**: unfinished positive-eligible attempts blocked specifically by absent/nonfrozen cohort. This is a subset of progress cards, not another additive progress bucket.

Each queue row gains `canFinalize` and a typed `blockingReason` matching existing detail semantics. Excluded cohort member and nonmanual mode need distinct labels; neither should be mislabelled “waiting for freeze.” AI NOT_AVAILABLE/PENDING/FAILED is a reference state and must not block manual grading when finalization eligibility holds.

Priority: actionable IN_PROGRESS first, actionable PENDING second, blocked unfinished work third, completed last. Use stable assignedAt/public ID order inside a bucket. Never auto-open a random attempt or change a draft/uncertain submission through overview navigation.

## Implementation alternatives

| Choice | Advantage | Cost / concern | Decision |
|---|---|---|---|
| Count all items in React by fetching every page | Small backend change | Unbounded requests, stale/inconsistent pages, wasted answer data, pagination totals do not express readiness | Reject. |
| Fetch three status lists merely to use each `totalItems` | Reuses current API | Multiple count queries per load; no freeze/readiness breakdown; Proctor API has no corresponding filters | Reject as primary design. |
| Add overview to every paginated list response | Overview/list delivered together | Expensive aggregates repeated on each page/filter change; couples independent refresh states | Reasonable alternative when strict per-response consistency is required, but not necessary for MVP. |
| Separate role-specific overview endpoints + shared read predicate | Lightweight, summary cached independently, minimal DTO churn | Two requests can observe small concurrent differences | Recommended. Include `asOf` in summary; treat counts as read-only guidance, detail/submit authoritative. |
| Reuse Host staff detail overview wholesale | Existing aggregation code | Host scope differs, some projections include published/history and pinned answer diagnostic scans | Reject direct reuse; reuse domain eligibility semantics only. |
| Stored counters/events/materialized views | Cheap repeated reads at large scale | Reconciliation, data migrations and stale counters add operational complexity | Defer pending actual query plans/load evidence. |

Suggested endpoints: `GET /api/v1/proctor-assignments/mine/overview` and `GET /api/v1/examiner/work/overview`. Follow existing controllers' role guard and principal-derived scope. Add DTOs/services/repository reads within the owning session/scoring modules; shared API client contracts under existing request/type conventions. No new domain mutable entity is required.

## Query design and performance

- Proctor overview: one aggregate against owned assignments + active session rows, conditional counts over status and UTC date boundaries. Use COUNT DISTINCT session public ID if the read model can contain more than one assignment row per session; verify schema uniqueness before assuming plain row counts.
- Examiner overview: first derive a single row per owned, undeleted, unpublished assignment. Preaggregate undeleted saved decisions by tenant/session/attempt and owner where valid; left join cohorts and cohort members with exact tenant/session/cohort/attempt keys, avoiding fan-out. Compute progress and readiness once, then aggregate counts. Queue should use the same read semantics rather than another slightly different CASE expression.
- Current queue repeats correlated score count subqueries in SELECT/filter/count. Copying that query four times for four cards magnifies work. A native projection/CTE with grouped score counts is an alternative for a clear one-pass aggregate; avoid making the query implementation a general dashboard framework.
- Do not call attempt detail once per queue row: that path reads answer payloads, prompt data and media metadata. Readiness is derivable directly from cohort and member read data.
- Existing `V93__staff_schedule_lookup_indexes.sql` has `(tenant_id, proctor_public_id, session_id) WHERE deleted=false` and session schedule index. Examiner V58 index is `(tenant_id, session_public_id, examiner_public_id)`, which may be less selective for personal cross-session overview than `(tenant_id, examiner_public_id, ...)`. Existing saved-score index covers `(tenant_id, session_public_id, attempt_public_id)`. Inspect actual query plans before adding indexes; any new migration must use the next available version rather than assuming a fixed number.
- Cache summaries for a short period; refetch on window focus/manual refresh. Avoid adding high-frequency global polling or an additional websocket solely for cards. Score success invalidates Examiner summary, queue and current detail. Identity switch must not reuse another actor's cached summary.

## Time and consistency

Use injected `Clock` from `pte-api/app/src/main/java/com/pte/shared/config/ClockConfig.java` (UTC) to obtain a single `asOf` instant per request. Today must be defined in a named timezone shared between backend bucketing and browser rendering. This research did not establish a canonical tenant timezone setting. For this Vietnamese MVP, explicitly adopt Asia/Ho_Chi_Minh in the contract unless the primary research finds an existing tenant setting; do not silently use the server timezone or arbitrary browser timezone. Convert local midnight and next midnight to instants and use `[start, end)` bounds.

When the summary request fails, keep the list usable and show a summary-specific retry. Loading must not show zero as a factual count. Empty assignment data should show zeros with an explanatory empty state. List and summary can differ transiently under concurrent grading; a refreshed summary cannot authorize finalization, and does not override the existing stale/receipt/uncertain-submit guards.

## Boundaries and unresolved implementation details

- No changes to Proctor force-submit/flag or Examiner grading decision/receipt logic, Host publication rules, login routing, feature flag defaults, or assigned ownership.
- No AI score values/student identity added to overview payloads; only owner-scoped operational counts and safe row metadata.
- Confirm whether product wants completed published history later. Current queue intentionally hides it; do not introduce that expansion under “Đã chốt”.
- Confirm query parity for soft-deleted scores and assignment eligibility snapshots when implementing the shared projection. Existing queue counts scores without an explicit score deleted condition; a new summary must not quietly diverge from queue totals.
- Unsaved drafts remain governed by the existing submission/draft implementation. An overview must not promise “resume draft” when it only knows committed IN_PROGRESS state.

Research is based on local source reads only. No measured performance claim, live data inspection, migration execution or runtime validation is asserted.
