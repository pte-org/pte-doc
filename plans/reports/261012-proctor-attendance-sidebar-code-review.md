# Review sidebar và điểm danh Proctor — 2026-10-12

Phạm vi: thay đổi chưa commit trong pte-api/pte-web, đối chiếu spec và 5 phase tại `plans/proctor-attendance-sidebar`. Review source và kiểm tra compile/typecheck; không sửa source, không chạy test/E2E. Các vấn đề dưới đây có tình huống và vị trí cụ thể; đây không phải cam kết rằng hệ thống không còn lỗi khác.

## Lỗi cần sửa

### R1 — P1: Hai service không có constructor được Spring chọn để injection

- `pte-api/app/src/main/java/com/pte/session/internal/service/AttendanceCommandService.java:52` và `:67`.
- `pte-api/app/src/main/java/com/pte/session/internal/service/AttendanceQueryService.java:36` và `:47`.

Mỗi `@Service` có hai constructor public, không constructor mặc định và không `@Autowired`. Cơ chế implicit constructor injection chỉ áp dụng khi có một constructor; cấu hình hiện tại không chỉ ra constructor cần dùng, gây lỗi tạo bean khi khởi động application context. Java compile không phát hiện lỗi này. Không thấy factory đăng ký thay thế trong source. Giữ một constructor nhận Clock hoặc đánh dấu constructor injection; dùng ClockConfig hiện có.

Kết luận từ source, được reviewer độc lập xác nhận; chưa chạy startup.

### R2 — P1: PATCH điểm danh serialize JSON hai lần

- `pte-web/packages/api-client/src/requests/attendance.ts:56` và `:110`.
- Đối chiếu `packages/api-client/src/client/client.ts:281`.

`recordAttendance` và `recordHostAttendance` truyền `body: JSON.stringify(request)`, trong khi ApiClient tiếp tục JSON.stringify body. Trên wire, body trở thành JSON string chứa JSON thay vì object. Spring nhận `@RequestBody RecordAttendanceRequest` không thể bind object từ payload này; thao tác Có mặt/Vắng mặt/đính chính của cả hai role bị lỗi 400. Truyền trực tiếp object request theo convention ApiClient.

### R3 — P1: Proctor bị gỡ phân công vẫn đọc được receipt và snapshot hiện tại

- `pte-api/app/src/main/java/com/pte/session/internal/service/AttendanceCommandService.java:281`.

`getReceipt` chỉ scope theo tenant, actor và request UUID, không kiểm tra assignment hiện tại. Controller chỉ kiểm tra role PROCTOR; coordinator và SessionService chuyển tiếp, không bổ sung authorization. Người từng điểm danh, sau đó bị unassign nhưng vẫn giữ role, có thể gọi UUID cũ để nhận `currentAttendance`, gồm những cập nhật sau này của Host/Proctor khác. Kiểm tra quyền đọc hiện tại trước lookup/disclosure receipt, giống policy của roster/history. Reviewer độc lập xác nhận đường gọi này.

### R4 — P2: Unenroll chưa tham gia session mutex

- `pte-api/app/src/main/java/com/pte/session/internal/service/EnrollmentService.java:170`.
- `AttendanceCommandService.java:89` và `:133`.

Host có thể xóa enrollment trong ca thủ công SCHEDULED; điểm danh cũng được phép trong trạng thái này từ opensAt−30 phút. Attendance khóa session rồi đọc enrollment, nhưng unenroll dùng `findOwned` không khóa. Host có thể xóa và commit sau bước validation enrollment; attendance vẫn commit trạng thái/receipt cho enrollment vừa bị xóa và trả thành công trong khi roster không còn sinh viên. Đổi unenroll sang mutex `findOwnedWithLock`, kiểm tra lại điều kiện sau khi lấy khóa. Đây là bước phase 02 đã đánh dấu xong nhưng source chưa thực hiện. Reviewer độc lập xác nhận tình huống SCHEDULED có thể xảy ra.

### R5 — P2: Exact retry bị chặn bởi lifecycle trước khi tìm receipt

- `pte-api/app/src/main/java/com/pte/session/internal/service/AttendanceCommandService.java:100` và `:145`.

Command đã commit nhưng response bị mất; Proctor vẫn được phân công retry đúng UUID/payload sau closesAt hoặc sau khi Host đóng ca. Lifecycle/window validation chạy trước receipt lookup nên request bị từ chối thay vì trả kết quả cũ, mặc dù retry này không tạo thay đổi mới. Enrollment hiện tại cũng được kiểm tra trước lookup, làm recovery thất bại khi membership thay đổi. Thứ tự cần là quyền đọc hiện tại → kiểm tra fingerprint/receipt → chỉ áp dụng lifecycle/enrollment/version cho command mới. Phải bảo toàn yêu cầu từ chối người đã bị thu hồi quyền.

### R6 — P2: Modal mất confirmed intent khi outcome chưa rõ

- `pte-web/apps/tenant-web/features/proctor/components/RecordAttendanceModal.tsx:69`, `:91`, `:105`, `:125`.

