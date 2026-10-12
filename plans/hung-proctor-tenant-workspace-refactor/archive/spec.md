# Spec: Proctor workspace trong tenant web

**Date:** 2026-10-11
**Status:** Approved — người dùng duyệt thiết kế và cho phép lập plan rồi triển khai ngày 2026-10-11
**Repositories:** `pte-api`, `pte-web`; tài liệu tập trung ở `pte-doc`.

## Problem Statement

Giám thị cần truy cập đúng buổi thi được phân công, theo dõi thí sinh và xử lý vi phạm trong tenant web. Scaffold hiện thiếu dữ liệu và thao tác thực; backend thiếu projection dành cho Proctor và một số kiểm tra quyền cho kênh giám sát.

## User Stories

- **[P1]** Là Proctor, tôi đăng nhập vào workspace phù hợp và thấy các buổi thi được phân công.
  Accepted when: tài khoản chỉ có PROCTOR vào `/proctor/sessions`; không thấy buổi thi ngoài tenant hoặc ngoài phân công; tài khoản nhiều role chuyển được giữa các workspace được phép.
- **[P1]** Là Proctor, tôi xem trạng thái thực của thí sinh và lần hoạt động gần nhất.
  Accepted when: thấy cả người chưa tạo attempt; trạng thái khớp CREATED / IN_PROGRESS / SUBMITTED; heartbeat được ghi là “Lần hoạt động gần nhất”, không cam kết online/offline.
- **[P1]** Là Proctor được phân công, tôi ghi nhận vi phạm và yêu cầu nộp bài của attempt đang làm.
  Accepted when: chỉ thao tác trong phiên giám sát của mình và đúng buổi thi; phải xác nhận trước FORCE_SUBMIT; chỉ báo đã nộp khi snapshot backend xác nhận SUBMITTED.
- **[P1]** Là Proctor, tôi xem sự kiện bảo mật của buổi thi và kết thúc phiên giám sát của mình.
  Accepted when: audit có nguồn, loại, thời gian, mức độ và mục tiêu; đóng giám sát không đóng buổi thi hoặc nộp bài hàng loạt.
- **[P2]** Là Proctor, tôi có lịch sử thao tác vận hành có actor và kết quả command để truy vết.
  Accepted when: có contract và storage riêng được phê duyệt; không giả định security audit hiện tại đã hỗ trợ. Chưa thuộc MVP.
- **[P3]** Camera/screen streaming, phát hiện tự động, chat, gia hạn giờ hoặc tạm dừng bài thi: ghi nhận cho tương lai, ngoài phạm vi.

## Screen Design

### Buổi thi được phân công — `/proctor/sessions`

- Giữ DashboardChrome, branding tenant, locale và UI kit hiện có. Navigation Proctor gồm Buổi thi và Hồ sơ.
- Mỗi hàng có tên buổi thi, sessionCode, lịch, trạng thái kỳ thi, vai trò phân công và hành động mở.
- Bộ lọc trạng thái/lịch và tìm kiếm chỉ dùng khi backend hỗ trợ đúng contract; phải lọc phía server trước phân trang, không trình bày lọc một trang như kết quả toàn bộ.
- Buổi thi chưa OPEN: xem thông tin; không mở phiên điều khiển. Buổi đã CLOSED: xem lịch sử/roster; không mở phiên điều khiển mới.
- Có loading ban đầu, lỗi có retry, empty “Chưa có buổi thi được phân công”, phân trang. Không thay bảng bằng skeleton mỗi lần refresh nền.

### Phòng giám sát — `/proctor/sessions/[publicId]`

