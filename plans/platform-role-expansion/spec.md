# Spec: Phân tách role vận hành và học thuật cho Admin Web

**Ngày:** 2026-10-08
**Trạng thái:** Approved for planning

## Problem Statement

Admin web cần hỗ trợ nhiều nhóm trách nhiệm hơn nhưng không được mở rộng quyền của một role theo cách khó kiểm soát. `PLATFORM_ADMIN` vẫn phải toàn quyền; role author hiện tại cần được định hướng thành người biên soạn học thuật; đồng thời cần có role quản lý vận hành nền tảng và role quản trị học thuật có quyền review/approve/publish.

Nếu không tách các nhóm này, người dùng vận hành có thể truy cập dữ liệu học thuật hoặc dữ liệu security không cần thiết, author có thể tự publish nội dung, và không có ranh giới rõ giữa catalog học thuật với billing/tenant operations.

## User Stories

### P1 — Platform administration

**Là** `PLATFORM_ADMIN`, **tôi muốn** giữ toàn quyền quản trị hệ thống, **để** có thể quản lý role, security, cấu hình nền tảng và xử lý ngoại lệ.

**Accepted when:** admin vẫn truy cập được toàn bộ nghiệp vụ hiện có; các role mới không làm giảm quyền admin; thao tác đặc quyền được audit.

### P1 — Platform operations

**Là** `PLATFORM_MANAGER`, **tôi muốn** quản lý các nghiệp vụ vận hành của platform, **để** giảm phụ thuộc vào admin cho công việc hằng ngày.

**Accepted when:** manager xem và xử lý được tenant/application, plan/catalog, license/order/subscription, báo cáo và announcement trong scope cho phép; không truy cập được role/security hoặc academic approve/publish.

### P1 — Academic governance

**Là** `ACADEMIC_MANAGER`, **tôi muốn** quản trị catalog và duyệt nội dung học thuật, **để** chỉ tài nguyên hợp lệ mới được dùng khi tạo exam/template.

**Accepted when:** academic manager review, approve, reject và publish được task/question type, question, question template, score template, rubric và phiên bản tương ứng; mọi thay đổi có actor, timestamp và version/audit.

### P1 — Academic authoring

**Là** `ACADEMIC_STAFF`, **tôi muốn** tạo, import và chỉnh sửa tài nguyên học thuật, **để** gửi nội dung cho academic manager duyệt.

**Accepted when:** staff tạo/sửa draft và submit được; staff không thể approve hoặc publish draft của mình qua UI hoặc API; feedback reject dẫn tới workflow chỉnh sửa và submit lại.

### P1 — Tenant administration

**Là** `HOST_ADMIN`, **tôi muốn** quản lý tài nguyên và kỳ thi trong tenant của mình, **để** tổ chức exam mà không thấy dữ liệu platform hoặc tenant khác.

**Accepted when:** host giữ nguyên quyền tenant hiện có; chỉ chọn được academic resources đã publish; cross-tenant access bị từ chối ở backend.

### P1 — Exam execution

**Là** `EXAMINER`, `PROCTOR` hoặc `STUDENT`, **tôi muốn** chỉ thấy nghiệp vụ đúng với vai trò và assignment của mình, **để** luồng chấm, giám sát và làm bài không bị mở rộng quyền.

**Accepted when:** examiner chỉ chấm bài được giao, proctor chỉ thao tác session được giao, student chỉ thao tác attempt của chính mình; không role nào được dùng quyền mới để bypass workflow publish.

## Functional Requirements

### Role catalog

- **FR-01:** Hệ thống phải có các role platform `PLATFORM_ADMIN`, `PLATFORM_MANAGER`, `ACADEMIC_MANAGER`, `ACADEMIC_STAFF`.
- **FR-02:** Hệ thống phải tiếp tục hỗ trợ `HOST_ADMIN`, `EXAMINER`, `PROCTOR`, `STUDENT` với boundary nghiệp vụ hiện có.
- **FR-03:** `PLATFORM_ADMIN` là role toàn quyền và là role duy nhất trong MVP được quản lý role/security.
- **FR-04:** Hệ thống phải có mapping tương thích cho role author cũ; mặc định định hướng `PLATFORM_AUTHOR` → `ACADEMIC_STAFF`, không để account cũ rơi vào trạng thái không có quyền.

### Permission và scope

