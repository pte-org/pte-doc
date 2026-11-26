# Phase 02 — Đầu phát: `advance` và `frameOf`

**Trạng thái:** [x] [quality: skipped_by_user; decision: user_confirmed_skip] · **Phụ thuộc:** phase 01
**Stories:** P1 thẻ khớp bước, P1 không lùi, P1 kết quả chỉ ở bước cuối, P2 các tùy chọn cũ; FR-03, FR-04; yêu cầu hiệu năng

## Vấn đề

Nhịp phát nay nằm rải ở `useTypedText` (`hooks/useTypedText.ts:13-41`), `useStepGate` (`hooks/useStepGate.ts:21-40`), `useDropQueue` (`hooks/useDropQueue.ts:20-50`) và `_LiveItemPanel.tsx:51-78`. Mỗi chỗ có đồng hồ riêng. Cần một hàm tiến đầu phát và một hàm dựng khung hình, cả hai thuần.

## Thay đổi

File mới trong `apps/vendor-web/features/questiongeneration/replay/`:

1. `frameTypes.ts` — `Playhead` (chỉ số bước, **số ký tự tích lũy**, số field đã đặt, giai đoạn field và thời gian trong giai đoạn), `ReplaySettings` (`charsPerSecond`, `pauseEachStep`, `released`, `revealAll`, `skip`), `Frame`, `FrameContext` (`needsAudio`, `needsImage`, field theo dạng bài).
2. `advance.ts` — `advance(playhead, script, elapsedMs, settings)`:
   - gõ chữ của bước viết và review theo `charsPerSecond`, dùng `revealedChars` (`utils/typingStep.ts:4`) nhưng cộng dồn ký tự, nên đổi tốc độ giữa chừng thì chạy tiếp từ chỗ cũ;
   - bước `assemble`: nghỉ `PIECE_GAP_MS`, bay `PIECE_FLY_MS`, đứng yên `PIECE_SETTLE_MS` cho từng field;
   - bước `media`: dạng bài cần ảnh và có `imageRef` thì dừng `CHART_REPLAY_MS`;
   - thinking: hiện sau `THINKING_REVEAL_AFTER_MS` đo bằng thời gian của đầu phát trong bước viết; thời gian đó nằm trong `Playhead`;
   - Dừng sau mỗi bước: đứng ở cuối bước khi `pauseEachStep`; `released` là số bước được phép đi qua. **Ở mép sống** (đã hết script nhưng chưa `ended`), `released` không tăng; khi bước mới được nối thì đầu phát đứng ở cuối bước vừa xong cho đến khi người dùng bấm Tiếp tục;
   - Hiện hết: chữ của bước hiện tại về cuối, không nhảy bước;
   - `skip`: chỉ áp dụng **một lần lúc mount** khi script đầu tiên dựng ra đã `ended`; sau đó một `end` đến muộn không bao giờ làm đầu phát nhảy (hook quyết định lúc mount, `advance` chỉ nhận cờ);
   - `elapsedMs = 0` không đổi gì; `elapsedMs` rất lớn (5000) vẫn không bỏ bước và không vượt cuối script;
   - hết script mà chưa `ended`: chờ ở mép sống, không lùi.
3. Dựng khung hình, tách theo trách nhiệm ngay từ đầu (mỗi file ≤ 300 dòng):
   - `frameOf.ts` — `frameOf(script, playhead, context)` ghép các phần dưới đây.
   - `stepsOf.ts` — 7 bước của thanh bước kèm trạng thái, round, `flagged`; bước round cũ không hiện là done cho bước mới; bước `superseded` hiện như đã qua.
   - `viewOf.ts` — dựng `view` (live item theo đầu phát), chữ đã hiện, thinking đã hiện.
   - `piecesOf.ts` — field đã đặt, đang bay, đang đứng yên. Gọi lại `livePieces` với bản nháp dở dang của bước đang phát; khóa theo `PieceKey`.
   - `chip.ts` — `chipRank(frame)` (queued 0, write 1, validate 2, review 3, media 4, assemble 5, outcome 6) và `chipOf(frame)` (nhãn, tông; tái dùng `STAGE_LABELS` và `ITEM_CHIP_TONES`). Chỉ phụ thuộc bước đầu phát.
4. `partialMemo.ts` — memo parse JSON dở dang theo (khóa bước, nhóm ký tự, ví dụ nhóm 16 ký tự), để `frameOf` không parse lại cả 10.000 ký tự mỗi tick. Xác nhận bằng test rằng kết quả giống không memo.
5. `releaseGate.ts` — `nextReleased(playhead, script)` cho nút Tiếp tục.
6. Test trong `tests/unit/features/questiongeneration/replay/`: `advance.test.ts`, `frameOf.test.ts`, `chip.test.ts`, `perf.test.ts`.

## Design Constraints

