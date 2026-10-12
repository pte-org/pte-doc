# Phase 3 — Attendance

Status: planned, chờ phê duyệt. Chỉ tài liệu; không triển khai.

## 1. Mục tiêu

Hoàn thiện điểm danh thủ công, bổ sung đến trễ thủ công và xác minh danh tính độc lập, dùng chung roster/history giữa Proctor và Host mà giữ permission riêng.

## 2. Hiện trạng

- **Existing:** roster có search/status/page/size, summary, record modal và history; backend có UNMARKED/PRESENT/ABSENT, optimistic version, enrollment generation, request ID/receipt và command history. Proctor điểm danh Scheduled/Open từ opensAt−30 phút inclusive đến closesAt exclusive; Host có đường correction sau Closed với reason; Cancelled chỉ đọc.
- **Missing:** LATE và trạng thái xác minh danh tính độc lập chưa có trong contract hiện hành.
- **Needs Modification:** roster/history raw tables, shared Host attendance presentation, summary/filter/commands để hỗ trợ trường mới; không viết lại cơ chế receipt/conflict.
- **Needs Confirmation:** không còn chờ quyết định LATE/identity: người dùng đã chọn LATE thủ công và UNVERIFIED/VERIFIED/FAILED độc lập. Thẩm quyền Admin phải theo role policy và chỉ scope được giao; việc cấp thêm quyền hoặc đổi cutoff không nằm trong quyết định này.

## 3. Chức năng bổ sung

Attendance bổ sung LATE do actor chọn; tuyệt đối không suy từ login, heartbeat hay attempt time. Identity hiển thị riêng UNVERIFIED/VERIFIED/FAILED, actor, timestamp, note và history/audit. Assigned Proctor hoặc Host được phép cập nhật theo policy; không thu ảnh giấy tờ/biometrics, không tự xác minh. FAILED báo cáo cho Host; Host chuyển Admin khi cần theo phase4, không bỏ qua bước Host. Không tự chặn bắt đầu thi, pause/submit/cancel. Điểm danh và identity không tự cập nhật lẫn nhau.

## 4. Luồng nghiệp vụ

Assigned Proctor chọn ca → roster enrollment → chọn student → ghi PRESENT/ABSENT/LATE trong cửa sổ hiện hành → gửi command với request ID, expectedVersion và generation → receipt → cập nhật row/summary/history. UNMARKED là trạng thái chưa ghi, không tự chuyển ABSENT khi hết giờ. Version/generation conflict giữ draft và yêu cầu đối chiếu dữ liệu mới; timeout tra receipt trước quyết định retry, tránh ghi kép. Host sửa Closed cần reason; Cancelled chỉ đọc.

Identity là luồng riêng: actor có quyền xem student và enrollment → kiểm tra thủ công ngoài hệ thống → chọn VERIFIED hoặc FAILED, note và command identity → append history. FAILED mở báo cáo incident với session/student/identity event, không cần attempt; chuyển giao có người nhận/reason và không kết luận gian lận. Re-enrollment phải giữ đúng generation và không gán kết quả enrollment cũ sang enrollment mới. Hoàn thành khi command đã có kết quả bền vững và history phản ánh actor/time; escalation hoàn thành khi có bản ghi chuyển giao, không khi chỉ mở dialog.

## 5. Frontend changes

- `AttendanceRosterTable` và `AttendanceHistoryModal` chuyển sang common DataTable; component hiện có `ExamAttendanceTab` trong `features/exams/components/ExamAttendanceTab.tsx` reuse cùng roster/history, chỉ truyền actions/capabilities và hook Host khác. Không dựng một Host table mới.
- DataTable typed rows, stable student/enrollment keys, badges riêng attendance/identity, rowActions qua ActionMenu; history chỉ đọc. Search controlled, filters slot dùng Select table variant/TableFilterInput; server search/status trước paging, thêm identity filter sau API mở rộng. Tắt client filtering/sorting/pagination, các header chưa hỗ trợ sort đặt `sortable=false`.
- Common pagination slot theo metadata thật, reset page khi filter đổi. Summary là server scope được định nghĩa, không lấy từ rows. renderMobileRow giữ đủ identity/attendance/actions.
- RecordAttendanceModal tiếp tục cơ chế receipt/retry; thêm LATE mà không thay semantics hiện có. Identity modal tách form và history; FAILED cung cấp report/escalation action. Pending/conflict/retry giữ unsaved note; initial loading/empty/error dùng common states, refresh giữ roster cũ và warning nếu stale.

