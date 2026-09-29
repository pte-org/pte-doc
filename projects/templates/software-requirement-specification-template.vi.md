# Báo cáo 3 — Đặc tả yêu cầu phần mềm

## Thông tin template

| Trường thông tin | Giá trị |
|---|---|
| Nguồn template | Report3_Software Requirement Specification.docx |
| Trạng thái template | Bản nháp |
| Dự án | [Tên dự án] |
| Phiên bản | [Phiên bản] |
| Ngày | [YYYY-MM-DD] |
| Người lập | [Tên / vai trò] |

> **Cách sử dụng template:** Thay nội dung trong dấu ngoặc vuông và dấu
> ngoặc nhọn bằng thông tin của dự án, bổ sung dòng khi cần và xóa phần mẫu
> không áp dụng. Giữ nguyên mã định danh yêu cầu sau khi mã đó đã được dùng
> trong tài liệu thiết kế, phát triển hoặc kiểm thử.

---

## I. Bảng ghi nhận thay đổi

| Ngày | A*M, D | Người phụ trách | Mô tả thay đổi | Tham chiếu |
|---|---|---|---|---|
| [YYYY-MM-DD] | A | [Tên] | [Mô tả nội dung được thêm] | [Tài liệu/quyết định] |
| [YYYY-MM-DD] | M | [Tên] | [Mô tả nội dung được sửa] | [Tài liệu/quyết định] |
| [YYYY-MM-DD] | D | [Tên] | [Mô tả nội dung được xóa] | [Tài liệu/quyết định] |
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

*A — Thêm; M — Sửa; D — Xóa. Mỗi dòng nên mô tả một thay đổi có ý nghĩa
đối với phạm vi hoặc hành vi của hệ thống, không chỉ là sửa lỗi chính tả.*

---

## II. Đặc tả yêu cầu phần mềm

### 1. Tổng quan sản phẩm

Mô tả sản phẩm, mục đích và bối cảnh vận hành. Nêu vấn đề sản phẩm giải
quyết, người sử dụng, giới hạn hệ thống và các hệ thống bên ngoài có liên
quan. Đưa vào sơ đồ bối cảnh thể hiện ranh giới hệ thống và kết nối giữa hệ
thống với phần mềm, phần cứng, con người hoặc hệ thống khác.

> **Nội dung mẫu cần thay thế:** Hệ thống Đặt món Căng tin là một hệ thống
> phần mềm mới, thay thế quy trình đặt món và nhận món thủ công hoặc qua
> điện thoại tại căng tin Process Impact. Sơ đồ bối cảnh bên dưới thể hiện
> các thực thể bên ngoài và giao diện của hệ thống trong phiên bản 1.0.
> Hệ thống có thể được mở rộng ở các phiên bản sau để kết nối với dịch vụ
> đặt món trực tuyến và dịch vụ xác thực thanh toán.

#### Sơ đồ bối cảnh

<!-- Chèn sơ đồ bối cảnh của dự án. Mô tả mọi thực thể bên ngoài và mọi luồng
dữ liệu, điều khiển hoặc vật chất xuất hiện trong sơ đồ. -->

> **Vị trí sơ đồ:** Chèn sơ đồ bối cảnh của dự án tại đây.

### 2. Yêu cầu người dùng

#### 2.1 Tác nhân

Tác nhân là người, phần mềm hoặc thiết bị phần cứng tương tác với hệ thống
để thực hiện một ca sử dụng. Có thể xác định tác nhân bằng các câu hỏi:

- Ai hoặc thành phần nào được thông báo khi có sự kiện xảy ra trong hệ thống?
- Ai hoặc thành phần nào cung cấp thông tin hoặc dịch vụ cho hệ thống?
- Ai hoặc thành phần nào hỗ trợ hệ thống xử lý và hoàn tất một nhiệm vụ?

| STT | Tác nhân | Mô tả |
|---:|---|---|
| 1 | [Tên tác nhân] | [Vai trò, mục tiêu và mối quan hệ với hệ thống] |
| 2 | [Tên tác nhân] | [Vai trò, mục tiêu và mối quan hệ với hệ thống] |
| 3 | [Tên tác nhân] | [Vai trò, mục tiêu và mối quan hệ với hệ thống] |

#### 2.2 Ca sử dụng

