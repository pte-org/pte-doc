# Phase 12: Trùng slot sinh viên

## Requirements

Một sinh viên có hai kỳ thi trùng khung giờ thì phải **loại sinh viên đó khỏi lô enroll**, không phải làm hỏng cả request — đồng thời thông báo lại cho trung tâm.

Maps to: **[ADR-006](../../architecture/ADR-006-commercialization-and-exam-templates.md) §4**

## Design Constraints

- **Loại khỏi lô, không chặn cả lô.** Enroll 500 người mà 3 người trùng slot thì 497 người vẫn vào được.
- **Một query cho cả lô.** Enroll 500 sinh viên không được sinh 500 query. Một câu `WHERE student_public_id IN (:ids) AND opens_at < :closesAt AND closes_at > :opensAt`, rồi diff trong bộ nhớ.
- **Phạm vi là trong cùng tenant** — không phải lựa chọn thiết kế mà là hệ quả cấu trúc: `User.tenantId` là cột scalar, một user thuộc đúng một tenant, nên `studentPublicId` chỉ tồn tại ở một tenant.
- Xét trùng với **mọi kỳ thi** của tenant, bất kể thuộc làn nào. Sinh viên không thể ngồi hai phòng thi cùng lúc dù trung tâm mua hai gói.
- Kỳ thi `CANCELLED` không tính là xung đột.

## Steps

1. `EnrollmentRepository.findConflictingEnrollments(tenantId, studentPublicIds, opensAt, closesAt)` — một câu, join `enrollments` với `exam_sessions`, trả về `(studentPublicId, conflictingSessionPublicId, conflictingSessionName)`.

2. Index hỗ trợ: `exam_sessions (tenant_id, opens_at, closes_at)`. Migration `V30__session_conflict_index.sql`. Đo `EXPLAIN` trên dữ liệu giả 10.000 enrollment trước khi chốt index.

3. `BulkEnrollResponse` thêm nhánh thứ ba:
   ```java
   record BulkEnrollResponse(
       List<UUID> enrolled,
       List<UUID> alreadyEnrolled,
       List<SlotConflict> skippedByConflict) {}

   record SlotConflict(UUID studentPublicId, UUID conflictingSessionPublicId, String conflictingSessionName) {}
   ```
   Nêu tên kỳ thi gây xung đột, không chỉ id — trung tâm phải hiểu được thông báo mà không cần tra cứu thêm.

4. `EnrollmentService.bulkEnroll()`:
   - Gọi `findConflictingEnrollments` **một lần** cho toàn bộ danh sách
   - Loại các sinh viên xung đột khỏi danh sách sẽ ghi
   - Kiểm `capacity` trên **số còn lại** sau khi loại, không phải trên danh sách gốc
   - Ghi phần còn lại, trả về cả ba nhánh

5. Phát event cho `notification` khi `skippedByConflict` không rỗng: gửi cho `HOST_ADMIN` của tenant, nội dung liệt kê sinh viên bị loại và kỳ thi gây xung đột.

6. `NotificationDispatchService`: thêm loại thông báo mới. Đi qua RabbitMQ như các thông báo khác — không gửi đồng bộ trong request enroll.

7. Enroll lẻ (`EnrollStudentRequest`) cũng kiểm xung đột, nhưng **ném exception** thay vì loại im lặng — enroll một người mà bị bỏ qua không báo gì là hành vi sai.

8. Test: sinh viên đã enroll kỳ thi 7h–9h, enroll vào kỳ thi 8h–10h → bị loại, có mặt trong `skippedByConflict` với đúng tên kỳ thi cũ.

9. Test biên: kỳ thi cũ 7h–9h, kỳ thi mới 9h–11h → **không** xung đột (chạm mép không phải chồng lấn). Đây là chỗ dễ sai dấu `<` với `<=`.

10. Test: lô 500 sinh viên, 3 người trùng slot → 497 enroll thành công, 3 người trong `skippedByConflict`.

11. Test hiệu năng: đếm số query thực tế khi enroll 500 người. Phải là hằng số, không tỷ lệ với số sinh viên.

12. Test: kỳ thi xung đột ở trạng thái `CANCELLED` → không tính là xung đột.

13. Test: `capacity` = 500, lô 500 người trong đó 3 trùng slot → 497 vào được, **không** báo vượt sức chứa.

## Success Criteria

- Sinh viên trùng slot bị loại khỏi lô, phần còn lại vẫn enroll được
- Thông báo tới trung tâm nêu rõ ai bị loại vì kỳ thi nào
- Số query không tăng theo số sinh viên trong lô
- Biên thời gian chạm mép không bị tính nhầm là chồng lấn
- Enroll lẻ báo lỗi rõ ràng thay vì im lặng bỏ qua

## Quality and Testing State

- Quality gate: chưa chạy
- Testing: chưa bắt đầu

## Session Notes

_(trống)_
