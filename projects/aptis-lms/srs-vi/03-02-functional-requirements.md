# SRS §3.2 - Yêu cầu chức năng
## APTIS LMS
**Phiên bản:** 1.0 | **Ngày:** 2026-06-16 | **Trạng thái:** BẢN THẢO

---

Tất cả các yêu cầu trong phần này đều sử dụng từ khóa **shall** để biểu thị nghĩa vụ ràng buộc. **Nên** biểu thị hướng dẫn không ràng buộc. **Có thể** biểu thị khả năng được phép nhưng không bắt buộc.

Việc đánh số FR là tuần tự trên tất cả các cụm. Không đặt lại giữa các phần.

---

## F-01: Xác thực và truy cập (FR-01 – FR-08)

---

#### FR-01 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ xác thực người dùng qua email và mật khẩu, xác định bối cảnh đăng nhập cho đối tượng thuê được xác định bởi miền phụ yêu cầu hiện tại và từ chối thông tin xác thực không thuộc về đối tượng thuê đó.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Bất kỳ người dùng đã đăng ký nào (tất cả các vai trò) |
| điều kiện tiên quyết | Người dùng có tài khoản đã đăng ký; tên miền phụ phân giải thành một đối tượng thuê đang hoạt động (hoặc Cổng thông tin nhà cung cấp) |
| Cò súng | Người dùng gửi mẫu đăng nhập bằng email và mật khẩu |
| Nguồn | cụm F-01; BR-02 (cách ly người thuê nhà); DC-03 (HTTPS) |

**Tiêu chí chấp nhận (GWT):**
- **Cho** người dùng truy cập `{slug}.aptis-lms.vn/login` và nhập email và mật khẩu của họ
- **Khi** mẫu đăng nhập được gửi
- **Sau đó** nếu thông tin đăng nhập khớp với tài khoản người dùng có `tenant_id` khớp với đối tượng thuê đã được giải quyết, thì hệ thống sẽ cấp mã thông báo truy cập JWT và mã thông báo làm mới, đồng thời chuyển hướng người dùng đến màn hình chính phù hợp với vai trò của họ
- **Và** nếu thông tin xác thực không hợp lệ hoặc tài khoản người dùng thuộc về một đối tượng thuê khác, hệ thống sẽ trả về HTTP 401 có nội dung `{"code://INVALID_CREDENTIALS","message"Email hoặc mật khẩu không hợp lệ"}`
- **Và** hệ thống không tiết lộ liệu email có tồn tại hay không (thông báo lỗi thống nhất ngăn cản việc liệt kê)
- **Và** năm lần thử thất bại liên tiếp từ cùng một IP trong vòng 10 phút sẽ kích hoạt phản hồi giới hạn tỷ lệ 429

---

#### FR-02 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cấp mã thông báo truy cập JWT tồn tại trong thời gian ngắn (TTL 15 phút) và mã thông báo làm mới luân phiên tồn tại lâu dài (TTL 7 ngày) khi xác thực thành công; hệ thống sẽ cấp mã thông báo truy cập mới và vô hiệu hóa mã thông báo làm mới cũ khi mã thông báo làm mới hợp lệ được xuất trình.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Bất kỳ người dùng được xác thực nào (do khách hàng khởi tạo); Dịch vụ xác thực |
| điều kiện tiên quyết | Người dùng đã xác thực thành công (FR-01) |
| Cò súng | Mã thông báo truy cập hết hạn; khách hàng gửi POST /api/v1/auth/refresh với mã thông báo làm mới hợp lệ |
| Nguồn | cụm F-01; tiêu chuẩn JWT; DC-03 |

**Tiêu chí chấp nhận (GWT):**
- **Đã cấp** mã thông báo truy cập của người dùng đã hết hạn và khách hàng có mã thông báo làm mới hợp lệ
- **Khi** khách hàng gửi `POST /api/v1/auth/refresh` với mã thông báo làm mới trong nội dung yêu cầu
- **Sau đó** hệ thống sẽ cấp mã thông báo truy cập mới (TTL = 15 phút) và mã thông báo làm mới mới (TTL = 7 ngày kể từ ngày phát hành)
- **Và** mã thông báo làm mới cũ ngay lập tức bị vô hiệu; bất kỳ việc sử dụng mã thông báo làm mới cũ nào sau đó đều trả về HTTP 401
- **Và** trọng tải của mã thông báo truy cập chứa: `user_id`, `tenant_id`, `roles[]`, `exp`
- **Và** nếu mã thông báo làm mới hết hạn hoặc không hợp lệ, hệ thống sẽ trả về HTTP 401 và máy khách sẽ chuyển hướng người dùng đến màn hình đăng nhập

---

#### FR-03 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ phân giải ngữ cảnh của đối tượng thuê từ tên miền phụ tiêu đề `Máy chủ` của mọi yêu cầu đến và chỉ áp dụng phạm vi tất cả các hoạt động dữ liệu cho `tenant_id` của đối tượng thuê đó; các yêu cầu tới `admin.aptis-lms.vn` ​​sẽ được định tuyến đến Cổng thông tin nhà cung cấp mà không có phạm vi đối tượng thuê.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Phần mềm trung gian API Gateway (tự động) |
| Điều kiện tiên quyết | Bản ghi DNS ký tự đại diện phân giải `*.aptis-lms.vn` ​​thành bộ cân bằng tải nền tảng |
| Cò súng | Mọi yêu cầu HTTP hoặc WebSocket đều đến nền tảng |
| Nguồn | F-01; DC-02 (ủy thác cách ly người thuê nhà); CI-04 |

**Tiêu chí chấp nhận (GWT):**
- **Được đưa ra** một yêu cầu được gửi đến với `Host: hanoi-english.aptis-lms.vn`
- **Khi** cổng API xử lý yêu cầu
- **Sau đó** hệ thống trích xuất slug `hanoi-english`, tra cứu `tenant_id` tương ứng trong cache (TTL = 5 phút) và đính kèm `tenant_id` vào ngữ cảnh yêu cầu
- **Và** tất cả các truy vấn cơ sở dữ liệu tiếp theo trong vòng đời yêu cầu bao gồm `WHERErent_id = {resolved_id}`
- **Và** nếu slug không phân giải được đối với bất kỳ đối tượng thuê nào, hệ thống sẽ trả về HTTP 404 với `{"code:"TENANT_NOT_FOUND","message">Không tìm thấy đối tượng thuê"}`
- **Và** yêu cầu `admin.aptis-lms.vn` ​​bỏ qua quá trình phân giải đối tượng thuê và định tuyến đến trình xử lý Cổng thông tin nhà cung cấp mà không có ràng buộc `tenant_id`

---

#### FR-04 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ hỗ trợ gán đồng thời nhiều vai trò cho một người dùng phía Bên thuê; các quyền có hiệu lực của người dùng sẽ là sự kết hợp của tất cả các bộ quyền của các vai trò được giao; việc thêm hoặc xóa vai trò sẽ có hiệu lực đối với yêu cầu được xác thực tiếp theo của người dùng.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Quản trị viên thuê nhà |
| Điều kiện tiên quyết | Người dùng mục tiêu tồn tại trong cùng một đối tượng thuê |
| Cò súng | Quản trị viên đối tượng thuê lưu thay đổi phân công vai trò cho người dùng |
| Nguồn | F-01; BR-01 (đoàn đa vai trò) |

**Tiêu chí chấp nhận (GWT):**
- **Được cho** Quản trị viên người thuê chỉ định vai trò `Giáo viên` và `Điều phối viên kỳ thi` cho người dùng U
- **Khi** người dùng U đăng nhập và thử thực hiện các hành động
- **Sau đó** người dùng U có thể thực hiện tất cả các hành động được cho phép bởi vai trò Giáo viên hoặc vai trò Điều phối viên bài kiểm tra (tập hợp các quyền)
- **Và** việc xóa vai trò `Giáo viên` khỏi người dùng U sẽ ngay lập tức thu hồi các quyền dành riêng cho Giáo viên đối với yêu cầu được xác thực tiếp theo của U, trong khi các quyền của Điều phối viên kỳ thi vẫn giữ nguyên
- **Và** người dùng không có vai trò nào được chỉ định sẽ nhận được HTTP 403 trên bất kỳ điểm cuối được bảo vệ nào
- **Và** Không thể chỉ định vai trò phía nhà cung cấp (Quản trị viên cấp cao, Người quản lý nội dung, Nhân viên hỗ trợ, Nhóm bán hàng) cho người dùng Đối tượng thuê và ngược lại

---

#### FR-05 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cung cấp quy trình đặt lại mật khẩu qua email cho tất cả người dùng đã đăng ký; liên kết đặt lại sẽ được giới hạn thời gian trong 1 giờ, sử dụng một lần và nằm trong phạm vi miền cổng thông tin của người dùng.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Bất kỳ người dùng đã đăng ký nào (tất cả các vai trò) |
| Điều kiện tiên quyết | Người dùng có tài khoản đã đăng ký với địa chỉ email hợp lệ |
| Cò súng | Người dùng gửi email của họ trên trang quên mật khẩu |
| Nguồn | cụm F-01; thực hành tốt nhất về bảo mật |

**Tiêu chí chấp nhận (GWT):**
- **Cho** người dùng điều hướng đến trang quên mật khẩu trên cổng thông tin tương ứng của họ
- **Khi** người dùng gửi địa chỉ email hợp lệ
- **Sau đó** nếu email khớp với người dùng trong phạm vi hiện tại (Cổng đối tượng thuê hoặc Cổng thông tin nhà cung cấp), hệ thống sẽ gửi email đặt lại mật khẩu chứa liên kết mã thông báo sử dụng một lần duy nhất có giá trị trong 60 phút vào hàng đợi
- **Và** nếu email không khớp với bất kỳ người dùng nào, hệ thống sẽ phản hồi với thông báo thành công tương tự (ngăn chặn việc liệt kê email)
- **Và** khi người dùng nhấp vào liên kết đặt lại và gửi mật khẩu mới, hệ thống sẽ cập nhật hàm băm mật khẩu, vô hiệu hóa mã thông báo và vô hiệu hóa tất cả các mã thông báo làm mới đang hoạt động cho người dùng đó
- **Và** sử dụng cùng một liên kết đặt lại lần thứ hai sẽ trả về HTTP 400 với `{"code://TOKEN_USED","message"Liên kết đặt lại này đã được sử dụng"}`

---

#### FR-06 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ buộc sinh viên đăng nhập lần đầu bằng mật khẩu được tạo hàng loạt phải thay đổi mật khẩu trước khi truy cập bất kỳ màn hình nào khác, khi người thuê đã bật `force_password_change`.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Học sinh |
| điều kiện tiên quyết | Tài khoản sinh viên được tạo thông qua nhập số lượng lớn (FR-47); cài đặt đối tượng thuê `force_password_change = true` |
| Cò súng | Sinh viên hoàn thành lần đăng nhập thành công đầu tiên |
| Nguồn | F-01; F-06; thực hành tốt nhất về bảo mật |

**Tiêu chí chấp nhận (GWT):**
- **Đã cho** một tài khoản sinh viên đã được tạo tự động bằng mật khẩu được tạo và `force_password_change = true`
- **Khi** học sinh đăng nhập lần đầu tiên
- **Sau đó** hệ thống chặn phiên xác thực và chuyển hướng đến màn hình thay đổi mật khẩu trước khi cấp mã thông báo truy cập cuối cùng
- **Và** học sinh không thể truy cập bất kỳ buổi thi, màn hình kết quả hoặc trang hồ sơ nào cho đến khi mật khẩu mới được lưu
- **Và** sau khi mật khẩu được thay đổi, `account.password_changed_at` được đặt và cờ `force_password_change` sẽ bị xóa cho tài khoản này
- **Và** các lần đăng nhập tiếp theo của cùng một học sinh sẽ chuyển sang màn hình chính bình thường mà không bị chặn thay đổi bắt buộc

---

#### FR-07 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ vô hiệu hóa mã thông báo làm mới của người dùng khi đăng xuất; Quản trị viên cấp cao có thể vô hiệu hóa tất cả các phiên hoạt động của bất kỳ người dùng nào trên tất cả các thiết bị.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Bất kỳ người dùng được xác thực nào (tự đăng xuất); Quản trị viên cấp cao (buộc đăng xuất) |
| điều kiện tiên quyết | Người dùng được xác thực bằng mã thông báo làm mới hợp lệ |
| Cò súng | Người dùng nhấp vào Đăng xuất; Quản trị viên cấp cao sử dụng hành động buộc đăng xuất trên hồ sơ người dùng |
| Nguồn | F-01; thực hành tốt nhất về bảo mật; DC-03 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** người dùng đã đăng nhập nhấp vào Đăng xuất
- **Khi** yêu cầu đăng xuất được xử lý (`POST /api/v1/auth/logout`)
- **Sau đó** máy chủ vô hiệu hóa mã thông báo làm mới hiện tại; bất kỳ việc sử dụng mã thông báo đó tiếp theo sẽ trả về HTTP 401
- **Và** khách hàng xóa tất cả mã thông báo được lưu trữ cục bộ (mã thông báo truy cập và mã thông báo làm mới)
- **Và** người dùng được chuyển hướng đến trang đăng nhập
- **Và** đối với buộc đăng xuất của Quản trị viên cấp cao: tất cả mã thông báo làm mới được liên kết với người dùng mục tiêu sẽ bị vô hiệu trong vòng 1 phút, bất kể thiết bị hoặc trình duyệt

---

#### FR-08 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cho phép người dùng chưa được xác thực truy cập vào trang đích dùng thử và bài kiểm tra thử mà không cần tạo tài khoản, cấp mã thông báo phiên ẩn danh ngắn hạn chỉ có giá trị trong thời gian dùng thử.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Khách mời (Người dùng thử) |
| điều kiện tiên quyết | Cụm tính năng Khách/Dùng thử (F-11) được bật; người dùng không được xác thực |
| Cò súng | Người dùng điều hướng đến URL dùng thử công khai và bắt đầu bài kiểm tra dùng thử |
| Nguồn | F-01; F-11; FR-88–FR-92 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** người dùng chưa được xác thực sẽ điều hướng đến URL dùng thử
- **Khi** người dùng nhấp vào "Bắt đầu dùng thử"
- **Sau đó** hệ thống tạo một bản ghi phiên ẩn danh (không có `user_id`, không có `tenant_id`) và cấp mã thông báo phiên ẩn danh có hiệu lực trong 2 giờ hoặc cho đến khi gửi bản dùng thử, tùy điều kiện nào đến trước
- **Và** phiên ẩn danh chỉ cấp quyền truy cập vào quy trình thi thử (FR-88–FR-92); mọi nỗ lực truy cập vào điểm cuối của đối tượng thuê hoặc người dùng đã đăng ký đều trả về HTTP 403
- **Và** dữ liệu phiên ẩn danh sẽ bị xóa sau thời gian lưu giữ (FR-92)
- **Và** không có tài khoản người dùng liên tục nào được tạo trừ khi Khách gửi biểu mẫu thu thập khách hàng tiềm năng một cách rõ ràng (FR-91)

---

## F-02: Quản lý ngân hàng câu hỏi APTIS (FR-09 – FR-16)

---

#### FR-09 [Cần thiết]

**Yêu cầu:** Hệ thống cho phép Người quản lý nội dung tạo, đọc, cập nhật và xóa câu hỏi trong ngân hàng câu hỏi APTIS; mỗi bản ghi câu hỏi sẽ lưu trữ kỹ năng, phần, loại câu hỏi, nội dung, khóa trả lời (loại điểm tự động), tiêu chí tự đánh giá (loại điểm con người), thẻ độ khó và thẻ chủ đề.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Trình quản lý nội dung |
| điều kiện tiên quyết | Trình quản lý nội dung được xác thực trong Cổng thông tin nhà cung cấp |
| Cò súng | Trình quản lý nội dung gửi biểu mẫu tạo hoặc cập nhật câu hỏi |
| Nguồn | F-02; A-04 (Nhà cung cấp quản lý toàn bộ nội dung); A-08 |

**Tiêu chí chấp nhận (GWT):**
- **Được cung cấp** Trình quản lý nội dung sẽ mở trình soạn thảo câu hỏi trong Cổng thông tin nhà cung cấp
- **Khi** Trình quản lý nội dung điền vào tất cả các trường bắt buộc (kỹ năng, phần, loại câu hỏi, nội dung) và lưu
- **Sau đó** hệ thống tạo bản ghi câu hỏi với trạng thái `bản nháp` và gán ID câu hỏi duy nhất
- **Và** câu hỏi xuất hiện trong trình duyệt ngân hàng câu hỏi có thể lọc theo kỹ năng, phần, độ khó, thẻ chủ đề và trạng thái
- **Và** cố gắng lưu câu hỏi thuộc loại MCQ mà không có `answer_key` sẽ trả về lỗi xác thực: `"cần có câu trả lời cho các loại câu hỏi tự động cho điểm"`
- **Và** các câu hỏi liên quan đến ít nhất một buổi thi đã hoàn thành được kiểm soát theo phiên bản khi chỉnh sửa (FR-14); việc xóa bị chặn với thông báo: `"Câu hỏi này đã được sử dụng trong các phiên hoàn thành và không thể xóa được"`

---

#### FR-10 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cho phép Người quản lý nội dung tải lên các tệp âm thanh (MP3, WAV) cho các câu hỏi Nghe và gửi chúng đến khách hàng thi qua CDN với giới hạn số lần phát cho mỗi phần.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Trình quản lý nội dung |
| điều kiện tiên quyết | Trình quản lý nội dung được xác thực; Câu hỏi nghe tồn tại hoặc đang được tạo |
| Cò súng | Trình quản lý nội dung chọn tệp âm thanh trong trình chỉnh sửa câu hỏi và tải tệp đó lên |
| Nguồn | F-02; SI-01 (Lưu trữ đám mây); CI-03 (tải lên tệp); FR-22 |

**Tiêu chí chấp nhận (GWT):**
- **Được cho** Trình quản lý nội dung đang chỉnh sửa câu hỏi Nghe và chọn tệp MP3 hoặc WAV (≤ 100 MB)
- **Khi** quá trình tải lên hoàn tất
- **Sau đó** tệp được lưu trữ trong Cloud Storage và URL CDN được tạo và liên kết với bản ghi câu hỏi
- **Và** câu hỏi lưu trữ `max_play_count` (có thể định cấu hình; mặc định: 1 cho mỗi tiêu chuẩn APTIS cho mỗi phần)
- **Và** Trình quản lý nội dung có thể xem trước phần phát lại âm thanh trong trình chỉnh sửa câu hỏi trước khi lưu
- **Và** tiến trình tải lên âm thanh được hiển thị theo thời gian thực; lỗi tải lên hiển thị nút thử lại kèm theo thông báo lỗi
- **Và** các định dạng tệp không được hỗ trợ (ví dụ: FLAC, OGG) bị từ chối khi tải lên với: `"Định dạng âm thanh không được hỗ trợ. Được chấp nhận: MP3, WAV"`

---

#### FR-11 [Cần thiết]

**Yêu cầu:** Hệ thống cho phép Người quản lý nội dung tải lên các tệp hình ảnh (JPEG, PNG, ≤ 10 MB) và liên kết chúng với các câu hỏi Nói Phần B (ảnh đơn) và Phần D (cặp ảnh).

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Trình quản lý nội dung |
| Điều kiện tiên quyết | Trình quản lý nội dung được xác thực; Câu hỏi Nói Phần B hoặc Phần D được mở để chỉnh sửa |
| Cò súng | Trình quản lý nội dung chọn tệp hình ảnh trong trình chỉnh sửa câu hỏi |
| Nguồn | F-02; SI-01; CI-03; FR-23 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** Người quản lý nội dung đang chỉnh sửa câu hỏi Phần B Nói và tải hình ảnh JPEG hoặc PNG lên
- **Khi** quá trình tải lên hoàn tất
- **Sau đó** hình ảnh được lưu trữ trong Cloud Storage, một URL được liên kết với câu hỏi và bản xem trước hình thu nhỏ sẽ hiển thị trong trình chỉnh sửa
- **Và** đối với phần Nói D (so sánh các hình ảnh), bản ghi câu hỏi lưu chính xác 2 URL hình ảnh (`image_1`, `image_2`); lưu chỉ với một hình ảnh trả về: `"Các câu hỏi Phần D yêu cầu chính xác 2 hình ảnh"`
- **Và** hình ảnh vượt quá 10 MB bị từ chối khi tải lên với: `"Hình ảnh vượt quá giới hạn kích thước 10 MB"`
- **Và** ứng dụng thi hiển thị hình ảnh một cách linh hoạt trong giao diện nói (FR-23)

---

#### FR-12 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cho phép Người quản lý nội dung tạo các mẫu bài thi được đặt tên bằng cách chọn câu hỏi cho mỗi kỹ năng và phần hoặc bằng cách chỉ định tiêu chí tự động điền; một mẫu sẽ chỉ được xuất bản khi đã bao gồm tất cả các kỹ năng và phần cần thiết.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Trình quản lý nội dung |
| điều kiện tiên quyết | Ngân hàng câu hỏi chứa đủ các câu hỏi được xuất bản cho mẫu dự định |
| Cò súng | Trình quản lý nội dung lưu mẫu bài kiểm tra |
| Nguồn | F-02; A-02 (cấu trúc APTIS ổn định); FR-37 |

