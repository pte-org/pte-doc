# Plan: Chuẩn hoá lỗi API thân thiện trên vendor-web và tenant-web

Status: Completed — all phases implemented; unit tests skipped by explicit user instruction  
Date: 2026-09-20  
Mode: Hard  
Test mode: unit tests skipped; compile/build/static quality gates enabled  
Created by: Codex

## Mục tiêu

Ngăn mã lỗi kỹ thuật như `PLAN_ARCHIVED_NOT_EDITABLE`, `ORDER_PLAN_NOT_ACTIVE`
hoặc `STUDENT_ALREADY_IN_CLASS` xuất hiện trên màn hình cho người dùng cuối.
Người dùng vẫn nhận được hướng dẫn rõ ràng, còn mã lỗi máy vẫn được giữ để
logic, log và hỗ trợ kỹ thuật sử dụng.

Phạm vi chính là `pte-web/packages/api-client`, `vendor-web` và `tenant-web`.
`pte-api` là nguồn contract cần kiểm chứng. Backend không có breaking change;
sau khi hai web app đã migrate mới bổ sung metadata additive nếu cần.

## Scope challenge

- **Tồn tại?** Có. Backend trả domain error code trong field `message`; nhiều
  màn hình render trực tiếp `ApiError.message` hoặc `Error.message`.
- **Tối thiểu?** Sửa tại API-client boundary, dùng một formatter chung, migrate
  toàn bộ caller đang hiển thị raw message, và ẩn `Edit` với archived plan.
- **Độ phức tạp?** Hard: ảnh hưởng hai Next app, shared client, auth
  anti-enumeration, dynamic validation messages và lifecycle của plan.
- **Ngoài phạm vi?** Flutter `pte-app`, localization đa ngôn ngữ, redesign
  toàn bộ nội dung UX, và thay đổi semantic của HTTP status/business rules.

## Bằng chứng hiện trạng

- `pte-api/app/src/main/java/com/pte/shared/exception/DomainException.java` dùng
  error code làm `RuntimeException.getMessage()`.
- `pte-api/app/src/main/java/com/pte/shared/exception/GlobalExceptionHandler.java`
  trả `ex.getMessage()` trong `ApiResponse.message`.
- `pte-web/packages/api-client/src/client/client.ts` lấy server `message` làm
  `ApiError.message`.
- `vendor-web` và `tenant-web` có 38 tham chiếu trực tiếp tới `error.message`
  trong 30 file; một số là render, một số là branch logic.
- `vendor-web` hiện luôn có action `Edit` trong
  `features/commercialization/components/PlanCatalogView.tsx`, kể cả archived
  plan; backend đúng là từ chối update archived plan.

## Quyết định kiến trúc

1. Giữ nguyên HTTP status và machine code hiện tại để không phá vỡ contract.
2. Bổ sung `ApiError.code` ở client boundary. Client đọc `body.code` nếu có;
   với contract hiện tại, fallback nhận diện code từ `body.message`.
3. Giữ `ApiError.message` theo legacy contract trong giai đoạn đầu để không phá
   consumer hiện tại; mọi UI phải dùng formatter, không render field này trực
   tiếp. Raw response chỉ giữ trong `details`/diagnostic field.
4. Tạo một formatter dùng chung cho hai web app:
   `getUserFacingApiErrorMessage(error, fallback?)`.
   Formatter phải:
   - map các business code đã biết sang câu hướng dẫn thân thiện;
   - giữ các validation message vốn đã là câu người dùng đọc được;
   - biến code chưa biết, internal error và raw `Error` thành fallback an toàn;
   - không stringify hoặc render toàn bộ response body.
5. Các branch logic migrate từ `error.message === CODE` sang `error.code ===
   CODE`; không dùng text hiển thị để quyết định nghiệp vụ.
6. Không đổi ý nghĩa legacy field `message` trong phase đầu. Sau khi client đã
   dùng `ApiError.code`, phase 4 có thể bổ sung `code` và `userMessage` theo
   kiểu additive; consumer cũ vẫn đọc được `message` như trước.

## Message catalog tối thiểu

Các message này là baseline; wording cuối cùng phải thống nhất với UI language
hiện tại là English.

