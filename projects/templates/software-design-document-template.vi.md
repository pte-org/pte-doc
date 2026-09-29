# Báo cáo 4 — Tài liệu thiết kế phần mềm

## Thông tin template

| Trường thông tin | Giá trị |
|---|---|
| Nguồn template | Report4_Software Design Document.docx |
| Trạng thái template | Bản nháp |
| Dự án | [Tên dự án] |
| Mã dự án | [Mã dự án] |
| Phiên bản | [Phiên bản] |
| Ngày | [YYYY-MM-DD] |
| Người lập | [Tên / vai trò] |
| Người phê duyệt | [Tên / vai trò] |
| SRS liên quan | [Liên kết hoặc mã tài liệu] |

> **Cách sử dụng template:** Thay mọi nội dung trong dấu ngoặc vuông bằng
> thông tin của dự án. Giữ nguyên mã yêu cầu, tính năng, thực thể, lớp và sơ
> đồ khi các mã này được tham chiếu ở tài liệu khác. Mọi quyết định thiết kế
> phải truy xuất được về một yêu cầu đã duyệt, hoặc phải được đánh dấu là
> ràng buộc hay giả định thiết kế. Không đưa thông tin xác thực, khóa riêng,
> giá trị môi trường production hoặc bí mật khác vào tài liệu.

> **Mức độ chi tiết cần có:** Tài liệu này giải thích cách các yêu cầu đã
> duyệt được tổ chức thành một giải pháp. Nội dung phải đủ chi tiết để người
> phát triển hiểu trách nhiệm thành phần, quyền sở hữu dữ liệu, giao diện,
> quan hệ, các bước xử lý quan trọng, luồng lỗi và ranh giới bảo mật mà không
> phải tự đoán. Tài liệu không thay thế mã nguồn hoặc nơi lưu trữ bí mật triển
> khai.

---

## I. Bảng ghi nhận thay đổi

| Ngày | A*M, D | Người phụ trách | Mô tả thay đổi | Tham chiếu |
|---|---|---|---|---|
| [YYYY-MM-DD] | A | [Tên] | [Mô tả nội dung thiết kế được thêm] | [SRS/review thiết kế] |
| [YYYY-MM-DD] | M | [Tên] | [Mô tả nội dung thiết kế được sửa] | [Yêu cầu/quyết định] |
| [YYYY-MM-DD] | D | [Tên] | [Mô tả nội dung thiết kế được xóa] | [Quyết định/review] |
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

*A — Thêm; M — Sửa; D — Xóa. Mỗi dòng nên mô tả một thay đổi thiết kế có ý
nghĩa, không chỉ là sửa lỗi trình bày.*

---

## II. Tài liệu thiết kế phần mềm

### 1. Thiết kế hệ thống

Phần này trình bày thiết kế ở cấp hệ thống. Giải thích các phần chính của
giải pháp, ranh giới của từng phần, đường giao tiếp giữa các phần và hệ thống
hoặc thiết bị bên ngoài có liên quan. Thiết kế phải nhất quán với ranh giới
hệ thống, tác nhân, giao diện và yêu cầu phi chức năng trong SRS.

#### 1.1 Kiến trúc hệ thống

Mô tả kiểu kiến trúc được chọn và lý do phù hợp với dự án. Nêu phần nào chạy
trên trình duyệt, ứng dụng di động, ứng dụng máy tính, máy chủ, cơ sở dữ
liệu, worker nền hoặc nhà cung cấp bên ngoài. Giải thích trách nhiệm của
từng thành phần và luồng dữ liệu hoặc điều khiển giữa các thành phần.

Sơ đồ kiến trúc cần thể hiện:

- ranh giới hệ thống;
- ứng dụng hướng tới người dùng và người sử dụng ứng dụng;
- các module hoặc dịch vụ của ứng dụng;
- cơ sở dữ liệu và nơi lưu trữ lâu dài;
- hàng đợi, tác vụ theo lịch hoặc worker nền;
- hệ thống, thiết bị và nhà cung cấp dịch vụ bên ngoài;
- ranh giới tin cậy và ranh giới xác thực;
- hướng và mục đích của từng kết nối quan trọng.

<!-- Chèn sơ đồ kiến trúc hệ thống tại đây. Đặt số hình, chú thích và phần
giải thích ngắn. Phần giải thích phải bao quát mọi thành phần và kết nối
trong sơ đồ. -->

