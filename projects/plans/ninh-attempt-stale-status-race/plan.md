# Plan: Không ghi đáp án vào attempt đã nộp khi autosave đua với nộp bài

Status: Completed
Date: 2026-11-15
Mode: Fast
Test: default
Owner/slug: Ninh — `ninh-attempt-stale-status-race`
Scope: `pte-api` (`attempt`), `pte-doc`
Related: [ninh-billing-auth-hardening](../ninh-billing-auth-hardening/plan.md)

## Mục tiêu

Phát hiện từ lần rà soát toàn dự án: `AttemptLifecycleService.saveAnswer/submitAnswer` nạp attempt (`findOwned`) trước, rồi mới chờ
khóa dòng session (`lockOpenSession`). Lệnh nộp bài cũng đi qua cùng khóa session nên hai request bị xếp hàng. Request đến sau,
khi được khóa, vẫn cầm bản attempt đã nạp trước đó (trạng thái `IN_PROGRESS` cũ). `AttemptAccess.lockAttempt` trả về đúng instance đã
được quản lý nên không nạp lại trạng thái. Kết quả: đáp án được ghi vào attempt đã `SUBMITTED` (chủ yếu qua `saveAnswerWithoutAdvance`,
vì đường này không sửa dòng attempt nên không bị lỗi khóa lạc quan chặn lại). Đáp án sau khi nộp có thể khác bản đã chấm.

Không làm: đổi cách khóa tổng thể, hay các thao tác khác (`playAudio`, `navigate`, `submitAttempt`) vì chúng sửa dòng attempt nên đã bị
chặn bởi `@Version`.

## Scope challenge

### Đã có gì?

- Khóa dòng session làm cho nộp bài và lưu đáp án chạy tuần tự; `AttemptAlreadyCompleteException` (409) đã có và được app Flutter coi là terminal.
- Kiểm tra `attempt.getStatus() != IN_PROGRESS` ở đầu `processAnswer` và `saveAnswerWithoutAdvance`, nhưng dựa trên bản nạp cũ.

### Tối thiểu là gì?

- Sau khi đã giữ khóa, đọc lại trạng thái từ DB bằng truy vấn vô hướng (`select a.status ...`; truy vấn vô hướng không lấy từ persistence context,
  và ở READ COMMITTED sau khi có khóa sẽ thấy dữ liệu đã commit) rồi từ chối nếu không còn `IN_PROGRESS`.
- Không dùng `EntityManager.refresh`: thêm phụ thuộc vào `AttemptAccess` và phải đổi mọi test dựng nó.

### Độ phức tạp

Fast. Một phương thức repository, một phương thức ở `AttemptAccess`, hai điểm gọi trong `AttemptAnswerRecorder`.

## Rủi ro đã biết

- Không có test tích hợp Postgres cho đường này (không dựng được session + ngân hàng câu hỏi); đua thật chỉ kiểm chứng bằng đọc code và test đơn vị.
- Nếu truy vấn vô hướng trả rỗng (không xảy ra ở production), dùng lại trạng thái đang có trong bộ nhớ để không đổi hành vi cũ.

## Phases

- [x] Phase 1: Đọc lại trạng thái attempt sau khi khóa — [phase-01-fresh-status-after-lock.md](./phase-01-fresh-status-after-lock.md)

## Kết quả thực hiện (2026-11-15)

- `ExamAttemptRepository.findStatusById` (truy vấn vô hướng), `AttemptAccess.requireStillInProgress`, và hai điểm gọi trong `AttemptAnswerRecorder`
  (`processAnswer`, `saveAnswerWithoutAdvance`) ngay sau `lockAttempt`. Các đường mã hóa (`submitEncryptedAnswer`, `saveEncryptedAnswer`)
  đi qua cùng hai phương thức nên được phủ luôn.
- 3 test mới ở `AttemptAnswerRecorderStaleStatusTest`: attempt trong bộ nhớ `IN_PROGRESS` nhưng DB đã `SUBMITTED` thì cả lưu nháp lẫn nộp-đáp-án-chuyển-task
  đều bị từ chối và không ghi gì; DB vẫn `IN_PROGRESS` thì lưu như cũ.

Kiểm chứng: toàn bộ test `com.pte.attempt` cùng `ModuleStructureTest` qua (gồm các test JPA H2 nạp repository nên JPQL mới hợp lệ).

Chưa làm: kiểm chứng đua thật với hai request đồng thời trên Postgres (cần session và ngân hàng câu hỏi); rebuild container; commit.
Hai điểm nhỏ khác từ lần rà soát chưa sửa: `completeUpload` media tin `secureUrl`/`bytes`/`durationSeconds` do client gửi; job định kỳ không có khóa phân tán khi chạy nhiều instance.

