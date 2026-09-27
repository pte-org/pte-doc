# PTE Exam App — bản export Stitch

Nguồn: [project Stitch 72925006002767125](https://stitch.withgoogle.com/projects/72925006002767125).

Mở `index.html` bằng trình duyệt để xem thư viện và tìm theo tên màn hình. Bấm ảnh để mở PNG đầy đủ; có thể phóng to để xem chi tiết.

- 34 màn hình hiển thị: mỗi màn hình có PNG độ phân giải gốc, HTML nguyên bản và metadata.
- Hai bản Read Aloud được giữ riêng theo screen ID, không gộp theo tên.
- Ba mục ẩn trong project là tài liệu: component specification (Markdown), design tokens (JSON) và CSS custom properties. Các mục này không có ảnh tải được.
- `DESIGN.md` và `design-theme.json`: design system trả về từ project.
- `project.json` và `screens-api.json`: dữ liệu gốc của các lệnh đọc MCP.
- `manifest.json`: danh mục, thời điểm export UTC, kích thước ảnh thực tế, dung lượng và SHA-256 của từng artifact.

Ảnh PNG tải trực tiếp từ Stitch ở kích thước gốc, không cắt theo viewport hoặc resize. Thư viện và PNG có thể xem offline; HTML gốc có thể cần mạng để tải font, ảnh và thư viện bên ngoài.

Thứ tự thư mục theo tọa độ dọc trên canvas Stitch, rồi screen ID; đây không phải thứ tự điều hướng đã xác nhận. Tên và nội dung thiết kế được giữ nguyên để tham chiếu khi triển khai.

Không có API key trong bộ export. Export chỉ đọc dữ liệu từ Stitch.