> **Vị trí sơ đồ:** Hình SD-01 — [Sơ đồ kiến trúc hệ thống]

##### Mô tả thành phần kiến trúc

| Mã thành phần | Thành phần / ranh giới | Trách nhiệm | Dữ liệu sở hữu | Giao diện vào | Giao diện ra | Phụ thuộc | Vị trí triển khai |
|---|---|---|---|---|---|---|---|
| C-01 | [Tên thành phần] | [Thành phần chịu trách nhiệm gì] | [Dữ liệu sở hữu/quản lý] | [Người dùng, module hoặc hệ thống] | [Module, hệ thống hoặc thiết bị] | [Phụ thuộc bắt buộc] | [Trình duyệt, app, máy chủ, cloud, ...] |
| C-02 | [Tên thành phần] | [Trách nhiệm] | [Dữ liệu sở hữu] | [Giao diện] | [Giao diện] | [Phụ thuộc] | [Vị trí] |
| C-03 | [Tên thành phần] | [Trách nhiệm] | [Dữ liệu sở hữu] | [Giao diện] | [Giao diện] | [Phụ thuộc] | [Vị trí] |

##### Quyết định và ràng buộc kiến trúc

| Mã quyết định | Quyết định hoặc ràng buộc | Lý do | Phương án đã xem xét | Yêu cầu hoặc rủi ro bị ảnh hưởng |
|---|---|---|---|---|
| ADR-01 | [Quyết định kiến trúc] | [Lý do chọn] | [Các phương án khác] | [Mã FR/NFR/rủi ro] |
| ADR-02 | [Quyết định kiến trúc] | [Lý do] | [Các phương án khác] | [Mã] |

##### Luồng dữ liệu và điều khiển

Với mỗi luồng quan trọng, mô tả sự kiện bắt đầu, các thành phần tham gia, dữ
liệu được gửi, kiểm tra hợp lệ hoặc phân quyền, trạng thái lâu dài thay đổi
và hành vi phản hồi hoặc khôi phục.

| Mã luồng | Tên luồng | Điểm kích hoạt | Các bước qua thành phần | Dữ liệu trao đổi | Kết quả thành công | Lỗi hoặc khôi phục |
|---|---|---|---|---|---|---|
| FLOW-01 | [Tên luồng] | [Hành động, sự kiện hoặc lịch] | [C-01 → C-02 → C-03] | [Dữ liệu] | [Kết quả] | [Lỗi, thử lại, phương án dự phòng] |
| FLOW-02 | [Tên luồng] | [Điểm kích hoạt] | [Chuỗi thành phần] | [Dữ liệu] | [Kết quả] | [Hành vi khi lỗi] |

#### 1.2 Sơ đồ package

Cung cấp sơ đồ package cho từng phân hệ hoặc ranh giới ứng dụng. Sơ đồ cần
thể hiện package logic, trách nhiệm và các phụ thuộc được phép. Một package
có thể đại diện cho module nghiệp vụ, lớp xử lý, khu vực tính năng hoặc năng
lực dùng chung. Dùng cùng tên package trong sơ đồ, mã nguồn, thiết kế cơ sở
dữ liệu và đặc tả lớp.

<!-- Chèn sơ đồ package tổng thể tại đây. Nếu giải pháp có nhiều phân hệ độc
lập, thêm một sơ đồ cho từng phân hệ và đặt mã riêng cho từng sơ đồ. -->

> **Vị trí sơ đồ:** Hình SD-02 — [Sơ đồ package tổng thể]

##### Mô tả package

| STT | Mã / tên package | Trách nhiệm | Lớp hoặc module chính | Điểm vào công khai | Phụ thuộc được phép | Phụ thuộc không được phép |
|---:|---|---|---|---|---|---|
| 1 | [PKG-01 / tên package] | [Trách nhiệm nghiệp vụ hoặc kỹ thuật] | [Lớp/module] | [Service, controller hoặc interface] | [Package được phép] | [Package không được truy cập] |
| 2 | [PKG-02 / tên package] | [Trách nhiệm] | [Lớp/module] | [Điểm vào] | [Package được phép] | [Package cấm] |
| 3 | [PKG-03 / tên package] | [Trách nhiệm] | [Lớp/module] | [Điểm vào] | [Package được phép] | [Package cấm] |

##### Quy tắc phụ thuộc

