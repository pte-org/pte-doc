# Sinh đề AI: bộ máy phát lại duy nhất

**Trạng thái:** Hoàn tất (2026-11-26), còn xác nhận với Capstone · **Tác giả:** quang · **Ngày:** 2026-11-26
**Nguồn:** [spec.md](spec.md) (kèm [brainstorm.md](brainstorm.md))
**Phạm vi:** chỉ `pte-web/apps/vendor-web` (`features/questiongeneration`, `features/batchgeneration`). Không đổi backend, API hay định dạng SSE.
**Chuẩn bắt buộc:** `pte-web/docs/CODING_STANDARDS_WEB.md`, `pte-web/AGENTS.md`

## Mục tiêu

- Chỉ còn một nguồn sự thật cho màn phát lại: khung hình (`frame`) tính từ kịch bản và đầu phát.
- Thanh bước, thẻ trong panel, thẻ ở danh sách job, chữ và field luôn cùng một bước.
- Có harness chạy lại sự kiện thật với đồng hồ giả, kiểm 6 bất biến ở mọi tick.
- Giữ nguyên cách dùng đã duyệt: tốc độ gõ, Hiện hết, Dừng sau mỗi bước, Bỏ qua phát lại, giữ câu và Next.

## Hiện trạng (đã đọc code)

- `hooks/useLiveJob.ts:28-31, 68-72, 87`: mọi sự kiện SSE được gộp ngay vào `LiveItems` qua `applyLiveEvent`. Thứ tự bước mất ở đây. Dòng 87 reset state mỗi lần effect chạy lại (đổi `jobId` hoặc `mode`).
- `utils/liveItems.ts:55-122`: `applyLiveEvent`. Snapshot thay toàn bộ (dòng 58). `check` PROMPT xóa checks cũ (dòng 103). `followedIndex` (dòng 125) chọn câu mở mặc định.
- `utils/stepGate.ts:5-63`: `GATE_STEPS`, `gateLive` cắt live item theo `rank` rồi giả stage. `hooks/useStepGate.ts:21-40`: rank theo stage của server.
- `utils/liveSteps.ts:37-118`: suy bước từ live feed, có mẹo `typing` (dòng 53) và `rewriting` (dòng 40).
- `components/_LiveItemPanel.tsx:51-78`: `useTypedText` hai lần, `stillTyping`, `busy`, `behind`, `outcome`, `dropsIdle`, `replayDone`. Nguồn lệch chính.
- `components/_LiveAssembly.tsx:94-156`: `useReplay` (chart, dòng 94), `useDropQueue` (dòng 119), `liveSteps` (dòng 149), `progress` đọc `live.stage` (dòng 127).
- `hooks/useDropQueue.ts:20-50`: hàng đợi field bằng ba `setTimeout` (gap, fly, settle). Luật thời gian nằm ở đây.
- `hooks/useReplay.ts:7`: đã có hook tên `useReplay(trigger, enabled, durationMs)` cho chart. **Trùng tên** với hook mới `useReplay(jobId, index)`.
- `components/LiveJobPanel.tsx:34-36, 71`: `endedWhenOpened` quyết định `instant`. `_LiveJobItemList.tsx:38-43`: `stageOf` đọc `record.stage` và `items[i].stage`.
- Batch: `hooks/useBatchFocus.ts:28, 37-43, 53` giữ `replayDone`; `_BatchDetailContent.tsx:81` truyền `replayingId`; `_BatchJobPicker.tsx:68` đổi chip thành RUNNING theo `replayingId`.
- Backend (chỉ tham chiếu, đã đọc lại 2026-11-26):
  - `LiveJob.attach` (dòng 94-106) gửi `snapshot` trước, rồi sự kiện lẻ; job đã xong thì gửi `end` rồi đóng.
  - `LiveItem.java`: `begin` ghi đè text của agent (dòng 36-42); `draft` và `review` chỉ giữ cái cuối, không xóa, không mang round (dòng 66-72); `check` PROMPT xóa `checks`, `audioRef`, `imageRef` (dòng 74-82); snapshot gồm attempt của từng agent (dòng 98).
  - `GenerationPipeline.java:112-204`: mỗi vòng chạy tuần tự draft, kiểm tra trùng, review, media, kiểm tra ảnh. Lỗi nhà cung cấp hay `begin` lặp lại trong cùng một vòng (dòng 128-132) là lần viết lại. `liveFeed.draft(..., round, ...)` (dòng 134) truyền số vòng làm `draft.attempt`. Chỉ `READY` được phát làm stage cuối (dòng 209-212, khi `saveQuestions=false`).

