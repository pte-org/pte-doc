# Phase 1: Kích hoạt có ngày bắt đầu + mã gắn tổ chức

**Status:** Not started · **Repo:** pte-api · **Stories:** P1 #1, #2 (FR-03, FR-04, FR-05, FR-06, FR-08)

Gốc đường dẫn: `pte-api/app/src/main/java/com/pte/`

## Mục tiêu

Làm nền cho cấp gói. Không có endpoint mới, không đổi hành vi PayOS hay redeem cũ.

## Việc cần làm

1. **Migration `V9__license_code_grant_fields.sql`** (V7, V8 đã thuộc PR chat #85): thêm vào `license_codes`
   - `bound_tenant_id uuid NULL`
   - `requested_starts_at timestamptz NULL`
   - `contract_reference varchar(64) NULL`
   - `note varchar(500) NULL`
   - index `idx_license_codes_bound_tenant (bound_tenant_id)`
   **Không** sửa CHECK constraint nào: giữ `activation_source = LICENSE_CODE` và scope idempotency `LICENSE_ISSUE`.
2. **`billing/domain/LicenseCode.java`:** thêm 4 field trên. Thêm factory `LicenseCode.grant(code, planId, issuedBy, issuedAt, boundTenantId, requestedStartsAt, contractReference, note)`. Mã cấp gói không có `codeExpiresAt`. Dùng `markRedeemed(tenantId, now)` và `linkSubscription(...)` có sẵn trong bộ nhớ, không dùng câu UPDATE dạng bulk.
3. **`SubscriptionActivationService`:**
   - Thêm overload `activate(tenantId, plan, source, Instant requestedStartsAt)`. Overload cũ gọi overload mới với `null`.
   - `startsAt = requestedStartsAt != null ? requestedStartsAt : clock.instant()`. License key vẫn sinh từ `startsAt`.
   - Chặn: `requestedStartsAt` sớm hơn đầu ngày hôm nay (giờ VN) hoặc muộn hơn `now + 6 tháng` → 422 `SUBSCRIPTION_START_OUT_OF_RANGE`.
   - Gói `STUDENT_CAPACITY` bỏ qua `requestedStartsAt`.
4. **Ngày mặc định:** thêm `resolveDefaultStart(tenantId, planId)` = `max(now, expiresAt lớn nhất của Subscription ACTIVE cùng tenant + plan)`.
   - Sửa `SubscriptionRepository.findUsableForPlanRenewal`: bỏ `s.startsAt <= :now` để tính cả gói chờ. Đổi tên thành `findRenewableForPlan` (hiện không ai gọi).
   - **Khóa:** người gọi phải đang giữ khóa dòng tổ chức qua `tenancyService.lockActiveTenant(tenantId)` (propagation MANDATORY). Khóa này tuần tự hóa các lần cấp cho cùng một tổ chức, kể cả khi tổ chức chưa có gói nào.
5. **Bảo vệ mã gắn tổ chức ở redeem cũ:** thêm điều kiện `and (code.boundTenantId is null or code.boundTenantId = :tenantId)` vào câu UPDATE `LicenseCodeRepository.markRedeemed`. Mã gắn tổ chức khác thì không cập nhật được, `explainRedeemFailure` trả 404.
6. **Event và thông báo:**
   - `CommercialOutcomeConfirmedEvent` thêm `Instant startsAt`, lấy từ `subscription.startsAt` thật; gói chỗ để null. Sửa 3 nơi tạo event (redeemer, webhook PayOS, đơn 0 đồng).
   - `CommercialNotificationListener:54-58` + `InboxConstants:61-63`: câu thông báo gói thi dùng ngày `dd/MM/yyyy` (giờ VN). Câu thông báo gói chỗ **không** chèn ngày.

## Design Constraints

- `activate` vẫn là **nơi duy nhất** tạo Subscription (ADR-006 bất biến #4).
- Không đổi chữ ký các hàm public đang dùng; chỉ thêm overload.
- Entity mới khớp schema (`ddl-auto: validate`). Không cần sửa seed SQL.
- Thông báo lỗi để trong `BillingConstants`.

## Tests

- `SubscriptionActivationServiceTest`:
  - `requestedStartsAt` tương lai thì `expiresAt = startsAt + durationDays`.
  - `null` thì giống hiện tại.
  - Quá khứ và quá 6 tháng thì 422.
  - Gói chỗ bỏ qua ngày.
  - `resolveDefaultStart`: không có gói → now; gói PayOS hết 31/12 → 31/12; có gói chờ → hết hạn của gói chờ.
- `LicenseCodeServiceTest`: mã gắn tổ chức A bị tổ chức B nhập thì 404; mã cũ không gắn tổ chức vẫn redeem được.
- `CommercialNotificationListenerTest`: câu thông báo gói thi có ngày; gói chỗ không có "null".

## Quality and Testing State

- Quality: not evaluated
- Testing: not started
