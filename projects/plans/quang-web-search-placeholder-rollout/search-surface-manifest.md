# Search Surface Manifest

Generated during Phase 01 of the search-placeholder rollout. This manifest is the source of truth for Phases 02–05.

## Shared contract

- `DataTable` defaults: `showSearch=true`, `clientSideFiltering=true`, generic fallback placeholder.
- A server-owned table must use controlled `searchValue`/`onSearchChange`, `clientSideFiltering={false}`, and `clientSidePagination={false}`.
- A client-owned table must expose only fields covered by its `filterAccessor` or rendered cell text.
- A contextual/review table must explicitly set `showSearch={false}`.
- Global header search (`Tìm kiếm trang...`) is navigation search and is not included below.

## Tenant-web DataTable inventory

| Source | Surface | Classification | Current search contract | Planned result |
|---|---|---|---|---|
| `features/auditLog/components/AuditLogView.tsx:86` | Tenant audit log | Primary paginated list | Generic local search; API has aggregate/page/size only | Server search by actor/action/aggregate or hide until API supports it |
| `features/supportTickets/components/SupportTicketsView.tsx:161` | Tenant support tickets | Primary paginated list | Generic local search; API has status/category/page/size only | Server search by ticket/subject/requester after API contract confirmation |
| `features/classes/components/ClassesSection.tsx:125` | Classes inside program | Contextual list | Generic client search | Explicit class name/code placeholder or hide if the section is small |
| `features/classes/components/ClassesListView.tsx:262` | Classes list | Primary client list | Generic client search | Search by class name/code |
| `features/classes/components/ClassRosterTable.tsx:202` | Class roster | Contextual list | Generic client search | Search by student name/email/code or hide if already scoped |
| `features/classes/components/LecturerAssignmentSection.tsx:58` | Assigned lecturers | Contextual list | Generic client search | Search by lecturer name/email or hide when small |
| `features/studentSearch/components/StudentSearchView.tsx:369` | Student search | Primary server list | Correct controlled search: name/email/phone/student code | Keep as reference |
| `features/examStaff/components/ExamStaffView.tsx:28` | Exam staff | Primary server list | Correct controlled search: name/email | Keep as reference |
| `features/examStaff/components/ExamStaffTable.tsx:37` | Legacy exam staff table | Unreferenced definition | Generic search | Do not treat as a visible screen; revisit dead-code ownership separately |
| `features/examoperations/components/LearnersOverview.tsx:82` | Learners overview | Primary paginated list | API query hard-codes `search: ""`; generic local search | Wire student-roster server search |
| `features/proctor/components/LiveMonitoringView.tsx:87` | Live monitoring | Primary/live list | Generic search over current rows | Define fields from attempt/session columns; keep client search if rows are complete |
| `features/proctor/components/AuditLogView.tsx:132` | Proctor audit log | Contextual/review list | Generic search over loaded rows | Explicit audit placeholder or hide if scope is one session |
| `features/proctor/components/AuditLogView.tsx:142` | Proctor security audit | Contextual/review list | Generic search over loaded rows | Explicit security-event placeholder or hide if scope is one session |
| `features/programs/components/ProgramsListView.tsx:157` | Programs list | Primary client list | Generic client search | Search by program name/code |
| `features/examoperations/components/SkippedRowsReport.tsx:23` | Skipped rows report | Review table | `showSearch={false}` | Keep hidden |
| `features/commercialization/components/OrdersView.tsx:26` | Orders | Primary paginated list | Generic local search; API has page/size only | Add server search by order/tenant fields supported by API |
| `features/programs/components/ProgramDashboard.tsx:67` | Program classes | Contextual list | Generic client search | Search by class name/code or hide if scoped list is small |
| `features/examoperations/components/RosterImport.tsx:124` | Roster import result | Review table | `showSearch={false}` | Keep hidden |
| `features/examoperations/components/StudentRosterTable.tsx:72` | Exam student roster | Contextual list | Generic client search | Search by student name/email/code or hide if already filtered |
| `features/studentDetail/components/StudentHistoryTab.tsx:140` | Student history | History table | `showSearch={false}` | Keep hidden |
| `features/exams/components/AnswersSection.tsx:120` | Exam answers | Primary paginated list | Generic local search; API has session/status/page/size only | Add server search by answer/student/task fields supported by API |
| `features/exams/components/ClassAssignmentSection.tsx:105` | Assigned classes | Contextual list | Generic client search | Search by class/program name or hide if small |
| `features/exams/components/ExaminerAssignmentSection.tsx:603` | Examiner assignment batches | Primary paginated list | Generic local search; API has session/page/size only | Add server search by batch/status/examiner fields supported by API |
| `features/exams/components/ExaminerAssignmentSection.tsx:671` | Examiner loads | Contextual summary | Generic client search | Hide unless the load list is large and searchable |
| `features/examStaff/detail/examiner/ExaminerSessionTable.tsx:33` | Examiner sessions | Contextual history list | `showSearch={false}` | Keep hidden |
| `features/exams/components/HostScoreReviewPanel.tsx:486` | Host score review | Review list | Generic client search | Define review fields; likely hide if bounded to one session |
| `features/exams/components/HostScoreReviewPanel.tsx:507` | Host score audit/review | Review list | Generic client search | Define audit fields; likely hide if bounded to one session |
| `features/exams/components/ProctorAssignmentSection.tsx:129` | Assigned proctors | Contextual list | Generic client search | Search by proctor name/email or hide if small |
| `features/exams/components/SessionTable.tsx:154` | Exam sessions | Primary client list | Generic client search plus date filter | Search by session name/code/status |

