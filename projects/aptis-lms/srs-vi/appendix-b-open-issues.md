# SRS Phụ lục B — Các mục mở
## APTIS LMS
**Phiên bản:** 1.0 | **Ngày:** 2026-06-16 | **Trạng thái:** BẢN THẢO

---

Tất cả các mục được gắn thẻ `[TBD]` trong SRS này đều được hợp nhất ở đây với chủ sở hữu, tác động chặn và giải quyết theo cột mốc. Không có phần SRS nào có thể được thăng cấp lên trạng thái CUỐI CÙNG trong khi các mục đang mở ảnh hưởng đến phần đó vẫn chưa được giải quyết.

---

## OI-01: Phân chia nền tảng Flutter

**Tình trạng:** MỞ
**Chủ sở hữu:** TechLead
**Chặn:** FR-18, FR-95, FR-97, FR-102, NFR-07, SI-03 (FCM), ước tính nỗ lực từ phía trước

**Câu hỏi:** Hệ thống con máy khách nào được triển khai trên mục tiêu nền tảng Flutter nào?

| Hệ thống con | Nền tảng ứng viên | Cần Quyết định |
|----------||----------------------|-----------------|
| Cổng thông tin nhà cung cấp | Web rung | Xác nhận |
| Cổng thông tin người thuê nhà | Web rung | Xác nhận |
| Khách hàng thi (Sinh viên) | Flutter Web + Flutter Desktop (Win/macOS) + Flutter Mobile (iOS/Android) | Nền tảng nào cho v1? |
| Trang đích dùng thử | Web rung | Xác nhận |

**Đường cơ sở được đề xuất:** Flutter Web cho tất cả các cổng quản trị; Flutter Desktop (Windows chính, macOS phụ) + Flutter Web cho Exam Client; Flutter Mobile được chuyển sang v1.5.

**Tác động nếu không được giải quyết:**
- FR-18 (kiểm tra trước kỳ thi — API kiosk và micrô khác nhau tùy theo nền tảng) không thể hoàn tất
- FR-102 (chế độ kiosk - Tính năng chỉ dành cho máy tính để bàn) vẫn có điều kiện
- FR-84 (thông báo đẩy) và SI-03 (FCM) vẫn có điều kiện
- Không thể hoàn thiện NFR-07 (Định dạng tệp âm thanh nói tùy thuộc vào API ghi nền tảng)
- Kiến trúc Frontend và lựa chọn gói bị chặn

**Giải quyết bằng cách:** Trước phiên kiến trúc TechLead

---

## OI-02: Lựa chọn nhà cung cấp AI

**Tình trạng:** MỞ
**Chủ sở hữu:** TechLead
**Chặn:** FR-30, FR-31, NFR-09, SI-04, SI-05

**Câu hỏi:**
1. Nhà cung cấp STT: API OpenAI Whisper, Google Cloud Speech-to-Text hay Azure Cognitive Services?
2. Nhà cung cấp LLM: Claude API (Anthropic) so với OpenAI GPT-4o so với Google Gemini?
3. Độ chính xác STT tiếng Anh của mỗi nhà cung cấp có đủ để phát âm tiếng Anh không phải tiếng Việt có giọng bản ngữ không?
4. Cấu trúc chi phí cho mỗi phút phiên âm và cho mỗi yêu cầu đánh giá LLM là gì?
5. Giới hạn tốc độ API và chính sách thử lại cho mỗi nhà cung cấp là gì?

**Tiêu chí đánh giá (theo thứ tự ưu tiên):**
- Độ chính xác STT tiếng Anh cho người nói giọng Việt (trình điều khiển chính)
- Chất lượng chấm điểm LLM theo tiêu chí thang đánh giá APTIS
- Độ trễ API (ảnh hưởng đến NFR-09)
- Định giá ở quy mô dự kiến (~150.000 bài phát biểu/năm ở trạng thái ổn định v1)
- Tính ổn định của API và SLA từ nhà cung cấp

**Tác động nếu không được giải quyết:**
- Không thể triển khai FR-30 (phiên âm STT) và FR-31 (chấm điểm dự thảo LLM)
- Không thể thiết kế kiến trúc quy trình chấm điểm AI
- Không thể ước tính NFR-09 (mục tiêu độ trễ đường ống)
- Không thể bắt đầu phân phối kỹ thuật nhanh chóng (lời nhắc trong thang đánh giá APTIS)

**Giải quyết bằng cách:** Trước phiên kiến trúc TechLead; nên đánh giá bằng chứng ngắn gọn về khái niệm

---

## OI-03: SLA chấm điểm viết và nói

