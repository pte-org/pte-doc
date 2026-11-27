# Phase 03: worker phân biệt dừng và hủy

**Trạng thái:** [ ] Chưa làm · **Repo:** pte-api · **Phụ thuộc:** 01, 02

## Mục tiêu

Job bị ngắt vì tạm dừng thì trả câu dở về hàng chờ, quay job về `PENDING` và nhả lease. Job bị ngắt vì hủy vẫn đóng `CANCELLED` như hiện nay.

## Bối cảnh

`GenerationJobRunner` hiện có đoạn `if (Thread.interrupted()) outcome = ItemOutcome.CANCELLED;`. Cờ interrupt không mang lý do, nên thiếu bước này thì tạm dừng sẽ hủy câu (rủi ro 1 của plan).

## Việc cần làm

- [ ] `QuestionGenerationWorker.onPauseRequested(GenerationPauseRequested)`: sau commit gọi `task.cancel(true)`, giống `onCancelRequested`. Có thể gộp hai event thành một `GenerationStopRequested` nếu gọn hơn, miễn giữ được tên event hủy cho code đang dùng.
- [ ] `LeaseState`: thêm `PAUSE_REQUESTED`. `JobLeaseService.leaseState` trả trạng thái này khi job `PAUSING`; runner kiểm tra nó trước mỗi câu (đường không ngắt, ví dụ khi job chạy ở instance khác).
- [ ] `GenerationItemStateService.stopReason(claim)`: đọc `statusIfLeaseHeld`, trả `PAUSING`, `CANCELLING` hoặc rỗng. Hàm `cancelRequested` cũ dùng lại hàm này.
- [ ] `ItemOutcome.PAUSED`. Trong runner: bị ngắt thì đọc `stopReason`. Kết quả là `CANCELLING` hoặc rỗng (mất lease hay lỗi khác) thì giữ hành vi cũ; là `PAUSING` thì ra `PAUSED`.
- [ ] Nhánh `PAUSED`:
  - `itemState.requeueOpen(claim)`: câu chưa ở trạng thái cuối về `QUEUED`; xóa bản nháp, review, media ref và bộ đếm lời gọi của vòng dở.
  - `leases.release(claim)`: job về `PENDING`, xóa worker id và hạn lease, **giữ** `started_at` (D4).
  - Hook chaining của lô được gọi để kiểm tra chuyển `PAUSED` (phase 02).
- [ ] Live feed: phát sự kiện cho người đang xem biết câu dở đã quay về hàng chờ. Đề xuất phát `stage QUEUED` cho câu đó rồi `end` cho job. Phase 06 dùng sự kiện này để đánh dấu vòng dở là `superseded`.
- [ ] Media dở: nếu vòng bị ngắt đã có `audioRef`/`imageRef` nhưng câu chưa lưu thì xóa file qua dịch vụ media sẵn có, ghi log khi xóa thất bại. Còn file đang tải dở mà chưa có ref thì chấp nhận và ghi chú lại. Local và prod dùng chung tài khoản Cloudinary, nên chỉ xóa đúng ref của vòng dở.

## Ràng buộc thiết kế

- Xóa cờ interrupt (`Thread.interrupted()`) **trước** khi gọi DB, giống code hiện tại, để các lệnh đóng không bị hỏng theo.
- Hủy thắng dừng: trạng thái đọc lại là `CANCELLING` thì hủy, kể cả khi trước đó đã có yêu cầu dừng.
- `GenerationJobRunner` không vượt 300 dòng; tách `StopHandler` nếu cần.

## Kiểm thử

- Runner:
  - bị ngắt khi job `PAUSING`: câu dở `QUEUED`, job `PENDING`, `started_at` giữ nguyên
  - bị ngắt khi job `CANCELLING`: hành vi cũ
  - dừng rồi hủy trước khi runner đọc lại: hủy
  - `PAUSE_REQUESTED` thấy được trước câu, không qua ngắt
- `requeueOpen`: không đụng câu `SAVED`/`FAILED`.
- Test hiện có của worker, runner và lease vẫn qua.

## Tiêu chí xong

Test worker, pipeline và lease qua. Chạy thử local: lô 6 câu, dừng giữa chừng, tiếp tục, tổng cuối đủ 6 câu và không có câu `CANCELLED`.
