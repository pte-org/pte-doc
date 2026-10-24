# Mermaid ERD — field thiết yếu

Đây là bộ Mermaid dùng để đối chiếu thiết kế khi Review 2. Các logical ERD đã được bổ sung field quan trọng từ source; không đưa toàn bộ cột database vào hình.

## Mở đúng phần

| Nhóm | Nội dung | File |
|---|---|---|
| Core | Bản 8 bảng trung tâm | `01-core-overview/quang-00-core-erd.mmd` (local) |
| Core | Thiết lập ca thi, 12 bảng | `01-core-overview/quang-01-core-exam-setup.mmd` (local) |
| Core | Làm bài, chấm điểm và báo cáo, 12 bảng | `01-core-overview/quang-02-core-delivery-grading.mmd` (local) |
| Core | Overview conceptual 11 khái niệm, chỉ để giới thiệu | `01-core-overview/quang-00-conceptual-overview.mmd` (local) |
| Business | 10 trang, 62 bảng nghiệp vụ khác nhau | `02-business-details/` (local) |
| Technical | 7 trang, 31 bảng kỹ thuật khác nhau | `03-technical-mapping/` (local) |

Hai trang core logical bao phủ 21 bảng khác nhau; các bảng lặp lại là anchor, không phải bảng mới. Core 8 là subset để tập trung giải thích. Bộ business và technical bao phủ 93 bảng.

## Tiêu chí chọn field

- Giữ PK, public_id và những cột cần cho khóa unique/khóa ghép và tham chiếu đã đối chiếu source.
- Giữ thông tin định danh nghiệp vụ, owner/tenant cần thiết, trạng thái, thời gian mở/đóng/nộp/công bố và dữ liệu chính của từng đối tượng.
- Giữ payload câu trả lời, điểm, nguồn điểm, nội dung đề đã chốt và thông tin báo cáo vì đây là dữ liệu quan trọng của luồng thi/chấm.
- Không tự thêm created_at, updated_at, deleted, version, token/lease, fingerprint, runtime metadata vào mọi bảng. Một số bảng log/job/auth vẫn cần các field tương ứng để mô tả đúng chức năng của chúng.
- Giữ một lựa chọn field nhất quán cho cùng bảng ở mọi trang logical.

Ví dụ: ExamSession có mã/tên ca, tenant, tham chiếu đề/mẫu điểm/subscription, trạng thái, lịch mở/đóng, sức chứa và chế độ thi. ExamAttempt có học sinh, ca thi, trạng thái, số lần thử và thời gian bắt đầu/nộp/hết giờ. AttemptAnswer có attempt, pinned item, payload và trạng thái. ScoringAnswer có nguồn chấm, điểm, trạng thái và thời gian chấm. AttemptReport có học sinh/ca/tenant, trạng thái công bố, thời gian và snapshot báo cáo.

## Các điểm cần đọc đúng khi bảo vệ

- Tên cột, kiểu storage và nullable được đối chiếu migration hiện tại. Kiểu Mermaid là ký hiệu trình bày; comment bên cạnh giữ kiểu SQL và NULL/NOT NULL.
- FK chỉ dùng khi có ràng buộc database. UUID logical references vẫn giữ cột tham chiếu, nhưng không gắn nhãn FK giả.
- UK trên một field chỉ biểu thị uniqueness của riêng field đó. Khóa unique ghép và partial indexes có ghi chú riêng, không biến thành nhiều field UK độc lập.
- Nét đứt là non-identifying relationship. Với logical reference và NOT VALID FK, xem giới hạn cardinality trong register gốc; NOT NULL không tự chứng minh row đích tồn tại.
- Các liên kết qua bảng ngoài trang giữ field tham chiếu nhưng không thêm đường nối đến entity không xuất hiện trong trang.
- Bản conceptual 11 khái niệm có gộp Organization/Tenant ở mức khái niệm; dùng hai bản core logical khi cần đối chiếu từng bảng với code.

[Bảng giải thích field được giữ/lược bỏ theo từng bảng](field-selection.md) · [Metadata kiểm tra](field-selection.json).

## Sử dụng

Mở file `.mmd`, copy nội dung vào công cụ hỗ trợ Mermaid. Khi chuyển sang Draw.io, chọn dạng diagram có thể chỉnh sửa. Các trang detail có nhiều field hơn bản slide cũ, nên dùng để giải thích chi tiết hoặc appendix.

Bộ này chỉ thay đổi source ERD bổ sung trong folder riêng. Không thay đổi database, code ứng dụng hoặc các slide Canva đã lưu.

## Chính sách commit

Theo yêu cầu người dùng ngày 2026-10-24, các file `.mmd` chỉ giữ local và được `.gitignore` loại khỏi commit. Bảng trên liệt kê đường dẫn local; clone repo sẽ chỉ có README và metadata lựa chọn field. SVG/PNG, ảnh chụp, Draw.io, ZIP và script Python đã được dọn. Các thay đổi này không ảnh hưởng hình đã chèn trên Canva.
