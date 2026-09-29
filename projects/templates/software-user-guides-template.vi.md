# Báo cáo 6 — Hướng dẫn sử dụng phần mềm

## Thông tin template

| Trường thông tin | Giá trị |
|---|---|
| Nguồn template | Report6_Software User Guides.docx |
| Trạng thái template | Bản nháp |
| Dự án | [Tên dự án] |
| Mã dự án | [Mã dự án] |
| Bản phát hành / phiên bản | [Phiên bản] |
| Ngày | [YYYY-MM-DD] |
| Người lập | [Tên / vai trò] |
| Người phụ trách kỹ thuật | [Tên / vai trò] |
| Kênh hỗ trợ | [Liên hệ hoặc kênh hỗ trợ] |
| Bản phát hành liên quan | [Build, tag hoặc mã phát hành] |

> **Cách sử dụng template:** Viết hướng dẫn cho người cài đặt, vận hành,
> quản trị hoặc sử dụng sản phẩm. Dùng đúng tên và nhãn xuất hiện trong phiên
> bản giao diện đã phát hành. Mỗi quy trình cần nêu ai được thực hiện, điều
> kiện trước, các bước chính xác, kết quả mong đợi và cách xử lý khi kết quả
> không xuất hiện.

> **Bằng chứng và an toàn:** Dùng ảnh chụp hoặc tham chiếu màn hình khớp với
> bản phát hành được ghi trong tài liệu. Che thông tin cá nhân, token, mật
> khẩu, khóa riêng và bí mật khác trong mọi ảnh và ví dụ. Nếu quy trình thay
> đổi hoặc xóa dữ liệu, giải thích tác động và thêm bước xác nhận hoặc khôi
> phục.

---

## I. Bảng ghi nhận thay đổi

| Ngày | A*M, D | Người phụ trách | Mô tả thay đổi | Tham chiếu |
|---|---|---|---|---|
| [YYYY-MM-DD] | A | [Tên] | [Mô tả hướng dẫn hoặc nội dung phát hành được thêm] | [Phát hành/review] |
| [YYYY-MM-DD] | M | [Tên] | [Mô tả hướng dẫn cài đặt/sử dụng được sửa] | [Lỗi/tính năng/phát hành] |
| [YYYY-MM-DD] | D | [Tên] | [Mô tả hướng dẫn bị xóa] | [Quyết định/phát hành] |
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

*A — Thêm; M — Sửa; D — Xóa. Ghi các thay đổi ảnh hưởng đến khả năng cài
đặt, vận hành hoặc sử dụng bản phát hành.*

---

## II. Gói phát hành và hướng dẫn sử dụng

### 1. Gói bàn giao

Liệt kê mọi thành phần có trong bản phát hành hoặc được bàn giao cho
đơn vị nhận bàn giao. Ghi phiên bản hoặc mã commit, vị trí, người sở hữu và trạng thái
kiểm tra. Template gốc có các hạng mục cơ bản dưới đây; chỉ giữ hạng mục
phù hợp với dự án.