**Tiêu chí chấp nhận (GWT):**
- **Được cung cấp** Trình quản lý nội dung sẽ mở trình tạo mẫu bài kiểm tra
- **Khi** Người quản lý nội dung chọn câu hỏi cho từng kỹ năng/phần và nhấp vào Lưu
- **Sau đó** mẫu được lưu với tên, mô tả và ánh xạ `{skill → {part → [question_ids]}}`
- **Và** cố gắng xuất bản một mẫu thiếu bất kỳ phần bắt buộc nào (Đọc A/B/C/D, Viết A/B/C, Nghe A/B/C/D, Nói A/B/C/D/E) trả về lỗi xác thực liệt kê tất cả các phần bị thiếu
- **Và** chế độ tự động điền chọn ngẫu nhiên các câu hỏi từ ngân hàng phù hợp với tiêu chí đã chỉ định (kỹ năng, phần, độ khó, số lượng) và có thể được Trình quản lý nội dung cuộn lại trước khi lưu
- **Và** các buổi thi được tạo từ mẫu này sử dụng bộ câu hỏi đã chọn với chế độ xáo trộn tùy chọn cho mỗi lần thử (BR-14)

---

#### FR-13 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cung cấp chế độ xem trước cho phép Người quản lý nội dung trải nghiệm một câu hỏi hoặc mẫu bài kiểm tra đầy đủ như học sinh, bao gồm phát lại âm thanh, hiển thị hình ảnh và hiển thị đồng hồ mà không cần tạo bất kỳ bản ghi bài kiểm tra nào.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Trình quản lý nội dung |
| điều kiện tiên quyết | Đã có mẫu câu hỏi hoặc bài thi trong hệ thống |
| Cò súng | Trình quản lý nội dung nhấp vào "Xem trước" trên mẫu câu hỏi hoặc bài kiểm tra |
| Nguồn | F-02; UI-02 |

**Tiêu chí chấp nhận (GWT):**
- **Được cho** Người quản lý nội dung nhấp vào "Xem trước" trên câu hỏi hoặc mẫu đã xuất bản hoặc bản nháp
- **Khi** bản xem trước ra mắt
- **Sau đó** hệ thống hiển thị câu hỏi hoặc mẫu trong giao diện chỉ đọc giống bài kiểm tra với chức năng phát lại âm thanh, hiển thị hình ảnh, đồng hồ đếm ngược (mô phỏng) và điều hướng
- **Và** không có bản ghi `exam_attempt`, `exam_state` hoặc `exam_answers` nào được tạo trong quá trình xem trước
- **Và** giới hạn số lần phát đối với âm thanh Nghe được mô phỏng (âm thanh bị tắt sau khi phát tối đa)
- **Và** Trình quản lý nội dung có thể thoát khỏi bản xem trước bất kỳ lúc nào và quay lại trình chỉnh sửa; các chỉnh sửa chưa lưu sẽ được giữ nguyên
- **Và** biểu ngữ "CHẾ ĐỘ XEM TRƯỚC" hiển thị giúp phân biệt phần xem trước với một buổi thi thực

---

#### FR-14 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ lưu giữ phiên bản của mọi câu hỏi được sử dụng trong một buổi thi đã hoàn thành; việc chỉnh sửa câu hỏi như vậy sẽ tạo ra một phiên bản mới (hiện tại) trong khi vẫn giữ nguyên phiên bản gốc (không thay đổi) được liên kết với các phiên trước.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Trình quản lý nội dung (trình kích hoạt chỉnh sửa); hệ thống (phiên bản tự động) |
| điều kiện tiên quyết | Câu hỏi đã được sử dụng trong ít nhất một buổi thi với trạng thái `đã đóng` hoặc `đã hoàn thành` |
| Cò súng | Trình quản lý nội dung chỉnh sửa và lưu câu hỏi đã sử dụng phiên trước đó |
| Nguồn | F-02; yêu cầu toàn vẹn dữ liệu |

**Tiêu chí chấp nhận (GWT):**
- **Đã cho** câu hỏi Q (phiên bản v1) đã được sử dụng trong một buổi thi hoàn chỉnh
- **Khi** Người quản lý nội dung chỉnh sửa và lưu câu hỏi Q
- **Sau đó** hệ thống tạo phiên bản câu hỏi Q-v2 được đánh dấu là `is_current = true`; Q-v1 được đánh dấu `is_current = false` và `is_immutable = true`
- **Và** tất cả các buổi thi và bản ghi câu trả lời hiện có đều giữ lại tham chiếu đến Q-v1; mẫu bài thi mới được tạo sau khi chỉnh sửa tài liệu tham khảo Q-v2
- **Và** cố gắng chỉnh sửa Q-v1 trực tiếp trả về HTTP 409: `"Phiên bản câu hỏi này được liên kết với các phiên đã hoàn thành và không thể sửa đổi"`
- **Và** trình duyệt ngân hàng câu hỏi hiển thị phiên bản hiện tại theo mặc định; điều khiển "Lịch sử phiên bản" hiển thị tất cả các phiên bản có dấu thời gian chỉnh sửa

---

#### FR-15 [Cần thiết]

**Yêu cầu:** Hệ thống cho phép Người quản lý nội dung nhập câu hỏi hàng loạt từ tệp CSV hoặc Excel theo mẫu nhập quy định; hệ thống sẽ xác thực từng hàng một cách độc lập và báo cáo lỗi trên mỗi hàng trước khi thực hiện bất kỳ dữ liệu nào.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Trình quản lý nội dung |
| điều kiện tiên quyết | Trình quản lý nội dung có tệp CSV hoặc Excel phù hợp với mẫu nhập |
| Cò súng | Trình quản lý nội dung tải tệp lên màn hình nhập hàng loạt |
| Nguồn | F-02; UI-02; CI-03 (tệp tải lên ≤ 50 MB) |

**Tiêu chí chấp nhận (GWT):**
- **Được cung cấp** Trình quản lý nội dung tải lên tệp CSV hoặc Excel (≤ 50 MB) trên màn hình nhập hàng loạt
- **Khi** hệ thống phân tích tệp
- **Sau đó** hệ thống hiển thị bảng xem trước của tất cả các hàng được phân tích cú pháp với chỉ báo lỗi/hợp lệ trên mỗi hàng
- **Và** các hàng không hợp lệ được đánh dấu bằng các thông báo lỗi cụ thể (ví dụ: `"Hàng 12: cần có khóa trả lời cho loại câu hỏi MCQ"`, `"Hàng 5: giá trị kỹ năng không hợp lệ 'Ngữ pháp' — dự kiến ​​Đọc|Viết|Nghe|Nói"`)
- **Và** Trình quản lý nội dung có thể chọn chỉ nhập các hàng hợp lệ (bỏ qua không hợp lệ) hoặc hủy toàn bộ quá trình nhập
- **Và** sau khi xác nhận nhập, các câu hỏi được tạo thành công sẽ xuất hiện trong ngân hàng câu hỏi với trạng thái `bản nháp`; một bản tóm tắt hiển thị: N câu hỏi được tạo, M hàng bị bỏ qua (có lý do)

---

#### FR-16 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ tính toán và hiển thị số liệu thống kê phân tích mục theo câu hỏi cho Người quản lý nội dung, được tổng hợp trên toàn cầu cho tất cả người thuê và tự động gắn cờ các câu hỏi có chỉ số phân biệt hoặc độ khó ngoại lệ về mặt thống kê.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Trình quản lý nội dung |
| Điều kiện tiên quyết | Câu hỏi đã được sử dụng trong ít nhất 10 lần thi đã hoàn thành (mẫu tối thiểu để có giá trị thống kê) |
| Cò súng | Trình quản lý nội dung mở chế độ xem phân tích mục và chọn một câu hỏi hoặc xem danh sách bị gắn cờ |
| Nguồn | F-02; F-07 (phân tích vật phẩm); FR-67–FR-70 |

**Tiêu chí chấp nhận (GWT):**
- **Được cung cấp** Trình quản lý nội dung sẽ mở chế độ xem phân tích mục
- **Khi** Người quản lý nội dung chọn một câu hỏi có ≥ 10 bản ghi phản hồi
- **Sau đó** hệ thống hiển thị: `tỷ lệ chính xác (%)`, `tỷ lệ sai cho mỗi tùy chọn phân tâm (MCQ)`, `skip_rate (%)`, `avg_time_spent (giây)`, `p_value`, `discrimination_index`
- **Và** hệ thống tự động gắn cờ: các câu hỏi có `p_value < 0,3` là "Quá khó"; `p_value > 0,9` là "Quá dễ"; `discrimination_index < 0,2` là "Người phân biệt đối xử kém"; `discrimination_index < 0` là "Cần xem xét"
- **Và** các câu hỏi có ít hơn 10 câu trả lời hiển thị thông báo: "Không đủ dữ liệu để phân tích thống kê (N = {count})" và không áp dụng cờ
- **Và** số liệu thống kê được tính lại hàng đêm từ bảng Exam_answers

---

## F-03: Mô phỏng bài kiểm tra - Chế độ đầy đủ (FR-17 – FR-26)

---

#### FR-17 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ xác minh tính đủ điều kiện của học sinh trước khi phát động kỳ thi; Tính đủ điều kiện yêu cầu học sinh phải đăng ký, cửa sổ phiên học được mở và học sinh này không có nỗ lực hoàn thành nào cho phiên học này.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Học sinh |
| điều kiện tiên quyết | Sinh viên được xác thực; một buổi thi đã được công bố |
| Cò súng | Học sinh nhấp chuột để tham gia một buổi thi từ danh sách Bài kiểm tra của tôi |
| Nguồn | F-03; F-05; BR-06 (một lần thử mỗi phiên); FR-26 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một học sinh nhấp vào "Enter" trong một buổi thi được chỉ định
- **Khi** hệ thống xử lý yêu cầu khởi chạy
- **Sau đó** nếu học sinh đã đăng ký thì cửa sổ phiên sẽ mở (`current_time` giữa `session.start_time` và `session.end_time`) và không có lần thử nào trước đó tồn tại: một bản ghi `exam_attempt` được tạo với `status = in_progress` và học sinh tiến hành kiểm tra trước kỳ thi (FR-18)
- **Và** nếu cửa sổ phiên học chưa mở: học sinh nhìn thấy thời gian bắt đầu theo lịch trình và đồng hồ đếm ngược
- **Và** nếu cửa sổ phiên làm việc đã đóng: học sinh nhìn thấy thông báo `"Bài thi này đã kết thúc"`
- **Và** nếu học sinh hiện có một lần thử `đang tiến hành`: học sinh được cung cấp luồng sơ yếu lý lịch (FR-106) thay vì tạo một lần thử mới
- **Và** nếu học sinh đã `đã nộp bài thi` và không có bài thi lại nào được phê duyệt: học sinh sẽ nhìn thấy `"Bạn đã nộp bài kiểm tra này"` cùng với nút Xem kết quả

---

#### FR-18 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ chạy ba lần kiểm tra tuần tự trước kỳ thi trước khi học sinh bắt đầu kỹ năng đầu tiên: phát hiện micrô và ghi âm bài kiểm tra, kích hoạt chế độ toàn màn hình và xác nhận hướng dẫn theo từng kỹ năng; cả ba đều phải đậu trước khi kỳ thi bắt đầu.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Học sinh |
| điều kiện tiên quyết | Học sinh đã vượt qua bài kiểm tra đủ điều kiện (FR-17); bản ghi `exam_attempt` tồn tại với `status = in_progress` |
| Cò súng | Học sinh ở trên màn hình kiểm tra trước kỳ thi và thực hiện từng bước kiểm tra |
| Nguồn | F-03; F-12 (chống gian lận); HW-01; FR-95 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một học sinh đã đủ điều kiện và đang ở trên màn hình kiểm tra trước kỳ thi
- **Khi** học sinh tiến hành qua từng bước kiểm tra
- **Sau đó** Chọn 1 (Micrô): hệ thống yêu cầu quyền sử dụng micrô thông qua API nền tảng; ghi lại âm thanh 3 giây; phát lại bản ghi âm; học sinh nhấp vào Đạt hoặc Thử lại; nếu không có micrô, học sinh sẽ thấy hướng dẫn khắc phục sự cố và tùy chọn báo hiệu cho giám thị (FR-110)
- **Và** Kiểm tra 2 (Toàn màn hình): hệ thống yêu cầu chế độ toàn màn hình; Nút "Nhập bài kiểm tra" bị tắt cho đến khi toàn màn hình được xác nhận hoạt động; nếu toàn màn hình bị từ chối, học sinh sẽ thấy hướng dẫn và không thể tiếp tục
- **Và** Kiểm tra 3 (Hướng dẫn): hiển thị giới hạn thời gian cho mỗi kỹ năng và những gì sẽ xảy ra; sinh viên bấm “Tôi hiểu — Bắt đầu” để xác nhận
- **Và** chỉ sau khi vượt qua cả ba bước kiểm tra, hệ thống mới khởi động đồng hồ tính giờ thi (FR-19) và hiển thị giao diện kỹ năng đầu tiên

---

#### FR-19 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ duy trì bộ đếm giờ thi bán phần chính thức trên máy chủ; khi `time_remaining` đạt đến 0, máy chủ sẽ đóng phần hiện tại và chuyển học sinh sang phần tiếp theo bất kể trạng thái máy khách; không cần thực hiện hành động nào từ phía khách hàng để kích hoạt tạm ứng.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Hệ thống (thực thi hẹn giờ tự động) |
| điều kiện tiên quyết | Một học sinh đang thực hiện bài thi `in_progress` với một phần đang diễn ra |
| Cò súng | `time_remaining` do máy chủ tính toán cho phần hiện tại đạt đến 0 |
| Nguồn | F-03; F-13 (thi liên tục); DC-04 (ủy thác hẹn giờ) |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một học sinh đang tham gia một phần thi đang diễn ra và máy chủ đã ghi lại `part_start_time`
- **Khi** `server_time - part_start_time ≥ part_duration`
- **Sau đó** máy chủ ghi lại `part_end_time`, lưu giữ tất cả các câu trả lời đã gửi cho đến thời điểm đó và đánh dấu phần đó là `đã hoàn thành` trong `exam_state`
- **Và** bất kỳ yêu cầu gửi câu trả lời nào nhận được sau `time_remaining = 0` đều trả về HTTP 409 với `{"code://PART_CLOSED","message://Thời gian dành cho phần này đã hết"}`
- **Và** máy khách hiển thị thời gian còn lại được đồng bộ hóa từ máy chủ (được thăm dò cứ sau 10 giây); sự trôi dạt của đồng hồ máy khách không ảnh hưởng đến thời hạn sử dụng phía máy chủ
- **Và** khi máy khách đồng bộ hóa lần tiếp theo (thăm dò hoặc đẩy), nó sẽ chuyển sang màn hình chuyển tiếp từng phần (FR-24)

---

#### FR-20 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ hiển thị từng phần Đọc với loại tương tác chính xác: Phần A (khớp câu), Phần B (điền vào chỗ trống bằng cách thả xuống), Phần C (MCQ với đoạn văn có thể cuộn), Phần D (nhập văn bản trả lời ngắn kèm theo đoạn văn); câu trả lời của học sinh sẽ được duy trì cho mỗi câu hỏi khi được nhập.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Học sinh |
| điều kiện tiên quyết | Học sinh đang ở kỹ năng Đọc của một bài thi tích cực |
| Cò súng | Học sinh điều hướng đến hoặc trả lời câu hỏi trong phần Đọc |
| Nguồn | F-03; A-02 (cấu trúc APTIS); FR-105 (độ bền cho mỗi câu trả lời) |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một học sinh đang đọc Phần C (MCQ với đoạn văn có thể cuộn)
- **Khi** học sinh chọn nút radio MCQ
- **Sau đó** hệ thống ngay lập tức lưu lại câu trả lời cho máy chủ (FR-105) và đánh dấu dấu chấm câu hỏi trong bảng điều hướng bằng dấu kiểm
- **Và** học sinh có thể di chuyển tự do giữa các câu hỏi trong phần Đọc hiện tại; các câu trả lời đã chọn trước đó được khôi phục từ trạng thái máy chủ khi điều hướng
- **Và** học sinh không thể quay lại phần Đọc đã hoàn thành
- **Và** thứ tự câu hỏi trong mỗi phần được xáo trộn theo hạt giống bài thi (FR-93); thứ tự xáo trộn tương tự được khôi phục trong sơ yếu lý lịch (FR-106)

---

#### FR-21 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ hiển thị các phần Viết với vùng nhập văn bản phù hợp và hiển thị số từ trực tiếp; chỉ báo đếm từ sẽ thay đổi màu sắc dựa trên mức độ gần với giới hạn từ tối thiểu và tối đa đã được định cấu hình.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Học sinh |
| Điều kiện tiên quyết | Học sinh đang ở kỹ năng Viết của một kỳ thi tích cực |
| Cò súng | Các loại học sinh trong vùng văn bản Viết |
| Nguồn | F-03; UI-09 (Giao diện viết); FR-105 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một học sinh đang viết Phần C (bài luận) với phạm vi từ được định cấu hình (ví dụ: 150–180 từ)
- **Khi** học sinh gõ vào vùng văn bản
- **Sau đó** số từ trực tiếp cập nhật theo thời gian thực (trên mỗi lần nhấn phím) được hiển thị bên dưới vùng văn bản
- **Và** khi số lượng dưới 80% mục tiêu tối thiểu: màu chỉ báo là màu xám; khi số lượng nằm trong phạm vi hợp lệ: chỉ báo màu xanh lá cây; khi số lượng vượt quá mức tối đa: đèn báo màu đỏ
- **Và** học sinh vẫn có thể gửi câu trả lời vượt quá mức tối đa (không có khối cứng); giáo viên có thể nhìn thấy độ dài quá mức trong quá trình ôn tập
- **Và** Văn bản viết được lưu vào máy chủ cứ sau 1 giây sau lần nhấn phím cuối cùng (FR-105)
- **Và** Phần A hiển thị 5 trường văn bản cấp độ câu riêng lẻ; Phần B hiển thị một vùng văn bản cho phản hồi email/tin nhắn

---

#### FR-22 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ tự động phát âm thanh Nghe khi học sinh nhập từng câu hỏi Nghe; học sinh sẽ không thể tìm kiếm, tua lại hoặc phát lại ngoài `max_play_count` đã được định cấu hình; các câu hỏi sẽ được trả lời đồng thời với việc phát lại âm thanh.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Học sinh |
| điều kiện tiên quyết | Học sinh đang ở kỹ năng Nghe; tệp âm thanh có thể truy cập được qua URL CDN |
| Cò súng | Học sinh nhập câu hỏi Nghe có nội dung âm thanh liên quan |
| Nguồn | F-03; FR-10; UI-09; HW-02 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một học sinh chuyển đến câu hỏi Phần Nghe Phần B với `max_play_count = 1`
- **Khi** câu hỏi hiển thị
- **Sau đó** âm thanh bắt đầu phát tự động; trình phát hiển thị thanh tiến trình chỉ đọc (điều khiển tìm kiếm không có hoặc bị tắt)
- **Và** chỉ báo số lần phát hiển thị "Phát 1 trên 1"; sau khi âm thanh kết thúc, nút Phát bị tắt và chỉ báo hiển thị "còn lại 0 lượt phát"
- **Và** học sinh có thể trả lời các câu hỏi MCQ hoặc điền vào biểu mẫu bất kỳ lúc nào trong hoặc sau khi phát lại âm thanh
- **Và** nếu yêu cầu âm thanh CDN không thành công (HTTP 5xx hoặc hết thời gian chờ), hệ thống sẽ thử lại tối đa 3 lần với độ trễ 2 giây; nếu tất cả các lần thử lại đều không thành công, một thông báo lỗi sẽ hiển thị và Điều phối viên bài thi sẽ được thông báo qua màn hình trực tiếp (FR-39)

---

#### FR-23 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ triển khai trình tự Nói gồm 5 giai đoạn cho mỗi phần: hiển thị hướng dẫn/hình ảnh, đếm ngược chuẩn bị, ghi bằng dạng sóng trực tiếp, tự động dừng khi giới hạn thời gian ghi và tải lên kèm theo chỉ báo tiến trình; âm thanh sẽ được lưu vào bộ đệm cục bộ và tải lên Cloud Storage.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Học sinh |
| điều kiện tiên quyết | Học sinh đang ở kỹ năng Nói; quyền sử dụng micrô đã được cấp (FR-18) |
| Cò súng | Học sinh bước vào phần Nói sau khi hết thời gian chuẩn bị |
| Nguồn | F-03; F-13; HW-01; SI-01; FR-108 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một học sinh đang ở Phần Nói A và thời gian chuẩn bị đã kết thúc
- **Khi** giai đoạn ghi hình bắt đầu
- **Sau đó** hệ thống bắt đầu ghi thông qua API micrô nền tảng; trực quan hóa dạng sóng trực tiếp hiển thị trong thời gian thực hiển thị biên độ âm thanh
- **Và** khi đạt đến giới hạn thời gian ghi được ủy quyền của máy chủ (logic FR-19), quá trình ghi sẽ tự động dừng; học sinh không thể kéo dài thời gian ghi phía máy khách
- **Và** âm thanh được lưu vào bộ đệm cục bộ (IndexedDB cho web, hệ thống tệp nền tảng cho máy tính để bàn) và được tải lên Cloud Storage (FR-108); học sinh nhìn thấy thanh tiến trình tải lên
- **Và** sau khi tải lên thành công, học sinh sẽ tự động được chuyển sang phần Nói tiếp theo
- **Và** nếu quá trình tải lên không thành công, bộ đệm cục bộ sẽ được giữ lại và được đánh dấu `pending_upload`; học sinh tiếp tục phần tiếp theo mà không bị chặn

---

#### FR-24 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ hiển thị màn hình chuyển tiếp giữa các phần thi hiển thị phần đã hoàn thành, phần tiếp theo, thời gian cho phép làm phần tiếp theo và đồng hồ đếm ngược để tự động chuyển tiếp; điều hướng quay lại phần hoàn thành bị chặn.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Học sinh |
| Điều kiện tiên quyết | Một học sinh vừa hoàn thành một phần (bằng cách trả lời tất cả các câu hỏi hoặc hết thời gian của máy chủ) |
| Cò súng | Sự kiện hoàn thành một phần |
| Nguồn | F-03; UI-09 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một học sinh đã hoàn thành phần Đọc A
- **Khi** hệ thống chuyển sang Đọc Phần B
- **Sau đó** màn hình chuyển tiếp hiển thị: "Đọc xong Phần A. Đọc Phần B bắt đầu sau [N] giây" kèm theo đồng hồ đếm ngược
- **Và** sau khi đồng hồ đếm ngược về 0, phần tiếp theo sẽ tự động bắt đầu; học sinh không thể kích hoạt bắt đầu sớm
- **Và** nút "Quay lại" không có trên màn hình chuyển tiếp; điều hướng quay lại trình duyệt bị chặn (FR-99)
- **Và** tiến độ làm bài tổng thể của học sinh được hiển thị (ví dụ: "Đọc xong 1/4 phần")

