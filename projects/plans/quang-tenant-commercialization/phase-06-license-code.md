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

- Preflight: license-code state changes stay in billing-owned entities and repositories; the redeem path uses a single conditional update before calling the public `SubscriptionActivationService`, while revoke uses a transactional domain update and only cancels the linked subscription. Controllers enforce `PLATFORM_ADMIN`/`HOST_ADMIN`; all user-facing codes live in `BillingConstants`; the redeem route remains behind the existing rate-limit filter. No session mutation is added before Phase 11, so scheduled/open/closed exam handling remains an explicit TODO.

## Files

- `pte-api/app/src/main/java/com/pte/billing/domain/LicenseCode.java`
- `pte-api/app/src/main/java/com/pte/billing/domain/enums/LicenseCodeStatus.java`
- `pte-api/app/src/main/java/com/pte/billing/domain/Subscription.java`
- `pte-api/app/src/main/java/com/pte/billing/internal/constant/BillingConstants.java`
- `pte-api/app/src/main/java/com/pte/billing/internal/controller/LicenseCodeController.java`
- `pte-api/app/src/main/java/com/pte/billing/internal/controller/LicenseCodeRedeemController.java`
- `pte-api/app/src/main/java/com/pte/billing/internal/dto/request/IssueLicenseCodeRequest.java`
- `pte-api/app/src/main/java/com/pte/billing/internal/dto/request/RedeemLicenseCodeRequest.java`
- `pte-api/app/src/main/java/com/pte/billing/internal/dto/request/RevokeLicenseCodeRequest.java`
- `pte-api/app/src/main/java/com/pte/billing/internal/dto/response/LicenseCodeResponse.java`
- `pte-api/app/src/main/java/com/pte/billing/internal/exception/LicenseCodeException.java`
- `pte-api/app/src/main/java/com/pte/billing/internal/repository/LicenseCodeRepository.java`
- `pte-api/app/src/main/java/com/pte/billing/internal/repository/SubscriptionRepository.java`
- `pte-api/app/src/main/java/com/pte/billing/internal/service/LicenseCodeExpirationService.java`
- `pte-api/app/src/main/java/com/pte/billing/internal/service/LicenseCodeGenerator.java`
- `pte-api/app/src/main/java/com/pte/billing/internal/service/LicenseCodePersistenceService.java`
- `pte-api/app/src/main/java/com/pte/billing/internal/service/LicenseCodeService.java`
- `pte-api/app/src/main/java/com/pte/identity/internal/config/SecurityConfig.java`
- `pte-api/app/src/main/java/com/pte/shared/web/RateLimitFilter.java`
- `pte-api/app/src/main/resources/application.yml`
- `pte-api/app/src/main/resources/db/migration/V19__billing_license_code.sql`
- `pte-api/.env.example`

## Steps

1. Enum `LicenseCodeStatus` (`ISSUED`, `REDEEMED`, `REVOKED`, `EXPIRED`).

2. Entity `LicenseCode`: `code` (unique), `planId`, `status`, `issuedBy`, `issuedAt`, `codeExpiresAt`, `redeemedByTenantId`, `redeemedAt`, `subscriptionId` (null tới khi redeem), `revokeReason`.

3. Migration `V19__billing_license_code.sql`, index trên `code`.

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

- Decision checkpoint: unit tests = yes; quality gate = yes (user confirmed).
- Quality gate: **approved**, 0 blocking/advisory/noted findings. Report: `quality/phase-06-license-code-quality-report.json`. Cryptographic receipt skipped because this report is in `pte-doc` while source files are in the separate `pte-api` repository.
- Testing result: **passed**, `530` tests, `0` failures, `0` errors, `0` skipped. Report: `tests/phase-06-license-code-test-report.json`.

## Session Notes

- Implemented individual SecureRandom bearer-code issue, atomic redeem, differentiated invalid-state errors, redemption expiry checks, admin revoke, subscription cancellation, expiration job, and a route-specific Redis-backed rate limit.
- Redeem calls the public `SubscriptionActivationService`; no Phase 6 production code constructs `Subscription` directly. Session cancellation for scheduled/open/closed exams remains an explicit Phase 11 TODO.
- `LicenseCodeServiceTest`, `LicenseCodeGeneratorTest`, and `LicenseCodeExpirationServiceTest` passed as part of the full app regression suite: `.\mvnw.cmd -pl app test`.
