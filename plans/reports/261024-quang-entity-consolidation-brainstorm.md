# Brainstorm: Tinh gọn mô hình entity của pte-api

**Date:** 2026-10-24

Hiện trạng: 90 JPA entity / 93 bảng (`pte-api/app`, xem
[ERD essential-fields review](261024-quang-erd-essential-fields-review.md)).
Mục tiêu của người dùng: refactor entity cho khớp nghiệp vụ thực tế; không ưu
tiên bàn rủi ro tương thích.

## Ideas Explored

- **Gom theo aggregate (~24 entity nghiệp vụ)** — đề xuất ban đầu từ một agent
  khác: bảng con (option, tiêu chí, lịch sử) là thành phần phụ thuộc; token,
  heartbeat, command, job/outbox, audit là hạ tầng. Được chọn làm khung.
- **Bỏ sao chép nội dung 4 tầng** — `SnapshotItem → PinnedItem → ScoringAnswer`
  + `PracticeSessionItem` cùng mang ~20 cột `runtime*`. Attempt trỏ thẳng vào
  `ExamVersion` bất biến. Đây là điểm cắt có giá trị nhất. Được chọn.
- **Gộp Practice vào ExamAttempt (mode PRACTICE|EXAM)** — loại bỏ: người dùng
  xác định pte-practice là luồng luyện tập riêng, không phải attempt thi.
- **QuestionType thành enum trong code** — loại bỏ: QuestionType phải quản lý
  qua UI. Giữ entity, gom `TaskRuntimeProfile/Contract/PublicationUsage` thành
  cấu hình nhúng.
- **Practice không lưu gì / chỉ lưu kết quả** — loại bỏ: giữ đủ resume, tiến
  độ, review, giải thích AI (pte-practice gọi `sessions/*`, `progress`,
  `review`, `explanation`).
- **Bỏ Program** — loại bỏ: giữ Program.
- **Bỏ LicenseCode, chỉ thanh toán PayOS** — loại bỏ: giữ voucher license code.
- **Mỗi thí sinh một mã đề (ExamForm)** — bỏ tính năng: mỗi ca thi dùng chung
  một `ExamVersion`; xoá `ExamForm`, `FormAssignment`, `ExamGenerationJob`.
- **Tenant nhiều cơ sở (Site)** — loại bỏ: code hiện tại đã cố định
  1 Tenant = 1 Organization (`TenantLifecycleService.addDefaultOrganization`).
  Gộp thành một `Organization`.

## User's Direction

- "Luồng nghiệp vụ của dự án tôi thật sự không cần thiết phải có tới 93 entity."
- Practice: "Giữ đủ như hiện tại" — là trang web cho student luyện tập, không
  lưu exam attempt.
- Giữ: Program, License code. Không giữ: đề riêng từng thí sinh.
- Host muốn thêm tổ chức thứ hai: **tổ chức độc lập, cùng một tài khoản** —
  nộp đơn mới, dữ liệu/gói tách biệt, User có nhiều membership và chọn tổ chức
  khi đăng nhập.
- QuestionType: quản lý qua UI.

Kết quả: **25 entity nghiệp vụ** (24 của đề xuất + `LicenseCode`), có thể là
26 nếu giữ `ScoreTemplate` riêng.

## Open Questions

Đã chốt cùng ngày (chi tiết trong spec, mục Decisions):

- `ScoreTemplate` → gộp: trọng số vào `QuestionType`, số câu/thời gian vào
  `ExamDefinition`. Tổng 25 entity.
- Dữ liệu → reset DB, baseline migration `V1` mới + seed demo.
- API contract → giữ nguyên; chỉ gỡ endpoint của tính năng bị bỏ.

## Risks

- Phạm vi lan sang cả 3 client vì DTO/endpoint thay đổi theo aggregate mới —
  khối lượng lớn hơn phần backend.
- Bộ test hiện tại (576 test) gắn chặt vào entity cũ; phần lớn sẽ phải viết lại.
- Bỏ các bảng command/receipt và hash chain vi phạm làm mất idempotency theo
  request và tính chống sửa log — người dùng đã chấp nhận đánh đổi này.
