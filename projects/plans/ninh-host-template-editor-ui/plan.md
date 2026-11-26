# Màn chỉnh sửa Mẫu bài thi (tenant-web) — chỉnh UI

**Trạng thái:** đã làm, chưa commit. Phạm vi: `apps/tenant-web/features/hostTemplates` (không đụng `SectionedTableCard` dùng chung nên màn mẫu của vendor-web giữ nguyên).

## Cột "Có / cần" trống: lỗi frontend, không phải thiếu dữ liệu
API `/host/exam-templates/{id}/feasibility` trả đủ từng dạng bài (`available`, `required`). Bug ở `HostTemplateEditorView`: bộ nhớ số câu có sẵn được khởi tạo rỗng, còn "ghi nhận câu trả lời mới" chỉ chạy khi dữ liệu **đổi**. Khi dữ liệu đã nằm trong cache TanStack Query (vào lại trang từ danh sách) thì nó không đổi, nên cột có tiêu đề nhưng ô trống. Tải lại trang (F5) thì hiện đúng. Sửa: khởi tạo từ dữ liệu đã có (`rememberAvailable(new Map(), feasibility.data)`). Ô nào server không báo thì hiện `—`.

## Bố cục
- Bỏ cột trái 3 thẻ. Đầu trang: tên mẫu (bút chì để đổi tên), badge trạng thái + Chuẩn Pearson, nút Lưu + menu `…`, một dòng nhỏ "v1 · Ngày tạo … · Cập nhật lần cuối …" (`HostTemplateHeader`, thay `HostTemplateInfoPanel`).
- Bộ lọc kỹ năng thành hàng tab ngang có chấm màu + số lượng (`Tabs variant="minimal"`, cùng kiểu trang Prompt).
- Thẻ "Dạng bài có thể thêm" thành nút `+ Thêm dạng bài` (cùng hàng với tab Số câu/Trọng số), mở menu liệt kê dạng còn thêm được; vô hiệu kèm tooltip khi đã đủ (`AddTaskTypeMenu`, dùng hook `useAnchoredPanel` của `@pte/ui`).
- `Thời lượng dự kiến` chuyển xuống dưới bảng.

## Bảng
- Dòng tổng "Tổng: 65–85 câu" theo tab đang chọn, cập nhật khi sửa.
- Chuẩn bị/Trả lời: `0` → `—`; ≥ 60 giây hiện theo phút (`10 phút`, `2 phút`, `1 phút 30 giây`); bỏ "(giây)" khỏi tiêu đề cột.
- Thùng rác xám, chỉ đỏ khi rê chuột.
- Tên dạng bài theo catalogue (`question_types.display_name`): "Re-tell Lecture", "Respond to a Situation", "Fill in the Blanks (Dropdown)"… Bảng tên nằm ở `utils/taskTypeLabel.ts` (tenant chưa có API catalogue; vendor dùng `displayName` từ API).

## Cố ý bỏ
- Kéo-thả dạng bài từ thẻ vào bảng và kéo dòng ra để xóa: hết nơi thả khi thẻ bên cạnh thành nút. Thêm bằng menu, xóa bằng nút thùng rác; kéo đổi thứ tự dòng vẫn còn. Đã xóa `TASK_TYPE_DRAG_TYPE`/`PALETTE_DROP_ATTRIBUTE` của tenant.
- Logic lưu/kích hoạt/cân trọng số giữ nguyên.

## Vòng 2 (theo nhận xét review)
- `Thời lượng dự kiến` dàn thành một hàng 4 cột: Nói & Viết, Đọc, Nghe và **Tổng dự kiến** (134–165 phút), làm tròn phút (71–81 thay vì 71.1–81.3). Thêm tùy chọn cho `DurationSummary` dùng chung (`layout="row"`, `roundMinutes`, `copy.total`), mặc định tắt nên màn mẫu của vendor-web giữ nguyên.
- Công tắc `Số câu | Trọng số` đổi sang kiểu segmented (khay xám, nút được chọn nổi) để khác thanh tab kỹ năng gạch chân. Thêm biến thể `segmented` cho `Tabs` dùng chung (tùy chọn).
- Nhãn tổng đổi theo tab: "Tổng: 65–85 câu" ở tab Tất cả, "Đọc: 15–20 câu" ở tab một kỹ năng.
