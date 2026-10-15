# Phase 1: Role catalog, common contracts and legacy author migration

## Goal

Đưa role catalog mới vào backend/frontend contract mà không làm hỏng account hoặc token đang dùng `PLATFORM_AUTHOR`. Sau phase này, hệ thống nhận diện được bốn platform role mới/canonical và vẫn có compatibility path cho author cũ.

## Stories covered

- P1 Platform administration
- P1 Academic authoring
- P1 Tenant administration/exam boundary (không thay đổi behavior)

## Steps

1. Đối chiếu toàn bộ call site role hiện tại với `Role.java`, `V35__identity_role_taxonomy.sql`, `AccessTokenIssuer`, `ResourceServerJwt`, `CurrentUserContext`, `@pte/ui` `SessionRole` và vendor `ADMIN_ROLES`.
2. Mở rộng `Role` bằng `PLATFORM_MANAGER`, `ACADEMIC_MANAGER`, `ACADEMIC_STAFF`; giữ `PLATFORM_AUTHOR` là deprecated legacy enum trong compatibility window.
3. Tạo shared canonical-role/permission contract ở boundary hiện có (không tạo custom-role database): role canonical, legacy alias mapping, platform-role predicate, tenant-role predicate và capability identifiers.
4. Tạo migration mới kế tiếp `V86__platform_role_catalog.sql` (hoặc số kế tiếp tại thời điểm cook): mở rộng check constraint `user_roles.role` và thêm index/constraint cần thiết cho platform role lookup; không sửa migration đã apply.
5. Chuẩn hóa role khi issue/đọc JWT: account cũ có `PLATFORM_AUTHOR` nhận capability `ACADEMIC_STAFF`; token mới phát canonical `ACADEMIC_STAFF`; resource server/current-user context vẫn đọc được token legacy trong window.
6. Cập nhật các common TypeScript contracts và role parser để các app không tự đoán role: `SessionRole`, canonical platform-role constants, legacy normalization và label key/type cần thiết.
7. Cập nhật tài liệu migration/rollback/compatibility và local seed manifest theo role code; không ghi password/token vào source.

## Design Constraints

- Preflight: Existing Java modules use enum-backed `identity.domain.Role`, string JWT claims through `shared.security`, Flyway SQL under `db/migration`, and focused JUnit/AssertJ tests; frontend role type is centralized in `@pte/ui`. Phase 1 reuses those conventions and does not introduce a dynamic permission table.
- Không xóa `PLATFORM_AUTHOR` khỏi Java enum/DB constraint trong phase này; cleanup chỉ sau khi backfill và compatibility đã được verify.
- Không đặt permission graph đầy đủ vào JWT; JWT chỉ mang role canonical, còn resource scope kiểm tra server-side.
- Platform role phải có `tenantId == null`; tenant role không được dùng làm platform role.
- Reuse `SecurityClaims`, `ResourceServerJwt`, `CurrentUserContext`, `CurrentUser` và `@pte/ui` session storage; chỉ thêm canonicalization cần thiết.
- Không thay đổi `HOST_ADMIN`, `EXAMINER`, `PROCTOR`, `STUDENT` semantics hoặc login organization selection.

## Files / ownership

- `pte-api/app/src/main/java/com/pte/identity/domain/Role.java`
- `pte-api/app/src/main/java/com/pte/identity/domain/User.java`
- `pte-api/app/src/main/java/com/pte/identity/internal/security/AccessTokenIssuer.java`
- `pte-api/app/src/main/java/com/pte/identity/internal/service/UserProvisioningHelper.java`
- `pte-api/app/src/main/java/com/pte/shared/security/SecurityRoles.java`
- `pte-api/app/src/main/java/com/pte/shared/security/CurrentUser.java`
- `pte-api/app/src/main/java/com/pte/shared/security/ResourceServerJwt.java`
- `pte-api/app/src/main/resources/db/migration/V86__platform_role_catalog.sql`
- `pte-api/app/src/test/java/com/pte/identity/internal/service/UserProvisioningHelperTest.java`
- `pte-api/app/src/test/java/com/pte/shared/security/SecurityRolesTest.java`
- `pte-web/packages/ui/src/hooks/sessionStorage.ts`
- `pte-web/packages/ui/src/hooks/index.ts`
- `pte-web/apps/vendor-web/features/auth/constants.ts` and `LoginView.tsx`
- `pte-web/packages/api-client/src/types/auth/*` nếu contract auth cần cập nhật
- compatibility/runbook docs dưới `pte-doc` và local seed/docs dưới `pte-api/scripts` khi cần

## Quality and Testing State

- Quality: APPROVED (`ck:quality --gate` equivalent); report and receipt are under `quality/`.
- Testing: PASSED (`ck:test --tdd --verify` equivalent); 56 focused identity/security regression tests passed, including the prepared role-catalog/policy tests and legacy authority compatibility test. Report: `tests/phase-01-role-catalog-and-legacy-migration-test-report.json`.
- `ck:cook` phải xác nhận có chạy unit test và quality gate cho phase này trước khi implementation.

## Acceptance Criteria

- Backend parse/issue được bốn platform role mới; legacy `PLATFORM_AUTHOR` không làm login hoặc refresh token thất bại.
- Token mới dùng `ACADEMIC_STAFF` cho account legacy; token legacy vẫn được resource server normalize thành capability tương đương trong window.
- DB migration chạy được trên PostgreSQL mới và database đã có `V35`; không sửa lịch sử migration.
- Mixed platform/tenant role set bị reject ở contract/policy layer.
- Frontend session parser nhận các role mới, normalize legacy và không loại account hợp lệ khỏi Admin Web.
- Có test xác nhận role constants/alias chỉ có một canonical mapping và không chứa credential.
