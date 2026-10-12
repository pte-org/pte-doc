# Phase 1 — Sidebar & Overview

Status: planned, chờ phê duyệt. Chỉ tài liệu; không triển khai.

## 1. Mục tiêu

Tách dashboard tổng quan khỏi danh sách ca đầy đủ; mỗi mục Overview, Monitoring, Attendance, Incidents, Audit Log và Hồ sơ có một trách nhiệm rõ ràng. Đây là tài liệu công việc dự kiến, không phải thay đổi đã triển khai.

## 2. Hiện trạng

- **Existing:** tenant-web có Next.js App Router, layout Proctor, navigation theo role/feature flag, route sessions, attendance, audit-log và profile. `AssignedSessionsView` đang gộp overview cards, priority preview và danh sách ALL/ACCESSIBLE/UPCOMING/TODAY. API overview trả counts, prioritySessions, asOf, timezone và day boundaries; danh sách trả metadata phân trang.
- **Missing:** chưa có mục Incidents với quy trình xử lý riêng. Chưa có server search cho assigned sessions; không gọi bộ lọc phía trình duyệt là tìm kiếm toàn danh sách.
- **Needs Modification:** dùng DataTable chung thay raw table cho danh sách; tách responsibilities mà không mất URL scope/page, timezone và midnight refresh.
- **Needs Confirmation:** vòng đời incident đã được người dùng xác nhận; counts “cảnh báo cần xử lý” cần projection theo các trạng thái case được định nghĩa ở Phase 4, không suy ra số chưa xử lý từ toàn bộ violation lịch sử. Không chờ hỏi lại quyết định đã trả lời.

## 3. Chức năng bổ sung

Overview hiển thị counts từ projection có sẵn, lịch hôm nay, ca sắp tới thông qua liên kết scope tương ứng, tối đa năm ca ưu tiên và quick links tới điểm danh/giám sát/audit. Không đặt full queue hoặc bảng incident tại Overview. Monitoring list sở hữu full assigned-session queue và bộ lọc scope. Hồ sơ hiển thị thông tin `auth/me` chỉ đọc và link về cùng danh sách phân công, không tạo tab lịch sử ca trùng dữ liệu.

## 4. Luồng nghiệp vụ

Giám thị có role PROCTOR và phân công trong tenant đăng nhập → xem overview → chọn ca/scope → mở Attendance hoặc Monitoring. Input gồm actor, tenant, timezone và session public ID; bước này chỉ đọc, không thay đổi trạng thái ca. `canMonitor` và blocking reason từ backend quyết định lời gọi hành động. Ca CLOSED/CANCELLED có điều hướng đọc theo policy hiện hành; mất assignment hoặc phiên đăng nhập không hợp lệ dẫn tới trạng thái unavailable/forbidden. Hoàn thành bước khi đúng ca được chọn và context được giữ qua điều hướng. Host tạo/quản lý phân công theo luồng hiện hữu; sidebar không cấp thêm quyền cho Admin hoặc LEAD_PROCTOR.

## 5. Frontend changes

- Giữ route hiện tại: `/proctor/sessions` không có scope là Overview; `/proctor/sessions?scope=ACCESSIBLE` là điểm vào Monitoring list. Giữ valid scopes khác và query filters/page hiện hữu; link cũ có scope vẫn mở list. Điều chỉnh `/proctor` redirect và active navigation theo pathname cộng query state.
- Tách overview composition từ `AssignedSessionsView`; giữ `ProctorWorkspaceOverview`, `ProctorPrioritySessions` và hooks timezone. Cards và priority rows vẫn là preview, không ép thành DataTable.
- Full queue và `AssignedSessionPicker` dùng một reusable assigned-session DataTable với typed columns, stable assignment/session keys, `rowActions` và ActionMenu; picker mode attendance/audit/incidents quyết định link, không nhân bản table shell.
- Dùng controlled search và filters slot với common Select/TableFilterInput; chỉ bật search sau API extension. Tắt client filtering/sorting/pagination cho server pages. Các cột chưa có controlled server sort phải `sortable=false`; dùng Select sort được API hỗ trợ nếu cần.
- Initial loading dùng common LoadingState; empty phân biệt chưa phân công và scope không có kết quả; ErrorState có retry. Refresh giữ dữ liệu cũ, hiện cảnh báo stale khi thất bại. Common pagination slot dùng metadata thật, adapter page API 0-based sang UI 1-based; reset page khi filter đổi, sửa trang vượt phạm vi.

## 6. Backend/API changes

Tái sử dụng GET `/api/v1/proctor-assignments/mine` và `/mine/overview`. Đề xuất thêm search vào assigned query/DTO/client/query key; search và mọi filter áp dụng trước paging, counts độc lập với trang đang tải. Overview unresolved-incident count phụ thuộc projection scoped NEW/IN_PROGRESS/ESCALATED tại Phase 4. Giữ SessionService facade, tenant/actor scope, sort whitelist và timezone/day-boundary semantics.

## 7. Database changes dự kiến

Không cần schema change để tách navigation/dashboard. Reuse ProctorAssignment → ExamSession và quan hệ room hiện có; counts/search qua query projection. Chỉ đề xuất index nếu truy vấn thực tế cần sau khi chốt search contract; không tạo migration trong công việc lập kế hoạch.

## 8. File dự kiến tạo/sửa

Paths dưới `pte-web`: `apps/tenant-web/lib/navigation.tsx`, `lib/navigationConstants.ts`; `app/(dashboard)/proctor/page.tsx`, `sessions/page.tsx`; `features/proctor/components/AssignedSessionsView.tsx`, `AssignedSessionPicker.tsx`, `ProctorWorkspaceOverview.tsx`, `ProctorPrioritySessions.tsx`, `ProctorProfileView.tsx`; dự kiến thêm `ProctorOverviewView.tsx`, `AssignedSessionTable.tsx`; `features/proctor/api.ts`, `queryKeys.ts`, `messages/{en,vi}.ts`; `packages/api-client/src/requests/proctoring.ts`, `types/proctoring/index.ts`. Paths dưới `pte-api/app/src/main/java/com/pte`: `session/internal/controller/ProctorAssignmentQueryController.java`, `session/SessionService.java` và assigned-query implementation/projections thuộc Session.

## 9. Dependencies

Common DataTable và navigation permission hiện hành; projection overview/assigned đã có. Phase 2 dùng list shell; Phase 3/4 dùng picker. Incident projection Phase 4 chặn riêng unresolved-incident count, không chặn tách dashboard.

## 10. Functional acceptance criteria

- Overview chỉ có tóm tắt/preview; mỗi action mở đúng scope hoặc đúng ca.
- Deep link, refresh và browser back khôi phục scope/page hợp lệ; TODAY dùng timezone và đổi ngày đúng context hiện có.
- Counts lấy từ toàn phạm vi server, không từ số rows trang hiện tại.
- Queue/picker dùng DataTable chung và pagination thật; search không bỏ sót ca ngoài trang đã tải.
- Hồ sơ chỉ đọc và không lặp chức năng queue; feature flag vẫn tắt.

## Design Constraints

DataTable-first; không dựng table shell/style riêng. Reuse tokens, StatusBadge/Badge, common controls và state components. Không mở rộng quyền, không sửa luồng Host/Examiner/Candidate, không đổi module ownership. Giữ lịch sử năm phase kỹ thuật đã hoàn thành; phase này chỉ là kế hoạch chức năng mới.
