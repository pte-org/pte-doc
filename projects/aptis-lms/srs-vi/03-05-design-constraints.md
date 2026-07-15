# SRS §3.5 — Ràng buộc về thiết kế
## APTIS LMS
**Phiên bản:** 1.0 | **Ngày:** 2026-06-16 | **Trạng thái:** BẢN THẢO

---

Ràng buộc thiết kế là những hạn chế không thể thương lượng về cách hệ thống phải được thiết kế và xây dựng. Chúng được áp đặt bởi các nhiệm vụ công nghệ, yêu cầu bảo mật, nghĩa vụ pháp lý hoặc quyết định của các bên liên quan — không phải bởi các ưu tiên về tính năng. Vi phạm ràng buộc thiết kế không phải là một sự đánh đổi; đó là việc thực hiện không tuân thủ.

---

### DC-01: Flutter như khung máy khách bắt buộc

**Được sửa đổi bởi ADR-006 (23-06-2026, `projects/aptis-mvp/team/techlead/ADR-006.md`):** ràng buộc này hiện áp dụng cho **Chỉ ứng dụng khách thi**. Cổng thông tin nhà cung cấp và Cổng thông tin đối tượng thuê được xây dựng trong Next.js (React), không phải Flutter. Đọc ADR-006 trước khi triển khai bất kỳ giao diện người dùng cổng thông tin nào.

Hệ thống sẽ triển khai tất cả các ứng dụng hướng tới khách hàng — Cổng thông tin nhà cung cấp, Cổng thông tin đối tượng thuê và Ứng dụng khách kiểm tra — độc quyền trong Flutter (Dart). Không có khung giao diện người dùng thay thế nào (React, Vue, Angular, v.v.) được phép cho bất kỳ thành phần giao diện người dùng máy khách nào.

**Áp đặt bởi:** Nhiệm vụ của bên liên quan — mục tiêu triển khai đa nền tảng (Web, Máy tính để bàn, Thiết bị di động từ một cơ sở mã duy nhất).

**Ý nghĩa thực hiện:**
- API phụ trợ phải là API REST và WebSocket thuần túy; không có HTML kết xuất từ máy chủ nào được tạo ra
- Tất cả các thành phần UI, logic điều hướng và quy tắc công việc phía máy khách phải được viết bằng Dart
- Hành vi dành riêng cho nền tảng (chế độ kiosk, API micrô, kiểm soát toàn màn hình, hệ thống tệp cục bộ) phải được triển khai thông qua các kênh nền tảng Flutter hoặc các gói Flutter đã được phê duyệt, với bộ điều hợp dành riêng cho nền tảng được tách biệt khỏi logic nghiệp vụ chung (SA-PRT-01)
- Tất cả các gói Flutter đã chọn phải được đánh giá về khả năng tương thích với từng nền tảng mục tiêu (gói hỗ trợ Flutter Web có thể không hỗ trợ Flutter Desktop hoặc Mobile); các gói không tương thích yêu cầu các lựa chọn thay thế có điều kiện nền tảng

---

### DC-02: Kiến trúc tên miền phụ nhiều bên thuê

Hệ thống sẽ thực hiện cách ly đối tượng thuê thông qua định tuyến tên miền phụ. Mỗi người thuê được gán một tên miền phụ duy nhất `{slug}.aptis-lms.vn`. Cổng API phải phân giải `tenant_id` từ miền phụ tiêu đề `Host` trên mọi yêu cầu đến và đặt phạm vi tất cả các hoạt động dữ liệu vào không gian tên của đối tượng thuê đó. Truy cập dữ liệu của nhiều người thuê bị cấm về mặt cấu trúc.

**Áp đặt bởi:** Nhiệm vụ của bên liên quan - các yêu cầu về cách ly người thuê và xây dựng thương hiệu.

