# Phase 3: Quên mật khẩu và đổi mật khẩu cho học viên

Preflight: Unit tests created and run: no (skipped_by_user) · ck:quality gate: skipped_by_user
Status: Completed · Yêu cầu: form đổi mật khẩu trong Cài đặt và quên mật khẩu "làm giống bên pte-web"; bỏ nút điền nhanh "Chỉ dùng khi dev"

## Requirements

- Trong Cài đặt có mục Mật khẩu: bấm "Đổi mật khẩu" mở form ba ô (mật khẩu hiện tại, mới, nhập lại) giống form của `pte-web`.
- Trang đăng nhập có "Quên mật khẩu?": nhập tên đăng nhập và e-mail, nhận link đặt lại; link mở `/reset-password`.
- Học viên đổi mật khẩu thành công trong Cài đặt thì **không bị đăng xuất**, các thiết bị khác thì bị.
- Gõ sai mật khẩu hiện tại thì báo lỗi và học viên vẫn ở trong app.
- Bỏ hẳn nút điền nhanh tài khoản dev ở trang đăng nhập.

## Design Constraints

- **Đảo quyết định của `hung-password-reset-email`:** plan đó để học viên tự đặt lại qua e-mail ngoài phạm vi (P3). Giờ `isEligible` ở `PasswordResetService` không còn loại học viên; xem R1 ở `plan.md`.
- Link e-mail theo vai trò: vai trò nền tảng → `app.web.admin-url`; **chỉ có STUDENT → `app.web.practice-url`**; còn lại (kể cả học viên kiêm vai trò nhân sự) → `app.web.tenant-url`.
- Phản hồi của `password-reset/request` không phụ thuộc tài khoản có tồn tại hay không; màn hình "kiểm tra hộp thư" cũng giống hệt trong mọi trường hợp.
- `change-password` gọi với `allowRefresh: false`: nếu refresh trước thì refresh token trong body đã bị xoay, server sẽ thu hồi luôn chính phiên này như "thiết bị khác".
- 401 mã `INVALID_LOGIN` không được xoá phiên của học viên.
- Server từ chối đổi mật khẩu khi học viên đang có lượt thi `IN_PROGRESS` (409 `STUDENT_ATTEMPT_IN_PROGRESS`); hiện thông báo riêng.
- Kiểm tra form trong Cài đặt **đúng thứ tự và lời văn của `pte-web`** (`ChangePasswordView`, `validateNewPassword`): thiếu ô → dưới 8 ký tự → dấu cách đầu/cuối → hai ô không khớp. Thiếu ô là **một** câu chung cho cả ba ô; form có `noValidate` để câu của mình hiện thay vì bong bóng của trình duyệt; không chặn `maxLength` (cắt ngầm khi dán làm học viên đặt ra mật khẩu khác cái họ tưởng); lỗi 400 của server hiện nguyên văn như bên portal.
- Cỡ form trong Cài đặt khớp các ô xung quanh: ô cao 38px, nút `size="sm"`.

## Related files

`pte-api`: `identity/internal/service/passwordreset/PasswordResetService.java` (`isEligible`, `baseUrlOf`), `identity/internal/config/WebAppProperties.java`, `app/src/main/resources/application.yml` (`app.web.practice-url`), `docker-compose.deploy.yml` (`APP_WEB_PRACTICE_URL`), `PasswordResetServiceTest.java`.

`pte-practice`: `common/components/PasswordField.tsx`, `features/auth/{AuthShell.tsx,ForgotPasswordForm.tsx,ResetPasswordView.tsx,forgot-password-param.ts,password-rules.ts,ChangePasswordForm.tsx,SignInView.tsx,SignInForm.tsx}`, `app/(auth)/{reset-password,sign-in}/page.tsx`, `features/settings/PasswordSettings.tsx`, `features/practice/{api.ts,constants.ts}`. Xoá: `features/auth/dev-accounts.ts`, `tests/unit/features/auth/dev-accounts.test.ts`, biến `NEXT_PUBLIC_DEV_TEST_ACCOUNTS`.

## Steps

1. Backend: bỏ `!roles.contains(STUDENT)` khỏi `isEligible`; thêm `practiceUrl` và `baseUrlOf`; sửa ba test đang khoá chính sách cũ (học viên → link về practice; học viên free không có tổ chức → cũng về practice; kiêm PROCTOR → về tenant) và đổi test "học viên hoặc tài khoản bị tạm ngưng" thành chỉ còn tài khoản bị tạm ngưng.
2. `PasswordField` dùng chung (nút hiện/ẩn, một nút mở cả hai ô mới) và `newPasswordError` (rỗng → ≥ 8 ký tự → không dấu cách đầu/cuối → hai ô khớp).
3. `AuthShell` tách khung trang đăng nhập; `ForgotPasswordForm` và `ResetPasswordView` theo form của `pte-web` (kiểm tra link trước khi cho gõ; link hỏng → "Yêu cầu link mới" mở thẳng bước quên mật khẩu qua `/sign-in?forgot=1`; xong thì toast và về trang đăng nhập).
4. `PasswordSettings` trong Cài đặt; sửa `practiceRequest` để 401 `INVALID_LOGIN` không xoá phiên.
5. Xoá nút điền nhanh dev, CSS, chuỗi i18n và biến môi trường.
6. `docker-compose.deploy.yml`: `APP_WEB_PRACTICE_URL: https://${PRACTICE_DOMAIN:-pte-practice.duckdns.org}`.
7. Form Cài đặt: thu nhỏ ô và nút (`f8bfd5c`); gộp thiếu ô thành một câu, thêm `noValidate`, bỏ `maxLength`, hiện câu lỗi 400 của server (`77ddc3b`). Hai khoá i18n `settings.passwordAllRequired` và `settings.changePasswordFailed` thay `settings.currentPasswordRequired`.

## Success Criteria

- Học viên có e-mail bấm Quên mật khẩu, nhận thư, link mở trang đặt lại của practice; đặt xong đăng nhập được bằng mật khẩu mới, mật khẩu cũ hết hiệu lực.
- Link đã dùng hoặc hết hạn hiện "This link cannot be used".
- Trong Cài đặt: mật khẩu hiện tại sai → báo lỗi và vẫn đăng nhập; đúng → báo thành công.
- Học viên đang thi nhận thông báo "chưa đổi được mật khẩu".
- Trang đăng nhập không còn dòng "Chỉ dùng khi dev".

## Quality and Testing State

- Quality: skipped_by_user
- Testing: skipped_by_user. Đã chạy lại 52 test reset mật khẩu của `pte-api` (đạt).
- Một thư thật đã được gửi tới e-mail của tài khoản test khi thử `password-reset/request` ở môi trường local, vì `.env` local trỏ SMTP thật.
