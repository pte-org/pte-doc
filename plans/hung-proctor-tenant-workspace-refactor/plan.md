# PTE Prep — Proctor: Implementation Plan

Ngày: 2026-10-12. **Chỉ lập kế hoạch; chờ phê duyệt.** Không chỉnh sửa source, tạo component/migration hoặc triển khai phase. Không có công việc Testing & Quality, test/lint/typecheck/build hoặc lệnh thực thi trong kế hoạch này.

Phạm vi: hoàn thiện chức năng Proctor và thống nhất UI với Common DataTable hiện tại. Các lựa chọn nghiệp vụ mới bên dưới đã được người dùng trả lời; phê duyệt toàn bộ kế hoạch triển khai vẫn đang chờ. Code và dữ liệu có sẵn không bị thay đổi trong bước lập kế hoạch.

## 1. Hiện trạng và phạm vi

Repository web là workspace Next.js App Router, tenant app ở `pte-web/apps/tenant-web`, Admin app ở `pte-web/apps/vendor-web`. Backend là `pte-api/app`, Spring modular monolith với các module Session, Attempt, Identity, Proctoring, Support và Shared.

| Khu vực | Existing | Needs Modification / Missing |
|---|---|---|
| Sidebar/Overview | Role-aware routes, overview counts/priority/timezone, scope query và feature flag | Overview và full assigned list đang cùng composition; chưa có Incidents sidebar/route |
| Monitoring | Roster enrollment, snapshot/summary, attempt history, STOMP/polling, force submit và violation | Raw tables/controls riêng; API chỉ page/size; search/filter/sort toàn bộ roster cần API mở rộng |
| Attendance | UNMARKED/PRESENT/ABSENT, search/status/paging, summary, version/enrollment generation, receipt/history và Host correction | Raw roster/history/picker tables; chưa có LATE và xác minh danh tính riêng |
| Incidents | Violation categories và evidence chain; security audit có source/severity/subject | Chưa có case state, phân công xử lý, handoff/escalation hoặc incident history |
| Audit | DataTable đã dùng; full violation list và security cursor API | Filtering/count trên records đã tải chưa tương đương toàn lịch sử; adapter không giữ đủ source/severity/subject |
| Profile | auth/me, thông tin cá nhân dạng chỉ đọc | Copy/common states/theme cần đồng bộ; assignment history nên dẫn về danh sách hiện có |

Không coi các chức năng đã có là cần xây lại. Không thêm pause/resume, camera/AI face verification, tự kết luận gian lận hoặc quyền công bố kết quả cho Proctor.

## 2. Common DataTable đã kiểm tra trước thiết kế UI

Nguồn chính: `pte-web/packages/ui/src/components/DataTable.tsx`; export qua `packages/ui/src/components/index.ts` và `@pte/ui`. Primitive `Table.tsx` là API composition riêng, không phải implementation của DataTable; không thay DataTable bằng table dựng tay.

### Cấu trúc, hình thức và behavior hiện có