## Quyết định thiết kế

1. **Kịch bản chỉ nối thêm, theo thứ tự chạy của pipeline.** Pipeline luôn chạy tuần tự, nên media không đến trước review và **không có túi tạm**. Media bị từ chối khi rewrite thì bước media của vòng đó bị đánh dấu `superseded` bởi vòng N+1. Kiểm tra ảnh (stage đổi RENDERING_MEDIA sang REVIEWING qua `images.issues`, dòng 190-191) là một phần của bước `media` ("kiểm tra ảnh"). `assemble` dùng media cuối chưa bị superseded.
2. **Mã bước (`StepKey`)** gồm loại bước, round và, với bước viết, số lần viết (`attempt`). Round là số của check `PROMPT`. `begin` lặp lại trong cùng một round (model dự phòng) là bước viết mới `(write, round, attempt+1)`; lần viết trước hiện là `superseded`. Hợp nhất snapshot đối chiếu theo mã này. Chỉ nối thêm, không chèn, không đổi chỗ.
3. **Đầu phát** lưu số ký tự đã gõ tích lũy (không lưu thời gian đã trôi), chỉ số bước, số field đã đặt, giai đoạn field (gap, fly, settle) và thời gian trong giai đoạn đó. Đổi tốc độ gõ thì chạy tiếp từ chỗ cũ.
4. **Bước `assemble`** nằm trong kịch bản, danh sách field lấy từ bản nháp cuối và dạng bài (như `livePieces`). Nhịp field dùng lại `PIECE_GAP_MS`, `PIECE_FLY_MS`, `PIECE_SETTLE_MS`.
5. **Chart replay** thành thời gian dừng của bước `media` khi dạng bài cần ảnh (`CHART_REPLAY_MS`). Hook `useReplay` cũ bị thay.
6. **Kết quả (`outcome`).** Feed không phát SAVED, FAILED, CANCELLED; chúng chỉ đến từ `record.stage` của job. Hook giữ kết quả theo từng câu như "kết thúc chờ" và chỉ nối bước `outcome` khi: (a) đã nhận `end` của kết nối; hoặc (b) kết nối đã đóng và job ở trạng thái cuối nên không còn sự kiện nào; hoặc (c) câu đã có stage cuối của feed (READY, xem dưới). Có bước `outcome` thì script `ended` và không nhận thêm bước; sự kiện đến sau bị bỏ và ghi log ở môi trường dev. `READY` là cuối **chỉ khi** job có `saveQuestions=false`; với job lưu vào ngân hàng thì `READY` không phải là cuối.
7. **Frame** có sẵn `view` (kiểu `QuestionGenerationLiveItem`) dựng theo đầu phát để `livePieces`, `_LiveAssemblyForm`, `_LiveStepDetail`, `_LiveExamPreview` đọc mà không viết lại. `view.stage` suy ra từ bước đầu phát, không từ server, nên field không sẵn sàng sớm hơn bước viết. Field vẫn đặt từ JSON dở dang theo thứ tự khóa trong lúc bước viết (hành vi đã duyệt), khóa theo `PieceKey`, không theo chỉ số.
8. **Thẻ (chip) và hạng.** `chipRank` theo bước đầu phát: queued 0, write (gồm prompt) 1, validate 2, review 3, media 4, assemble 5, outcome 6. `chipOf(frame)` chỉ phụ thuộc bước đầu phát, không bao giờ vào kết quả của job. Panel và danh sách job dùng cùng hàm.
9. **Suy nghĩ (thinking).** `THINKING_REVEAL_AFTER_MS` đo bằng thời gian của đầu phát trong bước viết; `_ThinkingPad` không có đồng hồ riêng. Snapshot chỉ có đoạn đuôi (`THINKING_TAIL_CHARS`) và tổng số ký tự, nên ca mở lại chỉ hiện đoạn đuôi.
10. **Không reset script khi kết nối lại.** Script chỉ reset khi `jobId` đổi. Snapshot mới chỉ hợp nhất; đầu phát không tham gia hợp nhất.
11. **Câu không mở** trong danh sách job vẫn dùng stage của server. Chỉ câu đang mở đi theo khung hình. Đầu phát của mỗi `(jobId, index)` lưu trong một store nhỏ ở mức trang để quay lại câu đã xem dở thì **tiếp tục**, không phát lại từ đầu.
12. **Tên file.** Engine nằm trong `features/questiongeneration/replay/` (thuần TS, không import React). Kiểu tách thành `scriptTypes.ts` và `frameTypes.ts`. Hook ở `hooks/useReplay.ts`.

