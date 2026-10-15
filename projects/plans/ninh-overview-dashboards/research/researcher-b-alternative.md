## Research Report: Overview dashboards (tenant host + platform admin) - Alternative: per-widget / hybrid fetching + FE design tradeoffs

**Role**: Alternative (Instance B)
**Calls used**: ~14 (budget in researcher.md is 5; exceeded because the task asked for a 6-part inventory. Read-only, no source edited.)
**Scope**: FRONTEND only (pte-web). Backend facts below are only what the FE can see (api-client, controller names).

---

## 0. Key facts discovered (change the framing of the task)

1. **/host/dashboard is HOST_ADMIN-only.** `apps/tenant-web/features/auth/constants.ts:12` `HOST_ROLES = ["HOST_ADMIN"]`, and `host/layout.tsx` -> `TenantDashboardLayoutChrome area="host"` -> `DashboardChrome allowedRoles={HOST_ROLES}`. No role variance inside the host area.
2. **Examiner/proctor have NO dashboards.** `app/(dashboard)/examiner/page.tsx` redirects to `/examiner/work`; `proctor/page.tsx` redirects to `/proctor/profile`. The `StaffWorkspaceController /overview` (`packages/api-client/src/requests/admin/examStaffWorkspace.ts`, `StaffOverviewResponse {proctor|null, examiner|null}`) is the HOST-facing staff detail page (`/host/exam-staff/[staffPublicId]`), not a staff landing. Task premise "examiner/proctor already have overview" is only true as host-side staff detail.
3. **/admin is multi-role.** `apps/vendor-web/features/auth/constants.ts:20` `ADMIN_ROLES = PLATFORM_ADMIN, PLATFORM_MANAGER, ACADEMIC_MANAGER, ACADEMIC_STAFF`. But the Tenants nav is `requiredRoles: PLATFORM_OPERATIONS_ROLES` (admin+manager only) (`lib/navigation.tsx:25`). The current `OverviewView` calls `useTenants()` for ALL four roles -> academic roles probably hit 403/empty. The aggregate endpoint and FE must be section-scoped by role (see 4.2).
4. **Current admin KPIs are not real.** `features/tenancy/types` documents `seatsUsed`, `location`, `activatedAt`, `expiresAt` as placeholder values (no backend support). So "Active Learners" = sum of fake `seatsUsed`, the Vietnam map has no locations, and `OverviewView` downloads the ENTIRE tenant list (`useTenants()`, unpaginated) just to count/slice 5. The `progress` % is passed as `trend` to StatCard (semantic misuse), `+12.5%`/`+8.2%` are dead fields. `SystemNoticeBanner` text ("operating normally") and `tenancy` `EMPTY_SYSTEM_HEALTH` are also fabricated. A real server aggregate fixes all of this.
5. **Recharts is already a dependency** (`recharts 3.8.1` in `packages/ui/package.json` and `apps/tenant-web/package.json`). Only consumer: `StatusDonutChart` (`packages/ui/src/components/StatusDonutChart.tsx`, `"use client"`, ResponsiveContainer, CSS-var tone colors, `isAnimationActive={false}`, legend `<ul>` for a11y). `CircularProgressChart` is hand-rolled SVG. `apps/tenant-web/components/ui/core/chart.tsx` is a shadcn-style recharts wrapper that is **unused** (and tenant-only, with undefined-in-ui tokens like `fill-text-tertiary`) - do not build on it; build chart primitives in `@pte/ui`.
6. **Prior art favors aggregates.** `useProgramDashboard` (tenant `features/programs`) = one `ProgramDashboardResponse` aggregate; `StaffOverviewResponse` = one aggregate with **nullable sections** (partial availability). Phase 4 of `pte-doc/projects/plans/codex-20260919-vendor-tenant-ui-authoring` already wrapped every `StatCard` group in `CollapsibleSection` - new KPI rows should follow that.
7. **Tests:** tenant-web has vitest (node env, `include: features/**/*.test.ts`, pure logic only, no DOM, no testing-library). vendor-web has **no test script/vitest**. `packages/api-client` has vitest with per-request tests (`endpoints.test.ts`, `reports.test.ts`, ...).
8. **Next 16 note** (`node_modules/next/dist/docs/01-app/03-api-reference/03-file-conventions/error.md`): `error.tsx` now receives `unstable_retry`; `reset` still works but docs say prefer `unstable_retry()` (re-fetches + re-renders). Existing repo `(dashboard)/error.tsx` uses `reset`. New dashboard `error.tsx` should use `unstable_retry`.
9. **Design ref** `pte-doc/design/stitch-pte-tenant-web/01-dashboard-overview/screen.png`: 4 KPI cards (Learners active, Attempts this month, Awaiting scoring review, Sessions this week); "Attempts delivered" 12-month grouped bar (PTE Academic vs PTE Core) + range select; Licence card (486/500, 97%, warning, "Request more seats"); Upcoming sessions table (date/time, code, exam, branch, enrolled/capacity, proctor, status, action); Recent activity timeline; "Can xu ly" (Needs attention) list with count chip. Admin design pack (`stitch-pte-admin-dashboards`) has NO dashboard screen (only tenants list/detail, question bank, blueprint, licences) - admin layout is ours to design, reusing the same system.

