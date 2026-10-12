# Examiner Workspace Completion — spec

Status: business decisions confirmed; implementation plan reviewed. Source: yêu cầu đính kèm và Q1–Q4 đã trả lời ngày 2026-10-12, cùng quyết định AI là tham khảo, Examiner quyết định điểm cuối cùng, Host công bố.

## Scope challenge

Exists: có module Examiner hoạt động, phân công nguyên attempt cho một người; điểm cuối cùng từng câu bất biến; overview/queue/detail có sẵn. Minimum: mở rộng module hiện tại và tách trách nhiệm màn hình, không xây hệ thống chấm khác. Complexity: Hard, 5 phase, database/API/security/concurrency, dữ liệu điểm hiện hữu cần giữ nguyên.

Yêu cầu mới đã chia 5 phase trong attachment nên giữ cùng phạm vi. Brainstorm Examiner trước đó là nền tảng; các yêu cầu mới về start/draft/finalize/issues được kiểm kê và chờ quyết định cụ thể, không coi là đã được duyệt.

## Stories và acceptance criteria

| ID | Priority | Story | Acceptance |
|---|---|---|---|
| E01 | P1 | Examiner có overview riêng và ba danh sách riêng | `/examiner/work` không có full queue; mỗi status chỉ hiện đúng trạng thái; thống kê/priority card dẫn đúng URL, một sidebar active |
| E02 | P1 | Bắt đầu chấm có chủ đích | GET detail không đổi trạng thái; explicit start thành công mới chuyển Pending→In Progress; retry không tạo lịch sử trùng |
| E03 | P1 | Nháp được lưu và tiếp tục sau reload | Server lưu score/comment/decision/version; chỉ Saved sau ACK; reload restore; tab cũ không ghi đè tab mới; lỗi không mất input |
| E04 | P1 | Chấm có hỗ trợ AI | Confirm AI yêu cầu AI version hợp lệ; manual giữ thang 0–100, không đổi normalization/aggregation; AI missing/error không giả điểm0 |
| E05 | P1 | Chốt an toàn | Validate đủ câu theo pinned eligibility; bảo toàn điểm cũ; xác nhận trước chốt; đúng owner/cohort/publication; double-click/exact retry idempotent; Completed read-only |
| E06 | P1 | Quyền và dữ liệu cũ được bảo vệ | Tenant/active role/assignment checked backend; không lộ student PII/điểm người khác; Host publication không chạy trước completion; không sửa điểm immutable đã lưu |
| E07 | P1 | Trạng thái tải/lỗi trung thực | Loading không hiển thị0; empty chỉ từ successful response; refreshing có dữ liệu cũ + cảnh báo nếu fail; retry đúng nguồn; 401/403/409 có handling riêng |
| E08 | P2 | Tra cứu lịch sử và hướng dẫn thực tế | Paginated own grading audit; guidelines lấy pinned scoring rules hiện có và ghi rõ giới hạn; menu chỉ xuất hiện khi route/API thực sự có |
| E09 | P2 | Báo vấn đề có truy vết | Audio/media/data issue theo quyền; ghi type/description/actor/time/status; unresolved blocking issue chặn finalize nếu workflow mới được chọn; reopen không tự thêm |
| E10 | P2 | Queue có search/sort hữu ích | Search safe attempt/session ID; server filter trước paging, sort whitelist stable; task filter chỉ khi contract hỗ trợ; không dùng tên sinh viên cho blind grading |
| E11 | P1 | Kiểm tra regression | Test start/draft/reload/finalize/idempotency/IDOR/Host publish; scoped unit/integration + lint/typecheck/build, báo thật mọi giới hạn |

## Quyết định đã có

- Giữ tenant web, role-separated routes và backend authorization.
- AI score chỉ tham khảo; Examiner có thể dùng AI hoặc quyết định điểm manual. Host công bố kết quả.
- Tái sử dụng @pte/ui, theme/layout/responsive và locale catalog. Routes mỏng, hooks trong feature api.ts, request/types trong @pte/api-client.
- Không có deadline Examiner trong schema đã đọc: không tạo thông báo sắp quá hạn, không suy deadline từ session closesAt.
- Một Examiner/attempt hiện tại: không mở multi-rater hay assignment theo câu/phần nếu chưa có thiết kế riêng.
- Yêu cầu test trong attachment mới thay thế lựa chọn bỏ test ở feature trước. Không tự bật TDD/ck:quality; các check bắt buộc của attachment được lập kế hoạch.

## Quyết định đã xác nhận Q1–Q4

Q1: durable draft độc lập từng câu + atomic finalize phạm vi được phân công; tất cả câu bắt buộc hoàn thành, màn hình tổng hợp và xác nhận trước chốt. Sau chốt read-only. Giữ toàn bộ điểm cũ, không tự tính lại/ghi đè. Scope phải lấy backend assignment, không mặc định mọi câu của student attempt. Model hiện hữu một Examiner/nguyên attempt được giữ; nhiều Examiner trên các assignment khác nhau và nhiều tab phải an toàn. Nếu mở partial/multi-rater assignment sau này cần thiết kế schema/ownership riêng, không tự thay unique constraints hiện tại. Sửa final scores chỉ qua Reopen phân quyền/audit trong một tính năng tương lai, không có đường sửa tắt ở lần này.

Q2: giữ scalar 0–100 và scoring rules hiện có. Không có rubric registry Examiner hiện tại; không tự tạo tiêu chí/thang0–5/công thức mới.

Q3: Completed và History giữ bài đã chốt kể cả sau Host publication; Overview đếm cùng phạm vi. Pending/In Progress vẫn chỉ công việc còn được phép làm; published detail chỉ đọc, không bỏ write guard. Contract list/counts/progress thống nhất; priority chỉ lấy công việc cần xử lý.

Q4: thêm issue reporting/history và Host xử lý; chưa implement Reopen hoặc Review Requests. Blocking issue phải được giải quyết trước finalize; không thay score/publication khi resolve. Examiner không được gọi HostSupportTicketController hoặc đọc tenant-wide audit.

## Spec quality check

Stories có priority, acceptance có điều kiện kiểm chứng. **PASS về các quyết định Q1–Q4**, đã được người dùng xác nhận. Plan cần hoàn tất red-team review trước implementation. Không còn nhánh tùy chọn về finalize/rubric/publication/issues.

## Definition of done

E01–E07/E11 đạt checks thật; E08–E10 theo lựa chọn đã xác nhận. Có migration additive/compatibility inventory/rollback strategy không mất điểm. Có report file/API/schema/test/limits/manual verification; không tuyên bố completed chỉ từ compile.
