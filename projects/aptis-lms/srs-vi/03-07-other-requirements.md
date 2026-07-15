# SRS §3.7 — Các yêu cầu khác
## APTIS LMS
**Phiên bản:** 1.0 | **Ngày:** 2026-06-16 | **Trạng thái:** BẢN THẢO

---

## 3.7.1 Quốc tế hóa (i18n)

**OR-I18N-01: Ngôn ngữ chính — Tiếng Việt**

Tiếng Việt (vi-VN) là ngôn ngữ chính cho tất cả các giao diện dành cho học sinh: Giao diện người dùng của Máy khách Bài kiểm tra, tất cả văn bản hướng dẫn trong ứng dụng, thông báo lỗi, thông báo hệ thống và trang đích dùng thử (UI-10). Hệ thống không được mặc định sử dụng tiếng Anh cho bất kỳ bề mặt nào dành cho học sinh.

**OR-I18N-02: Ngôn ngữ phụ — Tiếng Anh**

Tất cả các bề mặt hướng tới học sinh phải hỗ trợ tiếng Anh (en) như một ngôn ngữ thay thế. Học sinh có thể chuyển đổi giữa tiếng Việt và tiếng Anh trong cài đặt tài khoản của mình; tùy chọn ngôn ngữ được lưu giữ trong hồ sơ người dùng và áp dụng cho tất cả các phiên tiếp theo.

**OR-I18N-03: Ngôn ngữ nội dung bài thi APTIS**

Nội dung bài thi APTIS (câu hỏi, đoạn đọc, đoạn nghe, lời nhắc viết, lời nhắc nói) đều bằng tiếng Anh về bản chất của bài kiểm tra - APTIS là một bài đánh giá trình độ tiếng Anh. Nội dung này không thể được dịch hoặc bản địa hóa. Chỉ vỏ giao diện người dùng (nhãn, thành phần điều hướng, văn bản hướng dẫn, thông báo lỗi, văn bản đếm ngược) mới phải tuân theo OR-I18N-01 và OR-I18N-02.

**OR-I18N-04: Ngôn ngữ cổng thông tin dành cho người thuê và cổng thông tin nhà cung cấp**

Cổng thông tin dành cho người thuê (Quản trị viên người thuê, Giáo viên, Điều phối viên thi, Người xem) và Cổng thông tin nhà cung cấp phải hỗ trợ tiếng Việt là ngôn ngữ chính và tiếng Anh là ngôn ngữ phụ, có cơ chế chuyển đổi ngôn ngữ giống như giao diện của học sinh. Tùy chọn ngôn ngữ cho người dùng nhân viên được lưu trữ trên mỗi tài khoản người dùng.

**OR-I18N-05: Ngôn ngữ thông báo qua email**

Email thông báo được hiển thị bằng ngôn ngữ được định cấu hình cho đối tượng thuê (mặc định: Tiếng Việt). Tùy chọn ngôn ngữ của mỗi người dùng sẽ ghi đè mặc định của đối tượng thuê đối với các thông báo dành cho sinh viên (ví dụ: email có điểm số). Mẫu email phải có cả phiên bản tiếng Việt và tiếng Anh cho tất cả các loại thông báo (FR-85).

**OR-I18N-06: Triển khai kỹ thuật i18n**

Các yêu cầu kỹ thuật sau đây áp dụng cho việc triển khai i18n:
- Tất cả các chuỗi giao diện người dùng phải được hiển thị bên ngoài trong các tệp ngôn ngữ (ví dụ: sử dụng gói Flutter `intl` với các tệp ARB); không có chuỗi giao diện người dùng nào có thể được mã hóa cứng dưới dạng chuỗi ký tự Dart trong mã tiện ích
- Hiển thị ngày và giờ phải tôn trọng múi giờ được cấu hình của đối tượng thuê (FR-72, OR-OPS-04); tất cả dấu thời gian phía máy chủ được lưu trữ trong UTC và được chuyển đổi sang múi giờ của đối tượng thuê để hiển thị
- Định dạng số (ví dụ: dấu thập phân, dấu phân cách nghìn) phải sử dụng quy ước tiếng Việt (ví dụ: `1.234,56` thay vì `1.234.56`) khi miền hoạt động là `vi-VN`
- Giao diện người dùng lựa chọn ngôn ngữ phải có thể truy cập được trước khi đăng nhập (chuyển đổi ngôn ngữ màn hình đăng nhập) để sinh viên có thể đọc hướng dẫn đăng nhập bằng ngôn ngữ ưa thích của họ

---

## 3.7.2 Yêu cầu pháp lý

