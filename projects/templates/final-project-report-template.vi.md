# Báo cáo 7 — Báo cáo cuối dự án

## Kiểm soát tài liệu

| Trường thông tin | Giá trị |
|---|---|
| Nguồn template | Report7_Final Project Report.docx |
| Trạng thái template | Bản nháp |
| Tên dự án | [Tên dự án] |
| Mã dự án | [Mã dự án] |
| Nhóm | [Tên nhóm / lớp] |
| Phiên bản | [Phiên bản] |
| Ngày | [YYYY-MM-DD] |
| Người lập | [Tên / vai trò] |
| Giảng viên hướng dẫn | [Tên] |
| Giảng viên hướng dẫn ngoài | [Tên hoặc Không áp dụng] |
| Trạng thái phê duyệt | [Bản nháp / Đã review / Đã duyệt] |

> **Cách sử dụng template:** Đây là khung báo cáo cuối dự án. Thay mọi
> phần giữ chỗ bằng nội dung và bằng chứng của dự án, giữ thứ tự các phần trừ
> khi trường yêu cầu định dạng khác. Báo cáo tập hợp phần giới thiệu dự án,
> kế hoạch quản lý, yêu cầu, thiết kế, kiểm thử và gói phát hành/hướng dẫn sử
> dụng. Có thể tham chiếu các tài liệu Report 3, 4, 5 và 6 riêng, nhưng báo
> cáo cuối phải chỉ rõ phiên bản cuối đã được phê duyệt.

> **Quy tắc nhất quán:** Dùng một tên dự án, một mã dự án, một danh sách thành
> viên, một bộ thuật ngữ vai trò và một lịch sử phiên bản trong toàn bộ báo
> cáo. Mã yêu cầu, thiết kế, kiểm thử, hình, bảng và bản phát hành phải giữ
> ổn định khi được tham chiếu giữa các phần.

## Bảng ghi nhận thay đổi

| Ngày | A*M, D | Người phụ trách | Mô tả thay đổi | Tham chiếu |
|---|---|---|---|---|
| [YYYY-MM-DD] | A | [Tên] | [Cấu trúc/nội dung báo cáo cuối được thêm] | [Review/quyết định] |
| [YYYY-MM-DD] | M | [Tên] | [Cập nhật phần, yêu cầu, thiết kế hoặc bằng chứng kiểm thử] | [Tham chiếu] |
| [YYYY-MM-DD] | D | [Tên] | [Nội dung bị xóa hoặc thay thế] | [Tham chiếu] |
|  |  |  |  |  |
|  |  |  |  |  |
|  |  |  |  |  |
|  |  |  |  |  |
|  |  |  |  |  |
|  |  |  |  |  |
|  |  |  |  |  |
|  |  |  |  |  |
|  |  |  |  |  |
|  |  |  |  |  |

*A — Thêm; M — Sửa; D — Xóa. Ghi các thay đổi thực chất đối với báo cáo hoặc
baseline đã duyệt của dự án.*

---

## Phần đầu báo cáo

### Trang bìa

Dùng định dạng trang bìa được trường phê duyệt. Tối thiểu cần có:

- tên trường và khoa;
- tên dự án và mã dự án;
- tên môn học hoặc capstone;
- tên nhóm và lớp;
- toàn bộ thành viên và mã sinh viên;
- giảng viên hướng dẫn và hướng dẫn ngoài nếu có;
- ngày nộp và phiên bản báo cáo.

| Hạng mục | Giá trị |
|---|---|
| Trường | [Tên trường] |
| Khoa | [Tên khoa] |
| Dự án capstone | [Tên môn/capstone] |
| Tên dự án | [Tên dự án] |
| Mã dự án | [Mã] |
| Nhóm / lớp | [Nhóm/lớp] |
| Ngày nộp | [YYYY-MM-DD] |

### Lời cảm ơn

Viết lời cảm ơn cụ thể cho những người, tổ chức và nguồn lực đã hỗ trợ
thực chất cho dự án. Không khẳng định việc được phê duyệt, hợp tác, chứng
nhận hoặc sở hữu sản phẩm nếu không có bằng chứng.

[Viết lời cảm ơn của nhóm tại đây.]

### Định nghĩa và từ viết tắt

Định nghĩa các thuật ngữ và từ viết tắt trong báo cáo. Dùng cùng ý nghĩa
trong SRS, thiết kế, kiểm thử và hướng dẫn sử dụng. Nếu là thuật ngữ nghiệp
vụ hướng tới người dùng, hãy viết nghĩa thông thường trước nghĩa kỹ thuật.

| Từ viết tắt / thuật ngữ | Định nghĩa | Phần sử dụng đầu tiên | Ghi chú |
|---|---|---|---|
| [THUẬT_NGỮ] | [Định nghĩa] | [Phần] | [Ghi chú] |
| [THUẬT_NGỮ] | [Định nghĩa] | [Phần] | [Ghi chú] |
| [THUẬT_NGỮ] | [Định nghĩa] | [Phần] | [Ghi chú] |

---

# I. Giới thiệu dự án

Phần này giải thích lý do dự án tồn tại, sản phẩm được xây dựng cho ai và
ranh giới của sản phẩm. Nội dung phải thống nhất với phiếu đăng ký dự án và
SRS cuối cùng.

## 1. Tổng quan

### 1.1 Thông tin dự án

Cung cấp metadata và mô tả cấp cao đầy đủ nhưng ngắn gọn. Nêu vấn đề, người
dùng, dạng sản phẩm, bối cảnh dự án và không khẳng định năng lực ngoài phạm
vi đã duyệt.

