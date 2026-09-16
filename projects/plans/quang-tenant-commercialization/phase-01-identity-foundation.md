# Phase 1: Nền tảng định danh — `Tenant.code` & `User.username`

## Requirements

Tách khoá đăng nhập ra khỏi email. Thêm `User.username` (unique toàn cục) làm khoá duy nhất `AuthService` tra cứu, thêm `Tenant.code` làm tiền tố cho username của sinh viên. Bỏ `email` khỏi vai trò định danh. Backfill toàn bộ user hiện có.

Maps to: **[ADR-007](../../architecture/ADR-007-student-identity-and-login.md) § Decision**

## Design Constraints

- **Hệ thống chưa có dữ liệu thật (chốt 2026-09-16)** → không cần backfill, không cần lo đá user hiện có ra khỏi hệ thống. Schema viết thẳng dạng cuối cùng; DB local drop và dựng lại.
- Phase này vẫn phải làm **trước tất cả** — không vì rủi ro dữ liệu mà vì `Tenant.code` và `User.username` là nền của Phase 2 và Phase 8.
- `Tenant.code` chỉ thêm cột ở phase này; việc *đặt* nó thuộc Phase 2 (lúc duyệt đơn).
- `email` nullable và **bỏ unique** — chỉ có nghĩa với đường tạo sinh viên. Các vai trò khác vẫn phải có email và `email` = `username` nên vẫn unique trên thực tế.
- `fullName` chuyển sang nullable (Phase 8 cần, gộp luôn vào đây để chỉ một lần đụng bảng `users`).
- **Sửa thẳng `V2__identity.sql` và `V3__tenancy.sql`**, không thêm migration mới. Lịch sử migration nên kể câu chuyện của production — mà production chưa tồn tại. Cả đội `docker compose down -v` rồi dựng lại.
- **`V3__tenancy.sql` cũng bị [plan RLS](../quang-row-level-security/plan.md) P2 sửa** (đổi `organizations.tenant_id`/`quota_transactions.tenant_id` sang `UUID`). **RLS P2 merge trước, phase này rebase lên trên.** Một lần `docker compose down -v` chung cho cả hai plan.

## Steps

1. Sửa `V3__tenancy.sql`: `tenants` thêm `code VARCHAR(32) NOT NULL UNIQUE`.

2. Sửa `V2__identity.sql`:
   - `users` thêm `username VARCHAR(255) NOT NULL UNIQUE`
   - `email` bỏ `NOT NULL`, **bỏ unique constraint**
   - `full_name` bỏ `NOT NULL`

3. Thông báo cho cả đội drop volume Postgres trước khi pull — Flyway sẽ báo checksum mismatch nếu DB cũ còn đó. Đây là lần duy nhất trong plan được sửa migration đã tồn tại; từ Phase 2 trở đi chỉ thêm `V14`, `V15`, …

4. `Tenant`: thêm `code` (`nullable = false, unique = true`). **Không** viết setter công khai — chỉ gán lúc tạo. Đổi `code` làm hỏng mọi username đã phát.

5. `User`: thêm `username` (`nullable = false, unique = true`); `email` bỏ `unique = true` và cho nullable; `fullName` cho nullable.

6. `UserRepository`: thêm `findByUsername`, `existsByUsername`. Giữ `findByEmail` cho luồng khôi phục mật khẩu.

7. `AuthService.login()`: đổi `findByEmail(request.email())` → `findByUsername(request.username())`. Đổi `LoginRequest.email` → `username` và cập nhật `IdentityConstants` tương ứng.

8. `UserService.create()`: gán `username = email` cho mọi vai trò không phải `STUDENT`. Đường tạo `STUDENT` chưa đụng ở phase này (Phase 8 lo) — tạm thời vẫn gán `username = email` như cũ.

9. Thêm `UsernameGenerator` trong `identity/internal/util/`: sinh `{tenant.code}.{random}`, phần random từ `SecureRandom`, độ dài đủ để không đoán được tài khoản của sinh viên khác. Chưa gọi ở phase này — Phase 8 dùng.

10. Cập nhật seed/fixture dữ liệu dev (nếu có) để mọi user có `username`.

11. Test đăng nhập cho **từng vai trò**: `STUDENT`, `HOST_ADMIN`, `HOST_AUTHOR`, `PROCTOR`, `LECTURER`, `PROGRAM_COORDINATOR`, `PLATFORM_ADMIN`, `PLATFORM_AUTHOR`. Mỗi vai trò một test, không gộp — rẻ, và đây là thứ duy nhất chứng minh việc đổi khoá đăng nhập không làm hỏng vai trò nào.

12. Test rằng hai user ở hai tenant khác nhau tạo được với **cùng một email** — đây là điều trước đây bất khả thi và là lý do tồn tại của cả phase.

## Success Criteria

- Mọi vai trò đăng nhập được bằng `username`
- Hai tenant khác nhau tạo được user cùng email, không còn `EmailAlreadyUsedException` xuyên tenant
- `tenants.code` là `NOT NULL UNIQUE`
- `UsernameGenerator` sinh được chuỗi có tiền tố tenant, có test thống kê không trùng trên 10.000 lần sinh
- App khởi động được với `ddl-auto: validate` — entity khớp schema Flyway vừa dựng

## Quality and Testing State

- Quality gate: chưa chạy
- Testing: chưa bắt đầu

## Session Notes

_(trống)_
