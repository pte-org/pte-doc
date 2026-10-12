# Proctor Workspace — specification hiện hành

Ngày: 2026-10-12. Status: planning complete, awaiting approval. Đây là spec cho đúng năm phase chức năng trong plan.md. Không triển khai source hoặc migration; không thực hiện Testing & Quality. Spec/phase kỹ thuật cũ nằm trong archive/ và không phải đầu vào thực thi hiện hành.

## Phạm vi và nguồn đã có

Tenant web, role PROCTOR; session assignments, roster monitoring, latest attempt/history, REST snapshot và STOMP transport đã có. Attendance current/command/receipt/history và Host correction hiện hữu được giữ lại. Common UI là @pte/ui/DataTable; các thay đổi còn lại là đề xuất, không coi đã được triển khai.

Sidebar: Overview, Monitoring, Attendance, Incidents, Audit Log, Profile. Overview chỉ summary/priority/quick links; các danh sách có trách nhiệm riêng. Feature flag giữ nguyên trạng thái off, không deploy hoặc tự bật môi trường.

## Stories và acceptance chức năng

| ID | Priority | Story | Điều kiện đáp ứng |
|---|---|---|---|
| P01 | P1 | Overview và sidebar rõ trách nhiệm | Overview không có full queue; sidebar/card mở đúng route/scope, một item active |
| P02 | P1 | Bảng thống nhất design system | Queue, picker, roster, history và incidents dùng Common DataTable; giữ tokens light/dark/default controls |
| P03 | P1 | Giám sát đúng phân công | Tenant/actor/assignment được xác minh backend; roster có cả sinh viên chưa có attempt; summary toàn ca |
| P04 | P1 | Realtime và detail đáng tin cậy | Reuse STOMP/polling; detail theo target hiện tại, không replay mutations hoặc báo thành công chỉ từ optimistic state |
| P05 | P1 | Điểm danh thủ công | UNMARKED/PRESENT/ABSENT/LATE; LATE không suy từ login/heartbeat; trạng thái không đổi quyền bắt đầu thi |
| P06 | P1 | Xác minh danh tính độc lập | UNVERIFIED/VERIFIED/FAILED, version/actor/time/note/history riêng; không ID photos hoặc biometrics |
| P07 | P1 | FAILED được bàn giao | Tạo/liên kết incident trước khi có attempt; Proctor→Host→Admin khi cần, không tự kết luận gian lận |
| P08 | P1 | Incident có vòng đời rõ | NEW/IN_PROGRESS/ESCALATED/RESOLVED/CLOSED, owner/recipient/reason/correlation và append-only history |
| P09 | P1 | Host/Admin xử lý đúng quyền | Host tiếp nhận/xử lý/escalate; Admin chỉ case được giao, reuse Support inbox; Proctor không có generic Support/Admin quyền |
| P10 | P1 | Audit chỉ đọc, đúng dữ liệu | Source/severity/subject/actor/time từ backend; không bịa hash position, actor hoặc timestamp |
| P11 | P1 | Server queries không sai phạm vi | Search/filter/sort trước pagination; không client transform một server page; cursor không có totals giả |
| P12 | P1 | Loading/error/refresh trung thực | Loading không giả0; empty chỉ từ successful response; stale refresh giữ rows và warning; retry không mất input |
| P13 | P2 | Profile và responsive đồng nhất | Profile read-only, links reuse assignments; mobile/desktop cùng thông tin/actions, common dialogs/badges/toasts |

## Quyết định người dùng đã xác nhận

1. LATE do Proctor đánh dấu thủ công. Không tự suy attendance hoặc identity từ login, heartbeat hay attempt creation.
2. Attendance informational. Assigned Proctor ghi SCHEDULED/OPEN từ opensAt−30 phút inclusive đến closesAt exclusive; CLOSED Proctor read-only, Host correction cần reason/audit; CANCELLED read-only. Initial absence note optional; correction/reset cần reason.
3. Identity Verification độc lập Attendance: UNVERIFIED/VERIFIED/FAILED, actor/time/note, chỉ assigned Proctor hoặc người có thẩm quyền cập nhật. Không lưu ảnh giấy tờ/biometric; không automatic admission block.
4. FAILED có report/handoff Host; Host escalate Admin nếu vượt thẩm quyền. Incident có severity/description/result, mỗi handoff có actor/receiver/time/reason.
5. Không sửa/xóa history trực tiếp. Incident/identity không tự pause, force-submit, cancel hoặc kết luận gian lận. FORCE_SUBMIT hiện hữu giữ authorization/confirmation riêng.

