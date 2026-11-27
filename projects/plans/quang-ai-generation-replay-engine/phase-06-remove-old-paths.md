# Phase 06 — Xóa đường cũ, ratchet kiến trúc, kiểm toàn bộ

**Trạng thái:** [x] [quality: skipped_by_user; decision: user_confirmed_skip] · **Phụ thuộc:** phase 05
**Stories:** FR-07; tiêu chí thành công (không còn nguồn trạng thái cũ, fixture qua, tsc/eslint/vitest qua)

## Vấn đề

Sau phase 4 và 5, đường cũ không còn được gọi nhưng vẫn nằm đó (và công tắc dev còn). Để lại sẽ có người dùng lại và sinh nguồn sự thật thứ hai. Grep một lần không giữ được lâu, nên thay bằng một test ratchet chạy mãi.

## Thay đổi

1. Gỡ công tắc `REPLAY_ENGINE_ENABLED` và biến `NEXT_PUBLIC_GENERATION_REPLAY_ENGINE`; `LiveItemPanel` chỉ còn đường mới.
2. Xóa `utils/stepGate.ts` (`gateLive`, `GATE_STEPS`, `stageRank`, `endedBadly`) và `tests/unit/features/questiongeneration/stepGate.test.ts`.
3. Xóa `hooks/useStepGate.ts`.
4. Xóa `utils/liveSteps.ts` (mẹo `typing`, `rewriting`) và `liveSteps.test.ts`. Kiểu `StepId`, `LiveStep` đã ở `replay/`; bỏ re-export tạm.
5. Xóa `hooks/useTypedText.ts` (giữ `utils/typingStep.ts` vì `advance` dùng).
6. **Xóa `hooks/useDropQueue.ts` vô điều kiện.** `frame` đã cho `placed`, `flying`, `settling`; kiểu `DropQueue` đã chuyển sang `replay/` ở phase 4c. Nếu tsc báo còn nơi dùng thì sửa nơi đó, không giữ file.
7. Xóa `hooks/useChartReplay.ts` (chart nay là bước `media`).
8. Xóa `endedWhenOpened`, `replayingId`, `stillTyping`, `behind` và biến `outcome` cục bộ còn sót ở `LiveJobPanel.tsx`, `_LiveItemPanel.tsx`, `_BatchDetailContent.tsx`, `_BatchSidebar.tsx`, `_BatchJobPicker.tsx`.
9. Dọn constants không còn dùng (`gateConstants.ts` nếu chỉ phục vụ `gateLive`).
10. **Ratchet kiến trúc** `tests/unit/architecture/replayEngineRatchet.test.ts` (môi trường `node`): đọc mọi file `.ts` và `.tsx` trong `features/questiongeneration` và `features/batchgeneration` (đệ quy mọi thư mục con) bằng `node:fs`, và fail nếu:
    - xuất hiện các định danh `gateLive`, `useStepGate`, `liveSteps`, `endedWhenOpened`, `replayingId`, `stillTyping`, `useDropQueue`, `useTypedText`, `REPLAY_ENGINE_ENABLED`;
    - một file trong `components/` hay `hooks/` dùng `record.stage`, `job.status` hay `items[...].stage` để chọn bước hay thẻ của câu đang phát.
    Allowlist nhỏ **theo tên file**, không theo số dòng, mỗi mục kèm lý do: `_LiveJobItemList.tsx` (chip câu không mở và `followedIndex`), `LiveGenerationView.tsx` (nút Hủy và READY của trang form), `_JobOutcomeList.tsx`, `_ReviewItemList.tsx`, `_ReviewPanelTabs.tsx`, `useLiveJob.ts` (poll), `useReplay.ts` (kết quả của job đi vào kịch bản, đúng chỗ), `_BatchSidebar.tsx` và các file `utils/` của batch (`batchResults.ts`, `jobExpansion.ts`, `jobFilter.ts`). Test cũng fail nếu allowlist chứa file không còn tồn tại.
11. Ghi I2 mới và I7 vào spec (mục Yêu cầu chức năng, FR-08) và đặt Trạng thái `plan.md` và spec là Hoàn tất khi mọi mục qua.

## Design Constraints

- Chỉ xóa code đã chứng minh không còn ai dùng (tsc và ratchet). Không xóa file bị `tests/` hay trang khác import mà chưa chuyển.
- Không giữ lại "đường dự phòng" nào đọc stage của server để quyết định bước hay thẻ của câu đang phát.
- Không đổi backend, API hay hành vi đã duyệt.
- Ratchet không được nới bằng cách thêm mục vào allowlist mà không ghi lý do; allowlist chỉ có thể co lại.
- Mỗi file ≤ 300 dòng; mỗi component ≤ 150 dòng; không `any`; không tắt lint.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