| Code | UI message dự kiến |
|---|---|
| `PLAN_ARCHIVED_NOT_EDITABLE` | This plan is archived and can no longer be edited. Create a new plan if you need different pricing or capacity. |
| `PLAN_MUST_BE_DRAFT_TO_ACTIVATE` | Only draft plans can be published. |
| `ORDER_PLAN_NOT_ACTIVE` | This plan is no longer available for purchase. Please choose another active plan. |
| `SUBSCRIPTION_PLAN_NOT_ACTIVE` | This plan is no longer active. Please contact the platform administrator. |
| `LICENSE_CODE_PLAN_NOT_ACTIVE` | This license is linked to a plan that is no longer active. Please contact the platform administrator. |
| `TENANT_NAME_ALREADY_USED` | An organization with this name already exists. |
| `TENANT_CODE_ALREADY_USED` / `REQUESTED_CODE_ALREADY_USED` | This organization code is already in use. |
| `STUDENT_ALREADY_IN_CLASS` | This student is already enrolled in the selected class. |
| `DUPLICATE_EMAIL_IN_BATCH` | Some email addresses appear more than once in the uploaded file. |
| `INVALID_LOGIN` | The username or password is incorrect. |
| unknown machine code | We could not complete this action. Please try again or contact support. |

## Phases

- [x] Phase 1: Shared `ApiError` safety boundary and message formatter
- [x] Phase 2: Vendor-web migration and archived plan UX
- [x] Phase 3: Tenant-web migration, auth safety and error boundaries
- [x] Phase 4: Additive backend contract, guardrails and regression/handoff

## Dependency graph

```text
P1 ──┬──> P2 ──┐
     └──> P3 ──┴──> P4
```

P1 must land first so every screen uses one extraction and fallback policy. P2
and P3 are independent after P1. P4 runs only after both app migrations finish.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Message catalog misses a new backend code | Never render machine-shaped unknown values; use generic fallback and keep code in diagnostics. |
| Existing caller depends on `error.message` being a code | Add `ApiError.code`, migrate all comparisons, and add client tests for legacy response parsing. |
| Login UI leaks account existence | Preserve one generic message for 400/401 regardless of server code. |
| Dynamic validation message is accidentally replaced by generic text | Distinguish human-readable server messages from machine-shaped codes; add explicit tests. |
| Archived plan still appears editable through stale UI | Hide `Edit` for `ARCHIVED` and keep the fallback message for stale requests/bookmarks. |
| Error boundary exposes internal exception text | Use fixed safe copy in route error boundaries; log details only through diagnostics. |
| Shared formatter becomes a hidden presentation dependency | Keep it small, English-only for this scope, document future localization as a separate concern. |

## Global acceptance criteria

- No user-facing vendor/tenant screen renders a machine-shaped API code.
- Unknown API codes are never shown verbatim; they use a human fallback.
- Known billing, identity, enrollment and session conflicts have actionable
  messages.
- Login 400/401 behavior remains anti-enumeration safe.
- Archived plans cannot be edited from the catalog menu, and stale update
  attempts show a friendly explanation.
- API status codes, endpoint paths, plan lifecycle rules and existing successful
  response shapes remain unchanged.
- Both app typechecks, both app lint runs, backend compile, and both production
  builds pass. API-client/backend unit tests were explicitly skipped for this
  cook run; the existing Phase 1 API-client suite previously passed 232 tests.
- A final repository scan finds no raw error rendering except explicitly
  documented diagnostic/logging code.

## Verification command set

From `pte-web/`:

```powershell
corepack pnpm --filter @pte/api-client test
corepack pnpm --filter @pte/api-client typecheck
corepack pnpm --filter vendor-web exec tsc --noEmit
corepack pnpm --filter tenant-web exec tsc --noEmit
corepack pnpm --filter vendor-web lint
corepack pnpm --filter tenant-web lint
corepack pnpm --filter vendor-web build
corepack pnpm --filter tenant-web build
```

From `pte-api/` (contract/regression safety):

```powershell
.\mvnw.cmd -pl app test
```

For this cook run, the two test commands above were intentionally not run per
the user's instruction. The completed gates and their exit codes are recorded
in `phase-04-cross-app-regression-and-handoff-verification-report.json`.

Final static scan:

```powershell
rg -n "error\.message|Error \? error\.message|ApiError\.message" `
  apps/vendor-web apps/tenant-web --glob '*.{ts,tsx}'
```

Every remaining hit must be a branch/diagnostic use, not user-facing render.

Backend contract smoke cases after phase 4:

- legacy error: `{ success, data, message }` remains readable;
- additive error: `{ success, data, message, code, userMessage }` is parsed;
- structured `data/details` remains intact and is never rendered blindly.

## Handoff

Implementation is complete and ready for manual commit/review. Quality receipts
for all four phases are stored under `quality/`; no commit, push, or deploy was
performed.
