# Đặc tả yêu cầu phần mềm: PTE Org

**Slug:** `pte-org-srs`  
**Ngày:** 2026-09-27  
**Trạng thái:** Bản đặc tả cơ sở, được viết từ bản brainstorm đã chốt  
**Ngôn ngữ:** Tiếng Việt nghiệp vụ; tên vai trò được giữ bằng tiếng Anh để khớp với sản phẩm

Tài liệu này mô tả PTE Org bằng ngôn ngữ dành cho người phụ trách nghiệp vụ, quản lý tổ chức, giáo viên, giám thị, người chấm và người vận hành. Các tên công nghệ chỉ được dùng trong phần ràng buộc kỹ thuật hoặc phụ lục khi cần.

## 1. Tổng quan sản phẩm

### 1.1. Tên hệ thống

**PTE Org** là nền tảng quản lý tổ chức và thi thử PTE. Nền tảng phục vụ các tổ chức đào tạo, trung tâm và đơn vị tổ chức kỳ thi. Tổ chức mua quyền sử dụng theo gói; học viên sử dụng tài khoản do tổ chức tạo.

### 1.2. Vấn đề cần giải quyết

Một tổ chức cần quản lý nhiều việc liên quan đến học viên và kỳ thi:

- tạo tài khoản và danh sách học viên;
- tổ chức học viên theo chương trình và lớp;
- chuẩn bị kỳ thi, chọn nhóm học viên và giới hạn số lượng;
- theo dõi bài làm, giám sát kỳ thi và chấm các câu cần người chấm;
- công bố kết quả cho đúng học viên;
- theo dõi gói sử dụng, thanh toán và hạn mức;
- lưu lại lịch sử các hành động quan trọng.

Nếu các việc này nằm ở nhiều công cụ rời rạc, tổ chức dễ bị trùng học viên, dùng sai gói, công bố sai kết quả, mất bài khi mất mạng hoặc không biết ai đã thay đổi dữ liệu. PTE Org gom các việc trên vào một quy trình thống nhất.

### 1.3. Tóm tắt giải pháp

PTE Org có ba kênh sử dụng chính:

1. **Organization web portal:** Host quản lý tổ chức, học viên, kỳ thi, gói sử dụng, nhân sự thi và kết quả.
2. **Platform administration portal:** Platform Admin và Platform Author quản lý nội dung dùng chung, gói thương mại và các quy tắc của nền tảng.
3. **Windows exam client:** Student đăng nhập, làm bài, lưu bài trên thiết bị, gửi bài và xem kết quả được công bố.

Quy trình nghiệp vụ tổng quát:

```text
Tổ chức đăng ký
    → Platform Admin duyệt
    → Host kích hoạt gói sử dụng
    → Host tạo kỳ thi và chọn học viên
    → Hệ thống kiểm tra điều kiện và chuẩn bị đề
    → Student làm bài
    → Hệ thống/Examiner chấm điểm
    → Host duyệt và công bố kết quả
    → Student xem báo cáo
```

### 1.4. Mục tiêu và chỉ số thành công

PTE Org được xem là đáp ứng mục tiêu khi:

1. Một tổ chức được duyệt có thể đi từ việc tạo học viên đến việc tạo, mở và đóng một kỳ thi mà không cần nhập lại cùng một dữ liệu ở nhiều nơi.
2. Host chỉ nhìn thấy dữ liệu của tổ chức mình; Student chỉ nhìn thấy bài làm và báo cáo của chính mình.
3. Nội dung câu hỏi, đề thi và quy tắc tính điểm đã công bố không thay đổi giữa chừng.
4. Bài làm được lưu trên thiết bị trước khi gửi đi, để việc mất mạng không làm mất câu trả lời.
5. Kết quả chỉ được hiển thị sau khi Host hoàn thành bước duyệt và công bố.
6. Nền tảng hướng tới tối thiểu 1.000 lượt thi đang diễn ra và 100 câu trả lời được gửi trong một giây vào thời điểm cao điểm.
7. Ít nhất 95% yêu cầu thông thường nhận được phản hồi trong 0,5 giây và mức hoạt động mục tiêu đạt 99,9% mỗi tháng.

### 1.5. Từ ngữ chính

| Từ dùng trong tài liệu | Cách hiểu đơn giản |
|---|---|
| Organization | Tổ chức sử dụng PTE Org, ví dụ trung tâm hoặc trường học |
| Host | Người quản trị của một tổ chức |
| Exam / exam sitting | Một kỳ thi có thời gian, danh sách Student và nội dung riêng |
| Student attempt | Một lượt Student làm một kỳ thi |
| Student list | Danh sách Student được chọn hoặc được gán vào kỳ thi |
| Pre-exam validation | Kiểm tra điều kiện trước khi công bố hoặc mở kỳ thi |
| Fixed exam version | Bản nội dung và quy tắc đã khóa để mọi người thi theo cùng điều kiện |
| Score Template | Mẫu quy định số câu, thời gian, trọng số và cách tính điểm |
| Subscription / license | Quyền sử dụng một gói trong thời gian và giới hạn đã mua |
| Publish | Công bố để người có quyền nhìn thấy hoặc sử dụng |
| Audit log | Lịch sử ghi lại ai đã làm gì, khi nào và trên dữ liệu nào |
| SHARED_FORM | Một bộ đề dùng chung cho các Student trong kỳ thi |
| UNIQUE_FORM_PER_STUDENT | Mỗi Student được gán một bộ đề riêng |
| Retry | Thử gửi hoặc xử lý lại sau khi lần trước thất bại |

## 2. Actors và phạm vi sử dụng

### 2.1. Platform Admin

**Vai trò:** Người quản trị toàn bộ nền tảng.

**Mức độ thành thạo:** Cơ bản đến trung cấp về công cụ quản trị; không cần biết lập trình để thực hiện nghiệp vụ.

**Kiến thức nghiệp vụ:** Cao về quản lý tổ chức, nội dung PTE, gói sử dụng, kiểm duyệt và vận hành nền tảng.

**Tần suất và kênh:** Sử dụng thường xuyên qua cổng quản trị trên web.

**Nhu cầu hỗ trợ:** Giao diện tiếng Việt/tiếng Anh, dùng được bằng bàn phím, màu sắc dễ đọc, thông báo xác nhận cho thao tác có ảnh hưởng lớn.