- Header: tên/code, trạng thái buổi thi, vai trò LEAD/ASSISTANT, tình trạng kết nối và thời điểm snapshot mới nhất.
- Tổng hợp số thí sinh đăng ký, đang làm, đã nộp; tổng hợp từ toàn bộ roster, độc lập trang hiện tại.
- Bảng: thí sinh, attempt đang hiển thị, trạng thái, lần hoạt động gần nhất, số ghi nhận thủ công của giám thị cho attempt (`manualViolationCount`). Không gộp mọi sự kiện lockdown thành vi phạm đã xác nhận. Không hiển thị phần trăm hoàn thành khi chưa có dữ liệu thực.
- Một hàng cho mỗi enrollment; backend trả latest attempt và số thứ tự/lịch sử attempt khi có nhiều lần thi. Panel chi tiết cho phép chọn attempt cụ thể; mọi lệnh sử dụng UUID của attempt đã chọn, không tự suy diễn từ student UUID.
- Không có attempt: hiển thị “Chưa bắt đầu” từ trạng thái nullable, không tạo enum persist NO_ATTEMPT. CREATED hiển thị “Đã tạo bài”, IN_PROGRESS “Đang làm”, SUBMITTED “Đã nộp”.
- Panel chi tiết: tên, attempt, trạng thái, thời gian hoạt động và sự kiện liên quan. Ghi nhận vi phạm và Yêu cầu nộp bài; thao tác target explicit.
- Drawer/modal ghi vi phạm có enum backend và detail tùy chọn. Các loại MULTIPLE_FACES, FACE_NOT_VISIBLE, SUSPICIOUS_AUDIO là nhãn ghi nhận thủ công, không ngụ ý có camera/audio feed.
- FORCE_SUBMIT chỉ cho attempt IN_PROGRESS, kỳ thi OPEN và phiên giám sát ACTIVE. ConfirmDialog có tên thí sinh/attempt và tác động nộp bài.
- Nút “Kết thúc giám sát” đóng phiên của giám thị, sau xác nhận; không gắn nhãn “Đóng kỳ thi”. Chuyển về danh sách sau thành công.
- Mất kết nối/assignment/quyền: banner rõ, khóa thao tác ngay khi biết; trạng thái stale có timestamp. Điều hướng khỏi phòng không tự đóng monitoring session; có thể resume nếu vẫn đủ điều kiện. Logout/workspace switch dispose connection, không tự kết thúc giám sát.

### Nhật ký sự kiện — `/proctor/audit-log/[publicId]`

- Link theo ngữ cảnh từ buổi thi/phòng giám sát; dùng audit thống nhất, không tạo tab nhật ký actor/action không có contract.
- Hiển thị nguồn STUDENT_LOCKDOWN / PROCTOR, violationType, severity, detectedAt, attemptPublicId, studentPublicId khi có và detail.
- Entry PROCTOR có thể thiếu studentPublicId: đối chiếu bằng projection roster trong đúng buổi thi, không tự đi gọi directory HOST.
- Giữ thứ tự cursor backend (tăng dần thời gian/publicId); “Tải thêm” không lặp hoặc làm mất entry. Không đảo sang newest-first nếu chưa thay query/cursor nhất quán.
- Chưa hỗ trợ server filter: không thêm bộ lọc toàn bộ audit. Bản minh họa không đại diện cho lượng dữ liệu thật.

### Hồ sơ — `/proctor/profile`

Tái sử dụng ProctorProfileView/useCurrentUser, giữ loading/error/retry. Không mở thêm trang quản trị phân công cho Proctor.

## Functional Requirements

