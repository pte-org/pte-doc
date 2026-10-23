# PTEPrep — Đối chiếu phạm vi hiện tại với phiếu đăng ký và Report 3–6

**Ngày đọc và đối chiếu:** 22/10/2026  
**Căn cứ đăng ký:** `template-doc/Generate/FA26SE182_Phieu-dang-ky_v1.2.docx`, đối chiếu bản gốc v1.0  
**Phạm vi khảo sát:** Phiếu đăng ký, phân quyền platform, các kênh web, module practice, các đầu mối tạo đề/chấm bài/công bố kết quả, cấu trúc lưu bài của Windows client và bộ Report 3–6 hiện có.  
**Giới hạn bằng chứng:** Đọc source và tài liệu trong workspace. Chưa chạy ứng dụng, kiểm thử nghiệp vụ, kiểm tra cấu hình bí mật hoặc xác nhận tính năng đang bật trên production. “Có triển khai trong source” không đồng nghĩa “đã nghiệm thu”.

## 1. Kết luận về sản phẩm và tên đề tài

Giữ nguyên tên đã đăng ký:

- **Tiếng Anh:** PTEPrep: An AI-Powered PTE Practice Platform and Realistic Exam Simulator
- **Tiếng Việt:** PTEPrep: Hệ thống luyện tập và mô phỏng thi thử PTE ứng dụng AI
- **Viết tắt:** PTEPrep

Phiếu v1.2 giữ đúng các tên trên. Không thêm chữ “management” hoặc “quản lý” vào tên đề tài khi cập nhật báo cáo.

Sản phẩm có hai hành trình học viên cần mô tả riêng: tự luyện tập trên web và tham gia kỳ thi được tổ chức giao trên Windows client. Các hoạt động quản trị platform, vận hành tổ chức, học liệu, thanh toán gói, chấm bài và công bố báo cáo hỗ trợ hai hành trình này.

PTEPrep mô phỏng dạng bài và nội dung theo định hướng PTE; không đại diện, chứng nhận, kết nối hay tuyên bố được PTE Academic/Pearson bảo trợ. Kết quả do PTEPrep tạo không phải kết quả thi chính thức. Dự án phát triển phần mềm và tích hợp AI; phiếu hiện tại không đặt mục tiêu nghiên cứu hay huấn luyện mô hình mới.

**Lưu ý trạng thái phê duyệt:** Dòng lịch sử thay đổi v1.2 ghi “pending supervisor confirmation”. Đây là bản đăng ký mới nhất tìm thấy trong workspace, chưa phải bằng chứng rằng giảng viên đã duyệt toàn bộ nội dung mới.

## 2. Các kênh sử dụng hiện tại

| Kênh | Đối tượng | Nghiệp vụ |
|---|---|---|
| Platform Administration Web — `pte-web/apps/vendor-web` | Platform Admin, Platform Manager, Academic Manager, Academic Staff | Vận hành platform; hồ sơ tổ chức; gói và license; quản trị tài khoản platform; soạn và duyệt học liệu; cấu hình; hỗ trợ và audit theo quyền. |
| Organization Web — `pte-web/apps/tenant-web` | Host, Proctor, Examiner, Student theo workspace | Host vận hành tổ chức/kỳ thi; Proctor thực hiện công việc giám sát; Examiner nhận và chấm bài; Student xem kết quả đã công bố. |
| PTE Practice Web — `pte-practice` | Student | Đăng nhập bằng xác minh email; Home, Practice Tests, Study-Pack, Progress; kiểm tra quyền luyện tập; tạo/làm/lưu phiên luyện tập. |
| Windows Exam Client — `pte-app` | Student trong hành trình thi; source còn có các phần chức năng hỗ trợ khác | Vào kỳ thi được giao, kiểm tra thiết bị, làm bài theo thời gian, lưu câu trả lời tại máy và đồng bộ, gửi bài. |
| Backend dùng chung — `pte-api/app` | Các kênh trên và dịch vụ tích hợp | Danh tính, tổ chức, học liệu, gói, phiên luyện tập, kỳ thi, bài làm, giám sát, chấm, báo cáo, media, thông báo và audit. |

Không đồng nhất chức năng “Practice” của một kỳ thi do Host tạo với `PracticeSession` tự luyện trên web. Đối tượng, cách cấp quyền, vòng đời và cách xem kết quả của chúng cần được phân biệt trong SRS và ERD.