| STT | Hạng mục bàn giao | Phiên bản / mã định danh | Mô tả và nội dung | Vị trí | Người phụ trách | Đã kiểm tra |
|---:|---|---|---|---|---|:---:|
| 1 | Lịch / theo dõi dự án | [Phiên bản/ngày] | [Nội dung] | [Đường dẫn/liên kết] | [Vai trò] | [ ] |
| 2 | Product backlog | [Phiên bản/ngày] | [Nội dung] | [Đường dẫn/liên kết] | [Vai trò] | [ ] |
| 3 | Mã nguồn | [Commit/tag] | [Ứng dụng, module hoặc package] | [Repository/đường dẫn] | [Vai trò] | [ ] |
| 4 | Script cơ sở dữ liệu | [Phiên bản/ngày] | [Migration, dữ liệu mẫu hoặc schema] | [Đường dẫn/liên kết] | [Vai trò] | [ ] |
| 5 | Tài liệu báo cáo cuối | [Phiên bản/ngày] | [Report 7 hoặc báo cáo cuối] | [Đường dẫn/liên kết] | [Vai trò] | [ ] |
| 6 | Tài liệu test case | [Phiên bản/ngày] | [Case và truy xuất] | [Đường dẫn/liên kết] | [Vai trò] | [ ] |
| 7 | Danh sách lỗi | [Phiên bản/ngày] | [Lỗi mở và đã đóng] | [Đường dẫn/liên kết] | [Vai trò] | [ ] |
| 8 | Danh sách issue | [Phiên bản/ngày] | [Issue, rủi ro và quyết định] | [Đường dẫn/liên kết] | [Vai trò] | [ ] |
| 9 | Slide thuyết trình | [Phiên bản/ngày] | [Slide review hoặc cuối kỳ] | [Đường dẫn/liên kết] | [Vai trò] | [ ] |
| 10 | Gói cài đặt / tệp triển khai | [Phiên bản/ngày] | [Kết quả build hoặc triển khai] | [Đường dẫn/liên kết] | [Vai trò] | [ ] |
| 11 | Hướng dẫn sử dụng | [Phiên bản/ngày] | [Tài liệu này và hướng dẫn theo vai trò] | [Đường dẫn/liên kết] | [Vai trò] | [ ] |

#### Nhận diện bản phát hành

| Hạng mục | Giá trị |
|---|---|
| Tên bản phát hành | [Tên] |
| Phiên bản ứng dụng | [Phiên bản] |
| Commit/tag mã nguồn | [Mã định danh] |
| Ngày build | [YYYY-MM-DD] |
| Môi trường được hỗ trợ | [Danh sách môi trường] |
| Giới hạn đã biết | [Danh sách ngắn và mã issue] |
| Bản dùng để rollback | [Vị trí hoặc Không áp dụng] |

### 2. Hướng dẫn cài đặt

Phần này giải thích cách người vận hành được ủy quyền cài đặt và chuẩn bị bản phát
hành. Tách hướng dẫn local, test, staging và production khi điều kiện hoặc
rủi ro khác nhau. Không đặt mật khẩu thật trong tài liệu; tham chiếu quy trình
quản lý bí mật đã được duyệt.

#### 2.1 Yêu cầu hệ thống

Xác định yêu cầu phần cứng, phần mềm, mạng, lưu trữ, tài khoản, quyền và
dịch vụ bên ngoài cần để cài đặt và chạy ứng dụng. Ghi phiên bản hoặc khoảng
tương thích khi kết quả phụ thuộc vào chúng.

##### Yêu cầu cho người vận hành hoặc máy chủ

| Nhóm | Yêu cầu | Phiên bản / dung lượng | Cách kiểm tra | Ghi chú |
|---|---|---|---|---|
| Hệ điều hành | [Hệ điều hành] | [Phiên bản] | [Lệnh hoặc màn hình] | [Ghi chú] |
| Runtime | [Runtime/framework] | [Phiên bản] | [Kiểm tra] | [Ghi chú] |
| Cơ sở dữ liệu | [Cơ sở dữ liệu] | [Phiên bản] | [Kiểm tra] | [Schema/extension] |
| Dịch vụ hỗ trợ | [Cache, queue, storage, ...] | [Phiên bản] | [Kiểm tra] | [Ghi chú] |
| Mạng | [DNS, port, outbound] | [Yêu cầu] | [Kiểm tra] | [Giới hạn] |
| Lưu trữ | [Lưu trữ ứng dụng và dữ liệu] | [Yêu cầu] | [Kiểm tra] | [Tăng trưởng/sao lưu] |
| Quyền | [Quyền hệ điều hành/hệ thống] | [Yêu cầu] | [Kiểm tra] | [Quyền tối thiểu] |

##### Yêu cầu thiết bị người dùng

