# Chi tiết lớp học: gộp một trang (tenant-web)

**Trạng thái:** đã làm, chưa commit.

## Quyết định
Tab "Tổng quan" chỉ có 4 trường, tab "Danh sách học viên" mới là việc chính, nên bỏ tab: thông tin lớp lên đầu trang, bảng học viên ngay bên dưới.

## Đã làm (`apps/tenant-web/features/classes`)
- `ClassHeader` (mới, thay `ClassInformation`): tên lớp + badge trạng thái, nút `+ Thêm học viên`, menu `…` (Chỉnh sửa, Tạm dừng, Ngừng hoạt động, Gỡ bỏ), và một dòng "Chương trình (link) · N học viên · ID: 4ef8c68a… [copy]". Đổi tên tại chỗ (Enter lưu, Esc hủy), giữ `UnsavedChangesGuard`.
- Menu `…` không còn mục "Phân công học viên" ở trang này (đã có nút `+ Thêm học viên`); thêm prop `showAssignStudents` (mặc định bật nên danh sách lớp trong trang Chương trình giữ nguyên). Dấu phân cách đầu menu chỉ hiện khi có mục giữa.
- Bảng học viên: tên có thêm mã học viên ở dòng nhỏ xám, tìm theo mã ra đúng dòng (`filterAccessor`). Empty state: icon nhóm người, "Chưa có học viên trong lớp / Thêm học viên hiện có hoặc nhập danh sách để bắt đầu." Nút thêm học viên chuyển lên header.
- `@pte/ui` (tùy chọn, mặc định không đổi): `EmptyState.icon`, `DataTable.emptyIcon`, `CopyableId.truncateTo`.

## Chưa làm / ghi nhận
- Trang chi tiết Chương trình (`ProgramDetailView`) cùng kiểu 2 tab Tổng quan + Lớp học; chưa đổi.
