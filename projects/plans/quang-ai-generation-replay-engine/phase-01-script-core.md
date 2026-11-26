# Phase 01 — Lõi kịch bản: kiểu, `buildScript`, hợp nhất snapshot

**Trạng thái:** [x] [quality: skipped_by_user; decision: user_confirmed_skip] · **Phụ thuộc:** không
**Stories:** P1 "bước đi lần lượt, không bỏ bước" (nền), P1 harness (nền), FR-01, FR-02

## Vấn đề

`useLiveJob` gộp sự kiện thành `LiveItems` ngay khi đến (`hooks/useLiveJob.ts:68-72`, `utils/liveItems.ts:55-122`). Thứ tự bước mất, nên mỗi component phải đoán lại. Cần một kịch bản có thứ tự, chỉ nối thêm.

Snapshot còn khó hơn: `draft` và `review` không bao giờ bị xóa và không mang round (`LiveItem.java:66-72`). `check` PROMPT chỉ xóa `checks` và media (dòng 74-82). `generator.attempt` và `reviewer.attempt` có thể khác nhau. Phải có bảng quy tắc rõ để suy bước từ một snapshot.

## Thay đổi

Tất cả file mới, thuần TS, không import React, không dùng alias `@/`. Mỗi file ≤ 300 dòng.

1. `apps/vendor-web/features/questiongeneration/replay/scriptTypes.ts`
   - `ScriptStep`: `prompt`, `write` (round, attempt, text, thinking tail, thinkingChars, draft, `superseded`), `check` (JSON/RULES/DUPLICATE, status), `review` (round, text, verdict), `media` (audioRef, imageRef, "kiểm tra ảnh", `superseded`), `assemble` (danh sách `PieceKey`), `previousRounds` (bước gộp, không có chữ), `outcome` (SAVED, READY, FAILED, CANCELLED).
   - `StepKey` (loại, round, attempt), `ItemScript` (steps, `ended`, `pendingOutcome`), `Script` (theo index câu).
   - Chuyển `StepId`, `LiveStep` từ `utils/liveSteps.ts:5-14` sang kiểu dùng chung (file cũ re-export tạm đến phase 6).
2. `.../replay/buildScript.ts`
   - `buildScript(snapshot | null, events[])`: hàm thuần, gấp `extendScript(script, event)`.
   - `extendScript` là bước tăng dần cho hook. Token và thinking liền nhau của cùng câu và cùng agent nối vào cùng bước viết hoặc review.
   - Check `PROMPT` mới mở round mới. `begin` GENERATOR lặp lại trong cùng round tạo bước viết mới `(round, attempt+1)`; bước viết trước thành `superseded`.
   - Media của round cũ thành `superseded` khi round mới bắt đầu. Stage REVIEWING sau RENDERING_MEDIA là kiểm tra ảnh, thuộc bước media.
   - Có bước `outcome` thì `ended = true` và mọi sự kiện sau đó bị bỏ (ghi log ở dev bằng hàm tiêm vào, không `console` trực tiếp).
3. `.../replay/outcome.ts`
   - Ánh xạ stage sang `outcome`. Quy tắc: `FAILED`, `CANCELLED`, `SAVED` chỉ đến từ job record; `READY` từ feed là cuối **chỉ khi** job `saveQuestions=false` (tham số truyền vào, không đọc global).
   - `settleOutcome(script, index, jobOutcome, reason)`: chỉ nối `outcome` khi `reason` là `end`, `closed-terminal` hay `feed-ready`; ngoài ra giữ ở `pendingOutcome`.
4. `.../replay/mergeSnapshot.ts`
   - **Bảng quy tắc snapshot sang bước** theo `(stage, activeAgent, generator.attempt = G, reviewer.attempt = R, checks)`. Viết thành bảng trong đầu file và test từng dòng:

     | Tình huống | Suy ra |
     |---|---|
     | `G` null | câu chưa bắt đầu: không có bước |
     | `G = 1`, `checks` có PROMPT | round 1; prompt, write, các check theo thứ tự |
     | `G = 1`, `R = 1`, `review` có | thêm review round 1 (chữ `reviewer.text`, verdict `review`) |
     | `G > R` hoặc `G > 1`, và `checks` không có gì sau PROMPT/WRITE | `draft`, `review` thuộc round `G-1`; round `G` mới tới prompt hay write |
     | `G > 1`, `checks` có JSON trở đi | `draft` thuộc round `G`; `review` (nếu `R = G`) thuộc round `G` |
     | các round `1..G-1` không có dữ liệu riêng | gộp thành một bước `previousRounds` (đếm số vòng, không phát lại chữ) |
     | `imageRef` hoặc `audioRef` có | bước media của round hiện tại |
     | `stage = READY` và job `saveQuestions=false` | outcome READY |

   - **Quy tắc hợp nhất vào kịch bản đang có** (không cần đầu phát, hàm thuần): bước snapshot có mã trùng thì chỉ được cập nhật chữ nếu chữ mới bắt đầu bằng chữ cũ (dài hơn thì thay, ngắn hơn hay khác thì bỏ). Bước không có bản đối ứng được **nối ở cuối**, không chèn. Bước trùng mã nhưng sẽ rơi trước vị trí hiện có thì bỏ. Không bao giờ xóa hay đổi chỗ.