| Hạng mục | Hiện có trong source | Quy tắc áp dụng |
|---|---|---|
| Layout | Shell, toolbar, table header/body, loading/empty, mobile rows và footer | Feature chỉ cung cấp dữ liệu/cột/actions, không dựng shell table riêng |
| Header/columns/rows | Generic columns/cell/accessor, stable getRowKey, semantic th scope/aria-sort | Dùng UUID canonical; attendance theo student/enrollment, monitoring không dùng attempt làm khóa duy nhất |
| Typography | Font kế thừa design tokens; header text-xs semibold; body 13px | Giữ mặc định, không ép font/size/weight để giống mockup |
| Spacing | Header px4, sm:px6/py2.5; body px4, sm:px6/py3, sm:py3.5 | Giá trị mô tả common source, không sao chép thành class feature-local |
| Surface/border | rounded-xl, border0.5px, no shadow, token surface/border/hover | Không bg-white/slate palette, radius hoặc border riêng cho Proctor |
| Light/Dark | `packages/ui/src/styles/design-tokens.css`: :root và [data-theme=dark], bộ --table-* | Dùng table/control/badge tokens, giữ ThemeProvider hiện có |
| Search | TableSearchControl, controlled searchValue/onSearchChange hoặc internal search | Chỉ một search control; server search đi qua hook/API, không filter riêng trang đang tải |
| Filters | Custom filters slot, column Select options, DateRangePicker; TableFilterInput có sẵn | Select variant table; filter cần trạng thái server dùng filters slot. Không giả rằng per-column text input tự được render |
| Sorting | Common header buttons, internal sort và initialSort | Chưa có controlled server sort; đề xuất extension chung hoặc ẩn sorting chưa hỗ trợ |
| Pagination | Internal pagination; pagination slot; PaginationControls nhận API meta zero-based, Pagination one-based | Không có footer Previous/Next riêng trong mỗi feature; không phân trang hai lần |
| Badges/actions | Cell và rowActions slots, StatusBadge/Badge, ActionMenu/Button | Badge có label; ActionMenu dùng default ellipsis; giữ default visual props |
| Loading/empty | LoadingState table skeleton và EmptyState | Chỉ loading ban đầu che table; empty chỉ khi successful response thật sự rỗng |
| Error/refresh | DataTable chưa có error/refresh props | Compose ErrorState/Alert/Button chung ở view; giữ dữ liệu cũ nếu refresh lỗi, không biến lỗi thành empty/0 |
| Responsive | Overflow-x, toolbar/footer stack; renderMobileRow/mobileToolbar dưới sm | Không tạo kiểu bảng mobile khác; mobile content dùng common tokens/actions và cùng quyền |

Ba client transforms filtering/sorting/pagination mặc định đều true, initialPageSize=10. Server-paged Proctor phải tắt cả ba; dùng server meta/cursor. `clientSideSorting=false` không tự ẩn header sort controls: cột chưa có server sort phải đặt unsortable. Filter controls nội bộ cũng chưa có callback cập nhật server, nên không render control có vẻ hoạt động nhưng không đổi query.

### Những màn hình thực sự đang sử dụng

| Nhóm | File tiêu biểu và pattern |
|---|---|
| Host exam sessions | `apps/tenant-web/features/exams/components/SessionTable.tsx`: DataTable, date-range, badges, toolbar actions |
| Host exam staff | `features/examStaff/components/ExamStaffView.tsx`, `ExamStaffTable.tsx`: common table; server search/custom filters/pagination |
| Host theo dõi Examiner | `features/examStaff/detail/examiner/ExaminerSessionTable.tsx`: DataTable/StatusBadge/ActionMenu; client transforms/search tắt, cột unsortable |
| Host audit/support | `features/auditLog/components/AuditLogView.tsx`, `features/supportTickets/components/SupportTicketsView.tsx` |
| Admin | `apps/vendor-web/features/platformUsers/components/PlatformUsersView.tsx`, `tenancy/components/_TenantTable.tsx`, `supportTickets/components/AdminSupportTicketsView.tsx` |
| Proctor | `features/proctor/components/AuditLogView.tsx` đã dùng DataTable cho violations/security |
| Examiner workspace | `features/examiner/ExaminerQueueView.tsx` hiện dùng list ul, không phải DataTable. Không nhận là đã thống nhất toàn bộ Examiner; lần này không refactor module đó |

Các consumer khác đã xác nhận: tenant classes/ClassRosterTable, ClassesListView, ClassesSection, LecturerAssignmentSection; programs/ProgramsListView, ProgramDashboard; studentSearch/StudentSearchView, studentDetail/StudentHistoryTab; exams/AnswersSection, ClassAssignmentSection, ExaminerAssignmentSection, ProctorAssignmentSection, HostScoreReviewPanel; examoperations/StudentRosterTable, SkippedRowsReport, LearnersOverview, RosterImport; commercialization/OrdersView. Vendor: tenancy/_OrganizationTable; licensing/_LicenseTable, QuotaHistoryModal; commercialization/PlanCatalogView, LicenseCodesView, AdminApplicationsView; dashboard/_RecentTenantsTable; scoretemplate/_ScoreTemplateItemTable, ScoreTemplateListView; questionbank/_QuestionTable; questiontemplate/QuestionTemplateView; notifications/AnnouncementsView. Tái sử dụng contract UI, không sao chép các behavior server/client không phù hợp từ consumer khác.

