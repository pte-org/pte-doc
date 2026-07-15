# SRS §3.3 - Yêu cầu về hiệu suất
## APTIS LMS
**Phiên bản:** 1.0 | **Ngày:** 2026-06-16 | **Trạng thái:** BẢN THẢO

---

NFR được chỉ định ở định dạng Kịch bản thuộc tính chất lượng ISO/IEC 25023. Tất cả các Biện pháp ứng phó phải ở dạng số hoặc được đánh dấu rõ ràng `[TBD]` với chủ sở hữu và giải quyết theo mốc quan trọng.

**Tổng số NFR: 14 (5 Đã xác nhận / 9 TBD)**

---

#### NFR-01 — Hiệu quả về hiệu suất: Hành vi về thời gian phản hồi

| Cánh đồng | Giá trị |
|-------|-------|
| Nguồn kích thích | Học sinh gửi bài viết cho mỗi câu trả lời (FR-105) hoặc bất kỳ người dùng nào thực hiện lệnh gọi API REST |
| Kích thích | API phụ trợ nhận được yêu cầu HTTP REST trên bất kỳ điểm cuối không phải phương tiện nào |
| Môi trường | Hệ thống chịu tải đồng thời cao điểm (tất cả người thuê, giờ thi cao điểm) |
| Cổ vật | API REST phụ trợ (tất cả các điểm cuối ngoại trừ truyền phát âm thanh) |
| Phản ứng | Máy chủ xử lý yêu cầu và trả về phản hồi HTTP |
| Biện pháp đáp ứng | `[TBD: p50 < 200ms, p95 < 500ms, p99 < 1s — TechLead xác nhận dựa trên quy mô cơ sở hạ tầng \| chủ sở hữu: TechLead \| giải quyết bằng: Phiên kiến ​​trúc (OI-05)]` |

**Lý do:** Yêu cầu PATCH cho mỗi câu trả lời (FR-105) được gửi trên mọi lựa chọn MCQ và nhập văn bản; độ trễ ở đây tạo ra độ trễ rõ ràng trong chỉ báo "Đã lưu" và làm giảm trải nghiệm làm bài thi của học sinh. P95 cao cũng ảnh hưởng đến khả năng phản hồi của bảng điều khiển màn hình trực tiếp (FR-39).

**Phương pháp đo lường:** Nhật ký độ trễ yêu cầu phía máy chủ ở cấp cân bằng tải, được lấy mẫu trong quá trình kiểm tra tải mô phỏng lưu lượng kiểm tra đồng thời cao điểm.

---

#### NFR-02 - Độ tin cậy: Tính sẵn có (Tổng thể)

| Cánh đồng | Giá trị |
|-------|-------|
| Nguồn kích thích | Bất kỳ người dùng hoặc công việc theo lịch trình nào đưa ra yêu cầu đối với nền tảng |
| Kích thích | Yêu cầu đến nền tảng trong giờ hoạt động bình thường (không kiểm tra, không bảo trì) |
| Môi trường | Trạng thái hoạt động bình thường; bên ngoài các buổi thi tích cực |
| Cổ vật | Toàn bộ nền tảng (Cổng thông tin nhà cung cấp, Cổng thông tin người thuê, API phụ trợ) |
| Phản ứng | Hệ thống xử lý và trả về phản hồi hợp lệ |
| Biện pháp đáp ứng | `[TBD: ≥ 99,5% thời gian hoạt động hàng tháng (< 3,6 giờ thời gian ngừng hoạt động/tháng) — TechLead xác nhận cấp SLA \| chủ sở hữu: TechLead \| giải quyết bởi: OI-05]` |

**Lý do:** Cổng quản trị và quản lý nội dung có thể chấp nhận khoảng thời gian ngừng hoạt động ngắn hạn theo kế hoạch; mối quan tâm chính là khả năng cung cấp bài kiểm tra (xem NFR-03).

