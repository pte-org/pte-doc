# Brainstorm: Mở rộng role cho Admin Web

**Ngày:** 2026-10-08
**Trạng thái:** Đã chốt hướng, sẵn sàng chuyển sang lập plan

## Bối cảnh

Admin web hiện có `PLATFORM_ADMIN` và luồng authoring học thuật đang bị gom vào một vai trò author. Khi hệ thống có thêm quản lý tenant, thương mại, nội dung học thuật, duyệt tài nguyên và vận hành kỳ thi, một role duy nhất sẽ dễ bị cấp quyền quá rộng hoặc khó xác định trách nhiệm.

Mục tiêu là tách rõ:

- quản trị toàn hệ thống;
- quản lý vận hành nền tảng;
- quản trị học thuật và phê duyệt nội dung;
- biên soạn tài nguyên học thuật;
- các role vận hành trong phạm vi tenant/exam hiện có.

## Các hướng đã xem xét

### 1. Thêm role cố định theo trách nhiệm

Đây là hướng phù hợp với giai đoạn hiện tại vì nghiệp vụ đã có các nhóm trách nhiệm tương đối ổn định. Role cố định giúp menu, API authorization, audit và quy trình phê duyệt dễ kiểm soát hơn so với cho phép tạo role tùy ý ngay từ đầu.

### 2. Dùng role như bundle quyền, nhưng kiểm tra thêm scope

Role không chỉ là tên hiển thị. Mỗi quyền cần được giới hạn bởi scope:

- `PLATFORM`: dữ liệu và nghiệp vụ cấp nền tảng;
- `TENANT`: dữ liệu của tenant được phân công;
- `ASSIGNED_SESSION`: session/exam được giao;
- `OWN_DRAFT`: bản nháp do staff tạo hoặc được phân công.

Backend phải kiểm tra cả permission và scope; việc ẩn menu trên frontend không được xem là cơ chế bảo mật.

### 3. Tách quản lý vận hành khỏi quản trị học thuật

`PLATFORM_MANAGER` xử lý tenant, application, plan, license, order, subscription, báo cáo vận hành và thông báo nền tảng. Role này không được duyệt/publish nội dung học thuật, thay đổi role/security hoặc tùy ý thay đổi chính sách chấm điểm.

`ACADEMIC_MANAGER` chịu trách nhiệm về task type, question type, question, question template, score template, rubric và phiên bản nội dung. Role này duyệt và publish tài nguyên sau khi `ACADEMIC_STAFF` tạo bản nháp.

### 4. Thay author bằng Academic Staff

Author hiện tại được định hướng thành `ACADEMIC_STAFF`. Staff có thể tạo, sửa, import và submit tài nguyên học thuật; không được tự duyệt hoặc tự publish tài nguyên của mình.

### 5. Giữ các role tenant/exam hiện có

`HOST_ADMIN`, `EXAMINER`, `PROCTOR` và `STUDENT` tiếp tục phục vụ các nghiệp vụ tenant, chấm thi, giám sát và làm bài. Việc thêm role platform không được làm mở rộng nhầm quyền sang tenant khác.

## Role và trách nhiệm đã thống nhất