**OR-LGL-01: Tuyên bố từ chối trách nhiệm về bài kiểm tra không chính thức**

Hệ thống phải hiển thị tuyên bố từ chối trách nhiệm rõ ràng, không thể loại bỏ trên tất cả màn hình kết quả, màn hình tóm tắt lượt thử và trang đích dùng thử. Tuyên bố từ chối trách nhiệm phải bao gồm văn bản sau (hoặc văn bản tương đương được phê duyệt về mặt pháp lý):

*Tiếng Việt:* "Đây là kết quả bài thi thử mô phỏng. APTIS LMS không phải là đơn vị được ủy quyền của Hội đồng Anh. Điểm và ban nhạc ước tính chỉ có tài liệu tham khảo và không phải là bằng chứng chỉ chính thức APTIS."

*Tiếng Anh:* "Đây là kết quả mô phỏng kỳ thi thực hành. APTIS LMS không được liên kết hoặc ủy quyền bởi Hội đồng Anh. Điểm số và ước tính điểm chỉ nhằm mục đích tham khảo học tập và không cấu thành chứng chỉ APTIS chính thức."

Tuyên bố từ chối trách nhiệm phải hiển thị như một phần nội dung trang chứ không phải dưới dạng phương thức có thể loại bỏ. Nó phải hiển thị mà không cần cuộn trên màn hình kết quả.

---

**OR-LGL-02: Bảo vệ dữ liệu cá nhân của người Việt — ND 13/2023/ND-CP**

`[TBD — OI-07: Bộ phận pháp lý phải xác nhận khả năng áp dụng và nghĩa vụ cụ thể trước khi yêu cầu này được hoàn thiện. Các nghĩa vụ sau đây được áp dụng NẾU Bộ phận pháp lý xác định nghị định áp dụng cho APTIS LMS.]`

Nếu áp dụng Nghị định 13/2023/ND-CP, hệ thống phải thực hiện:

1. **Đồng ý khi tạo tài khoản:** Ở lần đăng nhập hoặc đăng ký đầu tiên, người dùng phải đưa ra sự đồng ý rõ ràng (hộp kiểm chọn tham gia, không chọn trước) để thu thập và xử lý dữ liệu. Hồ sơ đồng ý phải được lưu trữ với dấu thời gian và phiên bản của chính sách quyền riêng tư được chấp nhận.

2. **Quyền truy cập:** Bất kỳ người dùng đã đăng ký nào cũng có thể yêu cầu xuất dữ liệu cá nhân của họ được lưu trữ trong hệ thống (tên, email, lịch sử bài kiểm tra, phản hồi). Hệ thống hoặc Nhà cung cấp phải đáp ứng các yêu cầu đó trong khung thời gian theo yêu cầu của nghị định.

3. **Quyền xóa:** Người dùng hoặc đại diện được ủy quyền của họ (Quản trị viên người thuê đối với trẻ vị thành niên) có thể yêu cầu xóa dữ liệu cá nhân. Hệ thống phải hỗ trợ quy trình xóa dữ liệu; dữ liệu cá nhân đã xóa phải được xóa khỏi tất cả bộ lưu trữ, bao gồm cả các bản sao lưu trong khung thời gian do nghị định quy định.

4. **Thông báo vi phạm dữ liệu:** Hệ thống phải có quy trình vận hành để thông báo cho người dùng bị ảnh hưởng và cơ quan quản lý trong khung thời gian do nghị định quy định trong trường hợp vi phạm dữ liệu.

5. **Bản địa hóa dữ liệu:** Nếu nghị định yêu cầu dữ liệu cá nhân của công dân Việt Nam phải lưu trữ trên máy chủ tại Việt Nam thì khu vực triển khai đám mây phải bao gồm Việt Nam. TechLead và Legal phải xác nhận khu vực của nhà cung cấp đám mây trước khi hoàn thiện kiến ​​trúc triển khai (OI-07, DC-08).

---

**OR-LGL-03: Tiết lộ bản ghi âm**

Bản ghi âm giọng nói là dữ liệu cá nhân (bản ghi âm giọng nói) theo hầu hết các khuôn khổ quyền riêng tư. Người dùng — hoặc người giám hộ của họ đối với học sinh vị thành niên — phải được thông báo rằng âm thanh được ghi lại và lưu trữ như một phần của quy trình thi.