---

#### FR-25 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ sắp xếp các kỹ năng thi theo thứ tự được xác định trong mẫu đề thi (mặc định: Đọc → Nghe → Viết → Nói); ngắt giữa các kỹ năng sẽ được cấu hình theo mẫu; bộ đếm thời gian kỹ năng tiếp theo sẽ không bắt đầu cho đến khi hết thời gian đếm ngược.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Sinh viên (thụ động); Hệ thống (thực thi hẹn giờ) |
| điều kiện tiên quyết | Học sinh đã hoàn thành tất cả các phần của một kỹ năng |
| Cò súng | Học sinh hoàn thành phần cuối cùng của kỹ năng |
| Nguồn | F-03; A-02 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một học sinh đã hoàn thành cả bốn phần Đọc
- **Khi** hệ thống chuyển sang kỹ năng Nghe
- **Sau đó** màn hình nghỉ giữa các kỹ năng hiển thị đếm ngược thời gian nghỉ; bộ đếm thời gian Nghe không bắt đầu cho đến khi đồng hồ đếm ngược về 0
- **Và** học viên không thể bỏ qua giờ giải lao hoặc bắt đầu kỹ năng tiếp theo sớm
- **Và** nếu `break_duration = 0` đối với mẫu, quá trình chuyển đổi sẽ diễn ra ngay lập tức mà không có màn hình ngắt
- **Và** tất cả bốn kỹ năng phải được hoàn thành theo thứ tự do mẫu xác định; bài kiểm tra không thể được gửi cho đến khi đạt được tất cả các kỹ năng (ngoại trừ buộc phải nộp FR-41 hoặc hết hạn hẹn giờ FR-19)

---

#### FR-26 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ kết thúc bài thi khi tất cả các kỹ năng đã được hoàn thành hoặc khi thời gian phiên làm việc đóng lại; quá trình hoàn thiện sẽ duy trì tất cả các câu trả lời còn lại, đặt `attempt.status = submit` và kích hoạt quy trình tính điểm.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Sinh viên (hoàn thành tự nhiên); Hệ thống (tự động đóng phiên hoặc hết giờ) |
| điều kiện tiên quyết | Tất cả các phần thi đã hoàn thành hoặc `current_time > session.end_time` |
| Cò súng | Học viên hoàn thành kỹ năng cuối cùng; hoặc cửa sổ phiên đóng lại khi một nỗ lực đang diễn ra |
| Nguồn | F-03; F-04 (chấm điểm); FR-27; FR-30; FR-31 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một học sinh hoàn thành phần Nói cuối cùng
- **Khi** việc gửi được xử lý
- **Sau đó** hệ thống đặt `exam_attempt.status = submit` và `exam_attempt.submit_at = current_server_time`
- **Và** tất cả các câu trả lời liên tục tại thời điểm gửi đều được hoàn thiện; không chấp nhận viết thêm câu trả lời nào (HTTP 409)
- **Và** quy trình chấm điểm tự động được kích hoạt cho phần Đọc và Nghe (FR-27)
- **Và** quy trình chấm điểm AI được xếp hàng cho phần Viết và Nói (FR-30, FR-31)
- **Và** học sinh được chuyển hướng đến màn hình kết quả: Phần Đọc và Nghe hiển thị trong vòng 2 phút (FR-29); Tiết mục Viết và Nói “Đang chờ giáo viên xét duyệt”

---

## F-04: Hệ thống tính điểm (FR-27 – FR-36)

---

#### FR-27 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ tự động tính điểm Đọc và Nghe ngay sau khi nộp bài thi bằng cách so sánh câu trả lời của từng học sinh với đáp án đã lưu.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Hệ thống (công việc chấm điểm tự động) |
| Điều kiện tiên quyết | `exam_attempt.status = đã gửi`; Có đáp án Đọc và Nghe trong `exam_answers` |
| Cò súng | Sự kiện nộp bài thi (FR-26) |
| Nguồn | F-04; FR-26 |

**Tiêu chí chấp nhận (GWT):**
- **Đã cho** một bài thi đã được gửi với câu trả lời Đọc và Nghe
- **Khi** công việc tính điểm tự động chạy (trong vòng 2 phút sau khi gửi)
- **Sau đó** đối với mỗi câu trả lời Đọc và Nghe: hệ thống so sánh `student_answer` với `question.answer_key`; ghi lại `is_true (0 hoặc 1)` trong `exam_answers`
- **Và** tính `raw_score` mỗi phần dưới dạng tổng các câu trả lời đúng
- **Và** kích hoạt tính toán băng tần (FR-28) sau khi hoàn thành
- **Và** công việc không có tác dụng gì: việc chạy lại nó trên một nỗ lực đã được ghi điểm sẽ không làm thay đổi điểm số

---

#### FR-28 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ chuyển đổi điểm thô cho phần Đọc và Nghe thành các cấp độ APTIS (A1, A2, B1, B2, C) bằng cách sử dụng bảng ánh xạ băng tần do Nhà cung cấp cấu hình; điểm ngoài phạm vi sẽ được gắn cờ là `MAPPING_ERROR`.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Hệ thống (tự động) |
| điều kiện tiên quyết | Điểm thô cho phần Đọc và Nghe đã được tính toán (FR-27) |
| Cò súng | Tự động chấm điểm hoàn thành công việc |
| Nguồn | F-04; A-10 (bảng ánh xạ băng tần do Nhà cung cấp cung cấp); FR-27 |

**Tiêu chí chấp nhận (GWT):**
- **Đã cho** Đọc raw_score = 18
- **Khi** tính toán băng tần chạy theo bảng ánh xạ băng tần đã định cấu hình (ví dụ: Đọc 18–22 → B1)
- **Sau đó** `attempt_results.reading_band = "B1"` và `attempt_results.reading_score = 18`
- **Và** nếu điểm thô nằm trong phạm vi không nằm trong bất kỳ mục ánh xạ nào, hệ thống sẽ gắn cờ `reading_band = "MAPPING_ERROR"` và tạo cảnh báo để Nhà cung cấp xem xét
- **Và** kết quả tính toán băng tần được lưu trữ trong bảng `attempt_results` với dấu thời gian `scored_at`
- **Và** kết quả ban nhạc hiển thị ngay trên màn hình kết quả của học sinh (FR-29)

---

#### FR-29 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cung cấp kết quả điểm Đọc và Nghe cho học sinh trong vòng 2 phút sau khi hoàn thành bài thi.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Hệ thống (tự động); Sinh viên (người tiêu dùng) |
| Điều kiện tiên quyết | Tự động tính điểm (FR-27) và tính điểm (FR-28) đã hoàn thành |
| Cò súng | Hoàn thành công việc tính toán băng tần |
| Nguồn | F-04; NFR-09 (độ trễ đường ống tính điểm) |

**Tiêu chí chấp nhận (GWT):**
- **Đã cho** tính năng tự động chấm điểm và tính điểm cho phần Đọc và Nghe đã hoàn thành
- **Khi** học sinh xem màn hình kết quả
- **Sau đó** Điểm và điểm Đọc và Nghe sẽ được hiển thị trong vòng 2 phút kể từ dấu thời gian gửi
- **Và** `attempt_results.status_reading = "available"` và `attempt_results.status_listening = "available"` được đặt
- **Và** hệ thống gửi thông báo qua email cho học sinh (FR-83: trigger "Có kết quả Đọc/Nghe")

---

#### FR-30 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ gửi từng bản ghi âm Bài phát biểu tới API STT đã định cấu hình và lưu trữ bản ghi kết quả cho mỗi phần; đối với lỗi API vĩnh viễn sau 3 lần thử lại, phần này sẽ được gắn cờ `STT_FAILED` để giáo viên xem xét thủ công.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Hệ thống (đường dẫn tính điểm AI) |
| điều kiện tiên quyết | Các tệp âm thanh nói đã được tải lên Cloud Storage; `exam_attempt.status = đã gửi` |
| Cò súng | Công việc quy trình chấm điểm AI, được xếp hàng bởi FR-26 |
| Nguồn | F-04; SI-04 (API STT); OI-02 |

**Tiêu chí chấp nhận (GWT):**
- **Được cung cấp** một bài thi đã nộp có chứa âm thanh Nói cho Phần A–E
- **Khi** công việc quy trình chấm điểm AI chạy
- **Sau đó** đối với mỗi tệp âm thanh Phần Nói, hệ thống sẽ gọi API STT đã định cấu hình bằng URL âm thanh Cloud Storage
- **Và** văn bản bản chép lại được trả về được lưu trữ trong `speak_transcripts` với `attempt_id` và `part` tương ứng
- **Và** nếu lệnh gọi API STT không thành công, hệ thống sẽ thử lại tối đa 3 lần với thời gian chờ theo cấp số nhân (độ trễ: 5 giây, 15 giây, 45 giây)
- **Và** nếu cả 3 lần thử lại đều không thành công, `say_transcripts.status = "STT_FAILED"` được đặt cho phần đó và Giáo viên được phân công sẽ được thông báo để xem lại bản ghi âm theo cách thủ công
- **Và** quy trình tiến tới FR-31 cho tất cả các phần sao chép thành công

---

#### FR-31 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ gửi bản ghi câu trả lời bằng văn bản Viết và phần Nói tới API LLM đã được định cấu hình với lời nhắc thang đánh giá APTIS; điểm nháp kết quả sẽ được lưu trữ với `trạng thái = bản nháp` và sẽ không được hiển thị cho học sinh cho đến khi giáo viên xác nhận.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Hệ thống (đường dẫn tính điểm AI) |
| điều kiện tiên quyết | Viết câu trả lời bằng văn bản trong `exam_answers`; Bản ghi bài nói nằm trong `bản ghi_nói` (FR-30) |
| Cò súng | Công việc quy trình chấm điểm AI; tuân theo FR-30 cho phần Nói |
| Nguồn | F-04; SI-05 (API LLM); BR-13 (Bản nháp AI không được hiển thị cho đến khi giáo viên xác nhận); OI-02 |

**Tiêu chí chấp nhận (GWT):**
- **Đã cho** Văn bản Viết Phần C và Bản ghi Phần Nói Phần B có sẵn để bạn thử
- **Khi** công việc tính điểm LLM chạy
- **Sau đó** đối với mỗi phần Viết và Nói, hệ thống sẽ xây dựng một lời nhắc bao gồm: câu trả lời của học sinh, tiêu chí thang đánh giá APTIS cho phần đó và hướng dẫn chấm điểm; gửi lời nhắc tới API LLM
- **Và** phản hồi LLM `{"criterion_scores": {...}, "band_estimate": "B1", "feedback_narrative": "..."}` được lưu trữ trong `ai_score_drafts` với `status = Draft`
- **Và** `attempt_results.status_writing` và `attempt_results.status_peaking` vẫn ở trạng thái `pending_review`; Màn hình kết quả của học sinh hiển thị "Đang chờ giáo viên xem xét"
- **Và** hệ thống thông báo cho Giáo viên được phân công qua email (FR-83: trigger "Viết/Nói đang chờ đánh giá")
- **Và** nhà cung cấp LLM có thể được chuyển đổi thông qua thay đổi cấu hình mà không cần thay đổi mã (yêu cầu chuyển đổi nhà cung cấp SI-05)

---

#### FR-32 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ hiển thị cho Giáo viên một hàng bài nộp Viết và Nói đang chờ con người đánh giá, được sắp xếp theo thời gian nộp (cũ nhất xếp trước), hiển thị phản hồi của học sinh, điểm dự thảo AI và tường thuật phản hồi.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Giáo viên |
| điều kiện tiên quyết | Điểm dự thảo AI tồn tại trong `ai_score_drafts` với `status = bản nháp` dành cho học sinh lớp Giáo viên |
| Cò súng | Giáo viên mở hàng chấm điểm |
| Nguồn | F-04; UI-06 (Hàng đợi chấm điểm của giáo viên) |

**Tiêu chí chấp nhận (GWT):**
- **Đã cho** Điểm dự thảo AI tồn tại cho bài nộp Viết/Nói của học sinh trong các lớp do Giáo viên chỉ định
- **Khi** Giáo viên mở hàng chấm điểm
- **Sau đó** hệ thống hiển thị tất cả các mục đang chờ xử lý trong phạm vi lớp của Giáo viên, được sắp xếp theo `submit_at` tăng dần (cũ nhất xếp trước)
- **Và** mỗi mục trong hàng đợi hiển thị: tên sinh viên, ngày thi, kỹ năng, phần, câu trả lời của sinh viên (văn bản cho phần Viết; bảng điểm cho phần Nói), điểm dự thảo AI cho mỗi tiêu chí thang đánh giá, ước tính điểm AI, tường thuật phản hồi AI
- **Và** huy hiệu đếm trên biểu tượng điều hướng hiển thị tổng số mục đang chờ xử lý
- **Và** Giáo viên có thể nhấp vào bất kỳ mục nào để mở màn hình ôn tập (FR-33)

---

#### FR-33 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cho phép Giáo viên xác nhận nguyên trạng điểm dự thảo AI hoặc ghi đè điểm tiêu chí riêng lẻ và tường thuật phản hồi; sau khi được xác nhận, điểm số sẽ được tổng hợp và cung cấp cho học sinh.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Giáo viên |
| Điều kiện tiên quyết | Điểm dự thảo tồn tại cho bài viết Viết hoặc Nói |
| Cò súng | Giáo viên nhấn Xác nhận trên màn hình chấm điểm |
| Nguồn | F-04; BR-13; UI-06 |

**Tiêu chí chấp nhận (GWT):**
- **Đưa ra** Giáo viên đang xem xét điểm dự thảo AI kèm theo điểm tiêu chí và nội dung phản hồi
- **Khi** Giáo viên (tùy ý chỉnh sửa điểm tiêu chí hoặc phản hồi) và nhấp vào Xác nhận
- **Sau đó** hệ thống tạo một bản ghi `điểm_cuối cùng` với: `confirmed_by = Teacher_id`, `confirmed_at = now()`, `final_score_per_criterion`, `final_band`, `final_feedback_narrative`
- **Và** `attempt_results.status_writing` hoặc `attempt_results.status_peaking` được đặt thành `available`
- **Và** học sinh nhận được thông báo qua email (FR-83: "Có kết quả Viết/Nói")
- **Và** mục đã được xác nhận sẽ bị xóa khỏi hàng đợi chờ xử lý của Giáo viên
- **Và** điều hướng khỏi màn hình xem lại mà không nhấp vào Xác nhận sẽ kích hoạt thông báo "Rời khỏi mà không lưu?" hộp thoại (điểm KHÔNG được lưu tự động trên điều hướng)

---

#### FR-34 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ hiển thị bảng điều khiển kết quả cá nhân cho mỗi học sinh hiển thị tất cả các lần thử trước đây với các mức độ theo kỹ năng, biểu đồ tiến trình và phân tích cấp độ từng phần cho mỗi lần thử đã hoàn thành.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Học sinh |
| điều kiện tiên quyết | Học sinh đã nộp ít nhất một bài thi |
| Cò súng | Học sinh điều hướng đến phần kết quả của họ |
| Nguồn | F-04; UI-09 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một học sinh điều hướng đến phần kết quả của họ
- **Khi** trang kết quả tải
- **Sau đó** hệ thống hiển thị danh sách tất cả các bài thi được sắp xếp theo thứ tự `submit_at` giảm dần, với các cột: Ngày, Tên buổi thi, Nhóm đọc, Nhóm nghe, Nhóm viết, Nhóm nói
- **Và** các kỹ năng chưa được tính điểm hiển thị "Đang chờ xử lý" trong cột liên quan
- **Và** nhấp vào hàng lần thử sẽ mở màn hình chi tiết lần thử (phân tích phần FR-54)
- **Và** biểu đồ tiến trình (FR-53) được hiển thị phía trên danh sách nếu học sinh có ≥ 2 lần ghi điểm

---

#### FR-35 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ hiển thị bản tóm tắt hồ sơ nhóm bốn kỹ năng (các nhóm Đọc, Viết, Nghe, Nói) cho bất kỳ bài thi nào được ghi điểm đầy đủ, với mỗi nhóm được hiển thị cùng với phần mô tả phù hợp với CEFR.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Học sinh; Giáo viên (khi xem nỗ lực của học sinh) |
| Điều kiện tiên quyết | Tất cả bốn kỹ năng của một lần thử đều được tính điểm và `trạng thái = khả dụng` |
| Cò súng | Học sinh hoặc Giáo viên mở màn hình tóm tắt bài làm |
| Nguồn | F-04; UI-09; DC-11 (yêu cầu từ chối trách nhiệm) |

**Tiêu chí chấp nhận (GWT):**
- **Cho** tất cả bốn kỹ năng của một lần thử đều có `trạng thái = có sẵn` trong `attempt_results`
- **Khi** bản tóm tắt lần thử được xem
- **Sau đó** hệ thống hiển thị bốn bảng (mỗi bảng cho mỗi kỹ năng), mỗi bảng hiển thị: tên kỹ năng, cấp độ (A1/A2/B1/B2/C) nổi bật và một phần mô tả CEFR ngắn gọn (ví dụ: "B1 — Có thể hiểu các điểm chính của thông tin đầu vào tiêu chuẩn rõ ràng về các vấn đề quen thuộc")
- **Và** tuyên bố từ chối trách nhiệm được hiển thị: "Điểm này là kết quả mô phỏng và không cấu thành kết quả APTIS chính thức từ Hội đồng Anh" (DC-11)

---

#### FR-36 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ hiển thị tường thuật phản hồi đã được giáo viên xác nhận về phần Viết và Nói cho học sinh, có thể truy cập được từ màn hình chi tiết bài thi, sau khi tổng điểm.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Học sinh |
| Điều kiện tiên quyết | Giáo viên đã xác nhận điểm Viết/Nói (FR-33); `attempt_results.status = có sẵn` |
| Cò súng | Học sinh xem chi tiết bài thi bao gồm các kết quả Viết/Nói đã được xác nhận |
| Nguồn | F-04; UI-09 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** Giáo viên đã xác nhận điểm cho Phần Viết C và Phần Nói A–E
- **Khi** học sinh xem chi tiết bài thi
- **Sau đó** hệ thống hiển thị phần tường thuật phản hồi cho từng phần được xác nhận, bao gồm: điểm tiêu chí thang đánh giá, điểm tổng thể và văn bản tường thuật (do Giáo viên nhập/chỉnh sửa)
- **Và** phần phản hồi chưa được xác nhận hiển thị: "Kết quả đang chờ giáo viên xem xét"
- **Và** phản hồi được hiển thị bằng ngôn ngữ viết (tiếng Việt hoặc tiếng Anh) mà không cần dịch

---

## F-05: Lên lịch và triển khai bài kiểm tra (FR-37 – FR-43)

---

#### FR-37 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cho phép Giáo viên và Điều phối viên bài kiểm tra tạo các buổi thi bằng cách chỉ định tên phiên, mẫu bài kiểm tra, phạm vi người tham gia, cửa sổ ngày giờ mở/đóng và cấu hình chống gian lận.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Giáo viên; Điều phối viên thi |
| Điều kiện tiên quyết | Tồn tại ít nhất một mẫu bài thi đã xuất bản; khóa học dành cho người dùng diễn xuất đã ghi danh học viên |
| Cò súng | Giáo viên hoặc Điều phối viên thi nộp biểu mẫu tạo phiên |
| Nguồn | F-05; BR-08; FR-38 |

**Tiêu chí chấp nhận (GWT):**
- **Được cho** Giáo viên mở biểu mẫu tạo phiên thi
- **Khi** biểu mẫu được gửi với tất cả các trường bắt buộc
- **Sau đó** hệ thống tạo một bản ghi `exam_session` với `status = đã lên lịch`; các sinh viên được chọn được liên kết với tư cách là người tham gia đủ điều kiện
- **Và** cấu hình chống gian lận được lưu trữ: `shuffle_enabled`, `warning_threshold`, `terminate_threshold`
- **Và** phiên này hiển thị trên danh sách Bài kiểm tra của tôi của sinh viên đủ điều kiện nhưng không thể tham gia cho đến `session.start_time`
- **Và** một email thông báo được xếp hàng ngay lập tức cho tất cả người tham gia (FR-38)
- **Và** `session.start_time` phải ở trong tương lai; `session.end_time` phải sau `session.start_time`; xác thực trả về HTTP 422 cho phạm vi ngày giờ không hợp lệ

---

#### FR-38 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ tự động gửi thông báo qua email đến tất cả học viên đã đăng ký khi có buổi thi và vào lúc T−24h và T−1h trước khi buổi thi khai mạc.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Hệ thống (lập lịch thông báo) |
| Điều kiện tiên quyết | Một buổi thi đã được tạo (FR-37) với những người tham gia đủ điều kiện |
| Cò súng | Tạo phiên (ngay lập tức); công việc theo lịch trình lúc T−24h và T−1h |
| Nguồn | F-05; F-10 (thông báo); FR-83 |

