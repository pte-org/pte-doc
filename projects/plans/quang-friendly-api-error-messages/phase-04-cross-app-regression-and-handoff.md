# Phase 4: Additive backend contract, guardrails and regression/handoff

## Objective

Hoàn thiện contract lỗi theo hướng additive sau khi hai web app đã chuyển sang
dùng `ApiError.code` và formatter chung; đồng thời chứng minh không làm gãy
client cũ, không còn raw-code leak và có thể handoff cho implementation/review.

## Scope

- `pte-api/app/src/main/java/com/pte/shared/web/ApiResponse.java`
- `pte-api/app/src/main/java/com/pte/shared/exception/DomainException.java`
- `pte-api/app/src/main/java/com/pte/shared/exception/GlobalExceptionHandler.java`
- các test serialization/exception handler trong `pte-api/app`
- `pte-web/packages/api-client/src/client/client.ts` và các type/test liên quan
- `docs/CODING_STANDARDS_API.md`
- `pte-web/docs/CODING_STANDARDS_WEB.md`

## Steps

1. Bổ sung `code` và `userMessage` tùy chọn vào `ApiResponse` theo hướng
   additive; giữ nguyên field legacy `message`, HTTP status, `success`, `data`
   và shape của các response thành công. Giữ hoặc bổ sung factory/constructor
   tương thích để các call site `new ApiResponse<>(success, data, message)` và
   `ApiResponse.success/error(...)` không bị break ngoài ý muốn.
2. Chỉ mở rộng `DomainException`/`GlobalExceptionHandler` ở mức an toàn để
   phát ra metadata mới; không đổi `getMessage()` trong đợt này vì test và
   consumer hiện tại vẫn dùng machine code legacy. Không big-bang migrate toàn
   bộ khoảng 114 exception subclasses.
3. Mở rộng `ApiResponseEnvelope` và parser của api-client để đọc `code`,
   `userMessage` và structured data; sửa các field không tồn tại trong response
   thực tế thành optional/đúng nghĩa. Formatter ưu tiên user message an toàn từ
   backend, sau đó mới tới catalog phía client. Raw code vẫn nằm ở field dành
   cho branch/diagnostic, không được render trực tiếp.
4. Thêm test backend cho cả envelope legacy
   `{ success, data, message }` và envelope additive
   `{ success, data, message, code, userMessage }`; bảo đảm structured data của
   các lỗi như quota/question-bank vẫn còn nguyên và không bị stringify vào UI.
5. Chạy toàn bộ API-client tests/typecheck và backend `app` test suite để xác
   nhận code/status/lifecycle guard hiện tại vẫn giữ nguyên.
6. Chạy typecheck, lint và production build cho vendor-web và tenant-web.
7. Rà static search các pattern `error.message`, `Error.message`,
   `ApiError.message` trong hai app; phân loại mọi hit còn lại là branch logic
   hoặc diagnostic hợp lệ, không phải user-facing render.
8. Cập nhật `CODING_STANDARDS_API.md` và `CODING_STANDARDS_WEB.md`: phân biệt
   machine code, user-facing message và diagnostic details; cấm render raw
   exception/server message tại UI boundary.
9. Chạy browser smoke với local seeded admin/host, không tạo dữ liệu
   production; ghi verification report gồm command, exit code, test count và
   các giới hạn runtime còn lại.

## Design Constraints

Preflight: both web applications now consume `ApiError.code` and the shared
formatter; the backend can add `code` and `userMessage` while retaining the
legacy `message`, status, success flag, data, and existing constructors.

- Không đổi ý nghĩa legacy `ApiResponse.message` trong đợt đầu; client ngoài
  `pte-web` vẫn phải đọc được contract cũ.
- Không đổi endpoint, HTTP status, request payload, lifecycle rule hoặc quyền
  hiện tại chỉ để phục vụ message UX.
- Không expose stack trace, provider message, token, password hoặc raw
  structured data ra UI.
- Không yêu cầu migrate đồng loạt mọi `DomainException`; các code chưa có
  `userMessage` an toàn phải đi qua generic fallback phía client.
- Không commit, push hoặc deploy trong phase này.
- Không reset/ghi đè thay đổi dirty worktree không liên quan.
- Không dùng production credentials hoặc in secret/env value.
- Nếu một test fail do dirty-worktree file ngoài scope, ghi rõ thay vì bỏ qua.

## Quality and Testing State

- Quality: approved — `quality/phase-04-cross-app-regression-and-handoff-quality-report.json` with valid receipt.
- Testing: unit tests skipped by user — compile, typecheck, lint, build, static scans, and browser login smoke run.

### Release gate

- API-client: typecheck pass; tests explicitly skipped by user.
- Backend: `mvnw -pl app -DskipTests compile` pass; tests explicitly skipped by user.
- Vendor/tenant: typecheck, lint, build pass.
- Legacy và additive error envelope đều được parse đúng; structured error data
  vẫn được bảo toàn.
- Hai coding-standard docs mô tả rõ boundary hiển thị lỗi thân thiện.
- Browser: known error flows show friendly copy; no machine code visible.
- Static scan: no user-facing raw error render remains.

## Exit criteria

- Có evidence report cho bốn nhóm gate.
- Không còn blocker/high finding chưa xử lý.
- Plan đã được cập nhật status Completed và sẵn sàng cho manual commit/review;
  không commit, push hoặc deploy trong phase này.
