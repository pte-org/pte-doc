# Đặc tả yêu cầu phần mềm
## APTIS LMS — Hệ thống phát triển khai thi thử APTIS
### Phần 1: Giới thiệu

**Phiên bản tài liệu:** 1.0  
**Ngày:** 2026-06-16  
**Trạng thái:** BẢN DỰ THẢO  
**Phân loại:** Nội bộ — Sử dụng phát triển

---

## 1.1 Mục đích

Đặc tả yêu cầu phần mềm (SRS) này xác định các yêu cầu chức năng và phi chức năng hoàn chỉnh cho **APTIS LMS** (Hệ thống phát triển thi thử APTIS), một nền tảng Phần mềm dưới dạng dịch vụ B2B2C có nhiều bên thuê để triển khai, quản lý và phân tích các kỳ thi thực hành APTIS (Đánh giá tiếng Anh chuyên nghiệp).

Tài liệu này có thẩm quyền cho:

- **Nhóm phát triển Backend và Frontend (Flutter):** Tất cả hành vi của hệ thống được mô tả ở đây cấu thành hợp đồng triển khai. Các tính năng không được mô tả trong SRS này nằm ngoài phạm vi của v1.
- **Kỹ sư kiểm tra và đảm bảo chất lượng:** Mọi Yêu cầu chức năng (FR) đều bao gồm các tiêu chí chấp nhận Cho trước/Khi/Sau đó xác định các điều kiện đạt/không đạt có thể kiểm tra được.
- **TechLead và kiến ​​trúc sư hệ thống:** Yêu cầu phi chức năng (NFR), ràng buộc thiết kế (§3.5) và thuộc tính hệ thống (§3.6) xác định phạm vi kiến ​​trúc mà hệ thống phải được thiết kế trong đó.
- **Chủ sở hữu sản phẩm và các bên liên quan của Nhà cung cấp:** Tài liệu này ghi lại phạm vi v1 đã thỏa thuận. Những thay đổi yêu cầu sửa đổi chính thức với sự gia tăng phiên bản.

SRS này **không** chứa wireframe, mã triển khai, tập lệnh triển khai hoặc nội dung tiếp thị. Những hiện vật đó được duy trì riêng biệt.

---

## 1.2 Phạm vi

### 1.2.1 Tên hệ thống

**APTIS LMS** — Hệ thống phát triển khai thi thử APTIS đa bên (B2B2C SaaS nhiều bên thuê)

### 1.2.2 Tuyên bố vấn đề

Các trường học và trung tâm đào tạo ở Việt Nam chuẩn bị cho học sinh thi APTIS (Đánh giá tiếng Anh chuyên nghiệp — Hội đồng Anh) hiện thiếu một nền tảng chuyên dụng cung cấp đồng thời:

1. **Mô phỏng APTIS đích thực** — một môi trường thực hành sao chép một cách trung thực thời gian, âm thanh, bản ghi micrô và giao diện của bài kiểm tra APTIS thực.
2. **Quản lý người học tích hợp** — tạo tài khoản hàng loạt, nhóm lớp, đăng ký và lập lịch thi từ một giao diện quản trị duy nhất.
3. **Phân tích có thể hành động** - mức độ tiến triển của từng học sinh, phân tích điểm yếu ở cấp độ lớp, số liệu chất lượng ở cấp độ mục, tất cả đều có thể truy cập được bởi giáo viên, điều phối viên và quản trị viên mà không cần xuất dữ liệu bên ngoài.

### 1.2.3 Giải pháp

APTIS LMS là nền tảng SaaS ba mặt:

| Bên | Nhóm diễn viên | Chức năng cốt lõi |
|---|---|---|
| **Cổng thông tin nhà cung cấp** | Nhân viên nhà cung cấp (Super Admin, Content Manager, Support, Sales) | Quản lý tất cả người thuê và giấy phép; duy trì ngân hàng câu hỏi APTIS |
| **Cổng thông tin dành cho người thuê** | Nhân viên trường học/trung tâm (Quản trị viên người thuê nhà, Giáo viên, Điều phối viên, Người xem) | Quản lý người học, lên lịch thi, xem xét các câu trả lời do AI chấm điểm, phân tích kết quả |
| **Khách hàng thi** | Người học (Sinh viên, Khách hàng) | Thực hiện các bài kiểm tra thực hành APTIS đầy đủ trên các máy khách đa nền tảng Flutter |

