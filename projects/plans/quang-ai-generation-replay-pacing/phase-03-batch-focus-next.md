# Phase 03 — Trang lô: giữ câu và nút Next

**Trạng thái:** [x] · **Phụ thuộc:** phase 01 (cờ `busy`), phase 02 (`idle`)

## Vấn đề

`BatchDetailView` chọn câu đang xem bằng `focusedJobId(children, pickedJob, currentJobPublicId)`, tức là theo trạng thái server:
- Server xong một job thì trang nhảy sang job đang chạy kế tiếp.
- Lô xong thì trang sang ngay lưới kết quả, trong khi màn hình còn đang phát lại.

## Quyết định của user

- Câu đang xem giữ nguyên cho user review.
- Các câu khác vẫn chạy ở server, không bị chặn.
- Chỉ sang câu khác khi user bấm Next.

## Thay đổi

1. **Báo khi phát lại xong** (`questiongeneration`).
   - `_LiveItemPanel` nhận prop tùy chọn `onReplayDone?: (done: boolean) => void`.
   - `done = !busy && dropQueue.idle && outcome !== null`.
   - Gọi qua `useEffect` khi giá trị đổi. `LiveJobPanel` truyền tiếp xuống.
   - Nếu `idle` nằm ở component con (`_LiveAssembly`), đưa lên bằng callback; không gọi `useDropQueue` hai lần.
2. **Giữ câu đang xem** (`batchgeneration/components/BatchDetailView.tsx`).
   - Lần đầu có `focusedId` khi lô đang chạy thì ghi vào `pickedJob` (dùng effect, hoặc gán trong render có kiểm tra điều kiện, theo đúng mẫu đang dùng trong repo).
   - Sau đó không đổi theo server nữa.
   - Mở trang khi lô đã xong và chưa chọn câu nào: vẫn hiện lưới kết quả như cũ.
3. **Không tự sang lưới kết quả.**
   - Khi `finished` và đang xem một câu: hiện `Alert` "Lô đã xong" kèm nút **Xem kết quả** (`setPickedJob(null)`).
   - Bỏ cách tự chuyển hiện tại.
4. **Nút Next / Trước** (`_BatchFocusNav.tsx` mới).
   - Đặt cạnh tiêu đề panel.
   - Hàm thuần `nextJobId(children, current, seen)` trong `utils/jobExpansion.ts`: ưu tiên câu đã xong mà chưa xem (theo `batchSeq`), rồi đến câu đang chạy, rồi đến câu tiếp theo trong thứ tự.
   - Trước: câu ngay trước theo `batchSeq`.
   - Hết câu thì tắt nút.
5. **Đánh dấu chưa xem.**
   - State `seen: Set<string>`, thêm job vào mỗi khi nó được chọn để xem.
   - `BatchSidebar` hiện chấm nhỏ cho job đã xong mà chưa có trong `seen`, dùng `Badge` hoặc chấm có sẵn trong `@pte/ui`.
6. **"Đã phát lại xong ✓".** Khi `onReplayDone(true)`, hiện một dòng thông tin trên panel. Không tự chuyển câu.
7. **Chữ hiển thị** (vi/en) trong constants của `batchgeneration`:
   - `next` (Câu tiếp), `previous` (Câu trước), `batchDoneViewResults` (Lô đã xong), `viewResults` (Xem kết quả), `replayDone` (Đã phát lại xong), `unseen` (Chưa xem).
8. `BatchDetailView` đang dài, tách component nếu hàm vượt 150 dòng.

## Test

- `tests/unit/features/batchgeneration/jobExpansion.test.ts`: `nextJobId` ưu tiên câu chưa xem, rồi đến câu đang chạy; trả null khi hết câu.
- Logic giữ câu (hàm thuần nếu tách được): server đổi `currentJobPublicId` thì câu đang xem không đổi; lô xong mà đang xem thì không sang lưới.

## Hoàn thành khi

- [x] Server xong job hay xong lô thì câu đang xem vẫn giữ nguyên.
- [x] Next và Trước hoạt động; câu chưa xem được đánh dấu.
- [x] Phát lại xong thì có thông báo, không tự chuyển câu.
- [x] tsc, eslint và vitest đều qua.

## Ghi chú khi làm

- Có thêm một chỗ tự chuyển trong `LiveJobPanel`: job xong là đổi sang `JobOutcomeList` và bỏ phần đang phát lại. Đã sửa: khi live feed còn dữ liệu của job thì vẫn giữ màn phát lại; chỉ dùng danh sách kết quả khi live feed đã xóa (sau 10 phút).
- `BatchDetailView` được tách: phần nội dung chính chuyển sang `_BatchDetailContent.tsx`, để hook `useBatchFocus` không bị gọi sau lệnh return sớm.
