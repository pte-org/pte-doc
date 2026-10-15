# Phase 05: Regression và quality gate

Status: Implemented — targeted gates passed; full suite has a repository-level module-structure gate  
Depends on: Phase 01, 02, 03, 04

## Mục tiêu

Chứng minh lifecycle mới đúng ở backend, notification, persistence, frontend và Docker-backed runtime; không kết luận complete chỉ từ compile.

## Backend verification

1. Chạy compile và test scope session/lifecycle/notification/scoring:
   - `.mvnw.cmd -pl app -DskipTests compile`
   - `.mvnw.cmd -pl app test`
2. Chạy integration với PostgreSQL/RabbitMQ thật trong Compose cho:
   - transition allow/deny;
   - cancellation event sau commit;
   - notification recipient filtering;
   - auto-close;
   - deleted draft visibility.
3. Kiểm tra audit log:
   - actor/target/status transition đúng;
   - không có password, token, license secret;
   - cancel/delete/auto-close có event name ổn định.
4. Kiểm tra tenant isolation và direct API:
   - host tenant khác không đọc/thao tác session;
   - student recipient không xuất hiện trong cancellation notification;
   - inactive/deleted staff không nhận.

## Frontend verification

- `pnpm --filter tenant-web exec tsc --noEmit`
- `pnpm --filter @pte/api-client typecheck`
- `pnpm --filter @pte/ui typecheck`
- scoped lint/prettier cho files thay đổi
- `pnpm --filter tenant-web build`
- smoke detail/list menu cho DRAFT, PREPARING, READY, SCHEDULED, OPEN, CLOSED, CANCELLED
- kiểm tra common toast/action menu, không tạo Archive filter/action

## Runtime verification

- Chạy Compose từ `pte-api` với đúng `.env.local`, không in secrets.
- Kiểm tra app, PostgreSQL, Redis, RabbitMQ, Mailpit healthy.
- Dùng browser/network để xác nhận action gọi đúng API và response status.
- Playwright log/screenshot nếu có phải nằm ở `D:\GitHub\pte-org\.playwright-mcp`, không nằm trong `pte-web`.
- Report trong `pte-doc` chỉ giữ text/JSON cần thiết; không thêm ảnh runtime vào repo.

## Acceptance criteria

- Tất cả phase 01–04 có test evidence.
- Không còn BLOCKER/HIGH hoặc current-change MEDIUM từ quality review.
- Notification contract được chứng minh chỉ gửi tới assigned active PROCTOR/EXAMINER.
- Không có Archive UI/API/status.
- Known limitations và phần chưa kiểm chứng production được ghi rõ trong quality report.

## Artifacts

- `pte-doc/plans/quang-exam-session-lifecycle/quality/phase-05-quality-report.json`
- `pte-doc/plans/quang-exam-session-lifecycle/tests/phase-05-test-report.json`
- `pte-doc/plans/reports/261013-exam-session-business-rules-audit.md`
