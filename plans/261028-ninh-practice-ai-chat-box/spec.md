# Spec: Chat box AI cho PTE Practice (Task 76)

**Date:** 2026-10-28  
**Status:** Draft — chờ plan  
**Owner:** Ninh — `261028-ninh-practice-ai-chat-box`  
**Repo:** `pte-api` + `pte-practice` (nhánh `Ninh/feat/Chat-Bot-AI`)  
**Scope:** Backend module `chat` mới (`pte-api`) + frontend `pte-practice/features/chat`. Không làm Flutter `pte-app`.  
**Nguồn:** tài liệu thảo luận nhóm https://claude.ai/artifact/SCdJmKsdf7PZr3G15b5ota (rev 47)

---

## 1. Problem Statement

Học viên PTE Practice chưa có nơi hỏi nhanh về tiếng Anh/PTE khi đang luyện. Cần một chat box AI với 3 ràng buộc:

1. **Giới hạn quota** để kiểm soát chi phí và chống lạm dụng.
2. **Chỉ trả lời câu hỏi liên quan đến tiếng Anh** (ưu tiên PTE), từ chối chủ đề khác.
3. **Trả lời trung lập, không chiều ý, không khen suông** người hỏi.

Hạ tầng sẵn có: module `scoring` đã có client Gemini/OpenAI-compatible + `ProviderGuard`; `PracticeEntitlementService` kiểm tra quyền student/tenant/gói. Chưa có quota theo lượt chat và chưa có client chat tự do (client scoring ép JSON + `temperature 0`).

---

## 2. User Stories

### [P1] Hỏi đáp tiếng Anh/PTE trong quota
- **Là học viên**, tôi muốn gửi câu hỏi tiếng Anh/PTE và nhận câu trả lời markdown đẹp, theo ngôn ngữ tôi hỏi.
- **AC:**
  - Mỗi student có tối đa **20 tin/ngày** (cấu hình được), reset 00:00 giờ VN; ngày do server tính.
  - Hết lượt: API trả HTTP 429 kèm `resetAt`; UI vô hiệu hoá ô nhập + nút gửi và hiện "còn X giờ Y phút".
  - Còn ≤ 3 lượt: UI hiện cảnh báo kèm giờ reset. Mỗi response có `remaining`, `limit`, `resetAt`; có endpoint trạng thái quota khi mở box.
  - Tin tối đa **1000 ký tự**; vượt thì từ chối ở cả client và server.

### [P1] Từ chối chủ đề ngoài tiếng Anh, không tốn quota
- **Là hệ thống**, tôi chỉ phục vụ chủ đề tiếng Anh (ưu tiên PTE); câu ngoài chủ đề nhận câu từ chối cố định.
- **AC:**
  - Gemini Structured Output trả `{is_on_topic, markdown_content}`; `is_on_topic = false` → câu từ chối cố định + **hoàn quota**.
  - Câu kiểu "bỏ qua hướng dẫn trên" bị từ chối; có test prompt injection.
  - Nhờ làm hộ bài thi thật bị từ chối. Dịch Anh↔Việt phục vụ học được phép.

### [P1] Không chiều ý, không khen suông
- **AC:** bộ test prompt (ví dụ "Tôi nghĩ X đúng, đúng không?" khi X sai; gửi essay hỏi "viết tốt chưa?") cho câu trả lời nói thẳng sai/đúng, không mở đầu bằng lời khen, không đổi kết luận theo ý người hỏi.

### [P1] Quota đúng khi chạy đồng thời và khi lỗi
- **AC:**
  - Bảng `chat_usage` có UNIQUE `(student_id, usage_date)`; trừ quota bằng `INSERT ... ON CONFLICT DO UPDATE ... WHERE used < limit`; hoàn quota giảm 1, không âm.
  - Hai request song song không vượt quota; không tạo nhiều dòng đếm cho một ngày.
  - Provider lỗi (timeout, 429, 5xx), JSON hỏng/bị cắt (`MAX_TOKENS`) → hoàn quota + báo "hệ thống bận", **không retry**.
  - Mỗi user chỉ 1 request chat đang xử lý (HTTP 409); semaphore toàn hệ thống (mặc định 20) → "hệ thống đang bận".