| Hạng mục | Mô tả |
|---|---|
| Tên dự án | [Tên] |
| Mã dự án | [Mã] |
| Loại sản phẩm | [Web/mobile/desktop/service, ...] |
| Người dùng mục tiêu | [Vai trò và đối tượng] |
| Vấn đề giải quyết | [Phát biểu vấn đề] |
| Kết quả chính | [Kết quả] |
| Ranh giới bàn giao | [Nhóm bàn giao gì] |
| Phụ thuộc đã biết | [Phụ thuộc hoặc giả định] |

### 1.2 Nhóm dự án

Liệt kê thành viên và các bên liên quan. Phân biệt người sở hữu công việc với người
review hoặc phê duyệt.

| Họ tên | Mã sinh viên/nhân sự | Vai trò dự án | Trách nhiệm chính | Trách nhiệm phê duyệt/review |
|---|---|---|---|---|
| [Tên] | [Mã] | [Vai trò] | [Trách nhiệm] | [Trách nhiệm] |
| [Tên] | [Mã] | [Vai trò] | [Trách nhiệm] | [Trách nhiệm] |

## 2. Bối cảnh sản phẩm

Giải thích tình hình dẫn đến ý tưởng sản phẩm. Mô tả vấn đề hiện tại, người
bị ảnh hưởng, cách xử lý hiện tại và người hoặc tổ chức đưa ra nhu cầu. Tách
rõ sự kiện đã quan sát khỏi giả định.

| Điểm bối cảnh | Bằng chứng hoặc nguồn | Tác động đến người dùng/tổ chức | Liên quan đến sản phẩm |
|---|---|---|---|
| [Tình hình hiện tại] | [Phỏng vấn, quan sát, tài liệu] | [Tác động] | [Lý do quan trọng] |
| [Nỗi đau/vấn đề] | [Bằng chứng] | [Tác động] | [Phản hồi của sản phẩm] |

## 3. Hệ thống hiện có

Mô tả hệ thống có thể giải quyết một phần vấn đề hoặc được xem xét làm tài
liệu tham khảo. Không hàm ý dự án tích hợp, đại diện, được chứng nhận hoặc
thuộc sở hữu sản phẩm bên ngoài nếu quan hệ đó chưa được thiết lập chính
thức.

| Hệ thống / tài liệu tham khảo | Mục đích | Khả năng liên quan | Giới hạn đối với dự án | Quan hệ với sản phẩm đề xuất |
|---|---|---|---|---|
| [Hệ thống] | [Mục đích] | [Khả năng] | [Giới hạn] | [Tham khảo/thay thế/tích hợp/không có] |
| [Hệ thống] | [Mục đích] | [Khả năng] | [Giới hạn] | [Quan hệ] |

## 4. Cơ hội nghiệp vụ

Mô tả vấn đề nghiệp vụ hoặc tổ chức cần giải quyết và môi trường sử dụng sản
phẩm. So sánh cẩn thận với phương án hiện tại, người hưởng lợi và lý do sản
phẩm hấp dẫn. Không đưa số liệu thị trường chưa có nguồn.

| Cơ hội / vấn đề | Phương án hiện tại | Khoảng trống | Phản hồi của sản phẩm | Lợi ích dự kiến |
|---|---|---|---|---|
| [Vấn đề] | [Phương án] | [Khoảng trống] | [Phản hồi] | [Lợi ích] |
| [Vấn đề] | [Phương án] | [Khoảng trống] | [Phản hồi] | [Lợi ích] |

## 5. Tầm nhìn sản phẩm phần mềm

Viết một câu tầm nhìn ngắn gọn rồi giải thích trạng thái mong muốn trong
tương lai. Tầm nhìn cần cân bằng nhu cầu người dùng, giá trị tổ chức, ràng
buộc kỹ thuật, nguồn lực và phạm vi dự án đã duyệt.

> **Tuyên bố tầm nhìn:** [Một hoặc hai câu mô tả mục đích sản phẩm và tình
> hình được cải thiện nhờ sản phẩm.]

| Thành phần tầm nhìn | Mô tả |
|---|---|
| Người dùng mục tiêu | [Ai được hưởng lợi] |
| Vấn đề người dùng | [Vấn đề] |
| Cam kết sản phẩm | [Giá trị cung cấp] |
| Khả năng khác biệt | [Khả năng] |
| Ràng buộc đã thừa nhận | [Ràng buộc] |
| Hướng tương lai | [Hướng có thể làm sau, ghi rõ là tương lai] |

## 6. Phạm vi và giới hạn dự án

Xác định ranh giới giải pháp. Liệt kê nội dung trong phạm vi, ngoài phạm vi,
giả định, phụ thuộc và giới hạn. Tính năng ngoài ranh giới cần có quyết định
phạm vi và đánh giá ảnh hưởng đến thời gian, công sức, chất lượng và rủi ro.

### 6.1 Tính năng trong phạm vi

| Mã tính năng | Tính năng | Giá trị người dùng | Bản phát hành | Yêu cầu liên quan |
|---|---|---|---|---|
| F-01 | [Tính năng] | [Giá trị] | [Bản phát hành] | [Mã FR/UC] |
| F-02 | [Tính năng] | [Giá trị] | [Bản phát hành] | [Mã] |

### 6.2 Tính năng ngoài phạm vi

| Nội dung loại trừ | Lý do | Tác động đến người dùng | Hướng xử lý tương lai |
|---|---|---|---|
| [Tính năng/khả năng] | [Lý do] | [Tác động] | [Quyết định tương lai/Không dự kiến] |
| [Tính năng/khả năng] | [Lý do] | [Tác động] | [Quyết định tương lai] |

