# SRS §3.6 — Thuộc tính hệ thống
## APTIS LMS
**Phiên bản:** 1.0 | **Ngày:** 2026-06-16 | **Trạng thái:** BẢN THẢO

---

Thuộc tính hệ thống mô tả các thuộc tính chất lượng mà hệ thống phải thể hiện ngoài tính đúng đắn về chức năng. Họ xác định cách hệ thống hoạt động khi bị căng thẳng, thất bại, bị tấn công và thay đổi theo thời gian.

---

## 3.6.1 Độ tin cậy

**SA-REL-01: Tính toàn vẹn dữ liệu của phiên thi**

Hệ thống không làm mất bất kỳ đáp án bài thi nào của học sinh đã được máy chủ xác nhận (HTTP 200 được trả về cho máy khách). Đây là yêu cầu về độ tin cậy số 1 của toàn bộ hệ thống.

Thuộc tính này đạt được thông qua hoạt động tổng hợp của cụm F-13 (FR-104 đến FR-111): tính bền vững phía máy chủ cho mỗi câu trả lời (FR-105), bộ đếm thời gian do máy chủ xác thực (FR-104), bộ đệm cục bộ âm thanh nói với thử lại (FR-108), tiếp tục kết nối lại (FR-106) và khôi phục sự cố (FR-111). Không một thành phần nào bị lỗi sẽ khiến học sinh mất đi các câu trả lời đã nộp.

**Chấp nhận:** Kiểm tra sau phiên cho thấy không có trường hợp nào cố gắng trong đó số lượng bản ghi `exam_answers` nhỏ hơn số câu trả lời mà khách hàng của học sinh đã báo cáo đã gửi.

---

**SA-REL-02: Dung sai lỗi đường ống tính điểm AI**

Quy trình tính điểm AI (bản ghi STT FR-30 + tính điểm dự thảo LLM FR-31) phải có khả năng chịu lỗi đối với các lỗi API của bên thứ ba. Lệnh gọi API AI không thành công sẽ không tạo ra điểm số không chính xác, làm hỏng bản ghi lần thử hoặc chặn quy trình cho các lần thử khác.

Hành vi khi thất bại:
- Lỗi STT: thử lại tối đa 3 lần với thời gian chờ theo cấp số nhân; khi lỗi vĩnh viễn, đặt `stt_status = failed` và cảnh báo Giáo viên
- Lỗi LLM: hành vi thử lại và gắn cờ tương tự; đặt `llm_status = thất bại`
- Bất kỳ kết quả lỗi AI nào: hàng đợi đánh giá của Giáo viên hiển thị rõ ràng lỗi; Giáo viên trực tiếp xem xét âm thanh hoặc văn bản thô

Quy trình phải xử lý từng lần thử một cách độc lập; việc thất bại của một học sinh không được làm trì hoãn hoặc cản trở việc chấm điểm của các học sinh khác.

---

**SA-REL-03: Hệ thống thông báo không chặn**

Hệ thống con thông báo (F-10) sẽ hoạt động độc lập với việc gửi bài kiểm tra. Lỗi của nhà cung cấp email (SI-02) hoặc công việc thông báo tồn đọng không được ảnh hưởng đến khả năng phản hồi của việc ghi trạng thái bài kiểm tra (FR-105) hoặc màn hình trực tiếp (FR-39).

Thông báo không thành công được thử lại sau 5 phút (FR-83) rồi ghi lại là không thành công. Lỗi thông báo hàng loạt không được xếp tầng; các lỗi gửi riêng lẻ sẽ bị cô lập.

---

**SA-REL-04: Không có điểm sai sót nào trong giờ thi**

Đường dẫn phân phối bài kiểm tra (API phụ trợ + cơ sở dữ liệu + máy chủ WebSocket/SSE) không được thiết kế có một điểm lỗi duy nhất. Trong bất kỳ phiên kiểm tra đang hoạt động nào, phải có ít nhất một bản sao của mỗi thành phần để phục vụ các yêu cầu.