1. **FR-01 — Role routing:** bổ sung AUTH_ROUTES và resolver đích đăng nhập tập trung. PROCTOR-only → danh sách; tổ hợp không có PROCTOR giữ hành vi hiện tại. Với nhiều role có PROCTOR, giữ đích mặc định đang hợp lệ nếu có và bổ sung chuyển workspace được phép. Guard bảo vệ toàn bộ route; wrong-role không tạo vòng redirect giữa login và workspace.
2. **FR-02 — Assigned list:** actor lấy từ JWT; chỉ trả assignment của actor trong tenant hiện tại. HOST_ADMIN vẫn quản lý phân công bằng endpoint hiện có; không mở quyền HOST_ADMIN cho Proctor.
3. **FR-03 — Monitoring snapshot:** chỉ PROCTOR đang được phân công, trong đúng tenant; chứa session metadata, assignment role, aggregate counts, enrollment + latest attempt, heartbeat, số vi phạm và dữ liệu lịch sử attempt khi mở chi tiết. Không trả đáp án, điểm chi tiết hay dữ liệu hồ sơ không cần thiết.
4. **FR-04 — Identifiers:** route/topic dùng examSessionPublicId; open response `publicId` là proctorSessionPublicId dùng khi SEND command/violation và REST close. Phải khai báo type/adapter rõ để không trộn hai ID.
5. **FR-05 — Open/resume:** PROCTOR, tenant, assignment còn hiệu lực và kỳ thi OPEN trong thời gian entry gate cho phép; resume cũng recheck. Mỗi actor chỉ resume phiên ACTIVE của mình cho cùng buổi thi. LEAD/ASSISTANT có cùng quyền theo backend hiện tại.
6. **FR-06 — Commands:** xác thực ownership/ACTIVE, tenant, assignment và target attempt thuộc đúng exam session; kiểm tra kỳ thi còn OPEN bằng gate hiện có. Attempt không tồn tại hoặc sai phạm vi bị từ chối; SUBMITTED không bị submit lại. Không replay command sau reconnect/refresh token.
7. **FR-07 — Confirmation:** broadcast command không được coi là success. UI chuyển “Đang xác nhận”, refresh snapshot ngay và theo chu kỳ; trong 10 giây chưa xác nhận thì hiển thị “Chưa xác nhận kết quả”, cho làm mới, không đổi attempt status giả. Khi mất kết nối có thể dùng REST snapshot để xác nhận trạng thái; không gửi lại tự động.
8. **FR-08 — Violation:** validate enum, target tồn tại/thuộc session, actor/tenant/assignment/ownership/ACTIVE; dedupe hiển thị bằng event publicId. Ghi vi phạm chỉ trong khi giám sát kỳ thi OPEN; xem lịch sử sau CLOSED vẫn được phép nếu còn phân công.
9. **FR-09 — Close:** REST close phiên của mình, idempotent. Cho phép dọn phiên của mình sau kỳ thi đóng hoặc assignment bị thu hồi; không cấp quyền đọc roster/gửi lệnh vì quyền close này. Không gọi API đóng exam session.
10. **FR-10 — Read access:** monitoring/audit chỉ theo tenant + assignment; không chỉ dựa vào role hoặc ẩn nút. Legacy violations endpoint phải áp cùng assignment check, hoặc UI chỉ dùng security-audit và route legacy được sửa để không vượt phạm vi.
11. **FR-11 — STOMP:** dùng `/ws`, CONNECT Authorization Bearer như backend; bảo vệ SEND lẫn SUBSCRIBE. Chỉ subscribe topic buổi thi được phân công và user queue của bản thân. Thu hồi assignment chặn mọi thao tác và lượt cấp quyền gửi mới sau commit, kể cả subscription cũ; không chờ reconnect. Ranh giới gửi là snapshot của truy vấn quyền recipient ngay trước handler: message đã được cấp quyền trước commit có thể hoàn tất sau commit. Không cam kết thu hồi bytes/message đang gửi; plan phải kiểm thử cả message chờ trước kiểm tra và message đã vượt kiểm tra quyền.
12. **FR-12 — Lifecycle:** token refresh/reconnect có backoff hữu hạn; dispose socket/subscriptions/query cache theo lifecycle auth. JWT không nằm URL/log. Rời phòng unsubscribe; trở lại chỉ resume sau auth check. Mất quyền chuyển sang trạng thái bị từ chối, không tiếp tục polling không giới hạn.
13. **FR-13 — Polling:** mặc định monitoring snapshot 5 giây, tạm dừng khi tab ẩn; refetch khi tab hiện lại/reconnect hoặc nhận sự kiện liên quan. Tránh duplicate timer và burst request. Audit dùng “Tải thêm” và “Làm mới”: làm mới lấy lại trang đầu, chỉ thay danh sách sau thành công, reset cursor và ghi timestamp; lỗi giữ dữ liệu cũ. Không polling tail hoặc cam kết audit realtime vì endpoint hiện trả nextCursor=null tại cuối và không có feed lockdown. Dedupe publicId giữa các trang; ghi rõ dữ liệu tại lần tải mới nhất.
14. **FR-14 — Feature rollout:** giữ `NEXT_PUBLIC_PROCTOR_UI_ENABLED` mặc định tắt cho đến khi API/authorization/integration checks đạt yêu cầu. Login resolver và workspace switcher phải cùng đọc khả năng rollout; khi tắt không điều hướng đến route 404, hiển thị thông báo workspace chưa khả dụng cho PROCTOR-only.
15. **FR-15 — States/localization:** loading/error/empty/access denied/stale/closed đều có giao diện, actions pending chống double-click. Toàn bộ product text qua locale hiện có; demo dùng tiếng Việt và dữ liệu minh họa.

## API Contracts: Existing versus Proposed

