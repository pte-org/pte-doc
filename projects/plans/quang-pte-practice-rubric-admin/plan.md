# Plan: quản lý rubric Practice trên Admin Web

**Owner:** Ngô Đăng Quang  
**Project:** PTEPrep: An AI-Powered PTE Practice Platform and Realistic Exam Simulator  
**Date:** 23 October 2026  
**Mode:** `ck:plan --hard`  
**Status:** Implementation complete; Phase 05 evidence recorded; final `--hard` confirmation pending  
**Scope:** `pte-api`, `pte-web/apps/vendor-web`, `pte-web/packages/api-client`, `pte-doc`

## 1. Mục tiêu

Xây dựng chức năng quản lý rubric học thuật cho PTE Practice trên Admin Web và nối rubric đã phát hành vào luồng giải thích AI. Rubric được tạo, chỉnh sửa, gửi duyệt, phát hành và ngừng sử dụng theo phiên bản bất biến. Practice chỉ dùng rubric đã được Academic Manager hoặc Platform Admin phê duyệt; mỗi phiên luyện tập lưu lại đúng phiên bản rubric đã dùng để kết quả cũ không bị thay đổi khi rubric mới được phát hành.

Rubric là chính sách hướng dẫn nhận xét học tập. Đây không phải bảng quy đổi điểm chính thức của Pearson/PTE Academic. Writing và Speaking chỉ nhận feedback theo tiêu chí trong giai đoạn đầu; điểm số AI cho hai kỹ năng này nằm ngoài phạm vi cho đến khi có kiểm định riêng.

## 2. Phạm vi

### Trong phạm vi

- Quản lý rubric theo task type và kênh `PRACTICE`.
- Phiên bản rubric, tiêu chí, mức mô tả, quy tắc bằng chứng, ví dụ neo và nguồn tham chiếu.
- Quy trình `DRAFT → PENDING_APPROVAL → PUBLISHED → RETIRED`.
- Phân quyền theo Academic Staff, Academic Manager, Platform Author và Platform Admin.
- Kiểm tra sẵn sàng ở server trước khi phát hành hoặc đưa task vào Practice.
- Liên kết phiên bản rubric với task/question revision phù hợp.
- Pin rubric ID, version, hash và snapshot an toàn vào Practice session item.
- Gemini nhận rubric projection đã được phê duyệt và bị giới hạn bởi criterion ID/level hợp lệ.
- Deterministic result provenance cho objective task và form task (word count, form status, evaluator version, result hash và evidence identity hash).
- Server-owned evidence manifest chỉ quảng cáo text/media đã tồn tại và xác minh được trong tenant context; provider không tự bịa đường dẫn bằng chứng.
- Task-specific required-evidence map chặn publish khi rubric thiếu bằng chứng bắt buộc của task; các criterion audio không đủ assessor evidence trả `NOT_ASSESSABLE`.
- Admin Web list, editor, detail, readiness, diff, reject, publish, retire và override.
- Tái sử dụng các common/shared layer hiện có thay vì tạo component hoặc contract song song.
- Audit cho các thao tác quản lý và các lỗi bị từ chối.

### Ngoài phạm vi

- Bảng điểm chính thức, chứng nhận hoặc liên kết đại diện cho Pearson/PTE Academic.
- Điểm AI số cho Writing/Speaking trước khi hoàn thành calibration.
- Chatbot mở, adaptive learning hoặc kế hoạch học cá nhân hóa.
- Cho Student sửa rubric, xem prompt nội bộ, answer key hoặc restricted reference.
- Thay thế `ScoreTemplate`; score template vẫn giữ trách nhiệm về cấu trúc đề, thời lượng và trọng số kỳ thi.
- Tạo bộ tiêu chí bằng cách nhúng vào `ScoreTemplateItem`.
- Production publish, deploy hoặc migration trên môi trường thật trong giai đoạn lập kế hoạch.

## 3. Quyết định thiết kế chính

| ID | Quyết định | Lý do |
|---|---|---|
| D01 | Dùng module `rubric` riêng trong Spring Modulith | Rubric là chính sách học thuật; không trộn với score template hoặc itembank. |
| D02 | Dùng mô hình quan hệ chuẩn hóa kết hợp snapshot JSON bất biến | Form Admin cần criterion/level có cấu trúc; Gemini cần một projection ổn định và có hash. |
| D03 | Một rubric logical key cho mỗi canonical task type và channel | Tránh một rubric chung áp dụng âm thầm cho nhiều dạng bài có bằng chứng khác nhau. |
| D04 | Lifecycle là `DRAFT → PENDING_APPROVAL → PUBLISHED → RETIRED` | Bản đã publish không sửa trực tiếp; sửa tạo revision mới. Các tài liệu cũ dùng `ACTIVE` phải được mapping rõ trước implementation. |
| D05 | Academic Manager không được tự duyệt bản do chính mình tạo | Bảo đảm tách người soạn và người phê duyệt. Platform Admin override phải có lý do và audit riêng. |
| D06 | Practice chỉ chọn rubric `PUBLISHED` | Không fallback sang draft, rubric cũ chưa duyệt hoặc rubric EXAM khi Practice thiếu dữ liệu. |
| D07 | Snapshot rubric được pin tại thời điểm tạo Practice session | Explanation retry hoặc GET về sau không đọc rubric hiện tại rồi làm sai lịch sử. |
| D08 | Shared/common là bắt buộc | Backend dùng `ApiResponse`, exception mapping, `CurrentUserContext`, `AuditLogService`, module facade và constants hiện có; web dùng `@pte/api-client`, `@pte/ui`, permissions, React Query và localization hiện có. |

