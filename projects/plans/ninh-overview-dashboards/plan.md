# Plan: Overview Dashboards (Tenant Host + Platform Admin) - Task #69
Status: 🟡 In Progress
Date: 2026-10-12
Mode: Hard
Revision: 2 (red-team adjudication applied)

## Overview
Deliver real, data-backed overview screens for tenant-web `/host/dashboard` (HOST_ADMIN only, LearnersOverview kept as the last full-width section) and vendor-web `/admin` (role-aware for PLATFORM_ADMIN/PLATFORM_MANAGER vs ACADEMIC_MANAGER/ACADEMIC_STAFF). Each dashboard is served by ONE aggregate endpoint in pte-api with honest period-over-period trends, replacing the current client-side counting and fake trends in vendor-web. Repos: backend `D:\FPT-FALL2026\Capstore\pte-api`, frontend `D:\FPT-FALL2026\Capstore\pte-web`. The user commits by themselves; this plan contains no commit/PR steps.

## Phases
- [x] Phase 1: [quality: approved (no receipt: report outside pte-web repo); tests: passed incl. Postgres+EXPLAIN] Backend foundations + host core - baseline recording, leaf `overview` module, section/trend envelope, cache, host index migration (V94), host core sections
- [x] Phase 2: [quality: approved after 1 fix cycle (no receipt: report outside pte-web repo); tests: passed, Postgres+EXPLAIN on scratch PG17] Backend host commercial and ops - grading backlog, subscription/expiry, pending order count, support facade, recent activity
- [ ] Phase 3: Backend admin core + role gating - section-to-permission table, tenants + growth series, learners, recent tenants, applications, licenses, subscriptions, plans, support; platform-wide indexes (V96)
- [ ] Phase 4: Backend admin revenue + question bank - per-currency revenue and extended question bank stats (V97 only if needed)
- [ ] Phase 5: Frontend api-client contract + app `typecheck` scripts - dashboard types, endpoint constants, request functions, tests
- [ ] Phase 6: @pte/ui dashboard primitives - StatCard delta (additive), DashboardPanel, trend charts, ActivityList, icons, overview skeleton
- [ ] Phase 7: Tenant host dashboard UI - feature module, thin route, widgets, i18n messages, LearnersOverview retained last
- [ ] Phase 8: Vendor admin dashboard UI - role-aware sections, remove fake data and full tenant-list dependency, vitest installed in vendor-web
- [ ] Phase 9: Integration verification, states and polish - route-specific loading/error, responsive + a11y pass, end-to-end check per role
- [ ] Phase 10 (DEFERRED - not in this cook; see "Deferred / Follow-up" at the end): Tenant province for the map - province captured through application/approval/create flows, map aggregate, vendor form field

## Validation Decisions (user, 2026-10-12)
1. Backend ownership: Claude implements BOTH backend (Phases 1-4) and frontend (Phases 5-9). Cook order 1 -> 9.
2. Architecture test: only add `examstaff` to the asserted module list; pre-existing cycles are left untouched. Gate = no NEW violations vs the Phase 1 baseline.
3. Phase 10 (province for the map) is DEFERRED. The map ships with an empty-state in Phase 8. Do not cook Phase 10.
4. P3 widgets (staff coverage, academic structure, tenant own support tickets / pending orders cards, admin plans card) ARE built as compact cards after P1/P2 ("as complete as possible").

## Phase Dependencies
- 1 -> 2 -> 3 -> 4 (Phase 3 depends on Phase 2 because billing and support facades are created in Phase 2 and extended, not duplicated, in Phase 3: one facade owner per module).
- Phase 5 step 1 (adding `typecheck` scripts to both apps) is the first FE action and must land before any FE verification in Phases 6-9. The remaining Phase 5 work may start once the envelope and host contract (end of Phase 1) and the admin draft (start of Phase 3) are frozen; types are extended additively when Phases 2, 3 and 4 land.
- Phase 6 is independent of the backend and can run in parallel with Phases 1-4 after Phase 5 step 1.
- Phase 7 needs Phases 5 + 6 and backend Phase 1 (P1 widgets) / Phase 2 (remaining widgets).
- Phase 8 needs Phases 5 + 6 and backend Phase 3 (P1) / Phase 4 (revenue, question bank). The map ships with an empty-state fallback until Phase 10.
- Phase 9 needs Phases 7 and 8 and all backend phases 1-4.
- Phase 10 is optional and needs Phases 3 and 8 (admin gating, vitest install in vendor-web, and the map consumer); it only turns the map empty-state into real data. It also changes the public register-organisation form in tenant-web.

