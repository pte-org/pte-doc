# Phase 4: Assessment blueprint, template ordering and approval API

## Goal

Cung cấp HTTP contract cho vendor tạo/chỉnh sửa curated blueprint theo PTE template, có thứ tự mặc định, filter question và approval workflow; đồng thời giữ random generation cho host.

## Steps

1. Tách template ordering trong `ScoreTemplateService`/assessment thành component dùng chung: section order → template sequence → task type → item order.
2. Thêm curated blueprint request/response: name, template version, sections, ordered items và status.
3. Thêm blueprint CRUD cho Platform Admin/Author; DRAFT mới được sửa item/name.
4. Thêm filter question API cho blueprint picker: section, task type, status, keyword và metadata đã lưu; chỉ trả APPROVED current questions cho selection.
5. Thêm workflow `DRAFT → PENDING_APPROVAL → PUBLISHED`; Author submit, Admin approve/reject. Approve validate question status, section/task match, duplicates, order and template compliance rồi publish immutable snapshot.
6. Tách requirement calculation trong `ExamGenerationService` thành component dùng chung cho random preview/generate.
7. Giữ random generate atomic: validate skills → load active template → calculate/roll requirements → check stock → draw → create blueprint → publish snapshot.
8. Trả lỗi shortage có task type, required, available; không tạo blueprint/snapshot dở dang.
9. Lưu random seed hoặc generation metadata để audit/reproduce; không expose seed cho host/student.
10. Bổ sung list/detail DTO an toàn cho blueprint/snapshot và snapshot version uniqueness/transaction guard.

## Design Constraints

- Không cho vendor gọi `POST /api/v1/sessions` như một shortcut; session vẫn thuộc host + subscription.
- Không cho generation lấy DRAFT/ARCHIVED/non-current question.
- Curated blueprint mặc định bám ACTIVE PTE template; thay đổi thứ tự thủ công phải được lưu rõ trong DRAFT.
- Preview random chỉ báo availability; không hứa danh sách câu cuối cùng nếu generation vẫn random tại command time.
- Snapshot publish là immutable; chỉnh criteria phải generate/regenerate snapshot mới.
- Author không có approve/publish permission.

## Files / ownership

- `pte-api/.../assessment/internal/service/ExamGenerationService.java`
- new generation controller, request/response DTOs
- `BlueprintController.java`, `SnapshotController.java`, `BlueprintService.java`
- `SnapshotPublishService.java`, `ExamBlueprint.java`, `ExamSnapshot.java`
- score-template/assessment repositories and migration for blueprint approval/seed/version constraints
- API client assessment requests/types

## Quality and Testing State

- Chưa chạy cho phase này.
- Theo quyết định hiện tại, không bắt buộc test/quality audit ở từng phase. Template ordering, approval permission, shortage và snapshot immutability được ghi lại làm checklist tùy chọn.
- Preflight: backend compile passed at final gate; quality audit and tests skipped by user decision (`quality: skipped_by_user; decision: user_confirmed_skip`).

## Acceptance Criteria

- Vendor có filter question bank và tạo/chỉnh sửa blueprint DRAFT theo thứ tự mặc định của PTE template.
- Author submit được blueprint nhưng không approve/publish được.
- Admin approve/reject được blueprint; approve trả blueprint ID, snapshot ID, template version và safe item summary.
- Random generation vẫn có preview availability và shortage theo task type.
- Generation thiếu stock trả lỗi có cấu trúc, không sinh dữ liệu một phần.
- Snapshot cũ không đổi khi question hoặc template thay đổi.
- Platform Author dùng được endpoint; tenant roles bị deny.