## Các phase

| # | Phase | Trạng thái | File |
|---|---|---|---|
| 1 | Lõi kịch bản: kiểu, `buildScript`, hợp nhất snapshot | [x] | [phase-01-script-core.md](phase-01-script-core.md) |
| 2 | Đầu phát: `advance` và `frameOf` | [x] | [phase-02-playhead-frame.md](phase-02-playhead-frame.md) |
| 3 | Harness: fixture, runner, bất biến, công cụ ghi | [x] | [phase-03-harness.md](phase-03-harness.md) |
| 4 | Nối giao diện `questiongeneration` (4a hook và công tắc, 4b panel và thẻ, 4c lắp ráp field) | [x] | [phase-04-wire-questiongeneration.md](phase-04-wire-questiongeneration.md) |
| 5 | Trang lô đọc `frame.done` | [x] | [phase-05-batch-page.md](phase-05-batch-page.md) |
| 6 | Xóa đường cũ, ratchet kiến trúc, kiểm toàn bộ | [x] | [phase-06-remove-old-paths.md](phase-06-remove-old-paths.md) |

Thứ tự: 1, 2, 3, 4a, 4b, 4c, 5, 6. Phase 1-3 chỉ thêm code mới, chưa ai gọi, nên app chạy y như cũ. Phase 4a thêm hook mới và một công tắc dev (`NEXT_PUBLIC_GENERATION_REPLAY_ENGINE`, mặc định tắt) chọn đường cũ hay mới. Mỗi bước 4a, 4b, 4c để app chạy được. Phase 5 đổi trang lô. Phase 6 gỡ công tắc và đường cũ.

## Kiểm tra chung (mỗi phase)

Chạy từ `pte-web/apps/vendor-web`:

```bash
pnpm exec tsc --noEmit
pnpm exec eslint features/questiongeneration features/batchgeneration tests/unit/features
pnpm exec vitest run tests/unit/features/questiongeneration tests/unit/features/batchgeneration
```

- Không mở trình duyệt; user tự kiểm tra giao diện.
- vitest chạy môi trường `node`, không có `@testing-library/react` hay `renderHook`. Engine phải là module TS thuần. Hook chỉ là lớp mỏng.
- Test đặt trong `tests/unit/features/...`, import bằng đường dẫn tương đối; alias `@/` không chạy trong vitest. Engine không import file có alias `@/`.
- Mỗi file ≤ 300 dòng, mỗi component ≤ 150 dòng, component là `const` arrow có kiểu trả về.
- Chữ hiển thị đặt trong constants (vi/en). Dùng `@pte/ui` như được cung cấp.
- Không commit token hay key vào fixture, script hay plan.

## Rủi ro

- **Cao: đổi lớn ở màn đang dùng.** Mitigation: phase 1-3 chỉ thêm; phase 4 chia 4a/4b/4c với công tắc; hằng số nhịp (`TYPING_SPEEDS`, `PIECE_*`, `THINKING_REVEAL_AFTER_MS`, `CHART_REPLAY_MS`) không đổi; user tự kiểm tra sau mỗi bước 4.
- **Cao: snapshot sau rewrite mơ hồ.** `draft` và `review` không bị xóa và không mang round; `generator.attempt` khác `reviewer.attempt`. Mitigation: bảng quy tắc ở phase 1, bước "các vòng trước" gộp, fixture `reconnect-after-rewrite`.
- **Cao: kết quả của job đến trước phần phát lại.** Đây chính là lỗi "Đã lưu khi còn đang gõ". Mitigation: kết thúc chờ (quyết định 6), I2/I3 mới và test đột biến.
- **Cao: lệch nhịp so với bản đã duyệt.** Mitigation: test `advance` đối chiếu `revealedChars` (`utils/typingStep.ts:4`) và hằng nhịp field; test xác định (tick 50 ms và 1 s cho cùng khung).
- **Trung bình: kết nối lại giữa chừng.** Mitigation: script không reset, hợp nhất theo `StepKey`, chỉ nối thêm; fixture `reconnect-midway` (snapshot đến khi đầu phát ở giữa script).
- **Trung bình: kết nối rớt không có `end`.** Mitigation: kết quả của job (poll) là nguồn cuối (quyết định 6b); có test ở phase 5.
- **Trung bình: hiệu năng với chữ 10.000 ký tự.** Mitigation: gộp token ngay khi nối; memo parse JSON dở theo (stepKey, nhóm ký tự); ngân sách p95 dưới 1 ms đo trong vitest (phase 2).
- **Thấp: fixture chứa nội dung đề do AI sinh.** Mitigation: giữ nhỏ, cắt `thinking`, thay mã nhận diện bằng chỗ giữ; script ghi từ chối ghi token.
- **Thấp: tên `useReplay` trùng.** Mitigation: đổi tên hook chart cũ trước (phase 4a), rồi mới tạo hook mới; tsc báo nếu sót.

