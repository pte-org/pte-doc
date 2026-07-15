# SRS §3.4 — Yêu cầu về cơ sở dữ liệu
## APTIS LMS
**Phiên bản:** 1.0 | **Ngày:** 2026-06-16 | **Trạng thái:** BẢN THẢO

---

## 3.4.1 Định nghĩa thực thể

Tất cả các bảng trong phần phạm vi đối tượng thuê của lược đồ đều bao gồm `tenant_id UUID NOT NULL REFERENCES tenants(id)`. Mọi truy vấn cơ sở dữ liệu trong API phụ trợ phải bao gồm `WHERE tenant_id = {resolved_id}` (hoặc mức tương đương ở cấp lược đồ) do phần mềm trung gian thực thi (FR-03, DC-02).

---

### tenants

Hồ sơ gốc cho từng trường, trung tâm đào tạo (khách hàng B2B).

| Column | Type | Constraint | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| slug | VARCHAR(64) | UNIQUE NOT NULL | Mã định danh tên miền phụ an toàn cho URL; bất biến sau lần kích hoạt đầu tiên |
| display_name | VARCHAR(255) | NOT NULL | Tên tổ chức mà con người có thể đọc được |
| contact_email | VARCHAR(255) | NOT NULL | Người liên hệ chính để nhận thông báo hệ thống |
| status | ENUM | NOT NULL | `pending / active / suspended / deactivated` |
| timezone | VARCHAR(64) | NOT NULL DEFAULT 'Asia/Ho_Chi_Minh' | Chuỗi múi giờ IANA |
| logo_url | VARCHAR(512) | | URL CDN tùy chọn để xây dựng thương hiệu cổng thông tin đối tượng thuê |
| created_at | TIMESTAMP | NOT NULL | |
| updated_at | TIMESTAMP | NOT NULL | |

**Quy tắc kinh doanh:** `slug` phải là duy nhất trên toàn cầu đối với tất cả đối tượng thuê. Sau khi được thiết lập và kích hoạt, `slug` là bất biến (việc thay đổi nó sẽ phá vỡ định tuyến tên miền phụ và tất cả các liên kết được đánh dấu trang cho người dùng thuê).

---

### licenses

Giấy phép dựa trên chỗ ngồi do Nhóm bán hàng cấp cho người thuê (FR-73).

| Column | Type | Constraint | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| tenant_id | UUID | FK → tenants NOT NULL | |
| seat_count | INTEGER | NOT NULL CHECK (seat_count >= 1) | Tài khoản sinh viên hoạt động tối đa |
| expires_at | DATE | NOT NULL | Ngày kết thúc hiệu lực của giấy phép |
| created_by | UUID | FK → users NOT NULL | Người dùng Nhóm bán hàng đã tạo giấy phép này |
| created_at | TIMESTAMP | NOT NULL | |
| last_modified_by | UUID | FK → users | |
| last_modified_at | TIMESTAMP | | |
| status | ENUM | NOT NULL | `active / expired / superseded` |

**Dẫn xuất:** Hạn ngạch hiệu quả của đối tượng thuê là `seat_count` tính từ giấy phép gần đây nhất trong đó `status = active AND expires_at >= CURRENT_DATE`. Hồ sơ không bao giờ bị xóa (nhật ký kiểm tra bất biến theo FR-81).

---

### users

Tất cả tài khoản người dùng ở cả hai phía Nhà cung cấp và Bên thuê. Người dùng phía nhà cung cấp có `tenant_id = NULL`.

| Column | Type | Constraint | PII | Notes |
|--------|------|-------------|-----|-------|
| id | UUID | PK | | |
| tenant_id | UUID | FK → tenants | | NULL dành cho người dùng phía nhà cung cấp (Quản trị viên cấp cao, Người quản lý nội dung, Nhân viên hỗ trợ, Nhóm bán hàng) |
| email | VARCHAR(255) | NOT NULL | PII | Duy nhất cho mỗi `tenant_id` (hoặc trên toàn cầu đối với người dùng của nhà cung cấp); được sử dụng làm thông tin đăng nhập |
| password_hash | VARCHAR(255) | NOT NULL | Credential | hàm băm bcrypt có hệ số chi phí ≥ 12 (NFR-12); chưa bao giờ đăng nhập hoặc xuất khẩu |
| full_name | VARCHAR(255) | NOT NULL | PII | |
| status | ENUM | NOT NULL | | `active / suspended / disabled` |
| email_bounced | BOOLEAN | NOT NULL DEFAULT false | | Đặt đúng khi gửi lại (FR-87); cổng gửi email trong tương lai |
| force_password_change | BOOLEAN | NOT NULL DEFAULT false | | Đúng đối với các tài khoản được tạo hàng loạt; kích hoạt dòng FR-06 |
| created_at | TIMESTAMP | NOT NULL | | |
| last_login_at | TIMESTAMP | | | Cập nhật mỗi lần xác thực thành công |

