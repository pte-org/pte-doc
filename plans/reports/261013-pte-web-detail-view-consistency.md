# Rà soát và làm lại các màn hình detail

**Ngày:** 2026-10-13  
**Phạm vi:** `pte-web/apps/tenant-web` và `pte-web/apps/vendor-web`  
**Trạng thái:** Đã triển khai trong working tree; chưa commit

## Quy ước UI đã áp dụng

- Breadcrumb là nơi hiển thị tên bản ghi ở cấp trang. Các `PageHeader` lặp lại tên bản ghi trên các màn hình detail đã được bỏ.
- Trạng thái và action được đặt trong panel Tổng quan hoặc panel nghiệp vụ liên quan, ngay cạnh thông tin mà action tác động tới.
- Form chỉnh sửa thông tin bản ghi hiển thị inline trong panel, theo cùng pattern `ProfileAccountPanel` của Learner và Exam Staff.
- Vẫn giữ các dialog xác nhận cho thao tác không thể hoàn tác và các modal nghiệp vụ riêng như import học viên, reset password, tạo login account và editor chuyên dụng.
- Không thay đổi default typography, màu, variant hoặc trigger của `@pte/ui`.

## Phạm vi màn hình đã rà soát

| App | Màn hình detail | Kết quả |
| --- | --- | --- |
| Tenant | Student | Đã có inline account editor; giữ profile header vì đây là identity block của người dùng |
| Tenant | Exam Staff | Đã có inline account editor; giữ profile header và action menu nghiệp vụ |
| Tenant | Program | Bỏ heading/action phía trên tab; action chuyển vào `ProgramInformation`; edit chuyển thành inline form |
| Tenant | Class | Bỏ heading/status phía trên tab; edit tên lớp chuyển từ modal sang inline form trong `ClassInformation`; bỏ panel Lecturer |
| Tenant | Exam session | Bỏ PageHeader và nút back lặp navigation; lifecycle action vẫn nằm trong Overview |
| Tenant | Notification | Bỏ PageHeader lặp tiêu đề breadcrumb; nội dung thông báo giữ nguyên |
| Tenant | Support ticket | Bỏ PageHeader chung; thông tin ticket và note thread giữ nguyên |
| Admin | Tenant | Bỏ PageHeader; status chuyển vào nhóm thông tin Organization trong Summary |
| Admin | Application | Bỏ PageHeader; review/status action giữ trong panel Review |
| Admin | Question | Bỏ PageHeader; status và nút editor chuyển vào panel Thông tin câu hỏi |
| Admin | Score/Exam template | Bỏ PageHeader; status và Clone chuyển vào metadata card nội dung |
| Admin | Announcement | Bỏ PageHeader; draft edit chuyển từ modal sang inline form; publish/delete vẫn có confirm dialog |
| Admin | Notification | Bỏ PageHeader lặp tiêu đề breadcrumb; nội dung thông báo giữ nguyên |
| Admin | Support ticket | Bỏ PageHeader; transition giữ trong StatusPanel và note form giữ trong panel Notes |

## Các ngoại lệ có chủ đích

- `QuestionEditorView` và `ScoreTemplateEditorView` là route authoring riêng, không phải view detail; không nhúng toàn bộ editor chuyên dụng vào detail.
- Các modal `ImportOrAssignModal`, `CreateLoginAccountModal`, `ResetPasswordModal` và confirm dialog không phải form chỉnh sửa thông tin bản ghi nên được giữ nguyên.
- Proctor session/audit-log là workspace vận hành; API hiện tại không cung cấp metadata tên bản ghi phù hợp cho breadcrumb detail nên không tự tạo tên giả.

## Kiểm tra trực quan

- Program overview: breadcrumb `Chương trình > Test`, không còn heading `Test` lặp; status, Edit và menu nằm trong panel `Thông tin chương trình`.
- Program edit: form tên, mô tả, ngày bắt đầu/kết thúc hiển thị ngay trong panel, không mở modal.
- Class overview: breadcrumb `Lớp học > Class 1`, không còn heading `Class 1` lặp; status và Edit nằm trong panel thông tin.
- Class edit: form tên lớp hiển thị inline, các thuộc tính chỉ đọc vẫn giữ bên dưới.

Ảnh bằng chứng đã được dọn theo yêu cầu; kết quả rà soát được giữ trong nội dung báo cáo.


## Xác minh kỹ thuật

- `pnpm --filter tenant-web exec tsc --noEmit`: pass
- `pnpm --filter vendor-web exec tsc --noEmit`: pass
- `pnpm --filter tenant-web lint`: pass
- `pnpm --filter vendor-web lint`: pass với 2 warning `@next/next/no-img-element` đã tồn tại ở QuestionDetailView/QuestionEditorForm
- `pnpm --filter tenant-web build`: pass
- `pnpm --filter vendor-web build`: pass
- `git diff --check`: pass
- Browser smoke test: Program overview/edit, Class overview/edit, Admin Question detail và Admin Announcement detail đều render đúng; không phát sinh console error ở các route đã kiểm tra.

Build vẫn in warning cấu hình `turbopack.root should be absolute`, đây là warning cấu hình hiện có và không liên quan thay đổi detail UI.