Những cân nhắc thiết kế bắt buộc (sẽ được TechLead xác nhận trong phiên kiến trúc):
- Cơ sở dữ liệu: đọc bản sao + chuyển đổi dự phòng tự động cho chính
- API phụ trợ: tối thiểu 2 phiên bản phía sau bộ cân bằng tải
- Máy chủ WebSocket: mối quan hệ phiên hoặc trạng thái phiên chia sẻ (Redis) để tồn tại khi phiên bản bị lỗi
- Kiểm tra tình trạng: cân bằng tải loại bỏ các trường hợp không lành mạnh trong vòng 30 giây

---

## 3.6.2 Sẵn có

**SA-AVL-01: Mục tiêu sẵn có trong giờ thi**

Hệ thống phải đạt được độ sẵn sàng ≥ 99,9% trong bất kỳ khoảng thời gian nào có ít nhất một phiên thi đang diễn ra (NFR-03). Điều này có nghĩa là thời gian ngừng hoạt động trong mỗi buổi thi là 43 giây.

Việc bảo trì theo kế hoạch phải được lên lịch ngoài giờ thi. Nếu cần triển khai khẩn cấp trong phiên hoạt động, TechLead phải ủy quyền cho việc triển khai đó khi nhận thức đầy đủ về rủi ro liên tục của kỳ thi.

---

**SA-AVL-02: Sự xuống cấp nhẹ nhàng đối với các dịch vụ không quan trọng**

Nếu bất kỳ dịch vụ không quan trọng nào sau đây không khả dụng thì dịch vụ phân phối bài kiểm tra cốt lõi phải tiếp tục hoạt động mà không bị gián đoạn:
- Dịch vụ thông báo qua Email (SI-02): tiếp tục phát bài thi; email được xếp hàng đợi và gửi khi khôi phục
- Quy trình chấm điểm AI (SI-04, SI-05): tiếp tục phát bài thi; tính điểm được xếp hàng đợi và xử lý khi khôi phục
- Truy vấn báo cáo phân tích: tiếp tục phân phối bài kiểm tra; số liệu phân tích đã cũ nhưng vẫn khả dụng sau khi dịch vụ báo cáo phục hồi
- Tính năng Mạo danh / Hỗ trợ Nhân viên: việc không có mặt không ảnh hưởng đến quy trình làm bài thi của học sinh hoặc giáo viên

Việc phân phối bài kiểm tra cốt lõi (FR-17 đến FR-26, FR-104 đến FR-111) phải được tách biệt về mặt kiến trúc khỏi hoạt động phân tích, chấm điểm AI và xử lý thông báo.

---

**SA-AVL-03: Giao tiếp cửa sổ bảo trì**

Khoảng thời gian bảo trì theo kế hoạch phải được thông báo cho tất cả Quản trị viên đối tượng thuê qua email ít nhất 48 giờ trước khi bắt đầu bảo trì. Không được đặt lịch bảo trì trong giờ thi cao điểm.

Giờ thi cao điểm được xác định là `07:00–22:00 Giờ chuẩn Việt Nam (UTC+7)` vào các ngày học [có thể điều chỉnh OI-05 bởi Hoạt động của nhà cung cấp]. Cửa sổ bảo trì mặc định là `02:00–06:00 VNT`.

---

## 3.6.3 Bảo mật

**SA-SEC-01: Xác thực trên tất cả các điểm cuối được bảo vệ**

Mọi điểm cuối API ngoại trừ trang đích dùng thử công khai (FR-88), thông tin đăng nhập (FR-01), quên mật khẩu (FR-05) và làm mới mã thông báo (FR-02) đều phải yêu cầu mã thông báo truy cập JWT hợp lệ trong tiêu đề `Authorization: Bearer {token}`. Yêu cầu không có mã thông báo hợp lệ sẽ trả về HTTP 401. Yêu cầu có mã thông báo hợp lệ nhưng không đủ quyền sẽ trả về HTTP 403.

Xác thực mã thông báo xảy ra trên mọi yêu cầu. Các quyết định về quyền không được lưu vào bộ nhớ đệm ngoài TTL của chính mã thông báo (15 phút, NFR-13).

---

**SA-SEC-02: Cách ly dữ liệu của người thuê**

Không người dùng nào có thể đọc hoặc ghi dữ liệu của người thuê khác trong bất kỳ trường hợp nào. Việc cách ly đối tượng thuê được thực thi ở hai lớp:
1. **Lớp ứng dụng:** Mọi truy vấn cơ sở dữ liệu được tạo bởi API phụ trợ bao gồm `WHERErent_id = {resolved_id}` (được giải quyết từ tên miền phụ yêu cầu, FR-03)
2. **Lớp cơ sở dữ liệu:** Chính sách bảo mật cấp hàng (RLS) hoặc biện pháp thực thi cấp cơ sở dữ liệu tương đương như một biện pháp bảo vệ chuyên sâu

