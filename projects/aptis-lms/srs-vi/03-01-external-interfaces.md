# SRS §3.1 — Yêu cầu về giao diện bên ngoài
## APTIS LMS
**Phiên bản:** 1.0 | **Ngày:** 2026-06-16 | **Trạng thái:** BẢN THẢO

---

## 3.1.1 Giao diện người dùng

### UI-01: Cổng thông tin nhà cung cấp — Bảng điều khiển dành cho quản trị viên
**Diễn viên:** Siêu quản trị viên | **Nền tảng:** Flutter Web

Bảng điều khiển dành cho quản trị viên trình bày tổng quan về hệ thống toàn cầu với:
- Bảng danh sách đối tượng thuê: tên, slug, trạng thái (đang hoạt động/bị đình chỉ/hết hạn/hết hạn), số giấy phép (đã sử dụng/tổng ​​cộng), ngày hết hạn, hoạt động cuối cùng. Có thể sắp xếp theo tất cả các cột; có thể tìm kiếm theo tên hoặc sên.
- Trạng thái được mã hóa màu: xanh = hoạt động >30 ngày, vàng = hết hạn 30 ngày, đỏ = hết hạn hoặc bị đình chỉ.
- Các nút hành động dành cho người thuê: Xem chi tiết, Tạm dừng, Kích hoạt lại (có hộp thoại xác nhận cho các hành động phá hoại).
- Bảng tình trạng hệ thống: Tỷ lệ lỗi API, độ sâu hàng đợi (điểm AI), thông báo lỗi gần đây.

**Yêu cầu về giao diện người dùng:** Bảng dữ liệu phân trang theo 50 hàng. Các hành động phá hoại (Tạm dừng, Ngừng hoạt động) yêu cầu hộp thoại xác nhận đã nhập ("Nhập tên đối tượng thuê để xác nhận"). Tất cả dấu thời gian được hiển thị theo múi giờ trình duyệt của nhà điều hành trừ khi được định cấu hình khác.

---

### UI-02: Cổng thông tin nhà cung cấp — Quản lý nội dung
**Diễn viên:** Người quản lý nội dung | **Nền tảng:** Flutter Web

Giao diện kiểu CMS để quản lý ngân hàng câu hỏi APTIS:
- **Trình duyệt câu hỏi:** lọc theo kỹ năng (Đọc/Viết/Nghe/Nói), phần (A–E), độ khó, thẻ chủ đề, trạng thái (bản nháp/đang hoạt động/đã lưu trữ). Tìm kiếm toàn văn trong nội dung câu hỏi.
- **Trình soạn thảo câu hỏi:** nội dung văn bản đa dạng thức có hỗ trợ định dạng; tải lên âm thanh với bản xem trước dạng sóng (Nghe); tải lên hình ảnh có xem trước (Phần Nói B/D); trường khóa trả lời (loại điểm tự động); trình soạn thảo tiêu chí phiếu tự đánh giá (loại điểm số của con người); công cụ chọn thẻ độ khó/chủ đề.
- **Trình tạo mẫu bài kiểm tra:** chọn câu hỏi cho mỗi phần hoặc tự động điền theo tiêu chí; xác nhận tính đầy đủ (tất cả các phần bắt buộc đều có mặt).
- **Chế độ xem trước:** hiển thị câu hỏi hoặc mẫu ở chế độ xem chỉ đọc giống như bài kiểm tra với chức năng phát lại âm thanh và hiển thị hình ảnh.
- **Chế độ xem phân tích mục:** bảng có giá trị p, chỉ số phân biệt đối xử, trạng thái gắn cờ; danh sách câu hỏi được gắn cờ; đi sâu vào thống kê theo từng câu hỏi.
- **Nhập hàng loạt:** tải lên tệp kéo và thả (CSV/Excel); bảng xem trước trước khi nhập; báo cáo lỗi mỗi hàng sau khi nhập.