---

## 1. Fetching strategy: aggregate vs per-widget vs hybrid

| Criterion | (A) 1 aggregate / dashboard (user decision) | (B) per-widget endpoints, independent `useQuery` | (C) hybrid: aggregate KPI/attention + separate heavy/param endpoints |
|---|---|---|---|
| First paint | 1 request; all-or-nothing skeleton, bounded by slowest section | progressive: each card resolves independently; 8-12 parallel requests through gateway | KPIs fast (cheap COUNTs), charts/lists stream in |
| Failure isolation | weak by default; fixable with **nullable sections / per-section status** (exact precedent: `StaffOverviewResponse`) | native: one `ErrorState` per card, retry per card | good: KPI failure and chart failure independent |
| Caching/invalidation | one key `HOST_DASHBOARD_QUERY_KEY`; after import/create class/session mutations invalidate **one** key | N keys to invalidate from other features -> easy to forget, stale widgets | 2-3 keys |
| Params (range selector, "last 30d") | changing range refetches everything | per-widget param, ideal | trend endpoint takes `range`; aggregate stays param-free |
| Backend coupling | facade crossing Modulith modules (enrollment, session, scoring, billing, reporting, audit; controllers live under `com.pte.<module>.internal.controller`) = one orchestrator + one DTO that grows | each endpoint maps to ONE module (matches module ownership) | middle |
| Server cost | one authz check; shared tenant-scope; can batch COUNT queries | N authz + N tenant-resolve; each cheap | 2-4 requests |
| FE complexity | 1 hook + `select` slices; simplest | N hooks + N loading/error branches (more code, more tests) | 2-3 hooks |
| Testability | 1 mapper `dashboard DTO -> view models`, pure-function tests; MSW-free | N mappers; each small | few |
| Payload growth | DTO grows with each new widget (versioning risk) | none | contained |

Codebase-specific points:
- `new QueryClient()` has **no defaults** (`apps/tenant-web/app/providers.tsx`) -> `staleTime 0`, `refetchOnWindowFocus` true. N parallel widget queries refocus-refetch N endpoints; one aggregate refetches once. Set `staleTime: 60_000` on the dashboard query (precedents: `exams/api/index.ts:158`, `questionbank/api.ts:181`).
- HTTP/2 + gateway (`pte-api/gateway`) makes N small requests cheap; the real cost is N x authz/tenant resolution server-side and N invalidations FE-side.
- `LearnersOverview` already has its own independent paged query (`useStudentRoster`) - this stays an independent widget regardless.
- Admin currently downloads all tenants; aggregate replaces that with a 5-row `recentTenants` slice (largest FE win).

### Recommendation
**Keep the user's decision: ONE aggregate per dashboard**, but design the contract and FE so it behaves like per-widget:
1. **Sectioned envelope**: every widget section is nullable/optional (`kpis`, `licence`, `trend`, `upcomingSessions`, `attention`, `activity`, ...). `null` = "section unavailable (failed or not permitted for this role)". FE renders `ErrorState`/hidden per section. Add `generatedAt`. This gives partial-failure isolation without N endpoints (copy `StaffOverviewResponse` shape).
2. **FE slices** via a single `useHostDashboard()` and widgets receiving `dashboard.sectionX` props; widgets stay dumb and testable.
3. **Split off only where there is a user-controlled parameter**: the trend chart range (6/12 months) and any "view more" list should be a separate `GET .../trend?range=` (and the existing list pages), NOT a re-fetch of the whole aggregate. Ship P1 with fixed 12 months and **no range selector** so no split is needed on day one; hybrid becomes a P3 add-on without breaking the aggregate.
4. If backend finds any section expensive (e.g., score distribution, 12-month attempts GROUP BY), mark it a **deferred section** (separate endpoint, own `useQuery`, `enabled` when rendered) - this is the hybrid escape hatch; decide after measuring, not up front (YAGNI).
Verdict for part 1: **Aggregate with sectioned/nullable envelope; hybrid only for param-driven trend**. Pure per-widget not recommended (more keys, N invalidations, more tests, no real benefit given prior art).

