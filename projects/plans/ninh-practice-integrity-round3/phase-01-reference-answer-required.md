# Phase 1: Bắt buộc transcript cho RE_TELL_LECTURE, SUMMARIZE_SPOKEN_TEXT, SUMMARIZE_GROUP_DISCUSSION

Status: Completed

## Requirements

- Tạo hoặc sửa câu hỏi ba dạng trên mà thiếu `referenceAnswerText` thì bị từ chối (`REFERENCE_ANSWER_REQUIRED`).
- Editor vendor-web bắt nhập "Audio transcript" cho ba dạng này và hiện thông báo đúng (không nhắc "Repeat Sentence").
- Cờ trong bảng `question_types` của các DB đã chạy được bật bằng migration, DB mới (dev-seed) có giá trị đúng ngay.

## Design Constraints

- Enum `PteTaskType.requiresReferenceAnswer()` là nguồn chuẩn; migration chỉ đồng bộ dữ liệu đã seed.
- Migration `V42` chỉ `UPDATE` cờ, idempotent, không đổi cấu trúc bảng; không sửa migration cũ (check-migrations).
- Câu đã lưu thiếu transcript không bị quét lại hay xóa.

## Related files

- `pte-api/app/src/main/java/com/pte/itembank/domain/enums/PteTaskType.java`
- `pte-api/app/src/main/resources/db/migration/V52__require_reference_answer_for_ai_listening_tasks.sql` (mới)
- `pte-api/app/src/main/resources/db/dev-seed/010-reference-data.sql`
- `pte-api/app/src/test/java/com/pte/itembank/TaskRuntimeContractDescriptorTest.java`
- `pte-web/apps/vendor-web/features/questionbank/constants.ts`

## Steps

1. `requiresReferenceAnswer()` trả `true` cho bốn task type.
2. Migration `V42`: `UPDATE question_types SET requires_reference_answer = true WHERE task_type_key IN (...)`.
3. Dev-seed: đổi cờ cuối của ba dòng tương ứng thành `true`.
4. Đổi thông báo `REFERENCE_ANSWER_REQUIRED` ở editor thành chung cho mọi dạng.
5. Test enum và `authoringRequirementsFor` cho cả bốn dạng.

## Quality/Testing State

- Test đơn vị mở rộng ở `TaskRuntimeContractDescriptorTest`.
