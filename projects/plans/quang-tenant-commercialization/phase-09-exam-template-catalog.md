# Phase 9: Catalog template đề

## Requirements

`ExamTemplate` — bản đặc tả cấu trúc đề: mỗi phần thi chiếm bao nhiêu % điểm, và mỗi loại task cần bao nhiêu câu. Do **Admin nền tảng** tạo, tenant chỉ chọn khi tạo kỳ thi.

Maps to: **[ADR-006](../../architecture/ADR-006-commercialization-and-exam-templates.md) §5**

## Design Constraints

Preflight: follow the existing assessment aggregate/mapper/repository conventions; keep template persistence and controllers under assessment internals, expose Phase 10 access only through `AssessmentService`, call itembank only through `ItembankService`, guard platform writes with method security, and represent user-facing domain failures through `AssessmentConstants`/`DomainException`. Drafts may be structurally incomplete, activation is the aggregate validation boundary, and active structure is immutable unless cloned.

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

## Files

- `pte-api/app/src/main/java/com/pte/assessment/AssessmentService.java`
- `pte-api/app/src/main/java/com/pte/assessment/domain/ExamTemplate.java`
- `pte-api/app/src/main/java/com/pte/assessment/domain/TemplateSection.java`
- `pte-api/app/src/main/java/com/pte/assessment/domain/TemplateSlot.java`
- `pte-api/app/src/main/java/com/pte/assessment/domain/enums/TemplateStatus.java`
- `pte-api/app/src/main/java/com/pte/assessment/dto/response/TemplateSpec.java`
- `pte-api/app/src/main/java/com/pte/assessment/internal/constant/AssessmentConstants.java`
- `pte-api/app/src/main/java/com/pte/assessment/internal/controller/TemplateAdminController.java`
- `pte-api/app/src/main/java/com/pte/assessment/internal/controller/TemplateController.java`
- `pte-api/app/src/main/java/com/pte/assessment/internal/dto/request/TemplateRequest.java`
- `pte-api/app/src/main/java/com/pte/assessment/internal/dto/request/TemplateSectionRequest.java`
- `pte-api/app/src/main/java/com/pte/assessment/internal/dto/request/TemplateSlotRequest.java`
- `pte-api/app/src/main/java/com/pte/assessment/internal/dto/response/TemplateFeasibilityResponse.java`
- `pte-api/app/src/main/java/com/pte/assessment/internal/dto/response/TemplateResponse.java`
- `pte-api/app/src/main/java/com/pte/assessment/internal/exception/TemplateNotFoundException.java`
- `pte-api/app/src/main/java/com/pte/assessment/internal/exception/TemplateStateException.java`
- `pte-api/app/src/main/java/com/pte/assessment/internal/exception/TemplateValidationException.java`
- `pte-api/app/src/main/java/com/pte/assessment/internal/mapper/TemplateMapper.java`
- `pte-api/app/src/main/java/com/pte/assessment/internal/repository/ExamTemplateRepository.java`
- `pte-api/app/src/main/java/com/pte/assessment/internal/service/TemplateService.java`
- `pte-api/app/src/main/java/com/pte/itembank/ItembankService.java`
- `pte-api/app/src/main/java/com/pte/itembank/internal/repository/QuestionRepository.java`
- `pte-api/app/src/main/resources/db/migration/V21__assessment_exam_template.sql`
- `pte-api/app/src/test/java/com/pte/assessment/internal/service/TemplateServiceTest.java`
- `pte-api/app/src/test/java/com/pte/itembank/ItembankServiceTest.java`

## Quality and Testing State

- Decision checkpoint: unit tests = yes; quality gate = yes (user confirmed).

- Quality gate: **approved**, 0 blocking/advisory/noted findings. Manual review covered platform ownership and method-security guards, assessment-to-itembank public boundary, active-template immutability locking, transaction scope, FK/index/check constraints, and draft-vs-activation validation. Cryptographic receipt skipped because this report is in `pte-doc` while source files live in the separate `pte-api` repository.
- Testing result: **passed**, `559` tests, `0` failures, `0` errors, `0` skipped. Focused Phase 9 scope: `18` tests. Report: `tests/phase-09-exam-template-catalog-test-report.json`.

## Session Notes

- Added platform-owned `ExamTemplate`/`TemplateSection`/`TemplateSlot` catalog with V21 migration, admin lifecycle endpoints, tenant active-only listing, active structure locking with clone-to-draft editing, Phase 10 `AssessmentService` spec facade, and SHARED question feasibility checks.
- Added focused validation and feasibility tests, then completed the full app regression suite after adding pessimistic locks for lifecycle mutations.