Ghi lại các quy tắc bảo vệ thiết kế khỏi liên kết ngoài ý muốn. Ví dụ: package
nào sở hữu quy tắc nghiệp vụ, nơi kiểm tra phân quyền, package nào được đọc
kho dữ liệu, cách dùng tiện ích dùng chung và cách biểu diễn lỗi giữa các
package.

| Mã quy tắc | Quy tắc phụ thuộc | Lý do | Cách kiểm tra |
|---|---|---|---|
| DEP-01 | [Ví dụ: Package A chỉ được gọi Package B thông qua interface service công khai.] | [Lý do về ranh giới/quyền sở hữu] | [Review mã nguồn, kiểm tra kiến trúc hoặc checklist] |
| DEP-02 | [Quy tắc phụ thuộc] | [Lý do] | [Cách kiểm tra] |

### 2. Thiết kế cơ sở dữ liệu

Phần này mô tả thiết kế dữ liệu logic và vật lý cần có để hỗ trợ SRS. Giải
thích quyền sở hữu dữ liệu, quan hệ, mã định danh, ràng buộc, vòng đời, thời
hạn lưu trữ và yêu cầu audit. Thiết kế cơ sở dữ liệu phải thống nhất với ERD
trong SRS và không được tự thêm thực thể hoặc quan hệ không cần cho một tính
năng đã duyệt.

#### 2.1 Tổng quan cơ sở dữ liệu

| Hạng mục | Quyết định |
|---|---|
| Công nghệ cơ sở dữ liệu | [Công nghệ và phiên bản] |
| Ranh giới cơ sở dữ liệu | [Cơ sở dữ liệu, schema, ranh giới tenant hoặc cách khác] |
| Module sở hữu dữ liệu chính | [Module hoặc thành phần] |
| Cách tạo mã định danh | [Mã sinh tự động, khóa tự nhiên hoặc kết hợp] |
| Quy ước ngày và giờ | [Múi giờ, cách lưu trữ và hiển thị] |
| Cách cập nhật schema | [Cách tạo, review và áp dụng thay đổi schema] |
| Giả định sao lưu và khôi phục | [Giả định vận hành đã được duyệt] |
| Lưu trữ và xóa dữ liệu | [Tham chiếu yêu cầu SRS hoặc quyết định theo hợp đồng] |

#### 2.2 Quan hệ thực thể và quan hệ bảng

<!-- Chèn ERD logic và, khi cần, sơ đồ quan hệ bảng vật lý. Giải thích lực
lượng quan hệ, quan hệ tùy chọn, ranh giới quyền sở hữu và quan hệ được biểu
diễn bằng bảng nối. -->

> **Vị trí sơ đồ:** Hình SD-03 — [ERD / quan hệ bảng]

| Mã quan hệ | Thực thể cha | Thực thể con | Lực lượng quan hệ | Bắt buộc/tùy chọn | Quy tắc sở hữu | Hành vi xóa/cập nhật |
|---|---|---|---|---|---|---|
| REL-01 | [Thực thể] | [Thực thể] | [1-n, ...] | [Tùy chọn/bắt buộc] | [Bên sở hữu quan hệ] | [Chặn, cascade, lưu trữ, ...] |
| REL-02 | [Thực thể] | [Thực thể] | [Lực lượng] | [Tùy chọn/bắt buộc] | [Quyền sở hữu] | [Hành vi] |

#### 2.3 Mô tả bảng

| STT | Bảng / collection | Mục đích | Khóa chính | Khóa ngoại | Trường và ràng buộc quan trọng | Package sở hữu |
|---:|---|---|---|---|---|---|
| 1 | [Tên bảng] | [Bản ghi đại diện cho điều gì] | [Danh sách trường khóa chính] | [Danh sách trường khóa ngoại] | [Trường bắt buộc, duy nhất, trạng thái được phép] | [Package] |
| 2 | [Tên bảng] | [Mục đích] | [Khóa] | [Khóa] | [Ràng buộc] | [Package] |
| 3 | [Tên bảng] | [Mục đích] | [Khóa] | [Khóa] | [Ràng buộc] | [Package] |

Với mỗi bảng, mô tả các chi tiết không thể hiểu chỉ từ sơ đồ:

