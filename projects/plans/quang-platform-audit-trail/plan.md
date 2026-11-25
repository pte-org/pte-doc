# Plan: Lịch sử thao tác nền tảng (trước/sau, tra theo người, tab Lịch sử)

Ngày: 2026-11-25. Tác giả: quang. Trạng thái: **xong (2026-11-25)**; báo cáo `pte-doc/plans/reports/261125-platform-audit-trail-verification.md`.

## Bối cảnh

Nhân sự nền tảng (PLATFORM_MANAGER, ACADEMIC_MANAGER, ACADEMIC_STAFF) sửa tài nguyên dùng chung cho mọi tenant: câu hỏi,
template đề, task type, blueprint, gói. Một thao tác sai có thể lan sang tất cả khách hàng ở lần publish kế tiếp. Cần trả lời
nhanh ba câu: **ai** sửa, sửa **từ gì thành gì**, và **người X đã sửa những gì**.

## Hiện trạng đã đọc (2026-11-25)

- Bảng `audit_logs` đã có `actor_user_id`, `actor_role`, `aggregate_type/id`, `resource_name/code`, `action`, `summary`,
  `request_public_id`, **`before_state`, `after_state`**. Không cần migration.
- Hai bộ ghi: `AuditLogService.record(...)` (chỉ summary) và `AuditLogChangeWriter.record(caller, AuditChange)` (có trước/sau).
  Các service bên dưới hiện chỉ dùng `AuditLogService`, nên trước/sau đang trống:
  - `QuestionLifecycleService` (update, createRevision, submit/approve/reject/publish/archive/unarchive)
  - `ExamDefinitionCommandService` (createDraft, cloneToDraft, updateCefrTargets, updateTimeFrame, replaceItems, deleteDraft)
  - `BlueprintService`, `DynamicTaskTypeService`, `StandardTaskTypeService`, `TaskTypeGovernanceService`, `PlanService`
- `AuditLogResponse` **không** trả `before_state/after_state`. `GET /api/v1/platform/audit-logs` lọc theo
  `aggregateType`, `search`, `createdFrom/To`; **không** có lọc theo người hay theo một đối tượng cụ thể.
- Vendor-web đã có `/admin/audit-log` (`PlatformAuditLogView`), trang chi tiết `/admin/questions/[publicId]` và
  `/admin/exam-template/[publicId]`; màn `/admin/platform-users` có menu ba chấm.
- Câu hỏi đã publish **không sửa tại chỗ**: `createRevision` tạo bản nháp mới (`supersedesPublicId`, `revisionGroupPublicId`,
  `revisionNumber`), đi qua duyệt rồi publish; bản cũ chuyển `ARCHIVED`, nội dung giữ nguyên. Vì vậy lịch sử nội dung câu hỏi
  đã publish lấy từ chuỗi revision, audit trước/sau chỉ cần cho sửa bản nháp (chi tiết: phase 02, "Kết quả xác minh").
- Kích thước đo thực tế: template 22 dạng bài ~5,4 KB, câu hỏi tối đa ~2,9 KB mỗi trạng thái; cột `jsonb` có nén TOAST.
- Đề đã phát dùng snapshot (`SnapshotPublishService`), nên sửa sai không làm hỏng ngay kỳ thi đang chạy.

## Ngoài phạm vi

- Prompt AI (đã có phiên bản bất biến), rubric (bảng `scoring_rubric_activation_audits`), platform settings (summary đã ghi từ/đến).
- Template của host (`HostExamTemplateService`, dữ liệu một tenant). Có thể làm tiếp theo cùng mẫu sau khi xong plan này.
- Khôi phục tự động từ `before_state`. Plan chỉ cung cấp dữ liệu để người khôi phục thủ công.
- Phiên bản hóa câu hỏi kiểu prompt.

## Quyết định

1. **Dùng lại `audit_logs` và `AuditLogChangeWriter`**, không thêm bảng. Mỗi lần ghi là một dòng có trước/sau.
2. **Chỉ chụp field nghiệp vụ** qua một snapshot record riêng cho từng loại tài nguyên (ví dụ `QuestionAuditState`):
   nội dung, option, đáp án, cấu trúc, tham số. Media chỉ lưu `publicId`/URL, không lưu payload. Giới hạn kích thước JSON
   (hằng số trong `AuditLogConstants`); vượt ngưỡng thì cắt và đánh dấu `truncated: true`.
3. **Thứ tự key ổn định** (Jackson `ORDER_MAP_ENTRIES_BY_KEYS`, list giữ thứ tự `orderIndex`) để diff ở web không nhiễu.
4. Bản ghi audit nằm **trong cùng transaction** với thay đổi (giống hiện tại); lỗi serialize không được làm hỏng thao tác chính:
   ghi `summary` và để trống trước/sau, kèm log WARN.
5. Danh sách audit **không** trả trước/sau (giữ response nhẹ); thêm endpoint chi tiết một dòng.
6. Quyền đọc giữ nguyên `PLATFORM_ADMIN`, `PLATFORM_MANAGER`. Tab Lịch sử trên câu hỏi/template dùng cùng quyền; vai trò khác
   không thấy tab (không 403 giữa màn).

## Các phase

| # | Phase | Repo | Phụ thuộc |
|---|---|---|---|
| 01 | [Hạ tầng chụp trạng thái và API đọc](phase-01-audit-state-infrastructure.md) | pte-api | |
| 02 | [Ghi trước/sau cho câu hỏi, template, task type, blueprint, gói](phase-02-wire-before-after.md) | pte-api | 01 |
| 03 | [Lọc theo người ở màn audit và lối vào từ màn nhân sự](phase-03-actor-filter-web.md) | pte-web | 01 |
| 04 | [Tab Lịch sử trên chi tiết câu hỏi và template](phase-04-history-tab-diff.md) | pte-web | 01, 02 |
| 05 | [Kiểm thử, kiểm tra và báo cáo](phase-05-verification.md) | cả hai | 01–04 |

Phase 02 và 03 có thể chạy song song sau khi 01 xong.

## Rủi ro

- **Dung lượng bảng** tăng do JSON trước/sau (câu hỏi sửa nhiều lần). Giảm bằng giới hạn kích thước và chỉ field nghiệp vụ;
  theo dõi kích thước `audit_logs` sau một tuần chạy thật.
- **Lộ đáp án**: `before_state` chứa đáp án đúng. Endpoint chi tiết chỉ dành cho vai trò nền tảng; không đưa vào audit của tenant
  (`/api/v1/audit-logs`) và không đưa vào `recent()` của dashboard host.
- **Ratchet kiến trúc**: file ≤ 300 dòng, package `internal/**` ≤ 15 class. Snapshot record đặt cạnh service của từng module,
  không dồn vào `shared/audit`.
- **Ranh giới module**: `shared/audit` không được phụ thuộc entity của module khác; module tự dựng snapshot rồi đưa JSON
  (hoặc object) vào `AuditChange`.

## Tài liệu bắt buộc khi thực hiện

- `docs/CODING_STANDARDS_API.md`, `docs/API_RESPONSE_SETUP.md`, `docs/COMMON_EXCEPTION_SETUP.md` (phase 01, 02).
- `docs/CODING_STANDARDS_WEB.md` (phase 03, 04).
- `docs/TEST_SCENARIOS_IAM.md` (phase 01: quyền đọc audit).
