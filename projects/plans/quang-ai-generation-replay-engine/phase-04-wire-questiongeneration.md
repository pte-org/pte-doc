# Phase 04 — Nối giao diện `questiongeneration` vào khung hình

**Trạng thái:** [x] code xong, chờ user kiểm tra giao diện [quality: skipped_by_user; decision: user_confirmed_skip] · **Phụ thuộc:** phase 01-03
**Stories:** P1 thẻ khớp bước, P1 không lùi, P1 kết quả chỉ ở bước cuối, P2 các tùy chọn cũ; FR-05, FR-06 (phần `questiongeneration`)

## Vấn đề

Panel và các thẻ vẫn lấy nguồn riêng: `_LiveItemPanel.tsx:51-78`, `_LiveAssembly.tsx:94-156`, `LiveJobPanel.tsx:34-36`, `_LiveJobItemList.tsx:38-43`. Phase này đổi chúng sang đọc khung hình, chia ba bước nhỏ để mỗi bước app còn chạy. Một công tắc dev chọn đường cũ hay mới; công tắc gỡ ở phase 6.

**Công tắc:** hằng số đọc `process.env.NEXT_PUBLIC_GENERATION_REPLAY_ENGINE === "1"` (mặc định tắt) trong `liveConstants.ts`, tên `REPLAY_ENGINE_ENABLED`. Chỉ dùng ở chỗ chọn đường; không là cấu hình sản phẩm.

## Phase 4a — Hook và công tắc (đường cũ vẫn là mặc định)

1. **Đổi tên trước.** `hooks/useReplay.ts` (chart) đổi thành `hooks/useChartReplay.ts` và cập nhật import ở `_LiveAssembly.tsx:10, 94`. Chạy tsc. Chỉ khi qua mới tạo hook mới (L3).
2. `hooks/useLiveJob.ts` — thêm `scripts` (kịch bản mỗi câu) cạnh `items`: mỗi sự kiện vào `extendScript`. **Reset script chỉ khi `jobId` đổi**, không reset khi `mode` đổi hay khi kết nối lại (dòng 87 hiện reset trong cùng effect; tách ra effect theo `jobId`). Giữ `items` cho `LiveJobPanel`. Giữ cờ kết nối: `ended` khi nhận `end`, `closed` khi kết nối đóng.
3. `hooks/useReplay.ts` (mới) — `useReplay(jobId, index)`:
   - giữ đầu phát, chạy `requestAnimationFrame` với đồng hồ tiêm vào (tham số `clock`, mặc định `performance.now`), gọi `advance` rồi `frameOf`;
   - đọc `settings` từ `useTypingSpeed`, Dừng sau mỗi bước, Hiện hết, Bỏ qua phát lại;
   - nhận `record` của job và `saveQuestions`; gọi `settleOutcome` đúng quy tắc: nối `outcome` khi nhận `end`, hay kết nối đã đóng và job đã ở trạng thái cuối (poll đang chạy ở `useLiveJob`), hay READY của form;
   - `skip`: quyết định **một lần lúc mount** (script đầu tiên dựng ra đã `ended` thì đầu phát tới cuối); `end` đến muộn không làm nhảy;
   - đầu phát của mỗi `(jobId, index)` lưu trong store nhỏ ở mức trang (module-level, xóa khi `jobId` đổi hay trang đóng) để quay lại câu xem dở thì tiếp tục (L6);
   - trả `{ frame, controls }`; `controls` gồm `revealAll`, `release`, `setPauseEachStep`.
4. Công tắc: `LiveItemPanel` chọn đường cũ hay mới; mặc định đường cũ. Hook mới gọi thật chỉ khi công tắc bật (tránh chạy hai đồng hồ).
5. Test thuần cho hàm dựng `settings`, hàm quyết định lúc nào nối `outcome`, hàm lưu và khôi phục đầu phát của store (không `renderHook`).

## Phase 4b — Panel, thanh bước và thẻ đọc frame

1. `components/_LiveItemPanel.tsx` — với công tắc bật: bỏ `useTypedText`, `useStepGate`, `gateLive`, `stillTyping`, `behind`, `outcome`, `dropsIdle`. Chỉ gọi `useReplay`; `stageChip` dùng `chipOf(frame)`; `onReplayDone(frame.done)` giữ cho trang lô. Mỗi component ≤ 150 dòng, `const` arrow có kiểu trả về.
2. `components/_LiveStepper.tsx`, `_LiveStepDetail.tsx`, `_ThinkingPad.tsx`, `_StepGateBar.tsx`, `_ReplayControls.tsx` — đọc từ frame. `_ThinkingPad` bỏ đồng hồ riêng (độ trễ nay là thời gian đầu phát, quyết định 9). `_StepGateBar` dùng `frame.heldAtStep` và `controls.release`. Đọc từng file trước khi sửa.
3. `components/LiveJobPanel.tsx` và `_LiveJobItemList.tsx` — bỏ `endedWhenOpened` và `instant` (đường mới). Chip câu đang mở dùng `chipOf(frame)`; câu khác dùng stage server (quyết định 11).

## Phase 4c — Lắp ráp field và hoạt ảnh

