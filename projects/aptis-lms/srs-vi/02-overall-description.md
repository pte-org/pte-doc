# SRS §2 — Mô tả tổng thể
## APTIS LMS
**Phiên bản:** 1.0 | **Ngày:** 2026-06-16 | **Trạng thái:** BẢN THẢO

---

## 2.1 Quan điểm sản phẩm

APTIS LMS là một sản phẩm SaaS mới, độc lập, không có hệ thống tiền thân. Nó không phải là một mô-đun hoặc phần mở rộng của bất kỳ nền tảng hiện có nào.

### 2.1.1 Bối cảnh hệ thống

```
┌──────────────────────────────────────────────────────────────────┐
│                      APTIS LMS Platform                          │
│                                                                  │
│  ┌───────────────┐  ┌───────────────┐  ┌──────────────────┐    │
│  │ Vendor Portal │  │ Tenant Portal │  │   Exam Client    │    │
│  │   (Flutter    │  │   (Flutter    │  │   (Flutter       │    │
│  │    Web)       │  │    Web)       │  │ Desktop/Web/Mob) │    │
│  └──────┬────────┘  └──────┬────────┘  └────────┬─────────┘    │
│         └──────────────────┼──────────────────────┘             │
│                            │                                     │
│               ┌────────────▼──────────────┐                     │
│               │        Backend API         │                     │
│               │   REST + WebSocket/SSE     │                     │
│               └───┬──────────┬────────────┘                     │
│                   │          │                                   │
│          ┌────────▼──┐  ┌───▼──────────────┐                   │
│          │ Relational │  │  Async Job Queue  │                   │
│          │  Database  │  │ (AI Scoring +     │                   │
│          └────────────┘  │  Notifications)   │                   │
│                          └───────────────────┘                   │
└──────────────────────────────────────────────────────────────────┘
         │                 │                  │
   ┌─────▼──────┐  ┌───────▼──────┐  ┌───────▼───────┐
   │   Cloud    │  │ Email / Push │  │   AI APIs     │
   │  Storage   │  │   Service    │  │  STT + LLM    │
   │ (S3 / GCS) │  │(SendGrid/FCM)│  │    [TBD]      │
   └────────────┘  └──────────────┘  └───────────────┘
```

### 2.1.2 Kiến trúc nhiều người thuê

Mỗi đối tượng thuê được xác định bằng một tên miền phụ duy nhất:

- `admin.aptis-lms.vn` ​​→ Cổng thông tin nhà cung cấp (không có phạm vi đối tượng thuê)
- `{slug}.aptis-lms.vn` ​​→ Cổng thông tin người thuê + Đăng nhập ứng dụng khách kiểm tra
- Chứng chỉ SSL ký tự đại diện bao gồm `*.aptis-lms.vn`
- Tất cả các yêu cầu API phụ trợ đều mang `tenant_id` được giải quyết từ tên miền phụ; mọi truy vấn cơ sở dữ liệu đều nằm trong phạm vi đối tượng thuê đó

### 2.1.3 Giao diện hệ thống bên ngoài

| Hệ thống bên ngoài | Phương hướng | Mục đích |
|---|---|---|
| Lưu trữ đối tượng đám mây (S3/GCS) | Đọc + Viết | Ghi âm, Nghe âm thanh, hình ảnh, xuất báo cáo |
| Dịch vụ Email (SendGrid/SES - TBD) | Đi | Tất cả thông báo qua email |
| Nhắn tin qua đám mây Firebase | Đi | Thông báo đẩy (Flutter di động, nếu có trong phạm vi) |
| API STT (TBD — OI-02) | Đi | Chuyển lời nói thành văn bản cho bản ghi âm Nói |
| API LLM (TBD — OI-02) | Đi | Tính điểm AI viết và nói |

---

## 2.2 Chức năng sản phẩm

### 2.2.1 Chức năng cổng thông tin nhà cung cấp
- Quản lý vòng đời của đối tượng thuê (tạo, định cấu hình, tạm dừng, kích hoạt lại)
- Duy trì ngân hàng câu hỏi APTIS (cả 4 kỹ năng, 16 phần, âm thanh, hình ảnh, mẫu đề thi)
- Quản lý giấy phép theo chỗ ngồi (Nhóm bán hàng tạo; hệ thống thực thi hạn ngạch và hết hạn)
- Giám sát việc sử dụng của nhiều người thuê và cung cấp quyền truy cập chỉ đọc cho Nhân viên hỗ trợ
- Xem số liệu phân tích mặt hàng được tổng hợp trên toàn cầu

