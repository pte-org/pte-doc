# Phase 01: Overview contracts and bounded read queries

Status: completed [quality: skipped_by_user; decision: user_confirmed_skip; tests: not_started_user_declined]. Dependencies: none. Covers P1 Proctor/Examiner/actor; FR01–08, FR12.

## Design Constraints

CurrentUser-derived tenant and actor only, existing role guards, no client-selected owner. Read-only transactions. No schema/write behavior changes. Same predicates across summary, priority and paginated lists; no list-page-derived counts, all-page hydration or per-attempt detail calls. Reuse module ownership: session for Proctor, scoring for Examiner. One injected Clock instant per request.
Preflight: Module boundaries strictly followed (session module owns Proctor reads, scoring module owns Examiner reads); Spring constructor injection with Clock injected; DomainException mapped to HTTP 400 for invalid timezone/scope; Read-only transactions with @Transactional(readOnly = true); no join amplification; bounded page/query volume (<=5 priority rows); backwards-compatible response structures.

## Exact files and contract

Paths below are relative to `pte-api/app/src/main/java/com/pte/`.

- Extend `session/internal/controller/ProctorAssignmentQueryController.java`, `session/SessionService.java`, `session/internal/service/ProctorMonitoringQueryService.java`, `session/internal/repository/ProctorAssignmentRepository.java`.
- Add `session/dto/response/ProctorWorkspaceOverviewView.java` and safe row view `ProctorWorkspaceSessionView.java`; controller-facing DTOs in `session/internal/dto/response/ProctorWorkspaceOverviewResponse.java` / `ProctorWorkspaceSessionResponse.java` follow current internal REST mapping. No internal entity serialization.
- Extend `scoring/internal/controller/ExaminerWorkController.java`, `scoring/internal/service/ExaminerScoringService.java`, `scoring/internal/repository/ExaminerWorkQueueRepository.java`, `scoring/dto/response/ExaminerQueueItemResponse.java`.
- Add `scoring/dto/response/ExaminerWorkspaceOverviewResponse.java`, `scoring/internal/service/ExaminerWorkspaceQueryService.java`; a dedicated `scoring/internal/repository/ExaminerWorkspaceReadRepository.java` with custom implementation is appropriate for a shared native CTE/projection. Do not build a general dashboard framework.

`GET /api/v1/proctor-assignments/mine/overview?timezone={browserIanaZone}` returns existing `ApiResponse<T>` envelope, payload:

```text
asOf: Instant; timezone: String; dayStart/dayEnd: Instant
counts: { accessible: long, upcoming: long, today: long }
prioritySessions: ProctorWorkspaceSessionResponse[] // <=5
row: existing safe assignment/session identifiers, name/code/status/times/role
     + canMonitor: boolean + monitoringBlockingReason: nullable enum
```

No duplicate bounded “complete today schedule” payload. Add optional `scope=ALL|ACCESSIBLE|UPCOMING|TODAY` to existing `/mine?page&size`; default ALL preserves old caller behavior. Add readiness fields to `AssignedProctorSessionResponse` without removing existing fields. TODAY requires validated timezone and returns the entire day schedule via pages. Freeze the payload as `ProctorAssignedSessionsPageResponse { data, meta, asOf, timezone, dayStart, dayEnd }` under the existing ApiResponse envelope; data/meta retain their current shape. New UI sends timezone for every scope. Legacy ALL requests without timezone remain valid and return null timezone/day bounds plus asOf; supplied invalid timezone always returns400. This list computes its own time context and never depends on a successful overview request. Add the response record under session/internal/dto/response and type it as an additive PagedResult extension in the client.

`GET /api/v1/examiner/work/overview` returns:

```text
asOf: Instant; scope: ASSIGNED_UNPUBLISHED
counts: { pending: long, inProgress: long, completed: long }
progress: { eligibleAnswerTotal: long, finalizedAnswerTotal: long }
priorityItems: ExaminerQueueItemResponse[] // <=5
```