## Migration Numbering (recheck at merge time; another branch may take numbers)
| Phase | Migration | Content |
|---|---|---|
| 1 | V94 | host tenant-leading composite indexes (attempts by tenant+submitted/started time, others as measured) |
| 2 | V95 (only if needed) | reports (tenant, published) index if EXPLAIN shows it is required |
| 3 | V96 | platform-wide time-leading attempt indexes (started_at, submitted_at, partial on not deleted), subscription (status, expires_at), support (status, created_at), application (status, created_at), tenants created_at |
| 4 | V97 (only if needed) | revenue paid_at index if EXPLAIN shows it is required |
| 10 | V98 | tenants/applications province columns |

## Research Summary
Chosen approach (researcher A primary, researcher B alternative cross-checked, red-team adjusted):
- One aggregate endpoint per dashboard (`GET /api/v1/dashboard/host`, `GET /api/v1/dashboard/admin`, optional window of 7/30/90 days, default 30), living in a NEW leaf Modulith module `overview` that composes small public per-module summary facades (never internal repositories). This avoids the billing -> tenancy cycle and keeps ownership in one place.
- Sectioned envelope: every widget section is `{status: OK | ERROR | FORBIDDEN, data}`; one failing widget does not blank the page; academic admin roles receive FORBIDDEN for operations sections instead of a whole-request 403. The admin controller itself rejects callers that carry a tenant id (HOST_ADMIN gets 403) instead of relying on a bare role annotation.
- Trend shape `{current, previous, changePct|null}` on rolling windows; `changePct` is null when previous is zero. Monthly series are bucketed in Asia/Ho_Chi_Minh (zone returned in meta), the current partial month is included and flagged partial. Metrics without history (tenant status over time, seat utilisation over time, ticket resolve time, average score) are shown as current value or deferred.
- Caching (existing Redis template, no new dependency): host TTL 30s, admin TTL 60s. Host key = tenant id + window + schema version; admin key = visibility bucket + window + schema version, where the bucket is the COMPUTED visibility set (operations vs academic), not the raw role (legacy PLATFORM_AUTHOR canonicalizes to ACADEMIC_STAFF). Host core counts (cheap indexed counts) are NOT cached so the frontend's post-mutation refetch is fresh; only heavy host sections are cached. Payment links are never returned or cached. Mutations may appear on cached sections after up to one TTL; this is documented behaviour.
- Query portability: default backend tests run on H2 with Flyway disabled and schema auto-created, so migrations never run there and schema validation does not check indexes. Therefore all new aggregate queries are portable JPQL/derived queries covered by repository tests, and a separate Postgres-gated integration test (or compose boot with a health check) proves Flyway V94+ migrates.
- Frontend: one query per dashboard, widgets are dumb panels fed by sections; additive @pte/ui extensions on recharts (already installed). "Needs attention" lists are derived feature-side from section counts.

Rejected alternatives:
- Per-widget endpoints / hybrid fetching: more authz and tenant resolution per page, N query keys to invalidate, more states; the user also decided on aggregates.
- Placing aggregators inside tenancy or billing: creates module cycles and splits ownership.
- Spring cache starter / Caffeine: new dependency, not shared across instances.
- New chart library or tenant-web's unused chart wrapper: recharts already a @pte/ui dependency.
- Appending copy to the 1005-line admin copy dictionary or the 1612-line locale provider: use sibling message files.
- Backend templates and platform-health sections: dropped (no widget consumes them); can return in a later task together with a widget.
- Province inside the admin-extras phase: under-scoped (touches the application, approval and create flows), moved to optional Phase 10.