## 4. Vai trò và quyền

| Vai trò | Quyền dự kiến |
|---|---|
| Academic Staff | Tạo, sửa, clone, submit draft do mình sở hữu; xem lịch sử theo phạm vi được cấp. |
| Academic Manager | Tạo draft; review, reject, publish, retire draft của người khác; không tự duyệt bản của mình. |
| Platform Author | Tạo và submit nội dung học thuật nếu policy hiện tại vẫn cho phép role này; không tự publish. |
| Platform Admin | Toàn quyền theo policy platform; override publish chỉ khi có lý do bắt buộc và audit. |
| Host/Proctor/Examiner | Không quản lý rubric; chỉ nhận projection đã được phép bởi nghiệp vụ tương ứng. |
| Student | Chỉ xem feedback đã render; không nhận raw rubric, answer key, restricted reference hoặc prompt. |

UI chỉ ẩn/hiện action để giảm nhầm lẫn. API và service phải kiểm tra quyền, ownership, lifecycle và self-review độc lập.

## 5. Mô hình dữ liệu đề xuất

### Nguồn chuẩn hóa

- `rubric_definitions`: logical key, task type, channel, owner và mô tả ngắn.
- `rubric_revisions`: public ID, revision number, status, author/reviewer/publisher, change reason, rejection reason, runtime contract, canonical hash, timestamps.
- `rubric_criteria`: criterion ID ổn định, thứ tự, tên, applicability, evidence policy, empty/invalid/`NOT_ASSESSABLE` policy.
- `rubric_criterion_levels`: level key, nhãn VI/EN, descriptor, điều kiện được phép trả về.
- `rubric_anchor_examples`: ví dụ tốt/đang phát triển/yếu/rỗng/không hợp lệ, nguồn và trạng thái đã kiểm duyệt.
- `rubric_references`: source artifact, reference revision, provenance và hash; nội dung answer key vẫn thuộc ownership của itembank.
- `question_rubric_bindings`: liên kết question revision với rubric revision và reference/evaluator revision khi task cần ràng buộc cụ thể.

### Projection và tính bất biến

Khi publish, server tạo canonical JSON projection và `definition_hash`. Projection là bản Gemini và historical read sử dụng; nó không phải nguồn chỉnh sửa trực tiếp. Published/retired revision và snapshot lịch sử không bị cập nhật lại.

Các ràng buộc chính:

- unique `(rubric_key, revision_number)`;
- tối đa một `PUBLISHED` revision cho mỗi logical key/channel;
- index theo task, channel, status, author và published lookup;
- dùng UUID public ID giữa module, không tạo JPA relationship xuyên module;
- các cột pin trên `practice_session_items` và `practice_explanations` là nullable để migration tương thích dữ liệu cũ.

## 6. Luồng nghiệp vụ chính

### Luồng 1: Tạo và gửi rubric

Academic Staff/Author tạo draft → thêm tiêu chí và mức mô tả → thêm evidence policy và ví dụ → server validate → lưu draft → submit for approval → audit.

### Luồng 2: Review và publish

Academic Manager mở draft → xem readiness và diff → kiểm tra nguồn tham chiếu → reject kèm lý do hoặc publish → server tạo canonical hash → retire bản publish cũ → bản mới thành `PUBLISHED` → audit.

### Luồng 3: Override của Platform Admin

Platform Admin mở revision → chọn override publish → nhập lý do bắt buộc → server kiểm tra readiness tối thiểu → publish và ghi `OVERRIDE_PUBLISHED` cùng actor/reason.

### Luồng 4: Practice sử dụng rubric

Practice chọn task → server tìm question revision và rubric `PUBLISHED` tương thích → pin rubric/reference/evaluator/runtime metadata vào session item → Student nộp bài → evaluator deterministic chạy trước → Gemini nhận safe rubric projection → validator kiểm tra criterion/level/evidence → lưu explanation bất biến.

### Luồng 5: Rubric mới

Người có quyền clone revision cũ → chỉnh draft mới → submit/review/publish → session cũ vẫn đọc revision đã pin → session mới chỉ dùng revision publish hiện hành.

## 7. Phases