| Bảng | Trường | Kiểu / kích thước | Bắt buộc | Mặc định | Giá trị được phép | Ý nghĩa hoặc kiểm tra | Nhạy cảm? |
|---|---|---|:---:|---|---|---|:---:|
| [Bảng] | [Trường] | [Kiểu] | Có/Không | [Mặc định] | [Khoảng hoặc enum] | [Ý nghĩa và quy tắc] | Có/Không |
| [Bảng] | [Trường] | [Kiểu] | Có/Không | [Mặc định] | [Khoảng hoặc enum] | [Ý nghĩa và quy tắc] | Có/Không |

#### 2.4 Toàn vẹn dữ liệu, index và giao dịch

Mô tả các ràng buộc và ranh giới giao dịch cần có để dữ liệu chính xác. Bao
gồm tính duy nhất, toàn vẹn tham chiếu, khóa lạc quan hoặc bi quan, tính
idempotent, mức cô lập, index cho truy vấn quan trọng và hành vi khi hai
người cùng cập nhật một bản ghi.

| Mã thiết kế | Quy tắc hoặc cơ chế dữ liệu | Bảng/luồng bị ảnh hưởng | Hành vi khi lỗi | Cách kiểm tra |
|---|---|---|---|---|
| DB-01 | [Ràng buộc duy nhất hoặc tham chiếu] | [Bảng hoặc mã luồng] | [Thông báo, rollback, thử lại] | [Kiểm thử hoặc kiểm tra migration] |
| DB-02 | [Quy tắc giao dịch hoặc đồng thời] | [Bảng hoặc mã luồng] | [Hành vi] | [Cách kiểm tra] |
| DB-03 | [Quy tắc index hoặc hiệu năng truy vấn] | [Bảng hoặc truy vấn] | [Hành vi khi không có] | [Review truy vấn hoặc kiểm thử] |

#### 2.5 Audit, lưu trữ và dữ liệu nhạy cảm

Mô tả thay đổi dữ liệu nào tạo bản ghi audit, ai được xem, thời hạn lưu trữ,
cách xóa hoặc ẩn danh và cách bảo vệ dữ liệu nhạy cảm. Tham chiếu SRS và hợp
đồng của tổ chức đối với quyết định lưu trữ chưa chốt.

| Nhóm dữ liệu | Ví dụ | Giới hạn truy cập | Sự kiện audit | Quy tắc lưu trữ/xóa | Biện pháp bảo vệ |
|---|---|---|---|---|---|
| [Nhóm] | [Trường hoặc bản ghi] | [Vai trò được phép] | [Tên sự kiện] | [Quy tắc hoặc TBD] | [Mã hóa, che dữ liệu, ...] |
| [Nhóm] | [Ví dụ] | [Giới hạn] | [Sự kiện] | [Quy tắc] | [Bảo vệ] |

### 3. Thiết kế chi tiết

Tạo một phần cho từng tính năng hoặc chức năng quan trọng. Thiết kế chi tiết
phải liên kết tính năng với yêu cầu SRS và mô tả lớp, interface, dữ liệu,
chuỗi tương tác, trạng thái, kiểm tra, phân quyền và xử lý lỗi cần để triển
khai.

> **Quy tắc dùng lại:** Khi nhiều tính năng dùng cùng cấu trúc lớp hoặc
> chuỗi tương tác, mô tả thiết kế dùng chung một lần và tham chiếu ở các tính
> năng khác. Nêu rõ phần dùng chung và phần chuyên biệt.

#### 3.1 [Tên tính năng / chức năng 1]

| Hạng mục | Giá trị |
|---|---|
| Mã tính năng | [Mã tính năng hoặc FR] |
| Yêu cầu SRS | [Mã FR/NFR/BR/UC] |
| Tác nhân hoặc bên gọi | [Vai trò, module hoặc hệ thống bên ngoài] |
| Điểm vào | [Màn hình, API, sự kiện, lịch hoặc message] |
| Trách nhiệm chính | [Kết quả tính năng tạo ra] |
| Dữ liệu đọc | [Thực thể/bảng hoặc dữ liệu bên ngoài] |
| Dữ liệu thay đổi | [Thực thể/bảng hoặc dữ liệu bên ngoài] |
| Ranh giới phân quyền | [Ai được thực hiện từng hành động] |
| Ranh giới giao dịch | [Phần nào thành công hoặc rollback cùng nhau] |
| Phụ thuộc bên ngoài | [Dịch vụ, thiết bị, hàng đợi hoặc tệp] |

##### 3.1.1 Sơ đồ lớp

