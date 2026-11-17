# Phase 1: Đọc lại trạng thái attempt sau khi khóa

Status: Completed

## Requirements

- `saveAnswer`, `saveEncryptedAnswer`, `submitAnswer`, `submitEncryptedAnswer` từ chối với `AttemptAlreadyCompleteException` khi attempt đã không còn `IN_PROGRESS`
  tại thời điểm giữ khóa, kể cả khi bản đã nạp trong bộ nhớ vẫn ghi `IN_PROGRESS`.
- Luồng bình thường (attempt đang làm bài) không đổi.

## Design Constraints

- Kiểm tra nằm sau khi `AttemptAccess.lockAttempt` trả về, trước khi ghi đáp án.
- Đọc trạng thái bằng truy vấn vô hướng trong `ExamAttemptRepository`; không thêm `EntityManager`.
- Giữ nguyên các mã lỗi (`AttemptAlreadyCompleteException`).

## Related files

- `pte-api/app/src/main/java/com/pte/attempt/internal/repository/ExamAttemptRepository.java`
- `pte-api/app/src/main/java/com/pte/attempt/internal/service/AttemptAccess.java`
- `pte-api/app/src/main/java/com/pte/attempt/internal/service/AttemptAnswerRecorder.java`
- `pte-api/app/src/test/java/com/pte/attempt/internal/service/AttemptLifecycleServiceSubmitAnswerTest.java` (và test mới cho recorder)

## Steps

1. `ExamAttemptRepository.findStatusById(Long id)` trả `Optional<AttemptStatus>` bằng truy vấn vô hướng.
2. `AttemptAccess.requireStillInProgress(ExamAttempt)`: đọc trạng thái mới, rỗng thì dùng trạng thái trong bộ nhớ; không `IN_PROGRESS` thì ném `AttemptAlreadyCompleteException`.
3. `AttemptAnswerRecorder.processAnswer` và `saveAnswerWithoutAdvance`: gọi bước 2 ngay sau `lockAttempt`.
4. Test: attempt trong bộ nhớ `IN_PROGRESS` nhưng DB đã `SUBMITTED` thì cả hai đường đều từ chối và không gọi `answerSubmitService`; DB vẫn `IN_PROGRESS` thì lưu như cũ.

## Quality/Testing State

- Test đơn vị mới; chạy lại toàn bộ test module `attempt` và `ModuleStructureTest`.