| Nhóm người dùng | Thiết bị / hệ điều hành | Trình duyệt/app hỗ trợ | Thiết bị vào/ra | Yêu cầu mạng | Ghi chú |
|---|---|---|---|---|---|
| [Vai trò] | [Thiết bị/HĐH] | [Phiên bản] | [Microphone, camera, headset, ...] | [Yêu cầu] | [Ghi chú] |
| [Vai trò] | [Thiết bị/HĐH] | [Phiên bản] | [Thiết bị] | [Yêu cầu] | [Ghi chú] |

##### Điều kiện trước về cấu hình và dịch vụ ngoài

| Điều kiện | Giá trị hoặc thiết lập cần có | Người phụ trách | Cách kiểm tra | Tác động nếu thiếu |
|---|---|---|---|---|
| [Database/schema] | [Thiết lập] | [Vai trò] | [Kiểm tra] | [Tác động] |
| [Dịch vụ ngoài] | [Tài khoản/endpoint/cấu hình đã duyệt] | [Vai trò] | [Kiểm tra] | [Tác động] |
| [Domain/TLS] | [Thiết lập] | [Vai trò] | [Kiểm tra] | [Tác động] |

#### 2.2 Hướng dẫn cài đặt

Viết các bước theo đúng thứ tự người vận hành cần thực hiện. Phân biệt lệnh và
giải thích, nêu nơi chạy từng lệnh và trạng thái hoặc kết quả mong đợi sau
mỗi bước quan trọng.

##### Trước khi cài đặt

| Kiểm tra | Kết quả mong đợi | Bằng chứng / người phụ trách |
|---|---|---|
| Gói phát hành và checksum/tag sẵn sàng. | [Kết quả] | [Bằng chứng] |
| Quyền truy cập và cấu hình đã duyệt sẵn sàng. | [Kết quả] | [Bằng chứng] |
| Điểm sao lưu hoặc rollback được xác nhận nếu dữ liệu sẽ thay đổi. | [Kết quả] | [Bằng chứng] |
| Phụ thuộc và dịch vụ bên ngoài có thể truy cập. | [Kết quả] | [Bằng chứng] |
| Khung bảo trì và kế hoạch thông báo được xác nhận. | [Kết quả] | [Bằng chứng] |

##### Các bước cài đặt

| Bước | Nơi thực hiện / người thực hiện | Hành động | Kết quả mong đợi | Bằng chứng hoặc checkpoint |
|---:|---|---|---|---|
| 1 | [Máy/vai trò] | [Chuẩn bị thư mục, gói hoặc phụ thuộc] | [Kết quả] | [Checkpoint] |
| 2 | [Máy/vai trò] | [Áp dụng cấu hình qua cơ chế đã duyệt] | [Kết quả] | [Checkpoint] |
| 3 | [Máy/vai trò] | [Tạo/cập nhật schema cơ sở dữ liệu] | [Kết quả] | [Output migration] |
| 4 | [Máy/vai trò] | [Cài đặt/khởi động dịch vụ] | [Kết quả] | [Trạng thái dịch vụ] |
| 5 | [Máy/vai trò] | [Chạy health check hoặc smoke test] | [Kết quả] | [Bằng chứng test] |
| 6 | [Máy/vai trò] | [Bàn giao và thông báo trạng thái] | [Kết quả] | [Biên bản bàn giao] |

##### Hướng dẫn cấu hình

Mô tả từng thiết lập người vận hành phải cung cấp hoặc kiểm tra. Tách cấu hình
không nhạy cảm khỏi bí mật và liên kết đến quy trình quản lý bí mật đã duyệt
đối với phần bí mật.

| Thiết lập | Mục đích | Bắt buộc? | Dạng hợp lệ / ví dụ | Nguồn chuẩn | Cách thay đổi an toàn |
|---|---|:---:|---|---|---|
| [Tên thiết lập] | [Mục đích] | Có/Không | [Ví dụ không nhạy cảm] | [Tài liệu/hệ thống] | [Quy trình] |
| [Tham chiếu bí mật] | [Mục đích] | Có/Không | [Chỉ tham chiếu, không ghi giá trị thật] | [Secret manager] | [Quy trình] |

