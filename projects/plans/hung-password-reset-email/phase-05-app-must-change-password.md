# Phase 05 — pte-app: buộc đổi mật khẩu + hướng dẫn quên mật khẩu

**Stories:** P1 #3, P2 #5 · **FR:** 15, 16
**Status:** [ ]
**Depends on:** contract của Phase 01 (`change-password` nhận `refreshToken` tuỳ chọn)

## Overview

pte-app hiện bỏ qua `mustChangePassword`. Đăng nhập với cờ này phải đi qua màn hình đổi mật khẩu trước khi tới device check hay bài thi.

## Files

- `lib/features/auth/data/repositories/auth_repository_impl.dart`: đọc `mustChangePassword` từ phản hồi login; thêm `changePassword(current, new)`, gửi kèm `refreshToken` đang lưu.
- `lib/features/auth/domain/repositories/auth_repository.dart`: khai báo hàm mới.
- `lib/features/auth/presentation/bloc/auth_event.dart`, `auth_state.dart`, `auth_bloc.dart`: thêm event `AuthPasswordChangeSubmitted` và state `AuthPasswordChangeRequired`.
- `lib/features/auth/presentation/pages/change_password_page.dart` (mới).
- `lib/features/auth/presentation/pages/login_page.dart`: dòng "Quên mật khẩu? Liên hệ trung tâm của bạn."
- `lib/features/auth/constants/auth_strings.dart`: thêm chuỗi (tạo file nếu chưa có, theo quy ước `*_strings.dart`).
- `lib/app.dart`: điều hướng theo state mới.

## Steps

1. Login trả `mustChangePassword = true` → bloc phát `AuthPasswordChangeRequired`, giữ token tạm để gọi `change-password`, **không** cho vào luồng thi.
2. `ChangePasswordPage`: mật khẩu hiện tại (điền sẵn mật khẩu vừa nhập ở màn login), mật khẩu mới, nhập lại. Validate ≥ 8 ký tự và khớp nhau.
3. Thành công → giữ session → chuyển sang luồng sau đăng nhập bình thường. Lỗi 409 (đang thi) gần như không xảy ra ở đây, nhưng vẫn hiện thông báo chung.
4. Login page: thêm dòng hướng dẫn liên hệ trung tâm, không có form.

## Design Constraints

- Theo `pte-app/CLAUDE.md`: event là sealed class; state bất biến, không dùng cờ boolean; `build()` ≤ 50 dòng; `dispose()` mọi `TextEditingController`/`FocusNode`; kiểm tra `mounted` sau `await`; màu dùng `AppColors`; chuỗi đặt trong file strings của feature.
- Không lưu mật khẩu xuống storage.

## Tests

- `auth_bloc_test`: login với `mustChangePassword` → state `AuthPasswordChangeRequired`; đổi thành công → authenticated, request có `refreshToken`; đổi thất bại → state lỗi, vẫn ở màn đổi mật khẩu.
- Widget test `ChangePasswordPage`: validate, nút submit bị khoá khi không hợp lệ.

## Quality and Testing State

- Quality: not evaluated
- Testing: not started
