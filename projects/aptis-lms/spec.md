# Specification: APTIS LMS — Hệ thống triển khai thi thử APTIS
Version: 1.0  
Date: 2026-06-16  
Status: Draft — awaiting TechLead review  
Source: `projects/aptis-lms/brainstorm.md`

---

## §1 — Project Overview

### 1.1 System Name
**APTIS LMS** — Hệ thống triển khai thi thử APTIS đa bên (Multi-tenant B2B2C SaaS)

### 1.2 Problem Statement

Các trường học và trung tâm luyện thi tại Việt Nam đang chuẩn bị học viên cho kỳ thi APTIS (Assessment of Professional English — British Council) nhưng thiếu một nền tảng chuyên biệt đáp ứng đồng thời ba nhu cầu:

1. **Giả lập thi chính xác:** Học viên cần trải nghiệm môi trường thi mô phỏng y hệt kỳ thi APTIS thực tế (giao diện, thời gian, audio, microphone recording) để làm quen trước khi thi thật.
2. **Quản lý học viên và triển khai thi tập trung:** Trường/trung tâm cần công cụ quản lý toàn bộ vòng đời học viên — từ tạo tài khoản hàng loạt, phân lớp, lên lịch thi, đến theo dõi tiến trình — trong một hệ thống duy nhất.
3. **Phân tích điểm mạnh/yếu có chiều sâu:** Giáo viên và quản lý cần dữ liệu phân tích chi tiết theo từng kỹ năng, từng part, từng câu hỏi để điều chỉnh giảng dạy và cải thiện đề thi.

Hiện tại, không có giải pháp SaaS nào tại thị trường Việt Nam kết hợp được cả ba yêu cầu này trong một nền tảng multi-tenant có khả năng scale.

### 1.3 Solution Summary

APTIS LMS là nền tảng SaaS multi-tenant (B2B2C) gồm ba phân hệ phục vụ ba bên:

| Phân hệ | Bên | Chức năng chính |
|---|---|---|
| **Vendor Portal** | Nhà cung cấp phần mềm | Quản lý tenant (trường/trung tâm), license, ngân hàng đề thi APTIS, hỗ trợ kỹ thuật |
| **Tenant Portal** | Trường / Trung tâm | Quản lý học viên, lớp học, lịch thi, phân tích kết quả, chấm điểm Writing/Speaking |
| **Exam Client** | Học viên / Người học | Thi thử mô phỏng APTIS full 4 kỹ năng; giao diện cross-platform (Flutter) |

Mỗi trường/trung tâm là một **tenant độc lập** với subdomain riêng (`tenantslug.aptis-lms.vn`), dữ liệu cách ly hoàn toàn. Nhà cung cấp phần mềm (Vendor) quản lý toàn bộ hệ thống qua Vendor Portal riêng biệt.

### 1.4 Primary Success Metrics

| Metric | Định nghĩa | Mục tiêu giai đoạn đầu |
|---|---|---|
| Exam session completion rate | % ca thi được hoàn thành không gián đoạn (không mất dữ liệu) | ≥ 95% |
| Score availability SLA | Thời gian từ khi nộp bài đến khi có kết quả Reading/Listening | ≤ 2 phút (auto-score) |
| Student band progression | % học viên cải thiện band sau ≥ 2 lần thi trên cùng kỹ năng | [TBD: baseline sau 3 tháng] |
| Tenant activation rate | % tenant đã tạo ít nhất 1 ca thi sau khi mua license | ≥ 80% trong 30 ngày |
| System uptime (exam hours) | Uptime trong khung giờ có ca thi đang diễn ra | ≥ 99.9% |

---

## §2 — Actors

### 2.1 Super Admin (Vendor)

| Attribute | Value |
|---|---|
| Role | Quản trị toàn bộ hệ thống phía Vendor |
| Technical proficiency | Expert (developer-level hoặc senior IT ops) |
| Domain knowledge | Hiểu toàn bộ nghiệp vụ EdTech và APTIS |
| Channel | Web (Vendor Admin Portal) |
| Frequency | Daily — vận hành và monitor hệ thống |
| Access scope | admin-global: toàn quyền trên mọi tenant, mọi dữ liệu |
| Accessibility needs | Standard |

**Responsibilities:** Tạo/xóa/tạm ngưng tenant, cấu hình hệ thống toàn cục, xem log lỗi, quản lý gói license, impersonate các role khác khi hỗ trợ kỹ thuật.

---

### 2.2 Content Manager (Vendor)

| Attribute | Value |
|---|---|
| Role | Tạo và quản lý ngân hàng đề thi APTIS |
| Technical proficiency | Intermediate (biết dùng CMS, không cần code) |
| Domain knowledge | Chuyên gia nội dung APTIS — hiểu cấu trúc 4 kỹ năng, rubric chấm điểm |
| Channel | Web (Vendor Portal — Content module) |
| Frequency | Regular — mỗi lần có đề thi mới hoặc cập nhật |
| Access scope | write-content: tạo/sửa/xóa câu hỏi, đề thi; xem item analysis toàn hệ thống |
| Accessibility needs | Standard |

**Responsibilities:** Nhập câu hỏi theo từng part (Reading/Writing/Listening/Speaking), upload audio file cho Listening, upload image cho Speaking, tạo đề thi từ ngân hàng câu hỏi, xem item analysis để cải thiện câu hỏi.

---

### 2.3 Support Staff (Vendor)

| Attribute | Value |
|---|---|
| Role | Hỗ trợ kỹ thuật và nghiệp vụ cho tenant |
| Technical proficiency | Basic-Intermediate |
| Domain knowledge | Hiểu cơ bản quy trình thi, không cần hiểu sâu APTIS rubric |
| Channel | Web (Vendor Portal — Support module) |
| Frequency | Daily — xử lý ticket hỗ trợ |
| Access scope | read + limited-write: xem dữ liệu tenant (để debug), không chỉnh đề thi hoặc license |
| Accessibility needs | Standard |

**Responsibilities:** Tiếp nhận và xử lý yêu cầu hỗ trợ từ Tenant Admin (reset password, debug ca thi, v.v.), escalate lên Super Admin khi cần.

---

### 2.4 Sales Team (Vendor)

| Attribute | Value |
|---|---|
| Role | Quản lý khách hàng (tenant) và license |
| Technical proficiency | Basic (non-technical) |
| Domain knowledge | Biết nghiệp vụ bán hàng và gói dịch vụ; không cần hiểu kỹ thuật |
| Channel | Web (Sales Portal — module riêng trong Vendor Portal) |
| Frequency | Several times per week — tạo/gia hạn license, theo dõi khách hàng |
| Access scope | write-tenant: tạo/sửa tenant account, tạo/gia hạn license; không xem dữ liệu thi |
| Accessibility needs | Standard |

**Responsibilities:** Tạo tài khoản tenant mới, cấp license (số seat + expiry date), gia hạn hoặc nâng cấp license, xem danh sách khách hàng và trạng thái license.  
**Note:** Payment xử lý hoàn toàn ngoài hệ thống (bên Sales tự quản lý). Hệ thống không theo dõi invoice hay billing.

---

### 2.5 Tenant Admin (School / Training Center)

| Attribute | Value |
|---|---|
| Role | Quản trị toàn bộ tài khoản trường/trung tâm |
| Technical proficiency | Basic-Intermediate (văn phòng/IT nhà trường) |
| Domain knowledge | Hiểu quy trình tổ chức thi, quản lý học viên; không cần hiểu kỹ thuật APTIS sâu |
| Channel | Web (Tenant Portal — Admin view) |
| Frequency | Daily trong mùa thi, weekly ngoài mùa thi |
| Access scope | admin-tenant: toàn quyền trong phạm vi tenant (user, khóa học, lịch thi, báo cáo) |
| Accessibility needs | Standard |

**Responsibilities:** Tạo tài khoản giáo viên và học viên (bulk hoặc từng người), phân quyền role cho user, tạo/quản lý khóa học và nhóm lớp, xem báo cáo toàn trường, theo dõi quota license.

