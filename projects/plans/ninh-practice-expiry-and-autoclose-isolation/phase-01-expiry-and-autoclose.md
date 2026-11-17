# Phase 1: Giữ EXPIRED và cách ly lỗi auto-close

Status: Completed

## Requirements

- Thao tác trên practice session quá hạn vẫn trả 410 và `EXPIRED` được commit.
- Một session lỗi khi auto-close không làm các session khác bị bỏ qua.
- Các lỗi 409/422 khác vẫn rollback như cũ.

## Related files

- `pte-api/app/src/main/java/com/pte/practice/internal/exception/PracticeSessionExpiredException.java` (mới)
- `pte-api/app/src/main/java/com/pte/practice/internal/service/session/PracticeSessionStateGuard.java`, `PracticeSessionService.java`
- `pte-api/app/src/main/java/com/pte/session/internal/service/lifecycle/SessionAutoCloseWorker.java`
- Test: `PracticeSessionExpiryTransactionTest`, `SessionAutoCloseWorkerTest`

## Quality/Testing State

- Test đơn vị mới; chạy lại test practice, hai worker và `ModuleStructureTest`.