**Phạm vi dữ liệu:** Đọc và thay đổi dữ liệu toàn nền tảng; duyệt nội dung, gói sử dụng, tổ chức và báo cáo audit.

### 2.2. Platform Author

**Vai trò:** Người soạn câu hỏi và quy tắc chấm điểm dùng chung.

**Mức độ thành thạo:** Cơ bản đến trung cấp về công cụ soạn nội dung.

**Kiến thức nghiệp vụ:** Cao về PTE, loại câu hỏi, tiêu chí chấm và cách trình bày nội dung.

**Tần suất và kênh:** Sử dụng thường xuyên qua cổng quản trị web.

**Nhu cầu hỗ trợ:** Biểu mẫu rõ ràng, xem trước nội dung, cảnh báo thiếu âm thanh/hình ảnh và hỗ trợ bàn phím.

**Phạm vi dữ liệu:** Đọc và thay đổi bản nháp câu hỏi, bản nháp quy tắc chấm; gửi nội dung để Platform Admin duyệt. Không được tự kích hoạt nội dung dùng trong kỳ thi thật.

### 2.3. Host

**Vai trò:** Người quản trị của một tổ chức sử dụng nền tảng.

**Mức độ thành thạo:** Cơ bản về công cụ web; không yêu cầu kiến thức kỹ thuật.

**Kiến thức nghiệp vụ:** Cao về học viên, lớp học, lịch thi, gói sử dụng và quản lý kết quả.

**Tần suất và kênh:** Sử dụng hằng ngày hoặc theo từng đợt tổ chức thi qua organization web portal.

**Nhu cầu hỗ trợ:** Giao diện responsive, thao tác bằng bàn phím, lọc và tìm kiếm dễ hiểu, giải thích rõ lỗi về gói và danh sách học viên.

**Phạm vi dữ liệu:** Đọc và thay đổi dữ liệu của tổ chức mình; không được đọc dữ liệu tổ chức khác, không sửa trực tiếp ngân hàng câu hỏi dùng chung.

### 2.4. Proctor

**Vai trò:** Giám thị giám sát một kỳ thi được phân công.

**Mức độ thành thạo:** Cơ bản về công cụ giám sát.

**Kiến thức nghiệp vụ:** Trung cấp đến cao về quy trình thi, xử lý vi phạm và hỗ trợ thí sinh.

**Tần suất và kênh:** Sử dụng tập trung trong thời gian một kỳ thi qua màn hình giám sát được cấp quyền.

**Nhu cầu hỗ trợ:** Trạng thái học viên dễ nhìn, cảnh báo rõ ràng, màu sắc không phải là tín hiệu duy nhất, dùng được bằng bàn phím.

**Phạm vi dữ liệu:** Đọc trạng thái và ghi hành động trong các kỳ thi được phân công; không quản lý gói, nội dung dùng chung hoặc kết quả toàn tổ chức.

### 2.5. Examiner

**Vai trò:** Người chấm các câu trả lời được giao, đặc biệt là các câu cần đánh giá Speaking hoặc Writing.

**Mức độ thành thạo:** Cơ bản về công cụ chấm; có thể cần đào tạo nghiệp vụ chấm.

**Kiến thức nghiệp vụ:** Cao về tiêu chí PTE và hướng dẫn chấm được tổ chức áp dụng.

**Tần suất và kênh:** Sử dụng theo hàng đợi bài được giao qua web.

**Nhu cầu hỗ trợ:** Hiển thị đề, câu trả lời, hướng dẫn chấm và trạng thái đã gửi; hỗ trợ bàn phím và tránh che khuất nội dung cần đọc/nghe.

**Phạm vi dữ liệu:** Đọc bài được giao và ghi điểm của bài đó; không được tự công bố báo cáo.

### 2.6. Student

**Vai trò:** Học viên làm bài thi.

**Mức độ thành thạo:** Không yêu cầu kiến thức kỹ thuật; chỉ cần biết sử dụng máy tính ở mức cơ bản.

**Kiến thức nghiệp vụ:** Biết quy trình và yêu cầu của bài thi PTE ở mức phù hợp với kỳ thi được giao.

**Tần suất và kênh:** Sử dụng theo từng lượt thi qua Windows exam client.

**Nhu cầu hỗ trợ:** Chữ dễ đọc, tương phản tốt, điều khiển bằng bàn phím, hướng dẫn kiểm tra âm thanh/microphone, cảnh báo mất mạng và trạng thái lưu bài rõ ràng.

**Phạm vi dữ liệu:** Đọc và ghi bài làm của chính mình; chỉ xem báo cáo của chính mình sau khi Host công bố.

### 2.7. External Integration Services

**Vai trò:** Các dịch vụ bên ngoài trao đổi thông tin với PTE Org.

**Thành phần ban đầu:** PayOS, Cloudinary, dịch vụ chấm điểm AI, dịch vụ email/thông báo và các dịch vụ được phê duyệt sau này.

**Tần suất và kênh:** Gọi dữ liệu qua kết nối dịch vụ hoặc gửi thông báo xác nhận; không dùng giao diện người dùng của PTE Org.

**Phạm vi dữ liệu:** Chỉ nhận dữ liệu cần thiết cho một tác vụ. Không có quyền quản trị người dùng, tổ chức hoặc báo cáo.

## 3. Features trong phạm vi

Mỗi feature bên dưới có ba lớp mô tả:

- **Mô tả theo brainstorm:** nội dung đã được chốt trong vòng brainstorm.
- **Chi tiết cần có:** các khả năng cụ thể mà hệ thống phải hỗ trợ.
- **Actor và mức ưu tiên:** ai sử dụng và feature quan trọng đến mức nào.

### 3.1. Feature 1 — Tài khoản và đăng ký tổ chức

**Mô tả theo brainstorm:**

> Public organization registration; Platform Admin review, approval and rejection; creation of an organization and its first Host account after approval; login, logout, token renewal, password change and administrator-assisted password reset.

**Chi tiết cần có:**

