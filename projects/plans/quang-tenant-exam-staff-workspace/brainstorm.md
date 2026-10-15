# Brainstorm: Hồ sơ Exam Staff dành cho Host

Ngày: 2026-10-10. Trạng thái: hướng sản phẩm đã được đồng ý; chi tiết contract cần xác nhận trước implementation.

## Người dùng và việc chính

Người xem là HOST_ADMIN của tenant hiện tại, không phải Examiner/Proctor đang làm việc.
Host cần biết nhân sự được phân công ca nào, ca sắp tới và tiến độ chấm; xem tài khoản và thực hiện các thao tác quản trị đã được phép.

## Hướng được chọn

- Dùng trang chi tiết cùng browser tab thay modal Account details.
- Common hóa phần trình bày của Learner; không dùng lại query, thống kê điểm hay logic Student.
- Overview đứng đầu/default. PROCTOR có Lịch coi thi; EXAMINER có Theo dõi chấm bài. Tài khoản ở cuối.
- Nhân sự có cả hai role: hiển thị cả hai tab nghiệp vụ, người dùng đã xác nhận.
- Lịch coi thi là danh sách theo ngày/bảng có filter thời gian; lịch tháng chưa nằm trong V1.
- Examiner có Kanban read-only và table toggle. Một card là công việc của nhân sự ở một ca thi; không kéo thả, không chấm bài thay Examiner.
- Account hiển thị read-only, nút Edit bên phải chuyển các field được phép thành input trong cùng layout.

## Tham chiếu đúng dự án

Đã khảo sát `D:/DOCUMENTFPT/Github/pte-org/nextjs-admin-dashboard`.
Profile/calendar cung cấp ý tưởng composition. Không tìm thấy source Kanban trong dự án này qua tìm tên file và nội dung, kể cả file bị ignore.
Ảnh Kanban chỉ tham khảo bố cục; không copy style, font, màu hay port dependency của reference.
Giữ component/token/default của `@pte/ui`. Board chưa có thì thêm primitive trình bày dùng chung, không domain logic.

## Phương án và trade-off

| Hướng | Kết luận |
| --- | --- |
| Viết riêng trang staff từ các primitive | Ít thay đổi ban đầu nhưng lặp cấu trúc Learner |
| Extract profile presentation từ Learner | Chọn: có hai consumer thật, trách nhiệm rõ, cần regression Learner |
| Port profile/calendar của dashboard mẫu | Không chọn: contract và style khác, thêm dependency ngoài nhu cầu |
| Host gọi queue Examiner cá nhân | Không hợp lệ: endpoint lấy ownership từ người đăng nhập |
| Ghép mọi session/proctor ở frontend | Không chọn: request fan-out, filter và count không đầy đủ |

## Kết quả khảo sát domain

- ProctorAssignment là phân công theo ca, không phải chứng cứ đã tham dự. Xóa phân công không giữ lịch sử đầy đủ.
- ExaminerAttemptAssignment là theo attempt; bổ sung batch vẫn cần nhóm thành một card theo ca.
- Trạng thái batch PREVIEWED/COMMITTED/EXPIRED/STALE không phải tiến độ chấm.
- ExaminerAnswerScore phản ánh điểm Examiner; không cộng AI/teacher score thành tiến độ nhân sự.
- API queue cá nhân loại ca đã publication; Host cần giữ chúng để xem lịch sử.
- API overview batch hiện có thao tác expire preview khi GET; query hồ sơ mới phải thuần đọc.
- PATCH profile Student hiện có không được dùng cho staff.
- Workflow credential staff hiện tại là generate/send email; không đổi thành Student credential action.

## Ngoài phạm vi

Không lịch sử audit phân công bị xóa, calendar drag/drop, thay đổi phân công tại hồ sơ, role editor, scoring impersonation, deadline/SLA tự suy diễn, avatar upload, địa chỉ/bio, account delete hay thay typography toàn hệ thống.