**Yêu cầu về giao diện người dùng:** Tải lên âm thanh hiển thị tiến trình và thời lượng tải lên. Trình chỉnh sửa câu hỏi tự động lưu bản nháp sau mỗi 30 giây. Chế độ xem trước không tạo hồ sơ bài thi.

---

### UI-03: Cổng thông tin nhà cung cấp — Bảng thông tin hỗ trợ
**Diễn viên:** Nhân viên hỗ trợ | **Nền tảng:** Flutter Web

- Tìm kiếm người thuê theo tên, sên hoặc email liên hệ.
- Chế độ xem chi tiết đối tượng thuê: dữ liệu giống như chi tiết đối tượng thuê trong Bảng điều khiển dành cho quản trị viên nhưng tất cả các điều khiển ghi đều bị ẩn.
- Mục nhập mạo danh: Nút "Xem với tư cách quản trị viên đối tượng thuê" sẽ mở Cổng thông tin đối tượng thuê ở chế độ mạo danh chỉ đọc với biểu ngữ màu cam cố định: "Đang xem [Tên đối tượng thuê] — Chỉ đọc | Thoát".
- Tất cả các hành động ghi ở chế độ mạo danh đều bị tắt (các nút bị ẩn hoặc bị tắt bằng chú giải công cụ "Chế độ xem chỉ đọc").

---

### UI-04: Cổng thông tin bán hàng
**Diễn viên:** Đội ngũ bán hàng | **Nền tảng:** Flutter Web

- Danh sách khách hàng: tên, liên hệ, trạng thái giấy phép (mã màu), Seat_used/seat_count, ngày hết hạn, nút thao tác nhanh "Gia hạn".
- Bảng cảnh báo hết hạn trên trang tổng quan: đối tượng thuê sẽ hết hạn trong 30 ngày tới, được sắp xếp tăng dần theo số ngày còn lại.
- Hình thức giấy phép: thả xuống đối tượng thuê, số lượng chỗ ngồi (số nguyên), bộ chọn ngày hết hạn. Xác thực: số chỗ ngồi ≥ 1, ngày hết hạn > hôm nay.
- Lịch sử giấy phép cho mỗi người thuê: danh sách theo trình tự thời gian đảo ngược của tất cả các giấy phép với các trường kiểm tra đầy đủ.

---

### UI-05: Cổng thông tin dành cho người thuê — Chế độ xem của quản trị viên
**Diễn viên:** Người thuê quản trị viên | **Nền tảng:** Flutter Web

- **Trang tổng quan:** Thanh tiến trình sử dụng giấy phép (ngưỡng xanh/vàng/đỏ), thẻ phiên sắp tới, số lượng khóa học đang hoạt động, số lượng sinh viên đã đăng ký so với hạn ngạch, nguồn cấp dữ liệu hoạt động gần đây.
- **Quản lý người dùng:** bảng gồm tất cả người dùng Đối tượng thuê có vai trò; thêm/chỉnh sửa/hủy kích hoạt; phân công đa vai trò thông qua danh sách hộp kiểm.
- **Quản lý khóa học:** tạo/chỉnh sửa khóa học (tên, mô tả, phạm vi ngày); tạo/chỉnh sửa các nhóm trong khóa học; phân công giáo viên vào các nhóm.
- **Quản lý học viên:** danh sách học sinh mỗi lớp kèm theo các thao tác đăng ký; Luồng nhập CSV; nút xuất thông tin xác thực hàng loạt (có cảnh báo mật khẩu văn bản gốc một lần).
- **Analytics:** có thể truy cập tất cả các chế độ xem phân tích (§UI-07a đến §UI-07d).
- **Các buổi thi:** danh sách tất cả các buổi có trạng thái, tỷ lệ hoàn thành và các nút hành động.

**Yêu cầu về giao diện người dùng:** Nhập CSV hiển thị số lượng hàng, số lỗi và lỗi trên mỗi hàng. Xuất khẩu số lượng lớn kích hoạt tải xuống ngay lập tức. Thanh sử dụng giấy phép hiển thị số lượng chính xác và ngày hết hạn bên dưới thanh.

