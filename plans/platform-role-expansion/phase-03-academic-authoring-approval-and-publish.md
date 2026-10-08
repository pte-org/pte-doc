# Phase 3: Academic authoring, approval và publish boundaries

## Goal

Chuyển ownership của Question Bank, task/question type, score template và curated blueprint từ mô hình `PLATFORM_AUTHOR`/admin sang workflow `ACADEMIC_STAFF` draft → `ACADEMIC_MANAGER` review/approve/publish, vẫn giữ `PLATFORM_ADMIN` override và không làm trôi snapshot/runtime contract.

## Stories covered

- P1 Academic governance
- P1 Academic authoring
- P1 Tenant administration (chỉ consume published resources)

## Steps

1. Tạo academic capability policy dùng shared role contract nhưng để mỗi module giữ lifecycle invariant riêng: draft write, submit, review, approve, reject, publish/activate, read published.
2. Bổ sung `authorUserPublicId`/creator metadata (nullable cho legacy rows) và version/ownership mapping cần thiết cho `Question`, `QuestionTypeDefinition`, `ScoreTemplate`, `ExamBlueprint` hoặc aggregate tương đương.
3. Tạo migration mới cho ownership/lifecycle metadata; backfill resource cũ theo quy tắc legacy (`PLATFORM_ADMIN` override, không cho `ACADEMIC_MANAGER` tự nhận quyền approve resource không có owner rõ ràng).
4. Question Bank:
   - `ACADEMIC_STAFF` tạo/sửa/import media/submit draft;
   - `ACADEMIC_MANAGER` approve/reject/publish bản của staff khác;
   - `PLATFORM_ADMIN` giữ override;
   - revision, archive, unarchive, media completion và question validation hiện có vẫn giữ nguyên.
5. Task type/question type catalog:
   - chuẩn hóa legacy `/question-types` và canonical `/task-types` trên cùng policy;
   - custom definition mới đi qua DRAFT → PENDING_APPROVAL → APPROVED/ACTIVE hoặc lifecycle tương thích;
   - standard active rows và runtime-locked fields không bị mutate in-place;
   - approve/publish/retire có audit và không phá `TaskRuntimeContract`/`TaskRuntimeProfile`.
6. Score template:
   - cho staff/manager tạo và chỉnh draft;
   - manager approve và activate/publish version đã được kiểm tra;
   - admin override;
   - active/retired rows immutable, score policy thay đổi qua version mới.
7. Blueprint/question-template:
   - staff/manager tạo/sửa/submit draft;
   - manager approve để publish snapshot theo lifecycle hiện có;
   - snapshot remains write-once và không lộ answer key;
   - host chỉ dùng active/published template/snapshot theo endpoint hiện có.
8. Chặn self-approval server-side: academic manager không approve/publish aggregate có `authorUserPublicId` của chính mình; admin override nếu cần phải audit rõ actor/action/reason theo contract.
9. Mở rộng `AuditLogService` calls cho create/update/submit/reject/approve/publish/activate/retire và authorization failure; thay literal authorization messages bằng module constants.
10. Cập nhật controller security tests và service tests cho từng aggregate, bao gồm gọi API trực tiếp với role sai và legacy token.

## Design Constraints

- Không đổi `APPROVED` thành `PUBLISHED` nếu contract/runtime hiện tại đang dùng `APPROVED`; map nhãn UI riêng.
- Không dùng audit log như ownership check duy nhất; creator/author phải được lưu trên aggregate hoặc revision.
- Không cho academic staff sửa active/approved runtime contract hoặc question in-place; dùng version/revision transition hiện có.
- Không thêm một bảng workflow generic nếu các aggregate đã có lifecycle khác nhau; dùng shared authorization policy + domain-specific transition service.
- `QuestionTypeDefinition.active` tiếp tục là availability projection; không dùng nó để thay thế toàn bộ approval state nếu làm mất tương thích runtime.
- `ACADEMIC_MANAGER` không được truy cập billing/tenant security chỉ vì có quyền academic publish.
- Media upload/complete/preview phải dùng policy academic scope và ownership hiện có; không mở Cloudinary asset của user khác.

## Files / ownership

- `pte-api/.../itembank/internal/controller/QuestionController.java`
- `pte-api/.../itembank/internal/controller/TaskTypeController.java`
- `pte-api/.../itembank/internal/controller/QuestionTypeController.java`
- `pte-api/.../itembank/ItembankService.java`
- `pte-api/.../itembank/QuestionTypeService.java`
- `pte-api/.../itembank/internal/service/ItembankAccessPolicy.java`
- `pte-api/.../itembank/internal/service/QuestionDeletionService.java`
- `pte-api/.../assessment/internal/controller/BlueprintController.java`
- `pte-api/.../assessment/internal/controller/SnapshotController.java`
- `pte-api/.../assessment/internal/service/AssessmentAccessPolicy.java`
- `pte-api/.../assessment/internal/service/BlueprintService.java`
- `pte-api/.../scoretemplate/internal/controller/ScoreTemplateController.java`
- `pte-api/.../scoretemplate/internal/service/ScoreTemplateAdminService.java`
- academic entities, repositories, mappers, constants, Flyway migrations and tests
- media authoring policy/service if it currently checks author role directly

## Quality and Testing State

- Quality: APPROVED — `quality/phase-03-academic-authoring-approval-and-publish-quality-report.json`; receipt verified at `quality/phase-03-academic-authoring-approval-and-publish-receipt.json`.
- Testing: PASSED — 96 focused backend tests, 0 failures/errors/skips; clean compile passed for 1069 source files. Evidence: `tests/phase-03-academic-authoring-approval-and-publish-test-report.json`.
- Deferred validation: live PostgreSQL/Flyway execution, HTTP authorization through a running deployment, browser/FE integration, and full seed regression remain for later phases.

## Acceptance Criteria

- Staff tạo/import/sửa draft và submit được tất cả academic aggregate trong scope.
- Staff gọi trực tiếp approve/publish/activate đều nhận 403.
- Academic manager approve/publish được draft của staff khác; self-approval bị từ chối.
- Admin giữ được override và tất cả thao tác có audit.
- Legacy author accounts vẫn author được trong compatibility window qua capability canonical.
- Task type runtime lock, question revision, score-template active uniqueness và snapshot immutability không bị phá.
- Host chỉ đọc/sử dụng resource published/active; không nhìn thấy draft hoặc answer key ngoài boundary hiện tại.
- Các literal “Only platform admins/authors…” được thay bằng centralized constant/error contract trong phần đã chạm tới.