Mỗi trường học hoặc trung tâm đào tạo là một **đối tượng thuê** biệt lập với tên miền phụ riêng (`{slug}.aptis-lms.vn`), cơ sở người dùng riêng và dữ liệu được cách ly nghiêm ngặt.

### 1.2.4 Các tính năng trong phạm vi

| Cụm tính năng | Sự ưu tiên |
|---|---|
| F-01: Xác thực & Truy cập (cách ly email/JWT/RBAC đa vai trò/tên miền phụ) | Thiết yếu |
| F-02: Ngân hàng câu hỏi APTIS (4 kỹ năng × 16 phần, âm thanh/hình ảnh, mẫu, phân tích mục) | Thiết yếu |
| F-03: Mô phỏng bài kiểm tra - Chế độ đầy đủ (đồng hồ máy chủ, trình phát âm thanh, máy ghi âm, bộ đếm văn bản) | Thiết yếu |
| F-04: Hệ thống chấm điểm (tự động chấm điểm + kết hợp AI+con người cho phần Viết/Nói) | Thiết yếu |
| F-05: Lên lịch và triển khai bài kiểm tra (tạo, xuất bản, theo dõi trực tiếp, can thiệp) | Thiết yếu |
| F-06: Quản lý người học (đăng ký, nhập CSV, xuất thông tin xác thực số lượng lớn, nhóm) | Thiết yếu |
| F-07: Phân tích & Báo cáo (bảng điều khiển sinh viên, lớp, người thuê, phân tích mục) | Thiết yếu |
| F-08: Quản lý nhà cung cấp (vòng đời của người thuê, giấy phép dựa trên chỗ ngồi, cảnh báo) | Thiết yếu |
| F-09: Cổng thông tin nhóm bán hàng (danh sách khách hàng, tạo/gia hạn/điều chỉnh giấy phép) | Thiết yếu |
| F-10: Hệ thống thông báo (email + tin nhắn đẩy tùy chọn) | Thiết yếu |
| F-11: Guest/Trial Flow (thi giới hạn, không có tài khoản) | có điều kiện |
| F-12: Tính toàn vẹn của bài kiểm tra / Chống gian lận (xáo trộn, kiosk, phát hiện vi phạm và ghi nhật ký) | Thiết yếu |
| F-13: Tính liên tục của bài kiểm tra - xuyên suốt (đồng hồ máy chủ, lưu lại mỗi câu trả lời, tiếp tục, bộ đệm âm thanh) | Thiết yếu |

### 1.2.5 Các tính năng ngoài phạm vi

| Tính năng | Lý do | Phiên bản tương lai |
|---|---|---|
| Tự động hóa thanh toán/thanh toán | Bộ phận bán hàng xử lý thanh toán thủ công bên ngoài hệ thống | v2.0 |
| Giám sát video (giám sát camera) | Những lo ngại về sự phức tạp và quyền riêng tư; phát hiện kiosk + tab đủ cho v1 | v3.0 |
| Cấp chứng chỉ chính thức APTIS | Hệ thống không phải là trung tâm được Hội đồng Anh ủy quyền | Không áp dụng |
| Ứng dụng gốc dành cho thiết bị di động độc lập (tách biệt với Flutter) | Đa nền tảng Flutter bao gồm tất cả các nền tảng | Không áp dụng |
| Tích hợp LMS bên ngoài (Moodle / Canvas / Google Classroom) | Không có yêu cầu về người thuê ở v1 | v2.0 |
| Thị trường câu hỏi (mua/bán giữa những người thuê nhà) | Mô hình kinh doanh khác nhau | v3.0+ |

### 1.2.6 Tuyên bố miễn trừ trách nhiệm

APTIS LMS là **nền tảng mô phỏng và thực hành**. Nó không được liên kết, ủy quyền hoặc xác nhận bởi Hội đồng Anh. Điểm số và ước tính ban nhạc do hệ thống này tạo ra chỉ là giá trị gần đúng cho mục đích học tập và không cấu thành kết quả APTIS chính thức.

---

## 1.3 Định nghĩa, từ viết tắt và từ viết tắt

Các định nghĩa đầy đủ được cung cấp trong Phụ lục A (Bảng thuật ngữ). Các thuật ngữ sau đây rất quan trọng để đọc tài liệu này một cách chính xác:

