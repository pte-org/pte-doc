# Phase 4: Lõi kích hoạt Subscription

## Requirements

`Subscription` = một lần mua gói thi = một "làn" chạy độc lập, mang `licenseKey` riêng. Xây **một** thao tác kích hoạt duy nhất mà cả hai đường mua (Phase 5 PayOS, Phase 6 mã kích hoạt) đều gọi vào.

Maps to: **[ADR-006](../../architecture/ADR-006-commercialization-and-exam-templates.md) §2**, bất biến #3 và #4

## Design Constraints

- **`activate()` là nơi DUY NHẤT trong code sinh ra `Subscription`.** Nếu logic kích hoạt bị nhân đôi giữa hai đường mua thì sớm muộn chúng lệch nhau về `expiresAt`, format `licenseKey`, hoặc cap đã snapshot. Phase 5 và 6 chỉ được gọi vào đây, không được tự `new Subscription()`.
- **Snapshot `maxStudentsPerSession` từ `Plan` tại thời điểm kích hoạt.** Không đọc live. Admin sửa Plan không bao giờ được làm đổi hợp đồng tenant đã mua.
- **`expiresAt` tính từ lúc kích hoạt**, không phải từ lúc tạo Order hay phát mã. Mã phát tháng 1, redeem tháng 6 → gói chạy từ tháng 6.
- `licenseKey` unique toàn cục, dạng người đọc được, **bất biến** theo vòng đời Subscription.
- `STUDENT_CAPACITY` đi nhánh khác hoàn toàn: không sinh Subscription, gọi thẳng `QuotaTransactionService.grant()`.

## Steps

1. Enum `SubscriptionStatus` (`ACTIVE`, `EXPIRED`, `CANCELLED`).

2. Entity `Subscription`: `tenantId`, `planId`, `licenseKey` (unique), `startsAt`, `expiresAt`, `maxStudentsPerSession` (**snapshot**), `status`, `activationSource` (`PAYMENT`/`LICENSE_CODE`).

3. Migration `V17__billing_subscription.sql`, index trên `(tenant_id, status)` — truy vấn "gói nào của tenant này còn dùng được" chạy ở mọi lần tạo kỳ thi.

4. `LicenseKeyGenerator`: `PTE-{PLAN_CODE}-{YYYY}-{6 ký tự}`, phần ngẫu nhiên từ `SecureRandom`, bỏ ký tự dễ nhìn nhầm (`0`/`O`, `1`/`I`/`l`). Trùng thì bắt `DataIntegrityViolationException` rồi sinh lại, giới hạn số lần thử.

5. `SubscriptionActivationService.activate(tenantId, plan, source)`:
   - `plan.type == EXAM_PACKAGE` → tạo `Subscription`: `startsAt = now`, `expiresAt = now + plan.durationDays`, `maxStudentsPerSession = plan.maxStudentsPerSession`, sinh `licenseKey`, `status = ACTIVE`
   - `plan.type == STUDENT_CAPACITY` → **không** tạo Subscription; gọi `TenancyService.grantQuota(tenantId, plan.extraStudentSlots, note)`
   - Trả về một kiểu kết quả chung mô tả cả hai nhánh, để caller không phải rẽ theo loại gói

6. `TenancyService`: thêm `grantQuota(...)` vào facade, uỷ quyền xuống `QuotaTransactionService.grant()` đã có.

7. `BillingService` (facade): phơi ra `getActiveSubscription(licenseKey, tenantId)` và `listActiveSubscriptions(tenantId)` — Phase 11 (`session`) sẽ gọi.

8. Job đánh dấu hết hạn: `Subscription` có `expiresAt < now` và `status = ACTIVE` → `EXPIRED`. Chạy định kỳ. Truy vấn tính hợp lệ **không được** chỉ dựa vào `status` — luôn kiểm cả `expiresAt` để không phụ thuộc job chạy đúng giờ.

9. Controller: `GET /api/subscriptions` (tenant xem gói của mình, kèm `licenseKey`, hạn, cap).

10. Test: kích hoạt `EXAM_PACKAGE` → Subscription có cap **bằng giá trị Plan lúc đó**; sửa Plan xong đọc lại Subscription → cap **không đổi**.

11. Test: kích hoạt `STUDENT_CAPACITY` → không có Subscription nào sinh ra, `tenant.studentLimit` tăng đúng, có một dòng `QuotaTransaction` mới.

12. Test: mua hai lần cùng một Plan → hai Subscription, hai `licenseKey` khác nhau, cả hai `ACTIVE`.

## Success Criteria

- Chỉ có đúng một chỗ trong code khởi tạo `Subscription` — grep `new Subscription(` trả về một kết quả
- Sửa Plan không làm đổi bất kỳ Subscription đã bán nào
- Mua nhiều lần cùng một Plan tạo ra nhiều làn độc lập
- `STUDENT_CAPACITY` không đẻ ra Subscription, chỉ cộng vào ledger
- Gói hết hạn không dùng được kể cả khi job chưa kịp chạy

## Quality and Testing State

- Quality gate: chưa chạy
- Testing: chưa bắt đầu

## Session Notes

_(trống)_