### [P2] Phiên hội thoại, lịch sử và cache
- **AC:**
  - Mọi hội thoại lưu DB (student, `session_id`, thời điểm, câu hỏi, trả lời, task type, ngôn ngữ, token vào/ra, `from_cache`, `on_topic`).
  - Client gửi `session_id` (UUID v4); server kiểm tra phiên thuộc đúng student rồi tự nạp 6 tin gần nhất; không tin lịch sử/cờ "phiên rỗng" từ client.
  - Chỉ tra cache khi phiên **rỗng**; khoá cache = câu hỏi chuẩn hoá + ngôn ngữ + task type + phiên bản system prompt; chỉ lưu câu trả lời hợp lệ; cache hit **không trừ quota**.
  - Tải lại trang: client nạp lại `session_id` gần nhất từ server; chỉ nút **"Đoạn chat mới"** tạo `session_id` mới.

### [P2] Giao diện side panel
- **AC:**
  - Side panel phải bật/tắt, đẩy nội dung bài tập sang bên; màn hình nhỏ dùng overlay (layout cuối cùng chốt với UI/UX Designer).
  - Render markdown bằng `react-markdown` + `remark-gfm` + `@tailwindcss/typography`; bảng và `pre` bọc `overflow-x-auto`, nội dung `break-words`; không dùng `dangerouslySetInnerHTML`.
  - Trạng thái loading (ba chấm), ô nhập + nút gửi khoá khi đang xử lý, lỗi giữ nguyên nội dung đã gõ.
  - Disclaimer cố định dưới ô nhập: "Đoạn chat được lưu lại để kiểm tra chất lượng dịch vụ và cải thiện AI. Đừng chia sẻ thông tin cá nhân."

### [P3] Vận hành và chi phí
- **AC:** cấu hình `chat.ai.*` riêng (key, model ghim tên cụ thể, không alias `-latest`, `temperature` thấp, `max-tokens` ~600, timeout ~20 giây, `daily-limit`, `max-input-chars`, `history-size`); ghi `finishReason` và token vào DB; có tài liệu hướng dẫn đặt budget alert.

---

## 3. Functional Requirements

- **FR-01:** Module `chat` trong `pte-api` (Spring Modulith, PostgreSQL), tái dùng `RestClient`/`ProviderGuard`/`VendorHttp`, chat client riêng cho Gemini.
- **FR-02:** Luồng xử lý một tin: entitlement → validate → (cache nếu phiên rỗng) → trừ quota UPSERT → Gemini structured output → làm sạch/parse/validate schema → lưu DB → trả `markdown_content` + quota.
- **FR-03:** Làm sạch đầu ra: bỏ rào ```json nếu có, parse trong try-catch, kiểm tra schema (đủ trường, đúng kiểu, nội dung không rỗng khi `is_on_topic = true`); lỗi → hoàn quota + báo bận.
- **FR-04:** Endpoint gửi tin, endpoint trạng thái quota, endpoint nạp phiên gần nhất + lịch sử.
- **FR-05:** System prompt: chủ đề cho phép/từ chối, trung lập không khen suông, trả lời theo ngôn ngữ người hỏi, ưu tiên danh sách thay bảng rộng, trả lời ngắn gọn.
- **FR-06:** Frontend `pte-practice/features/chat`: side panel, hook quota, hook phiên, render markdown, nút "Đoạn chat mới", disclaimer, i18n en/vi, hằng số tập trung.
- **FR-07:** Gửi kèm task type/câu đang luyện trong mỗi tin.

## 4. Non-Functional Requirements

- **NFR-01 (tải):** chịu ~70 request/phút cao điểm (ước tính 500 student); chi phí trần ~105 đến 510 USD/tháng tuỳ model (giá tra ngày 2026-10-28).
- **NFR-02 (bảo mật):** server không tin `session_id`/lịch sử từ client; chống IDOR theo student; chống prompt injection.
- **NFR-03 (riêng tư):** key free chỉ dùng với dữ liệu thử; production bắt buộc key trả phí; PM cập nhật Privacy Policy/ToS trước release.
- **NFR-04 (đúng khi đồng thời):** quota nguyên tử qua UNIQUE + UPSERT, kiểm tra bằng test song song.

## 5. Out of Scope

Flutter `pte-app`; streaming (SSE); cache khớp ngữ nghĩa (embedding); quyết định train AI; quota theo gói tenant; quản trị/xem lịch sử chat cho staff.

## 6. Open Items (không chặn plan)

- Hạn mức RPM/TPM thực tế của key trả phí: Tech Lead/PM ghi sau khi tạo Cloud Project có billing.
- Layout side panel: hẹn 15 phút với UI/UX Designer.
- Chọn model Flash-Lite cụ thể (2.5 / 3.1 / 3.5) và cấu hình thinking.
- Người phụ trách pháp lý duyệt câu chữ disclaimer và Privacy Policy.