Sau timeout/network error, người dùng vẫn sửa reason và gửi lại bằng cùng request UUID; nếu command cũ đã commit thì đây là intent khác và backend trả idempotency conflict. Nếu đóng/mở modal, UUID mới được tạo, mất liên kết với command cũ. Frontend không giữ frozen payload theo sinh viên và không gọi receipt reconciliation; hai hàm receipt chỉ được import trong api.ts, chưa được dùng. Version guard hạn chế ghi đè nhưng không giải quyết việc UI không biết command nào đã commit.

Giữ nguyên payload/key đã xác nhận ngoài modal đến khi đối soát xong; hiển thị outcome chưa rõ, dùng receipt và authorized refetch; chỉ cho exact retry có kiểm soát. Không mở intent mới hoặc thay payload trong khi command cũ chưa được xác định. Modal chung được dùng cho cả Host và Proctor.

### R7 — P2: Thời gian kiểm tra cutoff được lấy trước khi chờ khóa

- `pte-api/app/src/main/java/com/pte/session/internal/service/AttendanceCommandService.java:86` và `:89`.

Request đến trước closesAt, bị chờ session lock rồi được thực thi sau closesAt trong lúc trạng thái vẫn OPEN. `now` vẫn là thời điểm trước khi chờ, nên command mới vượt cutoff vẫn được chấp nhận và audit timestamp cũng là thời gian cũ. Lấy clock sau khi acquire lock, trước validation command mới. Trạng thái CLOSED hiện tại có thể chặn một số trường hợp nhưng không thay thế cutoff theo thời gian.

### R8 — P2: UI lịch sử không truy cập được các trang sau

- `pte-web/apps/tenant-web/features/proctor/components/AttendanceHistoryModal.tsx:51` và `:62`.
- Đối chiếu `features/proctor/api.ts:309`, `:350` (mặc định page0/size20).

Modal luôn gọi page0, bỏ qua meta và không có pagination/load more. Khi sinh viên có hơn 20 thay đổi, Host/Proctor chỉ thấy 20 bản ghi mới nhất; cuộn modal không tải thêm nên audit cũ không thể xem qua UI. Thêm page state và controls theo response meta, reset khi đổi sinh viên/session. Cả hai role chịu ảnh hưởng.

## Chênh lệch kế hoạch và chuẩn code

### C1: Version reset sau re-enrollment trái contract monotonic đã chốt

`AttendanceCommandService.java:163`, `:220`, `:233`; `AttendanceQueryService.java:195`.

Khi row thuộc enrollment cũ, read trả version0 và command mới ghi lại row với version1. Phase 02 quy định version0 chỉ khi chưa có row; row khác generation phải hiển thị UNMARKED nhưng giữ version và increment lần kế tiếp. Cần đồng bộ contract giữa read/write/snapshot. Enrollment UUID hiện vẫn chặn stale generation, nên không diễn giải điểm này thành lỗi ABA đã được chứng minh.

### C2: Chưa tích hợp locale và safe error copy cho màn hình mới

`pte-web/apps/tenant-web/lib/navigation.tsx:116`, `:174`; `features/proctor/components/RecordAttendanceModal.tsx:106`; `ProctorAttendanceView.tsx:97`.

Các labelKey mới không có trong `packages/ui/src/i18n/LocaleProvider.tsx`, nên menu fallback tiếng Anh trong locale tiếng Việt. Các màn hình/modal lại dùng chuỗi tiếng Việt trực tiếp và locale `vi-VN`, không đổi theo locale người dùng. Modal ghép raw error message và view hiển thị machine blockingReason trực tiếp. Bổ sung catalog/constants và mapping mã lỗi/capability sang copy an toàn theo locale, đúng AGENTS.md. Không coi đây là lỗi encoding: output PowerShell hiển thị ký tự tiếng Việt sai không chứng minh file source sai encoding.

## Những điểm đã đối chiếu

- Sidebar có mục riêng Proctor/Examiner; resolver dùng query để chọn một mục active, giữ override Host Classes và dùng cùng active item cho breadcrumb. Chưa thấy lỗi cụ thể trong các đường đi đã đọc.
- Attendance độc lập với attempt; roster LEFT JOIN enrollment và lọc trạng thái trước pagination; summary toàn roster không phụ thuộc filter/search/page.
- Backend history đã lọc `changed=true`; no-op receipt không bị hiển thị như transition. Migration dùng full_name/username khớp schema Identity hiện có.
- Lý do bắt buộc cho correction/reset từ trạng thái đã đánh dấu và mọi thao tác Host; initial ABSENT của Proctor không bắt buộc. Không thêm điều kiện điểm danh vào quyền bắt đầu thi.

## Kiểm tra thực tế và giới hạn

- Backend: Maven offline `-pl app -am -DskipTests compile` exit0, BUILD SUCCESS; compiler báo classes đã up-to-date, không phải clean rebuild.
- Tenant web: chạy trực tiếp tsc đã cài `--noEmit --incremental false`, exit0.
- Không chạy unit/integration/E2E, full Next production build, application startup, migration hoặc SQL runtime. Compile/typecheck không xác nhận các hành vi runtime trên.
- Reviewer độc lập kiểm chứng R1/R3/R4 từ source; các finding còn lại được đối chiếu trực tiếp đường gọi/contract.
- Không sửa source hoặc pnpm-lock.yaml. Báo cáo này là artifact duy nhất được thêm.
