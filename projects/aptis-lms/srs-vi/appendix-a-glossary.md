# SRS Phụ lục A — Bảng thuật ngữ
## APTIS LMS
**Phiên bản:** 1.0 | **Ngày:** 2026-06-16 | **Trạng thái:** BẢN THẢO

---

Tất cả các thuật ngữ về miền, kỹ thuật và hệ thống cụ thể được sử dụng trong SRS này. Được liệt kê theo thứ tự bảng chữ cái. Trong trường hợp một thuật ngữ có định nghĩa giống hệt nhau trong bảng chú giải thuật ngữ giai đoạn kế hoạch thì phiên bản SRS này là chính thức.

---

**Tính điểm AI**
Quy trình tự động đánh giá phản hồi Viết và Nói của học sinh bằng API AI của bên thứ ba: STT (Chuyển giọng nói thành văn bản) để chép âm và LLM (Mô hình ngôn ngữ lớn) để chấm điểm dựa trên phiếu tự đánh giá. Tính điểm AI tạo ra điểm dự thảo (được lưu trong `ai_score_drafts`) phải được Giáo viên xem xét và xác nhận trước khi hiển thị cho học sinh (BR-13). Xem FR-30, FR-31.

**Phiên ẩn danh**
Bản ghi phiên phía máy chủ tồn tại trong thời gian ngắn được tạo cho người dùng Khách truy cập bài kiểm tra dùng thử mà không cần đăng ký tài khoản. Phiên ẩn danh không có `user_id` và hết hạn sau 2 giờ hoặc khi gửi bản dùng thử. Tất cả dữ liệu từ phiên ẩn danh sẽ bị xóa sau khoảng thời gian lưu giữ được định cấu hình. Xem FR-08, FR-92.

**APTIS**
Đánh giá tiếng Anh chuyên nghiệp. Bài kiểm tra trình độ tiếng Anh tiêu chuẩn do Hội đồng Anh phát triển và quản lý. APTIS kiểm tra bốn kỹ năng: Đọc, Viết, Nghe và Nói. Kết quả được báo cáo dưới dạng các dải phù hợp với CEFR (A1 đến C). APTIS LMS là một nền tảng mô phỏng thực hành và không được liên kết hoặc ủy quyền bởi Hội đồng Anh. Xem DC-11, OR-LGL-01.

**Cố gắng**
Một học sinh thực hiện một buổi thi. Một lần thi bao gồm việc học sinh hoàn thành (hoặc hoàn thành một phần) tất cả các kỹ năng và các phần của một buổi thi. Theo mặc định, mỗi học sinh được phép thử một lần trong mỗi buổi học (BR-06); thi lại tạo ra lần thử thứ hai (`attempt_number = 2`) và yêu cầu phê duyệt rõ ràng (FR-43). Xem thực thể `exam_attempts`.

**Ban nhạc**
Mức độ thành thạo APTIS/CEFR được ấn định cho thành tích của học sinh trong một kỹ năng. Giá trị băng tần: A1 (Sơ cấp), A2 (Sơ cấp), B1 (Trung cấp), B2 (Trung cấp), C (Nâng cao). Các dải được lấy từ điểm thô bằng cách sử dụng Bảng ánh xạ dải do nhà cung cấp định cấu hình (FR-28). Đối với môn Viết và Nói, điểm được Giáo viên chỉ định trong quá trình xác nhận điểm (FR-33).

**Bảng ánh xạ băng tần**
Bảng cấu hình được duy trì bởi Trình quản lý nội dung của nhà cung cấp ánh xạ các phạm vi điểm thô tới các dải APTIS cho mỗi kỹ năng. Ví dụ: Đọc điểm thô 18–22 = B1. Bảng này là nguồn dẫn xuất băng tần có thẩm quyền duy nhất (Giả định A-10). Lỗi trong bảng dẫn đến cờ `MAPPING_ERROR` (FR-28).

