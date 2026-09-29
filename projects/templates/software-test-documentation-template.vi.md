# Báo cáo 5 — Tài liệu kiểm thử phần mềm

## Thông tin template

| Trường thông tin | Giá trị |
|---|---|
| Nguồn template | Report5_Test Documentation.docx |
| Trạng thái template | Bản nháp |
| Dự án | [Tên dự án] |
| Mã dự án | [Mã dự án] |
| Phiên bản | [Phiên bản] |
| Ngày | [YYYY-MM-DD] |
| Người lập | [Tên / vai trò] |
| Người phụ trách kiểm thử | [Tên / vai trò] |
| SRS liên quan | [Liên kết hoặc mã tài liệu] |
| Tài liệu thiết kế liên quan | [Liên kết hoặc mã tài liệu] |

> **Cách sử dụng template:** Thay phần giữ chỗ bằng thông tin có bằng chứng
> của dự án. Mỗi kiểm thử phải truy xuất được về một yêu cầu, rủi ro, giao
> diện, quy tắc nghiệp vụ hoặc mục tiêu chất lượng. Ghi lại chính xác build,
> môi trường, dữ liệu kiểm thử và kết quả của từng lần chạy. Không kết luận
> một yêu cầu đã được xác minh chỉ vì đã tạo test case; cần có bằng chứng chạy
> và kết quả.

> **Giữ đúng phạm vi:** Tài liệu này mô tả công việc kiểm thử và bằng chứng,
> không tự thay đổi phạm vi sản phẩm đã duyệt. Nếu chưa thể kiểm thử một yêu
> cầu, phải ghi rõ lý do, rủi ro, người phụ trách và kế hoạch xử lý sau đó.

---

## I. Bảng ghi nhận thay đổi

| Ngày | A*M, D | Người phụ trách | Mô tả thay đổi | Tham chiếu |
|---|---|---|---|---|
| [YYYY-MM-DD] | A | [Tên] | [Mô tả phạm vi, chiến lược hoặc bằng chứng được thêm] | [SRS/review kiểm thử] |
| [YYYY-MM-DD] | M | [Tên] | [Mô tả nội dung kiểm thử được sửa] | [Yêu cầu/build/lỗi] |
| [YYYY-MM-DD] | D | [Tên] | [Mô tả nội dung kiểm thử được xóa] | [Quyết định/review] |
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

*A — Thêm; M — Sửa; D — Xóa. Mỗi dòng cần nêu lý do hoặc tham chiếu của
thay đổi kiểm thử có ý nghĩa.*

---

## II. Tài liệu kiểm thử

### 1. Phạm vi kiểm thử

Mô tả nội dung sẽ kiểm thử, không kiểm thử và lý do. Phạm vi nên bao quát
tính năng, chức năng, vai trò người dùng, giao diện, luồng dữ liệu và yêu cầu
phi chức năng liên quan đến bản phát hành. Dùng SRS và tài liệu thiết kế đã
duyệt làm nguồn chính.

#### 1.1 Mục tiêu kiểm thử

Nêu các quyết định mà kiểm thử phải hỗ trợ, ví dụ xác nhận người dùng hoàn
thành luồng đã duyệt, bảo vệ ranh giới dữ liệu, phát hiện dữ liệu không hợp
lệ, chứng minh hành vi tích hợp hoặc đo mục tiêu chất lượng đã thống nhất.

| Mã mục tiêu | Mục tiêu kiểm thử | Bằng chứng cần có | Người phụ trách |
|---|---|---|---|
| OBJ-01 | [Quyết định hoặc rủi ro mà kiểm thử xử lý] | [Kết quả, log, ảnh, báo cáo] | [Tên/vai trò] |
| OBJ-02 | [Mục tiêu] | [Bằng chứng] | [Tên/vai trò] |

#### 1.2 Yêu cầu và chức năng trong phạm vi

| Mã yêu cầu / tính năng | Yêu cầu hoặc tính năng | Mức kiểm thử | Loại kiểm thử | Kịch bản quan trọng | Bằng chứng dự kiến |
|---|---|---|---|---|---|
| [FR/UC/NFR] | [Yêu cầu hoặc tính năng] | [Unit/tích hợp/hệ thống/chấp nhận] | [Các loại] | [Luồng bình thường và luồng thay thế] | [Vị trí bằng chứng] |
| [Mã] | [Yêu cầu hoặc tính năng] | [Mức] | [Các loại] | [Kịch bản] | [Bằng chứng] |