**Phương pháp đo:** Đầu dò giám sát thời gian hoạt động bên ngoài (kiểm tra tình trạng HTTP) chạm vào nền tảng cứ sau 60 giây; báo cáo sẵn có hàng tháng được tính toán từ dữ liệu thăm dò.

---

#### NFR-03 — Độ tin cậy: Tính khả dụng (Các buổi thi) — **Đã xác nhận**

| Cánh đồng | Giá trị |
|-------|-------|
| Nguồn kích thích | Bất kỳ học sinh hoặc Điều phối viên kỳ thi nào đưa ra yêu cầu trong một buổi thi đang diễn ra |
| Kích thích | Một yêu cầu đến trong một cửa sổ có ít nhất một phiên thi đang diễn ra `in_progress` |
| Môi trường | Cửa sổ phiên thi đang hoạt động; hệ thống theo tải người thi đồng thời cao điểm |
| Cổ vật | Đường dẫn phân phối bài kiểm tra: API phụ trợ, ghi DB Exam_state, kết nối WebSocket/SSE (FR-39), CDN âm thanh (FR-22) |
| Phản ứng | Hệ thống xử lý yêu cầu trong giới hạn thời gian phản hồi thông thường |
| Biện pháp đáp ứng | ** ≥ 99,9% khả dụng trong bất kỳ khoảng thời gian phiên kiểm tra đang hoạt động nào** (được đo trên mỗi phiên: tỷ lệ các phiên không bị gián đoạn phía hệ thống trên tổng số phiên) |

**Cơ sở lý luận:** Được nêu rõ ràng là ưu tiên số 1 của các bên liên quan. Việc ngừng hoạt động hệ thống trong kỳ thi có giới hạn thời gian là không thể phục hồi hoàn toàn: học sinh mất thời gian, bản ghi có thể bị mất và sự can thiệp của giám thị sẽ tạo ra các vấn đề về tính toàn vẹn của kỳ thi. Mục tiêu 99,9% có nghĩa là thời gian ngừng hoạt động ≤ 43 giây cho mỗi buổi thi.

**Lưu ý triển khai:** Yêu cầu khoảng thời gian bảo trì được lên lịch ngoài giờ thi, bộ ngắt mạch trên các dịch vụ không quan trọng và cơ sở hạ tầng phục vụ bài kiểm tra chuyên dụng (tách biệt với đường dẫn phân tích/quản trị viên).

---

#### NFR-04 — Hiệu suất hoạt động: Năng lực (Người thực hiện bài kiểm tra đồng thời)

| Cánh đồng | Giá trị |
|-------|-------|
| Nguồn kích thích | Nhiều người thuê lên lịch các buổi thi trùng nhau về thời gian |
| Kích thích | N sinh viên đồng thời tham gia các buổi thi trên tất cả người thuê |
| Môi trường | Giờ thi cao điểm (cuối học kỳ, nhiều học sinh cùng lúc); hệ thống đầy tải |
| Cổ vật | API phụ trợ (ghi Exam_state), máy chủ WebSocket (FR-39), tầng ghi cơ sở dữ liệu |
| Phản ứng | Tất cả các sự kiện ghi cho mỗi câu trả lời, đồng bộ hóa bộ hẹn giờ và giám sát trực tiếp đều được xử lý trong các mục tiêu độ trễ NFR-01 |
| Biện pháp đáp ứng | `[TBD: ≥ 500 người tham gia kỳ thi đồng thời trên tất cả đối tượng thuê mà không bị suy giảm — TechLead xác nhận dựa trên cơ sở hạ tầng và khả năng ghi cơ sở dữ liệu \| chủ sở hữu: TechLead \| giải quyết bởi: OI-05]` |

**Lý do:** Tính bền vững trên mỗi câu trả lời (FR-105) có nghĩa là viết thang đo tải theo tuyến tính với những người thực hiện bài kiểm tra tích cực. Đánh giá quá cao năng lực là tốt hơn; chi phí do hiệu suất bị suy giảm trong một kỳ thi vượt xa chi phí cung cấp quá mức cơ sở hạ tầng.