## 3. Mô hình actor và phân quyền mới

Code xác nhận **8 role người dùng theo tên chuẩn**, cộng External Integration Services là actor tích hợp. `PLATFORM_AUTHOR` vẫn còn trong enum để tương thích; `SecurityRoles.canonicalize()` chuyển tên này thành `ACADEMIC_STAFF`. Không đếm tên cũ thành role thứ chín.

| Actor trong tài liệu | Tên trong source | Trách nhiệm và ranh giới |
|---|---|---|
| Platform Admin | `PLATFORM_ADMIN` | Quyền vận hành platform và học thuật; riêng quyền quản trị tài khoản/role platform và platform settings có gate Admin. |
| Platform Manager | `PLATFORM_MANAGER` | Vận hành tổ chức, xử lý hồ sơ đăng ký, gói/license, thông báo, support và audit theo các endpoint/menu. Không nằm trong nhóm author/reviewer học thuật hay nhóm quản trị role platform. |
| Academic Manager | `ACADEMIC_MANAGER` | Tham gia soạn học liệu và thực hiện quyền reviewer: duyệt/từ chối/công bố câu hỏi, duyệt/kích hoạt Score Template theo quy tắc tương ứng. |
| Academic Staff | `ACADEMIC_STAFF` | Soạn/sửa học liệu và bản nháp Score Template, gửi duyệt. Không được cấp quyền duyệt/công bố qua các endpoint reviewer. |
| Host | `HOST_ADMIN` | Vận hành dữ liệu tổ chức, học viên, chương trình/lớp, gói, kỳ thi, phân công nhân sự, xem xét nguồn điểm và công bố báo cáo trong tổ chức. |
| Proctor | `PROCTOR` | Giám sát kỳ thi có quyền tiếp cận, điểm danh/sự cố/audit theo workspace và chính sách. Menu console phụ thuộc `NEXT_PUBLIC_PROCTOR_UI_ENABLED`; profile vẫn có menu riêng. |
| Examiner | `EXAMINER` | Nhận việc chấm trong workspace Examiner, chấm bài được giao, xem thông tin liên quan. Quyền công bố báo cáo cuối thuộc Host. |
| Student | `STUDENT` | Tự luyện trên `pte-practice` theo quyền hợp lệ; tham gia kỳ thi được giao; truy cập bài làm/lịch sử/kết quả của mình theo từng kênh. |
| External Integration Services | Không phải role đăng nhập | PayOS, Cloudinary, email/thông báo và các dịch vụ AI theo cấu hình. |

Nguồn: [Role.java](../../../pte-api/app/src/main/java/com/pte/identity/domain/Role.java), [SecurityRoles.java](../../../pte-api/app/src/main/java/com/pte/shared/security/SecurityRoles.java), [permissions.ts](../../../pte-web/apps/vendor-web/features/auth/permissions.ts), [menu platform](../../../pte-web/apps/vendor-web/lib/navigation.tsx), [menu tổ chức](../../../pte-web/apps/tenant-web/lib/navigation.tsx).

### 3.1 Những thay đổi trách nhiệm cần sửa trong báo cáo

- Không tiếp tục mô tả mọi quyết định vận hành đều chỉ do Platform Admin. Endpoint duyệt/từ chối hồ sơ tổ chức đã cho phép cả Platform Manager.
- Không chuyển toàn bộ quyền Admin cho Platform Manager: platform settings và quản trị tài khoản/role platform vẫn có ranh giới riêng.
- Không tiếp tục dùng Platform Author làm actor chuẩn cho nội dung mới. Chuyển nghiệp vụ soạn sang Academic Staff và nghiệp vụ reviewer sang Academic Manager, đồng thời giữ quyền Admin mà source cho phép.
- Phải phân biệt quyền soạn, gửi duyệt, duyệt, công bố và kích hoạt. Hiện các endpoint câu hỏi và Score Template đã thể hiện các nhóm quyền này.
- Không suy diễn rằng AI giải thích đã có quy trình duyệt riêng chỉ từ việc phiếu yêu cầu Academic Manager kiểm soát hướng dẫn giải thích. Chưa xác định được module quản trị lời giải AI riêng trong phần source đã đọc.