**BR (Quy tắc kinh doanh)**
Một chính sách hoặc ràng buộc cụ thể đối với miền kinh doanh mà hệ thống phải thực thi. Quy tắc kinh doanh được đánh số từ BR-01 đến BR-15 và được trình bày chi tiết trong §3.2 và spec.md.

**CDN (Mạng phân phối nội dung)**
Mạng máy chủ được phân bổ theo địa lý cung cấp nội dung (tệp âm thanh, hình ảnh) cho người dùng với độ trễ thấp. Được sử dụng để Nghe phân phối âm thanh cho khách hàng thi (SI-01). Các nút biên CDN phải được đặt tại Việt Nam hoặc Đông Nam Á để đáp ứng mục tiêu về độ trễ (NFR-08).

**CEFR (Khung tham chiếu chung về ngôn ngữ của Châu Âu)**
Một tiêu chuẩn quốc tế để mô tả khả năng ngôn ngữ. Cấp độ: A1, A2 (Người dùng cơ bản), B1, B2 (Người dùng độc lập), C1, C2 (Người dùng thành thạo). Các dải APTIS căn chỉnh theo A1–C (C ánh xạ tới C1/C2 được kết hợp trong APTIS).

**Người quản lý nội dung**
Vai trò người dùng phía Nhà cung cấp chịu trách nhiệm tạo và quản lý ngân hàng câu hỏi APTIS, mẫu bài kiểm tra, nội dung âm thanh và hình ảnh cũng như xem xét số liệu thống kê phân tích mục. Người quản lý nội dung không thể quản lý người thuê, giấy phép hoặc dữ liệu sinh viên. Xem §2.3.

**Khóa học**
Một vùng chứa có giới hạn thời gian trong một đối tượng thuê để nhóm học sinh vào một giai đoạn học tập. Một khóa học có `ngày_bắt_đầu` và `ngày_kết thúc`; các buổi thi nằm trong phạm vi một khóa học tích cực; học viên chỉ có thể tham gia các buổi thi trong khi khóa học đang diễn ra. Xem FR-44, thực thể `khóa học`.

**DC (Ràng buộc thiết kế)**
Một hạn chế không thể thương lượng đối với thiết kế hệ thống được áp đặt bởi các nhiệm vụ công nghệ, yêu cầu bảo mật hoặc quyết định của các bên liên quan. Các ràng buộc thiết kế được đánh số từ DC-01 đến DC-12 và được ghi lại trong §3.5.

**Chỉ số phân biệt đối xử**
Một thước đo thống kê về mức độ phân biệt một câu hỏi giữa học sinh có thành tích cao và học sinh có thành tích thấp. Được tính bằng mối tương quan giữa điểm-ngược giữa độ chính xác của mỗi câu hỏi (0/1) và tổng điểm bài thi. Các giá trị nằm trong khoảng từ −1 đến 1. Các câu hỏi có chỉ số < 0,2 được gắn cờ là "Phân biệt đối xử kém"; các câu hỏi có chỉ số < 0 được gắn cờ là "Cần xem lại". Xem FR-69.

**Chỉ số độ khó (giá trị p)**
Tỷ lệ học sinh trả lời đúng một câu hỏi: `p = Correct_responses / Total_responses`. Câu hỏi có `p < 0,3` là "Quá khó"; `p > 0.9` là "Quá dễ." Cả hai thái cực đều được gắn cờ để Trình quản lý nội dung xem xét. Xem FR-68.

**Khách hàng thi**
Ứng dụng đa nền tảng Flutter được sinh viên sử dụng để làm bài kiểm tra thực hành APTIS. Chạy trên Flutter Web, Flutter Desktop (Windows/macOS) và tùy chọn Flutter Mobile (iOS/Android — OI-01). Ứng dụng khách Bài kiểm tra là một trong ba cổng trong nền tảng APTIS LMS.

**Điều phối viên kỳ thi**
Vai trò người dùng phía đối tượng thuê chịu trách nhiệm triển khai các phiên kiểm tra, theo dõi các bài kiểm tra trực tiếp thông qua bảng điều khiển thời gian thực (FR-39) và xử lý các sự cố trong thời gian kiểm tra (gia hạn thời gian FR-40, buộc gửi FR-41, thi lại FR-43).