**Tiêu chí chấp nhận (GWT):**
- **Đã cho** một buổi thi được lưu với những người tham gia đủ điều kiện
- **Khi** phiên được tạo
- **Sau đó** thông báo qua email ngay lập tức được đưa vào hàng đợi cho tất cả người tham gia bao gồm: tên phiên, ngày/giờ, thời lượng, liên kết cổng thông tin
- **Và** các công việc đã lên lịch sẽ thực hiện vào đúng T−24h và T−1h (dung sai ±5 phút) để gửi email nhắc nhở
- **Và** nếu một học sinh được thêm vào phiên sau khi tạo, họ sẽ nhận được thông báo tạo ngay lập tức; lời nhắc T−24h/T−1h áp dụng cho tất cả những người tham gia hiện tại tại thời điểm gửi
- **Và** mỗi lần thông báo đều được ghi vào `notification_log` (FR-87)

---

#### FR-39 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cung cấp cho Điều phối viên bài kiểm tra một bảng điều khiển thời gian thực hiển thị trạng thái của mỗi học sinh trong một buổi thi đang diễn ra, được cập nhật qua WebSocket hoặc SSE mà không cần tải lại trang.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Điều phối viên thi |
| điều kiện tiên quyết | Một phiên thi đang diễn ra (current_time trong cửa sổ phiên); ít nhất một học sinh đang thực hiện |
| Cò súng | Điều phối viên mở bảng điều khiển màn hình trực tiếp |
| Nguồn | F-05; CI-02 (WebSocket/SSE); UI-07 |

**Tiêu chí chấp nhận (GWT):**
- **Đưa** Điều phối viên bài kiểm tra sẽ mở bảng điều khiển màn hình trực tiếp cho một phiên hoạt động
- **Khi** trang tổng quan tải và trong suốt thời gian tồn tại của trang tổng quan
- **Sau đó** hệ thống thiết lập kết nối WebSocket (hoặc dự phòng SSE) và đẩy các sự kiện theo thời gian thực: `student.started`, `student.progress`, `student.disconnected`, `student.reconnected`, `student.submit`, `student.violation`
- **Và** bảng tổng quan có một hàng cho mỗi học sinh đã đăng ký hiển thị: tên, trạng thái (Chưa bắt đầu / Đang tiến hành [kỹ năng hiện tại - phần] / Đã ngắt kết nối [N phút trước] / Đã gửi), huy hiệu số lượng vi phạm, thời gian còn lại
- **Và** Những học sinh bị ngắt kết nối được đánh dấu bằng màu hổ phách; học sinh bị chấm dứt theo ngưỡng vi phạm được đánh dấu màu đỏ
- **Và** bảng cập nhật mà không cần tải lại trang; điều phối viên không cần phải làm mới thủ công

---

#### FR-40 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cho phép Điều phối viên thi kéo dài thời gian còn lại cho bài thi của một học sinh cụ thể; phần mở rộng phải được ghi lại với trường lý do bắt buộc.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Điều phối viên thi |
| điều kiện tiên quyết | Học sinh mục tiêu có nỗ lực `in_progress`; phiên đang hoạt động |
| Cò súng | Điều phối viên nộp đơn xin gia hạn thời gian cho sinh viên |
| Nguồn | F-05; UI-07 |

**Tiêu chí chấp nhận (GWT):**
- **Được** Điều phối viên Kỳ thi xác định một học sinh cần thêm thời gian
- **Khi** Điều phối viên nhập gia hạn_phút và lý do không trống rồi xác nhận
- **Sau đó** máy chủ cập nhật `part_end_time` của học sinh (và `session_end_time` nếu nằm trong phần hiện tại) bằng cách thêm phần mở rộng
- **Và** ứng dụng khách của học sinh phản ánh `time_remaining` đã cập nhật trong lần đồng bộ hóa tiếp theo (≤ 10 giây)
- **Và** sự kiện được ghi vào `exam_events`: `{codinator_id, sinh viên_id, session_id, tiện ích_phút, lý do, dấu thời gian}`
- **Và** việc gửi biểu mẫu gia hạn có trường lý do trống bị từ chối: `"Lý do là bắt buộc"`

---

#### FR-41 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cho phép Điều phối viên thi buộc học sinh phải nộp bài thi, hoàn thành bài thi đó với tất cả các câu trả lời hiện có và lý do bắt buộc được ghi lại.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Điều phối viên thi |
| điều kiện tiên quyết | Học sinh mục tiêu có một nỗ lực `in_progress` |
| Cò súng | Điều phối viên xác nhận việc cưỡng chế học sinh có lý do |
| Nguồn | F-05; F-13 |

**Tiêu chí chấp nhận (GWT):**
- **Đưa ra** Điều phối viên kỳ thi xác nhận việc buộc nộp hồ sơ đối với học sinh S với lý do không trống
- **Khi** việc buộc gửi được xử lý
- **Sau đó** máy chủ đặt `exam_attempt.status = submit`, `submit_at = now()`, `force_submit_by = coctor_id`, `force_submit_reason = Reason`
- **Và** quy trình tính điểm được kích hoạt giống hệt với FR-26
- **Và** nếu học sinh đang ghi âm giữa chừng, hệ thống sẽ cắt bản ghi ở vị trí hiện tại và tải lên một phần âm thanh được gắn cờ là `partial_recording = true` (FR-109)
- **Và** gửi mà không có lý do sẽ trả về HTTP 422: `"cần có lý do để buộc gửi"`

---

#### FR-42 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cho phép Điều phối viên kết thúc buổi thi trước khi kết thúc theo lịch; những học sinh tích cực sẽ nhận được cảnh báo trong thời gian gia hạn trước khi nỗ lực của họ bị buộc phải nộp.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Điều phối viên thi |
| điều kiện tiên quyết | Một phiên thi đang hoạt động với trạng thái `in_progress` |
| Cò súng | Điều phối viên xác nhận "Đóng phiên sớm" kèm lý do và thời gian ân hạn |
| Nguồn | F-05; UI-07 |

**Tiêu chí chấp nhận (GWT):**
- **Đưa ra** Điều phối viên xác nhận phiên kết thúc có thời gian ân hạn = 5 phút và lý do
- **Khi** quá trình đóng được bắt đầu
- **Sau đó** `session.status` được đặt thành `đóng`; tất cả học viên đã đăng ký `đang tiến bộ` sẽ nhận được biểu ngữ trong kỳ thi: "Buổi thi sẽ kết thúc sau 5 phút nữa - vui lòng gửi bài kiểm tra của bạn ngay bây giờ"
- **Và** sau thời gian gia hạn, tất cả các lần thử `in_progress` còn lại đều bị buộc gửi (logic FR-41) với `force_submit_reason = "Phiên được điều phối viên đóng sớm"`
- **Và** `session.status` được đặt thành `closed`
- **Và** những sinh viên đã nộp bài sẽ không bị ảnh hưởng

---

#### FR-43 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cho phép Giáo viên và Điều phối viên thi phê duyệt yêu cầu thi lại của học sinh, tạo ra một bài thi mới cho học sinh đã được phê duyệt.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Giáo viên; Điều phối viên thi |
| Điều kiện tiên quyết | Học sinh có ít nhất một lần nộp bài dự thi trong buổi học; cửa sổ phiên vẫn mở hoặc Điều phối viên mở khóa nó một cách rõ ràng |
| Cò súng | Giáo viên hoặc Điều phối viên phê duyệt việc học lại cho học sinh |
| Nguồn | F-05; BR-07 (việc thi lại cần có sự phê duyệt rõ ràng) |

**Tiêu chí chấp nhận (GWT):**
- **Cho** Điều phối viên phê duyệt việc thi lại cho học sinh S trong phiên X
- **Khi** quá trình phê duyệt được xử lý
- **Sau đó** một bản ghi `exam_attempt` mới được tạo cho sinh viên S trong phiên X với `status = not_started` và `attempt_number = 2`
- **Và** lần thi lại được ghi lại: `{requester_id, người phê duyệt_id, số lần thử, lý do, dấu thời gian}`
- **Và** lần thử ban đầu (số_số lần thử = 1) được giữ nguyên và không thay đổi
- **Và** bây giờ sinh viên có thể tham gia lại phiên học (tùy thuộc vào cửa sổ phiên học đang mở)

---

## F-06: Quản lý người học (FR-44 – FR-51)

---

#### FR-44 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cho phép Quản trị viên đối tượng thuê tạo các khóa học có tên, mô tả, ngày bắt đầu và ngày kết thúc; học sinh chỉ có thể tham gia các buổi thi trong khung ngày hoạt động của khóa học.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Quản trị viên thuê nhà |
| điều kiện tiên quyết | Quản trị viên thuê nhà được xác thực |
| Cò súng | Quản trị viên thuê nộp mẫu tạo khóa học |
| Nguồn | F-06; BR-09 (phạm vi ngày khóa học) |

**Tiêu chí chấp nhận (GWT):**
- **Được tặng** Quản trị viên người thuê mở biểu mẫu tạo khóa học
- **Khi** biểu mẫu được gửi cùng với tên, mô tả, ngày bắt đầu và ngày kết thúc
- **Sau đó** một bản ghi khóa học được tạo với: `trạng thái = đã lên lịch` (trước ngày bắt đầu), `hoạt động` (giữa các ngày) hoặc `đã kết thúc` (sau ngày_kết thúc)
- **Và** các buổi thi chỉ có thể được tạo trong khóa học `hoạt động`
- **Và** những sinh viên đã đăng ký khóa học đã kết thúc không thể bắt đầu những lần thử mới trong khóa học đó; cố gắng tham gia một phiên trong khóa học đã kết thúc sẽ trả về HTTP 403: `"Khóa học này đã kết thúc"`
- **Và** `ngày_kết thúc` phải sau `ngày_bắt đầu`; xác thực trả về HTTP 422 nếu không

---

#### FR-45 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cho phép Quản trị viên đối tượng thuê tạo các nhóm (lớp) được đặt tên trong một khóa học và phân công Giáo viên cho các nhóm cụ thể; Giáo viên chỉ có thể xem và quản lý học sinh trong nhóm được phân công.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Quản trị viên thuê nhà |
| điều kiện tiên quyết | Một khóa học tồn tại |
| Cò súng | Quản trị viên thuê tạo nhóm và chỉ định Giáo viên |
| Nguồn | F-06; BR-03 (Phạm vi giáo viên = nhóm được chỉ định) |

**Tiêu chí chấp nhận (GWT):**
- **Được** Quản trị viên thuê tạo nhóm "Lớp 10A" trong khóa C và phân công Giáo viên T
- **Khi** Thầy T đăng nhập
- **Sau đó** Danh sách học sinh, hàng chấm điểm và chế độ xem phân tích của Thầy T chỉ hiển thị học sinh đăng ký "Lớp 10A"
- **Và** Giáo viên T không thể xem hoặc quản lý học sinh trong các nhóm không được phân công
- **Và** Vai trò Quản trị viên và Người xem của đối tượng thuê có thể xem tất cả các nhóm trên tất cả các khóa học trong đối tượng thuê của họ

---

#### FR-46 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cho phép Quản trị viên và Giáo viên của Người thuê thêm từng học sinh vào nhóm khóa học qua email; nếu email không tồn tại, hệ thống sẽ tạo tài khoản sinh viên mới với mật khẩu được tạo tự động; việc tuyển sinh sẽ bị chặn ở giới hạn chỉ tiêu chỗ ngồi.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Quản trị viên thuê nhà; Giáo viên |
| Điều kiện tiên quyết | Một nhóm lớp tồn tại; hạn ngạch chỗ ngồi không ở mức 100% |
| Cò súng | Quản trị viên hoặc Giáo viên nộp đơn đăng ký học một học sinh |
| Nguồn | F-06; BR-05 (thực thi hạn ngạch chỗ ngồi) |

**Tiêu chí chấp nhận (GWT):**
- **Cho** Quản trị viên người thuê nhập địa chỉ email vào mẫu đăng ký lớp học
- **Khi** hồ sơ đăng ký được gửi
- **Sau đó** nếu email khớp với một học sinh hiện có trong đối tượng thuê: học sinh đó đã được ghi danh vào lớp học (nếu chưa ghi danh)
- **Và** nếu email không tồn tại: hệ thống tạo tài khoản sinh viên mới với mật khẩu được tạo tự động và đăng ký tài khoản đó; một email do tài khoản tạo được gửi đến sinh viên (FR-83)
- **Và** nếu `seats_used ≥ Seat_count`: đăng ký bị từ chối với thông báo `"Đã đạt đến hạn ngạch chỗ ngồi. Vui lòng liên hệ với người quản lý tài khoản của bạn để nâng cấp giấy phép của bạn."` và không có tài khoản nào được tạo

---

#### FR-47 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cho phép Quản trị viên đối tượng thuê nhập hàng loạt danh sách sinh viên từ tệp CSV hoặc Excel, tự động tạo tài khoản cho sinh viên mới, xác thực từng hàng một cách độc lập và thực thi hạn mức chỗ ngồi.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Quản trị viên thuê nhà |
| điều kiện tiên quyết | Một nhóm lớp tồn tại; Quản trị viên người thuê có tệp CSV/Excel chứa dữ liệu sinh viên |
| Cò súng | Quản trị viên đối tượng thuê tải tệp lên và xác nhận việc nhập |
| Nguồn | F-06; CI-03 (tệp tải lên ≤ 50 MB); BR-05 |

**Tiêu chí chấp nhận (GWT):**
- **Được cho** Quản trị viên đối tượng thuê tải lên tệp CSV có các cột: `full_name`, `email`
- **Khi** hệ thống phân tích tệp
- **Sau đó** một bảng xem trước được hiển thị với xác thực trên mỗi hàng: có các trường bắt buộc, định dạng email hợp lệ, không có email trùng lặp trong đối tượng thuê
- **Và** Quản trị viên đối tượng thuê xác nhận việc nhập; hệ thống tạo tài khoản cho tất cả các hàng email mới hợp lệ và đăng ký chúng; các email trùng lặp trong đối tượng thuê được đăng ký mà không cần tạo tài khoản mới
- **Và** một bản tóm tắt được hiển thị: "N tài khoản đã được tạo, M đã tồn tại (đã đăng ký), K hàng bị bỏ qua (có lý do)"
- **Và** nếu quá trình nhập vượt quá `seat_count`, hệ thống chỉ xử lý số hàng còn lại, báo cáo hàng nào bị bỏ qua do hạn ngạch và dừng khi đạt đến hạn ngạch

---

#### FR-48 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ tạo tệp thông tin xác thực Excel có thể tải xuống ngay sau khi tạo hàng loạt học sinh; tệp chỉ được bao gồm mật khẩu văn bản gốc khi được xuất trong vòng 24 giờ kể từ khi tạo tài khoản; các lần xuất tiếp theo sẽ che giấu mật khẩu.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Quản trị viên thuê nhà |
| Điều kiện tiên quyết | Nhập hàng loạt hoặc tạo tài khoản hàng loạt đã được hoàn thành |
| Cò súng | Quản trị viên đối tượng thuê nhấp vào "Xuất thông tin xác thực" |
| Nguồn | F-06; UI-05 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** quá trình nhập số lượng lớn vừa hoàn tất
- **Khi** Quản trị viên đối tượng thuê nhấp vào Xuất thông tin xác thực
- **Sau đó** hệ thống tạo file Excel gồm các cột: STT, Họ và tên, Email/Username, Mật khẩu, Lớp
- **Và** mật khẩu văn bản gốc chỉ được bao gồm cho các tài khoản được tạo trong vòng 24 giờ qua
- **Và** các tài khoản cũ hơn 24 giờ hiển thị "···········" trong cột mật khẩu
- **Và** trước khi quá trình tải xuống bắt đầu, một cảnh báo sẽ hiển thị: "Lưu tệp này một cách an toàn. Mật khẩu sẽ không được hiển thị lại sau 24 giờ."
- **Và** quá trình tải xuống bắt đầu ngay lập tức mà không cần hộp thoại xác nhận riêng

---

#### FR-49 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ hiển thị trang hồ sơ học sinh mà nhân viên được ủy quyền có thể truy cập, hiển thị thông tin cá nhân, các khóa học/lớp học đã đăng ký, lịch sử thi và tóm tắt thành tích.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Giáo viên (học sinh trong lớp); Quản trị viên thuê nhà (tất cả sinh viên) |
| điều kiện tiên quyết | Người dùng xem có quyền truy cập vào sinh viên mục tiêu trong đối tượng thuê |
| Cò súng | Nhân viên nhấp vào tên của học sinh ở bất cứ đâu trong cổng thông tin |
| Nguồn | F-06; F-07 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** Giáo viên nhấp vào học sinh S thuộc một trong các lớp được chỉ định của họ
- **Khi** tải trang hồ sơ học sinh
- **Sau đó** hệ thống hiển thị: tên sinh viên, email, trạng thái tài khoản (đang hoạt động/bị đình chỉ), các lớp đã đăng ký, danh sách các lần thi (ngày, tên phiên, trạng thái, điểm cho mỗi kỹ năng) và tóm tắt tiến trình của điểm
- **Và** Giáo viên không thể truy cập hồ sơ của một học sinh không thuộc lớp được chỉ định (HTTP 403)
- **Và** Quản trị viên người thuê có thể xem bất kỳ hồ sơ sinh viên nào trong người thuê

---

#### FR-50 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cho phép Quản trị viên và Giáo viên của Người thuê hủy đăng ký một học sinh khỏi nhóm khóa học; việc hủy đăng ký sẽ không xóa tài khoản của học sinh hoặc hồ sơ bài kiểm tra lịch sử của họ và sẽ miễn phí một chỗ.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Quản trị viên thuê nhà; Giáo viên |
| điều kiện tiên quyết | Học sinh đã được ghi danh vào lớp học |
| Cò súng | Quản trị viên hoặc Giáo viên xác nhận hành động hủy đăng ký |
| Nguồn | F-06; BR-05 (quản lý chỗ ngồi) |

**Tiêu chí chấp nhận (GWT):**
- **Cho** Quản trị viên người thuê nhà xác nhận việc hủy đăng ký của sinh viên S khỏi lớp C
- **Khi** việc hủy đăng ký được xử lý
- **Sau đó** học sinh bị loại khỏi tuyển sinh lớp C; học sinh không còn có thể truy cập các buổi thi trong khóa học đó nữa
- **Và** `seats_used` giảm 1 ngay lập tức
- **Và** hồ sơ kỳ thi lịch sử của học sinh S trong khóa C được lưu giữ và vẫn hiển thị cho Quản trị viên và Giáo viên của Người thuê nhà
- **Và** nếu học sinh hiện đang `đang tiến hành` một bài kiểm tra đang diễn ra trong khóa học đó thì việc hủy đăng ký sẽ bị chặn với: "Không thể hủy đăng ký một học sinh đang làm bài kiểm tra đang hoạt động. Vui lòng đợi cho đến khi bài kiểm tra hoàn tất."

---

#### FR-51 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ theo dõi việc sử dụng chỗ ngồi theo thời gian thực của mỗi người thuê theo hạn mức giấy phép và từ chối đăng ký mới khi `seats_used ≥ Seat_count`.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Hệ thống (thực thi tự động); Quản trị viên đối tượng thuê (kích hoạt đăng ký) |
| Điều kiện tiên quyết | Giấy phép hoạt động tồn tại cho người thuê nhà |
| Cò súng | Bất kỳ hành động đăng ký nào (FR-46, FR-47) |
| Nguồn | F-06; BR-05; FR-65 (màn hình bảng điều khiển) |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một người thuê có `seat_count = 100` và `seat_used = 100`
- **Khi** Quản trị viên người thuê cố gắng ghi danh một sinh viên mới
- **Sau đó** hệ thống từ chối đăng ký với HTTP 409: `"Đã đạt đến hạn ngạch chỗ ngồi (100 trên 100 chỗ đã được sử dụng). Vui lòng liên hệ với người quản lý tài khoản của bạn để nâng cấp giấy phép của bạn."`
- **Và** không có tài khoản nào được tạo và không có hồ sơ đăng ký nào được ghi
- **Và** `seats_used` bị giảm dần khi hủy đăng ký (FR-50); lần đăng ký tiếp theo sẽ thành công ngay lập tức nếu một chỗ trống được giải phóng
- **Và** bảng điều khiển Quản trị viên đối tượng thuê luôn hiển thị `seats_used / Seat_count` hiện tại theo thời gian thực

---

## F-07: Phân tích & Báo cáo (FR-52 – FR-70)

---

#### FR-52 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ hiển thị danh sách theo thứ tự thời gian của tất cả các lần thi của học sinh đã đăng nhập, hiển thị ngày thi, tên phiên và kết quả của từng kỹ năng hoặc "Đang chờ xử lý" đối với các kỹ năng chưa được tính điểm.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Học sinh |
| điều kiện tiên quyết | Học sinh đã được xác thực và có ít nhất một lần nộp bài thi |
| Cò súng | Học sinh điều hướng đến phần kết quả của họ |
| Nguồn | F-07; UI-09 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một học sinh có 3 lần nộp bài thi
- **Khi** học sinh mở phần kết quả
- **Sau đó** hệ thống hiển thị tất cả các bài thi được sắp xếp theo `submit_at` giảm dần theo các cột: Ngày, Buổi thi, Nhóm Đọc, Nhóm Nghe, Nhóm Viết, Nhóm Nói
- **Và** các kỹ năng đang chờ giáo viên đánh giá hiển thị "Đang chờ xử lý" trong cột ban nhạc
- **Và** nhấp vào một hàng sẽ mở ra chi tiết lần thử (FR-54)

---

#### FR-53 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ hiển thị biểu đồ đường tiến triển cho học sinh có ≥ 2 lần thử được ghi điểm, hiển thị một dòng cho mỗi kỹ năng trong tất cả các ngày thử.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Học sinh |
| điều kiện tiên quyết | Học sinh có ≥ 2 lần thi đạt điểm tối đa |
| Cò súng | Học sinh mở phần kết quả |
| Nguồn | F-07; UI-09 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một học sinh có 4 lần ghi điểm trong 3 tháng
- **Khi** biểu đồ tiến trình hiển thị
- **Sau đó** biểu đồ hiển thị 4 dòng (Đọc, Nghe, Viết, Nói) với trục x = ngày thi, trục y = band (A1 đến C theo thang thứ tự)
- **Và** di chuột qua một điểm dữ liệu sẽ hiển thị ngày và băng tần chính xác
- **Và** nếu một kỹ năng chỉ có 1 điểm dữ liệu, nó sẽ hiển thị dưới dạng một điểm duy nhất (không phải một đường)
- **Và** những bài thi mà Viết hoặc Nói vẫn đang chờ xử lý sẽ bị loại khỏi dòng kỹ năng đó

