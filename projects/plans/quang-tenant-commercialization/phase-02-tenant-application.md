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

3. Migration `V15__billing_tenant_application.sql`. `requested_code` có **unique partial index** trên các đơn còn giữ chỗ:
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
- Testing: `TenantApplicationServiceTest` viết xong (9 test: submit x3, approve x3, reject x2 + implicit not-found), **chưa chạy được** — sandbox không có Java/Maven.

## Session Notes

Implement 2026-09-16. Module `com.pte.billing` mới, toàn bộ dưới `billing.internal.*` trừ `package-info.java` + `BillingService` (facade rỗng — chưa ai gọi vào billing, đúng quy ước "không phình speculative" của `IdentityService`).

**File mới:** `TenantApplicationStatus`, `TenantApplication` (entity), `V15__billing_tenant_application.sql`, `TenantApplicationRepository`, 3 exception (`TenantApplicationNotFoundException`, `RequestedCodeAlreadyUsedException`, `ApplicationNotPendingException`), `BillingConstants`, 2 request DTO + 2 response DTO, `TenantApplicationMapper`, `TenantApplicationService`, `TenantApplicationController`, `TenantApplicationServiceTest`.

**Đụng sang module khác (đúng hướng `billing → tenancy`, `billing → identity`):**
- `TenantLifecycleService.createFromApplication(...)` — logic giống `onboard()` nhưng validate lại uniqueness thay vì tin caller (thời gian trôi giữa lúc nộp đơn và lúc duyệt).
- `TenancyService` facade +`existsByCode`, +`createTenant` (trả về entity `Tenant`, không phải DTO nội bộ — `tenancy.domain` đã có `@NamedInterface` sẵn từ trước).
- `IdentityService` facade +`createHostAdmin`, trả `HostAdminCreated` — **phải để record này ở top-level `com.pte.identity`, không nested trong `IdentityService`**: Spring Modulith không coi type nested trong facade là "exposed" dù facade nằm ở module root. Bài học rút ra giữa chừng khi IDE báo `MODULITH_TYPE_REF_VIOLATION`.
- `IdentityServiceTest` sửa constructor call (3 tham số thay vì 1).

**Route thật khác với plan gốc:** repo này không dùng tiền tố `/api/` (xác nhận qua `TenantController`/`AuthController` hiện có) — dùng `/applications` (public) và `/admin/applications` (PLATFORM_ADMIN) thay vì `/api/applications`/`/api/admin/applications` như plan.md ghi. Thêm `/applications` vào `SecurityConfig.PUBLIC_PATHS` — path chính xác, không wildcard, vì controller không map method nào khác lên đúng path đó.

**Chưa kiểm chứng được (như Phase 1):** `mvn test`, và riêng phase này còn một khoảng trống test đáng nói — **unique partial index `uq_application_code_active` không kiểm chứng được bằng `@DataJpaTest`** vì quy ước hiện tại của repo (H2 + Hibernate `create-drop`, Flyway tắt) không chạy migration SQL thật, nên index tay viết trong `V15` không tồn tại trong schema test. Chỉ có nhánh kiểm tra ở tầng application (`TenantApplicationService.submit()`) được test; DB-level index cần verify thủ công trên Postgres thật.