Role gating for admin: backend omits sections the caller may not see (`tenants/revenue` for operations roles; `content` for academic roles); FE additionally hides with `hasAnyRole` from `features/auth/permissions.ts` (ACADEMIC_ROLES vs PLATFORM_OPERATIONS_ROLES). Do not let academic roles call a tenants-only list.

---

## 2. @pte/ui inventory and gaps

`packages/ui/src/index.ts` re-exports `components`, `hooks`, `i18n`, `layouts`, `runtime`, `theme`, `utils`. Tokens are CSS vars (`--surface-card`, `--shell-border`, `--ink-*`, `--mint|sky|cream|blush-{tint,action}`, `--action`, `--brand-tint`) with dark mode; charts must use these, never hex.

| Component | File / props (read) | Use for dashboards |
|---|---|---|
| `StatCard` | `label, value:string, icon, accent(blue/sky/mint/cream/blush), highlight, progress(0-100 native <progress>), footnote, trend:string, trendPositive, compact, className` | KPI tiles. **Trend is weak**: renders a "+"/"-" glyph next to the value and the trend string at right; no up/down arrow, no neutral, no "vs previous period" caption, `trendPositive` conflates direction and good/bad. Admin misuses it to show progress. |
| `DashboardCard` | `ComponentProps<"div">`; rounded-xl bordered surface p-5 | surface for every widget |
| `CollapsibleSection` | `title, subtitle, actions, collapsible, defaultExpanded, contentClassName` (h2, aria-expanded/controls, `t("common.collapse")`) | section wrapper; precedent for KPI groups |
| `StatusDonutChart` | `items:{key,label,value,tone}[] , totalLabel, emptyLabel, ariaLabel` (recharts, legend list, empty state) | status/plan/org splits - ready as is |
| `CircularProgressChart` | `value|null, max, valueLabel, ariaLabel, caption, tone(brand/success/warning)` | licence/seat gauge |
| `ProgressBar` | `value,max,tone(success/warning/danger),label` | utilisation lists, scoring progress |
| `DataTable` (711 lines) | `columns, rows, getRowKey, isLoading, emptyTitle/Description, rowActions, clientSidePagination, pagination...` | upcoming sessions, recent tenants; already used by `LearnersOverview` |
| `Badge` / `StatusBadge` | `variant success/warning/danger/info/neutral` | session status |
| `Alert` | `tone info/success/warning/error, title` | licence warning, section errors (as `LearnersOverview` does) |
| `EmptyState` / `ErrorState` | `title, description, action` (EmptyState is a full bordered card; ErrorState a blush box) | per-widget empty/error. ErrorState has no built-in retry (pass `action={<Button>}`) |
| `Skeleton`, `LoadingState(rows,variant)`, `DashboardLoadingState(variant page/detail/table)` | skeleton primitives | route `loading.tsx`; page variant = 4 stat skeletons + table (shape does not match our layouts -> need dashboard-specific skeleton, see below) |
| `PageHeader` | `title, subtitle(ignored!), actions` | page title; **subtitle prop is intentionally not rendered** - do not rely on it (current host page passes one and it is dropped) |
| `Tabs` | `items{id,label,count,badge}, value, onChange, variant` | optional period switch |
| `Select`, `DateRangePicker`, `Button`, `ActionMenu`, `Avatar`, `icons` (Grid, Users, Building, Clipboard, Document, License, AlertTriangle, CheckCircle, Bell, Billing, Shield, Settings, Nav*...) | | actions / icons (icon set lacks calendar, clock, trending-up/down, chart, activity -> add) |

### Gaps -> decision (additive only; AGENTS.md: do not change defaults other screens rely on; 6 files use StatCard, `trend=` used in admin `_AdminStatGrid` and vendor `_QuestionStatGrid`)

