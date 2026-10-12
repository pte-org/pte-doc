# Primary research — staff workspace overview

Date: 2026-10-12. Source-only research; no product edits or runtime verification.

## Verified existing surfaces

- `pte-api/.../session/internal/controller/ProctorAssignmentQueryController.java`: role PROCTOR, GET /api/v1/proctor-assignments/mine derives actor/tenant from CurrentUserContext, returns PagedResult. SessionService facade calls ProctorMonitoringQueryService. Existing sorting opensAt ASC makes historical assignments precede current work; counts cannot be taken from this page.
- `pte-api/.../session/internal/service/ProctorMonitoringQueryService.java`: server-side Page<ProctorAssignment>, safe session DTO, no personal overview. New summary belongs to session assignment ownership, not a Host-wide statistics API.
- `pte-api/.../scoring/internal/controller/ExaminerWorkController.java`: EXAMINER class authorization, own queue and detail. ExaminerScoringService.requireActiveExaminer validates active identity; overview should reuse it.
- `pte-api/.../scoring/internal/repository/ExaminerWorkQueueRepository.java`: current visible scope = own active assignment, tenant, no scoring publication. Status based on eligibleAnswerCount and human score counts; eligible0 = COMPLETED. Sorting assignedAt DESC; no readiness fields in queue projection.
- ExaminerScoringService detail computes capability from MANUAL cohort FROZEN/COMPLETED, exact member not excluded, unpublished. This is separate from PENDING/IN_PROGRESS progress and from AI readiness. Any new queue capability must agree with detail.
- Frontend Proctor AssignedSessionsView and ExaminerQueueView already form landing pages; root routes redirect into them. resolveWorkspace and navigation should remain unchanged.
- @pte/api-client uses separate proctoring/scoring request/types paths. Examiner mutation invalidates queue and detail; new overview needs explicit invalidation too. Query cache scope must include actor and tenant.

## Recommended implementation

Add read-only own-summary endpoints and bounded priority lists. Aggregate database-side, avoiding all-page fetch and per-attempt detail/media. Add server ordering/filter support to existing list routes as optional additive query params where needed. Proctor TODAY must have a full paginated view behind a bounded preview; do not pretend five items represent all shifts.

Counts/time policy should be described once and reused across summary, priority and listing. For Examiner use grouped scores by answer/assignment with explicit ownership/deleted predicates and no multiplicative join counts. Progress totals count human decisions, not AI output. Avoid rowcount changes hidden in a dashboard query without aligning the queue semantics.

Frontend adds three cards on each existing page, existing list remains visible if overview fails. No new app/route, WebSocket, media signature or writes. Preference: fixed Asia/Ho_Chi_Minh for schedule until timezone configuration is explicitly in scope; completed Examiner totals retain unpublished scope and say so.

## Alternatives and verification

Calling existing queue once per status can get count totals but adds redundant page content/queries and cannot provide readiness/priorities. Fetching all assignments to count is unbounded. Use a compact summary DTO instead. Database indexes only after EXPLAIN evidence; no schema change by default.

Checks planned: >1 page count stability, other tenant/actor isolation, actor switch cache, session window boundaries/cross-midnight, excluded/AI_ONLY/no-cohort readiness, AI pending manual permission, mutation overview invalidation. No SLA measurement or test result claimed.

## Execution note

Primary researcher returned the key findings above before its run ended with capacity error. Root consolidated and checked them against current controller/repository/service source. Alternative research remains independently assigned.
