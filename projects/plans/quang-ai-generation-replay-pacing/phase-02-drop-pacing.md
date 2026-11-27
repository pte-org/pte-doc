# Phase 02 — Nhịp kéo field vào preview

**Trạng thái:** [x] · **Phụ thuộc:** không có (làm sau phase 1 để dễ kiểm tra)

## Vấn đề

`useDropQueue` cho mỗi field bay `PIECE_FLY_MS = 1500` và nghỉ `PIECE_GAP_MS = 500`. Field không dừng lại sau khi đáp, nên mắt không theo kịp.

## Thay đổi (`features/questiongeneration`)

1. **`assemblyConstants.ts`.**
   - `PIECE_FLY_MS = 2200`, `PIECE_GAP_MS = 1000`.
   - Thêm `PIECE_SETTLE_MS = 1500`, kèm comment giải thích lý do: để mắt kịp thấy field đã vào đúng chỗ trên preview.
2. **`hooks/useDropQueue.ts`.**
   - Thêm trạng thái `settling: PieceKey | null`.
   - Vòng đời mỗi field: nghỉ `PIECE_GAP_MS` → bay (`flying`) trong `PIECE_FLY_MS` → đáp (vào `placed`) và settling trong `PIECE_SETTLE_MS` → field kế.
   - Trả thêm `idle: boolean`, đúng khi không còn field chờ bay, đang bay hay đang settling.
3. **Preview hiện viền sáng.**
   - Tìm component nhận `placed`/`flying` (`grep useDropQueue`) và truyền thêm `settling`.
   - Field đang settling có viền hoặc ring sáng, dùng token màu có sẵn như `ring-[var(--action)]/30`, đúng với cách `_WritingBrief` đang làm.
   - Không dùng inline style.
4. Giữ đúng thứ tự field hiện tại theo `ready`.

## Test

`tests/unit/features/questiongeneration/useDropQueue.test.ts` (mới, dùng fake timers và `renderHook`):
- Đúng thứ tự gap → flying → settling → field kế.
- `idle` là false trong suốt thời gian đó và chỉ true khi đã xong hết.
- Field mới sẵn sàng giữa chừng thì được thêm vào hàng đợi, không chen ngang field đang bay.

## Hoàn thành khi

- [x] Field bay 2,2s, sáng viền 1,5s, rồi nghỉ 1s trước field kế.
- [x] Có `idle` để phase 3 dùng.
- [x] tsc, eslint và vitest đều qua.

## Ghi chú khi làm

- Không viết được test cho hook `useDropQueue`: vitest của app chạy môi trường `node`, không có thư viện render hook. Logic chỉ được kiểm tra bằng tsc và review.
- `ExamScreenPreview` thuộc `questionbank` nên không làm sáng được từng field bên trong. Thay vào đó, cả khung preview sáng viền trong `PIECE_SETTLE_MS`.