### Thành phần dùng lại và mở rộng dự kiến

Dùng lại `DataTable`, `TableSearchControl`, `TableFilterInput`, `Select`, `DateRangePicker`, `PaginationControls`, `PaginationPageSizeSelect`, `StatusBadge`, `Badge`, `ActionMenu`, `Button`, `PageHeader`, `StatCard`, `LoadingState`, `EmptyState`, `ErrorState`, `Alert`, `Modal`, `ConfirmDialog`, `ToastProvider/useToast`.

| Đề xuất mở rộng common | Lý do | Giữ tương thích |
|---|---|---|
| Controlled sort state/change trong DataTable | Header sort cần chạy server query, đồng bộ URL/aria-sort | Props opt-in; consumer cũ tiếp tục internal sort và default style |
| Controlled column filters, chỉ nếu dùng built-in filter cho server | Đồng bộ filter UI/query thay vì local-only | Ưu tiên filters slot/Select hiện có; không mở rộng nếu composition đã đủ |
| Active-row key/state presentation opt-in | Monitoring cần giữ thí sinh đang xem | Domain-neutral token styling; không dùng bulk checkbox để giả single active row |
| Cursor mode opt-in cho PaginationControls | Security audit không có totalPages/totalElements | Giữ offset default; cursor chỉ có controls/hasNext/busy, không chế total hoặc pager số trang |
| Loading label opt-in/localized | LoadingState mặc định có nhãn tiếng Việt; DataTable chưa truyền label từ caller | Giữ behavior cũ, caller mới truyền copy theo locale |

Không cần dựng ErrorTable hoặc toolbar clone: ErrorState/Alert và existing slots đủ. Error slot/refresh indicator chỉ là extension tùy nhu cầu layout, không bắt buộc. Không đổi global design-tokens, default font/padding/border/radius, default pagination hoặc trigger ActionMenu. Không sửa hàng loạt Host/Admin/Examiner consumer trong phạm vi này.

### Trang Proctor cần chuyển

| Trang/component hiện tại | Hướng kế hoạch |
|---|---|
| AssignedSessionsView.tsx | Overview riêng; assigned monitoring list dùng DataTable + server meta |
| AssignedSessionPicker.tsx | Một common table composition chọn session cho attendance/audit/incidents |
| MonitoringStudentTable.tsx | DataTable, status/connection badges, active-row/domain selection, row details/actions |
| MonitoringStudentPanel.tsx | Paged attempt-history nếu trình bày bảng dùng DataTable, không style table riêng |
| AttendanceRosterTable.tsx | DataTable, attendance và verification badges độc lập, ActionMenu theo capability |
| AttendanceHistoryModal.tsx | DataTable và API PaginationControls trong common Modal |
| AuditLogView.tsx | Giữ DataTable, sửa coverage/paging/filter/source fields và fetch states |
| Incident list/history — chưa có | Thiết kế trực tiếp với DataTable; không tạo table variant riêng |
| Overview | Stat cards, cảnh báo, tối đa5 priority items và quick links; không full queue/table trùng Monitoring |

Host `features/exams/components/ExamAttendanceTab.tsx` tái sử dụng chính roster/history composition của Proctor; chỉ permission/actions khác, không bảng Host riêng.

## 3. Navigation và trách nhiệm màn hình

Overview `/proctor/sessions`; Monitoring `/proctor/sessions?scope=ACCESSIBLE`, detail `/proctor/sessions/{session}`; Attendance picker/detail `/proctor/attendance[/{session}]`; Incidents picker/detail `/proctor/incidents[/{session}]` là đề xuất mới; Audit picker/detail `/proctor/audit-log[/{session}]`; Profile `/proctor/profile`.

Sidebar và dashboard cards đều có entry hợp lệ; sidebar không biến mất khi không có assignments. Query-aware resolver chọn một item active, giữ Host Classes override, detail parent và mobile drawer. Giữ vai trò mặc định/workspace switching và flag off; không mở socket/API children khi feature disabled.

## 4. Nghiệp vụ đã chốt