### 6.3 Giả định, phụ thuộc và giới hạn

| Loại | Nội dung | Người phụ trách | Tác động nếu sai/không có | Biện pháp |
|---|---|---|---|---|
| Giả định | [Nội dung] | [Người phụ trách] | [Tác động] | [Biện pháp] |
| Phụ thuộc | [Phụ thuộc] | [Người phụ trách] | [Tác động] | [Biện pháp] |
| Giới hạn | [Giới hạn đã biết] | [Người phụ trách] | [Tác động] | [Biện pháp/truyền thông] |

---

# II. Kế hoạch quản lý dự án

Phần này ghi lại cách nhóm lập kế hoạch, ước lượng, phối hợp, review và
kiểm soát công việc. Mô tả những gì thực tế đã dùng và nêu khác biệt đáng kể
giữa kế hoạch với kết quả cuối.

## 1. Tổng quan

### 1.1 Phạm vi và ước lượng

Liệt kê chức năng sản phẩm và phân loại độ phức tạp. Giải thích cơ sở ước
lượng, giả định, phụ thuộc và thay đổi so với ước lượng ban đầu.

| Tính năng/chức năng | Độ phức tạp | Công sức dự kiến | Công sức thực tế | Cơ sở/giả định | Mã yêu cầu |
|---|---|---:|---:|---|---|
| [Tính năng] | [Đơn giản/Trung bình/Phức tạp] | [Công sức] | [Công sức] | [Cơ sở] | [Mã] |
| [Tính năng] | [Đơn giản/Trung bình/Phức tạp] | [Công sức] | [Công sức] | [Cơ sở] | [Mã] |

| Tóm tắt ước lượng | Dự kiến | Thực tế | Chênh lệch | Giải thích |
|---|---:|---:|---:|---|
| Yêu cầu | [Giá trị] | [Giá trị] | [Giá trị] | [Giải thích] |
| Thiết kế | [Giá trị] | [Giá trị] | [Giá trị] | [Giải thích] |
| Phát triển | [Giá trị] | [Giá trị] | [Giá trị] | [Giải thích] |
| Kiểm thử | [Giá trị] | [Giá trị] | [Giá trị] | [Giải thích] |
| Quản lý/tài liệu | [Giá trị] | [Giá trị] | [Giá trị] | [Giải thích] |

### 1.2 Mục tiêu dự án

Nêu mục tiêu chung và mục tiêu cụ thể về phạm vi, chất lượng, lịch, công sức,
khả dụng, độ tin cậy và chấp nhận của bên liên quan. Đánh dấu mục tiêu là dự
kiến, đạt, đạt một phần hoặc chưa đo, đồng thời liên kết bằng chứng.

| Mã mục tiêu | Mục tiêu / đích | Thước đo | Giá trị dự kiến | Kết quả cuối | Trạng thái | Bằng chứng |
|---|---|---|---|---|---|---|
| OBJ-01 | [Mục tiêu] | [Thước đo] | [Mục tiêu] | [Kết quả] | [Trạng thái] | [Liên kết] |
| OBJ-02 | [Mục tiêu] | [Thước đo] | [Mục tiêu] | [Kết quả] | [Trạng thái] | [Liên kết] |

### 1.3 Rủi ro dự án

Ghi lại rủi ro ảnh hưởng đến phạm vi, lịch, chất lượng, chi phí, con người,
công nghệ, bảo mật, dữ liệu hoặc chấp nhận của bên liên quan. Bao gồm cả rủi
ro còn tồn tại khi bàn giao.

| Mã rủi ro | Mô tả rủi ro | Nguyên nhân | Khả năng | Tác động | Mức phơi nhiễm | Biện pháp/ứng phó | Người phụ trách | Trạng thái |
|---|---|---|---|---|---|---|---|---|
| R-01 | [Rủi ro] | [Nguyên nhân] | [Thấp/Trung bình/Cao] | [Thấp/Trung bình/Cao] | [Đánh giá] | [Ứng phó] | [Tên] | [Mở/đóng] |
| R-02 | [Rủi ro] | [Nguyên nhân] | [Mức] | [Mức] | [Đánh giá] | [Ứng phó] | [Tên] | [Trạng thái] |

## 2. Cách tiếp cận quản lý

Mô tả cách nhóm tổ chức và kiểm soát công việc, gồm lập kế hoạch, ưu tiên,
review, kiểm soát thay đổi, truyền thông, kiểm tra chất lượng, chuyển cấp và
quyết định phát hành.

| Thực hành quản lý | Cách áp dụng | Người phụ trách | Bằng chứng |
|---|---|---|---|
| Lập kế hoạch và ưu tiên | [Quy trình] | [Vai trò] | [Backlog/kế hoạch] |
| Kiểm soát thay đổi | [Quy trình] | [Vai trò] | [Bảng thay đổi] |
| Review và phê duyệt | [Quy trình] | [Vai trò] | [Biên bản review] |
| Chuyển cấp issue/rủi ro | [Quy trình] | [Vai trò] | [Danh sách] |

### 2.1 Quy trình dự án

Vẽ và mô tả mô hình phát triển phần mềm mà nhóm dùng. Thể hiện công việc đi
từ ý tưởng hoặc yêu cầu qua phân tích, thiết kế, phát triển, kiểm thử,
review và phát hành. Giải thích cách quay lại bước trước khi phát hiện lỗi
hoặc có quyết định mới.

