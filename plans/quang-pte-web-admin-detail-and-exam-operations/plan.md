# Plan: Chuẩn hóa detail admin và vận hành vòng đời kỳ thi

Status: Implemented in code; Docker health/basic browser smoke pass, full E2E remains pending  
Date: 2026-10-13  
Scope: `pte-web`, `pte-api`, `pte-doc`

## 1. Mục tiêu

Gom các quyết định đã thống nhất cho khu vực host/admin thành một kế hoạch triển khai thống nhất:

- Các màn hình detail dùng cùng một cấu trúc breadcrumb, tab, action và inline edit.
- Program, class, learner và exam không lặp lại tiêu đề, trạng thái hoặc action ở nhiều vị trí.
- Bảng dùng common UI; nút tạo/thêm nằm trong toolbar của table và hỗ trợ song ngữ.
- Vòng đời kỳ thi phản ánh đúng ý nghĩa nghiệp vụ của `DRAFT`, `PREPARING`, `READY`, `SCHEDULED`, `OPEN`, `CLOSED`, `CANCELLED`.
- Cho phép chỉnh sửa có kiểm soát trước và trong thời gian thi, nhưng không dùng `PREPARING` làm trạng thái tạm khi người dùng mở form.
- Backend là nơi quyết định quyền sửa, transition, thời gian và concurrency; frontend chỉ hiển thị capability tương ứng.
- Không triển khai Archive/Lưu trữ và không gửi thông báo hủy kỳ thi cho student.

## 2. Quyết định đã chốt

### 2.1. Quy tắc detail UI

1. Tên bản ghi ở breadcrumb là tên chính của trang detail; bỏ heading lặp lại ngay bên dưới breadcrumb.
2. Status đặt trong panel thông tin nghiệp vụ, không đặt thêm một badge giống hệt ở page header.
3. Action chính của bản ghi đặt trong common `ActionMenu` (`...`). Chỉ giữ nút nổi bật riêng cho thao tác thật sự thường xuyên hoặc nguy hiểm đã được quy định.
4. Chỉnh sửa thông tin bản ghi hiển thị inline trong panel detail, theo pattern của Learner và Exam Staff; không mở một form popup cho chỉnh sửa thông tin chính.
5. Các dialog nghiệp vụ riêng vẫn được giữ: import Excel, chọn học viên, reset password và confirm thao tác không thể hoàn tác.
6. Không thay đổi font, màu, kích thước, variant hoặc trigger mặc định của `@pte/ui` để bắt chước ảnh mockup.
7. Tất cả user-facing copy phải đi qua locale/catalog hiện có; mọi label và message mới phải có VI/EN.
8. Dọn bản copy legacy trong `apps/tenant-web/components`; component dùng chung phải lấy từ `@pte/ui` hoặc package/feature đúng trách nhiệm.

### 2.2. Quy tắc vòng đời kỳ thi

| Status | Ý nghĩa | Quyền chỉnh sửa đề xuất | Action chính |
|---|---|---|---|
| `DRAFT` | Bản nháp chưa phát hành | Sửa toàn bộ field draft | Sửa, chuẩn bị/sinh đề, xóa bản nháp |
| `PREPARING` | Backend đang chuẩn bị/sinh đề | Không sửa; chỉ hủy job sinh đề | Theo dõi hoặc hủy sinh đề |
| `READY` | Đã sinh snapshot, sẵn sàng phát hành | Không sửa nội dung snapshot | Phát hành/lên lịch, hủy |
| `SCHEDULED` | Đã phát hành, chưa tới `opensAt` | Sửa các field được phép trước giờ thi | Sửa, mở sớm nếu được phép, hủy |
| `OPEN` | Kỳ thi đang diễn ra | Chỉ sửa field vận hành khẩn cấp, trước hết là gia hạn `closesAt` | Sửa giới hạn, đóng kỳ thi |
| `CLOSED` | Đã kết thúc | Chỉ xem và thực hiện flow chấm/kết quả | Không sửa, không xóa, không archive |
| `CANCELLED` | Đã hủy, trạng thái terminal | Chỉ xem lịch sử | Không sửa, không xóa, không archive |

