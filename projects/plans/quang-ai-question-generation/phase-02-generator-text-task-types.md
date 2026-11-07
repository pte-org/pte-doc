# Phase 2: Generator + validator cho các dạng text (P1)

## Mục tiêu
Sinh câu DRAFT hợp lệ cho 8 dạng: MC_READING_SINGLE, MC_READING_MULTIPLE, FILL_IN_THE_BLANKS_DROPDOWN,
FILL_IN_THE_BLANKS_DRAG_AND_DROP, RE_ORDER_PARAGRAPHS, SUMMARIZE_WRITTEN_TEXT, WRITE_ESSAY, READ_ALOUD.

## Việc cần đọc trước khi code
- Cách mỗi dạng lưu dữ liệu trong `Question`/`QuestionOption`: `promptText`, `options`, `correctAnswerText`, cú pháp ô trống của FIB,
  thứ tự của RO, `referenceAnswerText`, `min/maxWordCount`. Đọc trong `TaskAuthoringRequirements`, `QuestionValidationHelper`,
  `StimulusLength`, `tasktype/*` và các test tạo câu hiện có. **Mapper phải ghi đúng format mà form tạo câu thủ công của vendor-web đang gửi.**

## Thay đổi (`.../generation/generator`)
- `PromptRegistry`: nạp `resources/question-generation/prompts/{TASK_TYPE}.md` và `_common-generator.md`.
  - Phần chung: vai trò người ra đề PTE Academic; viết bằng tiếng Anh chuẩn học thuật; không sao chép đề Pearson thật hay đề đã công bố;
    tránh chủ đề nhạy cảm (chính trị, tôn giáo, bạo lực); viết số bằng chữ; chỉ trả về JSON.
  - Biến chèn vào prompt: `{cefr}`, `{topicHint}`, `{avoidTopics}` (20 chủ đề gần nhất cùng dạng, lấy từ `generation_meta.topic`),
    `{lengthRules}` (lấy từ bảng ràng buộc bên dưới).
  - Mỗi file prompt có 1 ví dụ JSON mẫu do nhóm tự viết.
- `ItemDraft` (sealed interface) với các record theo hình dạng tương tác, **không** tạo record riêng cho mỗi dạng:
  - `ChoiceDraft(topic, passage, question, options[], correctIndexes[])`, dùng cho MC single và multiple
  - `BlankFillDraft(topic, passageWithSlots, slots[{answer, distractors[]}])`, dùng cho FIB dropdown và drag-drop (drag-drop gộp chung word bank)
  - `ReorderDraft(topic, paragraphs[] theo thứ tự đúng)`, khi lưu thì xáo trộn bằng seed
  - `PassageDraft(topic, passage, keyPoints[]?, essayPrompt?)`, dùng cho SWT, WE, RA
- `DraftParser`: Jackson parse chặt, field lạ thì bỏ qua, thiếu field thì báo lỗi `GENERATION_SCHEMA_INVALID`.
- `LlmItemGenerator implements ItemGenerator`: build prompt, gọi `LlmGateway(GENERATOR)`, parse. Lỗi parse thì retry 1 lần với lời nhắc "return valid JSON only".
- `DraftToQuestionMapper`: chuyển `ItemDraft` sang `CreateQuestionRequest`, gồm:
  - `cefrLevel`, `pool` và cờ availability;
  - `referenceAnswerText` = keyPoints hoặc đáp án mẫu (định dạng giống form thủ công);
  - với WE và SWT: `min/maxWordCount` theo mặc định của dạng.

## Validator (`DraftValidator`): luật cứng, gồm cả luật suy ra từ rubric
| Dạng | Luật |
|---|---|
| Chung | Không có ô hay text rỗng; tiếng Anh (ký tự ASCII chiếm từ 95% trở lên); không trùng hash `passage` với câu đã có cùng dạng |
| MC_SINGLE | 4–5 lựa chọn, đúng 1 đáp án, các lựa chọn không trùng nhau |
| MC_MULTIPLE | 5–7 lựa chọn, 2–3 đáp án đúng |
| FIB dropdown | 4–6 ô trống, mỗi ô có 1 đáp án và 3 distractor khác đáp án |
| FIB drag-drop | 3–5 ô trống, word bank = đáp án + 2–3 từ thừa, không trùng |
| RO | 4–5 đoạn, mỗi đoạn 15–60 từ |
| SWT | Đoạn văn 200–300 từ, 3–4 keyPoints |
| WE | Đề 20–60 từ, có dạng tranh luận (keyword như "agree", "discuss", "advantages", "to what extent") |
| RA | 50–60 từ (theo CEFR: B1 khoảng 45–55), không có chữ số hay từ viết tắt viết hoa |
| Passage reading | Độ dài theo CEFR (bảng trong prompt). Thông tin tham khảo thêm: độ dài câu trung bình, Flesch–Kincaid (lưu vào meta, không dùng để chặn) |

- Vi phạm được trả về dạng `List<ValidationIssue(code, message)>` và gửi kèm cho Generator khi viết lại.
  Viết lại tối đa 1 lần cho mỗi câu (dùng chung lượt với lần viết lại do Reviewer ở phase 3).
- Sau validator, `ItembankService.create` vẫn validate thêm một lần. Lỗi ở bước này được ghi `GENERATION_ITEMBANK_REJECTED` kèm mã lỗi gốc.

## Test
- `DraftParserTest`: JSON hợp lệ và JSON thiếu field cho từng hình dạng.
- `DraftValidatorTest`: mỗi luật có ít nhất 1 case đạt và 1 case vi phạm.
- `DraftToQuestionMapperTest`: với mỗi dạng, `CreateQuestionRequest` sinh ra phải qua được `ItembankService.create` thật (slice test với repo in-memory hoặc mock theo pattern hiện có).
- `PromptRegistryTest`: đủ file prompt cho 8 dạng, mọi placeholder đều được thay.
- Smoke thủ công (không chạy trong CI): `QuestionGenerationSmokeTest` dùng `@EnabledIfEnvironmentVariable("QUESTION_GEN_SMOKE")`,
  gọi 9router thật, sinh mỗi dạng 1 câu, in ra ID câu. Nội dung không in ra log CI.

## Done khi
- Job thật (key trong `.env.local`) sinh được câu DRAFT cho cả 8 dạng, mở được trong màn chỉnh sửa câu hỏi của vendor-web.

## Design Constraints
- Giữ các ratchet (300 dòng/file, 15 class/package `internal`, `Clock`, constants) và áp dụng các quyết định red-team của phase này trong plan.md.

## Quality and Testing State
- Chưa cook. Test theo mục Test của phase; cổng `ck:quality` bắt buộc trước khi đóng phase.

## Quyết định đã chốt (red-team H6)
- `content_hash` theo mục "Quyết định đã chốt: content_hash" trong plan.md. Validator từ chối câu trùng hash cùng dạng hoặc trùng trong cùng job; cột và index thêm ở V34 (phase 1).
- Test: cùng nội dung khác hoa thường hoặc dấu câu cho cùng hash; nội dung khác cho hash khác; câu viết tay (hash null) không bị coi là trùng.
