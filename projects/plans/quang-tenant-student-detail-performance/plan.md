# Plan: Tenant student detail and performance workspace

**Date:** 2026-10-10
**Status:** Implemented for Phases 01–05; fresh typechecks and 23 focused backend tests passed; manual UI and independent `ck:quality` approval remain pending
**Mode:** Hard
**Repository scope:** `pte-api`, `pte-web`, `pte-doc`
**Owner/slug:** `quang-tenant-student-detail-performance`

## Objective

Replace the tenant roster's modal-only student detail path with a dedicated same-tab student workspace. Show Overview first/default, followed by Account information and Exam history. Account information starts read-only and switches editable fields to inputs in the same layout. Preserve tenant authorization, identity ownership, report semantics, and the existing shared UI system.

## Superseding user decisions and verification (2026-10-10)

- Same-tab client navigation replaces the original new-tab proposal wherever mentioned in older phase notes.
- Overview is first/default; Account information is second; Exam history is third.
- Dashboard breadcrumbs omit Home and root-level breadcrumbs; detail shows Learners > learner name, without an extra back link.
- Use default common ActionMenu (ellipsis only), PageHeader, DescriptionList and shared typography; no one-off visual overrides. Student-code copy is beside the code, not a menu action. Remove the persistent password notice.
- Fresh verification: tenant-web and vendor-web `tsc --noEmit`, `@pte/ui` and `@pte/api-client` typechecks passed; the selected backend test run completed 23 tests with zero failures/errors/skips.
- This is not browser/E2E, production PostgreSQL verification, or independent `ck:quality` approval. Earlier build evidence is historical, not a build rerun for this commit.

## Scope challenge

### Does the capability already exist?

Partially. The roster already has student discovery, status actions, credential generation, and a modal account summary. The backend has identity detail/actions and individual report reads. There is no dedicated student workspace route, profile update endpoint, tenant-scoped attempt-history query, or batch performance summary suitable for this UX.

### Minimum viable implementation

1. A stable tenant detail route opened through same-tab client navigation.
2. Account tab with read/edit fields and existing status/credential actions.
3. Server-paginated attempt history.
4. Server-owned overall and four-skill performance summary.
5. Focused backend/API-client/frontend tests plus typecheck/build; manual UI review by the user.

### Complexity classification

Hard. This is a multi-repository, multi-module feature involving identity mutation, cross-module read composition, authorization, pagination, report semantics, a new route, charting, and regression risk in an already modified worktree.

## Verified source constraints

- The tenant roster route is `apps/tenant-web/app/(dashboard)/host/students/page.tsx` and currently renders `StudentSearchView`.
- The roster currently opens `AccountDetailsModal`; the new route must replace this path without disturbing existing row actions.
- `@pte/ui` already contains the needed table, form, tab, status, description, progress, stat, and modal primitives.
- `apps/tenant-web` already has Recharts and a chart wrapper; no new chart dependency is required.
- `StudentRosterController` is host-scoped and already supports server-side roster search/filter parameters.
- `UserController` owns user detail, suspend/reactivate, and credential actions but currently has no profile PATCH contract.
- `ExamAttempt` and `AttemptReport` are separate domain owners. Report reads have publication and sufficient-data semantics that must be preserved.
- The current data model does not persist a historical program relationship for every attempt; the detail workspace therefore omits program filtering in V1. The existing roster program filter is unchanged.
- Cross-module repositories are not a valid shortcut. New composition must use public service boundaries or a deliberately owned query/read facade.

## Architecture decisions

### AD-01: Dedicated student resource read model

Use a student detail read model for the new page rather than orchestrating multiple identity, enrollment, session, and report requests in the browser. The read model may be implemented in the module/application boundary selected during Phase 01, but it must use public cross-module contracts and must remain tenant-scoped.

### AD-02: Identity owns profile mutation

Profile fields belong to the identity aggregate. The proposed `PATCH /api/v1/users/{studentPublicId}` accepts only approved profile fields. Class/program membership is not edited by this form.

### AD-03: Server owns history and performance calculations

The API provides bounded history pages and an aggregate performance response. The frontend renders the response and does not calculate official averages from a full attempt list.

### AD-04: No side-effectful report fan-out

History/performance queries must not call the individual report endpoint once per row or create report records as a GET side effect. Add a batch/query projection where the current service boundaries require one.

### AD-05: Approved tab order

The route renders `Tổng quan` first and selected by default, then `Thông tin tài khoản`, then `Lịch sử làm bài`.

### AD-06: Official performance scope

The history is an activity view and may contain attempts whose reports are missing, live, or unpublished. Official overall and skill averages are calculated only from published, immutable reports with sufficient data. This keeps operational history visible without making unstable scores look official.

### AD-07: Detail history scope

Keep V1 detail history focused on date and status/report-state filters. Do not derive historical program from current membership and do not add snapshot/migration work solely for a detail-page selector. If program-level analytics is required later, it must scope both history and overview and introduce a reliable historical relationship first.

## Proposed route and API surface

### Frontend route

`/host/students/{studentPublicId}`

The roster detail action uses the existing client router in the same browser tab; it must not trigger a full-document reload.

### Backend baseline

| Capability | Baseline endpoint | Owner/constraint |
| --- | --- | --- |
| Detail read | `GET /api/v1/students/{studentPublicId}` | Composite read; `HOST_ADMIN` current tenant only |
| Profile edit | `PATCH /api/v1/users/{studentPublicId}` | Identity-owned fields; email editable, student code read-only |
| Attempt history | `GET /api/v1/students/{studentPublicId}/attempts` | Bounded page/size; date/status filters; no N+1 |
| Performance | `GET /api/v1/students/{studentPublicId}/performance` | Published immutable reports only; server aggregation |
| Status | Existing suspend/reactivate routes | Preserve current role hierarchy |
| Credential | Existing generate-credentials route | One-time plaintext only |