`OPEN` là status nghiệp vụ khi tới giờ thi. Trạng thái `editing`, `saving` hoặc `near-start-warning` chỉ là UI state, không được ghi vào `SessionStatus`. Không chuyển `SCHEDULED -> PREPARING` khi host bấm Chỉnh sửa vì `PREPARING` dành cho generation workflow.

Luồng thời gian mục tiêu:

```text
DRAFT -> PREPARING -> READY -> SCHEDULED -> OPEN -> CLOSED
                                  |           |
                                  +-> CANCELLED
```

- Khi tới `opensAt`, worker hoặc cơ chế mở tự động chuyển `SCHEDULED -> OPEN` idempotently.
- Khi tới `closesAt`, worker tự động chuyển `OPEN -> CLOSED` idempotently.
- Cửa sổ làm bài của student vẫn là `[opensAt, closesAt)`, độc lập với việc host đang mở form.
- Nếu form được mở lúc `SCHEDULED` nhưng save sau khi đã tới giờ, backend phải đánh giá lại status/time tại thời điểm save và áp dụng rule của `OPEN`.

### 2.3. Quy tắc cảnh báo thời gian

- Ngưỡng cảnh báo mặc định là 10 phút trước `opensAt`, đặt trong feature constant.
- Bấm Chỉnh sửa trong khoảng cảnh báo: hiển thị một common confirm dialog trước khi vào edit.
- Nếu đã vào edit từ trước, chỉ hiển thị một cảnh báo khi chạm ngưỡng; không xếp chồng toast và modal cùng lúc.
- Khi save trong hoặc sau thời điểm bắt đầu, nếu `closesAt` chưa được gia hạn, hiển thị confirm nhắc người dùng kiểm tra giờ kết thúc.
- Có thể giữ dữ liệu người dùng đã nhập trong form, nhưng save phải bị backend revalidate; nếu field không còn được phép thì báo lỗi rõ ràng và refetch dữ liệu.
- Lỗi race/concurrency từ backend phải được xử lý bằng common toast/alert và tải lại session; không hiển thị raw API error.

### 2.4. Quy tắc xóa, hủy và thông báo

- Chỉ `DRAFT` được xóa mềm.
- `PREPARING` phải hủy generation job trước và trả về `DRAFT` nếu hủy thành công.
- `READY` và `SCHEDULED` được hủy; `OPEN`, `CLOSED`, `CANCELLED` không được hủy lại.
- Không có Archive/Lưu trữ, Archive filter hoặc Archive API trong phạm vi này.
- Khi hủy, chỉ thông báo cho exam staff active đã được gán vào kỳ thi (`PROCTOR`/`EXAMINER`); không gửi cho `STUDENT`, không broadcast toàn tenant và không phụ thuộc `pte-practice`.
- `CANCELLED`, `CLOSED` và session đã có dữ liệu tham gia phải giữ lại để audit, chấm điểm, báo cáo và đối soát.

## 3. Phạm vi giao diện

### 3.1. Audit và chuẩn hóa tất cả detail view

Rà soát lại toàn bộ route detail tenant/vendor theo danh sách trong `261013-pte-web-detail-breadcrumb-audit.md` và `261013-pte-web-detail-view-consistency.md`:

- Breadcrumb hiển thị đúng mục cha và tên record.
- Không còn tên record lặp ở page heading.
- Không còn status/action lặp giữa page header và panel thông tin.
- Form thông tin chính inline; các editor chuyên dụng và confirm dialog vẫn giữ đúng boundary.
- VI/EN không làm mất tên record, route context hoặc label của common control.
- Không tạo local clone của common button, badge, action menu, modal, table toolbar hoặc toast.

### 3.2. Program detail