---

#### FR-54 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ hiển thị bảng phân tích kỹ năng mỗi lần thử hiển thị điểm từng phần cho từng kỹ năng khi học sinh hoặc Giáo viên xem một lần thử cụ thể.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Học sinh; Giáo viên |
| điều kiện tiên quyết | Lần thử có `trạng thái = đã gửi`; ít nhất kết quả Đọc/Nghe là `có sẵn` |
| Cò súng | Học sinh hoặc Giáo viên mở màn hình chi tiết lần thử |
| Nguồn | F-07 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một học sinh mở chi tiết bài thi
- **Khi** tải phần phân tích kỹ năng
- **Sau đó** cho phần Đọc và Nghe: mỗi phần hiển thị số điểm chính xác (ví dụ: "Phần A: 4/5"), tổng điểm thô và thang điểm
- **Và** dành cho phần Viết: số từ trên mỗi phần và thang điểm (hiển thị sau khi giáo viên xác nhận)
- **Và** cho phần Nói: ban nhạc theo từng phần (sau khi giáo viên xác nhận)
- **Và** các phần có điểm thấp nhất được biểu thị bằng hình ảnh (ví dụ: hàng được đánh dấu hoặc huy hiệu có điểm thấp nhất)

---

#### FR-55 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ tính toán và hiển thị bản tóm tắt điểm mạnh, điểm yếu cho học sinh có ≥ 2 lần thi đạt điểm, xác định rõ ràng điểm yếu và điểm mạnh trong tất cả các lần thi.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Học sinh |
| điều kiện tiên quyết | Học sinh có ≥ 2 lần ghi điểm |
| Cò súng | Sinh viên xem phần kết quả của mình |
| Nguồn | F-07 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một học sinh có 3 lần ghi điểm
- **Khi** bảng điểm mạnh/điểm yếu hiển thị
- **Sau đó** hệ thống tính điểm trung bình cho mỗi phần trong tất cả các lần ghi điểm
- **Và** các phần có mức trung bình dưới ngưỡng được định cấu hình được liệt kê là "Các lĩnh vực cần cải thiện"
- **Và** các phần luôn ở trên ngưỡng được liệt kê là "Điểm mạnh"
- **Và** bản tóm tắt tự động cập nhật khi có kết quả tính điểm mới

---

#### FR-56 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ hiển thị tường thuật phản hồi đã được giáo viên xác nhận về phần Viết và Nói cho học sinh từ màn hình chi tiết bài thi, sau khi hoàn thiện; các phần chưa được xác nhận sẽ hiển thị phần giữ chỗ đang chờ xử lý.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Học sinh |
| Điều kiện tiên quyết | Giáo viên đã xác nhận điểm Viết/Nói (FR-33) |
| Cò súng | Học sinh mở chi tiết bài thi |
| Nguồn | F-07; FR-36 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** Giáo viên đã xác nhận điểm cho phần Viết Phần C
- **Khi** học sinh mở thông tin chi tiết về lần thử đó
- **Sau đó** tường thuật phản hồi cho phần Viết C được hiển thị: điểm tiêu chí phiếu tự đánh giá, điểm tổng thể, văn bản tường thuật
- **Và** Phần nói mà Giáo viên chưa xác nhận hiển thị "Kết quả đang chờ giáo viên xem xét"
- **Và** ngôn ngữ phản hồi được hiển thị dưới dạng văn bản (không áp dụng bản dịch)

---

#### FR-57 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ hiển thị bảng điều khiển phân tích cấp lớp dành cho Giáo viên hiển thị điểm trung bình cho mỗi kỹ năng và phân bổ điểm cho một lớp và buổi thi đã chọn.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Giáo viên |
| Điều kiện tiên quyết | Đã hoàn thành ít nhất một buổi thi có kết quả được tính điểm ở lớp do Giáo viên phân công |
| Cò súng | Giáo viên mở phần phân tích lớp và chọn một buổi học |
| Nguồn | F-07; UI-06 |

**Tiêu chí chấp nhận (GWT):**
- **Được** Giáo viên chọn lớp "10A" và buổi "Thi thử 1"
- **Khi** tải trang phân tích lớp học
- **Sau đó** hệ thống hiển thị: điểm trung bình cho mỗi kỹ năng (nhãn + số trung bình), số học sinh đã hoàn thành so với chưa bắt đầu và số lượng phân bổ điểm cho mỗi kỹ năng (có bao nhiêu học sinh ở mỗi cấp độ)
- **Và** dữ liệu nằm trong phạm vi lớp và phiên đã chọn
- **Và** Giáo viên có thể điều hướng giữa các buổi học để so sánh kết quả

---

#### FR-58 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ hiển thị danh sách học sinh được xếp hạng trong lớp cho một buổi thi đã chọn, sắp xếp theo tổng điểm, có các cột cho từng nhóm kỹ năng; bảng sẽ được sắp xếp theo bất kỳ cột nào.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Giáo viên |
| điều kiện tiên quyết | Có ít nhất một lần ghi điểm trong lớp học cho buổi học đã chọn |
| Cò súng | Giáo viên yêu cầu bảng xếp hạng học sinh |
| Nguồn | F-07; UI-06 |

**Tiêu chí chấp nhận (GWT):**
- **Được** Giáo viên xem số liệu phân tích của lớp trong một buổi học có 30 học sinh được điểm
- **Khi** bảng xếp hạng hiển thị
- **Sau đó** hệ thống hiển thị: Thứ hạng, Tên học sinh, Nhóm đọc, Nhóm nghe, Nhóm viết, Nhóm nói, Tổng điểm; được sắp xếp theo tổng số điểm giảm dần theo mặc định
- **Và** Giáo viên có thể nhấp vào bất kỳ tiêu đề cột nào để sắp xếp lại
- **Và** những học sinh có điểm Viết/Nói đang chờ xử lý chỉ được xếp hạng theo các kỹ năng có sẵn, với "Đang chờ xử lý" trong các cột không được tính điểm

---

#### FR-59 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ đánh dấu những học sinh có điểm ở bất kỳ kỹ năng nào thấp hơn ngưỡng đã định cấu hình cho một buổi học, trong bảng "cảnh báo học sinh yếu" mà Giáo viên và Quản trị viên người thuê nhà có thể truy cập.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Giáo viên; Quản trị viên thuê nhà |
| điều kiện tiên quyết | Kết quả được tính điểm tồn tại cho phiên đã chọn |
| Cò súng | Quản trị viên giáo viên hoặc người thuê xem phân tích lớp học |
| Nguồn | F-07 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** ngưỡng học sinh yếu được cấu hình ở B1
- **Khi** bảng cảnh báo học sinh yếu tải về một phiên học
- **Sau đó** hệ thống liệt kê tất cả học sinh có ít nhất một nhóm kỹ năng dưới B1: Tên học sinh, (các) kỹ năng có điểm thấp, giá trị nhóm
- **Và** danh sách có thể được xuất sang Excel
- **Và** ngưỡng này có thể được cấu hình cho mỗi đối tượng thuê bởi Quản trị viên đối tượng thuê (mặc định: B1)

---

#### FR-60 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ tính toán và hiển thị sự thay đổi về điểm trung bình trên mỗi kỹ năng giữa buổi học đầu tiên và buổi học được ghi điểm gần đây nhất cho một lớp, cho thấy sự tiến bộ hoặc thụt lùi bằng chỉ báo định hướng.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Giáo viên |
| Điều kiện tiên quyết | Một lớp có ít nhất 2 buổi thi hoàn thành và chấm điểm |
| Cò súng | Giáo viên xem bảng so sánh trước/sau |
| Nguồn | F-07 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một lớp đã chấm điểm các buổi vào tháng 1 và tháng 3
- **Khi** kết xuất so sánh trước/sau
- **Sau đó** hệ thống hiển thị: `avg_band_first_session` và `avg_band_latest_session` cho mỗi kỹ năng và một delta có chỉ báo: ↑ (đã cải thiện), ↓ (hồi quy), = (không thay đổi)
- **Và** delta được biểu thị bằng số cấp độ băng tần đã thay đổi (ví dụ: "Dải +1: A2 → B1")
- **Và** nếu phần Viết hoặc Nói vẫn đang chờ xử lý một phần thì chỉ điểm được xác nhận mới được tính vào điểm trung bình

---

#### FR-61 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ hiển thị biểu đồ phân bổ điểm cho lớp, phiên và kỹ năng đã chọn, với các thanh cho mỗi cấp độ được tô màu theo từng nhóm.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Giáo viên |
| điều kiện tiên quyết | Đã có kết quả được tính điểm cho việc lựa chọn |
| Cò súng | Giáo viên chọn lớp, buổi, kỹ năng; bảng biểu đồ hiển thị |
| Nguồn | F-07 |

**Tiêu chí chấp nhận (GWT):**
- **Được** Giáo viên chọn lớp “10A”, phần “Thi thử 1”, kỹ năng “Đọc”
- **Khi** biểu đồ hiển thị
- **Sau đó** một biểu đồ thanh xuất hiện với trục x = cấp độ ban nhạc (A1, A2, B1, B2, C) và trục y = số học sinh trên mỗi ban nhạc
- **Và** các thanh được mã hóa màu (ví dụ: A1 = đỏ, A2 = cam, B1 = vàng, B2 = xanh nhạt, C = xanh lục)
- **Và** biểu đồ có thể được tải xuống dưới dạng PNG

---

#### FR-62 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cung cấp cho Quản trị viên người thuê và Người xem bảng điều khiển tổng quan về KPI hiển thị tổng số khóa học đang hoạt động, số sinh viên đã đăng ký so với hạn ngạch, số phiên, tỷ lệ hoàn thành, trạng thái giấy phép và các phiên sắp tới.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Quản trị viên thuê nhà; Người xem |
| điều kiện tiên quyết | Quản trị viên hoặc người xem của người thuê được xác thực |
| Cò súng | Người dùng điều hướng đến bảng điều khiển |
| Nguồn | F-07; UI-05; UI-08 |

**Tiêu chí chấp nhận (GWT):**
- **Được cho** Quản trị viên đối tượng thuê sẽ mở bảng điều khiển
- **Khi** trang tổng quan tải
- **Sau đó** hệ thống hiển thị thẻ KPI: tổng số khóa học đang hoạt động, tổng số học viên đã đăng ký (so với `seat_count`), tổng số buổi thi trong tháng này, tỷ lệ hoàn thành tổng thể (đã gửi / tổng số đủ điều kiện), trạng thái giấy phép với chỉ báo màu, các buổi thi sắp tới trong 7 ngày tới
- **Và** trang tổng quan tải trong vòng 3 giây (mục tiêu hiệu suất NFR)
- **Và** Người xem thấy dữ liệu giống hệt nhau mà không có điều khiển tạo/chỉnh sửa

---

#### FR-63 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ hiển thị biểu đồ phân bổ điểm toàn trường cho thấy tỷ lệ học sinh ở mỗi điểm APTIS cho từng kỹ năng, tổng hợp trên tất cả các buổi học và khóa học trong đối tượng thuê.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Quản trị viên thuê nhà; Người xem |
| điều kiện tiên quyết | Có ít nhất một lần ghi điểm trong đối tượng thuê |
| Cò súng | Quản trị viên hoặc người xem đối tượng thuê mở phần phân tích |
| Nguồn | F-07 |

**Tiêu chí chấp nhận (GWT):**
- **Được cho** Quản trị viên đối tượng thuê sẽ mở phần phân tích
- **Khi** biểu đồ phân bổ băng tần hiển thị
- **Sau đó** hệ thống hiển thị biểu đồ cho mỗi kỹ năng hiển thị tỷ lệ học sinh ở mỗi trình độ (A1–C) dựa trên nỗ lực ghi điểm gần đây nhất của mỗi học sinh cho kỹ năng đó
- **Và** biểu đồ có thể lọc theo khóa học và khoảng thời gian
- **Và** nhấp vào phân đoạn ban nhạc để xem chi tiết các lớp/khóa học nào đóng góp cho nhóm ban nhạc đó

---

#### FR-64 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ hiển thị bảng tóm tắt tất cả các khóa học trong đối tượng thuê hiển thị số lượng đăng ký, số phiên, tỷ lệ hoàn thành và mức trung bình cho mỗi kỹ năng.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Quản trị viên thuê nhà |
| điều kiện tiên quyết | Ít nhất một khóa học tồn tại trong đối tượng thuê |
| Cò súng | Quản trị viên thuê mở phần phân tích khóa học |
| Nguồn | F-07 |

**Tiêu chí chấp nhận (GWT):**
- **Được tặng** Quản trị viên người thuê sẽ mở phần phân tích khóa học
- **Khi** bảng tải
- **Sau đó** hệ thống hiển thị theo từng khóa học: tên, số lượng đăng ký, số buổi thi, tỷ lệ hoàn thành trung bình, điểm trung bình cho mỗi kỹ năng
- **Và** bảng có thể sắp xếp theo bất kỳ cột nào
- **Và** việc nhấp vào một hàng khóa học sẽ mở ra chế độ xem chi tiết cấp độ khóa học

---

#### FR-65 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ hiển thị mức sử dụng chỗ ngồi hiện tại dưới dạng thanh tiến trình được mã hóa màu trên bảng điều khiển Quản trị viên đối tượng thuê, với các ngưỡng ở mức 70% (màu xanh lá cây), 80–89% (màu vàng) và ≥90% (màu đỏ).

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Quản trị viên thuê nhà |
| Điều kiện tiên quyết | Giấy phép hoạt động tồn tại cho người thuê nhà |
| Cò súng | Quản trị viên người thuê xem bảng điều khiển |
| Nguồn | F-07; F-08; BR-05 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một người thuê có `seat_count = 200` và `seat_used = 185`
- **Khi** phần sử dụng giấy phép hiển thị
- **Sau đó** thanh tiến trình hiển thị 92,5% và có màu đỏ
- **Và** bên dưới thanh: nhãn đếm chính xác ("185 trên 200 chỗ đã sử dụng") và ngày hết hạn giấy phép
- **Và** liên kết "Liên hệ bán hàng" hiển thị khi sử dụng ≥ 90% hoặc hết hạn trong vòng 30 ngày
- **Và** thanh tiến trình cập nhật theo thời gian thực khi đăng ký/hủy đăng ký mà không cần tải lại trang

---

#### FR-66 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cho phép Quản trị viên, Người xem và Giáo viên của Người thuê (trong phạm vi lớp học của họ) xuất báo cáo phân tích dưới dạng tệp Excel; tất cả các hàng (không chỉ trang hiển thị) sẽ được bao gồm; Xuất PDF có điều kiện cho v1.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Quản trị viên thuê nhà; Người xem; Giáo viên |
| Điều kiện tiên quyết | Người dùng ở bất kỳ chế độ xem phân tích nào |
| Cò súng | Người dùng nhấp vào Xuất |
| Nguồn | F-07; §2.6 (Xuất PDF hoãn sang v1.5) |

**Tiêu chí chấp nhận (GWT):**
- **Cho** Quản trị viên người thuê đang xem báo cáo lớp học với 300 hàng sinh viên (được đánh số trang thành 50 trên mỗi trang)
- **Khi** Quản trị viên đối tượng thuê nhấp vào Xuất Excel
- **Sau đó** hệ thống tạo một tệp Excel chứa tất cả 300 hàng (không chỉ 50 hàng được hiển thị)
- **Và** tệp bao gồm: tiêu đề báo cáo, ngày tạo, tên đối tượng thuê, phạm vi (lớp/khóa học/trường học) và tất cả các cột được hiển thị
- **Và** file tải ngay về trình duyệt
- **Và** Việc xuất khẩu của giáo viên chỉ nằm trong phạm vi các lớp được chỉ định của họ; dữ liệu giữa các lớp bị loại trừ
- **Và** [Có điều kiện] Xuất PDF của cùng một dữ liệu có sẵn nếu được bật cho v1

---

#### FR-67 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ tính toán và hiển thị số liệu thống kê phân tích mục theo từng câu hỏi (tỷ lệ đúng, tỷ lệ sai trên mỗi yếu tố phân tâm, tỷ lệ bỏ qua, thời gian chi tiêu trung bình) cho Người quản lý nội dung, được tổng hợp trên toàn cầu trên tất cả đối tượng thuê.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Trình quản lý nội dung |
| Điều kiện tiên quyết | Câu hỏi đã được sử dụng trong ít nhất một buổi thi đã hoàn thành |
| Cò súng | Trình quản lý nội dung mở chế độ xem phân tích mục và chọn một câu hỏi |
| Nguồn | F-07; F-02; FR-16 |

**Tiêu chí chấp nhận (GWT):**
- **Được cho** Người quản lý nội dung chọn câu hỏi Q với 50 câu trả lời
- **Khi** bảng thống kê tải
- **Sau đó** hệ thống hiển thị: `tỷ lệ chính xác (%)`, `tỷ lệ sai cho mỗi người phân tâm` (đối với câu hỏi MCQ), `bỏ_tỷ lệ (%)`, `avg_time_spent (giây)`
- Số liệu thống kê **Và** được tổng hợp từ tất cả các đối tượng thuê trên toàn cầu (tổng hợp nhiều đối tượng thuê; không có dữ liệu riêng lẻ của đối tượng thuê nào bị lộ)
- **Và** số liệu thống kê được tính lại hàng đêm từ bảng `exam_answers`

---

#### FR-68 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ tính chỉ số độ khó (p-value) cho mỗi câu hỏi và tự động gắn cờ các câu hỏi có giá trị p < 0,3 (Quá khó) hoặc giá trị p > 0,9 (Quá dễ).

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Hệ thống (tính toán tự động); Người quản lý nội dung (người tiêu dùng) |
| điều kiện tiên quyết | Câu hỏi có ≥ 10 bản ghi phản hồi |
| Cò súng | Công việc phân tích hạng mục hàng đêm; Trình quản lý nội dung mở phân tích mục |
| Nguồn | F-07; FR-16 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** câu hỏi Q có 50 câu trả lời, trong đó có 12 câu đúng
- **Khi** tải trang phân tích mục
- **Sau đó** hệ thống tính toán và hiển thị `p_value = 12/50 = 0,24`, hiển thị là "24%"
- **Và** câu hỏi được gắn cờ "Quá khó" (p < 0,3)
- **Và** các câu hỏi có p < 10 câu trả lời hiển thị: "Không đủ dữ liệu để phân tích (N = {count})" và không áp dụng cờ

---

#### FR-69 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ tính chỉ số phân biệt đối xử theo điểm cho mỗi câu hỏi và gắn cờ các câu hỏi có chỉ số < 0,2 (Phân biệt đối xử kém) hoặc chỉ số < 0 (Yêu cầu đánh giá).

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Hệ thống (tính toán tự động); Người quản lý nội dung (người tiêu dùng) |
| điều kiện tiên quyết | Câu hỏi có ≥ 10 bản ghi phản hồi |
| Cò súng | Công việc phân tích mục hàng đêm |
| Nguồn | F-07; FR-16 |

**Tiêu chí chấp nhận (GWT):**
- **Cho trước** câu hỏi Q có hệ số tương quan điểm-ngược chiều được tính toán là −0,05
- **Khi** tải trang phân tích mục
- **Sau đó** hệ thống hiển thị `discrimination_index = -0,05` và gắn cờ câu hỏi là "Yêu cầu xem lại — câu trả lời đúng cho câu hỏi này tương ứng với điểm tổng thể thấp hơn"
- **Và** các câu hỏi có chỉ số từ 0 đến 0,19 được gắn cờ "Phân biệt đối xử kém"
- **Và** câu hỏi có chỉ số ≥ 0,2 không hiển thị cờ

---

#### FR-70 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cung cấp cho Người quản lý nội dung danh sách câu hỏi được gắn cờ tổng hợp hiển thị tất cả các câu hỏi có cờ phân tích mục đang hoạt động, có thể lọc theo kỹ năng, bộ phận và loại cờ.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Trình quản lý nội dung |
| điều kiện tiên quyết | Ít nhất một câu hỏi đã được FR-68 hoặc FR-69 tự động gắn cờ |
| Cò súng | Trình quản lý nội dung mở phần Câu hỏi được gắn cờ |
| Nguồn | F-07; FR-68; FR-69 |

**Tiêu chí chấp nhận (GWT):**
- **Đưa ra** 12 câu hỏi được gắn cờ theo các kỹ năng khác nhau
- **Khi** Trình quản lý nội dung mở Câu hỏi được gắn cờ
- **Sau đó** tất cả 12 câu hỏi được gắn cờ sẽ được liệt kê theo các cột: ID câu hỏi/xem trước, Kỹ năng, Phần, giá trị p, Chỉ số phân biệt đối xử, Loại cờ
- **Và** danh sách có thể lọc theo kỹ năng, bộ phận và loại cờ
- **Và** nhấp vào một câu hỏi sẽ mở trình soạn thảo câu hỏi (FR-09) và bảng phân tích mục (FR-67) cạnh nhau
- **Và** Người quản lý nội dung có thể đánh dấu cờ là "đã xác nhận" để theo dõi những câu hỏi nào đã được xem xét

---

## F-08: Quản lý nhà cung cấp (FR-71 – FR-76)

---

