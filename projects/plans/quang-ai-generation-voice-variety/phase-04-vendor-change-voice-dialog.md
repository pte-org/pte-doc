# Phase 04 — Hộp "Đổi giọng" ở trang chi tiết câu hỏi

**Trạng thái:** [x] [quality: skipped_by_user; decision: user_confirmed_skip] · **Phụ thuộc:** phase 03
**Story:** P1 "đổi giọng có nghe thử" (FR-08)

## Vấn đề

Trang chi tiết (`apps/vendor-web/features/questionbank/components/QuestionDetailView.tsx`) chỉ phát audio. Người tạo đề không đổi được giọng. File này đang **299 dòng** nên không thêm trực tiếp được.

## Thay đổi

Gốc: `pte-web/apps/vendor-web/features/questionbank/` (viết tắt `fq/`) và `pte-web/packages/api-client/src/`.

1. **Kiểu và request dùng chung.** Trong `packages/api-client/src/` (cạnh `types/question/index.ts` và thư mục request hiện có): kiểu `VoiceOption` (mã, accent, giới tính, nhãn), `ChangeVoiceRequest`, và hàm request cho ba endpoint của phase 3. Theo cách `listQuestions(apiClient, ...)` đang dùng.
2. **Hook** (`fq/api.ts`): `useVoiceCatalog` (`useQuery`, danh mục ít đổi nên cache lâu), `useVoiceSample(voice)` (chỉ tải khi người dùng bấm nghe), `useChangeVoice` (`useMutation`; thành công thì invalidate query của câu để audio và meta tải lại). Nếu `api.ts` gần 300 dòng thì tách file cùng thư mục, vẫn qua TanStack Query.
3. **(Làm đầu tiên) Tách phần audio khỏi `QuestionDetailView.tsx`.** Đưa `audioValue` và nút mới vào `fq/components/_AudioPromptValue.tsx`. File chi tiết ngắn đi trước khi thêm, và không vượt 300 dòng sau khi gắn component mới.
4. **Hộp thoại** `fq/components/_ChangeVoiceDialog.tsx` (dùng `Dialog`, `Button`, `Alert`, `Chip` của `@pte/ui` như có sẵn; nếu thiếu thành phần thì đọc `packages/ui` trước, không tự vẽ lại kiểu dáng).
   - Nhóm theo accent (Mỹ, Anh), trong nhóm có cột nữ và nam; mỗi giọng một hàng `_VoiceOptionRow.tsx` với nhãn, nút nghe thử, và radio chọn.
   - Giọng hiện tại được đánh dấu.
   - Nút xác nhận gọi `useChangeVoice`; trong lúc chờ khóa hộp thoại và hiện trạng thái đang xử lý (Re-tell Lecture, Summarize Spoken Text có thể tới 90 giây). Lỗi hiển thị bằng `getUserFacingApiErrorMessage`, kèm chữ riêng cho `GENERATION_VOICE_NOT_SUPPORTED_FOR_TASK` và lỗi độ dài.
   - Logic nhóm giọng là hàm thuần `fq/voiceGroups.ts`.
5. **Điều kiện hiện nút.** Nút hiện khi câu đang `DRAFT` (cùng điều kiện với nút Sửa) và `voiceChangeSupported` là true. Giọng hiện tại lấy từ `currentVoice`. Cả hai trường do phase 3 thêm vào `QuestionResponse`, nên web không phải tự giữ danh sách dạng bài được hỗ trợ.
   - Request gửi kèm `version` của câu đang hiển thị.
   - Nút xác nhận bị khóa khi chưa chọn giọng mới, khi giọng chọn trùng `currentVoice`, và trong lúc mutation đang chạy.
   - Lỗi xung đột phiên bản thì báo user tải lại trang. Lỗi `GENERATION_VOICE_BUSY` thì báo user thử lại sau.
6. **Chữ hiển thị** (vi/en, qua `useAdminCopy` như file chi tiết đang dùng) trong `fq/constants.ts` hoặc file constants riêng nếu gần 300 dòng: tiêu đề hộp, nhãn accent và giới tính, "Đổi giọng", "Nghe thử", "Đang tạo lại audio...", thông báo lỗi, thành công.
7. Chạy `tsc`, `eslint`, `vitest`; không mở trình duyệt.

