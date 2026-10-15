# Brainstorm: Tenant student detail and performance workspace

**Date:** 2026-10-10
**Status:** Approved UX direction; implementation planning
**Mode:** Hard
**Repository scope:** `pte-api`, `pte-web`, `pte-doc`

## Context

The tenant student roster currently exposes account details in a modal. That surface is too small for the next set of operations: editing student information, issuing credentials, reviewing attempt history, and understanding skill performance. The approved direction is to move the detail experience to a dedicated browser tab while keeping the roster as the operational list.

The existing roster remains the source for discovery and filtering. The new page is a student workspace, not a second copy of the roster and not a replacement for the shared `DataTable`.

## Approved product direction

### Entry and navigation

- The roster action `Xem chi tiết` opens `/host/students/{studentPublicId}` in a new browser tab.
- The roster keeps its current search, filters, pagination, and scroll state in the original tab.
- The page header always shows the student name, student code, status, and contextual actions.
- The first and default tab is `Thông tin tài khoản`.
- The remaining tabs are ordered as:
  1. `Thông tin tài khoản`
  2. `Tổng quan`
  3. `Lịch sử làm bài`

### Account tab

The account tab is the operational starting point. It displays and, where permitted, edits:

- Editable: full name, email, phone, and date of birth.
- Read-only: username, student code, role, current class, and current program relationship.
- Status actions: suspend/reactivate, subject to the current tenant authorization policy.
- Credential action: generate a fresh temporary student credential and show it once; never display an existing password or password hash.
- The page must preserve the distinction between identity/profile fields and class/program assignment data.

### Overview tab

The overview is a compact decision surface:

- KPI cards: number of attempts, average overall score when available, and latest attempt.
- Four horizontal skill summaries: Listening, Reading, Speaking, and Writing.
- A recent-attempt table with enough context to open an attempt-level report when the current authorization and report state allow it.
- Missing or insufficient score data is shown as unavailable; it is never converted to zero.

### History tab

- History is a server-paginated table, not a client-side timeline.
- Filters are sent to the API, with bounded page size and normalized date/status values.
- The page must not infer a historical program from the student's current program. The roster keeps its program filter; the detail history does not add a program selector in V1.
- Attempt rows contain summary data only. The UI does not fan out into one report request per row.

## UX principles

- Operations first: the account tab is immediately useful to a tenant administrator.
- Progressive disclosure: details and analytics are available without overcrowding the list page.
- Clear data states: loading, empty, insufficient data, forbidden, and failed requests have distinct presentation.
- Flat, bordered cards and the existing PTE brand blue/token system are preserved in light and dark themes.
- Reuse `@pte/ui` primitives (`Tabs`, `DescriptionList`, `DataTable`, `StatCard`, `ProgressBar`, `StatusBadge`, `ConfirmDialog`, and existing form controls).
- Use the existing Recharts wrapper in tenant-web; do not add a chart dependency.

## Deliberate non-goals

- No replacement of the roster table primitive.
- No change to class/program assignment workflows from the profile form.
- No password recovery/history view.
- No new scoring algorithm or change to score-template weighting.
- No client-side aggregation of an unbounded attempt list.
- Historical program segmentation is a future analytics extension; V1 does not require a program snapshot or migration for the detail page.

## Design decisions carried into the plan

1. A dedicated new-tab route is the primary detail surface; the existing account modal is retired from the student roster path after all references are migrated.
2. Account information is first, followed by performance overview and attempt history.
3. The browser consumes server-owned filters, pagination, authorization, and score semantics.
4. Cross-module reads must use public application/service boundaries or a deliberate read/query facade; controllers must not reach into another module's repository.
5. The implementation is split into a domain/API contract phase, backend phase, API-client phase, route/account phase, overview/history phase, and final quality handoff.

## Resolved decisions and remaining implementation gates

The following product decisions are now fixed:

1. The workspace is tenant-scoped and managed by `HOST_ADMIN` inside the current tenant. Cross-tenant `PLATFORM_ADMIN` access is out of scope for this feature.
2. Email is editable. Student code is read-only and cannot be changed from the account form.
3. The history may show tenant-visible attempts with explicit states such as `Đang làm`, `Đã nộp`, `Chưa có báo cáo`, `Chưa công bố`, and `Đã công bố`. Official KPIs and skill averages use only published, immutable reports with sufficient data; live/unpublished scores are excluded from averages.

The remaining implementation decisions are now resolved:

1. V1 detail history uses date/status filters only. The program filter remains on the student roster, where it helps find students. A future detail analytics filter must scope both history and overview and require a reliable historical relationship.
2. Validation scope is focused backend/API-client/frontend tests plus typecheck/build. The user will manually inspect the UI, so this plan does not claim browser/E2E verification.