**Xử lý PII:** `email` và `full_name` được mã hóa ở trạng thái lưu trữ thông qua mã hóa cấp cơ sở dữ liệu. Không có trường nào xuất hiện trong đầu ra nhật ký ứng dụng. `password_hash` không bao giờ được trả về qua API.

---

### user_roles

Phân công vai trò RBAC - một hàng cho mỗi vai trò được cấp cho người dùng (FR-04).

| Column | Type | Constraint | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| user_id | UUID | FK → users NOT NULL | |
| role | ENUM | NOT NULL | `super_admin / content_manager / support_staff / sales / tenant_admin / teacher / exam_coordinator / viewer / student / guest` |
| tenant_id | UUID | FK → tenants | NULL cho vai trò phía nhà cung cấp |
| assigned_by | UUID | FK → users NOT NULL | |
| assigned_at | TIMESTAMP | NOT NULL | |
| revoked_at | TIMESTAMP | | NULL = vai trò hiện đang hoạt động |

**Tính toán quyền:** Quyền hiệu quả = kết hợp tất cả các hàng `user_roles` cho người dùng trong đó `revoked_at IS NULL`. Các vai trò phía nhà cung cấp (`super_admin`, `content_manager`, `support_staff`, `sales`) phải luôn có `tenant_id = NULL`; Các vai trò phía đối tượng thuê phải có `tenant_id` không phải NULL.

---

### refresh_tokens

Kho lưu trữ mã thông báo làm mới phía máy chủ - cần thiết để hỗ trợ thu hồi mã thông báo (FR-02, FR-07, NFR-13).

| Column | Type | Constraint | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| user_id | UUID | FK → users NOT NULL | |
| token_hash | VARCHAR(255) | NOT NULL | hàm băm bcrypt của giá trị mã thông báo thô |
| issued_at | TIMESTAMP | NOT NULL | |
| expires_at | TIMESTAMP | NOT NULL | TTL = 7 ngày kể từ `issued_at` |
| revoked_at | TIMESTAMP | | NULL = mã thông báo hợp lệ |
| replaced_by | UUID | FK → refresh_tokens | Đặt khi mã thông báo này được xoay (FR-02) |

**Triển khai:** Không thể thu hồi mã thông báo làm mới JWT không trạng thái thuần túy. Bảng này cung cấp khả năng thu hồi theo yêu cầu của FR-07 (buộc đăng xuất). Trên mỗi vòng quay mã thông báo (FR-02), `revoked_at` của hàng cũ được đặt và `replaced_by` trỏ đến hàng mới.

---

### courses

Vùng chứa học tập có giới hạn thời gian trong một đối tượng thuê (FR-44).

| Column | Type | Constraint | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| tenant_id | UUID | FK → tenants NOT NULL | |
| name | VARCHAR(255) | NOT NULL | |
| description | TEXT | | |
| start_date | DATE | NOT NULL | |
| end_date | DATE | NOT NULL CHECK (end_date > start_date) | |
| status | ENUM | NOT NULL | `scheduled / active / ended` (được tính từ ngày) |
| created_by | UUID | FK → users NOT NULL | |
| created_at | TIMESTAMP | NOT NULL | |

---

### groups

Các phân khu được đặt tên của khóa học do Giáo viên được chỉ định quản lý (FR-45).

| Column | Type | Constraint | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| tenant_id | UUID | FK → tenants NOT NULL | |
| course_id | UUID | FK → courses NOT NULL | |
| name | VARCHAR(255) | NOT NULL | ví dụ: "Buổi sáng lớp 10A" |
| created_by | UUID | FK → users NOT NULL | |
| created_at | TIMESTAMP | NOT NULL | |

---

### group_teachers

Phân công người dùng Giáo viên vào Nhóm (FR-45).

| Column | Type | Constraint | Notes |
|--------|------|-------------|-------|
| group_id | UUID | FK → groups NOT NULL | |
| teacher_user_id | UUID | FK → users NOT NULL | Phải có vai trò `teacher` trong cùng một đối tượng thuê |
| assigned_by | UUID | FK → users NOT NULL | |
| assigned_at | TIMESTAMP | NOT NULL | |
| **PRIMARY KEY** | (group_id, teacher_user_id) | | PK tổng hợp ngăn chặn các bài tập trùng lặp |