- Hàm thuần: thời gian chỉ vào qua `elapsedMs`; không `Date.now`, không `performance.now`.
- Đầu phát không bao giờ giảm và không bao giờ vượt bước cuối đã nối. `advance` không bỏ bước (trừ `skip` lúc mount hoặc `revealAll` do người dùng chọn, `revealAll` cũng không nhảy bước).
- `frame.outcome` là null cho tới khi đầu phát ở bước `outcome`; `view.stage` không vượt bước đầu phát, nên `livePieces` không thấy field "sẵn sàng" sớm.
- Hằng nhịp lấy từ `assemblyConstants.ts` và `typingConstants.ts`; không số mới.
- Không import React, `@/`, hay `useQuestionTypes` (thông tin dạng bài vào qua `FrameContext`).
- Hiệu năng: `frameOf` cộng `advance` đạt p95 dưới 1 ms mỗi tick với script 10.000 ký tự.
- Mỗi file ≤ 300 dòng.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

## Test

- Gõ chữ: sau `t` ms ở 15, 30, 60 ký tự/giây số ký tự khớp `revealedChars`; đổi tốc độ giữa chừng thì tiếp tục từ chỗ cũ (không nhảy).
- **Xác định:** chạy cùng script bằng tick 50 ms và bằng tick 1 s; ở cùng tổng thời gian khung hình giống hệt.
- `elapsedMs = 0` không đổi đầu phát; `elapsedMs = 5000` đi qua nhiều bước nhưng không bỏ bước bắt buộc phát và không vượt cuối script.
- Field: gap rồi fly rồi settle đúng độ dài; hai field liền nhau cách đúng gap; field không "ready" trước khi view đủ điều kiện (L1).
- Dừng sau mỗi bước: đứng ở cuối bước tới khi `released` tăng; ở mép sống, bước mới nối thêm cũng chờ bấm.
- Hiện hết: chữ về cuối bước hiện tại, đầu phát vẫn ở bước đó.
- `skip` lúc mount: script đã `ended` thì tới cuối; một `end` đến sau khi đang phát không làm đầu phát nhảy.
- Mép sống: script dài thêm sau khi đầu phát chờ thì đi tiếp, không lùi.
- Thinking: chỉ hiện sau `THINKING_REVEAL_AFTER_MS` thời gian đầu phát trong bước viết.
- `frameOf`: round 2 đúng; `outcome` null trước bước cuối; `chipOf` chỉ phụ thuộc bước đầu phát (đổi `pendingOutcome` không đổi chip).
- Hiệu năng: script 10.000 ký tự, đo `advance` rồi `frameOf` nhiều lần (ví dụ 2.000), lấy p95 dưới 1 ms. Nếu máy CI quá chậm, ngưỡng đặt trong một hằng số trong test và ghi lý do, không tắt test.

## Hoàn thành khi

- [x] Các test trên qua.
- [x] Chưa có code giao diện nào gọi `advance` hay `frameOf`.
- [x] tsc, eslint, vitest đều qua; file ≤ 300 dòng.

## Ghi chú khi làm

- Đọc `utils/livePieces.ts` đầy đủ (đã biết dòng 134 và 221-241 phụ thuộc `live.stage`). Giữ hành vi đã duyệt: field đặt từ JSON dở theo thứ tự khóa trong lúc bước viết.
- Đọc `_ThinkingPad.tsx` để biết nó cần gì từ `view` khi bỏ đồng hồ riêng (phase 4b).
- Đã làm (2026-11-26): `replay/{frameTypes,advance,viewOf,piecesOf,stepsOf,chip,frameOf,partialMemo,releaseGate}.ts`; test `advance`, `frameOf`, `perf` (28 test, cùng 37 test phase 1 là 65). tsc, eslint sạch.
- Thêm hằng `STEP_DWELL_MS = 500` ở `assemblyConstants.ts`: các bước không có chữ để gõ (prompt, kiểm tra, kết luận) hiện ngần ấy thời gian trước khi sang bước sau. Plan ghi "không số mới" nhưng không có hằng nào phù hợp.
- `released` nằm trong `Playhead` (không trong `ReplaySettings`) vì là trạng thái của lần phát. `skip` không là cờ của `advance`: hook gọi `endPlayhead(item, context)` một lần lúc mount (phase 4a).
- Đầu phát đếm ký tự theo phần nghìn (`charMilli`) nên tick 50 ms và tick 1 s cho đúng cùng một kết quả (có test).
- Memo parse JSON dở dang so sánh nguyên chuỗi (không theo nhóm 16 ký tự như plan), nên kết quả không bao giờ cũ. Đo thực tế: p95 dưới 1 ms cho script 10.000 ký tự (có test).
- Trong frame, field chỉ được đặt trong bước `assemble` (sau review và media), không đặt dần khi review qua như cũ. Đây là thay đổi hành vi nhỏ so với bản đã duyệt; field vẫn được **điền** dần từ JSON dở dang trong bước viết.
- Đã mô phỏng đúng lỗi người dùng gặp: kết quả của job là SAVED trong khi màn hình còn đang gõ bước viết thì chip vẫn là "Đang viết đề", `outcome` là null (test `the bug the replay engine exists for`).