- Attendance informational; không chặn bắt đầu thi hoặc thay attempt/grade/publication. UNMARKED/PRESENT/ABSENT hiện có; thêm **LATE thủ công**, không suy từ login/heartbeat.
- Proctor assigned được ghi attendance SCHEDULED/OPEN từ opensAt−30 phút inclusive đến closesAt exclusive; CLOSED chỉ Host correction, reason/audit; CANCELLED read-only. Initial absence note optional, correction/reset cần reason.
- **Identity Verification độc lập Attendance**, trạng thái UNVERIFIED/VERIFIED/FAILED. Ghi actor/time/note và append-only audit; không ảnh ID, biometric hoặc auto verification. FAILED tạo/đính kèm báo cáo cho Host, có đường escalation Admin khi cần; không tự kết luận gian lận hoặc chặn/submit bài.
- **Incident Proctor → Host → Admin khi cần**, NEW/IN_PROGRESS/ESCALATED/RESOLVED/CLOSED; severity/classification/description. Mỗi handoff lưu from/to actor/role, receiver, timestamp và reason. Không sửa/xóa xử lý lịch sử; không sửa evidence chain.
- Proctor report/clarify/follow result trong assignment; Host tiếp nhận/xác minh/xử lý/escalate; Admin xử lý đúng case được chuyển cấp và capability. Identity FAILED trước khi có attempt vẫn cần được báo cáo, nên incident gắn session/student/enrollment với attempt tùy chọn; existing violation flag vẫn giữ điều kiện attempt.
- FORCE_SUBMIT là thao tác hiện hữu có authorization/confirmation riêng; incident/identity actions không tự gọi nó. Không thêm pause/resume/cancel.

## 5. API/schema hiện có và thay đổi dự kiến

| Existing API | Reuse / extension dự kiến |
|---|---|
| GET `/api/v1/proctor-assignments/mine/overview?timezone` | Reuse counts/priority/asOf/day boundaries; không tự dựng incident counts khi API chưa trả |
| GET `/api/v1/proctor-assignments/mine` scope/timezone/sort/page/size | Bổ sung bounded search/session state/date filter nếu UX cần; lọc trước paging, overview totals giữ nguyên scope |
| GET `/api/v1/exam-sessions/{id}/monitoring` page/size | Mở rộng search/status/connection filter và stable sort dựa trên DTO thực tế; summary full-session độc lập filter |
| GET monitoring student attempts page/size | Reuse history paging và owner scope |
| GET/PATCH attendance + receipt/history | Reuse concurrency/idempotency; thêm LATE count/filter/transition/receipt, không sửa receipt cũ |
| GET violations full list | Reuse evidence; thêm paged projection nếu cần global filters, giữ caller cũ tương thích |
| GET security-audit limit/cursor | Reuse cursor; thêm source/type/severity/subject/date filters trước cursor khi được expose; invalidate cursor khi đổi filter |
| Existing STOMP open/commands/violations | Reuse transport/correlation; socket chỉ invalidate snapshot, không replay mutations |
| POST `/api/v1/proctor-sessions/{id}/close` | Chỉ đóng monitoring session của Proctor, không đóng exam session hoặc tự resolve incidents |
| auth/me | Profile read-only; không dùng staff-admin edit API cho self-profile |

Schema hiện hữu: Session/ProctorAssignment/Enrollment, Attempt/latest/history, ProctorSession/ViolationEvent, session_attendances/session_attendance_commands và identity staff search view trong V97. Không chỉnh applied migrations. Mọi migration dưới đây là **đề xuất**, chọn version còn trống khi được phép triển khai.

Identity dự kiến Session-owned current+command/audit records per tenant/session/student/current enrollment generation, version riêng và độc lập attendance; publish facade DTO cho Proctoring coordinator. LATE mở rộng enum/string/state/counts, không chuyển trạng thái cũ tự động. Incident Proctoring-owned case + immutable handling/handoff events + correlation/receipt, optional refs tới violation/verification/attempt và support ticket. Bảo toàn audit khi enrollment bị gỡ, không copy ảnh giấy tờ hoặc toàn bộ response vào log.

## 6. Dependencies Proctor — Host — Admin

