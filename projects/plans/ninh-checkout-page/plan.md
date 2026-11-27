# Trang xác nhận kích hoạt / thanh toán gói (`/host/checkout`)

**Trạng thái:** đã làm, chưa commit.

## Trả lời câu hỏi của reviewer
Hiện **dùng chung một màn** cho gói miễn phí và gói trả phí (`isFreePlan = price === 0`): gói miễn phí kích hoạt luôn qua `createOrder`; gói trả phí tạo đơn rồi chuyển sang PayOS. Giữ nguyên cách này, chỉ đổi chữ/bố cục theo từng trường hợp.

## Đã làm (`apps/tenant-web/features/commercialization`)
- **Tiếng Việt + tiếng Anh**: 40 chuỗi mới `tenant.billing.checkout.*` (hằng số `CHECKOUT_TEXT`, hook `useCheckoutText`).
- **Điều hướng**: tiêu đề trang (`PageHeader`), breadcrumb "Gói và thanh toán › Xác nhận kích hoạt gói" (`breadcrumbRoutes`), sidebar tô xanh "Gói và thanh toán" cho `/host/checkout`, `/host/payment-status`, `/host/orders` (`resolveActiveNavItem`).
- **Tóm tắt đơn hàng** (`CheckoutSummary`, mới): giá ở dòng gói nhỏ (`text-sm font-medium`), dòng "Tổng thanh toán" lớn kèm badge "Miễn phí"; thêm các dòng Hình thức, Tổ chức áp dụng, và Hạn mức học viên "1.200 → 1.700 học viên (+500)" (gói sức chứa) hoặc Học viên mỗi kỳ thi / Thời hạn sử dụng (gói thi). Số định dạng theo ngôn ngữ.
- **Cột phải**: bỏ lặp "Free activation"; một hộp thông báo duy nhất ("Không cần thanh toán…"); gói trả phí giữ "Thanh toán an toàn · PayOS". `View payment status` chỉ hiện khi có khoản thanh toán chờ xử lý; còn lại là "Chọn gói khác" (về `/#plans`).
- **Chiều rộng**: khối giới hạn `max-w-5xl`.
- Test: `CheckoutSummary.test.tsx` (mới), cập nhật `CheckoutView.test.ts`, `resolveActiveNavItem.test.ts`.

## Chưa làm
- `PaymentStatusView` và `OrdersView` vẫn tiếng Anh (cùng nhóm Gói và thanh toán).
- Chưa thử gói có phí thật (dữ liệu seed đều 0 VND).

## Vòng 2 (theo nhận xét review)
- Card phải ôm sát nội dung (`items-start`); khối checkout căn giữa (`mx-auto max-w-5xl`).
- `(+500)` màu xanh lá, cùng tông với badge "Miễn phí".
- Khối "Điều gì diễn ra tiếp theo?" (`CheckoutNextSteps`, mới) dưới tóm tắt, dấu tick xanh. Chỉ ghi những điều đúng với từng loại gói: gói sức chứa (hạn mức tăng từ X lên Y, vĩnh viễn không tự gia hạn), gói thi (có hiệu lực ngay khi kích hoạt / khi thanh toán được xác nhận; thời hạn N ngày, không tự gia hạn), và giao dịch được ghi nhận ở Gói và thanh toán. Không ghi "không ảnh hưởng dữ liệu hiện có" vì chưa kiểm chứng.
- Dòng liên kết hỗ trợ cuối trang: "Cần hỗ trợ về gói dịch vụ hoặc giới hạn tổ chức? Gửi yêu cầu hỗ trợ" → `/host/support-tickets`.
- Test mới `CheckoutNextSteps.test.tsx`; cập nhật `CheckoutSummary.test.tsx`.
