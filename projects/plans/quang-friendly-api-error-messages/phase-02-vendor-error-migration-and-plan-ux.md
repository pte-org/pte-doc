# Phase 2: Vendor-web migration and archived plan UX

## Objective

Loại bỏ raw error display khỏi vendor/admin web và làm archived plan bất biến
đúng với lifecycle backend.

## Scope

Migration audit phải bao phủ các nhóm file hiện có:

- `apps/vendor-web/features/commercialization/components/PlanCatalogView.tsx`
- `apps/vendor-web/features/commercialization/components/LicenseCodesView.tsx`
- `apps/vendor-web/features/commercialization/components/PlatformSettingsView.tsx`
- `apps/vendor-web/features/commercialization/components/AdminApplicationDetailView.tsx`
- `apps/vendor-web/features/questiontemplate/components/QuestionTemplateView.tsx`
- `apps/vendor-web/features/questiontemplate/components/QuestionTypeEditorModal.tsx`
- `apps/vendor-web/features/scoretemplate/components/ScoreTemplateListView.tsx`
- `apps/vendor-web/features/tenancy/components/TenantDetailView.tsx`
- `apps/vendor-web/features/tenancy/components/TenantManagementView.tsx`
- `apps/vendor-web/features/licensing/components/LicensingView.tsx`
- `apps/vendor-web/features/auth/loginError.ts`
- `apps/vendor-web/features/questionbank/components/QuestionEditorForm.tsx`
- `apps/vendor-web/app/(dashboard)/error.tsx`
- các raw upload/create error còn sót lại trong vendor feature components.

## Steps

1. Replace direct `error.message` render bằng shared formatter; truyền fallback
   theo context của từng màn hình.
2. Migrate conflict checks từ message text sang `error.code`.
3. Giữ các message đặc thù đã có như duplicate tenant code/name, nhưng đi qua
   formatter/catalog chung.
4. Trong `PlanCatalogView`, chỉ render action `Edit` cho `DRAFT` và `ACTIVE`;
   archived row chỉ được xem status hoặc không có mutation action.
5. Giữ server guard `PLAN_ARCHIVED_NOT_EDITABLE` như defense-in-depth cho stale
   UI/bookmark/request race; không bắt người dùng đọc mã kỹ thuật.
6. Dùng câu hướng dẫn rõ cho các lifecycle conflict của plan/license/settings.
7. Route error boundary chỉ dùng fixed safe copy + retry; không render raw
   Next/server exception message.
8. Rà cả các `catch` không đi qua TanStack Query, đặc biệt media upload và
   score/question authoring, để không bỏ sót `Error.message` ngoài API mutation.

## Design Constraints

Preflight: vendor screens use TanStack Query mutation state for API errors,
`Alert` for user-facing feedback, and `ActionMenu` row actions; preserve those
boundaries and use the public `@pte/api-client` formatter rather than adding a
vendor-local error taxonomy.

- Không cho phép archived plan được publish lại hoặc edit trong phase này.
- Không thay đổi quyền PLATFORM_ADMIN hay endpoint billing.
- Không làm mất thông tin actionable của các conflict đã được map.
- Không dùng `window.confirm`/alert mới cho error copy nếu Alert hiện tại đủ.

## Quality and Testing State

- Quality: approved — `quality/phase-02-vendor-error-migration-and-plan-ux-quality-report.json`
  with a valid receipt.
- Testing: skipped by user — unit tests were explicitly disabled; Build Gate and
  static leak scan were still run.

### Verification

- Vendor typecheck, lint và build pass.
- Static review từng hit `error.message` trong vendor; chỉ giữ branch logic hoặc
  diagnostic hợp lệ.
- Manual/Playwright smoke:
  - archived plan không còn action `Edit`;
  - stale update trả message thân thiện;
  - license code, tenant conflict và settings failure không lộ code;
  - login failure vẫn dùng copy generic.

## Exit criteria

- Không còn vendor UI nào render raw API code.
- Archived plan không mở form edit từ action menu.
- Vendor regression commands pass.