#### 1.3 Nội dung ngoài phạm vi

Liệt kê nội dung cố ý không kiểm thử trong chu kỳ này. Mỗi nội dung phải
giải thích ranh giới và rủi ro còn lại; không dùng cụm “chưa kiểm thử” mà
không có lý do.

| Nội dung | Lý do loại khỏi phạm vi | Rủi ro/tác động | Người phụ trách / bản phát hành xử lý |
|---|---|---|---|
| [Tính năng, giao diện hoặc thuộc tính chất lượng] | [Lý do] | [Rủi ro] | [Người phụ trách và mục tiêu] |
| [Nội dung] | [Lý do] | [Rủi ro] | [Người phụ trách và mục tiêu] |

#### 1.4 Mức và giai đoạn kiểm thử

Mô tả các giai đoạn áp dụng cho dự án. Với mỗi giai đoạn, xác định đầu vào,
người chịu trách nhiệm, trọng tâm, điều kiện bắt đầu, tiêu chí kết thúc hoặc
chấp nhận và bằng chứng lưu trữ.

| Mức kiểm thử | Mục đích | Đầu vào | Người phụ trách | Điều kiện bắt đầu | Trọng tâm | Tiêu chí kết thúc/chấp nhận | Bằng chứng |
|---|---|---|---|---|---|---|---|
| Unit | [Kiểm tra logic nhỏ độc lập] | [Mã, fixture] | [Vai trò] | [Điều kiện] | [Logic và kiểm tra] | [Tiêu chí] | [Báo cáo/log] |
| Tích hợp | [Kiểm tra tương tác giữa thành phần] | [Build, dịch vụ, dữ liệu] | [Vai trò] | [Điều kiện] | [Giao diện và lưu trữ] | [Tiêu chí] | [Báo cáo/log] |
| Hệ thống | [Kiểm tra hành vi toàn sản phẩm] | [Ứng viên phát hành] | [Vai trò] | [Điều kiện] | [Luồng đầu cuối và chất lượng] | [Tiêu chí] | [Báo cáo/log] |
| Chấp nhận | [Xác nhận kết quả nghiệp vụ] | [Bản ổn định và kịch bản] | [Bên liên quan/vai trò] | [Điều kiện] | [Kết quả người dùng] | [Tiêu chí] | [Biên bản ký] |

#### 1.5 Giả định và ràng buộc

Ghi lại ràng buộc có thể ảnh hưởng đến thiết kế kiểm thử hoặc cách diễn giải
kết quả, như dịch vụ bên thứ ba không sẵn sàng, thiếu dữ liệu kiểm thử, thiếu
thiết bị, điều kiện mạng hạn chế, phụ thuộc xác thực, build không ổn định
hoặc một kiểm tra được thống nhất là thủ công.

| Mã | Giả định hoặc ràng buộc | Ảnh hưởng đến kiểm thử | Biện pháp hoặc xử lý sau |
|---|---|---|---|
| CON-01 | [Ràng buộc/giả định] | [Ảnh hưởng] | [Biện pháp/người phụ trách] |
| CON-02 | [Ràng buộc/giả định] | [Ảnh hưởng] | [Biện pháp/người phụ trách] |

### 2. Chiến lược kiểm thử

Giải thích cách các loại kiểm thử, mức kiểm thử, công cụ, dữ liệu và bằng
chứng phối hợp. Chiến lược phải phù hợp với rủi ro và nêu cách phân loại
lỗi, sửa, kiểm thử lại và đóng lỗi.

#### 2.1 Các loại kiểm thử

Với mỗi loại kiểm thử được chọn, nêu mục tiêu, nội dung, kỹ thuật, dữ liệu,
môi trường, điều kiện bắt đầu, tiêu chí hoàn thành, bằng chứng và vai trò
phụ trách. Thêm hoặc xóa dòng theo dự án.

