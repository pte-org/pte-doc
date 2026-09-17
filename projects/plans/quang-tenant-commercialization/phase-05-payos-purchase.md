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

- Preflight: Billing giữ entity/repository/service/controller nội bộ và response DTO riêng; PayOS được cô lập trong `internal/vendor/payos`. Order giữ snapshot amount/currency, dùng sequence riêng cho `orderCode`, partial unique index chống pending trùng và pessimistic lock để webhook idempotent. Webhook `/api/webhooks/payos` được permit công khai nhưng vẫn đi qua rate-limit filter; payload/signature và amount/currency từ PayOS đều được validate trước khi kích hoạt. Luồng tạo order reserve DB trước rồi mới gọi PayOS, sau đó cập nhật payment link trong transaction ngắn; job hết hạn chỉ chuyển order sau khi huỷ link thành công.

## Files

- `app/src/main/java/com/pte/billing/domain/Order.java`
- `app/src/main/java/com/pte/billing/domain/PaymentTransaction.java`
- `app/src/main/java/com/pte/billing/domain/enums/OrderStatus.java`
- `app/src/main/java/com/pte/billing/internal/controller/OrderController.java`
- `app/src/main/java/com/pte/billing/internal/controller/PayOsWebhookController.java`
- `app/src/main/java/com/pte/billing/internal/dto/request/CreateOrderRequest.java`
- `app/src/main/java/com/pte/billing/internal/dto/response/OrderResponse.java`
- `app/src/main/java/com/pte/billing/internal/exception/OrderException.java`
- `app/src/main/java/com/pte/billing/internal/exception/PayOsException.java`
- `app/src/main/java/com/pte/billing/internal/exception/PaymentWebhookException.java`
- `app/src/main/java/com/pte/billing/internal/repository/OrderRepository.java`
- `app/src/main/java/com/pte/billing/internal/repository/PaymentTransactionRepository.java`
- `app/src/main/java/com/pte/billing/internal/service/OrderExpirationService.java`
- `app/src/main/java/com/pte/billing/internal/service/OrderPersistenceService.java`
- `app/src/main/java/com/pte/billing/internal/service/OrderService.java`
- `app/src/main/java/com/pte/billing/internal/service/PayOsWebhookService.java`
- `app/src/main/java/com/pte/billing/internal/service/PaymentTransactionPersistenceService.java`
- `app/src/main/java/com/pte/billing/internal/vendor/payos/PayOsClient.java`
- `app/src/main/java/com/pte/billing/internal/vendor/payos/PayOsConfig.java`
- `app/src/main/java/com/pte/billing/internal/vendor/payos/PayOsProperties.java`
- `app/src/main/java/com/pte/billing/internal/constant/BillingConstants.java`
- `app/src/main/java/com/pte/identity/internal/config/SecurityConfig.java`
- `app/src/main/resources/application.yml`
- `app/src/main/resources/db/migration/V18__billing_order_payment.sql`
- `.env.example`

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

- Decision checkpoint: unit tests = no (user confirmed skip); quality gate = yes (user confirmed).
- Testing decision: skipped_by_user (not_started; user confirmed no).
- Quality decision: user confirmed yes; gate completed.
- Quality result: **APPROVED**, 0 blocking/advisory/noted findings. Report: `quality/phase-05-payos-purchase-quality-report.json`. Cryptographic receipt skipped because this report is in `pte-doc` while source files are in the separate `pte-api` repository.
- Testing result: skipped by user, not started, per checkpoint decision.

- Quality gate: **approved**, report and user decision are recorded above.
- Testing: **skipped_by_user**, not started, because the user selected no.

## Session Notes

- Implemented order reservation/payment-link flow, PayOS REST/HMAC adapter, public webhook verification, idempotent order locking, append-only transaction audit, and stale-order cancellation job.
- PayOS signature construction was checked against the current official API and webhook-signature documentation; the implementation signs the documented five create-link fields and sorts webhook `data` keys alphabetically.
- `.\mvnw.cmd -pl app -DskipTests compile` passed. Unit tests were intentionally not run because the user selected no. Runtime Flyway/PostgreSQL and PayOS integration remain unverified while Docker/credentials are unavailable.