| Contract | Trạng thái | Phạm vi/hành vi |
| --- | --- | --- |
| `GET /api/v1/proctor-assignments/mine` | **MỚI** | Session module; actor JWT, tenant + assignment. Page mặc định 25, cap 100. Filter/search server-side nếu đưa vào UI. DTO: assignmentPublicId, assignmentRole, examSessionPublicId, name/code, state, schedule. |
| `GET /api/v1/exam-sessions/{id}/monitoring` | **MỚI** | Proctoring orchestration qua facade công khai. Metadata/summary + paginated roster (25, cap 100), latest attempt/lastSeenAt/manualViolationCount. Search/status filter server-side trước pagination. |
| `GET /api/v1/exam-sessions/{id}/monitoring/students/{studentId}/attempts` | **MỚI** | Chi tiết lịch sử attempt cho enrollment trong chính buổi thi, có phân trang cap 100; same tenant/assignment check. Giúp giữ snapshot nhỏ, không kéo toàn bộ lịch sử mỗi 5 giây. |
| SEND `/app/sessions/{examSessionId}/open` → `/user/queue/proctor-session` | Có sẵn; cần harden | Response `{publicId,sessionPublicId,proctorPublicId,status,openedAt}`; `publicId` là monitoring ID. Xác thực điều kiện khi open/resume. |
| SEND `/app/proctor-sessions/{monitoringId}/commands` | Có sẵn; cần harden | `{attemptPublicId,commandType:"FORCE_SUBMIT"}`; không suy diễn success từ topic broadcast. |
| SEND `/app/proctor-sessions/{monitoringId}/violations` | Có sẵn; cần harden | `{attemptPublicId,violationType,detail?}`; chặn target ngoài session. |
| SUBSCRIBE `/topic/proctor-sessions/{examSessionId}` | Có sẵn; cần harden | Hiện có payload command/violation khác nhau, không envelope; adapter runtime phân biệt đúng schema, bỏ payload không hợp lệ. Không phá tương thích client bằng đổi envelope ngầm. |
| `POST /api/v1/proctor-sessions/{monitoringId}/close` | Có sẵn | Close monitoring của mình; không đóng kỳ thi. |
| `GET /api/v1/exam-sessions/{id}/security-audit?limit=50&cursor=...` | Có sẵn | Limit 1–100; `{entries,nextCursor}`. Cursor server-issued, giữ tenant/session scope, entries tăng dần. |

**Errors:** dùng ApiResponse/domain exceptions hiện tại; giữ semantics 401/403 và tài nguyên không tồn tại theo convention. Backend đã có `/user/queue/errors` với `{status,code}`; phải giữ tương thích. Plan bổ sung response/error riêng có correlation ID cho client mới, không đổi topic payload ngầm; command/violation UI nhận denial/validation và kết thúc pending. Chi tiết envelope do plan chốt, không expose stacktrace. Opening có timeout 10 giây/retry thủ công; không tự tạo nhiều open concurrent. Violation phải được xác nhận đã lưu từ private response, không phụ thuộc topic broadcast tới nhiều giám thị.

## Codebase Placement

- Backend list assignment đặt ở session module; monitoring orchestration đặt ở proctoring. Queries theo tenant/assignment và facade batch giữa session/attempt/identity; không import repository/internal DTO của module khác. Số truy vấn bounded theo trang, không truy vấn một lần cho mỗi thí sinh.
- Controllers/services/repositories/mappers/records theo cấu trúc `app/src/main/java/com/pte/{module}/internal/...`; exports bằng public facade/NamedInterface đúng convention. SQL/schema thay đổi nếu thực sự cần: migration Flyway mới, không sửa migration đã phát hành.
- Frontend routes giữ `apps/tenant-web/app/(dashboard)/proctor/...`; views/hooks/query keys ở `apps/tenant-web/features/proctor`, constants navigation tại lib hiện có. Không tạo `apps/tenant-web/src`.
- DTO và raw request mới ở `packages/api-client/src/types` và `requests` theo resource, hooks TanStack tại feature; local types chỉ cho presentation. Không dùng segment retired `/api/v1/proctor/...`.
- Reuse DataTable, PageHeader, Badge, Drawer/Modal, ConfirmDialog, ErrorState, EmptyState, Toast và DashboardChrome từ `@pte/ui`. Respect kích thước file/component và Tailwind/locale convention trong CODING_STANDARDS_WEB.
- Trước khi viết Next product code đọc `pte-web/AGENTS.md` và guide Next tại `node_modules/next/dist/docs` như repo yêu cầu.

## Non-Functional Requirements