1. `components/_LiveAssembly.tsx` — bỏ `useDropQueue`, chart replay (nay là bước `media`), `liveSteps`. Đọc `frame.steps`, `frame.view`, `placed`, `flying`, `settling`. `progress` (dòng 126-129) tính từ frame, không từ `live.stage`. Hiện hàm dài gần 150 dòng; tách ra: `useAssemblyPieces` (dựng danh sách field và nhãn bay), `_AssemblyPreviewColumn` (cột xem trước và vòng sáng settle) và để `LiveAssembly` chỉ ghép.
2. `components/_FlyingPiece.tsx`, `_AgentCursor.tsx`, `_LiveAssemblyForm.tsx`, `_LiveExamPreview.tsx` — đọc `frame` thay cho `DropQueue`; kiểu `DropQueue` thay bằng kiểu trong `replay/`.
3. `hooks/useDropQueue.ts` không còn ai gọi; **xóa ở phase 6** (không điều kiện).

## Design Constraints

- `useReplay(jobId, index)` là nơi **duy nhất** giữ đầu phát và chạy đồng hồ. Không component nào giữ `useState` về bước.
- Với công tắc bật, component chỉ đọc `frame`. Không `record.stage`, `live.stage`, `job.status` để quyết định bước hay thẻ của câu đang phát.
- Giữ nguyên hành vi đã duyệt: `TYPING_SPEEDS`, Hiện hết, Dừng sau mỗi bước, Bỏ qua phát lại, `PIECE_*`, `THINKING_REVEAL_AFTER_MS`, `CHART_REPLAY_MS`.
- Không đổi bố cục, không đổi kiểu dáng `@pte/ui`; chữ mới vào constants vi/en.
- Không `style={{}}`, `any`, `@ts-ignore`. Mỗi file ≤ 300 dòng, mỗi component ≤ 150 dòng.
- Công tắc dev không lưu ở bất cứ đâu ngoài biến môi trường; gỡ ở phase 6.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

## Test

- Test thuần của 4a (mục 5). Chạy lại toàn bộ fixture của phase 3.
- tsc phải qua **giữa các bước**: sau đổi tên chart, sau tạo hook, sau mỗi component.
- Không mở trình duyệt. User tự kiểm tra với công tắc bật: CLIProxyAPI (nhanh) và Capstone (chậm), Hiện hết, Dừng sau mỗi bước, Bỏ qua phát lại, quay lại câu xem dở.

## Hoàn thành khi

- [x] 4a: hook mới tồn tại, công tắc tắt thì app y như cũ; tsc, eslint, vitest qua.
- [x] 4b: công tắc bật thì panel, thanh bước, thẻ cùng đọc `frame`; `onReplayDone` còn hoạt động.
- [x] 4c: lắp ráp field đọc `frame` (code xong). **Chưa được user xác nhận kết quả đúng như đã duyệt**, vì tôi không mở trình duyệt.
- [x] tsc, eslint, vitest đều qua sau mỗi bước.

## Ghi chú khi làm

- `useQuestionTypes` hiện gọi ở `_LiveAssembly.tsx:88`; cần để lấy `FrameContext` (field theo dạng bài). Đưa lên `LiveItemPanel` rồi truyền vào `useReplay`; `@/` chỉ dùng ở code production, không ở `replay/`.
- Không reset `useReplay` khi script dài thêm; key chỉ theo `(jobId, index)`.
- Đã làm (2026-11-26):
  - 4a: `hooks/useChartReplay.ts` (đổi tên hook cũ), `hooks/useReplay.ts` (mới), `useLiveJob` giữ `script` (reset chỉ khi `jobId` đổi) và tiêm kết quả của job qua `reasonFor`/`settleOutcome`; `replay/playheadStore.ts`, `replay/gateRank.ts`; hằng `REPLAY_ENGINE_ENABLED` (`liveConstants.ts`). Test thuần: `hookParts.test.ts`.
  - 4b/4c gộp lại thành hai component mới thay vì sửa component cũ tại chỗ: `_ReplayItemPanel.tsx` (panel: thanh dừng/tốc độ, thẻ, gọi `useReplay`) và `_ReplayAssembly.tsx` (thanh bước, form, preview, con trỏ, field bay, đều đọc `frame`). `LiveItemPanel` là bộ chọn: công tắc bật dùng đường mới, tắt dùng `LegacyItemPanel` (code cũ nguyên vẹn). Cách này giữ đường cũ chạy được tới phase 6 và không động vào `_LiveAssembly`.
  - `_LiveJobItemList` thẻ của câu đang mở lấy từ `onChip` của panel; câu khác dùng stage server (quyết định 11). `LiveJobPanel` truyền `jobId`, `script`, `skipFinished`.
  - Công tắc **bật ở local**: `NEXT_PUBLIC_GENERATION_REPLAY_ENGINE=1` trong `apps/vendor-web/.env.local` (gitignore). Cần **khởi động lại dev server** của vendor-web để biến có hiệu lực.
- `_ThinkingPad` vẫn còn bộ đếm riêng (chờ thêm 1,5 giây sau khi pad hiện). Trong đường mới phần suy nghĩ đã bị đầu phát giữ lại 1,5 giây, nên tổng độ trễ là hơn 3 giây. Bỏ bộ đếm riêng ở phase 6 khi đường cũ bị xóa (lúc đó pad chỉ phục vụ đường mới).
- `useDropQueue`, `useStepGate`, `liveSteps`, `useTypedText`, `useChartReplay` vẫn còn vì `LegacyItemPanel` và `_LiveAssembly` dùng; xóa ở phase 6.