---

### 2.6 Teacher / Instructor

| Attribute | Value |
|---|---|
| Role | Quản lý lớp học và xem kết quả học viên |
| Technical proficiency | Basic (sử dụng web thông thường) |
| Domain knowledge | Giáo viên APTIS — hiểu cấu trúc thi và rubric chấm điểm |
| Channel | Web (Tenant Portal — Teacher view) |
| Frequency | Daily hoặc several times per week |
| Access scope | write-class: tạo lịch thi cho lớp mình, giao bài, xem kết quả học viên trong lớp; không xem lớp khác |
| Accessibility needs | Standard |

**Responsibilities:** Tạo và publish ca thi cho lớp, review và confirm điểm AI cho Writing/Speaking của học viên lớp mình, xem báo cáo lớp, phân tích điểm yếu học viên.  
**Multi-role note:** 1 user có thể vừa là Teacher vừa là Exam Coordinator. Role được cấp bởi Tenant Admin.

---

### 2.7 Exam Coordinator

| Attribute | Value |
|---|---|
| Role | Chuyên viên triển khai ca thi |
| Technical proficiency | Basic-Intermediate |
| Domain knowledge | Hiểu quy trình tổ chức phòng thi APTIS |
| Channel | Web / Flutter Desktop (monitor phòng thi real-time) |
| Frequency | Intensive trong ca thi; idle ngoài ca thi |
| Access scope | write-exam: tạo/quản lý ca thi, monitor live, xử lý sự cố trong ca thi; không xem báo cáo analytics |
| Accessibility needs | Standard |

**Responsibilities:** Lập lịch ca thi, monitor trạng thái từng thí sinh trong phòng thi (started/in-progress/disconnected/completed), can thiệp khi có sự cố (gia hạn thời gian, reset attempt với lý do), duyệt yêu cầu retake.

---

### 2.8 Viewer / Report Only

| Attribute | Value |
|---|---|
| Role | Xem báo cáo, không tham gia triển khai |
| Technical proficiency | Non-technical (hiệu trưởng, quản lý cấp trên) |
| Domain knowledge | Hiểu kết quả band APTIS; không cần biết chi tiết kỹ thuật |
| Channel | Web (Tenant Portal — read-only view) |
| Frequency | Weekly hoặc theo nhu cầu |
| Access scope | read: xem tất cả báo cáo trong tenant; không tạo/chỉnh bất kỳ nội dung nào |
| Accessibility needs | Standard (có thể cần font size lớn hơn — để TechLead xem xét) |

**Responsibilities:** Xem dashboard tổng quan tenant, báo cáo kết quả theo lớp/khóa học, band distribution, không thực hiện bất kỳ thao tác write nào.

---

### 2.9 Student (Registered)

| Attribute | Value |
|---|---|
| Role | Học viên tham gia thi thử APTIS |
| Technical proficiency | Non-technical đến Basic (học sinh/sinh viên/người đi làm) |
| Domain knowledge | Biết cơ bản kỳ thi APTIS; không cần biết hệ thống |
| Channel | Flutter (Desktop: Windows/Mac; Mobile: iOS/Android; Web — tùy platform split do TechLead quyết định) |
| Frequency | Theo lịch thi do trường triển khai |
| Access scope | write-own: tham gia ca thi đã được enroll, nộp bài, xem kết quả bản thân |
| Accessibility needs | Cần hỗ trợ microphone (Speaking), audio output (Listening); màn hình tối thiểu 10 inch khuyến nghị |

**Responsibilities:** Đăng nhập bằng tài khoản do trường cấp, tham gia ca thi được assign, hoàn thành bài thi (Reading, Writing, Listening, Speaking), xem kết quả và phản hồi sau khi có điểm.

---

### 2.10 Guest / Trial Taker

| Attribute | Value |
|---|---|
| Role | Người dùng thi thử không cần tài khoản |
| Technical proficiency | Non-technical |
| Domain knowledge | Mới tìm hiểu APTIS hoặc muốn trải nghiệm hệ thống |
| Channel | Web (landing page trial — không cần app cài) |
| Frequency | One-time hoặc vài lần |
| Access scope | limited: thi thử phần giới hạn, xem kết quả cơ bản; không có account lưu trữ lâu dài |
| Accessibility needs | Standard |

**Responsibilities:** Truy cập trang trial, chọn kỹ năng/part muốn thử, làm bài giới hạn, xem kết quả ước tính band, optionally chuyển đến trang liên hệ Sales.

---

### 2.11 Email / Notification Service (External System)

| Attribute | Value |
|---|---|
| Type | External SaaS integration |
| Provider | SendGrid / Firebase Cloud Messaging (TBD — TechLead quyết định) |
| Direction | Outbound only (hệ thống gửi, không nhận) |
| Triggers | Lịch thi mới, kết quả có sẵn, quota warning, account created, license expiry |
| Channels | Email (bắt buộc); Push notification (nếu có Flutter mobile) |

---

## §3 — Features (IN Scope)

### F-01: Authentication & Access Control

**Cluster:** Security & Identity  
**Priority:** Essential  
**Actors:** Tất cả actors

**Mô tả gốc (brainstorm):** Email + password, JWT, multi-tenant subdomain `tenantslug.aptis-lms.vn`, RBAC multi-role per user.

**Chi tiết mở rộng:**

| Sub-feature | Mô tả |
|---|---|
| F-01.1 User Login | Đăng nhập bằng email + password. Hệ thống xác định tenant từ subdomain của request, chỉ cho phép login nếu user thuộc tenant đó (hoặc là Vendor user trên Vendor Portal). |
| F-01.2 JWT Auth | Access token (short-lived, ~15 phút) + Refresh token (long-lived, ~7 ngày, rotating). Token mang claim: user_id, tenant_id, roles[]. |
| F-01.3 Multi-tenant Routing | Subdomain `{slug}.aptis-lms.vn` → resolve tenant_id → scope tất cả queries theo tenant_id. Vendor Portal dùng domain riêng biệt (e.g., `admin.aptis-lms.vn`). |
| F-01.4 RBAC Multi-role | Mỗi user Tenant có thể được gán 1 hoặc nhiều role (Teacher, Exam Coordinator, Viewer, v.v.). Permission = union của tất cả roles. Role được Tenant Admin gán/thu hồi. |
| F-01.5 Forgot Password | Flow reset password qua email (time-limited token). Áp dụng cho tất cả users trừ Guest. |
| F-01.6 Forced Password Change | Khi tài khoản được generate hàng loạt, học viên bắt buộc đổi password lần đăng nhập đầu (optional — Tenant Admin cấu hình). |
| F-01.7 Session Management | Logout invalidate refresh token. Vendor Super Admin có thể force-logout toàn bộ session của 1 user (emergency). |
| F-01.8 Guest Access | Guest không cần account; truy cập trial landing page. Guest session là stateless hoặc dùng short-lived anonymous token. Không có persistent storage. |

**Business rules liên quan:** BR-01 (multi-role), BR-12 (license expiry → read-only mode)

---

### F-02: APTIS Question Bank Management

**Cluster:** Content Management  
**Priority:** Essential  
**Actors:** Content Manager, Super Admin

**Mô tả gốc (brainstorm):** Ngân hàng câu hỏi đầy đủ 4 kỹ năng (Reading 4 parts, Writing 3 parts, Listening 4 parts, Speaking 5 parts). Content Manager quản lý toàn bộ 16 parts.

**Chi tiết mở rộng:**

**Cấu trúc đề thi APTIS đầy đủ:**