---

### UI-06: Cổng thông tin dành cho người thuê nhà — Chế độ xem của giáo viên
**Diễn viên:** Giáo viên/Người hướng dẫn | **Nền tảng:** Flutter Web

- **Lớp học của tôi:** danh sách các lớp được giao cho giáo viên này; bấm vào để nhập chi tiết lớp học.
- **Chi tiết lớp học:** danh sách học sinh, lịch sử các buổi thi, điểm trung bình của mỗi kỹ năng trong lớp, phân tích nhóm.
- **Tạo phiên thi:** biểu mẫu với: tên, bộ chọn mẫu, phạm vi người tham gia (cả lớp hoặc từng học sinh), cửa sổ ngày/giờ, cấu hình chống gian lận (chuyển đổi ngẫu nhiên, ngưỡng cảnh báo và chấm dứt).
- **Hàng đợi chấm điểm:** danh sách bài viết Viết/Nói đang chờ xem xét; huy hiệu đếm trên biểu tượng điều hướng. Sắp xếp theo submit_at tăng dần (cũ nhất xếp trước).
- **Màn hình đánh giá điểm:** bảng bên trái — câu trả lời của học sinh (văn bản cho phần Viết; bản ghi + trình phát âm thanh cho phần Nói); bảng bên phải - Điểm dự thảo AI cho mỗi tiêu chí, trường điểm có thể chỉnh sửa, tường thuật phản hồi AI (có thể chỉnh sửa), nút Xác nhận. Xác nhận là bắt buộc rõ ràng - không tự động lưu khi điều hướng.
- **Phân tích lớp:** tổng quan về điểm lớp, xếp hạng học sinh, so sánh trước/sau, biểu đồ phân bổ điểm, cảnh báo học sinh yếu; tất cả đều nằm trong phạm vi lớp học của giáo viên.

**Yêu cầu về giao diện người dùng:** Trình phát âm thanh trong phần đánh giá điểm hiển thị dạng sóng và thời lượng. Bản ghi được hiển thị trong bảng điều khiển có chiều cao cố định có thể cuộn dọc theo âm thanh. Những thay đổi chưa được lưu trong phần đánh giá điểm sẽ nhắc nhở "Rời khỏi mà không lưu?" hộp thoại trên điều hướng.

---

### UI-07: Cổng thông tin dành cho người thuê nhà - Chế độ xem điều phối viên kỳ thi
**Diễn viên:** Điều phối viên thi | **Nền tảng:** Flutter Web (hoặc Flutter Desktop để giám sát chuyên dụng)

- **Bảng điều khiển màn hình trực tiếp:** bảng tự động cập nhật (WebSocket/SSE) với một hàng cho mỗi học sinh đã đăng ký:
  - Trạng thái: Chưa bắt đầu / Đang tiến hành [Đọc Phần A] / Đã ngắt kết nối [xem lần cuối X phút trước] / Đã gửi.
  - Huy hiệu số lượng vi phạm (màu đỏ nếu ≥ ngưỡng_cảnh báo).
  - Mở rộng hàng: mục lục câu hỏi hiện tại, thời gian còn lại, nhật ký vi phạm.
- **Bảng can thiệp cho mỗi học sinh:** [Gia hạn thời gian (phút + lý do)] [Buộc gửi (lý do)] [Đặt lại lần thử (lý do)] [Xem vi phạm].
- **Kiểm soát phiên:** [Đóng phiên sớm (thời gian gia hạn + lý do)].
- **Báo cáo tính toàn vẹn:** có sẵn sau khi phiên kết thúc; hiển thị tất cả học sinh với số lượng và loại vi phạm.

**Yêu cầu về giao diện người dùng:** Những học sinh bị ngắt kết nối được tô sáng bằng màu hổ phách. Học sinh bị chấm dứt học tập do ngưỡng vi phạm được đánh dấu màu đỏ. Tất cả các biểu mẫu can thiệp đều yêu cầu trường lý do (không thể gửi trống). Cập nhật bảng mà không cần tải lại trang.

