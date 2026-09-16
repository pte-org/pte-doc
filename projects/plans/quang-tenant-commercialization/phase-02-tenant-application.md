# Phase 2: Đăng ký & thẩm định tổ chức

## Requirements

Tổ chức tự nộp đơn đăng ký (công khai, không cần đăng nhập), chọn `Tenant.code` của mình. Admin nền tảng thẩm định: duyệt hoặc từ chối. Duyệt → tạo `Tenant` + user `HOST_ADMIN` đầu tiên.

Tạo module mới `com.pte.billing`.

Maps to: **[ADR-006](../../architecture/ADR-006-commercialization-and-exam-templates.md) §1** · **[ADR-007](../../architecture/ADR-007-student-identity-and-login.md) § `Tenant.code`**

## Design Constraints

- **`TenantApplication` và `Tenant` là hai entity khác nhau ở hai module khác nhau.** Không thêm trạng thái `Tenant.PENDING` — tenant không tồn tại trước khi được duyệt (bất biến #2 của ADR-006).
- **Mã bị giữ chỗ ngay khi tạo đơn, không phải lúc duyệt.** Hai đơn đang chờ cùng xin `fpt`, duyệt cả hai là va nhau. Đơn bị từ chối hoặc hết hạn thì trả mã về.
- Admin có quyền bác đơn vì lý do mã — mạo danh thương hiệu khác, hoặc mã chung chung kiểu `pte`/`ielts`. Đây là một phần của thẩm định, không phải một luật riêng cần code.
- Endpoint nộp đơn là **công khai** → bắt buộc rate-limit (dùng `RateLimitFilter` đã có) và validate chặt. Đây là bề mặt tấn công mới duy nhất của plan này mà không có auth phía trước.
- Hướng phụ thuộc: `billing → tenancy`, `billing → identity`. **Không bao giờ chiều ngược lại.**
- `TenancyService` phải phơi ra thao tác tạo tenant cho `billing` gọi — hiện `TenantLifecycleService.onboard()` nằm trong `internal/`.

## Steps

1. Tạo module `com.pte.billing` với `package-info.java` (`@ApplicationModule(displayName = "Billing")`) và facade `BillingService`.

2. Entity `TenantApplication` (`billing/domain/`): `orgName`, `orgType`, `requestedCode`, `contactEmail`, `contactPhone`, `taxCode`, `status` (`PENDING`/`APPROVED`/`REJECTED`), `reviewedBy`, `reviewedAt`, `rejectReason`.

3. Migration `V21__billing_tenant_application.sql`. `requested_code` có **unique partial index** trên các đơn còn giữ chỗ:
   ```sql
   CREATE UNIQUE INDEX uq_application_code_active
     ON tenant_applications (requested_code)
     WHERE status = 'PENDING';
   ```
   Cộng thêm kiểm chéo với `tenants.code` ở tầng service — hai bảng khác nhau nên một index không phủ được cả hai.

4. `TenantApplicationService.submit()` — công khai, không auth. Kiểm `requestedCode` chưa có trong `tenants` và chưa bị đơn `PENDING` nào giữ. Trả 409 nếu trùng.

5. `TenantApplicationService.approve()`:
   - Trong **một transaction**: đổi status → `APPROVED`, gọi `TenancyService.createTenant(name, type, code, freeStudentLimit)`, gọi `IdentityService.createHostAdmin(tenantId, contactEmail)`
   - `freeStudentLimit` đọc từ `PlatformSetting` (Phase 3) — ở phase này tạm hardcode hằng số, Phase 3 thay bằng lookup
   - Sinh mật khẩu ban đầu cho `HOST_ADMIN`, trả về trong response một lần

6. `TenantApplicationService.reject()`: status → `REJECTED` + `rejectReason`. Partial index tự nhả mã.

7. `TenancyService`: thêm `createTenant(...)` vào facade, uỷ quyền xuống `TenantLifecycleService`. Đây là lần đầu `tenancy` có người gọi xuyên module — giữ facade mỏng, không nhét logic.

8. `IdentityService`: thêm `createHostAdmin(tenantId, email)` vào facade.

9. Controller: `POST /api/applications` (công khai), `GET /api/admin/applications` + `POST /api/admin/applications/{id}/approve|reject` (`PLATFORM_ADMIN`).

10. Test: duyệt đơn → tenant tồn tại với đúng `code`, user `HOST_ADMIN` đăng nhập được bằng mật khẩu trả về.

11. Test giữ chỗ mã: nộp hai đơn cùng `requestedCode` → đơn thứ hai 409. Từ chối đơn thứ nhất → nộp lại được.

## Success Criteria

- Tổ chức nộp đơn được mà không cần tài khoản
- Hai đơn `PENDING` không thể cùng giữ một mã
- Đơn bị từ chối nhả mã ra cho đơn khác dùng
- Duyệt đơn tạo ra tenant + `HOST_ADMIN` trong một transaction — lỗi giữa chừng không để lại tenant mồ côi
- Endpoint công khai có rate limit
- Không lớp nào trong `tenancy` hay `identity` import vào `billing`

## Quality and Testing State

- Quality gate: chưa chạy
- Testing: chưa bắt đầu

## Session Notes

_(trống)_
