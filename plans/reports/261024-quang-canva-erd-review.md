# Canva ERD handoff — 2026-10-24

[Thiết kế Review 2 Official trên Canva](https://www.canva.com/design/DAHY1E4oIkE/7g6JUYyxy_rWJdC33tD9ig/edit).

Đã điền ba trang ERD có sẵn trong deck 14 trang, giữ tiêu đề và phong cách nền xanh nhạt.

| Trang | Nội dung |
|---|---|
| 2 | Core ERD: 8 bảng, 10 quan hệ; bố cục tập trung để thuyết trình |
| 3 | Exam Setup: 12 bảng; hướng dẫn đọc theo nhóm ở cột phải |
| 4 | Delivery, Grading and Reporting: 12 bảng, 17 quan hệ; chú giải khóa và shared anchors ở cột phải |

Hai trang chi tiết bao phủ 21 bảng khác nhau. Các hình được chèn bằng clipboard sau khi người dùng đăng nhập. Text hướng dẫn và legend là Canva text có thể chỉnh sửa; sơ đồ trên Canva là ảnh độ phân giải cao.

## Kiểm tra lúc bàn giao

Đã xem trực tiếp cả ba trang trong chế độ trình chiếu, đối chiếu 27 relationship instances sau khi đổi hướng hiển thị và kiểm tra PK/UK/FK. Independent code/visual review không thấy lỗi nghiêm trọng về clipping hoặc overlap.

Canva báo đã lưu tất cả thay đổi. Sau reload, thiết kế vẫn có 14 trang và mở được trang ERD đã lưu. Đây là kiểm tra tại thời điểm bàn giao, không phải cam kết trạng thái Canva ở các lần chỉnh sửa sau.

## Sau khi dọn file

Theo yêu cầu người dùng, ảnh chụp trình chiếu, SVG/PNG local và script Python đã được xóa; các nguồn Mermaid local được giữ nhưng không commit. Việc dọn file không xóa hình hoặc thay đổi thiết kế trên Canva.

Xem [tài liệu ERD](../quang-pte-org-review2-erd/README.md) và [field thiết yếu](../quang-pte-org-review2-erd/mermaid-essential-fields/field-selection.md). Bộ field thiết yếu được tạo sau phần Canva nên không mặc định rằng các ảnh trên Canva đã chứa toàn bộ field của bộ mới.
