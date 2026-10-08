# Phase 2: Platform identity, role assignment và shared authorization foundation

## Goal

Thiết lập enforcement dùng chung cho role/scope và cung cấp API quản lý platform user dành riêng cho `PLATFORM_ADMIN`. Sau phase này, role mới có thể được cấp/quản lý an toàn; các module có thể dùng cùng policy thay vì mỗi nơi tự kiểm tra literal role.

## Stories covered

- P1 Platform administration
- P1 Platform operations
- P1 Academic governance/authoring

## Steps

1. Tạo capability policy dùng chung từ role bundle đã chốt: `ROLE_MANAGE`, `SECURITY_CONFIGURE`, platform operations, academic draft/review/approve/publish và các capability exam hiện có. Giữ domain lifecycle check ở module sở hữu dữ liệu.
2. Bổ sung helper kiểm tra platform scope/tenant scope/assigned scope và ownership; mọi helper phải deny-by-default và null-safe.
3. Tách platform-user management khỏi tenant host-user provisioning. Bổ sung service/repository query/API cho `PLATFORM_ADMIN` tạo, list, xem, suspend/reactivate và gán `PLATFORM_MANAGER`, `ACADEMIC_MANAGER`, `ACADEMIC_STAFF`.
4. Giữ `UserProvisioningHelper` hiện tại cho `HOST_ADMIN` và `HOST_ADMIN` provisioning; không cho manager/academic role gọi luồng tạo host/exam staff nếu không có capability.
5. Enforce invariant: platform user tenantless và chỉ có platform roles; tenant user phải có tenant và chỉ có tenant roles; không cho role request trộn scope hoặc tự cấp `PLATFORM_ADMIN`.
6. Thêm audit cho role assignment/revocation, platform-user lifecycle, authorization denial và privilege elevation bằng `AuditLogService`; không log password, token hoặc credential material.
7. Chuẩn hóa exception/error constant cho forbidden role assignment, invalid scope và legacy role; cập nhật response contract phù hợp với error mapping hiện có.
8. Viết matrix test cho mọi role/capability: allow, deny, target ownership, tenant isolation, self-role escalation và legacy alias.

## Design Constraints

- Preflight: Identity already owns `UserService`, `UserRepository`, `Role`, `UserResponse`, `IdentityConstants` and `AuditLogService`; shared security owns `CurrentUser`, `SecurityRoles` and JWT conversion. Phase 2 adds a separate platform-user boundary and reuses those contracts rather than widening tenant `/users` endpoints or creating another audit store.
- Chỉ `PLATFORM_ADMIN` được quản lý role/security; không tạo endpoint nhận arbitrary permission từ client.
- Không mở rộng `UserController` tenant endpoint một cách mơ hồ; platform-user API nên có namespace/resource boundary riêng nếu endpoint hiện tại không thể giữ rõ scope.
- Role authority là cần thiết nhưng không đủ: mutations phải kiểm tra ownership/scope bằng `CurrentUser` và dữ liệu target.
- Reuse `AuditLogService` và shared error response; không tạo audit table/response song song nếu không có yêu cầu mới.
- Platform manager/academic manager không được tự cấp quyền cho chính mình thông qua user API.

## Files / ownership

- `pte-api/.../identity/internal/service/UserProvisioningHelper.java`
- `pte-api/.../identity/internal/service/UserService.java`
- `pte-api/.../identity/internal/controller/UserController.java` hoặc controller platform-user mới
- identity DTO/repository/mapper/exception/constant/test files
- `pte-api/.../shared/security/*` policy/role helper mới hoặc mở rộng
- `pte-api/.../shared/audit/*` nếu cần mở rộng audit contract
- Flyway migration nếu cần index/backfill metadata

## Quality and Testing State

- Quality: APPROVED (`ck:quality --gate`); report and receipt are under `quality/phase-02-platform-identity-and-authorization-foundation-*`.
- Testing: PASSED (`ck:test --tdd --verify`); 34 focused tests and 61 identity regression tests passed. Artifact: `tests/phase-02-platform-identity-and-authorization-foundation-test-report.json`.
- `ck:cook` phải xác nhận unit/integration/security test và quality gate cho phase này trước khi implementation.

## Acceptance Criteria

- Chỉ `PLATFORM_ADMIN` tạo hoặc thay đổi platform role; mọi role khác nhận 403.
- Không thể tạo user có `PLATFORM_ADMIN` thông qua luồng platform-user thông thường nếu API contract yêu cầu admin bootstrap riêng; không thể tự cấp role cao hơn.
- Platform role không thể gắn tenant; tenant role không thể tạo như platform user.
- `PLATFORM_MANAGER`, `ACADEMIC_MANAGER`, `ACADEMIC_STAFF` có JWT canonical role sau login/refresh.
- Authorization denial và role changes có audit; log không chứa password/token.
- Existing Host user creation, Student roster import và examiner/proctor lookup vẫn pass regression.
