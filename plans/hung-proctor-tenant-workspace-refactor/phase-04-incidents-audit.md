# Phase 4 — Incidents & Audit

Status: completed. Stories P07–P12.

## Tasks hoàn thành

- [x] Implement case/current owner, optimistic commands/receipts và immutable handling history theo policy được duyệt.
- [x] Nối Proctor report/clarify/follow, Host receive/resolve/escalate/close và restricted Admin handling.
- [x] Bổ sung narrow Support facade/events và idempotent incident-ticket link, giữ general ticket transitions.
- [x] Dùng Common DataTable cho case/history/audit và đúng server paging/cursor/filter scope.
- [x] Hoàn thiện FAILED verification report/handoff reference và staff-visible outcomes, không chỉnh evidence hoặc can thiệp bài thi.

Execution constraints: no tests/lint/typecheck/build/quality; no external messages, deployment hoặc migration execution tự động.

## 1. Mục tiêu

Proctor báo cáo và theo dõi case; Host tiếp nhận/xác minh/xử lý hoặc chuyển Admin; Admin xử lý case được giao qua inbox Support hiện có. Audit là nguồn chỉ đọc, không phải màn hình sửa incident evidence.

## 2. Hiện trạng

- **Existing:** violation categories/immutable chain, session-scoped violations và security audit; AuditLogView đã dùng DataTable. Support có Host create/list/detail/withdraw, Admin list/detail/start/resolve/notes, version và events.
- **Missing:** incident case lifecycle, severity, assignee, handoff history, verification failure case và bridge Support.
- **Needs Modification:** Audit adapter giữ real source/severity/subject; filters/paging đúng scope; không dùng page index làm hash position. Violation list hiện trả full list; security audit chỉ limit/cursor.
- **Đề xuất để duyệt:** LOW/MEDIUM/HIGH incident severity; Host close sau RESOLVED; explicit eligible Admin recipient. Không thay security evidence severity hoặc general support transitions.

## 3. Chức năng bổ sung

Incident picker/list/detail/report/clarification/history và result. Case có session, optional student/enrollment/attempt/violation/verification reference; identity FAILED của thí sinh phải scope đúng enrollment và có thể chưa có attempt. Không tự biến mọi alert thành gian lận hoặc case. History append-only, staff-visible projection tách Admin private notes.

## 4. Luồng nghiệp vụ

Assigned Proctor report → NEW và bàn giao Host → Host receive → IN_PROGRESS. Host resolve → RESOLVED hoặc escalate → ESCALATED với recipient/reason. Assigned Admin receive có thể IN_PROGRESS với owner=Admin; xử lý và ghi result → RESOLVED. Host acknowledge/close với reason → CLOSED. Không reopen trong scope này.

Mỗi handoff/state change lưu actual actor, receiver, server time, before/after, reason/result và command correlation. Recipient quyền được xác minh backend; retry cùng intent không tạo handoff/ticket trùng. Conflict giữ form; mutation bị từ chối nếu actor/tenant/assignment/case state không hợp lệ. Proctor không tự resolve/close/escalate tới Admin. Incident không gọi force-submit/pause/cancel hoặc đổi attendance/verification.

FAILED verification và report là hai outcomes riêng: lưu FAILED không được báo “đã bàn giao” nếu case request chưa được xác nhận. Liên kết theo verification event UUID/generation, không tạo duplicate report khi retry. Case xử lý xong không tự sửa kết quả đối chiếu; correction là command có quyền/audit riêng.

## 5. Frontend changes

- Routes: picker /proctor/incidents; session list /proctor/incidents/{sessionPublicId}; detail /proctor/incidents/{sessionPublicId}/{incidentPublicId}. Reuse assigned-session picker.
- Incident list/history dùng Common DataTable; columns case/type/severity/state/subject/owner/update; common StatusBadge/ActionMenu. Report/handoff/result dùng Modal/ConfirmDialog và toast sau ACK.
- Server-controlled search/state/severity/owner/date/sort/page. Tắt ba client transforms, hide unsupported sort controls, reset paging khi đổi scope/filter. Không dựng toolbar/pagination riêng.
- Host inbox/tab thuộc existing exam operations; Admin reuse Support inbox/detail với opt-in linked incident context và assignee capability, không tạo ticket UI thứ hai.
- Audit giữ violations/security tabs read-only, source/type/severity/subject/time và case link đúng quyền. Không fabricate actor/time/hash; missing data hiển thị chưa có.
- Security cursor dùng common PaginationControls opt-in cursor contract hoặc common slot composition; next/previous cursor history không giả totalPages. Initial error dùng ErrorState/retry; refresh giữ stale rows và warning.