**Phương pháp đo lường:** Kiểm tra tải với người dùng mô phỏng đồng thời thực hiện vòng lặp bài kiểm tra-câu trả lời-nộp ở tần suất ghi cho mỗi câu trả lời (khoảng 1 lần viết trong 30 giây cho mỗi học sinh ở tất cả các kỹ năng).

---

#### NFR-05 — Hiệu suất hiệu suất: Hành vi thời gian (Tự động chấm điểm) — **Đã xác nhận**

| Cánh đồng | Giá trị |
|-------|-------|
| Nguồn kích thích | Học sinh hoàn thành và nộp bài thi (FR-26) |
| Kích thích | `exam_attempt.status` được đặt thành `đã gửi` |
| Môi trường | Tải hệ thống bình thường; hàng đợi công việc chấm điểm có năng lực |
| Cổ vật | Quy trình tính điểm tự động: khớp câu trả lời (FR-27) + tính điểm (FR-28) + ghi kết quả |
| Phản ứng | Các bản ghi Đọc và Nghe `attempt_results` được đặt thành `status = available` và hiển thị cho học sinh |
| Biện pháp đáp ứng | **Kết quả Đọc và Nghe sẽ có trong vòng 2 phút kể từ `exam_attempt.submit_at`** (được đo bằng `attempt_results.reading_available_at − Exam_attempt.submit_at`) |

**Lý do:** Học sinh mong đợi phản hồi gần như ngay lập tức đối với các kỹ năng được tự động chấm điểm. Độ trễ > 2 phút sẽ tạo ra ấn tượng về lỗi hệ thống. Cửa sổ 2 phút bao gồm: lấy hàng đợi công việc + tính toán khớp câu trả lời + tra cứu băng tần + ghi DB + chu trình thăm dò ý kiến ​​​​của khách hàng.

---

#### NFR-06 — Hiệu quả hoạt động: Thời gian phản hồi (Ghi trạng thái bài kiểm tra)

| Cánh đồng | Giá trị |
|-------|-------|
| Nguồn kích thích | Học sinh chọn tùy chọn MCQ hoặc hoàn thành việc nhập văn bản (FR-105) |
| Kích thích | Khách hàng gửi `PATCH /api/v1/exam/attempts/{id}/answers` |
| Môi trường | Hệ thống có tải bài thi đồng thời cao điểm |
| Cổ vật | Trạng thái kiểm tra API phụ trợ ghi điểm cuối + ghi cơ sở dữ liệu |
| Phản ứng | Máy chủ xác nhận việc ghi và trả về HTTP 200 |
| Biện pháp đáp ứng | `[TBD: p95 < 300ms từ đầu đến cuối (máy khách gửi tới HTTP 200 đã nhận) \| chủ sở hữu: TechLead \| giải quyết bởi: OI-05]` |

**Lý do:** Xác nhận ghi chậm khiến chỉ báo "Đã lưu" bị trễ, khiến học sinh lo lắng trong kỳ thi. Với 500 học sinh đồng thời gửi khoảng 1 lần ghi trong 30 giây, thông lượng ghi cao nhất là ~17 lần ghi/giây — nằm trong dung lượng cơ sở dữ liệu thông thường, nhưng giới hạn p95 phải được xác thực khi tải.

---

#### NFR-07 — Hiệu quả về hiệu suất: Thông lượng (Tải lên âm thanh khi nói)

| Cánh đồng | Giá trị |
|-------|-------|
| Nguồn kích thích | Học sinh hoàn thành bản ghi phần Nói (FR-23) |
| Kích thích | Khách hàng bắt đầu tải âm thanh Nói lên Cloud Storage (URL hoặc proxy được chỉ định, FR-108) |
| Môi trường | Sinh viên sử dụng kết nối băng thông rộng tiêu chuẩn (tải lên ≥ 10 Mbps); hệ thống chịu tải cao điểm |
| Cổ vật | Đường dẫn tải lên âm thanh nói: client → Cloud Storage (SI-01) |
| Phản ứng | Tệp âm thanh đã được tải lên đầy đủ và Cloud Storage xác nhận đã nhận |
| Biện pháp đáp ứng | `[TBD: Tổng số âm thanh Nói của một học sinh (tất cả 5 phần, tổng dung lượng ước tính là 5–15 MB) được tải lên trong vòng 5 phút trên kết nối 10 Mbps \| chủ sở hữu: TechLead \| giải quyết bởi: OI-05, OI-07]` |