- Giữ tab `Tổng quan` và thêm/giữ tab `Danh sách lớp học` cho các lớp thuộc chương trình.
- Bỏ card shortcut “Xem danh sách lớp học” trong overview vì tab đã là điểm truy cập chính.
- Overview chỉ giữ số lớp, số học viên và thông tin chương trình.
- Status nằm trong thông tin chương trình; Chỉnh sửa nằm trong action menu.
- Inline edit chỉ cho phép field được phép sửa; không hiển thị ID kỹ thuật như một field editable.

### 3.3. Class detail và class list

- Breadcrumb theo dạng `Lớp học > Class 1`, không hiển thị thêm heading `Class 1`.
- Tab gồm `Tổng quan` và `Danh sách học viên`.
- Bỏ section Giảng viên vì class hiện không có nghiệp vụ lecturer assignment.
- Inline edit tên lớp trong panel thông tin; field chương trình, status và ID là read-only hoặc ẩn theo nhu cầu.
- Không tự thêm nút xóa class nếu backend chưa có contract và chính sách xóa rõ ràng; trước mắt chỉ hiển thị action đã được backend hỗ trợ.
- Table danh sách lớp có common toolbar action slot ở góc trên bên phải cho `+ Tạo lớp học`.
- Table danh sách học viên của class có cùng toolbar action slot cho `Thêm học viên`.
- Modal thêm học viên phải dùng style/common dialog và có đầy đủ VI/EN cho tab chọn học viên có sẵn, import Excel và thêm từng người.
- Nút import/assignment phải dùng label đúng nghĩa `Thêm hàng loạt` / `Add in bulk`, không dùng label gây hiểu nhầm là thêm một học viên.

### 3.4. Exam list và exam detail

- Exam list bỏ cột `Cấu hình`; thông tin cấu hình chuyển vào tab/panel Tổng quan của detail.
- Bổ sung cột `Thao tác` như các bảng khác.
- Click tên vẫn có thể mở detail, nhưng không phải cách duy nhất: action menu phải có `Xem`.
- `Xóa kỳ thi` chỉ xuất hiện với `DRAFT`; `CANCELLED` không được xóa.
- Exam detail chỉ còn một tab Tổng quan cho identity, lịch, cấu hình và policy; bỏ tab Cài đặt kỳ thi bị trùng.
- Status hiển thị trong panel thông tin, không hiển thị thêm ở page header.
- Menu `...` chứa `Chỉnh sửa` và lifecycle action hợp lệ theo status.
- Form inline theo pattern Learner/Exam Staff; chỉ field editable mới render input/select.
- Khi edit, status dùng common dropdown và chỉ liệt kê transition hợp lệ theo state machine; không cho chọn tùy ý `PREPARING` để né auto-open.
- Mã kỳ thi có thể hiển thị để chia sẻ/copy; ID kỹ thuật và `snapshotPublicId` không hiển thị trong UI.
- `OPEN` hiển thị copy dễ hiểu là “Đang diễn ra” nếu không phá vỡ API enum; giữ enum backend là `OPEN`.
- Badge `DRAFT` dùng màu cảnh báo khác `CLOSED`; không để hai trạng thái nhìn như cùng một nhóm.

## 4. Phạm vi backend và API contract

### 4.1. Capability và transition

1. Đưa transition policy về một boundary backend dùng chung; frontend không phải security boundary.
2. Mỗi request update phải lock hoặc dùng optimistic version để tránh hai operator ghi đè nhau.
3. Mọi update phải kiểm tra lại tenant, status, `opensAt`, `closesAt`, deleted flag và quyền caller.
4. Trả lỗi conflict nghiệp vụ ổn định khi form stale hoặc status đã đổi; không trả raw exception.
5. Có thể expose capability/allowed fields trong response nếu frontend cần hiển thị field disabled chính xác; nếu không, giữ allowlist dùng chung giữa API contract và feature constants.

### 4.2. Endpoint/update boundary dự kiến