#### FR-71 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cho phép Quản trị viên cấp cao tạo, kích hoạt, tạm dừng, kích hoạt lại và ngừng hoạt động tài khoản đối tượng thuê; tất cả các thay đổi trạng thái sẽ được ghi lại bằng dấu thời gian và tác nhân; người dùng của đối tượng thuê bị đình chỉ sẽ nhận được HTTP 403 trên tất cả các yêu cầu đã được xác thực.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Siêu quản trị viên |
| Điều kiện tiên quyết | Quản trị viên cấp cao được xác thực trong Cổng thông tin nhà cung cấp |
| Cò súng | Quản trị viên cấp cao thay đổi trạng thái của người thuê |
| Nguồn | F-08; BR-10 (bị treo = chỉ đọc) |

**Tiêu chí chấp nhận (GWT):**
- **Được cho** Quản trị viên cấp cao đình chỉ người thuê "hanoi-english"
- **Khi** việc thay đổi trạng thái được xác nhận
- **Sau đó** `tenant.status = bị đình chỉ`; tất cả người dùng tại `hanoi-english.aptis-lms.vn` ​​nhận được HTTP 403 trên các điểm cuối được bảo vệ với thông báo: "Tài khoản của tổ chức bạn đã bị tạm ngưng. Vui lòng liên hệ với người quản lý tài khoản của bạn."
- **Và** các thay đổi `tenant.status` được ghi vào `audit_log`: `{actor_id, action,rent_id, old_status, new_status, timestamp}`
- **Và** những người thuê đã ngừng hoạt động có dữ liệu được bảo toàn nhưng tất cả thông tin đăng nhập đều bị chặn; `trạng thái = đã ngừng hoạt động` không thể được người dùng bên đối tượng thuê hoàn nguyên
- **Và** hộp thoại xác nhận đã nhập (UI-01) là bắt buộc để tạm dừng và ngừng hoạt động: "Nhập sên đối tượng thuê để xác nhận"

---

#### FR-72 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cho phép Quản trị viên cấp cao định cấu hình cài đặt cho mỗi đối tượng thuê bao gồm múi giờ, tên hiển thị và URL biểu tượng tùy chọn; các thay đổi sẽ có hiệu lực ngay lập tức mà không yêu cầu người dùng đăng nhập lại.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Siêu quản trị viên |
| điều kiện tiên quyết | Người thuê tồn tại trong hệ thống |
| Cò súng | Quản trị viên cấp cao lưu cấu hình đối tượng thuê |
| Nguồn | F-08; UI-01 |

**Tiêu chí chấp nhận (GWT):**
- **Được cho** Super Admin đặt tên hiển thị của đối tượng thuê thành "Trung tâm Anh ngữ Hà Nội" và múi giờ thành "Châu Á/Ho_Chi_Minh"
- **Khi** cấu hình được lưu
- **Sau đó** tiêu đề Cổng thông tin dành cho đối tượng thuê ngay lập tức hiển thị tên hiển thị và logo được cập nhật (nếu được cung cấp)
- **Và** tất cả hiển thị ngày giờ trong cổng thông tin đối tượng thuê đều sử dụng múi giờ "Châu Á/Hồ_Chi_Minh"
- **Và** các thay đổi sẽ có hiệu lực trên cổng thông tin đối tượng thuê trong vòng 30 giây mà không yêu cầu người dùng đối tượng thuê phải tải lại trang hoặc đăng nhập lại

---

#### FR-73 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cho phép các thành viên Nhóm Bán hàng tạo giấy phép theo chỗ ngồi cho người thuê và gia hạn ngày hết hạn hoặc điều chỉnh số lượng chỗ ngồi trên giấy phép hiện có; tất cả các thay đổi sẽ được ghi lại.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Đội ngũ bán hàng |
| điều kiện tiên quyết | Thành viên Nhóm bán hàng được xác thực trong Cổng thông tin nhà cung cấp; đối tượng thuê mục tiêu tồn tại |
| Cò súng | Thành viên Nhóm bán hàng lưu việc tạo hoặc sửa đổi giấy phép |
| Nguồn | F-08; F-09; BR-10 |

**Tiêu chí chấp nhận (GWT):**
- **Được cho** một thành viên Nhóm bán hàng tạo giấy phép cho đối tượng thuê T với `seat_count = 150` và `expiry_date = 2027-06-30`
- **Khi** giấy phép được lưu
- **Sau đó** một bản ghi giấy phép được tạo: `{tenant_id, Seat_count, Expiration_date, create_by, create_at}`
- **Và** hạn ngạch hiệu quả của người thuê sẽ trở thành 150 chỗ ngay lập tức
- **Và** nếu đối tượng thuê trước đó không có giấy phép hoạt động: `tenant.status` chuyển từ `đang chờ xử lý` sang `hoạt động`
- **Và** tất cả các thay đổi về giấy phép (tạo, mở rộng, điều chỉnh) đều được thêm vào `license_history` (FR-81)

---

#### FR-74 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ gửi thông báo qua email tự động tới Quản trị viên người thuê và Nhóm bán hàng khi mức sử dụng chỗ ngồi đạt 80%, 90% và khi giấy phép hết hạn sau 30 ngày và 7 ngày; cảnh báo sẽ không có giá trị (không lặp lại trong cùng một ngưỡng).

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Hệ thống (công việc cảnh báo theo lịch trình) |
| điều kiện tiên quyết | Giấy phép hoạt động tồn tại cho người thuê nhà |
| Cò súng | Công việc được lên lịch hàng ngày kiểm tra tất cả các ngưỡng của người thuê |
| Nguồn | F-08; F-10; BR-11 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** đối tượng thuê T có `seat_count = 100` và `seats_used` tăng lên 80
- **Khi** công việc cảnh báo hàng ngày chạy
- **Sau đó** một thông báo qua email được gửi đến Quản trị viên đối tượng thuê: "Tổ chức của bạn đang sử dụng 80% số giấy phép được cấp phép (80/100). Hãy liên hệ với người quản lý tài khoản của bạn để thêm giấy phép."
- **Và** khi `seats_used` đạt 90: email được gửi đến Nhóm bán hàng VÀ quản trị viên thuê
- **Và** khi `days_until_expiry ≤ 30`: email được gửi đến Quản trị viên và Nhóm bán hàng của Người thuê; khi `days_until_expiry ≤ 7`: một cảnh báo khác được gửi
- **Và** mỗi cảnh báo ngưỡng được gửi chính xác một lần cho mỗi lần vượt ngưỡng; nếu `seats_used` dao động quanh mức 80%, cảnh báo 80% sẽ không được gửi lại cho đến khi nó giảm xuống dưới 75% và lại vượt qua 80%

---

#### FR-75 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cho phép Quản trị viên cấp cao và Nhân viên hỗ trợ xem số liệu thống kê sử dụng của mỗi người thuê bao gồm số ghế đã sử dụng, số buổi thi, số lần thử của học sinh, dấu thời gian hoạt động gần đây nhất và trạng thái giấy phép; Quyền truy cập của Nhân viên Hỗ trợ ở chế độ chỉ đọc.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Siêu quản trị viên; Nhân viên hỗ trợ |
| Điều kiện tiên quyết | Quản trị viên cấp cao hoặc Nhân viên hỗ trợ được xác thực trong Cổng thông tin nhà cung cấp |
| Cò súng | Người dùng mở trang chi tiết về người thuê |
| Nguồn | F-08; UI-01; UI-03 |

**Tiêu chí chấp nhận (GWT):**
- **Được tặng** Nhân viên hỗ trợ mở chi tiết đối tượng thuê cho "hanoi-english"
- **Khi** tải trang
- **Sau đó** hệ thống hiển thị: tên đối tượng thuê, slug, trạng thái, giấy phép (số chỗ, thời hạn sử dụng), `seats_used / Seat_count`, tổng số buổi thi (mọi thời điểm và tháng hiện tại), tổng số lần thử của học sinh (mọi thời điểm), hoạt động gần đây nhất (lần đăng nhập gần đây nhất từ ​​bất kỳ người dùng nào trong đối tượng thuê)
- **Và** tất cả dữ liệu ở chế độ chỉ đọc đối với Nhân viên hỗ trợ; không hiển thị điều khiển tạo/chỉnh sửa/xóa
- **Và** Quản trị viên cấp cao nhìn thấy cùng một dữ liệu cộng với các nút hành động quản trị (tạm dừng, định cấu hình, v.v.)

---

#### FR-76 [Có điều kiện]

**Yêu cầu:** Hệ thống sẽ cho phép Nhân viên hỗ trợ truy cập chế độ xem mạo danh chỉ đọc của bất kỳ cổng thông tin đối tượng thuê nào; tất cả các hành động ghi sẽ bị vô hiệu hóa; mỗi phiên mạo danh sẽ được ghi lại với thời gian bắt đầu, thời gian kết thúc, ID nhân viên hỗ trợ và ID đối tượng thuê.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Nhân viên hỗ trợ |
| điều kiện tiên quyết | Nhân viên hỗ trợ được xác thực; đối tượng thuê mục tiêu đang hoạt động |
| Cò súng | Nhân viên hỗ trợ nhấp vào "Xem với tư cách quản trị viên đối tượng thuê" trên trang chi tiết về đối tượng thuê |
| Nguồn | F-08; UI-03; §2.6 (hoãn lại v1.5) |

**Tiêu chí chấp nhận (GWT):**
- **Được cho** Nhân viên hỗ trợ nhấp vào "Xem với tư cách quản trị viên đối tượng thuê" đối với đối tượng thuê T
- **Khi** chế độ xem mạo danh mở ra
- **Sau đó** một mục nhập `impersonation_log` được tạo bằng: `support_staff_id,rent_id, start_time`
- **Và** Nhân viên hỗ trợ xem Cổng thông tin dành cho đối tượng thuê như Quản trị viên đối tượng thuê; tất cả các điều khiển ghi (nút, biểu mẫu) đều bị ẩn hoặc vô hiệu hóa bằng chú giải công cụ "Chế độ xem chỉ đọc"
- **Và** một biểu ngữ màu cam dai dẳng có nội dung: "Đang xem [Tên người thuê] — Chỉ đọc | Thoát"
- **Và** nhấp vào Thoát sẽ đóng chế độ xem mạo danh và ghi nhật ký `end_time`
- **Và** việc mạo danh không tạo ra mã thông báo JWT quản trị viên thuê thực sự; tất cả các yêu cầu đều mang cờ bối cảnh mạo danh

---

## F-09: Cổng thông tin nhóm bán hàng (FR-77 – FR-82)

---

#### FR-77 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ hiển thị danh sách khách hàng có thể sắp xếp, có thể tìm kiếm cho các thành viên Nhóm bán hàng hiển thị tên người thuê, email liên hệ, trạng thái giấy phép, số chỗ đã sử dụng/tổng ​​cộng và ngày hết hạn.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Đội ngũ bán hàng |
| Điều kiện tiên quyết | Thành viên Nhóm bán hàng được xác thực trong Cổng thông tin nhà cung cấp |
| Cò súng | Thành viên Nhóm bán hàng mở Cổng thông tin bán hàng |
| Nguồn | F-09; UI-04 |

**Tiêu chí chấp nhận (GWT):**
- **Được cho** một thành viên của Nhóm bán hàng mở Cổng bán hàng
- **Khi** danh sách khách hàng được tải
- **Sau đó** hệ thống hiển thị tất cả người thuê trong một bảng: Tên, Email liên hệ, Trạng thái giấy phép (mã màu), Số chỗ đã sử dụng/Tổng số, Ngày hết hạn
- **Và** mã màu: xanh = đang hoạt động còn > 30 ngày, vàng = hết hạn trong vòng 30 ngày, đỏ = hết hạn
- **Và** danh sách có thể được sắp xếp theo bất kỳ cột nào và có thể tìm kiếm theo tên người thuê hoặc email liên hệ
- **Và** việc nhấp vào hàng đối tượng thuê sẽ mở ra chi tiết về đối tượng thuê bằng các nút hành động và lịch sử giấy phép

---

#### FR-78 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cho phép các thành viên Nhóm Bán hàng tạo giấy phép mới cho người thuê với số lượng chỗ ngồi và ngày hết hạn; giấy phép sẽ kích hoạt ngay khi lưu.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Đội ngũ bán hàng |
| Điều kiện tiên quyết | Người thuê mục tiêu tồn tại; Thành viên nhóm bán hàng được xác thực |
| Cò súng | Thành viên bán hàng nộp mẫu giấy phép tạo |
| Nguồn | F-09; FR-73 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** thành viên Nhóm bán hàng chọn đối tượng thuê T và nhập `seat_count = 200`, `expiry_date = 2027-12-31`
- **Khi** biểu mẫu được gửi
- **Sau đó** giấy phép được tạo và `tenant.effect_seat_count = 200` ngay lập tức
- **Và** nếu đối tượng thuê không có giấy phép hoạt động trước đó thì đối tượng thuê sẽ chuyển sang trạng thái `hoạt động`
- **Và** một email xác nhận sẽ được gửi tới Quản trị viên đối tượng thuê (FR-83: "Giấy phép được kích hoạt")
- **Và** `seat_count < 1` hoặc `expiry_date ≤ hôm nay` bị từ chối do lỗi xác thực HTTP 422

---

#### FR-79 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cho phép các thành viên Nhóm Bán hàng gia hạn thời hạn sử dụng của giấy phép hiện có; việc gia hạn giấy phép đã hết hạn sẽ kích hoạt lại đối tượng thuê từ chế độ chỉ đọc.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Đội ngũ bán hàng |
| điều kiện tiên quyết | Đối tượng thuê mục tiêu có giấy phép đang hoạt động hoặc gần đây đã hết hạn |
| Cò súng | Thành viên bán hàng nhập ngày hết hạn mới và xác nhận |
| Nguồn | F-09; BR-10 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** người thuê T có giấy phép đã hết hạn (trạng thái = đã hết hạn) và thành viên Bán hàng đặt `new_expiry_date = 2027-06-30`
- **Khi** việc gia hạn được xác nhận
- **Sau đó** `license.expiry_date` được cập nhật; `tenant.status` trở về `active`
- **Và** lịch sử giấy phép hiển thị thời hạn sử dụng trước đó và thời hạn sử dụng mới (FR-81)
- **Và** một email xác nhận sẽ được gửi tới Quản trị viên đối tượng thuê (FR-83: "Giấy phép được gia hạn")
- **Và** `new_expiry_date ≤ hôm nay` bị từ chối với HTTP 422

---

#### FR-80 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cho phép các thành viên Nhóm bán hàng tăng hoặc giảm số lượng chỗ ngồi trên giấy phép hiện tại của người thuê; giảm xuống dưới mức sử dụng hiện tại sẽ bị chặn.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Đội ngũ bán hàng |
| điều kiện tiên quyết | Người thuê nhà có giấy phép hoạt động |
| Cò súng | Thành viên bán hàng gửi điều chỉnh số lượng chỗ ngồi |
| Nguồn | F-09; BR-05 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** đối tượng thuê T có `seat_used = 95` và một thành viên Bán hàng cố gắng đặt `seat_count = 80`
- **Khi** điều chỉnh được gửi
- **Sau đó** hệ thống từ chối với HTTP 422: `"Không thể giảm số chỗ dưới mức sử dụng hiện tại (95 chỗ đang được sử dụng). Vui lòng hủy đăng ký học viên trước hoặc đặt số lượng cao hơn."`
- **Và** nếu `new_seat_count ≥ Seat_used`: `license.seat_count` cập nhật ngay lập tức; bảng điều khiển đối tượng thuê phản ánh hạn ngạch mới
- **Và** thay đổi được thêm vào lịch sử giấy phép (FR-81)

---

#### FR-81 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ duy trì lịch sử bất biến về tất cả các thay đổi giấy phép của mỗi người thuê; không có bản ghi lịch sử giấy phép nào có thể bị xóa bởi bất kỳ vai trò người dùng nào.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Hệ thống (tự động mỗi lần thay đổi giấy phép); Đội ngũ bán hàng; Quản trị viên cấp cao (chỉ đọc) |
| Điều kiện tiên quyết | Bất kỳ hành động tạo, mở rộng hoặc điều chỉnh giấy phép nào đều xảy ra |
| Cò súng | Sự kiện đổi giấy phép |
| Nguồn | F-09; F-08 |

**Tiêu chí chấp nhận (GWT):**
- **Được cấp** giấy phép được tạo và sau đó được gia hạn hai lần
- **Khi** thành viên Nhóm bán hàng hoặc Quản trị viên cấp cao mở lịch sử giấy phép của đối tượng thuê
- **Sau đó** hệ thống hiển thị tất cả 3 bản ghi theo thứ tự thời gian đảo ngược: ID giấy phép, create_by, create_at, Seat_count, Expiration_date, Last_modified_by, Last_modified_at, trạng thái (hoạt động/hết hạn/thay thế)
- **Và** không có kiểm soát xóa nào hiển thị đối với bất kỳ bản ghi giấy phép nào bất kể vai trò của người dùng
- **Và** mỗi bản ghi có thể mở rộng để hiển thị chi tiết kiểm tra đầy đủ

---

#### FR-82 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ hiển thị bảng cảnh báo hết hạn được ưu tiên trên bảng điều khiển Cổng bán hàng liệt kê những người thuê sẽ hết hạn trong vòng 30 ngày, được sắp xếp tăng dần theo số ngày còn lại.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Đội ngũ bán hàng |
| Điều kiện tiên quyết | Thành viên Nhóm bán hàng mở Cổng thông tin bán hàng |
| Cò súng | Tải trang tổng quan |
| Nguồn | F-09; UI-04 |

**Tiêu chí chấp nhận (GWT):**
- **Đưa ra** 5 người thuê nhà sẽ hết hạn giấy phép trong 30 ngày tới
- **Khi** tải bảng cảnh báo hết hạn
- **Sau đó** tất cả 5 đối tượng thuê được liệt kê được sắp xếp theo `ngày_cho đến_ngày hết hạn` tăng dần
- **Và** các cột: Tên người thuê, Ngày hết hạn, Số ngày còn lại, Số chỗ đã sử dụng/Tổng cộng, Email liên hệ, Gia hạn (nút)
- **Và** người thuê đã hết hạn (ngày = 0) xuất hiện ở trên cùng với trạng thái màu đỏ
- **Và** việc nhấp vào "Gia hạn" sẽ mở biểu mẫu gia hạn (FR-79) được điền trước cho đối tượng thuê đó

---

## F-10: Hệ thống thông báo (FR-83 – FR-87)

---

#### FR-83 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ gửi thông báo qua email cho tất cả các sự kiện kích hoạt đã xác định bằng cách sử dụng mẫu đã định cấu hình cho từng loại sự kiện và ngôn ngữ được cấu hình của đối tượng thuê; gửi không thành công sẽ được thử lại sau 5 phút.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Hệ thống (công việc thông báo) |
| Điều kiện tiên quyết | Dịch vụ email được cấu hình (SI-02); một sự kiện kích hoạt kích hoạt |
| Cò súng | Bất kỳ sự kiện kích hoạt nào được xác định (xem bảng bên dưới) |
| Nguồn | F-10; SI-02 (dịch vụ thư điện tử) |

**Sự kiện kích hoạt được xác định:**

| Cò súng | (Những) người nhận |
|---------|-------------|
| Buổi thi được công bố | Sinh viên đã đăng ký |
| T−24h trước khi bắt đầu phiên | Sinh viên đã đăng ký |
| T−1h trước khi bắt đầu phiên | Sinh viên đã đăng ký |
| Tự động chấm điểm Đọc/Nghe hoàn tất | Học sinh |
| Viết/Nói đang chờ xem xét | Giáo viên/Điều phối viên được chỉ định |
| Đã xác nhận điểm Viết/Nói | Học sinh |
| Hạn ngạch chỗ ngồi 80% | Quản trị viên thuê nhà |
| Chỉ tiêu chỗ ngồi 90% | Quản trị viên người thuê + Đội ngũ bán hàng |
| Giấy phép hết hạn 30 ngày | Quản trị viên người thuê + Đội ngũ bán hàng |
| Giấy phép hết hạn 7 ngày | Quản trị viên người thuê + Đội ngũ bán hàng |
| Đã tạo tài khoản (nhập số lượng lớn) | Sinh viên (mật khẩu tạm thời) |

**Tiêu chí chấp nhận (GWT):**
- **Được cung cấp** Kết quả Đọc/Nghe của học sinh sẽ có sẵn
- **Khi** công việc tính điểm hoàn thành (FR-29)
- **Sau đó** một thông báo qua email sẽ được đưa vào hàng đợi cho sinh viên với mẫu `RESULT_AVAILABLE`, được hiển thị bằng ngôn ngữ được định cấu hình của đối tượng thuê
- **Và** khi gửi thành công: `notification_log.delivery_status = đã gửi`
- **Và** khi thất bại: thử lại một lần sau 5 phút; nếu lần thử thứ hai không thành công: `delivery_status = failed` và cảnh báo sẽ hiển thị để giám sát Quản trị viên cấp cao
- **Và** nhà cung cấp dịch vụ email được gọi thông qua REST API (SI-02); nhà cung cấp có thể được chuyển đổi thông qua thay đổi cấu hình

---

#### FR-84 [Có điều kiện]

**Yêu cầu:** Hệ thống sẽ gửi thông báo đẩy tới học sinh trên Flutter Mobile (iOS/Android) về các sự kiện kích hoạt mà học sinh phải đối mặt (phiên đã xuất bản, T−24h, T−1h, có sẵn điểm), ngoài email; mã thông báo thiết bị cũ sẽ bị xóa khi giao hàng không thành công.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Hệ thống (công việc thông báo FCM) |
| điều kiện tiên quyết | Sinh viên đã cài đặt Flutter Mobile và được cấp quyền đẩy; OI-01 đã xác nhận di động trong phạm vi |
| Cò súng | Các yếu tố kích hoạt tương tự với học sinh như FR-83 |
| Nguồn | F-10; SI-03 (FCM); OI-01 |

