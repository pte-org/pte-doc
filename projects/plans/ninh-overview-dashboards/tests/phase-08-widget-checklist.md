# Phase 8 widget checklist (vendor-web `/admin`)

Feature root: `pte-web/apps/vendor-web/features/dashboard/` (components under `components/`).
Route: `app/(dashboard)/admin/page.tsx` (5 lines, server component, thin, renders `AdminDashboardView`).
One query: `useAdminDashboard` in `api.ts` (key `ADMIN_DASHBOARD_QUERY_KEY`, `staleTime` 60s, `retry: false`, one `getAdminDashboard(apiClient)` call).

Section state rule (all widgets): OK renders; ERROR renders that widget's own `DashboardPanel` error state with a retry that refetches the single query; FORBIDDEN is hidden; zero renders `0`; a null `changePct` renders a dash.

## Section to widget map

| Backend admin section | Rendered widget(s) | Priority | Component file(s) |
|---|---|---|---|
| tenants | KPI card "Total Tenants" (total + new in window note with trend delta) | P1 | `components/AdminKpiRow.tsx` (via `utils/kpis.ts`) |
| tenants | 12-month tenant growth bar chart (`TrendBarChart`, current month flagged partial) | P1 | `components/TenantGrowthPanel.tsx` (via `utils/charts.ts`) |
| tenants | Tenant status donut chart (active vs suspended vs pending, `StatusDonutChart`) | P1 | `components/TenantDistributionDonuts.tsx` |
| tenants | Tenant organization type donut chart (`StatusDonutChart`) | P1 | `components/TenantDistributionDonuts.tsx` |
| learners | KPI cards "Active Learners" (trend delta) and "Total Students" (total seats note) | P1 | `components/AdminKpiRow.tsx` |
| learners | Top seat utilisation list (`ProgressBar` per tenant, tone warning/danger at >= 75% / >= 90%) | P2 | `components/SeatUtilisationPanel.tsx` |
| recentTenants | Recent tenants table (`DataTable`: name/code, plan, students/seats, status badge, created date, "View details" button -> `TenantDetailModal` via single-tenant query `useTenant(tenantId)`) | P1 | `components/RecentTenantsPanel.tsx`, `components/TenantDetailModal.tsx` |
| applications | Oldest pending applications list (org name, org type badge, requested code, date received) | P2 | `components/ApplicationsPanel.tsx` |
| applications | "Pending applications" needs-attention item | P1 | `components/AdminNeedsAttentionPanel.tsx` (via `utils/attention.ts`) |
| licenses | Commercial card "License Codes" (active & valid count, redeemed count, redeemed in window note) | P2 | `components/CommercialCards.tsx` |
| licenses | "Expiring licenses" needs-attention item | P1 | `components/AdminNeedsAttentionPanel.tsx` |
| subscriptions | KPI card "Expiring Subscriptions" (expiring soon count, activated in window trend) | P1 | `components/AdminKpiRow.tsx` |
| subscriptions | Commercial card "Subscriptions" (active count, expiring soon count, activated in window note) | P2 | `components/CommercialCards.tsx` |
| subscriptions | "Expiring subscriptions" needs-attention item | P1 | `components/AdminNeedsAttentionPanel.tsx` |
| plans | Commercial card "Plans" (active, draft, archived counts) -> `/admin/plans` | P3 | `components/CommercialCards.tsx` |
| support | Oldest open tickets list (tenant name, category badge, date opened) | P2 | `components/SupportTicketsPanel.tsx` |
| support | "Open support tickets" needs-attention item (danger tone) | P1 | `components/AdminNeedsAttentionPanel.tsx` |
| revenue | Revenue panel per currency (current amount, change %, paid orders count, 12-month `TrendBarChart` with current month flagged partial) | P2 | `components/RevenuePanel.tsx` (via `utils/charts.ts`) |
| questionBank | Content health panel: total questions, created in 30d window, status breakdown grid (draft, pending approval, approved, archived), approved stock by pool (exam pool, practice pool) | P2 | `components/QuestionBankPanel.tsx` |
| questionBank | Primary content view for academic staff roles (`canReviewAcademic`) | P1 | `components/AcademicDashboardLayout.tsx` |

All 10 backend admin sections (tenants, learners, recentTenants, applications, licenses, subscriptions, plans, support, revenue, questionBank) have at least one rendered consumer.

## Non-section widgets

| Widget | Priority | Component file |
|---|---|---|
| Page header + dynamic greeting by time of day & current user + "Add Tenant" flow trigger (`PageHeader`) | P1 | `components/AdminDashboardHeader.tsx`, `utils/greeting.ts` |
| Quick actions dropdown (Review Questions, Review Applications, Support Tickets) | P2 | `components/AdminDashboardHeader.tsx` |
| Needs-attention list (derived feature-side from applications, subscriptions, licenses, support; items sorted by severity: danger before warning; failed sources noted with retry) | P1 | `components/AdminNeedsAttentionPanel.tsx`, `utils/attention.ts` |
| KPI row inside `CollapsibleSection` | P1 | `components/AdminKpiRow.tsx` |
| Vietnam tenant distribution map (empty state with informative message until Phase 10 province support) | P1 | `components/VietnamTenantMapPanel.tsx` |
| Tenant detail modal (on-demand single-tenant fetch via `useTenant(tenantId)`) | P1 | `components/TenantDetailModal.tsx` |
| Whole-query loading (`DashboardLoadingState variant="overview"`) and whole-query error (`ErrorState` + retry, `getUserFacingApiErrorMessage`) | P1 | `components/AdminDashboardView.tsx` |
| Responsive grid (`md` 2 columns, `xl` 12 columns) | P1 | `components/AdminDashboardGrid.tsx`, slot classes in `constants.ts` |
| Academic dashboard variant layout (`AcademicDashboardLayout`) | P1 | `components/AcademicDashboardLayout.tsx` |
| Tenant creation flow modals | P1 | `CreateTenantModal`, `TenantCreatedModal` via `useCreateTenantFlow` |
