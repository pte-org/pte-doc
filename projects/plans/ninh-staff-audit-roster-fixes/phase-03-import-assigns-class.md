# Phase 3: Import roster gán lớp theo tên

Status: Completed

## Requirements

- Học viên được import với cột `Class Name` trùng (không phân biệt hoa thường) với **đúng một** lớp `ACTIVE`, chưa xóa
  của tổ chức Host thì được gán vào lớp đó, và hiện đúng lớp trên Roster.
- Không khớp, hoặc khớp nhiều lớp: để "chưa phân lớp", import vẫn thành công.
- Lỗi khi gán lớp không làm hỏng việc import hay các học viên khác.

## Design Constraints

- `identity` không được phụ thuộc `enrollment` (Modulith): identity phát sự kiện công khai, enrollment lắng nghe.
- Sự kiện chỉ mang `tenantId` và cặp (`studentPublicId`, `className`) của học viên vừa tạo, không mang dữ liệu nhạy cảm.
- Listener chạy sau commit (`@TransactionalEventListener`, có `fallbackExecution`), mở transaction mới để ghi `class_students`.
- Không tự tạo lớp, không đổi `BulkCreateUsersResponse`.

## Related files

- `pte-api/app/src/main/java/com/pte/identity/StudentsImportedEvent.java` (mới)
- `pte-api/app/src/main/java/com/pte/identity/internal/service/user/UserAccountProvisioner.java`
- `pte-api/app/src/main/java/com/pte/enrollment/internal/listener/ImportedStudentClassAssigner.java` (mới)
- `pte-api/app/src/main/java/com/pte/enrollment/internal/repository/TrainingClassRepository.java`
- Test: `ImportedStudentClassAssignerTest`

## Steps

1. Record `StudentsImportedEvent(tenantId, List<ImportedStudent(studentPublicId, className)>)`.
2. `createBulk` phát sự kiện một lần sau vòng lặp, chỉ gồm học viên vừa tạo có `className`.
3. Repository: tìm lớp theo `organizationId` và tên không phân biệt hoa thường, chưa xóa.
4. Listener: mỗi học viên khớp đúng một lớp `ACTIVE` thì tạo `ClassStudent`; bắt và ghi log lỗi từng học viên.
5. Test: khớp một lớp, không khớp, khớp nhiều lớp, lớp không hoạt động, lỗi một học viên không chặn các học viên khác.

## Quality/Testing State

- Test đơn vị cho listener; chạy lại test `identity` và `enrollment`.