Phase 01 may refine names to match the API's existing resource conventions, but changing the ownership or authorization semantics requires an explicit plan update.

## Phase map

| Phase | Surface | Outcome | Gate |
| --- | --- | --- | --- |
| 01 | `pte-api` contract/domain | Finalized DTOs, route ownership, permission matrix, history/score semantics | No implementation until cross-module contract and open questions are resolved |
| 02 | `pte-api` | Detail, profile update, history, and performance query capabilities | Backend tests and security/query review pass |
| 03 | `pte-web` API client/state | Typed requests, query keys, mutations, invalidation, filter state | Client tests/typecheck pass without changing unrelated APIs |
| 04 | `pte-web` route/account | New-tab route, header, account-first tabs, profile/actions | Route/account UX and action states verified |
| 05 | `pte-web` overview/history | KPIs, skill visualization, server-paginated history | Focused data-state/request checks pass; manual UI review remains with user |
| 06 | `pte-web`/`pte-api`/`pte-doc` | Focused checks, quality audit, handoff | Focused tests/build and explicit verification report complete |

## Phase dependencies

~~~text
Phase 01: contract and permissions
          |
          +--> Phase 02: backend query/mutation capabilities
          |                |
          |                +--> Phase 03: API client and query state
          |                                 |
          |                                 +--> Phase 04: route and account tab
          |                                                  |
          |                                                  +--> Phase 05: overview and history
          |                                                                   |
          +-------------------------------------------------------------------+--> Phase 06: quality and handoff
~~~

## Design constraints

- Preserve unrelated changes already present in `pte-web`.
- Do not edit the shared table to create a one-off student-detail table. Reuse the current primitives and make additive changes only where a real shared need is demonstrated.
- Keep the current tenant brand tokens, light/dark behavior, and status language.
- Preserve existing list filters and server-owned filtering behavior.
- Do not leak passwords, password hashes, reset tokens, or cross-tenant existence.
- Keep the new student workspace and its management actions restricted to `HOST_ADMIN` in the current tenant; platform-admin cross-tenant access is out of scope.
- Do not use current class/program fields as historical attempt truth.
- Do not add a detail-page program filter or fallback to current membership in V1.
- Do not include live/unpublished reports in official KPI or skill averages; expose their state only in history where useful.
- Avoid direct cross-module repository imports and unbounded page sizes.
- Keep GET handlers free of report-creation side effects.
- No new package dependency without an explicit contract decision; Recharts is already available.
- No production migration, deployment, commit, or push is part of this plan.

## Quality and Testing State

Implementation evidence recorded for the code phases. The user explicitly requested code-only execution, so focused tests and the independent `ck:quality` gate were skipped. The current evidence is:

- `pte-api`: `./mvnw.cmd -pl app -DskipTests compile` passed;
- `pte-web`: API-client typecheck, tenant-web `tsc --noEmit`, and tenant-web production build passed;
- `pte-web` and `pte-api`: `git diff --check` passed and conflict-marker scans are clean;
- focused unit/integration/component tests were skipped by user request;
- independent `ck:quality` was skipped by user request;
- manual UI inspection remains with the user.

Automated browser/E2E verification is outside this agreed validation scope and must not be reported as completed.

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| N+1 report calls make the page slow | Add a batch/read projection and assert request counts with focused request/component checks |
| Cross-tenant IDOR through student public ID | Reuse scoped identity lookup and enforce tenant checks in every new query/mutation |
| Profile form changes assignment data accidentally | Keep class/program read-only and separate from identity PATCH |
| Missing scores render as zero | Carry `sufficientData`/report state through DTO and render explicit unavailable states |
| Historical program context is misleading | Omit a detail-page program filter in V1; keep program filtering on the roster, and require an approved historical relationship before adding future detail analytics |
| GET creates report rows | Use read-only report projection/queries for history and aggregates |
| New route regressions affect list actions | Migrate only the detail action, retain status/credential actions, and run roster regression checks |
| Shared UI change breaks vendor screens | Prefer existing components and inspect/test all changed shared surfaces |
| Static checks overstate readiness | Report browser, live API, and release boundaries separately |

## Definition of done

- All product decisions are resolved and reflected in the contract; the historical program relationship and test-scope gates are explicitly documented.
- Phases 01–05 are implemented without unapproved scope expansion.
- The student detail tab order is overview, account, history.
- The roster opens detail in the same tab through client navigation.
- Profile and action permissions are enforced server-side.
- History and performance are server-backed, bounded, and free of per-row report fan-out.
- V1 detail history intentionally omits program filtering; the existing roster filter remains the discovery mechanism.
- Score semantics and unavailable states are visible and correct.
- Focused tests, tenant-web checks, manual UI review, and independent quality review are recorded with their limitations.
- No unrelated worktree changes are removed or overwritten.

## Decisions before cook

- V1 detail history includes server-side date/status filters only. Program-level detail analytics is a future extension.
- Run focused backend/API-client/frontend tests plus typecheck/build.
- Manual UI inspection is performed by the user; automated browser/E2E verification is not part of this execution scope.

## Next command after those decisions

~~~text
/ck:cook --hard plans/quang-tenant-student-detail-performance/plan.md
~~~
