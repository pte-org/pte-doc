# Brainstorm: Bộ máy phát lại duy nhất cho sinh đề AI

**Ngày:** 2026-11-26 · **Tác giả:** quang

## Vấn đề

Luồng phát lại (vendor-web `questiongeneration` và `batchgeneration`) được vá nhiều lần, nên các bước lúc đúng lúc sai.

Mỗi phần trên màn hình tự suy ra "câu đang ở bước nào" từ một nguồn khác nhau:

| Phần | Nguồn hiện tại |
|---|---|
| Thanh bước (`liveSteps`) | live feed đã bị giới hạn bằng `gateLive`, cộng mẹo `typing` (đang gõ thì coi là bước viết) |
| Thẻ trong panel và trong "Thông tin câu hỏi" | `stage` tính trong `_LiveItemPanel` (`behind`, `outcome`, `stillTyping`) |
| Thẻ ở danh sách job của lô | trạng thái job trên server, trừ câu đang mở (`replayingId`) |
| Số "x / y câu đã lưu" | server |
| Field bay sang preview | hàng đợi riêng `useDropQueue` |
| "Đã phát lại xong", nút Next | `onReplayDone`, ghép từ `busy`, `dropsIdle` và `outcome` |

Khi model nhanh hơn (CLIProxyAPI `gpt-6-luna` trả lời trong vài giây) hay chậm hơn (Capstone giữ cả câu trả lời khoảng 56 giây), các nguồn lệch nhau ở một chỗ mới. Lần gần nhất là thẻ báo "Đã lưu" và "Hoàn tất" trong khi màn hình vẫn đang gõ bước viết.

## Điều đã kiểm tra trong code

- SSE gửi sự kiện theo thứ tự: `snapshot`, `begin`, `token`, `thinking`, `stage`, `check`, `draft`, `review`, `media`, `item`, `end`.
- `useLiveJob` gộp ngay mọi sự kiện thành `LiveItems` (`applyLiveEvent`), nên thứ tự bị mất.
- Mỗi lần kết nối (hoặc kết nối lại), server gửi trước một `snapshot` đã gộp. Với model nhanh, hoặc khi mở lại câu đã xong, client nhận gần như toàn bộ câu qua snapshot mà không có lịch sử từng bước.
- `checks` trong snapshot theo đúng thứ tự bắt đầu, nên dựng lại được trình tự các bước.
- Chữ của vòng viết trước (V1) bị ghi đè khi rewrite (V2). Snapshot chỉ còn chữ của vòng mới nhất.

## Các hướng đã xem

1. **A. Bộ máy phát lại duy nhất** (danh sách sự kiện, đầu phát, khung hình). **Chọn.**
2. **B. Server lưu và gửi lại toàn bộ lịch sử sự kiện của từng câu.** Giữ được cả chữ V1. Để sau (P3), vì A dựng lại được kịch bản từ snapshot cộng sự kiện mà không đổi backend.
3. **C. Giữ cấu trúc cũ, chỉ thêm test.** Loại: gốc lỗi là có nhiều nguồn sự thật, thêm test không gỡ được.
4. **D. Bỏ phát lại, hiện thẳng kết quả.** Loại: user muốn xem từng bước.

## Hướng user chọn

- Thay toàn bộ bằng một bộ máy phát lại duy nhất, làm theo nhiều phase, mỗi phase có test.
- Harness dùng SSE thật ghi từ local (CLIProxyAPI nhanh, Capstone chậm, rewrite V2) cộng fixture viết tay cho ca hiếm (lỗi giữa chừng, fallback, hủy, kết nối lại, mở lại câu đã xong).

## Thiết kế đề xuất

1. **Kịch bản (script).** Hàm thuần `buildScript(snapshot, events)` biến snapshot và các sự kiện sau đó thành một dãy bước có thứ tự cho mỗi câu. Ví dụ: Prompt, Viết V1 (chữ), Kiểm tra JSON/luật/trùng, Review (chữ, kết luận), Viết V2 nếu bị trả lại, Media, Ghép màn thi, Lưu hoặc Lỗi.
   - Sự kiện mới chỉ được **nối thêm** vào cuối kịch bản.
   - Riêng chữ của bước đang viết được phép dài thêm.
2. **Đầu phát (playhead).** Đầu phát gồm số thứ tự bước và tiến độ bên trong bước đó (số ký tự đã gõ, số field đã đặt). Hàm thuần `advance(playhead, script, elapsed, settings)` tiến đầu phát theo luật rõ ràng: gõ hết chữ, field bay xong và đứng yên, người dùng bấm tiếp nếu đang dừng sau mỗi bước, hoặc người dùng bấm Hiện hết. Đầu phát không bao giờ lùi.
3. **Khung hình (frame).** Hàm thuần `frameOf(script, playhead)` trả mọi thứ màn hình cần: trạng thái từng bước, chữ đã hiện, field đã đặt, nhãn thẻ, kết quả (chỉ có sau khi đã phát tới bước cuối), và `done`.
4. **React chỉ hiển thị.** Một hook duy nhất (`useReplay`) giữ đầu phát và chạy đồng hồ. Mọi component đọc từ khung hình. Thẻ ở danh sách lô đọc `done` của câu đang mở.
5. **Gỡ bỏ:** `gateLive`, các mẹo trong `liveSteps`, `stillTyping`/`behind`/`outcome` trong `_LiveItemPanel`, `endedWhenOpened`, `replayingId`, và luật bước của `useDropQueue` (chỉ giữ phần animation).
6. **Harness.**
   - Fixture là file NDJSON gồm các sự kiện SSE kèm thời điểm nhận.
   - Runner chạy fixture qua `buildScript`, `advance` và `frameOf` với đồng hồ giả, rồi kiểm tra bất biến ở mọi tick.
   - Bất biến: bước không lùi; nhãn thẻ khớp bước đang phát; "Đã lưu" chỉ hiện ở bước Lưu; thanh bước và các thẻ khớp nhau; chữ hiện ra là tiền tố của chữ thật; kết thúc thì `done` bằng true.

## Câu hỏi mở cho /ck:plan

- Ghi SSE thật bằng cách nào: một script node đọc `/live` với token local, hay một cờ debug ở client tải xuống NDJSON?
- Kết nối lại giữa chừng thì server gửi snapshot mới. Cần hợp nhất snapshot đó vào kịch bản đang phát mà không làm đầu phát nhảy lùi.
- "Bỏ qua phát lại câu đã xong" và "Hiện hết" trở thành luật của `advance` (nhảy đầu phát tới cuối), không phải nhánh riêng `instant`.

## Rủi ro

- Thay đổi lớn ở một màn hình đang dùng. Cần làm theo phase, và giữ được hành vi mà user đã duyệt: nhịp gõ, tốc độ, field bay.
- Có hai nguồn thời gian, đồng hồ thật và `requestAnimationFrame`. Đồng hồ phải tiêm vào được thì harness mới chạy bằng đồng hồ giả.
- Fixture ghi từ SSE thật chứa nội dung đề do AI sinh. Không chứa key, nhưng nên giữ fixture nhỏ.