## Section -> Widget Map (every backend section must have a consumer, else it is dropped)
| Dashboard | Section | Consumer widget (phase) | Priority |
|---|---|---|---|
| Host | learners | KPI row, learner assignment split (7) | P1 / P2 |
| Host | quota | seat/subscription usage panel (7) | P1 |
| Host | academics | compact academic-structure card (7) | P3 |
| Host | staff | compact staff coverage card (7) | P3 |
| Host | exams | upcoming sessions, sessions KPI, status donut (7) | P1 / P2 |
| Host | attempts | attempts KPI, 12-month trend (7) | P1 |
| Host | grading | grading pipeline panel, needs-attention (7) | P1 (attention) / P2 (panel) |
| Host | subscription | usage panel expiry warning (7) | P1 |
| Host | billing (pending order count only, no payment link) | compact orders card, needs-attention (7) | P3 |
| Host | support (own tickets) | compact tickets card, needs-attention (7) | P3 |
| Host | recentActivity | activity timeline (7) | P2 |
| Admin | tenants (+ growth series, by org type) | KPI row, growth chart, status and org-type donuts (8) | P1 |
| Admin | learners (+ top seat utilisation) | KPI row, utilisation list (8) | P1 / P2 |
| Admin | recentTenants | recent tenants table + detail modal (8) | P1 |
| Admin | applications | needs-attention, oldest pending list (8) | P1 / P2 |
| Admin | licenses | licenses card, needs-attention (8) | P2 |
| Admin | subscriptions | subscriptions card, expiring KPI (8) | P1 / P2 |
| Admin | plans | plans card (8) | P3 |
| Admin | support | needs-attention, oldest tickets list (8) | P2 |
| Admin | revenue | revenue panel (8) | P2 |
| Admin | questionBank | content health (all four roles) (8) | P2 |
| Admin | map | Vietnam map (8 empty-state; real data in 10) | P3 |

## Widget Priority Summary
- Host: P1 learners/quota/KPI row, attempts + sessions, upcoming sessions, needs-attention, subscription/expiry, quick actions, LearnersOverview (retained); P2 recent activity, sessions-by-status donut, learner assignment split, grading pipeline; P3 staff coverage, academic structure, own support tickets and pending orders cards, period selector, per-skill score and pass rate (deferred, not built).
- Admin: P1 KPI row, tenant growth, tenant status/org-type splits, needs-attention, recent tenants, greeting; P2 revenue, seat utilisation list, applications and tickets lists, licenses/subscriptions cards, content health, role-filtered quick actions; P3 plans card, province map data (Phase 10). Dropped: system notice banner (no data source; hardcoded banner removed), templates, platform health, platform exam volume, AI scoring depth.

## Dependencies
- pte-api: Spring Modulith 2.0.7, Flyway (enabled in production profile; disabled in default tests), Redis already configured.
- Existing roles/policies: `SecurityRoles`, `PlatformOperationPolicy`, `SecurityPolicy`, `CurrentUserContext`.
- pte-web: `@pte/api-client`, `@pte/ui`, recharts 3.8.1 already installed, TanStack Query.
- Real script inventory today: tenant-web has dev/build/start/lint/test; vendor-web has dev/build/start/lint (no test, no vitest); `@pte/ui` has typecheck only; `@pte/api-client` has typecheck + test; neither app has `typecheck` (added in Phase 5).
- Next.js 16 docs under `node_modules/next/dist/docs/` must be read before writing route files.
- A reachable Postgres (local compose) for the Postgres-gated migration test and EXPLAIN evidence.