**Tiêu chí chấp nhận (GWT):**
- **Đã cho** một sinh viên có mã thông báo thiết bị FCM đã đăng ký và một phiên được xuất bản
- **Khi** công việc thông báo kích hoạt
- **Sau đó** hệ thống sẽ gửi thông báo FCM có tiêu đề, nội dung và liên kết sâu tới màn hình liên quan
- **Và** nếu FCM trả về lỗi chưa đăng ký mã thông báo, mã thông báo cũ sẽ bị xóa khỏi cơ sở dữ liệu ngay lập tức
- **Và** thông báo đẩy được gửi cùng với thông báo qua email (không phải thay thế)
- **Lưu ý:** FR này có điều kiện - yêu cầu Flutter Mobile phải nằm trong phạm vi nền tảng (OI-01)

---

#### FR-85 [Cần thiết]

**Yêu cầu:** Hệ thống cho phép Quản trị viên cấp cao xem và chỉnh sửa mẫu email cho tất cả các loại thông báo; các mẫu sẽ hỗ trợ các phiên bản thay thế có thể thay đổi và tiếng Việt/tiếng Anh; các chỉnh sửa sẽ được phiên bản với khả năng khôi phục.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Siêu quản trị viên |
| Điều kiện tiên quyết | Quản trị viên cấp cao được xác thực trong Cổng thông tin nhà cung cấp |
| Cò súng | Quản trị viên cấp cao mở trình quản lý mẫu email và chỉnh sửa mẫu |
| Nguồn | F-10; SI-02 |

**Tiêu chí chấp nhận (GWT):**
- **Được cho** Quản trị viên cấp cao mở mẫu cho `RESULT_AVAILABLE`
- **Khi** Quản trị viên cấp cao chỉnh sửa chủ đề và nội dung rồi lưu
- **Sau đó** một phiên bản mẫu mới sẽ được tạo; phiên bản trước được giữ nguyên để khôi phục
- **Và** phần giữ chỗ biến (ví dụ: `{{student_name}}`, `{{session_name}}`, `{{session_date}}`) được đánh dấu trong trình chỉnh sửa và được xem trước bằng dữ liệu mẫu
- **Và** cả phiên bản tiếng Việt và tiếng Anh đều có thể chỉnh sửa độc lập thông qua bộ chọn ngôn ngữ
- **Và** mẫu được sử dụng cho từng đối tượng thuê được xác định theo ngôn ngữ được định cấu hình của đối tượng thuê (FR-72)

---

#### FR-86 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cho phép người dùng phía Bên thuê chọn không nhận các loại thông báo không quan trọng; các thông báo quan trọng (đã tạo tài khoản, điểm có sẵn, hết hạn giấy phép) sẽ không thể từ chối được.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Bất kỳ người dùng bên thuê nào |
| điều kiện tiên quyết | Người dùng được xác thực |
| Cò súng | Người dùng chuyển đổi tùy chọn thông báo trong hồ sơ của họ |
| Nguồn | F-10 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một học sinh mở tùy chọn thông báo và tắt "Lời nhắc bài kiểm tra"
- **Khi** công việc thông báo T−24h và T−1h chạy cho học sinh đó
- **Sau đó** email sẽ không được gửi đến học sinh đó (ưu tiên được tôn trọng)
- **Và** không thể tắt thông báo `score_available`, `account_created` và `license_expiry`; nút chuyển đổi cho các loại này không có hoặc bị khóa
- **Và** tùy chọn được lưu cho mỗi người dùng, không phải cho mỗi thiết bị

---

#### FR-87 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ ghi lại mọi nỗ lực thông báo với người nhận, loại, trình kích hoạt, dấu thời gian đã gửi, trạng thái gửi và phản hồi của nhà cung cấp; email bị trả lại sẽ gắn cờ tài khoản người nhận.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Hệ thống (dịch vụ thông báo) |
| điều kiện tiên quyết | Bất kỳ thông báo nào được gửi hoặc cố gắng |
| Cò súng | Phản hồi API dịch vụ email (thành công, thất bại, trả lại) |
| Nguồn | F-10; SI-02 |

**Tiêu chí chấp nhận (GWT):**
- **Đã cho** một thông báo qua email được gửi và nhà cung cấp trả về một webhook bị trả lại
- **Khi** webhook được xử lý
- **Sau đó** `notification_log.delivery_status = bị trả lại` được ghi lại; `user.email_bounced = true` được đặt trên tài khoản người nhận
- **Và** thông báo trong tương lai gửi tới tài khoản `email_bounced = true` được gắn cờ để xem xét trước khi gửi
- **Và** bản ghi nhật ký thông báo chứa: `recipient_id`, `notification_type`, `event_trigger`, `sent_at`, `delivery_status`, `provider_response`
- **Và** Quản trị viên cấp cao có thể xem thông báo bị lỗi và bị trả lại trong chế độ xem giám sát

---

## F-11: Luồng khách / thử nghiệm (FR-88 – FR-92) - Có điều kiện

---

#### FR-88 [Có điều kiện]

**Yêu cầu:** Hệ thống phải cung cấp trang đích dùng thử có thể truy cập công khai (không cần đăng nhập) với mô tả nền tảng, tóm tắt phạm vi thử nghiệm, tuyên bố từ chối trách nhiệm và lời kêu gọi hành động "Bắt đầu dùng thử" tải trong dưới 3 giây trên băng thông rộng tiêu chuẩn.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Khách mời (Người dùng thử) |
| điều kiện tiên quyết | Cụm tính năng F-11 (Khách/Dùng thử) được bật |
| Cò súng | Người dùng chưa được xác thực sẽ điều hướng đến URL dùng thử công khai |
| Nguồn | F-11; UI-10; DC-11 (từ chối trách nhiệm) |

**Tiêu chí chấp nhận (GWT):**
- **Cho** người dùng chưa được xác thực sẽ điều hướng đến URL dùng thử
- **Khi** tải trang
- **Sau đó** hệ thống hiển thị: mô tả nền tảng, danh sách các kỹ năng và phần có sẵn trong bản dùng thử, thời lượng dự kiến, tuyên bố từ chối trách nhiệm ("Đây là bài thi thử mô phỏng, không phải kỳ thi APTIS chính thức của Hội đồng Anh") và nút CTA "Bắt đầu thi thử"
- **Và** trang tải trong vòng 3 giây trên kết nối 10 Mbps
- **Và** không cần đăng nhập, nhập email hoặc tạo tài khoản để xem trang hoặc bắt đầu dùng thử

---

#### FR-89 [Có điều kiện]

**Yêu cầu:** Hệ thống sẽ cung cấp bài kiểm tra thực hành có giới hạn cho người dùng Khách bằng cách sử dụng bộ câu hỏi mẫu cố định do Nhà cung cấp định cấu hình; bài thi sử dụng giao diện bài thi giống như bài thi đã đăng ký.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Khách mời (Người dùng thử) |
| điều kiện tiên quyết | Bộ câu hỏi thử nghiệm được cấu hình bởi Quản trị viên cấp cao |
| Cò súng | Khách nhấn "Bắt đầu dùng thử" |
| Nguồn | F-11; F-03; OI-06 |

**Tiêu chí chấp nhận (GWT):**
- **Được** Khách nhấp vào "Bắt đầu dùng thử"
- **Khi** kỳ thi thử bắt đầu
- **Sau đó** hệ thống tạo một phiên ẩn danh (FR-08) và tải bộ câu hỏi dùng thử đã định cấu hình
- **Và** bản dùng thử sử dụng giao diện tương tự như FR-20–FR-23 (Đọc, Viết, Nghe, Nói như được định cấu hình trong phạm vi dùng thử)
- **Và** tất cả các tính năng hẹn giờ, âm thanh và ghi âm đều hoạt động giống hệt với bài thi đã đăng ký
- **Và** bộ câu hỏi dùng thử không được lấy từ ngân hàng câu hỏi của bất kỳ người thuê nào

---

#### FR-90 [Có điều kiện]

**Yêu cầu:** Hệ thống sẽ hiển thị bản tóm tắt kết quả đơn giản hóa cho Khách sau khi hoàn thành thử nghiệm, hiển thị mức ước tính cho các kỹ năng được ghi điểm, tuyên bố từ chối trách nhiệm và lời kêu gọi hành động "Liên hệ với bộ phận bán hàng".

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Khách mời (Người dùng thử) |
| Điều kiện tiên quyết | Khách đã hoàn thành bài thi thử (FR-89) |
| Cò súng | Nộp bài thi thử |
| Nguồn | F-11; DC-11 (từ chối trách nhiệm) |

**Tiêu chí chấp nhận (GWT):**
- **Được** Khách hàng hoàn thành bài thi thử
- **Khi** kết quả được tính toán (chỉ tính điểm tự động; không tính điểm AI cho bản dùng thử trừ khi được định cấu hình)
- **Sau đó** màn hình kết quả hiển thị: điểm ước tính cho mỗi kỹ năng đã thử, tuyên bố từ chối trách nhiệm: "Đây là kết quả thi thử mô phỏng — không phải điểm APTIS chính thức" và CTA nổi bật: "Muốn phát triển cho trường hoặc trung tâm của bạn? Liên hệ ngay"
- **Và** kết quả chỉ được hiển thị cho phiên ẩn danh hiện tại; chúng không được tồn tại sau khi hết phiên (FR-92)

---

#### FR-91 [Có điều kiện]

**Yêu cầu:** Hệ thống có thể nhắc người dùng Khách tùy ý cung cấp thông tin liên hệ sau khi có kết quả dùng thử; lời nhắc phải có sự đồng ý rõ ràng để theo dõi; giảm dần sẽ không lưu trữ dữ liệu.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Khách mời (Người dùng thử) |
| điều kiện tiên quyết | Khách đã xem kết quả dùng thử (FR-90) |
| Cò súng | Lời nhắc thu thập khách hàng tiềm năng hiển thị sau khi hiển thị kết quả |
| Nguồn | F-11; OI-06; tuân thủ quyền riêng tư |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một Khách đang xem kết quả dùng thử
- **Khi** lời nhắc thu thập khách hàng tiềm năng tùy chọn được hiển thị
- **Sau đó** lời nhắc hỏi tên và email kèm theo hộp kiểm đồng ý rõ ràng: "Tôi đồng ý được liên hệ lại về dịch vụ APTIS LMS"
- **Và** nếu Khách cung cấp thông tin và kiểm tra sự đồng ý: một bản ghi khách hàng tiềm năng sẽ được tạo (tên, email, sự đồng ý_timestamp, trial_result_summary) và Nhóm bán hàng sẽ được thông báo
- **Và** nếu Khách từ chối hoặc đóng lời nhắc mà không cung cấp thông tin: không có dữ liệu nào được lưu trữ
- **Và** hộp kiểm đồng ý không được chọn theo mặc định; kiểm tra trước nó không được phép

---

#### FR-92 [Có điều kiện]

**Yêu cầu:** Hệ thống sẽ tự động xóa tất cả dữ liệu phiên Khách/Phiên dùng thử (phiên ẩn danh, câu trả lời dùng thử, kết quả dùng thử) sau một khoảng thời gian lưu giữ có thể định cấu hình thông qua công việc được lên lịch hàng ngày; quá trình thanh lọc sẽ được ghi lại với số lượng bản ghi nhưng không có PII.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Hệ thống (công việc thanh lọc theo lịch trình) |
| điều kiện tiên quyết | Phiên dùng thử ẩn danh tồn tại lâu hơn khoảng thời gian lưu giữ đã định cấu hình |
| Cò súng | Công việc thanh lọc theo lịch trình hàng ngày |
| Nguồn | F-11; OI-07 (thời gian lưu giữ TBD) |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một phiên dùng thử ẩn danh đã được tạo tại dấu thời gian T và `current_time - T > duy trì_days`
- **Khi** công việc thanh lọc hàng ngày chạy
- **Sau đó** hệ thống xóa: `anonymous_session`, các bản ghi `trial_exam_answers`, `trial_result` được liên kết
- **Và** các bản ghi khách hàng tiềm năng được ghi lại qua FR-91 tuân theo chính sách lưu giữ riêng (dài hơn) do Bộ phận bán hàng xác định
- **Và** công việc thanh lọc sẽ ghi vào `audit_log`: `{job_name, run_at, record_deleted_count}` (không có PII trong nhật ký)
- **Và** nếu khoảng thời gian lưu giữ chưa được định cấu hình (mở OI-07), công việc thanh lọc sẽ chạy nhưng không xóa bất kỳ bản ghi nào; nó ghi lại: "Đã bỏ qua quá trình thanh lọc — số ngày lưu giữ không được định cấu hình"

---

## F-12: Tính liêm chính trong bài thi/ Chống gian lận (FR-93 – FR-103)

---

#### FR-93 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ sắp xếp ngẫu nhiên thứ tự các câu hỏi trong mỗi phần thi cho mỗi lần thi mới bằng cách sử dụng một hạt giống duy nhất được lưu trữ trong lần thi đó, đảm bảo thứ tự tương tự được khôi phục trong sơ yếu lý lịch.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Hệ thống (cố gắng khởi tạo) |
| điều kiện tiên quyết | Một bản ghi `exam_attempt` mới đang được tạo (FR-17) |
| Cò súng | Khởi tạo bài kiểm tra |
| Nguồn | F-12; BR-14 (xáo trộn mỗi lần thử); FR-106 (sơ yếu lý lịch) |

**Tiêu chí chấp nhận (GWT):**
- **Cho** hai học sinh bắt đầu cùng một buổi thi cùng một lúc
- **Khi** nỗ lực của họ được khởi tạo
- **Sau đó** mỗi lần thử sẽ nhận được một hạt giống ngẫu nhiên duy nhất; thứ tự câu hỏi trong mỗi phần được xáo trộn bằng cách sử dụng hạt giống đó
- **Và** hạt giống được lưu trữ trong `exam_attempt.shuffle_seed`
- **Và** khi một học sinh tiếp tục lại sau khi ngắt kết nối (FR-106), cùng một hạt giống sẽ khôi phục thứ tự câu hỏi tương tự - học sinh sẽ thấy thứ tự giống hệt trước khi ngắt kết nối
- **Và** mọi học sinh trong cùng một buổi học có xác suất nhận được thứ tự câu hỏi giống nhau rất thấp

---

#### FR-94 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ sắp xếp ngẫu nhiên thứ tự các phương án trả lời MCQ cho mỗi lần thử sử dụng cùng một hạt giống xáo trộn như thứ tự câu hỏi; tính điểm tự động sẽ khớp với nội dung câu trả lời chứ không phải vị trí tùy chọn.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Hệ thống (cố gắng khởi tạo) |
| điều kiện tiên quyết | Các câu hỏi MCQ có trong mẫu đề thi |
| Cò súng | Câu hỏi MCQ được đưa ra cho học sinh |
| Nguồn | F-12; BR-14; FR-93 |

**Tiêu chí chấp nhận (GWT):**
- **Đưa ra** câu hỏi MCQ có các phương án trả lời [A, B, C, D]
- **Khi** nó được hiển thị cho nỗ lực của học sinh
- **Sau đó** các tùy chọn được xáo trộn bằng cách sử dụng hạt giống thử; học sinh thấy các lựa chọn theo thứ tự khác (ví dụ: [C, A, D, B])
- **Và** tính năng tự động chấm điểm (FR-27) khớp với nội dung câu trả lời (văn bản của phương án đúng), không phải theo vị trí ký tự phương án ban đầu
- **Và** thứ tự xáo trộn nhất quán cho cùng một học sinh trong các phiên tiếp tục (áp dụng cùng một hạt giống)

---

#### FR-95 [Cần thiết]

**Yêu cầu:** Hệ thống yêu cầu học sinh vào chế độ toàn màn hình trước khi bắt đầu thi; kỳ thi sẽ không bắt đầu cho đến khi toàn màn hình được xác nhận là hoạt động; thoát khỏi chế độ toàn màn hình trong kỳ thi sẽ gây ra sự kiện vi phạm.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Học sinh |
| Điều kiện tiên quyết | Học sinh đã vượt qua bài kiểm tra trước kỳ thi (FR-18) |
| Cò súng | Học sinh cố gắng tham gia kỳ thi; phát hiện thoát toàn màn hình giữa kỳ thi |
| Nguồn | F-12; FR-18; FR-96 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một học sinh đang ở trên màn hình trước kỳ thi
- **Khi** học sinh nhấp vào "Vào bài kiểm tra"
- **Sau đó** hệ thống yêu cầu chế độ toàn màn hình thông qua API nền tảng; bài kiểm tra không bắt đầu cho đến khi toàn màn hình được xác nhận đang hoạt động
- **Và** nếu người dùng từ chối toàn màn hình: nút "Nhập bài kiểm tra" bị tắt; hướng dẫn bật toàn màn hình được hiển thị
- **Và** nếu học sinh thoát khỏi chế độ toàn màn hình giữa kỳ thi (sự kiện thay đổi toàn màn hình): một sự kiện vi phạm được ghi lại với `violation_type = fullscreen_exit` (FR-101); áp dụng logic ngưỡng vi phạm (FR-100)
- **Và** trên Flutter Desktop: toàn màn hình được thực thi ở cấp cửa sổ hệ điều hành; trên Flutter Web: API toàn màn hình của trình duyệt được sử dụng

---

#### FR-96 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ phát hiện khi học sinh chuyển sang tab trình duyệt khác hoặc thu nhỏ cửa sổ bài kiểm tra trong một bài kiểm tra đang diễn ra và ghi lại mỗi lần xảy ra dưới dạng sự kiện vi phạm; số lượng vi phạm sẽ tích lũy theo ngưỡng được định cấu hình.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Học sinh (hành động vô ý hoặc cố ý); Hệ thống (phát hiện) |
| điều kiện tiên quyết | Học sinh có một bài thi `in_progress` đang hoạt động |
| Cò súng | Sự kiện `visibilitychange` của trình duyệt/ứng dụng kích hoạt với `document.hidden = true`; hoặc sự kiện làm mờ cửa sổ |
| Nguồn | F-12; FR-100; FR-101 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một học sinh đang tham gia một kỳ thi đang diễn ra và chuyển sang tab trình duyệt khác
- **Khi** sự kiện `visibilitychange` kích hoạt
- **Sau đó** hệ thống ghi lại `sự kiện vi phạm`: `{attempt_id, vi phạm_type = "tab_switch", dấu thời gian, tích lũy_count}`
- **Và** `violation_count` được tăng lên
- **Và** nếu `violation_count = Warning_threshold`: một cảnh báo lớp phủ được hiển thị cho học sinh (FR-100)
- **Và** nếu `violation_count = terminating_threshold`: bài kiểm tra được gửi tự động (FR-100)

---

#### FR-97 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ phát hiện tình trạng mất tiêu điểm ở cấp độ hệ điều hành trên Flutter Desktop (Alt-Tab, thu nhỏ cửa sổ) và ghi lại sự kiện đó dưới dạng sự kiện vi phạm `focus_loss` góp phần vào bộ đếm vi phạm tương tự như chuyển đổi tab.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Học sinh; Hệ thống (phát hiện) |
| Điều kiện tiên quyết | Học sinh có bài kiểm tra đang hoạt động trên Flutter Desktop |
| Cò súng | Sự kiện rung `AppLifecycleState.inactive` hoặc mất tiêu điểm cửa sổ |
| Nguồn | F-12; FR-96; FR-101 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một học sinh đang tham gia kỳ thi Flutter Desktop và Alt-Tab cho một ứng dụng khác
- **Khi** ứng dụng Flutter mất tiêu điểm cửa sổ cấp hệ điều hành
- **Sau đó** hệ thống ghi lại `sự kiện vi phạm`: `{attempt_id, vi phạm_type = "focus_loss", dấu thời gian, tích lũy_count}`
- **Và** số `violation_count` tương tự được sử dụng trong FR-96 được tăng lên; logic ngưỡng (FR-100) được áp dụng giống hệt nhau
- **Và** trên Flutter Web: API hiển thị tài liệu phát hiện sự kiện tương đương

---

#### FR-98 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ âm thầm chặn các hành động sao chép (Ctrl+C), dán (Ctrl+V) và nhấp chuột phải vào menu ngữ cảnh trong tất cả các vùng nội dung bài kiểm tra; việc lựa chọn văn bản trong đoạn đọc sẽ bị vô hiệu hóa; đầu vào ghi sẽ cho phép gõ nhưng chặn dán clipboard.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Học sinh |
| điều kiện tiên quyết | Học sinh đang tích cực thi |
| Cò súng | Học sinh thực hiện hành động bị chặn trong khu vực nội dung bài kiểm tra |
| Nguồn | F-12 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một học sinh đang đọc đoạn Đọc và thử Ctrl+C
- **Khi** sự kiện bàn phím kích hoạt
- **Sau đó** sự kiện bị chặn và hủy bỏ; bảng nhớ tạm không được sửa đổi; không có cảnh báo nào được hiển thị cho học sinh
- **Và** nhấp chuột phải vào khu vực nội dung bài kiểm tra sẽ không mở ra menu ngữ cảnh
- **Và** Vùng văn bản viết (FR-21) chấp nhận kiểu gõ bàn phím thông thường; Ctrl+V bị chặn trong đầu vào Viết
- **Và** việc chặn không áp dụng cho các nút điều hướng bài kiểm tra, màn hình hẹn giờ hoặc các khu vực giao diện người dùng không có nội dung

---