| Role | Phạm vi | Trách nhiệm chính | Không được làm |
|---|---|---|---|
| `PLATFORM_ADMIN` | Toàn hệ thống | Toàn quyền; quản lý role, security, cấu hình nền tảng, dữ liệu và các thao tác đặc quyền | Không có giới hạn nghiệp vụ ngoài audit và chính sách an toàn hệ thống |
| `PLATFORM_MANAGER` | Toàn nền tảng, thiên về vận hành | Quản lý tenant/application, plan/catalog, license/order/subscription, báo cáo vận hành và thông báo toàn cục | Không quản lý role/security; không duyệt/publish học thuật; không tự thực hiện thao tác tài chính nhạy cảm nếu chưa được cấp riêng |
| `ACADEMIC_MANAGER` | Toàn nền tảng, miền học thuật | Quản lý catalog học thuật; review, approve, reject, publish task/question type, question, template, rubric và phiên bản | Không quản lý billing, tenant onboarding hoặc security; không bỏ qua version/audit |
| `ACADEMIC_STAFF` | Toàn nền tảng, bản nháp/được phân công | Tạo, sửa, import question/media/type/template; submit để review; xử lý feedback | Không tự approve/publish nội dung; không thay đổi role/security hoặc chính sách nền tảng |
| `HOST_ADMIN` | Một tenant/organization | Quản lý lớp, student, session, proctor/examiner được phân công và publish kết quả theo workflow exam | Không truy cập catalog hoặc dữ liệu tenant khác; không quản trị role platform |
| `EXAMINER` | Bài/session được giao | Chấm phần được phân công, đặc biệt speaking/writing | Không tự phân công bài, publish kết quả hoặc sửa catalog |
| `PROCTOR` | Session được giao | Giám sát session và xử lý nghiệp vụ proctor | Không chấm điểm hoặc quản lý học thuật |
| `STUDENT` | Dữ liệu của chính mình | Làm bài, nộp bài, xem kết quả được publish | Không xem dữ liệu người khác hoặc dữ liệu quản trị |

## Luồng nghiệp vụ đề xuất

```text
ACADEMIC_STAFF tạo bản nháp
        ↓
Submit for review
        ↓
ACADEMIC_MANAGER review
   ├── Reject + feedback → ACADEMIC_STAFF chỉnh sửa → submit lại
   └── Approve → Publish version
                         ↓
              HOST_ADMIN chọn tài nguyên đã publish
```

`PLATFORM_ADMIN` có thể can thiệp trong trường hợp quản trị, nhưng mọi thao tác approve, publish, thay đổi role và thay đổi cấu hình nhạy cảm phải có audit log.

## Quyền nên chuẩn hóa

Các mã quyền nên được định nghĩa tập trung và tái sử dụng thay vì rải chuỗi literal trong controller:

- `ROLE_MANAGE`, `SECURITY_CONFIGURE`;
- `TENANT_MANAGE`, `APPLICATION_REVIEW`;
- `CATALOG_MANAGE`, `PLAN_MANAGE`, `LICENSE_MANAGE`, `ORDER_MANAGE`, `REPORT_VIEW`;
- `ACADEMIC_DRAFT_WRITE`, `ACADEMIC_IMPORT`, `ACADEMIC_REVIEW`, `ACADEMIC_APPROVE`, `ACADEMIC_PUBLISH`;
- `SCORING_POLICY_MANAGE`;
- `EXAM_ASSIGN`, `EXAM_SCORE`, `EXAM_PUBLISH`, `SESSION_PROCTOR`;
- `OWN_ATTEMPT_READ`, `OWN_ATTEMPT_SUBMIT`.

Đây là permission bundle định hướng; plan triển khai cần đối chiếu với permission/authority đang có trong source để tránh tạo trùng contract.

## Rủi ro cần kiểm soát

1. **Role explosion:** không thêm các role `billing manager`, `support`, `reporting analyst` vào MVP; chỉ mở rộng khi có nhu cầu và permission boundary rõ.
2. **Tự duyệt nội dung:** phải chặn ở backend, không chỉ disable nút trên UI.
3. **Lẫn scope platform/tenant:** mọi endpoint phải kiểm tra tenant/organization hoặc phạm vi platform tương ứng.
4. **Legacy author:** cần chiến lược tương thích khi đổi `PLATFORM_AUTHOR` thành `ACADEMIC_STAFF`, tránh làm mất quyền hoặc tạo role mồ côi.
5. **Thay đổi scoring:** score template/rubric cần version và audit; không sửa âm thầm version đang được exam sử dụng.

## Kết luận brainstorm

Hướng được chấp thuận là giữ `PLATFORM_ADMIN` toàn quyền, đổi vai trò author thành `ACADEMIC_STAFF`, đồng thời bổ sung `PLATFORM_MANAGER` và `ACADEMIC_MANAGER`. Các role `HOST_ADMIN`, `EXAMINER`, `PROCTOR`, `STUDENT` được giữ nguyên ranh giới nghiệp vụ. Bước tiếp theo là lập plan triển khai theo permission, migration, backend authorization, admin UI, audit và test matrix.
