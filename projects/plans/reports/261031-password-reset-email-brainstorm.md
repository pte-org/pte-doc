# Brainstorm: Đặt lại mật khẩu qua email cho mọi role

**Date:** 2026-10-31

## Hiện trạng (đọc từ code)

- `identity/internal/service/user/UserCredentialRotation` có ba đường:
  - `resetPassword`: operator tự đặt mật khẩu cho người khác, **không** bật `mustChangePassword`, **không** thu hồi refresh token.
  - `sendGeneratedCredentials`: sinh mật khẩu tạm + gửi mail. **Chặn STUDENT** (`StudentCredentialEmailNotAllowedException`).
  - `generateStudentCredentials`: sinh mật khẩu tạm cho học viên, chỉ trả về cho Host, không gửi mail.
- Phân quyền: Platform Admin quản lý Host và nhân sự nền tảng; Host quản lý Proctor/Examiner/Student, và chỉ đổi credential của tài khoản do riêng tổ chức đó sở hữu (`isExclusivelyOwned`).
- Một `User` có một mật khẩu dùng chung cho mọi kênh: tenant-web, vendor-web, pte-practice và pte-app đều gọi `/api/v1/auth/login`.
- Access token 15 phút, refresh token 7 ngày. `RefreshTokenService.revokeAllForUser` đã có, nhưng chỉ dùng khi suspend.
- Link "Forgot password?" ở tenant-web/vendor-web là `href="#"`. pte-practice ghi "Liên hệ trung tâm của bạn".
- tenant-web/vendor-web chặn người dùng có `mustChangePassword`. pte-app **không** đọc cờ này.
- Import học viên (`StudentRosterImportService`) không gửi mail. Email của học viên là tuỳ chọn; thiếu email thì server tự sinh username.

## Ideas Explored

1. **Forgot password tự phục vụ qua link một lần cho mọi role, kể cả học viên.** Bị loại cho học viên vì nhiều học viên không có email và trung tâm muốn kiểm soát.
2. **Forgot password gửi mật khẩu tạm mới.** Bị loại: ai biết email người khác cũng bấm được và làm mật khẩu của họ bị đổi.
3. **Host gửi link đặt lại cho học viên.** Bị loại: mật khẩu cũ vẫn dùng được, không khớp với cách Host đang cấp mật khẩu tạm.
4. **Host gửi mật khẩu tạm mới qua mail cho học viên, tái dùng `sendGeneratedCredentials`.** Được chọn.
5. **Thu hồi phiên khi đổi mật khẩu:** không thu hồi / thu hồi ngay / thu hồi nhưng giữ lượt thi đang chạy. Chọn phương án cuối.
6. **Tham khảo hệ thống khác:** Pearson myPTE tự đặt lại qua email; các LMS mà tổ chức tạo tài khoản thì để giáo viên/admin reset hộ. Hệ thống mình kết hợp cả hai.

## User's Direction

- "Học sinh sinh viên cho thêm option gửi mật khẩu qua mail": thêm mục **Send password via email** vào menu ⋯ của học viên (cạnh View details / Generate password / Suspend). Hệ thống sinh mật khẩu tạm mới và bắt đổi ở lần đăng nhập đầu.
- "Lúc import student mặc định không gửi mật khẩu qua mail": giữ nguyên.
- "Áp dụng gửi mail reset password cho tất cả các role trừ học sinh sinh viên": dùng link đặt lại dùng một lần.
- Đổi mật khẩu thì thu hồi phiên ở các máy khác, nhưng lượt thi đang chạy trên pte-app được làm tiếp.
- Xử lý `mustChangePassword` trên cả pte-practice và pte-app trong đợt này.

## Open Questions

- Cơ chế giữ lượt thi đang chạy khi thu hồi refresh token. pte-app gia hạn token 15 phút một lần, nên nếu thu hồi hết, học viên sẽ mất quyền gửi bài giữa giờ. Cần chọn: giữ lại refresh token của phiên có attempt `IN_PROGRESS`, hoặc cấp token riêng cho attempt.
- Học viên vừa là học viên vừa có role khác (ví dụ Proctor): có được dùng "Quên mật khẩu" không? Đề xuất: chặn khi tài khoản có role STUDENT.
- Tài khoản thuộc nhiều tổ chức: Host không đổi được credential (quy tắc `isExclusivelyOwned` hiện tại). Mục "Send password via email" cần ẩn hoặc báo lý do.

## Risks

- Mật khẩu tạm nằm nguyên văn trong hộp thư. Giảm rủi ro bằng `mustChangePassword` trên mọi kênh và thu hồi phiên.
- Lộ thông tin tài khoản qua "Quên mật khẩu" (dò email, spam mail). Cần phản hồi giống nhau cho mọi trường hợp và rate limit.
- Thu hồi phiên sai cách có thể đăng xuất học viên đang thi. Đây là vi phạm nguyên tắc #1 của ADR-001.