---

### enrollments

Tư cách thành viên của sinh viên trong một nhóm khóa học - thúc đẩy số lượng chỗ ngồi và khả năng đủ điều kiện tham gia kỳ thi (FR-46, FR-47, FR-50, FR-51).

| Column | Type | Constraint | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| tenant_id | UUID | FK → tenants NOT NULL | |
| student_user_id | UUID | FK → users NOT NULL | |
| group_id | UUID | FK → groups NOT NULL | |
| course_id | UUID | FK → courses NOT NULL | Không chuẩn hóa khỏi nhóm để đạt hiệu quả truy vấn |
| enrolled_at | TIMESTAMP | NOT NULL | |
| enrolled_by | UUID | FK → users NOT NULL | |
| unenrolled_at | TIMESTAMP | | NULL = hiện đang theo học |
| seat_counted | BOOLEAN | NOT NULL DEFAULT true | Đúng = lượt đăng ký này được tính vào `seats_used` |

**Tính toán chỗ ngồi:** `seats_used = COUNT(*) FROM enrollments WHERE tenant_id = X AND unenrolled_at IS NULL AND seat_counted = true`.

Các bản ghi lịch sử được lưu giữ khi `unenrolled_at` được đặt (không bị xóa), do đó các bản ghi bài kiểm tra trước đây vẫn được liên kết.

---

### questions

Các mục câu hỏi riêng lẻ trong ngân hàng câu hỏi APTIS — Do nhà cung cấp quản lý (FR-09, FR-14).

| Column | Type | Constraint | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| version | INTEGER | NOT NULL DEFAULT 1 | Gia tăng chỉnh sửa sau khi sử dụng trong một phiên hoàn thành |
| parent_id | UUID | FK → questions | NULL cho v1; phiên bản 2+ trỏ tới v1 |
| is_current | BOOLEAN | NOT NULL DEFAULT true | Chỉ có một phiên bản trên mỗi chuỗi gốc có `is_current = true` |
| is_immutable | BOOLEAN | NOT NULL DEFAULT false | Đặt đúng khi được liên kết với một phiên hoàn thành |
| skill | ENUM | NOT NULL | `reading / writing / listening / speaking` |
| part | VARCHAR(4) | NOT NULL | `A / B / C / D / E` |
| question_type | ENUM | NOT NULL | `mcq / match / gap_fill / short_answer / essay / speaking_prompt` |
| content | JSONB | NOT NULL | Nội dung câu hỏi, lựa chọn, hình ảnh tham khảo |
| answer_key | JSONB | | Bắt buộc đối với `mcq / match / gap_fill`; NULL cho các loại do con người chấm điểm |
| rubric_criteria | JSONB | | Bắt buộc đối với `essay / speaking_prompt` |
| max_play_count | INTEGER | | Chỉ nghe; NULL cho các kỹ năng khác |
| audio_asset_id | UUID | FK → assets | |
| image_asset_ids | UUID[] | | Dành cho phần Nói Phần B (1 ảnh) và Phần D (2 ảnh) |
| difficulty_tag | ENUM | NOT NULL | `easy / medium / hard` |
| topic_tags | TEXT[] | NOT NULL DEFAULT '{}' | |
| status | ENUM | NOT NULL DEFAULT 'draft' | `draft / active / archived` |
| created_by | UUID | FK → users NOT NULL | Trình quản lý nội dung |
| created_at | TIMESTAMP | NOT NULL | |
| updated_at | TIMESTAMP | NOT NULL | |

---

### assets

Các tập tin được quản lý trong hệ thống: âm thanh, hình ảnh, ghi âm giọng nói, xuất báo cáo (SI-01).

| Column | Type | Constraint | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| asset_type | ENUM | NOT NULL | `listening_audio / speaking_image / recording_audio / report_export` |
| storage_key | VARCHAR(1024) | NOT NULL | Khóa đối tượng Cloud Storage (đường dẫn S3/GCS) |
| cdn_url | VARCHAR(1024) | | URL có mặt trước CDN để phân phối; NULL cho tài sản cá nhân |
| filename | VARCHAR(255) | NOT NULL | Tên tập tin gốc |
| size_bytes | BIGINT | NOT NULL | |
| mime_type | VARCHAR(128) | NOT NULL | |
| uploaded_by | UUID | FK → users | NULL cho nội dung do hệ thống tạo |
| tenant_id | UUID | FK → tenants | NULL cho tài sản do nhà cung cấp quản lý |
| created_at | TIMESTAMP | NOT NULL | |
| expires_at | TIMESTAMP | | NULL = vĩnh viễn; thiết lập cho các tập tin xuất tạm thời |