<!-- Chèn sơ đồ quy trình dự án tại đây. -->

> **Vị trí sơ đồ:** Hình PM-01 — [Quy trình phát triển phần mềm]

| Giai đoạn | Đầu vào | Hoạt động chính | Đầu ra | Quyết định bắt đầu/kết thúc | Người phụ trách |
|---|---|---|---|---|---|
| Yêu cầu | [Đầu vào] | [Hoạt động] | [Đầu ra] | [Quyết định] | [Vai trò] |
| Thiết kế | [Đầu vào] | [Hoạt động] | [Đầu ra] | [Quyết định] | [Vai trò] |
| Phát triển | [Đầu vào] | [Hoạt động] | [Đầu ra] | [Quyết định] | [Vai trò] |
| Kiểm thử | [Đầu vào] | [Hoạt động] | [Đầu ra] | [Quyết định] | [Vai trò] |
| Phát hành | [Đầu vào] | [Hoạt động] | [Đầu ra] | [Quyết định] | [Vai trò] |

### 2.2 Quản lý chất lượng

Giải thích cách nhóm lập kế hoạch và đánh giá chất lượng. Bao gồm review yêu
cầu, review thiết kế, review mã nguồn, kiểm tra tự động, chạy test, phân loại
lỗi, review tài liệu, kiểm tra quyền/bảo mật và chấp nhận. Phân biệt mục tiêu
dự kiến với kết quả đã đo.

| Hoạt động chất lượng | Thời điểm | Điều kiện bắt đầu | Tiêu chí hoàn thành | Bằng chứng | Người phụ trách |
|---|---|---|---|---|---|
| Review yêu cầu | [Thời điểm] | [Tiêu chí] | [Tiêu chí] | [Bằng chứng] | [Vai trò] |
| Review thiết kế | [Thời điểm] | [Tiêu chí] | [Tiêu chí] | [Bằng chứng] | [Vai trò] |
| Review triển khai | [Thời điểm] | [Tiêu chí] | [Tiêu chí] | [Bằng chứng] | [Vai trò] |
| Review kiểm thử | [Thời điểm] | [Tiêu chí] | [Tiêu chí] | [Bằng chứng] | [Vai trò] |

### 2.3 Kế hoạch đào tạo

Xác định khoảng trống kiến thức hoặc kỹ năng và hoạt động đào tạo cần để
hoàn thành dự án. Bao gồm kỹ năng kỹ thuật và thực hành dự án như viết yêu
cầu, kiểm thử, tài liệu, bảo mật hoặc dùng công cụ.

| Nhu cầu đào tạo | Đối tượng | Người/tài nguyên đào tạo | Phương pháp | Ngày dự kiến | Bằng chứng hoàn thành |
|---|---|---|---|---|---|
| [Nhu cầu] | [Thành viên/vai trò] | [Người/tài nguyên] | [Workshop/tự học] | [Ngày] | [Bằng chứng] |
| [Nhu cầu] | [Thành viên/vai trò] | [Tài nguyên] | [Phương pháp] | [Ngày] | [Bằng chứng] |

## 3. Sản phẩm bàn giao của dự án

Liệt kê sản phẩm bàn giao nội bộ và bên ngoài, người sở hữu, trạng thái
phê duyệt và vị trí. Bao gồm gói phát hành cuối và tài liệu cần cho bàn giao.

| Sản phẩm bàn giao | Mô tả | Người phụ trách | Phiên bản | Ngày dự kiến/thực tế | Bằng chứng chấp nhận | Vị trí |
|---|---|---|---|---|---|---|
| [Sản phẩm] | [Mô tả] | [Vai trò] | [Phiên bản] | [Ngày] | [Bằng chứng] | [Liên kết] |
| [Sản phẩm] | [Mô tả] | [Vai trò] | [Phiên bản] | [Ngày] | [Bằng chứng] | [Liên kết] |

## 4. Phân công trách nhiệm

Mô tả ai chịu trách nhiệm tạo, review, phê duyệt và nhận từng đầu ra quan
trọng. Dùng bảng RACI hoặc cách trình bày rõ ràng tương đương.

| Sản phẩm / hoạt động | Thực hiện | Chịu trách nhiệm cuối | Tham vấn | Được thông báo |
|---|---|---|---|---|
| Phạm vi dự án | [Tên/vai trò] | [Tên/vai trò] | [Tên/vai trò] | [Tên/vai trò] |
| SRS | [Tên/vai trò] | [Tên/vai trò] | [Tên/vai trò] | [Tên/vai trò] |
| Thiết kế | [Tên/vai trò] | [Tên/vai trò] | [Tên/vai trò] | [Tên/vai trò] |
| Kiểm thử | [Tên/vai trò] | [Tên/vai trò] | [Tên/vai trò] | [Tên/vai trò] |
| Phát hành/hướng dẫn | [Tên/vai trò] | [Tên/vai trò] | [Tên/vai trò] | [Tên/vai trò] |

## 5. Truyền thông dự án

Mô tả kế hoạch giao tiếp, công cụ, đối tượng, tần suất, thông tin chia sẻ và
cách ghi nhận quyết định. Không dùng tin nhắn chat không chính thức làm bản
ghi duy nhất cho quyết định thay đổi phạm vi hoặc chất lượng.

| Hoạt động truyền thông | Đối tượng | Mục đích | Kênh/công cụ | Tần suất/kích hoạt | Người phụ trách | Nơi ghi quyết định |
|---|---|---|---|---|---|---|
| [Họp/review] | [Đối tượng] | [Mục đích] | [Công cụ] | [Tần suất] | [Vai trò] | [Vị trí] |
| [Báo cáo trạng thái] | [Đối tượng] | [Mục đích] | [Công cụ] | [Tần suất] | [Vai trò] | [Vị trí] |

