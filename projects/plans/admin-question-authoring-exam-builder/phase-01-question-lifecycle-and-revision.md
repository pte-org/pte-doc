# Phase 1: Question lifecycle, revision and validation backend

## Goal

Biến Question API từ create/list/lifecycle cơ bản thành authoring API có DRAFT thật, approval workflow, optimistic locking, revision cho bản đã APPROVED và validation đủ để frontend xây form theo từng task.

## Steps

1. Audit entity/repository/query hiện tại: `Question.java`, `QuestionOption.java`, `QuestionStatus.java`, `ItembankService.java`, `QuestionController.java`, `QuestionValidationHelper.java`, `OptionRequest.java` và `CreateQuestionRequest.java`.
2. Thêm revision metadata và Flyway migration: `revision_group_public_id`, `revision_number`, `supersedes_public_id`, `is_current`, optimistic-lock/version field nếu chưa có; backfill row hiện hữu và tạo unique partial index cho một current revision/group.
3. Đổi create mới thành `DRAFT`; không nhận status từ request.
4. Thêm `UpdateQuestionRequest` và `PUT` cho DRAFT; reject stale version bằng lỗi conflict rõ ràng.
5. Thêm endpoint tạo revision từ APPROVED; giữ source revision không đổi cho snapshot cũ. Draft clone là non-current để bản APPROVED cũ vẫn được generation chọn.
6. Mở rộng validation:
   - `minWordCount <= maxWordCount`;
   - số option và số đáp án đúng theo task;
   - order/blank/gap index hợp lệ;
   - task type và section khớp;
   - media ref tồn tại, đã complete và đúng kind;
   - không cho option field thừa hoặc thiếu theo task.
7. Bổ sung pagination/filter server-side và metadata endpoint `/question-types`.
8. Thêm transition `DRAFT → PENDING_APPROVAL` cho Author; Admin approve/reject với rejection reason.
9. Khi Admin approve revision, lock revision group, archive bản current cũ và promote bản mới trong cùng transaction; reject unarchive revision đã supersede.
10. Định nghĩa lỗi 400/404/409/422 thống nhất cho frontend.

## Design Constraints

- Không đổi `APPROVED` thành `PUBLISHED` trong phase này.
- Không tách mỗi PTE task thành một bảng riêng.
- Không mutate bản APPROVED tại chỗ.
- Các query random phải chỉ lấy bản APPROVED current; snapshot cũ vẫn đọc được source question cũ.
- Archive là soft delete; unarchive luôn về DRAFT.
- Author không được approve/publish; chỉ Platform Admin được approve/reject.
- Publish revision phải atomic và không được tạo hai current revision trong cùng một group.

## Files / ownership

- `pte-api/.../itembank/domain/Question.java`
- `pte-api/.../itembank/domain/QuestionOption.java`
- `pte-api/.../itembank/domain/enums/QuestionStatus.java`
- `pte-api/.../itembank/ItembankService.java`
- `pte-api/.../itembank/internal/controller/QuestionController.java`
- `pte-api/.../itembank/internal/service/QuestionValidationHelper.java`
- request/response DTOs, mapper, repository
- `pte-api/.../resources/db/migration/V{next}__question_revision.sql`

## Quality and Testing State

- Chưa chạy cho phase này.
- Theo quyết định hiện tại, không bắt buộc test/quality audit ở từng phase. Các test lifecycle, revision và permission được ghi lại làm checklist tùy chọn cho release.
- Preflight: backend compile passed at final gate; quality audit and tests skipped by user decision (`quality: skipped_by_user; decision: user_confirmed_skip`).

## Acceptance Criteria

- Create trả DRAFT và question DRAFT không được generation chọn.
- Update DRAFT thành công; stale version trả 409.
- Edit APPROVED tạo public ID/revision mới ở DRAFT; bản cũ vẫn dùng được cho snapshot hiện hữu.
- Author submit chuyển DRAFT thành PENDING_APPROVAL; Admin approve chuyển thành APPROVED, reject trả về DRAFT kèm lý do.
- Approve revision mới chỉ đổi current revision sau khi toàn bộ validation pass.
- Archive/unarchive không hard-delete dữ liệu.
- API list filter được task type/status/search/page/size.
