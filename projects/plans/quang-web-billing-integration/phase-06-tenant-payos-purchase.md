# Phase 6: tenant-web — mua gói qua PayOS & lịch sử đơn hàng

## Requirements

Nối `PlanCatalogView`, `CheckoutView`, `OrdersView`, `PaymentStatusView` với API thật. Tenant xem gói `ACTIVE`, tạo đơn, nhận link PayOS, quay lại xem kết quả.

Xoá `TENANT_PLANS`, `DEMO_ORDERS`.

Maps to: **[ADR-006](../../architecture/ADR-006-commercialization-and-exam-templates.md) §7**

## Design Constraints

- **`returnUrl` không phải nguồn sự thật.** Webhook mới là thứ kích hoạt gói. Người dùng đóng tab sau khi trả tiền là **trường hợp bình thường**, không phải lỗi. `PaymentStatusView` phải đọc trạng thái từ `GET /api/v1/orders` của backend, **không** tin tham số trên URL PayOS trả về.

- **Có độ trễ giữa "trả tiền xong" và "gói xuất hiện".** Webhook đi đường riêng, không đồng bộ với việc trình duyệt quay lại. `PaymentStatusView` phải poll (hoặc cho nút làm mới) thay vì kết luận thất bại ngay khi thấy `PENDING`. Kết luận sai ở đây khiến người dùng trả tiền hai lần.

- **Một `PENDING` cho mỗi gói.** Backend chặn tạo đơn mới khi tenant còn đơn `PENDING` cùng gói (`ORDER_PENDING_EXISTS`). UI nên hiện đơn đang chờ và link thanh toán cũ thay vì để người dùng bấm mua rồi ăn 409.

- **Chỉ `HOST_ADMIN`/`HOST_AUTHOR` gọi được** `/api/v1/orders`. Các vai trò khác trong tenant thấy màn hình này là vô nghĩa — ẩn khỏi điều hướng, không chỉ chặn ở API.

- **Danh mục gói tenant thấy là `/api/v1/plans`** (chỉ `ACTIVE`). Cùng một resource path, khác quyền và bộ lọc theo role; không tạo thêm namespace `/admin` chỉ để biểu diễn quyền.

- **Hai họ gói hiển thị khác nhau.** `EXAM_PACKAGE` nói về thời hạn + cap mỗi kỳ thi; `STUDENT_CAPACITY` nói về số chỗ cộng thêm vĩnh viễn. Gộp chung một khuôn thẻ làm người mua hiểu sai thứ mình mua.

- **`orderCode` là số nguyên lớn.** Kiểm DTO backend xem trả `number` hay `string`; nếu là `number` gần giới hạn an toàn của JS thì phải xử lý cẩn thận khi hiển thị/đối chiếu.

## Steps

1. `features/commercialization/api.ts`: `usePlansQuery` (dùng `/api/v1/plans`), `useOrdersQuery`, `useCreateOrderMutation`.

2. `PlanCatalogView.tsx`: thay `TENANT_PLANS` bằng query thật. Tách khối hiển thị theo `type` — hai nhóm rõ ràng, không trộn.

3. Định dạng hiển thị đặt trong `utils/`: `price` + `currency` → chuỗi tiền tệ; `durationDays` → "N ngày"; `maxStudentsPerSession` → "tối đa N sinh viên mỗi kỳ thi"; `extraStudentSlots` → "+N chỗ vĩnh viễn".

4. `CheckoutView.tsx`: xác nhận gói đã chọn → `useCreateOrderMutation` → nhận `paymentLinkUrl` → chuyển hướng sang PayOS.

5. Trước khi cho bấm mua: kiểm trong `useOrdersQuery` xem đã có đơn `PENDING` cho gói đó chưa. Có thì hiện đơn cũ + link thanh toán, không tạo đơn mới.

6. Xử lý `ORDER_PENDING_EXISTS` (409) phòng trường hợp race — vẫn phải bắt dù đã chặn ở bước 5.

7. `OrdersView.tsx`: thay `DEMO_ORDERS` bằng `useOrdersQuery`. Bảng hiện `orderCode`, gói, số tiền, trạng thái, thời điểm. Đơn `PENDING` còn link thanh toán thì cho bấm lại.

8. `PaymentStatusView.tsx`:
   - Đọc trạng thái từ `useOrdersQuery`, **không** từ query param của PayOS
   - Poll khi còn `PENDING` (`refetchInterval`), dừng khi sang `PAID`/`CANCELLED`/`EXPIRED`
   - Đặt giới hạn số lần poll; hết hạn thì hiện nút làm mới thủ công, **không** tự kết luận thất bại
   - Trạng thái `PENDING` phải nói rõ "đang chờ xác nhận thanh toán", không phải "thất bại"

9. `PAID` → hiện link sang `SubscriptionsView` (Phase 7).

10. Ẩn mục điều hướng tới catalog/checkout với vai trò không phải `HOST_ADMIN`/`HOST_AUTHOR`.

11. Xoá `TENANT_PLANS`, `DEMO_ORDERS` khỏi `data.ts`.

12. **Ghi lại URL webhook cho cấu hình PayOS**: đường thật là `/api/v1/webhooks/payos`; Nginx chuyển tiếp nguyên path đến Spring Boot, không cắt `/api/v1`. Ghi vào README hoặc phần triển khai — cấu hình sai ở dashboard PayOS thì không gói nào được kích hoạt và **không có lỗi nào hiện ra ở FE**.

## Success Criteria

- Danh mục hiện gói `ACTIVE` thật, hai họ gói hiển thị phân biệt được
- Tạo đơn → nhận link PayOS → chuyển hướng được
- Thanh toán sandbox → webhook chạy → gói xuất hiện ở `/api/v1/subscriptions`
- **Đóng tab sau khi trả tiền rồi mở lại `OrdersView` → vẫn thấy `PAID`** — chứng minh không phụ thuộc `returnUrl`
- Mua trùng gói đang `PENDING` → hiện đơn cũ, không tạo đơn mới
- `PaymentStatusView` không kết luận thất bại khi mới chỉ `PENDING`
- Không còn `TENANT_PLANS`/`DEMO_ORDERS`

## Quality and Testing State

- Quality gate: chưa chạy
- Testing: chưa bắt đầu

## Session Notes

_(trống)_
