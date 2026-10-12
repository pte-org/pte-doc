# Spec: Sidebar chức năng và điểm danh sinh viên

Date: 2026-10-12. Status: Approved direction; all five product validation answers recorded for planning.

## Problem statement

Overview cần giữ các đường vào chức năng ở sidebar, thay vì phụ thuộc vào thẻ. Proctor cần xác nhận sinh viên có mặt/vắng trong một ca thi, độc lập với việc sinh viên đã mở attempt hay gửi heartbeat.

## User stories

- P1 Proctor/Examiner: truy cập chức năng từ cả sidebar và thẻ; hai đường dẫn mở cùng workflow/filter.
- P1 Assigned Proctor: chọn ca, tìm sinh viên trong roster enrollment, ghi Có mặt hoặc Vắng mặt và thấy kết quả lưu thật.
- P1 Assigned Proctor: xem số chưa điểm danh/có mặt/vắng trên toàn roster, kể cả ngoài trang hiện tại.
- P1 Proctor: biết khi giám thị khác đã thay đổi bản ghi; không ghi đè âm thầm hoặc replay write khi mất kết nối.
- P1 Host: xem attendance và sửa sau ca đóng với lý do, lưu đầy đủ người/thời điểm/trước-sau.
- P2 Proctor/Host: lọc trạng thái, xem lịch sử, điều hướng quay lại bộ lọc/trang đã chọn, locale vi/en và mobile.
- P3 outside MVP: biometrics/QR/student self check-in, absence auto-detection, exam-start gate, bulk absence, offline writes, excused absence/late policy.

## Sidebar and entry points

Proctor entries when workspace enabled:

| Entry | Destination proposal |
| --- | --- |
| Tổng quan | /proctor/sessions — existing overview/list |
| Giám sát | /proctor/sessions?scope=ACCESSIBLE — existing assigned accessible list |
| Điểm danh | /proctor/attendance — assigned-session picker, then /proctor/attendance/{sessionPublicId} |
| Nhật ký | /proctor/audit-log — new assigned-session picker leading to existing /proctor/audit-log/{sessionPublicId} |
| Hồ sơ | /proctor/profile — existing |

Examiner entries: Tổng quan /examiner/work; Chưa bắt đầu /examiner/work?status=PENDING; Đang chấm /examiner/work?status=IN_PROGRESS; Đã chốt /examiner/work?status=COMPLETED. These use existing queue/detail, not new publication or attendance permissions. Existing overview cards link to the same filters. Do not expose a function solely inside a card.

Sidebar active state must distinguish query-filter entries sharing a pathname (one active item, stable route precedence), and mark the appropriate parent for detail routes. Mobile drawer keeps the same available functions. Preserve login role precedence and existing workspace switching. Feature-disabled Proctor remains unavailable; do not activate rollout automatically. Role-authorized entries do not disappear simply because the current selection has zero rows; empty states explain no assignment.

## Attendance workflow

1. Open Điểm danh from sidebar or assigned-session action. Show only assigned ca in the current tenant; select a ca before accessing roster.
2. Display roster from active session.Enrollment, not just students with attempts. Default UNMARKED; no database attendance row is required just to display an unmarked student.
3. Row: safe student identifier/name/email where already allowed, attendance badge, separate exam activity status, last activity if available, recorded actor/time, actions Có mặt/Vắng mặt. Missing activity is unknown/not started, never auto-ABSENT.
4. Explicit per-student action writes server state; only show success after authoritative response. Switching already-marked status or resetting UNMARKED requires a reason. Initial absent can include a note; attendance is still explicitly manual.
5. If marking ABSENT while attempt activity exists, show a confirmation warning explaining the discrepancy. Keep activity and attendance independent; no force-submit, deletion or score change.
6. Summary counts UNMARKED/PRESENT/ABSENT over all current active enrollments; filter/search/page does not change its scope. Never call a failed request a count0.
7. Proctor can correct during the attendance editing window; after CLOSED roster is read-only. Host correction requires reason and audit; Host uses a tab on existing exam-session detail, not Proctor identity impersonation.

## Functional requirements

