# Specification: Tenant student detail and performance workspace

**Date:** 2026-10-10
**Status:** Implemented baseline; superseded UX decisions below take precedence over historical wording
**Repository scope:** `pte-api`, `pte-web`, `pte-doc`
**Related UX decision:** `brainstorm.md`

## Superseding decisions (2026-10-10)

Detail navigation is same-tab through the client router, not a new browser tab. Overview is first/default, followed by Account information and Exam history. Account starts read-only; Edit changes only permitted fields inline in the existing layout. Use common ActionMenu ellipsis, DescriptionList and PageHeader without visual overrides. Place copy beside the student code; omit the menu copy action, password notice and redundant back link. Deep breadcrumbs show Learners > learner name, with no Home entry. These decisions supersede contrary original requirements below.

## 1. Problem statement

The tenant student roster is useful for finding and acting on students, but the current modal detail surface cannot support profile maintenance and performance analysis. The next experience needs a durable URL, a first-class account view, server-backed attempt history, and score summaries that respect the existing PTE report semantics.

The feature must not solve this by duplicating identity, enrollment, attempt, or reporting data in the frontend. The backend remains responsible for authorization, filtering, pagination, relationship validity, and score aggregation.

## 2. Goals

- Give a tenant administrator a dedicated student workspace opened in a new tab.
- Put account information and permitted account actions first.
- Allow safe editing of profile fields without exposing credentials or mutating class/program assignment accidentally.
- Show server-backed attempt history with bounded pagination and explicit report state.
- Show average performance for the four communicative skills using existing score semantics.
- Avoid N+1 report calls and client-side aggregation of large datasets.
- Keep the existing roster behavior and shared UI system stable.

## 3. Actors and authorization

### Primary actor

`HOST_ADMIN` operating inside the current tenant.

### Out-of-scope actor

`PLATFORM_ADMIN` cross-tenant student inspection is out of scope for this feature. Existing platform-level user-management surfaces are not changed by this plan.

### Authorization rules

- Every new student-workspace read and mutation resolves the target student through the caller's authorized tenant scope.
- The new student-workspace endpoints are available to `HOST_ADMIN` for the current tenant only.
- A student public ID supplied by the browser is never sufficient authorization by itself.
- Profile update, suspend/reactivate, and credential generation use the existing identity ownership and role hierarchy.
- No endpoint returns a password, password hash, reset token, or other credential secret except the existing one-time plaintext credential response required by the generate-credentials action.
- Forbidden and not-found behavior must follow the existing API error contract and must not disclose cross-tenant existence.

## 4. User stories

### US-01: Open a student workspace

As a tenant administrator, I can open a student from the roster in a new tab so that the roster state remains available while I inspect or edit the student.

### US-02: Review and edit account information

As a tenant administrator, I can see the student's account information first and edit only the fields the identity contract allows.

### US-03: Manage student status and credentials

As an authorized administrator, I can suspend/reactivate a student and generate a fresh temporary credential with the existing one-time display behavior.

### US-04: Understand current performance

As a tenant administrator, I can see attempt count, latest attempt, overall average when valid, and per-skill averages without confusing missing data with zero.

### US-05: Investigate attempt history

As a tenant administrator, I can page through a student's attempts and filter the history through the API without loading or aggregating the entire dataset in the browser.

## 5. Functional requirements

### FR-01: New-tab detail route

The roster's detail action SHALL open a stable route containing the student public ID. Direct navigation and refresh SHALL load the same student workspace, subject to authorization.

### FR-02: Account tab is first

The default tab SHALL be `Thông tin tài khoản`, followed by `Tổng quan` and `Lịch sử làm bài`. The selected tab may be represented in the URL only if this follows the existing tenant route convention.

### FR-03: Profile editing

The form SHALL support full name, email, phone, and date of birth according to the backend validation contract. Email is editable. Username, role, student code, current class, and current program SHALL be read-only and SHALL not be accepted by the profile mutation.

### FR-04: Safe credential action

The page SHALL reuse the existing student credential-generation semantics. Existing passwords SHALL never be shown. The generated temporary credential SHALL be displayed once and SHALL not be persisted in client state after the one-time flow is closed or refreshed.

### FR-05: Status actions

Suspend/reactivate actions SHALL use the existing API behavior, require confirmation where destructive or disruptive, and invalidate the account query and the roster row state after success.

### FR-06: Performance summary

The overview SHALL use a bounded server response containing attempt totals, latest-attempt context, overall average when valid, and four skill summaries. Official KPI and skill averages SHALL include only published, immutable reports with sufficient data. The browser SHALL not calculate the official average from a complete attempt list.

### FR-07: Attempt history

The history SHALL request page, size, and supported filters from the API. The default page size SHALL be bounded by the backend. Rows SHALL expose attempt lifecycle and report state, including unpublished/no-report states, without presenting live scores as official results or issuing one report request per row.

### FR-08: Explicit score states

