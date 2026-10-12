# Phase 01: Attendance persistence and contracts

Status: pending. Stories P1 roster/state/audit; P2 filtering/history. FR02–04,07,10–11.

## Design Constraints

Session-owned state; roster independent of attempts; no enrollment-delete cascade, new start gate or new scoring state. Public facades for module boundaries. Current and history are separate from student presence inferred by activity.

## Files and steps

Paths under pte-api/app/src/main/java/com/pte unless otherwise stated.

- [x] Inspect current migrations and select the next unused version under app/src/main/resources/db/migration. Do not alter applied migrations or assume V97 is free.
- [x] Add session/domain/SessionAttendance and SessionAttendanceCommand (immutable) plus AttendanceStatus enum. Current key unique tenant/session/student; current recordedEnrollmentPublicId, explicit monotonic version and last actor/time. Store current row for reset as well; read synthetic UNMARKED/version0 if absent.
- [x] Command log fields: scoped request UUID, canonical original intent fingerprint, target enrollment/student, expected/applied version, previous/new effective status, reason/note, actor/role, server time, changed flag and committed result. Unique tenant/session/actor/request UUID, indexes for session/student history. No-op creates a receipt once but no transition-history entry. Do not put mutable URLs/PII into fingerprint.
- [x] Define read contracts under session/dto/response: AttendanceRowView, AttendanceSummaryView, AttendancePageView, AttendanceCommandReceiptView, AttendanceHistoryView. Required enum/version/enrollment UUID/capability/reason/asOf fields; 0 counts only on successful empty scope. Existing PageMeta/PagedResult semantics retained.
- [x] Add session internal repositories/services for active-enrollment LEFT JOIN current attendance; filter on effective generation-specific attendance before pagination. Full summary independent of search/filter/page. Stable student/enrollment ID sort; size20/max100. Removed enrollment excluded from current counts, historical events retained.
- [x] Publish minimal Identity staff-student search view in the same versioned migration, actual table/column names verified from Identity domain. View exposes tenant/student/displayName/email only. Session query joins safe view with exact tenant/student IDs and active roster; normalized bounded search length≤100, parameterized escaped LIKE or exact-ID search. No truncation of candidate IDs before roster pagination and no cross-module internal repository import.
- [x] Proctoring attendance read coordinator composes Session public roster + Identity display-name facade + Attempt latest-activity facade by returned page IDs. Existing MonitoringQueryService is reference, not an import target from Session. Host read can use same authorized coordinator or public facade; no separate inconsistent roster authority.
- [x] Proposed role-separated REST: Proctor `/api/v1/exam-sessions/{sessionId}/attendance` GET/page+summary, PATCH `/students/{studentId}` and GET history; Host `/api/v1/host/exam-sessions/{sessionId}/attendance` equivalents. Each derives actor/tenant; optional exact own receipt GET by requestUUID permits read reconciliation. Controllers thin; mutations delegate Session facade; verify actual route conflicts before adding.
- [x] Mutation DTO: status, enrollmentPublicId, expectedVersion, requestPublicId, reason/note. Server derives actor/time; define 400/403/404/409 machine codes plus safe UI mapping. Fingerprint contract fixed before Phase02.

## Acceptance evidence

Student with no attempt appears UNMARKED; 101-row roster totals page-independent; search matches beyond first page; other-tenant names never included; remove/re-add membership preserves audit but resets effective current status; exact JSON names align frontend; first saved version is1.

## Quality and Testing State

Quality not evaluated; testing not started; optional test/quality skipped by prior choice. Backend compile planned, not executed. Migration/native query execution and SQL constraints remain unverified until such checks are actually performed.
