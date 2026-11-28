# Phase 2: WF-01 chuẩn bị tài nguyên

**Owner gợi ý:** Quang (câu hỏi, validator); Phát (exam definition RF-19, Host template) · **Ưu tiên:** P1 (FR-05, FR-06), P2 (validator, remove-only) · **Phụ thuộc:** phase 01

## Overview

Exam definition có dấu "đã duyệt" thật (`approvedAt/approvedBy`), mất khi sửa, bắt buộc khi activate, RETIRED không activate lại. Action `PUBLISH` câu hỏi không còn bỏ qua kiểm tra CEFR. Câu viết tay được kiểm số đáp án/ô trống như câu AI, và Host không tăng được số câu hoặc thời gian của template.

## Spec stories covered

- P1: activate template DRAFT chưa duyệt trả 409 (FR-05, RF-19, 1-1, 1-2).
- P1: tự duyệt template (phần template của FR-04).
- P1: PUBLISH chạy cùng bộ kiểm tra submitApproval (FR-06, 1-4).
- P2: validator option/blank count cho câu viết tay (RF-08, 1-5).
- P2: Host template remove-only cho count/timing (1-7).

## Files to modify/create

Đọc trước: `docs/CODING_STANDARDS_API.md`, `docs/API_RESPONSE_SETUP.md`, `docs/COMMON_EXCEPTION_SETUP.md`. Đường dẫn dưới `pte-api/app/src/main/`:

- `resources/db/migration/V61__exam_definition_approval_marks.sql` — tạo mới (kiểm lại số tiếp theo): cột `approved_at`, `approved_by` trên bảng exam definitions; backfill các template đang ACTIVE hoặc RETIRED là đã duyệt (để không khóa dữ liệu prod). Xác minh tên bảng và entity trong `assessment/domain`.
- `java/com/pte/assessment/domain/` — entity exam definition thêm hai trường (xác minh tên lớp).
- `java/com/pte/assessment/internal/service/definition/ExamDefinitionApprovalWorkflow.java` — set dấu khi approve; `requireActivatable` (khoảng dòng 173-178) yêu cầu đã duyệt và chặn RETIRED; chặn tự duyệt kể cả Admin.
- `java/com/pte/assessment/internal/service/definition/ExamDefinitionCommandService.java` — xóa dấu duyệt khi sửa nội dung (xác minh tên phương thức update).
- `java/com/pte/assessment/internal/service/definition/ExamDefinitionActivationValidator.java` — thêm kiểm tra đã duyệt nếu hợp với chỗ đặt hiện tại.
- `java/com/pte/assessment/internal/service/definition/HostExamTemplateService.java` (dòng 161, 191) — chỉ cho giảm số câu và thời gian, từ chối tăng.
- `java/com/pte/assessment/internal/constant/*Constants.java` — mã lỗi mới (ví dụ chưa duyệt, RETIRED không activate lại, tăng vượt template).
- `java/com/pte/itembank/internal/service/lifecycle/QuestionApprovalService.java` (dòng 106-128) — nhánh `PUBLISH` gọi cùng kiểm tra như submitApproval (CEFR) hoặc gỡ nhánh nếu không có UI dùng.
- `java/com/pte/itembank/internal/service/QuestionValidationHelper.java` (dòng 81-101) — áp dụng kiểm tra cho câu viết tay.
- `java/com/pte/itembank/internal/generation/validate/ChoiceValidator.java`, `BlankFillValidator.java` — tái dùng logic; không chép. Nếu cần, rút phần dùng chung ra lớp nhỏ trong cùng package, tránh vượt 15 lớp.
- `java/com/pte/itembank/internal/service/lifecycle/QuestionCreationService.java` — gọi validator ở lúc tạo/sửa (dòng 101 là điểm validation hiện tại).
- Web: `pte-web/apps/tenant-web` (màn Host template) và `pte-web/apps/vendor-web` (màn template) — hiển thị trạng thái "đã duyệt" và thông điệp lỗi mới, chỉ nếu cần (xác minh thư mục feature bằng Glob khi làm).

## Implementation steps

1. Thêm migration additive cho dấu duyệt kèm backfill an toàn cho template đã ACTIVE/RETIRED.
2. Ghi dấu duyệt khi approve, xóa khi sửa; activate yêu cầu dấu còn hiệu lực; RETIRED trả 409 khi activate lại.
3. Áp dụng chặn tự duyệt (kể cả Admin) cho template, dùng chung chính sách ở phase 01.
4. Cho nhánh PUBLISH câu hỏi đi qua cùng bộ kiểm tra như submitApproval, gồm CEFR cho kênh Exam; hoặc gỡ nhánh nếu xác nhận không ai gọi.
5. Rút logic kiểm số đáp án và số ô trống từ validator sinh AI thành thành phần dùng chung, áp dụng cho câu viết tay; thông điệp lỗi chỉ ra field.
6. Host template: từ chối tăng số câu và thời gian task type, chỉ cho bớt; vẫn chặn thêm task type.
7. Cập nhật UI hiển thị lý do lỗi nếu API trả mã mới; map tên hiển thị cho DS-01d (`DESCRIBE_IMAGE`), mục thấp, làm nếu rẻ.