**Tình trạng:** MỞ
**Chủ sở hữu:** Doanh nghiệp nhà cung cấp + Đại diện người thuê nhà
**Chặn:** FR-83 (trình kích hoạt lời nhắc SLA), NFR-09, thông báo kỳ vọng về kết quả mà học sinh phải đối mặt

**Câu hỏi:**
1. Thời gian tối đa được chấp nhận để Giáo viên xem xét và xác nhận điểm dự thảo AI cho môn Viết và Nói sau khi nộp bài thi là bao lâu?
2. Điều gì sẽ xảy ra nếu Giáo viên không xem xét trong SLA — chỉ nhắc nhở hệ thống, tự động xác nhận bản nháp AI hoặc chuyển lên Quản trị viên đối tượng thuê?
3. Từ góc độ học sinh: việc chờ đợi kết quả Viết/Nói trong bao lâu là có thể chấp nhận được?

**Phương pháp đề xuất:**
- SLA = 48 giờ kể từ khi nộp bài thi
- T+24h: gửi email nhắc nhở Giáo viên
- T+48h: gửi email báo cáo tới Quản trị viên thuê nhà
- Không tự động xác nhận (duy trì sự giám sát của con người đối với BR-13)

**Tác động nếu không được giải quyết:**
- Không thể triển khai thông báo nhắc nhở SLA FR-83 (điều kiện kích hoạt không được xác định)
- Không thể viết tin nhắn cho học sinh ("Có kết quả trong vòng X giờ")
- Không thể đặt kỳ vọng của Giáo viên trong tài liệu giới thiệu

**Giải quyết bằng cách:** Trước khi hoàn thiện thông số kỹ thuật/phát triển cụm F-10

---

## OI-04: Ngưỡng vi phạm mặc định chống gian lận

**Tình trạng:** MỞ
**Chủ sở hữu:** Kinh doanh nhà cung cấp
**Chặn:** FR-100 (thực thi ngưỡng), FR-37 (giá trị mặc định tạo phiên), biểu mẫu tạo phiên giao diện người dùng Cổng thông tin đối tượng thuê

**Câu hỏi:**
1. Giá trị mặc định cho `warning_threshold` và `terminate_threshold` là gì?
2. Phạm vi cấu hình cho mỗi ngưỡng (tối thiểu/tối đa) là bao nhiêu?
3. Hệ thống có nên ngăn cài đặt `terminate_threshold` quá thấp (ví dụ: = 1, sẽ kết thúc ở lần chuyển tab đầu tiên) không?

**Mặc định được đề xuất:** `warning_threshold = 3`, `terminate_threshold = 5`
**Ràng buộc được đề xuất:** `ngưỡng_cảnh báo ≥ 1`, `ngưỡng_chấm dứt ≥ ngưỡng cảnh báo + 1`, `ngưỡng_chấm dứt 20`

**Tác động nếu không được giải quyết:**
- FR-100 không thể tham chiếu các giá trị mặc định cụ thể
- Không thể viết các trường hợp kiểm thử hành vi ngưỡng vi phạm
- Biểu mẫu tạo phiên không thể hiển thị đúng mặc định trong giao diện người dùng

**Giải quyết bằng cách:** Trước khi bắt đầu phát triển trên F-12 (Cụm tính toàn vẹn của bài kiểm tra)

---

## OI-05: Mục tiêu số NFR

**Tình trạng:** MỞ
**Chủ sở hữu:** TechLead
**Chặn:** NFR-01 (thời gian phản hồi API), NFR-02 (tính khả dụng), NFR-04 (tải đồng thời), NFR-06 (độ trễ ghi trạng thái kỳ thi), NFR-07 (tải lên âm thanh), NFR-08 (độ trễ CDN), NFR-09 (đường dẫn AI)

**Các câu hỏi yêu cầu đầu vào của TechLead:**

| NFR | Câu hỏi | Giá trị đề xuất |
|------|----------|-----------------|
| NFR-01 | Mục tiêu thời gian phản hồi API (p95) cho điểm cuối REST? | p95 < 500ms |
| NFR-02 | SLA sẵn có tổng thể (ngoài giờ thi)? | ≥ 99,5% hàng tháng |
| NFR-04 | Số người thi đồng thời tối đa ở v1? | ≥ 500 đồng thời |
| NFR-06 | Mục tiêu độ trễ ghi cho mỗi câu trả lời (p95)? | p95 < 300ms |
| NFR-07 | Giới hạn kích thước tải lên âm thanh và thời gian tải lên tối đa có thể chấp nhận được? | 5–15 MB/sinh viên, 5 phút |
| NFR-08 | Nghe mục tiêu độ trễ CDN âm thanh (TTFB)? | TTFB 500ms |
| NFR-09 | Mục tiêu thời gian từ đầu đến cuối của đường dẫn tính điểm AI? | Tổng cộng 15 phút |

