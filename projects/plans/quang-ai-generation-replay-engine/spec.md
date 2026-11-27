# Spec: Bộ máy phát lại duy nhất cho sinh đề AI

**Ngày:** 2026-11-26 · **Tác giả:** quang
**Trạng thái:** Đã làm (2026-11-26)
**Nguồn:** [brainstorm.md](brainstorm.md)
**Phạm vi:** `pte-web/apps/vendor-web` (`features/questiongeneration`, `features/batchgeneration`). Không đổi backend và API.

---

## Vấn đề

Màn hình phát lại sinh đề có nhiều nguồn trạng thái độc lập (thanh bước, các thẻ, danh sách job, hàng đợi field, "đã phát lại xong"). Chúng lệch nhau khi tốc độ model thay đổi, ví dụ thẻ "Đã lưu" hiện trong khi chữ còn đang gõ.

---

## User Stories

- **[P1]** Là người tạo đề, khi xem một câu đang được sinh, tôi muốn thanh bước, các thẻ trạng thái và nội dung luôn cùng một bước, dù model nhanh hay chậm.
  Đạt khi: trên mọi fixture, ở mọi tick, nhãn thẻ trong panel, thẻ ở danh sách job và bước đang chạy của thanh bước cùng ứng với một bước của kịch bản.

- **[P1]** Là người tạo đề, tôi muốn các bước đi lần lượt, không nhảy lùi và không bỏ bước.
  Đạt khi: chỉ số bước của đầu phát không bao giờ giảm. Mọi bước có trong kịch bản đều được phát (trừ khi người dùng chọn Hiện hết hoặc Bỏ qua phát lại).

- **[P1]** Là người tạo đề, tôi muốn kết quả (Đã lưu hoặc Lỗi) chỉ hiện khi màn hình đã phát tới bước cuối.
  Đạt khi: trên mọi fixture, `frame.outcome` là null cho tới khi đầu phát ở bước Lưu hoặc Lỗi.

- **[P1]** Là người phát triển, tôi muốn có một harness chạy lại được các dòng sự kiện thật để bắt lỗi lệch nhịp trước khi user thấy.
  Đạt khi: `vitest` chạy ít nhất 8 fixture và kiểm tra mọi bất biến ở mọi tick, trong dưới 5 giây.

- **[P2]** Là người tạo đề, tôi muốn các tùy chọn hiện có vẫn hoạt động như cũ: tốc độ gõ, Hiện hết, Dừng sau mỗi bước, Bỏ qua phát lại câu đã xong, giữ câu và nút Next.
  Đạt khi: mỗi tùy chọn có test trên `advance` và hành vi trên giao diện không đổi (user tự kiểm tra).

- **[P3]** _(ngoài phạm vi)_ Server lưu và gửi lại toàn bộ lịch sử sự kiện để phát lại được cả chữ V1 khi đã rewrite.

---

## Yêu cầu chức năng

1. **FR-01:** `buildScript(snapshot | null, events[])` là hàm thuần. Nó trả về kịch bản có thứ tự cho từng câu.
   - Sự kiện đến sau chỉ được nối thêm vào cuối kịch bản. Riêng chữ của bước viết hoặc review đang diễn ra thì được dài thêm.
   - Một snapshot mới (khi kết nối lại) được hợp nhất vào kịch bản đang có, không thay toàn bộ.
2. **FR-02:** Các loại bước của kịch bản: `prompt`, `write` (round, chữ, suy nghĩ), `check` (JSON, rules, duplicate; kết quả), `review` (round, chữ, kết luận), `media`, `assemble`, `outcome` (SAVED, READY, FAILED, CANCELLED).
3. **FR-03:** `advance(playhead, script, elapsedMs, settings)` là hàm thuần.
   - Gõ chữ theo `charsPerSecond`.
   - Mỗi field: nghỉ, bay, rồi đứng yên. Dùng lại các hằng hiện có `PIECE_GAP_MS`, `PIECE_FLY_MS`, `PIECE_SETTLE_MS`.
   - Dừng sau mỗi bước khi người dùng bật tùy chọn đó, tiếp tục khi người dùng bấm.
   - Hiện hết đưa chữ của bước hiện tại về cuối.
   - Bỏ qua phát lại đưa đầu phát tới cuối kịch bản.
