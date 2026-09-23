# Phase 03 — Examiner queue và blind scoring

**Plan:** [plan.md](plan.md) · **Spec:** [spec.md](spec.md)  
**Covers:** P1 Examiner; FR-03, FR-04, FR-09–11, FR-18.  
**Depends on:** Phase 01–02.  
**Outcome:** Examiner chỉ xem/chấm attempt đã giao cho mình, gồm playback cần thiết, và nộp điểm tổng 0–100 riêng cho từng answer đủ điều kiện.

## Mục tiêu

Tạo authenticated Examiner work area tách khỏi Host answer review. Blind marking là server-side data minimization: không chỉ ẩn cột bằng UI.

## Backend/API work

1. **Role boundary và queue**
   - Thêm Examiner queue/list API dùng principal hiện tại; không nhận examiner ID để quyết định ownership.
   - Query filter đồng thời authenticated examiner ID + tenant + assignment state; chỉ trả assigned attempts.
   - Kiểm tra tài khoản active/role ở authorization layer theo convention auth hiện có.
   - DTO trả attempt status/attempt-safe student label, câu AI-eligible, answer payload cần chấm và trạng thái score submission; loại bỏ `rawScore`, `teacherScore`, selected source, provider provenance, Host review metadata.

2. **Detail và media**
   - Detail API xác minh assignment trước khi đọc answer payload hoặc xin presigned media URL.
   - Không tạo media URL rồi mới lọc answer; URL được cấp ngắn hạn chỉ sau tenant + assignment + answer-to-attempt checks.
   - Phân biệt answer/media không tồn tại với không được quyền theo quy tắc no-existence-leak đang dùng trong scoring.

3. **Score submission**
   - Chỉ chấp nhận integer 0–100 cho answer AI-eligible thuộc attempt được giao.
   - Persist examiner, answer, attempt, session, tenant, submittedAt và status; giữ nguyên AI raw score và Host teacher score.
   - Một answer chỉ submit một lần trong MVP. Retry cùng examiner/cùng score trả kết quả đã lưu; khác score, examiner khác hoặc answer đã publish bị từ chối.
   - Batch completeness/query xác định answer đã submit để Host review hiển thị chính xác.

4. **Examiner web area**
   - Bổ sung route/layout và navigation dành riêng cho role EXAMINER trong tenant-web; không reuse Host-only shell nếu gây lộ Host controls.
   - Queue filter trạng thái chưa chấm/đã chấm; attempt detail liệt kê các câu cần chấm, render đúng task response và audio/image prompt media cần thiết.
   - Score field numeric 0–100, validation FE hỗ trợ UX nhưng backend vẫn validate; trạng thái submitted read-only.
   - Không render AI score, Host score, selected source, score availability của AI hoặc Host approval controls.

## Kiểm chứng và acceptance

- Security matrix: Examiner đúng tenant + assignment được phép; cùng tenant nhưng chưa assigned, assigned cho người khác, tenant khác, inactive, sai role đều bị từ chối.
- Gọi list/detail/media/submit bằng ID đoán được không lộ attempt title/payload/audio/AI score.
- JSON contract snapshot/serialization asserts không có AI/Host score và selected source, kể cả trạng thái lỗi.
- Media presign chỉ chạy sau assignment ownership; test answer thuộc attempt khác.
- Score range/type/eligibility/identity/timestamp; score không đổi rawScore/objective/teacherScore.
- Identical retry idempotent; conflicting retry rejected; concurrent duplicate submit chỉ ghi một score.
- E2E role navigation: EXAMINER mở queue; không truy cập Host routes; HOST_ADMIN vẫn dùng Host answer review như trước.

**Acceptance:** secure examiner workflow và một lần chấm cho mọi AI-eligible answer trong assignment; Host source-selection UI/API đến ở Phase 04.

## Design Constraints

- Assignment và tenant ownership được enforce server-side cho mọi endpoint đọc/chấm/media.
- Examiner DTO không chứa AI score, selected source, Host teacher score hoặc provenance; blind marking áp dụng trước/trong khi chấm.
- Examiner score là record riêng, immutable sau submit trong MVP; không ghi đè objective/AI/Host score.
- Không tin examinerPublicId do client truyền vào để quyết định work ownership.
- Không mở rộng quyền `HOST_ADMIN` hoặc chuyển examiner vào Host-only controls.

## Quality and Testing State

- quality: not evaluated
- testing: not started
- Kế hoạch: authorization/DTO/media integration tests; submit idempotency/concurrency tests; Examiner route/component/E2E tests.