**Bối cảnh để ước tính TechLead:**
- Đối tượng thuê dự kiến khi ra mắt: `[CẦN NHẬP NGƯỜI DÙNG từ Nhà cung cấp]`
- Số sinh viên dự kiến trên mỗi người thuê nhà: ~100–500
- Phiên cao điểm đồng thời dự kiến: `[CẦN NGƯỜI DÙNG ĐẦU VÀO]`
- Độ dài âm thanh nói trên mỗi phần: `[CẦN ĐẦU VÀO CỦA NGƯỜI DÙNG — theo thời gian tiêu chuẩn APTIS]`

**Tác động nếu không được giải quyết:**
- Không thể xác định được kịch bản kiểm tra tải và kích thước cơ sở hạ tầng
- NFR-01, NFR-02, NFR-04, NFR-06, NFR-07, NFR-08, NFR-09 vẫn còn `[TBD]` và không thể xác minh được trong thử nghiệm

**Giải quyết bằng cách:** Sau phiên kiến trúc TechLead; yêu cầu đầu vào mô hình tải từ Nhà cung cấp

---

## OI-06: Chính sách về phạm vi dùng thử và thu thập khách hàng tiềm năng

**Tình trạng:** MỞ
**Chủ sở hữu:** Tiếp thị nhà cung cấp / Sản phẩm
**Chặn:** FR-88–FR-92 (thông số kỹ thuật hoàn chỉnh), cấu hình bộ câu hỏi thử nghiệm, ước tính chi phí chấm điểm AI cho thử nghiệm

**Câu hỏi:**
1. Những kỹ năng APTIS nào được bao gồm trong bản dùng thử? (Tất cả 4? Chỉ đọc? Một kỹ năng do người dùng lựa chọn?)
2. Mỗi phần thi có bao nhiêu câu hỏi? (Toàn bộ phần? Giảm số lượng?)
3. Khả năng Nói có được tính vào kết quả thi thử không? (Yêu cầu đường dẫn STT + LLM để dùng thử - hàm ý chi phí đáng kể)
4. Việc thu thập khách hàng tiềm năng (FR-91) có cần thiết cho v1 hay bị trì hoãn không?
5. Nếu bao gồm cả việc thu thập khách hàng tiềm năng: việc nhập email là bắt buộc hay tùy chọn để tiếp tục?
6. URL dùng thử là URL tiếp thị dành riêng cho nhà cung cấp hay URL có thể chọn đối tượng thuê?

**Tác động nếu không được giải quyết:**
- Không thể chỉ định hoặc triển khai đầy đủ FR-88 đến FR-92
- Không thể cấu hình bộ câu hỏi thử nghiệm
- Không thể ước tính chi phí chấm điểm AI cho buổi thử nghiệm (xác định liệu Nói thử có khả thi hay không)
- F-11 (Khách/Bản dùng thử) có điều kiện — OI này xác định liệu nó có được vận chuyển trong phiên bản v1 hay không

**Giải quyết bằng cách:** Trước khi bắt đầu phát triển F-11; có thể được hoãn lại hoàn toàn nếu F-11 bị cắt khỏi phạm vi v1

---

## OI-07: Lưu giữ dữ liệu, tuân thủ và Nghị định Việt Nam 13/2023

**Tình trạng:** MỞ
**Chính chủ:** PM + Pháp lý
**Chặn:** NFR-10, NFR-11, FR-92, OR-LGL-02, OR-OPS-03, OR-OPS-06, §3.4.4 (bảng lưu giữ), chọn vùng đám mây

**Câu hỏi:**

| # | Câu hỏi | Tác động |
|---|----------|--------|
| 1 | Thời gian lưu giữ hồ sơ trả lời bài thi (`exam_state`, `attempt_results`)? | NFR-10, đặc tả công việc thanh lọc |
| 2 | Lưu giữ bản ghi âm Nói trong Cloud Storage trong bao lâu? | NFR-11, ước tính chi phí lưu trữ |
| 3 | Thời gian lưu giữ bản ghi STT (`ai_score_drafts`) là bao lâu? | Rủi ro về quyền riêng tư, chi phí lưu trữ |
| 4 | Lưu giữ `sự kiện vi phạm` và `sự kiện thi` trong bao lâu? | Yêu cầu kiểm tra tính liêm chính |
| 5 | Thời gian lưu giữ các mục nhập `notification_log` là bao lâu? | NFR-10 |
| 6 | Cần lưu giữ dữ liệu phiên Khách/Phiên dùng thử trong bao lâu trước khi thanh lọc (FR-92)? | Kích hoạt công việc thanh lọc FR-92 |
| 7 | Nghị định 13/2023/NĐ-CP có áp dụng cho APTIS LMS không? Nếu có thì nghĩa vụ gì? | OR-LGL-02, luồng đồng ý, quyền xóa |
| 8 | Có cần phải bản địa hóa dữ liệu (máy chủ ở Việt Nam) không? | Lựa chọn vùng đám mây, DC-08 |
| 9 | Hệ thống có phải triển khai quy trình làm việc có quyền xóa cho học sinh không? | FR mới có thể được yêu cầu |

