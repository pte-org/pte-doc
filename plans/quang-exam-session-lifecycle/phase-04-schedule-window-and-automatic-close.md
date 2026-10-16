# Phase 04: Cửa sổ thời gian và auto-close

Status: Implemented  
Depends on: Phase 01

## Mục tiêu

Làm rõ quan hệ giữa status và `opensAt/closesAt`, giữ cơ chế host mở thủ công đang có, đồng thời không để session bị treo `OPEN` sau thời điểm kết thúc.

## Quyết định MVP

- `SCHEDULED` nghĩa là đã publish và chờ host mở; không tự động `OPEN`.
- Student attempt chỉ được phép trong `[opensAt, closesAt)`, bất kể host mở sớm hay quên đóng.
- `OPEN -> CLOSED` là transition bắt buộc trước các flow chấm/report cần trạng thái CLOSED.
- Bổ sung auto-close idempotent tại hoặc sau `closesAt`; auto-close không tự động mở session.
- Nếu sau này cần auto-open, đó là phase riêng vì ảnh hưởng vận hành, notification và quyền kiểm soát host.

## Công việc backend

1. Chuẩn hóa time-window guard dùng chung cho open, close, attempt entry và reminder.
2. Xác định rule `open` trước `opensAt`: khuyến nghị vẫn cho host mở sớm nhưng student bị chặn đến thời điểm mở; response nên thể hiện window state để UI không hiểu nhầm.
3. Tạo worker auto-close:
   - query OPEN sessions có `closesAt <= now`;
   - lock từng session;
   - kiểm tra lại status/time;
   - close và ghi audit event;
   - retry an toàn, không duplicate transition.
4. Không auto-close session đã CANCELLED/CLOSED/deleted.
5. Bảo đảm close thủ công và auto-close dùng cùng transition service.
6. Giữ reminder closing-soon nhưng không để reminder là cơ chế đóng duy nhất.
7. Expose đủ status/window state cho host UI nếu status OPEN nhưng window chưa bắt đầu hoặc đã hết.

## Công việc frontend

- Hiển thị rõ status lifecycle và window state.
- Nút Đóng kỳ thi vẫn dùng common action; sau auto-close query tự refresh/invalidate.
- Không hiển thị nút Mở lại cho CLOSED.
- Copy phải nói rõ host mở thủ công và student chỉ vào được trong time window.

## Acceptance criteria

- Session ngoài time window không cho attempt.
- Session OPEN quá `closesAt` được auto-close trong một poll interval.
- Close thủ công và auto-close không tạo audit/notification trùng.
- Scoring/report flow có thể tiếp tục sau auto-close.
- Worker không tác động tới session đã xóa hoặc tenant khác.

## Test bắt buộc

- Time boundary chính xác tại `opensAt` và `closesAt`.
- Auto-close idempotency và concurrent manual close.
- Worker lock/tenant/deleted/status filtering.
- Reminder không thay thế auto-close.
- Integration test với scheduler và PostgreSQL-backed session rows.

## File dự kiến

- `pte-api/app/src/main/java/com/pte/session/internal/service/lifecycle/SessionStateService.java`
- `pte-api/app/src/main/java/com/pte/session/internal/service/SessionEntryGate.java`
- `pte-api/app/src/main/java/com/pte/session/internal/repository/ExamSessionRepository.java`
- `pte-api/app/src/main/java/com/pte/session/internal/service/lifecycle/SessionAutoCloseWorker.java`
- `pte-web/apps/tenant-web/features/exams/components/ExamOverviewTab.tsx`
