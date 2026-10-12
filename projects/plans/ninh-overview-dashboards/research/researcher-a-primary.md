## Research Report: Overview Dashboards - Dedicated Aggregate Endpoints in pte-api

**Role**: Primary (Instance A)
**Calls used**: ~30 read-only tool calls (exceeds the 5-call guideline in researcher.md because the brief asked for a full multi-module audit; no code edited)
**Date**: 2026-10-12

---

## 0. Executive summary

- pte-api is ONE Spring Boot app (`D:\FPT-FALL2026\Capstore\pte-api\app`), Spring Modulith 2.0.7 (`ModuleStructureTest.modules_have_no_boundary_violations` fails the build on internal access), Flyway **enabled** with `ddl-auto: validate` (V1..V93, next free = **V94**; the older plan `phat-remove-flyway-hibernate-only` is superseded - do not rely on `update`).
- No Spring Cache / Caffeine exists. Redis (`spring-boot-starter-data-redis`, Lettuce) is wired and used by hand in `attempt/internal/service/cache/PinnedSnapshotCacheService` (StringRedisTemplate + JsonMapper + SET NX single-flight) and `RateLimitConfig`.
- Tenant scoping = explicit `tenantId` param taken from the JWT (`CurrentUserContext.required().tenantId()`), NOT a Hibernate filter / TenantContext (grep for `TenantContext|@FilterDef|@Filter(` returned nothing). Other modules store tenant as a bare `UUID tenantId` column (no FK); only `Organization -> Tenant` is a JPA relation.
- Recommended shape: a NEW leaf Modulith module `com.pte.overview` (controllers + 2 composer services) that calls small **public per-module "summary" facades** (new classes at each module root, same pattern as `TenancyService`, `StaffScoringService`, `StaffScheduleService`). One endpoint per dashboard, each widget (section) computed independently with try/catch -> per-section `status` so a failing widget does not blank the page.
- Two genuine data gaps: (1) **Tenant has no province/location** (the vendor map's `Tenant.location` is hard-coded `null` in `apps/vendor-web/features/tenancy/api/index.ts` -> `tenantResponseToTenant`); the map needs a V94 migration + entity + onboarding field. (2) **No status history / no seat-usage snapshots** -> several "trend" numbers cannot be honest (see section 4).
- Estimated 4 backend phases (see section 8).

---

## 1. Tenant HOST dashboard - what data exists

Access: `@PreAuthorize("hasRole('HOST_ADMIN')")` is the convention for every host surface (`StudentQuotaController`, `ProgramController`, `SessionController`, `OrderController`, `SubscriptionController`, `HostSupportTicketController`, `AuditLogController`, `HostScoreReviewController`, `StaffWorkspaceController`). Other tenant roles (PROCTOR, EXAMINER, STUDENT) have their own workspaces (`/proctor`, `/examiner`, `/student` in tenant-web) -> host dashboard = **HOST_ADMIN only**. Tenant id comes from `CurrentUserContext.required().tenantId()`; `CurrentUser.isPlatformUser()` = tenantId null (must be rejected - `SecurityPolicy.hasValidScope`).

| Widget | Source (module -> repo/service) | Notes / how to compute |
|---|---|---|
| Learners total + new in period | identity: `IdentityService.countStudents(tenantId)` -> `UserRepository.countByTenantIdAndRole` (JPQL, distinct join on roles, `deleted=false`) | `User` extends `BaseEntity` -> has `createdAt`; need NEW `countByTenantIdAndRoleAndCreatedAtBetween`. `idx_users_tenant` is enough per tenant. |
| Learner status split (active/suspended) | `User.status` (`UserStatus`) | add grouped count in same facade. |
| Seat/quota usage | tenancy: `TenancyService.getStudentQuota(tenantId)` -> `StudentQuota(current, limit)` (`remaining()`, `canAdd`) | exactly what `GET /api/v1/tenant/quota` returns; reuse the method (do not call controller). Quota grants history: `QuotaTransactionService.history` (`QuotaTransaction.createdAt`). |
| Exam-staff counts | identity: `UserRepository.countByTenantIdAndRole(tenantId, PROCTOR/EXAMINER)` | `StaffWorkspaceController GET /exam-staff/{id}/overview` is PER-STAFF, not a tenant total - not reusable. Need a facade `IdentityService.countByRole`. |
| Programs / classes / organizations counts | enrollment: `ProgramRepository.findByOrganization_Tenant_PublicIdAndDeletedFalse(tenantPublicId)` (comment says "added for Phase 13 dashboard"); `StudentClassRepository` (class -> program -> organization -> tenant, **no tenant_id column**); `ClassMembership` | Existing `ProgramService.getDashboard` returns per-program counts only. Add `COUNT` JPQL with joins: `select count(c) from StudentClass c where c.program.organization.tenant.publicId=:t and c.deleted=false and c.status=ACTIVE`. Unassigned learners = students minus distinct active memberships. Public facade: `EnrollmentModuleService` (already exists at module root). |
| Exam sessions by status (upcoming / open / completed) | session: `ExamSession` (`tenantId`, `status` = DRAFT/PREPARING/READY/SCHEDULED/OPEN/CLOSED/CANCELLED, `opensAt`, `closesAt`, `capacity`) + `ExamSessionRepository`; indexes `idx_sessions_tenant`, `idx_staff_session_schedule (tenant_id, opens_at DESC, public_id)` (V93) | Add `count ... group by status` and `findTop5 ... where status in (SCHEDULED, OPEN) and closesAt > :now order by opensAt asc` (next sessions list). Facade: `SessionService` (root) or a new `SessionOverviewService`. Enrollment fill rate: `Enrollment` rows per session (`idx_enrollments_session`) vs `capacity`. |
| Attempts volume + completion | attempt: `ExamAttempt` (`tenantId`, `status` CREATED/IN_PROGRESS/SUBMITTED, `startedAt`, `submittedAt`), only index `idx_attempts_tenant` | needs NEW composite index `(tenant_id, submitted_at)` for period counts (V94). Facade: `AttemptService` (root) - add `countSubmitted(tenantId, from, to)`, `countInProgress(tenantId)`. |
| Awaiting grading / scoring failures | scoring: `ScoringAnswer` (`tenantId`, `status` PENDING/AI_SCORING/SCORING_FAILED/SCORED, `scoredAt`); index `idx_scoring_answers_tenant_review (tenant_id, session_public_id, status, created_at)`; `GradingCohort` (FROZEN/COMPLETED) | `count where tenantId=:t group by status` is index-supported (leading col tenant_id). Closed sessions not yet cohort-finalized: join `ExamSession(CLOSED)` with `session_grading_cohorts`. Facade: `ScoringService` (root) or new `ScoringOverviewService`. NOTE: ScoringAnswer rows exist per answer (large) - always `COUNT ... GROUP BY`, never load entities. |
| Reports awaiting publication | reporting: `AttemptReport(published, publishedAt, tenantId)`; index only on `(student_public_id, tenant_id, published, published_at)` | count unpublished by tenant would not use that index -> consider `(tenant_id, published)` index or compute per CLOSED session (small set). |
| Subscription / plan state, expiry, renewal | billing: `SubscriptionRepository` (`idx_subscriptions_tenant_status`), `BillingService.listActiveSubscriptions(tenantId)` -> `SubscriptionView(startsAt, expiresAt, status, maxStudentsPerSession, activationSource)` + `isUsableAt(now)` | days-to-expiry = `expiresAt - now`; "expiring soon" = ACTIVE with `expiresAt <= now+30d`. Plan name via `PlanRepository` (internal to billing -> do inside a billing facade, batch by planId, not N+1). Existing `LicenseCodeExpirationService`/`OrderExpirationService` already flip statuses on schedule, so status is trustworthy. |
| Unpaid orders | billing: `OrderRepository` (`idx_orders_tenant_created`), status PENDING/PAID/CANCELLED/EXPIRED; `ux_orders_pending_tenant_plan` | add `countByTenantIdAndStatusAndDeletedFalse` + latest pending (with `paymentLinkUrl`). |
| Support tickets (own) | support: `SupportTicketRepository`; index `idx_support_ticket_tenant_status_created (tenant_id, status, created_at)`; `TicketStatus` OPEN/IN_PROGRESS/RESOLVED/CLOSED | **support has NO root-level public service** (only `dto`, `package-info`) - must add `SupportOverviewService`/`SupportSummaryService` at `com.pte.support`. Count open = OPEN+IN_PROGRESS (+RESOLVED awaiting close). |
| Recent activity | shared: `AuditLogService.list(caller, aggregateType, page, size)` (tenant-scoped via `caller.tenantId()`, `idx` on tenant/created) -> `AuditLogResponse(publicId, actorUserId, aggregateType, aggregateId, action, summary, createdAt)` | reuse directly with page 0, size 8 (`shared` is an OPEN module). |
| Notifications unread | notification: `InboxController GET /notification-inbox/unread-count` (roles PLATFORM_ADMIN + HOST_ADMIN only) | cheap; optional. Header bell probably already shows it -> skip from aggregate (YAGNI) unless FE wants one call. |

Existing endpoints worth knowing (do NOT replace; just not sufficient): `GET /api/v1/tenant/quota`, `GET /api/v1/organizations/{org}/programs/{id}/dashboard` (per program), `GET /api/v1/exam-staff/{staffId}/overview` (per staff), `GET /api/v1/questions/stats` (platform question bank; academic/admin roles), `GET /api/v1/sessions` (list), `GET /api/v1/audit-logs`, `GET /api/v1/support-tickets`, `GET /api/v1/subscriptions`, `GET /api/v1/orders`.

Cannot compute for host today: learner login/last-active time (no `lastLogin*` field anywhere in `User`); "active learners" must be defined as *distinct students with an attempt `startedAt` in the last 30 days* (attempt-based), not login-based. Average score / pass rate: `ScoringAnswer.rawScore` is per answer; overall scores live in the report snapshot JSON (`AttemptReport.reportSnapshotJson`) -> parsing JSON in SQL is fragile; recommend deferring "average overall score" or reading only for last N published reports via `ReportingService` (new facade) - flag as phase-2/optional.

---

## 2. Platform ADMIN (vendor) dashboard - what data exists

Existing UI (`apps/vendor-web/features/dashboard/components/OverviewView.tsx`) builds everything client-side from `useTenants()` (GET `/api/v1/tenants`, unpaged `List<TenantResponse>`), with hard-coded `+12.5%` / `+8.2%`, `seatsUsed: 0`, `status` only `active|suspended` (never `expiring`), `location: null` (map always empty), `expiresAt: "-"`. So "Active learners" and "Expiring soon" are currently **always 0**.

Access: `/admin` UI is open to `PLATFORM_ADMIN, PLATFORM_MANAGER, ACADEMIC_MANAGER, ACADEMIC_STAFF` (`apps/vendor-web/features/auth/constants.ts` `ADMIN_ROLES`). Backend role matrix (`shared/security/SecurityRoles`, `PlatformOperationPolicy`, `SecurityPolicy`; plan `pte-doc/plans/platform-role-expansion/plan.md`):
- PLATFORM_ADMIN: everything. PLATFORM_MANAGER: ops set = APPLICATION_READ, TENANT_READ, PLAN_READ_ALL, LICENSE_MASKED_READ, COMMERCIAL_READ, SUPPORT_READ, ANNOUNCEMENT_READ ... (no settings/roles/revoke/reveal).
- ACADEMIC_MANAGER / ACADEMIC_STAFF: itembank / score templates only.
=> The aggregate must be **role-aware per section**: endpoint authorised for those four platform roles (`hasAnyRole('PLATFORM_ADMIN','PLATFORM_MANAGER','ACADEMIC_MANAGER','ACADEMIC_STAFF')`), then each section gated with `PlatformOperationPolicy.can(caller, TENANT_READ/APPLICATION_READ/COMMERCIAL_READ/LICENSE_MASKED_READ/SUPPORT_READ)` for ops sections and `SecurityPolicy.hasCapability(...)` / role check for the question-bank section. A gated-out section is returned as `{ "status": "FORBIDDEN" }` (not omitted-silently, so FE can hide cleanly) - never a whole-request 403 for an academic user.

| Widget | Source | Notes |
|---|---|---|
| Tenants total/active/suspended, new in period | tenancy: `TenantRepository` (JpaRepository<Tenant>), `Tenant.status` (`ACTIVE`/`SUSPENDED` only), `createdAt` via BaseEntity, `organizationType`, `packageName`, `studentLimit`, `deleted` | add `count group by status`, `countByCreatedAtBetween`. `TenantController.list` is unpaged; the aggregate should return only top-N + counts. |
| Tenants by province (map) | **NOT AVAILABLE** | `Tenant`/`Organization` have no province field (`Organization.address` is free text; `TenantResponse` has no location). Requires V94 `ALTER TABLE tenants ADD COLUMN province varchar(64)` (+ entity field, `OnboardTenantRequest`, `TenantResponse`, vendor create-tenant form). FE already has `TENANT_LOCATION_OPTIONS` constants (`features/tenancy/constants`) - align codes with that list. Map section returns `[{provinceCode, tenantCount}]` + `unmappedCount`. |
| Recent tenants | `TenantRepository` top 5 by `createdAt desc` (new derived query `findTop5ByDeletedFalseOrderByCreatedAtDesc`) | return projection (publicId, code, name, orgType, status, planName, studentLimit, studentCount, province, createdAt) - batch student counts, see N+1 below. |
| Seats / active learners platform-wide | identity: students count by tenant (`countByTenantIdAndRole` per tenant is N queries) | need ONE grouped query `select u.tenantId, count(distinct u.id) from User u join u.roles r where r=STUDENT and u.deleted=false group by u.tenantId` (new in a facade, e.g. `IdentityService.countStudentsByTenant()`); seatsTotal = sum `studentLimit`. "Active learners" = distinct students with attempt `startedAt` in last 30d (attempt facade, grouped, needs started_at index). |
| Licenses | billing: `LicenseCode` (`status` ISSUED/REDEEMED/REVOKED/EXPIRED, `issuedAt`, `redeemedAt`, `codeExpiresAt`, `redeemedByTenantId`), index `idx_license_codes_status_expiry (status, code_expires_at)`. NB ISSUED past `codeExpiresAt` is derived EXPIRED (see `LicenseCodeRepository.findAdminPage` + `LicenseCodeStateResolver`) | counts: issued-valid, redeemed, revoked, expired-derived, expiring in 7d. Reuse the same derived-state predicate; do NOT trust raw `status` for ISSUED. Platform ops roles only (MANAGER gets masked read; counts expose no secrets). |
| Subscriptions / expiring soon | billing: `Subscription` (`status` ACTIVE/EXPIRED/CANCELLED, `startsAt`, `expiresAt`, `activationSource`), `SubscriptionRepository.findByDeletedFalseAndStatusAndExpiresAtLessThanEqual` (existing, used by expiry job) | "expiring soon" = ACTIVE & `expiresAt` in [now, now+30d]; needs index `(status, expires_at)` (only `(tenant_id,status)` exists). Per-tenant expiry for the "expiring" badge can be returned in the recent/expiring-tenants list. |
| Pending tenant applications | billing: `TenantApplication` (`status` PENDING/APPROVED/REJECTED, `createdAt`, `reviewedAt`, `orgName`, `orgType`, `requestedCode`), `TenantApplicationRepository.findAllByOrderByCreatedAtDesc` (unfiltered, no count query) | add `countByStatus`, `findTop5ByStatusOrderByCreatedAtAsc(PENDING)` (oldest first = SLA view). Role: `PlatformOperation.APPLICATION_READ`. Table is small, no index needed. |
| Support tickets open | support: `SupportTicket` (`tenantId`, `status`, `category`, `createdAt`), only tenant-leading index | platform-wide `count group by status`, plus top-5 oldest OPEN; small table - add `(status, created_at)` index if desired. Needs new public facade in `com.pte.support`. `SupportTicketService.listAllForAdmin` exists but is internal and paged by filters. `PlatformOperation.SUPPORT_READ`. |
| Question bank stats | itembank: `ItembankService.stats(caller)` already public -> `QuestionStatsResponse(total, listening, reading, writing, speaking, draft)` (counts only `Visibility.SHARED`, but includes PRACTICE pool - see `QuestionPool`) | Extend (new method, keep old for `/questions/stats` compat) with `pendingApproval`, `approved`, `archived`, by pool EXAM/PRACTICE, created-in-period. `QuestionStatus` = DRAFT/PENDING_APPROVAL/APPROVED/ARCHIVED. Roles: all four platform roles (matches `QuestionController` class-level `@PreAuthorize`). "Pending approval" is the actionable KPI for ACADEMIC_MANAGER. |
| Exam templates | scoretemplate: `ScoreTemplateService` (root), `ScoreTemplateStatus`; assessment: `ExamBlueprint`/`BlueprintStatus`, `ExamSnapshot` | add `count group by status` facades; low priority widget. |
| Plans | billing: `Plan` (`PlanStatus` DRAFT/ACTIVE/ARCHIVED, `PlanType` EXAM_PACKAGE/STUDENT_CAPACITY, `price`, `currency`) | counts by status/type; plus subscriptions-per-plan top N (group by planId). |
| Revenue | billing: `Order` (`amount`, `currency`, `status`, `paidAt`) index `idx_orders_status_created (status, created_at)` | `sum(amount) where status=PAID and paidAt in period group by currency` (currency can differ -> return per-currency list, never sum across). Orders only cover PayOS purchases; license-code activations (`ActivationSource`) carry no payment -> label as "online revenue" and show activation-source split separately. Role: `COMMERCIAL_READ`. |
| Attempts volume platform-wide | attempt: `ExamAttempt` (`startedAt`, `submittedAt`) | `count where submittedAt in period` (no tenant filter) needs index on `submitted_at`/`started_at`. |
| Scoring health | scoring: `ScoringAnswer` status counts platform-wide (SCORING_FAILED = dead-lettered) | `count group by status` over full table - fine with `idx_scoring_answers_status`, but cache it. Good "system health" widget replacing the dummy `SystemHealth` type in `features/tenancy/types`. |

---

## 3. Module boundary design (must respect Modulith)

Verified facts:
- Each module: public API at the package root (`TenancyService`, `BillingService`, `SessionService`, `AttemptService`, `ScoringService`, `ItembankService`, `EnrollmentModuleService`, `ReportingService`...), entities in `domain` (tenancy exposes `@NamedInterface("domain")`), everything else in `internal`. Public records are plain `record` "views" (e.g. `SubscriptionView`, `TenantSummary`, `StudentQuota`).
- `ModuleStructureTest.all_sixteen_business_modules_plus_shared_are_detected` asserts the **exact** module set (`containsExactlyInAnyOrder("identity","tenancy","enrollment","itembank","assessment","session","attempt","scoring","proctoring","reporting","media","notification","scoretemplate","billing","support","practice","shared")`). Adding a module `overview` **requires updating this test list** (note: `examstaff` is not in it - it lacks a detection issue today only because the list is stale/lenient? it has a package-info; verify before editing: run the test first).
- `support` declares `allowedDependencies = {"shared","identity","tenancy","tenancy::domain","itembank","session","attempt"}`; `enrollment` declares `{"shared","identity","tenancy","tenancy::domain"}` - adding a new facade inside these modules is fine (inbound deps are not restricted) but do not make them depend on `billing`/`scoring`.
- Cycle risk: `billing -> tenancy` already exists (TenancyService.createTenant called from billing). Therefore the aggregator MUST NOT live inside `tenancy` (would force tenancy -> billing). A leaf `overview` module avoids all cycles.

Recommended layout (follows `<module>/internal/{controller,service,dto}` convention):
```
com.pte.overview/
  package-info.java            @ApplicationModule(displayName="Overview",
                               allowedDependencies={"shared","tenancy","tenancy::domain","identity","enrollment",
                               "session","attempt","scoring","billing","support","itembank","scoretemplate","reporting"})
  internal/controller/HostDashboardController.java      GET /api/v1/dashboard/host
  internal/controller/AdminDashboardController.java     GET /api/v1/dashboard/admin
  internal/service/HostDashboardService.java            composes sections, per-section try/catch
  internal/service/AdminDashboardService.java
  internal/service/DashboardSectionRunner.java          helper: run(Supplier<T>) -> Section<T>(status,data)
  internal/dto/response/*.java                          records
```
Per-module facades to add (each a thin `@Service` at module root with `@Transactional(readOnly = true)`, returning records; each delegating to internal repos with new `COUNT`/`GROUP BY` JPQL):
- `IdentityService` (+`countStudents(tenantId, from, to)`, `countByRole(tenantId, role)`, `countStudentsByTenant()`, `countStudentsByStatus(tenantId)`)
- `TenancyService` (+`TenantOverview platformOverview(from,to)`, `topRecent(n)`, `countByProvince()`)
- `EnrollmentModuleService` (+`TenantAcademicCounts countForTenant(tenantId)`)
- `SessionService` or new `SessionOverviewService` (+`SessionCounts`, `upcoming(tenantId, n)`)
- `AttemptService` (+`AttemptVolume`, `activeStudentCount(tenantId|null, since)`)
- `ScoringService` (+`ScoringBacklog backlog(tenantId|null)`)
- `BillingService` (+`HostBillingOverview forTenant(tenantId)`, `PlatformBillingOverview platform(from,to)` incl. licenses, subs expiring, pending applications, revenue by currency, plans)
- `com.pte.support.SupportOverviewService` (new root class)
- `ItembankService` (+`overview()` extending `stats`)
- `AuditLogService.list` reused as is.

Alternative inside-module approach (not recommended): put `GET /tenant/overview` into tenancy and `GET /platform/overview` into billing - mutually conflicting deps and splits the "one endpoint" ownership. Keep the overview module.

---

## 4. Trends - what can be computed truthfully

Strategy: **period-over-period on rolling windows** from the injected `Clock` (`shared/config/ClockConfig` exists): `current = [now-30d, now)`, `previous = [now-60d, now-30d)`; `windowDays` query param (7|30|90, default 30). Rolling windows sidestep the Vietnam-vs-UTC calendar boundary problem (V* migration `phat-postgres-utc-timestamptz-migration` stores UTC). Backend returns `{ current, previous, changePct|null }`; `changePct = null` when `previous == 0` (FE shows "New" / "-" instead of a fake "+inf%"). Never return a percentage the backend did not compute.

| Metric | Honest trend? | Basis |
|---|---|---|
| New learners | YES | `users.created_at` + STUDENT role (soft-delete leaves row; `deleted=false` filter means deleted-then-created-in-period are excluded - acceptable, document it). |
| Total learners (cumulative delta) | PARTIAL | approximated as `current total - (current total - newInWindow + deletedInWindow)`; no `deleted_at`, so deletions are unknown -> present as "new this period", not "net change". |
| New tenants | YES | `tenants.created_at`. |
| Active/suspended tenant counts over time | NO | no status history (only `updatedAt`, overwritten). Show current split, no trend. |
| Seat utilisation over time | NO | no snapshots; `QuotaTransaction` gives grants only. Show current %, no trend. (Optional later: nightly snapshot table.) |
| Exam sessions created / completed | YES | `exam_sessions.created_at`; completed approximated by `closes_at` in window with status CLOSED. |
| Attempts started/submitted | YES | `started_at` / `submitted_at` (needs indexes). |
| Active learners (attempt-based) | YES | distinct `student_public_id` with `started_at` in window. |
| Scoring backlog | NO (point-in-time) | current status counts; `scored_at` allows "scored in period" throughput. |
| Revenue (online) | YES | `orders.paid_at` + `amount` grouped by currency. |
| Subscriptions activated | YES | `subscriptions.created_at` (+ `activationSource`). |
| License codes issued / redeemed | YES | `issued_at` / `redeemed_at`. |
| Applications received | YES | `tenant_applications.created_at`; approval/rejection via `reviewed_at`. |
| Support tickets opened | YES | `support_ticket.created_at`. |
| Support tickets resolved / mean time to resolve | NO | no `resolvedAt`; `SupportTicketNote`/status transitions not timestamped as such -> skip. |
| Questions created / approved | PARTIAL | `Question.createdAt` yes; approval time not stored (provenance fields in V77 `question_publication_provenance` may have published time - verify before promising). |
| Avg exam score trend | DEFER | stored only in report snapshot JSON. |

---

## 5. Existing backend conventions to follow

- **Envelope**: every endpoint returns `ApiResponse<T>` (`success`, `data`, `message`, optional `code`/`userMessage`) from `com.pte.shared.web`. Paging uses `PagedResult<T>(data, PageMeta)` nested in `data`. FE `client.request<T>` auto-unwraps (`unwrapResponse` in `packages/api-client/src/client/client.ts`). Dashboards are not paged.
- **Controller**: `@RestController`, `@RequestMapping("/api/v1/...")`, class-level `@PreAuthorize`, private `currentUser()` helper -> `CurrentUserContext.required()`, no business logic. `RouteContractTest` scans all `@RestController`s and enforces the `/api/v1` public prefix -> the new controllers must start with `/api/v1`.
- **DTOs are Java records** under `internal/dto/{request,response}`; cross-module "views" are public records at module root/`dto`. No `@Data` on entities (`BaseEntity` uses `@Getter/@Setter`).
- **Errors**: `DomainException` hierarchy + `GlobalExceptionHandler`; `AccessDeniedException(SharedConstants.ACCESS_DENIED)` for policy failures.
- **Transactions**: `@Transactional(readOnly = true)` on read services. Sections of one dashboard should each run in their own read-only transaction (separate facade calls) so one failing query does not mark a shared tx rollback-only.
- **Constants**: `internal/constant/<Module>Constants.java` for magic numbers (window defaults, top-N sizes, TTLs).
- **Tests**: JUnit 5 + Mockito service tests under `src/test/java/com/pte/<module>/internal/service/*Test.java` (e.g. `ProgramServiceTest`, `ClassServiceTenantIsolationTest`, `SupportTicketServiceTest`), `@DataJpaTest` (+H2) for repositories (`spring-boot-starter-data-jpa-test`, `h2`), migration tests (`SupportFeedbackInboxMigrationTest`), architecture tests (`ModuleStructureTest`, `RouteContractTest`). Add: tenant-isolation test (host A cannot see host B counts), role matrix test (ACADEMIC_STAFF gets only itembank section; MANAGER gets no settings/PLATFORM_ADMIN-only data), trend math test with fixed `Clock`, per-section failure test.
- **Migrations**: Flyway `src/main/resources/db/migration/V94__...sql` (idempotent `CREATE INDEX IF NOT EXISTS`, as V93). `ddl-auto: validate` -> any `@Index`/column added to an entity must match the SQL. Add matching `@Index` annotations on entities as existing code does.
- **Caching**: nothing declarative. Options: (a) no cache for host dashboard (all queries are tenant-leading index counts) + short HTTP `Cache-Control: private, max-age=30`; (b) Redis single-flight like `PinnedSnapshotCacheService` for the admin dashboard (platform-wide aggregates over big tables); (c) add `spring-boot-starter-cache` + Caffeine (new dependency in `app/pom.xml`) with `@Cacheable("adminDashboard")`. Recommendation: **Redis via a small `DashboardCache` helper** reusing the existing `StringRedisTemplate` + `JsonMapper` (Jackson 3 `tools.jackson` per `phat-jackson3-objectmapper-migration`) - zero new dependency, shared across instances. Key `dash:admin:v1:{roleBucket}:{windowDays}`, TTL 60s (admin, role-bucketed because section visibility differs: OPS vs ACADEMIC); host key `dash:host:v1:{tenantId}:{windowDays}` TTL 30s. Cache failure must degrade to direct compute (catch `RedisConnectionFailureException`). Do not cache per-user data (audit actor names) beyond TTL.

---

## 6. Proposed API contract

### 6.1 Endpoints

| | Host | Admin |
|---|---|---|
| Path | `GET /api/v1/dashboard/host?windowDays=30` | `GET /api/v1/dashboard/admin?windowDays=30` |
| Auth | `@PreAuthorize("hasRole('HOST_ADMIN')")`; tenantId from JWT only (no tenant param -> no IDOR) | `@PreAuthorize("hasAnyRole('PLATFORM_ADMIN','PLATFORM_MANAGER','ACADEMIC_MANAGER','ACADEMIC_STAFF')")` + per-section policy |
| Caching | 30s Redis + `Cache-Control: private, max-age=15` | 60s Redis keyed by role bucket |
| Validation | `windowDays` in {7,30,90} else 400 | same |

(Path alternatives considered: `/api/v1/tenant/overview` + `/api/v1/platform/overview` matches existing `/tenant/quota` and `/platform/commercial` naming. Either passes `RouteContractTest`; `/dashboard/{host|admin}` chosen because it mirrors the FE routes `host/dashboard` and `admin`; planner may swap. Whatever is chosen, add it to `endpoints.test.ts`-covered `*_ENDPOINTS`.)

### 6.2 Response shape (TypeScript, for `packages/api-client/src/types/dashboard/index.ts`)

```ts
export type SectionStatus = "OK" | "ERROR" | "FORBIDDEN";
export interface DashboardSection<T> { status: SectionStatus; data: T | null; }   // ERROR carries no raw message (coding standard: no machine errors in UI)

export interface TrendValue { current: number; previous: number; changePct: number | null; } // null when previous == 0
export interface MoneyAmount { currency: string; amount: number; }

export interface DashboardMeta { generatedAt: string; windowDays: number; windowStart: string; windowEnd: string; }

// ---------- HOST ----------
export interface HostDashboardResponse {
  meta: DashboardMeta;
  learners:   DashboardSection<{ total: number; active: number; suspended: number; newInWindow: TrendValue;
                                  activeLearners: TrendValue; unassigned: number }>;
  quota:      DashboardSection<{ used: number; limit: number; remaining: number }>;
  academics:  DashboardSection<{ organizations: number; programs: number; activeClasses: number }>;
  staff:      DashboardSection<{ proctors: number; examiners: number }>;
  exams:      DashboardSection<{ byStatus: Record<SessionStatus, number>; created: TrendValue;
                                  upcoming: UpcomingSession[] }>;
  attempts:   DashboardSection<{ submitted: TrendValue; inProgressNow: number }>;
  grading:    DashboardSection<{ pendingAnswers: number; aiScoring: number; failedAnswers: number;
                                  closedSessionsAwaitingCohort: number; reportsAwaitingPublish: number }>;
  subscription: DashboardSection<{ current: SubscriptionSummary[]; nearestExpiryAt: string | null;
                                    daysToExpiry: number | null; expiringSoon: boolean }>;
  billing:    DashboardSection<{ pendingOrders: number; latestPendingOrder: { publicId: string; amount: number; currency: string; paymentLinkUrl: string | null } | null }>;
  support:    DashboardSection<{ open: number; inProgress: number; resolvedAwaitingClose: number }>;
  recentActivity: DashboardSection<AuditLogResponse[]>; // reuse existing type
}
export interface UpcomingSession { publicId: string; name: string; status: SessionStatus; opensAt: string; closesAt: string; enrolled: number; capacity: number | null; }
export interface SubscriptionSummary { publicId: string; planName: string; planType: "EXAM_PACKAGE" | "STUDENT_CAPACITY"; startsAt: string; expiresAt: string; status: string; }

// ---------- ADMIN ----------
export interface AdminDashboardResponse {
  meta: DashboardMeta;
  tenants:   DashboardSection<{ total: number; active: number; suspended: number; newInWindow: TrendValue;
                                 byOrgType: Record<string, number> }>;
  learners:  DashboardSection<{ totalStudents: number; totalSeats: number; activeLearners: TrendValue }>;
  map:       DashboardSection<{ provinces: { code: string; tenantCount: number }[]; unmapped: number }>;
  recentTenants: DashboardSection<RecentTenant[]>;
  applications:  DashboardSection<{ pending: number; receivedInWindow: TrendValue; oldestPending: PendingApplication[] }>;
  licenses:  DashboardSection<{ issuedValid: number; redeemed: number; revoked: number; expired: number;
                                 expiringIn7d: number; redeemedInWindow: TrendValue }>;
  subscriptions: DashboardSection<{ active: number; expiringIn30d: number; activatedInWindow: TrendValue;
                                     bySource: Record<string, number> }>;
  plans:     DashboardSection<{ active: number; draft: number; archived: number }>;
  revenue:   DashboardSection<{ perCurrency: { currency: string; current: number; previous: number; changePct: number | null }[]; paidOrders: TrendValue }>;
  support:   DashboardSection<{ open: number; inProgress: number; openedInWindow: TrendValue; oldestOpen: TicketBrief[] }>;
  questionBank: DashboardSection<{ total: number; draft: number; pendingApproval: number; approved: number; archived: number;
                                    bySection: Record<"LISTENING"|"READING"|"WRITING"|"SPEAKING", number>;
                                    byPool: Record<"EXAM"|"PRACTICE", number>; createdInWindow: TrendValue }>;
  templates: DashboardSection<{ scoreTemplates: Record<string, number>; blueprints: Record<string, number> }>;
  platformHealth: DashboardSection<{ scoringFailed: number; scoringPending: number; attemptsInProgress: number; attemptsSubmitted: TrendValue }>;
}
export interface RecentTenant { publicId: string; code: string; name: string; organizationType: string; status: "ACTIVE" | "SUSPENDED";
                                 planName: string | null; studentCount: number; studentLimit: number; province: string | null; createdAt: string; subscriptionExpiresAt: string | null; }
```
Section visibility by role: HOST gets all. ADMIN: PLATFORM_ADMIN all; PLATFORM_MANAGER all except none sensitive (revenue = COMMERCIAL_READ ok, licenses = counts only); ACADEMIC_MANAGER/STAFF -> only `questionBank` + `templates` (others `FORBIDDEN`, with `data: null`).

### 6.3 Frontend integration (api-client conventions)
- Add `packages/api-client/src/types/dashboard/index.ts` (+ export in `types/index.ts`) and `packages/api-client/src/requests/dashboard/index.ts` exporting `DASHBOARD_ENDPOINTS = { host: "/api/v1/dashboard/host", admin: "/api/v1/dashboard/admin" } as const` and `getHostDashboard(client, windowDays)` / `getAdminDashboard(client, windowDays)` (pattern: `requests/quota/index.ts`, `requests/admin/programs.ts`); re-export from `requests/index.ts`. Query string appended in the request function (client has no params helper in the examples seen - build with `new URLSearchParams`).
- `endpoints.test.ts` auto-discovers any `*_ENDPOINTS` const and asserts `/api/v1/` prefix + no retired segment; `/api/v1/dashboard/...` passes without edits (segment `dashboard` is not in `RETIRED_SERVICE_SEGMENTS`). Add a dedicated test for the request functions only if the team does elsewhere (admin `studentRoster.test.ts` exists as precedent).
- Feature wiring per CLAUDE.md: tenant-web `features/dashboard/{api.ts,constants.ts,types.ts,components/}`, vendor-web `features/dashboard/api.ts` (currently missing - it has only `constants.ts`, `types.ts`, components; `OverviewView` pulls from `features/tenancy/api` `useTenants`). TanStack `useQuery({ queryKey: ["dashboard","host",windowDays], staleTime: 30_000, refetchOnWindowFocus: true })`. Each widget component renders from its `DashboardSection` (skeleton on loading, "unavailable" card on ERROR, hidden on FORBIDDEN). Keep `LearnersOverview` (`apps/tenant-web/features/examoperations/components/LearnersOverview.tsx`) as a section below the widgets.
- Remove fake trends: `AdminStats.totalTenantsTrend` / `activeLearnersTrend` strings in `apps/vendor-web/features/dashboard/types.ts` and `OverviewView.tsx` are replaced by `TrendValue`.

---

## 7. Performance and risk

- **N+1 traps**: (a) recent tenants -> plan name, student count, subscription expiry per tenant: must be 3 batched queries (`findByPublicIdIn`-style, grouped counts, `IN (tenantIds)` subscription query) - note `TenancyService.findTenantSummaries` already shows the batch idiom. (b) subscriptions -> plan names: batch by planId. (c) class/program counts: single join count, not iterate programs (existing per-program dashboard would be N queries).
- **Count cost**: all host queries lead with `tenant_id` and hit `idx_users_tenant`, `idx_sessions_tenant`, `idx_attempts_tenant`, `idx_scoring_answers_tenant_review`, `idx_subscriptions_tenant_status`, `idx_orders_tenant_created`, `idx_support_ticket_tenant_status_created`. Period counts on attempts need `(tenant_id, submitted_at)` / `(tenant_id, started_at)`.
- **Admin platform-wide scans** (no tenant prefix): users STUDENT count (join `user_roles`; add nothing, cache it), attempts by `started_at`/`submitted_at` -> V94 indexes `exam_attempts(started_at)`, `exam_attempts(submitted_at)`; `subscriptions(status, expires_at)`; `scoring_answers` has `idx_scoring_answers_status`; `orders` has `(status, created_at)` but revenue uses `paid_at` -> index `orders(paid_at) WHERE status='PAID'` (partial) or filter by `(status, created_at)` and accept; `tenants(created_at)`, `tenant_applications(status, created_at)`, `support_ticket(status, created_at)` small tables (index optional). Suggested V94 content: the above `CREATE INDEX IF NOT EXISTS` + `ALTER TABLE tenants ADD COLUMN IF NOT EXISTS province varchar(64)`.
- **Partial failure**: `DashboardSectionRunner.run(name, supplier)` catches `RuntimeException`, logs with correlation id (`CorrelationIdFilter` exists) and returns `{status:"ERROR", data:null}`; HTTP stays 200. Whole-request failures only for auth (401/403) and bad `windowDays` (400). Run sections sequentially first (simple, predictable pool usage; Hikari max pool 10 per `application.yml`); parallelise with a small bounded executor only if p95 > ~300ms measured. Per-query timeout hint `jakarta.persistence.query.timeout`/`@QueryHints` ~2s on the heavy platform-wide counts.
- **Cache poisoning/leak**: admin cache key includes role bucket (OPS vs ACADEMIC) - an ACADEMIC_STAFF must never receive a cached OPS payload; host key includes tenantId.
- **Authorization**: never accept tenant id from request; platform callers hitting host endpoint get 403 via `hasRole('HOST_ADMIN')`; also assert `caller.tenantId() != null`.
- **Soft deletes**: every query must filter `deleted = false` (BaseEntity) - several existing repos forget it on purpose (e.g. `existsBySessionCode`); copy intentional behaviour only where documented.
- **Unknown/unverified**: whether `ExamSession.deleted` rows exist for cancelled drafts (use status CANCELLED vs deleted consistently); whether `V77 question_publication_provenance` has an approval timestamp; `examstaff` module absent from the asserted module list in `ModuleStructureTest` (either the test currently fails or the module is treated specially - run `./mvnw -pl app test -Dtest=ModuleStructureTest` before adding `overview`).

---

## 8. Phasing (backend) and suggested FE split

1. **Phase B1 - Foundations + Host core** (`overview` module skeleton, `DashboardSection`/`TrendValue` records, `DashboardSectionRunner`, window parsing/validation, Redis `DashboardCache`; facades for identity/tenancy quota/enrollment/session/attempt counts; V94 indexes; host controller + tenant-isolation + trend-math tests; update `ModuleStructureTest` list).
2. **Phase B2 - Host commercial & ops sections** (grading backlog, subscription/expiry, pending orders, support facade `SupportOverviewService`, audit recent activity) - can merge with B1 if capacity allows.
3. **Phase B3 - Admin core**: tenants/learners/recent tenants/applications/support/licenses/subscriptions/plans; role-aware section gating (`PlatformOperationPolicy`) + role-matrix tests.
4. **Phase B4 - Admin extras + map**: V94 (or V95) `tenants.province` + entity/`OnboardTenantRequest`/`TenantResponse`/vendor create-form field; map aggregate; revenue per currency; question bank extended stats; templates; platform health.
FE (parallel after B1/B3 contracts frozen): api-client types+requests (small, do first), tenant-web dashboard widgets + keep `LearnersOverview`, vendor-web `OverviewView` rewrite onto the single query hook.

---

### Relevant files
- `D:\FPT-FALL2026\Capstore\pte-api\app\pom.xml` - Redis, Flyway, Modulith 2.0.7; no cache starter.
- `D:\FPT-FALL2026\Capstore\pte-api\app\src\main\resources\application.yml` - `ddl-auto: validate`, `flyway.enabled: true`, Hikari pool 10.
- `...\pte-api\app\src\main\resources\db\migration\` - V1..V93 (next V94).
- `...\com\pte\shared\security\{CurrentUser,CurrentUserContext,SecurityRoles,PlatformOperation,PlatformOperationPolicy,SecurityPolicy}.java` - role/scope model.
- `...\com\pte\shared\web\{ApiResponse,PagedResult}.java`, `shared\domain\BaseEntity.java`, `shared\config\ClockConfig.java`, `shared\audit\AuditLogService.java`.
- `...\com\pte\tenancy\{TenancyService,StudentQuota,TenantSummary}.java`, `tenancy\domain\Tenant.java` (no province), `tenancy\internal\controller\{TenantController,StudentQuotaController}.java`, `tenancy\internal\repository\TenantRepository.java`.
- `...\com\pte\identity\IdentityService.java`, `identity\internal\repository\UserRepository.java` (`countByTenantIdAndRole`).
- `...\com\pte\billing\{BillingService,SubscriptionView}.java`, `billing\domain\{Subscription,Order,LicenseCode,TenantApplication,Plan}.java`, `billing\internal\repository\*`.
- `...\com\pte\session\{SessionService,StaffScheduleService}.java`, `session\domain\ExamSession.java`, `session\internal\repository\ExamSessionRepository.java`.
- `...\com\pte\attempt\{AttemptService}.java`, `attempt\domain\ExamAttempt.java`; `scoring\{ScoringService,StaffScoringService}.java`, `scoring\domain\{ScoringAnswer,GradingCohort}.java`.
- `...\com\pte\enrollment\{EnrollmentModuleService}.java`, `enrollment\internal\repository\{ProgramRepository,StudentClassRepository}.java`, `ProgramService.getDashboard`.
- `...\com\pte\support\internal\{service\SupportTicketService,repository\SupportTicketRepository}.java` (no root facade yet).
- `...\com\pte\itembank\ItembankService.java` (`stats`), `itembank\dto\response\QuestionStatsResponse.java`.
- `...\com\pte\attempt\internal\service\cache\PinnedSnapshotCacheService.java` - Redis caching precedent.
- `...\pte-api\app\src\test\java\com\pte\{ModuleStructureTest,RouteContractTest}.java`.
- `D:\FPT-FALL2026\Capstore\pte-web\packages\api-client\src\{requests\index.ts,requests\quota\index.ts,requests\admin\programs.ts,requests\endpoints.test.ts,types\index.ts,client\client.ts}`.
- `D:\FPT-FALL2026\Capstore\pte-web\apps\vendor-web\features\dashboard\components\OverviewView.tsx`, `...\features\tenancy\{api\index.ts,types\index.ts}`, `...\features\auth\constants.ts`.
- `D:\FPT-FALL2026\Capstore\pte-web\apps\tenant-web\features\examoperations\components\LearnersOverview.tsx`, `...\app\(dashboard)\host\dashboard\page.tsx`.
- `D:\FPT-FALL2026\Capstore\pte-doc\plans\platform-role-expansion\plan.md` - platform role matrix.

### Verdict
Use dedicated aggregate endpoints, but host them in a new leaf `overview` Modulith module that calls small per-module public facades (never internal repos), returns per-section `{status,data}` with real period-over-period `TrendValue`, gates admin sections by platform role, and caches via the existing Redis template; call out up front that the vendor map requires a new `tenants.province` column (V94) and that tenant-status/seat-usage/ticket-resolution trends cannot be shown honestly with the current schema.

Researcher A (Primary): dedicated aggregate endpoints in a new `overview` Modulith module with per-section degradation + per-module summary facades -> use this (add V94 indexes + tenants.province; defer untrendable metrics)