**Ghi chú hàm ý về chi phí:** Âm thanh nói ở mức ~5–15 MB cho mỗi lần thử của học sinh × 150.000 lần thử/năm = 750 GB–2,25 TB dung lượng lưu trữ âm thanh mỗi năm. Thời gian lưu giữ là yếu tố điều khiển chi phí lưu trữ chính.

**Tác động nếu không được giải quyết:**
- Không thể tính toán được ước tính chi phí lưu trữ cho Cloud Storage
- Không thể thực hiện các công việc thanh lọc (FR-92, OR-OPS-04) với các thông số cụ thể
- Không thể quyết định vùng đám mây (và do đó chi phí triển khai/độ trễ)
- Rủi ro tuân thủ nếu áp dụng ND 13 và hệ thống không được thiết kế phù hợp

**Giải quyết bằng cách:** Trước khi hoàn thiện kiến trúc đám mây (quyết định vùng đám mây phụ thuộc vào yêu cầu bản địa hóa)

---

## OI-08: Các trường hợp biên liên tục của bài kiểm tra

**Tình trạng:** MỞ
**Chủ sở hữu:** TechLead (giải quyết kỹ thuật) + Nhà cung cấp kinh doanh (quyết định chính sách)
**Chặn:** FR-109 (khôi phục một phần bản ghi), FR-110 (xử lý lỗi micrô), FR-111 (khôi phục sự cố)

**Các trường hợp khó giải quyết:**

**8.1 Ghi âm giữa chừng mạng rớt mạng**
Nếu quá trình ghi đang diễn ra và mạng bị rớt, đoạn nào là "đoạn tốt cuối cùng" cần lưu? Khoảng cách tối đa trong âm thanh (tính bằng giây) làm cho bản ghi bị hỏng chứ không thể phục hồi được?

**8.2 Ngắt kết nối thiết bị âm thanh trong khi ghi âm**
Sau khi kết nối lại, học sinh có ghi lại từ đầu phần đó hay được ghi công cho phần ghi âm một phần? Ai quyết định - chính sách hệ thống hay xem xét hướng dẫn sử dụng của giáo viên?

**8.3 Bộ hẹn giờ hết hạn trong khi ghi âm Nói**
Khi bộ đếm thời gian phía máy chủ cho phần Nói hết hạn trong khi học sinh đang ghi âm, bản ghi âm đó sẽ được cắt và tải lên. Việc cắt có chính xác ở giới hạn thời gian hay hệ thống có cho phép một khoảng thời gian gia hạn ngắn (được đề xuất: 5 giây) để học sinh nói hết câu của mình không?

**8.4 Buộc gửi trong khi ghi âm Bài phát biểu**
Khi Điều phối viên bài kiểm tra buộc phải nộp (FR-41) trong khi học sinh đang ghi âm, âm thanh trong quá trình thực hiện có được giữ nguyên không? Quy trình dự kiến ​​để tải lên một phần âm thanh là gì?

**8.5 Mất mạng liên tục (> thời gian thi còn lại)**
Nếu một học sinh ngoại tuyến lâu hơn thời gian thi còn lại, bài thi của họ sẽ hết hạn. Học sinh nhìn thấy UX gì khi kết nối lại? Ai phê duyệt việc khôi phục - Giáo viên, Điều phối viên hoặc chính sách tự động của hệ thống?

**8.6 Tắt nguồn thiết bị trong khi thi (Flutter Desktop)**
Bộ đệm âm thanh cục bộ bị mất. Các tùy chọn: (a) lượt thi bị hủy vì không có điểm Nói, (b) Giáo viên tự chấm điểm Nói dựa trên một phần dữ liệu có sẵn, (c) Điều phối viên có thể cho phép thi lại chỉ phần Nói. Đây là một quyết định chính sách kinh doanh.

