# Phase 6: Mã kích hoạt (đường B)

## Requirements

Admin nền tảng phát hành mã kích hoạt cho một `Plan`. Tenant nhập mã → gọi `activate()` của Phase 4. Admin thu hồi mã đã redeem → huỷ luôn Subscription sinh ra từ nó.

Maps to: **[ADR-006](../../architecture/ADR-006-commercialization-and-exam-templates.md) §7, §8**

## Design Constraints

- **Redeem phải atomic.** Hai request cùng nhập một mã thì chỉ một được ăn. Dùng `UPDATE ... WHERE code = ? AND status = 'ISSUED'` rồi kiểm số hàng bị ảnh hưởng — **không đọc-rồi-ghi**, vì đọc-rồi-ghi chính là chỗ sinh ra hai Subscription từ một mã.
- **Mã là bearer token trên thực tế.** Ai cầm mã thì kích hoạt được. Sinh bằng `SecureRandom`, đủ dài để không brute-force, và **rate-limit endpoint redeem** — nếu không thì quét mã hợp lệ là chuyện khả thi.
- **Hạn của mã ≠ hạn của gói.** `codeExpiresAt` là hạn phải redeem; `Subscription.expiresAt` tính từ lúc redeem (Phase 4 đã lo).
- **Phát lẻ từng mã. Không làm bán theo lô** — ngoài phạm vi, thêm sau nếu cần.
- Không tự `new Subscription()` — chỉ gọi `activate()`.
- `REVOKED` một mã đã redeem → huỷ Subscription sinh ra từ nó. **Không kèm chuyển tiền** — hoàn tiền không làm ở plan này.

## Steps

1. Enum `LicenseCodeStatus` (`ISSUED`, `REDEEMED`, `REVOKED`, `EXPIRED`).

2. Entity `LicenseCode`: `code` (unique), `planId`, `status`, `issuedBy`, `issuedAt`, `codeExpiresAt`, `redeemedByTenantId`, `redeemedAt`, `subscriptionId` (null tới khi redeem), `revokeReason`.

3. Migration `V25__billing_license_code.sql`, index trên `code`.

4. `LicenseCodeGenerator`: chuỗi từ `SecureRandom`, tối thiểu 16 ký tự hữu ích, bỏ ký tự dễ nhìn nhầm, chia nhóm bằng dấu gạch cho dễ đọc/gõ.

5. `LicenseCodeService.issue(planPublicId, codeExpiresAt, caller)` — `PLATFORM_ADMIN`. Chỉ phát cho Plan `ACTIVE`.

6. `LicenseCodeService.redeem(code, caller)`:
   - Câu lệnh atomic trước tiên:
     ```java
     int updated = repo.markRedeemed(code, tenantId, now);  // UPDATE ... WHERE code=? AND status='ISSUED' AND (code_expires_at IS NULL OR code_expires_at > now)
     if (updated != 1) throw new LicenseCodeNotRedeemableException();
     ```
   - Chỉ khi `updated == 1` mới gọi `activate()`, rồi gán `subscriptionId` ngược lại cho `LicenseCode`
   - Toàn bộ trong một transaction

7. `LicenseCodeService.revoke(code, reason, caller)` — `PLATFORM_ADMIN`:
   - `ISSUED` → `REVOKED`, xong
   - `REDEEMED` → `REVOKED` **và** `Subscription.status = CANCELLED`
   - Huỷ Subscription kéo theo xử lý kỳ thi: kỳ thi `SCHEDULED` trên làn đó bị huỷ + phát thông báo cho tenant; kỳ thi `OPEN`/`CLOSED` **không đụng vào**. Phần này cần `session` phơi ra một thao tác — nếu Phase 11 chưa xong thì để `TODO` có test đánh dấu, không làm im lặng

8. Job đánh dấu `ISSUED` quá `codeExpiresAt` → `EXPIRED`. Điều kiện redeem vẫn kiểm cả `codeExpiresAt`, không phụ thuộc job.

9. Rate limit riêng cho `POST /api/license-codes/redeem`, chặt hơn mặc định.

10. Controller: `/api/admin/license-codes` (issue, list, revoke — `PLATFORM_ADMIN`), `POST /api/license-codes/redeem` (`HOST_ADMIN`).

11. Test đồng thời: hai luồng redeem cùng một mã → đúng một thành công, đúng một Subscription.

12. Test: redeem mã đã `REVOKED` / đã `REDEEMED` / quá hạn → đều bị từ chối với thông báo phân biệt được.

13. Test: mã phát hôm nay với `durationDays = 30`, redeem sau 60 ngày (giả lập thời gian) → `Subscription.expiresAt` = ngày redeem + 30, **không** phải ngày phát + 30.

14. Test: `activate()` qua đường mã và qua đường PayOS sinh ra Subscription **giống hệt nhau** về format `licenseKey`, cách tính `expiresAt`, cap đã snapshot.

## Success Criteria

- Một mã chỉ dùng được đúng một lần, kể cả khi bị nhập đồng thời
- Endpoint redeem có rate limit chặt
- Thu hồi mã đã dùng huỷ đúng Subscription tương ứng, không đụng kỳ thi đã diễn ra
- Hai đường mua cho kết quả không phân biệt được
- Không có `new Subscription(` trong module này

## Quality and Testing State

- Quality gate: chưa chạy
- Testing: chưa bắt đầu

## Session Notes

_(trống)_