---

### exam_templates

Bộ câu hỏi được đặt tên, có thể sử dụng lại được sắp xếp theo kỹ năng và bộ phận — Do nhà cung cấp quản lý (FR-12).

| Column | Type | Constraint | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| name | VARCHAR(255) | NOT NULL | |
| description | TEXT | | |
| skill_sequence | JSONB | NOT NULL | Danh sách thứ tự các kỹ năng và thời gian nghỉ giữa các kỹ năng |
| questions | JSONB | NOT NULL | Bản đồ: `{skill: {part: [question_ids]}}` |
| shuffle_enabled | BOOLEAN | NOT NULL DEFAULT true | Mỗi BR-14 |
| created_by | UUID | FK → users NOT NULL | Trình quản lý nội dung |
| status | ENUM | NOT NULL DEFAULT 'draft' | `draft / published / archived` |
| created_at | TIMESTAMP | NOT NULL | |

**Ràng buộc về tính đầy đủ:** Không thể đặt mẫu thành `published` trừ khi `questions` chứa các mục nhập cho tất cả các phần bắt buộc: Đọc (A, B, C, D), Viết (A, B, C), Nghe (A, B, C, D), Nói (A, B, C, D, E). Việc xác thực này được thực thi ở lớp ứng dụng (FR-12).

---

### exam_sessions

Triển khai bài kiểm tra theo lịch trình do Giáo viên hoặc Điều phối viên bài kiểm tra tạo (FR-37).

| Column | Type | Constraint | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| tenant_id | UUID | FK → tenants NOT NULL | |
| course_id | UUID | FK → courses NOT NULL | |
| group_id | UUID | FK → groups | NULL nếu người tham gia được chọn riêng lẻ |
| template_id | UUID | FK → exam_templates NOT NULL | |
| name | VARCHAR(255) | NOT NULL | |
| start_time | TIMESTAMP | NOT NULL | Cửa sổ phiên mở ra |
| end_time | TIMESTAMP | NOT NULL CHECK (end_time > start_time) | Cửa sổ phiên đóng lại |
| status | ENUM | NOT NULL DEFAULT 'scheduled' | `scheduled / active / closed / cancelled` |
| anti_cheat_config | JSONB | NOT NULL | `{shuffle: bool, warning_threshold: int, terminating_threshold: int}` |
| created_by | UUID | FK → users NOT NULL | |
| created_at | TIMESTAMP | NOT NULL | |
| closed_by | UUID | FK → users | NULL = tự động đóng theo bộ đếm thời gian |
| closed_at | TIMESTAMP | | NULL cho đến khi phiên đóng |

---

### session_participants

Học sinh đủ điều kiện tham gia một kỳ thi cụ thể (FR-37).

| Column | Type | Constraint | Notes |
|--------|------|-------------|-------|
| session_id | UUID | FK → exam_sessions NOT NULL | |
| student_user_id | UUID | FK → users NOT NULL | |
| added_by | UUID | FK → users NOT NULL | |
| added_at | TIMESTAMP | NOT NULL | |
| **PRIMARY KEY** | (session_id, student_user_id) | | |

---

### exam_attempts

Một học sinh thực hiện một buổi thi (FR-17, FR-26).

| Column | Type | Constraint | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| session_id | UUID | FK → exam_sessions NOT NULL | |
| student_user_id | UUID | FK → users NOT NULL | |
| tenant_id | UUID | FK → tenants NOT NULL | Không chuẩn hóa cho phạm vi truy vấn |
| attempt_number | INTEGER | NOT NULL DEFAULT 1 | 1 cho lần đầu tiên; 2+ cho thi lại (FR-43) |
| status | ENUM | NOT NULL DEFAULT 'not_started' | `not_started / in_progress / submitted / force_submitted` |
| shuffle_seed | BIGINT | | Hạt giống ngẫu nhiên cho xáo trộn câu hỏi/câu trả lời (FR-93); thiết lập ở lần thử tạo |
| started_at | TIMESTAMP | | Đặt thời điểm trạng thái → in_progress |
| submitted_at | TIMESTAMP | | Đặt thời điểm trạng thái → submitted hoặc force_submitted |
| force_submit_by | UUID | FK → users | NULL nếu sinh viên nộp |
| force_submit_reason | TEXT | | Bắt buộc khi cài đặt force_submit_by |
| force_submit_on_crash | BOOLEAN | NOT NULL DEFAULT false | Cờ FR-111 |
| terminated_by_violation | BOOLEAN | NOT NULL DEFAULT false | Cờ FR-100 |
| current_skill | ENUM | | `reading / writing / listening / speaking`; NULL nếu chưa bắt đầu |
| current_part | VARCHAR(4) | | Phần hiện tại đang được tiến hành |
| created_at | TIMESTAMP | NOT NULL | |