### 2.2.2 Chức năng cổng thông tin người thuê
- Quản lý danh sách người học: đăng ký hàng loạt, nhập CSV, thông tin đăng nhập được tạo tự động, xuất Excel
- Tạo và triển khai các buổi thi: lên lịch, thông báo, theo dõi trực tiếp, can thiệp
- Xem xét và xác nhận điểm Viết/Nói do AI tạo ra
- Truy cập phân tích: kết quả của từng học sinh, báo cáo lớp học, bảng thông tin KPI của trường, xuất báo cáo
- Quản lý người dùng Tenant và phân công nhiều vai trò

### 2.2.3 Chức năng máy khách kiểm tra
- Xác thực là sinh viên thuê nhà và tham gia một kỳ thi được chỉ định
- Hoàn thành mô phỏng APTIS đầy đủ trên tất cả bốn kỹ năng và mười sáu phần
- Tiếp tục từ câu trả lời đã lưu gần đây nhất sau khi ngắt kết nối mạng
- Xem kết quả cá nhân và phản hồi của giáo viên sau khi chấm điểm xong

### 2.2.4 Chức năng hệ thống xuyên suốt
- Thực thi tính toàn vẹn của bài kiểm tra: ngẫu nhiên câu hỏi/câu trả lời, chế độ kiosk, phát hiện và ghi nhật ký vi phạm
- Duy trì tính liên tục của bài kiểm tra: bộ đếm thời gian có thẩm quyền của máy chủ, tính duy trì cho mỗi câu trả lời, bộ đệm âm thanh cục bộ, khôi phục sự cố
- Thực thi quy trình chấm điểm AI không đồng bộ: Phiên âm STT → Điểm dự thảo LLM → hàng đợi đánh giá của giáo viên
- Gửi thông báo: email và tùy chọn đẩy trên tất cả các sự kiện kích hoạt được xác định

---

## 2.3 Đặc điểm người dùng

### Siêu quản trị viên (Nhà cung cấp)
Người dùng kỹ thuật cấp chuyên gia; quản lý toàn bộ nền tảng. Yêu cầu truy cập dữ liệu trực tiếp, hoạt động hàng loạt và khả năng quan sát đầy đủ. Chấp nhận các giao diện kiểu nhà phát triển cho các hoạt động hiếm khi được thực hiện.

### Trình quản lý nội dung (Nhà cung cấp)
Chuyên gia về lĩnh vực sư phạm APTIS; không phải là nhà phát triển. Hoạt động trong giao diện kiểu CMS văn bản đa dạng thức. Yêu cầu: xác thực biểu mẫu rõ ràng, xem trước âm thanh trước khi lưu, nhập hàng loạt có phản hồi lỗi. Tần suất nhiệm vụ cao trong các lần chạy nước rút của tác giả nội dung; thấp hơn ở trạng thái ổn định.

### Nhân viên hỗ trợ (Nhà cung cấp)
Trình độ kỹ thuật từ cơ bản đến trung cấp. Hoạt động từ bối cảnh phiếu hỗ trợ. Nhu cầu: tra cứu đối tượng thuê theo tên/sên, chế độ xem chỉ đọc dữ liệu của đối tượng thuê, đường dẫn leo thang có hướng dẫn tới Quản trị viên cấp cao. Không có quyền truy cập thao tác dữ liệu thô.

### Đội ngũ bán hàng (Nhà cung cấp)
Phi kỹ thuật. Hoạt động từ mô hình tư duy danh sách khách hàng tương tự như CRM. Nhu cầu: hình thức tạo giấy phép đơn giản, rõ ràng trạng thái khách hàng trong nháy mắt, gia hạn chỉ bằng một cú nhấp chuột. Không tương tác với bài kiểm tra hoặc dữ liệu học sinh.

### Quản trị viên thuê nhà (Trường/Trung tâm)
Nhân viên văn phòng hoặc điều phối viên CNTT tại trường học. Trình độ kỹ thuật từ cơ bản đến trung cấp; thoải mái với Google Biểu mẫu và Excel. Nhu cầu: quy trình nhập số lượng lớn có hướng dẫn, hiển thị trạng thái giấy phép rõ ràng, báo cáo toàn diện nhưng dễ đọc. Mối quan tâm chính: quản lý nhóm lớn sinh viên một cách hiệu quả.

