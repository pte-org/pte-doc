# Đề xuất giải quyết feedback: chất lượng học liệu, cấu hình thiết bị và luyện tập AI

- Ngày: 2026-10-02
- Trạng thái: Draft — kết quả brainstorm, chưa phải phạm vi triển khai đã được phê duyệt.
- Phạm vi liên quan: question bank, giao diện tổ chức/giáo viên, pte-app student và module luyện tập.
- Mục đích: mô tả giải pháp, giá trị và bằng chứng nghiệm thu cho từng feedback của giáo viên.

## 1. Feedback và hướng giải quyết

| Feedback của giáo viên | Vấn đề cần giải quyết | Giải pháp đề xuất | Bằng chứng nghiệm thu |
|---|---|---|---|
| Thiếu bộ tiêu chí đảm bảo tính phù hợp và chuẩn xác từ ngân hàng học liệu; chưa phân dạng câu hỏi theo level | Chưa có cơ sở để duyệt chất lượng, xác định độ khó và chọn câu phù hợp năng lực | Bộ tiêu chí học liệu, metadata độ khó, quy trình giáo viên kiểm duyệt và thống kê kết quả làm bài | Câu chưa đạt tiêu chí bị chặn đưa vào pool; câu đã duyệt có mức khó và lý do đánh giá |
| Không cung cấp được các ràng buộc về cấu hình hoạt động của máy tính tổ chức kiểm tra | Tổ chức chưa xác định được máy nào đủ điều kiện và cách xử lý khi không đạt | Device policy theo kỳ thi, kiểm tra trước thi và audit kết quả | Student thấy từng điều kiện đạt/chưa đạt; điều kiện bắt buộc không đạt thì không được bắt đầu |
| Chưa ứng dụng AI trong module luyện tập; chỉ hỗ trợ mô phỏng thi thử, chưa chọn theo aim điểm/level | Practice chưa có mục tiêu học tập, chẩn đoán điểm yếu và phản hồi cá nhân hóa | Practice theo mục tiêu, chẩn đoán năng lực, lựa chọn câu phù hợp và phản hồi AI có căn cứ | Student đặt mục tiêu, nhận buổi luyện, xem giải thích lỗi và nhận bài tiếp theo dựa trên kết quả |

## 2. Ngân hàng học liệu có tiêu chí chất lượng và độ khó

### 2.1. Thông tin của mỗi câu hỏi

- Task type và các kỹ năng được đánh giá theo hợp đồng task type của hệ thống.
- Chủ đề và đặc điểm ngôn ngữ cần luyện, ví dụ từ vựng, ngữ pháp, nghe chi tiết hoặc đọc suy luận.
- Độ khó ban đầu: `Easy`, `Medium`, `Hard`.
- Lý do đánh giá độ khó và người đánh giá.
- Đáp án chuẩn, reference answer hoặc rubric tùy dạng câu.
- Lời giải hoặc hướng dẫn đánh giá phù hợp dạng câu.
- Nguồn học liệu và thông tin quyền sử dụng.
- Trạng thái kiểm duyệt, người duyệt và thời điểm duyệt.

Độ khó và mức năng lực học sinh là hai thông tin khác nhau. Nhãn `Hard` không tự chứng minh câu hỏi phân loại được học sinh giỏi và không được tự quy đổi thành một mốc điểm PTE như 79.

### 2.2. Bộ tiêu chí kiểm duyệt đề xuất

| Nhóm tiêu chí | Nội dung kiểm tra | Điều kiện đạt |
|---|---|---|
| Chuẩn xác | Nội dung, đáp án, lời giải và rubric nhất quán | Không có lỗi kiến thức hoặc mâu thuẫn làm ảnh hưởng kết quả |
| Phù hợp task type | Prompt, lựa chọn trả lời, media và cách chấm phù hợp dạng câu | Đáp ứng đầy đủ contract và quy tắc của task type |
| Rõ ràng | Hướng dẫn đủ thông tin; đáp án nhiễu có cơ sở | Không có sự mơ hồ ngoài chủ đích đánh giá |
| Media | Audio/ảnh truy cập được và đủ chất lượng để làm bài | File hoạt động và không thiếu nội dung cần thiết |
| Độ khó | Có nhãn và lý do theo tiêu chí của dạng câu | Giáo viên giải thích được mức khó đã chọn |
| Nguồn | Có nguồn và cơ sở sử dụng học liệu | Người duyệt xác nhận thông tin nguồn/quyền sử dụng |