## 6. Backend/API changes

Reuse GET/PATCH `/api/v1/exam-sessions/{id}/attendance`, receipts và student history; Host dùng HostAttendanceController hiện có. Mở rộng AttendanceStatus, summary, validation/client DTO để nhận LATE thủ công. Đề xuất identity read/update/history contracts tương ứng session/student, có version/generation/idempotency và audit độc lập; authority đi qua AttendanceCoordinator/ProctorAccessPolicy và Session owner, identity profile chỉ qua Identity facade. Endpoint cụ thể cần ghi nhận trong contract khi phê duyệt triển khai, không giả là API đã có. FAILED liên kết incident Phase 4; không yêu cầu attemptPublicId và không thêm exam admission gate.

Endpoint identity dự kiến để duyệt: GET `/api/v1/exam-sessions/{session}/identity-verifications` (status/search/page/size), PATCH cùng path `/students/{student}`, GET `/students/{student}/history` và GET `/receipts/{request}`. Host equivalents dưới `/api/v1/host/exam-sessions`. Command có state/note/enrollmentPublicId/expectedVerificationVersion/requestPublicId; backend tự lấy actor/time/tenant. Row có verification state/version, last actor/time/note và capability riêng. Verification revision không dùng expected attendance version. Nhánh correction/reset bắt buộc lý do; FAILED bắt buộc mô tả kết quả đối chiếu và pending handoff reference, không ghi thông tin giấy tờ nhạy cảm.

## 7. Database changes dự kiến

Reuse `session_attendances` và command records để mở rộng enum LATE. Đề xuất record identity độc lập trong Session cho tenant/session/student/enrollment generation, state/version/last actor/time/note cùng append-only commands/history; không ghi trạng thái identity vào attendance status hoặc sửa profile danh tính. Incident lưu reference identity event qua public IDs; giữ enrollment ownership và lịch sử cũ. Đây chỉ là schema proposal, không có migration được tạo/chạy.

## 8. File dự kiến tạo/sửa

`pte-web/apps/tenant-web/features/proctor/components/ProctorAttendanceView.tsx`, `AttendanceRosterTable.tsx`, `AttendanceHistoryModal.tsx`, `AttendanceFilterToolbar.tsx`, `AttendanceSummaryCards.tsx`, `RecordAttendanceModal.tsx`; dự kiến `IdentityVerificationModal.tsx`, `IdentityHistoryModal.tsx`; `features/exams/components/ExamAttendanceTab.tsx`; proctor `api.ts`, `queryKeys.ts`, `messages/{en,vi}.ts`; attendance requests/types thuộc `packages/api-client`. Backend: `proctoring/internal/controller/{ProctorAttendanceController,HostAttendanceController}.java`, `AttendanceCoordinatorService.java`; `session/domain/enums/AttendanceStatus.java`, `SessionAttendance.java`, `SessionAttendanceCommand.java`, `session/internal/service/{AttendanceCommandService,AttendanceQueryService}.java`, public request/response DTO; đề xuất identity domain/query/command/DTO files thuộc Session.

## 9. Dependencies

Phase 1 session picker, common DataTable, existing concurrency/receipt contracts. Phase 4 cần để FAILED có durable report/handoff; identity state không phụ thuộc attendance state. Host correction UI dùng existing role/capability và không mở rộng scope mặc định.

## 10. Functional acceptance criteria

- PRESENT/ABSENT/LATE chỉ do thao tác có quyền; kết nối không tự đổi attendance.
- Identity state, actor/time/note/history độc lập attendance; không lưu ID photos/biometrics hoặc auto verify.
- FAILED có báo cáo/chuyển giao đúng session/student trước khi có attempt và không tự can thiệp bài thi.
- Receipt/conflict/generation bảo vệ cập nhật; draft được giữ khi lỗi, lịch sử không mất khi correction.
- Proctor/Host cùng table presentation nhưng dùng đúng endpoint/policy; Closed correction và Cancelled read-only được giữ.

## Design Constraints

DataTable-first cho mọi roster/history. Không tự thay cửa sổ/cutoff hiện hữu, không suy attendance từ monitoring, không trao quyền Admin blanket. Không nhân bản profile identity, không import module internal khác. Common style/tokens/defaults giữ nguyên, feature flag vẫn tắt.
