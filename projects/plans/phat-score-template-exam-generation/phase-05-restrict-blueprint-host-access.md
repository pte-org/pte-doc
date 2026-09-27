# Phase 5: Assessment — Khóa luồng blueprint thủ công khỏi vai trò host

Covers phần còn lại của FR-15 ("bỏ hẳn luồng cũ phía host: tạo blueprint soạn tay"). **Không xóa** `BlueprintController`/`SnapshotController`/`BlueprintService` — `vendor-web` `/admin/exams` (ngoài phạm vi Plan B) vẫn dùng blueprint cho quy trình platform riêng; phase này chỉ rút quyền HOST khỏi 2 controller. `QuestionController` (câu hỏi thô, không phải blueprint) đã được khóa quyền tương tự ở **Phase 1** (quyết định "chỉ platform thao tác question bank", 2026-09-17) — phase này chỉ xử lý tầng blueprint/snapshot, nhưng bước grep-verify dưới đây xác nhận cả hai thay đổi cùng an toàn.

## Requirements

Host (`HOST_ADMIN`/`HOST_AUTHOR`) không còn gọi được API blueprint thủ công (`POST /blueprints`, `GET /blueprints`, `GET /blueprints/{id}`, `POST /blueprints/{id}/publish`, `GET /snapshots/{id}`) — chỉ `PLATFORM_ADMIN`/`PLATFORM_AUTHOR` còn quyền; luồng tạo-kỳ-thi-theo-skill (Phase 2/3) không đi qua 2 controller này nên không bị ảnh hưởng.

## Files

**Sửa**
- `pte-api/app/src/main/java/com/pte/assessment/internal/controller/BlueprintController.java` — `@PreAuthorize` cấp lớp rút còn `hasAnyRole('PLATFORM_ADMIN','PLATFORM_AUTHOR')`.
- `pte-api/app/src/main/java/com/pte/assessment/internal/controller/SnapshotController.java` — tương tự.

## Steps

1. Grep toàn repo (`pte-api`, `pte-web`, `pte-app`) tìm mọi lời gọi tới `/blueprints`/`/snapshots` **và** `/questions` để xác nhận không còn UI host nào (tenant-web sau Phase 7, pte-app sau Phase 8 xóa `features/authoring`) gọi 3 nhóm endpoint này — nếu còn, phase này (và việc Phase 1 đã khóa `QuestionController`) phải chờ Phase 7/8 xong trước khi merge/deploy.
2. Đổi `@PreAuthorize` cấp lớp của `BlueprintController` và `SnapshotController` từ 4 role xuống còn 2 role platform.
3. Xác nhận `AssessmentService.getSummary()`/`getFullContent()` (dùng nội bộ bởi `session`/`attempt`, gọi in-process không qua HTTP/`@PreAuthorize`) không bị ảnh hưởng — 2 method này không nằm trong 2 controller trên.
4. Chạy lại test controller hiện có (nếu có `@WebMvcTest`/security test cho 2 controller) và cập nhật kỳ vọng role.

## Tests

- Test security cho `BlueprintController`/`SnapshotController` (thêm mới nếu chưa có, theo mẫu `ScoreTemplateControllerSecurityTest` của Plan A):
  - `hostAdmin_callsBlueprintEndpoints_forbidden`.
  - `hostAuthor_callsSnapshotPublish_forbidden`.
  - `platformAdmin_callsBlueprintEndpoints_allowed`.
  - `platformAuthor_callsSnapshotPublish_allowed`.
- `mvn test -pl app` xanh.

## Success Criteria

- Gọi `POST /blueprints` (hoặc bất kỳ endpoint nào của 2 controller) bằng JWT role `HOST_ADMIN`/`HOST_AUTHOR` trả 403.
- Gọi cùng endpoint bằng `PLATFORM_ADMIN`/`PLATFORM_AUTHOR` vẫn thành công như trước.
- Luồng tạo-kỳ-thi-theo-skill (Phase 2/3) không hề gọi 2 controller này, không bị ảnh hưởng bởi thay đổi quyền.
- Grep bước 1 xác nhận đồng thời: không còn client nào (tenant-web, pte-app) gọi `/blueprints`, `/snapshots`, hoặc `/questions`.

## Risks

- LOW: Nếu Phase 7/8 chưa xong mà merge Phase 5 (hoặc phần khóa `QuestionController` của Phase 1) trước, tenant-web/pte-app cũ (`useCreateSession` gọi `publishBlueprint`; `pte-app`'s `features/authoring` gọi thẳng `/questions`) sẽ vỡ ngay lập tức với 403 — mitigation: thứ tự merge thực tế nên đặt Phase 5 sau Phase 7/8, hoặc merge cùng lúc; ghi rõ phụ thuộc ngược này trong PR description dù plan.md liệt kê phase theo thứ tự module.
