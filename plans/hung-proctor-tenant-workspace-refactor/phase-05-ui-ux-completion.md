# Phase 5 — UI/UX Completion

Status: completed. Stories P01/P02/P10–P13.

## Tasks hoàn thành

- [x] Hoàn thiện mọi Proctor table/picker/history bằng Common DataTable, giữ default theme/controls.
- [x] Bổ sung common opt-in controlled sorting/active-row/cursor/loading-label chỉ khi cần.
- [x] Đồng bộ localized copy/status/capability/error/refresh presentation và truthful notifications.
- [x] Hoàn thiện responsive/common dialogs/actions, giữ active context và unsaved input.
- [x] Giữ Host attendance reuse, profile read-only và feature flag off; không refactor unrelated consumer.

Execution constraints: không chạy tests/lint/typecheck/build hoặc quality audit. Các acceptance dưới đây mô tả behavior cần code, không phải lệnh kiểm tra.

## 1. Mục tiêu

Hoàn thiện presentation Proctor theo design system có thật: tables, controls, light/dark, responsive, states, dialogs và notifications. Không xây lại UI framework hoặc sửa hàng loạt Host/Admin/Examiner consumers.

## 2. Hiện trạng

- **Existing:** @pte/ui DataTable có typed columns/rows/search/filters/actions/loading/empty/mobile/pagination slots; common Select/TableSearchControl/TableFilterInput/DateRangePicker/StatusBadge/ActionMenu/PaginationControls/ErrorState/Modal/ConfirmDialog/useToast. Table tokens có light/dark trong design-tokens.css.
- **Needs Modification:** AssignedSessionsView/AssignedSessionPicker/MonitoringStudentTable/AttendanceRosterTable/AttendanceHistoryModal vẫn raw tables; AuditLogView đã DataTable nhưng cần đúng scope/cursor/refresh states.
- **Missing:** DataTable chưa có controlled header sort/built-in filter callbacks hoặc active-row presentation; PaginationControls chưa có cursor mode. ErrorState compose ngoài table đã đủ, không cần clone.
- **Đề xuất để duyệt:** additive opt-in common contracts khi thật cần; giữ consumer defaults và tokens hiện hữu.

## 3. Chức năng bổ sung

Một DataTable presentation cho queue/picker/roster/history/incidents/audit; controlled query controls đúng server capabilities, common dialogs và truthful notifications. Overview cards/priority preview và profile chỉ đọc giữ trách nhiệm riêng.

## 4. Luồng nghiệp vụ

Mở view → initial load → successful rows/empty hoặc error/retry. Đổi search/filter/sort reset page/cursor và giữ URL context; server trả dữ liệu mới. Background refresh giữ known-success rows, active student và unsaved form trong cùng scope; lỗi refresh có warning/asOf thay vì empty. Đổi session/actor/target không giữ nhầm pending intent. Command chỉ có success sau server ACK; timeout có outcome chưa rõ, không auto replay.

## 5. Frontend changes

- Reuse DataTable shell/header/body/toolbar/footer. Giữ typography, padding, radius/border/surface/hover từ common source và --table-* light/dark. Không table-specific palette/classes để thay defaults.
- Mọi server-paged table tắt client filtering/sorting/pagination; controlled search và filters slot compose common controls. Unsupported columns sortable=false; không header arrow/filter có vẻ hoạt động nhưng không đổi query.
- Server meta đi qua PaginationControls trong DataTable pagination slot, API0-based→UI1-based. Cursor audit opt-in contract có hasNext/current/previous cursor/busy; không manufactured totalRecords/numbered pages.
- Additive controlled sort state/change chỉ cho callers cần server header sorting, defaults cũ không đổi. Built-in column filter extension chỉ khi filters slot không đủ. Active row opt-in dùng tokens hiện hữu, không bulk selectable giả single selected student.
- Tables mobile dùng overflow-x hoặc renderMobileRow với cùng labels/status/actions; toolbar/footer stack theo common breakpoints, không dựng table card style riêng. Subject/case identifiers không bị mất trên mobile.
- Initial loading dùng LoadingState/table skeleton; empty từ successful scope có copy rõ; initial error compose ErrorState với Button retry. Refresh không dùng isFetching để che toàn table; no-data/auth-loading không hiển thị summary0.
- Modal/ConfirmDialog và default ActionMenu ellipsis; thông điệp/validation/machine-code mapping qua feature locale catalog, date/time theo user locale/timezone đã xác định. Không raw exceptions vào UI.
- ToastProvider/useToast hiển thị kết quả có thật; pending/conflict/unknown không gửi success. Profile reuse PageHeader/Skeleton/ErrorState/read-only description, không tự thêm self-edit permission.
- Host ExamAttendanceTab reuse roster/history common, chỉ khác capabilities/hooks; không fork table styling. Không sửa unrelated Examiner scoring hoặc Admin screens ngoài opt-in incident context phase04.

## 6. Backend/API changes

Không endpoint mới cho styling. Search/filter/sort/meta/capability thuộc phase01–04, mappings phải phản ánh actual contract. Cursor khác offset paging. Không bù thiếu API bằng mock data, fake totals hoặc client whole-dataset claims. Backend vẫn là quyền và state authority.

## 7. Database changes

Không schema change cho UI/UX. Verification/case proposals thuộc phase03/04. Không lưu connection/count caches như nguồn sự thật hoặc copy dữ liệu để giải quyết presentation.

## 8. File dự kiến tạo/sửa

Proctor views/components từ phase01–04; api/queryKeys/messages và focused column/helper hooks nếu cần; shared Host ExamAttendanceTab. Common optional changes: packages/ui/src/components/DataTable.tsx, PaginationControls.tsx, LoadingState.tsx và export index nếu cần. Giữ design-tokens.css/defaults; active row dùng token hiện có. Không tạo table variant riêng hoặc đổi toàn bộ consumer defaults.

## 9. Dependencies

Functional contracts phase01–04. Common extensions cần hoàn thành trước feature dùng props mới; nếu server sorting chưa có thì disable control, không fake interaction. Các consumer Host SessionTable/ExamStaffView/ExaminerSessionTable và vendor Admin DataTable giữ cách gọi hiện hữu. Examiner Workspace queue hiện raw list, không mở thêm refactor ngoài scope để tuyên bố mọi màn hình đã đồng nhất.

## 10. Acceptance chức năng

- Queue/picker/roster/history/incidents/audit của Proctor dùng DataTable; no duplicated shells/search/filter/pagination.
- Light/dark/mobile/desktop có cùng thông tin/quyền, giữ common tokens và defaults.
- Search/filter/sort truy vấn toàn server scope; cursor không fake totals, không phân trang hai lần.
- Loading/empty/error/retry/refresh khác nhau; known-success data và input không bị mất do refresh lỗi.
- Dialog/toast đúng kết quả thật; unsupported actions không thành mock functionality.
- Shared opt-in extensions không bắt unrelated consumer refactor và không thay default styles.

## Design Constraints

Common UI-first, typed API, feature-owned copy/hooks/domain logic, thin routes. Không thực hiện test/lint/typecheck/build hoặc quality audit. Không bật feature flag, deploy hoặc tự chuyển implementation trong nhiệm vụ sửa tài liệu này.