## Giả định chưa xác minh

1. **Đã xác minh (2026-11-26):** `LiveItem.checks` là `LinkedHashMap` theo thứ tự bắt đầu. Map bị xóa khi có check `PROMPT` mới (vòng mới), cùng `audioRef` và `imageRef`. Snapshot chỉ chứa check của vòng hiện tại; vòng trước chỉ còn biết qua `generator.attempt` và `reviewer.attempt`.
2. **Đã xác minh (2026-11-26), giả định cũ sai:** feed chỉ phát `stage` cho các bước `GenerationPipeline.advance` (GENERATING, VALIDATING, REVIEWING, RENDERING_MEDIA) và READY (`GenerationPipeline.java:211`). `fail()` và lưu SAVED không phát `stage`. SAVED, FAILED, CANCELLED **chỉ** đến từ `record.stage` của job.
3. Số field và thứ tự field lấy thuần từ bản nháp và dạng bài như `livePieces` đang làm (phase 2 đọc hết `utils/livePieces.ts`, mới đọc 80 dòng đầu và các dòng 134, 221-241 qua grep).
4. `_ThinkingPad.tsx`, `_LiveAssemblyForm.tsx`, `_LiveStepDetail.tsx`, `_StepGateBar.tsx`, `_ReplayControls.tsx`, `liveCheckCopy.ts`, `utils/reviewSummary.ts`, `hooks/useTypingSpeed.ts`, `_BatchSidebar.tsx` chưa đọc kỹ; phase 4 phải đọc trước khi sửa. `_ThinkingPad` hiện giả định tự giữ độ trễ; quyết định 9 chuyển độ trễ sang đầu phát nên phải sửa nó.
5. `_LiveAssembly` hiện gần 150 dòng; phase 4c có kế hoạch tách (xem phase 4).
6. Server giữ snapshot cuối của job đã xong khoảng 10 phút (ghi chú ở `LiveJobPanel`), nên mở lại câu cũ vẫn có snapshot. Hết hạn thì `JobOutcomeList` thay thế.
7. **Đã xác minh (2026-11-26):** mỗi lần `generator.generate` chạy đều phát check `PROMPT` trước (`LlmItemGenerator.java:71` → `DraftChecks.prompt`). Mỗi vòng `for` của pipeline, kể cả `continue` sau lỗi provider tạm thời hay JSON hỏng (`GenerationPipeline.java:121-132`), vì vậy bắt đầu bằng một `PROMPT` mới. Một `begin` lặp lại **không có** `PROMPT` mới chỉ xảy ra bên trong một lần gọi: gateway tự thử lại (`NineRouterLlmGateway`, `MAX_ATTEMPTS`), `FallbackLlmGateway` chuyển sang Capstone, hoặc generator xin viết lại JSON (`LlmItemGenerator.java:116`). Luật của engine giữ nguyên: round đếm theo `PROMPT`; `begin` lặp trong round là attempt mới.
8. Số round của pipeline (`draft.attempt`) và số check `PROMPT` trùng nhau, vì mỗi vòng `for` đều gọi `generate` và phát `PROMPT` (xem mục 7). Engine vẫn đếm check `PROMPT` và chỉ dùng `draft.attempt` để đối chiếu trong snapshot.
9. Endpoint `/live` có thể cần quyền ngoài bearer token; script ghi chưa chạy với server thật.

## Quyết định của user (2026-11-26)

