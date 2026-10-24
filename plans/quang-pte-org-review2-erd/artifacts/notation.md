# Quy ước đọc ERD

- Core overview là conceptual, không khẳng định mỗi hộp là một bảng. Organization gộp tenants/organizations; các vai trò là User.
- Detail là logical với bounds của source storage. Thuộc tính được chọn để giải thích nghiệp vụ; inventory giữ schema metadata rộng hơn.
- Crow's Foot: || = đúng 1; o| (phía phải) hoặc |o (phía trái) = 0..1; o{ / }o = 0..n. Đọc từng đầu ứng với một instance ở đầu đối diện.
- Mọi đường nối dùng dấu .. (non-identifying) vì các entity có surrogate identity độc lập. Nét đứt không mã hóa loại FK; xem key FK và relationship register.
- PK chỉ dành cho khóa chính đã chứng minh; UK cho unique column; FK chỉ khi source migration có REFERENCES. UUID public_id là UK, không tự động là PK.
- FK composite được lưu đủ tuple trong relationships.json. Có thể lược cột trong hộp để hình dễ đọc; không suy cardinality từ danh sách thuộc tính hiển thị.
- Logical reference dùng parent min=0 để thể hiện giới hạn resolve từ storage; business flow có thể bắt buộc owner hợp lệ. NOT VALID FK không bảo đảm toàn bộ dữ liệu cũ đã validate. Không biến 0..1 thành quyền tạo dữ liệu orphan.
- REL-* ID và ENT-* ID được giữ trong comment nguồn và dictionary. Theo yêu cầu người dùng, mọi title/entity/relationship/attribute/comment trong .mmd dùng tiếng Anh; nhãn entity giữ class name để đối chiếu source. Entity lặp giữa các trang dùng cùng ID.
- Không có mũi tên tiến trình; Question/Snapshot ở core là provenance M:N qua SnapshotItem. Main snapshot của ca thi là optional reference; các mã đề riêng xem trang 05.

Font trong nguồn 18px, Arial, nền trắng. Xem SVG ở tỷ lệ 100% để đọc chi tiết; khi đưa vào slide chỉ dùng core hoặc một detail page, không thu nhỏ tất cả trang vào một slide.