Rò rỉ dữ liệu giữa nhiều đối tượng thuê (bất kỳ phản hồi nào trả về dữ liệu từ không gian tên của đối tượng thuê khác) được phân loại là lỗi bảo mật nghiêm trọng và cần phải khắc phục ngay lập tức.

---

**SA-SEC-03: Ủy quyền vai trò phía máy chủ**

Mọi điểm cuối API phải khai báo (các) vai trò bắt buộc tối thiểu để có quyền truy cập. Việc ủy ​​quyền được thực thi phía máy chủ bởi phần mềm trung gian cuối cùng. Kiểm soát truy cập phía máy khách (ẩn các nút hoặc tuyến đường trong Flutter) chỉ là một cải tiến UX và không phải là kiểm soát bảo mật.

Việc ủy ​​quyền vai trò phải sử dụng sự kết hợp của tất cả các vai trò đang hoạt động cho người dùng yêu cầu (DC-09). Người dùng có vai trò Giáo viên + Điều phối viên bài kiểm tra có thể gọi bất kỳ điểm cuối nào được một trong hai vai trò cho phép.

---

**SA-SEC-04: Xác thực đầu vào và ngăn chặn tiêm**

Tất cả thông tin đầu vào do người dùng cung cấp phải được xác thực phía máy chủ trước khi được sử dụng trong bất kỳ hoạt động nào. Các quy tắc sau đây được áp dụng mà không có ngoại lệ:
- **Chèn SQL:** Chỉ các truy vấn được tham số hóa hoặc xây dựng truy vấn cấp ORM; không có nội suy chuỗi trong truy vấn cơ sở dữ liệu
- **Ngăn chặn XSS:** Nội dung HTML từ dữ liệu đầu vào của người dùng (nội dung câu hỏi, tường thuật phản hồi, nội dung email) phải được khử trùng bằng trình khử trùng dựa trên danh sách cho phép (các thẻ được phép: `<b>`, `<i>`, `<p>`, `<br>`, `<ul>`, `<li>`) trước khi hiển thị; không có HTML người dùng thô nào được hiển thị không được dọn dẹp
- **Chuyển nhượng hàng loạt:** Điểm cuối API phải đưa các trường yêu cầu được phép vào danh sách trắng; các trường bổ sung phải được bỏ qua, không được áp dụng
- **Xác thực tải lên tệp:** Cả loại MIME và phần mở rộng tệp đều phải được xác thực phía máy chủ (không chỉ phía máy khách); tập tin phải được quét trước khi lưu trữ

---

**SA-SEC-05: Bảo vệ dữ liệu khi vận chuyển và lưu trữ**

- **Đang truyền:** HTTPS (tối thiểu TLS 1.2, ưu tiên TLS 1.3) cho tất cả giao tiếp (DC-03); không cho phép kết nối HTTP văn bản gốc
- **Ở trạng thái nghỉ:** Mã hóa cơ sở dữ liệu được kích hoạt thông qua mã hóa do nhà cung cấp quản lý (ví dụ: mã hóa AWS RDS); Các đối tượng trong Cloud Storage được mã hóa ở trạng thái lưu trữ bằng khóa do nhà cung cấp quản lý
- **Bản ghi âm:** Tệp âm thanh giọng nói là đối tượng riêng tư trong Cloud Storage; quyền truy cập công cộng bị vô hiệu hóa; quyền truy cập yêu cầu URL hoặc proxy máy chủ được chỉ định có giới hạn thời gian
- **Nhật ký ứng dụng:** Không có PII (tên sinh viên, địa chỉ email, câu trả lời bài kiểm tra) hoặc thông tin đăng nhập xuất hiện trong đầu ra nhật ký; các trường mật khẩu bị loại bỏ bằng cách ghi lại phần mềm trung gian trước khi viết

---

**SA-SEC-06: Tính toàn vẹn của bài kiểm tra là hệ thống con bảo mật**