## Risks
- HIGH: Baseline architecture test is ALREADY RED on a clean tree: (a) `examstaff` is missing from the asserted module list, (b) the boundary-violation test fails on pre-existing cycles (attempt -> session -> enrollment -> attempt, plus one via reporting) and on enrollment dependency violations. Mitigation: Phase 1 records the baseline violation list; adding `examstaff` to the list is in scope (one-line fix); the pre-existing cycles are OUT of scope (pre-existing; user/backend-lead decision). Every later criterion reads "no NEW violations versus the recorded baseline, none involving overview" via a diff of the violation output. New facades must not extend the existing cycle.
- HIGH: Default backend tests use H2 with Flyway disabled, so migrations are never executed and schema validation does not check indexes - mitigation: portable JPQL/derived queries with repository tests, plus a Postgres-gated migration test (exact command in Phase 1) and EXPLAIN evidence for heavy queries.
- HIGH: Modulith dependency cycle (billing already depends on tenancy) - aggregator is a separate leaf `overview` module; facades live on source module roots, and facade DTOs live at the module root or a declared named interface, never in internal packages.
- HIGH: Role leakage through cache or section gating (ACADEMIC_STAFF receiving an operations payload; host data crossing tenants; legacy role aliases) - section-to-operation table (Phase 3), visibility-set cache buckets, tenant-scoped host keys, key-uniqueness and cross-tenant cache-isolation tests are mandatory.
- HIGH: Platform-wide attempt counts (active learners) scan a big table without time-leading indexes - V96 adds started_at/submitted_at indexes; distinct-student query shape fixed in Phase 3; EXPLAIN recorded in handoff.
- MEDIUM: Tenant province/location does not exist and creation flows are broader than assumed (tenants are created via the application approval path) - province moved to optional Phase 10; map shows empty state until then.
- MEDIUM: `seatsUsed` is a placeholder in the existing UI and there is no seat snapshot table - learners come from real student counts, seat utilisation shows current value only.
- MEDIUM: No login timestamps - "active learners" means distinct students with an attempt started in the window; labelled accordingly.
- MEDIUM: Untrendable metrics deferred - shown as current value; never fabricate a percentage.
- MEDIUM: Redis outage - cache helper degrades to direct compute; verified by a test and by a real stop-the-cache check in Phase 9.
- MEDIUM: N+1 on recent tenants and subscriptions->plans - batched/grouped queries; the quota lookup is never called in a loop on the admin side.
- MEDIUM: Month bucketing across UTC vs Vietnam time - fixed zone Asia/Ho_Chi_Minh, partial current month flagged, month-boundary test with fixed clock.
- MEDIUM: Frontend tooling gaps - apps have no `typecheck` script (added in Phase 5); vendor-web needs vitest installed incl. lockfile and the build-script allowance for esbuild; tenant-web vitest only matches `features/**/*.test.ts` (use `.test.ts`, not `.tsx`).
- MEDIUM: Next.js 16 breaking changes (route `error.tsx` retry via `unstable_retry`) - read bundled docs first. Area-wide `loading.tsx` files must not be changed for dashboard-specific skeletons.
- MEDIUM: Single-request claim - the dashboard endpoint is called exactly once per load; LearnersOverview keeps its own roster request (excluded from the count), optionally deferred until in view.
- MEDIUM: Currency mixing in revenue - per-currency amounts only.
- LOW: Redis-down verification must be real (stop the cache container), not only mocked.
- LOW: Frontend session role type still lists the legacy PLATFORM_AUTHOR - the compact academic layout must also cover it.
- LOW: Every displayed enum/status needs both vi and en message keys.
- LOW: `DataTable.tsx` is 711 lines - do not modify.
- LOW: `StatCard` is used in 6 files - change is strictly additive.
- LOW: File/component size (file <= 300, component <= 150) and i18n via sibling message files.

## Open Questions (planner default assumption in brackets)
1. Is "Branch" (shown in the design mockup's upcoming-sessions table) a real concept? [Default: No such concept in tenant-web; omit the column. Confirm with backend/PO before adding.]
2. Are per-skill score / pass rate and 12-month attempt aggregates cheap? [Default: monthly attempt counts per tenant are cheap with the new tenant+time index and are included (P1 single series). Per-skill average score and pass rate are NOT built (P3, later).]
3. Admin "learners": distinct students or seats? [Default: show total distinct students and total seat capacity separately; the trend applies to attempt-based active learners, not seats.]
4. Province data source for the map? [Default: deferred to optional Phase 10; until then the map shows an empty state with no fake locations.]
5. Does question approval store an approval timestamp? [Default: unknown; only current status counts and a created-in-window trend are promised; verify during Phase 4.]
6. Endpoint path naming? [Default: `/api/v1/dashboard/host` and `/api/v1/dashboard/admin`; a rename is isolated to Phase 5 constants and the two controllers.]
7. Period selector on day one? [Default: fixed 30-day window in UI (P3 selector); backend accepts 7/30/90.]
8. Who resolves the pre-existing module cycles and enrollment dependency violations? [Default: out of scope; reported to the backend lead; this task only guarantees no new violations.]

## Deferred / Follow-up (note for later)
- **Phase 10 - Tenant province for the Vietnam map** (deferred by user on 2026-10-12). Today `Tenant` has no province/location, so the vendor-web map (`VietnamTenantMap`) is always empty; Phase 8 ships it with an honest empty-state. To finish it later, see `phase-10-tenant-province-for-map.md`: migration V98 (tenants + applications province columns), public register form in tenant-web (`RegisterOrganizationView`), `TenantApplicationService` approval -> `TenancyService.createTenant`, tenant response DTO, vendor create/approve UI, province code list mirrored from vendor-web `TENANT_LOCATION_OPTIONS` with server-side closed-code validation, then the admin `map` aggregate section. Needs Phases 3 and 8 done first.
- Pre-existing architecture violations (cycle attempt -> session -> enrollment -> attempt, enrollment allowedDependencies) - reported, not fixed here.
- Per-skill average score / pass rate widgets for the host dashboard, period selector (7/30/90) in the UI, templates and platform-health admin sections - deferred until a consumer widget and data source exist.