---

### exam_state

Bản ghi câu trả lời cho mỗi câu hỏi cho một lần thử đang diễn ra — thay thế việc gửi hàng loạt (FR-105, DC-05).

| Column | Type | Constraint | Notes |
|--------|------|-------------|-------|
| attempt_id | UUID | FK → exam_attempts NOT NULL | |
| question_id | UUID | FK → questions NOT NULL | |
| answer_value | JSONB | | Câu trả lời của học sinh ở dạng câu hỏi cụ thể |
| saved_at | TIMESTAMP | NOT NULL | Dấu thời gian của máy chủ của lần lưu cuối cùng; dấu thời gian của khách hàng không đáng tin cậy |
| was_skipped | BOOLEAN | NOT NULL DEFAULT false | Đúng nếu học sinh bỏ qua một cách rõ ràng |
| **PRIMARY KEY** | (attempt_id, question_id) | | Được nâng cấp trên mỗi PATCH; một hàng cho mỗi câu hỏi cho mỗi lần thử |

**Ghi chú thực hiện:** Bảng này là bảng có tần suất ghi cao nhất trong hệ thống. Mỗi lựa chọn MCQ và nhập văn bản đều tạo ra một bản cập nhật tại đây (FR-105). Nó yêu cầu lập chỉ mục tối ưu trên `(attempt_id)` và đường dẫn ghi phải đáp ứng các mục tiêu về độ trễ NFR-06.

---

### part_timers

Trạng thái bộ hẹn giờ phía máy chủ cho mỗi lần thử trên mỗi phần — thực thi DC-04 (bộ hẹn giờ được máy chủ ủy quyền).

| Column | Type | Constraint | Notes |
|--------|------|-------------|-------|
| attempt_id | UUID | FK → exam_attempts NOT NULL | |
| skill | ENUM | NOT NULL | |
| part | VARCHAR(4) | NOT NULL | |
| part_duration_seconds | INTEGER | NOT NULL | Từ `exam_template.skill_sequence` |
| started_at | TIMESTAMP | NOT NULL | Thời gian máy chủ khi phần bắt đầu (FR-19) |
| extended_by_seconds | INTEGER | NOT NULL DEFAULT 0 | Gia hạn thời gian điều phối tích lũy (FR-40) |
| completed_at | TIMESTAMP | | NULL trong khi một phần đang được tiến hành |
| **PRIMARY KEY** | (attempt_id, skill, part) | | |

**Công thức tính giờ:** `time_remaining = part_duration_seconds + extended_by_seconds − (CURRENT_TIMESTAMP − started_at)`. Khi `time_remaining ≤ 0` máy chủ sẽ đóng phần (FR-19) và đặt `completed_at`.

---

### attempt_results

Kết quả ghi điểm cuối cùng cho mỗi kỹ năng trong mỗi lần thử (FR-27, FR-28, FR-33).

| Column | Type | Constraint | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| attempt_id | UUID | FK → exam_attempts NOT NULL | |
| skill | ENUM | NOT NULL | |
| raw_score | DECIMAL(6,2) | | Đối với kỹ năng tự động ghi điểm |
| band | ENUM | | `A1 / A2 / B1 / B2 / C / pending / maps_error / not_attempted` |
| status | ENUM | NOT NULL DEFAULT 'pending' | `pending / available / withheld` |
| scored_by | ENUM | | `auto / human` |
| scored_at | TIMESTAMP | | |
| final_score_per_criterion | JSONB | | Dành cho Viết/Nói: `{criterion_name: score}` |
| final_feedback_narrative | TEXT | PII | Phản hồi được giáo viên xác nhận (FR-33) |
| confirmed_by | UUID | FK → users | Giáo viên xác nhận điểm |
| confirmed_at | TIMESTAMP | | |

---

### ai_score_drafts

Điểm nháp do AI tạo cho môn Viết và Nói — học sinh không thể nhìn thấy cho đến khi được xác nhận (FR-31, BR-13).