| Module/actor | Hiện có | Phụ thuộc cần bổ sung, chỉ là đề xuất |
|---|---|---|
| Proctor | Assigned session, manual violations và audit | Case reporting/status/detail/history riêng; không mở Host support APIs hoặc tenant-wide audit cho Proctor |
| Host | Attendance correction; `HostSupportTicketController` `/api/v1/support-tickets`, HOST_ADMIN create/list/detail/withdraw | Session-scoped case inbox, receive/resolve/handoff, recipient lookup hẹp và escalation link |
| Admin | `AdminSupportTicketController` `/api/v1/admin/support-tickets`, PLATFORM_ADMIN/PLATFORM_MANAGER; list/detail/start/resolve/notes; vendor UI DataTable | Reuse inbox/detail cho escalated incident context; thêm assignee/explicit capability và case outcome projection, không tự cho mọi Admin sửa identity |
| Support | support_ticket OPEN/IN_PROGRESS/RESOLVED/CLOSED, optimistic version, notes/events; không có incident ref/assignee/escalation | Narrow public facade/exported DTO/events cho bridge; linkage idempotent, không truy cập internal repository từ Proctoring |
| Identity/Session | Active staff/public facades, assignment/tenant ownership/enrollment | Narrow authorized receiver projection và verification rights; actor từ principal, không client-supplied tenant/actor |

Incident là aggregate nghiệp vụ của Proctoring, **support ticket là channel xử lý Admin hiện có**, không xây thêm một Admin ticket engine trùng lặp. Link một escalation active tới ticket; tránh duplicate khi retry. Support hiện chỉ nhận EXAM_SESSION/EXAM_ATTEMPT/QUESTION refs; có thể dùng EXAM_SESSION và incident↔ticket mapping để giữ contract cũ.

Support `close()` hiện chỉ OPEN→CLOSED để Host withdraw, **không tương đương incident RESOLVED→CLOSED**. Không đổi general ticket transitions cho mọi consumer. Proctoring case status phải có ownership và mapping rõ: NEW→IN_PROGRESS(Host)→ESCALATED; Admin nhận có thể IN_PROGRESS với currentOwner=Admin và escalation history giữ nguyên; RESOLVED→CLOSED là acknowledgement/closure riêng theo quyền.

`SupportTicketStatusChangedEvent` hiện không có actual handler/recipient/time/reason đủ cho audit handoff. Đề xuất event/facade contract tương thích mang đủ correlation và actor thật; existing listeners giữ semantics. Support không khai báo dependency Proctoring: bridge theo Proctoring→Support public facade/event, không tạo dependency cycle hoặc import `support.internal`. Chỉ hợp nhất case outcome sau transaction commit, không đồng bộ bằng client optimistic success.

Host/Admin views tương ứng là phần dependency có giới hạn của phase4; không refactor unrelated ticket UI. Proctor chỉ nhận staff-visible outcome/history; không nhận Admin internal notes hoặc quyền xem ticket toàn tenant/platform.

## 7. Kế hoạch 5 phase đang chờ phê duyệt

| Phase | File | Dependencies | Trạng thái |
|---|---|---|---|
| 1 — Sidebar & Overview | [phase-01-sidebar-overview.md](phase-01-sidebar-overview.md) | Common UI contract và existing routes/API | Planned |
| 2 — Monitoring | [phase-02-monitoring.md](phase-02-monitoring.md) | Phase1, current projection/transport; server query extensions trước UI controls | Planned |
| 3 — Attendance & Identity | [phase-03-attendance.md](phase-03-attendance.md) | Phase1; phase4 case contract cho FAILED handoff | Planned |
| 4 — Incidents & Audit | [phase-04-incidents-audit.md](phase-04-incidents-audit.md) | Phase1/2; identity event contract phase3; Host/Support/Admin bridge | Planned |
| 5 — UI/UX Completion | [phase-05-ui-ux-completion.md](phase-05-ui-ux-completion.md) | Functional contracts phases1–4; no Testing/Quality phase | Planned |

