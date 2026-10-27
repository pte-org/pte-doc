# Phase 2: Organization & User

## Requirements

Gộp `Tenant` + `Organization` + `TenantApplication` thành `Organization` (PENDING/ACTIVE/REJECTED/SUSPENDED) và `User` + `PracticeIdentity` thành `User` + `OrganizationMember`. Đáp ứng story P1 đa tổ chức (một user ≥ 2 tổ chức, `/auth/login-options` trả danh sách để chọn) và FR-02. `/api/v1/tenants/**` đổi thành `/api/v1/organizations/**` kèm sửa client trong phase. Seed demo có `host.e2e@test.local` (HOST_ADMIN) của Organization ACTIVE slug `e2e`.

## Design Constraints

- Đọc đầy đủ `docs/CODING_STANDARDS_API.md`, `docs/API_RESPONSE_SETUP.md`, `docs/COMMON_EXCEPTION_SETUP.md`, `docs/TEST_SCENARIOS_IAM.md`, `docs/HOST_STUDENT_IMPORT_FLOW.md`, `docs/CODING_STANDARDS_WEB.md` (và `CODING_STANDARDS_APP.md` nếu `pte-app` gọi). Ghi standards-read note vào progress update đầu tiên.
- Ma trận phân quyền: token mang `organizationId` đã chọn + roles từ `OrganizationMember`; platform roles giữ global trên `User`; `RefreshToken` gắn organization, đổi tổ chức thì phát token mới, token cũ không dùng chéo tổ chức; quản lý user của host giới hạn theo `OrganizationMember` của tổ chức đang chọn.
- Giữ mã lỗi/kịch bản IAM và flow import student; response shape giữ trừ path đổi.
- `QuotaTransaction` giữ nguyên đến phase 3.
- Seed: chỉ BCrypt hash sinh bằng `PasswordEncoder` của app lúc implement; không ghi mật khẩu plaintext vào repo/plan/báo cáo.
- Plan roster-pagination và RLS tạm dừng đến khi phase này xong.

## Steps

1. Thiết kế `Organization` trong `tenancy` thay `Tenant`, `Organization`, `billing/domain/TenantApplication`; `TenantController` + `OrganizationController` thành `/api/v1/organizations/**`; `TenantApplicationController`/`TenantApplicationService` (PENDING → ACTIVE gán HOST_ADMIN qua `OrganizationMember`, từ chối, đình chỉ).
2. Thiết kế `User` + `OrganizationMember` trong `identity` thay `User`, `PracticeIdentity`, `PracticeIdentityMembership`; cập nhật `UserService`, `UserController`, `PracticeIdentityService`, `ExamStaffAccountService`, `ExamStaffIdentityService`; xoá `LoginHash`.
3. Mở rộng `AuthController` + `IdentityTokenService`: `/auth/login-options` trả danh sách tổ chức, token theo tổ chức chọn; `PracticeAuthController` giữ luồng practice.
4. Cập nhật roster/import (`StudentRosterImportService`, `RosterFileService`, `StudentRosterImportController`, enrollment `StudentRosterController`, `StudentRosterQueryService`, `AssignmentService`) dùng `OrganizationMember`; chạy lại kịch bản preview/confirm theo `HOST_STUDENT_IMPORT_FLOW.md`.
5. Sửa client cùng phase: `pte-web/packages/api-client/src/requests/tenant/index.ts`, `.../requests/organization/index.ts`, `apps/vendor-web/features/tenancy/components/_TenantTable.tsx`, `apps/vendor-web/lib/navigation.tsx`, `apps/vendor-web/features/dashboard/constants.ts`; lint/typecheck/build theo `CODING_STANDARDS_WEB.md`; grep path `/tenants` cũ trong 3 client còn 0 (trừ `quota-transactions`, xử lý ở phase 3).
6. Seed V1: thêm Organization ACTIVE slug `e2e` và `host.e2e@test.local` HOST_ADMIN qua `OrganizationMember` (thay phần tạo org/host trong `pte-api/scripts/seed-local-exam-ready.ps1`, khoảng dòng 421); cập nhật script đó bỏ bước tạo org/host đã có trong seed (các bước subscription/session cập nhật ở phase sau), và `seed-local-sample-class-students.ps1`/`seed-plan-b.sh` cho path `/organizations/**`; cập nhật `V1__baseline.sql` (`organization`, `app_user`, `organization_member`, `refresh_token`).
7. Test: bảo toàn test đăng ký/duyệt/đăng nhập/import; thêm test đa tổ chức, test phân quyền "Host org A không đọc/sửa được dữ liệu chỉ thuộc org B của user là thành viên cả hai", test refresh token không dùng chéo tổ chức, flow test đăng ký tổ chức → duyệt.
8. Chạy compile, test toàn app, `ModuleStructureTest`, gate Postgres.

## Success Criteria

- Một User có ≥ 2 `OrganizationMember`; `/auth/login-options` trả danh sách; dữ liệu hai tổ chức không lẫn (test); test phân quyền chéo tổ chức và refresh token bound-to-organization pass.
- Không còn `Tenant`, `TenantApplication`, `PracticeIdentity`, `PracticeIdentityMembership`, `LoginHash`; `QuotaTransaction` còn (xoá ở phase 3).
- Client `pte-web` build/typecheck pass với `/organizations/**`; scripts liên quan đã cập nhật.
- Gate dev DB (profile `local-schema`): từ `D:\GitHub\pte-org\pte-api`, DB `pte` trống trên Docker Postgres 17; `APP_SPRING_PROFILES=local-schema` trong `.env.local`; `docker compose --env-file .env.local -f docker-compose.yml -f docker-compose.services.yml up -d --no-deps --build app` khởi động (health UP) với Hibernate dựng schema, `db/dev-seed/*.sql` chạy xong, và `POST /api/v1/auth/login` thành công với `admin@test.local` và `host.e2e@test.local`. Ràng buộc chỉ Postgres phải có trong `db/dev-seed/000-postgres-objects.sql`. Không chạy được thì ghi "not verified", không bỏ qua im lặng.
- `.\mvnw.cmd -pl app -DskipTests compile`, `.\mvnw.cmd -pl app test`, `ModuleStructureTest` xanh; ghi số `@Entity` và số bảng do Hibernate dựng.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

## Risks

- `tenantId` → `organizationId` lan sang nhiều module: grep trước khi xoá `Tenant`, adapter tạm trong phase.
- Đổi path làm client hỏng nếu sót call site: dùng call-site inventory của phase 1.
- Tenant isolation hồi quy: thêm test truy vấn chéo tổ chức cho repository chính.
