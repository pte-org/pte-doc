# Phase 7: tenant-web — nhập mã kích hoạt, gói đang có, hạn mức sinh viên

## Requirements

Ba màn hình khép lại plan: `RedeemLicenseView` (nhập mã), `SubscriptionsView` (gói đang dùng được), `QuotaView` (hạn mức sinh viên).

Maps to: **[ADR-006](../../architecture/ADR-006-commercialization-and-exam-templates.md) §2, §8**

## Design Constraints

- **Hai đường mua phải cho kết quả không phân biệt được.** Gói nhận qua mã kích hoạt và gói mua qua PayOS đều là `Subscription` như nhau. `SubscriptionsView` **không** được hiển thị khác nhau theo `activationSource` ngoài việc ghi nguồn — nếu khác, tức là bất biến #4 của ADR-006 đã bị phá ở đâu đó.

- **Redeem có rate limit chặt hơn mặc định** (`DEFAULT_LICENSE_CODE_REDEEM_RATE_PER_SECOND = 5`) vì mã là bearer token và có thể bị dò. UI phải xử lý 429 rõ ràng, và **không** tự động thử lại — tự retry là tiếp tay cho việc dò mã.

- **Phân biệt đủ các lý do redeem thất bại.** Backend có mã lỗi riêng cho từng trường hợp: `LICENSE_CODE_NOT_FOUND`, `LICENSE_CODE_ALREADY_REDEEMED`, `LICENSE_CODE_REVOKED`, `LICENSE_CODE_EXPIRED`, `LICENSE_CODE_NOT_REDEEMABLE`. Gộp hết thành "mã không hợp lệ" làm người dùng không biết phải làm gì — nhưng cũng **đừng tiết lộ quá** (ví dụ "mã này thuộc tenant khác" là rò thông tin).

- **`STUDENT_CAPACITY` không sinh `Subscription`.** Redeem mã loại đó thì `SubscriptionsView` **không** có gì mới — hạn mức trong `QuotaView` mới tăng. Nếu UI chỉ chuyển sang danh sách gói sau khi redeem, người dùng sẽ tưởng thất bại. Kết quả redeem phải nói rõ vừa nhận được gì.

- **Gói hết hạn không chỉ dựa vào `status`.** Backend `/api/v1/subscriptions` đã lọc theo cả `status` lẫn `expiresAt` phòng khi job chưa chạy. FE **không** tự lọc lại theo `status` — tin danh sách backend trả về, nếu không sẽ lệch khi job trễ.

- **`QuotaView` hiện `used/limit`** — `StudentQuotaResponse` mang cả hai. Sắp chạm hạn mức thì cảnh báo trước, đừng để đến lúc import roster thất bại mới biết.

## Steps

1. `features/commercialization/api.ts`: `useSubscriptionsQuery`, `useRedeemLicenseMutation`, `useStudentQuotaQuery`.

2. `RedeemLicenseView.tsx`: ô nhập mã + nút gửi.
   - Chuẩn hoá đầu vào trước khi gửi: trim, chuyển hoa, bỏ khoảng trắng thừa — mã có dấu gạch nhóm cho dễ đọc, người dùng hay sao chép kèm khoảng trắng
   - **Không tự retry** khi lỗi

3. Sau khi redeem thành công, hiện kết quả **theo loại gói vừa nhận**:
   - `EXAM_PACKAGE` → nêu `licenseKey`, hạn dùng, cap mỗi kỳ thi; link sang `SubscriptionsView`
   - `STUDENT_CAPACITY` → nêu số chỗ vừa cộng thêm và hạn mức mới; link sang `QuotaView`
   - Đây là chỗ dễ làm người dùng hoang mang nhất — tránh câu chung chung như "thành công"

4. Map mã lỗi sang thông báo hành động được:
   - `LICENSE_CODE_NOT_FOUND` → "không tìm thấy mã, kiểm tra lại"
   - `LICENSE_CODE_ALREADY_REDEEMED` → "mã đã được sử dụng"
   - `LICENSE_CODE_REVOKED` → "mã đã bị thu hồi, liên hệ nơi cấp"
   - `LICENSE_CODE_EXPIRED` → "mã đã quá hạn kích hoạt"
   - 429 → "thử lại sau ít phút", không tự retry
   - Chuỗi đặt trong `constants.ts`

5. `SubscriptionsView.tsx`: bảng gói từ `useSubscriptionsQuery` — `licenseKey`, hạn, cap, nguồn kích hoạt.

6. Empty state nói rõ **chưa mua gói nào** kèm link sang catalog, không để bảng rỗng không giải thích.

7. Cảnh báo gói sắp hết hạn (ví dụ dưới 7 ngày) — tenant cần biết trước khi lên lịch kỳ thi.

8. **Không lọc lại theo `status` ở client.** Hiển thị đúng những gì backend trả.

9. `QuotaView.tsx`: hiện `used`/`limit` từ `useStudentQuotaQuery`, kèm thanh tiến độ. Gần chạm hạn mức thì cảnh báo + link sang catalog gói `STUDENT_CAPACITY`.

10. Nếu `RosterImport` (feature `examoperations`) đã có bước xem trước, nối nó với `/api/v1/students/import/preview` để hiện "sẽ dùng thêm N chỗ, còn lại M" trước khi import thật.

11. Ẩn ba màn hình này khỏi điều hướng với vai trò không phải `HOST_ADMIN` (backend `StudentQuotaController` yêu cầu `HOST_ADMIN`; `/api/v1/subscriptions` nhận cả `HOST_AUTHOR` — kiểm lại từng cái, đừng suy đoán).

## Success Criteria

- Redeem mã `EXAM_PACKAGE` → gói mới xuất hiện ở `SubscriptionsView`
- Redeem mã `STUDENT_CAPACITY` → **hạn mức tăng**, không có gói mới, và thông báo nói đúng điều đó
- Gói nhận qua mã và gói mua qua PayOS hiển thị như nhau (chỉ khác nguồn kích hoạt)
- Mỗi lý do redeem thất bại có thông báo riêng, không gộp một câu
- 429 không kích hoạt retry tự động
- `QuotaView` hiện đúng `used/limit` và cảnh báo khi sắp chạm hạn
- Chưa có gói → empty state có lối đi tiếp, không phải bảng trắng

## Quality and Testing State

- Quality gate: chưa chạy
- Testing: chưa bắt đầu

## Session Notes

_(trống)_