1. Người đại diện tổ chức có thể gửi thông tin đăng ký từ trang công khai.
2. Platform Admin có thể xem, duyệt hoặc từ chối đăng ký và ghi lý do khi từ chối.
3. Chỉ đăng ký được duyệt mới tạo ra tổ chức đang hoạt động và tài khoản Host đầu tiên.
4. Đăng ký đang chờ hoặc bị từ chối không được truy cập workspace đang hoạt động.
5. Người dùng có thể đăng nhập, đăng xuất, đổi mật khẩu và gia hạn phiên đăng nhập.
6. Host có thể yêu cầu Platform Admin hỗ trợ đặt lại mật khẩu theo quy trình được kiểm soát.
7. Tài khoản bị khóa hoặc tổ chức bị tạm ngưng không thể thực hiện thao tác nghiệp vụ.
8. Thông tin logo, màu chính và thông tin nhận diện của tổ chức được dùng trong giao diện tổ chức.

**Actor:** Platform Admin, Host.

**Mức ưu tiên:** Essential.

### 3.2. Feature 2 — Tổ chức, học viên và đăng ký tham dự

**Mô tả theo brainstorm:**

> Organization, program and class management; student creation, bulk import, roster search, filtering and pagination; student membership and transfer operations; exam enrollment by student, class or program; student capacity checks and conflict-aware enrollment.

**Chi tiết cần có:**

1. Host tạo và quản lý chương trình, lớp và trạng thái hoạt động của chúng.
2. Host tạo từng học viên hoặc nhập danh sách nhiều học viên.
3. Hệ thống kiểm tra dữ liệu trùng, dữ liệu thiếu và số lượng học viên trước khi ghi.
4. Host tìm kiếm, lọc, sắp xếp và phân trang danh sách học viên.
5. Học viên được gắn vào một lớp tại một thời điểm theo quy tắc hiện hành; việc chuyển lớp phải được ghi nhận.
6. Lớp có thể được hợp nhất hoặc tách theo quy trình có xác nhận.
7. Host thêm học viên vào kỳ thi bằng cách chọn từng người, một lớp hoặc một chương trình.
8. Hệ thống loại trùng trong danh sách và trả lý do cho học viên đã có, vượt hạn mức hoặc bị xung đột lịch.

**Actor:** Host, Student.

**Mức ưu tiên:** Essential.

### 3.3. Feature 3 — Ngân hàng câu hỏi và nội dung media

**Mô tả theo brainstorm:**

> Platform question creation, editing, revision, approval, publication, archive and recovery; PTE task-type catalog; image and audio media upload; publication checks that prevent incomplete media; shared question content is platform-owned.

**Chi tiết cần có:**

1. Platform Author tạo bản nháp câu hỏi theo loại task PTE.
2. Người soạn có thể sửa bản nháp, xem trước và gửi duyệt.
3. Platform Admin duyệt, từ chối, publish, archive hoặc khôi phục câu hỏi.
4. Sửa một câu hỏi đã publish phải tạo revision mới; bản đã dùng trong kỳ thi không bị thay đổi.
5. Hệ thống quản lý các loại task, khả năng hiển thị, dữ liệu trả lời và yêu cầu chấm.
6. Nội dung audio/image được tải lên thông qua dịch vụ media đã được xác thực.
7. Câu hỏi không được publish nếu media bắt buộc chưa hoàn tất.
8. Host có thể chọn nội dung qua template nhưng không được sửa hoặc publish câu hỏi dùng chung.

**Actor:** Platform Admin, Platform Author, Host, Student, External Integration Services.

**Mức ưu tiên:** Essential.

### 3.4. Feature 4 — Mẫu tính điểm và quy tắc task

**Mô tả theo brainstorm:**

> Scoring templates with skill weights, task counts, timing and AI eligibility; template draft, approval, activation and retirement lifecycle; versioned task behavior and delivery information.

**Chi tiết cần có:**

1. Platform Author tạo bản nháp mẫu tính điểm gồm kỹ năng, loại task, số câu, thời gian và khả năng dùng AI.
2. Platform Admin kiểm tra tính hợp lệ, duyệt và kích hoạt mẫu.
3. Mẫu hết hiệu lực không được dùng cho kỳ thi mới nhưng không làm thay đổi kỳ thi đã công bố.
4. Host chỉ chọn mẫu đang hoạt động, không thay đổi trọng số hoặc quy tắc chung.
5. Kỳ thi giữ lại phiên bản mẫu tính điểm đã chọn tại thời điểm khóa đề.
6. Hệ thống chỉ hiển thị điểm Overall khi kỳ thi có đủ điều kiện; kỳ thi theo một hoặc một số kỹ năng chỉ hiển thị điểm phù hợp.

**Actor:** Platform Admin, Platform Author, Host, Student.

**Mức ưu tiên:** Essential.

### 3.5. Feature 5 — Gói sử dụng, thanh toán và hạn mức

**Mô tả theo brainstorm:**

> Plan catalog for exam packages and student-capacity additions; PayOS order and payment callback handling; license-code issue, redeem and revoke; subscriptions, license keys and expiration windows; organization-wide and per-exam student limits.

**Chi tiết cần có:**

1. Platform Admin tạo, sửa, kích hoạt hoặc lưu trữ các gói.
2. Gói thi có thời hạn và số học viên tối đa cho một kỳ thi.
3. Gói tăng sức chứa học viên cộng vào hạn mức tổ chức theo quy tắc riêng.
4. Host tạo đơn thanh toán và xem trạng thái đơn.
5. PayOS gửi xác nhận thanh toán; hệ thống không coi việc quay lại từ trình duyệt là bằng chứng thanh toán.
6. Platform Admin phát hành license code; Host nhập mã để kích hoạt gói.
7. Mỗi lần kích hoạt tạo một subscription có mã license, thời gian và giới hạn riêng.
8. Gói hết hạn hoặc bị thu hồi không được dùng để tạo kỳ thi mới.
9. Host xem được gói, thời hạn, số chỗ và trạng thái sử dụng của tổ chức.

**Actor:** Platform Admin, Host, External Integration Services.

**Mức ưu tiên:** Essential.

### 3.6. Feature 6 — Tạo, kiểm tra và lên lịch kỳ thi

**Mô tả theo brainstorm:**

> Exam draft creation and editing; template, package, policy, date and capacity selection; student-list preview and duplicate removal; pre-exam validation; exam generation, publication, opening, closing and cancellation.

**Chi tiết cần có:**

