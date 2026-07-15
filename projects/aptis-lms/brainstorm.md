# Brainstorm: APTIS LMS — Hệ thống triển khai thi thử APTIS
Date: 2026-06-16

## Topic
Hệ thống triển khai thi thử APTIS gồm 3 bên:
1. **Nhà cung cấp phần mềm (Vendor):** quản lý khóa học, giả lập thi APTIS chính thức, quản lý các trường/trung tâm khách hàng.
2. **Phần mềm thi thử (Exam Client):** nơi người học thi mô phỏng như kỳ thi thật (full 4 kỹ năng APTIS).
3. **Nhà trường / Trung tâm (Tenant):** mua phần mềm, quản lý học viên, triển khai ca thi, xem phân tích cấu trúc đề, điểm yếu mạnh học viên.

## Domain / Scale
EdTech / SaaS — Multi-tenant B2B2C / Startup → Production

## Actors

### Vendor Side
- [ACTOR] **Super Admin**: Toàn quyền hệ thống — quản lý tenant, gói dịch vụ (license), cấu hình toàn cục | access: admin-global
- [ACTOR] **Content Manager**: Tạo & quản lý ngân hàng câu hỏi, cấu trúc đề thi APTIS (4 kỹ năng) | access: write-content
- [ACTOR] **Support Staff**: Xử lý ticket hỗ trợ từ trường/trung tâm; không chỉnh nội dung đề thi | access: read + limited-write
- [ACTOR] **Sales Team**: Quản lý khách hàng (tenant), tạo và cấp license seat-based; không tham gia luồng payment | access: write-tenant

### Tenant Side (School / Training Center)
- [ACTOR] **Tenant Admin**: Toàn quyền trong tenant — quản lý user, khóa học, nhóm/lớp, xem báo cáo, tạo license user | access: admin-tenant
- [ACTOR] **Teacher / Instructor**: Tạo lịch thi, giao bài, xem kết quả học viên trong lớp mình quản lý | access: write-class
- [ACTOR] **Exam Coordinator**: Chuyên triển khai ca thi — lập lịch, monitor phòng thi, xử lý sự cố | access: write-exam
- [ACTOR] **Viewer / Report Only**: Chỉ xem báo cáo; không tạo/chỉnh nội dung hay lịch thi | access: read

> **Design note:** 1 user Tenant có thể giữ nhiều role đồng thời (Teacher + Exam Coordinator, Teacher + Giám thị…) → RBAC multi-role per user là bắt buộc.

### Learner Side
- [ACTOR] **Student (registered)**: Học viên đã đăng ký khóa học; thi theo lịch trường triển khai; xem kết quả bản thân | access: write-own
- [ACTOR] **Guest / Trial taker**: Người dùng thi thử giới hạn; không cần tài khoản đầy đủ | access: limited

### External Systems
- [SYSTEM] **Email / Notification Service**: Gửi thông báo lịch thi, kết quả, nhắc nhở (SendGrid / Firebase) | type: integration

## Confirmed Features (IN Scope)

### 1. Authentication & Access
- Email + password, JWT
- Multi-tenant subdomain: `tenantslug.aptis-lms.vn`
- RBAC: multi-role per user (Tenant side)

### 2. APTIS Exam Structure (Question Bank)
- **Reading:** 4 parts (Part A: matching, Part B: gap fill, Part C: long text MCQ, Part D: reading+writing integrated)
- **Writing:** 3 parts (Part A: short sentences, Part B: short email/message, Part C: long essay 150–180 words)
- **Listening:** 4 parts (Part A: form fill, Part B: 5 short conversations, Part C: longer conversation, Part D: 4 monologues)
- **Speaking:** 5 parts (Part A: personal questions, Part B: describe image, Part C: topic discussion, Part D: compare images, Part E: extended discussion)
- Content Manager quản lý ngân hàng câu hỏi cho tất cả 16 parts

### 3. Exam Simulation (Full Mode)
- Timer per part (y như thi thật)
- Audio playback cho Listening (số lần nghe theo chuẩn APTIS)
- Microphone record cho Speaking → auto-upload
- Text input + word count cho Writing
- UI giao diện thi mô phỏng giao diện thi thật

### 4. Scoring
- **Reading / Listening:** auto-score (matching đáp án)
- **Writing / Speaking:** Hybrid — AI (STT + LLM theo APTIS rubric) chấm sơ bộ; Teacher/Coordinator review và confirm
- Output: band level A1–C per skill, điểm thành phần, nhận xét

### 5. Exam Scheduling & Deployment
- Tạo ca thi: chọn đề, chọn học viên/lớp, đặt thời gian
- Monitor phòng thi (Exam Coordinator xem trạng thái real-time)
- Xử lý sự cố trong ca thi

### 6. Learner Management (LMS)
- Enrollment: thủ công + import CSV
- Generate tài khoản + password hàng loạt → export Excel (tên, email, password)
- Khóa học có thời hạn (start date – end date)
- Nhóm / Lớp trong khóa học; Teacher quản lý lớp mình

### 7. Analytics & Reporting
- **Kết quả cá nhân:** điểm từng kỹ năng, band, biểu đồ tiến trình qua các lần thi, điểm yếu/mạnh theo part
- **Báo cáo lớp (Teacher):** phân phối điểm, học viên yếu/mạnh, so sánh lần thi trước-sau
- **Dashboard Tenant Admin:** tổng quan toàn trường, số ca thi, tỷ lệ hoàn thành, band distribution
- **Item Analysis:** tỷ lệ đúng/sai từng câu hỏi, câu hay sai nhất → Content Manager cải thiện đề