Hệ thống chống gian lận (F-12, FR-93–FR-103) được phân loại là hệ thống con bảo mật. Các điều khiển của nó phải được triển khai phía máy chủ nếu có thể:
- Ngăn chặn thao tác hẹn giờ về mặt cấu trúc (DC-04); hiển thị hẹn giờ phía máy khách ở chế độ chỉ đọc
- Các sự kiện vi phạm là bất biến ở cấp độ ứng dụng (DC-10); không có vai trò người dùng nào có thể xóa hoặc sửa đổi chúng
- Hạt giống xáo trộn câu hỏi/câu trả lời được tạo ở phía máy chủ và được lưu trữ ở phía máy chủ; khách hàng không thể tác động đến việc xáo trộn

---

**SA-SEC-07: Bảo mật xuất thông tin xác thực**

Xuất thông tin xác thực hàng loạt (FR-48) chỉ hiển thị mật khẩu văn bản gốc cho các tài khoản mới tạo trong khoảng thời gian 24 giờ. Sau cửa sổ này, mật khẩu không thể truy xuất được dưới bất kỳ hình thức nào (băm bcrypt trong cơ sở dữ liệu không thể đảo ngược). Đây là do thiết kế.

Tệp xuất phải được cung cấp qua HTTPS. Phần cuối không được ghi lại mật khẩu văn bản gốc tại bất kỳ thời điểm nào trong quá trình tạo hoặc truyền.

---

**SA-SEC-08: Giới hạn tỷ lệ**

Các danh mục điểm cuối sau đây phải triển khai giới hạn tốc độ để ngăn chặn hành vi bạo lực và lạm dụng:
- Điểm cuối đăng nhập (FR-01): 10 yêu cầu mỗi phút cho mỗi địa chỉ IP (CI-01)
- Quên mật khẩu điểm cuối (FR-05): 5 yêu cầu mỗi phút cho mỗi địa chỉ IP
- Điểm cuối ghi trạng thái bài kiểm tra (FR-105): 120 yêu cầu mỗi phút cho mỗi `attempt_id` (CI-01)
- Điểm cuối làm mới mã thông báo (FR-02): 30 yêu cầu mỗi phút cho mỗi người dùng

Các yêu cầu vượt quá giới hạn tốc độ sẽ nhận được HTTP 429 với tiêu đề `Thử lại sau` cho biết thời điểm đặt lại khoảng thời gian tốc độ.

---

## 3.6.4 Khả năng bảo trì

**SA-MNT-01: Giới thiệu người thuê không mã**

Việc thêm đối tượng thuê mới vào hệ thống chỉ yêu cầu: (1) tạo bản ghi đối tượng thuê trong Cổng thông tin nhà cung cấp (FR-71), (2) xác minh định tuyến DNS ký tự đại diện (ký tự đại diện CNAME tự động xử lý tất cả các phần mở rộng mới) và (3) tạo giấy phép (FR-73). Không cần triển khai mã, thay đổi tệp cấu hình hoặc cung cấp cơ sở hạ tầng cho mỗi đối tượng thuê mới.

---

**SA-MNT-02: Khả năng định cấu hình của nhà cung cấp AI mà không cần thay đổi mã**

Quy trình chấm điểm AI phải có thể định cấu hình để chuyển đổi giữa nhà cung cấp STT và nhà cung cấp LLM thông qua thay đổi cấu hình hệ thống, không thay đổi mã và không triển khai lại. Quy trình đọc `ai_config.stt_provider` và `ai_config.llm_provider` từ bảng cấu hình hệ thống tại thời điểm thực hiện công việc (yêu cầu chuyển đổi nhà cung cấp FR-31, SI-05).

---

**SA-MNT-03: Khả năng chỉnh sửa mẫu email thông qua giao diện người dùng quản trị**

Tất cả các mẫu thông báo qua email phải được Quản trị viên cấp cao chỉnh sửa thông qua Cổng thông tin nhà cung cấp (FR-85) mà không cần triển khai mã. Việc thêm hỗ trợ cho loại trình kích hoạt thông báo mới yêu cầu thay đổi mã (để thêm sự kiện kích hoạt), nhưng việc chỉnh sửa các mẫu hiện có chỉ yêu cầu Giao diện người dùng quản trị.

---

**SA-MNT-04: Cờ tính năng cho các tính năng có điều kiện**