| Skill | Part | Dạng câu hỏi | Ghi chú |
|---|---|---|---|
| Reading | Part A | Matching (5 câu) | Match definition với từ |
| Reading | Part B | Gap fill (6 câu) | Chọn từ điền vào chỗ trống |
| Reading | Part C | MCQ — Long text (8 câu) | Đọc hiểu văn dài, trả lời MCQ |
| Reading | Part D | Reading + Short answer (3 câu) | Đọc và viết câu trả lời ngắn |
| Writing | Part A | Short sentences (5 câu) | Viết câu dựa trên prompts |
| Writing | Part B | Short message/email | Viết email/tin nhắn ~50 từ |
| Writing | Part C | Long essay | Viết essay ~150–180 từ dựa trên topic |
| Listening | Part A | Form fill (7 câu) | Nghe và điền thông tin vào form |
| Listening | Part B | 5 short conversations — MCQ | Mỗi đoạn 1 câu MCQ |
| Listening | Part C | Longer conversation — MCQ (5 câu) | Đoạn dài, nhiều câu hỏi |
| Listening | Part D | 4 monologues — MCQ | Mỗi monologue 1 câu MCQ |
| Speaking | Part A | Personal questions (5 câu) | Trả lời câu hỏi cá nhân |
| Speaking | Part B | Describe an image | Mô tả hình ảnh (30s prep + 1 min answer) |
| Speaking | Part C | Topic discussion (5 rounds) | Thảo luận về topic từ cards |
| Speaking | Part D | Compare 2 images | So sánh 2 hình ảnh |
| Speaking | Part E | Extended discussion | Thảo luận mở rộng dựa trên Part D |

| Sub-feature | Mô tả |
|---|---|
| F-02.1 Question CRUD | Tạo/sửa/xóa câu hỏi; mỗi câu có: type, skill, part, content (text/HTML), answer key (nếu auto-score), rubric hints (nếu human-score), difficulty tag, topic tag |
| F-02.2 Audio Asset Management | Upload và gắn file audio (MP3/WAV) cho Listening parts. CDN delivery cho exam client. Cấu hình: số lần phát tối đa per part (Part A: 1 lần, Part B-D: tùy cấu hình theo chuẩn APTIS). |
| F-02.3 Image Asset Management | Upload và gắn hình ảnh (JPEG/PNG) cho Speaking Part B và Part D. Responsive rendering trên exam client. |
| F-02.4 Exam Template Builder | Tạo đề thi bằng cách chọn câu hỏi từ ngân hàng per part, hoặc auto-select ngẫu nhiên theo tag/difficulty. 1 đề = 1 bộ câu hỏi cho tất cả 4 kỹ năng. |
| F-02.5 Preview Mode | Content Manager preview đề thi như học viên sẽ thấy (giao diện thi, audio playback, image rendering). |
| F-02.6 Version Control | Câu hỏi có version history. Khi sửa câu đã dùng trong ca thi đã hoàn thành, câu cũ được giữ nguyên cho lịch sử. |
| F-02.7 Bulk Import | Import câu hỏi từ file Excel/CSV theo template chuẩn (cho phép nhập hàng loạt câu hỏi). |
| F-02.8 Item Analysis View | Content Manager xem tỷ lệ đúng/sai/bỏ qua per câu hỏi, flagged questions (outlier) để review. (Dữ liệu đến từ F-07.4) |

**Business rules liên quan:** BR-14 (shuffle per session), BR-15 (AI draft + human confirm)

---

### F-03: Exam Simulation — Full Mode

**Cluster:** Core Exam Experience  
**Priority:** Essential  
**Actors:** Student, Guest (limited)

**Mô tả gốc (brainstorm):** Full simulation: timer, audio playback, microphone record Speaking, text input + word count Writing, giao diện y như thi thật.

**Chi tiết mở rộng:**

| Sub-feature | Mô tả |
|---|---|
| F-03.1 Exam Launch | Học viên vào link ca thi → hệ thống kiểm tra eligibility (enrolled + session window open + attempt count) → launch exam session. |
| F-03.2 Pre-exam Checks | Trước khi bắt đầu: (1) Kiểm tra microphone (Speaking test) — alert nếu không tìm thấy; (2) Yêu cầu fullscreen / kiosk mode; (3) Hướng dẫn kỹ năng. |
| F-03.3 Server-side Timer | Timer cho mỗi part chạy trên server. Client hiển thị time remaining (sync với server mỗi N giây). Khi hết giờ server auto-advance sang part tiếp theo bất kể client state. |
| F-03.4 Reading Interface | Hiển thị nội dung bài đọc và câu hỏi. Dạng MCQ (radio button), matching (drag-drop hoặc dropdown), gap fill (dropdown hoặc text input). Navigation giữa các câu trong part. |
| F-03.5 Writing Interface | Text area với: live word count, word limit indicator (warn khi vượt/chưa đủ), font size control. Part A: prompt + input field per sentence. Part B: email scenario + text area. Part C: essay prompt + large text area với word counter. |
| F-03.6 Listening Interface | Audio player controlled theo chuẩn APTIS (auto-play, limited replay per part). Progress indicator. Câu hỏi hiển thị đồng thời với audio. Không cho tua nhanh (per APTIS standard). |
| F-03.7 Speaking Interface | Sequence per part: instruction screen (với hình ảnh nếu Part B/D) → preparation timer → recording timer → auto-stop → upload. Visual: waveform indicator khi recording, upload progress. |
| F-03.8 Part Transition | Transition screen giữa các part: thông báo kết thúc part, countdown đến part tiếp theo. Không cho quay lại part đã qua. |
| F-03.9 Skill Sequencing | Thứ tự kỹ năng trong exam session: Reading → Listening → Writing → Speaking (hoặc theo cấu hình đề thi). Break giữa các skill (cấu hình theo APTIS standard). |
| F-03.10 Exam Submission | Sau khi hoàn thành tất cả kỹ năng (hoặc hết giờ): auto-submit. Confirm screen. Redirect đến trang kết quả (available ngay cho Reading/Listening, pending cho Writing/Speaking). |

**Business rules liên quan:** BR-02 (server-side timer), BR-03 (state save per question), BR-14 (shuffle), BR-16 (Listening play count)

---

### F-04: Scoring System

**Cluster:** Assessment  
**Priority:** Essential  
**Actors:** System (auto), Teacher/Exam Coordinator (review Writing/Speaking), Student (view results)

**Mô tả gốc (brainstorm):** Reading/Listening: auto-score. Writing/Speaking: Hybrid — AI (STT + LLM theo APTIS rubric) chấm sơ bộ; Teacher/Coordinator review và confirm. Output: band level A1–C per skill, điểm thành phần, nhận xét.

**Chi tiết mở rộng:**

**4.1 Auto-scoring (Reading & Listening)**

| Sub-feature | Mô tả |
|---|---|
| F-04.1 Answer Matching | Sau khi submit, so sánh đáp án học viên với answer key. Tính điểm thô (raw score) per part. |
| F-04.2 Band Calculation | Convert raw score sang APTIS band (A1, A2, B1, B2, C) per skill theo mapping table (theo thang điểm APTIS official). |
| F-04.3 Instant Result | Kết quả Reading + Listening available ngay sau submit (< 2 phút SLA). |

**4.2 AI-assisted Scoring (Writing & Speaking)**

| Sub-feature | Mô tả |
|---|---|
| F-04.4 Speaking Transcription | Audio recording từ Speaking → STT API (Whisper/Google STT — TBD) → transcript text per part. |
| F-04.5 AI Scoring Draft | Transcript (Speaking) hoặc written text (Writing) + APTIS rubric → LLM API → AI generates: score per criterion (grammar, vocabulary, coherence, task completion), overall score estimate, narrative feedback in Vietnamese/English. Output stored as "draft" — NOT finalized. |
| F-04.6 Human Review Queue | Teacher/Exam Coordinator xem queue các bài Writing/Speaking chờ review. Interface: hiển thị đề bài, bài làm học viên, AI draft score + feedback, rubric criteria. Teacher chỉnh sửa điểm hoặc confirm AI draft. |
| F-04.7 Score Finalization | Sau khi Teacher confirm → điểm được finalize → học viên nhận notification → kết quả available. |
| F-04.8 Scoring SLA | [TBD — open item OI-03]: cần xác định thời gian tối đa Teacher phải review. Hệ thống cần reminder notification nếu quá SLA. |

**4.3 Result Output**