---

### UI-08: Cổng thông tin dành cho người thuê — Chỉ dành cho người xem / báo cáo
**Diễn viên:** Người xem | **Nền tảng:** Flutter Web

- Quyền truy cập chỉ đọc vào tất cả các chế độ xem phân tích hiển thị cho Quản trị viên đối tượng thuê.
- Không hiển thị điều khiển tạo/chỉnh sửa/xóa.
- Nút xuất (Excel/PDF) được đặt nổi bật.
- Không có quyền truy cập vào quản lý người dùng, quản lý khóa học hoặc tạo phiên thi.

---

### UI-09: Ứng dụng bài kiểm tra — Giao diện bài kiểm tra dành cho sinh viên
**Diễn viên:** Sinh viên | **Nền tảng:** Flutter Desktop (Windows/macOS), Flutter Web, Flutter Mobile (TBD — OI-01)

**Trình tự màn hình:**
1. **Đăng nhập:** mang thương hiệu của người thuê (logo + tên hiển thị), email + mật khẩu, liên kết quên mật khẩu.
2. **Bài kiểm tra của tôi:** danh sách các phiên được chỉ định — sắp tới (có đếm ngược), đang hoạt động (nút Nhập), đã hoàn thành (nút Xem kết quả).
3. **Kiểm tra trước kỳ thi:**
   - Kiểm tra micrô: yêu cầu quyền → bản ghi 3 giây → phát lại → Đạt/Thử lại.
   - Lời nhắc toàn màn hình: "Nhập toàn màn hình để bắt đầu bài kiểm tra."
   - Hướng dẫn cho mỗi kỹ năng: thời gian cho phép, điều gì sẽ xảy ra, nút "Tôi hiểu - Bắt đầu".
4. **Giao diện đọc:** đoạn văn có thể cuộn (trái); câu hỏi (phải); bảng điều hướng (dấu chấm câu hỏi); Nút radio MCQ/danh sách thả xuống phù hợp/đầu vào lấp đầy khoảng trống; đã trả lời các câu hỏi được đánh dấu bằng dấu kiểm trong bảng điều hướng.
5. **Giao diện soạn thảo:** dấu nhắc (trên cùng); vùng văn bản (dưới cùng) với số từ trực tiếp, chỉ báo giới hạn từ thay đổi màu ở mức 90% mức tối thiểu/tối đa.
6. **Giao diện nghe:** thanh tiến trình âm thanh chỉ đọc (không tìm kiếm); chỉ báo số lần phát ("Chơi 1 trên 1"); câu hỏi hiển thị đồng thời với âm thanh.
7. **Giao diện nói:** hướng dẫn/hiển thị hình ảnh → đếm ngược đồng hồ chuẩn bị → chỉ báo ghi hình với dạng sóng → tự động dừng → thanh tiến trình tải lên → phần tiếp theo.
8. **Chuyển đổi phần:** "Hoàn thành Phần X — Phần Y bắt đầu sau [đếm ngược] giây"; không có điều hướng trở lại.
9. **Màn hình kết quả:** thang điểm cho mỗi kỹ năng (ngay lập tức cho phần Đọc/Nghe; "Đang chờ giáo viên đánh giá" cho phần Viết/Nói); văn bản từ chối trách nhiệm.
10. **Chi tiết kết quả:** phân tích từng kỹ năng theo từng phần, phản hồi AI (sau khi được xác nhận), thẻ mô tả băng tần.

**Yêu cầu về giao diện người dùng:** Bộ hẹn giờ luôn hiển thị nổi bật (phông chữ lớn, trên cùng bên phải). Chỉ báo ngoại tuyến thay thế khu vực hẹn giờ bằng hoạt ảnh "Đang kết nối lại..." khi mất mạng. Màu đếm từ viết: xám < 80% tối thiểu, trong phạm vi xanh lục, đỏ > tối đa. Dạng sóng nói sử dụng hình ảnh biên độ thời gian thực.

---

