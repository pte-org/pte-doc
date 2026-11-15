# Phase 3: Giới hạn 72 byte cho mật khẩu

Status: Completed

## Requirements

- Mật khẩu dài hơn 72 byte UTF-8 bị từ chối với thông báo validation rõ ràng (HTTP 400), không còn lỗi 500.
- Áp dụng cho đổi mật khẩu, đặt lại mật khẩu (link và quản trị), tạo tài khoản.
- Mật khẩu hiện có và đăng nhập không đổi.

## Design Constraints

- Giới hạn tính theo byte UTF-8 vì đó là giới hạn của BCrypt, không phải số ký tự.
- Một ràng buộc dùng chung `@MaxUtf8Bytes`, chuỗi lỗi trong `IdentityConstants` (cạnh `PASSWORD_MIN_LENGTH`).

## Related files

- `pte-api/app/src/main/java/com/pte/identity/internal/validation/MaxUtf8Bytes.java` và validator (mới)
- `pte-api/app/src/main/java/com/pte/identity/internal/constant/IdentityConstants.java`
- Năm DTO: `ChangePasswordRequest`, `PasswordResetConfirmRequest`, `ResetPasswordRequest`, `CreateUserRequest`, `PlatformUserCreateRequest`
- `pte-api/app/src/test/java/com/pte/identity/internal/validation/MaxUtf8BytesTest.java`

## Steps

1. Annotation `@MaxUtf8Bytes(value = 72)` kèm `ConstraintValidator`.
2. Thêm `PASSWORD_TOO_LONG` vào `IdentityConstants`.
3. Gắn vào năm DTO.
4. Test: 72 byte hợp lệ; 73 byte không; tiếng Việt có dấu tính đúng theo byte; null hợp lệ (để `@NotBlank` lo).

## Quality/Testing State

- Test đơn vị mới và chạy lại test `identity`.