## Test

Từ `pte-web/apps/vendor-web`:

```bash
pnpm exec tsc --noEmit
pnpm exec eslint features/questiongeneration features/batchgeneration tests/unit/features tests/unit/architecture
pnpm exec vitest run tests/unit/features/questiongeneration tests/unit/features/batchgeneration tests/unit/architecture
```

- Ratchet qua; thử thêm tạm một định danh bị cấm để thấy nó fail rồi gỡ (không commit).
- Chạy cả bộ fixture của phase 3 lần cuối ở mọi chế độ.

## Hoàn thành khi

- [x] Ratchet qua và không có mục allowlist nào thiếu lý do hay trỏ tới file không còn tồn tại.
- [x] Bộ fixture qua I1-I7; `todo-record` (nếu còn) ghi rõ trong Ghi chú.
- [x] tsc, eslint, vitest (questiongeneration, batchgeneration, architecture) đều qua.
- [x] Không có file test trong thư mục production; không có token trong repo.
- [x] User xác nhận bằng mắt với CLIProxyAPI: "mượt mà hơn rồi" (2026-11-26). **Chưa xác nhận với Capstone** (model chậm giữ cả câu trả lời).

## Ghi chú khi làm

- Báo rõ phần chưa kiểm được: giao diện (user tự kiểm), fixture ghi thật nếu còn `todo-record`, mọi test Playwright (không chạy).
- Phát lại chữ V1 sau rewrite vẫn ngoài phạm vi (P3).
- Đã làm (2026-11-26): xóa `_LiveItemPanel.tsx`, `_LiveAssembly.tsx`, `hooks/{useStepGate,useTypedText,useDropQueue,useChartReplay}.ts`, `utils/{stepGate,liveSteps,typingStep}.ts` và ba test của chúng; gỡ `REPLAY_ENGINE_ENABLED` và biến `NEXT_PUBLIC_GENERATION_REPLAY_ENGINE` khỏi `.env.local`; bỏ `endedWhenOpened`/`instant` ở `LiveJobPanel` và `_LiveJobItemList`.
- `GATE_STEPS` và `GateStep` chuyển sang `gateConstants.ts` (thanh dừng vẫn dùng); `StepId`, `StepView` và `DropState` nằm trong `replay/frameTypes.ts`. `LiveGenerationView` (trang form) cũng truyền `jobId`, `script`, `skipFinished` cho `LiveJobItemList`.
- `utils/typingStep.ts` (`revealedChars`) bị xóa cùng test: plan định giữ nhưng engine đếm ký tự theo phần nghìn trong `advance`, nên không còn nơi nào dùng.
- Ratchet `tests/unit/architecture/replayEngineRatchet.test.ts` (15 test): cấm lại 10 định danh cũ, chỉ cho 6 file trong `components/` và `hooks/` đọc `record.stage`/`job.status` (kèm lý do), báo lỗi nếu allowlist có mục thừa hay không có lý do, và giữ `replay/` không import React hay `@/`. Đã thử chèn tạm định danh cấm và `record.stage` để thấy nó fail rồi gỡ.
- Kết quả cuối: `tsc` không lỗi, `eslint` 0 lỗi (6 cảnh báo có sẵn), toàn bộ vitest của vendor-web 959 test qua (124 file), fixture qua I1–I7 ở mọi chế độ. Không có `Bearer`/`eyJ` trong fixture.
- Sau đó (2026-11-26): `_ThinkingPad` đã bỏ bộ đếm 1,5 giây riêng. `rewrite-v2` ghi thật từ job A1 với brief "từ vựng học thuật nâng cao" (reviewer từ chối vòng 1, vòng 2 đạt): có đủ `PROMPT` thứ hai, qua I1–I7 ở mọi chế độ; xác nhận giả định 7 (mỗi vòng viết đều mở bằng `PROMPT`). Không còn fixture `todo-record`. Một lần ghi có 3 vòng (24 KB) bị bỏ vì vượt giới hạn 20 KB.
- Còn lại: `clearPlayheads` chưa được gọi khi đóng trang lô hay đổi job (store giữ vài đầu phát nhỏ trong bộ nhớ, không rò rỉ nội dung); nhãn model dự phòng ở giao diện chưa làm.