##### Kiểm tra sau cài đặt

| Kiểm tra | Kết quả mong đợi | Kết quả thực tế | Bằng chứng | Đạt/không đạt |
|---|---|---|---|:---:|
| Ứng dụng khởi động và báo trạng thái khỏe. | [Mong đợi] | [Quan sát] | [Liên kết] | [ ] |
| Đăng nhập và ranh giới vai trò hoạt động. | [Mong đợi] | [Quan sát] | [Liên kết] | [ ] |
| Luồng đọc/ghi chính hoạt động với dữ liệu kiểm thử. | [Mong đợi] | [Quan sát] | [Liên kết] | [ ] |
| Cơ sở dữ liệu và xử lý nền hoạt động. | [Mong đợi] | [Quan sát] | [Liên kết] | [ ] |
| Log và monitoring không có lỗi nghiêm trọng ngoài dự kiến. | [Mong đợi] | [Quan sát] | [Liên kết] | [ ] |

##### Rollback, gỡ cài đặt và khôi phục

| Kịch bản | Cách phát hiện | Hành động | Tác động dữ liệu | Cách xác minh | Người phụ trách |
|---|---|---|---|---|---|
| [Cài đặt thất bại] | [Cách phát hiện] | [Bước rollback] | [Tác động] | [Kiểm tra] | [Vai trò] |
| [Rollback bản phát hành] | [Cách phát hiện] | [Các bước] | [Tác động] | [Kiểm tra] | [Vai trò] |
| [Gỡ cài đặt/ngừng hệ thống] | [Cách phát hiện] | [Các bước] | [Lưu trữ/xóa dữ liệu] | [Kiểm tra] | [Vai trò] |

##### Xử lý lỗi khi cài đặt

| Triệu chứng / thông báo | Nguyên nhân có thể | Bước chẩn đoán | Hành động khắc phục | Khi nào cần chuyển cấp |
|---|---|---|---|---|
| [Triệu chứng] | [Nguyên nhân] | [Kiểm tra] | [Hành động] | [Nhóm/liên hệ] |
| [Triệu chứng] | [Nguyên nhân] | [Kiểm tra] | [Hành động] | [Nhóm/liên hệ] |

### 3. Hướng dẫn sử dụng

Phần này viết cho người dùng cuối và quản trị viên. Dùng ngôn ngữ dễ hiểu,
mỗi lần mô tả một kết quả, tránh thuật ngữ triển khai trừ khi người đọc phải
thực hiện thao tác kỹ thuật. Tạo phần riêng cho mỗi vai trò khi quyền hoặc
luồng thao tác khác nhau.

#### 3.1 Tổng quan

Mô tả:

- mục đích ứng dụng và vấn đề ứng dụng giúp người dùng giải quyết;
- đối tượng sử dụng và trách nhiệm theo vai trò;
- cách tổ chức các khu vực chính của ứng dụng;
- thuật ngữ, trạng thái và hành động người dùng nhìn thấy;
- cách đăng nhập, đăng xuất, khôi phục quyền và nhận hỗ trợ;
- các quy tắc quan trọng áp dụng cho mọi luồng;
- thông tin nào được lưu, gửi, công bố hoặc hiển thị cho người khác;
- việc cần làm khi ứng dụng offline, không khả dụng hoặc báo lỗi.

<!-- Chèn ảnh tổng quan sản phẩm hoặc sơ đồ luồng tính năng khi giúp người
mới hiểu ứng dụng. -->

> **Vị trí sơ đồ:** Hình UG-01 — [Tổng quan sản phẩm / luồng tính năng]

##### Tóm tắt vai trò và điều hướng

| Vai trò / đối tượng | Mục tiêu chính | Khu vực được dùng | Giới hạn quan trọng | Luồng liên quan |
|---|---|---|---|---|
| [Vai trò] | [Mục tiêu] | [Khu vực] | [Giới hạn] | [Phần] |
| [Vai trò] | [Mục tiêu] | [Khu vực] | [Giới hạn] | [Phần] |