- **Freshness:** khi tab active, snapshot poll 5 giây; bản ghi heartbeat hiển thị timestamp thực, stale badge khi snapshot không thành công sau 2 chu kỳ. Không claim online/offline từ threshold này.
- **Data bounds:** page mặc định 25, cap 100 cho roster/list/history, audit cap 100; không có API trả toàn bộ roster không giới hạn cho mỗi refresh. Search/filter cả dataset phía server, counts độc lập filter/page và nhãn ghi rõ tổng toàn buổi thi.
- **Security:** 100% read/write/subscription deny cases ngoài tenant/phân công/ownership có test; zero cross-session attempt mutations và zero lượt cấp quyền topic delivery mới sau commit thu hồi, theo ranh giới FR-11, được xác nhận trong integration test.
- **Reliability:** timeout pending open/command 10 giây; command không retry tự động. Reconnect backoff 1/2/4/8/16/30 giây, cap 30 giây; dừng khi logout, denied hoặc unmount.
- **Accessibility:** thao tác bằng keyboard, labels cho form, focus management dialog/drawer và focus restore; trạng thái ngoài màu. Kiểm tra widths 320, 768, 1024; phần chi tiết xuống dưới trên màn hẹp, bảng có overflow riêng khi cần.
- **Performance verification:** chứng minh không có N+1 bằng test/query inspection trên fixture 100 enrollment; đo API latency/payload trong plan trên hạ tầng thực trước khi đặt SLA. Không cam kết SLA chưa có baseline.

## Success Criteria

- [ ] PROCTOR-only đăng nhập vào đúng workspace khi flag bật; khi tắt thấy trạng thái khả dụng, không vòng redirect/404. Role matrix gồm HOST_ADMIN, STUDENT, EXAMINER và PROCTOR cùng các tổ hợp liên quan giữ quyền đúng.
- [ ] Assigned list và monitoring dùng API thật; zero query stub trả `[]`; enrollment chưa attempt và cả 3 AttemptStatus hiển thị đúng.
- [ ] Unauthorized tenant/assignment/topic/target attempt bị backend từ chối; resume và subscription cũ sau thu hồi không vượt quyền.
- [ ] FORCE_SUBMIT happy path xác nhận bằng SUBMITTED thực; no-op/denied/disconnect/timeout không báo thành công giả, không duplicate automatic command.
- [ ] Ghi vi phạm xuất hiện đúng một lần trong audit sau làm mới; pagination không mất/lặp entry trên dataset ổn định; sources đúng contract. Refresh bắt được sự kiện mới cả khi trang cũ đã tới cuối.
- [ ] Close monitoring không thay đổi exam session state; CLOSED/pre-OPEN chặn thao tác theo spec.
- [ ] Vitest request/role contract checks, backend service/security/Modulith checks và smoke trình duyệt cho các luồng P1 pass trước bật flag.
- [ ] Không có dữ liệu/role quản trị HOST bị đưa vào Proctor projection; không tạo thư mục/file trái convention.

## Out of Scope

- Video, camera, microphone, screen streaming; AI phát hiện gian lận tự động.
- Tạo/sửa/đóng kỳ thi, phân công giám thị, quản trị user/tenant, chấm điểm hoặc xem đáp án.
- Thay đổi quyền giữa LEAD và ASSISTANT; lệnh pause/resume/extend-time không có contract.
- Nhật ký command có actor bền vững (P2), bulk FORCE_SUBMIT, quản trị toàn bộ tenant.

## Assumptions

- Người dùng đã chọn giao diện hoàn chỉnh, cho phép API bổ sung và duyệt thiết kế bảng + panel qua câu trả lời “Duyệt thiết kế → $ck:plan rồi triển khai (Đề xuất)” ngày 2026-10-11.
- Quyền Proctor đến từ JWT và phân công trong session, không từ selector frontend. Assignment role là metadata, chưa là permission tier.
- Snapshot là nguồn sự thật; websocket hỗ trợ thao tác/cập nhật nhanh, chưa có feed progress/presence đầy đủ.
- Khi có nhiều attempt, latest là attempt có `attemptNumber` lớn nhất theo sequence bất biến hiện có của domain; query tenant/session/student và deleted=false. Lệnh luôn nhắm attempt explicit, lịch sử không bị gộp mất.
- Prototype chỉ dùng dữ liệu minh họa cục bộ. Đây là design artifact, không phải trang đã tích hợp API.