1. Host tạo kỳ thi ở trạng thái bản nháp.
2. Host chọn mẫu tính điểm, gói sử dụng, thời gian, sức chứa, chế độ Practice/Mock/Official và chính sách thi.
3. Host thêm danh sách học viên từ student, class hoặc program.
4. Hệ thống hiển thị số lượng hợp lệ, trùng, bị loại, vượt sức chứa và xung đột lịch.
5. Kiểm tra trước khi mở phải phát hiện thiếu câu, gói không hợp lệ, kỳ thi nằm ngoài thời hạn gói, vượt sức chứa và xung đột.
6. Hệ thống tạo nội dung kỳ thi và cung cấp trạng thái tạo cho Host.
7. Host chỉ publish khi mọi điều kiện bắt buộc đạt.
8. Sau publication lock, danh sách học viên, nội dung và quy tắc ảnh hưởng đến việc thi không được tự ý thay đổi.
9. Host có thể mở, đóng hoặc hủy kỳ thi theo trạng thái cho phép.
10. Kỳ thi dùng cùng một license không được trùng thời gian; hai license khác nhau có thể chạy đồng thời.

**Actor:** Host, Platform Admin (hỗ trợ mẫu/gói), Student (nhận kỳ thi), Proctor, Examiner.

**Mức ưu tiên:** Essential.

### 3.7. Feature 7 — Làm bài và gửi bài

**Mô tả theo brainstorm:**

> Student login and eligible-exam entry; Windows-first exam client; 23 PTE task types; per-task preparation and response timing; local-first answer saving; retry after connectivity loss; text, audio and image delivery; normal and protected answer submission; heartbeat and recovery.

**Chi tiết cần có:**

1. Student chỉ bắt đầu được kỳ thi đã được gán, đang mở và còn đủ điều kiện.
2. Ứng dụng hiển thị đúng loại task, nội dung, audio/image, thời gian chuẩn bị và thời gian trả lời.
3. Ứng dụng hỗ trợ 22 loại task có điểm và Personal Introduction không tính điểm theo nội dung PTE đã chốt.
4. Mỗi câu trả lời được lưu trên thiết bị trước khi gửi.
5. Khi mất mạng, câu trả lời chuyển sang trạng thái chờ và được gửi lại khi kết nối phục hồi.
6. Ứng dụng gửi tín hiệu đang hoạt động trong thời gian lượt thi còn mở.
7. Hệ thống kiểm tra người gửi, kỳ thi, câu hỏi và trạng thái bài trước khi nhận câu trả lời.
8. Các kỳ thi có yêu cầu bảo vệ cao có thể dùng đường gửi bài được mã hóa và phát hiện sửa đổi.
9. Student có thể gửi toàn bộ bài hoặc bị gửi tự động theo chính sách kỳ thi.
10. Sau khi gửi cuối, Student không thể tạo bài thứ hai trong cùng kỳ thi nếu chưa có quy tắc retake được cho phép.

**Actor:** Student, Proctor (hỗ trợ), External Integration Services (media/AI khi có).

**Mức ưu tiên:** Essential.

### 3.8. Feature 8 — Giám sát kỳ thi và bảo vệ tính trung thực

**Mô tả theo brainstorm:**

> Proctor assignment; student and attempt status monitoring; violation recording; unrestricted Practice, controlled Practice and strict Official delivery; Windows fullscreen, shortcut and clipboard controls where required.

**Chi tiết cần có:**

1. Host gán Proctor vào kỳ thi.
2. Proctor xem trạng thái học viên được phân công và ghi nhận sự việc.
3. Hệ thống ghi violation cùng thời gian, mức độ và kỳ thi liên quan.
4. Practice không khóa máy nếu chính sách là unrestricted.
5. Practice controlled có thể yêu cầu fullscreen, hạn chế shortcut/clipboard và hiển thị cảnh báo khi có violation.
6. Official dùng chính sách nghiêm ngặt hơn theo cấu hình của kỳ thi.
7. Chính sách được cố định vào lượt thi; thay đổi sau khi Student bắt đầu không làm thay đổi lượt đang chạy.
8. Ở phiên bản đầu, violation Practice được cảnh báo và ghi audit, không tự động hủy bài.
9. Các tính năng phát hiện máy ảo, quay màn hình hoặc chặn mọi thiết bị phụ không thuộc phiên bản này.

**Actor:** Host, Proctor, Student.

**Mức ưu tiên:** Conditional — bắt buộc cho Official và các Practice có bật kiểm soát; có thể tắt cho Practice tự luyện.

### 3.9. Feature 9 — Chấm bài và duyệt nguồn điểm

**Mô tả theo brainstorm:**

> Examiner assignment by exam and student-attempt pool; examiner work queue and answer scoring; Host review of automated and examiner scores; score-source selection; blocking report publication until required scores are complete.

**Chi tiết cần có:**

1. Host lọc nhóm bài theo kỳ thi, program hoặc class rồi gán cho một hoặc nhiều Examiner.
2. Một bài của Student chỉ thuộc về một Examiner trong một lần phân công.
3. Examiner xem hàng đợi và gửi điểm cho câu được giao.
4. Hệ thống lưu riêng điểm tự động và điểm Examiner khi cả hai cùng tồn tại.
5. Host xem hai nguồn điểm và chọn nguồn dùng cho từng task, section hoặc nhóm câu.
6. Lựa chọn ở phạm vi hẹp hơn ghi đè lựa chọn ở phạm vi rộng hơn.
7. Không cho publish nếu câu bắt buộc chưa có nguồn điểm hợp lệ hoặc điểm còn thiếu.
8. Điểm từ dịch vụ thử nghiệm hoặc placeholder phải được đánh dấu rõ và không được coi là điểm AI hợp lệ để publish nếu chính sách không cho phép.

**Actor:** Host, Examiner, External Integration Services.

**Mức ưu tiên:** Conditional — bắt buộc cho các task cần người chấm hoặc khi Host chọn Examiner làm nguồn điểm.

### 3.10. Feature 10 — Báo cáo, công bố và lịch sử thao tác

**Mô tả theo brainstorm:**

> Objective, automated and examiner score aggregation; PTE 10–90 results; Host-controlled report publication; Student result viewing; organization audit log; supported notifications.

**Chi tiết cần có:**

