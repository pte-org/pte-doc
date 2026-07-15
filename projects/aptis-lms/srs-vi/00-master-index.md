# Chỉ số SRS Master
## APTIS LMS — Hệ thống phát triển khai thi thử APTIS
**Phiên bản:** 1.0 | **Ngày:** 2026-06-17 | **Trạng thái:** BẢN THẢO

---

## Bản đồ tài liệu

| Tài liệu | Phần | Sự miêu tả |
|------|---------|-------------|
| [01-giới thiệu.md](01-introduction.md) | §1 Giới thiệu | Mục đích, phạm vi (IN/OUT), định nghĩa, tài liệu tham khảo, tổng quan tài liệu |
| [02-tổng thể-mô tả.md](02-overall-description.md) | §2 Mô tả tổng thể | Sơ đồ ngữ cảnh hệ thống, chức năng sản phẩm, đặc điểm người dùng (10 tác nhân), ràng buộc, giả định (A-01–A-10), phân bổ tính năng |
| [03-01-external-interfaces.md](03-01-external-interfaces.md) | §3.1 Giao diện bên ngoài | 10 màn hình UI (UI-01–UI-10), giao diện phần cứng (HW-01–04), API phần mềm (SI-01–06), giao thức truyền thông (CI-01–04) |
| [03-02-function-requirements.md](03-02-functional-requirements.md) | §3.2 Yêu cầu chức năng | Tất cả 111 FR ở định dạng IEEE 830 (mệnh đề phải + Bảng Tác nhân/Điều kiện tiên quyết/Trình kích hoạt/Nguồn + GWT đầy đủ) trên 13 cụm tính năng |
| [03-03-hiệu suất.md](03-03-performance.md) | §3.3 Yêu cầu về hiệu suất | 14 NFR ở định dạng Kịch bản Thuộc tính Chất lượng ISO/IEC 25023; 5 được xác nhận, 9 TBD |
| [03-04-database.md](03-04-database.md) | §3.4 Yêu cầu cơ sở dữ liệu | 22 định nghĩa thực thể với thông số cột đầy đủ, ước tính khối lượng dữ liệu, tóm tắt trường PII, chính sách lưu giữ và thanh lọc |
| [03-05-design-ràng buộc.md](03-05-design-constraints.md) | §3.5 Ràng buộc thiết kế | 12 ràng buộc thiết kế không thể thương lượng (DC-01–DC-12) với cơ sở lý luận và ý nghĩa thực hiện |
| [03-06-system-attributes.md](03-06-system-attributes.md) | §3.6 Thuộc tính hệ thống | Độ tin cậy, tính sẵn sàng, tính bảo mật, khả năng bảo trì, tính di động, các thuộc tính khả năng sử dụng (SA-REL/AVL/SEC/MNT/PRT/USA) |
| [03-07-other-requirements.md](03-07-other-requirements.md) | §3.7 Các yêu cầu khác | i18n (OR-I18N-01–06), Pháp lý (OR-LGL-01–04), Hoạt động (OR-OPS-01–06), Chuyển tiếp (OR-TRN-01–03), Đào tạo (OR-TRN-04–06) |
| [phụ lục-a-glossary.md](appendix-a-glossary.md) | Phụ lục A - Bảng thuật ngữ | 45 tên miền và thuật ngữ kỹ thuật được xác định theo thứ tự bảng chữ cái |
| [phụ lục-b-open-issues.md](appendix-b-open-issues.md) | Phụ lục B - Các mục mở | 8 mục mở chính (OI-01–OI-08) + 9 TBD nội tuyến; mỗi cái đều có chủ sở hữu, chặn FR/NFR và giải quyết theo mốc quan trọng |

---

## Tóm tắt FR

**Tổng số FR: 111**

| Sự ưu tiên | Đếm | Phạm vi FR |
|----------|-------|----------|
| Thiết yếu | 104 | FR-01–FR-29, FR-37–FR-75, FR-77–FR-82, FR-83 (một phần), FR-85–FR-87, FR-93–FR-111 |
| có điều kiện | 7 | FR-08 (Phiên khách), FR-76 (Mạo danh), FR-84 (Thông báo đẩy), FR-88–FR-92 (Khách/Dùng thử), FR-102 (Chế độ kiosk) |
| Không bắt buộc | 0 | — |

**Phân phối FR theo cụm:**

| Cụm | FR | Đếm |
|---------|-----|-------|
| F-01: Xác thực và truy cập | FR-01–FR-08 | 8 |
| F-02: Quản lý ngân hàng câu hỏi | FR-09–FR-16 | 8 |
| F-03: Mô phỏng bài thi — Chế độ đầy đủ | FR-17–FR-26 | 10 |
| F-04: Hệ thống chấm điểm | FR-27–FR-36 | 10 |
| F-05: Lên lịch và triển khai kỳ thi | FR-37–FR-43 | 7 |
| F-06: Quản lý người học | FR-44–FR-51 | 8 |
| F-07: Phân tích & Báo cáo | FR-52–FR-70 | 19 |
| F-08: Quản lý nhà cung cấp | FR-71–FR-76 | 6 |
| F-09: Cổng thông tin đội ngũ bán hàng | FR-77–FR-82 | 6 |
| F-10: Hệ thống thông báo | FR-83–FR-87 | 5 |
| F-11: Luồng khách / thử nghiệm | FR-88–FR-92 | 5 (Có điều kiện) |
| F-12: Tính liêm chính trong kỳ thi/Chống gian lận | FR-93–FR-103 | 11 |
| F-13: Tiếp tục thi | FR-104–FR-111 | 8 |
| **Tổng cộng** | | **111** |

