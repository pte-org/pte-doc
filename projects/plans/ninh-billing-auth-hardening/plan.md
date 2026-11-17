# Plan: Không kẹt đơn khi PayOS lỗi, không mất tiền khi gói bị lưu trữ, mật khẩu quá dài báo lỗi rõ ràng

Status: Ready
Date: 2026-11-15
Mode: Fast
Test: default
Owner/slug: Ninh — `ninh-billing-auth-hardening`
Scope: `pte-api` (`billing`, `identity`), `pte-doc`
Related: [ninh-staff-audit-roster-fixes](../ninh-staff-audit-roster-fixes/plan.md)

## Mục tiêu

Ba điểm đã đối chiếu từ lần rà soát billing và đăng nhập:

1. `OrderService.createOrder` lưu đơn PENDING (transaction riêng) rồi mới gọi PayOS. Nếu tạo link lỗi, đơn mồ côi còn PENDING,
   chặn mua lại gói (`ORDER_PENDING_EXISTS`) và job hết hạn giữ nguyên vì lệnh hủy link tới PayOS cho đơn PayOS chưa từng thấy
   rất có thể thất bại.
2. Webhook PayOS đã xác thực chữ ký nhưng gói đã bị lưu trữ hoặc xóa sau khi tạo đơn: `activate` ném lỗi, cả transaction rollback
   (mất luôn biên nhận); khách đã trả tiền mà không có gói và không có dấu vết, PayOS chỉ thử lại rồi bỏ.
3. Mật khẩu dài hơn 72 byte UTF-8: `BCryptPasswordEncoder.encode` ném `IllegalArgumentException`, thành lỗi 500 ở đổi mật khẩu, đặt lại
   mật khẩu và tạo tài khoản. Mật khẩu tiếng Việt có dấu chạm giới hạn sớm hơn (khoảng 25 đến 36 ký tự).

Không làm: phát hiện tái sử dụng refresh token (hướng tăng cường bảo mật, chưa chốt thiết kế).

## Scope challenge

### Đã có gì?

- `Order.cancel()` và `Order.expire()` chỉ đổi trạng thái khi đang PENDING; `OrderPersistenceService` đã có các transaction `REQUIRES_NEW` cho vòng đời đơn.
- `PayOsClient.cancelPaymentLink` và `OrderExpirationService` (cron mỗi giờ, hạn 24 giờ).
- Biên nhận `OrderPayment` có cờ `processed`; webhook chỉ gọi `markProcessed()` khi đã áp dụng xong.
- Các DTO mật khẩu dùng chung `IdentityConstants.PASSWORD_MIN_LENGTH` và `@Size(min = 8)`.

### Tối thiểu là gì?

- Bù trừ khi tạo link lỗi: hủy link ở PayOS (cố gắng hết sức) rồi hủy đơn cục bộ; job hết hạn bỏ qua bước PayOS cho đơn chưa có link.
- Webhook: nhánh "gói không còn dùng được" vẫn đánh dấu đơn PAID, giữ biên nhận chưa xử lý, ghi `error` để đối soát, và trả 200.
- Một ràng buộc `@MaxUtf8Bytes` dùng cho 5 DTO mật khẩu.

### Độ phức tạp

Fast. Phase 1 và 2 chạm tiền nên test bằng Mockito kỹ; không chạy được test tích hợp Postgres (đang bị bỏ qua).

## Rủi ro đã biết

- Phase 1: nếu PayOS đã tạo link nhưng phản hồi bị mất, và lệnh hủy ngay sau đó cũng lỗi, link vẫn sống. Thanh toán muộn vào đơn đã hủy sẽ đi vào nhánh "đơn không còn PENDING"
  (được ghi `warn` ở phase 2) để đối soát.
- Phase 2: đơn PAID mà chưa có gói là trạng thái mới cần người đối soát; biên nhận chưa `processed` là dấu hiệu để truy vấn.

## Phases

- [x] Phase 1: Bù trừ khi tạo link thanh toán lỗi — [phase-01-order-link-failure.md](./phase-01-order-link-failure.md)
- [x] Phase 2: Đơn đã trả tiền nhưng gói không còn dùng được — [phase-02-paid-inactive-plan.md](./phase-02-paid-inactive-plan.md)
- [x] Phase 3: Giới hạn 72 byte cho mật khẩu — [phase-03-password-bytes.md](./phase-03-password-bytes.md)

## Kết quả thực hiện (2026-11-15)

- Phase 1: `OrderPersistenceService.cancelIfPending` (`REQUIRES_NEW`). `OrderService.createOrder` bọc `createPaymentLink` và `attachPaymentLink`:
  khi lỗi, cố hủy link ở PayOS (bỏ qua lỗi của lệnh hủy), hủy đơn cục bộ, rồi ném lại đúng lỗi gốc. `OrderExpirationService` bỏ qua lệnh hủy PayOS
  với đơn chưa có link nên cũng dọn được các đơn mồ côi đã kẹt từ trước. 4 test mới (2 ở `OrderServiceTest`, 1 ở `OrderPersistenceServiceTest`,
  1 ở `OrderExpirationServiceTest`); hai test hết hạn cũ phải gắn link cho đơn vì giờ đơn không link không gọi PayOS.
- Phase 2: `PayOsWebhookService`: gói không còn, bị xóa, không `ACTIVE`, hoặc kích hoạt bị từ chối với lỗi 4xx thì đơn được đánh dấu PAID,
  biên nhận giữ ở trạng thái chưa xử lý, ghi `error`, webhook trả thành công, không công bố sự kiện thương mại. Lỗi 5xx vẫn rollback để PayOS thử lại.
  Thêm `warn` cho thanh toán muộn vào đơn đã hết hạn hoặc bị hủy. 4 test mới.
- Phase 3: `@MaxUtf8Bytes(72)` (validator + `IdentityConstants.PASSWORD_MAX_BYTES`, `PASSWORD_TOO_LONG`) gắn vào 5 DTO mật khẩu. 5 test mới, gồm một test
  khẳng định mọi mật khẩu validator chấp nhận đều băm được bằng BCrypt (24 ký tự tiếng Việt 3 byte đúng 72 byte).

Kiểm chứng: 487 test của `billing` và `identity` qua (24 bỏ qua sẵn có, đa số là test Postgres), kèm `ModuleStructureTest`.

Chưa làm: rebuild container; kiểm chứng hành vi thật của PayOS khi hủy đơn chưa từng được tạo; test tích hợp Postgres (đang bị bỏ qua); commit.
Đơn đã kẹt PENDING từ trước sẽ được job hết hạn dọn sau hạn 24 giờ. Đơn PAID mà chưa có gói là trạng thái cần người đối soát;
truy vấn: biên nhận `processed = false` của đơn `PAID`. Phát hiện tái sử dụng refresh token không nằm trong phạm vi.