1. Hệ thống tổng hợp điểm câu, kỹ năng và Overall theo mẫu tính điểm đã khóa.
2. Kỳ thi chỉ một số kỹ năng hiển thị điểm của những kỹ năng đó; Overall chỉ hiển thị khi đủ điều kiện.
3. Host xem trạng thái sẵn sàng của báo cáo trước khi publish.
4. Host publish theo kỳ thi hoặc theo quy trình được cấp quyền.
5. Student chỉ xem báo cáo sau publication và không xem được báo cáo của người khác.
6. Báo cáo lưu dấu vết tới kỳ thi, revision câu hỏi, mẫu tính điểm và nguồn điểm.
7. Audit log ghi các thay đổi về quyền, thanh toán, enrollment, chính sách thi, duyệt điểm và publication.
8. Notification chỉ gửi các loại sự kiện đã được hỗ trợ; lỗi gửi notification không được làm mất nghiệp vụ chính.

**Actor:** Host, Student, Platform Admin, Proctor, Examiner, External Integration Services.

**Mức ưu tiên:** Essential.

### 3.11. Feature 11 — Kết nối dịch vụ bên ngoài

**Mô tả theo brainstorm:**

> PayOS payment order and callback; Cloudinary media upload and preview; AI scoring provider abstraction; email/notification delivery; controlled retry and duplicate-callback handling.

**Chi tiết cần có:**

1. Mỗi kết nối có phạm vi dữ liệu rõ ràng và thông tin xác thực riêng.
2. Callback thanh toán được kiểm tra chữ ký và có thể xử lý lặp mà không tạo thêm subscription.
3. Upload media dùng thông tin ký có thời hạn; link hết hạn phải được cấp lại.
4. AI scoring có trạng thái chờ, thành công, thất bại và retry.
5. Email/notification có trạng thái gửi lỗi nhưng không rollback payment, exam hoặc score.
6. Người dùng nhìn thấy trạng thái dễ hiểu khi dịch vụ bên ngoài tạm thời không hoạt động.

**Actor:** Platform Admin, Host, Student, External Integration Services.

**Mức ưu tiên:** Essential cho PayOS, media và notification đang sử dụng; Conditional cho AI scoring thật khi provider chưa được chọn.

### 3.12. Feature 12 — Tạo đề có thể kiểm tra và mở rộng nền tảng

**Mô tả theo brainstorm:**

> Deterministic generation inputs, saved generation seed, algorithm version, form mode, form assignment, idempotent generation requests, generation-status record, shared-form and one-form-per-student modes, exam-series reuse rules and schedule-conflict checks.

**Chi tiết cần có:**

1. Hệ thống lưu thông tin đủ để giải thích vì sao một đề được tạo ra.
2. Yêu cầu tạo đề lặp lại cùng mã yêu cầu không tạo ra bộ form thứ hai.
3. Practice mặc định có thể dùng một form chung; Mock/Official mặc định có thể dùng một form riêng cho từng Student theo chính sách đã chốt.
4. Một form không được lặp cùng câu hỏi trong chính form đó.
5. Quy tắc loại học viên đã thi, đã được gán hoặc bị trùng lịch được áp dụng trước publication.
6. Hệ thống hiển thị tiến độ và lỗi của việc tạo đề.
7. Audience lớn có thể chuyển sang xử lý nền mà không làm mất bản nháp.
8. Về lâu dài, nền tảng bổ sung lớp bảo vệ dữ liệu ở tầng cơ sở dữ liệu, backup/recovery và khả năng phục vụ nhiều bản ứng dụng hơn.

**Actor:** Host, Platform Admin, Student, External Integration Services.

**Mức ưu tiên:** Conditional — các quy tắc hiện có cần thiết cho kỳ thi; mở rộng xử lý nền, quan sát hệ thống và bảo vệ dữ liệu là future hardening.

## 4. OUT of Scope

| Feature | Lý do loại khỏi phạm vi hiện tại | Phiên bản dự kiến |
|---|---|---|
| Student tự thanh toán hoặc mua gói cá nhân | Mô hình kinh doanh chỉ bán cho tổ chức; Student sử dụng gói do Host kích hoạt | Không thuộc dòng sản phẩm hiện tại |
| Danh tính Student dùng chung giữa nhiều tổ chức | Có thể tạo rủi ro trộn dữ liệu và chưa cần cho mô hình tenant hiện tại | Future version nếu có nhu cầu liên tổ chức |
| Host sở hữu question bank riêng và tự publish câu hỏi | Nội dung câu hỏi dùng chung cần được Platform Admin kiểm duyệt | Chưa lên lịch |
| Một định nghĩa exam dùng cho nhiều lần thi | Phiên bản đầu tập trung vào một exam sitting độc lập | Sau khi mô hình một kỳ thi ổn định |
| Adaptive testing và IRT | Cần nghiên cứu dữ liệu, mô hình chọn câu và kiểm định riêng | Research/future |
| Official certification | Nền tảng mô phỏng và luyện thi, không phát chứng chỉ có giá trị chính thức | Chưa xác định |
| Quy tắc không lặp câu vĩnh viễn trên mọi kỳ thi | Là bài toán kho câu hỏi và chính sách thương mại lớn hơn phạm vi hiện tại | Future nếu cần |
| Thi trên mobile hoặc thiết kế lại mobile | Windows desktop là kênh đầu tiên cho exam delivery | Future version |
| Thay Cloudinary hoặc thêm media provider mới | Chưa có nhu cầu nghiệp vụ và sẽ tạo thêm chi phí vận hành | Future nếu có yêu cầu |
| Tách Lecturer, Program Coordinator, Applicant hoặc Tenant Owner thành role riêng | Người dùng đã chốt actor model chỉ gồm sáu role người dùng | Chỉ xem xét khi actor model được phê duyệt lại |
| Phát hiện máy ảo, quay màn hình, chặn mọi thiết bị phụ và tự hủy mọi Practice violation | Cần native control, chính sách pháp lý và luồng xử lý riêng | Future hardening |

## 5. Ràng buộc kỹ thuật

### 5.1. Công nghệ hiện có

1. Hệ thống có một backend được chia thành các khu vực nghiệp vụ rõ ràng, thay vì nhiều backend độc lập.
2. Backend hiện dùng Java 21 và Spring Boot. PostgreSQL lưu dữ liệu nghiệp vụ; Redis giữ dữ liệu dùng tạm thời; RabbitMQ xử lý công việc chạy nền.
3. Organization web portal và platform administration portal dùng Next.js/React.
4. Exam client dùng Flutter, ưu tiên Windows.
5. Nginx là cửa vào công khai; các chức năng trao đổi dữ liệu dùng đường dẫn phiên bản `/api/v1`.