Tenant counts: 29 DataTables; 25 search-enabled; 2 explicit placeholders; 4 explicitly hidden.

## Vendor-web/admin DataTable inventory

| Source | Surface | Classification | Current search contract | Planned result |
|---|---|---|---|---|
| `features/platformUsers/components/PlatformUsersView.tsx:183` | Platform users | Primary server list | Correct controlled search: name/email | Keep as reference |
| `features/licensing/components/_LicenseTable.tsx:34` | Tenant licenses | Primary/client list | Generic client search | Search by tenant/license/plan fields actually rendered |
| `features/scoretemplate/components/_ScoreTemplateItemTable.tsx:183` | Score template items | Contextual list | Generic client search | Search by sequence/section/task type or hide if small |
| `features/licensing/components/QuotaHistoryModal.tsx:58` | Quota history | Modal history list | Generic client search | Explicit quota/tenant placeholder or hide if bounded |
| `features/scoretemplate/components/ScoreTemplateListView.tsx:269` | Score templates | Primary client list | Generic client search | Search by name/code/version |
| `features/commercialization/components/PlanCatalogView.tsx:520` | Plan catalog | Primary client list | Generic client search | Search by plan name/description/type/status |
| `features/commercialization/components/LicenseCodesView.tsx:565` | License codes | Primary paginated list | Generic local search; API has status/plan/tenant/page/size only | Add safe server search or remove free-text search; preserve sensitive-code boundaries |
| `features/questionbank/components/_QuestionTable.tsx:223` | Question bank | Primary client list | Placeholder says code/content; DataTable accessor only includes content | Align copy with content or add an ID accessor and test it |
| `features/notifications/components/AnnouncementsView.tsx:173` | Announcements | Primary paginated list | Generic local search; API has page/size only | Add server search by title/body or hide until supported |
| `features/dashboard/components/_RecentTenantsTable.tsx:50` | Recent tenants widget | Dashboard widget | Generic client search | Hide if “recent” is intentionally bounded; otherwise add tenant-specific copy |
| `features/questiontemplate/components/QuestionTemplateView.tsx:184` | Question templates | Primary client list | Correct placeholder: task types/keys/sections | Keep and verify accessors |
| `features/supportTickets/components/AdminSupportTicketsView.tsx:97` | Admin support tickets | Primary paginated list | Generic local search; API has status/category/tenant/page/size only | Add server search by ticket/subject/requester/tenant or hide until supported |
| `features/commercialization/components/AdminApplicationsView.tsx:92` | Tenant applications | Primary client list | Generic client search over org/code/contact/tax/status | Add explicit application criteria placeholder |
| `features/tenancy/components/_OrganizationTable.tsx:41` | Tenant organizations | Contextual/client list | Generic client search | Search by organization name/code or hide if small |
| `features/tenancy/components/_TenantTable.tsx:113` | Tenant management | Primary client list | Generic search; visible route uses this table, not `_TenantFilters` | Add tenant name/code/tax-code placeholder |

Vendor counts: 15 DataTables; 3 explicit placeholders; 12 generic; none explicitly hidden.

## Custom search inputs

| Source | Surface | Current contract | Result |
|---|---|---|---|
| `features/examoperations/components/ExistingStudentAssignmentModal.tsx:123` | Add existing students | Name/email/account/student code | Keep |
| `features/exams/components/create-exam/AudienceStep.tsx:82` | Audience source picker | Name/email/account/code | Keep |
| `features/tenancy/components/_TenantFilters.tsx:45` | Legacy tenant filters | Name/code/tax code copy; component is not mounted by visible tenant route | Do not count as visible search; align if integrated later |

## Server-paginated candidates

| Surface | Frontend owner | Existing request gap |
|---|---|---|
| Learners overview | `useStudentRoster` | Search is hard-coded empty in the view |
| Tenant support tickets | `useSupportTickets` → `listTickets` | No search parameter |
| Tenant audit log | `useAuditLogs` → `listAuditLogs` | No search parameter |
| Tenant orders | `useOrdersPage` → `listOrders` | No search parameter |
| Exam answers | `useAnswers` → `listAnswers` | No search parameter |
| Examiner assignment batches | `useExaminerAssignmentOverview` → `getExaminerAssignmentOverview` | No search parameter |
| Admin announcements | `useAnnouncementsQuery` → `listAnnouncements` | No search parameter |
| Admin support tickets | `useAdminSupportTickets` → `adminListTickets` | No search parameter |
| Admin license codes | `useAdminLicenseCodesQuery` → `listAdminLicenseCodes` | No free-text search parameter |

## Open decisions carried into later phases

- Exact server-side searchable fields must be confirmed in pte-api before adding each parameter.
- Contextual tables should be hidden when their row set is bounded and the parent scope already narrows the data.
- License-code search must not expose or cache secret license values.

## Cook result

- All 44 inventoried `DataTable` instances were rechecked after implementation: 30 enabled visible tables have an explicit placeholder, 13 contextual/review tables explicitly hide search, and the single remaining missing-placeholder definition is the unreferenced legacy `ExamStaffTable`.
- Tenant server search now reaches the API for learners, support tickets, audit logs, orders, answers, and examiner assignment batches. Each keeps tenant scoping, resets pagination, includes trimmed search in its query key, and disables local filtering/pagination where the server owns the result set.
- Admin server search now reaches the API for announcements, support tickets, and safe license identifiers. License-code free text accepts only UUID public/tenant identifiers; bearer codes never enter query strings or TanStack Query keys.
- The question-bank placeholder now describes question content, matching its actual `filterAccessor`.