##### Quy ước giao diện chung

| Quy ước | Ý nghĩa / thao tác người dùng |
|---|---|
| [Mục điều hướng] | [Nơi dẫn đến và khi nào dùng] |
| [Nhãn trạng thái] | [Ý nghĩa và hành động tiếp theo] |
| [Dấu trường bắt buộc] | [Cách hiển thị dữ liệu thiếu] |
| [Hộp thoại xác nhận] | [Khi hành động không thể đảo ngược hoặc ảnh hưởng người khác] |
| [Thông báo] | [Cách hiển thị thành công, cảnh báo và lỗi] |

#### 3.2 Luồng 1 — [Tên luồng]

Mô tả mục đích, người thực hiện và kết quả xác nhận hoàn tất. Thêm sơ đồ
luồng và sơ đồ trạng thái hoặc vai trò liên quan khi cần.

| Hạng mục | Mô tả |
|---|---|
| Mã luồng | [WF-01] |
| Mục đích | [Kết quả người dùng] |
| Actor chính | [Vai trò] |
| Actor/dịch vụ hỗ trợ | [Vai trò/hệ thống] |
| Điều kiện trước | [Điều kiện đã có] |
| Điểm bắt đầu | [Màn hình, liên kết, thông báo hoặc sự kiện] |
| Kết quả thành công | [Dữ liệu/trạng thái được lưu, công bố hoặc hiển thị] |
| Kết quả thay thế | [Các trường hợp hợp lệ khác] |
| Lỗi/khôi phục | [Việc người dùng cần làm] |
| Quyền | [Ai được xem/tạo/sửa/gửi] |

<!-- Chèn sơ đồ luồng. Tên bước trong sơ đồ phải khớp với phần hướng dẫn bên
dưới. -->

> **Vị trí sơ đồ:** Hình UG-02 — [Sơ đồ luồng 1]

##### Hướng dẫn từng bước

| Bước | Màn hình hoặc vị trí | Thao tác người dùng | Thông tin nhập/chọn | Kết quả mong đợi | Ảnh/tham chiếu |
|---:|---|---|---|---|---|
| 1 | [Màn hình] | [Thao tác] | [Dữ liệu] | [Kết quả] | [Ảnh/liên kết] |
| 2 | [Màn hình] | [Thao tác] | [Dữ liệu] | [Kết quả] | [Ảnh/liên kết] |
| 3 | [Màn hình] | [Thao tác] | [Dữ liệu] | [Kết quả] | [Ảnh/liên kết] |
| 4 | [Màn hình] | [Thao tác] | [Dữ liệu] | [Kết quả] | [Ảnh/liên kết] |

##### Kiểm tra, thông báo và khôi phục

| Tình huống | Thông báo hoặc kết quả hiển thị | Hành động người dùng | Dữ liệu được giữ? | Escalate |
|---|---|---|:---:|---|
| [Dữ liệu thiếu/không hợp lệ] | [Thông báo] | [Cách sửa] | Có/Không | [Liên hệ] |
| [Không đủ quyền] | [Thông báo] | [Vai trò/hành động cần có] | Có/Không | [Liên hệ] |
| [Lỗi mạng/dịch vụ] | [Thông báo] | [Thử lại/offline/khôi phục] | Có/Không | [Liên hệ] |

##### Checklist hoàn tất

| Kiểm tra | Hoàn tất |
|---|:---:|
| Bản ghi hoặc hành động có trạng thái mong đợi. | [ ] |
| Người dùng nhận được hoặc xem được xác nhận/báo cáo. | [ ] |
| Không tạo bản ghi trùng hoặc ngoài ý muốn. | [ ] |
| Người dùng hiểu nhiệm vụ hoặc thông báo tiếp theo. | [ ] |

#### 3.3 Luồng 2 — [Tên luồng]

Lặp lại đầy đủ cấu trúc trên cho một kết quả người dùng quan trọng khác.
Không gộp các thao tác không liên quan thành một quy trình mơ hồ.

