# Tenant-web: đổi ngôn ngữ và dịch các màn đăng nhập

## Yêu cầu
Các màn Welcome Back (đăng nhập), Set a new password (đăng nhập lần đầu) và Change your password chưa có nút đổi ngôn ngữ; nút sáng/tối cần hoạt động; dịch cả lỗi.

## Hiện trạng đã kiểm tra
- Cả 5 màn (đăng nhập, quên mật khẩu, đặt lại mật khẩu, đổi mật khẩu, đặt mật khẩu lần đầu) cùng nằm trong `AuthPageShell` nên chỉ cần thêm `LocaleSwitcher` vào `toolbar` của `AuthBrandShell`.
- Nút sáng/tối (`ThemeToggle`) đã có sẵn trong `AuthBrandShell`; thử trên trình duyệt thấy đổi sang dark và về light đúng. Ảnh chụp màn đổi mật khẩu bị cắt phần đầu trang nên không thấy nút.

## Thay đổi (pte-web/apps/tenant-web/features/auth)
- `AuthPageShell`: thêm `LocaleSwitcher`, footer/nhãn lấy theo ngôn ngữ.
- `authVietnamese.ts` (mới): bản tiếng Việt cho đăng nhập, đổi mật khẩu, đặt mật khẩu lần đầu, quên/đặt lại mật khẩu, liên kết, lỗi.
- `hooks/useAuthCopy.ts` (mới): chọn bảng văn bản theo ngôn ngữ; 5 view dùng hook này.
- `authErrors.ts` (mới): lỗi từ server — tiếng Việt ánh xạ theo loại/mã (mất kết nối, 429, 5xx, liên kết hết hạn), còn lại dùng câu của màn hình; tiếng Anh giữ catalog chung.
- Ví dụ username đổi sang `school.nguyenvana` cho khớp quy tắc mới; "centre" -> "center".

## Kết quả thực hiện
- `tsc`, eslint sạch; vitest 1082/1082 (sửa test FirstPasswordChange cho `LocaleProvider`, thêm test `authErrors`).
- Thử trên trình duyệt: nút VI/EN và sáng/tối hiển thị ở đầu trang đăng nhập, chuyển VI -> EN đúng, dark mode đúng.
- Chưa thử gửi đăng nhập sai/đổi mật khẩu thật để xem từng thông báo lỗi tiếng Việt trên trình duyệt (đã có unit test cho hàm ánh xạ).
- Menu người dùng trong dashboard (`USER_MENU_TEXT`) chưa dịch; ngoài phạm vi.

## Vòng 2: validation mật khẩu và lỗi lẫn ngôn ngữ
- Lỗi gốc (ảnh người dùng gửi): trang đặt mật khẩu hiện tiếng Anh nhưng lỗi "Mật khẩu mới không khớp." tiếng Việt, vì form lưu *câu* lỗi trong state nên đổi ngôn ngữ sau đó không đổi theo.
  Sửa: `ResetPasswordForm`, `ForgotPasswordForm`, `useSignInValidation` (đăng nhập), `ChangePasswordView` của tenant-web và vendor-web nay lưu *loại lỗi*, câu được dựng lúc hiển thị.
- Đối chiếu validation BE (`ChangePasswordRequest`, `PasswordResetConfirmRequest`): bắt buộc, tối thiểu 8 ký tự, không khoảng trắng đầu/cuối, tối đa 72 byte UTF-8 (BCrypt), khớp xác nhận.
  FE trước đó thiếu quy tắc 72 byte: thêm `MAX_PASSWORD_BYTES`, `exceedsMaxPasswordBytes`, loại lỗi `TOO_LONG` + câu `tooLong`/`TOO_LONG` (EN/VI) cho đặt lại, đặt lần đầu, đổi mật khẩu (cả vendor-web).
  Thứ tự kiểm tra: bắt buộc, quá ngắn, khoảng trắng đầu/cuối, quá dài, không khớp.
- Lỗi validation từ server bằng tiếng Anh được ánh xạ sang tiếng Việt theo nội dung (`getAuthFailureMessage` + `PasswordProblemText`).
- Kiểm tra: ui 398 test, tenant-web 1082, vendor-web 748, `tsc`/eslint sạch. Trình duyệt: lỗi đăng nhập đổi VI -> EN ngay khi bấm nút ngôn ngữ.
- Chưa thử trực tiếp màn đặt mật khẩu lần đầu và đổi mật khẩu trên trình duyệt (cần tài khoản đang ở mật khẩu tạm / đã đăng nhập); đã có test đơn vị cho quy tắc.

- Dấu tick xanh ở ô mật khẩu: `AuthTextField` chỉ hiểu "có nội dung và không có lỗi" nên ô sai quy tắc vẫn tick. Thêm prop `valid`; `ResetPasswordForm` tick ô mật khẩu mới chỉ khi qua đủ quy tắc (>=8, không khoảng trắng đầu/cuối, <=72 byte) và ô xác nhận chỉ khi khớp. Ô đăng nhập giữ hành vi cũ.

- Hai con mắt ở ô mật khẩu: Edge tự vẽ nút hiện mật khẩu (`::-ms-reveal`) bên cạnh nút của app. Ẩn `::-ms-reveal` và `::-ms-clear` toàn cục trong `design-tokens.css` (dùng chung tenant-web và vendor-web). Không có test; chỉ Edge bị ảnh hưởng.