### UI-10: Trang đích dùng thử / khách
**Diễn viên:** Khách mời | **Nền tảng:** Flutter Web (công khai, không cần đăng nhập)

- Chuyên mục anh hùng: "Luyện thi APTIS ngay hôm nay" với mô tả hệ thống ngắn gọn.
- Hiển thị phạm vi thử nghiệm: những kỹ năng/bộ phận nào có sẵn và thời lượng ước tính.
- Tuyên bố miễn trừ trách nhiệm: "Đây là bài thi thử mô phỏng, không phải kỳ thi chính thức APTIS của Hội đồng Anh."
- Nút CTA "Bắt đầu thử".
- Sau thử nghiệm: kết quả với phạm vi ước tính, tuyên bố từ chối trách nhiệm, "Liên hệ để phát triển cho trường của bạn" CTA với liên kết liên hệ.

---

## 3.1.2 Giao diện phần cứng

### HW-01: Micro
Cần thiết cho kỹ năng Nói. Máy khách bài kiểm tra sẽ yêu cầu quyền truy cập micrô thông qua API âm thanh của nền tảng (API âm thanh web cho Flutter Web; API micrô thiết bị cho Flutter Desktop/Mobile). Thông số kỹ thuật tối thiểu: chụp đơn âm, tốc độ lấy mẫu 16 kHz. Hệ thống sẽ kiểm tra tính khả dụng của micrô trong quá trình kiểm tra trước kỳ thi (FR-18) và xử lý lỗi một cách khéo léo (FR-110).

### HW-02: Đầu ra âm thanh
Cần thiết cho kỹ năng Nghe. Đầu ra âm thanh của thiết bị tiêu chuẩn (loa hoặc tai nghe). Không có giao diện phần cứng đặc biệt; hệ thống sử dụng API âm thanh nền tảng. Học sinh nên sử dụng tai nghe để tránh rò rỉ âm thanh khi thi nhóm.

### HW-03: Hiển thị
Độ phân giải tối thiểu cho Máy khách kiểm tra: 1024×768 (máy tính để bàn). Khuyến nghị: ≥1280×720 để có bố cục bài thi thoải mái. Chế độ toàn màn hình (FR-95) yêu cầu màn hình hỗ trợ API toàn màn hình của nền tảng.

### HW-04: Giao diện mạng
Cần có kết nối băng thông rộng ổn định tối thiểu để truyền phát âm thanh (Phân phối nghe) và tải lên âm thanh (Nói). Các tính năng Kiểm tra liên tục (F-13) của hệ thống xử lý tình trạng ngắt kết nối trong thời gian ngắn nhưng không thể phục hồi sau khi mất toàn bộ liên tục.

---

## 3.1.3 Giao diện phần mềm

### SI-01: Lưu trữ đối tượng đám mây (S3/GCS)
- **Mục đích:** Lưu trữ liên tục cho các bản ghi âm Nói, Tệp âm thanh Nghe, hình ảnh câu hỏi, nhập CSV, xuất Excel/PDF được tạo.
- **Hướng dẫn:** Đọc + Viết (API phụ trợ); Đọc qua URL được chỉ định hoặc CDN (Ứng dụng khách kiểm tra âm thanh nghe).
- **Giao thức:** HTTPS thông qua SDK của nhà cung cấp (SDK AWS hoặc SDK lưu trữ đám mây của Google).
- **Phân phối âm thanh:** Hỗ trợ CDN để phát lại Nghe với độ trễ thấp; Âm thanh nghe phải bắt đầu phát trong giới hạn độ trễ được xác định trong NFR-08.
- **Tải lên bằng giọng nói:** Tải lên ứng dụng khách qua URL được chỉ định (ưu tiên) hoặc proxy API phụ trợ (dự phòng). Các URL được chỉ định sẽ hết hạn trong cửa sổ phiên thi.

