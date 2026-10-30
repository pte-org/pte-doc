# Brainstorm: Admin cấp gói theo hợp đồng thay cho Host nhập mã

**Date:** 2026-10-29
**Spec:** [plans/hung-license-grant/spec.md](../hung-license-grant/spec.md)
**Tiền đề:** [261029-hung-license-grant-renewal.md](261029-hung-license-grant-renewal.md)

## Ideas Explored

- **A. Giữ mã chạy ngầm (chọn):** Admin cấp = phát mã gắn tổ chức + redeem ngay trong một transaction. Tái dùng redeemer, đường kích hoạt, audit, thông báo và luồng thu hồi mã.
- **B. Kích hoạt thẳng Subscription, không sinh mã:** ít khái niệm hơn nhưng mất đường thu hồi. Vì thu hồi để đợt sau nên cấp nhầm sẽ không sửa được. Loại.
- **C. Thêm nút "Gửi mã cho Host" vẫn giữ Host nhập:** vẫn còn bước thừa và rủi ro lộ mã, gói vẫn tính từ ngày nhập. Loại.
- **Gia hạn nối tiếp cho PayOS** (có trong đề xuất gốc): bỏ theo quyết định của Hung. Mua online là license mới chạy ngay.
- **Ngày bắt đầu tự điền:** chỉ tính gói Admin cấp, hoặc không tự điền. Chọn **tính mọi nguồn** (cả gói PayOS) để Host không mất ngày.
- **Thu hồi theo gói cho mọi nguồn, nhắc hạn:** để đợt sau.

## User's Direction

- Luồng Admin: *"Admin bấm Cấp gói cho đúng tổ chức → gói kích hoạt luôn. Host không phải làm gì."* Gồm tìm theo mã tổ chức/MST, xác nhận MST in đậm, nhập gói, ngày bắt đầu, số hợp đồng bắt buộc, xem trước, rồi xác nhận.
- *"Luồng PayOS sẽ không có gia hạn mà phải mua tiếp."*
- Thu hồi: *"bỏ qua luồng thu hồi đi, chưa làm."*
- Nguyên tắc chung: *"làm sao mà tối ưu nhất không phải sửa nhiều trong hệ thống."* Vì vậy nhắc hạn để sau và tái dùng tối đa.
- Quyền: Platform Admin + Platform Manager được cấp; thu hồi mã vẫn chỉ Admin.
- Gói chỗ học viên: *"làm theo nghiệp vụ hiện tại đang có trong code."* Cùng form, không có ngày bắt đầu, giống redeem hiện nay.

## Phát hiện khi rà code (dev, 2026-10-29)

- Thông báo Host đã có: `CommercialOutcomeConfirmedEvent` → `CommercialNotificationListener` ghi inbox.
- Gói chờ đang bị chặn ở 4 chỗ của `session`, cùng đi qua `BillingService.getActiveSubscription` (`isUsableAt(now)`). Nới một chỗ này là đủ; chặn theo khoảng ngày đã có sẵn.
- `SubscriptionRepository.findUsableForPlanRenewal` đã có khóa nhưng chưa ai gọi. Bỏ `startsAt <= now` để tính cả gói chờ.
- `GET /api/v1/organizations` chưa có tham số tìm kiếm.
- Migration Flyway đã gộp: `V1__baseline` … `V6`.

## Open Questions

1. Ngày bắt đầu xa nhất Admin được chọn (đề xuất 6 tháng).
2. Tra cứu tổ chức: mở rộng `GET /organizations` hay endpoint riêng trong billing.
3. Nội dung thông báo inbox khi gói chưa chạy ngay: có cần ghi rõ "hiệu lực từ dd/mm" không.

## Risks

- **Nới `getActiveSubscription`** có thể ảnh hưởng chỗ gọi ngoài dự kiến, ví dụ bắt đầu attempt trên gói chưa chạy. Bước plan phải rà mọi chỗ gọi và có test.
- **Admin cấp nhầm tổ chức:** giảm rủi ro bằng tra theo mã/MST, MST in đậm, bắt buộc số hợp đồng. Sửa sai bằng thu hồi mã hiện có (chỉ Admin).
- **Host tưởng gói chờ đã dùng được:** nhãn *Sắp hiệu lực* phải phát hành cùng đợt với cấp gói.