**Ý nghĩa thực hiện:**
- Cần có chứng chỉ SSL ký tự đại diện bao gồm `*.aptis-lms.vn` và `aptis-lms.vn`
- DNS phải được cấu hình với ký tự đại diện CNAME trỏ `*.aptis-lms.vn` tới bộ cân bằng tải
- Phần mềm trung gian cổng API giải quyết `slug →rent_id` trên mọi yêu cầu trước khi định tuyến tới bất kỳ trình xử lý nào; không trình xử lý nào có thể bỏ qua độ phân giải này
- Mọi truy vấn cơ sở dữ liệu phải bao gồm ràng buộc `WHERErent_id = {resolved_id}` (hoặc mức độ bảo mật tương đương ở cấp hàng); bất kỳ truy vấn nào bỏ qua phạm vi đối tượng thuê đều là lỗi bảo mật nghiêm trọng
- Cổng thông tin nhà cung cấp hoạt động trên `admin.aptis-lms.vn` không có phạm vi đối tượng thuê; trình xử lý của nó không được chấp nhận `tenant_id` từ ngữ cảnh yêu cầu

---

### DC-03: Giao tiếp chỉ dùng HTTPS

Hệ thống sẽ không hiển thị hoặc sử dụng bất kỳ điểm cuối HTTP nào không được mã hóa. Tất cả các giao tiếp từ máy khách đến máy chủ, cuộc gọi từ máy chủ đến dịch vụ bên ngoài (SI-01 đến SI-06) và phân phối CDN phải sử dụng HTTPS với TLS 1.2 làm phiên bản giao thức tối thiểu và ưu tiên TLS 1.3.

**Áp đặt bởi:** Đường cơ sở bảo mật.

**Ý nghĩa thực hiện:**
- Các yêu cầu HTTP tới nền tảng được chuyển hướng vĩnh viễn (HTTP 301) sang HTTPS tương đương
- URL phân phối CDN âm thanh và hình ảnh sử dụng HTTPS; không cho phép cảnh báo nội dung hỗn hợp trong Flutter Web
- URL được chỉ định cho Cloud Storage (SI-01) là URL HTTPS
- Cấu hình chứng chỉ TLS phải thực thi phiên bản tối thiểu và vô hiệu hóa bộ mật mã không được dùng nữa

---

### DC-04: Bộ đếm thời gian kiểm tra được ủy quyền của máy chủ

Bộ tính giờ của phần thi phải được tính toán và lưu trữ riêng trên máy chủ. Máy khách hiển thị đồng hồ đếm ngược bắt nguồn từ các giá trị do máy chủ cung cấp. Máy khách không thể mở rộng, đặt lại, tạm dừng hoặc thao tác bộ hẹn giờ phía máy chủ trong bất kỳ trường hợp nào.

**Được áp đặt bởi:** Yêu cầu về tính toàn vẹn của bài kiểm tra — ngăn chặn thao tác tính giờ phía máy khách.

**Ý nghĩa thực hiện:**
- Điểm cuối API đồng bộ hóa bộ hẹn giờ trả về `time_remaining` được tính là `part_duration_seconds +extend_by_seconds − (CURRENT_TIMESTAMP − part_timers.started_at)`
- Máy khách thăm dò điểm cuối này ≤ 10 giây một lần (hoặc nhận server-push qua WebSocket); Đếm ngược phía máy khách là nội suy trực quan giữa các lần đồng bộ hóa, không phải giá trị xác thực
- Khi máy chủ xác định `time_remaining ≤ 0`, máy chủ sẽ đóng phần đó và đặt `part_timers.completed_at`; trạng thái khách hàng không liên quan đến quá trình chuyển đổi này
- Bất kỳ câu trả lời nào được gửi cho phần đã đóng đều trả về Xung đột HTTP 409 bất kể khách hàng hiển thị nội dung gì
- Phần cuối không bao giờ được sử dụng dấu thời gian do khách hàng cung cấp để tính toán bộ đếm thời gian

---

### DC-05: Tính bền vững phía máy chủ cho mỗi câu trả lời