Ca sử dụng mô tả chuỗi tương tác giữa hệ thống và tác nhân bên ngoài, tạo ra
một kết quả có giá trị cho tác nhân. Đặt tên theo dạng **động từ + đối
tượng**, ví dụ: Xem thực đơn hoặc Gửi đơn hàng.

##### 2.2.1 Sơ đồ

<!-- Chèn một hoặc nhiều sơ đồ ca sử dụng. Thể hiện quan hệ giữa tác nhân và
ca sử dụng, cũng như quan hệ giữa các ca sử dụng. Thêm chú thích ngắn cho
từng sơ đồ. -->

> **Vị trí sơ đồ:** Chèn các sơ đồ ca sử dụng của dự án tại đây.

##### 2.2.2 Mô tả

| Mã | Ca sử dụng | Tác nhân | Mô tả ca sử dụng |
|---|---|---|---|
| UC-01 | [Động từ + đối tượng] | [Tác nhân] | [Kết quả và tóm tắt tương tác] |
| UC-02 | [Động từ + đối tượng] | [Tác nhân] | [Kết quả và tóm tắt tương tác] |
| UC-03 | [Động từ + đối tượng] | [Tác nhân] | [Kết quả và tóm tắt tương tác] |

### 3. Yêu cầu chức năng

#### 3.1 Tổng quan chức năng hệ thống

Trình bày tổng quan các chức năng phần mềm. Bao gồm luồng màn hình, mô tả
màn hình, vai trò hệ thống, quyền truy cập màn hình, các chức năng không có
màn hình và mô hình quan hệ thực thể.

##### 3.1.1 Luồng màn hình

<!-- Chèn sơ đồ luồng màn hình. Có thể dùng ký hiệu khác nhau cho màn hình
bình thường, cửa sổ bật lên và màn hình có nhiều tab thông tin. -->

> **Vị trí sơ đồ:** Chèn sơ đồ luồng màn hình của dự án tại đây.

##### 3.1.2 Mô tả màn hình

Mô tả mọi màn hình xuất hiện trong sơ đồ luồng màn hình.

| STT | Tính năng | Màn hình | Mô tả |
|---:|---|---|---|
| 1 | [Tên tính năng] | [Tên màn hình] | [Mục đích và nội dung chính] |
| 2 | [Tên tính năng] | [Tên màn hình] | [Mục đích và nội dung chính] |
| 3 | [Tên tính năng] | [Tên màn hình] | [Mục đích và nội dung chính] |

##### 3.1.3 Phân quyền màn hình

Thay Vai trò 1, Vai trò 2 và Vai trò 3 bằng vai trò thật của dự án. Thêm
hoặc xóa cột, dòng để mọi hoạt động trên từng màn hình đều có quyết định
phân quyền rõ ràng.

| Màn hình / hoạt động | Vai trò 1 | Vai trò 2 | Vai trò 3 | [Vai trò N] |
|---|:---:|:---:|:---:|:---:|
| [Tên màn hình] | X |  | X |  |
| └ [Hoạt động trên màn hình] |  |  | X | X |
| [Tên màn hình] | X |  | X |  |
| └ Xem toàn bộ dữ liệu | X |  |  |  |
| └ Xem dữ liệu của mình |  |  | X |  |
| └ Xem dữ liệu được quản lý |  |  | X |  |
| └ Thêm dữ liệu |  |  | X | X |
| └ Sửa toàn bộ dữ liệu |  |  |  | X |
| └ Sửa dữ liệu của mình |  |  |  | X |
| └ Sửa dữ liệu được quản lý |  |  |  | X |
| └ Xóa dữ liệu |  |  |  |  |
| └ [Hoạt động khác] |  |  |  |  |

##### 3.1.4 Chức năng không có màn hình

Mô tả các chức năng chạy nền hoặc không hiển thị thành màn hình, chẳng hạn
như tác vụ theo lịch, xử lý hàng loạt, dịch vụ, tích hợp và API.

| STT | Tính năng | Chức năng hệ thống | Mô tả |
|---:|---|---|---|
| 1 | [Tên tính năng] | [Tên chức năng] | [Mục đích, điều kiện chạy và kết quả] |
| 2 | [Tên tính năng] | [Tên chức năng] | [Mục đích, điều kiện chạy và kết quả] |
| 3 | [Tên tính năng] | [Tên chức năng] | [Mục đích, điều kiện chạy và kết quả] |

##### 3.1.5 Sơ đồ quan hệ thực thể

