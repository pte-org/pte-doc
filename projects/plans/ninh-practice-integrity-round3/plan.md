# Plan: Ràng buộc transcript cho 3 dạng bài AI, đồng bộ đếm từ, tắt Pip trong Mock Test

Status: Ready
Date: 2026-11-15
Mode: Fast
Test: default
Owner/slug: Ninh — `ninh-practice-integrity-round3`
Scope: `pte-api` (`itembank`, migration), `pte-practice`, `pte-web` (`vendor-web`), `pte-doc`
Related: [ninh-practice-scoring-input-fixes](../ninh-practice-scoring-input-fixes/plan.md)

## Mục tiêu

Ba điểm đã đối chiếu là đúng trong đợt review mới:

1. Câu RE_TELL_LECTURE, SUMMARIZE_SPOKEN_TEXT, SUMMARIZE_GROUP_DISCUSSION có thể lưu mà không có transcript gốc,
   nhưng AI scorer cần nó (`AI_SOURCE_TEXT_EMPTY`), nên mọi học viên làm câu đó đều bị lỗi chấm.
2. Frontend đếm từ bằng `Intl.Segmenter` (tách `well-known` thành 2 từ), backend đếm theo khoảng trắng.
3. Pip (trợ lý AI) vẫn mở được trong Mock Test và nhận được đề bài.

Không làm: điểm "Đúng/Đúng một phần" của `InlineResultCard` (quyết định hiển thị, chờ bạn chốt).

## Scope challenge

### Đã có gì?

- `QuestionValidationHelper` đã chặn `REFERENCE_ANSWER_REQUIRED`, dựa vào cờ `requires_reference_answer` của bảng
  `question_types` (ưu tiên) hoặc của enum `PteTaskType`.
- Cờ trong DB được suy ra từ enum khi đồng bộ (`StandardTaskTypeService.applyCanonicalRequirements`), nhưng các dòng đã
  seed trước đó giữ giá trị cũ (`false`), nên chỉ sửa enum là chưa đủ.
- `useChatLauncher()` đã trả `null` khi không có `ChatLayout`; `PipCompanion` và `PracticeSupport` đã xử lý trường hợp đó.
- `PracticeSession.kind` (`MOCK_TEST`) đã có ở frontend.

### Tối thiểu là gì?

Enum + migration `V42` + dev-seed, một dòng đếm từ, một prop `enabled`.

### Độ phức tạp

Fast. Rủi ro: migration Flyway không sửa lại được sau khi merge; câu cũ thiếu transcript không tự được sửa.

## Phases

- [x] Phase 1: Bắt buộc transcript cho RE_TELL_LECTURE, SUMMARIZE_SPOKEN_TEXT, SUMMARIZE_GROUP_DISCUSSION — [phase-01-reference-answer-required.md](./phase-01-reference-answer-required.md)
- [x] Phase 2: Đếm từ theo khoảng trắng như backend — [phase-02-word-count.md](./phase-02-word-count.md)
- [x] Phase 3: Tắt Pip trong Mock Test — [phase-03-no-chat-in-mock-test.md](./phase-03-no-chat-in-mock-test.md)

## Kết quả thực hiện (2026-11-15)

- Phase 1: `PteTaskType.requiresReferenceAnswer()` thêm RE_TELL_LECTURE, SUMMARIZE_SPOKEN_TEXT, SUMMARIZE_GROUP_DISCUSSION;
  migration `V52__require_reference_answer_for_ai_listening_tasks.sql`; ba dòng dev-seed đổi cờ thành `true`;
  thông báo `REFERENCE_ANSWER_REQUIRED` ở editor vendor-web viết chung cho mọi dạng.
  Phát hiện thêm: `scripts/seed-local-practice-question-bank.ps1` không gửi `referenceAnswerText` cho SUMMARIZE_SPOKEN_TEXT,
  sau thay đổi này script seed sẽ bị chặn, nên đã bổ sung. Test cũ `summarizeSpokenText_withTranscript_isAccepted` giả định
  transcript nằm ở `promptText`; scorer thực tế đọc từ `referenceAnswerText` (và `AudioDraftMapper` cũng đặt ở đó) nên test đã sửa
  và thêm một test cho cả ba dạng.
- Phase 2: `countPracticeWords` đếm theo khoảng trắng. Test cũ coi dấu "—" đứng riêng không phải từ (5 từ); giờ là 6, giống backend.
- Phase 3: `ChatLayout` có prop `enabled`; `PracticeSessionView` tắt khi `session.kind === "MOCK_TEST"`. Test mới `chat-layout-disabled.test.tsx`.

Kiểm chứng: `pte-practice` tsc sạch, 801 test và eslint qua; `QuestionValidationHelperTest` và `TaskRuntimeContractDescriptorTest` qua;
vendor-web tsc không lỗi mới.

Chưa làm:
- Đã rebuild container và chạy migration `V42` trên Postgres local (2026-11-15): bản đầu tiên đặt tên `V10` bị trùng với V10 đã có (DB đang ở V41), nên đã đổi thành `V42`; `flyway_schema_history` ghi V42 thành công và 3 dạng bài có `requires_reference_answer = true`, `DESCRIBE_IMAGE` vẫn `false`.
- `PromptTestUsageCounterTest` báo lỗi vì cần Docker (Testcontainers), không liên quan thay đổi này.
- Câu đã lưu thiếu transcript chưa được quét; chưa thử trên giao diện; chưa commit.
- Điểm 3 của đợt review (InlineResultCard) cố ý không sửa.