Các tính năng sau phải được kiểm soát thông qua cờ tính năng cấp hệ thống mà không cần triển khai mã:
- Luồng khách/dùng thử (F-11, FR-88–FR-92): bật/tắt trên toàn cầu
- Thông báo đẩy Flutter Mobile (FR-84): bật/tắt trên toàn cầu
- Xuất PDF (FR-66, Có điều kiện): bật/tắt cho mỗi người thuê hoặc trên toàn cầu

Cờ tính năng được lưu trữ trong bảng cấu hình hệ thống có thể được Quản trị viên cấp cao chỉnh sửa. Việc tắt một tính năng phải ẩn hoặc tắt một cách khéo léo tất cả các điều khiển giao diện người dùng và điểm cuối API có liên quan (không gặp sự cố).

---

**SA-MNT-05: Ghi nhật ký có cấu trúc**

Tất cả các mục nhật ký ứng dụng phải ở định dạng JSON có cấu trúc với các trường được tiêu chuẩn hóa:



```json
{
  "timestamp": "ISO8601",
  "level": "INFO|WARN|ERROR",
  "request_id": "UUID",
  "tenant_id": "UUID or null",
  "user_id": "UUID or null",
  "event_type": "string",
  "message": "string",
  "metadata": {}
}
```



Không có PII nào có thể xuất hiện trong đầu ra nhật ký. Nhật ký phải có thể truy vấn được bằng `tenant_id`, `user_id`, `event_type` và `request_id` để gỡ lỗi và điều tra sự cố.

---

## 3.6.5 Tính di động

**SA-PRT-01: Mẫu bộ điều hợp nền tảng Flutter**

Cơ sở mã Flutter phải tách mã dành riêng cho nền tảng khỏi logic nghiệp vụ được chia sẻ bằng cách sử dụng mẫu bộ điều hợp. Việc triển khai dành riêng cho nền tảng (truy cập micrô, quản lý cửa sổ kiosk, hệ thống tệp cục bộ, kiểm soát toàn màn hình) phải được gói gọn trong các lớp bộ điều hợp dành riêng cho nền tảng. Công cụ thi được chia sẻ phải gọi trực tiếp các giao diện bộ điều hợp chứ không phải SDK nền tảng.

Điều này đảm bảo rằng việc thêm hỗ trợ cho nền tảng mới (ví dụ: Flutter Mobile được thêm vào phiên bản 1.5) chỉ yêu cầu triển khai lớp bộ điều hợp chứ không phải viết lại logic bài kiểm tra.

---

**SA-PRT-02: Tính trừu tượng của nhà cung cấp đám mây**

API phụ trợ phải xác định giao diện dịch vụ cho tất cả các dịch vụ dành riêng cho nhà cung cấp đám mây:
- `StorageService` (giao diện cho các hoạt động đối tượng S3/GCS)
- `QueueService` (giao diện cho hàng đợi công việc — SQS/Pub-Sub/tương đương)
- `EmailService` (giao diện cho API SendGrid/SES)

Logic miền phải gọi các giao diện này; SDK của nhà cung cấp chỉ được sử dụng khi triển khai bộ chuyển đổi cụ thể. Việc di chuyển từ nhà cung cấp đám mây này sang nhà cung cấp đám mây khác yêu cầu thay đổi cách triển khai bộ điều hợp chứ không phải logic miền.

---

**SA-PRT-03: Khả năng di chuyển của lược đồ cơ sở dữ liệu**

Lớp truy cập dữ liệu phải sử dụng các truy vấn được tham số hóa hoặc ORM nhắm mục tiêu SQL tiêu chuẩn mà không cần tiện ích mở rộng dành riêng cho nhà cung cấp bất cứ khi nào có thể. Các tính năng dành riêng cho PostgreSQL (ví dụ: loại gốc `JSONB`, `UUID`) có thể được sử dụng khi chúng mang lại lợi ích đáng kể, nhưng lớp trừu tượng ORM phải ghi lại mọi giả định về tính di động.

---

## 3.6.6 Khả năng sử dụng

**SA-USA-01: Quy trình thi không cần đào tạo dành cho sinh viên**