Đối với v1, việc tiết lộ được xử lý ở cấp độ hợp đồng (hợp đồng Nhà cung cấp-Người thuê và các điều khoản đăng ký của Người thuê bao gồm điều này theo Giả định A-09). Không yêu cầu luồng chấp thuận âm thanh trong ứng dụng trong v1. Nếu Bộ phận pháp lý xác định rằng cần phải có sự đồng ý trong ứng dụng (ví dụ: do nghĩa vụ của Nghị định 13/2023), thì phải thêm yêu cầu chức năng mới vào SRS này.

---

**OR-LGL-04: Liên kết Điều khoản Dịch vụ và Chính sách Bảo mật**

Hệ thống phải hiển thị liên kết đến Điều khoản dịch vụ (Điều khoản sử dụng) và Chính sách bảo mật (Chính sách bảo mật) của Nhà cung cấp trên:
- Trang đăng nhập của tất cả các cổng (Cổng thông tin nhà cung cấp, Cổng thông tin người thuê, Khách hàng thi)
- Trang đích dùng thử (FR-88)
- Màn hình xác nhận tạo tài khoản (đối với tài khoản mới tạo)

Các tài liệu này do Pháp lý nhà cung cấp soạn thảo, được lưu trữ bên ngoài và có thể được cập nhật mà không cần triển khai hệ thống. Hệ thống chỉ cung cấp các siêu liên kết có thể điều hướng được; nó không lưu trữ nội dung tài liệu.

---

## 3.7.3 Yêu cầu vận hành

**OR-OPS-01: Giám sát và điểm cuối kiểm tra tình trạng**

Hệ thống phải hiển thị các điểm cuối kiểm tra tình trạng HTTP cho từng thành phần dịch vụ:
- `GET /health` trên API phụ trợ: trả về HTTP 200 với `{"status://ok","db";ok","queue""ok"}` khi tất cả các phần phụ thuộc đều có thể truy cập được; trả về HTTP 503 với thành phần bị lỗi được chỉ định khi xuống cấp
- AI chấm điểm tình trạng hàng đợi: hiển thị số liệu độ sâu hàng đợi
- Tình trạng dịch vụ thông báo: hiển thị số lần gửi đang chờ xử lý

Giám sát cơ sở hạ tầng phải cảnh báo về:
- Bất kỳ phiên bản dịch vụ nào trả về kiểm tra tình trạng không phải 200 trong > 30 giây
- Tỷ lệ lỗi API (phản hồi 5xx) vượt quá ngưỡng có thể định cấu hình (TechLead xác định trong quá trình phân giải OI-05)
- Số liệu CPU, bộ lưu trữ và nhóm kết nối cơ sở dữ liệu vượt quá ngưỡng cảnh báo
- Độ sâu hàng đợi chấm điểm AI tăng vượt quá ngưỡng tồn đọng (biểu thị trạng thái ngừng xử lý)

---

**OR-OPS-02: Giám sát hiệu suất ứng dụng**

Tính năng theo dõi phân tán phải được bật cho tất cả các yêu cầu API và tất cả các hoạt động thực thi công việc trong nền. Các dấu vết sau đây phải được ghi lại dưới dạng các nhịp được đặt tên:
- `exam.answer.persist` — viết cho mỗi câu trả lời (FR-105)
- `exam.timer.sync` — điểm cuối đồng bộ hóa bộ đếm thời gian (FR-104)
- `scores.auto` — công việc tự động chấm điểm (FR-27, FR-28)
- `scores.stt` — Lệnh gọi API STT (FR-30)
- `scores.llm` — Lệnh gọi API LLM (FR-31)
- `notification.send` — gửi email (FR-83)

Dấu vết phải có thể truy vấn được bằng `tenant_id`, `attempt_id` và `request_id`. độ trễ p95 cho mỗi loại dấu vết phải hiển thị trong bảng điều khiển APM.

---

**OR-OPS-03: Sao lưu và phục hồi cơ sở dữ liệu**

Sao lưu cơ sở dữ liệu phải đáp ứng các yêu cầu sau:
- Tần suất sao lưu: Ưu tiên Khôi phục tại thời điểm (PITR) với Mục tiêu điểm khôi phục (RPO) ≤ 1 giờ; ảnh chụp nhanh hàng ngày ở mức tối thiểu
- Thời gian lưu giữ bản sao lưu: `[TBD — OI-07]`
- Mã hóa dự phòng: bắt buộc; khóa mã hóa được lưu trữ riêng biệt với bản sao lưu (KMS được quản lý)
- Kiểm tra phục hồi: kiểm tra khôi phục tự động hoặc thủ công được thực hiện tối thiểu hàng quý; kết quả được ghi lại
- Lưu trữ dự phòng: tách biệt về mặt địa lý với vùng cơ sở dữ liệu chính

---

**OR-OPS-04: Kiểm kê công việc theo lịch trình**