- Draft update: giữ endpoint draft hiện có cho `DRAFT`; cho phép chỉnh đầy đủ field draft và kiểm tra `closesAt > opensAt`.
- Policy update: chỉ cho policy thay đổi ở `SCHEDULED` trước giờ bắt đầu, trừ khi có quyết định riêng cho field không ảnh hưởng attempt đã bắt đầu.
- Schedule/operations update: tạo boundary riêng cho `SCHEDULED` và `OPEN`:
  - `SCHEDULED`: cho phép field lịch được allowlist.
  - `OPEN`: chỉ cho phép thay đổi vận hành khẩn cấp, tối thiểu là tăng `closesAt`; không cho lùi `opensAt`, đổi snapshot, đổi skill hoặc đổi policy đã được pin cho attempt.
- Status transition: giữ endpoint transition hiện có nhưng enforce cùng state machine; không dùng status transition để giả lập editing.
- Audit: ghi actor, session, status trước/sau, field thay đổi và thời điểm; không ghi password, token hoặc secret.

### 4.3. Tự động theo thời gian

- Auto-open `SCHEDULED -> OPEN` tại `opensAt`, có lock, retry và audit idempotent.
- Auto-close `OPEN -> CLOSED` tại/sau `closesAt`, dùng cùng transition service với close thủ công.
- Không auto-open session `CANCELLED`, `CLOSED` hoặc deleted.
- Kiểm tra lại time window ở entry gate; không coi status riêng lẻ là đủ để cho student vào làm bài.

## 5. Các phase triển khai

| Phase | Nội dung | Kết quả chính | Phụ thuộc |
|---|---|---|---|
| 01 | Chốt contract và state machine | Status/capability matrix, transition rules, field allowlist, API error contract | Không |
| 02 | Backend lifecycle và time worker | Auto-open/auto-close, close guard, optimistic lock, time-window guard | 01 |
| 03 | Backend edit trong `SCHEDULED`/`OPEN` | Draft/policy/operations update boundary, audit và conflict handling | 01–02 |
| 04 | Exam detail hợp nhất | Overview + settings thành một panel, inline edit, status/action matrix, bỏ ID/snapshot khỏi UI | 01–03 |
| 05 | Exam list và lifecycle actions | Cột action, View, delete draft only, cancel notification trigger, bỏ Archive | 01–03 |
| 06 | Time-aware edit UX | T-10 confirm, warning một lần, save reminder sau khi qua giờ, refetch khi conflict | 03–04 |
| 07 | Program/class/detail consistency | Breadcrumb, tab lớp/học viên, bỏ lecturer/duplicate sections, common table action slot | Không; có thể chạy song song 04 |
| 08 | Common bilingual controls | Toolbar action API, common modal style, VI/EN cho add/import student và action menu | 07 |
| 09 | Cancellation, deletion và staff notification | Soft-delete draft, generation cancel, recipient resolver cho exam staff, no student notification | 01–03 |
| 10 | Regression, Docker và handoff | Test matrix, browser smoke, Docker runtime check, report trong `pte-doc` | 02–09 |

Các phase 01, 02, 05 và 09 kế thừa artifact trong `plans/quang-exam-session-lifecycle/`. Plan này bổ sung và cập nhật quyết định edit/time mới nhất; nếu tài liệu cũ nói “SCHEDULED chỉ sửa policy” hoặc “host chỉ mở thủ công”, phải ưu tiên matrix trong plan này trước khi triển khai.

## 6. Acceptance criteria toàn plan

### Nghiệp vụ

- `PREPARING` chỉ đại diện generation, không bị dùng làm trạng thái khi mở form.
- Tại `opensAt`, session trở thành `OPEN`; operator vẫn có thể sửa field được allowlist mà không đổi status.
- Khi `OPEN`, không thể sửa snapshot, skill, start time hoặc policy đã pin; có thể gia hạn `closesAt` theo rule.
- Save từ form stale không ghi đè dữ liệu mới và không bypass time/status guard.
- Chỉ `DRAFT` xóa được; `CANCELLED`/`CLOSED` không có delete/archive.
- Hủy kỳ thi chỉ thông báo cho assigned active exam staff; không có student recipient.
- Auto-open/auto-close và thao tác thủ công không tạo transition/audit trùng.