Nguồn: [TenantApplicationController](../../../pte-api/app/src/main/java/com/pte/billing/internal/controller/TenantApplicationController.java), [QuestionController](../../../pte-api/app/src/main/java/com/pte/itembank/internal/controller/QuestionController.java), [ScoreTemplateController](../../../pte-api/app/src/main/java/com/pte/scoretemplate/internal/controller/ScoreTemplateController.java), [PlatformSettingController](../../../pte-api/app/src/main/java/com/pte/billing/internal/controller/PlatformSettingController.java).

## 4. Hành trình Student trên PTE Practice Web

### 4.1 Đăng nhập và liên kết với tổ chức

1. Student nhập email để xin mã xác minh.
2. Backend tạo challenge, lưu mã dưới dạng hash và phát sự kiện gửi email; có thời hạn và giới hạn yêu cầu.
3. Student nhập mã; backend kiểm tra email, challenge và trạng thái danh tính rồi cấp phiên đăng nhập.
4. Backend tạo hoặc cập nhật danh tính luyện tập theo email, liên kết với các bản ghi Student đã được tổ chức tạo/import.
5. Danh tính luyện tập được xác minh không tự tạo tư cách thành viên tổ chức và không tự cấp quyền luyện tập.
6. Hệ thống xác định tổ chức áp dụng. Nếu có nhiều membership đang hoạt động mà chưa xác định được một tổ chức, trả trạng thái `AMBIGUOUS`.

Không nên viết trong SRS rằng “bất kỳ ai đăng ký email đều được luyện tập miễn phí” hoặc Student bắt buộc dùng chung một cách đăng nhập cho mọi ứng dụng. Đăng nhập bằng email của practice và thông tin đăng nhập theo tổ chức của các kênh khác là hai hợp đồng cần mô tả riêng.

Nguồn: [PracticeEmailAuthService](../../../pte-api/app/src/main/java/com/pte/practice/internal/service/PracticeEmailAuthService.java), [PracticeIdentityService](../../../pte-api/app/src/main/java/com/pte/identity/PracticeIdentityService.java), [practice API client](../../../pte-practice/features/practice/api.ts).

### 4.2 Điều kiện mở quyền luyện tập

`PracticeEntitlementService` kiểm tra danh tính đang hoạt động, Student membership hợp lệ, tenant đang hoạt động, quota học viên và gói exam đang còn hiệu lực. Code hiện dùng `hasActiveExamPackageSubscription()`; chưa có bằng chứng về một gói Student tự mua độc lập.

Các trạng thái quyền phía backend gồm `UNLOCKED`, `LOCKED`, `AMBIGUOUS`, `UNAVAILABLE`; frontend còn xử lý giá trị không biết là `UNKNOWN`. Không được coi lỗi kiểm tra quyền là được phép tiếp tục.

Quyền được kiểm tra lại khi thay đổi phiên/lưu câu trả lời, không chỉ khi vào trang. `practice.strict-entitlement.enabled` bị tắt cũng không tự mở quyền ghi dữ liệu. Controller practice và email auth có điều kiện bật riêng; việc source có endpoint không xác nhận môi trường đang bật endpoint đó.

Nguồn: [PracticeEntitlementService](../../../pte-api/app/src/main/java/com/pte/practice/internal/service/PracticeEntitlementService.java), [practice controllers](../../../pte-api/app/src/main/java/com/pte/practice/internal/controller), [PracticeConstants](../../../pte-api/app/src/main/java/com/pte/practice/internal/constant/PracticeConstants.java).

### 4.3 Danh mục và khả năng thực thi dạng bài

Danh mục được lấy từ định nghĩa dạng bài và học liệu dùng chung. Một dạng bài có thể xuất hiện trên danh mục nhưng chưa được làm: backend phân biệt `RUNNABLE`, `VISIBLE`, `UNAVAILABLE`. Để bắt đầu, dạng bài phải có nội dung phù hợp và ứng dụng phải hỗ trợ cách làm bài tương ứng.

Không được lấy số lượng tên dạng bài trong catalog làm số lượng dạng bài đã chạy hoàn chỉnh. Source có trường hợp `WRITE_EMAIL` được giữ hiển thị với trạng thái không khả dụng. Hằng tên sản phẩm luyện tập hiện là `PTE Core Practice`; điểm này phải được phân biệt với cách các báo cáo cũ nói về PTE Academic.

