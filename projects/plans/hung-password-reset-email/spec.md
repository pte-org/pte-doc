# Spec: Đặt lại mật khẩu qua email

**Date:** 2026-10-31
**Status:** Draft
**Brainstorm:** [261031-password-reset-email-brainstorm](../reports/261031-password-reset-email-brainstorm.md)
**Repos:** pte-api, pte-web (tenant-web, vendor-web), pte-practice, pte-app

---

## Problem Statement

Hiện người quên mật khẩu không tự lấy lại được: link "Forgot password?" chưa làm gì, và Platform Admin không có ai reset hộ. Học viên chỉ nhận được mật khẩu tạm khi Host đọc cho họ, vì luồng gửi mail mật khẩu đang chặn role STUDENT. Ngoài ra, đổi mật khẩu không đăng xuất các phiên cũ, và pte-app bỏ qua cờ buộc đổi mật khẩu.

---

## User Stories

- **[P1]** Là Host, tôi muốn bấm **Send password via email** trong menu ⋯ của một học viên, để học viên nhận mật khẩu tạm mà tôi không phải tự gửi.
  Accepted when: học viên có email và thuộc riêng tổ chức của Host thì nhận được mail có username + mật khẩu tạm; mật khẩu cũ hết hiệu lực; lần đăng nhập đầu bị buộc đổi mật khẩu.

- **[P1]** Là nhân sự (Platform Admin, Platform Manager, Academic Manager, Academic Staff, Host, Proctor, Examiner) quên mật khẩu, tôi muốn nhập email ở trang đăng nhập để nhận link đặt lại.
  Accepted when: link dùng được đúng một lần, hết hạn sau 30 phút, đặt xong thì đăng nhập được bằng mật khẩu mới.

- **[P1]** Là học viên, tôi muốn bị buộc đổi mật khẩu tạm ở lần đăng nhập đầu trên pte-practice và pte-app, để mật khẩu nằm trong hộp thư không dùng được mãi.
  Accepted when: đăng nhập với `mustChangePassword = true` thì phải qua màn hình đổi mật khẩu trước khi vào bất kỳ màn hình nào khác.

- **[P1]** Là người dùng, khi mật khẩu của tôi bị đổi, tôi muốn các thiết bị khác bị đăng xuất, nhưng lượt thi đang chạy của tôi không bị cắt ngang.
  Accepted when: refresh token cũ bị từ chối, trừ phiên đang có lượt thi `IN_PROGRESS`.

- **[P2]** Là học viên bấm "Quên mật khẩu" ở pte-practice hoặc pte-app, tôi muốn thấy hướng dẫn liên hệ trung tâm thay vì một form không dùng được.

- **[P3]** _(ngoài phạm vi)_ Học viên tự đặt lại mật khẩu qua email; tuỳ chọn gửi mail hàng loạt khi import.

---

## Functional Requirements

### A. Host gửi mật khẩu tạm qua email cho học viên

1. FR-01: Bỏ chặn STUDENT trong luồng gửi mail mật khẩu tạm. Luồng mới vẫn sinh mật khẩu tạm, bật `mustChangePassword` và phát `UserCredentialsEmailRequestedEvent` như `sendGeneratedCredentials` hiện tại. Cách làm cụ thể (mở rộng hàm cũ hay thêm endpoint riêng) để plan quyết định.
2. FR-02: Chỉ HOST_ADMIN của tổ chức đó, hoặc Platform Admin, được gọi; tài khoản phải thuộc riêng tổ chức (`isExclusivelyOwned`). Sai điều kiện → 403 `ForbiddenPasswordResetException`. Học viên ngoài tổ chức → 404.
3. FR-03: Học viên không có email → API trả lỗi `UserEmailRequiredException`. Ở UI, mục menu bị vô hiệu hoá kèm tooltip giải thích.
4. FR-04: tenant-web thêm mục **Send password via email** vào `ActionMenu` của học viên, giữa "Generate password" và "Suspend". Bấm thì hiện hộp xác nhận ghi rõ "mật khẩu hiện tại sẽ mất hiệu lực". Thành công thì hiện toast có email người nhận. Dùng các component `@pte/ui` sẵn có.
5. FR-05: Import học viên (đơn lẻ và hàng loạt) **không** gửi mail mật khẩu, giữ như hiện tại.
6. FR-06: Ghi audit `USER_CREDENTIALS_EMAILED` (actor, học viên, tổ chức, thời điểm). Không ghi mật khẩu.

### B. Quên mật khẩu (mọi role trừ học viên)

7. FR-07: `POST /api/v1/auth/password-reset/request` với body `{ email }`, không cần đăng nhập. Luôn trả **200 với cùng một nội dung**, dù email có tồn tại hay không.
8. FR-08: Chỉ gửi mail khi tài khoản tồn tại, đang ACTIVE, có email trùng khớp và **không** mang role STUDENT. Các trường hợp còn lại không làm gì.
9. FR-09: Token reset: ngẫu nhiên ≥ 32 byte, DB chỉ lưu hash (dùng lại `TokenHasher`), hết hạn sau 30 phút, dùng một lần. Mỗi lần yêu cầu mới thì token cũ của tài khoản đó hết hiệu lực. Bảng mới trong module `identity`, tạo bằng migration Flyway mới.
10. FR-10: `POST /api/v1/auth/password-reset/confirm` với body `{ token, newPassword }`. Mật khẩu tối thiểu 8 ký tự (giống quy tắc hiện tại). Thành công thì: đổi mật khẩu, tắt `mustChangePassword`, đánh dấu token đã dùng, thu hồi phiên (FR-13), ghi audit `USER_PASSWORD_RESET_SELF`. Token sai, hết hạn hoặc đã dùng → 400 với một thông báo chung.
11. FR-11: Link trong mail trỏ về đúng portal của người dùng: vendor-web cho role nền tảng, tenant-web cho Host/Proctor/Examiner. Domain lấy từ cấu hình, không hardcode.
12. FR-12: tenant-web và vendor-web làm hai trang mới: `/forgot-password` (nhập email → luôn hiện cùng một thông báo) và `/reset-password?token=…` (đặt mật khẩu mới → về trang đăng nhập). Link "Forgot password?" trỏ tới `/forgot-password`.