| Loại kiểm thử | Mục tiêu | Kỹ thuật | Đối tượng chính | Điều kiện bắt đầu | Tiêu chí hoàn thành | Bằng chứng | Người phụ trách |
|---|---|---|---|---|---|---|---|
| Kiểm thử unit | [Kiểm tra logic độc lập] | [Ví dụ, mock, giá trị biên] | [Lớp/hàm] | [Có build] | [Tiêu chí] | [Báo cáo tự động] | [Vai trò] |
| Kiểm thử tích hợp | [Kiểm tra tương tác thành phần] | [Phụ thuộc thật hoặc kiểm soát] | [API, DB, queue] | [Phụ thuộc sẵn sàng] | [Tiêu chí] | [Log/kết quả] | [Vai trò] |
| Kiểm thử hệ thống | [Kiểm tra sản phẩm tổng thể] | [Luồng người dùng và kịch bản] | [Tính năng đầu cuối] | [Ứng viên phát hành] | [Tiêu chí] | [Báo cáo chạy] | [Vai trò] |
| Kiểm thử chấp nhận | [Xác nhận kết quả bên liên quan] | [Kịch bản nghiệp vụ] | [Luồng ưu tiên] | [Môi trường ổn định] | [Quyết định của bên liên quan] | [Biên bản] | [Vai trò] |
| Kiểm thử hồi quy | [Phát hiện ảnh hưởng ngoài ý muốn] | [Bộ kiểm thử lặp lại] | [Hành vi quan trọng] | [Build đã thay đổi] | [Tiêu chí] | [Báo cáo bộ kiểm thử] | [Vai trò] |
| Kiểm thử bảo mật | [Kiểm tra truy cập và bảo vệ dữ liệu] | [Ma trận vai trò, kiểm tra âm, rà soát phụ thuộc] | [Xác thực, phân quyền, dữ liệu nhạy cảm] | [Giao diện sẵn sàng] | [Tiêu chí] | [Báo cáo/phát hiện] | [Vai trò] |
| Kiểm thử hiệu năng | [Kiểm tra mục tiêu phản hồi/dung lượng] | [Tải có kiểm soát và đo lường] | [Request/luồng quan trọng] | [Môi trường đại diện] | [Tiêu chí] | [Báo cáo đo lường] | [Vai trò] |
| Kiểm thử khả dụng/tiếp cận | [Kiểm tra người dùng hoàn thành tác vụ] | [Quan sát kịch bản và rà soát tiếp cận] | [Màn hình người dùng] | [Có build giao diện] | [Tiêu chí] | [Phát hiện/bằng chứng] | [Vai trò] |

##### Quy tắc hoàn thành và xử lý lỗi

| Mã quy tắc | Quy tắc |
|---|---|
| STR-01 | [Định nghĩa khi một lần chạy hoàn tất và các kết quả bắt buộc.] |
| STR-02 | [Cách ghi nhận kiểm thử bị chặn, bỏ qua hoặc không kết luận.] |
| STR-03 | [Mức độ lỗi nào chặn phát hành và ai quyết định.] |
| STR-04 | [Cách kiểm thử lại bản sửa và chọn phạm vi hồi quy.] |

#### 2.2 Mức kiểm thử

Giữ rõ ma trận ánh xạ giữa loại kiểm thử và mức kiểm thử để nhóm biết công
việc nào được thực hiện ở giao điểm nào. Chỉ đánh dấu X khi giao điểm đó có
kế hoạch và người phụ trách cụ thể.

| Loại kiểm thử | Unit | Tích hợp | Hệ thống | Chấp nhận |
|---|:---:|:---:|:---:|:---:|
| [Loại kiểm thử 1] | X |  |  |  |
| [Loại kiểm thử 2] |  | X | X |  |
| [Loại kiểm thử 3] |  |  | X | X |

Mô tả từng mức theo dự án:

| Mức kiểm thử | Ranh giới | Loại kiểm thử | Môi trường/dữ liệu | Vai trò phụ trách | Quyết định kết thúc |
|---|---|---|---|---|---|
| Unit | [Ranh giới] | [Loại] | [Môi trường/dữ liệu] | [Vai trò] | [Quyết định] |
| Tích hợp | [Ranh giới] | [Loại] | [Môi trường/dữ liệu] | [Vai trò] | [Quyết định] |
| Hệ thống | [Ranh giới] | [Loại] | [Môi trường/dữ liệu] | [Vai trò] | [Quyết định] |
| Chấp nhận | [Ranh giới] | [Loại] | [Môi trường/dữ liệu] | [Vai trò] | [Quyết định] |

