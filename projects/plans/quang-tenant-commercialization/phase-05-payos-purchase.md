# Phase 5: Mua gói qua PayOS (đường A)

## Requirements

Tenant chọn gói → tạo `Order` → nhận payment link PayOS → thanh toán → webhook xác nhận → gọi `activate()` của Phase 4.

Maps to: **[ADR-006](../../architecture/ADR-006-commercialization-and-exam-templates.md) §7**, bất biến #5

## Design Constraints

- **Webhook là nguồn sự thật, không phải `returnUrl`.** Người dùng đóng tab sau khi trả tiền là trường hợp bình thường, không phải lỗi. Kích hoạt Subscription nằm ở webhook handler.
- **Webhook phải idempotent.** PayOS retry. Xử lý hai lần không được tạo hai Subscription.
- **`orderCode` của PayOS là số nguyên (long), unique toàn merchant** — không tái dùng được `BaseEntity.publicId` (UUID). Cần sequence riêng.
- **PayOS chưa có SDK Java chính thức** (chỉ Node/PHP/Python/Go) → gọi REST trực tiếp, tự implement phần ký. **Thuật toán ký HMAC phải đối chiếu docs PayOS khi làm — không viết theo trí nhớ, không suy từ ví dụ của cổng khác.**
- Không tự `new Subscription()` — chỉ gọi `SubscriptionActivationService.activate()`.
- Secret PayOS (`clientId`, `apiKey`, `checksumKey`) đọc từ biến môi trường, **không** commit vào repo, thêm vào `.env.example` dạng rỗng.

## Steps

1. Enum `OrderStatus` (`PENDING`, `PAID`, `CANCELLED`, `EXPIRED`).

2. Entity `Order`: `tenantId`, `planId`, `orderCode` (bigint, unique), `amount`, `currency`, `status`, `paymentLinkUrl`, `paidAt`.

3. Entity `PaymentTransaction`: append-only, **không sửa sau khi tạo**. `orderCode`, `rawPayload`, `signatureValid`, `receivedAt`, `processed`.

4. Migration `V18__billing_order_payment.sql` + sequence `order_code_seq` (bắt đầu từ một số đủ lớn để không đụng dải test của PayOS).

5. `PayOsProperties` (`@ConfigurationProperties`): `clientId`, `apiKey`, `checksumKey`, `returnUrl`, `cancelUrl`, `baseUrl`. Validate có mặt lúc khởi động — thiếu secret phải nổ lúc start, không phải lúc tenant bấm mua.

6. `PayOsClient` (`billing/internal/vendor/payos/`):
   - `createPaymentLink(order)` — POST tới PayOS, ký payload theo docs
   - `verifyWebhookSignature(payload, signature)` — HMAC bằng `checksumKey`
   - `cancelPaymentLink(orderCode)` — dùng ở Phase 6/13 và luồng huỷ đơn
   - Timeout rõ ràng (connect/read), không để mặc định vô hạn

7. `OrderService.createOrder(tenantId, planPublicId)`:
   - Chặn tạo Order mới khi tenant còn Order `PENDING` cho **cùng** Plan — tránh mua trùng do bấm hai lần
   - Lấy `orderCode` từ sequence, gọi `PayOsClient.createPaymentLink`, lưu `paymentLinkUrl`, trả về cho FE

8. `PayOsWebhookController` — endpoint **công khai** (PayOS gọi từ ngoài):
   - Verify chữ ký **trước tiên**; sai → 400, ghi `PaymentTransaction` với `signatureValid = false` rồi dừng
   - Ghi `PaymentTransaction` trước khi xử lý
   - Idempotent: nếu `Order` đã `PAID` thì trả 200 và không làm gì thêm
   - `Order` → `PAID`, gọi `SubscriptionActivationService.activate(tenantId, plan, PAYMENT)`
   - Tất cả trong một transaction

9. Endpoint webhook **không** nằm sau JWT filter — thêm vào danh sách bỏ qua của `SecurityConfig`, nhưng **có** rate limit.

10. Job dọn `Order` `PENDING` quá hạn (ví dụ 24h) → `EXPIRED` + gọi `cancelPaymentLink`.

11. Controller: `POST /api/orders` (tenant), `GET /api/orders` (lịch sử của tenant).

12. Test: giả lập webhook hợp lệ → Subscription sinh ra đúng một cái. Gửi lại **cùng** payload → vẫn đúng một cái.

13. Test: webhook sai chữ ký → 400, không Subscription nào sinh ra, có dòng `PaymentTransaction` ghi `signatureValid = false`.

14. Test: `Order` `PENDING` quá hạn → `EXPIRED`, không kích hoạt được nữa.

## Success Criteria

- Trả tiền xong mà đóng tab vẫn nhận được gói
- Webhook chạy hai lần chỉ sinh một Subscription
- Webhook giả mạo bị chặn ở bước verify chữ ký và để lại dấu vết
- Không secret PayOS nào nằm trong repo
- App không khởi động được nếu thiếu cấu hình PayOS
- Không có `new Subscription(` nào trong module này

## Quality and Testing State

- Quality gate: chưa chạy
- Testing: chưa bắt đầu

## Session Notes

_(trống)_