Các yếu tố đánh giá độ khó có thể gồm độ dài, từ vựng, cấu trúc câu, số bước suy luận, độ gần nghĩa của đáp án nhiễu và tốc độ/độ phức tạp audio. Cần định nghĩa rubric riêng cho từng nhóm task type; không dùng cùng một ngưỡng độ dài để kết luận độ khó cho mọi dạng câu.

### 2.3. Quy trình duyệt

1. Người biên soạn tạo bản nháp và điền metadata.
2. Hệ thống kiểm tra các điều kiện cấu trúc tự động: trường bắt buộc, media và contract task type.
3. Giáo viên/người có quyền duyệt kiểm tra nội dung và bộ tiêu chí, sau đó duyệt hoặc trả lại kèm lý do.
4. Chỉ revision đã được duyệt và đủ điều kiện lifecycle hiện có mới được đưa vào pool thi/luyện tập.
5. Sửa nội dung đã duyệt phải tạo revision cần duyệt lại; giữ lịch sử và snapshot của bài đã phát hành.

Vai trò giáo viên là vai trò nghiệp vụ đề xuất. Khi lập plan cần xác định role/permission hiện hữu phù hợp; không mặc định examiner hoặc host được sửa ngân hàng học liệu toàn nền tảng.

### 2.4. Hiệu chỉnh sau khi có dữ liệu

Hệ thống thống kê tỷ lệ đúng, thời gian làm và phân bố kết quả theo task type/mức năng lực. Khi mẫu dữ liệu đủ, có thể bổ sung phân tích khả năng phân biệt nhóm năng lực để giáo viên xem xét lại độ khó.

Trong MVP, các thống kê chỉ hỗ trợ quyết định. Giáo viên chịu trách nhiệm xác nhận điều chỉnh. Ngưỡng số lượt làm hợp lệ và phương pháp đánh giá khả năng phân loại cần được chốt trước khi công bố kết luận; không suy diễn từ vài lượt test.

## 3. Device policy cho tổ chức kiểm tra

### 3.1. Cấu hình tại host

Host chọn policy cho kỳ thi từ các điều kiện mà desktop app có khả năng kiểm tra thực tế. Mỗi điều kiện có mức xử lý `Cảnh báo` hoặc `Chặn bắt đầu`, với thông báo và hướng khắc phục.

| Điều kiện đề xuất | Cách sử dụng |
|---|---|
| Phiên bản app và OS được hỗ trợ | Kiểm tra khả năng tương thích của runtime và nền tảng |
| Microphone | Bắt buộc khi bài thi cần thu âm; thông báo cách kết nối/cấp quyền |
| Loa/headset | Kiểm tra phát âm thanh khi bài có audio; ghi nhận xác nhận của student nếu chưa thể đo tự động |
| Kết nối dịch vụ | Xác minh khả năng truy cập API và media cần thiết |
| Số màn hình | Cảnh báo/chặn nhiều màn hình nếu nền tảng hỗ trợ phát hiện |
| Fullscreen và kích hoạt chống gian lận | Kiểm tra trạng thái kích hoạt khi policy yêu cầu |

Không được hiển thị một điều kiện là “đạt” nếu app không đo được. Khi không hỗ trợ kiểm tra phải trả về trạng thái rõ ràng và xử lý theo policy. Bài kiểm tra loa có xác nhận của người dùng phải phân biệt với phép đo tự động.

### 3.2. Luồng student

1. Đăng nhập và cung cấp session ID theo luồng hiện có.
2. Tải policy của kỳ thi và hiển thị kiểm tra thiết bị.
3. Kích hoạt fullscreen/chống gian lận từ màn hình kiểm tra thiết bị khi policy yêu cầu.
4. Hiển thị từng điều kiện, kết quả và cách khắc phục; cho kiểm tra lại.
5. Cho bắt đầu khi tất cả điều kiện `Chặn bắt đầu` đã đạt. Điều kiện cảnh báo cần được hiển thị và ghi nhận.
6. Ghi audit kiểm tra và các vi phạm phát sinh trong bài theo policy.

Policy hiệu lực cần được server xác nhận và gắn với attempt để tránh client tự hạ mức ràng buộc. Kết quả kiểm tra ghi kèm thời điểm và phiên bản policy; chỉ thu thập thông tin thiết bị cần cho điều kiện kiểm tra.

### 3.3. Liên hệ với mode practice

