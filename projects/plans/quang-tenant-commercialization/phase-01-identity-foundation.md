# Phase 1: Nền tảng định danh — `Tenant.code` & `User.username`

## Requirements

Tách khoá đăng nhập ra khỏi email. Thêm `User.username` (unique toàn cục) làm khoá duy nhất `AuthService` tra cứu, thêm `Tenant.code` làm tiền tố cho username của sinh viên. Bỏ `email` khỏi vai trò định danh. Backfill toàn bộ user hiện có.

Maps to: **[ADR-007](../../architecture/ADR-007-student-identity-and-login.md) § Decision**

## Design Constraints

- **Đây là phase duy nhất trong plan có thể làm sập đăng nhập của toàn hệ thống.** Không phase nào khác bắt đầu trước khi phase này xanh.
- Backfill `username = email` cho **mọi** user hiện có, **kể cả sinh viên**. Không sinh username mới cho sinh viên cũ — làm vậy là đá họ ra khỏi hệ thống và bắt trung tâm phát lại tài khoản cho toàn bộ roster.
- `Tenant.code` chỉ thêm cột ở phase này; việc *đặt* nó thuộc Phase 2 (lúc duyệt đơn). Tenant hiện có cần một giá trị backfill — sinh từ `Tenant.name` (slug hoá, khử trùng bằng hậu tố số).
- `email` chuyển sang nullable và **bỏ unique** — nhưng chỉ với đường tạo sinh viên. Các vai trò khác vẫn phải có email và `email` = `username` nên vẫn unique trên thực tế.
- `fullName` chuyển sang nullable (Phase 8 cần, thêm luôn ở đây để chỉ một lần migration đụng bảng `users`).
- Migration bắt đầu từ `V14` — `V1..V13` đã dùng.

## Steps

1. Migration `V14__identity_username.sql`:
   - `ALTER TABLE tenants ADD COLUMN code VARCHAR(32)` — chưa `NOT NULL`
   - Backfill `tenants.code` = slug của `name`, khử trùng bằng hậu tố số; rồi `SET NOT NULL` + `UNIQUE`
   - `ALTER TABLE users ADD COLUMN username VARCHAR(255)`
   - `UPDATE users SET username = email` — toàn bộ, không lọc role
   - `ALTER COLUMN username SET NOT NULL`, thêm `UNIQUE`
   - `ALTER TABLE users ALTER COLUMN email DROP NOT NULL`, **drop unique constraint trên email**
   - `ALTER TABLE users ALTER COLUMN full_name DROP NOT NULL`

2. `Tenant`: thêm `code` (`nullable = false, unique = true`). **Không** viết setter công khai — chỉ gán lúc tạo. Đổi `code` làm hỏng mọi username đã phát.

3. `User`: thêm `username` (`nullable = false, unique = true`); `email` bỏ `unique = true` và cho nullable; `fullName` cho nullable.

4. `UserRepository`: thêm `findByUsername`, `existsByUsername`. Giữ `findByEmail` cho luồng khôi phục mật khẩu.

5. `AuthService.login()`: đổi `findByEmail(request.email())` → `findByUsername(request.username())`. Đổi `LoginRequest.email` → `username` và cập nhật `IdentityConstants` tương ứng.

6. `UserService.create()`: gán `username = email` cho mọi vai trò không phải `STUDENT`. Đường tạo `STUDENT` chưa đụng ở phase này (Phase 8 lo) — tạm thời vẫn gán `username = email` như cũ.

7. Thêm `UsernameGenerator` trong `identity/internal/util/`: sinh `{tenant.code}.{random}`, phần random từ `SecureRandom`, độ dài đủ để không đoán được tài khoản của sinh viên khác. Chưa gọi ở phase này — Phase 8 dùng.

8. Test đăng nhập cho **từng vai trò**: `STUDENT`, `HOST_ADMIN`, `HOST_AUTHOR`, `PROCTOR`, `LECTURER`, `PROGRAM_COORDINATOR`, `PLATFORM_ADMIN`, `PLATFORM_AUTHOR`. Mỗi vai trò một test, không gộp.

9. Test rằng hai user ở hai tenant khác nhau tạo được với **cùng một email** — đây là điều trước đây bất khả thi và là lý do tồn tại của cả phase.

## Success Criteria

- Mọi user hiện có đăng nhập được bằng đúng thông tin cũ (email nay là `username`)
- Hai tenant khác nhau tạo được user cùng email, không còn `EmailAlreadyUsedException` xuyên tenant
- `tenants.code` có giá trị unique cho mọi tenant hiện có
- `UsernameGenerator` sinh được chuỗi có tiền tố tenant, có test thống kê không trùng trên 10.000 lần sinh
- App khởi động được với `ddl-auto: validate` — entity khớp schema Flyway vừa dựng

## Quality and Testing State

- Quality gate: chưa chạy
- Testing: chưa bắt đầu

## Session Notes

_(trống)_
