# Phase 10: Sinh đề từ template & kho đề chỉ còn SHARED

## Requirements

Tenant chọn template → hệ thống random lấy câu từ kho SHARED theo từng slot → publish thành `ExamSnapshot` bất biến. Rút đường soạn đề thủ công của host. Rút `Visibility.PRIVATE` khỏi `itembank`.

Maps to: **[ADR-006](../../architecture/ADR-006-commercialization-and-exam-templates.md) §5, §6**

## Design Constraints

- **Kiểm đủ câu TRƯỚC khi sinh.** Kho thiếu câu cho một slot → 422 kèm tên task type thiếu. Không bao giờ phát đề thiếu câu rồi báo sau.
- **Lưu `randomSeed`.** Đề đã phát phải tái tạo được để audit và để khiếu nại điểm có cơ sở. Random không lưu seed là random không giải trình được.
- **Seed và nội dung snapshot không lộ ra ngoài `assessment` trước `opensAt`.** Không endpoint nào trả `randomSeed` hay nội dung câu hỏi cho host trước giờ thi — nếu không thì "random đề" chỉ là trang trí.
- **`weightPercent` snapshot hoá vào `ExamSnapshot`.** Admin sửa template không được làm đổi điểm của kỳ thi đã diễn ra. Cùng logic với việc Phase 4 snapshot cap của gói.
- Rút `Visibility.PRIVATE` theo thứ tự: **bỏ đường ghi trước, rút enum sau**. Đã kiểm — không có row `PRIVATE` nào trong DB, nên không cần bước migrate dữ liệu.
- `ExamBlueprint` trở thành **artifact được sinh ra**, không còn là thứ người dùng soạn.

## Steps

1. `ExamSnapshot` thêm: `templatePublicId`, `randomSeed` (long), `sectionWeights` (JSON hoặc bảng con `SnapshotSectionWeight` — chọn bảng con để `reporting` query được mà không parse JSON).

2. Migration `V22__assessment_snapshot_template.sql` + bảng `snapshot_section_weights`.

3. `QuestionRepository.findRandomByTaskType(taskType, limit, seed)` — dùng `ORDER BY md5(id::text || :seed)` để random **tất định theo seed**, không dùng `RANDOM()` (không tái tạo được). Chỉ lấy câu `SHARED` và `status = APPROVED`.

4. `QuestionRepository.countAvailableByTaskType(taskType)` — cho bước kiểm khả thi.

5. `TemplateResolverService.resolve(templatePublicId, seed)`:
   - **Bước 1 — kiểm đủ:** với mỗi slot, so `questionCount` với `countAvailableByTaskType`. Gom **tất cả** slot thiếu rồi ném một exception liệt kê đầy đủ, không ném ở slot thiếu đầu tiên
   - **Bước 2 — lấy câu:** theo thứ tự `section.orderIndex` rồi `slot.orderIndex`
   - **Bước 3 — publish:** deep-copy nội dung vào `ExamSnapshot` + `SnapshotItem`, lưu `randomSeed` và `sectionWeights`
   - Toàn bộ trong một transaction

6. `InsufficientQuestionsException` → 422, payload liệt kê `{taskType, required, available}` cho từng slot thiếu.

7. `AssessmentService` (facade) thêm `generateSnapshotFromTemplate(templatePublicId, seed)`. Seed do caller truyền (Phase 11 sinh lúc tạo kỳ thi) để `session` nắm được giá trị đã dùng.

8. Rút đường soạn đề thủ công:
   - Bỏ `POST`/`PUT`/`DELETE` trên `BlueprintController` (host tự chọn câu)
   - Giữ `GET` để xem lại blueprint đã sinh
   - `CreateBlueprintRequest`, `BlueprintItemRequest` và các exception liên quan (`EmptyBlueprintException`, `InvalidSectionException`) rút theo nếu không còn ai dùng

9. Rút `Visibility.PRIVATE`:
   - Bỏ khả năng đặt `PRIVATE` ở `QuestionController` / `CreateQuestionRequest`
   - `ItembankAccessPolicy` rút gọn còn kiểm quyền ghi (`PLATFORM_AUTHOR`)
   - `SharedWriteForbiddenException` xoá
   - `Question.tenantId` luôn null
   - **Rút enum value `PRIVATE` sau cùng**, sau khi không còn đường ghi nào

10. `reporting`: `ScoreAggregationService` đọc `sectionWeights` từ snapshot của attempt, tính `Σ(điểm phần × trọng số)`. **Đọc từ snapshot, không đọc từ `ExamTemplate`.**

11. Test: template cần 5 `READ_ALOUD` nhưng kho chỉ có 3 → 422 liệt kê đúng slot đó, **không** snapshot nào được tạo.

12. Test tái tạo: `resolve()` hai lần **cùng seed** → hai snapshot có danh sách câu hỏi giống hệt, cùng thứ tự.

13. Test: `resolve()` hai lần **khác seed** trên kho đủ lớn → danh sách câu khác nhau.

14. Test: sửa `weightPercent` của template (qua clone + activate bản mới) → snapshot cũ giữ nguyên trọng số cũ, điểm tính ra không đổi.

15. Test: không endpoint nào trả `randomSeed` hoặc nội dung câu hỏi cho vai trò host trước `opensAt`.

## Success Criteria

- Tenant tạo kỳ thi → đề sinh tự động, đúng số câu mỗi loại theo template
- Kho thiếu câu → chặn ngay, liệt kê đủ mọi chỗ thiếu trong một lần
- Đề tái tạo được từ seed đã lưu
- Host không còn đường nào tự chọn câu hỏi
- Không còn `Visibility.PRIVATE` trong code, app khởi động bình thường
- Điểm tổng tính theo trọng số đọc từ snapshot

## Quality and Testing State

- Quality gate: chưa chạy
- Testing: chưa bắt đầu

## Session Notes

_(trống)_