<!-- Chèn sơ đồ quan hệ thực thể và mô tả các thực thể bên dưới. -->

> **Vị trí sơ đồ:** Chèn ERD của dự án tại đây.

**Mô tả thực thể**

| STT | Thực thể | Mô tả |
|---:|---|---|
| 1 | [Tên thực thể] | [Mục đích và các quan hệ quan trọng] |
| 2 | [Tên thực thể] | [Mục đích và các quan hệ quan trọng] |
| 3 | [Tên thực thể] | [Mục đích và các quan hệ quan trọng] |
| 4 | [Tên thực thể] | [Mục đích và các quan hệ quan trọng] |

#### 3.2 [Tên tính năng 1]

##### 3.2.1 [Tên chức năng 1]

Một chức năng có thể là chức năng trên màn hình hoặc chức năng không có màn
hình đã liệt kê ở Mục 3.1.4. Mô tả các nội dung sau:

- **Điểm kích hoạt:** Cách chức năng được bắt đầu, ví dụ đường dẫn điều
  hướng, sự kiện hoặc lịch chạy.
- **Mô tả chức năng:** Vai trò hoặc tác nhân, mục đích, giao diện và cách xử
  lý dữ liệu.
- **Bố cục màn hình:** Liên kết hoặc chèn bản phác thảo, prototype khi có.
- **Chi tiết chức năng:** Trường dữ liệu, kiểm tra hợp lệ, quy tắc nghiệp vụ,
  trường hợp bình thường và trường hợp bất thường.

**Điểm kích hoạt:** [Điểm kích hoạt, đường dẫn, sự kiện hoặc tần suất]

**Mô tả chức năng:** [Tác nhân, mục đích, giao diện và xử lý]

**Bố cục màn hình / prototype:** [Liên kết, hình ảnh hoặc Không áp dụng]

**Chi tiết chức năng**

| Khu vực | Chi tiết |
|---|---|
| Dữ liệu đầu vào | [Trường, định dạng và nguồn dữ liệu] |
| Kiểm tra hợp lệ | [Trường bắt buộc, giới hạn, định dạng và điều kiện liên trường] |
| Quy tắc nghiệp vụ | [Các quy tắc áp dụng] |
| Luồng bình thường | [Hành vi thành công dự kiến] |
| Luồng bất thường | [Lỗi, hết thời gian, thử lại và khôi phục] |
| Kết quả đầu ra | [Trạng thái màn hình, phản hồi, sự kiện hoặc dữ liệu lưu trữ] |

##### 3.2.2 [Tên chức năng 2]

[Lặp lại cấu trúc mô tả chức năng ở trên.]

#### 3.3 [Tên tính năng 2]

##### 3.3.1 [Tên chức năng]

[Lặp lại cấu trúc mô tả chức năng ở trên.]

##### 3.3.2 [Tên chức năng]

[Lặp lại cấu trúc mô tả chức năng ở trên.]

#### 3.4 [Tên tính năng N]

[Bổ sung các phần tính năng và chức năng khi cần.]

### 4. Yêu cầu phi chức năng

#### 4.1 Giao diện bên ngoài

Mô tả các yêu cầu để hệ thống giao tiếp đúng với người dùng, phần cứng bên
ngoài, phần mềm bên ngoài và hệ thống khác.

| Giao diện | Bên giao tiếp bên ngoài | Dữ liệu trao đổi | Giao thức / định dạng | Xác thực | Ràng buộc |
|---|---|---|---|---|---|
| [Tên giao diện] | [Hệ thống, thiết bị hoặc tác nhân] | [Dữ liệu] | [HTTPS, WebSocket, tệp, ...] | [Cách xác thực] | [Giới hạn hoặc quy tắc] |
| [Tên giao diện] | [Hệ thống, thiết bị hoặc tác nhân] | [Dữ liệu] | [Giao thức / định dạng] | [Cách xác thực] | [Giới hạn hoặc quy tắc] |

#### 4.2 Thuộc tính chất lượng

Liệt kê các đặc tính bắt buộc của hệ thống. Khi có thể, mỗi yêu cầu nên có
thước đo hoặc tiêu chí chấp nhận và chỉ rõ tính năng hoặc ca sử dụng liên
quan.

##### 4.2.1 Khả năng sử dụng