| Sub-feature | Mô tả |
|---|---|
| F-04.9 Result Dashboard (Student) | Xem: band per skill (A1–C), điểm thành phần per part, so sánh với lần thi trước (nếu có), AI feedback text (Writing/Speaking). |
| F-04.10 APTIS Band Summary | Hiển thị band profile như APTIS chính thức (4 skills + overall composite nếu áp dụng). |
| F-04.11 Feedback Narrative | AI-generated narrative feedback cho Writing và Speaking, được Teacher review/chỉnh trước khi publish cho học viên. |

**Business rules liên quan:** BR-15 (AI draft → human confirm pipeline)

---

### F-05: Exam Scheduling & Deployment

**Cluster:** Exam Operations  
**Priority:** Essential  
**Actors:** Teacher, Exam Coordinator, Tenant Admin

**Mô tả gốc (brainstorm):** Tạo ca thi (chọn đề, chọn học viên/lớp, đặt thời gian), monitor phòng thi real-time, xử lý sự cố.

**Chi tiết mở rộng:**

| Sub-feature | Mô tả |
|---|---|
| F-05.1 Create Exam Session | Chọn: tên ca thi, đề thi (từ template đã tạo), học viên tham dự (chọn lớp hoặc cá nhân), ngày giờ mở/đóng session, anti-cheat settings (shuffle on/off, violation thresholds). |
| F-05.2 Publish & Notify | Sau khi tạo: tự động gửi email thông báo đến học viên được assign (tên ca thi, ngày giờ, link vào thi). |
| F-05.3 Live Monitor Dashboard | Trong ca thi: Exam Coordinator thấy real-time list thí sinh với trạng thái: Not started / In progress (skill đang làm) / Disconnected / Submitted. Refresh tự động (WebSocket hoặc SSE). |
| F-05.4 Time Extend | Exam Coordinator có thể gia hạn thêm thời gian cho 1 học viên cụ thể (ví dụ: do sự cố kỹ thuật). Log lại lý do gia hạn. |
| F-05.5 Force Submit | Exam Coordinator có thể force-submit bài của học viên (ví dụ: ca thi đã quá giờ, học viên không submit được do lỗi mạng). |
| F-05.6 Session Close | Đóng ca thi thủ công trước giờ (nếu cần) hoặc auto-close sau thời điểm kết thúc. Học viên đang thi trong window được phép hoàn thành. |
| F-05.7 Retake Approval | Khi học viên request retake: Teacher/Coordinator nhận request → approve/reject. Nếu approve: tạo attempt mới cho học viên đó trong ca thi (hoặc ca thi mới). |

**Business rules liên quan:** BR-05 (duplicate attempt), BR-09 (retake approval)

---

### F-06: Learner Management (LMS)

**Cluster:** User & Course Management  
**Priority:** Essential  
**Actors:** Tenant Admin, Teacher

**Mô tả gốc (brainstorm):** Enrollment (thủ công + CSV), generate account + password → export Excel, khóa học có thời hạn, nhóm/lớp trong khóa học.

**Chi tiết mở rộng:**

| Sub-feature | Mô tả |
|---|---|
| F-06.1 Course Creation | Tenant Admin tạo khóa học: tên, mô tả, start date, end date. Học viên chỉ có thể thi trong khoảng thời gian khóa học còn hiệu lực. |
| F-06.2 Group/Class Management | Trong mỗi khóa học: tạo các nhóm/lớp. Teacher được assign vào lớp cụ thể → chỉ xem/quản lý lớp đó. |
| F-06.3 Manual Enrollment | Tenant Admin hoặc Teacher thêm học viên vào lớp từng người: nhập email (nếu đã có account) hoặc tạo account mới ngay. |
| F-06.4 CSV Import | Import danh sách học viên từ file CSV/Excel: cột tối thiểu (họ tên, email hoặc username). Hệ thống auto-generate password, tạo account, enroll vào lớp chỉ định. Preview trước khi import, error report sau import. |
| F-06.5 Bulk Account Export | Sau khi tạo accounts: export file Excel gồm: STT, họ tên, email/username, password (plain text — chỉ export 1 lần ngay sau tạo), tên lớp. Export này dùng để phát cho học viên. |
| F-06.6 Student Profile | Xem profile học viên: thông tin cơ bản, lịch sử ca thi, điểm theo thời gian, trạng thái trong khóa học. |
| F-06.7 Unenroll | Xóa học viên khỏi lớp/khóa (không xóa account; lịch sử thi vẫn giữ). |
| F-06.8 Seat Tracking | Số lượng học viên active trong tenant được đếm theo seat license. Thêm học viên mới khi đã đạt 100% quota sẽ bị block (BR-07). |

**Business rules liên quan:** BR-04 (seat quota), BR-07 (block khi 100%), BR-08 (license expiry → read-only)

---

### F-07: Analytics & Reporting

**Cluster:** Insights & Decision Support  
**Priority:** Essential  
**Actors:** Student (view own), Teacher (class + individual), Tenant Admin & Viewer (all in tenant), Content Manager (item analysis — global), Super Admin (all)

**Mô tả gốc (brainstorm):** Kết quả cá nhân, báo cáo lớp, dashboard tenant, item analysis.

**Chi tiết mở rộng:**

**7.1 Individual Student Dashboard**

| Sub-feature | Mô tả |
|---|---|
| F-07.1.1 Score History | List tất cả lần thi của học viên: ngày thi, ca thi, band per skill, tổng điểm. Sort mới nhất trước. |
| F-07.1.2 Progression Chart | Biểu đồ line chart: band per skill qua các lần thi. Trực quan hóa tiến trình cải thiện. |
| F-07.1.3 Skill Breakdown | Per lần thi: điểm chi tiết theo từng part của từng kỹ năng. Highlight part yếu (dưới ngưỡng cần thiết). |
| F-07.1.4 Strengths & Weaknesses | Tổng hợp: skill/part nào consistently yếu qua nhiều lần thi. Gợi ý tập trung cải thiện. |
| F-07.1.5 Feedback Access | Xem AI feedback (Writing/Speaking) sau khi Teacher đã confirm. |

**7.2 Class Report (Teacher view)**

| Sub-feature | Mô tả |
|---|---|
| F-07.2.1 Class Score Overview | Điểm trung bình lớp per skill per ca thi. Band distribution (số học viên ở mỗi band). |
| F-07.2.2 Student Ranking | Bảng xếp hạng học viên trong lớp theo tổng điểm (có thể ẩn tên nếu Tenant cấu hình). |
| F-07.2.3 Weak Students Alert | Danh sách học viên có điểm dưới ngưỡng (Tenant Admin cấu hình ngưỡng). |
| F-07.2.4 Before/After Comparison | So sánh điểm trung bình lớp giữa ca thi đầu và ca thi gần nhất → đo lường hiệu quả giảng dạy. |
| F-07.2.5 Score Distribution Histogram | Histogram phân phối điểm của lớp per skill. |

**7.3 Tenant Admin Dashboard**

| Sub-feature | Mô tả |
|---|---|
| F-07.3.1 Overview KPIs | Tổng học viên active, số ca thi trong tháng, tỷ lệ hoàn thành ca thi (completed/assigned). |
| F-07.3.2 Band Distribution | Pie/bar chart phân phối band toàn trường per skill. |
| F-07.3.3 Course Activity | Danh sách khóa học với: số học viên, số ca thi, tỷ lệ hoàn thành, band trung bình. |
| F-07.3.4 License Usage | Số seat đã dùng / tổng quota. Cảnh báo màu đỏ khi ≥ 90%. |
| F-07.3.5 Export Reports | Export báo cáo ra Excel/PDF (lớp, khóa học, toàn trường) để nộp cho lãnh đạo. |

**7.4 Item Analysis (Content Manager)**