### 8. Vendor Management
- Quản lý tenant (trường/trung tâm): tạo, tạm ngưng, cấu hình subdomain
- Seat-based license: tạo license thủ công (Sales), số seat + expiry date
- Cảnh báo tenant khi gần hết quota (80%, 90%); khóa khi vượt quota

### 9. Sales Team Portal
- Quản lý danh sách khách hàng (tenant)
- Tạo license mới, gia hạn, điều chỉnh quota

### 10. Notification System
- Email: thông báo lịch thi, kết quả, nhắc nhở sắp thi
- Push notification (nếu có mobile client Flutter)

### 11. Guest / Trial Flow
- Thi thử giới hạn (ví dụ: 1 kỹ năng, số câu giới hạn)
- Không cần tài khoản đầy đủ; xem kết quả basic

### 12. Exam Integrity (Anti-cheat)
- Shuffle câu hỏi / đáp án
- Block copy-paste, right-click
- Fullscreen / Kiosk mode lock
- Tab-switch detection, focus loss detection
- Xử lý khi phát hiện vi phạm (cảnh báo, ghi log, tùy chọn kết thúc bài)
- Duplicate attempt: chỉ thi lại khi Teacher/Coordinator cho phép

### 13. Cross-cutting: Exam Continuity
- Exam resume: học viên bị disconnect → tiếp tục từ chỗ dừng (timer tiếp tục chạy server-side)
- Speaking record fail: lưu local draft, retry upload tự động
- State bài thi lưu server-side sau mỗi câu

## OUT of Scope

1. **Payment / Billing tự động:** không có cổng thanh toán online; Sales xử lý manual bên ngoài hệ thống
2. **Video proctoring:** không record video / AI phát hiện gian lận qua camera
3. **Cấp chứng chỉ APTIS chính thức:** không phải đơn vị British Council; chỉ mang tính mô phỏng/luyện thi
4. **Mobile native app tách biệt:** Flutter cross-platform thay thế (xem Technical Constraints)
5. **Tích hợp LMS bên ngoài:** không sync Moodle / Canvas / Google Classroom
6. **Marketplace đề thi:** không có chợ mua/bán đề giữa các trường

## Technical Constraints

| Constraint | Decision |
|---|---|
| Backend stack | [TBD] — TechLead quyết định |
| Client framework | **Flutter** (cross-platform) |
| Flutter platforms | [TBD] — phân bổ theo từng side (TechLead tư vấn); gợi ý: Web cho Admin/Tenant panel, Desktop (Windows/Mac) + Mobile cho Exam client |
| Hosting | **Cloud** (AWS / GCP / Azure) |
| Audio storage | Cloud object storage (S3 / GCS) |
| AI scoring — STT | [TBD] — TechLead quyết định (Whisper / Google STT) |
| AI scoring — LLM | [TBD] — TechLead quyết định (Claude / GPT-4 / Gemini) |
| Auth | JWT, multi-tenant subdomain isolation |
| Data isolation | Strict per-tenant (row-level or schema-level) |

## Business Rules

1. **Multi-role per user:** 1 user Tenant có thể có nhiều role; role combinations được cấp bởi Tenant Admin
2. **Exam continuity:** timer chạy server-side; state lưu sau mỗi câu trả lời; resume cho phép nếu còn thời gian
3. **Speaking upload fail:** lưu local draft, retry upload tự động; bài thi không bị hủy
4. **Seat quota:** cảnh báo email + dashboard tại 80% và 90% quota; block thêm user mới khi đạt 100%
5. **Duplicate attempt:** mỗi ca thi chỉ được thi 1 lần; retake cần Teacher hoặc Exam Coordinator approve
6. **Scoring SLA:** [TBD] — cần xác định SLA cho human review Speaking/Writing
7. **Anti-cheat:** tab-switch / focus loss được log; ngưỡng vi phạm → cảnh báo và/hoặc kết thúc ca thi (Tenant tự cấu hình)
8. **License expiry:** khi license hết hạn, tenant vào chế độ read-only (xem báo cáo), không thi mới được
9. **Trial:** Guest thi thử không lưu dữ liệu lâu dài (purge sau N ngày)

## NFR Baselines

| NFR | Target |
|---|---|
| API response time | [TBD] — TechLead estimate |
| Uptime | [TBD] — TechLead estimate |
| Concurrent exam takers | [TBD] — TechLead estimate |
| Audio upload max size | [TBD] — phụ thuộc Speaking part duration |
| **Exam continuity** | **#1 priority** — exam session KHÔNG được mất khi mất kết nối |

## Open Items

1. **Flutter platform split:** side nào dùng Web, Desktop, Mobile? Cần TechLead tư vấn kiến trúc client.
2. **AI provider:** Whisper STT vs Google STT vs Azure; Claude vs GPT-4 cho scoring — TechLead quyết định.
3. **Speaking/Writing scoring SLA:** Teacher phải review trong bao lâu? Học viên chờ kết quả bao lâu?
4. **Anti-cheat thresholds:** bao nhiêu lần tab-switch mới vi phạm? Tenant có tự cấu hình không?
5. **NFR numeric targets:** Performance, Availability, Scalability — để TechLead estimate.
6. **Guest trial limits:** thi thử bao nhiêu câu/phần? Có lưu email để remarketing không?
7. **Data retention:** giữ audio recording Speaking bao lâu? Giữ exam logs bao lâu?
8. **Exam integrity deep-dive:** nhiều edge case phức tạp cần ultrathinking ở spec phase (network drop mid-Speaking record, audio device không tìm thấy, browser crash, v.v.)
