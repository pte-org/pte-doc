# Phase 7 widget checklist (tenant-web `/host/dashboard`)

Feature root: `pte-web/apps/tenant-web/features/hostDashboard/` (components under `components/`). Route: `app/(dashboard)/host/dashboard/page.tsx` (4 lines, server component, no text, renders `HostDashboardView`). One query: `useHostDashboard` in `api.ts` (key `HOST_DASHBOARD_QUERY_KEY`, `staleTime` 30 s, `retry: false`, one `getHostDashboard(apiClient)` call).

Section state rule (all widgets): OK renders; ERROR renders that widget's own `DashboardPanel` error state with a retry that refetches the single query; FORBIDDEN is hidden; zero renders `0`; a null `changePct` renders a dash.

## Section to widget map

| Backend host section | Rendered widget(s) | Priority | Component file(s) |
|---|---|---|---|
| learners | KPI cards "Learners" (total + new in window note) and "Active learners" (trend delta) | P1 | `components/KpiRow.tsx` (via `utils/kpis.ts`) |
| learners | Learner assignment split donut (assigned vs unassigned, `StatusDonutChart`) | P2 | `components/LearnerSplitPanel.tsx` |
| quota | Seat usage progress bar, remaining seats, near-limit warning (>= 90 %, `SEAT_NEAR_LIMIT_PERCENT`) with link to billing | P1 | `components/UsagePanel.tsx` -> `components/SeatUsageBlock.tsx` |
| quota | "Seat limit almost reached" needs-attention item | P1 | `components/NeedsAttentionPanel.tsx` (via `utils/attention.ts`) |
| subscription | Subscription list (plan name / type / status / expiry), nearest expiry text, expiring-soon warning | P1 | `components/UsagePanel.tsx` -> `components/SubscriptionBlock.tsx` |
| subscription | "Subscription expiring soon" needs-attention item | P1 | `components/NeedsAttentionPanel.tsx` |
| attempts | KPI card "Attempts submitted" (trend delta, in-progress note) | P1 | `components/KpiRow.tsx` |
| attempts | 12-month attempts bar chart, current month flagged partial (`TrendBarChart`) | P1 | `components/AttemptsTrendPanel.tsx` |
| exams | KPI card "Exam sessions created" (trend delta) | P1 | `components/KpiRow.tsx` |
| exams | Upcoming sessions table (`DataTable`: session link to `/host/exams/[publicId]`, status badge, opens, closes, enrolled / capacity with null capacity -> dash; no Branch column) | P1 | `components/UpcomingSessionsPanel.tsx` |
| exams | Sessions-by-status donut | P2 | `components/SessionStatusPanel.tsx` |
| grading | Grading pipeline (pending / AI scoring / failed as share of backlog via `ProgressBar`, plus awaiting-finalisation and reports-awaiting-publication counts) | P2 | `components/GradingPipelinePanel.tsx` |
| grading | Needs-attention items: failed answers, grading backlog, sessions awaiting finalisation, reports awaiting publication | P1 | `components/NeedsAttentionPanel.tsx` |
| billing (pending orders count only) | Compact "Pending orders" card -> `/host/orders` (no payment link) | P3 | `components/CompactCards.tsx` -> `components/CompactMetricPanel.tsx` |
| billing | "Orders awaiting payment" needs-attention item | P1 | `components/NeedsAttentionPanel.tsx` |
| support (own tickets) | Compact "Support tickets" card (open / in progress / resolved awaiting close) -> `/host/support-tickets` | P3 | `components/CompactCards.tsx` |
| support | "Open support tickets" needs-attention item | P1 | `components/NeedsAttentionPanel.tsx` |
| academics | Compact "Academic structure" card (organizations / programs / active classes, org-label nouns) -> `/host/programs` | P3 | `components/CompactCards.tsx` |
| staff | Compact "Staff coverage" card (proctors / examiners) -> `/host/exam-staff` | P3 | `components/CompactCards.tsx` |
| recentActivity | Recent activity timeline (`ActivityList` timeline; known audit codes labelled, unknown codes -> generic label; actor only "Staff member" / "System") -> `/host/audit-log` | P2 | `components/RecentActivityPanel.tsx` (via `utils/activity.ts`) |

All 11 backend host sections (learners, quota, academics, staff, exams, attempts, grading, subscription, billing, support, recentActivity) have at least one rendered consumer.

## Non-section widgets

| Widget | Priority | Component file |
|---|---|---|
| Page header + quick actions (Add learners -> `/host/students`, Create exam session -> `/host/exams`, Plans & billing -> `/host/billing`) via `PageHeader` | P1 | `components/HostDashboardHeader.tsx` |
| Needs-attention list (derived feature-side from sections; items hidden when their source is unavailable; failed sources noted with retry) | P1 | `components/NeedsAttentionPanel.tsx`, `utils/attention.ts` |
| KPI row inside `CollapsibleSection` | P1 | `components/KpiRow.tsx` |
| Whole-query loading (`DashboardLoadingState variant="overview"`) and whole-query error (`ErrorState` + retry, `getUserFacingApiErrorMessage`) | P1 | `components/HostDashboardView.tsx` |
| Responsive grid (mobile single column with needs-attention first; `md` two columns; `xl` twelve columns) | P1 | `components/HostDashboardGrid.tsx`, slot classes in `constants.ts` |
| LearnersOverview retained, untouched, mounted last at full width (own roster request) | P1 | `features/examoperations/components/LearnersOverview.tsx` (mounted in `HostDashboardView.tsx`) |

## Dashboard-key invalidation added (`invalidateQueries({ queryKey: HOST_DASHBOARD_QUERY_KEY })`)

- Roster import / add student: `features/examoperations/api.ts` (`useCreateRosterAccounts`, `useCreateStudent`), `features/studentSearch/api/index.ts` (`useCreateTenantStudents`), `features/classes/api/rosterImport.ts` (`useCreateRosterAccountsForClass`).
- Class creation: `features/classes/api/index.ts` (`useCreateClass`).
- Exam session creation: `features/exams/api/index.ts` (`useCreateSession`, `useCreateExamWorkflow`).

## Deferred / not built (per plan)

Per-skill score and pass rate, period selector (the backend default 30-day window is used; no `windowDays` is sent).