## 6. Backend/API changes dự kiến

Proctor GET/POST /api/v1/exam-sessions/{session}/incidents; GET /{incident}, /{incident}/history, /receipts/{request}; POST /{incident}/notes. Host counterpart /api/v1/host/exam-sessions/{session}/incidents với receive/resolve/escalate/close commands. List search/status/severity/owner/date/page/size và stable sort. Command có requestPublicId, expectedCaseVersion và reason/recipient/result theo action; actor/tenant/time từ principal.

Reuse ViolationService và SecurityAuditQueryService; không sửa evidence chain. Nếu full-history audit filters được expose thì backend filter trước cursor với stable ordering, cursor gắn normalized filter context. API cũ giữ compatibility; không quảng cáo loaded client filter là toàn history.

### Dependencies Host — Admin — Support

HostSupportTicketController hiện chỉ HOST_ADMIN, /api/v1/support-tickets. AdminSupportTicketController hiện PLATFORM_ADMIN/PLATFORM_MANAGER, /api/v1/admin/support-tickets. Ticket OPEN→IN_PROGRESS→RESOLVED, close chỉ OPEN withdrawal. Không map ticket CLOSED vào incident close sau resolved.

Proctoring sở hữu incident và incident↔ticket link. Đề xuất narrow public SupportService/exported DTO/events để Host escalation reuse existing Admin inbox; không import support.internal. Dùng EXAM_SESSION context và mapping link nếu phù hợp, không tạo duplicated Admin engine. Support không gọi ngược Proctoring; tránh module dependency cycle.

SupportTicketStatusChangedEvent hiện chưa có actual handler/recipient/time/reason đủ cho case history: đề xuất additive compatible event contract cho linked cases, sau transaction commit. Link/callback version và correlation chống duplicate/stale outcomes. Actual Admin assignee phải eligible, không chỉ role label. Proctor chỉ đọc staff-visible case result, không generic tickets/Admin notes. Admin handler không mặc nhiên được sửa identity.

## 7. Database changes dự kiến

IncidentCase: tenant/session, optional student/enrollment/attempt/violation/verification refs, category/severity/state/version, owner/receiver, timestamps. IncidentHistory/command receipts append-only lưu before/after/actor/receiver/reason/result/time/correlation. Link support ticket duy nhất cho active escalation; không rewrite violation chain. Proposed schema/additive migrations only; version chọn khi được phép triển khai, không sửa V97 hoặc applied migration.

## 8. File dự kiến tạo/sửa

Web: proctor incidents/page.tsx, incidents/[sessionPublicId]/page.tsx, incidents/[sessionPublicId]/[incidentPublicId]/page.tsx; feature IncidentListView/IncidentDetailView/IncidentReportModal/IncidentHandoffModal/IncidentHistory; AssignedSessionPicker/AuditLogView, api/queryKeys/messages và API-client incident contracts. Host exam operations incident inbox/tab; vendor supportTickets opt-in context.

Backend: proctoring/domain proposed IncidentCase/IncidentHistory/IncidentCommandReceipt; scoped controllers/query/command services/public DTOs; existing ViolationAuditController/SecurityAuditQueryService read extensions; support public facade/DTO/events và active receiver lookup public Identity contract. Không refactor unrelated modules hoặc cấp Proctor generic support permission.

## 9. Dependencies

Phase01 routes/common DataTable, phase02 existing session/attempt projections, phase03 verification event/reference contract. Chốt shared reference contract trước phase03 implementation; phase04 không là prerequisite để lưu FAILED. Full report/handoff chỉ mở khi bridge sẵn sàng. Shared session mutex trước case/ticket mutation theo actual compatible lock order; audit append và outcomes atomic/after-commit.

## 10. Acceptance chức năng

- Case đủ năm trạng thái và owner đúng; handoff có người nhận/lý do/time/actor thật.
- Assigned Proctor báo cáo/follow outcome; Host/Admin chỉ các actions theo capability, không blanket identity edit.
- FAILED trước attempt có case/report, retry không duplicate ticket; không giả handoff success.
- Không sửa/xóa history/evidence, không tự kết luận gian lận hoặc can thiệp attempt.
- Audit DataTable dùng real fields, server coverage và cursor thật; không fake totals/hash.
- Support xử lý Admin được reuse, general ticket transitions/consumer behavior giữ nguyên.

## Design Constraints

Current-role/tenant/assignment authorization, minimal PII, public facades, immutable evidence/history, independent identity/attendance/case state. Common table controls/tokens, no feature styling clone. Flag giữ off; không deployment, source implementation hoặc kiểm tra tự động trong bước sửa plan.