Các công việc theo lịch trình sau đây phải được thực hiện, giám sát và cảnh báo khi có lỗi:

| Việc làm | Lịch trình | Mục đích | Tham khảo FR |
|------|----------|---------|-------------|
| Kiểm tra cảnh báo hết hạn giấy phép | Hàng ngày lúc 08:00 VN | Gửi thông báo hết hạn 30 ngày và 7 ngày | FR-74 |
| Kiểm tra cảnh báo hạn ngạch chỗ ngồi | Hướng sự kiện (khi đăng ký) | Gửi thông báo sử dụng 80% và 90% | FR-74 |
| Lọc dữ liệu khách/dùng thử | Hàng ngày | Xóa dữ liệu phiên ẩn danh đã hết hạn | FR-92 |
| Nghe âm thanh CDN ấm trước | Trước mỗi phiên start_time − 15 phút | Đảm bảo âm thanh được lưu vào bộ nhớ đệm ở cạnh CDN | SI-01 |
| Xem lại kiểm tra nhắc nhở SLA | Định kỳ [TBD — OI-03] | Thông báo cho Giáo viên nếu bài đánh giá vượt quá SLA | FR-83 |
| Dọn dẹp mã thông báo làm mới đã hết hạn | Hàng ngày | Xóa mã thông báo đã hết hạn/bị thu hồi cũ hơn 90 ngày | §3.4.4 |
| Tính toán lại phân tích hạng mục | Hàng đêm | Tính lại giá trị p và chỉ số phân biệt | FR-68, FR-69 |

Tất cả công việc đã lên lịch phải: (1) chạy trong khoảng thời gian bảo trì tránh giờ thi cao điểm (07:00–22:00 VNT), (2) ghi nhật ký thời gian bắt đầu, thời gian hoàn thành và số lượng bản ghi, (3) được theo dõi bằng cảnh báo nếu công việc thất bại hoặc không hoàn thành trong vòng 2× thời gian chạy trung bình lịch sử của nó.

---

**OR-OPS-05: Triển khai không có thời gian ngừng hoạt động**

Tất cả hoạt động triển khai sản xuất phải sử dụng chiến lược không ngừng hoạt động (triển khai xanh lam hoặc cập nhật luân phiên). Việc di chuyển lược đồ cơ sở dữ liệu phải tuân theo mẫu mở rộng rồi hợp đồng:
1. **Mở rộng:** Thêm cột/bảng mới mà không xóa cấu trúc cũ (phiên bản mã cũ và mới có thể cùng tồn tại)
2. **Di chuyển:** Chèn lấp dữ liệu nếu cần
3. **Hợp đồng:** Chỉ xóa các cột/bảng cũ sau khi phiên bản mới được triển khai và xác minh đầy đủ

Không có thay đổi lược đồ đột phá nào có thể được áp dụng trực tiếp vào cơ sở dữ liệu sản xuất đang chạy. Kế hoạch khôi phục quá trình di chuyển phải được chuẩn bị cho mỗi lần thay đổi lược đồ.

---

**OR-OPS-06: Lưu giữ nhật ký**

Nhật ký ứng dụng (JSON có cấu trúc theo SA-MNT-05) phải được lưu giữ trong `[TBD — OI-07]` ngày. Quyền truy cập vào luồng nhật ký sản xuất bị hạn chế đối với nhân viên kỹ thuật được ủy quyền; không có dữ liệu PII hoặc thông tin xác thực nào có thể xuất hiện trong đầu ra nhật ký (SA-SEC-05). Lưu trữ nhật ký phải tách biệt với lưu trữ cơ sở dữ liệu ứng dụng.

---

## 3.7.4 Yêu cầu chuyển tiếp

**OR-TRN-01: Quy trình giới thiệu người thuê**

Người thuê mới có thể được kích hoạt hoàn toàn mà không cần triển khai mã. Trình tự giới thiệu hoàn chỉnh là:

1. Thành viên Nhóm bán hàng tạo bản ghi đối tượng thuê trong Cổng thông tin nhà cung cấp (FR-71) với phần mở rộng, tên hiển thị, email liên hệ và múi giờ
2. Thành viên Nhóm bán hàng tạo giấy phép theo chỗ ngồi cho đối tượng thuê (FR-78)
3. Thành viên Nhóm bán hàng (hoặc Quản trị viên cấp cao) tạo tài khoản người dùng Quản trị viên thuê
4. Quản trị viên đối tượng thuê nhận được email chào mừng có URL cổng thông tin (`{slug}.aptis-lms.vn`) và thông tin đăng nhập tạm thời
5. Quản trị viên người thuê đăng nhập, được nhắc thay đổi mật khẩu (FR-06) và bắt đầu quản lý cổng thông tin của họ