**Lý do:** Tải lên chậm có nguy cơ âm thanh không đầy đủ khi kết thúc phiên. Âm thanh phần nói phải được tải lên trước khi thời gian phiên thi đóng lại để được tính điểm. Đường dẫn tải lên URL được chỉ định (SI-01) bỏ qua phần phụ trợ, giảm tải máy chủ và tăng thông lượng.

**Phương pháp đo lường:** Thời gian tải lên được đo lường ở cấp độ khách hàng; Dấu thời gian xác nhận biên nhận Cloud Storage được ghi lại trên mỗi tệp.

---

#### NFR-08 — Hiệu suất hiệu suất: Độ trễ (Phân phối CDN âm thanh nghe)

| Cánh đồng | Giá trị |
|-------|-------|
| Nguồn kích thích | Học sinh nhập câu hỏi Nghe (FR-22) |
| Kích thích | Máy khách kiểm tra yêu cầu tệp âm thanh Nghe từ CDN |
| Môi trường | Sinh viên tại một trường học ở Việt Nam; Nút biên CDN phục vụ Đông Nam Á |
| Cổ vật | Đường dẫn phân phối CDN để nghe các tệp âm thanh (SI-01, có mặt trước CDN) |
| Phản ứng | Tệp âm thanh được truyền tới máy khách và bắt đầu phát |
| Biện pháp đáp ứng | `[TBD: Thời gian tính đến byte đầu tiên 500ms; không bị gián đoạn đệm trong khi phát lại \| chủ sở hữu: TechLead \| giải quyết bởi: OI-05]` |

**Lý do:** Nghe âm thanh tự động phát khi nhập phần (FR-22) và có giới hạn số lần phát nghiêm ngặt (mặc định là 1 lần phát). Lỗi phân phối CDN hoặc độ trễ lưu vào bộ đệm kéo dài sẽ tiêu tốn số lượt phát hạn chế của học sinh mà không phân phối được âm thanh — một vấn đề quan trọng về tính công bằng trong kỳ thi.

**Lưu ý triển khai:** Cần có các nút biên CDN ở Việt Nam hoặc Đông Nam Á. Nội dung âm thanh bài kiểm tra phải được làm ấm trước ở cạnh CDN khi bắt đầu phiên, không được tải xuống nguội theo yêu cầu đầu tiên của học viên.

---

#### NFR-09 — Hiệu quả về hiệu suất: Hành vi thời gian (Đường dẫn chấm điểm AI)

| Cánh đồng | Giá trị |
|-------|-------|
| Nguồn kích thích | Việc nộp bài kiểm tra của học sinh sẽ kích hoạt quy trình chấm điểm AI (FR-30, FR-31) |
| Kích thích | Công việc chấm điểm AI được xếp hàng đợi và bắt đầu xử lý âm thanh Nói và Văn bản viết |
| Môi trường | Tính sẵn có của API nhà cung cấp AI thông thường; hàng đợi công việc không bị quá tải |
| Cổ vật | Quy trình chấm điểm AI: Lệnh gọi API STT (FR-30) + Lệnh gọi API LLM (FR-31) + ghi điểm dự thảo |
| Phản ứng | Giáo viên nhận được email thông báo rằng điểm dự thảo đã sẵn sàng để xem xét |
| Biện pháp đáp ứng | `[TBD: STT hoàn thành trong vòng 5 phút kể từ khi gửi; Điểm dự thảo LLM được tạo trong vòng 10 phút sau bảng điểm; giáo viên thông báo trong vòng 15 phút kể từ ngày thi_attempt.submit_at \| chủ sở hữu: TechLead \| giải quyết bởi: OI-02 (lựa chọn nhà cung cấp), OI-05]` |