| Thuật ngữ | Định nghĩa ngắn gọn |
|---|---|
| **APTIS** | Đánh giá tiếng Anh chuyên nghiệp – Bài kiểm tra tiếng Anh tiêu chuẩn của Hội đồng Anh |
| **Ban nhạc** | Trình độ thành thạo APTIS/CEFR: A1, A2, B1, B2, C |
| **Người thuê nhà** | Trường học hoặc trung tâm đào tạo sử dụng APTIS LMS theo giấy phép đã mua |
| **Sên** | Giá trị nhận dạng đối tượng thuê an toàn với URL được sử dụng làm tên miền phụ (ví dụ: `hanoi-english`) |
| **Ghế** | Một đơn vị giấy phép = một tài khoản sinh viên đang hoạt động trong một đối tượng thuê |
| **Phần thi** | Triển khai bài kiểm tra theo lịch trình với những người tham gia và khoảng thời gian được xác định |
| **Nỗ lực** | Một học sinh thực hiện một buổi thi |
| **Phần** | Phần phụ của kỹ năng APTIS (ví dụ: Nghe Phần A) |
| **STT** | Speech-to-Text - Dịch vụ AI chuyển đổi âm thanh Nói thành bản ghi |
| **LLM** | Mô hình ngôn ngữ lớn - Mô hình AI chấm điểm Viết và Nói |
| **RBAC** | Kiểm soát truy cập dựa trên vai trò |
| **JWT** | Mã thông báo Web JSON - mã thông báo xác thực không trạng thái |
| **FR** | Yêu cầu chức năng |
| **NFR** | Yêu cầu phi chức năng |
| **GWT** | Đưa ra / Khi / Sau đó - định dạng tiêu chí chấp nhận |
| **TBD** | Cần quyết tâm - yêu cầu giải quyết trước trạng thái CUỐI CÙNG |

---

## 1.4 Tài liệu tham khảo

| Thẩm quyền giải quyết | Tài liệu |
|---|---|
| [IEEE 830-1998] | Thông số kỹ thuật yêu cầu phần mềm được IEEE khuyến nghị |
| [Định dạng APTIS] | Tài liệu về định dạng bài kiểm tra APTIS — Hội đồng Anh (công khai) |
| [CEFR] | Khung tham chiếu chung về ngôn ngữ của Châu Âu — Hội đồng Châu Âu |
| [ND13-2023] | Nghị định 13/2023/ND-CP — Nghị định bảo vệ dữ liệu cá nhân của người Việt |
| [BỘT TÂM] | `projects/aptis-lms/brainstorm.md` — nguồn động não |
| [SPEC] | `projects/aptis-lms/spec.md` — đặc tả nguồn |
| [KẾ HOẠCH-00] | `projects/aptis-lms/plan/00-overview.md` — bản đồ tổng thể kế hoạch |

---

## 1.5 Tổng quan về tài liệu

SRS này được tổ chức như sau:

| Phần | Nội dung |
|---|---|
| §1 Giới thiệu | Mục đích, phạm vi, định nghĩa, tài liệu tham khảo (phần này) |
| §2 Mô tả tổng thể | Bối cảnh hệ thống, chức năng cấp cao, đặc điểm người dùng, ràng buộc, giả định, phân bổ tính năng |
| §3.1 Giao diện bên ngoài | Giao diện người dùng (mỗi màn hình), phần cứng, API phần mềm, giao thức truyền thông |
| §3.2 Yêu cầu chức năng | Tất cả 111 FR ở định dạng will + GWT, được sắp xếp theo cụm tính năng |
| §3.3 Hiệu suất | Tất cả 14 NFR ở định dạng Kịch bản thuộc tính chất lượng ISO/IEC 25023 |
| Cơ sở dữ liệu §3.4 | Định nghĩa thực thể, khối lượng dữ liệu, trường PII, chính sách lưu giữ |
| §3.5 Ràng buộc thiết kế | Công nghệ không thể thương lượng và các hạn chế tuân thủ |
| §3.6 Thuộc tính hệ thống | Độ tin cậy, tính sẵn sàng, tính bảo mật, khả năng bảo trì, tính di động, khả năng sử dụng |
| §3.7 Các yêu cầu khác | i18n, pháp lý, vận hành, đào tạo, chuyển tiếp |
| Phụ lục A | Bảng chú giải đầy đủ về tên miền và thuật ngữ kỹ thuật |
| Phụ lục B | Tất cả các mục mở (TBD) có chủ sở hữu và tác động |

Mọi câu lệnh "**shall**" trong §3.2 đều là một yêu cầu ràng buộc. "**Nên**" biểu thị hướng dẫn không ràng buộc. "**Có thể**" biểu thị khả năng tùy chọn được phép nhưng không bắt buộc.