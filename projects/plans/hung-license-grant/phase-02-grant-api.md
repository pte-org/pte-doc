# Phase 2: API cấp gói, xem trước, tra cứu tổ chức

**Status:** Not started · **Repo:** pte-api · **Stories:** P1 #1, #3 · P2 (FR-01, FR-02, FR-07, FR-09, FR-10)

Gốc đường dẫn: `pte-api/app/src/main/java/com/pte/`

## Mục tiêu

Mở API cho vendor-web: tìm tổ chức, xem trước, cấp gói. Danh sách mã cho Admin có thêm cột.

## Việc cần làm

1. **Tra cứu tổ chức (tenancy):** `GET /api/v1/organizations?q=`
   - `OrganizationController:64` nhận `@RequestParam(required = false) String q`.
   - `OrganizationService.list`: chỉ caller platform mới dùng `q`. Host truyền `q` thì bỏ qua.
   - Khớp không phân biệt hoa thường: `code` và `taxCode` theo tiền tố, `contactEmail` khớp chính xác. Chỉ tổ chức đã duyệt, tối đa 20 kết quả, sắp theo `name`.
   - `OrganizationResponse` đã có `taxCode`, địa chỉ, tỉnh/phường, `facilityType`, nên màn xác nhận dùng luôn, không trả thêm.
2. **Xem trước (billing):** `POST /api/v1/admin/license-grants/preview`
   - Body `{tenantId, planId, startsAt?}`. Quyền `PlatformOperation.LICENSE_ISSUE` (Admin + Manager).
   - Trả:
     - `hosts` (username/email qua `IdentityService.findActiveByTenantIdAndRole(tenantId, HOST_ADMIN)`)
     - `planType`, `defaultStartsAt`, `startsAt`, `expiresAt`, `maxStudentsPerSession` / `extraStudentSlots`
     - `renewsSubscription` (licenseKey đã che + `expiresAt` của gói được nối tiếp) nếu có
   - Chỉ đọc, không khóa. Tổ chức không `ACTIVE` → 409 `GRANT_TENANT_NOT_ACTIVE`. Gói không `ACTIVE` → 409.
3. **Cấp gói (billing):** `POST /api/v1/admin/license-grants`
   - Header `Idempotency-Key` bắt buộc. Body `{tenantId, planId, startsAt?, contractReference, note?}`. `contractReference` bắt buộc, trim, ≤ 64 ký tự. `note` ≤ 500 ký tự.
   - Service mới `billing/internal/service/license/LicenseGrantService`, chạy **một transaction REQUIRED**:
     1. Kiểm tra quyền `LICENSE_ISSUE`.
     2. `tenancyService.lockActiveTenant(tenantId)`. Trả `false` (không ACTIVE: pending, rejected, suspended, đã xóa) → 409 `GRANT_TENANT_NOT_ACTIVE`. Khóa plan bằng `findByPublicIdForUpdate`.
     3. Idempotency: `IdempotencyKeyService.begin` với scope **`LICENSE_ISSUE`** (có sẵn trong CHECK), key `grant:{issuedBy}:{key}`, fingerprint SHA-256 của `tenantId|planId|startsAt|contractReference`. Gửi lại cùng key → trả kết quả cũ. Cùng key khác fingerprint → 409. Rollback thì dòng key cũng rollback theo (begin/complete là REQUIRED).
     4. `startsAt` không gửi thì dùng `resolveDefaultStart` (Phase 1).
     5. `activate(tenantId, plan, LICENSE_CODE, startsAt)`.
     6. Sinh mã: lặp `LicenseCodeGenerator.generate()` cho tới khi `!existsByCode`, tối đa 5 lần, giống `saveWithUniqueLicenseKey`. Nếu vẫn vi phạm unique thì trả lỗi 500, client gửi lại với cùng Idempotency-Key.
     7. `LicenseCode.grant(...)` → `markRedeemed(tenantId, now)` → `linkSubscription(subscriptionId)` (gói thi) → **một** `saveAndFlush`. Không bao giờ còn mã ISSUED.
     8. Phát `CommercialOutcomeConfirmedEvent` (BEFORE_COMMIT → inbox Host). Audit `AUDIT_LICENSE_GRANT`, ghi tenant, plan, hợp đồng, startsAt. **Không ghi mã.**
     9. `IdempotencyKeyService.complete` với `{licenseCodePublicId}`.
   - Response: `{licenseCodePublicId, tenantId, planId, kind, subscriptionPublicId?, licenseKey (đã che)?, startsAt?, expiresAt?, maxStudentsPerSession?, grantedStudentSlots?}`. Không trả mã gốc.
   - Controller mới `AdminLicenseGrantController` dưới `/api/v1/admin/license-grants`.
4. **Danh sách mã cho Admin:** `AdminLicenseCodeSummary` thêm `boundTenantId`, `contractReference`, `subscriptionStartsAt`, `subscriptionExpiresAt`.
   - `LicenseCodeAdminQuery` lấy Subscription theo lô các `subscriptionId` của trang (một query, không N+1).
   - Bộ lọc `tenantId` khớp `redeemedByTenantId` (mã cấp gói luôn có trường này nên không cần thêm điều kiện).

## Design Constraints

- Controller mỏng. Chuỗi thông báo trong `BillingConstants`. Gọi module khác qua facade công khai.
- Không đổi `POST /api/v1/license-codes` và `/license-code-redemptions`.
- Không dùng `LicenseCodePersistenceService.issue` (nó chạy `REQUIRES_NEW` và chặn gói chỗ).

## Tests

- `LicenseGrantServiceTest` (Mockito):
  - Cấp gói thi có/không `startsAt`.
  - Cấp gói chỗ thì không có Subscription, quota tăng.
  - Tổ chức pending/suspended → 409.
  - Thiếu số hợp đồng → 422.
  - Gửi lại cùng key trả kết quả cũ; khác fingerprint → 409.
  - Mã sinh ra trùng thì sinh lại.
  - Mã lưu xuống ở trạng thái REDEEMED, có `subscriptionId`.
- `LicenseGrantHttpContractTest` (MockMvc standalone): Admin/Manager được, Host 403; thiếu header → 400; response không có mã gốc.
- `OrganizationServiceTest`: `q` theo code tiền tố, MST, email; Host truyền `q` bị bỏ qua; tối đa 20.
- Postgres integration (`lifecycle.test.db.url`): hai lần cấp đồng thời cho tổ chức **chưa có gói** ra hai khoảng nối tiếp, không trùng.

## Quality and Testing State

- Quality: not evaluated
- Testing: not started