Nguồn: [PracticeCatalogService](../../../pte-api/app/src/main/java/com/pte/practice/internal/service/PracticeCatalogService.java), [PracticeCatalogTaskMapper](../../../pte-api/app/src/main/java/com/pte/practice/internal/service/PracticeCatalogTaskMapper.java), [PracticeConstants](../../../pte-api/app/src/main/java/com/pte/practice/internal/constant/PracticeConstants.java), [renderer allowlist](../../../pte-practice/features/practice/renderer-allowlist.ts).

### 4.4 Tạo, làm và hoàn tất phiên luyện tập

Luồng có trong source:

Student chọn bài/dạng bài → kiểm tra quyền và khả năng làm bài → tạo phiên ở `OVERVIEW` → Begin → lưu nội dung câu hỏi cho phiên và chuyển `IN_PROGRESS` → làm bài/chọn mức tự tin/gửi hoặc bỏ qua → hoàn tất khi không còn câu chờ → xem Progress.

Các điểm nghiệp vụ quan trọng:

- Phiên thuộc một Student và một tổ chức; mọi truy cập phải kiểm tra chủ sở hữu.
- Bắt đầu làm mới thiết lập thời điểm bắt đầu và hạn kết thúc; lưu rồi thoát không đồng nghĩa được khởi động lại thời gian.
- Có Save and Exit, bản nháp và đường thử lại khi gửi thất bại.
- Mỗi thao tác có mã yêu cầu để gửi lại không tạo kết quả trùng, kèm phiên bản dữ liệu để phát hiện thay đổi từ tab khác.
- Câu trả lời có mức tự tin Low/Medium/High; đây là Student tự đánh giá, không phải điểm AI.
- Câu hỏi được sao chép các thông tin nguồn, prompt, giới hạn từ và lựa chọn vào item luyện tập. Không khẳng định đã lưu mọi loại media/rubric chỉ từ phần snapshot hiện đọc.
- Ghi âm được upload bằng grant và kiểm tra ràng buộc với đúng Student, phiên và câu hỏi; không chỉ nhận một URL tùy ý.
- Trạng thái kết thúc gồm `COMPLETED`, `DISCARDED`, `EXPIRED`. Không mô tả chúng như cùng một kết quả “đã nộp và đã chấm”.

Nguồn: [PracticeSessionService](../../../pte-api/app/src/main/java/com/pte/practice/internal/service/PracticeSessionService.java), [PracticeSessionItemService](../../../pte-api/app/src/main/java/com/pte/practice/internal/service/PracticeSessionItemService.java), [PracticeSessionView](../../../pte-practice/features/practice/PracticeSessionView.tsx), [PracticeMediaBindingService](../../../pte-api/app/src/main/java/com/pte/practice/PracticeMediaBindingService.java).

### 4.5 Progress và Study-Pack hiện tại

Progress đọc lịch sử do Student sở hữu, thống kê số phiên/câu đã làm, câu bỏ qua/bản nháp và mức tự tin. Service hiện đọc tối đa 100 phiên gần nhất và trả `hasMore`; đây là giới hạn triển khai, không phải cam kết năng lực hệ thống. Lịch sử đọc không bị xóa chỉ vì quyền gói đã bị thu hồi.

Điểm đặc biệt: `PracticeProgressService.toEntry()` đang trả `score = null`; phiên hoàn tất có câu trả lời được gán `COMPLETED_PENDING_SCORE`. Có khai báo trạng thái “đã có điểm” không có nghĩa luồng hiện tại đã tạo được điểm đó. Không đưa biểu đồ điểm AI hoặc tiến bộ kỹ năng đã đo lường vào mô tả hiện trạng nếu chưa có tích hợp và bằng chứng tiếp theo.

Study-Pack có trang và các thẻ nhóm bài. Nút mở hiện điều hướng về Practice Tests; chưa chứng minh có bộ quản trị khóa học/bài học, tiến độ hoàn thành pack hoặc lộ trình cá nhân hóa độc lập.

Nguồn: [PracticeProgressService](../../../pte-api/app/src/main/java/com/pte/practice/internal/service/PracticeProgressService.java), [ProgressView](../../../pte-practice/features/progress/ProgressView.tsx), [StudyPackView](../../../pte-practice/features/studyPack/StudyPackView.tsx).