Mỗi câu trả lời của học sinh phải được ghi vào cơ sở dữ liệu máy chủ và được xác nhận trước khi được coi là đã lưu. Không có việc truyền tải hàng loạt bị trì hoãn khi kết thúc kỳ thi. Điểm cuối gửi bài kiểm tra chỉ hoàn thiện siêu dữ liệu; nó không chuyển dữ liệu câu trả lời của học sinh.

**Áp đặt bởi:** Nhiệm vụ liên tục của kỳ thi — ưu tiên số 1 của các bên liên quan (NFR-14).

**Ý nghĩa thực hiện:**
- Điểm cuối ghi trạng thái bài kiểm tra (`PATCH /api/v1/exam/attempts/{id}/answers`) phải hỗ trợ các hoạt động nâng cấp tần suất cao; bảng `exam_state` sử dụng `(attempt_id, question_id)` làm khóa nâng cấp tổng hợp
- Thông lượng ghi cơ sở dữ liệu cho `exam_state` là mối quan tâm mở rộng quan trọng (NFR-06); bộ đệm ghi hoặc phân nhóm với ngữ nghĩa xác nhận có thể được yêu cầu ở quy mô lớn
- Điểm cuối gửi bài kiểm tra (`POST /api/v1/exam/attempts/{id}/submit`) đặt `attempt.status = submit` và kích hoạt quy trình chấm điểm; nó không chấp nhận dữ liệu câu trả lời trong phần thân yêu cầu
- Máy khách phải xử lý lỗi ghi bằng logic thử lại (tối đa 3 lần thử lại, FR-105) và đệm các câu trả lời chưa được xác nhận trong bộ nhớ

---

### DC-06: Chấm điểm AI chỉ qua API của bên thứ ba

Việc đánh giá các câu trả lời Viết và Nói dựa trên AI phải sử dụng các API có sẵn trên thị trường của bên thứ ba (STT để chép lời, LLM để chấm điểm dựa trên phiếu tự đánh giá). Việc đào tạo, tinh chỉnh hoặc lưu trữ các mô hình học máy tùy chỉnh nằm ngoài phạm vi của v1.

**Áp đặt bởi:** Các hạn chế về chi phí và tiến trình — đào tạo mô hình tùy chỉnh yêu cầu ghi nhãn dữ liệu, cơ sở hạ tầng và chuyên môn ML ngoài phạm vi v1.

**Ý nghĩa thực hiện:**
- Quy trình chấm điểm AI là một bộ chuyển đổi có thể định cấu hình; nhà cung cấp STT cụ thể (OI-02) và nhà cung cấp LLM (OI-02) được đọc từ bảng cấu hình hệ thống khi chạy
- Chuyển đổi giữa các nhà cung cấp chỉ yêu cầu thay đổi cấu hình, không thay đổi mã hoặc triển khai lại (SA-MNT-02)
- Lời nhắc trong phiếu tự đánh giá APTIS cho từng kỹ năng và phần là phần triển khai bắt buộc có thể cung cấp bên ngoài SRS này; chất lượng kịp thời quyết định trực tiếp đến độ chính xác của việc chấm điểm
- Quy trình phải triển khai logic thử lại (FR-30, FR-31) và xuống cấp nhẹ nhàng (cờ để xem xét thủ công về lỗi API vĩnh viễn)

---

###DC-07: Không xử lý thanh toán trong hệ thống

Hệ thống không được triển khai bất kỳ tích hợp cổng thanh toán, quản lý hóa đơn, thanh toán đăng ký hoặc xử lý dữ liệu thẻ thanh toán nào. Tạo và gia hạn giấy phép là các thao tác thủ công được thực hiện bởi các thành viên Nhóm bán hàng thông qua Cổng bán hàng.

**Áp đặt bởi:** Quyết định kinh doanh — thanh toán được xử lý theo hợp đồng bên ngoài nền tảng.

