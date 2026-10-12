# Implementation Handoff Note: Staff Workspace Overview

**Plan:** `hung-staff-workspace-overview`  
**Date:** 2026-10-12  
**Status:** All 4 Phases Completed (`phase-01`, `phase-02`, `phase-03`, `phase-04`)  
**Mode:** Fast Mode (`--fast`: Quality and unit tests skipped by user preference)

---

## 1. Summary of Changes

### Backend (`pte-api`)
- **Proctor Workspace Endpoints & Queries:**
  - `GET /api/v1/proctor-assignments/mine/overview?timezone={browserIanaZone}`: Returns `ProctorWorkspaceOverviewResponse` (accessibleCount, upcomingCount, todayCount, priorityCount, prioritySessions <= 5, dayStart, dayEnd, asOf, timezone).
  - `GET /api/v1/proctor-assignments/mine`: Extended with `scope` (`ALL`, `ACCESSIBLE`, `UPCOMING`, `TODAY`), `sort` (`PRIORITY`), and `timezone` returning `ProctorAssignedSessionsPageResponse`.
  - Added `InvalidTimezoneException` and `InvalidProctorScopeException` returning HTTP 400.
  - Efficient bounded DB queries in `ProctorAssignmentRepository.java` using `Clock` and local day boundaries.
- **Examiner Workspace Endpoints & Queries:**
  - `GET /api/v1/examiner/work/overview`: Returns `ExaminerWorkspaceOverviewResponse` (counts: unstarted, inProgress, finalized; progress: completedUnits, totalUnits, percentComplete; priorityQueue <= 5; asOf).
  - Created `ExaminerWorkspaceReadRepository.java` with single native PostgreSQL CTE joining `examiner_attempt_assignments`, grouped scores, `scoring_session_states`, `session_grading_cohorts`, and `session_grading_cohort_members` with zero join amplification.
  - Enhanced `ExaminerQueueItemResponse` with `canFinalize`, `blockingReason`, and `hasOutstandingAnswers`.

### API Client (`packages/api-client`)
- Added Proctor workspace overview response and session response DTOs, `ProctorScope` type, and `getProctorWorkspaceOverview`. Extended `listAssignedProctorSessions` with optional `{ scope, sort, timezone }`.
- Added Examiner workspace overview response and progress DTOs, and `getExaminerWorkspaceOverview`. Extended `ExaminerQueueItemResponse`.

### Frontend (`apps/tenant-web`)
- **Actor & Tenant-Scoped Cache:**
  - `PROCTOR_QUERY_KEYS`: Structure `["proctor", tenantId, actorId, ...]` prevents actor cache collision; overview and TODAY scopes track resolved IANA timezone.
  - `EXAMINER_QUERY_KEYS`: Structure `["examiner", tenantId, actorId, ...]` separates queue, overview, and attempt details by actor.
  - Queries are disabled until valid `tenantId` and `actorId` are resolved.
- **Proctor Overview & Today's Schedule (`/proctor/sessions`):**
  - Exactly 3 overview cards (“Có thể giám sát”, “Ca sắp tới”, “Lịch hôm nay”) with live counts. Clicking cards filters the list and resets page.
  - Priority preview list (<= 5 items) with server `canMonitor` governing primary CTA ("Vào giám sát" vs "Xem phòng").
  - URL-driven filtering (`scope`, `page`) with browser back/forward support.
  - Dynamic browser IANA timezone detection via `useClientTimezone` and scheduled midnight boundary refresh via `useMidnightBoundaryRefresh`.
  - Full localization in `vi` and `en` with `useProctorWorkspaceText`.
- **Examiner Overview & Progress (`/examiner/work`):**
  - Exactly 3 progress cards (“Chưa bắt đầu”, “Đang chấm”, “Đã chốt”) with live counts. Clicking cards filters the queue.
  - Personal progress bar showing completed/total eligible units and percentage.
  - Priority queue preview (<= 5 items) with "Tiếp tục chấm" / "Bắt đầu chấm" action buttons.
  - Readiness reasons displayed (e.g., "Chờ Host chốt danh sách" for `WAITING_FOR_HOST_FREEZE`). Non-actionable 0-eligible rows clearly labeled without leading to 404 routes.
  - Full localization in `vi` and `en` with `useExaminerWorkspaceText`.

---

## 2. Verification & Build Results

1. **Backend (`pte-api`):**
   - Command: `./mvnw test-compile -DskipTests`
   - Result: `BUILD SUCCESS` (1,186 source files, 220 test files compiled with 0 errors).
2. **API Client (`packages/api-client`):**
   - Command: `npx tsc --noEmit`
   - Result: Exited with code 0 (clean compile).
3. **Frontend (`tenant-web`):**
   - Command: `npx tsc --noEmit`
   - Result: Exited with code 0 (clean compile).

---

## 3. Rollback Steps
If rollback is required:
1. `git restore` on modified files in `pte-api` and `pte-web`.
2. Delete new DTOs/components created under `pte-api/app/src/main/java/com/pte/...` and `apps/tenant-web/features/...`.
3. No database rollback is needed (zero database schema migrations were added; all queries are read-only).
