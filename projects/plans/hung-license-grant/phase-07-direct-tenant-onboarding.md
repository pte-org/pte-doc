# Phase 7: Admin tạo tenant trực tiếp đúng nghiệp vụ

**Status:** Implemented 2026-10-30 · **Repo:** pte-api, pte-web · **Stories:** P1 (bổ sung 2026-10-30) — FR-15 → FR-18

## Vấn đề (đã đối chiếu code)

Form *Add Tenant* cũ (`POST /api/v1/organizations` → `OrganizationLifecycleService.onboard`) lệch nghiệp vụ ở 3 chỗ:

1. **Ô Plan chỉ là nhãn.** Ba lựa chọn Starter/Professional/Enterprise viết cứng trong vendor-web, chỉ lưu thành `Organization.packageName`. Không tạo Subscription, không sinh mã. Nhãn "500 users" mâu thuẫn với ô Student Limit, còn "Unlimited" trái ADR-006.
2. **Student Limit nhập tay.** Ô này đi vòng qua quy tắc *hạn mức = `freeStudentLimit` + gói chỗ học viên* và không có bản ghi QuotaGrant.
3. **Không tạo tài khoản Host.** Tổ chức ACTIVE nhưng không ai đăng nhập được, trái spec ("duyệt → tổ chức + Host đầu tiên").

## Đã làm

**pte-api**
- `TenantApplicationService.onboardDirect(...)`: ghi tổ chức như một đơn (`tenancyService.submitApplication`) rồi duyệt ngay. Phần duyệt được tách thành `approvePending(...)`, dùng chung với `approve(...)`, nên có cùng `freeStudentLimit`, cùng `createHostAdmin`, cùng `TenantApplicationApprovedEvent` (email mật khẩu) và cùng audit.
  - Quyền: `PlatformOperation.TENANT_ONBOARD`, tức Admin + Manager.
  - Kiểm tra trùng tên và mã như luồng `submit`. MST kiểm tra lúc duyệt.
- Endpoint mới: `POST /api/v1/admin/organizations` trong `TenantApplicationController`. DTO mới: `DirectOnboardRequest` (code, name, organizationType, taxCode, hostEmail) và `DirectOnboardResponse` (publicId, code, name, hostUsername).
- **Gỡ** `POST /api/v1/organizations` khỏi `OrganizationController`. `OrganizationLifecycleService.onboard` còn lại cho test cũ, không còn route nào gọi.
- Seed script `seed-local-exam-ready.ps1` chuyển sang endpoint mới với `hostEmail`.

**pte-web**
- api-client: `onboardOrganization` + `DirectOnboardRequest/Response` thay `onboardTenant` + `OnboardTenantRequest`.
- vendor-web `features/tenancy`:
  - `CreateTenantInput` bỏ `plan`/`studentLimit`, thêm `hostEmail`. Validate định dạng email.
  - `_TenantGeneralFields`: bỏ ô Plan và Student Limit, thêm ô Email Host và `Alert` ghi chú về hạn mức và cấp gói.
  - `useCreateTenant`: gọi `onboardOrganization` rồi `getTenant` để có đủ dữ liệu hiển thị.
  - `TenantCreatedModal`: bỏ dòng Plan, thêm dòng Host kèm ghi chú đã gửi mật khẩu, thêm nút **Cấp gói ngay**.
  - `TenantManagementView`: nút đó mở `GrantLicenseWizard` với `initialCode = tenant.code`.
  - `_TenantTable`: cột/bộ lọc *Plan* thay bằng cột *Student Limit*. `TenantDetailView` bỏ dòng Plan; nhóm "Plan & capacity" đổi tên thành "Capacity".
  - **Giữ** `TenantPlan`, `TENANT_PLAN_LABELS`, `PLAN_SELECT_OPTIONS` vì `features/licensing` (quota grant) còn dùng.
- vendor-web `features/licenseGrant`: `useGrantLicenseFlow(onGranted, initialCode)`. Tổ chức khớp đúng mã và đang ACTIVE được **tính ra** (derived state, không dùng effect, vì luật lint `react-hooks/set-state-in-effect`) và hiện ngay ở bước *Xác nhận*. Bấm *Quay lại* sẽ bỏ chọn để Admin chọn tổ chức khác.
- vendor-web trang *Cấp gói*: cột *Expires* (hạn nhập mã) **tắt** bằng cờ `SHOW_CODE_EXPIRY_COLUMN = false` (FR-18).
- `adminCopy.ts`: thêm bản dịch tiếng Việt cho các chuỗi mới.

## Design Constraints

- `tenancy` không gọi `billing`/`identity` (vòng phụ thuộc), nên luồng tạo tenant đặt ở `billing`, giống luồng duyệt đơn.
- Không thêm migration. Không đổi bảng `organizations`; `packageName` giữ giá trị mặc định `starter`.
- FE dùng component `@pte/ui` sẵn có (`Alert`, `Button`, `Modal`, `Select`). Chuỗi để trong constants, có bản dịch trong `adminCopy`.

## Kiểm tra đã chạy

- `mvnw test-compile`: sạch.
- vendor-web `tsc --noEmit`: không có lỗi từ code. 3 lỗi còn lại đã có từ trước, nằm trong cache `.next/types/validator.ts`, trỏ tới trang `practice-rubrics` đã xóa.
- vendor-web `eslint` cho `features/tenancy`, `features/licenseGrant`, `adminCopy.ts`: sạch. api-client `tsc`: sạch.
- Seed script: parse PowerShell OK.

## Quality and Testing State

- Quality: not evaluated [quality: skipped_by_user; decision: user_confirmed_skip]
- Testing: not started. Test cũ có thể ảnh hưởng: `OrganizationLifecycleServiceTest` (vẫn gọi `onboard` trực tiếp, không qua HTTP nên vẫn compile); test HTTP nào gọi `POST /api/v1/organizations` sẽ nhận 405.
