# Phase 04: tự hủy lô dừng quá hạn (admin cấu hình được)

**Trạng thái:** [x] Đã làm (2026-11-27) · **Repo:** pte-api · **Phụ thuộc:** 02

## Mục tiêu

Lô `PAUSED` dừng lâu hơn hạn thì tự chuyển `CANCELLED` theo đúng đường hủy. Người thực hiện là hệ thống, audit ghi lý do. **Platform admin sửa được hạn** trong panel "Giới hạn" của trang AI, giống các giới hạn sinh đề khác.

## Cấu hình: theo đúng cơ chế giới hạn hiện có

Các giới hạn sinh đề đang lưu dưới dạng platform setting:
- danh mục ở `com.pte.billing.QuestionGenerationLimit`
- đọc qua `GenerationLimits` mỗi lần dùng, nên đổi không cần khởi động lại
- khi admin chưa đặt thì dùng giá trị triển khai `QUESTION_GEN_*`

Hạn tự hủy đi đúng đường này:

- [x] `QuestionGenerationLimit.PAUSED_BATCH_EXPIRY_HOURS("question_generation_paused_batch_expiry_hours", 24, 0, 168, "hours", "Hours a paused generation batch is kept before it is cancelled")`.
  - Khoảng hợp lệ 0..168 giờ (tối đa 7 ngày).
  - **0 nghĩa là không tự hủy**, theo quy tắc "0 = không giới hạn" sẵn có (`GenerationLimits.isUnlimited`).
- [x] `QuestionGenerationProperties.limits.pausedBatchExpiryHours`, đọc từ env `QUESTION_GEN_BATCH_PAUSED_EXPIRY_HOURS`, mặc định 24, làm giá trị dự phòng. Thêm biến vào `application.yml`, `docker-compose.services.yml` và `.env.example`; không thêm vào `.env` thật.
- [x] `GenerationLimits.pausedBatchExpiryHours()`.
- [x] Đưa giá trị vào phản hồi trạng thái AI (`AiStatusResponse` limits) và đường cập nhật giới hạn mà `AiOverviewService` đang dùng. Panel admin đọc và ghi qua đúng API hiện có, không thêm endpoint.
- [x] Phản hồi lô có `pauseExpiresAt` tính từ `paused_at` + hạn **lúc đọc**. Admin đổi hạn thì lô đang dừng theo hạn mới; ghi rõ điều này trong mô tả của setting. Hạn bằng 0 thì `pauseExpiresAt = null`.

## Job quét

- [x] `BatchPausedExpiry` (package `batch`), `@Scheduled` cùng nhịp `RECONCILE_DELAY_PROPERTY`:
  - đọc hạn, nếu bằng 0 thì bỏ qua cả vòng
  - tìm `findPausedBefore(now - hạn)`
  - với mỗi lô, trong transaction riêng: khóa lô, kiểm tra lại `PAUSED`, rồi chạy logic hủy
  - Hàm hủy cần nhận người thực hiện là hệ thống: tách lõi của `cancel` thành method nội bộ nhận `actor`, không giả `CurrentUser`.
- [x] Hằng số:
  - audit `BATCH_EXPIRED_WHILE_PAUSED` kèm summary ghi hạn đang áp dụng
  - mã đóng lô `GENERATION_BATCH_PAUSE_EXPIRED`
- [x] Quota: không viết code hoàn. Job chưa chạy bị hủy tự rơi khỏi tổng (`NOT_REFUNDED`).

## Ràng buộc thiết kế

- Dùng `Clock` được inject.
- Một lô lỗi không làm dừng cả vòng quét: bắt lỗi cho từng lô, ghi log chỉ kèm id và loại lỗi.
- Đổi giá trị setting được ghi audit như các giới hạn khác (cơ chế sẵn có của platform settings).

## Kiểm thử

- Hạn 24 giờ: lô dừng 25 giờ bị hủy và có audit hệ thống; lô dừng 23 giờ giữ nguyên.
- Admin đổi hạn thành 2 giờ: lô dừng 3 giờ bị hủy ở vòng quét kế tiếp.
- Hạn bằng 0: không lô nào bị hủy, `pauseExpiresAt` là `null`.
- Setting ngoài khoảng 0..168 bị từ chối bằng lỗi validate sẵn có của giới hạn.
- Lô vừa được tiếp tục giữa lúc quét (không còn `PAUSED` khi khóa) thì giữ nguyên.
- Quota: sau khi tự hủy, `sumRequestedSinceByUser` giảm đúng số câu của các job chưa chạy.
- Test hiện có của `GenerationLimits`, `AiOverviewService` và danh mục setting (nếu có test liệt kê đủ key) được cập nhật.

## Tiêu chí xong

Test qua; giá trị hiện và sửa được qua API trạng thái AI.