### SI-02: Dịch vụ email (SendGrid / AWS SES - TBD)
- **Hướng dẫn:** Gửi đi từ hàng đợi công việc không đồng bộ ở phần cuối.
- **Giao thức:** REST API (dành riêng cho nhà cung cấp).
- **Nội dung:** Các mẫu HTML có khả năng thay thế có thể thay đổi; Phiên bản tiếng Việt và tiếng Anh.
- **Theo dõi phân phối:** Webhook của nhà cung cấp cập nhật `notification_log.delivery_status` thành đã gửi/bị trả lại/không thành công.

### SI-03: Nhắn tin qua đám mây Firebase (Thông báo đẩy)
- **Có điều kiện:** Chỉ khi Flutter Mobile nằm trong phạm vi nền tảng (OI-01).
- **Hướng dẫn:** Gửi đi từ Phần cuối.
- **Giao thức:** API FCM HTTP v1.
- **Quản lý mã thông báo:** Mã thông báo thiết bị được đăng ký khi khởi chạy ứng dụng di động lần đầu tiên; mã thông báo cũ (đã gỡ cài đặt ứng dụng) đã bị xóa khi phân phối không thành công.

### SI-04: API STT — Chuyển giọng nói thành văn bản (TBD — OI-02)
- **Ứng cử viên:** OpenAI Whisper API, Google Cloud Speech-to-Text, Dịch vụ nhận thức Azure.
- **Hướng dẫn:** Gửi đi từ công việc không đồng bộ của AI Scoreing.
- **Đầu vào:** URL tệp âm thanh trong Cloud Storage.
- **Đầu ra:** Văn bản chép lời cho mỗi phần Nói.
- **Ngôn ngữ:** Tiếng Anh (APTIS là bài kiểm tra tiếng Anh; không cần STT tiếng Việt cho nội dung bài thi).
- **Xử lý lỗi:** Thử lại tối đa 3 lần; trên bản ghi cờ lỗi vĩnh viễn dưới dạng STT_FAILED.

### SI-05: API LLM — Chấm điểm AI (TBD — OI-02)
- **Ứng cử viên:** Claude API (Anthropic), OpenAI GPT-4, Google Gemini.
- **Hướng dẫn:** Gửi đi từ công việc không đồng bộ của AI Scoreing.
- **Đầu vào:** Văn bản phản hồi của học sinh + Lời nhắc về phiếu đánh giá APTIS + hướng dẫn cụ thể theo từng phần.
- **Đầu ra:** JSON — `{criterion_scores: {}, band_estimate: "B1",feedback_narrative: "..."}`.
- **Thiết kế gợi ý:** Lời nhắc trong phiếu tự đánh giá APTIS cho mỗi kỹ năng/phần là sản phẩm triển khai bắt buộc (không nằm trong phạm vi SRS nhưng phải được lên kế hoạch).
- **Chuyển đổi nhà cung cấp:** Phải thực hiện được thông qua thay đổi cấu hình chứ không phải thay đổi mã.

### SI-06: SDK nền tảng Flutter
Cần có các gói Flutter sau (hoặc tương đương):
- Ghi âm micrô: `record` hoặc `flutter_sound`
- Bộ đệm âm thanh cục bộ (Nói): `IndexedDB` (web) hoặc hệ thống tệp nền tảng (máy tính để bàn/thiết bị di động)
- Ứng dụng khách WebSocket: `web_socket_channel`
- Bộ chọn tệp (nhập CSV): `file_picker`
- Bộ nhớ cục bộ (bộ đệm trạng thái bài kiểm tra ngoại tuyến): `shared_preferences` hoặc `Hive`
- Kiểm soát toàn màn hình: `flutter_fullscreen` hoặc kênh nền tảng

---

## 3.1.4 Giao diện truyền thông