| Sub-feature | Mô tả |
|---|---|
| F-07.4.1 Question Statistics | Per câu hỏi: tổng số lần xuất hiện, % đúng, % sai per đáp án (MCQ), % bỏ qua, average time spent. |
| F-07.4.2 Difficulty Index | Tính difficulty index (p-value) per câu: p < 0.3 = quá khó, p > 0.9 = quá dễ. Flag outliers. |
| F-07.4.3 Discrimination Index | Tính correlation giữa kết quả câu hỏi và tổng điểm (point-biserial). D < 0.2 = câu hỏi cần review. |
| F-07.4.4 Flagged Questions List | Tổng hợp câu hỏi cần review: quá khó, quá dễ, hoặc có discrimination thấp. |

---

### F-08: Vendor Management

**Cluster:** Platform Operations  
**Priority:** Essential  
**Actors:** Super Admin, Sales Team (partial), Support Staff (read)

**Mô tả gốc (brainstorm):** Quản lý tenant (tạo, tạm ngưng, cấu hình subdomain), seat-based license (Sales tạo thủ công), cảnh báo quota 80%/90%, khóa khi vượt.

**Chi tiết mở rộng:**

| Sub-feature | Mô tả |
|---|---|
| F-08.1 Tenant Lifecycle | Super Admin: tạo tenant (tên, subdomain slug, contact email), activate, suspend, reactivate, decommission. Suspend: tenant không login được nhưng dữ liệu vẫn giữ. |
| F-08.2 Tenant Configuration | Per tenant: timezone, branding (logo — optional), default language. |
| F-08.3 License Management | Sales tạo license: tenant_id, seat_count, expiry_date. Hệ thống track: seats_used (tổng học viên active trong tenant). Có thể tạo nhiều license lần lượt (extend sau khi hết hạn). |
| F-08.4 License Alerts | Automated email + dashboard indicator khi tenant dùng 80% seats, 90% seats. Alert license expiry 30 ngày và 7 ngày trước khi hết. |
| F-08.5 Tenant Usage Monitoring | Super Admin / Support Staff xem: số ca thi, số học viên, license usage, last activity timestamp per tenant. |
| F-08.6 Impersonation (Support) | Support Staff có thể view-as Tenant Admin (read-only impersonation) để debug vấn đề mà không cần credentials của tenant. Mỗi lần impersonate phải log lại. |

**Business rules liên quan:** BR-04, BR-05 (seat quota), BR-08 (license expiry)

---

### F-09: Sales Team Portal

**Cluster:** Customer Relationship  
**Priority:** Essential  
**Actors:** Sales Team

**Mô tả gốc (brainstorm):** Quản lý danh sách khách hàng, tạo license mới, gia hạn, điều chỉnh quota.

**Chi tiết mở rộng:**

| Sub-feature | Mô tả |
|---|---|
| F-09.1 Customer List | Danh sách tất cả tenant: tên trường/trung tâm, contact, trạng thái license (active/expiring/expired), seats used/total, ngày hết hạn. Search và filter. |
| F-09.2 Create License | Tạo license mới cho tenant: chọn tenant, nhập seat count, expiry date. Confirm → tenant ngay lập tức có quota mới. |
| F-09.3 Renew / Extend | Gia hạn license sắp hết: extend expiry date (seats giữ nguyên hoặc thay đổi). Lịch sử license history per tenant. |
| F-09.4 Adjust Quota | Tăng/giảm số seat (ví dụ: trường mua thêm slot giữa chừng). |
| F-09.5 License History | Per tenant: xem toàn bộ lịch sử license (tạo khi nào, ai tạo, bao nhiêu seat, expiry). |
| F-09.6 Expiry Alerts | Dashboard Sales: danh sách tenant hết hạn trong 30 ngày tới → ưu tiên contact. |

---

### F-10: Notification System

**Cluster:** Communication  
**Priority:** Essential  
**Actors:** Tất cả actors (receive); System (send)

**Mô tả gốc (brainstorm):** Email thông báo lịch thi, kết quả, nhắc nhở; push notification nếu có mobile Flutter.

**Chi tiết mở rộng:**

| Trigger | Recipients | Channel | Timing |
|---|---|---|---|
| Exam session published | Students enrolled | Email | Ngay khi publish |
| Exam starting soon | Students enrolled | Email | 24h và 1h trước |
| Exam results available (auto-score) | Student | Email | Ngay sau auto-score |
| Speaking/Writing results available | Student | Email | Sau Teacher confirm |
| Speaking/Writing pending review | Teacher / Exam Coordinator | Email | Ngay sau học viên submit |
| Review SLA warning | Teacher / Exam Coordinator | Email | [TBD — OI-03] |
| Seat quota 80% | Tenant Admin | Email | Khi vượt ngưỡng |
| Seat quota 90% | Tenant Admin | Email | Khi vượt ngưỡng |
| License expiry 30 days | Tenant Admin + Sales Team | Email | 30 ngày trước expiry |
| License expiry 7 days | Tenant Admin + Sales Team | Email | 7 ngày trước expiry |
| Account created (bulk) | Student | Email (optional) | Ngay sau tạo account |
| Push notifications | Students (if mobile) | FCM | Tương tự email triggers |

**Sub-features:**
- F-10.1 Email Template Management: Super Admin cấu hình email templates (hỗ trợ tiếng Việt và tiếng Anh).
- F-10.2 Notification Preferences: User có thể opt-out từng loại notification (trừ critical: account created, results).
- F-10.3 Delivery Logging: Log tất cả notifications đã gửi, trạng thái delivery, error nếu thất bại.

---

### F-11: Guest / Trial Flow

**Cluster:** Marketing & Acquisition  
**Priority:** Conditional  
**Actors:** Guest / Trial Taker

**Mô tả gốc (brainstorm):** Thi thử giới hạn (1 kỹ năng, số câu giới hạn), không cần tài khoản đầy đủ, xem kết quả basic.

**Chi tiết mở rộng:**

| Sub-feature | Mô tả |
|---|---|
| F-11.1 Trial Landing Page | Public page, không cần login. Giới thiệu hệ thống, nút "Thi thử ngay". |
| F-11.2 Trial Exam | Số kỹ năng và số câu: [TBD — OI-06]. Đề thi trial dùng bộ câu hỏi sample cố định (không từ ngân hàng tenant). |
| F-11.3 Trial Result | Hiển thị kết quả ước tính band. Basic feedback. Call-to-action: "Liên hệ để mua gói cho trường/trung tâm của bạn". |
| F-11.4 Lead Capture (Optional) | Tùy chọn: sau khi xem kết quả, Guest có thể để lại email để nhận tài liệu hoặc demo. [TBD — OI-06]. |
| F-11.5 Data Purge | Guest session data (đáp án, kết quả) được purge sau N ngày. N = [TBD — OI-07]. |

---

### F-12: Exam Integrity (Anti-cheat)

**Cluster:** Exam Security  
**Priority:** Essential  
**Actors:** System (enforces), Student (subject to), Exam Coordinator (reviews), Teacher (configures thresholds)

**Mô tả gốc (brainstorm):** Shuffle câu hỏi/đáp án, block copy-paste/right-click, fullscreen/kiosk lock, tab-switch detection, focus loss detection, violation handling, duplicate attempt control.

**Chi tiết mở rộng:**

**12.1 Pre-exam Integrity Setup**

| Sub-feature | Mô tả |
|---|---|
| F-12.1 Question Shuffle | Per exam session: randomize thứ tự câu hỏi trong mỗi part. Mỗi học viên nhận thứ tự khác nhau. Thứ tự được seed và lưu → consistent nếu resume. |
| F-12.2 Answer Shuffle | Per MCQ question: randomize thứ tự các đáp án lựa chọn. |
| F-12.3 Fullscreen Enforcement | Trước khi bắt đầu: yêu cầu fullscreen mode. Hiển thị warning và nút "Enter Fullscreen". Nếu từ chối → không thể bắt đầu thi. |

**12.2 During-exam Enforcement**