## 6. Quản lý cấu hình

Giải thích cách nhóm định danh, tạo phiên bản, review, lưu trữ và phát hành
tài liệu, mã nguồn, cấu hình, bằng chứng kiểm thử và các baseline khác.

### 6.1 Quản lý tài liệu

| Loại tài liệu | Quy tắc đặt tên/phiên bản | Nơi lưu | Review/phê duyệt | Bảng thay đổi | Quyền truy cập |
|---|---|---|---|---|---|
| Yêu cầu | [Quy tắc] | [Vị trí] | [Quy trình] | [Bảng] | [Vai trò] |
| Thiết kế | [Quy tắc] | [Vị trí] | [Quy trình] | [Bảng] | [Vai trò] |
| Kiểm thử | [Quy tắc] | [Vị trí] | [Quy trình] | [Bảng] | [Vai trò] |
| Hướng dẫn | [Quy tắc] | [Vị trí] | [Quy trình] | [Bảng] | [Vai trò] |

### 6.2 Quản lý mã nguồn

| Hạng mục | Quy tắc |
|---|---|
| Repository và branch | [Repository và chiến lược branch] |
| Quy tắc commit và review | [Quy tắc] |
| Tag phát hành | [Quy tắc] |
| File dependency và lock | [Quy tắc] |
| Xử lý bí mật | [Quy tắc; không commit giá trị bí mật] |
| Kết quả build/triển khai | [Quy tắc và vị trí lưu] |

### 6.3 Công cụ và hạ tầng

| Mục đích | Công cụ/hạ tầng | Phiên bản/cấu hình | Người phụ trách | Ghi chú truy cập và khôi phục |
|---|---|---|---|---|
| Lập kế hoạch | [Công cụ] | [Phiên bản] | [Vai trò] | [Ghi chú] |
| Quản lý mã nguồn | [Công cụ] | [Phiên bản] | [Vai trò] | [Ghi chú] |
| Build/triển khai | [Công cụ] | [Phiên bản] | [Vai trò] | [Ghi chú] |
| Kiểm thử | [Công cụ] | [Phiên bản] | [Vai trò] | [Ghi chú] |
| Tài liệu/thiết kế | [Công cụ] | [Phiên bản] | [Vai trò] | [Ghi chú] |

---

# III. Đặc tả yêu cầu phần mềm

Đây là SRS cuối đã được duyệt. Có thể viết trực tiếp hoặc tham chiếu đến
tài liệu Report 3 cuối. Nếu tham chiếu, ghi chính xác đường dẫn, phiên bản,
ngày và trạng thái phê duyệt.

| Trường SRS | Giá trị |
|---|---|
| Tài liệu SRS | [Đường dẫn/liên kết] |
| Phiên bản/ngày SRS | [Phiên bản/ngày] |
| Người phê duyệt | [Tên/vai trò] |
| Baseline phạm vi | [Tham chiếu] |

## 1. Tổng quan sản phẩm

Mô tả mục đích sản phẩm, người dùng, bối cảnh vận hành, ranh giới hệ thống,
kết nối bên ngoài, giả định, ràng buộc và phụ thuộc. Đưa sơ đồ bối cảnh và
giải thích mọi thực thể, luồng bên ngoài.

> **Vị trí sơ đồ:** Hình SRS-01 — [Sơ đồ bối cảnh sản phẩm]

## 2. Yêu cầu người dùng

Liệt kê các tác nhân người dùng và bên ngoài đã thống nhất. Cung cấp sơ đồ
ca sử dụng và mô tả mục tiêu, kích hoạt, điều kiện trước, luồng bình thường,
luồng thay thế/ngoại lệ, kết quả và ranh giới phân quyền.

| Mã tác nhân/ca sử dụng | Tác nhân hoặc ca sử dụng | Mục tiêu | Kết quả chính | Yêu cầu liên quan |
|---|---|---|---|---|
| [ACT/UC] | [Tên] | [Mục tiêu] | [Kết quả] | [Mã] |

> **Vị trí sơ đồ:** Hình SRS-02 — [Sơ đồ ca sử dụng]

## 3. Yêu cầu chức năng

Mô tả tổng quan chức năng, luồng màn hình, mô tả màn hình, phân quyền,
chức năng không có màn hình, ERD và từng tính năng/chức năng đủ chi tiết để
có thể kiểm thử.

### 3.1 Tổng quan chức năng hệ thống

> **Vị trí sơ đồ:** Hình SRS-03 — [Sơ đồ luồng màn hình]

| Màn hình/hoạt động | Nền tảng | Mục đích | Vai trò | Dữ liệu chính | Mã liên quan |
|---|---|---|---|---|---|
| [Màn hình/hoạt động] | [Nền tảng] | [Mục đích] | [Vai trò] | [Dữ liệu] | [Mã] |

| Màn hình/hoạt động | Platform Admin | Platform Author | Host | Proctor | Examiner | Student |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| [Màn hình/hoạt động] | [X/-] | [X/-] | [X/-] | [X/-] | [X/-] | [X/-] |

> **Vị trí sơ đồ:** Hình SRS-04 — [Sơ đồ quan hệ thực thể]

### 3.2 [Tên tính năng 1]