| Column | Type | Constraint | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| attempt_id | UUID | FK → exam_attempts NOT NULL | |
| skill | ENUM | NOT NULL | `writing / speaking` |
| part | VARCHAR(4) | NOT NULL | |
| draft_score_per_criterion | JSONB | | Đầu ra LLM: `{criterion: score}` |
| draft_band_estimate | ENUM | | A1–C |
| draft_feedback_narrative | TEXT | | Văn bản phản hồi do LLM tạo |
| stt_transcript | TEXT | PII | Chỉ nói; đầu ra từ API STT (FR-30) |
| stt_status | ENUM | | `pending / completed / failed` |
| llm_status | ENUM | | `pending / completed / failed` |
| created_at | TIMESTAMP | NOT NULL | |

**Kiểm soát quyền truy cập:** không bao giờ được trả lại `draft_score_per_criterion`, `draft_band_estimate` và `draft_feedback_narrative` trong bất kỳ phản hồi API nào đối với mã thông báo JWT vai trò của sinh viên. Chỉ những vai trò Giáo viên, Điều phối viên bài kiểm tra và Quản trị viên người thuê (BR-13) mới có thể truy cập được chúng.

---

### speaking_recordings

Tham chiếu tệp âm thanh cho mỗi lần thử cho mỗi phần (FR-23, FR-108, FR-109).

| Column | Type | Constraint | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| attempt_id | UUID | FK → exam_attempts NOT NULL | |
| part | VARCHAR(4) | NOT NULL | A / B / C / D / E |
| asset_id | UUID | FK → assets NOT NULL | Trỏ tới tệp đã tải lên trong Cloud Storage |
| duration_seconds | DECIMAL(6,2) | | |
| is_partial | BOOLEAN | NOT NULL DEFAULT false | Đúng nếu quá trình ghi bị gián đoạn (FR-109) |
| upload_status | ENUM | NOT NULL DEFAULT 'pending' | `pending / uploaded / failed` |
| local_buffer_cleared | BOOLEAN | NOT NULL DEFAULT false | Đặt đúng khi máy khách xác nhận bộ đệm cục bộ đã được xóa sau khi tải lên |
| created_at | TIMESTAMP | NOT NULL | |

---

### violation_events

Nhật ký vi phạm chống gian lận bất biến — không cho phép XÓA hoặc CẬP NHẬT lớp ứng dụng (FR-101, DC-10).

| Column | Type | Constraint | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| attempt_id | UUID | FK → exam_attempts NOT NULL | |
| violation_type | ENUM | NOT NULL | `tab_switch / focus_loss / fullscreen_exit / copy_paste_attempt` |
| occurred_at | TIMESTAMP | NOT NULL | |
| cumulative_count | INTEGER | NOT NULL | Số vi phạm tại thời điểm sự kiện này được ghi lại |
| action_taken | ENUM | NOT NULL | `none / warning / terminate` |

**Thực thi tính bất biến:** API phụ trợ không được hiển thị bất kỳ điểm cuối XÓA hoặc CẬP NHẬT nào cho bảng này. Thanh lọc hàng loạt quản trị viên cấp cao (theo chính sách lưu giữ NFR-10/NFR-11) là đường dẫn xóa được phép duy nhất, được thực thi dưới dạng công việc đã lên lịch chứ không phải lệnh gọi API đặc biệt.

---

### exam_events

Nhật ký kiểm tra tất cả các hoạt động can thiệp của Điều phối viên và Giáo viên trong các buổi thi (FR-40, FR-41, FR-42, FR-43).

| Column | Type | Constraint | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| session_id | UUID | FK → exam_sessions NOT NULL | |
| attempt_id | UUID | FK → exam_attempts | NULL cho các sự kiện cấp phiên (ví dụ: phiên đã đóng) |
| event_type | ENUM | NOT NULL | `time_extended / force_submit / session_closed / retake_approved / retake_created` |
| actor_user_id | UUID | FK → users NOT NULL | Điều phối viên hoặc Giáo viên thực hiện hành động |
| reason | TEXT | NOT NULL | Trường lý do bắt buộc; chuỗi trống bị từ chối ở lớp API |
| metadata | JSONB | | Ngữ cảnh bổ sung (ví dụ: `{"extension_minutes": 5}`) |
| created_at | TIMESTAMP | NOT NULL | |

---

### notification_log

Bản ghi mọi nỗ lực thông báo do hệ thống gửi (FR-87).

