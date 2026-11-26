# Phase 03 — Harness: fixture, runner, bất biến, công cụ ghi

**Trạng thái:** [x] [quality: skipped_by_user; decision: user_confirmed_skip] · **Phụ thuộc:** phase 01, phase 02
**Stories:** P1 harness chạy lại sự kiện thật (≥ 8 fixture, dưới 5 giây); FR-08, FR-09, FR-10

## Vấn đề

Lỗi lệch nhịp chỉ lộ khi user xem. Cần chạy lại dòng sự kiện thật bằng đồng hồ giả và kiểm bất biến ở mọi tick. Bất biến cũ "ba thẻ khớp nhau" là tautology (cùng một hàm tính ra cả ba), nên phải thay.

## Thay đổi

1. **Định dạng fixture.** `apps/vendor-web/tests/fixtures/replay/*.ndjson`, mỗi dòng `{ "atMs": number, "event": QuestionGenerationLiveEvent }`. Metadata (dạng bài, `needsAudio`, `needsImage`, `saveQuestions`, kết quả của job và lúc nó đến, nguồn: `recorded`, `handwritten` hay `todo-record`, mức: `event-complete` hay `snapshot-reduced`) nằm ở `tests/unit/features/questiongeneration/replay/fixtureRegistry.ts`. `snapshot-reduced` nghĩa là fixture chỉ có snapshot nên không đủ lịch sử (L2).
2. **Công cụ ghi (FR-10).** `apps/vendor-web/tests/tools/recordReplayFixture.mjs`, Node thuần, `fetch` có sẵn.
   - Đọc `GET {PTE_API_BASE_URL}/api/v1/question-generation/jobs/{id}/live`. Token bearer từ biến môi trường `PTE_REPLAY_TOKEN`, không nhận qua tham số.
   - Từ chối URL không phải HTTPS, trừ `localhost` và `127.0.0.1`.
   - Khi lỗi chỉ in mã trạng thái và đường dẫn (không in header, URL đầy đủ, body).
   - Thay `audioRef`, `imageRef`, `jobId` và mọi UUID bằng chỗ giữ cố định (`media-1`, `job-1`, ...).
   - Trước khi ghi file: thất bại nếu nội dung có `Bearer` hoặc dạng JWT (`eyJ...`).
   - Cắt gọn: bỏ gần hết `thinking` (giữ vài dòng cho tail), cắt `facts` và `details` dài. Không cắt `token`.
   - Script phải qua eslint như mọi file; không thêm `eslint-ignore`. Nếu cấu hình hiện tại không phủ `.mjs`, thêm nó vào phạm vi lint (không tắt rule).
3. **Runner.** `tests/unit/features/questiongeneration/replay/runReplay.ts`: đọc NDJSON bằng `node:fs` (đường dẫn từ `import.meta.url`); tick 50 ms với đồng hồ giả. Mỗi tick: nạp sự kiện đến hạn (`extendScript`), tiêm kết quả job đúng lúc đã đăng ký (qua `settleOutcome`), gọi `advance` rồi `frameOf`, đưa frame cho từng bất biến.
   - Chế độ chạy: tốc độ mặc định (30), tốc độ nhanh (60), `revealAll` bấm ở bước đầu mỗi bước viết, `skip` lúc mount (chỉ cho fixture đã `ended` lúc đầu), và Dừng sau mỗi bước.
   - **Tự nhả khi Dừng sau mỗi bước:** runner tăng `released` ngay khi `heldAtStep` xuất hiện sau 2 tick (mô phỏng người bấm Tiếp tục).
   - **Ngân sách I6:** `T = sumChars / charsPerSecond × 1000 + (số field) × (PIECE_GAP_MS + PIECE_FLY_MS + PIECE_SETTLE_MS) + số bước × 100 + CHART_REPLAY_MS + 2000 ms` (cộng cả round bị superseded). Hết fixture và đã qua `T` mà `done` chưa true thì fail.
4. **Bất biến** `invariants.ts`:
   - I1 chỉ số bước của đầu phát không giảm.
   - I2 (thay bản cũ) `chipRank(frame)`, hạng của `view.stage` và hạng của bước đang chạy trong `frame.steps` đều bằng hạng của bước tại `playhead.stepIndex`, và không cái nào lớn hơn nó.
   - I3 `frame.outcome` null cho tới khi đầu phát ở bước `outcome`.
   - I4 chữ hiện ra là tiền tố của chữ đầy đủ **của bước đó** (theo `StepKey`, không theo chữ của cả câu).
   - I5 field chỉ `placed` hay `flying` sau khi bước viết của nó đã phát hết và `view` đủ điều kiện.
   - I6 hết fixture và hết ngân sách thời gian thì `done` là true.
   - I7 đầu phát không bao giờ vượt bước cuối đã nối vào script.
   - Chỉ I1-I6 là của spec; I7 là bổ sung. Cả I2 bản mới lẫn I7 ghi trong spec ở phase 6.
