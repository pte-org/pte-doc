# Spec: Task phân tích và kiểm thử unhappy cases của Admin

Ngày: 2026-10-05. Trạng thái: Draft — ma trận phân tích đã lập; chưa triển khai test mới hoặc sửa chức năng.

Giải pháp thiết kế cho từng case được bổ sung tại [solutions.md](solutions.md). Đây là đề xuất để lựa chọn, chưa thay đổi policy hoặc phê duyệt triển khai.

Đánh giá bổ sung tại [archive-assessment.md](archive-assessment.md): không mở Archive đại trà; phân biệt retirement, discard draft và soft removal. Đề xuất mở Archive DRAFT plan đã được rút lại.

## Problem Statement

Admin đang vận hành xét duyệt tổ chức, catalog và cấp/thu hồi license code. Task cần phát hiện sai lệch dữ liệu/quyền lợi và bảo đảm admin hiểu đúng kết quả khi validation, mạng, concurrency hoặc dependency thất bại.

## User Stories

- [P1] Là QA, tôi cần case có điều kiện, bước thực hiện, expected và căn cứ code để chuyển thành test case có thể lặp lại.
  Accepted when: cả 45 case trong [ma trận](unhappy-cases.md) có các thông tin này và phân biệt source finding với giả thuyết runtime.
- [P1] Là platform admin, tôi cần không đưa ra hai quyết định trái ngược hoặc cấp/thu hồi quyền lợi sai khi thao tác đồng thời.
  Accepted when: APP-03, PLN-09/10, LIC-04/08/09 được kiểm tra với transaction/commit thật; chỉ một kết quả nghiệp vụ hợp lệ được lưu, hậu quả được hiển thị và kiểm tra DB.
- [P1] Là platform admin, tôi cần biết request thất bại trước hay sau khi lưu để không tạo mã/plan trùng hoặc hiểu sai kết quả approve.
  Accepted when: timeout/hậu commit được kiểm tra bằng fault injection; UI cho đối chiếu trạng thái server trước khi retry mutation.
- [P2] Là platform admin, tôi cần tìm mã cũ và đọc lỗi đúng nguyên nhân để xử lý hỗ trợ khách hàng.
  Accepted when: phân biệt empty/loading/error, truy xuất mã ngoài 100 bản ghi mới nhất theo policy được duyệt, không mất dấu khi conflict.
- [P3] Redesign UI, đổi brand và tối ưu mỹ thuật ngoài phạm vi task này.

## Functional Requirements

1. FR-01: Giữ 45 ID ổn định; case record gồm module, priority, precondition, input/steps, expected, actual, evidence, execution status.
2. FR-02: Kết quả test dùng `Not run / Passed / Failed / Blocked`; không gắn Passed chỉ vì đọc thấy nhánh xử lý.
3. FR-03: Test validation qua cả UI và HTTP controller khi có khác biệt; ghi chính xác HTTP/error code thực tế, không mặc định mọi validation là 422.
4. FR-04: Test review/plan/redeem/revoke concurrency bằng ít nhất hai request độc lập cùng tài nguyên, đồng bộ điểm bắt đầu và kiểm tra DB sau commit.
5. FR-05: Test lỗi tải, lỗi mutation, 401/403, stale cache, timeout trước/sau commit bằng fixture/fault injection, không dùng tài khoản hoặc token thật trong báo cáo.
6. FR-06: Test archive/edit plan trên mã ISSUED và subscription đã tồn tại riêng biệt; xác nhận policy quyền lợi đã được chủ sản phẩm duyệt.
7. FR-07: Test revoke trên ISSUED, REDEEMED có subscription, capacity code nếu được hỗ trợ, REVOKED, EXPIRED; xác nhận tác động session SCHEDULED và không hủy OPEN/CLOSED theo nghiệp vụ hiện tại.
8. FR-08: Test onboarding email qua từng mốc commit, enqueue, worker, mail transport; không dùng API success hoặc SENT làm bằng chứng inbox delivery.
9. FR-09: Chỉ mở bug ticket khi actual khác expected đã chốt; câu hỏi nghiệp vụ và rủi ro chưa tái hiện là backlog xác minh, không phải bug confirmed.

## Non-Functional Requirements

- Security: 0 mutation production trong task kiểm thử nếu chưa được cho phép; 0 credentials/raw bearer tokens thật trong artifact hoặc log test.
- Repeatability: fixture độc lập giữa các case; teardown không xóa dữ liệu người dùng; tối thiểu 10 lần lặp cho mỗi race case, không coi 10 lần pass là chứng minh tuyệt đối.
- Observability: mỗi test transaction quan trọng lưu HTTP result và trạng thái persisted sau commit; kiểm tra rollback không để tenant/user/subscription/quota mồ côi.
- Performance: chưa đặt SLO latency; task này kiểm thử đúng trạng thái và phục hồi, không giả định số liệu production.

## Success Criteria

- [x] Có ma trận 45 case với nguồn traceable và ưu tiên.
- [x] Chạy 3 suite hiện có: 27 tests, 0 failure/error/skipped ngày 2026-10-05.
- [ ] Thực thi mọi case P1 sau khi chuẩn bị môi trường test và chốt policy liên quan; actual + evidence có cho 100% case đã chạy.
- [ ] Race tests kiểm tra trạng thái sau commit, không chỉ Mockito invocation.
- [ ] Mọi bug confirmed có bước tái hiện; mọi policy chưa chốt được tách khỏi kết luận bug.

## Out of Scope

- Sửa implementation, tạo mockup, triển khai test mới, commit/push/deploy.
- Gọi approval/revoke/redeem vào production hoặc phát mã thật.
- Audit toàn bộ billing/payment/tenant: chỉ trace các tác động trực tiếp của ba màn admin.

## Assumptions

- `vendor-web` là ứng dụng admin; role thao tác là PLATFORM_ADMIN. Email giống nhau ở các tenant khác nhau không mặc định là lỗi vì identity có tenant scope.
- Ưu tiên P1/P2/P3 trong ma trận là đề xuất kiểm thử, không phải mức độ bug đã được xác nhận.
- API/code hiện tại là căn cứ hành vi; tài liệu phase cũ là ý định nghiệp vụ, không phải chứng minh implementation.

## [NEEDS CLARIFICATION]

- [ ] Policy quyền lợi mã lúc phát/lúc redeem và archive/đổi family plan có mã đang lưu hành.
- [ ] Capacity license có thuộc phạm vi sản phẩm không, và revoke quota đã cấp xử lý thế nào.
- [ ] Cơ chế admin phục hồi khi onboarding credentials email lỗi sau approval commit.
