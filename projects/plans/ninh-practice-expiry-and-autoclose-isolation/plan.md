# Plan: Giữ trạng thái EXPIRED của practice session và cách ly lỗi từng session ở auto-close

Status: Completed
Date: 2026-11-15
Mode: Fast
Test: default
Owner/slug: Ninh — `ninh-practice-expiry-and-autoclose-isolation`
Scope: `pte-api` (`practice`, `session`), `pte-doc`
Related: [ninh-attempt-stale-status-race](../ninh-attempt-stale-status-race/plan.md)

## Mục tiêu

Hai điểm từ một nhận xét về pte-api, đã đối chiếu với code, cả hai đúng:

1. `SessionAutoCloseWorker.closeDueSessions` lặp qua các session đến hạn mà không có `try/catch`; một session lỗi làm cả vòng dừng, các session còn lại
   không được đóng ở chu kỳ đó. `SessionAutoOpenWorker` đã cách ly từng session.
2. Khi session luyện tập quá hạn, `PracticeSessionStateGuard.requireLiveInProgress` (và `heartbeat`, `saveAndExit`) đặt `EXPIRED`, `saveAndFlush`, rồi ném
   `PracticeSessionException` (410). Phương thức `@Transactional` rollback khi gặp `RuntimeException`, nên `EXPIRED` không được lưu; DB vẫn `IN_PROGRESS`
   cho tới khi có lần `get`. Test Mockito không thấy vì không đi qua proxy giao dịch.

Không làm: `noRollbackFor` cho cả `PracticeSessionException` (sẽ commit cả các thay đổi dở dang khi gặp lỗi 409/422 sau khi đã sửa dữ liệu).

## Scope challenge

Tối thiểu: một lớp con `PracticeSessionExpiredException` chỉ ném ở ba chỗ đặt `EXPIRED`, đều trước mọi thay đổi khác; `noRollbackFor` đúng lớp đó
trên 5 phương thức; `try/catch` ở worker. Fast.

## Phases

- [x] Phase 1: Giữ EXPIRED và cách ly lỗi auto-close — [phase-01-expiry-and-autoclose.md](./phase-01-expiry-and-autoclose.md)

## Kết quả thực hiện (2026-11-15)

- `PracticeSessionExpiredException` (mới, kế thừa `PracticeSessionException`, vẫn 410 cùng mã lỗi và thông điệp). Guard, `heartbeat`, `saveAndExit` ném lớp này;
  `heartbeat`, `answer`, `skip`, `saveDraft`, `saveAndExit` khai báo `@Transactional(noRollbackFor = PracticeSessionExpiredException.class)`.
- `SessionAutoCloseWorker`: `try/catch (RuntimeException)` từng session, ghi `warn`.
- Test: `PracticeSessionExpiryTransactionTest` (5 phương thức khai báo đúng `noRollbackFor`), `SessionAutoCloseWorkerTest` (một session lỗi không chặn session khác).

Kiểm chứng: test `com.pte.practice`, hai worker test và `ModuleStructureTest` qua. Chưa có test chạy thật qua proxy giao dịch trên DB (test đơn vị không thấy được rollback), nên hành vi commit
chỉ được khóa bằng test khai báo. Chưa làm: rebuild container; commit.