### Giáo viên/Người hướng dẫn
Giáo viên đứng lớp; người dùng web cơ bản. Quen thuộc với Google Classroom hoặc tương tự. Nhu cầu: tạo phiên thi đơn giản, xếp hàng chấm điểm rõ ràng với bản nháp AI được điền sẵn, phân tích lớp học trực quan. Điểm yếu chính: ôn tập Viết/Nói nhanh mà không xem lại từng câu trả lời từ đầu.

### Điều phối viên thi
Quản lý phòng thi; trình độ kỹ thuật trung cấp. Chỉ hoạt động mạnh mẽ trong các buổi thi tích cực. Nhu cầu: bảng thông tin trạng thái theo thời gian thực mà không cần làm mới trang, kiểm soát can thiệp nhanh chóng cho mỗi học sinh, xóa nhật ký vi phạm.

### Chỉ người xem / báo cáo
Lãnh đạo trường phi kỹ thuật (hiệu trưởng, trưởng phòng). Xem bảng điều khiển tóm tắt và xuất. Nhu cầu: thẻ KPI sạch, báo cáo Excel/PDF có thể tải xuống. Không có sự tương tác hoạt động với hệ thống.

### Sinh viên (Đã đăng ký)
Nhân khẩu học hỗn hợp: học sinh trung học đến người lớn đang đi làm. Người dùng ứng dụng/web từ cơ bản đến trung cấp. Không quen với giao diện APTIS LMS nhưng quen với việc làm bài kiểm tra trực tuyến. Nhu cầu: không cần đào tạo làm quen thông qua hướng dẫn trong ứng dụng, hiển thị đồng hồ hẹn giờ rõ ràng, phản hồi trực quan để ghi/tải lên. Khả năng tiếp cận quan trọng: yêu cầu micrô hoạt động để Nói; yêu cầu đầu ra âm thanh để Nghe.

### Khách/Người dùng thử
Khách truy cập lần đầu không có tài khoản trước. Có thể bạn chưa biết APTIS là gì. Cần quyền truy cập dễ dàng — không cần đăng ký, không cần tải xuống. Bản dùng thử là một công cụ chuyển đổi tiếp thị giống như một bản trình diễn sản phẩm.

---

## 2.4 Hạn chế

### 2.4.1 Hạn chế về công nghệ
- **Nhiệm vụ của khung máy khách:** Flutter (Dart) cho tất cả các ứng dụng máy khách. Không cho phép khung giao diện người dùng thay thế (DC-01).
- **Mục tiêu nền tảng:** Do TechLead (OI-01) xác định. Giả định cơ bản: Flutter Web dành cho cổng quản trị viên; Flutter Desktop (Windows/macOS) + Flutter Web dành cho máy khách thi.
- **Nhiệm vụ lưu trữ:** Chỉ dành cho đám mây (AWS, GCP hoặc Azure). Không triển khai tại chỗ cho v1 (DC-08).
- **Quyền cách ly đối tượng thuê:** Tất cả dữ liệu đều nằm trong phạm vi `tenant_id` ở lớp ứng dụng và cơ sở dữ liệu (DC-02).
- **Yêu cầu HTTPS:** Không có điểm cuối HTTP không được mã hóa (DC-03).
- **Quyền đặt giờ:** Hẹn giờ thi do máy chủ quyết định; thao tác phía máy khách bị ngăn chặn về mặt kiến ​​trúc (DC-04).
- **Nhiệm vụ kiên trì:** Tính kiên trì phía máy chủ cho mỗi câu trả lời cho trạng thái bài kiểm tra (DC-05).
- **Nhiệm vụ AI:** Chỉ API của bên thứ ba; không có đào tạo mô hình ML tùy chỉnh (DC-06).

### 2.4.2 Ràng buộc kinh doanh
- Không xử lý thanh toán trong hệ thống; Sales quản lý hợp đồng bên ngoài (DC-07).
- Người thuê không thể tạo hoặc sửa đổi câu hỏi thi trong v1; tất cả nội dung đều do Nhà cung cấp quản lý (Giả định A-04).
- Hệ thống này không phải là trung tâm khảo thí APTIS chính thức; tuyên bố từ chối trách nhiệm phải được hiển thị trên tất cả các màn hình kết quả (DC-11, OR-LGL-01).

### 2.4.3 Ràng buộc quy định
- Tiếng Việt Nghị định 13/2023/ND-CP (Bảo vệ dữ liệu cá nhân): khả năng áp dụng và nghĩa vụ bắt buộc là TBD — Pháp lý để xác nhận (OI-07).
- PCI-DSS: Không áp dụng (không có dữ liệu thẻ thanh toán).
- HIPAA: Không áp dụng (không có dữ liệu về sức khỏe).

