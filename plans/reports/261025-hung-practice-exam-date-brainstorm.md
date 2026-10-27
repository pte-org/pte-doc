# Brainstorm: Ngày thi (mục tiêu học tập) trên Trang chủ

**Date:** 2026-10-25

## Ideas Explored
- Chỉ ngày thi (giống app tham chiếu "Ngày thi: 7 tháng 11") — chọn.
- Thêm điểm mục tiêu 10–90 để so với điểm ước lượng của đề luyện — để sau.
- Đếm ngược số ngày còn lại — để sau.
- Lưu trong trình duyệt (nhanh, mất khi đổi máy) vs lưu server theo tài khoản — chọn server.

## User's Direction
- "làm giống như này" (ảnh: "Ngày thi: 7 tháng 11"), "chỉ ngày thi, cho phép có cây bút kế bên chỉnh sửa ngày thi".
- Lưu trên server theo tài khoản.

## Open Questions
- Không còn câu hỏi chặn; múi giờ và giới hạn 2 năm là quyết định mặc định của Claude (ghi trong spec).

## Risks
- Ranh giới Modulith: không ghi vào bảng `users` của identity → dùng bảng riêng trong practice.
- Lệch ngày do múi giờ khi so "quá khứ" → dùng `Asia/Ho_Chi_Minh` ở server, gửi ngày dạng `YYYY-MM-DD` (không giờ).