Mô tả các yêu cầu ảnh hưởng đến việc sử dụng, chẳng hạn thời gian đào tạo,
thời gian hoàn thành tác vụ, khả năng tiếp cận, ngôn ngữ hỗ trợ và tuân thủ
tiêu chuẩn giao diện người dùng.

| Yêu cầu | Thước đo / tiêu chí chấp nhận | Tính năng hoặc ca sử dụng liên quan |
|---|---|---|
| [Yêu cầu khả năng sử dụng] | [Tiêu chí định lượng hoặc quan sát được] | [Mã] |

##### 4.2.2 Độ tin cậy

Mô tả khả năng sẵn sàng, bảo trì, hành vi khi suy giảm, thời gian trung bình
giữa các lỗi, thời gian trung bình sửa lỗi, độ chính xác, tỷ lệ lỗi và các
mục tiêu liên quan.

| Yêu cầu | Thước đo / tiêu chí chấp nhận | Tính năng hoặc ca sử dụng liên quan |
|---|---|---|
| Khả năng sẵn sàng | [Tỷ lệ và khoảng thời gian đo] | [Mã] |
| Thời gian trung bình giữa các lỗi | [Mục tiêu] | [Mã] |
| Thời gian trung bình sửa lỗi | [Mục tiêu] | [Mã] |
| Độ chính xác | [Định nghĩa và mục tiêu] | [Mã] |
| Tỷ lệ lỗi tối đa | [Mục tiêu] | [Mã] |
| Phân loại tỷ lệ lỗi | [Định nghĩa lỗi nhỏ, nghiêm trọng và nghiêm trọng nhất] | [Mã] |

##### 4.2.3 Hiệu năng

Mô tả các yêu cầu về thời gian phản hồi, thông lượng, dung lượng và mức sử
dụng tài nguyên. Chỉ rõ ca sử dụng hoặc tính năng liên quan.

| Yêu cầu | Thước đo / tiêu chí chấp nhận | Tính năng hoặc ca sử dụng liên quan |
|---|---|---|
| Thời gian phản hồi | [Ngưỡng trung bình / tối đa] | [Mã] |
| Thông lượng | [Giao dịch mỗi giây hoặc thước đo tương đương] | [Mã] |
| Dung lượng | [Người dùng, bản ghi, tệp hoặc giao dịch] | [Mã] |
| Mức sử dụng tài nguyên | [Mục tiêu CPU, bộ nhớ, ổ đĩa, mạng] | [Mã] |

##### 4.2.4 [Tên thuộc tính chất lượng]

[Bổ sung phần Bảo mật, Khả năng bảo trì, Tính di động, Tính tương thích hoặc
thuộc tính chất lượng khác khi cần.]

| Yêu cầu | Thước đo / tiêu chí chấp nhận | Tính năng hoặc ca sử dụng liên quan |
|---|---|---|
| [Yêu cầu chất lượng] | [Tiêu chí định lượng hoặc quan sát được] | [Mã] |

### 5. Phụ lục yêu cầu

Sử dụng phần này cho các quy tắc nghiệp vụ, yêu cầu dùng chung, thông báo
ứng dụng và các yêu cầu áp dụng cho nhiều tính năng.

#### 5.1 Quy tắc nghiệp vụ

Liệt kê các quy tắc nghiệp vụ chung mà hệ thống phải tuân thủ.

| Mã | Định nghĩa quy tắc |
|---|---|
| BR-01 | [Quy tắc nghiệp vụ] |
| BR-02 | [Quy tắc nghiệp vụ] |
| BR-03 | [Quy tắc nghiệp vụ] |
| BR-04 | [Quy tắc nghiệp vụ] |
| BR-05 | [Quy tắc nghiệp vụ] |

