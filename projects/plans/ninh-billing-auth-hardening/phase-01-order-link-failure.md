# Phase 1: Bù trừ khi tạo link thanh toán lỗi

Status: Completed

## Requirements

- Tạo hoặc lưu link lỗi thì đơn vừa giữ chỗ chuyển sang CANCELLED, và lỗi gốc vẫn được trả về; học viên/tổ chức mua lại được ngay.
- Job hết hạn: đơn PENDING chưa có link thanh toán được đánh dấu hết hạn mà không cần gọi PayOS (xử lý cả đơn mồ côi đã kẹt từ trước).
- Đơn có link vẫn hủy link ở PayOS trước, lỗi PayOS thì giữ PENDING và thử lại như cũ.

## Design Constraints

- Bù trừ chạy trong transaction riêng (`REQUIRES_NEW`), vì `createOrder` không có transaction bao ngoài.
- Cố gắng hủy link ở PayOS trước khi hủy cục bộ, nhưng lỗi của lệnh hủy không che lỗi gốc.
- Chỉ hủy khi đơn còn PENDING.

## Related files

- `pte-api/app/src/main/java/com/pte/billing/internal/service/order/OrderService.java`
- `pte-api/app/src/main/java/com/pte/billing/internal/service/order/OrderPersistenceService.java`
- `pte-api/app/src/main/java/com/pte/billing/internal/service/order/OrderExpirationService.java`
- `pte-api/app/src/test/java/com/pte/billing/internal/service/order/OrderServiceTest.java` và test của `OrderExpirationService`

## Steps

1. `OrderPersistenceService.cancelIfPending(publicId)` (`REQUIRES_NEW`).
2. `createOrder`: bọc `createPaymentLink` và `attachPaymentLink` bằng try/catch; khi lỗi, hủy link ở PayOS (bỏ qua lỗi) rồi `cancelIfPending`, ném lại lỗi gốc.
3. `OrderExpirationService`: bỏ qua `cancelPaymentLink` khi `order.getPaymentLinkUrl() == null`.
4. Test: lỗi tạo link thì đơn bị hủy và lỗi gốc được ném; job hết hạn xử lý đơn không có link mà không gọi PayOS.

## Quality/Testing State

- Test Mockito mới cho cả hai nơi; chạy lại toàn bộ test `billing`.