Queue row additions: `canFinalize`, `blockingReason` matching detail strings (`WAITING_FOR_HOST_FREEZE`, `COHORT_NOT_MANUAL_EXAMINER`, `EXCLUDED_FROM_COHORT`, `ALREADY_PUBLISHED`), `hasOutstandingAnswers`. Null blockingReason when policy permits; eligible=0 is explicitly completed/non-actionable rather than a new invented Host block reason. Existing queue status/session/page/size parameters and envelope retained.

## Steps

- [x] Verify existing uniqueness/immutability and saved score status assumptions. Read query schema/source before choosing score grouping; no product mutations. Record any owner/deletion semantic discrepancy in phase notes before changing the predicate.
- [x] Resolve browser timezone parameter with ZoneId, return controlled400 for absent/invalid required overview/TODAY timezone. Do not use host timezone or accept a client asOf. Implement Proctor aggregate conditional counts over actor-owned undeleted assignments/session rows; prevent duplicate sessions via existing uniqueness or distinct identity projection. Compute day boundaries from Clock once: `dayStart <= opensAt && opensAt < dayEnd`, excluding cancelled/deleted; temporal nulls excluded. Ca mở hôm qua không thuộc TODAY.
- [x] Add paginated scope predicates and DB ordering. New scope order: accessible first, then upcoming, then other rows; ties opensAt ASC null-last, session publicId ASC, assignment publicId if needed. Keep legacy ALL order unless UI explicitly requests new `sort=PRIORITY`; validate supported query enums as4xx. Priority previews use accessible/upcoming only, DB limit5 and identical predicates; TODAY full filter preserves local start-day semantics, including noncancelled READY/DRAFT/etc as read-only when assigned.
- [x] Implement Examiner shared read projection: one row per actor-owned assignment with grouped human decision counts and scoped cohort/member joins, no join amplification. Align queue SELECT/status filter/count/overview/priority using the same projection. Preserve current queue score-count semantics by exact tenant/session/attempt; do not add stricter owner/deleted/status predicates only in overview. Verify immutable score/assignment and schema ownership assumptions; document anomalies separately rather than changing existing write/detail/receipt or progress policy.
- [x] Preserve eligible0 COMPLETED. For answer totals, denominator is assignment eligible sum; numerator uses finalized eligible human decisions for that assignment and must not exceed denominator. Any overcount is diagnosed, not silently hidden by clamp. AI score rows never count.
- [x] Derive readiness from exact active assignment + no publication + MANUAL_EXAMINER cohort FROZEN/COMPLETED + present included member. Use shared read helper/predicate with detail capability checks, without loosening submit policy. `hasOutstandingAnswers` is derived from actual valid eligible unfinalized answers using canonical eligibility, not AI availability or just an optimistic table count. Detail fields remain authoritative after navigation.
- [x] Examiner priority: actionable IN_PROGRESS, then actionable PENDING; within bucket assignedAt ASC then attempt publicId ASC (oldest actionable first). Limit5 in DB; exclude completed/zero-answer/blocked rows. Existing main queue sort stays newest-first unless explicitly requested; progress cards filter current queue.
- [x] Controller role guard/principal derives scope; reuse `requireActiveExaminer` before summary. Return genuine zeros only for successful empty scope. Omit media/payload/student/provider data; 403 and standard validation/error mapping preserved.
- [x] Keep query-count bounded: overview at most one aggregate + one limited priority read per role; list page + count are separate. No per-row service call. Inspect EXPLAIN only if execution checks are authorized; no speculative index migration.

## Acceptance evidence to record during implementation

101 assignments with useful rows outside page0; summary unchanged across pages/filters. Tenant/actor denial and owner/deleted-row scope. Exact opensAt/closesAt and browser-local day bounds; previous-day opening excluded even if ongoing; timezone invalid controlled400. READY not upcoming. Zero-eligible completed with disabled action. Manual/cohort/excluded/publication cases agree with detail; AI pending does not block valid manual work. No data writes or detail/media fan-out.

## Quality and Testing State

Quality: not evaluated; prior preference skip. Testing: not started; prior preference skip tests/E2E. Cases above are recommended evidence, not automatically scheduled tests. Compile with `-DskipTests` planned after edits. Compile alone does not verify SQL query validity/startup/access behavior. Phase completion requires implementation review and recorded limitations.
