# Phase 1: Shared `ApiError` safety boundary and message formatter

## Objective

Tạo một contract client-side duy nhất để tách machine code khỏi UI message,
đồng thời giữ backward compatibility với response hiện tại chỉ có
`success/data/message`.

## Scope

Files dự kiến:

- `pte-web/packages/api-client/src/client/apiError.ts`
- `pte-web/packages/api-client/src/client/client.ts`
- `pte-web/packages/api-client/src/client/index.ts`
- `pte-web/packages/api-client/src/index.ts`
- `pte-web/packages/api-client/src/client/client.test.ts`
- file mới cho formatter/message catalog và test tương ứng trong
  `packages/api-client/src/client/`

## Steps

1. Thêm `ApiError.code?: string`, `userMessage?: string` và raw/server
   diagnostic metadata cần thiết;
   không để caller phải parse HTTP body.
2. Tách code từ `body.code` nếu contract tương lai đã có; đọc
   `body.userMessage` nếu có; fallback nhận diện machine code từ `body.message`
   của contract hiện tại.
3. Giữ `ApiError.message` để tương thích legacy trong phase đầu; không cho UI
   render trực tiếp field này. Formatter mới là boundary duy nhất cho text hiển
   thị, còn raw body chỉ nằm trong `details`.
4. Implement `getUserFacingApiErrorMessage(error, fallback?)` với:
   - catalog business code;
   - fallback theo `ApiError.kind`/status;
   - bảo toàn validation text rõ ràng;
   - generic fallback cho unknown code, raw `Error`, network, server failure và 429.
5. Export formatter và type từ public package entrypoint.
6. Ghi rõ trong code comment rằng `ApiError.code` dùng cho branch logic, còn
   formatter là boundary duy nhất cho text hiển thị.

## Design Constraints

Preflight: `@pte/api-client` uses named exports from `src/client/index.ts` and
`src/index.ts`, `ApiError` is a small `Error` subclass, and Vitest tests inject
`fetchFn`; preserve those conventions while keeping request/refresh behavior
unchanged.

- Không đổi endpoint, HTTP status, request payload hoặc success response.
- Không log token, password, raw response chứa dữ liệu nhạy cảm.
- Không dùng `Error.message` làm code branch sau khi phase này hoàn tất.
- Không tự động hiển thị JSON `details` cho người dùng.
- Không pass through dynamic server text nếu chưa xác định đó là validation
  message được phép hiển thị; 5xx/provider failure luôn dùng generic copy.
- Message catalog English-only trong phase này; localization là scope riêng.

## Quality and Testing State

- Quality: approved — `quality/phase-01-shared-api-error-safety-quality-report.json`
  with a valid receipt.
- Testing: passed — `tests/phase-01-shared-api-error-safety-test-report.json`
  (232 tests passed, 0 failed).

### Tests to add/run

- Legacy `{ success: false, data: null, message: "PLAN_ARCHIVED_NOT_EDITABLE" }`
  tạo ra `code` đúng và UI message không chứa code.
- Future `{ success: false, data: null, code: "...", message: "..." }`
  ưu tiên `code` riêng.
- Future `{ success: false, data: null, code: "...", userMessage: "..." }`
  ưu tiên user message an toàn cho phần hiển thị, nhưng không dùng nó cho
  branch logic.
- Human validation message được giữ nguyên.
- Unknown machine code, `INTERNAL_ERROR`, network, 401 và 403 đều có fallback
  thân thiện.
- Existing unwrap, refresh-token retry và upload/download behavior không đổi.

## Exit criteria

- API-client tests và typecheck pass.
- Hai app có thể import formatter từ public package.
- Có test chứng minh formatter không trả raw machine code làm UI message.
