# Màn chi tiết đơn đăng ký (vendor-web): bỏ ô "Lý do từ chối" khỏi cạnh nút Duyệt

## Nhận xét đã đối chiếu với code
| Nhận xét | Kết luận |
|---|---|
| Ô "Lý do từ chối *" cạnh nút Duyệt gây bối rối | Đúng. Chuyển sang popup khi bấm Từ chối. |
| Thiếu Tên tổ chức trong bảng chi tiết | Đúng (chỉ có ở breadcrumb). Đã thêm. |
| Loại tổ chức hiển thị raw (`language-center`) | Đúng, và nguyên nhân là bảng nhãn dùng sai khóa (`SCHOOL`, `TRAINING_CENTER`...) trong khi form gửi `school`, `language-center`, `university`, `other`. Đã sửa khóa + bản dịch. |
| Thiếu ngày nộp đơn | Đúng. API chưa trả về, thêm `submittedAt` (lấy `createdAt` của organization). Định dạng theo ngôn ngữ đang chọn. |
| Nút Từ chối trông như bị disable | Do đang disabled khi chưa có lý do. Nay luôn bấm được khi đơn PENDING. |
| Bố cục mất cân đối | Giảm nhờ thêm 2 dòng bên trái và bỏ ô input bên phải. Chưa dời nút lên header. |
| Badge SLA "còn 70 giờ" | Không làm: API không có hạn SLA theo đơn; số giờ chỉ là cấu hình chung. |
| Nút tra cứu MST ra cổng thuế | Không làm: cần chọn trang tra cứu bên ngoài và cách mở; đề xuất riêng. |

## Thay đổi
- pte-api: `TenantApplicationResponse.submittedAt`, `TenantApplicationMapper`.
- api-client: type `submittedAt: string`.
- vendor-web: `AdminApplicationDetailView` (thêm Tên tổ chức, Thời điểm nộp đơn, nhãn loại tổ chức đúng khóa, bỏ ô input, hai nút
  chỉ hiện khi PENDING), `RejectApplicationDialog` mới (lý do bắt buộc, tối đa 500 ký tự, lỗi hiện trong popup), copy VI/EN.

## Kết quả thực hiện
- `tsc`, eslint sạch; vendor-web vitest 748/748; `TenantApplicationServiceTest` 15/15.
- Đã đăng nhập tài khoản seed local và xem màn hình thật: bảng có Tên tổ chức, Loại "Trung tâm ngoại ngữ", Thời điểm nộp đơn
  theo định dạng VI; nút Từ chối mở popup, nút xác nhận bị khóa đến khi nhập lý do. Không bấm Duyệt/Từ chối thật.
- Chưa có test component cho popup (vendor-web chưa có hạ tầng test component).

## Vòng 2: bố cục theo mẫu của người dùng
- Thanh trên cùng: nút "Quay lại danh sách" bên trái, `Từ chối` và `Duyệt đơn đăng ký` bên phải (chỉ khi đơn PENDING).
- Cột trái: card "Thông tin tổ chức" (tên, loại hình, mã yêu cầu, MST + link "Tra cứu ↗" mở masothue.com ở tab mới) và card
  "Thông tin người đại diện" (email, SĐT). Cột phải: card "Trạng thái hồ sơ" (trạng thái, thời điểm nộp + "x giờ trước",
  thời hạn phản hồi còn lại/quá hạn, thông tin xét duyệt và lý do từ chối nếu đã xử lý).
- API: thêm `responseDueAt` (= ngày nộp + SLA từ cài đặt nền tảng) chỉ cho đơn PENDING ở endpoint chi tiết; danh sách không có.
- Tách `ApplicationInfoSections.tsx` và `applicationFormat.ts`; `AdminApplicationDetailView` còn phần logic duyệt/từ chối.
- Kiểm tra: tsc, eslint, vitest 748/748, `TenantApplicationServiceTest` 16/16, xem thật trên trình duyệt (còn 71 giờ, link Tra cứu hiển thị).
- Lưu ý: link tra cứu dùng masothue.com (đổi ở `TAX_LOOKUP_URL` nếu muốn trang khác).
