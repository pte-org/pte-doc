# Phase 4: Platform Manager operational boundaries

## Goal

Cho `PLATFORM_MANAGER` xử lý công việc vận hành platform sau admin theo action matrix rõ ràng, đồng thời giữ các thao tác security, platform settings và tài chính nhạy cảm ở `PLATFORM_ADMIN`.

## Stories covered

- P1 Platform operations
- P1 Platform administration
- P1 Tenant administration boundary

## Action Matrix

| Domain | `PLATFORM_MANAGER` được phép | `PLATFORM_ADMIN`-only |
|---|---|---|
| Applications | List/detail/approve/reject | Override/security exception |
| Tenants | List/detail/onboard/suspend/reactivate/branding theo workflow vận hành | Role/security, sensitive quota override nếu không có capability riêng |
| Plans/catalog | List all, draft CRUD, activate/archive | Override policy/config exception |
| License codes | Issue, list, masked lookup/detail | Reveal raw code, revoke/cancel |
| Orders/subscriptions | Platform-wide read/reporting | Refund, revoke, destructive commercial mutation |
| Announcements | Create/update/delete draft, preview, publish/retry | Override/delete published sensitive announcement nếu policy yêu cầu |
| Support tickets | List/detail/status/note | Security escalation/role changes |
| Platform settings | Không | Full |
| Platform users/roles | Không | Full |

Nếu source không có admin read endpoint cho orders/subscriptions, phase này chỉ thêm read-only platform query với scope rõ ràng; không tái sử dụng endpoint `/api/v1/orders` vốn là tenant `HOST_ADMIN` endpoint.

## Steps

1. Tạo `PlatformOperationPolicy`/capability mapping dùng common role contract; ghi action matrix thành constants/enum để controller và service dùng cùng định nghĩa.
2. Tách class-level guards thành method-level guards ở các controller có mixed sensitivity; không đổi toàn class `PLATFORM_ADMIN` thành `hasAnyRole` khi trong class có reveal/revoke/settings.
3. Tenant applications/tenants:
   - mở đúng list/detail/review/lifecycle cho manager;
   - truyền `CurrentUser` vào service mutation để audit actor và enforce platform scope;
   - quota/organization/security actions giữ boundary admin nếu thuộc sensitive capability.
4. Plan/catalog:
   - cho manager draft CRUD/activate/archive theo policy;
   - cập nhật `PlanController` list/admin projection và `PlanService` caller checks;
   - giữ active public catalog unauthenticated/public behavior nếu đang có.
5. License:
   - split issue/list/masked lookup khỏi reveal/revoke;
   - cập nhật `LicenseCodeController`, `AdminLicenseCodeController`, `LicenseCodeService` và error constants;
   - không trả raw license code cho manager.
6. Order/subscription/reporting: thêm hoặc mở read-only platform projections nếu cần, lọc/authorize server-side theo platform scope; không lẫn tenant order create/redeem path.
7. Announcements/support: mở operational CRUD/review cho manager, giữ recipient/audience scope và audit; notification inbox recipient visibility không bị thay đổi.
8. Giữ `PlatformSettingController`, role management, security config và các emergency override ở admin-only.
9. Ghi audit cho application decision, tenant lifecycle, plan transition, license issue, announcement publish và support mutation; không ghi sensitive code/payment payload.
10. Cập nhật backend tests cho từng action matrix row, đặc biệt 403 manager với settings/reveal/revoke/refund/role/security/academic publish.

## Design Constraints

- Preflight: reused the shared `CurrentUser`/`SecurityPolicy` scope contract, `AuditLogService`, module constants, existing lifecycle services, and `PagedResult`/`PageMeta` contracts. The new `PlatformOperation` enum and `PlatformOperationPolicy` own only the manager delegation matrix; domain services retain lifecycle, ownership, masking, and tenant-filter rules. Applicable rules are server-side authorization, tenantless platform scope, bounded pagination, safe projections, centralized constants, actor audit, and backward-compatible service constructors. Live PostgreSQL/Flyway, HTTP, browser, and FE checks remain deferred to later phases.
- Manager là platform-scoped, không có `tenantId`; không dùng `HOST_ADMIN` tenant policy để authorize manager.
- `PLATFORM_MANAGER` không được grant/revoke role, đổi security setting, xem raw secret/license code hoặc hoàn tiền/revoke subscription.
- Mutating service phải nhận caller khi actor/audit/scope cần thiết; không dựa riêng vào annotation.
- Không mở public endpoint mới; mọi admin/manager endpoint vẫn bearer-authenticated.
- Không để API response phân biệt quá mức resource tồn tại khi caller không có scope nếu module hiện tại đang dùng not-found masking.
- Reuse billing/notification/support constants, DTO và audit infrastructure trước khi thêm code mới.

## Files / ownership

- `pte-api/.../billing/internal/controller/TenantApplicationController.java`
- `pte-api/.../tenancy/internal/controller/TenantController.java`
- `pte-api/.../billing/internal/controller/PlanController.java`
- `pte-api/.../billing/internal/service/PlanService.java`
- `pte-api/.../billing/internal/controller/LicenseCodeController.java`
- `pte-api/.../billing/internal/controller/AdminLicenseCodeController.java`
- `pte-api/.../billing/internal/service/LicenseCodeService.java`
- `pte-api/.../billing/internal/controller/PlatformSettingController.java` (giữ admin-only, test deny)
- `pte-api/.../notification/internal/controller/AnnouncementController.java`
- `pte-api/.../support/internal/controller/AdminSupportTicketController.java`
- order/subscription admin query classes nếu cần
- module policy/constants/tests và Flyway/indexes nếu query mới cần

## Quality and Testing State

- Quality: APPROVED — `quality/phase-04-platform-manager-operations-quality-report.json`; receipt verified at `quality/phase-04-platform-manager-operations-receipt.json`.
- Testing: PASSED — 113 focused backend tests, 0 failures/errors/skips; clean compile passed for 1074 source files. Evidence: `tests/phase-04-platform-manager-operations-test-report.json`.
- Deferred validation: live PostgreSQL/Flyway execution, HTTP authorization through a running deployment, browser/vendor-admin UI, and full seed/regression sweep remain for later phases.

## Acceptance Criteria

- Manager xử lý được đúng application/tenant/plan/catalog/announcement/support actions trong matrix.
- Manager nhận 403 cho platform settings, role/security, academic approve/publish, raw license reveal, license revoke, refund/cancel/revoke subscription.
- Admin vẫn làm được toàn bộ thao tác cũ.
- Tenant host order/redeem/subscription flows không bị manager policy làm thay đổi.
- Mọi mutation manager có actor audit và scope platform; không log secret/payment payload.
- Không có class-level annotation vô tình mở sensitive endpoint; security tests chứng minh từng action.
