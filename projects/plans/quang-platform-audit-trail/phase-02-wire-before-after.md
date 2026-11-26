# Phase 02: Ghi trước/sau cho các tài nguyên dùng chung

Repo: `pte-api`. Trạng thái: **xong (2026-11-25)**. Phụ thuộc: phase 01.

## Nguyên tắc

- Mỗi module có một snapshot record riêng, đặt cạnh service (ví dụ `itembank/internal/service/lifecycle/QuestionAuditState.java`),
  dựng từ entity bằng một factory tĩnh `of(entity)`. Không đưa entity vào `shared/audit`.
- Chụp `before` **trước** khi áp thay đổi, `after` sau khi `save`. Với tạo mới: `before = null`. Với xóa: `after = null`.
- Không ghi dòng khi trước và sau bằng nhau (lưu thừa), trừ thao tác đổi trạng thái.
- Giữ nguyên chuỗi `summary` hiện có (không đổi text hiển thị).

## Bảng việc

| Tài nguyên | Service | Thao tác chụp trước/sau | Field chụp |
|---|---|---|---|
| Câu hỏi (bản nháp) | `QuestionLifecycleService` | chỉ `update` của bản `DRAFT` (ai đổi gì trước khi gửi duyệt) | taskType, cefr, promptText, referenceAnswerText, correctAnswerText, min/maxWordCount, option (text, correct, orderIndex, blankIndex, correctGapIndex), audio/imagePromptRef (chỉ ref), answerHintVi/En |
| Template đề | `ExamDefinitionCommandService` | `createDraft`, `cloneToDraft`, `updateCefrTargets`, `updateTimeFrame`, `replaceItems`, `deleteDraft` | tên, timeframe, CEFR targets, item: taskTypeKey, section, sequence, min/maxCount, prep/responseSeconds, scoringMethod, 5 trọng số kỹ năng; rubricVersion. **Không** chụp các cột `runtime_*` (dẫn xuất từ runtime profile của task type, người dùng không sửa) |
| Blueprint | `BlueprintService` | `create`, `update` | cấu trúc section/item, tham số |
| Task type chuẩn | `StandardTaskTypeService` | `create`, `update`, `delete` | mã, tên, skill, cấu hình chấm, giới hạn |
| Task type động | `DynamicTaskTypeService` | `create`, `update` | như trên cộng schema màn hình |
| Governance task type | `TaskTypeGovernanceService` | các thao tác bật/tắt | trạng thái, phạm vi |
| Gói | `PlanService` | `create`, `update`, `activate`, `archive`, `deleteDraft` | tên, giá, thời hạn, giới hạn học viên/phiên, quyền lợi |

## Kết quả xác minh (2026-11-25)

**Revision câu hỏi đã có liên kết và bản cũ bất biến**, nên lịch sử nội dung đã publish **không cần audit trước/sau**:

- `Question` có `revisionGroupPublicId` (chung cho mọi bản), `revisionNumber`, `supersedesPublicId` (trỏ bản nguồn).
- `createRevision` sao chép bản `APPROVED`+`current` sang bản `DRAFT` mới; chỉ `DRAFT` sửa được (`update` chặn trạng thái khác).
- Khi publish (`QuestionApprovalService`), bản nguồn chuyển `ARCHIVED`, `current=false`, **nội dung giữ nguyên**.
- Hệ quả: diff "bản đang chạy so với bản trước" tính trực tiếp từ hai dòng `questions` cùng `revisionGroupPublicId`. Không ghi
  trước/sau cho `createRevision`/`publish` (trùng dữ liệu). Audit chỉ cần trước/sau cho `update` bản nháp.
- Việc mới (chuyển sang phase 04 phía API): endpoint `GET /api/v1/questions/{publicId}/revisions` trả chuỗi revision cùng nhóm
  (publicId, revisionNumber, status, current, author, thời điểm duyệt/publish), và web tự diff hai bản bằng chi tiết câu hỏi đã có.
  Repository hiện chỉ có `findByRevisionGroupPublicIdAndCurrentTrueAndPublicIdNot`; cần thêm truy vấn theo nhóm, sắp theo `revisionNumber`.

**Kích thước JSON không phải vấn đề** (đo DB local, 12 template, 244 câu hỏi):

| Đối tượng | Field nghiệp vụ | Ghi chú |
|---|---|---|
| Template 22–23 dạng bài | ~5,4 KB mỗi trạng thái | Nếu chụp cả cột `runtime_*`: ~23 KB, nên loại ra |
| Câu hỏi (text + option) | TB 0,7 KB, p95 1,9 KB, max 2,9 KB | |

- `before_state`/`after_state` là `jsonb` không giới hạn độ dài; PostgreSQL tự nén (TOAST) giá trị > 2 KB.
- Đặt `AuditLogConstants.STATE_MAX_CHARS = 65_536` làm **chốt an toàn**, không dự kiến dữ liệu thật chạm tới. Mỗi lần
  `replaceItems` thêm khoảng 11 KB trước khi nén, chấp nhận được với tần suất sửa template.
- `audit_logs` local hiện 612 dòng, 360 kB.

## Tiêu chí hoàn thành

- Mỗi service có test: dòng audit có `before_state`/`after_state` đúng field; tạo mới thì before null; không ghi khi không đổi.
- Test đảm bảo không có payload media hoặc text dài vượt giới hạn trong JSON.
- Toàn bộ `app` test suite xanh (hoặc báo rõ lỗi không liên quan).