5. `.../replay/index.ts` — barrel.
6. `apps/vendor-web/tests/unit/features/questiongeneration/replay/buildScript.test.ts`, `mergeSnapshot.test.ts`, `outcome.test.ts`.

## Design Constraints

- Hàm thuần: không đồng hồ, không `localStorage`, không React, không `@/`.
- Chỉ nối thêm. Không xóa, đổi chỗ hay rút ngắn bước và chữ đã có.
- Script không bao giờ reset khi kết nối lại; chỉ hook reset khi `jobId` đổi (phase 4a).
- Không dùng `record.stage` hay trạng thái job làm nguồn bước; outcome chỉ vào qua `settleOutcome`.
- Có bước `outcome` thì script đóng, không nhận thêm bước.
- Chưa file nào ngoài `replay/` import module này (app chạy như cũ).

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

## Test

- Chuỗi sự kiện đủ một câu cho đúng thứ tự bước; media chỉ sau review.
- Review rớt rồi rewrite: round 2, round 1 còn nguyên, media round 1 `superseded`.
- `begin` lặp lại trong cùng round: bước viết mới, bước cũ `superseded`.
- Mỗi dòng của bảng quy tắc snapshot có một test, gồm snapshot dựng từ hình dạng `LiveItem` thật (`generator`, `reviewer`, `draft`, `review`, `checks`, `audioRef`, `imageRef`) sau rewrite.
- Hợp nhất: chữ dài thêm thì cập nhật; chữ ngắn hơn hay khác tiền tố thì bỏ; bước thiếu nối cuối; bước rơi trước thì bỏ.
- `outcome` đến sớm (trước `end`) chỉ nằm ở `pendingOutcome`; sau `end` mới nối; sau khi có `outcome` sự kiện thêm bị bỏ.
- READY: là cuối khi `saveQuestions=false`, không phải cuối khi `true`.
- `buildScript(null, [])` trả kịch bản rỗng.

## Hoàn thành khi

- [x] Các test trên qua; UI hiện tại không bị đụng.
- [x] tsc, eslint, vitest đều qua.
- [x] Mỗi file ≤ 300 dòng, không `any`.

## Ghi chú khi làm

- Nếu chạy thật cho thấy generator không phát lại `PROMPT` khi gọi lại model (giả định 7 trong plan.md), sửa quy tắc round trong `extendScript`, không đổi bảng snapshot.
- Ghi lại mọi chỗ snapshot làm rơi dữ liệu (chữ V1) để phase 3 có fixture đúng.
- Đã làm (2026-11-26): `replay/{scriptTypes,steps,outcome,buildScript,mergeSnapshot,index}.ts`; test ở `tests/unit/features/questiongeneration/replay/` (37 test, gồm `helpers.ts`). tsc, eslint sạch.
- Tách thêm `steps.ts` (khóa bước, thứ hạng, hàm dựng) ngoài kế hoạch, để `buildScript.ts` ≤ 300 dòng.
- Snapshot cũ hơn script: nếu số lần gọi writer (`generator.attempt`) nhỏ hơn số bước viết script đã thấy thì bỏ qua cả snapshot cho câu đó. Nếu bằng nhau thì dùng round của script (tránh đọc nhầm round khi writer retry hoặc đổi sang model dự phòng). Chỉ khi lớn hơn mới dùng bảng quy tắc.
- Bước `assemble` chỉ được thêm khi kết quả SAVED hoặc READY được chốt (trong `outcome.ts`), chưa thêm theo sự kiện nào của feed.
- Hạn chế đã biết: `generator.attempt` đếm cả retry, nên mở một câu giữa chừng bằng snapshot có thể coi một retry là round mới (bước `previousRounds` thừa). Chỉ ảnh hưởng ca mở lại giữa lúc đang retry.
