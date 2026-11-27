# Sinh đề AI: nhịp phát lại và chuyển câu trong lô — Brainstorm

**Ngày:** 2026-11-26 · **Phạm vi:** `pte-web/apps/vendor-web` (`features/questiongeneration`, `features/batchgeneration`). Không đổi backend hay API.
**Liên quan:** [brainstorm của kế hoạch fallback](../quang-ai-generation-streaming-fallback/brainstorm.md)

## 1. Vấn đề

1. **Chữ gõ quá nhanh.**
2. **Field kéo vào preview quá nhanh**, chưa kịp nhìn thì câu đã lưu và trang lô đã chuyển sang câu khác hoặc sang màn hình kết quả.

## 2. Nguyên nhân (đã xác minh trong code)

| # | Nguyên nhân | Vị trí |
|---|---|---|
| 1 | Nhịp gõ tính theo **khung hình**: `TYPING_CHARS_PER_FRAME = 1` cho mỗi `requestAnimationFrame`, nên tốc độ phụ thuộc màn hình: 60 ký tự/giây ở 60 Hz, 144 ký tự/giây ở 144 Hz. | `liveConstants.ts`, `hooks/useTypedText.ts`, `utils/typingStep.ts` |
| 2 | Mỗi field bay 1,5s, cách nhau 0,5s, và **không dừng lại sau khi đáp**, nên field kế tiếp bay ngay. | `assemblyConstants.ts` (`PIECE_FLY_MS`, `PIECE_GAP_MS`), `hooks/useDropQueue.ts` |
| 3 | Trang lô chọn câu đang xem theo **trạng thái server**. Server xong job (thường xong từ lâu, vì model free trả cả khối) thì `focusedJobId` nhảy sang job đang chạy kế tiếp. Lô kết thúc thì đổi ngay sang lưới kết quả, trong khi màn hình còn đang gõ hoặc kéo field. | `batchgeneration/components/BatchDetailView.tsx:63-67`, `utils/jobExpansion.ts` |

## 3. Quyết định (user đã chọn)

| Vấn đề | Quyết định |
|---|---|
| Tốc độ gõ | Gõ **theo thời gian**, có lựa chọn **Chậm 15 / Vừa 30 / Nhanh 60 ký tự/giây**. Mặc định là Vừa, trình duyệt nhớ lựa chọn. Có nút **Hiện hết**. |
| Kéo field vào preview | Mỗi field **bay 2,2s**. Sau khi đáp, field trên preview **sáng viền 1,5s**. Hai field **cách nhau 1s**. |
| Chuyển câu trong lô | **Không tự chuyển.** Câu đang xem giữ nguyên cho user review. Các câu khác vẫn chạy ở server, không bị chặn. User bấm **Next** thì mới sang câu khác. |

Đánh giá phương án chuyển câu của user: **hợp lý và làm được.**
- Server chạy các job độc lập với màn hình. Màn hình chỉ là người xem nên giữ một câu lâu bao nhiêu cũng không làm chậm lô.
- Chỉ cần đổi cách trang lô chọn câu đang xem: chọn một lần rồi giữ nguyên.

## 4. Thiết kế

### 4.1 Nhịp gõ theo thời gian (`questiongeneration`)

- `useTypedText(target, charsPerSecond)`: mỗi frame tính số ký tự được hiện = `floor((now − start) × cps)`. Tốc độ giống nhau trên màn 60 Hz và 144 Hz. Bỏ `TYPING_CHARS_PER_FRAME`, thêm `TYPING_SPEEDS = { slow: 15, normal: 30, fast: 60 }`.
- `hooks/useTypingSpeed.ts`: lưu lựa chọn vào `localStorage`. Lần đầu dùng `normal`.
- Thanh điều khiển cạnh "Dừng sau mỗi bước" (`_StepGateBar`), gồm: chọn tốc độ (dùng segmented control hoặc `Select` của `@pte/ui`, không tự vẽ) và nút **Hiện hết**. Hiện hết chỉ hiện chữ đã nhận, không bỏ qua các bước đang tạm dừng hay bước xác nhận trước khi lưu.
- Bộ đếm "còn đang gõ" (`stillTyping`) giữ như hiện tại. Bước kế tiếp của gate vẫn chờ gõ xong.