**Phần thi**
Một phiên bản theo lịch của bài kiểm tra được tạo bởi Giáo viên hoặc Điều phối viên bài kiểm tra. Một buổi thi chỉ định mẫu bài thi, học sinh đủ điều kiện, khung thời gian mở/đóng và cấu hình chống gian lận. Nhiều sinh viên học cùng một buổi cùng một lúc. Xem FR-37, thực thể `exam_sessions`.

**Trạng thái thi**
Bản ghi câu trả lời cho mỗi câu hỏi phía máy chủ cho một lần thử đang diễn ra. Cập nhật trên mỗi lần gửi câu trả lời của học sinh (FR-105). Cho phép tiếp tục sau khi ngắt kết nối (FR-106) và khôi phục sự cố (FR-111). Xem thực thể `exam_state`.

**Mẫu bài thi**
Một bộ câu hỏi được đặt tên và có thể sử dụng lại, được sắp xếp theo kỹ năng và phần do Người quản lý nội dung tạo ra. Các buổi thi luôn được tạo từ một mẫu đã xuất bản. Mẫu phải bao gồm tất cả 4 kỹ năng và tất cả các phần bắt buộc để có thể xuất bản được (FR-12). Xem thực thể `exam_templates`.

**FCM (Nhắn tin qua đám mây Firebase)**
Dịch vụ thông báo đẩy của Google. Được sử dụng cho thông báo đẩy của sinh viên trên Flutter Mobile (SI-03, FR-84). Có điều kiện trên Flutter Mobile nằm trong phạm vi nền tảng (OI-01).

**Bắt buộc gửi**
Hành động của Điều phối viên Kỳ thi nhằm hoàn tất bài thi của học sinh trước khi học sinh tự nguyện nộp bài. Lần thử được đánh dấu `force_submit`; tất cả các câu trả lời kiên trì tại thời điểm đó sẽ trở thành bài nộp cuối cùng. Xem FR-41.

**FR (Yêu cầu chức năng)**
Một yêu cầu chỉ rõ một hành vi mà hệ thống phải thực hiện. Các FR được đánh số từ FR-01 đến FR-111 trong SRS này và được ghi lại trong §3.2.

**Nhóm (Lớp)**
Một phân khu được đặt tên của một khóa học. Học sinh được ghi danh theo nhóm; Giáo viên được phân vào nhóm và chỉ có thể quản lý, xem học sinh trong nhóm được phân công. Xem FR-45, thực thể `nhóm`.

**Khách (Người dùng thử)**
Người dùng không được xác thực truy cập vào bài thi thử mà không có tài khoản đã đăng ký. Phiên khách sử dụng phiên ẩn danh (FR-08) và tạm thời; tất cả dữ liệu sẽ bị xóa sau thời gian lưu giữ (FR-92). Xem F-11.

**Hàng đợi đánh giá con người**
Giao diện được Giáo viên sử dụng để xem điểm dự thảo AI cho bài nộp Viết và Nói và xác nhận hoặc ghi đè chúng. Xem FR-32, UI-06.

**Phân tích vật phẩm**
Phân tích thống kê các đề thi riêng lẻ để đánh giá chất lượng sư phạm. Số liệu chính: chỉ số độ khó (giá trị p, FR-68) và chỉ số phân biệt đối xử (FR-69). Được Người quản lý nội dung sử dụng để xác định và cải thiện các câu hỏi có vấn đề. Xem F-07, FR-67–FR-70.

**JWT (Mã thông báo web JSON)**
Một định dạng mã thông báo nhỏ gọn, khép kín được sử dụng để xác thực. Trong APTIS LMS: mã thông báo truy cập (tồn tại trong thời gian ngắn, 15 phút) chứa `user_id`, `tenant_id` và `roles[]`. Làm mới mã thông báo (tồn tại lâu dài, ≤ 7 ngày) cho phép gia hạn mã thông báo. Mã thông báo truy cập không có trạng thái; Mã thông báo làm mới được lưu trữ phía máy chủ để có thể thu hồi. Xem FR-02, NFR-13.