**Add to @pte/ui (domain-neutral, used by 2 apps):**
1. **StatCard delta (extend, additive):** `trendDirection?: "up"|"down"|"flat"`, `trendTone?: "good"|"bad"|"neutral"` (up can be bad e.g. failures), `trendLabel?: string` ("vs previous 30 days"). Render arrow icon + value + sr-only direction text. Keep old `trend/trendPositive` behaviour untouched when new props absent. Fixes fake `+12.5%` honestly: FE receives real numbers, shows `null` as "-" (no previous data) rather than 0%.
2. **`DashboardPanel`** (new): DashboardCard + h2 title/subtitle/actions + state slots `isLoading / isError(onRetry) / isEmpty`. Eliminates per-widget loading/error/empty boilerplate (each of ~10 widgets would otherwise repeat it and bust the 150-line limit). No react-query dependency (props only).
3. **`TrendBarChart` / `TrendLineChart`** (new, recharts, `"use client"`): `data:{key,label,values:{seriesKey:number}}[]`, `series:{key,label,tone}[]`, `ariaLabel`, `emptyLabel`, optional `stacked`. Reuse `StatusDonutChart`'s TONE_COLORS (extract a shared `chartTones.ts` instead of duplicating), `isAnimationActive={false}`, `role="img"` + visually-hidden data table fallback, tooltip with locale numbers. Line version is the same file family (`AreaChart` optional P3).
4. **`ActivityList`** (new): `items:{id,title,description?,meta?,tone?,icon?,href?}[]`, `variant: "timeline"|"actions"`, `emptyLabel`. One component serves Recent activity (timeline) and Needs attention (actions with count chip) - DRY, both apps use it.
5. **Icons**: `CalendarIcon`, `ClockIcon`, `TrendUpIcon/TrendDownIcon`, `ChartBarIcon`, `ActivityIcon` (in `icons.tsx`).
6. **`DashboardLoadingState` new variant** `"overview"` (KPI row + chart row + list row skeleton) - additive variant; do not change `page` default.
7. (P3) `Sparkline` (tiny recharts LineChart without axes) for StatCard `sparkline` slot.

**Keep feature-local:** DTO-to-view-model mappers, delta formatting rules, licence severity thresholds (`>=90%` warn), attention-item routing/hrefs, quick-action sets, org-label-aware copy. Map (`_VietnamTenantMap`), `_RecentTenantsTable`, `_TenantDetailModal` stay in vendor `features/dashboard`.

**Charts decision:** use recharts (already installed, one consumer, theme tokens proven by the donut) wrapped in `@pte/ui`; **no new dependency**. Hand-rolled SVG only for tiny shapes (gauge/sparkline). Do not reuse tenant's `components/ui/core/chart.tsx`.

---

## 3. Existing patterns

- **Feature layout:** `features/<name>/{components,constants.ts,types.ts,api.ts}`; private subcomponents `_Name.tsx`; barrel `components/index.ts`. Vendor dashboard: `features/dashboard/{constants.ts,types.ts,components/}` (no `api.ts` yet - it composes `tenancy/api`). Tenant dashboard has no feature folder: `host/dashboard/page.tsx` currently holds an inline `HOST_DASHBOARD_TEXT` const and `"use client"` -> violates thin-route rule; create `features/hostDashboard/` (`api.ts`, `constants.ts`, `types.ts`, `utils/`, `components/`).
- **Client API:** hook in feature `api.ts` calling `@pte/api-client` request fn with `apiClient` from `@/lib/apiClient` (both apps; `createSessionApiClient` from `@pte/ui`); query-key constants in `constants.ts` (e.g. `EXAMINER_QUEUE_QUERY_KEY`). New request modules go in `packages/api-client/src/requests/<domain>/` + types in `src/types/`, exported via `requests/index.ts`, with a vitest `*.test.ts` + entry in `endpoints.test.ts` (house pattern: `reports.ts`, `quota.ts`). Suggest `requests/admin/tenantDashboard.ts` and `requests/tenant/...` or `requests/admin/platformDashboard.ts` (names for planner to finalise).
- **Error display:** `errorMessage(error, fallback)` (`tenant-web/features/examoperations/errorMessage.ts`) wraps `getUserFacingApiErrorMessage` from `@pte/api-client` - never show raw `error.message`.
- **i18n (two mechanisms):**
  - vendor-web: constants stay English; `useAdminCopy(RAW_TEXT)` (`features/i18n/adminCopy.ts`) translates by **English literal key** via a giant `ADMIN_VI` dict (**already 1005 lines**, over the 300-line standard). Do NOT append 40+ new entries there; add a sibling `features/i18n/adminCopy.dashboard.ts` (or `features/dashboard/messages/vi.ts`) merged into `ADMIN_VI`, or follow the tenant pattern below.
  - tenant-web: mixed. Core chrome uses `useLocale().t(key, fallback)` with `COMMON_MESSAGES` inside `packages/ui/src/i18n/LocaleProvider.tsx` (1612 lines, do not grow it with feature copy). The cleaner precedent is `features/examStaff/detail/messages/{en.ts,vi.ts}` + `hooks/useStaffDetailText.ts` (typed keys, `{name}` interpolation). **Use that for hostDashboard** (`messages/en.ts`, `messages/vi.ts`, `useHostDashboardText`), because most existing host constants (e.g. `LEARNERS_OVERVIEW_TEXT`) are English-only and the design is bilingual.
  - Greeting (admin): hardcoded "Good morning, Administrator" - use user's name from `useCurrentUser` + time-of-day greeting, locale-aware.