### 5.2. Triển khai

1. Stack hiện chạy bằng Docker trên một Oracle VPS.
2. Bản SRS không yêu cầu Kubernetes hoặc một nền tảng triển khai mới.
3. Có thể mở rộng thêm bản chạy backend và xử lý hàng đợi về sau, nhưng nghiệp vụ không được phụ thuộc vào một máy cụ thể.
4. Thời gian lưu trong hệ thống dùng UTC; giao diện hiển thị theo múi giờ của người dùng.
5. Mật khẩu, khóa riêng, token và giá trị môi trường không được ghi vào tài liệu hoặc mã nguồn.

### 5.3. Kết nối hiện có

| Hệ thống | Hướng trao đổi | Mục đích | Yêu cầu chính |
|---|---|---|---|
| PayOS | PTE Org gửi đơn; PayOS gửi callback xác nhận | Thanh toán gói | Kiểm tra chữ ký, xử lý lặp an toàn |
| Cloudinary | Trình duyệt tải media theo thông tin ký; PTE Org nhận trạng thái | Lưu audio/image | Link có thời hạn, kiểm tra hoàn tất trước khi publish |
| AI scoring provider | PTE Org gửi bài đủ điều kiện; dịch vụ trả điểm/trạng thái | Chấm tự động | Có trạng thái chờ/lỗi/retry và lưu nguồn điểm |
| Email/notification delivery | PTE Org gửi nội dung và người nhận | Thông báo | Lỗi gửi không được rollback nghiệp vụ chính |
| Redis/RabbitMQ | Thành phần nội bộ của stack | Giữ trạng thái tạm thời và xử lý nền | Không được tạo quyền nghiệp vụ mới |

### 5.4. An toàn và phân quyền

1. Mọi thao tác được bảo vệ phải kiểm tra role và tổ chức hoặc kỳ thi được phân công.
2. Platform Admin có phạm vi toàn nền tảng; năm role còn lại chỉ làm việc trong phạm vi được giao.
3. Dữ liệu học viên, câu trả lời, điểm và báo cáo được xem là dữ liệu mật của tổ chức.
4. Kết nối mạng phải được bảo vệ; dữ liệu nhạy cảm không được ghi vào log thông thường.
5. Các thay đổi quan trọng phải có audit log đầy đủ.
6. Khi kỳ thi yêu cầu bảo vệ câu trả lời, dữ liệu phải được mã hóa và phát hiện sửa đổi trên đường từ exam client đến backend. Chi tiết thuật toán là việc của thiết kế kỹ thuật, không phải yêu cầu để BA phải đọc.
7. Cơ chế kiểm tra dữ liệu theo tổ chức đang nằm ở tầng ứng dụng; lớp bảo vệ bổ sung ở cơ sở dữ liệu là mục tiêu tương lai.

### 5.5. Khả năng sử dụng

1. Web portal phải hỗ trợ tiếng Việt và tiếng Anh.
2. Web portal phải hướng tới WCAG AA: tương phản đủ, dùng được bằng bàn phím, có focus rõ, có nhãn cho biểu mẫu và tôn trọng cài đặt giảm chuyển động.
3. Exam client phải cung cấp hướng dẫn kiểm tra âm thanh/microphone và trạng thái lưu bài dễ hiểu.

### 5.6. Quy định và dữ liệu

1. SRS này không đặt phạm vi chứng nhận HIPAA, PCI-DSS, SOC 2 hoặc chứng nhận ngân hàng.
2. Dữ liệu giáo dục và dữ liệu cá nhân phải được xử lý như dữ liệu mật.
3. Thanh toán được giao cho PayOS; PTE Org không lưu dữ liệu thẻ gốc.
4. Thời gian lưu, xóa, xuất và giữ dữ liệu theo yêu cầu pháp lý phải được ghi trong hợp đồng với từng tổ chức.

## 6. Business Rules

### Phân quyền và sở hữu dữ liệu

- **BR-001:** Một người dùng chỉ được mang một hoặc nhiều trong sáu role người dùng đã được phê duyệt: Platform Admin, Platform Author, Host, Proctor, Examiner hoặc Student. External Integration Services không phải role người dùng.
- **BR-002:** Chỉ Platform Admin được thay đổi dữ liệu quản trị toàn nền tảng.
- **BR-003:** Platform Author được tạo, sửa và gửi bản nháp để duyệt nhưng không được tự kích hoạt nội dung dùng trong production.
- **BR-004:** Host chỉ được đọc và thay đổi dữ liệu thuộc tổ chức mình.
- **BR-005:** Proctor và Examiner chỉ được làm việc với kỳ thi hoặc bài được phân công.
- **BR-006:** Student chỉ được đọc/ghi bài làm đang diễn ra của mình và xem báo cáo của mình sau publication.

### Đăng ký và tổ chức

- **BR-007:** Một tổ chức chỉ chuyển sang trạng thái hoạt động sau khi Platform Admin duyệt.
- **BR-008:** Tổ chức đang chờ hoặc bị từ chối không được coi là workspace đang hoạt động.
- **BR-009:** Một tài khoản Student chỉ thuộc một tổ chức trong mô hình hiện tại.
- **BR-010:** Tạo hoặc nhập Student phải kiểm tra hạn mức Student của tổ chức trước khi ghi dữ liệu.
- **BR-011:** Không được tạo class membership trùng mà không thông báo; chuyển hoặc xóa membership phải là thao tác rõ ràng và có audit.

### Nội dung và template

- **BR-012:** Câu hỏi chỉ được publish khi nội dung bắt buộc và media bắt buộc đã hoàn tất.
- **BR-013:** Sửa câu hỏi đã publish phải tạo revision mới; revision đã gắn vào kỳ thi không bị thay đổi.
- **BR-014:** Host chỉ được chọn Score Template đang active.
- **BR-015:** Host không được thay đổi trọng số, số câu hoặc quy tắc dùng chung của Score Template.
- **BR-016:** Sau publication lock, nội dung và quy tắc tính điểm dùng cho Student phải giữ nguyên.

### Billing và hạn mức