| Sub-feature | Mô tả |
|---|---|
| F-12.4 Tab/Window Switch Detection | Browser: detect `visibilitychange` event và `blur` event → log violation với timestamp. |
| F-12.5 Focus Loss Detection | Detect khi window mất focus → log violation. |
| F-12.6 Copy-Paste Block | Disable: Ctrl+C, Ctrl+V, right-click context menu. Disable text selection trong exam content area. |
| F-12.7 Navigation Block | Block browser back button, address bar access, F5 refresh (với grace: nếu refresh do mạng thì resume, không tính violation). |
| F-12.8 Violation Threshold & Response | Per ca thi, Teacher/Coordinator cấu hình: warning_threshold (số lần → hiện cảnh báo cho học viên), terminate_threshold (số lần → tự động nộp bài và lock). [TBD — OI-04: giá trị default]. |
| F-12.9 Violation Log | Tất cả violations được log: user_id, exam_session_id, violation_type, timestamp, count. Exam Coordinator xem log trong ca thi. |
| F-12.10 Kiosk Mode (Flutter Desktop) | Trên Flutter Desktop: hệ thống request OS-level focus lock (prevent Alt+Tab, Windows key). Mức độ lock phụ thuộc platform capability. |

**12.3 Post-exam Reporting**

| Sub-feature | Mô tả |
|---|---|
| F-12.11 Integrity Report | Per ca thi: danh sách học viên với số violations, type của violations. Flag học viên có violations vượt ngưỡng warning. |

**Business rules liên quan:** BR-05 (duplicate attempt), BR-06 (anti-cheat threshold), BR-09 (retake approval)

---

### F-13: Exam Continuity (Cross-cutting)