- **Auth/role gating:** layouts -> `DashboardChrome navItems allowedRoles` -> `RequireAuth`. Nav items carry `requiredRoles`; `RequireAuth` has no "forbidden" state (bounces to login), so hide widgets by role instead of linking to gated pages (comment in `lib/navigation.tsx`). Host nav `buildHostNav(labels)`; `Overview` -> `/host/dashboard`.
- **loading/error:** `host/loading.tsx` = `<DashboardLoadingState variant="detail"/>`; `admin/loading.tsx` = default page variant; `(dashboard)/error.tsx` exists in both apps (full-screen `min-h-screen`, uses `reset`). Per-route `error.tsx` exists for dynamic routes (`host/classes/error.tsx`...). `/host/dashboard` has none of its own. React Query errors do not trigger error boundaries (no `throwOnError`), so **per-widget ErrorState is the real error UX**; route `error.tsx` is a backstop.
- **Tests:** tenant-web vitest node env `features/**/*.test.ts` (existing: `cleanRosterFile.test.ts`, `rosterTemplate.test.ts`); vendor-web none. Plan: pure mapper/format tests in each app (add a minimal `vitest.config.ts` + `"test": "vitest run"` to vendor-web mirroring tenant-web) + api-client request tests; UI verified by lint/typecheck/build + browser check (no DOM test infra exists; do not introduce testing-library unless the planner explicitly wants it).

---

## 4. Per-role / per-org-type

1. **Tenant:** one dashboard, HOST_ADMIN only. Do not vary by role (single role). Examiner/proctor dashboards are out of scope for #69; if wanted later, reuse `ExaminerOverviewResponse`/`ProctorOverviewResponse` shapes ("my workload") under their own routes.
2. **Org type:** `features/orgLabels/constants.ts` - `SCHOOL_FAMILY` and `CENTER_FAMILY` dictionaries are **identical** today (`Program`/`Class`). Only vary nouns: use `useOrgLabels()` + `pluralize()` for widget copy (e.g. "Learners per {class}", "Top {classes}"). **Do not vary the widget set by org type** (YAGNI; the labels spec itself only defines a noun split). The design shows a "Branch" column/"3 chi nhanh" - there is no branch concept in tenant-web today (vendor has organizations via `listOrganizations`); treat Branch as P3 / confirm with backend, omit from P1 table.
3. **Admin:** vary by role. PLATFORM_ADMIN/MANAGER: everything. ACADEMIC_MANAGER/STAFF: content-health + announcements + their own notices only; hide tenants/revenue/licences. Section-level nullability in the aggregate (part 1) carries this.

---

## 5. Widget catalogs

Priorities: P1 = ship in this task, P2 = ship if aggregate supports cheaply (user said "as complete as possible"), P3 = later. "Data" = what FE needs from the aggregate (backend shapes are for the contract owner; real deltas computed server-side as `{value, previousValue}`, FE derives % and direction; `previousValue===0|null` -> show "-" not Infinity).

### 5.1 Tenant host dashboard (`/host/dashboard`)