### 4.2 Kéo field vào preview

- `PIECE_FLY_MS = 2200`, `PIECE_GAP_MS = 1000`, thêm `PIECE_SETTLE_MS = 1500`.
- `useDropQueue` có thêm trạng thái `settling: PieceKey | null`. Sau khi đáp, field được đánh dấu settling trong `PIECE_SETTLE_MS` (preview hiện viền sáng), xong mới tới field kế tiếp.
- `useDropQueue` trả thêm `idle` (không còn field chờ bay, bay hay settling) để biết lúc phát lại xong (mục 4.3).

### 4.3 Trang lô: giữ câu đang xem, bấm Next mới chuyển (`batchgeneration`)

- **Giữ câu đang xem:** lần đầu mở trang, `focusedJobId` chọn như hiện tại (job đang chạy). Sau đó ghi job đó vào `pickedJob` và **giữ nguyên**, kể cả khi server đã xong job hoặc xong cả lô.
- **Không tự sang lưới kết quả:**
  - Khi lô đã xong mà user còn đang xem một câu, hiện thông báo "Lô đã xong · **Xem kết quả**" phía trên. Bấm vào mới mở lưới.
  - Mở trang khi lô đã xong từ trước (chưa xem câu nào): vẫn vào thẳng lưới kết quả như hiện tại.
- **Next / Trước** cạnh tiêu đề panel, đi theo thứ tự `batchSeq`. Next ưu tiên câu xong mà chưa xem, rồi đến câu đang chạy.
- **Đánh dấu "chưa xem"** ở sidebar cho câu đã xong mà user chưa mở. Giữ trong state của trang, không lưu server.
- **Thanh "Đã phát lại xong ✓"** hiện khi câu đang xem đã gõ xong, đã kéo xong và có kết quả. Đây chỉ là thông tin, không tự chuyển.
  - `LiveItemPanel` báo trạng thái phát lại xong qua callback `onReplayDone`, tính từ `!busy && dropQueue.idle && outcome`.

### 4.4 Phát lại câu chạy ngầm

- Khi bấm Next sang một câu đã chạy ngầm, panel phát lại từ đầu theo đúng nhịp, vì live feed còn giữ toàn bộ chữ trong `QUESTION_GEN_LIVE_FINISHED_RETENTION_MS`, mặc định 10 phút. Không cần sửa backend.
- Quá 10 phút thì live feed không còn: panel hiện câu đã lưu như hiện tại, không có phát lại. Đây là giới hạn chấp nhận được.

## 5. Kiểm thử (vitest, không dùng trình duyệt)

- `useTypedText`: dùng fake timers và mock `performance.now`. Xác nhận cùng thời gian trôi qua thì hiện cùng số ký tự, dù số frame khác nhau. Hiện hết thì hiện ngay toàn bộ.
- `useDropQueue`: thứ tự bay → settling → nghỉ → field kế. `idle` chỉ đúng khi đã hết field.
- `focusedJobId` / logic giữ câu: job server xong thì không đổi câu đang xem. Lô xong mà đang xem thì không sang lưới. Next chọn đúng câu chưa xem.
- Giữ nguyên các test `stepGate`, `livePieces`. Cập nhật `typingStep.test.ts`.

## 6. Rủi ro

- Chậm 15 ký tự/giây với passage 1.200 ký tự mất 80 giây. Đã có nút Hiện hết và lựa chọn tốc độ.
- `_LiveItemPanel.tsx` và `liveConstants.ts` đã gần 300 dòng. Hằng số tốc độ đưa vào file riêng (`typingConstants.ts`), callback giữ ngắn.
- Chữ trên thanh điều khiển (Chậm/Vừa/Nhanh, Hiện hết, Next, "Lô đã xong · Xem kết quả", "Đã phát lại xong") đặt trong constants vi/en.

## 7. Bước tiếp theo

→ `/ck:plan`, chia 3 phase: (1) gõ theo thời gian và chọn tốc độ, (2) nhịp kéo field, (3) giữ câu và Next trong trang lô.