#### 2.3 Công cụ hỗ trợ

Liệt kê công cụ dùng để tạo, chạy, thu thập và báo cáo kiểm thử. Ghi rõ mục
đích, nhà cung cấp, phiên bản, cấu hình và nơi lưu bằng chứng. Không liệt kê
công cụ chỉ vì đã cài đặt; phải giải thích cách dự án sử dụng công cụ đó.

| Mục đích | Công cụ | Nhà cung cấp / nội bộ | Phiên bản | Cấu hình hoặc cách dùng | Vị trí bằng chứng |
|---|---|---|---|---|---|
| [Mục đích] | [Công cụ] | [Nhà cung cấp/nội bộ] | [Phiên bản] | [Cách sử dụng] | [Đường dẫn/liên kết] |
| [Mục đích] | [Công cụ] | [Nhà cung cấp/nội bộ] | [Phiên bản] | [Cách sử dụng] | [Đường dẫn/liên kết] |

### 3. Kế hoạch kiểm thử

Mô tả nhân sự, môi trường, lịch, dữ liệu và phụ thuộc cần để chạy chiến
lược. Kế hoạch phải chỉ rõ quyền sở hữu thay vì giả định mọi thành viên đều
làm mọi việc.

#### 3.1 Nhân sự

| Người thực hiện | Vai trò | Trách nhiệm và ghi chú | Kỹ năng cần có | Khả dụng / bàn giao |
|---|---|---|---|---|
| [Tên] | [Vai trò] | [Trách nhiệm] | [Kỹ năng] | [Khả dụng/bàn giao] |
| [Tên] | [Vai trò] | [Trách nhiệm] | [Kỹ năng] | [Khả dụng/bàn giao] |

##### Quyền sở hữu review và lỗi

| Hoạt động | Người phụ trách chính | Người review/phê duyệt | Vai trò hỗ trợ | Đầu ra bắt buộc |
|---|---|---|---|---|
| Thiết kế test case | [Vai trò] | [Vai trò] | [Vai trò] | [Case và truy xuất] |
| Chạy kiểm thử | [Vai trò] | [Vai trò] | [Vai trò] | [Kết quả chạy] |
| Phân loại lỗi | [Vai trò] | [Vai trò] | [Vai trò] | [Danh sách ưu tiên] |
| Kiểm thử lại và đóng lỗi | [Vai trò] | [Vai trò] | [Vai trò] | [Bằng chứng] |
| Đề xuất phát hành | [Vai trò] | [Vai trò] | [Vai trò] | [Đề xuất/biên bản] |

#### 3.2 Môi trường kiểm thử

Liệt kê phần mềm, phần cứng, hạ tầng, mạng, dịch vụ bên ngoài, tài khoản,
quyền, dữ liệu và cấu hình cần cho từng môi trường. Tách môi trường dùng
chung khỏi môi trường cục bộ của developer.

| Mã môi trường | Mục đích | Phần mềm / build | Phần cứng / thiết bị | Hạ tầng | Mạng / dịch vụ ngoài | Dữ liệu và tài khoản | Chủ sở hữu |
|---|---|---|---|---|---|---|---|
| ENV-01 | [Mục đích] | [Phiên bản] | [Thiết bị] | [Dịch vụ] | [Điều kiện] | [Dữ liệu/tài khoản] | [Vai trò] |
| ENV-02 | [Mục đích] | [Phiên bản] | [Thiết bị] | [Dịch vụ] | [Điều kiện] | [Dữ liệu/tài khoản] | [Vai trò] |

##### Checklist sẵn sàng môi trường

| Kiểm tra | Trạng thái | Bằng chứng / giá trị |
|---|:---:|---|
| Build ứng dụng đúng và được định danh. | [ ] | [Build/phiên bản] |
| Schema cơ sở dữ liệu và dữ liệu mẫu khớp kế hoạch. | [ ] | [Migration/fixture] |
| Tài khoản kiểm thử có vai trò và quyền cần thiết. | [ ] | [Mã bộ tài khoản] |
| Dịch vụ bên ngoài sẵn sàng hoặc được thay bằng test double đã duyệt. | [ ] | [Endpoint/test double] |
| Thiết bị, trình duyệt, microphone, camera hoặc phần cứng khác sẵn sàng. | [ ] | [Ma trận thiết bị] |
| Log và thu bằng chứng hoạt động mà không làm lộ bí mật. | [ ] | [Cấu hình] |