| Khu vực | Chi tiết |
|---|---|
| Điểm kích hoạt | [Điều hướng, sự kiện hoặc lịch] |
| Tác nhân | [Vai trò/hệ thống] |
| Đầu vào | [Trường/dữ liệu] |
| Kiểm tra | [Quy tắc] |
| Quy tắc nghiệp vụ | [Quy tắc] |
| Luồng bình thường | [Các bước] |
| Luồng thay thế/bất thường | [Lỗi, thử lại, khôi phục] |
| Đầu ra | [Trạng thái màn hình, phản hồi, sự kiện, dữ liệu lưu] |

### 3.3 [Tên tính năng 2]

Lặp lại đặc tả cho mọi tính năng đã duyệt. Giữ mã yêu cầu duy nhất và có thể
truy xuất.

## 4. Yêu cầu phi chức năng

Ghi các giao diện bên ngoài và thuộc tính chất lượng như khả năng sử dụng,
độ tin cậy, hiệu năng, bảo mật, khả năng bảo trì, tương thích, tính di động,
khả năng tiếp cận, audit và bảo vệ dữ liệu. Mỗi mục tiêu phải có thước đo
hoặc tiêu chí chấp nhận và nguồn bằng chứng.

| Mã yêu cầu | Yêu cầu giao diện/chất lượng | Thước đo hoặc tiêu chí chấp nhận | Bằng chứng | Trạng thái |
|---|---|---|---|---|
| [NFR] | [Yêu cầu] | [Tiêu chí] | [Test/review] | [Trạng thái] |

## 5. Phụ lục yêu cầu

### 5.1 Quy tắc nghiệp vụ

| Mã quy tắc | Định nghĩa | Tính năng bị ảnh hưởng | Nguồn/người sở hữu |
|---|---|---|---|
| BR-01 | [Quy tắc] | [Tính năng] | [Nguồn/người sở hữu] |

### 5.2 Yêu cầu dùng chung

| Mã yêu cầu | Yêu cầu dùng chung | Phạm vi |
|---|---|---|
| CR-01 | [Yêu cầu] | [Hệ thống/tính năng] |

### 5.3 Danh sách thông báo ứng dụng

| Mã thông báo | Loại | Bối cảnh | Nội dung | Yêu cầu liên quan |
|---|---|---|---|---|
| MSG-01 | [Nội tuyến/toast/hộp thoại/lỗi trường] | [Bối cảnh] | [Thông báo] | [Mã] |

### 5.4 Yêu cầu khác

[Yêu cầu về quốc tế hóa, pháp lý, cấp phép, audit, chuyển đổi dữ liệu, triển
khai hoặc yêu cầu khác chưa nêu ở trên.]

---

# IV. Mô tả thiết kế phần mềm

Đây là thiết kế cuối đã được duyệt. Có thể viết trực tiếp hoặc tham chiếu
đến tài liệu Report 4 cuối.

| Trường thiết kế | Giá trị |
|---|---|
| Tài liệu thiết kế | [Đường dẫn/liên kết] |
| Phiên bản/ngày thiết kế | [Phiên bản/ngày] |
| Người review | [Tên/vai trò] |
| Phiên bản SRS liên quan | [Phiên bản/ngày] |

## 1. Thiết kế hệ thống

### 1.1 Kiến trúc hệ thống

> **Vị trí sơ đồ:** Hình SDD-01 — [Kiến trúc hệ thống]

| Thành phần | Trách nhiệm | Dữ liệu sở hữu | Giao diện | Phụ thuộc | Vị trí triển khai |
|---|---|---|---|---|---|
| [Thành phần] | [Trách nhiệm] | [Dữ liệu] | [Giao diện] | [Phụ thuộc] | [Vị trí] |

### 1.2 Sơ đồ package

> **Vị trí sơ đồ:** Hình SDD-02 — [Sơ đồ package]

| Package | Trách nhiệm | Lớp/module chính | Phụ thuộc được phép |
|---|---|---|---|
| [Package] | [Trách nhiệm] | [Lớp/module] | [Phụ thuộc] |

## 2. Thiết kế cơ sở dữ liệu

> **Vị trí sơ đồ:** Hình SDD-03 — [ERD/quan hệ bảng]

| Bảng/thực thể | Mục đích | Khóa chính | Khóa ngoại | Ràng buộc quan trọng | Người sở hữu |
|---|---|---|---|---|---|
| [Bảng/thực thể] | [Mục đích] | [Khóa] | [Khóa] | [Ràng buộc] | [Package] |

## 3. Thiết kế chi tiết

### 3.1 [Tên tính năng/chức năng 1]

> **Vị trí sơ đồ:** Hình SDD-04 — [Sơ đồ lớp]

| Lớp/interface | Trách nhiệm | Thuộc tính chính | Hoạt động công khai | Lớp cộng tác |
|---|---|---|---|---|
| [Lớp] | [Trách nhiệm] | [Thuộc tính] | [Hoạt động] | [Lớp cộng tác] |

> **Vị trí sơ đồ:** Hình SDD-05 — [Sơ đồ tuần tự]

| Bước | Bên gửi | Bên nhận | Message/dữ liệu | Kết quả/luồng lỗi |
|---:|---|---|---|---|
| 1 | [Bên gửi] | [Bên nhận] | [Message] | [Kết quả] |

### 3.2 [Tên tính năng/chức năng 2]

Lặp lại thiết kế cho từng tính năng quan trọng. Dùng lại sơ đồ lớp hoặc sơ
đồ tuần tự chung bằng cách tham chiếu và nêu rõ phần khác biệt theo tính
năng.

---

# V. Tài liệu kiểm thử phần mềm