- **BR-017:** Student không phải là bên thanh toán hoặc người sở hữu package.
- **BR-018:** Mỗi lần mua EXAM_PACKAGE tạo một license độc lập; hai license khác nhau có thể chạy đồng thời.
- **BR-019:** Subscription chỉ dùng được khi đang active và thời gian kỳ thi nằm trong thời hạn của subscription.
- **BR-020:** Số Student trong một kỳ thi không được vượt `maxStudentsPerSession` của license.
- **BR-021:** Một license code chỉ được redeem một lần; callback thanh toán lặp không được tạo subscription thứ hai.
- **BR-022:** Thu hồi license code đã redeem phải làm mất quyền sử dụng subscription được tạo từ code đó theo chính sách đã công bố.

### Tạo và lên lịch kỳ thi

- **BR-023:** Host phải vượt qua pre-exam validation trước khi publish kỳ thi.
- **BR-024:** Danh sách Student phải được loại trùng trước khi kiểm tra sức chứa và xung đột.
- **BR-025:** Student bị trùng lịch, đã được gán hoặc đã bắt đầu kỳ thi trước đó phải được loại hoặc chặn theo Reuse Policy; hệ thống không được tự động ghi nhận mà không nêu lý do.
- **BR-026:** Hai kỳ thi dùng cùng license không được có khoảng thời gian giao nhau; hai license khác nhau có thể giao nhau.
- **BR-027:** Thay đổi membership của class/program sau publication không được tự sửa danh sách Student đã công bố.
- **BR-028:** Practice mặc định dùng SHARED_FORM; Mock Test và Official Exam mặc định dùng UNIQUE_FORM_PER_STUDENT, trừ khi một chính sách được phê duyệt cho phép cách khác.
- **BR-029:** Một form không được chứa cùng một câu hỏi nhiều lần.

### Làm bài và an toàn câu trả lời

- **BR-030:** Exam client phải lưu câu trả lời trên thiết bị trước khi gửi mạng.
- **BR-031:** Khi mất mạng, câu trả lời phải ở trạng thái có thể retry và không được bị bỏ im lặng.
- **BR-032:** Backend phải kiểm tra Student, kỳ thi, câu hỏi và trạng thái bài trước khi nhận câu trả lời.
- **BR-033:** Chính sách thi được cố định cho một lượt thi sau khi lượt đó bắt đầu.
- **BR-034:** Một bài đã submit không được tạo lượt thi thứ hai trong cùng kỳ thi nếu không có chính sách retake được cấp quyền.

### Proctor và Examiner

- **BR-035:** Mọi hành động quan trọng của Proctor phải gắn với kỳ thi được phân công và được ghi audit.
- **BR-036:** Điểm Examiner chỉ trở thành nguồn điểm cuối sau khi Host review.
- **BR-037:** Host chỉ được chọn nguồn điểm nếu nguồn đó có điểm hợp lệ cho câu hoặc nhóm câu được chọn.
- **BR-038:** Hệ thống không được publish báo cáo một phần khi câu bắt buộc còn thiếu điểm hoặc thiếu nguồn điểm.
- **BR-039:** Practice violation ở phiên bản đầu tạo cảnh báo và audit, không tự động pause, force-submit, invalidate hoặc terminate bài.

### Báo cáo và audit

- **BR-040:** Student chỉ xem được báo cáo sau khi Host publish và chỉ xem báo cáo của mình.
- **BR-041:** Báo cáo đã publish phải truy ra được exam version, question revision, Score Template và nguồn điểm được chọn.
- **BR-042:** Thay đổi về quyền, thanh toán, exam policy, enrollment, scoring approval và publication phải có audit log.
- **BR-043:** Bài làm, điểm và audit log được lưu theo thời hạn trong hợp đồng với tổ chức; quy trình xóa, xuất và legal hold phải được hợp đồng mô tả.

### Dịch vụ bên ngoài và lỗi

- **BR-044:** Payment callback được retry an toàn và không tạo activation trùng.
- **BR-045:** AI score lỗi phải có trạng thái dễ hiểu, có thể retry hoặc chuyển sang Examiner review.
- **BR-046:** Media link hết hạn phải được xin lại; không được coi đó là mất câu trả lời.
- **BR-047:** Email/notification lỗi không được rollback payment, exam, enrollment hoặc score đã thành công.
- **BR-048:** Khi dịch vụ bên ngoài không hoạt động, người dùng phải thấy trạng thái chờ hoặc lỗi có hướng xử lý.

## 7. NFR Baselines

| ID | Đặc tính | Mục tiêu | Trạng thái |
|---|---|---|---|
| NFR-01 | Tốc độ phản hồi | Ít nhất 95% yêu cầu thông thường phản hồi trong 0,5 giây | Confirmed |
| NFR-02 | Số lượt thi đồng thời | Ít nhất 1.000 active attempts trong thời điểm thi cao điểm | Confirmed |
| NFR-03 | Khả năng nhận câu trả lời | Ít nhất 100 câu trả lời/giây trong burst mà không mất dữ liệu | Confirmed |
| NFR-04 | Kiểm tra trước kỳ thi | Danh sách tối đa 500 Student trả kết quả kiểm tra trong 5 giây | Confirmed |
| NFR-05 | Mức hoạt động | 99,9% mỗi tháng trong production | Confirmed |
| NFR-06 | Mức mất dữ liệu | Tối đa 15 phút dữ liệu sau sự cố nghiêm trọng | Confirmed |
| NFR-07 | Thời gian khôi phục | Khôi phục dịch vụ trong tối đa 1 giờ sau sự cố nghiêm trọng | Confirmed |
| NFR-08 | Cách ly dữ liệu | Không có thao tác người dùng thông thường nào đọc được dữ liệu riêng của tổ chức khác | Confirmed |
| NFR-09 | Audit thao tác nhạy cảm | 100% thay đổi về quyền, thanh toán, publication, duyệt điểm và công bố báo cáo được ghi audit | Confirmed |
| NFR-10 | Bảo vệ đăng nhập | Không quá 5 lần đăng nhập thất bại trong 15 phút cho cùng account hoặc nguồn trước khi áp dụng bảo vệ tạm thời | Confirmed |
| NFR-11 | Dữ liệu mật | Student data, answer và report dùng kết nối được bảo vệ và không ghi vào log thường | Confirmed |
| NFR-12 | Khả năng tăng trưởng | Tăng 2–5 lần lượng người dùng ban đầu mà không đổi business rules | Confirmed |
| NFR-13 | Ngôn ngữ | Giao diện và thông báo hỗ trợ tiếng Việt và tiếng Anh | Confirmed |
| NFR-14 | Khả năng tiếp cận | Web portal hướng tới WCAG AA, dùng được bằng bàn phím và có focus rõ | Confirmed |
| NFR-15 | Lưu dữ liệu | Theo thời hạn trong hợp đồng của từng tổ chức; phải có quy trình xóa, xuất và legal hold | [TBD: Platform Admin và người phụ trách pháp lý; chốt trước khi ký hợp đồng] |
| NFR-16 | Phạm vi chứng nhận | Không đặt chứng nhận HIPAA, PCI-DSS, SOC 2 hoặc chứng nhận ngân hàng trong bản này | Confirmed |
| NFR-17 | Quốc gia và quy định riêng | Xác định quốc gia hoạt động và nghĩa vụ bảo vệ dữ liệu trước khi ký hợp đồng | [TBD: Platform Admin + người phụ trách pháp lý; chốt trước khi phát hành production] |