| # | Widget | Data needed | Component | Pri |
|---|---|---|---|---|
| T1 | KPI row: Active learners, Attempts this month, Awaiting scoring review (highlight/cream), Sessions this week | `kpis.{activeLearners,attemptsThisMonth,awaitingReview,sessionsThisWeek}` each `{value,previousValue}` (+ review count `href`) | `StatCard`(+delta ext) inside `CollapsibleSection` | P1 |
| T2 | Seat/licence usage + expiry warning + "Buy/Request seats" CTA | `licence.{used,limit,planName,expiresAt}` | `CircularProgressChart` + `ProgressBar` + `Alert` (>=90%) + `Button`/Link to `/host/billing` or `/host/quota` | P1 |
| T3 | Attempts delivered, 12 months | `trend.attempts[{month,count}]` (P2: split by exam template/type, as in design) | new `TrendBarChart` | P1 (single series), P2 (stacked) |
| T4 | Upcoming sessions (next 5-8) | `upcomingSessions[{publicId,code,name,startsAt,enrolled,capacity,proctorName|null,status}]` | `DataTable` (no pagination) + `Badge`, row link `/host/exams/[publicId]`; "View all" link | P1 |
| T5 | Needs attention | `attention[{kind,count,href}]`: sessions without proctor, awaiting review/scoring failures, unpublished reports, licence >90%, open support tickets, pending imports | new `ActivityList variant="actions"` | P1 |
| T6 | Recent activity (audit) | `activity[{id,occurredAt,text,actor}]` last 8 (HOST_ADMIN has audit access) | `ActivityList variant="timeline"` + link `/host/audit-log` | P2 |
| T7 | Exam sessions by status | `sessionStatusCounts` | `StatusDonutChart` (exists) | P2 |
| T8 | Learner assignment status (assigned to class / unassigned) and Top {classes} by learners | `learnerSplit`, `topClasses[{name,count}]` | `StatusDonutChart`, list of `ProgressBar` | P2 |
| T9 | Score performance: avg score per skill (L/R/W/S), pass rate | `scores.{bySkill[], passRate}` | `TrendBarChart` (single series) or `ProgressBar` list | P2 |
| T10 | Marking pipeline progress (scored/submitted, backlog) | `marking.{scored,submitted,pending}` | `ProgressBar` / `CircularProgressChart` | P2 |
| T11 | Quick actions (Import learners, Create exam, Create class) | none (routes) | `Button` links in `PageHeader actions` (P1: 2 primary) - no new component | P1 |
| T12 | Staff coverage (examiners/proctors active) | `staff.{examiners,proctors}` | `StatCard compact` | P3 |
| T13 | Open support tickets / last order status | `support.open`, `billing.lastOrder` | feeds T5 + small `StatCard` | P3 |
| T14 | **LearnersOverview** roster table (KEEP, existing) | own query (`useStudentRoster`) | existing component, last section, full width, retitle h2 consistent with other panels (heading currently hand-styled `text-xl` - acceptable as-is, do not restyle) | P1 (retain) |
| T15 | Period selector (7d/30d/12m) | `?range=` | `Tabs variant="minimal"` + trend endpoint (the hybrid split point) | P3 |

Layout (Tailwind mobile-first, 12-col grid `grid-cols-1 md:grid-cols-6 xl:grid-cols-12`; shell already has sidebar so effective content width at xl is ~1100px):
- **Desktop (xl):** r1 T1 4 cols (`xl:grid-cols-4` inside section) / r2 T3 (span 8) + T2 (span 4) / r3 T4 (span 8) + T5 (span 4) / r4 T6 (4) + T7 (4) + T9 (4) / r5 T14 (12).
- **Tablet (md, 768-1279):** T1 2x2; T3 full; T2 + T5 side by side (3+3); T4 full (table scrolls inside card); T6/T7/T9 stacked 3+3 then full; T14 full.
- **Mobile (<768):** single column. DOM order = reading order: T1 (2x2 compact StatCards), T5 attention, T2 licence, T3, T4, T6, T7, T9, T14. Because DOM order on mobile should put Attention first, define DOM order as (T1,T5,T2,T3,T4,...) and place on desktop with explicit `xl:col-span-*`/`xl:order-*`; avoid duplicate DOM.
- Quick actions in PageHeader `actions` (wraps below title on mobile by existing PageHeader classes).

### 5.2 Platform admin dashboard (`/admin`)

| # | Widget | Data needed | Component | Pri | Roles |
|---|---|---|---|---|---|
| A1 | KPI row: Total tenants, Active tenants, Learners (seats used, real), Expiring <=30d (highlight) | each `{value, previousValue}`; `expiring` has `href` | `StatCard` (+delta) in `CollapsibleSection` (replaces `_AdminStatGrid`, drops fake trend + progress-as-trend) | P1 | ops |
| A2 | Tenant growth, 12 months (new + cumulative) | `trend.tenants[{month,new,total}]` | `TrendBarChart`/Line | P1 | ops |
| A3 | Tenants by status | counts active/expiring/expired/suspended | `StatusDonutChart` | P1 | ops |
| A4 | Tenants by plan / by organisation type | counts | `StatusDonutChart` | P1 | ops |
| A5 | Needs attention: pending tenant applications, expiring tenants, open/unassigned support tickets, unredeemed/expired license codes, failed payments | `attention[{kind,count,href}]` | `ActivityList actions` (hrefs: `/admin/applications`, `/admin/tenants`, `/admin/support-tickets`, `/admin/license-codes`) | P1 | ops |
| A6 | Recently updated tenants (existing) | `recentTenants` (5) - replaces full `useTenants()` | existing `_RecentTenantsTable` + `_TenantDetailModal` | P1 (retain) | ops |
| A7 | Revenue/orders per month (+ MRR delta) | `trend.revenue[{month,amount,orders}]` | `TrendBarChart` | P2 | admin/manager |
| A8 | Seat utilisation: top 5 tenants by utilisation / near-quota | `topUtilisation[{tenantName,used,limit}]` | `ProgressBar` list | P2 | ops |
| A9 | Tenant distribution map (existing) | `byProvince[]` - **today `Tenant.location` is always null** so map is empty; keep only if backend provides province counts, else keep EmptyState | existing `_VietnamTenantMap` | P2/P3 | ops |
| A10 | Recent applications / recent support tickets | top 5 each | `DataTable` / `ActivityList` | P2 | ops |
| A11 | Content health: questions by skill (L/R/W/S), by status (draft/published), exam templates, score templates | counts | `StatusDonutChart` + `StatCard compact` | P2 | academic roles + ops (this is the ONLY block academic roles see) |
| A12 | System notice from latest announcement (replace hardcoded banner); system health only if backend truly supplies metrics | `notice` | existing `SystemNoticeBanner` fed by data / `Alert` | P2 | all |
| A13 | Platform exam volume (attempts/month across tenants), AI scoring queue depth | | `TrendBarChart`, `StatCard` | P3 | ops |
| A14 | Quick actions: Add tenant (existing), Create announcement, Add question, Generate license codes | routes | `Button`s in `PageHeader actions` (role-filtered with `hasAnyRole`) | P2 | per-role |
| A15 | Greeting with real name + locale time-of-day | `useCurrentUser` | `PageHeader title` | P1 | all |

