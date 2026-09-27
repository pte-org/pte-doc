# Phase 3: Tenant-web migration, auth safety and error boundaries

## Objective

Chuẩn hóa mọi helper và màn hình tenant đang trả thẳng `Error.message`, nhưng
vẫn giữ các message nghiệp vụ cụ thể và anti-enumeration của login.

## Scope

- `apps/tenant-web/features/examoperations/errorMessage.ts` và toàn bộ caller
  của helper: student search, exam staff, roster/import, programs, classes,
  audit log và learner flows.
- Local error helpers trong `features/classes`, `features/exams` và
  `features/programs`.
- `features/commercialization/components/CheckoutView.tsx`
- `features/commercialization/components/QuotaView.tsx`
- `features/commercialization/components/RedeemLicenseView.tsx`
- `features/auth/loginError.ts`
- `features/auth/components/RegisterOrganizationView.tsx`
- dashboard/host `error.tsx` boundaries.

## Steps

1. Refactor `features/examoperations/errorMessage.ts` thành wrapper quanh
   shared formatter; mọi caller truyền fallback theo ngữ cảnh.
2. Xóa các helper cục bộ chỉ làm `return error.message`; thay bằng shared
   formatter hoặc helper domain-specific có map rõ ràng.
3. Migrate comparisons như `TENANT_NAME_ALREADY_USED`,
   `REQUESTED_CODE_ALREADY_USED` và `STUDENT_ALREADY_IN_CLASS` sang
   `ApiError.code`.
4. Mở rộng redeem/license mapping để code chưa biết không fallback về raw code.
5. Giữ login 400/401 cùng một message generic, không phân biệt account tồn tại
   hay không; không để formatter override rule này.
6. Sửa error boundaries và upload/import errors để không hiển thị exception
   message từ server/provider.
7. Kiểm tra các modal/form và Alert nơi error đi qua prop `error`, vì đây là
   nơi người dùng cuối trực tiếp nhìn thấy text.

## Design Constraints

Preflight: tenant flows already centralize many alerts through
`features/examoperations/errorMessage.ts`, while assignment screens still have
local helpers and auth/billing screens use direct `ApiError.message`; migrate
both paths to the shared api-client formatter and preserve existing
field-specific copy.

- Không tiết lộ account existence hoặc tenant identity qua message login.
- Không render raw error object, raw JSON hay provider exception.
- Human-readable row validation/import messages phải tiếp tục hiển thị được.
- Các fallback phải nhất quán về ngôn ngữ và hành động tiếp theo.

## Quality and Testing State

- Quality: approved — `quality/phase-03-tenant-error-migration-and-auth-safety-quality-report.json` with valid receipt.
- Testing: skipped by user — unit tests explicitly disabled; Build Gate and static scan run.

### Verification

- Tenant typecheck, lint và build pass.
- Static review toàn bộ caller của shared `errorMessage` và mọi local helper.
- Manual/Playwright smoke:
  - invalid login 400/401 cùng copy;
  - add student/staff, class assignment, exam assignment và quota conflict;
  - license redeem invalid/expired/revoked/inactive plan;
  - error boundary không lộ `Error.message` kỹ thuật.

## Exit criteria

- Tenant UI không hiển thị machine-shaped code ở bất kỳ flow đã audit.
- Anti-enumeration login behavior không đổi.
- Tenant regression commands pass.