5. **Test đột biến (tái hiện lỗi của user).** Chạy `capstone-slow` nhưng tiêm kết quả SAVED của job khi bước viết còn đang gõ: chip phải vẫn ở hạng write, `outcome` null. Một test thứ hai phá cố ý từng bất biến bằng frame giả để chắc mỗi cái báo lỗi đúng.
6. **Test xác định.** Mọi fixture chạy với tick 50 ms và tick 1 s cho cùng khung ở cùng tổng thời gian (có thể tái dùng test ở phase 2 với script từ fixture).
7. **Chín cộng ba fixture (FR-09).**
   - Ghi thật: `cliproxy-fast`, `capstone-slow`, `rewrite-v2`. Chưa có lần chạy thật thì viết tay cùng tên, đánh dấu `todo-record` (một `console.warn` trong test, không fail).
   - Viết tay: `fail-midway`, `fallback-begin-repeat`, `cancelled`, `reconnect-midway` (snapshot đến khi đầu phát đang giữa script), `reopen-finished-snapshot-only` (`snapshot-reduced`), `media-chart`.
   - Thêm cho các finding: `reconnect-after-rewrite` (snapshot dựng từ hình dạng `LiveItem` thật sau rewrite, theo bảng phase 1), `outcome-before-events` (job record báo SAVED trước khi feed xong), `ready-form` (`saveQuestions=false`, stage READY là cuối), `stream-drop-no-end` (feed rớt không có `end`, job record báo SAVED về sau).
8. **Đo thời gian.** Ghi lại tổng thời gian chạy bộ fixture trong Ghi chú; nếu gần 5 giây thì thu nhỏ fixture, không nâng ngưỡng.

## Design Constraints

- Test và fixture nằm dưới `tests/`; code production không import chúng.
- Không đưa token, key, URL nội bộ, UUID thật hay email vào fixture, script, test hay plan.
- Runner dùng đồng hồ giả; không `setTimeout`, `requestAnimationFrame`, `Date.now`.
- Fixture giữ nhỏ (khoảng 20 KB mỗi file trở xuống) và có nhãn `event-complete` hay `snapshot-reduced`.
- Bất biến fail là lỗi engine hay fixture; không sửa bất biến để qua mà không giải thích.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

## Test

- Mọi fixture qua I1-I7 ở mọi tick, ở các chế độ: tốc độ 30, tốc độ 60, `revealAll`, `skip` (khi hợp lệ), Dừng sau mỗi bước.
- Test đột biến và test phá bất biến (mục 5) qua.
- Test xác định (mục 6) qua.
- Chạy thử script ghi với chuỗi SSE mẫu: HTTPS-only, thay UUID, từ chối khi có `Bearer` hay `eyJ`.
- Tổng thời gian vitest cho thư mục `replay` dưới 5 giây.

## Hoàn thành khi

- [x] Ít nhất 8 fixture (mục tiêu 13) qua I1-I7.
- [x] Ba fixture ghi thật hoặc stand-in `todo-record` trong registry.
- [x] Không có `Bearer` hay `eyJ` trong fixture (grep rỗng); script qua eslint không có ignore.
- [x] tsc, eslint, vitest đều qua.

## Ghi chú khi làm

- Nếu bất biến fail trên fixture ghi thật, giữ fixture lại (ca lỗi thật), sửa engine ở phase 1 hoặc 2.
- Dùng các lần ghi thật để xác nhận giả định 7 và 8 của plan.md.
- Đã làm (2026-11-26): `tests/fixtures/replay/*.ndjson` (13 file), `tests/tools/recordReplayFixture.mjs`; ở `tests/unit/features/questiongeneration/replay/`: `fixtureRegistry.ts`, `invariants.ts`, `runReplay.ts`, `harness.test.ts`, `playHelpers.ts`. Toàn bộ thư mục `replay`: 144 test, 1,5 giây. tsc, eslint sạch (kể cả `.mjs`, không cần ignore).
- **Ghi thật xong 2 fixture** (2026-11-26, user cho phép): `cliproxy-fast` (job thật qua CLIProxyAPI `gpt-6-luna`, token đầu tiên sau 6 giây rồi stream đều, tổng 16 giây) và `capstone-slow` (CLIProxyAPI tắt tạm nên job rơi sang Capstone: token đầu tiên sau 10 giây, tổng 32 giây). Cả hai là câu hỏi từ form (`saveQuestions=false`) nên READY là kết thúc, không để lại bản nháp. Cả hai qua I1–I7 ở mọi chế độ ngay lần đầu. Cấu hình CLIProxyAPI đã khôi phục sau khi ghi.
- `rewrite-v2` vẫn là `todo-record` (stand-in viết tay): không ép được reviewer từ chối. Test in cảnh báo mỗi lần chạy.
- Script ghi gộp các `token` đến trong cùng 50 ms thành một sự kiện để fixture nhỏ (7,8 KB và 8,8 KB), vì phát lại gõ theo thời gian. Plan ghi "không cắt token"; gộp không đổi thứ tự hay nội dung.
- Giả định 8 của plan.md: endpoint `/live` chỉ cần bearer token của người dùng có quyền (admin local).
- Giả định xác nhận từ lần ghi thật: `snapshot` đến đầu tiên (atMs 1), rồi `stage`, `check`, `begin`, `token`; `end` ở cuối. Chưa thấy `begin` lặp hay `PROMPT` thứ hai (cần job có rewrite để kiểm giả định 7).
- Test phá bất biến: mỗi bất biến I1–I7 có một test dựng frame sai và chắc chắn báo lỗi.