Giữ lựa chọn bật/tắt chống gian lận cho practice. Practice bật chống gian lận phải áp dụng các điều kiện tương ứng của policy; practice tắt vẫn kiểm tra khả năng chạy bài như API và media cần thiết.

Device policy và cơ chế chống gian lận cần phối hợp với luồng finish/submit hiện có. Các tuyên bố về phím tắt, fullscreen, thoát app và khôi phục khi lỗi phải dựa trên kiểm thử từng nền tảng. Phạm vi đề xuất không bao gồm thiết lập Windows Assigned Access/Shell Launcher ở cấp hệ điều hành.

## 4. Luyện tập theo mục tiêu và phản hồi AI

### 4.1. Mục tiêu học tập

Student chọn aim điểm PTE, kỹ năng cần cải thiện và thời gian luyện mỗi ngày. Aim là mục tiêu học tập; điểm hiển thị từ bài luyện phải được ghi rõ là kết quả nội bộ, trừ khi đã có phương pháp quy đổi được kiểm chứng.

Nếu chưa có kết quả phù hợp gần đây, student làm bài chẩn đoán ngắn. Hệ thống sử dụng kết quả theo task type để xác định mức khởi đầu và nhóm lỗi cần luyện.

### 4.2. Luồng luyện tập đề xuất

1. Student chọn mục tiêu và kỹ năng.
2. Hệ thống thực hiện chẩn đoán hoặc dùng kết quả phù hợp gần đây.
3. Hệ thống chọn câu đã duyệt theo mức hiện tại, task type và điểm yếu.
4. Student làm buổi luyện; thời gian và điều hướng áp dụng cấu hình practice.
5. Hệ thống chấm theo đáp án/rubric phù hợp và lưu bài làm.
6. AI giải thích lỗi, dẫn căn cứ từ học liệu và gợi ý cách cải thiện.
7. Hệ thống chọn buổi tiếp theo theo kết quả và lịch sử luyện; student thấy lý do lựa chọn.

Ví dụ: student đặt aim 65 và chọn Reading. Buổi luyện gồm 10 câu phù hợp mức hiện tại. Nếu thường sai câu đọc suy luận, buổi sau tăng tỷ trọng dạng này; nếu kết quả ổn định, hệ thống đề xuất tăng độ khó. Con số 10 là cấu hình demo đề xuất, không phải số câu cố định của template thi.

### 4.3. Phân công trách nhiệm AI và hệ thống

| Thành phần | Trách nhiệm |
|---|---|
| Question bank và giáo viên | Cung cấp nội dung đã duyệt, đáp án, rubric, lời giải và metadata |
| Hệ thống lựa chọn bài | Lọc câu đủ điều kiện và chọn theo quy tắc có thể giải thích |
| Bộ chấm | Xác định kết quả theo đáp án/rubric và hợp đồng chấm của dạng câu |
| AI feedback | Giải thích lỗi, gợi ý luyện và tổng hợp điểm yếu dựa trên bài làm/học liệu |
| Student | Chọn mục tiêu, xem phản hồi và tiếp tục luyện |

Đáp án khách quan đã duyệt là căn cứ xác định đúng/sai. AI không tự thay đổi đáp án chuẩn hoặc sửa trạng thái duyệt. Phản hồi cần liên kết với câu, revision và bài làm; khi thiếu căn cứ, phản hồi phải nêu giới hạn thay vì khẳng định kết luận.

Nếu dịch vụ AI lỗi, kết quả bài làm vẫn được lưu và student vẫn xem được đáp án/lời giải chuẩn. Có thể thử tạo feedback lại mà không nộp lại bài. Cần lưu phiên bản prompt/model phục vụ đánh giá chất lượng và kiểm soát chi phí.

### 4.4. Hướng mở rộng

- AI tạo nháp học liệu cho giáo viên duyệt trước khi sử dụng.
- Giáo viên giao mục tiêu và bài luyện cho lớp/student.
- Cá nhân hóa Speaking/Writing bằng rubric và phản hồi đã được đánh giá độ tin cậy.
- Hiệu chỉnh độ khó và thuật toán thích ứng khi có đủ dữ liệu thực tế.

## 5. Phạm vi và thứ tự triển khai đề xuất

