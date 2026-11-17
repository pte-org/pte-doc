# Plan: Sửa audit vai trò Host, quyền sửa tài khoản Staff nhiều tổ chức, gán lớp khi import roster

Status: Ready
Date: 2026-11-15
Mode: Fast
Test: default
Owner/slug: Ninh — `ninh-staff-audit-roster-fixes`
Scope: `pte-api` (`scoring`, `identity`, `enrollment`), `pte-web` (`tenant-web`), `pte-doc`
Related: [ninh-practice-integrity-round3](../ninh-practice-integrity-round3/plan.md)

## Mục tiêu

Ba phát hiện đã đối chiếu là đúng trong đợt review module ngoài phần thi:

4. Host Admin giải quyết sự cố chấm thi nhưng audit ghi vai trò `EXAMINER`.
2. Staff thuộc nhiều tổ chức không sửa được, nhưng UI vẫn cho sửa và chỉ báo lỗi chung chung.
1. Import roster có cột `Class Name` chỉ lưu chữ vào `users.class_name`, không tạo `class_students`,
   nên học viên vẫn hiện "chưa phân lớp".

Không làm: vòng đời Support Ticket (phát hiện 3, cần chốt nghiệp vụ), tối ưu `scanExaminer` (phát hiện 5, cần đo trước).

## Scope challenge

### Đã có gì?

- `CurrentUser` mang vai trò của người gọi; `ExaminerGradingAuditMetadata.actorRole` là chuỗi tự do.
- `ExamStaffAccountService.update` đã dùng `directory.isExclusivelyOwned(member)` để chặn; chỉ thiếu việc báo ra cho UI.
- `useStaffAccountForm` đã tách lỗi `conflict`; `text.*` là bộ chuỗi có sẵn cho màn staff.
- `UserCredentialsEmailRequestedEvent` (identity) + `@TransactionalEventListener` (notification) là mẫu sự kiện giữa module.
- `enrollment` đã được phép phụ thuộc `identity` (package-info), `identity` thì không được phụ thuộc `enrollment`.

### Tối thiểu là gì?

- Phát hiện 4: lấy vai trò thật từ `CurrentUser`.
- Phát hiện 2: thêm cờ `editable` vào view, ẩn nút Sửa, thông báo riêng cho lỗi 403.
- Phát hiện 1: sự kiện `StudentsImportedEvent` do identity phát, enrollment nghe và gán lớp khi tên lớp khớp đúng một lớp đang hoạt động trong tổ chức.

### Quyết định đã chọn cho phát hiện 1 (chưa được bạn xác nhận, dễ đổi)

- Tên lớp so sánh không phân biệt hoa thường, bỏ khoảng trắng đầu cuối.
- Chỉ gán khi khớp **đúng một** lớp `ACTIVE`, chưa xóa, trong tổ chức của Host. Không khớp hoặc khớp nhiều lớp thì để "chưa phân lớp".
- Không tự tạo lớp mới; không báo thêm trong kết quả import (không đổi hợp đồng API).
- Lỗi gán lớp không làm hỏng việc import.

### Độ phức tạp

Fast. Phát hiện 1 chạm ranh giới module (Modulith) nên dùng sự kiện thay vì gọi trực tiếp.

## Phases

- [x] Phase 1: Audit ghi đúng vai trò người giải quyết sự cố — [phase-01-audit-actor-role.md](./phase-01-audit-actor-role.md)
- [x] Phase 2: Cờ `editable` cho tài khoản Staff và giao diện tương ứng — [phase-02-staff-editable.md](./phase-02-staff-editable.md)
- [x] Phase 3: Import roster gán lớp theo tên — [phase-03-import-assigns-class.md](./phase-03-import-assigns-class.md)

## Kết quả thực hiện (2026-11-15)

- Phase 1: `ExaminerScoringConstants.HOST_ADMIN_ROLE`; `resolveIssue` ghi `actorRole = HOST_ADMIN`. Test mới trong `ExaminerWorkflowCommandServiceTest`.
- Phase 2: `ExamStaffAccountView.editable` (= `directory.isExclusivelyOwned(member)`), kiểu `ExamStaffAccountResponse.editable` ở api-client,
  `StaffAccountTab` ẩn nút Sửa và hiện ghi chú khi `editable = false`, `useStaffAccountForm` map lỗi `forbidden` sang chuỗi riêng (EN và VI).
  Menu hàng của danh sách Staff không sửa hồ sơ nên truyền `editable: false` (không dùng). Test mới `ExamStaffAccountServiceEditableTest`.
- Phase 3: `StudentsImportedEvent` (identity), `ImportedStudentClassAssigner` (enrollment), `TrainingClassRepository.findByOrganizationIdAndNameIgnoreCaseAndDeletedFalse`.
  `createBulk` phát một sự kiện sau vòng lặp. 4 test mới cho listener.

Kiểm chứng: backend 1620 test của `identity`, `enrollment`, `scoring` qua (29 bỏ qua sẵn có), kèm `ModuleStructureTest`/`ChatModuleBoundaryTest`;
`tenant-web` tsc sạch, 40 test của `examStaff` qua, eslint sạch.

Chưa làm: rebuild container, thử trên giao diện (cần Host và dữ liệu thật), commit.
Quyết định phát hiện 1 (khớp đúng một lớp ACTIVE, không tạo lớp, không báo thêm trong kết quả import) là mặc định của mình, chưa được bạn xác nhận.
Phát hiện 3 và 5 cố ý không sửa.

## Kết quả thử trên backend đã rebuild (2026-11-15)

Dùng Host test và hai Staff test tạo riêng trong DB local, gọi API thật, sau đó đã dọn:

- Import roster: dòng `className = "  pte-50a "` được gán vào lớp `PTE-50A` và Roster hiện đúng tên lớp; dòng tên lớp không tồn tại và dòng không có
  tên lớp để "chưa phân lớp" (log `Imported student left unassigned`); import vẫn trả 200.
- Staff: tài khoản do một tổ chức sở hữu trả `editable = true` và `PATCH` thành công; tài khoản dùng chung trả `editable = false` và `PATCH` trả 403.
- Phát hiện 4 (audit) chỉ kiểm bằng test đơn vị, chưa chạy luồng báo và giải quyết sự cố thật.
- Giao diện Staff chưa thử: `tenant-web` không có trang đăng nhập (`/login` trả 404).

Lưu ý khi tạo dữ liệu bằng SQL: id đặt tay làm sequence `users`, `organization_members`, `class_students` bị lệch, lần import đầu trả 500
(`users_pkey`). Đã đặt lại sequence bằng `setval`; không phải lỗi của mã mới.