Học sinh phải có khả năng hoàn thành toàn bộ quy trình thi — đăng nhập → Bài kiểm tra của tôi → kiểm tra trước kỳ thi → phần thi → kết quả — mà không cần đào tạo bên ngoài, chỉ sử dụng màn hình hướng dẫn trong ứng dụng do hệ thống cung cấp. Tất cả các hướng dẫn phải bằng tiếng Việt là ngôn ngữ chính với tùy chọn ngôn ngữ tiếng Anh.

Tiêu chí đánh giá: một học sinh chưa từng sử dụng nền tảng này trước đây có thể hoàn thành bài kiểm tra trong phiên kiểm soát khả năng sử dụng mà không cần yêu cầu giám thị trợ giúp.

---

**SA-USA-02: Giao diện thi quen thuộc của APTIS**

Giao diện người dùng của ứng dụng kỳ thi (UI-09) phải khớp với bố cục trực quan và các thành ngữ tương tác của kỳ thi trực tuyến APTIS thực tế ở mức khả thi nhất về mặt kỹ thuật. Mục đích là để giảm bớt chi phí nhận thức cho những học sinh đã tham gia hoặc luyện tập cho kỳ thi APTIS chính thức. Những sai lệch so với quy ước giao diện APTIS phải được ghi lại và chứng minh.

---

**SA-USA-03: Thông báo lỗi có thể xử lý**

Mọi thông báo lỗi được hiển thị cho bất kỳ người dùng nào đều phải bao gồm ba yếu tố: (1) điều gì đã xảy ra, (2) tại sao nó xảy ra (trong phạm vi an toàn có thể tiết lộ mà không làm rò rỉ nội bộ hệ thống) và (3) người dùng nên làm gì tiếp theo. Các thông báo chung chung như "Đã xảy ra lỗi" hoặc "Đã xảy ra lỗi" mà không có hướng dẫn đều không được chấp nhận.

Ví dụ về các thông báo lỗi được chấp nhận:
- "Phiên của bạn đã hết hạn. Vui lòng đăng nhập lại để tiếp tục."
- "Đã đạt hạn ngạch chỗ ngồi (200 trên 200 chỗ đã sử dụng). Vui lòng liên hệ với người quản lý tài khoản của bạn để thêm chỗ."
- "Định dạng tệp âm thanh không được hỗ trợ. Các định dạng được chấp nhận: MP3, WAV."

---

**SA-USA-04: Tiến độ hoạt động hàng loạt và phản hồi kết quả**

Tất cả các hoạt động hàng loạt — nhập CSV (FR-47), tạo tài khoản hàng loạt, thông báo hàng loạt — phải hiển thị chỉ báo tiến trình trong khi hoạt động đang chạy và tóm tắt kết quả khi hoàn thành. Bản tóm tắt phải bao gồm: số bản ghi được xử lý thành công, số bản ghi không thành công hoặc bị bỏ qua và mô tả lỗi trên mỗi bản ghi cho bất kỳ lỗi nào. Người dùng không được chờ đợi một cách mù quáng mà không có phản hồi đối với các thao tác có thể mất hơn 2 giây.

---

**SA-USA-05: Độ rộng màn hình tối thiểu cho cổng quản trị**

Chế độ xem Flutter Web cho Cổng thông tin nhà cung cấp và Cổng thông tin người thuê phải hoạt động tốt và được hiển thị chính xác trên màn hình có chiều rộng tối thiểu là 1024 pixel. Bố cục đáp ứng di động cho cổng quản trị không bắt buộc trong v1. Ứng dụng kiểm tra là bề mặt chính dành cho thiết bị di động và xử lý các màn hình nhỏ hơn.

---

**SA-USA-06: Yêu cầu cập nhật theo thời gian thực của màn hình trực tiếp**

Bảng điều khiển giám sát trực tiếp Điều phối viên bài kiểm tra (FR-39) phải cập nhật trạng thái học sinh mà không yêu cầu làm mới trang thủ công. Dữ liệu cũ trên màn hình điều khiển trong phiên thi đang diễn ra là lỗi khả năng sử dụng, có thể khiến điều phối viên bỏ sót các vấn đề của học sinh (ngắt kết nối, vi phạm) và trì hoãn can thiệp.

Các bản cập nhật phải đến thông qua WebSocket push (chính) hoặc SSE (dự phòng) trong vòng 5 giây kể từ khi sự kiện cơ bản xảy ra ở phía học sinh.