# Phase 05: nút, trạng thái và thông báo trên web

**Trạng thái:** [ ] Chưa làm · **Repo:** pte-web · **Phụ thuộc:** 02

## Mục tiêu

Người dùng dừng và tiếp tục lô từ trang chi tiết lô, thấy rõ lô đang dừng ở mọi nơi hiện trạng thái lô.

## Việc cần làm

- [ ] api-client:
  - `QuestionGenerationBatchStatus` thêm `PAUSING`, `PAUSED`; batch response thêm `pausedAt`, `pauseExpiresAt` (backend tính sẵn, để web khỏi biết cấu hình hạn); request `pauseQuestionGenerationBatch`, `resumeQuestionGenerationBatch`.
  - Thêm câu chữ en và vi cho `GENERATION_BATCH_NOT_PAUSABLE`, `GENERATION_BATCH_NOT_RESUMABLE`, `GENERATION_BATCH_PAUSE_EXPIRED` vào `errorMessage.ts` và `userMessagesVi.ts` (có test đối chiếu hai ngôn ngữ).
- [ ] `batchgeneration/api.ts`: `usePauseQuestionGenerationBatch`, `useResumeQuestionGenerationBatch`, cùng cách invalidate với cancel.
- [ ] `_BatchDetailContent.tsx` (đã gần 150 dòng, tách `_BatchActions.tsx`):
  - lô `RUNNING`/`QUEUED`: nút **Tạm dừng** (`variant="secondary"`) cạnh **Hủy lô**
  - lô `PAUSING`: nút khóa, ghi "Đang dừng…"
  - lô `PAUSED`: nút **Tiếp tục** (`primary`) và **Hủy lô**
  - Không có hộp xác nhận. Dòng phụ cạnh nút: "Câu đang viết sẽ được viết lại khi tiếp tục".
- [ ] `constants.ts`: `CANCELLABLE_BATCH_STATUSES` thêm `PAUSING`, `PAUSED`; thêm `PAUSABLE_BATCH_STATUSES` và `RESUMABLE_BATCH_STATUSES`.
- [ ] `_BatchStatusBadge`: nhãn và màu cho `PAUSING` ("Đang dừng…") và `PAUSED` ("Đã tạm dừng"). Ở trang chi tiết lô `PAUSED` thì thêm "· tự hủy lúc {giờ}".
- [ ] `utils/jobChip.ts`: job quay về `PENDING` sau khi dừng hiện "Chờ lượt", không còn "Đang chạy".
- [ ] Sidebar activity (`generationActivity.ts`, `GenerationActivityNavItem.tsx`):
  - `OPEN_BATCH_STATUSES` thêm hai trạng thái mới
  - lô dừng hiện chấm tĩnh màu xám thay vì chấm nhấp nháy, kèm "Tạm dừng"
  - polling dùng nhịp chậm (`ACTIVITY_IDLE_POLL_MS`) khi lô đang dừng
- [ ] Panel "Giới hạn" của trang AI (`features/aiadmin`):
  - `AiStatusLimits` (api-client) thêm `pausedBatchExpiryHours`
  - `GENERATION_LIMITS` thêm dòng `{ field: "pausedBatchExpiryHours", settingKey: "question_generation_paused_batch_expiry_hours", label: "PAUSED_EXPIRY", unit: "UNIT_HOURS", min: 0, max: 168 }`
  - Câu chữ: nhãn "Tự hủy lô tạm dừng sau" / "Cancel a paused batch after"; đơn vị "{count} giờ" / "{count} hours"; gợi ý "0 = không tự hủy. Áp dụng cả cho lô đang dừng."
  - Giá trị 0 hiện "Không tự hủy" (như "Không giới hạn" của các giới hạn ngày).
  - Panel đang chia 5 cột trên màn rộng; dòng thứ sáu cần kiểm tra lại lưới (`lg:grid-cols-5` → `lg:grid-cols-6` hoặc xuống hàng).
- [ ] Messages en và vi cho mọi câu chữ mới; không có chuỗi nào viết thẳng trong JSX.

## Ràng buộc thiết kế

- Nút dùng `Button` của `@pte/ui` như đang có, không tự chỉnh màu.
- Không đổi luồng hủy lô hiện có, ngoài việc mở rộng tập trạng thái.

## Kiểm thử

- `jobChip`, `generationActivity`: có ca cho `PAUSING`/`PAUSED`.
- Render tĩnh `_BatchActions`: đúng nút cho từng trạng thái.
- Test đối chiếu câu chữ lỗi en và vi của api-client.
- aiadmin: dòng hạn tự hủy hiện đúng, 0 hiện "Không tự hủy", giá trị ngoài 0..168 bị đánh dấu lỗi.
- `tsc`, `eslint` và vitest của vendor-web và api-client đều qua.

## Tiêu chí xong

Trên local: dừng, thấy "Đã tạm dừng"; tiếp tục, lô chạy lại; mục ở sidebar đổi đúng.
