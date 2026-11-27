# Phase 05 — Xáo lại giọng câu hội thoại

**Trạng thái:** [ ] · **Phụ thuộc:** phase 03 (API, `SpeechFitter`), phase 04 (hộp thoại)
**Story:** P2 "xáo lại giọng người nói"

## Vấn đề

SUMMARIZE_GROUP_DISCUSSION và RESPOND_TO_A_SITUATION không dựng lại được văn bản từ `Question` (không lưu các lượt thoại), nên phase 3 từ chối chúng. Cần lưu lượt thoại khi sinh và có thao tác xáo giọng. Bản đầu chỉ xáo, không chọn giọng từng người (đã chốt).

## Thay đổi

Gốc backend: `pte-api/app/src/main/java/com/pte/itembank/internal/generation/`.

1. **Trích `DialogueRenderer`** (`media/DialogueRenderer.java`, mới) từ `MediaRenderer`: phần `converse`, `distinctVoices`, `hasSituation`. `MediaRenderer` gọi lại lớp này, ngắn đi và giữ hành vi. Gói `media` lên 13 class.
2. **Lưu lượt thoại cho câu mới.** `DialogueRenderer` thêm vào meta media: `situation` và `turns` (người nói + câu), cạnh `voices` và `durationSec` hiện có. Câu hội thoại sinh trước thay đổi này không có `turns`.
3. **Dịch vụ xáo giọng** trong gói `voice/` (phase 3): `DialogueShuffleService.shuffle(publicId, caller)` (một phương thức public, không `@Transactional`, cùng khuôn với `VoiceChangeService`). Dựng lại draft từ `turns`, chọn bộ giọng mới bằng seed lấy từ `Clock` được inject, **bảo đảm bộ giọng khác bộ hiện tại** (thử lại vài lần), tổng hợp, kiểm tra độ dài theo `AudioDurationRules`, lưu file mới, ghi qua `QuestionVoiceWriter` (meta `voices` mới, `audioPromptRef` mới, audit). File cũ giữ nguyên.
4. **Endpoint** `POST /api/v1/questions/{publicId}/audio/voices/shuffle` (không body) trong `QuestionVoiceController`, trả `ApiResponse<QuestionResponse>`. Câu hội thoại thiếu `turns` trả `GENERATION_VOICE_NOT_SUPPORTED_FOR_TASK`. Phase 3 vẫn từ chối `POST .../audio/voice` cho hội thoại.
5. **Giao diện.** Hộp "Đổi giọng" của phase 4 nhận chế độ hội thoại: không hiện danh sách chọn, chỉ hiện giải thích, các giọng hiện tại theo người nói và nút "Xáo lại giọng". Thêm hook `useShuffleDialogueVoices` trong `fq/api.ts`; chữ vi/en trong constants. Điều kiện hiện nút ở web mở rộng cho hội thoại có `turns` trong meta.
6. **Dọn cuối kế hoạch.** Đối chiếu lại tài liệu cấu hình (`.env.example`, ghi chú trong `AGENTS.md` nếu có nhắc `QUESTION_GEN_VOICES_US/UK`), chạy toàn bộ kiểm tra backend và web.

## Design Constraints

- Tuân thủ `docs/CODING_STANDARDS_API.md` và `pte-web/docs/CODING_STANDARDS_WEB.md` (xem các phase 3 và 4): thông báo trong `*Constants.java` và constants vi/en; `@Transactional` chỉ ở writer; thời gian qua `Clock`; file ≤ 300 dòng; component ≤ 150 dòng; gói `internal/**` ≤ 15 class.
- Không xóa file audio cũ; chỉ xóa file mới nếu lưu DB thất bại.
- Mỗi người nói vẫn mang một giọng khác nhau (không trùng trong cùng câu).
- Câu hội thoại cũ không có `turns` không bị sửa dữ liệu hàng loạt (ngoài phạm vi).

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

## Test

- `DialogueRendererTest` (chuyển và bổ sung từ test của `MediaRenderer`): mỗi người nói một giọng khác nhau; meta có `turns` và `situation`.
- `DialogueShuffleServiceTest`: bộ giọng mới khác bộ cũ; người nói vẫn khác giọng nhau; thiếu `turns` bị từ chối đúng mã; độ dài vượt luật không lưu file; ref cũ không bị xóa.
- `QuestionVoiceControllerTest`: endpoint shuffle (quyền, mã lỗi).
- Web: `tests/unit/features/questionbank/` thêm test điều kiện hiện nút cho hội thoại và ánh xạ chữ lỗi.
- Chạy cuối kế hoạch: `.\mvnw.cmd -pl app -DskipTests compile`, `.\mvnw.cmd -pl app test` (báo riêng lỗi `SourceFileSizeTest` ở `ExamPublishService.java`), rồi `pnpm exec tsc --noEmit`, `pnpm exec eslint features/questionbank tests/unit/features/questionbank`, `pnpm exec vitest run` ở `pte-web/apps/vendor-web`. Build lại container `app` local.

## Hoàn thành khi

- [ ] Câu hội thoại mới sinh có `turns` trong meta.
- [ ] Xáo giọng tạo ref audio mới, bộ giọng khác bộ cũ, mỗi người nói giọng khác nhau, độ dài đúng luật.
- [ ] Câu hội thoại cũ không có `turns` nhận thông báo "không hỗ trợ" dễ hiểu.
- [ ] Toàn bộ test backend (trừ lỗi có sẵn đã nêu) và kiểm tra web qua.

## Ghi chú khi làm

(để trống)