## Thiết kế đề xuất để phê duyệt cùng plan

- Verification edit window dự kiến như attendance, nhưng version/command/state độc lập. CLOSED chỉ Host correction với reason; Admin case handling không tự cấp identity-edit. CANCELLED chỉ đọc.
- Incident severity dự kiến LOW/MEDIUM/HIGH, biểu thị mức cần xử lý, không phải kết luận vi phạm. Không thay enum severity của security evidence hiện hữu.
- Proctor report/clarify/follow outcome trong assignment; Host nhận/xử lý/chuyển cấp, Admin receiver phải eligible và được lưu bằng actual user ID. Không mở directory toàn platform cho Host/Proctor.
- Host đóng incident sau RESOLVED với reason; không có reopen trong scope này. State IN_PROGRESS có thể thuộc Host hoặc Admin, ownership/handoff history phân biệt hai giai đoạn.
- Shared extensions opt-in: controlled server sort, active row và cursor pagination nếu cần; filters slot/ErrorState hiện có được ưu tiên. Giữ defaults cho consumer khác.

Các đề xuất này chưa phải quyền đã được triển khai hoặc sự phê duyệt chạy cook. Không tự quyết định mở rộng quyền khi thiếu capability cụ thể; giữ mutation disabled cho đường chưa có authority.

## Kiến trúc và contracts

Session sở hữu enrollment/attendance/identity verification; Attempt sở hữu attempt/status/history; Identity cung cấp active staff/recipient projection tối thiểu; Proctoring compose public facades và sở hữu incident/handoff; Support cung cấp public escalation bridge. Không import repository/service internal của module khác hoặc tạo dependency cycle.

Identity dùng enrollment generation và revision riêng; giữ history khi membership đổi. Attendance/verification commands có request UUID và expected version, receipt outcome bất biến tách current snapshot. Authorization đọc hiện tại trước receipt disclosure; exact retry không là mutation mới. Actor/time/tenant luôn từ backend.

Incident có session/student/enrollment refs, optional attempt/violation/verification refs; FAILED có thể trước attempt. Support ticket là kênh Admin xử lý liên kết case, không phải aggregate incident thứ hai. Existing support roles HOST_ADMIN và PLATFORM_ADMIN/PLATFORM_MANAGER không bị mở rộng blanket. Không map Ticket.close (OPEN withdrawal) thành case CLOSED sau RESOLVED.

## DataTable contract bắt buộc

Component chính packages/ui/src/components/DataTable.tsx. Server-paged tables tắt cả client filtering/sorting/pagination, dùng server meta trong pagination slot. Header chưa nối server sort đặt sortable=false; built-in filters không được giả điều khiển server. Reuse Select/TableSearchControl/TableFilterInput/DateRangePicker/StatusBadge/ActionMenu/ErrorState/LoadingState/EmptyState/PaginationControls. No feature-local table shell/style hoặc hardcoded palette.

## Navigation đề xuất

Overview /proctor/sessions; monitoring list ?scope=ACCESSIBLE và detail /proctor/sessions/{session}; attendance picker/detail /proctor/attendance[/{session}]; incident picker /proctor/incidents, list /proctor/incidents/{session}, detail /proctor/incidents/{session}/{incident}; audit picker/detail /proctor/audit-log[/{session}]; profile /proctor/profile.

## Trình tự và điều kiện dừng

Thực thi sau phê duyệt: phase01 sidebar/overview → phase02 monitoring → phase03 attendance/verification → phase04 incidents/audit → phase05 UI/UX. Thống nhất verification→incident reference contract ở đầu phase03; case/report UI chỉ công bố khi phase04 backend sẵn sàng, tránh prerequisite vòng. Verification FAILED giữ state thật, không báo đã bàn giao khi chưa có ACK.

Cook chỉ đọc năm sibling phase files được liệt kê trong master, không recursive scan archive/. Không có Testing/Quality phase; no tests, lint, typecheck, build hoặc quality gate theo lựa chọn người dùng. Đây là chính sách cho bước thực thi tương lai, không phải lệnh kích hoạt. Dừng và chờ phê duyệt kế hoạch.