#### 3.3 Mốc kiểm thử

Sử dụng mốc để thông báo công việc đã chuẩn bị, chạy, review và chấp nhận.
Thêm phụ thuộc và bằng chứng mong đợi tại mỗi mốc.

| Công việc/mốc | Ngày bắt đầu | Ngày kết thúc | Người phụ trách | Điều kiện bắt đầu | Tiêu chí kết thúc / đầu ra | Trạng thái |
|---|---|---|---|---|---|---|
| [Lập kế hoạch kiểm thử] | [YYYY-MM-DD] | [YYYY-MM-DD] | [Vai trò] | [Điều kiện] | [Kế hoạch được duyệt] | [Dự kiến/Đang làm/Xong] |
| [Chuẩn bị test case] | [YYYY-MM-DD] | [YYYY-MM-DD] | [Vai trò] | [Điều kiện] | [Case và truy xuất] | [Trạng thái] |
| [Chạy kiểm thử] | [YYYY-MM-DD] | [YYYY-MM-DD] | [Vai trò] | [Điều kiện] | [Báo cáo chạy] | [Trạng thái] |
| [Kiểm thử lại lỗi] | [YYYY-MM-DD] | [YYYY-MM-DD] | [Vai trò] | [Điều kiện] | [Bằng chứng] | [Trạng thái] |
| [Chấp nhận/phê duyệt] | [YYYY-MM-DD] | [YYYY-MM-DD] | [Vai trò] | [Điều kiện] | [Biên bản quyết định] | [Trạng thái] |

### 4. Test case

Chuẩn bị test case chi tiết trong spreadsheet hoặc công cụ quản lý kiểm thử
đã thống nhất. Template gốc tham chiếu các tài liệu/kết quả sau; cập nhật liên kết
thật khi dùng:

- Test case unit: [Đường dẫn/liên kết tệp test unit]
- Test case khác (tích hợp, hệ thống, chấp nhận): [Đường dẫn/liên kết tệp]

Mỗi test case phải thực hiện độc lập và gồm các thông tin dưới đây. Tách một
kịch bản lớn khi các kết quả, vai trò hoặc điều kiện dữ liệu cần bằng chứng
riêng.

| Trường | Mô tả |
|---|---|
| Mã test case | Mã ổn định, ví dụ TC-FR-001. |
| Tham chiếu yêu cầu/rủi ro | SRS, quy tắc nghiệp vụ, giao diện, lỗi hoặc rủi ro được kiểm tra. |
| Mục tiêu kiểm thử | Điều test case chứng minh hoặc cố gắng phát hiện. |
| Mức và loại kiểm thử | Unit, tích hợp, hệ thống, chấp nhận hoặc loại đã chọn. |
| Độ ưu tiên | Mức ưu tiên nghiệp vụ hoặc phát hành. |
| Điều kiện trước | Tài khoản, trạng thái, dữ liệu, thiết bị và cấu hình cần có. |
| Dữ liệu kiểm thử | Giá trị nhập hoặc mã fixture, không chứa bí mật. |
| Các bước | Hành động có thứ tự để tester khác có thể lặp lại. |
| Kết quả mong đợi | Kết quả quan sát được, trạng thái, thông báo, bản ghi hoặc sự kiện. |
| Kết quả thực tế | Điều xảy ra khi chạy. |
| Bằng chứng | Ảnh, log, response, bản ghi hoặc vị trí báo cáo. |
| Kết quả | Đạt, không đạt, bị chặn, bỏ qua hoặc không kết luận. |
| Tham chiếu lỗi | Mã lỗi phát sinh từ test case. |
| Tester và ngày chạy | Người chạy, build, môi trường và ngày. |

#### Mẫu bản ghi test case