<!-- Chèn sơ đồ lớp của tính năng. Thể hiện lớp, interface, kế thừa, hợp
thành, liên kết và lực lượng quan hệ liên quan. Không đưa helper chỉ phục vụ
triển khai vào sơ đồ nếu chúng không ảnh hưởng đến thiết kế. -->

> **Vị trí sơ đồ:** Hình SD-04 — [Sơ đồ lớp của tính năng 1]

##### 3.1.2 Đặc tả lớp

| Lớp / interface | Loại | Trách nhiệm | Thuộc tính quan trọng | Hoạt động công khai | Lớp cộng tác | Bất biến |
|---|---|---|---|---|---|---|
| [Tên lớp] | [Entity/service/controller/interface] | [Trách nhiệm] | [Thuộc tính] | [Hoạt động và kết quả] | [Lớp khác] | [Quy tắc luôn phải đúng] |
| [Tên lớp] | [Loại] | [Trách nhiệm] | [Thuộc tính] | [Hoạt động] | [Lớp cộng tác] | [Bất biến] |

Với mỗi hoạt động có ý nghĩa nghiệp vụ, cung cấp chi tiết:

| Hoạt động | Tác nhân/bên gọi | Đầu vào | Kiểm tra | Xử lý | Đầu ra | Lỗi và khôi phục | Tác động phụ |
|---|---|---|---|---|---|---|---|
| [Tên hoạt động] | [Bên gọi] | [Tham số] | [Quy tắc] | [Các bước hoặc điểm quyết định] | [Kết quả/sự kiện/trạng thái] | [Lỗi và thử lại] | [Dữ liệu/audit/thông báo] |
| [Tên hoạt động] | [Bên gọi] | [Tham số] | [Quy tắc] | [Xử lý] | [Đầu ra] | [Lỗi] | [Tác động phụ] |

##### 3.1.3 Sơ đồ tuần tự — [Tên chuỗi 1]

Mô tả kịch bản trong sơ đồ tuần tự, bao gồm điều kiện bắt đầu và trạng thái
cuối mong đợi. Thể hiện message giữa tác nhân và giao diện, giao diện và
ứng dụng, ứng dụng và kho dữ liệu hoặc dịch vụ bên ngoài khi có.

<!-- Chèn sơ đồ tuần tự tại đây. Chỉ đánh số message khi giúp theo dõi tương
tác phức tạp. Đánh dấu rõ nhánh thay thế, tùy chọn, thử lại và lỗi. -->

> **Vị trí sơ đồ:** Hình SD-05 — [Tên sơ đồ tuần tự 1]

| Bước | Bên gửi | Bên nhận | Message / dữ liệu | Kiểm tra hoặc quyết định | Kết quả |
|---:|---|---|---|---|---|
| 1 | [Tác nhân/thành phần] | [Thành phần] | [Hành động và dữ liệu] | [Kiểm tra] | [Kết quả] |
| 2 | [Thành phần] | [Thành phần] | [Hành động và dữ liệu] | [Kiểm tra] | [Kết quả] |
| 3 | [Thành phần] | [Kho dữ liệu/dịch vụ] | [Hành động và dữ liệu] | [Kiểm tra] | [Kết quả] |

##### 3.1.4 Sơ đồ tuần tự — [Tên chuỗi 2]

Lặp lại thiết kế chuỗi cho một kịch bản bình thường, thay thế hoặc ngoại lệ
quan trọng. Không bỏ qua luồng lỗi ảnh hưởng đến giao diện, toàn vẹn dữ
liệu, hành vi thử lại hoặc bản ghi audit.

> **Vị trí sơ đồ:** Hình SD-06 — [Tên sơ đồ tuần tự 2]

| Bước | Bên gửi | Bên nhận | Message / dữ liệu | Kiểm tra hoặc quyết định | Kết quả |
|---:|---|---|---|---|---|
| 1 | [Tác nhân/thành phần] | [Thành phần] | [Hành động và dữ liệu] | [Kiểm tra] | [Kết quả] |
| 2 | [Thành phần] | [Thành phần] | [Hành động và dữ liệu] | [Kiểm tra] | [Kết quả] |

##### 3.1.5 Thiết kế trạng thái, kiểm tra và lỗi

Nếu tính năng có vòng đời, chèn sơ đồ trạng thái hoặc liệt kê mọi chuyển
trạng thái được phép. Nêu ai hoặc thành phần nào được tạo từng chuyển trạng
thái và chuyển nào bị cấm.