**Chế độ kiosk**
Một chế độ hoạt động bị hạn chế trong đó Flutter Desktop Exam Client ngăn học sinh chuyển sang các ứng dụng hoặc cửa sổ khác trong khi thi. Được triển khai bằng cách sử dụng API quản lý cửa sổ cấp hệ điều hành nơi khả năng nền tảng cho phép. Xem FR-102 (Có điều kiện).

**Giấy phép**
Quyền truy cập dựa trên chỗ ngồi do Nhóm bán hàng của nhà cung cấp cấp cho người thuê. Giấy phép chỉ định `seat_count` (tài khoản sinh viên tối đa) và `ngày_hết hạn`. Người thuê không có giấy phép hoạt động hợp lệ sẽ ở chế độ chỉ đọc (BR-10). Xem FR-73, thực thể `giấy phép`.

**LLM (Mô hình ngôn ngữ lớn)**
Một mô hình AI có khả năng hiểu và tạo ra văn bản. Được sử dụng trong APTIS LMS để đánh giá bảng điểm Viết và Nói của học sinh dựa trên tiêu chí đánh giá APTIS và đưa ra điểm dự thảo cũng như tường thuật phản hồi. Nhà cung cấp TBD (OI-02). Xem SI-05, FR-31.

**Nhiều người thuê**
Kiến trúc phần mềm trong đó một phiên bản duy nhất của ứng dụng phục vụ nhiều đối tượng thuê (khách hàng) độc lập với dữ liệu riêng biệt. APTIS LMS sử dụng nhiều bên thuê dựa trên tên miền phụ (`{slug}.aptis-lms.vn`) được thực thi tại cổng API và các lớp cơ sở dữ liệu. Xem DC-02.

**NFR (Yêu cầu phi chức năng)**
Thuộc tính chất lượng hoặc ràng buộc về hành vi của hệ thống hơn là một chức năng cụ thể. NFR được đánh số từ NFR-01 đến NFR-14 trong SRS này và được ghi lại trong §3.3.

**OI (Mục mở)**
Một mục TBD yêu cầu độ phân giải trước khi phần SRS tương ứng có thể được hoàn thiện. Các mục mở được đánh số từ OI-01 đến OI-08 (với các mục bổ sung trong Phụ lục B) và được theo dõi trong Phụ lục B.

**Phần**
Một phần phụ của kỹ năng trong kỳ thi APTIS. Đọc: Phần A, B, C, D. Viết: Phần A, B, C. Nghe: Phần A, B, C, D. Nói: Phần A, B, C, D, E. Tổng cộng: 16 phần, 4 kỹ năng.

**PITR (Phục hồi tại thời điểm)**
Chiến lược sao lưu cơ sở dữ liệu cho phép khôi phục cơ sở dữ liệu về bất kỳ điểm nào trong cửa sổ lưu giữ bản sao lưu. Cung cấp Mục tiêu điểm khôi phục (RPO) tốt hơn nhiều so với ảnh chụp nhanh hàng ngày. Cần thiết cho cơ sở dữ liệu APTIS LMS (OR-OPS-03).

**Tương quan điểm-lưỡng chuỗi**
Một thước đo thống kê tương quan giữa một biến nhị phân (câu hỏi đúng = 1, sai = 0) với một biến liên tục (tổng điểm thi). Được sử dụng làm chỉ số phân biệt đối xử để phân tích vật phẩm. Phạm vi: −1 đến 1.

**Hạn ngạch (Hạn ngạch chỗ ngồi)**
Số lượng tài khoản sinh viên đang hoạt động tối đa được phép trong một đối tượng thuê cùng một lúc, được xác định bởi `seat_count` của giấy phép hiện tại. Theo dõi theo thời gian thực thông qua bảng `đăng ký`. Việc đăng ký bị chặn khi `seat_used ≥ ghế_count` (BR-05). Xem FR-51.