## 5. AI: phạm vi đăng ký và bằng chứng triển khai

Phiếu v1.2 yêu cầu AI hỗ trợ phản hồi/giải thích sau khi Student gửi câu trả lời, nêu rõ đây là hướng dẫn học tập và không tạo kết quả PTE chính thức. Phạm vi loại trừ huấn luyện mô hình mới, chatbot gia sư mở và tự động tạo lộ trình cá nhân hóa.

Code scoring dùng chung đã có các adapter AI theo cấu hình, gồm OpenAI-compatible và Azure/Gemini, đồng thời còn stub cho một số đường xử lý. Stub được nhận diện riêng và source ghi rõ kết quả stub không được dùng để công bố như điểm thật. Việc có adapter không xác nhận nhà cung cấp nào đang được cấu hình hoặc chất lượng chấm đã được xác thực.

Trong phần practice đã đọc, API session/task/progress chưa trả nội dung giải thích AI; service lưu câu trả lời và kết thúc phiên chưa thể hiện việc gọi pipeline giải thích. Progress vẫn để điểm trống. Vì vậy:

| Nội dung | Cách ghi đúng khi cập nhật tài liệu |
|---|---|
| AI hỗ trợ phản hồi và giải thích trong luyện tập | Yêu cầu nằm trong phiếu v1.2; tích hợp trọn luồng practice chưa được chứng minh bởi source đã khảo sát. |
| Chấm bằng AI trong phân hệ chấm dùng chung | Có source adapter và hợp đồng nhà cung cấp; cần xác định dạng bài, cấu hình và bằng chứng thực thi trước khi ghi hoàn tất. |
| Student tự chọn mức tự tin | Chức năng có trong luồng lưu câu trả lời; không phải đánh giá chất lượng của mô hình. |
| Kết quả PTE chính thức hoặc bảo đảm tương đương Pearson | Ngoài phạm vi. |
| Chatbot mở, nghiên cứu/huấn luyện mô hình mới, lộ trình cá nhân hóa | Ngoài phạm vi theo phiếu hiện tại. |

Nguồn: [scoring adapters](../../../pte-api/app/src/main/java/com/pte/scoring/internal/vendor), [PracticeSessionItemService](../../../pte-api/app/src/main/java/com/pte/practice/internal/service/PracticeSessionItemService.java), [PracticeSessionResponseMapper](../../../pte-api/app/src/main/java/com/pte/practice/internal/mapper/PracticeSessionResponseMapper.java), [practice contracts](../../../pte-practice/features/practice/contracts.ts).

## 6. Các luồng tổ chức và kỳ thi tiếp tục cần giữ

### 6.1 Tiếp nhận tổ chức và gói sử dụng

Tổ chức gửi hồ sơ → Platform Admin/Platform Manager xem xét → duyệt hoặc từ chối → tổ chức và quyền Host được xử lý theo onboarding → Host kích hoạt/mua gói hoặc đổi license theo nghiệp vụ cho phép → sử dụng các quyền theo gói.

Đăng ký tổ chức và mua/kích hoạt gói là các bước khác nhau. Phiếu tiếp tục loại trừ Student tự thanh toán và marketplace gói cá nhân. PayOS là tích hợp thanh toán phía gói tổ chức, không có nghĩa public registration tự thu tiền.

### 6.2 Chuẩn bị học liệu

Academic Staff/người có quyền soạn → tạo hoặc sửa nháp câu hỏi, media và cấu hình → gửi duyệt → Academic Manager/Platform Admin xử lý reviewer → công bố câu hỏi hoặc kích hoạt Score Template → học liệu đủ điều kiện mới được dùng cho các luồng tương ứng.

### 6.3 Chuẩn bị dữ liệu và kỳ thi

Host tạo/import Student → thiết lập chương trình/lớp và membership → chuẩn bị nhân sự kỳ thi → tạo exam draft → chọn cấu hình, lịch, gói, chế độ đề và nguồn học viên → xem trước danh sách → preflight kiểm tra → sinh đề → công bố → mở/đóng/hủy theo trạng thái.

