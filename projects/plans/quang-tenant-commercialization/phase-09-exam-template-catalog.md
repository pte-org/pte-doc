# Phase 9: Catalog template đề

## Requirements

`ExamTemplate` — bản đặc tả cấu trúc đề: mỗi phần thi chiếm bao nhiêu % điểm, và mỗi loại task cần bao nhiêu câu. Do **Admin nền tảng** tạo, tenant chỉ chọn khi tạo kỳ thi.

Maps to: **[ADR-006](../../architecture/ADR-006-commercialization-and-exam-templates.md) §5**

## Design Constraints

- **Template là tài nguyên nền tảng.** `tenantId = null` luôn. Tenant không tạo, không sửa, chỉ đọc danh sách `ACTIVE`.
- **Tổng `weightPercent` của các section phải bằng đúng 100.** Validate lúc chuyển sang `ACTIVE`, không phải lúc lưu nháp — người soạn cần lưu dở.
- `TemplateSlot.taskType` phải thuộc `section` của `TemplateSection` chứa nó. `PteTaskType` đã mang sẵn `section` nên kiểm được bằng dữ liệu, không cần bảng tra.
- Template `ACTIVE` mà đang được kỳ thi dùng thì **không sửa được nữa** — sửa sẽ làm lệch giữa đề đã phát và đặc tả. Chỉ cho `ARCHIVED` (ngừng dùng cho kỳ thi mới) hoặc clone ra bản mới.
- Phase này **chỉ** làm catalog. Việc sinh đề từ template là Phase 10.

## Steps

1. Enum `TemplateStatus` (`DRAFT`, `ACTIVE`, `ARCHIVED`) trong `assessment/domain/enums/`.

2. Entity `ExamTemplate`: `name`, `description`, `tenantId` (luôn null, giữ cột cho nhất quán với `ExamBlueprint`), `status`.

3. Entity `TemplateSection`: FK `template_id`, `section` (`PteSection`), `weightPercent` (int), `orderIndex`.

4. Entity `TemplateSlot`: FK `template_section_id`, `taskType` (`PteTaskType`), `questionCount` (int > 0), `orderIndex`.

5. Migration `V21__assessment_exam_template.sql`, index trên `(status)`.

6. `TemplateService` — CRUD cho `PLATFORM_AUTHOR` / `PLATFORM_ADMIN`:
   - Lưu `DRAFT` không kiểm tổng %
   - `activate()` kiểm: Σ `weightPercent` == 100; mỗi section có ít nhất một slot; mọi `slot.taskType.getSection()` khớp `section` của cha; `questionCount > 0`
   - Sai → 422 nói rõ vi phạm nào

7. Chặn sửa: `ExamTemplate` ở `ACTIVE` chỉ đổi được `name`/`description`. Đổi cấu trúc phải clone sang `DRAFT` mới.

8. `clone(templatePublicId)` — tạo bản `DRAFT` sao chép toàn bộ section/slot. Đây là đường duy nhất để "sửa" một template đang dùng.

9. `AssessmentService` (facade) thêm `getTemplateSpec(templatePublicId)` — trả cấu trúc slot + trọng số cho Phase 10 dùng.

10. Controller: `/api/admin/templates` (CRUD, activate, clone — platform), `GET /api/templates` (tenant, chỉ `ACTIVE`).

11. Endpoint kiểm khả thi: `GET /api/admin/templates/{id}/feasibility` — với mỗi slot, so `questionCount` với số câu SHARED hiện có của `taskType` đó. Trả danh sách slot thiếu. Đây là công cụ cho Admin biết template có sinh đề được không **trước khi** tenant tạo kỳ thi và gặp 422 ở Phase 10.

12. Test: template có Σ% = 90 → `activate()` trả 422.

13. Test: slot `WRITE_ESSAY` (WRITING) nằm dưới section SPEAKING → 422.

14. Test: template `ACTIVE` → sửa `questionCount` bị từ chối; clone ra `DRAFT` thì sửa được.

## Success Criteria

- Admin tạo được template đầy đủ 4 section với trọng số cộng bằng 100
- Template không hợp lệ không `ACTIVE` được, và thông báo nói đúng chỗ sai
- Template đang dùng không sửa được cấu trúc
- Tenant thấy danh sách template `ACTIVE`, không sửa được gì
- Endpoint feasibility chỉ ra đúng slot thiếu câu

## Quality and Testing State

- Quality gate: chưa chạy
- Testing: chưa bắt đầu

## Session Notes

_(trống)_