Tránh dependency vòng phase3/4: thống nhất verification→incident event/reference contract ở đầu thiết kế; current verification state không phụ thuộc ticket resolution. Không expose FAILED “đã chuyển” trước server acknowledgement; phase3 có thể giữ trạng thái FAILED và “chưa bàn giao” nếu case capability chưa sẵn sàng. Hoàn thiện bridge trước khi công bố workflow hoàn chỉnh.

Các file technical phase cũ (`phase-01-public-projections.md`, `phase-02-scoped-api-and-security.md`, `phase-03-client-and-role-routing.md`, `phase-04-room-transport.md`, `phase-05-screens-and-rollout.md`) giữ nguyên làm nền tảng đã có. Checkbox completed trong chúng không đồng nghĩa các phase chức năng mới này đã triển khai.

## 8. File dự kiến sửa/tạo khi triển khai được duyệt

- Common: `pte-web/packages/ui/src/components/{DataTable,PaginationControls,LoadingState}.tsx` và `components/index.ts` nếu cần export additive contract; không đổi `styles/design-tokens.css` mặc định. Consumer khác tiếp tục dùng props cũ.
- Proctor: `apps/tenant-web/features/proctor/components/{AssignedSessionsView,AssignedSessionPicker,ProctorWorkspaceOverview,ProctorPrioritySessions,LiveMonitoringView,MonitoringStudentTable,MonitoringStudentPanel,AttendanceRosterTable,AttendanceFilterToolbar,AttendanceHistoryModal,RecordAttendanceModal,ProctorAttendanceView,AuditLogView,ProctorProfileView}.tsx`; `api.ts`, `queryKeys.ts`, messages/hooks/typed feature column definitions. Proposed new Incident list/detail/history/handoff compositions và routes.
- Routing: `apps/tenant-web/app/(dashboard)/proctor`, `lib/navigation.tsx`, `lib/navigationConstants.ts`, `features/auth/utils/resolveActiveNavItem.ts`; giữ role precedence và Host Classes override.
- Client: `packages/api-client/src/requests/{proctoring,attendance}.ts`, `types/{proctoring,attendance}`, proposed verification/incident DTOs/requests; actual fields/versions theo facade.
- Backend: `pte-api/app/src/main/java/com/pte/session/{SessionService,domain,dto,internal/service,internal/repository}`, `com/pte/proctoring/{domain,internal/controller,internal/service,dto}`; existing monitoring/assignment/audit query owners; proposed Session identity verification and Proctoring case/handoff entities/services.
- Limited dependencies: tenant `features/exams/components/ExamAttendanceTab.tsx` reuse common roster; proposed Host incident inbox in existing exam operations; vendor `features/supportTickets` opt-in escalated incident context; proposed Support public facade/DTO/events and narrow identity receiver lookup. Không sửa Examiner scoring.

## 9. Điểm còn cần phê duyệt trong thiết kế chi tiết

1. Quyền sửa identity verification sau CLOSED: đề xuất Host với lý do/audit, Proctor read-only; Admin xử lý incident không mặc nhiên có quyền sửa identity. Cửa sổ verification đề xuất như staff attendance nhưng state/revision độc lập.
2. Severity taxonomy và recipient allocation: reuse existing severity vocabulary khi tương thích; explicit Admin receiver/authorized pool cần narrow lookup, không mở directory toàn platform cho Proctor/Host.
3. Incident close/re-open policy: đề xuất Host đóng sau RESOLVED với lý do, Proctor chỉ follow/clarify; không có reopen hoặc xoá lịch sử trong phạm vi này.
4. Shared UI extensions: controlled server sorting, opt-in active row/cursor pagination/loading label; chỉ additive, giữ default consumer. Full-history filter chỉ expose khi backend có scope tương ứng.

Đây là đề xuất trong plan để duyệt, không phải blocker khiến tự chuyển sang code hoặc tự thêm quyền. Các quyết định LATE thủ công, identity3-state và Proctor→Host→Admin đã xác nhận, không hỏi lại.

## 10. Điều kiện dừng

Deliverable là master plan và năm phase chức năng. Không có source implementation, component/migration mới, pseudocode, mock data hay công việc Testing & Quality. **Dừng sau lập kế hoạch và chờ người dùng phê duyệt; không tự chạy ck:cook.**