**Lý do:** Sự chậm trễ kéo dài trong quy trình AI đã đẩy lùi quá trình đánh giá của giáo viên và khả năng cung cấp kết quả của học sinh. Mục tiêu toàn diện kéo dài 15 phút được đề xuất có nghĩa là giáo viên có thể bắt đầu xem xét điểm Viết/Nói trong một chu kỳ thi. Mục tiêu thực tế phụ thuộc vào độ trễ API của nhà cung cấp AI (OI-02).

---

#### NFR-10 — Khả năng bảo trì: Lưu giữ dữ liệu (Hồ sơ bài kiểm tra)

| Cánh đồng | Giá trị |
|-------|-------|
| Nguồn kích thích | Công việc lưu giữ dữ liệu theo lịch trình |
| Kích thích | Bản ghi câu trả lời bài kiểm tra, siêu dữ liệu bài thi và bản ghi điểm vượt quá ngưỡng lưu giữ đã định cấu hình |
| Môi trường | Hệ thống hoạt động bình thường; công việc bảo trì nền |
| Cổ vật | bảng_câu trả lời bài kiểm tra, số lần thử, số lần thử, kết quả, điểm_dự thảo, bảng_điểm cuối cùng |
| Phản ứng | Các bản ghi cũ hơn ngưỡng lưu giữ sẽ được lưu trữ hoặc xóa sạch |
| Biện pháp đáp ứng | `[TBD: Tối thiểu 2 năm kể từ ngày thử việc — PM/Pháp lý để xác nhận dựa trên khả năng áp dụng ND 13/2023/ND-CP \| chủ sở hữu: PM + Pháp lý \| giải quyết bởi: OI-07]` |

**Lưu ý tuân thủ:** ND 13/2023/ND-CP (Nghị định bảo vệ dữ liệu cá nhân của Việt Nam) có thể áp dụng nghĩa vụ lưu giữ tối thiểu hoặc tối đa đối với dữ liệu cá nhân của học sinh (tên, email, điểm thi). Bộ phận pháp lý phải xác nhận khả năng áp dụng trước khi NFR này có thể được hoàn thiện.

---

#### NFR-11 — Khả năng bảo trì: Lưu giữ dữ liệu (Bản ghi âm nói)

| Cánh đồng | Giá trị |
|-------|-------|
| Nguồn kích thích | Công việc lưu giữ âm thanh theo lịch trình |
| Kích thích | Tệp âm thanh nói trong Cloud Storage vượt quá ngưỡng lưu giữ được định cấu hình |
| Môi trường | Hệ thống hoạt động bình thường |
| Cổ vật | Cloud Storage (SI-01): Tệp âm thanh nói cho mỗi lần thử cho mỗi phần |
| Phản ứng | Các tệp âm thanh cũ hơn ngưỡng sẽ bị xóa khỏi Cloud Storage |
| Biện pháp đáp ứng | `[TBD: 90 ngày đăng xác nhận điểm của giáo viên, sau đó thanh lọc - PM/Pháp lý để xác nhận \| chủ sở hữu: PM + Pháp lý \| giải quyết bởi: OI-07]` |

**Lưu ý về chi phí:** Âm thanh nói ước tính khoảng 5–15 MB cho mỗi lần học sinh thực hiện. Với 150.000 lượt học sinh thử/năm, dung lượng lưu trữ tích lũy ở mức 750 GB–2,25 TB mỗi năm. Thời gian lưu giữ là yếu tố chính gây ra chi phí lưu trữ và phải được giảm thiểu phù hợp với các yêu cầu pháp lý và kiểm toán.

---

#### NFR-12 — Bảo mật: Lưu trữ mật khẩu — **Đã xác nhận**