**Ý nghĩa thực hiện:**
- Không có Stripe, VNPay, MoMo, PayPal hoặc bất kỳ SDK thanh toán nào được đưa vào bất kỳ thành phần hệ thống nào
- Không có số thẻ thanh toán, số tài khoản ngân hàng hoặc thông tin xác thực thanh toán nào được lưu trữ hoặc truyền đi
- Không bắt buộc phải tuân thủ PCI-DSS và không được coi là hạn chế
- Hệ thống chỉ theo dõi hiệu lực của giấy phép (`seat_count` và `expiry_date`); nó không biết liệu Nhà cung cấp đã được thanh toán hay chưa

---

### DC-08: Chỉ Cloud Hosting (Không có On-Premise cho v1)

Tất cả các thành phần hệ thống — API phụ trợ, cơ sở dữ liệu quan hệ, hàng đợi công việc, Lưu trữ đám mây và công cụ quan sát — phải được triển khai trên cơ sở hạ tầng đám mây được quản lý (AWS, GCP hoặc Azure). Triển khai tại chỗ không được hỗ trợ trong v1.

**Áp đặt bởi:** Quyết định của các bên liên quan.

**Ý nghĩa thực hiện:**
- Cơ sở hạ tầng dưới dạng Mã phải nhắm mục tiêu các dịch vụ đám mây được quản lý (ví dụ: RDS/Cloud SQL, S3/GCS, điều phối vùng chứa được quản lý, hàng đợi được quản lý)
- Kiến trúc đám mây không được cản trở việc triển khai đa vùng trong tương lai (ngay cả khi v1 là một vùng)
- Nếu Nghị định 13/2023/ND-CP (OI-07) yêu cầu nội địa hóa dữ liệu tại Việt Nam thì khu vực triển khai phải bao gồm Việt Nam hoặc quốc gia thay thế tương đương về mặt pháp lý; nhà cung cấp đám mây phải được chọn trước khi kiến trúc được hoàn thiện

---

### DC-09: RBAC Phải Hỗ trợ Phân công đa vai trò (Bên thuê)

Hệ thống cấp phép cho người dùng Bên thuê phải hỗ trợ gán nhiều vai trò cùng lúc cho một người dùng. Các quyền hiệu quả là sự kết hợp của tất cả các bộ quyền của các vai trò hiện được giao. Hệ thống không bao giờ được cho rằng người dùng Đối tượng thuê chỉ giữ một vai trò.

**Áp đặt bởi:** Yêu cầu của bên liên quan — tình huống thực tế: Giáo viên đồng thời là Điều phối viên Kỳ thi (Giám thị) phải đảm nhiệm cả hai vai trò.

**Ý nghĩa thực hiện:**
- Truy vấn kiểm tra quyền `user_roles` cho tất cả các hàng đang hoạt động (không bị thu hồi) đối với người dùng yêu cầu và tính toán liên kết quyền
- Không trình xử lý API nào có thể cho rằng người dùng có chính xác một vai trò; giả định vai trò đơn trong phần mềm trung gian ủy quyền là một lỗi logic
- Giao diện người dùng hiển thị sự kết hợp của tất cả các điều khiển dựa trên vai trò; Giáo viên+Điều phối viên nhìn thấy cả menu Giáo viên và menu Điều phối viên
- Các mục nhật ký kiểm tra phải ghi lại `user_id` và vai trò thực hiện hành động đó (hoặc tất cả các vai trò đang hoạt động, theo quyết định của TechLead — OI-05 liền kề)

---

### DC-10: Nhật ký kiểm tra và tính toàn vẹn bất biến

Các bảng sau đây phải bất biến ở lớp ứng dụng: `violation_events`, `exam_events`, `impersonation_log` và các bản ghi lịch sử giấy phép. Không có vai trò ứng dụng nào có thể đưa ra câu lệnh `DELETE` hoặc `UPDATE` đối với các bảng này thông qua API phụ trợ.

**Áp đặt bởi:** Các yêu cầu về tính liêm chính trong học thuật và kiểm toán.