---

## Tóm tắt NFR

**Tổng số NFR: 14**

| NHẬN DẠNG | đặc trưng | Biện pháp đáp ứng | Trạng thái |
|----|----------------|-----------------|--------|
| NFR-01 | Thời gian phản hồi API (p95) | TBD (được đề xuất: < 500ms) | TBD — OI-05 |
| NFR-02 | Tổng thể sẵn có | TBD (đề xuất: ≥ 99,5%/tháng) | TBD — OI-05 |
| NFR-03 | Giờ thi có sẵn | ≥ 99,9% trong các phiên hoạt động | **Đã xác nhận** |
| NFR-04 | Người thi đồng thời | TBD (đề nghị: ≥ 500) | TBD — OI-05 |
| NFR-05 | Độ trễ tự động tính điểm | 2 phút kể từ khi gửi | **Đã xác nhận** |
| NFR-06 | Độ trễ ghi trạng thái bài kiểm tra (p95) | TBD (được đề xuất: < 300ms) | TBD — OI-05 |
| NFR-07 | Tải lên âm thanh nói | TBD (được đề xuất: tổng cộng 5 phút) | TBD — OI-05 |
| NFR-08 | Nghe phân phối CDN (TTFB) | TBD (được đề xuất: 500ms) | TBD — OI-05 |
| NFR-09 | Quy trình chấm điểm AI | TBD (đề xuất: 15 phút) | TBD — OI-02, OI-05 |
| NFR-10 | Lưu giữ hồ sơ thi | TBD — đang chờ pháp lý (OI-07) | TBD — OI-07 |
| NFR-11 | Lưu giữ bản ghi âm | TBD — đang chờ pháp lý (OI-07) | TBD — OI-07 |
| NFR-12 | Băm mật khẩu | chi phí bcrypt ≥ 12 | **Đã xác nhận** |
| NFR-13 | Tuổi thọ của mã thông báo JWT | Truy cập ≤ 15 phút; Làm mới ≤ 7 ngày luân phiên | **Đã xác nhận** |
| NFR-14 | Tính toàn vẹn dữ liệu bài kiểm tra | Tỷ lệ mất dữ liệu trả lời 0% | **Đã xác nhận (ưu tiên số 1)** |

**Đã xác nhận: 5 | TBD: 9**

---

## Mở mục tóm tắt

**Tổng số mục mở: 8 mục chính (OI-01 đến OI-08) + 9 TBD nội tuyến**

| ôi | Sự miêu tả | Người sở hữu | Trạng thái |
|----|-------------|-------|--------|
| OI-01 | Phân chia nền tảng Flutter (Web / Desktop / Mobile trên mỗi hệ thống con) | Trưởng nhóm công nghệ | MỞ |
| OI-02 | Lựa chọn nhà cung cấp AI (STT + LLM) | Trưởng nhóm công nghệ | MỞ |
| OI-03 | Định nghĩa SLA chấm điểm Viết/Nói | Kinh doanh nhà cung cấp | MỞ |
| OI-04 | Ngưỡng vi phạm mặc định chống gian lận | Kinh doanh nhà cung cấp | MỞ |
| OI-05 | Mục tiêu số NFR (độ trễ API, tính khả dụng, dung lượng, v.v.) | Trưởng nhóm công nghệ | MỞ |
| OI-06 | Phạm vi dùng thử của khách và chính sách thu hút khách hàng tiềm năng | Tiếp thị nhà cung cấp | MỞ |
| OI-07 | Thời gian lưu giữ dữ liệu và tuân thủ ND 13/2023 | Thủ tướng + Pháp lý | MỞ |
| OI-08 | Các trường hợp cạnh liên tục của bài kiểm tra (âm thanh, sự cố, tắt nguồn) | TechLead + Nhà cung cấp | MỞ |

**Tất cả 8 mục OI-XX phải được giải quyết trước khi SRS này có thể được thăng cấp từ trạng thái DRAFT lên CUỐI CÙNG.**

---

## Tóm tắt các ràng buộc thiết kế