### CI-01: API REST
- **Giao thức:** HTTPS (tối thiểu TLS 1.2; ưu tiên TLS 1.3)
- **Định dạng:** JSON (application/json) cho tất cả nội dung yêu cầu và phản hồi
- **Xác thực:** `Ủy quyền: Tiêu đề mang {access_token}` trên tất cả các điểm cuối được bảo vệ
- **Phiên bản:** Phiên bản đường dẫn URL: `/api/v1/...`
- **Giải quyết đối tượng thuê:** Đã giải quyết từ miền phụ yêu cầu bằng phần mềm trung gian cổng API trước khi định tuyến tới trình xử lý
- **Lược đồ phản hồi lỗi:** `{ "code": "TENANT_QUOTA_EXCEEDED", "message": "...", "details": [...] }`
- **Giới hạn tốc độ:** Điểm cuối xác thực: 10 yêu cầu/phút cho mỗi IP. Ghi trạng thái bài kiểm tra: 120 yêu cầu/phút cho mỗi lần thử_id.

### CI-02: Sự kiện WebSocket/Máy chủ gửi
- **Mục đích:** Giám sát bài kiểm tra theo thời gian thực dành cho Điều phối viên bài kiểm tra (FR-39)
- **Giao thức:** WebSocket (ưu tiên); SSE làm dự phòng
- **Xác thực:** JWT đã chuyển tham số truy vấn URL kết nối WebSocket hoặc tiêu đề nâng cấp
- **Các sự kiện máy chủ được đẩy tới máy khách Điều phối viên:**
  - `student.started` — học sinh bắt đầu bài thi
  - `student.progress` — kỹ năng hiện tại và phần được cập nhật
  - `student.disconnected` — máy khách bị mất kết nối (không nhận được nhịp tim trong N giây)
  - `student.reconnected` — máy khách đã kết nối lại
  - `student.submit` — lần thử đã hoàn tất
  - `student.violation` — sự kiện vi phạm được ghi lại (loại, số lượng tích lũy)
- **Nhịp tim của khách hàng:** Khách hàng kiểm tra sẽ gửi nhịp tim sau mỗi 15 giây; máy chủ đánh dấu sinh viên là bị ngắt kết nối nếu không nhận được nhịp tim trong 45 giây
- **Kết nối lại:** Điều phối viên và Khách hàng sinh viên triển khai kết nối lại theo cấp số nhân (1 giây, 2 giây, 4 giây, 8 giây, tối đa 30 giây)

### CI-03: Tải tệp lên
- **Luồng URL được chỉ định (chính):** Phần cuối tạo URL tải lên được chỉ định → Ứng dụng khách tải trực tiếp lên Cloud Storage → Ứng dụng khách thông báo Phần cuối hoàn thành → Phần cuối xác minh và tạo bản ghi `tài sản`
- **Luồng proxy (dự phòng):** Khách hàng tải lên API phụ trợ → Luồng phụ trợ lên Cloud Storage
- **Các định dạng được chấp nhận:** Âm thanh: MP3, WAV, WebM (ghi âm trên trình duyệt); Hình ảnh: JPEG, PNG; Nhập khẩu: CSV, XLSX
- **Giới hạn kích thước:** Âm thanh nói trên mỗi phần: TBD (OI-05/07); Nghe âm thanh: không giới hạn mỗi tệp (do nhà cung cấp quản lý); Hình ảnh: 10MB; Nhập CSV/XLSX: ≤50MB

### CI-04: Định tuyến nhiều người thuê tên miền phụ
- **DNS:** Ký tự đại diện CNAME: `*.aptis-lms.vn` ​​→ cân bằng tải / cạnh CDN
- **SSL:** Chứng chỉ ký tự đại diện bao gồm `*.aptis-lms.vn` ​​và `aptis-lms.vn`
- **Cổng API:** Trích xuất sên từ tiêu đề Máy chủ → tra cứurent_id trong bộ đệm (Redis/trong bộ nhớ) → đính kèm vào ngữ cảnh yêu cầu
- **Bộ nhớ đệm TTL cho slug→ánh xạ tenant_id:** 5 phút (tần suất đột biến thấp; đối tượng thuê mới kích hoạt trong một chu kỳ bộ nhớ đệm)
- **Xử lý sên không xác định:** Trả về HTTP 404 với thông báo "Không tìm thấy đối tượng thuê"