| Ưu tiên | Phạm vi | Kết quả cần đạt |
|---|---|---|
| P1 | Bộ tiêu chí, metadata độ khó và quy trình duyệt | Có pool học liệu đủ điều kiện, truy vết được quyết định duyệt |
| P1 | Device policy và kiểm tra trước thi | Tổ chức cấu hình được điều kiện cảnh báo/chặn; student hiểu kết quả |
| P1 | Practice Reading theo aim, chẩn đoán và AI feedback | Demo được một luồng cá nhân hóa trọn vẹn với đáp án khách quan |
| P2 | Practice Listening và báo cáo tiến bộ | Mở rộng cùng luồng với kiểm tra audio và phản hồi phù hợp |
| P2 | Giáo viên giao mục tiêu/bài luyện | Quản lý tiến độ học tập của lớp/student |
| P3 | Speaking/Writing thích ứng, phân tích độ phân biệt và AI tạo nháp học liệu | Mở rộng sau khi rubric, dữ liệu và cách đánh giá AI đã đủ căn cứ |

Đây là thứ tự khuyến nghị, chưa phải quyết định bắt buộc chỉ hỗ trợ Reading. Trước khi lập plan cần chốt có cần Reading + Listening hoặc cả bốn kỹ năng trong lần triển khai đầu.

## 6. Tiêu chí nghiệm thu đề xuất

- [ ] Cả ba feedback đều có luồng UI và bằng chứng kiểm chứng tương ứng.
- [ ] 100% revision được thêm mới vào pool theo cơ chế này có metadata bắt buộc và xác nhận duyệt. Học liệu cũ có lộ trình rà soát riêng, không tự nhận là đã đạt chuẩn.
- [ ] Câu thiếu đáp án/reference/rubric bắt buộc, media cần thiết hoặc xác nhận duyệt bị chặn đưa vào pool.
- [ ] Ít nhất một câu mỗi mức Easy/Medium/Hard có lý do đánh giá và người duyệt trong bộ dữ liệu demo.
- [ ] Demo được một điều kiện thiết bị cảnh báo, một điều kiện chặn bắt đầu và một lượt kiểm tra lại thành công.
- [ ] Policy yêu cầu chống gian lận được áp dụng từ device check, trước khi hiển thị câu đầu.
- [ ] Student đặt được aim và hoàn thành một buổi luyện 10 câu Reading từ pool đã duyệt.
- [ ] Với cùng pool và dữ liệu test cố định, hai hồ sơ năng lực khác nhau nhận cấu hình buổi luyện khác nhau theo quy tắc đã xác định.
- [ ] Sau buổi luyện, student xem được kết quả, lỗi theo task type, feedback AI có căn cứ và đề xuất buổi tiếp theo.
- [ ] Khi AI không khả dụng, bài làm/kết quả vẫn được lưu và lời giải chuẩn vẫn truy cập được.
- [ ] Không hiển thị điểm luyện tập nội bộ như điểm PTE chính thức khi chưa có phương pháp quy đổi được kiểm chứng.

## 7. Kịch bản demo để trả lời giáo viên

1. Giáo viên mở một câu nháp, chọn độ khó và điền lý do.
2. Cho thấy câu thiếu một tiêu chí bắt buộc bị chặn duyệt; hoàn thiện rồi duyệt thành công.
3. Host cấu hình kỳ thi/policy và giải thích các điều kiện cảnh báo/chặn.
4. Student mở app, xem một điều kiện không đạt, khắc phục và kiểm tra lại.
5. Student chọn mục tiêu Reading, hoàn thành chẩn đoán và nhận buổi luyện.
6. Student làm bài và xem feedback AI đối chiếu với đáp án/lời giải chuẩn.
7. Hiển thị điểm yếu và lý do hệ thống đề xuất buổi luyện tiếp theo.

Demo phải dùng dữ liệu được gắn nhãn là dữ liệu minh họa. Kết quả demo chứng minh luồng hoạt động; đánh giá hiệu quả học tập, độ chuẩn xác AI và khả năng phân loại cần thêm dữ liệu/đánh giá riêng.

## 8. Các quyết định cần chốt khi lập spec/plan triển khai

1. Phạm vi kỹ năng của MVP và rubric đánh giá độ khó theo task type; chưa chốt quy đổi level với aim điểm.
2. Role/permission kiểm duyệt học liệu, quyền của tổ chức và cách xử lý học liệu cũ.
3. Nhà cung cấp AI, ngân sách/giới hạn sử dụng và cách đánh giá feedback bằng bộ bài mẫu do giáo viên xác nhận.

Khi lập plan cần khảo sát code hiện tại để tận dụng question revision, template, practice, device check và audit đã có. Tài liệu này mô tả hành vi mong muốn; chưa xác nhận các đề xuất đã được triển khai hoặc kiểm thử trong repository.