### C. Phiên đăng nhập và buộc đổi mật khẩu

13. FR-13: Mọi lần đổi credential (reset bởi operator, generate, gửi mail, tự đặt lại qua link, tự đổi mật khẩu) đều thu hồi refresh token của tài khoản. Riêng khi tự đổi mật khẩu thì giữ phiên hiện tại. Ngoại lệ: phiên có lượt thi `IN_PROGRESS` vẫn gia hạn được tới khi lượt thi kết thúc. Cơ chế cụ thể xem mục cần làm rõ.
14. FR-14: `resetPassword` (operator tự đặt mật khẩu) phải bật `mustChangePassword = true`.
15. FR-15: pte-app đọc `mustChangePassword` từ phản hồi login (pte-practice đã làm việc này ở `features/auth/SignInView.tsx`). Nếu true thì chuyển sang màn hình đổi mật khẩu (`POST /auth/change-password`) và chặn mọi màn hình khác cho tới khi đổi xong.
16. FR-16: Ở pte-practice và pte-app, "Quên mật khẩu?" hiện hướng dẫn liên hệ trung tâm, không có form.

---

## Non-Functional Requirements

- **Security:**
  - Rate limit `password-reset/request`: tối đa 3 lần mỗi email mỗi 15 phút và 10 lần mỗi IP mỗi 15 phút, dùng lại `RateLimitFilter`/Redis. Vượt mức thì vẫn trả 200 với cùng nội dung.
  - Thời gian phản hồi không được để lộ email có tồn tại hay không: phần gửi mail chạy bất đồng bộ qua RabbitMQ.
  - Token và mật khẩu không xuất hiện trong log, audit hay URL phía server, trừ link trong mail.
- **Reliability:** gửi mail lỗi không làm hỏng thao tác đổi mật khẩu (BR-047). Mail đi qua `notification` → RabbitMQ → `EmailWorker` sẵn có.
- **i18n:** mail và UI có cả tiếng Việt và tiếng Anh, theo NFR-13.
- **Performance:** `password-reset/request` trả về trong < 500 ms p95, theo NFR-01.

---

## Success Criteria

- [ ] Host gửi mật khẩu tạm cho học viên có email: mail đến hộp thư Mailpit (dev) trong < 30 giây; mật khẩu cũ bị từ chối khi đăng nhập.
- [ ] Học viên đăng nhập bằng mật khẩu tạm trên pte-app và pte-practice: 100% bị chuyển sang màn hình đổi mật khẩu.
- [ ] Gọi `password-reset/request` với email tồn tại và không tồn tại: nội dung phản hồi giống hệt nhau, chênh lệch thời gian trung vị < 50 ms.
- [ ] Token dùng lần thứ hai hoặc sau 30 phút → bị từ chối.
- [ ] Sau khi đặt lại mật khẩu, refresh token cũ trên máy khác bị từ chối ở lần gia hạn kế tiếp; lượt thi đang `IN_PROGRESS` trên pte-app vẫn gửi bài và nộp bài thành công.
- [ ] Platform Admin tự lấy lại được tài khoản mà không cần sửa DB.

---

## Out of Scope

- Học viên tự đặt lại mật khẩu qua email.
- Gửi mail mật khẩu hàng loạt khi import hoặc cho cả lớp.
- Lấy lại username, câu hỏi bảo mật, MFA, OTP qua SMS.
- Tài khoản thuộc nhiều tổ chức: giữ quy tắc Host không đổi được credential.

---

## Assumptions

- Email của nhân sự là email thật mà họ đọc được. Nếu sai, cần bước xác minh email trước khi bật "Quên mật khẩu".
- Hạ tầng gửi mail (SMTP; Mailpit ở dev) đang hoạt động trên production.
- Tài khoản có role STUDENT cùng một role nhân sự được coi là học viên, nên không dùng được "Quên mật khẩu".

---

## Quyết định đã chốt (2026-10-31)

- **Giữ lượt thi đang chạy (FR-13):** **chặn** mọi thao tác đổi credential của tài khoản STUDENT đang có lượt thi `IN_PROGRESS`, gồm Host generate, send email, reset và học viên tự đổi. API trả 409 với thông báo "Học viên đang làm bài, hãy thử lại sau khi nộp bài". Nhờ vậy thu hồi phiên luôn là thu hồi toàn bộ, không cần ngoại lệ. Lý do: refresh token chỉ gắn với `userId` + `organizationId`, không phân biệt được thiết bị đang thi.
- **Giữ phiên hiện tại khi tự đổi mật khẩu (FR-13):** `change-password` giữ response rỗng để tương thích ngược, và nhận thêm `refreshToken` tuỳ chọn của phiên đang gọi. Có trường này thì thu hồi mọi phiên khác; không có thì không thu hồi (client cũ). Hung chọn không release đồng loạt 4 repo.
- **Domain cho link reset (FR-11):** thêm cấu hình `app.web.tenant-url` và `app.web.admin-url`. Trong `docker-compose.deploy.yml`, hai giá trị này lấy từ `https://${TENANT_DOMAIN}` và `https://${ADMIN_DOMAIN}`; ở local mặc định là `http://localhost:3000` và `http://localhost:3001`.
