# Phase 05 — Trang lô đọc `frame.done`

**Trạng thái:** [x] [quality: skipped_by_user; decision: user_confirmed_skip] · **Phụ thuộc:** phase 04 (4a-4c)
**Stories:** P1 thẻ ở danh sách khớp panel (I2), P2 giữ câu và Next; spec "Đã chốt" (số x / y đã lưu theo server); FR-06 (phần `batchgeneration`)

## Vấn đề

Chip RUNNING của câu đang mở được giả bằng `replayingId` (`_BatchDetailContent.tsx:81`, `_BatchJobPicker.tsx:68`), suy từ `replayDone` (`hooks/useBatchFocus.ts:28, 37-43, 53`). Đó là một nguồn lệch riêng. Chip nên đọc `frame.done` của câu đang mở.

## Thay đổi

1. `features/questiongeneration/components/LiveJobPanel.tsx` — giữ `onReplayDone(done)` nhưng `done` đến thẳng từ `frame.done` của câu đang mở.
2. `features/batchgeneration/hooks/useBatchFocus.ts` — giữ `replayDone` (nay là `frame.done`), bỏ phần suy ra `replayingId`. Giữ `picked`, `seen`, `nextId`, `previousId`, `unseen`.
3. `features/batchgeneration/components/_BatchDetailContent.tsx` — bỏ prop `replayingId` truyền vào `BatchSidebar` (dòng 81); truyền `replayDone` và `focusedId`.
4. `features/batchgeneration/components/_BatchSidebar.tsx` và `_BatchJobPicker.tsx` — chip của job đang mở: `!replayDone` thì RUNNING, ngược lại theo `job.status`. Lý do là `frame.done`, không còn cờ `replayingId`. Đọc đầy đủ `_BatchSidebar.tsx` trước (mới thấy dòng 21, 35, 107, 138).
5. `features/batchgeneration/components/_BatchFocusNav.tsx` — giữ, chỉ nhận `replayDone` từ `frame.done`.
6. **Quay lại câu đã xem dở (L6).** Chọn **tiếp tục**: đầu phát theo `(jobId, index)` nằm trong store của phase 4a, nên Previous/Next quay lại thì chạy tiếp từ chỗ cũ. Khi trang lô đóng thì store xóa.
7. **`done` của script không bao giờ kết thúc (M5).** Chip và `replayDone` không chờ `end`: khi kết nối rớt không có `end` mà job (poll `LIVE_JOB_REFRESH_MS`) đã ở trạng thái cuối, hook nối `outcome` (phase 4a), nên `frame.done` vẫn thành true. Không thêm đồng hồ hay cờ nào trong `batchgeneration`.
8. Số "x / y đã lưu" (`job.succeededCount`/`requestedCount` ở `_BatchJobPicker.tsx:57`) giữ theo server.
9. Test trong `tests/unit/features/batchgeneration/` cho hàm thuần chọn trạng thái chip (nếu tách); `nextJobId`, `previousJobId`, `unseenJobIds` không đổi nên test cũ giữ.

## Design Constraints

- Chỉ chip của câu đang mở đi theo khung hình. Chip các job khác và số "x / y đã lưu" lấy từ server.
- Giữ câu đang mở và Next/Trước đúng như phase 3 của kế hoạch pacing; server xong job hay lô không làm trang đổi câu.
- Không đổi backend hay API; không thêm nguồn trạng thái mới trong `batchgeneration`.
- Chữ hiển thị trong constants `batchgeneration` (vi/en).

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

## Test

- Hàm chọn trạng thái chip: job đang mở và `done = false` cho RUNNING; `done = true` theo status server; job khác luôn theo status server.
- **Rớt kết nối (M5):** fixture `stream-drop-no-end` (phase 3): feed rớt không `end`, job record báo SAVED về sau thì `frame.done` thành true khi đầu phát tới cuối; không treo ở "đang chạy".
- Test store đầu phát: quay lại `(jobId, index)` đã xem dở thì đầu phát giữ nguyên.
- Chạy lại toàn bộ test `batchgeneration` và `questiongeneration`.
- User tự kiểm tra: server xong job sớm hơn phần phát thì chip vẫn RUNNING cho đến khi phát xong, và không tự chuyển câu.

## Hoàn thành khi

- [x] `replayingId` không còn được truyền hay đọc ở trang lô.
- [x] Chip câu đang mở và panel không lệch nhau; rớt kết nối không làm chip treo.
- [x] tsc, eslint, vitest đều qua.

## Ghi chú khi làm

- `useBatchFocus` hiện `setPicked` và `setSeen` trong lúc render (dòng 33-34). Giữ mẫu đã được duyệt.
- Nếu `onReplayDone` gọi từ effect với giá trị đổi liên tục, kiểm tra `frame.done` chỉ chuyển từ false sang true một lần cho mỗi câu.
- Đã làm (2026-11-26): `utils/jobChip.ts` (`jobChipStatus`), `_BatchJobPicker`/`_BatchSidebar`/`_BatchDetailContent` đổi `replayingId` thành `replayDone`. `replayDone` vẫn đến từ `onReplayDone` của panel, và với đường mới đó là `frame.done`. Test: `jobChip.test.ts` (4 test). Chạy lại toàn bộ `batchgeneration` và `questiongeneration`: 325 test qua.
- Khác plan một chút: chip chỉ giả "đang chạy" khi server đã kết thúc job (COMPLETED, FAILED, CANCELLED) mà phần phát chưa xong. Job còn PENDING hay QUEUED vẫn hiện đúng trạng thái server (trước đây một job chưa chạy được mở ra cũng hiện "đang chạy").
- Rớt kết nối (M5) đã được phủ bởi fixture `stream-drop-no-end` ở harness (phase 3): kết quả của job vào qua `closed-terminal`, `frame.done` thành true.
- Store đầu phát (quay lại câu xem dở thì tiếp tục) là `replay/playheadStore.ts` + `useReplay` từ phase 4a, có test ở `hookParts.test.ts`. Store chỉ xóa khi `clearPlayheads` được gọi; chưa có chỗ nào gọi nó khi trang lô đóng hay `jobId` đổi: ghi vào việc cần làm ở phase 6.