Layout admin: desktop `lg` r1 A1 (4 cols; grid currently `lg:grid-cols-3`) / r2 A2 (8) + A3 (4) / r3 A4 (4) + A8 (4) + A5 (4) / r4 A6 (12) / r5 A9 (6) + A11 (6) / r6 A7, A10. Tablet: 2-col; mobile: single, order A1, A5, A2, A3, A4, A6, ... Academic roles: only A11, A12, A15 (+ their quick actions) -> render a compact single-column layout.

### States and a11y (all widgets)
- **Loading:** route `loading.tsx` with new `DashboardLoadingState variant="overview"`; per-widget `DashboardPanel isLoading` skeleton only for deferred (hybrid) sections. With one aggregate, a single skeleton covers everything.
- **Empty:** meaningful empty copy per widget (new tenant with 0 learners: "Import learners to start", CTA link) using `DashboardPanel isEmpty` / chart `emptyLabel`; zero KPIs show `0`, null delta shows "-".
- **Error:** whole-query failure -> one `ErrorState` with Retry (`refetch`); null section -> that panel's `ErrorState`/hidden per role. Never raw error text (`errorMessage`/`getUserFacingApiErrorMessage`).
- **a11y:** `PageHeader` h1; each panel h2 (DashboardPanel/CollapsibleSection already h2); charts `role="img"` + `aria-label` + hidden table or legend list (donut pattern); delta communicated by arrow + sign + sr-only text, not color alone; `<progress aria-label>` (already); tables get an accessible name; links >=44px target; `motion-safe:` animations only; charts `isAnimationActive={false}`; `aria-live="polite"` for refresh status only if added.

---

## 6. Pitfalls / constraints checklist
- **Size limits:** component <=150 lines, file <=300. `DataTable.tsx` (711), `LocaleProvider.tsx` (1612), `adminCopy.ts` (1005) are already over - **do not append to them**; new copy in feature `messages/` files. Split each dashboard into ~8-10 small `_Panel.tsx` files + a thin `*DashboardView.tsx` (grid composition only).
- **Route files thin:** `host/dashboard/page.tsx` must become `export default function Page() { return <HostDashboardView/>; }` (remove inline const + `"use client"`; the client boundary belongs to the view). Admin `page.tsx` is already thin.
- **No hardcoded strings:** all labels/aria/chart legends in feature constants/messages (`HOST_DASHBOARD_TEXT`, vi/en). No `"Good morning, Administrator"`, no `"+12.5%"`. Numbers via `Intl.NumberFormat(locale)` helper (no magic formatting inline).
- **No inline styles:** recharts needs a sized parent via Tailwind (`h-64 w-full min-w-0`); progress via `<progress>` (ProgressBar), not `style={{width}}`. Map SVG uses classNames (existing).
- **Tokens, no raw hex/arbitrary values;** extract `chartTones` shared by donut and new charts.
- **`@pte/ui` change policy:** additive props/variants only; grep all 6 `StatCard` users before touching it (`_AdminStatGrid`, `_QuestionStatGrid`, billing/quota/program overview). Do not restyle `PageHeader`/`StatCard`/`ActionMenu`.
- **Recharts + Next 16/React 19:** chart files `"use client"`; `ResponsiveContainer` renders 0-size on first paint if parent has no height -> give explicit `h-*`; keep `isAnimationActive={false}`. Verify `pnpm build` (peer `react ^19`, recharts 3.8.1 already builds with donut).
- **Query keys/invalidations:** define `HOST_DASHBOARD_QUERY_KEY` / `ADMIN_DASHBOARD_QUERY_KEY` in constants; invalidate from import-roster, create-class, create-session, tenant create (`useCreateTenantFlow`) mutations. Clear on logout is handled by `subscribeSessionLifecycle` -> `queryClient.clear()`.
- **Next 16:** `error.tsx` use `unstable_retry`; no `params` use here so async-params breaking change not relevant; `loading.tsx`/`error.tsx` for `/host/dashboard` and `/admin` (static routes - not mandated by CLAUDE.md rule 7, but both dashboards benefit; use the new `overview` skeleton).
- **Time zones:** "this week/month", upcoming-session times must be computed server-side in the tenant's zone (VN +07); FE only formats (`Intl.DateTimeFormat(locale)`). Don't recompute periods client-side.
- **Admin tenant list pagination:** after the aggregate, `OverviewView` should stop calling `useTenants()`; `TenantDetailModal` needs a single tenant (`getTenant` exists) fetched on open instead of the whole list.
- **Fake fields:** do not render `seatsUsed`/`location`/`activatedAt` from the placeholder `Tenant` model on the dashboard; use aggregate values only.