**RBAC (Kiểm soát truy cập dựa trên vai trò)**
Mô hình quyền trong APTIS LMS nơi người dùng được cấp các vai trò xác định quyền truy cập của họ. Người dùng bên thuê có thể giữ nhiều vai trò cùng lúc (BR-01); quyền có hiệu lực là sự kết hợp của tất cả các vai trò được giao. Xem DC-09, FR-04.

**Tiếp tục**
Khả năng học sinh tiếp tục bài kiểm tra đang diễn ra sau khi ngắt kết nối khỏi chính xác trạng thái câu hỏi và câu trả lời được máy chủ xác nhận cuối cùng, trong khi bộ đếm thời gian có thẩm quyền của máy chủ vẫn tiếp tục. Xem FR-106.

**Thi lại**
Lần thử thứ hai hoặc tiếp theo trong một buổi thi, chỉ được phép khi được Giáo viên hoặc Điều phối viên Kỳ thi phê duyệt rõ ràng (BR-07, FR-43). Thi lại tạo một bản ghi `exam_attempt` mới với `số_lần thử ≥ 2`.

**Tiêu đề**
Tiêu chí chấm điểm được sử dụng để đánh giá các phản hồi Viết và Nói của APTIS. Mỗi phần có tiêu chí cụ thể (ví dụ: ngữ pháp, từ vựng, tính mạch lạc, hoàn thành nhiệm vụ) kèm theo giá trị điểm. Thang đánh giá được sử dụng bởi cả hệ thống tính điểm AI (FR-31) và Giáo viên trong quá trình đánh giá con người (FR-33).

**Đội ngũ bán hàng**
Vai trò người dùng phía Nhà cung cấp chịu trách nhiệm quản lý các mối quan hệ khách hàng của đối tượng thuê và tạo/gia hạn giấy phép thông qua Cổng bán hàng. Các thành viên của Nhóm bán hàng không có quyền truy cập vào dữ liệu bài kiểm tra hoặc sinh viên. Xem F-09.

**Ghế**
Một đơn vị hạn ngạch giấy phép của người thuê nhà. Một chỗ ngồi = một người hiện đang theo học, tài khoản sinh viên đang hoạt động. Việc hủy đăng ký học sinh sẽ nhường một chỗ (FR-50). Số `số ghế_đã sử dụng` của đối tượng thuê là số bản ghi đăng ký có `unenrolled_at IS NULL AND Seat_counted = true`.

** Chấm điểm SLA**
Thời gian tối đa đã được thống nhất từ khi nộp bài thi đến khi có điểm được giáo viên xác nhận. Bao gồm thời gian quy trình AI (mục tiêu: 15 phút, NFR-09 TBD) cộng với thời gian đánh giá của giáo viên (TBD - OI-03). Điều khiển trình kích hoạt thông báo nhắc nhở đánh giá (FR-83).

**Sên**
Mã định danh chuỗi an toàn URL dành cho đối tượng thuê, được dùng làm tiền tố tên miền phụ: `{slug}.aptis-lms.vn`. Sên là duy nhất trên toàn cầu trên nền tảng, không thể thay đổi sau khi đối tượng thuê được kích hoạt và chỉ có chữ và số viết thường với dấu gạch nối.

**Bài nói**
Đầu ra văn bản của API STT được áp dụng cho bản ghi âm Nói của học sinh. Bảng điểm là đầu vào chính để tính điểm dựa trên LLM (FR-31) và được hiển thị cho Giáo viên trong quá trình xem xét điểm (FR-32). Bảng điểm là PII (nội dung bài phát biểu của một cá nhân cụ thể). Xem `ai_score_drafts.stt_transcript`.

**SSE (Sự kiện do máy chủ gửi)**
Giao thức đẩy máy chủ đến máy khách một chiều qua HTTP. Được sử dụng làm phương án dự phòng cho WebSocket cho bảng thông tin giám sát bài kiểm tra trực tiếp (FR-39, CI-02).

