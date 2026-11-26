# Email "đã ghi danh vào kỳ thi" (tiếng Anh)

**Trạng thái:** đã làm, chưa commit.

## Vấn đề
Mail cũ chỉ in UUID của phiên thi và bảo "Log in to view your schedule", nhưng học viên không có trang web nào để xem lịch: họ thi bằng app Flutter (`pte-app`) bằng cách nhập **mã kỳ thi** (`sessionCode`), và cổng tổ chức từ chối tài khoản học viên.

## Quyết định
Không đính kèm file lịch `.ics`, không có nút dẫn tới trang web. Lịch thi nằm ngay trong thân mail.

## Đã làm (`pte-api`)
- `StudentEnrolledEvent` mang thêm tên kỳ thi, mã phiên, giờ mở, giờ đóng (phía `EnrollmentService` có sẵn). Giữ constructor 3 tham số cho nơi chỉ biết ID (mail khi đó bỏ phần chi tiết).
- `ExamEnrollmentEmailTemplate` (mới, cùng khung mail Approved/Welcome): lời chào theo tên, bảng tóm tắt (Exam, Exam code, Opens, Closes, Organization; giờ ghi kèm múi giờ, ví dụ `27 Nov 2026, 13:00 (GMT+7)`), khối "How to join" (mở app thi, đăng nhập, nhập mã), khung nhắc đến sớm kiểm tra micro/tai nghe, câu hỗ trợ "Contact your center or administrator.", chữ ký. Subject: `[PTE Prep] Enrolled: <tên kỳ thi>`. Có bản text kèm theo; giá trị host nhập được escape; thiếu dữ liệu thì bỏ dòng đó.
- `EnrollmentNotificationListener` tra tên học viên và tên tổ chức (`TenancyService.findOrganizationName`), dựng mail từ template mới. Múi giờ hiển thị lấy từ `notification.display-zone` (mặc định `Asia/Ho_Chi_Minh`).
- Gỡ `NotificationEmailTemplate.studentEnrolled` (không còn dùng).
- Test: `ExamEnrollmentEmailTemplateTest` (6), `EnrollmentNotificationListenerTest` (2, viết lại), cập nhật `NotificationEmailTemplateTest`. Cả module notification + enrollment: 242 test, không lỗi.

## Kiểm tra thật
Rebuild container, gỡ rồi ghi danh lại `duc.hoang@example.com` vào kỳ thi "Test 1" (NINHLE2-261127-LU27): mail vào Mailpit đúng thiết kế, giờ 13:00–16:00 (GMT+7) khớp 06:00–09:00 UTC trong DB.

## Chưa làm
- Chưa có link tải app thi trong mail (chưa có URL nào được cấu hình). Có URL thì thêm vào khối "How to join".
- Mail huỷ / đổi giờ kỳ thi chưa đổi.

## Vòng 2: không gửi mã kỳ thi qua mail
Mã kỳ thi là lớp kiểm soát tại phòng thi: giám thị đưa mã vào ngày thi để chỉ người có mặt mới vào thi được. Gửi trước qua email thì ai có mail cũng có thể chia sẻ hoặc dùng mã ngoài phòng thi. Vì vậy:
- Mail bỏ dòng **Exam code** và bước nhập mã cụ thể; "How to join" giờ là 3 bước: đến phòng thi đúng giờ, mở app thi và đăng nhập, nhập mã kỳ thi do giám thị đưa tại kỳ thi.
- `StudentEnrolledEvent` không còn mang `sessionCode` (không cho mã đi qua event nữa).
- Test mới `neverGivesTheExamCode_theProctorDoesOnTheDay`.