| NHẬN DẠNG | ràng buộc | Trạng thái |
|----|-----------|--------|
| DC-01 | Flutter được ủy quyền làm khung máy khách duy nhất | Đã xác nhận |
| DC-02 | Kiến trúc tên miền phụ nhiều người thuê | Đã xác nhận |
| DC-03 | Chỉ HTTPS (TLS 1.2+) | Đã xác nhận |
| DC-04 | Bộ hẹn giờ kiểm tra có thẩm quyền của máy chủ | Đã xác nhận |
| DC-05 | Tính kiên trì phía máy chủ cho mỗi câu trả lời | Đã xác nhận |
| DC-06 | Tính điểm AI chỉ thông qua API của bên thứ ba (không có ML tùy chỉnh) | Đã xác nhận |
| DC-07 | Không xử lý thanh toán trong hệ thống | Đã xác nhận |
| DC-08 | Chỉ lưu trữ đám mây (không có tại chỗ) | Đã xác nhận |
| DC-09 | RBAC phải hỗ trợ đa vai trò cho mỗi người dùng (phía thuê) | Đã xác nhận |
| DC-10 | Các sự kiện vi phạm và nhật ký kiểm tra là không thể thay đổi | Đã xác nhận |
| DC-11 | Yêu cầu từ chối trách nhiệm trên tất cả các màn hình kết quả | Đã xác nhận |
| DC-12 | Mật khẩu không bao giờ được lưu trữ trong bản rõ | Đã xác nhận |

---

## Tóm tắt quy tắc kinh doanh

| NHẬN DẠNG | Luật lệ |
|----|------|
| BR-01 | Người dùng bên thuê có thể giữ nhiều vai trò cùng một lúc; quyền = liên minh các vai trò |
| BR-02 | Tất cả dữ liệu đều nằm trong phạm vi `tenant_id`; quyền truy cập của nhiều người thuê bị cấm |
| BR-03 | Quyền truy cập của giáo viên được giới hạn ở những học sinh trong nhóm được chỉ định |
| BR-04 | Bộ tính giờ thi được ủy quyền bởi máy chủ; khách hàng không thể thao túng chúng |
| BR-05 | Việc đăng ký bị chặn khi `seat_used ≥ Seat_count` |
| BR-06 | Một lần thử cho mỗi học sinh mỗi buổi; thi lại cần có sự chấp thuận rõ ràng |
| BR-07 | Việc thi lại cần có sự chấp thuận của Giáo viên hoặc Điều phối viên kỳ thi |
| BR-08 | Các buổi thi chỉ có thể được tạo trong một khóa học đang hoạt động |
| BR-09 | Học viên chỉ có thể bắt đầu thi trong khoảng thời gian hoạt động của khóa học |
| BR-10 | Người thuê không có giấy phép hoạt động hoặc giấy phép hết hạn sẽ ở chế độ chỉ đọc |
| BR-11 | Thông báo về hạn ngạch chỗ ngồi được gửi khi mức sử dụng là 80% và 90%; cảnh báo hết hạn giấy phép sau 30 và 7 ngày |
| BR-12 | Các câu hỏi được sử dụng trong các phiên hoàn thành được kiểm soát theo phiên bản và không thể thay đổi |
| BR-13 | Học sinh không thể nhìn thấy điểm dự thảo AI cho đến khi được Giáo viên xác nhận |
| BR-14 | Thứ tự câu hỏi và câu trả lời MCQ được xáo trộn mỗi lần thử bằng cách sử dụng hạt giống ngẫu nhiên được lưu trữ |
| BR-15 | Các sự kiện vi phạm là bất biến; không cho phép DELETE lớp ứng dụng |

---

## Trạng thái tài liệu

| Thuộc tính | Giá trị |
|-----------|-------|
| Tình trạng hiện tại | BẢN NHÁP |
| Phần hoàn thành | Tệp chuyên mục 11/11 + Mục lục chính |
| Mở các mục chặn CUỐI CÙNG | 8 (OI-01 đến OI-08) |
| Chặn TBD nội tuyến CUỐI CÙNG | 9 |
| Tổng số yêu cầu | 111 FR + 14 NFR + 12 DC + 15 BR |
| Hành động tiếp theo | Giải quyết các mục OI → thăng cấp lên CUỐI CÙNG |

---

## Các bước tiếp theo được đề xuất

1. **Giải quyết OI-01** (Tách nền tảng Flutter) — bỏ chặn kiến ​​trúc giao diện người dùng và FR-18, FR-95, FR-97, FR-102
2. **Giải quyết OI-02** (nhà cung cấp AI) — bỏ chặn FR-30, FR-31, NFR-09; nên đánh giá PoC ngắn gọn
3. **Giải quyết OI-07** (lưu giữ + tuân thủ ND 13) — phải được hoàn thành trước khi chọn vùng đám mây (DC-08)
4. **Giải quyết OI-05** (mục tiêu NFR) — yêu cầu OI-01 và tải mô hình đầu vào từ Nhà cung cấp; bỏ chặn kích thước cơ sở hạ tầng
5. **Giải quyết OI-03, OI-04, OI-06, OI-08** — có thể tiến hành song song với các cách trên

Sau khi tất cả các mục OI được giải quyết, hãy chạy `/sr:validate` để xác thực SRS theo IEEE 830-1998 và thăng cấp trạng thái lên CUỐI CÙNG.