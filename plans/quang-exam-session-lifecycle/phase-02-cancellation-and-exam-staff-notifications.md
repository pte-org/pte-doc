# Phase 02: Hủy kỳ thi và notification cho exam staff

Status: Implemented  
Depends on: Phase 01

## Mục tiêu

Khi một kỳ thi bị hủy, thông báo đúng cho nhân sự kỳ thi liên quan. Student không phải recipient vì không dùng tenant exam platform; không tạo integration với `pte-practice`.

## Recipient contract

Exam staff được resolve tại thời điểm hủy, gồm:

- Proctor active được tìm từ các `ProctorAssignment` của session.
- Examiner active được tìm từ các examiner assignment đã commit cho session.
- Chỉ giữ user thuộc đúng tenant, chưa bị xóa, đang active và có role tương ứng.
- Dedupe theo `userPublicId`; không gửi hai lần nếu một user có nhiều assignment.
- Nếu session chưa gán staff thì không broadcast sang toàn bộ tenant staff.
- Không đưa `STUDENT` hoặc enrollment student IDs vào event.

## Công việc backend

1. Đổi contract event từ tên trường student-specific sang recipient-neutral, ví dụ `recipientUserPublicIds`.
2. Tạo một resolver/facade trong boundary phù hợp để lấy recipient từ:
   - session proctor assignments;
   - committed examiner attempt assignments.
3. Tái sử dụng event path cho:
   - host hủy session;
   - subscription revocation hủy session scheduled.
4. Listener dispatch qua `NotificationDispatchService` hiện có, giữ `AFTER_COMMIT` và `REQUIRES_NEW`.
5. Thêm dedupe key/idempotency theo session, cancellation transition và recipient để retry event không gửi trùng.
6. Nội dung notification phải nêu tên/mã kỳ thi, thời điểm hủy và hướng dẫn exam staff quay lại workspace. Dùng constants/message catalog, không hardcode trong handler.
7. Audit phải ghi actor, session, trạng thái trước/sau và số recipient; không ghi email/password/token ngoài policy hiện có.

## Công việc frontend

- Toast cho host sau khi hủy chỉ xác nhận thao tác thành công.
- Exam staff nhận notification trong channel hiện có của notification module.
- Không thêm notification UI hoặc API dependency vào student/pte-practice.
- Trạng thái CANCELLED chỉ có view/history, không có delete/archive.

## Acceptance criteria

- Hủy `SCHEDULED` gửi đúng proctor/examiner active đã gán.
- Hủy `READY` chỉ gửi nếu đã có staff assignment; không gửi student.
- User inactive/deleted/cross-tenant không nhận.
- Không có assignment thì không gửi broadcast.
- Subscription revocation và host cancel dùng cùng recipient contract.
- Retry transaction/event không tạo duplicate notification.

## Test bắt buộc

- Resolver test cho proctor, examiner, duplicate recipient và empty assignment.
- Tenant/status/active-user filtering test.
- Listener test khẳng định không có student recipient.
- Integration test kiểm tra notification log và queue job sau commit.
- Manual cancel và subscription revoke đều có event cùng schema.

## File dự kiến

- `pte-api/app/src/main/java/com/pte/session/dto/event/SessionCancelledEvent.java`
- `pte-api/app/src/main/java/com/pte/session/internal/service/ExamOrchestrationService.java`
- `pte-api/app/src/main/java/com/pte/session/internal/service/lifecycle/SessionRevocationService.java`
- `pte-api/app/src/main/java/com/pte/notification/internal/listener/SessionCancelledNotificationListener.java`
- `pte-api/app/src/main/java/com/pte/notification/internal/constant/*`
- notification/session test suites