1. FR01: sidebar+card parity as above; session-specific functions have an assigned-session selector rather than an invalid UUID-less deep link. No new Host-only link in Examiner/Proctor nav.
2. FR02: attendance identity = tenant + exam session + student, max one current record; not attemptPublicId. Start from valid active enrollment. Preserve historical audit if enrollment is later removed, without changing existing enrollment deletion behavior; current summaries exclude removed enrollment.
3. FR03: states UNMARKED/PRESENT/ABSENT only. PRESENT is confirmed presence, ABSENT is confirmed absence. Neither attempt creation nor heartbeat writes attendance. A student may start while UNMARKED/ABSENT because user explicitly selected informational-only MVP.
4. FR04: read authority uses assigned Proctor/tenant or Host owning tenant as appropriate. Examiner/student cannot write or read another student's attendance via these staff APIs. Actor/tenant derived from CurrentUser, never client identity parameters.
5. FR05: Proctor write lifecycle = SCHEDULED or OPEN, active assignment/enrollment, opensAt minus30minutes <= serverNow < closesAt. No writes in DRAFT/PREPARING/READY/CANCELLED/CLOSED, before the30-minute boundary or after cutoff; missing/invalid timing fails closed. Every write rechecks current membership. No ACTIVE monitoring STOMP session is needed. Attendance never automatically closes or marks students absent at a clock boundary. CLOSED corrections only Host with reason; CANCELLED remains read-only.
6. FR06: Host may correct SCHEDULED/OPEN/CLOSED with reason; no change to CLOSED session state, enrollment, attempt eligibility, grading disposition/cohort or published score snapshot. Published attendance corrections remain administrative metadata, not score corrections.
7. FR07: persist current status with version plus immutable change history: actor, role, server time, old/new status, reason/note and request correlation. Same-status click should be no-op without duplicate audit; full exact retry semantics decided in plan, not inferred from equal status alone. A different intent must not be accepted as a retry.
8. FR08: mutation revalidates session lifecycle, tenant, assignment and enrollment inside transaction. Coordinate session-close/assignment-revocation with existing session mutex before attendance-row lock; verify actual lock matrix in plan. Expected version prevents two proctors overwriting; conflict409 triggers authorized refetch and explicit reconfirmation. Score/STOMP locks are not reused as permission to edit before OPEN.
9. FR09: network timeout is unknown outcome. Keep confirmed intent/correlation, read authoritative attendance/history, permit only controlled exact retry. No automatic offline write replay; warning stays until reconciled. No success from optimistic-only state.
10. FR10: full roster is paginated20/max100; safe search/status filter handled server-side. Batch identity/activity projections and aggregate counts, no per-student detail/media API calls. Manual/focus refresh; no extra WebSocket requirement for MVP. If another proctor changes a row, refresh shows it; write409 protects stale writes.
11. FR11: list+summary/read DTOs include canEdit/blockingReason/server time/version; UI capability is guidance, server write always checks. Counts and rows preserve canonical status field names; no missing-field defaults hiding malformed contracts.
12. FR12: labels, notes, status and machine-code mapping use feature locale catalogs and shared @pte/ui; no raw errors displayed. Accessible row actions/confirm dialogs, keyboard, widths320/768/1024, light/dark. Audit PII exposure remains limited to existing staff-safe projections.

## Proposed API and placement

Read-only roster: GET /api/v1/exam-sessions/{sessionPublicId}/attendance with page/size/status/search. Return page plus whole-roster summary and per-row capability/version. Mutation: PATCH /api/v1/exam-sessions/{sessionPublicId}/attendance/students/{studentPublicId} with status, expectedVersion, requestPublicId and reason/note. History: GET same student path/history, paginated and tenant/role scoped. Exact route/envelope finalized in ck:plan against conventions.

Session module owns roster membership and attendance keyed by enrollment session/student. Proctoring supplies existing assigned policy/activity through public facades; no direct cross-module repository imports. Use dedicated current attendance and audit persistence rather than putting physical attendance on ExamAttempt or treating violation logs as attendance history. Planning may choose a simpler model only if it preserves versioning/audit and enrollment removal behavior. New migration version must be selected from actual repo state, not hard-coded here.

Frontend: extend lib/navigation.tsx and shared navigation active-match rules; reuse assigned sessions/query hooks for selectors. Add features/proctor attendance components/hooks/messages and thin attendance/audit-selector route wrappers. Host attendance tab belongs in existing exam detail feature. Shared types/requests in packages/api-client follow session/proctoring conventions. No examiner scoring UI/API modifications beyond navigation entry points.

## Success criteria

- Every approved sidebar function has a valid destination with or without any assigned rows, and matches its card link; exactly one active nav item when query filters share a pathname.
- Student without an attempt remains visible and UNMARKED until explicit action. Heartbeat does not change attendance.
- Summary for a101-enrollment roster is identical at page0/page1 and reflects all committed attendance statuses.
- Assigned Proctor can record SCHEDULED/OPEN attendance in the proposed window; wrong tenant, unassigned actor, revoked assignment and removed enrollment cannot mutate.
- CLOSED Proctor write is denied; Host correction without reason is denied; allowed Host correction yields one current change and one audit record.
- Two concurrent versions produce one accepted mutation and a conflict requiring reconfirmation, rather than silent overwrite.
- Attendance edits never change exam-start permission, attempt state, grading membership/score/source or publication snapshot.
- Failed/timeout writes do not show success or automatically replay; server-authoritative reconciliation resolves retained intent.
- Existing current Proctor feature flag state is preserved; no deploy implied.

## Validated scope and handoff

User confirmed informational-only attendance; Host-only post-close correction with reason/history; Proctor starts30minutes before opensAt; initial absence reason optional; reset to UNMARKED allowed with reason/history. Individual actions, three statuses and route placements follow the approved brainstorm direction. No implementation/testing done. Prior preference to skip tests/quality is retained for later handoff; acceptance cases remain requirements even if checks are declined.
