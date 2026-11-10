# Phase 3: Reviewer theo rubric + vòng viết lại + generation_meta

## Mục tiêu
Câu chỉ được lưu sau khi Reviewer cho PASS. Phiếu review được lưu cùng câu hỏi để người duyệt đọc.

## Thay đổi (`.../generation/review`)
- `ReviewPromptBuilder`: dựng system prompt **độc lập** với Generator. Prompt không chứa prompt hay lập luận của Generator, chỉ có:
  - đặc tả dạng bài: ràng buộc từ `TaskAuthoringRequirements` và bảng scorability;
  - **trait của rubric** cho dạng bài, lấy từ `com.pte.scoring.rubric.RubricCatalog`: tên trait, thang điểm, level descriptor.
    Câu hỏi cho Reviewer: "Câu trả lời cho câu hỏi này có chấm được đủ thang điểm của mỗi trait không?";
  - CEFR mục tiêu và mô tả ngắn từng mức (B1–C2), đặt trong `_common-reviewer.md`;
  - `ItemDraft` dưới dạng JSON.
- Đầu ra bắt buộc:
```json
{"verdict":"PASS|FAIL",
 "checks":{
   "taskFidelity":{"ok":true,"note":""},
   "cefrFit":{"ok":true,"estimated":"B2","note":""},
   "answerKey":{"ok":true,"note":""},
   "scorability":{"ok":true,"note":""},
   "clarity":{"ok":true,"note":""},
   "safety":{"ok":true,"note":""}},
 "fixSuggestion":""}
```
- `ReviewVerdictParser`: verdict phải nhất quán. Nếu verdict là PASS mà có check `ok=false`, coi như **FAIL** (fail closed).
  Nếu `estimated` lệch CEFR mục tiêu từ 2 bậc trở lên thì cũng FAIL.
- `LlmItemReviewer`: `LlmGateway(REVIEWER)`, temperature 0.

## Pipeline sau phase này
```
generate → validate ─(issues)→ regenerate(issues) ─┐
             └ ok → review ─ PASS → [media] → save  │
                         └ FAIL → regenerate(fixSuggestion + notes) → validate → review → PASS? save : fail item
```
- Mỗi câu có tối đa **1 lượt viết lại**, dù lý do là validator hay reviewer.
- Câu thất bại được ghi `failureCode` (`GENERATION_VALIDATION_FAILED` / `GENERATION_REVIEW_FAILED` / ...) và `failureNote` (tóm tắt, tối đa 300 ký tự).

## `questions.generation_meta` (JSONB, schema v1)
```json
{"schema":1,"jobPublicId":"...","model":{"generator":"Capstone","reviewer":"Capstone"},
 "promptVersion":"2026-11-06","topic":"urban farming","attempts":1|2,
 "review":{...đầu ra reviewer của lượt cuối...},
 "metrics":{"words":212,"avgSentenceLength":18.4,"fleschKincaid":11.2},
 "keyPoints":[...], "media":{"voice":"af_heart","speed":1.0,"durationSec":42} }
```
- `QuestionResponse` thêm `generationMeta` (nullable, đã parse). Chỉ trả về cho role tác giả (controller hiện có đã giới hạn role).
- Khi tạo revision: **không** copy `generation_meta` sang câu mới, để câu đã sửa tay không còn mang nhãn "AI".
  Thêm `aiGenerated` (boolean) vào bộ lọc list question: `generation_meta IS NOT NULL`.
- `promptVersion` là hằng số trong code, tăng khi sửa prompt.

## Test
- `ReviewVerdictParserTest`: PASS mâu thuẫn bị đổi thành FAIL; lệch CEFR 2 bậc thì FAIL; thiếu check thì FAIL.
- `ReviewPromptBuilderTest`: prompt chứa trait của rubric cho WE và SWT; không chứa text prompt của Generator.
- `GenerationPipelineTest` (gateway giả kịch bản hóa): PASS ngay; FAIL rồi PASS; FAIL hai lần; validator fail rồi review PASS; lỗi provider.
- Test revision: `generation_meta` không bị copy.

## Done khi
- Câu do AI tạo có phiếu review đầy đủ trong DB và API. Câu viết tay có `generationMeta = null`.

## Design Constraints
- Giữ các ratchet (300 dòng/file, 15 class/package `internal`, `Clock`, constants) và áp dụng các quyết định red-team của phase này trong plan.md.

## Quality and Testing State
- Chưa cook. Test theo mục Test của phase; cổng `ck:quality` bắt buộc trước khi đóng phase.