- Được chạy 3 job thật ở local để ghi fixture: CLIProxyAPI nhanh, Capstone chậm, rewrite V2. Câu sinh ra là bản nháp và sẽ xóa sau khi ghi. Ref Cloudinary và UUID thay bằng giá trị giả.
- Công tắc `NEXT_PUBLIC_GENERATION_REPLAY_ENGINE` bật ở local trong suốt phase 4a–4c; prod tắt tới phase 6.
- Khi cook: mỗi phase có chạy test (vitest), không chạy quality gate.

## Review phản biện (2026-11-26)

| Mã | Kết luận | Đã áp dụng ở |
|---|---|---|
| H1 Snapshot sau rewrite mơ hồ | ACCEPTED | phase 1 (bảng quy tắc, bước "các vòng trước"), phase 3 (fixture `reconnect-after-rewrite`) |
| H2 Hợp nhất không cần đầu phát | ACCEPTED | plan quyết định 10; phase 1 (quy tắc hợp nhất), phase 3 (fixture snapshot giữa script), phase 4a (reset chỉ khi `jobId` đổi) |
| H3 I2 là tautology | ACCEPTED | phase 2 (`chipRank`), phase 3 (I2, I7 mới và test đột biến) |
| H4 Tiêm kết quả sớm | ACCEPTED | plan quyết định 6; phase 1 (script `ended`), phase 4a (kết thúc chờ), phase 3 (fixture `outcome-before-events`, `ready-form`) |
| M1 Bỏ túi tạm, media superseded | ACCEPTED | plan quyết định 1; phase 1, phase 2 |
| M2 Round theo PROMPT, attempt viết | ACCEPTED | plan quyết định 2; phase 1; I4 theo mã bước ở phase 3 |
| M3 Thinking theo đầu phát | ACCEPTED | plan quyết định 9; phase 2, phase 4b |
| M4 Chia phase 4 | ACCEPTED | phase 4 (4a, 4b, 4c), công tắc dev, gỡ ở phase 6 |
| M5 Chip lô khi script không kết thúc | ACCEPTED | phase 5 (test rớt kết nối rồi job SAVED) |
| M6 Ratchet kiến trúc thay grep | ACCEPTED | phase 6 (test vitest đọc source, allowlist theo file); `useDropQueue` xóa vô điều kiện |
| M7 Harness mở rộng | ACCEPTED | phase 2 (elapsed 0 và 5000, xác định), phase 3 (tốc độ mặc định, revealAll, skip, công thức I6, nhãn fixture) |
| M8 Công cụ ghi an toàn hơn | ACCEPTED | phase 3 mục 2 |
| L1 Field theo JSON dở dang | ACCEPTED | plan quyết định 7; phase 2 |
| L3 Thứ tự sửa để tsc qua, tách file | ACCEPTED | phase 1 (tách kiểu), phase 2 (tách `frameOf`), phase 4 (thứ tự) |
| L4 Memo parse, ngân sách p95 | ACCEPTED | phase 2 |
| L5 Ký tự tích lũy, skip một lần | ACCEPTED | plan quyết định 3; phase 2, phase 4a |
| L6 Đầu phát theo (jobId, index) | ACCEPTED (chọn tiếp tục) | plan quyết định 11; phase 4a, phase 5 |

Không có finding nào bị REJECTED hay chỉ NOTED. Phần chưa thể áp dụng đầy đủ khi lập kế hoạch (cần đọc hoặc chạy thật): cách `livePieces` đặt field theo khóa (phase 2 phải đọc hết file) và ca `begin` lặp lại có phát `PROMPT` hay không (giả định 7).

## Việc thêm sau khi hoàn tất (2026-11-26)

- Nhãn agent đổi thành **P** (người viết), **T** (người review), **E** (media: audio hoặc biểu đồ). Nhãn của P và T kèm tên model đã trả lời, ví dụ "P · gpt-6-luna"; khi CLIProxyAPI hết token và Capstone tiếp quản, `begin` được gửi lại với tên model mới nên nhãn đổi theo.
- Backend: `TokenSink.begin(String model)`, `LiveEvent.Begin` và `AgentText` có thêm `model` (snapshot cũng mang). Frontend: `WriteStep.model`, `ReviewStep.model`, `view.generator.model`, nhãn ở `_ReplayAssembly`. Câu mở lại từ snapshot của server cũ chưa có tên model nên chỉ hiện "P" hoặc "T".
- Ghi thật `rewrite-v2` (job A1, reviewer từ chối vòng 1) thay stand-in; bỏ bộ đếm 1,5 giây riêng của `_ThinkingPad`.
