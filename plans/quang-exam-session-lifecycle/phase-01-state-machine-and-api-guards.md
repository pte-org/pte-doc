# Phase 01: State machine và API guards

Status: Implemented  
Scope: `pte-api` + các action liên quan trong `pte-web`

## Mục tiêu

Biến state policy thành invariant ở backend, đặc biệt chặn lỗi API hiện tại cho phép đóng session không ở trạng thái `OPEN`.

## Công việc

1. Chuẩn hóa transition policy tại một boundary dùng chung:
   - `SCHEDULED -> OPEN`
   - `OPEN -> CLOSED`
   - `READY/SCHEDULED -> CANCELLED`
   - `PREPARING -> DRAFT` sau khi generation job đã dừng thành công.
   - `DRAFT -> CANCELLED` không còn là action của host; draft dùng delete.
2. Sửa `SessionStateService.close()` để lock row, kiểm tra `OPEN`, rồi mới close. Không dựa vào điều kiện render ở frontend.
3. Thu hẹp domain methods `open()`, `close()`, `cancel()` hoặc chuyển toàn bộ validation vào state transition service; không để entity nhận transition bất kỳ chỉ vì method được gọi.
4. Tách exception/message cho từng transition không hợp lệ, dùng constant hiện có theo coding standard.
5. Giữ idempotency và concurrency:
   - lock session trước transition;
   - request lặp lại sau khi transition thành công trả lỗi nghiệp vụ ổn định hoặc response idempotent theo contract;
   - không cho open/close/cancel race tạo trạng thái cuối sai.
6. Cập nhật frontend action matrix:
   - bỏ cancel khỏi DRAFT;
   - hiển thị delete draft đúng điều kiện;
   - chỉ hiển thị close ở OPEN;
   - không thêm action cho CLOSED/CANCELLED.
7. Ghi audit event cho close, cancel và generation cancellation; không ghi secret/token.

## Acceptance criteria

- Direct API close với DRAFT, PREPARING, READY, SCHEDULED, CLOSED, CANCELLED đều bị từ chối.
- Direct API open chỉ nhận SCHEDULED.
- DRAFT không còn endpoint/action cancel từ host.
- Hủy PREPARING không để queued/running job tiếp tục ghi snapshot hoặc đổi status sau đó.
- Các action trên detail/list đồng nhất với backend policy.

## Test bắt buộc

- Service parameterized test cho mọi status.
- Controller/security test cho allow-deny và tenant scope.
- Concurrent transition test với pessimistic lock/version.
- Frontend test/smoke cho menu theo từng status.

## File dự kiến

- `pte-api/app/src/main/java/com/pte/session/domain/ExamSession.java`
- `pte-api/app/src/main/java/com/pte/session/internal/service/lifecycle/SessionStateService.java`
- `pte-api/app/src/main/java/com/pte/session/internal/service/ExamOrchestrationService.java`
- `pte-api/app/src/test/java/com/pte/session/*`
- `pte-web/apps/tenant-web/features/exams/components/*`