---

## 2.5 Giả định và sự phụ thuộc

| NHẬN DẠNG | Giả định | Rủi ro nếu sai |
|---|---|---|
| A-01 | Học sinh có một thiết bị tương thích với micrô hoạt động | Học sinh không thể hoàn thành phần Nói; giáo viên phải xử lý từng trường hợp một cách thủ công theo FR-110 |
| A-02 | Cấu trúc bài thi APTIS (kỹ năng, phần, dạng thức) ổn định trong suốt vòng đời sản phẩm v1 | Cần phải tái cấu trúc nội dung và giao diện người dùng chính nếu Hội đồng Anh thay đổi hình thức thi |
| A-03 | Người thuê nhà có giáo viên sẵn sàng đánh giá phần Viết/Nói trong phạm vi SLA có thể chấp nhận được | Tích lũy điểm tồn đọng; kết quả của học sinh bị trì hoãn vô thời hạn |
| A-04 | Tất cả nội dung ngân hàng câu hỏi được tạo và duy trì bởi Người quản lý nội dung của nhà cung cấp | Câu hỏi về chất lượng sư phạm hoàn toàn là trách nhiệm của Nhà cung cấp |
| A-05 | Mạng tại các địa điểm thi đủ ổn định để tải lên âm thanh trong cửa sổ phiên | Các tính năng liên tục của F-13 giảm thiểu tình trạng mất kết nối trong thời gian ngắn nhưng không thể xử lý tình trạng mất kết nối liên tục |
| A-06 | Việc thanh toán giữa Bên bán và Bên thuê được quản lý hoàn toàn bên ngoài hệ thống | Không cần theo dõi trạng thái thanh toán trong nền tảng |
| A-07 | Một tên miền phụ ánh xạ chính xác tới một đối tượng thuê (không chia sẻ tên miền phụ) | Kiến trúc định tuyến của đối tượng thuê sẽ yêu cầu thiết kế lại |
| A-08 | Người quản lý nội dung có chuyên môn sư phạm APTIS để tạo ra các câu hỏi hợp lệ | Hệ thống xác nhận cấu trúc nhưng không xác nhận tính đúng đắn về mặt sư phạm |
| A-09 | Sự đồng ý ghi âm được quy định trong hợp đồng Nhà cung cấp-Người thuê nhà và các điều khoản đăng ký của Người thuê nhà | Không cần có luồng chấp thuận trong ứng dụng cho âm thanh; nếu sai thì phải thêm FR đồng ý |
| A-10 | Bảng ánh xạ băng tần (điểm thô → băng tần APTIS) do Nhà cung cấp cung cấp và được định cấu hình tĩnh | Độ chính xác của việc chấm điểm phụ thuộc hoàn toàn vào tính chính xác của bảng do Nhà cung cấp cung cấp |

---

## 2.6 Phân bổ các yêu cầu

Các yêu cầu sau đây được bao gồm trong SRS này nhưng được chuyển sang phiên bản 1.5 một cách rõ ràng nếu các ràng buộc về dòng thời gian hoặc nguồn lực yêu cầu giảm phạm vi. Chúng có thể bị cắt khỏi v1 mà không ảnh hưởng đến khả năng thực hiện bài kiểm tra cốt lõi.

| Yêu cầu hoãn lại | Trì hoãn đến | Điều kiện để cắt |
|---|---|---|
| F-11: Luồng khách/dùng thử (FR-88–FR-92) | v1.5 | Sản phẩm cốt lõi hoạt động không cần dùng thử; chỉ có tác động tiếp thị |
| Flutter Mobile (iOS/Android) dành cho máy khách thi | v1.5 | Flutter Web + Desktop đủ dùng cho phòng thi |
| Thông báo đẩy (FR-84) | v1.5 | Yêu cầu khách hàng di động; thông báo qua email bìa v1 |
| Xuất báo cáo PDF (FR-66 — phần PDF) | v1.5 | Xuất Excel đủ cho v1 |
| Mạo danh nhân viên hỗ trợ (FR-76) | v1.5 | Quản trị viên cấp cao có thể trực tiếp xử lý việc hỗ trợ người thuê khẩn cấp |
| Tuân thủ đầy đủ ND 13/2023 (nếu có) | v1.5 | Đang chờ quyết định pháp lý (OI-07) |