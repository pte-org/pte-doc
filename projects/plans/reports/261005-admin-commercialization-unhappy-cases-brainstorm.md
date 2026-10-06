# Brainstorm: Unhappy cases của Admin commercialization

Ngày: 2026-10-05. Phạm vi: Applications, Plan catalog, License codes trong `vendor-web` và backend monolith hiện tại.

## Hướng người dùng yêu cầu

Tìm trong code và dự đoán unhappy cases sát ngữ cảnh dự án để phục vụ task phân tích/kiểm thử. Không thiết kế lại UI, không sửa chức năng, không thao tác dữ liệu production.

## Các hướng đã khảo sát

1. Validation và biên dữ liệu: thiếu trường, chuỗi quá dài, số âm/overflow, hai loại plan có trường loại trừ nhau.
2. Vòng đời nghiệp vụ: application đã được review, plan archived, mã hết hạn/redeemed/revoked.
3. Liên thông: approve → tenant/user/email; plan → mã → subscription/quota; revoke → subscription → exam sessions.
4. Đồng thời: hai admin review, update/archive cùng plan, hai tenant redeem, revoke đua với redeem.
5. Khả năng phục hồi UI: lỗi tải, cache cũ, timeout không biết server đã commit, lỗi mutation tồn dư, đóng modal khi đang lưu.
6. Vận hành: SMTP/RabbitMQ hỏng, giới hạn danh sách 100 mã, truy vết người nhận/quyết định, bảo vệ bearer token.

Chỉ kiểm thử UI sẽ bỏ sót transaction và race. Chỉ gọi API sẽ bỏ sót trạng thái lỗi/khả năng phục hồi của admin. Hướng đề xuất là ma trận UI + API + integration/concurrency; ưu tiên rủi ro quyền truy cập và entitlement trước mỹ thuật.

## Kết quả nổi bật

- APP-01: Detail không đọc `isError`; lỗi tải danh sách có thể bị diễn giải thành application không tồn tại.
- APP-03: Approve và reject không khóa chéo ở UI; backend đọc PENDING không có khóa/version. Kết quả race cần tái hiện trên PostgreSQL, chưa kết luận đã xảy ra.
- APP-04: Reject reason không có giới hạn ở DTO/UI nhưng DB giới hạn 500 ký tự.
- APP-07: Approve không đồng nghĩa email đã đến inbox. Email được dispatch sau commit, UI lại báo credentials đã gửi.
- PLN-09 / LIC-06: Archive plan có thể khiến mã đã phát chưa redeem nhận conflict; mã lưu plan ID, không snapshot cấu hình lúc phát.
- PLN-10 / LIC-07: Sửa ACTIVE plan có thể đổi quyền lợi mã chưa redeem; đổi cả family còn có thể biến exam access thành quota.
- LIC-05: API cho revoke mã REDEEMED nhưng UI chỉ hiện action khi ISSUED.
- LIC-09: Hủy session sau revoke chạy qua AFTER_COMMIT listener, dịch vụ đích chỉ dùng REQUIRED. Cần test commit thực, cả lỗi listener và khả năng persistence; không suy từ unit test sang hiệu lực DB.
- LIC-10: API chỉ trả 100 mã mới nhất, UI chưa có phân trang/tìm mã cũ.

## Tài liệu bàn giao

- [Ma trận 45 unhappy cases](../quang-admin-commercialization-unhappy-cases/unhappy-cases.md): 12 APP, 12 PLN, 15 LIC, 6 COM; có nguồn, cách test, expected và trạng thái bằng chứng.
- [Spec của task kiểm thử](../quang-admin-commercialization-unhappy-cases/spec.md): acceptance criteria và các quyết định nghiệp vụ còn mở.
- [Giải pháp cho 45 case](../quang-admin-commercialization-unhappy-cases/solutions.md): phương án UI/backend, acceptance, trade-off snapshot/transaction/delivery và thứ tự triển khai đề xuất; chưa phê duyệt sửa code.

## Câu hỏi mở

1. Mã đã phát phải giữ cấu hình lúc phát hay dùng plan hiện tại? Có được archive/đổi family khi còn mã ISSUED?
2. License code có chủ ý chỉ phục vụ EXAM_PACKAGE? Nếu capacity code được phép thì revoke có hoàn quota hay chỉ thu hồi token?
3. Khi approve đã commit nhưng email lỗi, admin phục hồi qua gửi lại/reset credentials bằng cơ chế nào?

## Rủi ro chính

1. Quyết định review và trạng thái application có thể không nhất quán với tenant/user/email khi race hoặc lỗi hậu commit.
2. Thay đổi catalog ảnh hưởng người đang giữ mã nhưng admin không thấy cảnh báo phụ thuộc.
3. Revoke trả thành công nhưng tác động lên session/email chưa được kiểm chứng bằng integration test có commit thật.

## Phạm vi xác minh

Đã đọc UI → hooks → API client → controller/DTO → service/repository/entity/migration, cùng notification, identity, session liên quan. Code hiện tại được ưu tiên hơn các phase plan cũ: approval không trả password cho admin, thông tin đăng nhập đi qua email.

Chạy tại `pte-api`:

```powershell
.\mvnw.cmd -pl app '-Dtest=TenantApplicationServiceTest,PlanServiceTest,LicenseCodeServiceTest' test
```

Kết quả: BUILD SUCCESS; 27 tests, 0 failures, 0 errors, 0 skipped (Application 11, Plan 7, License 9). Đây là unit tests với dependencies mock, không phải browser E2E, PostgreSQL concurrency hay xác nhận email đến inbox. Không chạy các case mới trên runtime, không sửa source, không commit/push/deploy.
