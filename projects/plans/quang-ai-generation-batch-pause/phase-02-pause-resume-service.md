# Phase 02: service và endpoint tạm dừng / tiếp tục

**Trạng thái:** [ ] Chưa làm · **Repo:** pte-api · **Phụ thuộc:** 01

## Mục tiêu

API dừng, tiếp tục và hủy-khi-đang-dừng chạy đúng ở tầng DB. Worker chưa ngắt (phase 03): ở phase này job đang chạy chỉ được đánh dấu `PAUSING`.

## Việc cần làm

- [ ] Thêm `pause` và `resume` vào `QuestionGenerationBatchService` (thành 4 public method, trong giới hạn 5). Nếu file vượt 300 dòng thì tách `BatchPauseService` vào package `batch`, giữ cùng thứ tự khóa.
- [ ] `pause(publicId, caller)`:
  1. `queries.require` (chỉ chủ lô), `batches.findByIdForUpdate`.
  2. Cập nhật có điều kiện `status IN PAUSABLE → PAUSING`, ghi `paused_at = now`.
     - Không đổi được mà lô đang `PAUSING`/`PAUSED`: trả trạng thái hiện tại (idempotent).
     - Các trường hợp khác: `409 GENERATION_BATCH_NOT_PAUSABLE`.
  3. Job `QUEUED` của lô (chưa có worker nhận) về lại `PENDING`, bằng cập nhật có điều kiện trên status `QUEUED`.
  4. Job `RUNNING` chuyển `PAUSING` (`jobs.markPausing`), rồi phát `GenerationPauseRequested(jobPublicId)` sau commit.
  5. Không còn job `LEASED` thì chuyển ngay `PAUSED`.
  6. Ghi audit `BATCH_PAUSED`.
- [ ] `resume(publicId, caller)`:
  - `PAUSED → RUNNING`, xóa `paused_at`, rồi `chaining.topUp(batchId)` (mở `topUp` thành package-visible hoặc thêm method `resume` trong `BatchChainingService`).
  - Lô `PAUSING`: `409 GENERATION_BATCH_NOT_RESUMABLE`. Lô `RUNNING`: idempotent. Ghi audit `BATCH_RESUMED`.
- [ ] `cancel`: nhận thêm `PAUSING` và `PAUSED` (`requestCancel` dùng tập `CANCELLABLE`). Job `PAUSING` được chuyển `CANCELLING`, nên hủy thắng dừng (D7). Lô `PAUSED` không còn job giữ lease nên đóng `CANCELLED` ngay.
- [ ] `BatchChainingService`:
  - `topUp` trả 0 khi lô `PAUSING`/`PAUSED`.
  - `chain`/`reconcile`: lô `PAUSING` mà không còn job `LEASED` thì chuyển `PAUSED`. Không đóng lô đang dừng như lô đã xong.
- [ ] Repository: `markPausing`, `requeueQueued(batchId)`, `pause/resume` có điều kiện, `findPausedBefore(Instant)` (để phase 04 dùng).
- [ ] Controller `QuestionGenerationBatchController`: `POST /{publicId}/pause`, `POST /{publicId}/resume`, cùng quyền với `cancel`.
- [ ] Hằng số trong `BatchGenerationConstants`:
  - mã lỗi `GENERATION_BATCH_NOT_PAUSABLE`, `GENERATION_BATCH_NOT_RESUMABLE` kèm câu chữ
  - action audit `BATCH_PAUSED`, `BATCH_RESUMED` kèm summary
- [ ] `ApiInventoryExportTest`: thêm 2 route.

## Ràng buộc thiết kế

- Thứ tự khóa giống `cancel`: khóa hàng lô trước, rồi tới job. Không đọc trạng thái từ entity đã load trước khi khóa.
- Mọi chuyển trạng thái là `UPDATE ... WHERE status IN (...)`; số dòng bị đổi quyết định kết quả.
- Lỗi dùng `GenerationJobConflictException` như `cancel`; không đổi khuôn envelope lỗi (`docs/COMMON_EXCEPTION_SETUP.md`).

## Kiểm thử

- Service, với repository giả hoặc lớp test sẵn có của batch:
  - dừng lô đang chạy (`QUEUED → PENDING`, `RUNNING → PAUSING`, có phát event)
  - dừng lô không có job chạy thì `PAUSED` ngay
  - dừng hai lần (idempotent)
  - dừng lô đã xong trả 409
  - tiếp tục lô `PAUSED` thì gọi `topUp`
  - tiếp tục lô `PAUSING` trả 409
  - hủy lô `PAUSED` thì `CANCELLED` ngay
  - hủy lô `PAUSING` thì job `PAUSING → CANCELLING`
- `BatchChainingService`: lô dừng không được đẩy job; job cuối nhả lease thì lô chuyển `PAUSED`.
- Controller: route, quyền (người khác và vai trò tenant bị từ chối).

## Tiêu chí xong

Compile và các test batch, chaining, controller, inventory qua.