> **Quy tắc mẫu từ template gốc (thay hoặc xóa):**
>
> | Mã | Định nghĩa quy tắc |
> |---|---|
> | BR-01 | Khung thời gian giao món kéo dài 15 phút và bắt đầu vào mỗi mốc một phần tư giờ. |
> | BR-02 | Việc giao món phải được hoàn tất trong khoảng thời gian từ 10:00 đến 14:00 theo giờ địa phương. |
> | BR-03 | Tất cả món trong cùng một đơn phải được giao đến cùng một địa điểm. |
> | BR-04 | Tất cả món trong cùng một đơn phải sử dụng cùng một phương thức thanh toán. |
> | BR-11 | Nếu đơn cần giao, khách phải thanh toán bằng hình thức khấu trừ vào lương. |
> | BR-12 | Giá đơn được tính bằng tổng giá từng món nhân số lượng, cộng thuế bán hàng và phí giao hàng nếu có. |
> | BR-24 | Chỉ nhân viên căng tin được quản lý căng tin chỉ định mới được tạo, sửa hoặc xóa thực đơn. |
> | BR-33 | Truyền tải có thông tin tài chính hoặc thông tin nhận dạng cá nhân phải được mã hóa 256-bit. |
> | BR-86 | Chỉ nhân viên chính thức mới được đăng ký khấu trừ lương cho giao dịch của công ty. |
> | BR-88 | Nhân viên chỉ được đăng ký thanh toán bữa ăn bằng khấu trừ lương nếu phần lương gộp đang bị khấu trừ cho các lý do khác không vượt quá 40 phần trăm. |

#### 5.2 Yêu cầu dùng chung

[Điền các yêu cầu áp dụng cho nhiều tính năng hoặc toàn bộ hệ thống.]

| Mã | Yêu cầu dùng chung | Phạm vi |
|---|---|---|
| CR-01 | [Yêu cầu dùng chung] | [Tính năng hoặc toàn hệ thống] |
| CR-02 | [Yêu cầu dùng chung] | [Tính năng hoặc toàn hệ thống] |

#### 5.3 Danh sách thông báo ứng dụng

| STT | Mã thông báo | Loại thông báo | Bối cảnh | Nội dung |
|---:|---|---|---|---|
| 1 | MSG-01 | [Nội tuyến / toast / hộp thoại / lỗi trường] | [Bối cảnh] | [Nội dung] |
| 2 | MSG-02 | [Nội tuyến / toast / hộp thoại / lỗi trường] | [Bối cảnh] | [Nội dung] |
| 3 | MSG-03 | [Nội tuyến / toast / hộp thoại / lỗi trường] | [Bối cảnh] | [Nội dung] |
| 4 | MSG-04 | [Nội tuyến / toast / hộp thoại / lỗi trường] | [Bối cảnh] | [Nội dung] |
| 5 | MSG-05 | [Nội tuyến / toast / hộp thoại / lỗi trường] | [Bối cảnh] | [Nội dung] |
| 6 | MSG-06 | [Nội tuyến / toast / hộp thoại / lỗi trường] | [Bối cảnh] | [Nội dung] |
| 7 | MSG-07 | [Nội tuyến / toast / hộp thoại / lỗi trường] | [Bối cảnh] | [Nội dung] |
| 8 | MSG-08 | [Nội tuyến / toast / hộp thoại / lỗi trường] | [Bối cảnh] | [Nội dung] |
| 9 | MSG-09 | [Nội tuyến / toast / hộp thoại / lỗi trường] | [Bối cảnh] | [Nội dung] |

> **Thông báo mẫu từ template gốc (thay hoặc xóa):**
>
> | Mã | Bối cảnh | Nội dung |
> |---|---|---|
> | MSG01 | Không có kết quả tìm kiếm | Không tìm thấy kết quả tìm kiếm. |
> | MSG02 | Bỏ trống trường bắt buộc | Trường có dấu * là bắt buộc. |
> | MSG03 | Cập nhật thông tin tài sản thành công | Cập nhật thông tin tài sản thành công. |
> | MSG04 | Thêm tài sản mới thành công | Thêm tài sản thành công. |
> | MSG05 | Gửi email xác nhận | Email xác nhận đã được gửi đến {địa_chỉ_email}. |
> | MSG06 | Hoàn trả thông tin tài sản thành công | Hoàn trả tài sản thành công. |
> | MSG07 | Xóa thông tin tài sản thành công | Xóa tài sản thành công. |
> | MSG08 | Giá trị nhập vượt độ dài tối đa | Vượt quá độ dài tối đa là {độ_dài_tối_đa}. |
> | MSG09 | Tên người dùng hoặc mật khẩu không đúng | Tên người dùng hoặc mật khẩu không đúng. Vui lòng kiểm tra lại. |

#### 5.4 Yêu cầu khác

[Bổ sung các yêu cầu về quốc tế hóa, bản địa hóa, pháp lý, cấp phép, quy
định, triển khai, chuyển đổi dữ liệu, audit hoặc yêu cầu khác chưa được đề
cập ở trên.]

