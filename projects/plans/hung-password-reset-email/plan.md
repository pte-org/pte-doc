# Plan: Đặt lại mật khẩu qua email

**Spec:** [spec.md](spec.md) · **Brainstorm:** [261031-password-reset-email-brainstorm](../reports/261031-password-reset-email-brainstorm.md)
**Mode:** Hard (bảo mật, 4 repo, thêm bảng mới)
**Branch:** `hung/feat/password-reset-email` (cùng tên ở pte-api, pte-web, pte-app, pte-doc)
**Status:** Ready

## Phases

| # | Phase | Repo | Stories | Status |
|---|---|---|---|---|
| 01 | [Credential policy: chặn khi đang thi, thu hồi phiên, cho gửi mail học viên](phase-01-credential-policy.md) | pte-api | P1 #1 (BE), P1 #4 | [x] |
| 02 | [Forgot password: token, endpoint, mail, rate limit](phase-02-forgot-password-api.md) | pte-api | P1 #2 (BE) | [ ] |
| 03 | [tenant-web: mục Send password via email cho học viên](phase-03-tenant-student-email.md) | pte-web | P1 #1 (UI) | [ ] |
| 04 | [tenant-web + vendor-web: trang forgot/reset, nhận token mới khi đổi mật khẩu](phase-04-web-forgot-password.md) | pte-web, pte-practice | P1 #2 (UI), P1 #4 (client) | [ ] |
| 05 | [pte-app: buộc đổi mật khẩu + hướng dẫn quên mật khẩu](phase-05-app-must-change-password.md) | pte-app | P1 #3, P2 #5 | [ ] |

Thứ tự: 01 → 02 → (03, 04, 05 làm song song được). Phase 03–05 chỉ cần contract API của 01–02.

## Contract API (các phase sau bám theo đây)

| Method | Path | Auth | Ghi chú |
|---|---|---|---|
| POST | `/api/v1/users/{id}/credentials/send-email` | Host/Platform Admin | Có sẵn. Bỏ chặn STUDENT, thêm 409 `STUDENT_ATTEMPT_IN_PROGRESS` |
| POST | `/api/v1/users/{id}/credentials/generate` | Host | Có sẵn. Thêm 409 |
| POST | `/api/v1/users/{id}/reset-password` | Host/Platform Admin | Có sẵn. Thêm `mustChangePassword`, thu hồi phiên, 409 |
| POST | `/api/v1/auth/change-password` | Đã đăng nhập | Response giữ `Void`. Body thêm `refreshToken` tuỳ chọn: có → thu hồi mọi phiên khác, giữ phiên này; không có → không thu hồi (client cũ). Thêm 409 |
| POST | `/api/v1/auth/password-reset/request` | Public | `{ email }` → luôn 200, `data: null` |
| POST | `/api/v1/auth/password-reset/confirm` | Public | `{ token, newPassword }` → 200 / 400 `INVALID_PASSWORD_RESET_TOKEN` |

## Quyết định chính

- Không cho đổi credential của học viên đang có lượt thi `IN_PROGRESS` → 409. Nhờ vậy mọi lần đổi credential đều thu hồi toàn bộ refresh token, không có ngoại lệ.
- `change-password` tương thích ngược (2026-10-31, Hung chọn không release đồng loạt): client mới gửi `refreshToken` của mình để server giữ phiên đó và thu hồi các phiên khác; client cũ vẫn chạy như hiện nay.
- Host/Platform Admin tự đặt mật khẩu cho người khác thì bật `mustChangePassword` (Hung xác nhận).
- Link reset lấy domain từ `app.web.tenant-url` / `app.web.admin-url`.
- Email không unique trong `users` (chỉ có index). "Quên mật khẩu" gửi **một** mail, mỗi tài khoản đủ điều kiện có một link riêng kèm username (Hung xác nhận).
- **Do Claude quyết định:** tài khoản có role nền tảng (Platform Admin/Manager, Academic Manager/Staff) nhận link vendor-web; các tài khoản khác nhận link tenant-web.

## Risks

- Tới khi mọi client gửi `refreshToken`, việc tự đổi mật khẩu từ client cũ chưa đăng xuất được các máy khác. Phase 04/05 bịt dần; khi xong thì mở ticket bắt buộc trường này.
- Rò rỉ email tồn tại qua thời gian phản hồi. Giảm bằng cách luôn làm cùng khối lượng việc đồng bộ và để gửi mail đi qua RabbitMQ (`@TransactionalEventListener` → `NotificationDispatchService`).
- Mật khẩu tạm của học viên nằm nguyên văn trong hộp thư. Giảm nhờ `mustChangePassword` (Phase 05 bịt pte-app, kênh cuối cùng còn thiếu).
- Kiểm tra `IN_PROGRESS` đi qua `StartedAttemptLookup` (port trong `shared`), không để `identity` phụ thuộc trực tiếp vào `attempt` (ADR-001 #3).