| Mã test case | [Mã] |
|---|---|
| Yêu cầu / rủi ro | [Tham chiếu] |
| Mục tiêu | [Mục tiêu] |
| Mức / loại / ưu tiên | [Giá trị] |
| Điều kiện trước | [Điều kiện] |
| Dữ liệu kiểm thử | [Fixture hoặc giá trị] |
| Các bước | 1. [Bước] <br> 2. [Bước] <br> 3. [Bước] |
| Kết quả mong đợi | [Kết quả] |
| Kết quả thực tế | [Quan sát] |
| Bằng chứng | [Đường dẫn/liên kết] |
| Kết quả | [Đạt/Không đạt/Bị chặn/Bỏ qua/Không kết luận] |
| Tham chiếu lỗi | [DEF-xxx hoặc Không có] |
| Người chạy / ngày / build | [Chi tiết] |

### 5. Báo cáo kiểm thử

Cung cấp kết quả, thống kê và phân tích cho từng lần chạy hoặc ứng viên phát
hành. Các con số phải truy xuất được về test case và bằng chứng chạy.

#### 5.1 Tóm tắt thực thi

| Mã lần chạy | Build/phiên bản | Môi trường | Bắt đầu/kết thúc | Lập kế hoạch | Đã chạy | Đạt | Không đạt | Bị chặn/bỏ qua | Người phụ trách |
|---|---|---|---|---:|---:|---:|---:|---:|---|
| [RUN-01] | [Build] | [ENV-01] | [Ngày] | [Số lượng] | [Số lượng] | [Số lượng] | [Số lượng] | [Số lượng] | [Tên] |

#### 5.2 Độ bao phủ yêu cầu

| Mã yêu cầu | Yêu cầu | Case lập kế hoạch | Case đã chạy | Kết quả | Lỗi còn mở | Bằng chứng |
|---|---|---:|---:|---|---|---|
| [FR/NFR/UC] | [Yêu cầu] | [Số lượng] | [Số lượng] | [Trạng thái] | [Mã lỗi] | [Liên kết] |

#### 5.3 Tổng hợp và phân tích lỗi

| Mức độ / ưu tiên | Đang mở | Đã sửa | Kiểm thử lại đạt | Mở lại | Hoãn | Ảnh hưởng phát hành |
|---|---:|---:|---:|---:|---:|---|
| [Critical] | [Số] | [Số] | [Số] | [Số] | [Số] | [Quyết định] |
| [High] | [Số] | [Số] | [Số] | [Số] | [Số] | [Quyết định] |
| [Medium/Low] | [Số] | [Số] | [Số] | [Số] | [Số] | [Quyết định] |

Giải thích các lỗi quan trọng, mẫu lỗi lặp lại, vấn đề môi trường, lỗi lọt
qua và rủi ro còn lại sau lần chạy.

#### 5.4 Kết luận kiểm thử

| Hạng mục quyết định | Kết quả / phát biểu |
|---|---|
| Kết luận tổng thể | [Đạt, đạt có điều kiện hoặc chưa sẵn sàng] |
| Giới hạn đã biết | [Giới hạn] |
| Rủi ro chưa xử lý | [Rủi ro và người phụ trách] |
| Việc cần làm tiếp | [Hành động và bản phát hành mục tiêu] |
| Phê duyệt / ký xác nhận | [Tên, vai trò, ngày hoặc chờ quyết định] |

## Phụ lục A — Truy xuất yêu cầu đến kiểm thử

| Mã yêu cầu | Tính năng/ca sử dụng | Mã test case | Mức kiểm thử | Kết quả mới nhất | Bằng chứng |
|---|---|---|---|---|---|
| [FR/NFR/UC] | [Tính năng] | [Mã case] | [Mức] | [Kết quả] | [Liên kết] |

## Phụ lục B — Mẫu bản ghi lỗi

| Trường | Giá trị |
|---|---|
| Mã lỗi | [DEF-xxx] |
| Tiêu đề | [Mô tả ngắn] |
| Yêu cầu/test liên quan | [Mã] |
| Môi trường/build | [Chi tiết] |
| Điều kiện trước và các bước | [Các bước tái hiện] |
| Kết quả mong đợi | [Mong đợi] |
| Kết quả thực tế | [Thực tế] |
| Mức độ / ưu tiên | [Giá trị] |
| Bằng chứng | [Liên kết] |
| Người phụ trách / trạng thái | [Chi tiết] |
| Bản sửa và kiểm thử lại | [Chi tiết] |