## Relevant files
- `D:\FPT-FALL2026\Capstore\pte-web\apps\tenant-web\app\(dashboard)\host\dashboard\page.tsx` - current thin-violating page (inline text, `LearnersOverview`).
- `D:\FPT-FALL2026\Capstore\pte-web\apps\tenant-web\features\examoperations\components\LearnersOverview.tsx` - section to keep (own `useStudentRoster`).
- `D:\FPT-FALL2026\Capstore\pte-web\apps\vendor-web\features\dashboard\components\OverviewView.tsx` (+ `_AdminStatGrid.tsx`, `_RecentTenantsTable.tsx`, `_VietnamTenantMap.tsx`, `_SystemNoticeBanner.tsx`) and `features\dashboard\{constants,types}.ts` - fake trends, client-side counting from full tenant list.
- `D:\FPT-FALL2026\Capstore\pte-web\packages\ui\src\components\{StatCard,DashboardCard,StatusDonutChart,CircularProgressChart,ProgressBar,CollapsibleSection,DashboardLoadingState,EmptyState,ErrorState,PageHeader,DataTable}.tsx` - inventory.
- `D:\FPT-FALL2026\Capstore\pte-web\packages\ui\src\i18n\LocaleProvider.tsx`, `apps\vendor-web\features\i18n\adminCopy.ts`, `apps\tenant-web\features\examStaff\detail\{messages,hooks\useStaffDetailText.ts}` - i18n mechanisms.
- `D:\FPT-FALL2026\Capstore\pte-web\apps\tenant-web\features\orgLabels\{constants,useOrgLabels}.ts` - org labels (identical dictionaries).
- `D:\FPT-FALL2026\Capstore\pte-web\apps\vendor-web\features\auth\{constants,permissions}.ts`, `apps\vendor-web\lib\navigation.tsx` - admin role matrix.
- `D:\FPT-FALL2026\Capstore\pte-web\packages\api-client\src\requests\{admin\examStaffWorkspace.ts,billing\quota.ts,reporting\reports.ts}` - request/aggregate precedents (`StaffOverviewResponse` nullable sections).
- `D:\FPT-FALL2026\Capstore\pte-doc\design\stitch-pte-tenant-web\01-dashboard-overview\screen.{png,html}` - tenant design target.
- `D:\FPT-FALL2026\Capstore\pte-doc\projects\plans\codex-20260919-vendor-tenant-ui-authoring\phase-04-collapsible-statistics-overview.md` - prior KPI-section convention.

## Open questions for the planner
1. Is "Branch" (design) a real concept for tenants (maps to `organizations`)? If not, drop from upcoming-sessions table.
2. Does the backend have per-skill score data and per-month attempt aggregation cheaply (T3, T9)? Otherwise T9 -> P3.
3. Real tenant `location`/province: required for A9 map; otherwise mark map as deferred.
4. Admin KPI "learners": define as distinct active students (not seats) - confirm.

## Verdict
Researcher B (Alternative): per-widget endpoints / hybrid -> NOT recommended as the primary; keep one aggregate per dashboard with a sectioned/nullable envelope (precedent `StaffOverviewResponse`, `ProgramDashboard`) and split off only the param-driven trend later; add StatCard delta ext, DashboardPanel, TrendBarChart (recharts, already installed), ActivityList to @pte/ui.