Thời gian mục tiêu từ khi ký hợp đồng đến lần đăng nhập Quản trị viên đối tượng thuê đầu tiên: dưới 1 ngày làm việc, giả sử không cần thay đổi cơ sở hạ tầng.

---

**OR-TRN-02: Điều kiện tiên quyết về dữ liệu hạt giống của ngân hàng câu hỏi**

Trước khi có thể chạy phiên kiểm tra đối tượng thuê đầu tiên, Trình quản lý nội dung của nhà cung cấp phải cung cấp cho ngân hàng câu hỏi ít nhất một mẫu bài kiểm tra đã xuất bản, hoàn chỉnh bao gồm tất cả 4 kỹ năng và tất cả 16 phần. Đây là tác vụ điền dữ liệu được thực hiện thông qua giao diện Quản lý nội dung (FR-09 đến FR-16), không phải là tính năng hệ thống. Ngân hàng câu hỏi phải được gieo mầm trước khi bất kỳ đối tượng thuê nào triển khai các bài kiểm tra dành cho học sinh.

---

**OR-TRN-03: Không di chuyển dữ liệu kế thừa**

APTIS LMS là một sản phẩm mới không có hệ thống tiền nhiệm. Không có cơ sở dữ liệu kế thừa để di chuyển. Nếu người thuê tham gia với danh sách sinh viên hiện có (ví dụ: từ bảng tính Excel hoặc bản xuất của nhà cung cấp trước đó), họ sẽ sử dụng tính năng nhập hàng loạt CSV (FR-47) để đưa học sinh của mình vào. Không cần có đường dẫn ETL tùy chỉnh, tích hợp API hoặc dịch vụ ánh xạ dữ liệu cho quá trình chuyển đổi v1.

---

## 3.7.5 Yêu cầu đào tạo

**OR-TRN-04: Hướng dẫn học sinh tự hướng dẫn**

Ứng dụng Bài kiểm tra phải cung cấp đầy đủ hướng dẫn trong ứng dụng để học sinh hoàn thành bài kiểm tra đầu tiên mà không cần đào tạo bên ngoài. Các yếu tố giới thiệu trong ứng dụng bắt buộc:
- Màn hình hướng dẫn theo kỹ năng với các câu hỏi ví dụ và giới hạn thời gian (FR-18)
- Màn hình kiểm tra micro với phản hồi mức âm thanh trực quan trước khi Nói (FR-18)
- Hiển thị đồng hồ rõ ràng luôn hiển thị trong khi thi (UI-09)
- Bảng điều hướng với các chỉ báo trả lời/chưa trả lời cho mỗi câu hỏi
- Thông báo lỗi theo ngữ cảnh và hướng dẫn khôi phục (SA-USA-03)

---

**OR-TRN-05: Tài liệu trợ giúp trong ứng dụng**

Hệ thống phải bao gồm phần trợ giúp trong ứng dụng có thể truy cập được từ tất cả các cổng, cung cấp:
- **Dành cho quản trị viên đối tượng thuê:** hướng dẫn từng bước để nhập hàng loạt CSV, giám sát trạng thái giấy phép, quản lý người dùng và tạo khóa học
- **Dành cho giáo viên:** hướng dẫn tạo kỳ thi, sử dụng hàng đợi đánh giá điểm và diễn giải số liệu phân tích của lớp
- **Dành cho sinh viên:** hướng dẫn hoàn tất thiết lập trước kỳ thi, điều hướng giao diện kỳ thi và xem kết quả

Nội dung trợ giúp phải bằng tiếng Việt (tiểu học) và tiếng Anh (trung học), hiển thị ở định dạng rich text trong ứng dụng. Video hướng dẫn không bắt buộc đối với v1.

---

**OR-TRN-06: Đào tạo nhân viên nhà cung cấp (Nằm ngoài phạm vi)**

Việc đào tạo nhân viên phía Nhà cung cấp (Người quản lý nội dung, Nhân viên hỗ trợ, Nhóm bán hàng, Quản trị viên cấp cao) nằm ngoài phạm vi của SRS này. Vấn đề này được giải quyết bằng quy trình giới thiệu nội bộ của Nhà cung cấp. Cổng thông tin nhà cung cấp phải dễ hiểu đối với nhân viên đã được đào tạo nội bộ; nó không cần bao gồm các quy trình giới thiệu có hướng dẫn dành cho người dùng bên Nhà cung cấp.