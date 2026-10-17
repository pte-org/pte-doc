# Phase 15: Enrollment concurrency & publish reconciliation

Owner: **Quang**
Status: **Planned**
Depends on: **Phase 14**
Maps to: [ADR-006](../../architecture/ADR-006-commercialization-and-exam-templates.md) §4

## Requirements

Phase 12 đã có conflict query tenant-wide và xử lý partial batch, nhưng query hiện tại vẫn là read-then-write. Hai request đồng thời enroll cùng một student vào hai session overlap có thể cùng thấy “không conflict” rồi cùng insert. Ngoài ra publish hiện gọi bulk enroll nhưng không reconcile `skippedByConflict`, nên audience member có thể bị đánh dấu `ENROLLED` dù không có `Enrollment` tương ứng.

## Design Constraints

- Invariant kinh doanh là một student không được có hai enrollment active trong các khoảng thời gian overlap trong cùng tenant. Khoảng thời gian là half-open: `opensAt < otherClosesAt` và `closesAt > otherOpensAt`; chạm biên không conflict.
- Không coi một conflict query trước transaction insert là bằng chứng cuối cùng. Cần DB-backed serialization/invariant áp dụng cho single enroll, bulk enroll và publish.
- Nếu khoá identity row là giải pháp được chọn, mọi request phải acquire các student row theo `publicId` tăng dần trước khi conflict query và insert; không được có path riêng khoá theo thứ tự request.
- `ExamAudienceMember.status = ENROLLED` chỉ là projection của enrollment thực tế. `enrolled` và `alreadyEnrolled` mới được đánh dấu enrolled; `skippedByConflict` phải có status/reason conflict.
- Partial batch behavior của Phase 12 được giữ: student conflict không làm hỏng các student hợp lệ khác. Quy tắc khi toàn bộ audience bị conflict phải được chốt trước implementation.

## Steps

1. Chọn và ghi rõ cơ chế serialize ở Postgres. Khuyến nghị dùng pessimistic lock trên các identity row đã được Phase 14 xác nhận active, acquire theo sorted `studentPublicId`; nếu chọn advisory lock hoặc schema invariant khác phải ghi rõ collision/rollback behavior và lý do.

2. Đưa lock helper vào một đường dùng chung cho `enrollStudent`, `bulkEnroll` và `bulkEnrollPublishedExam`. Lock phải nằm trong cùng transaction với conflict query, capacity check và insert; không gọi một helper read-only ở ngoài transaction rồi tin kết quả cũ.

3. Giữ response ba nhánh của `BulkEnrollResponse` và bổ sung đủ conflict metadata để UI/notification giải thích được session gây conflict. Không để caller phải tự suy ra từ số lượng rows.

4. Sửa publish reconciliation:

   - nhận và xử lý response thật từ `bulkEnrollPublishedExam`;
   - map `enrolled` và `alreadyEnrolled` sang `ENROLLED`;
   - map `skippedByConflict` sang `EXCLUDED` với reason và session gây conflict;
   - chỉ chuyển session sang `SCHEDULED` theo policy đã chốt, không dựa vào việc preflight trước đó đã xanh;
   - phát notification/audit sau khi status đã phản ánh đúng database.

5. Chốt behavior all-conflict. Khuyến nghị: partial publish được phép; nếu không còn student nào có thể enroll thì giữ session `READY`, trả lỗi có thể xử lý và không tạo trạng thái `SCHEDULED` rỗng. Nếu business chọn publish rỗng, phải ghi rõ lý do và acceptance test thay thế.

6. Viết Postgres integration/concurrency tests:

   - hai session overlap, cùng student, hai transaction bắt đầu gần như đồng thời;
   - hai batch overlap có nhiều student chung, kiểm tra acquisition order và không deadlock;
   - session chỉ chạm biên không conflict;
   - một publish bị conflict sau preflight không sinh false `ENROLLED`;
   - retry publish/enroll không tạo duplicate và response phản ánh `alreadyEnrolled` đúng.

7. Đo query count của batch 500 student sau khi thêm lock/eligibility. Lock không được biến thành N+1 không có giới hạn; nếu cần một query load/lock theo `IN` thì vẫn phải giữ deterministic ordering trong code.

## Success Criteria

- Không có hai enrollment overlap cho cùng student sau khi chạy concurrent Postgres test.
- Batch vẫn partial đúng contract và không vượt capacity sau khi loại conflict.
- Không có audience member `ENROLLED` nào thiếu enrollment thực tế.
- Conflict phát sinh sau preflight được lưu reason, session gây conflict và notification/audit tương ứng.
- Retry/idempotency không tạo duplicate hoặc làm đổi status đã reconcile.

## Quality and Testing State

- Quality gate: **not evaluated**.
- Testing: **not started**. Bằng chứng bắt buộc là Postgres integration/concurrency test; mock-only test không đủ để đóng phase này. Docker unavailable phải được report như một release blocker hoặc gap, không ghi `passed`.

## Decision Gates

- All-conflict publish giữ `READY` hay vẫn `SCHEDULED` với audience rỗng?
- Có chấp nhận lock identity row làm serialization contract chính thức không, hay cần schema-level invariant mới?
- Notification/audit conflict cần hiển thị student name tại thời điểm nào, và xử lý identity đã bị archive ra sao?