Các mục Confirmed là mục tiêu của bản SRS, không phải bằng chứng rằng môi trường một VPS hiện tại đã đạt đủ mọi chỉ tiêu. Việc chứng minh bằng tải, backup và vận hành thuộc kế hoạch triển khai sau.

## 8. Assumptions

1. **Host là người quản trị tổ chức.** Nếu tổ chức cần nhiều cấp quản lý hoặc Lecturer/Program Coordinator, actor model phải được phê duyệt lại trước khi mở rộng.
2. **Student do Host tạo hoặc nhập.** Nếu có self-registration, cần thêm quy trình xác minh và kiểm soát hạn mức.
3. **PTE Org phục vụ luyện thi và thi thử.** Nếu nền tảng phát chứng chỉ chính thức, cần thêm yêu cầu pháp lý, kiểm tra danh tính và quy trình chống gian lận nghiêm ngặt hơn.
4. **PayOS vẫn là kênh thanh toán ban đầu.** Nếu đổi nhà cung cấp, phải giữ nguyên nguyên tắc callback là bằng chứng thanh toán và activation idempotent.
5. **Cloudinary vẫn là nơi lưu media ban đầu.** Nếu thay nhà cung cấp, phải giữ được link có thời hạn, kiểm tra hoàn tất media và quyền truy cập.
6. **Windows là nền tảng exam đầu tiên.** Nếu cần macOS, Linux, Android hoặc iOS, phải bổ sung kiểm thử thiết bị, audio và lockdown.
7. **Mẫu tính điểm và loại task được quản lý tập trung.** Nếu Host được tự tạo scoring rule, cần thiết kế lại quyền, kiểm duyệt và ảnh hưởng giữa các kỳ thi.
8. **Hệ thống có thể xử lý bài theo cách không đồng bộ.** Nếu tất cả điểm phải có ngay lập tức, cần đặt lại mục tiêu thời gian và chi phí AI/Examiner.
9. **Các chỉ tiêu 1.000 lượt thi, 100 câu trả lời/giây, 99,9% và phục hồi 1 giờ là mục tiêu sản phẩm.** Nếu không có backup, máy chủ hoặc ngân sách phù hợp, các mục tiêu phải được hạ hoặc ghi rõ là mục tiêu tương lai.
10. **Thời gian lưu dữ liệu do hợp đồng quyết định.** Nếu hợp đồng không ghi thời hạn, Platform Admin không được tự suy đoán; phải yêu cầu bổ sung trước khi tạo tổ chức.
11. **Student có một tổ chức trong phiên bản này.** Nếu một người học cần học ở hai tổ chức, phải có thiết kế danh tính liên tổ chức và quy tắc hiển thị dữ liệu riêng.
12. **Exam client có thể lưu bài cục bộ trong thời gian mất mạng.** Nếu thiết bị bị hỏng trước khi đồng bộ, khả năng khôi phục phụ thuộc vào bản sao lưu của thiết bị và chính sách vận hành.

## 9. Open Items

| ID | Điều chưa biết | Người cần quyết định | Ảnh hưởng nếu chưa chốt |
|---|---|---|---|
| TBD-01 | Thời hạn lưu bài thi, điểm và audit log; quy trình xóa, xuất và legal hold | Platform Admin + người phụ trách pháp lý + đại diện tổ chức | Không thể hoàn tất chính sách dữ liệu, hợp đồng và NFR lưu trữ |
| TBD-02 | Nhà cung cấp AI cuối cùng, ngưỡng chất lượng điểm và điều kiện chuyển sang Examiner | Platform Admin + người phụ trách scoring + Tech Lead | Ảnh hưởng chi phí, thời gian trả điểm và điều kiện publish |
| TBD-03 | Cách gửi violation từ exam client đến audit của Host/Proctor | Tech Lead + Proctor representative | Không thể tuyên bố luồng cảnh báo và audit Practice đã hoàn chỉnh |
| TBD-04 | Phạm vi còn lại của xử lý audience lớn, recovery khi tạo đề lỗi và mức provenance Host được xem | Product Owner + Tech Lead | Ảnh hưởng thiết kế màn hình tạo đề, dung lượng xử lý và khả năng giải trình |
| TBD-05 | Các màn hình trước khi thi còn thiếu và cách Student nhận exam identifier | Product Owner + Host representative + Student representative | Ảnh hưởng việc Student tự tìm và bắt đầu kỳ thi trong sản phẩm thật |
| TBD-06 | Kế hoạch vận hành để đạt 99,9%, 1.000 active attempts và khôi phục trong 1 giờ | Tech Lead + Operations owner | Không thể nghiệm thu các chỉ tiêu availability, capacity và recovery |
| TBD-07 | Quốc gia áp dụng, yêu cầu bảo vệ dữ liệu và điều khoản xử lý dữ liệu của từng tổ chức | Platform Admin + người phụ trách pháp lý | Có thể phải thay đổi nơi lưu dữ liệu, thời hạn lưu và nội dung hợp đồng |

Các TBD trên không làm thay đổi actor model hoặc phạm vi feature đã chốt, nhưng phải được xử lý trước khi phát hành SRS cuối cùng và kế hoạch triển khai tương ứng.