**STT (Chuyển giọng nói thành văn bản)**
Dịch vụ AI chuyển đổi bản ghi âm giọng nói thành bản ghi văn bản. Được sử dụng để chấm điểm kỹ năng Nói APTIS; bảng điểm sau đó được đánh giá bởi LLM. Nhà cung cấp TBD (OI-02). Xem SI-04, FR-30.

**Quản trị viên cấp cao**
Vai trò người dùng phía Nhà cung cấp có quyền truy cập quản trị toàn cầu vào tất cả dữ liệu và cấu hình hệ thống. Có thể tạo/quản lý người thuê, xem tất cả dữ liệu, buộc người dùng đăng xuất và thực hiện các biện pháp can thiệp khẩn cấp. Vai trò có đặc quyền cao nhất trong hệ thống.

**Người thuê nhà**
Trường học hoặc trung tâm đào tạo đã mua giấy phép APTIS LMS và vận hành không gian tên biệt lập của riêng họ trong nền tảng. Mỗi đối tượng thuê có tên miền phụ riêng, cơ sở người dùng riêng và dữ liệu được cách ly nghiêm ngặt. Tất cả dữ liệu trong phạm vi đối tượng thuê bao gồm `tenant_id` trong mọi bản ghi cơ sở dữ liệu.

**Quản trị viên người thuê**
Vai trò người dùng trong một đối tượng thuê có đầy đủ đặc quyền quản trị chỉ dành cho đối tượng thuê đó. Quản lý người dùng, khóa học, nhóm, khả năng hiển thị giấy phép và phân tích trong đối tượng thuê. Không thể truy cập dữ liệu của người thuê khác hoặc các chức năng của Cổng thông tin nhà cung cấp.

** Hẹn giờ (Máy chủ có thẩm quyền) **
Bộ hẹn giờ thi chạy trên máy chủ chứ không phải máy khách. Máy chủ tính toán `time_remaining = part_duration + phần mở rộng − (now − part_start_time)`. Máy khách hiển thị giá trị do máy chủ cung cấp; thao tác phía máy khách không ảnh hưởng đến bộ đếm thời gian của máy chủ. Xem thực thể DC-04, FR-104, `part_timers`.

**Cổng thông tin nhà cung cấp**
Ứng dụng Flutter Web được nhân viên phía Nhà cung cấp (Quản trị viên cấp cao, Người quản lý nội dung, Nhân viên hỗ trợ, Nhóm bán hàng) sử dụng để quản lý tất cả đối tượng thuê, nội dung và giấy phép. Có thể truy cập tại `admin.aptis-lms.vn` ​​mà không cần xác định phạm vi đối tượng thuê.

**Sự kiện vi phạm**
Một sự kiện chống gian lận được ghi lại khi học sinh thực hiện hành động đáng ngờ về tính toàn vẹn trong bài kiểm tra: chuyển đổi tab, mất tiêu điểm ở cấp hệ điều hành, thoát toàn màn hình hoặc cố gắng sao chép-dán. Các sự kiện vi phạm là không thể thay đổi ở lớp ứng dụng (DC-10) và tích lũy theo ngưỡng cảnh báo và chấm dứt có thể định cấu hình (FR-100). Xem thực thể FR-101, `violation_events`.

**Ngưỡng vi phạm**
Có thể định cấu hình cho mỗi phiên thi: `warning_threshold` (số lần vi phạm tại đó lớp phủ cảnh báo được hiển thị) và `terminate_threshold` (số lần vi phạm tại đó lần thử được tự động gửi). Đặt trong quá trình tạo phiên (FR-37). Giá trị mặc định TBD (OI-04).

**WebSocket**
Giao thức liên lạc song công hoàn toàn qua TCP, được sử dụng cho bảng thông tin giám sát kỳ thi theo thời gian thực (FR-39, CI-02). WebSocket là giao thức chính; SSE là dự phòng.