Đây là kế hoạch và bản tóm tắt bằng chứng kiểm thử cuối. Có thể viết trực
tiếp hoặc tham chiếu đến tài liệu Report 5 cuối.

| Trường kiểm thử | Giá trị |
|---|---|
| Tài liệu kiểm thử | [Đường dẫn/liên kết] |
| Phiên bản/ngày tài liệu kiểm thử | [Phiên bản/ngày] |
| Kết luận kiểm thử | [Đạt/đạt có điều kiện/chưa sẵn sàng] |
| Người phê duyệt | [Tên/vai trò] |

## 1. Phạm vi kiểm thử

| Khu vực | Bao gồm | Không bao gồm | Lý do/rủi ro |
|---|---|---|---|
| [Tính năng/khu vực chất lượng] | [Nội dung kiểm thử] | [Nội dung không kiểm thử] | [Lý do/rủi ro] |

## 2. Chiến lược kiểm thử

### 2.1 Các loại kiểm thử

| Loại kiểm thử | Mục tiêu | Kỹ thuật | Tiêu chí hoàn thành | Người phụ trách |
|---|---|---|---|---|
| [Loại] | [Mục tiêu] | [Kỹ thuật] | [Tiêu chí] | [Vai trò] |

### 2.2 Mức kiểm thử

| Loại kiểm thử | Unit | Tích hợp | Hệ thống | Chấp nhận |
|---|:---:|:---:|:---:|:---:|
| [Loại kiểm thử 1] | X |  |  |  |
| [Loại kiểm thử 2] |  | X | X |  |

### 2.3 Công cụ hỗ trợ

| Mục đích | Công cụ | Nhà cung cấp | Phiên bản | Bằng chứng |
|---|---|---|---|---|
| [Mục đích] | [Công cụ] | [Nhà cung cấp] | [Phiên bản] | [Đường dẫn/liên kết] |

## 3. Kế hoạch kiểm thử

### 3.1 Nhân sự

| Người thực hiện | Vai trò | Trách nhiệm |
|---|---|---|
| [Tên] | [Vai trò] | [Trách nhiệm] |

### 3.2 Môi trường kiểm thử

| Môi trường | Phần mềm/build | Phần cứng/thiết bị | Dữ liệu/tài khoản | Người phụ trách |
|---|---|---|---|---|
| [Môi trường] | [Chi tiết] | [Chi tiết] | [Chi tiết] | [Vai trò] |

### 3.3 Mốc kiểm thử

| Công việc/mốc | Ngày bắt đầu | Ngày kết thúc | Đầu ra kết thúc | Trạng thái |
|---|---|---|---|---|
| [Công việc] | [Ngày] | [Ngày] | [Đầu ra] | [Trạng thái] |

## 4. Test case

Tham chiếu các tệp test case unit, tích hợp, hệ thống và chấp nhận chi tiết.
Mỗi case cần có yêu cầu, điều kiện trước, bước, kết quả mong đợi, kết quả
thực tế, bằng chứng và trạng thái.

| Mã test case | Yêu cầu | Mức/loại | Kết quả | Mã lỗi | Bằng chứng |
|---|---|---|---|---|---|
| [Mã] | [Yêu cầu] | [Mức/loại] | [Kết quả] | [DEF/Không có] | [Liên kết] |

## 5. Báo cáo kiểm thử

| Lần chạy/build | Lập kế hoạch | Đã chạy | Đạt | Không đạt | Bị chặn/bỏ qua | Kết luận |
|---|---:|---:|---:|---:|---:|---|
| [Run/build] | [Số] | [Số] | [Số] | [Số] | [Số] | [Kết luận] |

Giải thích lỗi quan trọng, defect chưa xử lý, giới hạn, rủi ro còn lại và
quyết định phát hành. Liên kết bằng chứng hỗ trợ.

---

# VI. Gói phát hành và hướng dẫn sử dụng

Đây là danh mục phát hành cuối, hướng dẫn cài đặt và hướng dẫn sử dụng. Có
thể viết trực tiếp hoặc tham chiếu đến tài liệu Report 6 cuối.

| Trường phát hành | Giá trị |
|---|---|
| Tài liệu phát hành | [Đường dẫn/liên kết] |
| Phiên bản/tag phát hành | [Phiên bản/tag] |
| Ngày phát hành | [YYYY-MM-DD] |
| Người phụ trách phát hành | [Tên/vai trò] |
| Kênh hỗ trợ | [Liên hệ/kênh] |

## 1. Gói bàn giao

| STT | Hạng mục bàn giao | Phiên bản | Mô tả | Vị trí | Đã kiểm tra |
|---:|---|---|---|---|:---:|
| 1 | Lịch/theo dõi dự án | [Phiên bản] | [Mô tả] | [Liên kết] | [ ] |
| 2 | Product backlog | [Phiên bản] | [Mô tả] | [Liên kết] | [ ] |
| 3 | Mã nguồn | [Commit/tag] | [Mô tả] | [Liên kết] | [ ] |
| 4 | Script cơ sở dữ liệu | [Phiên bản] | [Mô tả] | [Liên kết] | [ ] |
| 5 | Báo cáo cuối dự án | [Phiên bản] | [Mô tả] | [Liên kết] | [ ] |
| 6 | Tài liệu test case | [Phiên bản] | [Mô tả] | [Liên kết] | [ ] |
| 7 | Danh sách lỗi | [Phiên bản] | [Mô tả] | [Liên kết] | [ ] |
| 8 | Danh sách issue | [Phiên bản] | [Mô tả] | [Liên kết] | [ ] |
| 9 | Slide | [Phiên bản] | [Mô tả] | [Liên kết] | [ ] |

