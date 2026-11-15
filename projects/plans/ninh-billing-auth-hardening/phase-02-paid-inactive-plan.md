# Phase 2: Đơn đã trả tiền nhưng gói không còn dùng được

Status: Completed

## Requirements

- Webhook đã xác thực cho đơn PENDING mà gói không còn (bị xóa, bị lưu trữ, hoặc kích hoạt bị từ chối vì dữ liệu gói không hợp lệ):
  đơn được đánh dấu PAID, biên nhận được giữ nguyên ở trạng thái chưa xử lý, ghi log mức `error` để đối soát, webhook trả thành công để PayOS không thử lại vô ích.
- Thanh toán muộn cho đơn không còn PENDING (đã hết hạn hoặc bị hủy) được ghi `warn` thay vì im lặng.
- Lỗi hệ thống thật (HTTP 5xx, ví dụ sinh khóa giấy phép) vẫn làm rollback để PayOS thử lại.

## Design Constraints

- Chỉ bắt `SubscriptionActivationException` mức 4xx: chúng được ném trước khi ghi gì, nên không làm transaction rollback-only.
- Không công bố `CommercialOutcomeConfirmedEvent` khi chưa có gói được kích hoạt.
- Không đổi hành vi của đường chạy bình thường.

## Related files

- `pte-api/app/src/main/java/com/pte/billing/internal/service/order/PayOsWebhookService.java`
- `pte-api/app/src/test/java/com/pte/billing/internal/service/order/PayOsWebhookServiceTest.java`

## Steps

1. Tách phần "tìm gói và kích hoạt" ra một nhánh: gói không có, đã xóa, không `ACTIVE`, hoặc `SubscriptionActivationException` 4xx thì `order.markPaid`, `LOGGER.error`, trả về (biên nhận không `markProcessed`).
2. Thêm `LOGGER.warn` ở nhánh đơn không còn PENDING.
3. Test: gói bị lưu trữ, gói bị xóa, kích hoạt 4xx giữ biên nhận chưa xử lý và đơn PAID; lỗi 5xx vẫn ném; đường bình thường không đổi.

## Quality/Testing State

- Test Mockito mới; chạy lại toàn bộ test `billing`.