### UX

- Detail pages không lặp tên, status hoặc action.
- Program có tab lớp học; class có tab học viên và không còn lecturer section.
- Exam detail có một overview/config panel, inline edit và action menu common.
- Exam list có cột action và View; không còn cột cấu hình trùng với detail.
- T-10 warning, confirm khi vào edit và reminder khi save không tạo stacked popup/toast.
- VI/EN hoàn chỉnh cho label, button, dialog, toast, validation và empty state.
- Table action button nằm trong toolbar common, không hardcode vị trí riêng cho từng table.

### An toàn và dữ liệu

- Tenant isolation, deleted filtering và permission được kiểm tra ở backend.
- Audit không chứa secret hoặc dữ liệu nhạy cảm ngoài contract.
- Snapshot/ID kỹ thuật vẫn được giữ trong API/runtime khi cần, chỉ ẩn khỏi UI theo yêu cầu.

## 7. Verification và artifact

### Frontend

- `pnpm --filter tenant-web exec tsc --noEmit`
- `pnpm --filter tenant-web lint`
- `pnpm --filter tenant-web test`
- `pnpm --filter tenant-web build`
- Nếu sửa common hoặc vendor detail: chạy thêm typecheck/lint/build của package/app bị ảnh hưởng.
- Browser smoke cho từng status và các flow: list → View → edit → save, near-start warning, OPEN extension, delete draft, cancel.

### Backend

- Unit/service/controller test cho allow-deny matrix của status và field.
- Integration test với PostgreSQL cho lock, time boundary, auto-open, auto-close, soft-delete và notification sau commit.
- Test concurrency cho save lúc `opensAt`, close lúc `closesAt`, cancel/delete/generation race.

### Runtime và tài liệu

- Chạy Docker/Compose đúng stack trước khi kết luận runtime pass; báo rõ service nào đã kiểm tra.
- Playwright log, trace và screenshot chỉ đặt trong `D:\GitHub\pte-org\.playwright-mcp`, không đặt trong `pte-web`.
- Sau khi kiểm tra, không giữ ảnh screenshot runtime trong `pte-doc`; chỉ giữ report Markdown/JSON cần truy vết.
- Mọi báo cáo rà soát tiếp theo đặt trong `pte-doc/plans/reports/` hoặc thư mục plan tương ứng.
- Report phải ghi command, môi trường, kết quả, giới hạn kiểm chứng và các warning còn tồn tại.

## 8. Ngoài phạm vi hoặc cần discovery riêng

- Quyết định cardinality host–organization trong backend chưa được thay đổi bởi plan này; cần một discovery/ADR tenancy riêng trước khi sửa schema hoặc permission.
- Không xây student exam platform mới; student chỉ dùng `pte-practice` cho luyện tập.
- Không đổi scoring algorithm, proctoring policy hoặc snapshot schema ngoài phần cần để bảo vệ lifecycle/edit contract.
- Không thêm class delete nếu chưa có domain/API policy rõ ràng.
- Không thêm component UI local nếu common component đã đáp ứng; nếu common thiếu capability thật sự, cập nhật common component và thêm test dùng ở nhiều feature.

## 9. Tài liệu liên quan

- `plans/quang-exam-session-lifecycle/plan.md`
- `plans/reports/261013-exam-session-business-rules-audit.md`
- `plans/reports/261013-pte-web-detail-breadcrumb-audit.md`
- `plans/reports/261013-pte-web-detail-view-consistency.md`
- `plans/reports/261013-program-detail-ui-review.md`
- `docs/CODING_STANDARDS_WEB.md`
