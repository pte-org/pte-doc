# Phase 03: Xóa bản nháp và toàn vẹn soft-delete

Status: Implemented  
Depends on: Phase 01

## Mục tiêu

Cho phép dọn bản nháp an toàn nhưng giữ audit và không làm lộ session đã xóa qua các module khác. Không tạo archive, restore hoặc purge workflow.

## Quy tắc xóa

- Chỉ `DRAFT` được xóa mềm.
- `PREPARING` phải dừng generation job trước; không cho delete trực tiếp.
- `READY`, `SCHEDULED`, `OPEN`, `CLOSED`, `CANCELLED` không được xóa.
- Xóa lặp lại phải trả kết quả ổn định, không tạo audit duplicate.
- Sau khi xóa, session không xuất hiện ở host list/detail, enrollment lookup, attempt lookup, staff schedule hoặc overlap query.

## Công việc backend

1. Giữ `ExamSession.deleted = true` làm source of truth cho parent.
2. Xác định retention cho child rows:
   - audience source/member;
   - generation job;
   - selected skills;
   - forms/form assignments;
   - proctor/class/examiner assignment references.
3. Chọn một chiến lược nhất quán:
   - soft-delete child rows nếu child có lifecycle riêng; hoặc
   - giữ child rows để audit nhưng mọi read path phải join/filter parent non-deleted.
4. Rà soát repository method dạng `findByPublicId(UUID)` và các internal caller; host/student path phải có tenant + `deleted = false`.
5. Bảo đảm session code không bị tái sử dụng và audit event `ExamDraftDeleted` vẫn truy được.
6. Nếu bản nháp có job queued/running do race, delete phải lock và từ chối cho tới khi job terminal; không để worker ghi vào session đã xóa.
7. Bổ sung retention note vào module documentation; không dùng delete vật lý trong flow UI.

## Công việc frontend

- Chỉ hiển thị Xóa bản nháp ở DRAFT.
- Confirm dialog nói rõ bản nháp bị xóa khỏi danh sách và không thể khôi phục qua UI.
- Sau thành công invalidate list/detail query và hiển thị common toast.
- Không tạo filter Archive/Deleted.

## Acceptance criteria

- Không thể xóa CANCELLED bằng UI hoặc direct API.
- Deleted draft không xuất hiện ở bất kỳ read surface nào dành cho host/student/staff.
- Không có worker hoặc report đọc nhầm child data của deleted draft.
- Audit vẫn giữ actor, target và thời điểm xóa.
- Không ảnh hưởng session đã publish và attempt/report history.

## Test bắt buộc

- Delete allow/deny matrix theo status.
- Query isolation cho từng read path.
- Race delete với generation job.
- Session code uniqueness sau soft-delete.
- Frontend list/detail cache update và error toast.

## File dự kiến

- `pte-api/app/src/main/java/com/pte/session/internal/service/ExamOrchestrationService.java`
- `pte-api/app/src/main/java/com/pte/session/internal/repository/ExamSessionRepository.java`
- child repositories và worker liên quan
- `pte-web/apps/tenant-web/features/exams/components/SessionTable.tsx`