`ExamOrchestrationService` có xử lý đề chung và đề theo Student, danh sách audience, xung đột và các gate công bố. `ExamGenerationService` chọn câu từ ngân hàng published/shared và có nhánh sinh xác định theo seed. Không chỉ mô tả “Host tạo bài test rồi trộn câu” mà bỏ các bước kiểm tra và lưu nội dung đề.

### 6.4 Làm bài và giám sát

Student vào kỳ thi được giao → kiểm tra thiết bị/chính sách → làm theo thời gian → lưu tại máy → đồng bộ và thử lại khi cần → gửi bài. Windows client có cấu trúc answer outbox, hàng đợi media và sync engine. Việc mất mạng tạm thời và việc có thể thi hoàn toàn offline là hai cam kết khác nhau; phần khảo sát không chứng minh cam kết offline toàn bộ.

Proctor thực hiện giám sát, điểm danh và sự cố trong phạm vi được cấp; đây là nhánh song song của kỳ thi. Menu hiện đã có console Proctor theo cờ bật, vì vậy không sử dụng kết luận cũ rằng Proctor hoàn toàn chưa có route frontend.

### 6.5 Phân công chấm, chọn nguồn điểm và công bố

Host xem roster/phạm vi chấm → preview và xác nhận phân công Examiner → Examiner nhận và chấm bài được giao → Host xem nguồn điểm, preview/apply lựa chọn nguồn và các quyết định liên quan → kiểm tra điều kiện công bố → công bố báo cáo → Student xem kết quả được phép.

Không đồng nhất điểm practice đang chờ với báo cáo kỳ thi đã được Host công bố. Cũng không suy diễn Examiner có quyền công bố báo cáo cuối.

Nguồn: [SessionController](../../../pte-api/app/src/main/java/com/pte/session/internal/controller/SessionController.java), [ExamOrchestrationService](../../../pte-api/app/src/main/java/com/pte/session/internal/service/ExamOrchestrationService.java), [ExamGenerationService](../../../pte-api/app/src/main/java/com/pte/assessment/internal/service/ExamGenerationService.java), [ExaminerAssignmentController](../../../pte-api/app/src/main/java/com/pte/scoring/internal/controller/ExaminerAssignmentController.java), [HostScoreReviewController](../../../pte-api/app/src/main/java/com/pte/scoring/internal/controller/HostScoreReviewController.java), [ReportPublishController](../../../pte-api/app/src/main/java/com/pte/reporting/internal/controller/ReportPublishController.java), [Windows sync engine](../../../pte-app/lib/core/sync/sync_engine.dart).

## 7. Các điểm chưa thống nhất hoặc cần xác nhận khi lập baseline mới

| ID | Điểm đối chiếu | Cách xử lý trong tài liệu tiếp theo |
|---|---|---|
| SCOPE-01 | Report foundation vẫn chốt 6 role người dùng, dùng Platform Author. Source và phiếu v1.2 có 8 role chuẩn. | Cập nhật actor catalog, ma trận quyền, use case và mọi diagram liên quan; ghi rõ tên legacy trong ghi chú chuyển đổi. |
| SCOPE-02 | Phiếu có `pte-practice`; Report 3–6 tập trung hành trình tổ chức/kỳ thi. | Thêm hành trình tự luyện với quyền, dữ liệu, trạng thái và điều kiện lỗi riêng. |
| SCOPE-03 | Phiếu yêu cầu lời giải/feedback AI cho practice; source practice đã đọc chưa chứng minh tích hợp trả kết quả. | Giữ là yêu cầu; ghi riêng trạng thái triển khai, không xóa mục tiêu và không ghi hoàn tất. |
| SCOPE-04 | Phiếu loại trừ cross-organization identity/membership management; source có global email identity và liên kết nhiều membership. | Làm rõ “không có chức năng tự quản lý/chia sẻ xuyên tổ chức” hay “không được có liên kết danh tính”. Không tự xem chúng là cùng nghĩa. |
| SCOPE-05 | Phiếu và report cũ nói PTE-style/PTE Academic; catalog practice dùng nhãn PTE Core Practice, có Write Email chưa khả dụng. | Xác định bộ đề/dạng bài cho từng kênh và trạng thái hỗ trợ; giữ nguyên tên đề tài. |
| SCOPE-06 | Study-Pack có trang nhưng hành động hiện về catalog; phiếu loại trừ personalized study-plan generation. | Mô tả nhóm bài ở mức source hiện có; không bổ sung LMS/lộ trình AI ngoài phạm vi. |
| SCOPE-07 | Phiếu yêu cầu bảo quản nội dung/rubric/provider/model/feedback status; practice response hiện chưa chứng minh đủ dữ liệu giải thích. | Bổ sung thiết kế và tiêu chí chấp nhận cho pipeline AI, giữ trạng thái chưa xác nhận. |
| SCOPE-08 | Root AGENTS/report cũ mô tả Caddy và hai web; Compose hiện có Nginx và `web-practice`. | Report 4/6 phải đối chiếu Compose/deploy hiện tại. Đây là cấu hình source, chưa phải kiểm tra VPS. |
| SCOPE-09 | Source support có Host gửi ticket và Admin/Manager xử lý; feedback giảng viên trước đây còn yêu cầu report nội dung bài/câu hỏi/bài học. | Không khẳng định ticket Host đã bao phủ toàn bộ feedback Student theo nội dung; cần xác định ai gửi, đối tượng và đường phản hồi. |
| SCOPE-10 | Record v1.2 còn chờ giảng viên xác nhận; retention theo hợp đồng. | Giữ ngày/trạng thái duyệt minh bạch; không tự chốt thời gian lưu hoặc coi toàn bộ scope mới đã được duyệt. |