| Cánh đồng | Giá trị |
|-------|-------|
| Nguồn kích thích | Người dùng đăng ký hoặc thay đổi mật khẩu; kẻ tấn công có quyền truy cập đọc vào bảng người dùng |
| Kích thích | Mật khẩu văn bản gốc được gửi để lưu trữ; hoặc hàm băm được lưu trữ bị lấy ra |
| Môi trường | Luồng xác thực bình thường; hoặc tình huống sau vi phạm |
| Cổ vật | Bộ nhớ thông tin xác thực người dùng (bảng người dùng, cột pass_hash) |
| Phản ứng | Mật khẩu được lưu trữ dưới dạng hàm băm thích ứng một chiều; các giá trị băm đã lọc không thể được đảo ngược trong thời gian thực tế |
| Biện pháp đáp ứng | **bcrypt có hệ số chi phí ≥ 12** (khoảng 300 mili giây mỗi lần băm trên phần cứng hàng hóa hiện tại); không có mật khẩu văn bản gốc nào được lưu trữ trong cơ sở dữ liệu bất cứ lúc nào |

**Ràng buộc triển khai:** Việc xuất thông tin xác thực văn bản gốc một lần (FR-48) chỉ phải tạo và truyền mật khẩu tại thời điểm tạo tài khoản; nó không bao giờ được lưu trữ dưới dạng bản rõ trong cơ sở dữ liệu. Quá trình xuất sẽ đọc bản rõ từ bộ nhớ tại thời điểm tạo và băm trước khi ghi.

---

#### NFR-13 — Bảo mật: Thời gian tồn tại của mã thông báo xác thực — **Đã xác nhận**

| Cánh đồng | Giá trị |
|-------|-------|
| Nguồn kích thích | Phiên người dùng được xác thực; kẻ tấn công chặn mã thông báo truy cập |
| Kích thích | Mã thông báo truy cập đang được sử dụng; hoặc mã thông báo truy cập bị kẻ tấn công chiếm giữ |
| Môi trường | Phiên xác thực bình thường; hoặc tình huống đánh cắp mã thông báo/MITM đang hoạt động |
| Cổ vật | Mã thông báo truy cập JWT và mã thông báo làm mới (FR-02) |
| Phản ứng | Mã thông báo truy cập bị chặn sẽ hết hạn nhanh chóng; mã thông báo làm mới xoay vòng khi sử dụng, vô hiệu hóa mã thông báo trước đó |
| Biện pháp đáp ứng | **Truy cập token TTL ≤ 15 phút; Làm mới mã thông báo TTL ≤ 7 ngày; mã thông báo làm mới xoay vòng trong mỗi lần sử dụng (mã thông báo cũ bị vô hiệu khi phát hành mã thông báo mới)** |

**Ghi chú triển khai:** Mã thông báo làm mới phải được lưu trữ phía máy chủ (cơ sở dữ liệu hoặc Redis) để hỗ trợ việc vô hiệu hóa bắt buộc (FR-07). Không thể thu hồi mã thông báo làm mới JWT không trạng thái thuần túy. Mã thông báo làm mới chỉ sử dụng một lần; việc sử dụng lại mã thông báo làm mới cũ sẽ trả về HTTP 401.

---

#### NFR-14 — Độ tin cậy: Tính toàn vẹn của dữ liệu bài kiểm tra (Tính liên tục của bài kiểm tra) — **Đã xác nhận (Ưu tiên số 1)**

