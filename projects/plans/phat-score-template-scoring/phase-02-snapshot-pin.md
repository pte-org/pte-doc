# Phase 2: Pin template vào ExamSnapshot lúc publish

Covers phần pin của spec FR-13 ("Sinh đề → publish snapshot một lần khi tạo kỳ thi; `ExamSnapshot` lưu `scoreTemplatePublicId` + `scoreTemplateVersion`") — chỉ phần pin, **không** đụng `selectedSkills`/sinh đề ngẫu nhiên (Plan B). Luồng publish thủ công hiện có (`BlueprintService` → `SnapshotPublishService.publish`) giữ nguyên, chỉ thêm bước pin template ACTIVE tại thời điểm publish.

## Requirements

Mỗi `ExamSnapshot` mới được publish (qua luồng blueprint thủ công hiện có) ghi lại `scoreTemplatePublicId`/`scoreTemplateVersion` của template ACTIVE tại thời điểm đó, bất biến vĩnh viễn kể từ lúc publish — kích hoạt template mới sau này không ảnh hưởng snapshot đã publish.

## Files

**Sửa**
- `pte-api/app/src/main/java/com/pte/assessment/domain/ExamSnapshot.java` — thêm `scoreTemplatePublicId` (`UUID`, not null) và `scoreTemplateVersion` (`int`, not null).
- `pte-api/app/src/main/java/com/pte/assessment/internal/service/SnapshotPublishService.java` — inject `ScoreTemplateService`; trong `publish()`, gọi `getActive()` một lần và set 2 field trên trước khi `save`.
- `pte-api/app/src/main/java/com/pte/assessment/dto/response/SnapshotContentResponse.java` — thêm `scoreTemplatePublicId` (dùng ở Phase 3 bởi `attempt`).
- `pte-api/app/src/main/java/com/pte/assessment/dto/response/SnapshotResponse.java` — thêm `scoreTemplatePublicId`/`scoreTemplateVersion` (hiển thị được cho admin/host xem đề đang dùng thang điểm nào — rẻ, hữu ích, không bắt buộc bởi FR nhưng cùng chỗ sửa).
- `pte-api/app/src/main/java/com/pte/assessment/internal/mapper/SnapshotMapper.java` — map 2 field mới ở cả `toResponse` và `toContentResponse`.
- `pte-api/app/src/main/resources/db/migration/V15__assessment_score_template_pin.sql` — `ALTER TABLE exam_snapshots ADD COLUMN score_template_public_id UUID NOT NULL, ADD COLUMN score_template_version INTEGER NOT NULL` (xác nhận lại `V14` là migration mới nhất trước khi đặt tên `V15`).

## Steps

1. Thêm 2 cột vào `ExamSnapshot` + migration tương ứng; vì cột `NOT NULL` không default, nếu DB dev cục bộ đã có `exam_snapshots` cũ, migration sẽ fail — chấp nhận yêu cầu xoá/tạo lại DB dev cục bộ một lần (hệ thống chưa deploy, không có dữ liệu thật cần giữ).
2. Sửa `SnapshotPublishService.publish()` gọi `scoreTemplateService.getActive()` đúng một lần mỗi lần publish, set `scoreTemplatePublicId`/`scoreTemplateVersion` lên `ExamSnapshot` trước khi lưu.
3. Thêm `NoActiveScoreTemplateException` (từ Phase 1) vào đường lan truyền lỗi của `publish()` — không bắt/nuốt, để lộ rõ lỗi cấu hình nếu vì lý do nào đó không có ACTIVE (không nên xảy ra sau khi seed V5, nhưng phải fail rõ ràng thay vì publish snapshot thiếu template).
4. Cập nhật `SnapshotContentResponse`/`SnapshotResponse`/`SnapshotMapper` để lộ 2 field mới ra ngoài — đây là điểm nối cho `attempt` (Phase 3) đọc `scoreTemplatePublicId` lúc pin.
5. Xác nhận `AssessmentService` (facade) không cần đổi chữ ký — `getFullContent`/`getSummary` chỉ đổi kiểu trả về (record thêm field), không đổi tham số.
6. Chạy lại `SnapshotPublishServiceTest` hiện có (đã dùng Mockito) và bổ sung case mới.

## Tests

- Sửa `SnapshotPublishServiceTest` (file có sẵn): thêm mock `ScoreTemplateService`, assert mọi test `publish` hiện có vẫn pass với `scoreTemplatePublicId` được set đúng giá trị từ `getActive()`.
- Test mới: `publish_noActiveTemplate_throws` — `getActive()` ném `NoActiveScoreTemplateException` → `publish()` không lưu snapshot, không đổi `BlueprintStatus`.
- Test mapper: `getSummary`/`getContent` trả về `scoreTemplatePublicId` đúng giá trị đã lưu trên entity.
- `./mvnw test -pl app` (từ `pte-api/`).

## Success Criteria

- Mọi snapshot publish mới có `scoreTemplatePublicId`/`scoreTemplateVersion` khớp template ACTIVE tại thời điểm publish (unit test xác nhận).
- `mvnw test` xanh; `SnapshotPublishServiceTest` không còn test nào fail vì thiếu mock `ScoreTemplateService`.
- Không có snapshot nào được tạo ra khi không có template ACTIVE (test `publish_noActiveTemplate_throws`).

## Risks

- Cột `NOT NULL` không default trên bảng đã tồn tại (`exam_snapshots`) — chỉ an toàn vì hệ thống chưa deploy; nếu ai đó đã có snapshot thật trong DB dev, phải reset DB trước khi chạy `V15`. Ghi rõ bước này trong hướng dẫn chạy migration của phase.
- `SnapshotPublishService` giờ phụ thuộc thêm `scoretemplate` — kiểm tra `ModuleStructureTest` không báo vi phạm boundary mới (assessment → scoretemplate là phụ thuộc một chiều hợp lệ, không có chiều ngược).