**Ý nghĩa thực hiện:**
- Tài khoản người dùng ứng dụng cơ sở dữ liệu không được có đặc quyền `DELETE` hoặc `UPDATE` trên các bảng này
- Việc thanh lọc lưu giữ dữ liệu cho `sự kiện vi phạm` phải được thực thi bởi một công việc hệ thống đặc quyền chuyên dụng (không phải lệnh gọi API đặc biệt) và chỉ khi các bản ghi vượt quá thời gian lưu giữ (OI-07)
- Lưu trữ vào kho lạnh (thay vì xóa) là một giải pháp thay thế có thể chấp nhận được để đáp ứng chính sách lưu giữ trong khi vẫn duy trì dấu vết kiểm tra tính toàn vẹn

---

### DC-11: Tuyên bố miễn trừ trách nhiệm trên tất cả màn hình kết quả

Hệ thống phải hiển thị tuyên bố từ chối trách nhiệm rõ ràng, không thể bỏ qua trên mọi màn hình kết quả, trang kết quả thử nghiệm và trang đích thử nghiệm nêu rõ rằng APTIS LMS là một nền tảng mô phỏng thực hành và không được liên kết, ủy quyền hoặc xác nhận bởi Hội đồng Anh và các kết quả đó chỉ là giá trị gần đúng cho mục đích học tập và không cấu thành điểm APTIS chính thức.

**Áp đặt bởi:** Bảo vệ pháp lý — APTIS LMS không phải là trung tâm khảo thí được ủy quyền của Hội đồng Anh.

**Văn bản từ chối trách nhiệm bắt buộc (tiếng Việt):** "Đây là bài thi thử mô phỏng. Điểm số và ước tính từ hệ thống này chỉ mang tính chất tham khảo và không phải là kết quả APTIS chính thức của Hội đồng Anh."

**Ý nghĩa thực hiện:**
- Tuyên bố từ chối trách nhiệm phải được hiển thị như một phần của nội dung trang, không phải dưới dạng biểu ngữ cookie hoặc phương thức có thể bị loại bỏ vĩnh viễn
- Tuyên bố từ chối trách nhiệm phải xuất hiện trên: màn hình kết quả bài thi của học sinh (FR-34), màn hình kết quả bài thi (FR-90) và trang đích bài thi (FR-88)
- Tài liệu tiếp thị (ngoài phạm vi SRS) cũng không được ngụ ý liên kết chính thức của Hội đồng Anh

---

### DC-12: Mật khẩu không bao giờ được lưu trong bản rõ

Mật khẩu người dùng không bao giờ được lưu trữ, ghi lại, xuất, lưu vào bộ nhớ đệm hoặc truyền ở dạng văn bản gốc. Hình thức lưu trữ được phép duy nhất là hàm băm bcrypt có hệ số chi phí ≥ 12 (NFR-12).

**Áp đặt bởi:** Đường cơ sở bảo mật.

**Ý nghĩa thực hiện:**
- Xuất thông tin xác thực số lượng lớn (FR-48) tạo mật khẩu văn bản gốc tại thời điểm tạo tài khoản, truyền mật khẩu đó một lần đến khách hàng yêu cầu và chỉ lưu trữ hàm băm bcrypt trong cơ sở dữ liệu; bản rõ không được lưu trữ ở bất cứ đâu
- Bản sao lưu cơ sở dữ liệu phải được mã hóa; khóa mã hóa phải được lưu trữ riêng biệt với bản sao lưu
- Phần mềm trung gian ghi nhật ký ứng dụng phải loại bỏ bất kỳ trường nào có tên `password`, `password_hash`, `plaintext_password` hoặc trường tương đương khỏi nhật ký yêu cầu và phản hồi trước khi ghi
- Đặt lại mật khẩu (FR-05) phát hành mã thông báo có giới hạn thời gian, không phải mật khẩu hiện có; hàm băm hiện tại không bao giờ bị đảo ngược