- **FR-05:** Quyền phải được định nghĩa bằng constant/enum hoặc contract dùng chung hiện có; controller/service không được tự rải chuỗi authority trùng lặp.
- **FR-06:** Mỗi authorization decision phải xét cả permission và scope: `PLATFORM`, `TENANT`, `ASSIGNED_SESSION` hoặc `OWN_DRAFT`.
- **FR-07:** Frontend phải ẩn menu/action không phù hợp để UX rõ ràng, nhưng backend phải là lớp enforcement bắt buộc.
- **FR-08:** Tất cả endpoint đọc/ghi liên quan role mới phải có test cho allow, deny và cross-scope access.

### Platform Manager

- **FR-09:** `PLATFORM_MANAGER` được quản lý nghiệp vụ vận hành platform gồm tenant/application, plan/catalog, license/order/subscription, operational report và global announcement theo permission được cấp.
- **FR-10:** `PLATFORM_MANAGER` không được quản lý role/security, approve/publish academic resources, hoặc thay đổi scoring policy nếu chưa có permission đặc biệt được phê duyệt.
- **FR-11:** Các thao tác tài chính có tính hủy/hoàn tiền/thay đổi trách nhiệm pháp lý phải mặc định thuộc `PLATFORM_ADMIN`; chi tiết action nào được mở cho manager phải được chốt trong plan/API matrix.

### Academic Manager và Academic Staff

- **FR-12:** `ACADEMIC_MANAGER` được review, approve, reject và publish task/question type, question, question template, score template, rubric và các version academic tương ứng.
- **FR-13:** `ACADEMIC_STAFF` được create/edit/import media, question, task/question type và template ở trạng thái draft; được submit draft để review.
- **FR-14:** Hệ thống phải ngăn `ACADEMIC_STAFF` tự approve hoặc publish nội dung do mình tạo, kể cả khi gọi API trực tiếp.
- **FR-15:** Rejection phải lưu feedback và trạng thái để staff chỉnh sửa, submit lại; không overwrite lịch sử review đã hoàn tất.
- **FR-16:** Không được sửa âm thầm version academic đang được exam/session sử dụng; thay đổi scoring/template phải tạo hoặc chuyển sang version phù hợp và có audit.

### Giữ boundary tenant/exam

- **FR-17:** `HOST_ADMIN` chỉ truy cập tenant/organization được gắn với account và chỉ sử dụng academic resources đã publish.
- **FR-18:** `EXAMINER` chỉ xem/chấm attempt hoặc task được assignment; không approve/publish điểm cuối nếu workflow hiện tại yêu cầu host duyệt.
- **FR-19:** `PROCTOR` chỉ thao tác session được phân công và không có quyền chấm hoặc thay đổi academic catalog.
- **FR-20:** `STUDENT` chỉ đọc/ghi attempt, answer và kết quả của chính mình theo trạng thái cho phép.

### Audit và quản trị

- **FR-21:** Hệ thống phải audit role assignment/revocation, approve/reject/publish, scoring-policy change và các thao tác manager nhạy cảm.
- **FR-22:** Audit phải chứa tối thiểu actor, action, target type/id, scope, timestamp và kết quả allow/deny hoặc trạng thái trước/sau khi phù hợp.
- **FR-23:** Admin web phải hiển thị đúng menu, button và trạng thái workflow theo permission; việc không hiển thị UI không thay thế backend authorization.

## Proposed Permission Bundles

| Nhóm | Permission tiêu biểu | Role mặc định |
|---|---|---|
| Security | `ROLE_MANAGE`, `SECURITY_CONFIGURE` | `PLATFORM_ADMIN` |
| Platform operations | `TENANT_MANAGE`, `APPLICATION_REVIEW`, `PLAN_MANAGE`, `LICENSE_MANAGE`, `ORDER_MANAGE`, `REPORT_VIEW`, `ANNOUNCEMENT_MANAGE` | `PLATFORM_MANAGER`, một phần `PLATFORM_ADMIN` |
| Academic authoring | `ACADEMIC_DRAFT_WRITE`, `ACADEMIC_IMPORT` | `ACADEMIC_STAFF`, `ACADEMIC_MANAGER` |
| Academic governance | `ACADEMIC_REVIEW`, `ACADEMIC_APPROVE`, `ACADEMIC_PUBLISH`, `SCORING_POLICY_MANAGE` | `ACADEMIC_MANAGER`, `PLATFORM_ADMIN` |
| Exam operations | `EXAM_ASSIGN`, `EXAM_SCORE`, `EXAM_PUBLISH`, `SESSION_PROCTOR` | `HOST_ADMIN`, `EXAMINER`, `PROCTOR` theo scope |
| Student | `OWN_ATTEMPT_READ`, `OWN_ATTEMPT_SUBMIT` | `STUDENT` |

