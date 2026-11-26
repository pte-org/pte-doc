# Thông báo: đọc bằng Modal, danh sách mới

## Vấn đề
Thông báo hệ thống (không có trang đích) mở một trang chi tiết riêng chỉ in lại nội dung đã có trong chuông. Không có email hay link nào trỏ tới trang đó.

## Quyết định
- Thông báo **không có trang đích** (hệ thống, bảo trì, announcement) mở **Modal** tại chỗ, từ chuông và từ trang danh sách; mở là tự đánh dấu đã đọc.
- Thông báo **có trang đích** (kỳ thi, đơn, gói, quota, yêu cầu hỗ trợ; admin: đơn đăng ký, yêu cầu hỗ trợ) vẫn chuyển thẳng tới trang đó.
- Xóa route chi tiết `/host/notifications/[publicId]` và `/admin/notifications/[publicId]` cùng hai `NotificationDetailView`, `InboxItemDetail`.
- Hộp "Thời gian ảnh hưởng" để sau: dữ liệu hộp thư không có `affectedFrom/Until`, cần backend.

## Thay đổi (`@pte/ui`, dùng chung hai cổng)
- `InboxItemModal`: dialog đọc một thông báo (badge, giờ, nội dung đầy đủ).
- `inboxBadgeVariant`: màu badge theo loại (hệ thống xanh dương, hỗ trợ/bảo trì cam, thanh toán xanh lá, quan trọng luôn cam).
- `NotificationRows`: badge ở trên trái, giờ + chấm chưa đọc ở trên phải, tiêu đề đậm hơn khi chưa đọc.
- `NotificationHistoryToolbar`: Tất cả | Chưa đọc + chọn danh mục, tiếng Việt qua `common.*`.
- `NotificationHistory`: nhận `toolbar`, đặt trong header của thẻ; trạng thái lỗi/đang tải/trống nằm trong thẻ.
- `NotificationBell` + `NotificationFooter`: `onViewAll` → link "Xem tất cả thông báo →".

## Hai cổng
- `features/notifications/targetHref.ts` (mỗi app): trả về đường dẫn hoặc `null` (→ Modal).
- Bell container và History view: `PageHeader` (tiêu đề + "Đánh dấu tất cả đã đọc"), state Modal.
- History view giữ state Modal ở component ngoài: danh sách remount khi `readRevision` đổi, nếu để trong thì Modal bị mất ngay sau khi đánh dấu đã đọc.

## Kiểm tra
- tsc sạch ở ui, tenant-web, vendor-web; eslint tenant/vendor sạch.
- vitest: ui 426, tenant-web 1133, vendor-web 760 đều qua (thêm test `inboxBadgeVariant` và `notificationTargetHref` hai app).
- Trình duyệt (host): bố cục mới, Modal từ danh sách và từ chuông, link "Xem tất cả", thông báo hỗ trợ vẫn chuyển trang. Admin: trang danh sách hiển thị đúng; không có dữ liệu để thử Modal ở admin.