| Trạng thái hiện tại | Kích hoạt | Điều kiện trước | Trạng thái tiếp theo | Actor/hệ thống được phép | Audit hoặc thông báo |
|---|---|---|---|---|---|
| [Trạng thái] | [Hành động/sự kiện] | [Điều kiện] | [Trạng thái] | [Vai trò/thành phần] | [Sự kiện] |
| [Trạng thái] | [Hành động/sự kiện] | [Điều kiện] | [Trạng thái] | [Vai trò/thành phần] | [Sự kiện] |

| Mã lỗi | Điều kiện | Điểm phát hiện | Phản hồi người dùng/hệ thống | Thử lại hoặc khôi phục | Audit/log |
|---|---|---|---|---|---|
| ERR-01 | [Điều kiện] | [Thành phần] | [Thông báo/phản hồi] | [Thử lại/dự phòng] | [Bản ghi] |
| ERR-02 | [Điều kiện] | [Thành phần] | [Thông báo/phản hồi] | [Khôi phục] | [Bản ghi] |

#### 3.2 [Tên tính năng / chức năng 2]

Lặp lại đầy đủ cấu trúc thiết kế chi tiết ở trên. Tối thiểu cần có:

- liên kết đến các yêu cầu SRS;
- ranh giới tính năng và bên gọi;
- thiết kế lớp hoặc thành phần;
- sơ đồ tuần tự cho luồng bình thường và luồng thay thế;
- hành vi dữ liệu và giao dịch;
- phân quyền, kiểm tra, lỗi và audit;
- phần nêu rõ thiết kế dùng lại từ Mục 3.1.

<!-- Bổ sung các phần tính năng 3.3, 3.4, ... khi cần. Không gộp các tính
năng không liên quan chỉ để rút ngắn tài liệu. -->

### 4. Quyết định thiết kế dùng chung

Dùng phần tùy chọn này khi một mối quan tâm thiết kế áp dụng cho nhiều tính
năng và nếu lặp lại sẽ gây dư thừa. Chủ đề có thể gồm xác thực và phân quyền,
quy ước kiểm tra và phản hồi lỗi, thông báo, xử lý tệp/phương tiện, tính
idempotent, xử lý nền, log, audit, múi giờ và khả năng tiếp cận.

| Mối quan tâm | Quy tắc thiết kế | Thành phần/tính năng bị ảnh hưởng | Mã yêu cầu | Cách kiểm tra |
|---|---|---|---|---|
| [Mối quan tâm] | [Quy tắc] | [Thành phần/tính năng] | [Mã] | [Review/kiểm thử] |
| [Mối quan tâm] | [Quy tắc] | [Thành phần/tính năng] | [Mã] | [Review/kiểm thử] |

### 5. Truy xuất thiết kế và checklist review

| Hạng mục kiểm tra | Trạng thái | Bằng chứng / tham chiếu | Người review |
|---|:---:|---|---|
| Mọi yêu cầu chức năng đã duyệt đều liên kết đến một thành phần hoặc tính năng thiết kế. | [ ] | [Phần/hình/bảng] | [Tên] |
| Mọi giao diện bên ngoài trong SRS xuất hiện trong kiến trúc hoặc sơ đồ tuần tự. | [ ] | [Tham chiếu] | [Tên] |
| Mọi thực thể lưu trữ trong SRS xuất hiện trong ERD và mô tả bảng. | [ ] | [Tham chiếu] | [Tên] |
| Ranh giới vai trò và truy cập dữ liệu được nêu rõ. | [ ] | [Tham chiếu] | [Tên] |
| Luồng bình thường, thay thế, hết thời gian, thử lại và lỗi của luồng quan trọng được mô tả. | [ ] | [Tham chiếu] | [Tên] |
| Quyết định và giả định thiết kế được ghi nhận và phê duyệt. | [ ] | [Tham chiếu] | [Tên] |
| Không có thông tin xác thực hoặc bí mật production trong tài liệu. | [ ] | [Kết quả review] | [Tên] |
| Sơ đồ có chú thích, mã định danh, chú giải khi cần và nhãn dễ đọc. | [ ] | [Danh sách hình] | [Tên] |
| Thiết kế đã được đối chiếu với phiên bản SRS mới nhất. | [ ] | [Biên bản review] | [Tên] |