| Column | Type | Constraint | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| recipient_user_id | UUID | FK → users | NULL cho khách/người nhận ẩn danh |
| notification_type | ENUM | NOT NULL | `exam_published / result_available / review_pending / seat_warning / license_expiry / account_created / score_confirmed / review_sla / license_renewed` |
| channel | ENUM | NOT NULL | `email / push` |
| sent_at | TIMESTAMP | NOT NULL | |
| delivery_status | ENUM | NOT NULL | `sent / failed / bounced` |
| provider_response | JSONB | | Phản hồi API thô từ nhà cung cấp email/push |
| retry_count | INTEGER | NOT NULL DEFAULT 0 | |

---

### impersonation_log

Nhật ký kiểm tra các phiên mạo danh Nhân viên hỗ trợ (FR-76).

| Column | Type | Constraint | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| support_user_id | UUID | FK → users NOT NULL | Nhân viên hỗ trợ |
| tenant_id | UUID | FK → tenants NOT NULL | Đối tượng thuê |
| started_at | TIMESTAMP | NOT NULL | |
| ended_at | TIMESTAMP | | NULL nếu phiên vẫn hoạt động |

**Lưu giữ:** Vĩnh viễn — nhật ký mạo danh không bị xóa tự động. Chúng tạo thành một dấu vết kiểm tra truy cập đặc quyền.

---

## 3.4.2 Ước tính khối lượng dữ liệu

Ước tính dựa trên 50 người thuê khi ra mắt phiên bản v1, trung bình 1.000 sinh viên trên mỗi người thuê, 2 buổi thi mỗi tuần cho mỗi người thuê trong vòng 12 tháng.

| Entity | Hàng ước tính (12 tháng) | Trình điều khiển lưu trữ |
|--------|-----------------------------|----------------|
| tenants | ~50 | không đáng kể |
| licenses | ~150 | không đáng kể |
| users | ~50,000 | Thấp |
| user_roles | ~60,000 | Thấp |
| refresh_tokens | ~200,000 | Thấp (bị xóa khi hết hạn) |
| courses | ~500 | không đáng kể |
| groups | ~2,000 | không đáng kể |
| enrollments | ~200,000 | Thấp |
| questions | ~5,000 | Thấp |
| assets (âm thanh/hình ảnh của nhà cung cấp) | ~5,000 | Siêu dữ liệu thấp; các tập tin trong Bộ nhớ đám mây |
| exam_templates | ~50 | không đáng kể |
| exam_sessions | ~5,000 | Thấp |
| session_participants | ~150,000 | Thấp |
| exam_attempts | ~150,000 | Thấp |
| **exam_state** | **~15,000,000** | **Cao — điểm truy cập DB chính** |
| part_timers | ~2,400,000 | Trung bình (16 phần × 150k lần thử) |
| attempt_results | ~600,000 | Thấp (4 kỹ năng × 150k lần thử) |
| ai_score_drafts | ~900,000 | Trung bình (Viết: 3 phần + Nói: 5 phần × 150k) |
| speaking_recordings | ~750,000 | Siêu dữ liệu thấp; tệp âm thanh trong Cloud Storage (~5–15 MB mỗi tệp) |
| violation_events | ~500,000 | Thấp-trung bình (thay đổi tùy theo hành vi đoàn hệ) |
| exam_events | ~50,000 | Thấp |
| notification_log | ~3,000,000 | Trung bình |
| impersonation_log | ~1,000 | không đáng kể |

**Bảng lớn nhất theo số hàng:** `exam_state` (~15M hàng). Bảng này yêu cầu một chỉ mục tổng hợp trên `(attempt_id, question_id)` và tùy chọn một chỉ mục bao trùm cho truy vấn tìm nạp sơ yếu lý lịch (`SELECT * FROM exam_state WHERE attempt_id = ?`).

**Dung lượng lưu trữ lớn nhất:** Bản ghi âm giọng nói trong Cloud Storage. Ở mức 5–15 MB cho mỗi lần thử của học sinh × 150.000 lần thử = 750 GB–2,25 TB mỗi năm. Chính sách giữ lại (NFR-11, OI-07) là đòn bẩy chính để kiểm soát chi phí này.

---

## 3.4.3 Trường PII