## Tests

Dưới `pte-api/app/src/test/java/com/pte/`:
- Tạo `assessment/internal/service/definition/ExamDefinitionApprovalWorkflowTest` (chưa có): DRAFT chưa duyệt activate trả 409; duyệt xong activate được; sửa xong mất dấu; RETIRED không activate; Admin tác giả bị chặn.
- Mở rộng `assessment/internal/service/HostExamTemplateServiceTest.java` — tăng count/timing bị từ chối, giảm được.
- Tạo/mở rộng test `QuestionApprovalService` (tìm test hiện có trong `itembank/`): PUBLISH thiếu CEFR bị chặn.
- Mở rộng test validator sinh AI (`itembank/internal/generation/validate/`) và test `QuestionValidationHelper`: MC-Single 2 đáp án, MC-Multiple 1 đáp án, số ô trống.
- Test migration: kiểm backfill bằng test Postgres IT hiện có (cần `lifecycle.test.db.url`, xem AGENTS.md).

## Design Constraints

- Migration additive V61+; kiểm số cao nhất hiện tại (V60) trước khi đặt tên, setting mới (nếu có) seed cùng migration.
- Backfill không được khóa template đang chạy trên prod.
- Thông điệp và mã lỗi trong `*Constants.java` của module sở hữu; giữ envelope/mã lỗi cũ.
- Cross-module chỉ qua public service API (itembank và assessment không chọc internals của nhau).
- File ≤ 300 dòng, `internal/**` ≤ 15 lớp (ratchet architecture); `ExamDefinitionApprovalWorkflow` và `QuestionApprovalService` cần theo dõi dòng.
- `Clock` inject cho `approvedAt`.
- Không phá hành vi validator của draft AI khi tái dùng.
- Restart docker app local sau backend, và áp migration bằng tay nếu profile `local-schema` bỏ qua Flyway.

## Risks

- Backfill sai làm template prod đang ACTIVE bị coi là chưa duyệt: dùng backfill cho mọi trạng thái từng ACTIVE và test.
- Validator mới làm hỏng import/seed câu hỏi cũ: chỉ áp dụng khi tạo/sửa, không quét dữ liệu cũ.
- Gỡ PUBLISH làm gãy client: grep web/app trước khi quyết định gỡ hay chặn.

## Quality and Testing State

- Quality gate: skipped_by_user (user_confirmed_skip)
- Testing: passed (tdd green 2026-11-28; ExamDefinitionAdminServiceTest fixtures updated to approved contract)

## Todo

- [ ] Kiểm số migration tiếp theo và viết V61 + backfill
- [ ] Entity, workflow approve/edit/activate, constants
- [ ] PUBLISH vs submitApproval (CEFR)
- [ ] Validator option/blank cho câu viết tay (tái dùng, không chép)
- [ ] Host template remove-only
- [ ] UI thông điệp (nếu cần) + tsc/eslint/vitest cho app web đã đụng
- [ ] Test mới/mở rộng, ratchet architecture, restart docker, thử curl 1-1, 1-2, 1-4

## Bổ sung sau red-team (2026-11-27)

- **[M3] PUBLISH đang được UI dùng** (`vendor-web/features/questionbank/constants.ts:33` `ROW_PUBLISH`). **Không gỡ.** Cho nhánh
  PUBLISH chạy cùng bộ kiểm tra như submitApproval (CEFR cho kênh Exam, validation đầy đủ, chặn tự duyệt).
- **[H2] Activate yêu cầu duyệt làm đổi luồng đang chạy.** DS-01a phải đi đủ: Staff tạo → submit → M1 approve → M1 activate.
  Phase 08 thêm bước tập dượt. Backfill: các template ACTIVE/RETIRED hiện có được set `approved_at = updated_at` (hoặc `now()`),
  `approved_by` **được phép NULL** (ghi rõ trong migration comment).
- **[H2] RETIRED không activate lại:** trước khi chặn, grep vendor-web/tenant-web xem có nút "activate lại" cho RETIRED không.
  Đường rollback được ghi trong tài liệu là clone thành DRAFT → duyệt → activate. Nếu UI đang dùng re-activate và không kịp làm clone,
  giữ re-activate nhưng yêu cầu `approved_at` còn hiệu lực (ghi NOTED).
