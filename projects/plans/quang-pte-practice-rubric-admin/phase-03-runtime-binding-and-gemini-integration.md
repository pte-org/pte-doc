# Phase 03: runtime binding, snapshot và Gemini explanation

**Status:** implemented and verified  
**Dependency:** Phase 01–02  
**Output:** Practice dùng đúng rubric đã publish và explanation có provenance kiểm chứng được.

## Mục tiêu

Loại bỏ việc chỉ truyền `rubricVersion` từ configuration. Practice session phải resolve published rubric, pin snapshot/hash, rồi truyền safe projection vào generator. Explanation cũ không bị đánh giá lại bằng rubric hiện tại.

## Công việc

1. Trong `PracticeSessionItemService.pinQuestionContent()`, resolve published rubric theo canonical task và channel.
2. Kiểm tra question revision, reference/evaluator revision, renderer/runtime profile, answer schema và rubric compatibility.
3. Lưu rubric public ID, revision, hash, projection/snapshot reference và runtime metadata vào session item; giữ safe student projection tách khỏi restricted fields.
4. Nếu thiếu published rubric hoặc binding không hợp lệ, đánh dấu task unavailable và ngăn session mới bắt đầu.
5. Đổi `PracticeExplanationGenerator.ExplanationRequest` sang `RubricContext` có criterion IDs, levels, evidence policy, snapshot hash và language.
6. Cập nhật `PracticeExplanationService` và `PracticeGeminiExplanationGenerator` để Gemini nhận projection đã phê duyệt, VI mặc định và EN tùy chọn.
7. Validate output: không có criterion ID lạ, không trùng, không thiếu criterion bắt buộc, level hợp lệ, đúng thứ tự, evidence reference hợp lệ và `NOT_ASSESSABLE` đúng applicability.
8. Persist rubric public ID/version/hash và evaluator/evidence provenance vào explanation; thêm các trường này vào submission hash.
9. Giữ objective correctness do deterministic evaluator quyết định. AI chỉ tạo feedback; không trả numeric Writing/Speaking score.
10. Legacy sessions không có pin phải trả provenance `LEGACY_RUBRIC_UNPINNED`/unavailable rõ ràng, không âm thầm dùng rubric mới.

## Common/shared bắt buộc

- Gọi rubric qua public module facade; không đọc repository từ practice.
- Giữ `ApiResponse`, error mapping và Practice constants hiện có.
- Dùng cùng submission/evaluation identity và snapshot conventions của Practice completion plan.
- Không tạo provider client riêng trong practice nếu Gemini adapter hiện tại đã là abstraction dùng chung.

## Design Constraints

- Gemini chỉ nhận safe rubric projection và verified evidence.
- Runtime key là semantic allowlist; không lưu class name, script hoặc executable configuration.
- Retired rubric vẫn đọc được cho historical session.
- Retry/GET không resolve current published rubric lại.
- Audio không có thì pronunciation/fluency là `NOT_ASSESSABLE`; không suy luận từ text/transcript.

## Quality and Testing State

- Quality: **APPROVED** by the independent review for immutable pinning, deterministic/form provenance, evidence manifest ownership and provider-output safety; final phase completion remains subject to the `--hard` confirmation gate.
- Testing: session pin, generator contract, objective/form result preservation, evidence spoofing and numeric-score rejection are covered by targeted tests; full backend regression passes.
- Required tests: missing rubric admission block, task/runtime mismatch, retired pin, legacy provenance, pinned retry, Gemini schema validation, criterion/level allowlist, objective result preservation, prompt injection/evidence spoofing và no numeric AI score.
- TDD gate: session pin and generator contract tests were added before accepting the related production changes.