**Cluster:** Reliability  
**Priority:** Essential (#1 stated priority)  
**Actors:** Student, System

**Mô tả gốc (brainstorm):** Exam resume sau disconnect (timer tiếp tục chạy), Speaking record fail → lưu local draft + retry upload, state lưu server-side sau mỗi câu.

**Chi tiết mở rộng:**

| Sub-feature | Mô tả |
|---|---|
| F-13.1 Server-authoritative Timer | Timer chạy server-side từ khi học viên bắt đầu part. Client fetch `time_remaining` mỗi N giây. Khi reconnect: client nhận `time_remaining` hiện tại (không bao giờ reset). |
| F-13.2 Per-answer State Persistence | Mỗi khi học viên trả lời/thay đổi đáp án: gửi PATCH request lên server ngay lập tức. Server lưu vào exam_state record. Không dùng batch submit cuối bài. |
| F-13.3 Resume on Reconnect | Khi client reconnect: fetch exam_state → restore UI (answered questions highlighted, current question index, time remaining). Timer tiếp tục từ `time_remaining` server. |
| F-13.4 Offline Indicator | Client detect mất kết nối → hiển thị offline indicator. Không auto-submit, không panic. Retry connection silently. |
| F-13.5 Speaking Audio Buffer | Record Speaking audio vào local buffer (device memory/IndexedDB). Upload theo chunks (nếu connection ổn) hoặc batch sau khi reconnect. Retry logic: exponential backoff, tối đa N lần (TBD). |
| F-13.6 Speaking Partial Recovery | Nếu recording bị gián đoạn (microphone disconnect, network drop during upload): lưu partial recording. Sau reconnect: tiếp tục record hoặc upload phần đã record. Bài không bị null — partial được giữ và gửi cho teacher review. |
| F-13.7 Microphone Fail Handling | Nếu microphone không detect được khi bắt đầu Speaking: alert học viên (hướng dẫn check permission). Options: (1) retry microphone check, (2) signal proctor/coordinator, (3) skip Speaking (logged, Teacher biết). Skip Speaking không tự động = 0 điểm; Teacher review và xử lý thủ công. |
| F-13.8 Browser Crash Recovery | Nếu browser/app crash: khi học viên mở lại và login → hệ thống detect active exam session → auto-offer resume. Nếu trong window time còn hạn → resume. Nếu đã quá giờ → session closed, teacher review. |

---

## §4 — OUT of Scope

| # | Feature | Lý do loại trừ | Phiên bản tương lai |
|---|---|---|---|
| 1 | Payment / Billing tự động | Sales team quản lý payment thủ công ngoài hệ thống; không đủ ROI để xây payment gateway ở v1 | v2.0 — nếu Sales scale và cần tự phục vụ |
| 2 | Video proctoring (giám sát qua camera) | Yêu cầu hạ tầng lưu trữ video lớn, privacy concerns, độ phức tạp cao; kiosk mode + tab detection đủ cho v1 | v3.0 — nếu có yêu cầu từ tenant lớn |
| 3 | Cấp chứng chỉ APTIS chính thức | Không phải British Council; không có thẩm quyền cấp chứng chỉ. Hệ thống là mô phỏng/luyện thi, không thay thế kỳ thi chính thức | Never (giới hạn pháp lý) |
| 4 | Mobile native app tách biệt (standalone iOS/Android app) | Flutter cross-platform thay thế; không cần app store riêng biệt ngoài Flutter deployment | Không áp dụng — Flutter đã cover |
| 5 | Tích hợp LMS bên ngoài (Moodle, Canvas, Google Classroom) | Không có tenant nào yêu cầu ở giai đoạn đầu; use case niche; tăng độ phức tạp integration đáng kể | v2.0 — nếu tenant lớn yêu cầu |
| 6 | Marketplace đề thi (mua/bán giữa trường) | Mô hình kinh doanh khác; nội dung APTIS cần chuẩn hóa từ Vendor, không phải từ trường | v3.0+ — nếu có đủ content ecosystem |

---

## §5 — Technical Constraints

### 5.1 Client Framework

- **Framework:** Flutter (Dart) — cross-platform
- **Platform targets:** [TBD — OI-01]
  - **Đề xuất kiến trúc sơ bộ (TechLead sẽ xác nhận):**
    - Vendor Portal & Tenant Portal (Admin, Teacher, Coordinator, Viewer): Flutter Web — accessible từ bất kỳ browser nào, không cần cài app
    - Exam Client (Student): Flutter Desktop (Windows + macOS) cho phòng thi có máy tính + Flutter Web cho thi tại nhà + Flutter Mobile (iOS/Android) cho thi trên điện thoại
  - Kiến trúc Flutter cho phép share codebase lớn, chỉ adapt UI per platform
- **Note:** Kiosk mode capabilities phụ thuộc platform; Flutter Desktop có nhiều control hơn Web

### 5.2 Backend

- **Stack:** [TBD — TechLead quyết định]
- **Requirements từ product:**
  - REST API (primary) + WebSocket/SSE (for live exam monitoring)
  - Background job processing (AI scoring queue, notification queue)
  - Async processing cho audio STT và LLM scoring (không block HTTP response)
  - Multi-tenant data isolation (row-level security hoặc schema-per-tenant)
  - File upload handling (audio files, images, CSV imports)

### 5.3 Database

- **Type:** [TBD — TechLead quyết định]
- **Requirements:**
  - Relational DB phù hợp cho structured exam data, user/course relationships
  - Row-level security hoặc tenant_id column strategy cho multi-tenant isolation
  - ACID compliance cho exam state writes (BR-03: per-answer persistence)
  - JSON/JSONB support cho flexible question content schema

### 5.4 Hosting & Infrastructure

- **Cloud provider:** AWS / GCP / Azure (TechLead quyết định)
- **Deployment model:** Managed cloud (không on-premise cho v1)
- **Required services:**
  - Compute: containerized backend (Docker + orchestration)
  - Object storage: S3 hoặc GCS cho audio files, images, exports
  - CDN: cho audio/image delivery đến exam client (low latency critical cho Listening)
  - Managed database: RDS / Cloud SQL / Azure Database
  - Queue/async: SQS / Pub-Sub / Azure Service Bus cho scoring jobs
  - Email service: SendGrid / AWS SES / Firebase (TBD)
  - Push notifications: Firebase Cloud Messaging (nếu mobile)

### 5.5 AI Services

- **STT (Speech-to-Text):** [TBD — OI-02] Candidates: OpenAI Whisper API, Google Cloud Speech-to-Text, Azure Cognitive Services
- **LLM Scoring:** [TBD — OI-02] Candidates: Claude API (Anthropic), OpenAI GPT-4, Google Gemini
- **Integration pattern:** Async queue — khi học viên submit → jobs được queue → STT → LLM scoring → store draft → notify Teacher
- **Không train model riêng:** Sử dụng API của provider, không tự build model

### 5.6 Authentication & Security

- **Auth method:** Email + password với bcrypt hashing. JWT (access token: 15 phút, refresh token: 7 ngày rotating)
- **Tenant isolation:** Mỗi request phải validate tenant_id từ subdomain. Queries phải scoped theo tenant_id. Cross-tenant data access bị block ở application layer và nên có thêm DB-level enforcement.
- **HTTPS:** Bắt buộc toàn bộ — không có HTTP endpoint public
- **Password storage:** bcrypt (cost factor ≥ 12)
- **Sensitive data:** Không log passwords, không log JWT tokens. Audio recordings chỉ accessible qua pre-signed URLs (time-limited)
- **Exam integrity:** Client-side protections (fullscreen, copy-paste block) + server-side validation (timer, attempt count)

### 5.7 Compliance

- **Standard HTTPS + Data isolation:** Bắt buộc
- **Exam integrity (F-12):** Bắt buộc cho tính năng thi
- **Nghị định 13/2023/NĐ-CP (PDPA Việt Nam):** [TBD — TechLead xác định scope áp dụng]. Cần xem xét: consent khi tạo account, quyền xóa dữ liệu, data localization nếu dùng cloud provider nước ngoài
- **British Council:** Không có yêu cầu compliance chính thức (không phải authorized partner). Cần disclaimer rõ ràng trong UI: "Đây là phần mềm luyện thi mô phỏng, không phải kỳ thi APTIS chính thức"

---

## §6 — Business Rules

**BR-01: Multi-role per user**
Mỗi user trong một Tenant có thể được gán đồng thời nhiều role (Teacher, Exam Coordinator, Viewer). Permission của user = union (tổng hợp) tất cả permissions từ các roles đang active. Role được Tenant Admin gán hoặc thu hồi bất kỳ lúc nào.

**BR-02: Server-authoritative exam timer**
Timer cho mỗi part của bài thi chạy trên server kể từ thời điểm học viên bắt đầu part đó. Client hiển thị `time_remaining` lấy từ server. Khi học viên disconnect và reconnect, `time_remaining` được tính từ server (không reset, không pause). Khi `time_remaining = 0`, server tự động đóng part và advance sang part tiếp theo, bất kể client state.

**BR-03: Per-answer state persistence**
Mỗi lần học viên trả lời hoặc thay đổi đáp án cho một câu hỏi, đáp án đó phải được ghi vào server ngay lập tức (không batch submit). Bài thi không bao giờ submit toàn bộ một lần duy nhất vào cuối — chỉ có "finalize" call. Nếu session kết thúc bất ngờ, tất cả đáp án đã submit đều được giữ.

**BR-04: Seat quota enforcement — Warning thresholds**
Khi số học viên active trong tenant đạt 80% quota: hệ thống gửi email cảnh báo tới Tenant Admin và hiển thị indicator trên dashboard. Khi đạt 90%: gửi email cảnh báo lần 2. Alerts email cũng gửi tới Sales Team trong cả hai ngưỡng.

**BR-05: Seat quota enforcement — Block at 100%**
Khi số học viên active đã đạt 100% quota (seats_used >= seat_count): hệ thống từ chối tạo thêm account học viên mới hoặc enroll thêm học viên vào khóa học. Tenant Admin nhận thông báo rõ ràng về lý do block và hướng dẫn liên hệ Sales để nâng quota.

**BR-06: Duplicate exam attempt — One attempt per session**
Mỗi học viên chỉ được thực hiện một attempt (lần thi) cho mỗi ca thi. Hệ thống không cho phép học viên mở ca thi lần thứ hai nếu đã có attempt (hoàn thành hoặc đang dở). Attempt tính là "đã bắt đầu" kể từ khi học viên pass pre-exam checks và bắt đầu part đầu tiên.

**BR-07: Retake requires explicit approval**
Nếu học viên cần thi lại một ca thi (ví dụ: do sự cố kỹ thuật không phải lỗi học viên), Teacher hoặc Exam Coordinator phải explicitly approve retake trong hệ thống. Approve tạo một attempt mới. Không có cơ chế self-service retake cho học viên. Lý do approve được log.

**BR-08: Anti-cheat violation logging**
Mọi sự kiện vi phạm integrity (tab switch, focus loss, fullscreen exit) phải được log với: user_id, session_id, violation_type, timestamp, violation_count_at_time. Log này không thể bị xóa bởi Teacher hay Coordinator (chỉ Super Admin mới có thể purge theo data retention policy).

**BR-09: Anti-cheat threshold — Configurable per session**
Teacher/Coordinator cấu hình per ca thi: `warning_threshold` (số violations → hiển thị cảnh báo cho học viên) và `terminate_threshold` (số violations → auto-submit bài và lock session). Giá trị default: [TBD — OI-04]. Không thể thay đổi sau khi ca thi đã bắt đầu.

**BR-10: License expiry — Read-only mode**
Khi license của một Tenant hết hạn (`expiry_date < current_date`): tenant chuyển sang chế độ read-only. Nghĩa là: Tenant Admin và teachers chỉ xem được báo cáo và lịch sử. Không thể tạo ca thi mới, không thể enroll học viên mới, không thể thi. Email cảnh báo được gửi 30 ngày và 7 ngày trước khi hết hạn.

**BR-11: Speaking upload fail — No data loss**
Nếu upload audio Speaking thất bại (network error, server error): recording được giữ trong local buffer (device memory hoặc IndexedDB). Hệ thống retry tự động (exponential backoff). Bài thi không bị huỷ. Học viên không mất đáp án. Nếu retry tất cả thất bại: flag session để teacher review thủ công; học viên được thông báo.

**BR-12: Guest data retention**
Dữ liệu của Guest (trial taker) — bao gồm đáp án, kết quả thi thử — được purge tự động sau N ngày kể từ ngày thi. N = [TBD — OI-07]. Nếu Guest cung cấp email: email không được dùng cho mục đích marketing nếu không có explicit consent.

**BR-13: AI scoring — Draft state only**
Điểm do AI generate cho Writing và Speaking có trạng thái "draft" và KHÔNG được hiển thị cho học viên cho đến khi Teacher/Coordinator explicitly confirm (hoặc chỉnh sửa và confirm). Học viên nhận thông báo "kết quả đang chờ review" — không thấy điểm AI draft.

**BR-14: Question and answer randomization**
Trong mỗi exam session: thứ tự câu hỏi trong mỗi part được randomize per học viên. Thứ tự đáp án MCQ cũng được randomize per câu. Seed của randomization được lưu cùng exam_state để đảm bảo consistent khi resume sau disconnect.

**BR-15: Listening audio play count**
Số lần phát audio cho mỗi part Listening tuân theo chuẩn APTIS: Part A (1 lần), Part B (1 lần per conversation), Part C (1 lần), Part D (1 lần per monologue). Học viên không thể tua lại hoặc phát lại khi đã hết số lần. Số lần phát được cấu hình bởi Content Manager khi tạo câu hỏi, mặc định theo chuẩn APTIS.

---

## §7 — NFR Baselines

| ID | Characteristic | Target | Status | Owner |
|---|---|---|---|---|
| NFR-01 | API Response Time (p95) | [TBD] | TBD — TechLead estimate | TechLead |
| NFR-02 | Availability (overall) | [TBD] | TBD — TechLead estimate | TechLead |
| NFR-03 | Availability during exam hours | ≥ 99.9% trong khung giờ có ca thi active | Confirmed (priority requirement) | TechLead |
| NFR-04 | Concurrent exam takers | [TBD] | TBD — TechLead estimate based on tenant scale | TechLead |
| NFR-05 | Auto-score latency (Reading/Listening) | ≤ 2 phút sau submit | Confirmed | TechLead |
| NFR-06 | Exam state write latency | [TBD] — phải đủ nhanh để không block UX khi trả lời câu hỏi | TBD | TechLead |
| NFR-07 | Audio upload max file size | [TBD] — phụ thuộc độ dài Speaking part | TBD — cần spec Speaking duration | TechLead |
| NFR-08 | Audio CDN latency (Listening) | [TBD] — phải đủ thấp để audio playback mượt mà | TBD | TechLead |
| NFR-09 | AI scoring turnaround (Speaking/Writing) | [TBD] — cần SLA cho STT + LLM pipeline | TBD | TechLead |
| NFR-10 | Data retention — exam records | [TBD] | TBD — OI-07 | PM / Legal |
| NFR-11 | Data retention — audio recordings | [TBD] | TBD — OI-07 | PM / Legal |
| NFR-12 | Security — password hashing | bcrypt, cost factor ≥ 12 | Confirmed | TechLead |
| NFR-13 | Security — token expiry | Access token ≤ 15 phút; Refresh ≤ 7 ngày rotating | Confirmed | TechLead |
| **NFR-X** | **Exam continuity** | **Exam session KHÔNG được mất dữ liệu khi disconnect. Resume phải hoạt động trong 100% trường hợp còn trong exam window.** | **#1 Priority — Confirmed** | **TechLead** |

---

## §8 — Assumptions

**A-01:** Tất cả học viên có thiết bị đủ khả năng chạy Flutter (Desktop hoặc Web) và có microphone hoạt động khi tham gia ca thi có phần Speaking. Nếu không có microphone, học viên phải signal proctor — hệ thống không auto-assign 0 điểm.

**A-02:** Kỳ thi APTIS chính thức không thay đổi cấu trúc (số kỹ năng, số part, dạng câu hỏi) trong vòng đời v1 của sản phẩm. Nếu British Council thay đổi cấu trúc, cần update question bank và exam templates.

**A-03:** Mỗi tenant (trường/trung tâm) có đủ giáo viên có thể review Speaking/Writing trong thời gian chấp nhận được. Hệ thống không tự hoàn thành nếu không có human review — scoring pipeline phụ thuộc human action.

**A-04:** Vendor quản lý toàn bộ ngân hàng câu hỏi. Tenant không tạo câu hỏi riêng trong v1. Nếu có nhu cầu này, đây là feature v2.

**A-05:** Mạng internet tại địa điểm thi đủ ổn định để audio upload Speaking hoạt động trong vài phút sau khi record. Exam Continuity features xử lý trường hợp mất kết nối ngắn, không phải mất kết nối hoàn toàn suốt ca thi.

**A-06:** Payment giữa Vendor và Tenant được xử lý hoàn toàn ngoài hệ thống. Hệ thống chỉ cần biết: tenant có license hợp lệ hay không — không cần biết invoice hay payment status.

**A-07:** Một tenant subdomain (`slug.aptis-lms.vn`) mapping 1-1 với một tenant. Không có trường hợp 1 tenant dùng nhiều subdomain hoặc 1 subdomain shared giữa nhiều tenant.

**A-08:** Content Manager tại Vendor đủ domain knowledge APTIS để tạo câu hỏi đúng chuẩn. Hệ thống không validate câu hỏi về mặt pedagogical — chỉ validate về mặt kỹ thuật (đủ fields, có audio nếu cần, v.v.).

**A-09:** Dữ liệu âm thanh Speaking của học viên được lưu trên cloud. Học viên và trường/trung tâm đồng ý với điều này khi ký hợp đồng với Vendor (không cần implement consent flow riêng trong app nếu đã có trong hợp đồng).

**A-10:** Ruby-band mapping (raw score → APTIS band A1-C) là cố định và được Vendor Content Manager cấu hình. Hệ thống không tự tính toán band conversion — dùng mapping table do Vendor cung cấp.

---

## §9 — Open Items

**OI-01: Flutter platform split**
- **Câu hỏi:** Side nào (Vendor Portal, Tenant Portal, Exam Client) deploy trên platform nào (Flutter Web, Flutter Desktop Windows, Flutter Desktop macOS, Flutter Mobile iOS/Android)?
- **Ai trả lời:** TechLead agent — kiến trúc client
- **Impact nếu chưa giải quyết:** Không thể estimate effort frontend, không biết cần bao nhiêu build targets, ảnh hưởng đến kiosk mode capability
- **Gợi ý initial:** Web cho admin panels, Desktop + Web cho exam client, Mobile là v1.5

**OI-02: AI provider selection**
- **Câu hỏi:** (1) STT: OpenAI Whisper vs Google Cloud Speech-to-Text vs Azure Cognitive? (2) LLM Scoring: Claude API vs GPT-4 vs Gemini? (3) Cần tiếng Việt support cho feedback?
- **Ai trả lời:** TechLead agent — performance benchmark, cost, language support
- **Impact nếu chưa giải quyết:** Không thể implement F-04.4, F-04.5

**OI-03: Speaking/Writing scoring SLA**
- **Câu hỏi:** Teacher phải review và confirm điểm Writing/Speaking trong bao lâu kể từ khi học viên submit? Học viên sẽ chờ kết quả bao lâu là acceptable?
- **Ai trả lời:** Business stakeholder (Vendor) + representative Tenant
- **Impact nếu chưa giải quyết:** Không thể implement SLA reminder notification (F-10), không thể set expectations với Tenant

**OI-04: Anti-cheat default thresholds**
- **Câu hỏi:** Default values cho warning_threshold và terminate_threshold (số violations) là bao nhiêu? Tenant có thể override không? Range cho phép là gì?
- **Ai trả lời:** Vendor business decision
- **Impact nếu chưa giải quyết:** Không thể implement F-12.8 với giá trị cụ thể, không thể test

**OI-05: NFR numeric targets**
- **Câu hỏi:** API response time (p95), overall uptime SLA, concurrent exam takers (max expected), exam state write latency — các con số cụ thể?
- **Ai trả lời:** TechLead agent — estimate based on load model và architecture
- **Impact nếu chưa giải quyết:** Không thể design infrastructure, không thể validate system trước go-live

**OI-06: Guest trial limits**
- **Câu hỏi:** (1) Trial cho phép thi kỹ năng/part nào? Bao nhiêu câu? (2) Lead capture email có bắt buộc không? (3) Trial data có dùng cho remarketing không?
- **Ai trả lời:** Vendor marketing/product decision
- **Impact nếu chưa giải quyết:** Không thể implement F-11 với đủ chi tiết

**OI-07: Data retention policy**
- **Câu hỏi:** (1) Giữ exam logs (đáp án, kết quả) bao lâu? (2) Giữ audio recordings Speaking bao lâu? (3) Guest data purge sau bao nhiêu ngày? (4) Có yêu cầu data localization (server ở Việt Nam) theo NĐ 13/2023 không?
- **Ai trả lời:** PM + Legal
- **Impact nếu chưa giải quyết:** Không thể estimate storage costs, không thể design data purge jobs, có thể có rủi ro compliance

**OI-08: Exam integrity edge cases — deep dive**
- **Câu hỏi:** Nhiều edge case phức tạp cần được xử lý cụ thể: (a) Network drop mid-Speaking record: record bị cắt giữa chừng → upload phần nào? (b) Audio device disconnect trong khi đang record Speaking — có retry attempt không? (c) Browser crash và reopen trong cùng phiên: restore state như thế nào? (d) Exam Coordinator force-submit bài học viên đang record Speaking: audio đang record có được lưu không? (e) Timer hết giờ khi đang record Speaking: auto-cut và upload recording đến lúc đó? (f) Máy tính tắt đột ngột (power off) trong ca thi: mọi thứ trong local buffer mất hết — SLA cho trường hợp này?
- **Ai trả lời:** TechLead (technical resolution) + Business stakeholder (policy decisions)
- **Impact nếu chưa giải quyết:** F-13 (Exam Continuity) có thể implement thiếu sót, gây mất dữ liệu học viên trong edge cases