**8.7 Quyền sử dụng micrô bị từ chối trong trình duyệt (không phải sự vắng mặt của thiết bị)**
Học sinh có thể cấp lại giấy phép sau khi bị từ chối. Luồng thử lại là gì? Học sinh phải thử lại bao nhiêu lần trước khi phải ra hiệu cho giám thị? Có thời gian chờ không?

**Tác động nếu không được giải quyết:**
- Không thể chỉ định đầy đủ FR-109 (khôi phục ghi âm một phần) và FR-110 (lỗi micrô)
- Trường hợp tắt nguồn FR-111 (khôi phục sự cố) không được xử lý
- Các trường hợp khó khăn có thể gây mất dữ liệu hoặc kết quả thi không công bằng nếu không được giải quyết trước khi thực hiện

**Giải quyết bằng cách:** Hội thảo dành riêng cho các trường hợp đặc biệt với TechLead (luồng kỹ thuật) + Sản phẩm của nhà cung cấp (quyết định chính sách); trước khi phát triển cụm F-13

---

## Các mục trong SRS bổ sung [CẦN ĐẦU VÀO CỦA NGƯỜI DÙNG]

Các mục sau đây được gắn thẻ nội tuyến trong các phần SRS và yêu cầu độ phân giải trước khi các phần đó có thể được hoàn thiện:

| Vị trí gắn thẻ | Câu hỏi | Chủ sở hữu |
|-------------|----------|-------|
| FR-28 | Xác nhận định dạng bảng ánh xạ điểm (phạm vi điểm cho mỗi kỹ năng → điểm) và xử lý các điểm ngoài phạm vi | Người quản lý nội dung + TechLead |
| FR-58 | Tên học sinh có nên ẩn danh trong xếp hạng lớp không? (Ưu tiên quyền riêng tư) | Sản phẩm của nhà cung cấp + Phản hồi của người thuê |
| FR-59 | Ngưỡng điểm "học sinh yếu" mặc định là gì? (Gợi ý: dưới B1) | Sản phẩm của nhà cung cấp |
| FR-85 | Ngôn ngữ nào là mặc định cho mỗi người thuê? Quản trị viên người thuê có thể cấu hình cái này không? | Sản phẩm của nhà cung cấp |
| HOẶC-OPS-01 | Xác định ngưỡng cảnh báo giám sát cụ thể (tỷ lệ lỗi %, độ sâu hàng đợi N, CPU %) | TechLead + Hoạt động |
| HOẶC-OPS-04 | Xác định "giờ thi cao điểm" để loại trừ thời gian bảo trì (đề xuất: 07:00–22:00 VNT) | Sản phẩm của nhà cung cấp |
| HOẶC-OPS-04 | Xác định khoảng thời gian công việc được lên lịch cụ thể để kiểm tra lời nhắc SLA | Sản phẩm của nhà cung cấp (phụ thuộc OI-03) |
| HOẶC-OPS-06 | Xác định thời gian lưu giữ nhật ký | PM + Legal (phụ thuộc OI-07) |
| OI-05 | Số lượng người thuê khi khởi chạy và số phiên đồng thời cao nhất (tải đầu vào mô hình) | Kinh doanh nhà cung cấp |

---

## Theo dõi độ phân giải

| ôi | Chủ sở hữu | Phần chặn | Trạng thái | Giải quyết bởi |
|----|-------|-------------------|--------|----------||
| OI-01 | TechLead | §3.1, §3.2 (FR-18, FR-95, FR-97, FR-102, FR-84) | MỞ | Phiên kiến ​​trúc |
| OI-02 | TechLead | §3.2 (FR-30, FR-31), §3.3 (NFR-09) | MỞ | Phiên kiến ​​trúc |
| OI-03 | Kinh doanh nhà cung cấp | §3.2 (FR-83), §3.3 (NFR-09) | MỞ | Trước nhà phát triển F-10 |
| OI-04 | Kinh doanh nhà cung cấp | §3.2 (FR-100, FR-37) | MỞ | Trước nhà phát triển F-12 |
| OI-05 | TechLead | §3.3 (NFR-01/02/04/06/07/08/09) | MỞ | Sau buổi kiến ​​trúc |
| OI-06 | Tiếp thị nhà cung cấp | §3.2 (FR-88–92) | MỞ | Trước nhà phát triển F-11 |
| OI-07 | Thủ tướng + Pháp lý | §3.3 (NFR-10/11), §3.4 §3.7.2 | MỞ | Trước kiến ​​trúc |
| OI-08 | TechLead + Nhà cung cấp | §3.2 (FR-109/110/111) | MỞ | Xưởng F-13 |