Tên permission chỉ là contract đề xuất; khi lập plan phải tái sử dụng authority/constant/common contract đã có nếu source đã cung cấp tương đương.

## Non-Functional Requirements

- **NFR-01 — Security:** Backend authorization deny-by-default cho endpoint thuộc scope mới; không tin vào role/permission do client gửi lên.
- **NFR-02 — Isolation:** Không phát sinh cross-tenant hoặc cross-session data exposure khi thêm role platform.
- **NFR-03 — Auditability:** Các thay đổi role, approve/publish và thao tác nhạy cảm phải truy vết được theo actor và thời gian.
- **NFR-04 — Consistency:** Một permission chỉ có một định nghĩa canonical; UI/API/test dùng chung contract đó.
- **NFR-05 — Backward compatibility:** Account và dữ liệu role author hiện có phải được migrate/alias có kiểm soát, có kế hoạch rollback hoặc compatibility window.
- **NFR-06 — Maintainability:** Không tạo permission editor hoặc custom-role builder trong MVP nếu chưa có yêu cầu quản trị vòng đời và kiểm thử tương ứng.
- **NFR-07 — Testability:** Permission matrix phải có unit/service tests và integration/API tests cho happy path, deny path, self-approval và cross-scope.

## Success Criteria

1. Có role catalog và permission matrix được backend, frontend và test dùng thống nhất.
2. `PLATFORM_ADMIN` vẫn toàn quyền; `PLATFORM_MANAGER` không thể truy cập role/security hoặc academic publish.
3. `ACADEMIC_STAFF` tạo và submit được draft nhưng 100% đường gọi approve/publish bị từ chối.
4. `ACADEMIC_MANAGER` duyệt/publish được tài nguyên, có reject feedback, version và audit.
5. `HOST_ADMIN`, `EXAMINER`, `PROCTOR`, `STUDENT` vẫn bị giới hạn đúng tenant/session/own-data như trước.
6. Toàn bộ account dùng role author cũ có mapping rõ sang `ACADEMIC_STAFF` hoặc được xử lý theo migration decision; không có account mồ côi.
7. Có test chứng minh không xảy ra self-approval và cross-tenant/cross-scope access.
8. Admin web hiển thị đúng menu/action theo role và API vẫn an toàn khi gọi trực tiếp.

## Out of Scope

- Custom role builder cho phép admin tự tạo permission bundle tùy ý.
- Các role mới như billing manager, support agent, reporting analyst hoặc academic reviewer độc lập.
- Việc thay đổi toàn bộ authentication/token architecture.
- Việc thay đổi business rule chấm điểm, assignment examiner hoặc publish result ngoài phần boundary role.
- Việc cho tenant tự tạo academic role platform.

## Assumptions

- `PLATFORM_ADMIN` vẫn giữ toàn quyền như yêu cầu hiện tại.
- `PLATFORM_MANAGER`, `ACADEMIC_MANAGER`, `ACADEMIC_STAFF` là role cấp platform; `HOST_ADMIN`, `EXAMINER`, `PROCTOR`, `STUDENT` giữ scope tenant/exam/own-data.
- Academic Staff là tên mới cho trách nhiệm author; việc đổi tên database/API hay dùng alias tương thích sẽ được quyết định khi lập plan sau khi rà source.
- Academic Manager là bên duyệt và publish tài nguyên học thuật; staff không tự duyệt nội dung của mình.
- Platform Manager được xử lý nghiệp vụ vận hành thông thường, còn thao tác tài chính hủy/hoàn tiền và security đặc quyền mặc định vẫn dành cho admin.
- Các common constants, common DTO, permission contract hoặc shared UI guard đã có phải được tái sử dụng trước khi tạo mới.

## Resolved Decisions

- `PLATFORM_MANAGER` được xử lý nghiệp vụ vận hành thông thường; `cancel`, `revoke`, `refund` và các thao tác tài chính hủy/hoàn tiền giữ ở `PLATFORM_ADMIN`.
- `PLATFORM_AUTHOR` là legacy alias trong compatibility window; token/API/UI normalize về `ACADEMIC_STAFF`, sau đó backfill dữ liệu và cleanup alias theo migration gate.
- `ACADEMIC_MANAGER` chỉ review/approve/publish version; không sửa trực tiếp scoring policy đang active. Mọi thay đổi phải qua draft/version và audit.
