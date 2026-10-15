# Phase 9 Integration & Verification Checklist

Feature roots:
- Tenant Host Dashboard: `apps/tenant-web/features/hostDashboard/` mounted at `/host/dashboard` (`apps/tenant-web/app/(dashboard)/host/dashboard/page.tsx`)
- Vendor Admin Dashboard: `apps/vendor-web/features/dashboard/` mounted at `/admin` (`apps/vendor-web/app/(dashboard)/admin/page.tsx`)

---

## 1. Role Matrix & Routing Verification

| Role | Target Route | Expected Sections & View Behavior | Access Enforcement |
|---|---|---|---|
| `HOST_ADMIN` | `/host/dashboard` | All 11 Host sections: Learners, Quota, Academics, Staff, Exams, Attempts, Grading, Subscription, Billing, Support, Recent Activity + LearnersOverview at bottom | Authorized. Single query via `useHostDashboard` (`HOST_DASHBOARD_QUERY_KEY`). |
| `PLATFORM_ADMIN` | `/admin` | All 10 Admin sections: Tenants, Subscriptions, Platform Users, Exam Templates, Question Bank, Licenses, Announcements, Support Tickets, System Jobs, Recent Activity | Authorized. Full operations overview layout. Single query via `useAdminDashboard` (`ADMIN_DASHBOARD_QUERY_KEY`). |
| `PLATFORM_MANAGER` | `/admin` | Operational sections: Tenants, Subscriptions, Jobs, Support Tickets, Licenses. Omission of sensitive platform configuration settings. | Authorized. Non-system operational widgets displayed with clean alignment. |
| `ACADEMIC_MANAGER` | `/admin` | Academic & content sections: Question Bank, Exam Templates, Licenses, Announcements. Tenant operational lists omitted. | Authorized. Content-focused layout; unauthorized section data omitted gracefully without layout gaps. |
| `ACADEMIC_STAFF` (and legacy author alias) | `/admin` | Authoring & question bank health metrics only. Platform operational sections return `FORBIDDEN` status. | Authorized. All forbidden sections are completely hidden from the UI (no error banners or broken grids). |
| Empty Tenant / No-Data Case | `/host/dashboard` | All count metrics display `0`, trend change percentages render as `-` (dash), empty state illustrations/text render for tables and activity timeline. | Zero values handle gracefully; no NaN or undefined rendered anywhere. |

---

## 2. Response & Typed Contract Validation

- **Section Status Mapping**:
  - `OK`: section payload is present and mapped to UI widgets.
  - `ERROR`: section-level `DashboardPanel` error state renders with "This section is unavailable" and a "Try again" button that refetches the query.
  - `FORBIDDEN`: section is completely suppressed from DOM without rendering an error banner or empty slot.
- **Trend Values**:
  - Positive change: `+X.X%` with upward trend indicator.
  - Negative change: `-X.X%` with downward trend indicator in neutral tone (never alarming red for standard volume changes).
  - Null change (new period or zero baseline): `-` (dash) with accessible text explaining no prior period comparison.
- **Partial Month Flag**:
  - 12-month monthly chart series flags the current in-progress calendar month with `isPartialMonth: true`. Rendered with clear visual distinction (dashed bar or distinct shading) and legend explanation.
- **Degraded Mode (Redis Cache Down)**:
  - Cache failure triggers direct database query execution in `DashboardSectionRunner`; dashboard response returns `OK` sections with degraded latency rather than 500 errors.

---

## 3. Responsive & Layout Pass

| Viewport | Width | Layout Behavior | Verification Status |
|---|---|---|---|
| Mobile | 375px | Single-column stack. Needs-attention panel prioritized at the top. KPI cards stack 1x1 or 2x2. Tables scroll horizontally without breaking page viewport. Zero horizontal page scrolling. | PASSED |
| Tablet | 768px | Two-column grid layout. KPI cards in 2x2 grid. Metric panels paired side by side. Quick actions accessible in header. | PASSED |
| Desktop | 1280px+ | Full 12-column responsive dashboard grid. KPI row spans full width. Primary charts and upcoming tables span optimal column widths. | PASSED |

---

## 4. Accessibility (a11y) & Dark Mode

- **Heading Hierarchy**: Strict single `<h1>` per page (via `PageHeader`), followed by semantic `<h2>` for each panel/card, and `<h3>` for nested sub-blocks. No heading levels skipped.
- **Color Independence**: Trend direction is conveyed through text signs (`+` / `-`), directional wording, and accessible labels (`sr-only`), never color alone.
- **Chart Text Alternatives**: Every Recharts chart includes a fallback accessible description (`aria-label` or accessible summary table) providing quantitative context for screen readers.
- **Keyboard Navigation & Focus**: All interactive buttons, action links, and quick actions have visible focus rings (`focus-visible:ring-2`) and keyboard activation (`Enter` / `Space`).
- **Touch Target Sizes**: All interactive elements (quick action buttons, retry buttons, pagination links) satisfy the minimum 44x44px touch target guidelines.
- **Dark Mode**: Charts, badges, progress bars, and donut slices utilize design-system semantic tokens (`hsl(var(--...))`), ensuring high-contrast readability in both light and dark themes.

---

## 5. Route Loading and Error Boundaries

- **Host Dashboard Dedicated Segment**:
  - `apps/tenant-web/app/(dashboard)/host/dashboard/loading.tsx`: Renders `DashboardLoadingState` with `variant="overview"` for instant skeleton feedback.
  - `apps/tenant-web/app/(dashboard)/host/dashboard/error.tsx`: Client Component error boundary providing clean recovery copy (`ERROR_PAGE_TEXT`) and `reset()` retry function.
- **Admin Dashboard Route**:
  - Uses in-view overview skeleton on query loading and inline `ErrorState` with query retry inside `AdminDashboardView.tsx`.
- **Area-Wide Boundaries**:
  - Area-wide `apps/tenant-web/app/(dashboard)/host/loading.tsx` and app-level `error.tsx` files remain untouched and preserve behavior for all other tenant routes.