| Phase | Mục tiêu | Phụ thuộc |
|---|---|---|
| [01](phase-01-rubric-contract-and-readiness.md) | Chốt contract, task matrix, lifecycle và readiness | Không |
| [02](phase-02-api-rubric-module-and-migration.md) | Module backend, migration, validation, lifecycle, authorization, audit | 01 |
| [03](phase-03-runtime-binding-and-gemini-integration.md) | Binding question/rubric, pin session, Gemini projection và output validation | 01, 02 |
| [04](phase-04-shared-api-client-and-admin-ui.md) | Shared API client và Admin Web dùng common UI | 02, contract của 03 |
| [05](phase-05-verification-rollout-and-docs.md) | Test, quality gate, seed, rollout evidence và cập nhật tài liệu | 02–04 |

## 8. Acceptance criteria toàn bộ

1. Academic Staff không thể publish bằng cách gọi trực tiếp API hoặc bỏ qua UI.
2. Academic Manager không thể tự approve/publish draft của chính mình.
3. Published/retired revision không thể sửa; correction tạo revision mới.
4. Mỗi task/channel chỉ có một rubric publish hiện hành.
5. Practice không tạo item mới khi thiếu rubric publish hoặc binding không tương thích.
6. Session item pin rubric revision/hash; retry explanation không lấy rubric hiện tại.
7. Gemini không thể tạo criterion ID, level hoặc numeric score ngoài contract.
8. Objective correctness vẫn do evaluator deterministic quyết định; AI chỉ giải thích.
9. Student response không bị gửi lẫn giữa account/context; raw answer key và prompt không xuất hiện ở response Student.
10. Mọi create/update/submit/reject/publish/retire/override/validation failure/authorization denial đều có audit phù hợp.
11. Admin UI sử dụng `@pte/ui` và `@pte/api-client`; không tạo bản sao của DataTable, Modal, FormField, toast hoặc API envelope.
12. Existing historical practice sessions vẫn đọc được, kể cả khi rubric cũ đã retired.

## 9. Rủi ro và kiểm soát

| Rủi ro | Kiểm soát |
|---|---|
| Copy lifecycle ScoreTemplate làm draft được activate sau approve | Dùng trạng thái `PUBLISHED` rõ ràng và service transition riêng. |
| Rubric thay đổi làm kết quả cũ đổi theo | Pin public ID/version/hash/snapshot tại session creation. |
| Gemini trả criterion giả hoặc level sai | Safe projection + allowlist validation + canonical order. |
| Speaking bị nhận xét pronunciation/fluency khi không có audio | Criterion phải trả `NOT_ASSESSABLE` nếu evidence policy không đủ. |
| UI ẩn action nhưng API vẫn bị gọi trực tiếp | Controller role gate và service ownership/lifecycle checks. |
| Mất thay đổi do nhiều người cùng sửa | expected version/optimistic concurrency và lỗi `409` ổn định. |
| Migration trùng số | Kiểm tra migration head ngay trước khi code, không mặc định số hiện tại. |

## 10. Quality and Testing State

- Preflight: đã đọc `docs/CODING_STANDARDS_API.md`, `docs/CODING_STANDARDS_WEB.md`, `docs/API_RESPONSE_SETUP.md`, `docs/COMMON_EXCEPTION_SETUP.md` và `docs/TEST_SCENARIOS_IAM.md` trước các thay đổi code.
- Implementation: Phase 01–04 đã triển khai; Phase 05 đã ghi nhận bằng chứng kiểm thử và các giới hạn chưa xác minh.
- Backend: compile s?ch; full `app` test ??t 2,645 tests, 0 failures, 0 errors, 77 skipped. Targeted rubric/provenance/lifecycle tests ??t (11 tests, 0 failures, 0 errors, 0 skipped).
- Web: API client typecheck và 3 rubric request tests đạt; vendor typecheck, lint và production build đạt. Lint còn 2 cảnh báo `no-img-element` có sẵn ngoài phạm vi.
- Practice: `npm run typecheck` đạt. `git diff --check` đạt ở các repository bị chạm, chỉ còn cảnh báo chuẩn hóa LF/CRLF của Git.
- Full API client suite hiện có 1 test contract dashboard không liên quan thất bại vì 4 response record `Student*` chưa có fixture mapping; 711/712 tests vẫn đạt. Không xem lỗi này là lỗi của rubric feature.
- Quality gate: review ??c l?p cu?i ?? **APPROVED**; v?i `--hard`, ch?a chuy?n tr?ng th?i cu?i c?ng sang completed tr??c khi ng??i d?ng x?c nh?n k?t qu? review.
- Chưa chạy Gemini thật, PostgreSQL migration trên database thật, browser flow có xác thực hoặc production deploy.

## 11. Handoff

Sau khi duyệt plan, chạy:

```text
/ck:cook --hard --tdd pte-doc/projects/plans/quang-pte-practice-rubric-admin/plan.md
```

Nếu chưa muốn TDD, bỏ `--tdd`. Với `--hard`, cần xác nhận của người dùng sau quality review trước khi đóng plan. Chưa có commit nào được tạo cho plan này.