4. **FR-04:** `frameOf(script, playhead)` trả về đúng một khung hình: các bước của thanh bước kèm trạng thái, chữ đã hiện, field đã đặt hoặc đang bay, nhãn và tông màu của thẻ, `outcome`, `done`, và `heldAtStep`.
5. **FR-05:** Hook `useReplay(jobId, index)` là nơi duy nhất giữ đầu phát và chạy đồng hồ (`requestAnimationFrame`). Đồng hồ được tiêm vào để test.
6. **FR-06:** Mọi component chỉ đọc khung hình, gồm `_LiveItemPanel`, `_LiveAssembly`, `_LiveStepper`, thẻ trạng thái, `_BatchJobPicker`, `_BatchFocusNav`. Không component nào đọc `record.stage` hay live feed để quyết định bước.
7. **FR-07:** Gỡ bỏ `gateLive`, các mẹo bước trong `liveSteps`, `stillTyping`/`behind`/`outcome` trong `_LiveItemPanel`, `endedWhenOpened`, `replayingId` và luật thời gian trong `useDropQueue`.
8. **FR-08:** Harness gồm:
   - Fixture NDJSON trong `tests/fixtures/replay/`, mỗi dòng là `{ atMs, event }`.
   - Runner chạy theo tick 50 ms với đồng hồ giả.
   - Bất biến kiểm ở mọi tick (I2 bản đầu bị bỏ vì tautology, thay bằng bản dưới; thêm I7 sau review):
     - I1: bước không lùi.
     - I2: hạng của thẻ, của stage trong `view` và của bước đang chạy trên thanh bước đều bằng hạng của bước tại đầu phát, và không cái nào đi trước nó.
     - I3: `outcome` chỉ khác null ở bước cuối.
     - I4: chữ hiện ra là tiền tố của chữ thật.
     - I5: field chỉ được đặt sau khi bước viết của nó đã phát.
     - I6: hết fixture và hết thời gian thì `done` bằng true.
     - I7: đầu phát không bao giờ vượt bước cuối đã nối vào kịch bản.
9. **FR-09:** Fixture tối thiểu:
   - Ghi thật: CLIProxyAPI nhanh, Capstone chậm, rewrite V2.
   - Viết tay: lỗi giữa chừng, fallback (`begin` lặp lại), hủy, kết nối lại giữa chừng, mở lại câu đã xong (chỉ có snapshot), dạng bài có media.
10. **FR-10:** Có một cách ghi SSE thật ra NDJSON để làm fixture. Cách ghi do phase lập kế hoạch quyết định.

---

## Yêu cầu phi chức năng

- **Hiệu năng:** `frameOf` và `advance` chạy dưới 1 ms mỗi tick với kịch bản 10.000 ký tự. Không render lại toàn trang mỗi frame.
- **Chuẩn code:** theo `pte-web/docs/CODING_STANDARDS_WEB.md`. File ≤ 300 dòng, component ≤ 150 dòng, chữ hiển thị đặt trong constants vi/en, dùng `@pte/ui` như có sẵn, test đặt trong `tests/unit`.
- **Không đổi backend và API.**

---

## Tiêu chí thành công

- [ ] Toàn bộ 9 fixture qua 6 bất biến ở mọi tick.
- [ ] Không còn chỗ nào trong `questiongeneration` hay `batchgeneration` đọc `record.stage`, `job.status` hay live stage để quyết định bước hoặc thẻ của câu đang phát. Kiểm tra bằng grep trong plan.
- [ ] Đã xóa `gateLive`, `endedWhenOpened`, `replayingId` và các mẹo `typing`/`stillTyping`.
- [ ] `tsc`, `eslint` và `vitest` (questiongeneration, batchgeneration) đều qua.
- [ ] Chạy thử với CLIProxyAPI và với Capstone: các thẻ không vượt trước bước đang phát (user tự xác nhận).

---

## Ngoài phạm vi

- Thay đổi backend hoặc định dạng SSE.
- Phát lại chữ V1 khi đã rewrite (P3).
- Thiết kế lại giao diện. Giữ nguyên bố cục và nhịp mà user đã duyệt.

---

## Giả định

- Thứ tự `checks` trong snapshot là thứ tự các bước bắt đầu (comment của kiểu `QuestionGenerationLiveItem` nói vậy).
- Server luôn gửi `snapshot` trước rồi mới gửi sự kiện lẻ khi kết nối.
- Số field và thứ tự field trên preview lấy được thuần từ bản nháp (`draft`) và dạng bài, như `pieces` hiện nay.

---

## Đã chốt (2026-11-26)

- Số "x / y câu đã lưu" của lô giữ theo server (kết quả thật của cả lô). Chỉ thẻ của câu đang mở đi theo phần phát lại.