## Design Constraints

- Tuân thủ `pte-web/docs/CODING_STANDARDS_WEB.md` và `pte-web/AGENTS.md`: dùng `@pte/ui` như đã phát hành, không ghi đè kiểu dáng; chữ hiển thị trong constants vi/en; API chỉ qua `api.ts` + `@pte/api-client` + TanStack Query, không `fetch` trong component; không `any`, không inline style; component ≤ 150 dòng, file ≤ 300 dòng; component hàm `const`; mỗi component có props interface.
- Test đặt dưới `tests/unit/` phản chiếu cây nguồn, không đặt cạnh component.
- Nút chỉ nằm ở trang chi tiết câu hỏi (đã chốt), không ở trang lô.
- Không hiển thị mã lỗi máy; mã `GENERATION_*` được ánh xạ sang chữ trong constants.
- Không xử lý audio bằng thẻ `<a>`/`<img>` thô ngoài mẫu đã có (`<audio>` giữ như hiện tại).

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

## Test

Dưới `apps/vendor-web/tests/unit/features/questionbank/`:
- `voiceGroups.test.ts`: nhóm theo accent rồi giới tính, giữ thứ tự ổn định, bỏ qua giọng không có trong danh mục.
- `voiceChangeEligibility.test.ts` (hàm thuần điều kiện hiện nút): `DRAFT` có meta và dạng hỗ trợ thì hiện; câu `APPROVED`, thiếu meta, dạng hội thoại thì không.
- `voiceErrorCopy.test.ts`: mã lỗi ánh xạ sang chữ, mã lạ dùng chữ dự phòng.
- Chạy từ `pte-web/apps/vendor-web`: `pnpm exec tsc --noEmit`, `pnpm exec eslint features/questionbank tests/unit/features/questionbank`, `pnpm exec vitest run tests/unit/features/questionbank`.

## Hoàn thành khi

- [x] Trang chi tiết có nút "Đổi giọng" đúng điều kiện; `QuestionDetailView.tsx` ≤ 300 dòng.
- [x] Hộp chọn giọng nhóm theo accent, nghe thử được, xác nhận thì audio mới phát lại trên trang.
- [x] Có trạng thái đang xử lý và thông báo lỗi dễ hiểu.
- [x] `tsc`, `eslint`, `vitest` qua.

## Ghi chú khi làm

- **Điều kiện hiện nút** không dùng `currentVoice` / `voiceChangeSupported` như plan cũ. Backend đã trả `generationMeta.media.voice` cho người soạn đề, và `GET /question-generation/voices` kèm `supportedTaskTypes` (xem phase 3). `canChangeVoice` ở `voiceGroups.ts` dùng hai nguồn đó: câu `DRAFT`, có audio, có giọng hiện tại, dạng bài nằm trong danh sách hỗ trợ.
- **Nghe thử:** `client.download` đọc được `blob`, nên mẫu là `audio/wav` (`getQuestionVoiceSample`). `useVoiceSamplePlayer` phát một mẫu một lúc, giải phóng object URL khi dừng.
- **Chữ hiển thị:** `voiceConstants.ts` có vi/en riêng theo `useLocale` (giống `questiongeneration`), không thêm vào từ điển `adminCopy`. Mã lỗi mới thêm vào danh mục lỗi người dùng ở `packages/api-client/src/client/errorMessage.ts`.
- **`QuestionDetailView.tsx`:** phần audio tách sang `_AudioPromptValue.tsx`; file còn 294 dòng.
- **Request:** gửi `version` của câu đang xem. Nút xác nhận khóa khi chưa chọn giọng hoặc chọn trùng giọng hiện tại, và khi đang gọi.
- Đã kiểm tra: `tsc` qua; `eslint` 0 lỗi (2 cảnh báo `<img>` có sẵn); `vitest` questionbank 65 test qua (có 11 test mới ở `voiceGroups.test.ts`); `api-client` 778 test qua. Chưa mở trình duyệt (user tự thử giao diện).
- Không chạy quality gate (user yêu cầu bỏ).
