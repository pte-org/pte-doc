# Phase 02 — Forgot password API (pte-api)

**Stories:** P1 #2 (backend) · **FR:** 07–11 · **NFR:** rate limit, không lộ email, i18n mail
**Status:** [ ]
**Depends on:** Phase 01 (helper thu hồi phiên)

## Overview

Luồng tự đặt lại mật khẩu cho mọi role trừ STUDENT: yêu cầu bằng email → nhận link một lần → đặt mật khẩu mới.

## Files

- `db/migration/V17__password_reset_tokens.sql` (mới). Bảng `password_reset_tokens`: `id`, `public_id`, `user_id` (FK `users`), `token_hash` (unique), `expires_at`, `used_at`, `created_at`, `updated_at`, `deleted`. Index trên `user_id`.
- `identity/internal/domain/PasswordResetToken.java` (mới, kế thừa `BaseEntity`).
- `identity/internal/repository/PasswordResetTokenRepository.java` (mới): `findByTokenHash`, `invalidateActiveByUserId`.
- `identity/internal/repository/UserRepository.java`: `List<User> findAllByEmailIgnoreCaseAndDeletedFalse(String email)`.
- `identity/internal/service/PasswordResetService.java` (mới).
- `identity/internal/config/PasswordResetProperties.java` (mới): `app.web.tenant-url`, `app.web.admin-url`, `token-ttl` (mặc định 30 phút).
- `identity/PasswordResetEmailRequestedEvent.java` (mới, công khai cho `notification`): `requestId`, `email`, `locale`, `List<Link(username, url)>`.
- `notification/internal/listener/PasswordResetNotificationListener.java` (mới) + `NotificationType.PASSWORD_RESET_LINK_SENT` (cần migration nếu enum là DB check constraint; xem V9 làm mẫu).
- `identity/internal/controller/AuthController.java`: 2 endpoint mới. `identity/internal/config/SecurityConfig.java`: thêm 2 path vào `PUBLIC_PATHS`.
- `identity/internal/dto/request/auth/PasswordResetRequest.java`, `PasswordResetConfirmRequest.java` (mới).
- `identity/internal/exception/InvalidPasswordResetTokenException.java` (mới, 400).
- `resources/application.yml`: khối `app.web.*`. `docker-compose.deploy.yml`: truyền `APP_WEB_TENANT_URL=https://${TENANT_DOMAIN}`, `APP_WEB_ADMIN_URL=https://${ADMIN_DOMAIN}` cho service app. `.env.example` không đổi.

## Steps

1. **request(email, ip):**
   - Chuẩn hoá email (trim, lowercase).
   - Kiểm tra hai bucket Bucket4j trên `ProxyManager<String>` sẵn có: `pwreset:email:<sha256(email)>` (3/15 phút) và `pwreset:ip:<ip>` (10/15 phút). Hết lượt thì return luôn.
   - Lấy các tài khoản theo email, giữ lại tài khoản ACTIVE, có credential và không có role STUDENT.
   - Với mỗi tài khoản: vô hiệu token cũ, sinh token 32 byte (`SecureRandom`, base64url), lưu hash bằng `TokenHasher`, dựng link `<portal-url>/reset-password?token=…`.
   - Nếu có ít nhất một link thì phát `PasswordResetEmailRequestedEvent`.
   - Luôn trả 200, `data: null`.
2. **confirm(token, newPassword):**
   - Tìm token theo hash, có khoá ghi.
   - Token không tồn tại, đã dùng, hết hạn, hoặc user không còn ACTIVE → `InvalidPasswordResetTokenException`.
   - Set `used_at`, đổi hash mật khẩu, tắt `mustChangePassword`, `revokeAllForUser`, ghi audit `USER_PASSWORD_RESET_SELF`.
   - Không cần guard "đang thi" vì luồng này không áp dụng cho STUDENT.
3. **Listener:** mail song ngữ VI/EN (tiêu đề + nội dung), liệt kê từng username kèm link, ghi rõ hạn 30 phút và câu "Nếu bạn không yêu cầu, hãy bỏ qua email này". Dùng `dispatchExternalSensitive` để link không bị lưu vào lịch sử.
4. IP lấy từ `X-Forwarded-For` do Caddy đặt (lấy phần tử đầu), fallback `remoteAddr`. Kiểm tra cách `RateLimitFilter` đang lấy IP và làm giống.

## Design Constraints

- Token thô chỉ xuất hiện trong mail. Không log, không lưu, không trả về trong response.
- Phản hồi của `request` giống hệt nhau trong mọi nhánh. Không có nhánh nào trả lỗi, kể cả lỗi validation email: email sai định dạng vẫn trả 200, chỉ `@NotBlank` trả 400.
- Bảng mới thuộc module `identity`. Không tham chiếu bảng của module khác.
- Hibernate `ddl-auto: validate`: entity phải khớp migration.

## Tests

- `PasswordResetServiceTest`: email không tồn tại / STUDENT / SUSPENDED → không phát event; tài khoản hợp lệ → event có đúng link portal theo role; email dùng chung cho 2 tài khoản → 1 event, 2 link; token cũ bị vô hiệu khi yêu cầu lại; vượt rate limit → không phát event.
- confirm: thành công (đổi mật khẩu, thu hồi phiên, audit); token dùng lần 2 → 400; token hết hạn (dùng `Clock` giả) → 400.
- Integration: 2 endpoint public truy cập được khi không có JWT; response của email tồn tại và không tồn tại giống hệt nhau.

## Quality and Testing State

- Quality: not evaluated
- Testing: not started