#### FR-99 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ chặn nút quay lại của trình duyệt, điều hướng thanh địa chỉ, làm mới F5/Ctrl+R và đóng cửa sổ trong khi khám đang hoạt động; một hộp thoại cảnh báo sẽ xuất hiện khi cố gắng điều hướng đi; tải lại trang sẽ kích hoạt luồng tiếp tục (FR-106).

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Học sinh |
| điều kiện tiên quyết | Học sinh đang tích cực thi |
| Cò súng | Học sinh thử thực hiện hành động điều hướng trong trình duyệt |
| Nguồn | F-12; FR-106 (sơ yếu lý lịch) |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một học sinh đang tham gia một kỳ thi tích cực
- **Khi** học sinh nhấn nút quay lại của trình duyệt
- **Sau đó** điều hướng quay lại bị chặn; một thông báo trong ứng dụng hiển thị "Bạn không thể điều hướng quay lại trong khi thi"; bài kiểm tra vẫn dựa trên câu hỏi hiện tại
- **Và** đóng cửa sổ / điều hướng thanh địa chỉ sẽ kích hoạt hộp thoại `trước khi tải` của trình duyệt: "Bạn có chắc chắn muốn rời khỏi không? Tiến trình của bạn sẽ được lưu."
- **Và** nếu học sinh xác nhận rời đi (hoặc trình duyệt gặp sự cố): luồng sơ yếu lý lịch (FR-106) sẽ khôi phục tất cả các câu trả lời đã lưu trong lần truy cập tiếp theo
- **Và** Việc làm mới F5/Ctrl+R bị chặn ở nơi nền tảng hỗ trợ nó; nếu quá trình tải lại xảy ra, hãy tiếp tục xử lý quá trình khôi phục

---

#### FR-100 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ thực thi các ngưỡng vi phạm có thể định cấu hình cho mỗi phiên thi: hiển thị cảnh báo trong bài kiểm tra khi `violation_count` đạt đến `warning_threshold` và tự động gửi lượt thử khi `violation_count` đạt đến `terminate_threshold`.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Hệ thống (thực thi tự động) |
| điều kiện tiên quyết | Cấu hình chống gian lận được cài đặt trong buổi thi (FR-37); học sinh có một nỗ lực tích cực |
| Cò súng | Số lượng vi phạm đạt đến giá trị ngưỡng |
| Nguồn | F-12; OI-04 (giá trị mặc định TBD) |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một buổi thi có `warning_threshold = W` và `terminate_threshold = T`
- **Khi** số `vi phạm` của học sinh đạt đến W
- **Sau đó** một cảnh báo lớp phủ được hiển thị: "Cảnh báo: Bạn đã rời khỏi bài kiểm tra [W] lần. Nếu bạn rời khỏi [T−W] lần nữa, bài kiểm tra của bạn sẽ tự động được gửi."
- **Và** khi `violation_count` đạt đến T: hệ thống buộc gửi bài thi (luồng FR-26), đánh dấu `exam_attempt.terminated_by_violation = true` và thông báo cho Điều phối viên bài kiểm tra qua màn hình trực tiếp (FR-39)
- **Và** không thể sửa đổi ngưỡng sau khi phiên đã bắt đầu (đã tạo lần thử đầu tiên)
- **Và** giá trị mặc định: `warning_threshold` và `terminate_threshold` là các giá trị mặc định trên toàn hệ thống có thể định cấu hình do Quản trị viên cấp cao đặt [TBD: các giá trị đang chờ giải quyết OI-04]

---

#### FR-101 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ duy trì nhật ký bất biến về tất cả các sự kiện vi phạm chống gian lận trong mỗi lần thử, lưu trữ loại vi phạm, dấu thời gian và số lượng tích lũy tại thời điểm xảy ra mỗi sự kiện; không có vai trò người dùng nào có thể xóa hồ sơ vi phạm.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Hệ thống (ghi nhật ký tự động) |
| điều kiện tiên quyết | Phát hiện bất kỳ sự kiện vi phạm nào (FR-95–FR-97) |
| Cò súng | Phát hiện sự kiện vi phạm |
| Nguồn | F-12; DC-10 (bất biến nhật ký vi phạm) |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một học sinh gây ra vi phạm tab_switch
- **Khi** vi phạm được xử lý
- **Sau đó** một bản ghi `violation_event` được tạo: `{id, Exam_attempt_id, vi phạm_type (tab_switch | focus_loss | fullscreen_exit | copy_paste_attempt), dấu thời gian, tích lũy_count_at_time}`
- **Và** không có điểm cuối xóa nào tồn tại đối với `violation_events` bất kể vai trò của người gọi
- **Và** Việc thanh lọc hồ sơ vi phạm của Quản trị viên cấp cao chỉ tuân theo chính sách lưu giữ dữ liệu (thanh lọc hàng loạt với quy tắc lưu giữ OI-07), chứ không phải xóa hồ sơ cá nhân
- **Và** các sự kiện vi phạm được hiển thị cho Điều phối viên kỳ thi trong màn hình trực tiếp (FR-39) và trong báo cáo về tính toàn vẹn sau phiên (FR-103)

---

#### FR-102 [Có điều kiện]

**Yêu cầu:** Hệ thống sẽ yêu cầu khóa cửa sổ cấp hệ điều hành trên Flutter Desktop để ngăn học sinh chuyển sang ứng dụng khác trong kỳ thi; trong trường hợp khóa cấp hệ điều hành không khả dụng, hệ thống sẽ chuyển sang ghi nhật ký vi phạm dựa trên phát hiện.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Hệ thống (điều khiển cấp hệ điều hành); Học sinh |
| Điều kiện tiên quyết | Sinh viên khởi chạy Exam Client trên Flutter Desktop (Windows hoặc macOS) |
| Cò súng | Kỳ thi bắt đầu (FR-18 hoàn thành) |
| Nguồn | F-12; OI-01 (TBD phạm vi nền tảng) |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một học sinh bắt đầu bài kiểm tra trên Flutter Desktop (Windows)
- **Khi** kỳ thi bắt đầu
- **Sau đó** hệ thống yêu cầu chế độ cửa sổ luôn ở trên cùng và cố gắng vô hiệu hóa quyền truy cập vào thanh tác vụ thông qua các API Windows có sẵn
- **Và** trên macOS: hệ thống yêu cầu chế độ toàn màn hình để tắt Mission Control khi API cho phép
- **Và** nếu không thể thiết lập khóa cấp hệ điều hành (không đủ quyền): hệ thống sẽ ghi nhật ký `kiosk_mode_unavailable = true` trong lần thử và quay lại ghi nhật ký vi phạm dựa trên phát hiện (FR-96, FR-97)
- **Và** học sinh sẽ nhận được thông báo trước kỳ thi nếu chế độ kiosk không kích hoạt được: "Không thể bật chế độ kiosk. Hoạt động thi của bạn sẽ vẫn được theo dõi."
- **Lưu ý:** FR này có điều kiện - yêu cầu Flutter Desktop phải nằm trong phạm vi nền tảng (OI-01)

---

#### FR-103 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ tạo báo cáo về tính toàn vẹn của mỗi phiên mà Điều phối viên kỳ thi và Quản trị viên người thuê có thể truy cập sau khi phiên kết thúc, liệt kê tất cả học sinh với số lượng, loại và kết quả vi phạm; báo cáo sẽ có thể xuất sang Excel.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Điều phối viên kỳ thi; Quản trị viên thuê nhà |
| Điều kiện tiên quyết | Một buổi thi đã bị đóng (tất cả các bài thi đã nộp hoặc phiên đã kết thúc) |
| Cò súng | Điều phối viên hoặc Quản trị viên đối tượng thuê mở báo cáo tính toàn vẹn của phiên |
| Nguồn | F-12; UI-07 |

**Tiêu chí chấp nhận (GWT):**
- **Đưa** một buổi thi bế mạc với 30 học sinh
- **Khi** Điều phối viên mở báo cáo tính toàn vẹn của phiên
- **Sau đó** hệ thống hiển thị bảng: Tên học sinh, Tổng số vi phạm, Số lần chuyển đổi tab, Số lần mất tiêu điểm, Số lần thoát toàn màn hình, Kết quả (Không vi phạm / Mức cảnh báo / Bị chấm dứt bởi hệ thống)
- **Và** học viên bị tự động chấm dứt theo ngưỡng vi phạm được đánh dấu trực quan bằng màu đỏ
- **Và** báo cáo có thể xuất sang Excel; tất cả các hàng đều được bao gồm bất kể phân trang bảng
- **Và** báo cáo có sẵn ngay sau khi kết thúc phiên mà không cần bước tính toán bổ sung

---

## F-13: Kiểm tra liên tục — Xuyên suốt (FR-104 – FR-111)

---

#### FR-104 [Cần thiết]

**Yêu cầu:** Hệ thống theo dõi thời gian làm bài thi độc quyền trên máy chủ; máy khách sẽ đồng bộ hóa thời gian hiển thị từ máy chủ cứ sau 10 giây; Thao tác đồng hồ phía máy khách sẽ không ảnh hưởng đến bộ đếm thời gian phía máy chủ hoặc hết hạn một phần.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Hệ thống (bộ hẹn giờ phía máy chủ); Sinh viên (người tiêu dùng trưng bày) |
| điều kiện tiên quyết | Học sinh đang có một phần thi đang diễn ra |
| Cò súng | Phần bắt đầu; cuộc thăm dò đồng bộ hóa máy khách cứ sau 10 giây |
| Nguồn | F-13; DC-04 (ủy thác hẹn giờ); FR-19 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một học sinh đang đọc Phần C với thời lượng 8 phút part_duration
- **Khi** khách hàng thăm dò ý kiến ​​về `time_remaining`
- **Sau đó** máy chủ trả về: `part_duration_seconds - (current_server_time - part_start_time)` tính bằng giây
- **Và** máy khách hiển thị giá trị này; nếu đồng hồ máy khách hiển thị một giá trị khác, giá trị máy chủ sẽ ghi đè
- **Và** khi `time_remaining ≤ 0` trên máy chủ: máy chủ đóng phần (FR-19) và từ chối gửi câu trả lời tiếp theo bằng HTTP 409
- **Và** thao tác của máy khách đối với bộ đếm thời gian được hiển thị (ví dụ: thông qua công cụ phát triển của trình duyệt) không ảnh hưởng đến tính toán phía máy chủ

---

#### FR-105 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ lưu giữ mọi câu trả lời của học sinh về máy chủ ngay khi vào; nộp đợt vào cuối kỳ thi sẽ không được sử dụng làm cơ chế duy trì chính; câu trả lời chưa được lưu sẽ được thử lại tối đa 3 lần do lỗi mạng.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Học sinh |
| Điều kiện tiên quyết | Học sinh đang tích cực thi |
| Cò súng | Học sinh chọn một phương án MCQ; học sinh tạm dừng nhập vào trường văn bản (gỡ lỗi 1 giây) |
| Nguồn | F-13; DC-05 (ủy thác kiên trì) |

**Tiêu chí chấp nhận (GWT):**
- **Cho** học sinh chọn nút radio MCQ trong Phần Đọc A
- **Khi** sự kiện lựa chọn kích hoạt
- **Sau đó** khách hàng ngay lập tức gửi `PATCH /api/v1/exam/attempts/{attempt_id}/answers` kèm theo `{question_id, answer_value}`
- **Và** máy chủ cập nhật `exam_state` cho câu hỏi đó; trả về HTTP 200 khi thành công
- **Và** khi mạng bị lỗi: máy khách thử lại tối đa 3 lần (độ trễ: 1 giây, 2 giây, 4 giây); câu trả lời được giữ trong bộ nhớ máy khách trong quá trình thử lại
- **Và** một chỉ báo trực quan hiển thị "Đã lưu" (dấu kiểm) khi thành công hoặc "Đang lưu..." trong khi thử lại
- **Và** việc gửi bài kiểm tra (FR-26) là lệnh gọi quyết toán; nó không chuyển dữ liệu chưa tồn tại, nó chỉ thay đổi `attempt.status`

---

#### FR-106 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cho phép học sinh bị ngắt kết nối trong khi thi tiếp tục lại từ trạng thái đã lưu gần đây nhất, bao gồm phần hiện tại, vị trí câu hỏi, tất cả các câu trả lời đã lưu trước đó và thời gian được máy chủ cho phép còn lại.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Học sinh |
| Điều kiện tiên quyết | `exam_attempt.status = in_progress`; sinh viên kết nối lại sau khi ngắt kết nối |
| Cò súng | Học sinh mở ứng dụng thi và đăng nhập sau khi ngắt kết nối |
| Nguồn | F-13; DC-05; FR-105 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một học sinh bị ngắt kết nối trong phần Đọc Phần C với 12 câu trả lời được lưu
- **Khi** học sinh mở lại ứng dụng và đăng nhập
- **Sau đó** hệ thống phát hiện lần thử `in_progress` và hiển thị: "Bạn có một bài kiểm tra đang hoạt động. Tiếp tục từ nơi bạn đã dừng lại?" bằng nút Tiếp tục
- **Và** nhấp vào Tiếp tục: máy khách tìm nạp `exam_state` (tất cả 12 câu trả lời đã lưu), phần hiện tại, chỉ mục câu hỏi hiện tại và `time_remaining` từ máy chủ
- **Và** bài thi tiếp tục hiển thị các câu trả lời đã lưu của học sinh và thời gian còn lại chính xác (thời gian đã trôi qua trong quá trình ngắt kết nối được máy chủ tính)
- **Và** nếu cửa sổ phiên thi hết hạn trong khi ngắt kết nối: bài thi sẽ tự động được gửi cùng với tất cả các câu trả lời đã lưu và `force_submit_on_session_close = true`

---

#### FR-107 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ phát hiện mất kết nối mạng trong khi khám và hiển thị chỉ báo không chặn liên tục; học sinh sẽ có thể tiếp tục trả lời các câu hỏi với các câu trả lời được ghi sẵn tại địa phương; các câu trả lời được lưu vào bộ đệm sẽ được gửi đến máy chủ khi kết nối lại.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Học sinh |
| điều kiện tiên quyết | Học sinh đang tích cực thi |
| Cò súng | Sự kiện mất kết nối mạng |
| Nguồn | F-13; HW-04 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một học sinh mất kết nối mạng trong khi viết Phần B
- **Khi** mạng ngoại tuyến
- **Sau đó** hệ thống hiển thị một biểu ngữ liên tục: "Mất kết nối — tiến trình của bạn đang được lưu cục bộ. Đang kết nối lại..." bằng một vòng quay
- **Và** học sinh có thể tiếp tục gõ vào vùng văn bản Viết; tổ hợp phím được lưu vào bộ nhớ máy khách
- **Và** khi mạng được khôi phục: tất cả các câu trả lời được lưu vào bộ đệm sẽ được chuyển đến máy chủ (luồng thử lại FR-105); biểu ngữ ngoại tuyến được thay thế bằng xác nhận ngắn gọn "Đã kết nối"
- **Và** nếu thời lượng ngoại tuyến vượt quá 5 phút: một cảnh báo nổi bật hơn sẽ hiển thị: "Bạn đã ngoại tuyến được 5 phút. Vui lòng thông báo cho giám thị của bạn."

---

#### FR-108 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ ghi âm thanh Nói vào bộ đệm cục bộ và tải lên Cloud Storage trong hoặc ngay sau khi ghi; khi tải lên không thành công, bộ đệm cục bộ sẽ được giữ lại và thử lại với thời gian chờ theo cấp số nhân mà không ngăn học sinh tiếp tục.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Học sinh |
| điều kiện tiên quyết | Học sinh đang ở phần Nói; micro có sẵn |
| Cò súng | Bắt đầu ghi âm giọng nói (FR-23) |
| Nguồn | F-13; SI-01; HW-01 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một học sinh đang ghi âm phần Nói B
- **Khi** quá trình ghi đang được tiến hành
- **Sau đó** dữ liệu âm thanh được ghi vào bộ đệm cục bộ (IndexedDB cho Flutter Web; hệ thống tệp nền tảng cho Flutter Desktop) trong thời gian thực
- **Và** hệ thống cố gắng tải từng đoạn lên Cloud Storage trong quá trình ghi; bộ đệm còn lại được tải lên khi dừng ghi
- **Và** khi tải lên không thành công: hệ thống thử lại với thời gian chờ theo cấp số nhân (độ trễ: 5 giây, 10 giây, 30 giây, 1 phút, 2 phút)
- **Và** nếu tất cả các lần thử lại đều không thành công: bộ đệm cục bộ được giữ nguyên và được đánh dấu `pending_upload = true`; học sinh tiến tới phần Nói tiếp theo mà không bị gián đoạn
- **Và** Điều phối viên kỳ thi được thông báo qua màn hình trực tiếp (FR-39) rằng âm thanh của học sinh này đang chờ tải lên

---

#### FR-109 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ lưu giữ và tải lên một phần bản ghi Nói khi quá trình ghi bị gián đoạn giữa chừng; các bản ghi một phần sẽ được gắn cờ để giáo viên xem xét thủ công và không được tự động loại bỏ.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Hệ thống (khi phát hiện gián đoạn) |
| Điều kiện tiên quyết | Đang ghi âm Bài phát biểu thì xảy ra gián đoạn (ngắt kết nối, gặp sự cố) |
| Cò súng | Sinh viên kết nối lại; bộ đệm một phần được phát hiện |
| Nguồn | F-13; OI-08 |

**Tiêu chí chấp nhận (GWT):**
- **Đưa** quá trình ghi Phần C của một học sinh bị gián đoạn sau 20 giây của cửa sổ ghi 40 giây
- **Khi** học sinh kết nối lại
- **Sau đó** bộ đệm âm thanh một phần (20 giây) được tải lên Cloud Storage với siêu dữ liệu `partial_recording = true` và `interruption_reason`
- **Và** `exam_state` đánh dấu Phần Nói C là `partial_recorded`
- **Và** quy trình chấm điểm AI (FR-30) xử lý một phần âm thanh bằng chú thích: "Ghi một phần — {N} giây trong số {M} giây được ghi"
- **Và** hàng đợi đánh giá của Giáo viên (FR-32) hiển thị chỉ báo "Ghi một phần" cho các phần bị ảnh hưởng
- **Và** các bản ghi một phần không bị âm thầm loại bỏ; Giáo viên được yêu cầu xem xét và có thể cho điểm thủ công

---

#### FR-110 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ phát hiện lỗi micrô khi bắt đầu kỹ năng Nói và cung cấp cho học sinh các bước khắc phục sự cố cũng như khả năng thử lại; bài kiểm tra sẽ không tự động kết thúc do lỗi micrô; học sinh có thể ra hiệu cho giám thị.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Học sinh |
| Điều kiện tiên quyết | Học sinh đã đạt được kỹ năng Nói (đã vượt qua quá trình kiểm tra micrô trước kỳ thi hoặc bị bỏ qua do giám thị ghi đè) |
| Cò súng | Yêu cầu truy cập micrô không thành công (quyền bị từ chối, không tìm thấy thiết bị, lỗi thiết bị) |
| Nguồn | F-13; HW-01; FR-18; OI-08 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** một học sinh đạt đến Phần Nói A và trình duyệt từ chối cấp quyền sử dụng micrô
- **Khi** hệ thống cố gắng truy cập vào micrô
- **Sau đó** hệ thống sẽ hiển thị màn hình khắc phục sự cố với: thông báo lỗi cụ thể (ví dụ: "Quyền truy cập micrô bị từ chối"), hướng dẫn từng bước dành riêng cho nền tảng để bật quyền và nút "Thử lại"
- **Và** nhấp vào Thử lại yêu cầu quyền sử dụng micrô; nếu được chấp nhận, kỳ thi tiếp tục bình thường
- **Và** nếu tất cả các lần thử lại đều không thành công: học sinh sẽ thấy hai tùy chọn: (A) "Giám thị tín hiệu" — gửi thông báo đến Điều phối viên bài thi trên màn hình trực tiếp (FR-39) với trạng thái "Lỗi micrô - học sinh cần hỗ trợ"; (B) "Bỏ qua phần Nói" — đánh dấu phần Nói là `skipped_due_to_device_error`, Giáo viên sẽ được thông báo
- **Và** kỳ thi không tự động kết thúc do lỗi micrô; lần thử vẫn ở trạng thái `in_progress` đang chờ giám thị can thiệp

---

#### FR-111 [Cần thiết]

**Yêu cầu:** Hệ thống sẽ cho phép học sinh khôi phục hoàn toàn buổi thi của mình sau khi trình duyệt gặp sự cố hoặc buộc đóng ứng dụng, khôi phục tất cả các câu trả lời đã lưu trước đó và tiếp tục với bộ đếm thời gian do máy chủ ủy quyền; Âm thanh giọng nói được lưu vào bộ nhớ đệm cục bộ trước khi xảy ra sự cố sẽ được tải lên khi kết nối lại.

| Cánh đồng | Giá trị |
|-------|-------|
| Diễn viên | Học sinh |
| điều kiện tiên quyết | Học sinh đã thi `in_progress` khi xảy ra sự cố; học sinh mở lại ứng dụng trong cửa sổ phiên |
| Cò súng | Học sinh khởi chạy lại trình duyệt/ứng dụng sau sự cố |
| Nguồn | F-13; FR-106 (sơ yếu lý lịch); FR-108 (bộ đệm âm thanh); OI-08 |

**Tiêu chí chấp nhận (GWT):**
- **Cho** trình duyệt của học sinh bị đóng trong khi viết Phần B với 8 câu trả lời được lưu
- **Khi** học sinh mở lại trình duyệt trong cửa sổ phiên thi và đăng nhập
- **Sau đó** hệ thống phát hiện lần thử `in_progress` và tự động kích hoạt quy trình tiếp tục (FR-106)
- **Và** tất cả 8 câu trả lời đã lưu trước đó đều được khôi phục từ `exam_state` phía máy chủ
- **Và** bộ đệm cục bộ âm thanh Nói (FR-108) được chọn; mọi âm thanh được lưu vào bộ đệm chưa được tải lên trước khi xảy ra sự cố sẽ được tải lên khi kết nối lại
- **Và** nếu cửa sổ phiên hết hạn trong lúc xảy ra sự cố: lượt thử sẽ tự động được gửi cùng với tất cả dữ liệu đã tồn tại và được gắn cờ `force_submit_on_crash = true` để Điều phối viên xem xét
- **Và** học sinh không nhận được hình phạt trừng phạt nào đối với một lỗi kỹ thuật rõ ràng (tai nạn) khác với hành vi cố ý điều hướng đi (FR-99)