| Hạng mục | Mô tả |
|---|---|
| Mã luồng | [WF-02] |
| Mục đích | [Kết quả người dùng] |
| Actor chính | [Vai trò] |
| Actor/dịch vụ hỗ trợ | [Vai trò/hệ thống] |
| Điều kiện trước | [Điều kiện] |
| Điểm bắt đầu | [Màn hình/sự kiện] |
| Kết quả thành công | [Kết quả] |
| Kết quả thay thế | [Các trường hợp] |
| Lỗi/khôi phục | [Khôi phục] |
| Quyền | [Quy tắc truy cập] |

> **Vị trí sơ đồ:** Hình UG-03 — [Sơ đồ luồng 2]

| Bước | Màn hình hoặc vị trí | Thao tác người dùng | Thông tin nhập/chọn | Kết quả mong đợi | Ảnh/tham chiếu |
|---:|---|---|---|---|---|
| 1 | [Màn hình] | [Thao tác] | [Dữ liệu] | [Kết quả] | [Ảnh/liên kết] |
| 2 | [Màn hình] | [Thao tác] | [Dữ liệu] | [Kết quả] | [Ảnh/liên kết] |
| 3 | [Màn hình] | [Thao tác] | [Dữ liệu] | [Kết quả] | [Ảnh/liên kết] |

<!-- Bổ sung các phần luồng 3.4, 3.5, ... theo tính năng và vai trò của bản
phát hành. -->

### 4. Hỗ trợ, xử lý sự cố và câu hỏi thường gặp

Phần tùy chọn này giúp người dùng có hướng xử lý an toàn khi không hoàn
thành được luồng. Không yêu cầu người dùng thay đổi thiết lập được bảo vệ
hoặc cung cấp bí mật.

| Câu hỏi hoặc triệu chứng | Giải thích có thể | Hành động người dùng | Khi nào liên hệ hỗ trợ | Tham chiếu |
|---|---|---|---|---|
| [Câu hỏi/triệu chứng] | [Giải thích] | [Hành động] | [Điều kiện chuyển cấp] | [Luồng/issue] |
| [Câu hỏi/triệu chứng] | [Giải thích] | [Hành động] | [Điều kiện escalate] | [Tham chiếu] |

## Phụ lục A — Danh mục ảnh và thuật ngữ

| Mã | Màn hình / ảnh | Build/phát hành | Dùng ở phần | Đã che dữ liệu? | Người phụ trách |
|---|---|---|---|:---:|---|
| IMG-01 | [Tên màn hình] | [Build] | [Phần] | Có/Không | [Tên] |

| Thuật ngữ | Ý nghĩa hướng tới người dùng | Ghi chú / trạng thái liên quan |
|---|---|---|
| [Thuật ngữ] | [Định nghĩa ngôn ngữ thông thường] | [Ghi chú] |

## Phụ lục B — Checklist review hướng dẫn

| Hạng mục kiểm tra | Trạng thái | Bằng chứng / người review |
|---|:---:|---|
| Hướng dẫn khớp với giao diện và build đã phát hành. | [ ] | [Tham chiếu] |
| Mọi quy trình nêu actor, điều kiện trước, kết quả và luồng lỗi. | [ ] | [Tham chiếu] |
| Ảnh chụp dễ đọc và không chứa dữ liệu cá nhân hoặc bí mật. | [ ] | [Tham chiếu] |
| Hướng dẫn cài đặt có cấu hình, xác minh và rollback. | [ ] | [Tham chiếu] |
| Giới hạn vai trò và thao tác thay đổi dữ liệu được nêu rõ. | [ ] | [Tham chiếu] |
| Liên kết và tài liệu/kết quả tham chiếu có thể truy cập đúng đối tượng. | [ ] | [Tham chiếu] |
| Người làm theo hướng dẫn có thể hoàn thành luồng mà không phải đoán. | [ ] | [Tham chiếu] |