| Entity | Column | Phân loại PII | Yêu cầu xử lý |
|--------|--------|-------------------|----------------------|
| users | email | PII — định danh trực tiếp | Được mã hóa ở phần còn lại; chưa bao giờ đăng nhập vào bản rõ; duy nhất cho mỗi tenant |
| users | full_name | PII — định danh trực tiếp | Được mã hóa ở phần còn lại; không được trả về trong danh sách điểm cuối mà không được phép |
| users | password_hash | Credential | chỉ bcrypt; không bao giờ được trả lại thông qua bất kỳ điểm cuối API nào |
| speaking_recordings | (tệp âm thanh trong Cloud Storage) | PII — proxy sinh trắc học (giọng nói) | Hạn chế truy cập URL được chỉ định; lưu giữ trên NFR-11; thanh lọc theo OI-07 |
| ai_score_drafts | stt_transcript | PII — nội dung lời nói | Quyền truy cập cấp cơ sở dữ liệu bị hạn chế đối với vai trò Giáo viên/hệ thống; được giữ lại trên mỗi NFR-11 |
| attempt_results | final_feedback_narrative | PII — hồ sơ giáo dục | Sinh viên có thể truy cập sau xác nhận; được giữ lại trên mỗi NFR-10 |
| notification_log | recipient_user_id | PII — gián tiếp | Được giữ lại theo OI-07; chưa đăng nhập |

**Nghị định 13/2023/ND-CP của Việt Nam:** Khả năng áp dụng là TBD (OI-07). Nếu có thể, hệ thống phải: (a) xin phép thu thập dữ liệu, (b) duy trì sổ đăng ký xử lý dữ liệu, (c) thực hiện quy trình công việc có quyền xóa, (d) có khả năng lưu trữ dữ liệu trên máy chủ ở Việt Nam. Các nghĩa vụ này phải được Pháp lý xác nhận trước khi hoàn thiện kiến ​​trúc.

---

## 3.4.4 Chính sách lưu giữ và xóa dữ liệu

| Danh mục dữ liệu | Mục tiêu giữ chân | Cơ chế thanh lọc | Ghi chú |
|---------------|-----------------|-----------------|-------|
| Hồ sơ trả lời bài kiểm tra (`exam_state`) | `[TBD — OI-07]` | Công việc thanh lọc theo lịch trình | Xóa tầng với nỗ lực của cha mẹ |
| Thử kết quả và phản hồi | `[TBD — OI-07]` | Công việc thanh lọc theo lịch trình | Có thể kích hoạt luồng quyền xóa |
| Tệp âm thanh nói (Lưu trữ đám mây) | `[TBD — OI-07]` | Chính sách vòng đời lưu trữ đám mây | Trình điều khiển chi phí chính; giảm thiểu việc lưu giữ |
| Bản ghi STT (`ai_score_drafts.stt_transcript`) | `[TBD — OI-07]` | Cascade với nỗ lực thanh lọc | Dữ liệu proxy sinh trắc học; ưu tiên duy trì ngắn hạn |
| Điểm dự thảo AI (`ai_score_drafts`) | `[TBD — OI-07]` | Công việc thanh lọc theo lịch trình | Sau khi xác nhận, bản nháp có thể bị xóa |
| Sự kiện vi phạm | `[TBD — OI-07]` | Công việc thanh lọc theo lịch trình | Tối thiểu: phiên + 1 năm đối với khiếu nại về tính liêm chính |
| Nhật ký thông báo | `[TBD — OI-07]` | Công việc thanh lọc theo lịch trình | Không có PII trong nhật ký kiểm tra thanh lọc |
| Dữ liệu phiên khách/dùng thử | `[TBD — OI-07]` | Công việc thanh lọc khách (FR-92) | Thời gian lưu giữ ngắn; Đề xuất 7–30 ngày |
| Làm mới mã thông báo (đã hết hạn/bị thu hồi) | 90 ngày sau khi hết hạn | Công việc dọn dẹp theo lịch trình | Cần thiết cho việc kiểm tra chuỗi luân chuyển mã thông báo |
| Nhật ký mạo danh | **Vĩnh viễn** | Không có thanh lọc tự động | Dấu vết kiểm tra quyền truy cập đặc quyền |
| Lịch sử giấy phép | **Vĩnh viễn** | Không có thanh lọc tự động | Đường mòn kiểm toán tài chính |

**Yêu cầu công việc thanh lọc:** Tất cả các công việc thanh lọc đã lên lịch phải: (1) ghi lại số lượng bản ghi đã xóa (không có PII trong mục nhập nhật ký thanh lọc), (2) bình thường (an toàn để chạy lại), (3) hoàn thành trong khoảng thời gian bảo trì xác định (OR-OPS-04) và (4) được theo dõi bằng các cảnh báo nếu công việc không thành công hoặc chạy lâu hơn dự kiến.