Nguồn bổ sung: [actor catalog cũ](../../report/_foundation/actor-feature-catalog.md), [Report 3 Overall Description](../../report/report03/01-overall-description.md), [Report 4 System Design](../../report/report04/01-system-design.md), [support controllers](../../../pte-api/app/src/main/java/com/pte/support/internal/controller), [Compose hosted](../../../pte-api/docker-compose.deploy.yml).

## 8. Ảnh hưởng tới bộ Report 3–6

| Report | Phần cần cập nhật |
|---|---|
| Foundation dùng chung | Actor/feature catalog; danh mục thuật ngữ; mã yêu cầu; bằng chứng; trạng thái hiện tại/dự kiến; danh sách vấn đề mở. Bỏ ràng buộc cũ cấm role mới. |
| Report 3 — SRS | Overall Description thêm practice; user requirements và ma trận quyền theo 8 role; functional requirements cho email login, entitlement, catalog, phiên luyện tập, recording, confidence, Progress, AI feedback; NFR và appendix phân biệt yêu cầu/hiện trạng. |
| Report 4 — Design | Context/deployment có web practice; thiết kế identity/membership và dữ liệu practice; các trạng thái phiên; quan hệ media; ranh giới practice/exam; sequence kiểm tra quyền, lưu câu trả lời và tích hợp AI dự kiến; kiến trúc edge hiện tại. |
| Report 5 — Test Documentation | Scenario tích cực và từ chối quyền cho các role mới; xác minh email; hết gói/quota/tenant ngưng hoạt động; task hiển thị nhưng không chạy; gửi lại thao tác; nhiều tab; recording sai sở hữu; hết giờ; lịch sử khi mất quyền; AI pending/failed. Không tạo kết quả test giả. |
| Report 6 — User Guides | Hướng dẫn riêng Platform Manager, Academic Manager, Academic Staff và Student practice; phân biệt login; locked/ambiguous/unavailable; Begin/Save and Exit/resume/Progress; Study-Pack đúng hiện trạng; prerequisite bật tính năng khi triển khai. |
| DOCX nộp | Xuất lại từ bộ Markdown đã thống nhất scope, giữ mục lục và style mẫu/logo. Bản DOCX cũ chưa phản ánh các thay đổi này. |

## 9. Ranh giới của lần khảo sát này

Đã đọc phiếu v1.2 và so bản gốc, đối chiếu các nguồn được dẫn ở trên, khảo sát hợp đồng UI → API và logic chính của practice cùng các endpoint nghiệp vụ liên quan. Nhận định “chưa thấy tích hợp” giới hạn trong các đường code khảo sát, không khẳng định mọi nhánh hoặc tài liệu khác đều không tồn tại.

Lần này tạo bản đối chiếu để làm căn cứ cập nhật. Chưa chỉnh nội dung Report 3–6, phiếu đăng ký hay source ứng dụng; chưa chạy build/test hoặc thao tác production.