The UI SHALL distinguish at least: no attempts, no sufficient score data, score available, and report unavailable/not permitted. A missing or untested skill SHALL not render as a numeric zero.

### FR-09: Resilient states

Account, overview, and history surfaces SHALL expose independent loading, empty, error, and forbidden states where independent requests are used. A failure in history must not blank the account tab.

### FR-10: Responsive and themed UI

The new route SHALL work at the tenant app's supported desktop/tablet widths and preserve light/dark token behavior. Long names, emails, class names, and localized status text SHALL not break the layout.

## 6. Proposed API contract

The exact route and DTO names are finalized in Phase 01 against the current API conventions. The following is the baseline contract for planning:

### 6.1 Student detail read

`GET /api/v1/students/{studentPublicId}`

Returns a composite, read-only detail view needed by the account tab: identity fields, current status, roles, current class/program context, and capability flags for permitted actions. It should avoid making the frontend call several identity/enrollment endpoints just to render the header.

### 6.2 Profile update

`PATCH /api/v1/users/{studentPublicId}`

Baseline editable body:

~~~json
{
  "fullName": "UI Review Student 12",
  "email": "ui.review.student12@test.local",
  "phone": "09120012",
  "dateOfBirth": "2008-12-12"
}
~~~

The identity module owns validation and persistence. The endpoint must not mutate class/program assignment and must not accept password or role fields.

### 6.3 Attempt history

`GET /api/v1/students/{studentPublicId}/attempts`

Planned parameters:

- `page`, `size`
- supported sort field and direction
- optional `from`, `to`
- optional attempt/report status filters
- `from`, `to`, and supported attempt/report status filters. No program filter is included in the detail history contract for V1.

The response follows the existing `ApiResponse`/`PagedResult`/page metadata conventions rather than inventing a second pagination envelope.

### 6.4 Performance summary

`GET /api/v1/students/{studentPublicId}/performance`

Planned parameters are a bounded date range. The calculation scope is fixed to published, immutable reports with sufficient data; the browser must not opt into live/unpublished score aggregation. The response includes the calculation scope, attempt count, latest attempt context, overall average if valid, and skill summaries for Listening, Reading, Speaking, and Writing.

### 6.5 Existing actions retained

The detail route continues to use the existing identity actions for suspend, reactivate, and one-time student credential generation unless Phase 01 identifies a contract defect. Existing report endpoints remain responsible for an attempt-level report view.

## 7. Domain and data semantics

- Current class/program context comes from the authoritative enrollment/membership relationship, not the identity `className` display field.
- The student's current program is account context only. V1 does not claim a historical program for an attempt.
- Student code is currently treated as a read-only identity identifier in the UI.
- `ExamAttempt` owns attempt identity, student, tenant, status, and timestamps.
- `AttemptReport` owns report publication and score snapshot semantics.
- The four communicative skills are Listening, Reading, Speaking, and Writing.
- Missing, untested, or insufficient data is omitted or marked unavailable according to the reporting contract; it is never converted to zero.
- A GET used by the new history/performance read model must not lazily create report records as a side effect.
- History may label unpublished or missing reports, but performance aggregation excludes them from official averages.
- Date filtering for performance uses the documented report publication/score scope; date filtering for history uses attempt lifecycle timestamps. The final API contract must make this distinction explicit.

## 8. Out of scope

- Class/program assignment changes.
- New exam or scoring algorithms.
- Student self-service changes.
- Password reset history or password display.
- Bulk student import changes.
- Replacing `DataTable` or redesigning unrelated vendor tables.
- Historical program segmentation in the detail workspace; this is a future analytics extension requiring a reliable historical relationship.
- Database snapshot/migration work solely to support a V1 detail-page program filter.
- Cross-tenant `PLATFORM_ADMIN` access to the student workspace.
- Production deployment or data migration execution in this plan.

## 9. Measurable acceptance criteria

- From the roster, `Xem chi tiết` opens the new student route in a separate tab and the original list remains usable.
- On first load, `Thông tin tài khoản` is selected and the header identifies the correct student.
- Profile updates persist only approved fields; unauthorized, invalid, cross-tenant, and stale updates return the existing API error shape.
- No browser response or rendered UI exposes a stored password/hash.
- History requests are paginated and filter parameters are visible in the request; the browser does not fetch every attempt.
- The existing roster program filter remains available for finding students; the detail history does not add a duplicate program selector in V1.
- Performance values match the server's score semantics for tested skills, use only published immutable reports, and never show missing skills as zero.
- The feature does not create one report request per history row.
- Focused backend/API-client/frontend tests plus tenant-web typecheck/build pass for the changed scope. Manual UI inspection is performed by the user; no automated browser/E2E verification is claimed by this plan.

## 10. Traceability

- UX decisions: `brainstorm.md`
- Phase sequencing and gates: `plan.md`
- Existing tenant UI conventions: `pte-web` shared `@pte/ui` components and tenant route patterns
- Existing backend contracts: identity, enrollment, attempt, session, and reporting public service boundaries