| Cánh đồng | Giá trị |
|-------|-------|
| Nguồn kích thích | Bất kỳ sự kiện nào làm gián đoạn quá trình thi của học sinh: ngắt kết nối mạng, lỗi trình duyệt, buộc đóng ứng dụng, tắt nguồn thiết bị, chuyển đổi lỗi máy chủ |
| Kích thích | Ứng dụng khách thi của học sinh mất kết nối hoặc chấm dứt đột ngột trong quá trình thử hoạt động |
| Môi trường | Bất kỳ điều kiện mạng nào; bất kỳ thời điểm nào trong buổi thi đang diễn ra |
| Cổ vật | Exam_state (lưu giữ cho mỗi câu trả lời), bộ đệm âm thanh cục bộ (Đang nói), bộ hẹn giờ do máy chủ xác thực, luồng tiếp tục |
| Phản ứng | Khi học sinh kết nối lại trong cửa sổ phiên, tất cả các câu trả lời đã gửi trước đó vẫn giữ nguyên; bộ đếm thời gian của máy chủ đã tiếp tục chính xác; Âm thanh nói được tải lên hoặc có thể phục hồi từ bộ đệm cục bộ |
| Biện pháp đáp ứng | **Tỷ lệ mất dữ liệu câu trả lời bài kiểm tra = 0%** đối với bất kỳ bài thi nào mà học sinh đã gửi thành công ít nhất một câu trả lời trước khi ngắt kết nối; được đo bằng số lần thử trong đó `câu trả lời cuối cùng < sinh viên_reported_submit_count` |

**Lý do:** Bên liên quan chỉ định rõ ràng tính liên tục của kỳ thi là ưu tiên số 1 của sản phẩm. Bất kỳ câu trả lời nào được FR-105 lưu vào máy chủ đều phải tồn tại sau mọi lỗi phía máy khách. NFR này là kết quả tổng hợp của cụm F-13 (FR-104 đến FR-111).

**Phương pháp đo lường:** Kiểm tra sau phiên so sánh các bản ghi câu trả lời cho mỗi câu hỏi trong `exam_answers` với nhật ký gửi `exam_state` của lần thi; Tốc độ phân phối âm thanh giọng nói (tệp được xác nhận trong Cloud Storage so với tệp được khách hàng ghi lại mỗi lần thử).

---

## Tóm tắt yêu cầu hiệu suất

| NHẬN DẠNG | đặc trưng | Biện pháp đáp ứng | Trạng thái |
|----|----------------|-----------------|--------|
| NFR-01 | Thời gian phản hồi API (p95) | TBD (được đề xuất: p95 < 500ms) | TBD — OI-05 |
| NFR-02 | Tổng thể sẵn có | TBD (đề xuất: ≥ 99,5%/tháng) | TBD — OI-05 |
| NFR-03 | Giờ thi có sẵn | ≥ 99,9% trong các buổi thi tích cực | **Đã xác nhận** |
| NFR-04 | Người thi đồng thời | TBD (đề xuất: ≥ 500 đồng thời) | TBD — OI-05 |
| NFR-05 | Độ trễ tự động tính điểm | 2 phút kể từ khi gửi | **Đã xác nhận** |
| NFR-06 | Độ trễ ghi trạng thái bài kiểm tra (p95) | TBD (được đề xuất: p95 < 300ms) | TBD — OI-05 |
| NFR-07 | Tải lên âm thanh nói | TBD (đề xuất: 5 phút cho toàn bộ) | TBD — OI-05 |
| NFR-08 | Nghe phân phối CDN | TBD (được đề xuất: TTFB 500ms) | TBD — OI-05 |
| NFR-09 | Quy trình chấm điểm AI | TBD (được đề xuất: tổng cộng 15 phút) | TBD — OI-02, OI-05 |
| NFR-10 | Lưu giữ hồ sơ thi | TBD (đang chờ pháp lý - OI-07) | TBD — OI-07 |
| NFR-11 | Lưu giữ bản ghi âm | TBD (đang chờ pháp lý - OI-07) | TBD — OI-07 |
| NFR-12 | Băm mật khẩu | chi phí bcrypt ≥ 12 | **Đã xác nhận** |
| NFR-13 | Tuổi thọ của mã thông báo JWT | Truy cập ≤ 15 phút; Làm mới ≤ 7 ngày luân phiên | **Đã xác nhận** |
| NFR-14 | Tính toàn vẹn dữ liệu bài kiểm tra | Tỷ lệ mất dữ liệu trả lời 0% | **Đã xác nhận (ưu tiên số 1)** |