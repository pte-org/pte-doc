# Phase 5: Vendor Admin Web và API-client role-aware UX

## Goal

Cập nhật login/session/navigation/page actions để bốn platform roles dùng chung Admin Web nhưng mỗi role chỉ thấy và thao tác được capability phù hợp. Không thay đổi tenant-web host navigation ngoài việc giữ regression boundary.

## Stories covered

- P1 Platform administration
- P1 Platform operations
- P1 Academic governance/authoring
- P1 Academic authoring

## Steps

1. Cập nhật `@pte/ui` `SessionRole`/session parser và vendor `LoginView` để nhận canonical platform roles, normalize legacy author và redirect tất cả platform role vào `/admin`.
2. Tạo capability helpers/constants ở common/app boundary đang có; không rải các điều kiện `roles.includes(...)` mới trong từng page.
3. Mở `ADMIN_ROLES` cho `PLATFORM_ADMIN`, `PLATFORM_MANAGER`, `ACADEMIC_MANAGER`, `ACADEMIC_STAFF`; giữ `PLATFORM_ADMIN_ONLY` cho settings, role management, raw license reveal/revoke và emergency actions.
4. Cập nhật `ADMIN_NAV`/route guards:
   - commercial/tenant/application/support/announcement cho admin + manager;
   - question bank/question types/question templates/score templates cho admin + academic manager + academic staff;
   - settings/security/platform-user management cho admin;
   - các action nhạy cảm dùng `requiredRoles` hoặc capability-level action guard, không chỉ menu guard.
5. Thêm/hoàn thiện platform user management surface cho `PLATFORM_ADMIN`: list/filter role/status, create/update role, suspend/reactivate và confirmation/error states; không tái sử dụng form tạo `HOST_ADMIN` trong tenant detail cho platform account.
6. Cập nhật Question Bank, Question Type, Question Template/Score Template components:
   - staff thấy create/edit/submit/rejection feedback nhưng không thấy approve/publish;
   - manager thấy review/approve/reject/publish/activate cho resource của người khác;
   - admin thấy đầy đủ override;
   - hiển thị status/owner/audit-relevant feedback khi API đã trả contract.
7. Cập nhật commercialization/announcement/support pages theo manager action matrix; ẩn reveal/revoke/settings actions với manager nhưng vẫn xử lý 403 nếu người dùng gọi trực tiếp.
8. Cập nhật API client comments/types/hooks/mutations và endpoint tests; loại bỏ comment stale “PLATFORM_ADMIN-only” ở các endpoint đã mở cho manager/academic role.
9. Giữ `tenant-web` host route guard và role constants unchanged except shared type compatibility; kiểm tra `HOST_ADMIN` không thể vào `/admin`.
10. Thêm role labels, accessible disabled/hidden action explanation, loading/error/403 states và refresh session behavior khi legacy role được canonicalize.

## Design Constraints

- Preflight: the active workspace contains unrelated tenant-web Create Exam changes from another workstream; this phase scopes implementation to vendor-web, shared UI/API-client contracts, and the minimum backend response/filter compatibility needed by those screens. Existing route, query/mutation, capability-helper, and common error patterns were reused.
- Frontend role guard chỉ là UX; không coi navigation ẩn là security.
- Reuse `@pte/ui` session storage/`ProtectedRoute`, `DashboardChrome`, `RequireAuth`, common API client and existing query/mutation patterns.
- Không đổi route public/host hoặc login organization semantics.
- Không để staff nhìn thấy answer key, raw license code, platform setting hay dữ liệu tenant ngoài response contract.
- Page action visibility phải phản ánh capability matrix nhưng vẫn xử lý API 401/403/409/error message bằng common error helpers.
- Không tạo một role type riêng cho vendor-web khác `@pte/ui` `SessionRole`.

## Files / ownership

- `pte-web/packages/ui/src/hooks/sessionStorage.ts`
- `pte-web/packages/ui/src/hooks/useSessionManager.ts` nếu cần helper
- `pte-web/apps/vendor-web/features/auth/constants.ts`
- `pte-web/apps/vendor-web/features/auth/components/LoginView.tsx`
- `pte-web/apps/vendor-web/features/auth/components/RequireAuth.tsx`
- `pte-web/apps/vendor-web/features/auth/components/DashboardChrome.tsx`
- `pte-web/apps/vendor-web/lib/navigation.tsx`
- `pte-web/apps/vendor-web/app/(dashboard)/admin/layout.tsx`
- vendor questionbank/questiontype/questiontemplate/scoretemplate/commercialization/notification/support components and APIs
- `pte-web/packages/api-client/src/types/*`, `src/requests/*` và tests
- platform user route/components/API client mới nếu Phase 2 backend cung cấp API

## Quality and Testing State

- Current validation record is authoritative; the historical bootstrap note below is retained for traceability.
- Quality: APPROVED by the inline `ck:quality --gate` review. Report: `pte-doc/plans/platform-role-expansion/quality/phase-05-vendor-admin-role-aware-ui-quality-report.json`; receipt: `pte-doc/plans/platform-role-expansion/quality/phase-05-vendor-admin-role-aware-ui-receipt.json`.
- Testing: PASSED. API-client: 20 files / 422 tests; backend focused task-type/contract checks: 19 tests; vendor-web typecheck, lint, and production build passed. Lint retains two pre-existing `<img>` warnings. Live browser authorization, running HTTP, PostgreSQL/Flyway, and full seed regression remain outside this phase run.
- Hard-mode checkpoint: confirmed by the user on 2026-10-08; Phase 5 completion transition is recorded and Phase 6 may proceed.
- The original bootstrap prerequisite below is historical context; the current validation record above supersedes it.
- `ck:cook` phải xác nhận API-client tests, TypeScript/lint/build và quality gate cho phase này trước khi implementation.

## Acceptance Criteria

- Bốn platform roles đăng nhập được vào Admin Web; legacy author được normalize mà không mất route.
- Manager/academic manager/staff thấy đúng menu và action theo matrix; staff không có approve/publish action.
- Gọi URL trực tiếp với role không phù hợp bị route guard/403 đúng contract.
- Admin vẫn thấy và dùng toàn bộ menu/action privileged.
- Host/examiner/proctor/student không vào được Admin Web; Host UI không bị thay đổi ngoài regression.
- Platform user management chỉ render và gọi API cho admin.
- `pnpm`/workspace lint, `tsc --noEmit`, build và API-client contract tests được lập thành checklist cho final gate.
