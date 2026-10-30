# Phase 3: Thương mại

## Requirements

> **Quyết định khi cook phase 3 (2026-10-24):** `QuotaTransaction` không thành `Subscription` MANUAL vì nó ghi hạn mức *chỗ học viên* (`Organization.studentLimit`) còn `Subscription` là gói thi; trộn hai thứ sẽ buộc mọi truy vấn "subscription dùng được" thêm bộ lọc loại. Thay vào đó lịch sử cấp tay là danh sách append-only `Organization.quotaGrants` (`@Embeddable QuotaGrant`, bảng con `organization_quota_grants`), endpoint đổi tên thành `/api/v1/organizations/{id}/quota-grants`; `PaymentTransaction` → `Order.payments` (`OrderPayment`, chỉ lưu thông báo đã xác thực chữ ký của đơn có thật; thông báo giả/đơn lạ chỉ ghi log); `LicenseIssueIntent` → `IdempotencyKey` scope `LICENSE_ISSUE` (thua cuộc đua cùng key nhận 409 và thử lại để lấy receipt).


Chuyển `Plan`, `Subscription`, `LicenseCode`, `Order` (+ `PaymentTransaction` thành `Order.payments`) sang `ServicePlan`/`Subscription`/`LicenseCode`/`Order`, bỏ `QuotaTransaction` và `LicenseIssueIntent`. Đáp ứng story P1 redeem license tạo Subscription ACTIVE; cấp hạn mức thủ công vẫn truy vết được qua `Organization.quotaGrants`. Seed: Organization `e2e` có Subscription ACTIVE.

## Design Constraints

- Đọc đầy đủ `docs/CODING_STANDARDS_API.md`, `docs/API_RESPONSE_SETUP.md`, `docs/COMMON_EXCEPTION_SETUP.md`, `docs/CODING_STANDARDS_WEB.md`. Ghi standards-read note vào progress update đầu tiên.
- Giữ hành vi webhook PayOS (chữ ký, idempotent, đối soát) trong `PayOsWebhookController`/`PayOsWebhookService`.
- Giữ exclusion constraint chống chồng lấp session/subscription trong V1; chứng minh bằng gate Postgres, không bằng H2.
- `payments` là bảng con, không phải jsonb. Mọi aggregate có `organizationId`.
- `PlatformSetting` GIỮ; `PlatformSettingController` (`/api/v1/settings`) không đổi.
- Không ghi plaintext mật khẩu seed vào repo; message/mã lỗi billing giữ trong constants.

## Steps

1. Chuyển `Plan` → `ServicePlan` (`PlanService`, `PlanController`, `PlatformCommercialController`), giữ DTO/endpoint.
2. Chuyển `Subscription` (`SubscriptionPersistenceService`, `SubscriptionController`, `SubscriptionExpirationService`) với nguồn ORDER/LICENSE/MANUAL; đổi `/organizations/{id}/quota-transactions` thành `/organizations/{id}/quota-grants` (giữ chức năng cấp tay và xem lịch sử, bỏ cột `actionType` vì chỉ có GRANTED); `StudentQuotaController` vẫn đọc `Organization.studentLimit`; xoá `QuotaTransaction`, `QuotaTransactionService`, `QuotaTransactionMapper`, `QuotaTransactionResponse`, `QuotaActionType`.
3. Adapter thu hồi subscription → huỷ ca đã lên lịch: billing phát `SubscriptionRevokedEvent` từ `SubscriptionPersistenceService`; `SubscriptionRevocationListener` (module `session`) gọi `SessionRevocationService`; giữ hành vi và test.
4. Chuyển `LicenseCode` (`LicenseCodePersistenceService`, `LicenseCodeController`, `AdminLicenseCodeController`, `LicenseCodeRedeemController`, `LicenseCodeExpirationService`); redeem tạo Subscription ACTIVE; thay `LicenseIssueIntent` bằng `IdempotencyKey` scope LICENSE_ISSUE.
5. Gộp `PaymentTransaction` vào `Order.payments` (`OrderPersistenceService`, `PaymentTransactionPersistenceService`, `OrderController`, `OrderExpirationService`); `BillingOverviewService`, `BillingRevenueOverviewService` dùng JOIN bảng con; `BillingService` giữ public API.
6. Sửa client cùng phase: `pte-web/packages/api-client/src/requests/quota/index.ts`, `apps/vendor-web/app/(dashboard)/admin/licenses/page.tsx` nếu dùng; lint/typecheck/build theo `CODING_STANDARDS_WEB.md`; grep `quota-transactions` trong 3 client trả 0.
7. Seed V1: service plan, license code mẫu và Subscription ACTIVE cho Organization `e2e`; cập nhật `pte-api/scripts/seed-local-exam-ready.ps1` bỏ bước tạo plan/subscription/quota đã có trong seed (và các script khác còn gọi quota/plan API). Test: webhook PayOS, redeem, order expiry, overlap, manual grant, revoke → huỷ ca, flow test mua/redeem.
8. Cập nhật `V1__baseline.sql` (`service_plan`, `subscription`, `license_code`, `orders`, `order_payment`, exclusion constraint); chạy compile, test toàn app, `ModuleStructureTest`, gate Postgres.

## Success Criteria

- Redeem tạo Subscription ACTIVE đúng tổ chức; cấp tay nâng `studentLimit` và ghi một `QuotaGrant`; webhook PayOS cho kết quả như trước (test).
- Không còn `QuotaTransaction`, `LicenseIssueIntent`, `PaymentTransaction`, `Plan`.
- Gate dev DB (profile `local-schema`): từ `D:\GitHub\pte-org\pte-api`, DB `pte` trống trên Docker Postgres 17; `APP_SPRING_PROFILES=local-schema` trong `.env.local`; `docker compose --env-file .env.local -f docker-compose.yml -f docker-compose.services.yml up -d --no-deps --build app` khởi động (health UP) với Hibernate dựng schema, `db/dev-seed/*.sql` chạy xong, và `POST /api/v1/auth/login` thành công với `admin@test.local` và `host.e2e@test.local`. Ràng buộc chỉ Postgres (exclusion constraint `no_overlap_per_subscription`) phải có trong `db/dev-seed/000-postgres-objects.sql`. Không chạy được thì ghi "not verified", không bỏ qua im lặng.
- Client không còn path `quota-transactions`; build pass; scripts đã cập nhật (`seed-local-exam-ready.ps1` giữ nguyên: nó tạo tenant/plan theo SeedKey qua API còn hợp lệ).
- `.\mvnw.cmd -pl app -DskipTests compile`, `.\mvnw.cmd -pl app test`, `ModuleStructureTest` xanh; ghi số `@Entity` và số bảng do Hibernate dựng.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

## Risks

- Exclusion constraint không chạy trên H2: logic service test ở H2, DDL chứng minh ở gate Postgres.
- Webhook trùng/đến sớm hơn Order: giữ test idempotency hiện có.
- GET manual-subscriptions khác `QuotaTransactionResponse`: client sửa trong phase này.