## 2. Hướng dẫn cài đặt

### 2.1 Yêu cầu hệ thống

| Nhóm | Yêu cầu | Phiên bản/dung lượng | Cách xác minh |
|---|---|---|---|
| Hệ điều hành/runtime | [Yêu cầu] | [Phiên bản] | [Kiểm tra] |
| Cơ sở dữ liệu/dịch vụ hỗ trợ | [Yêu cầu] | [Phiên bản] | [Kiểm tra] |
| Mạng/lưu trữ/quyền | [Yêu cầu] | [Chi tiết] | [Kiểm tra] |
| Thiết bị người dùng cuối | [Yêu cầu] | [Chi tiết] | [Kiểm tra] |

### 2.2 Hướng dẫn cài đặt

| Bước | Hành động | Kết quả mong đợi | Bằng chứng/checkpoint |
|---:|---|---|---|
| 1 | [Chuẩn bị gói và cấu hình] | [Kết quả] | [Bằng chứng] |
| 2 | [Áp dụng schema/cấu hình] | [Kết quả] | [Bằng chứng] |
| 3 | [Khởi động dịch vụ/ứng dụng] | [Kết quả] | [Bằng chứng] |
| 4 | [Chạy kiểm tra sau cài đặt] | [Kết quả] | [Bằng chứng] |

Mô tả cấu hình, xác minh, rollback và xử lý sự cố. Không ghi giá trị bí mật
thật.

## 3. Hướng dẫn sử dụng

### 3.1 Tổng quan

Mô tả mục đích ứng dụng, vai trò, khu vực điều hướng, trạng thái/thông báo,
quyền truy cập và kênh hỗ trợ.

> **Vị trí sơ đồ:** Hình UG-01 — [Tổng quan/luồng ứng dụng]

### 3.2 Luồng 1 — [Tên luồng]

| Hạng mục | Mô tả |
|---|---|
| Mục đích | [Kết quả] |
| Actor | [Vai trò] |
| Điều kiện trước | [Điều kiện] |
| Kết quả thành công | [Kết quả] |
| Lỗi/khôi phục | [Khôi phục] |

> **Vị trí sơ đồ:** Hình UG-02 — [Luồng 1]

| Bước | Màn hình/vị trí | Thao tác người dùng | Kết quả mong đợi | Ảnh/tham chiếu |
|---:|---|---|---|---|
| 1 | [Màn hình] | [Thao tác] | [Kết quả] | [Liên kết] |
| 2 | [Màn hình] | [Thao tác] | [Kết quả] | [Liên kết] |

### 3.3 Luồng 2 — [Tên luồng]

Lặp lại cấu trúc đầy đủ cho một kết quả người dùng quan trọng khác. Bổ sung
thêm phần luồng khi phạm vi sản phẩm yêu cầu.

| Bước | Màn hình/vị trí | Thao tác người dùng | Kết quả mong đợi | Ảnh/tham chiếu |
|---:|---|---|---|---|
| 1 | [Màn hình] | [Thao tác] | [Kết quả] | [Liên kết] |
| 2 | [Màn hình] | [Thao tác] | [Kết quả] | [Liên kết] |

---

## Phụ lục

### Phụ lục A — Truy xuất yêu cầu/thiết kế/kiểm thử

| Mã yêu cầu | Phần/hình thiết kế | Test case/lần chạy | Phần phát hành/hướng dẫn | Trạng thái |
|---|---|---|---|---|
| [FR/NFR/UC] | [Tham chiếu] | [Tham chiếu] | [Tham chiếu] | [Trạng thái] |

### Phụ lục B — Issue mở và giới hạn đã biết

| Mã issue | Mô tả | Tác động | Cách xử lý tạm | Người phụ trách | Kế hoạch xử lý |
|---|---|---|---|---|---|
| [ISS-01] | [Issue] | [Tác động] | [Workaround] | [Vai trò] | [Kế hoạch] |

### Phụ lục C — Tài liệu tham chiếu

| Tài liệu tham chiếu | Mô tả | Phiên bản/ngày | Vị trí |
|---|---|---|---|
| [Tài liệu] | [Mô tả] | [Phiên bản/ngày] | [Liên kết/đường dẫn] |

### Phụ lục D — Checklist review báo cáo cuối

| Hạng mục kiểm tra | Trạng thái | Bằng chứng / người review |
|---|:---:|---|
| Phạm vi dự án khớp phiếu đăng ký và các quyết định review đã duyệt. | [ ] | [Tham chiếu] |
| Thành viên, vai trò, giảng viên và mã dự án nhất quán. | [ ] | [Tham chiếu] |
| Yêu cầu, thiết kế, kiểm thử và hướng dẫn dùng cùng mã định danh. | [ ] | [Tham chiếu] |
| Mọi tính năng trong phạm vi có yêu cầu, thiết kế và bằng chứng kiểm thử. | [ ] | [Tham chiếu] |
| Nội dung ngoài phạm vi và giới hạn đã biết được nêu rõ. | [ ] | [Tham chiếu] |
| Hình và bảng có chú thích, mã định danh và nhãn dễ đọc. | [ ] | [Tham chiếu] |
| Mọi tài liệu/kết quả tham chiếu được đính kèm hoặc liên kết đến bản phát hành cuối. | [ ] | [Tham chiếu] |
| Không có credential, token, khóa riêng hoặc giá trị bí mật thật. | [ ] | [Kết quả review] |
| Báo cáo cuối đã được các bên cần thiết review và phê duyệt. | [ ] | [Biên bản phê duyệt] |
