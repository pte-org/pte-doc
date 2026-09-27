# Plan: Tenant student roster pagination, filters, and sorting

**Date:** 2026-09-15  
**Status:** Implemented locally — live VPS release pending  
**Mode:** Hard  
**Repository scope:** `pte-api`, `pte-web`, `pte-doc`

## Scope challenge

- **Exists?** Partial. Tenant web already has student creation, IAM student
  listing, and an Admin class-membership listing, but no default table,
  server-side pagination, complete search, or combined Program/Class filters.
- **Minimum?** One tenant-scoped paged roster query plus one frontend paged
  table. The current create/import flows remain in place.
- **Complexity?** Hard, and larger than the first draft assumed. IAM owns
  student identity data; Admin owns Programs, Classes, and memberships. A
  correct query needs a local read projection — and Admin currently has **no
  inbound messaging infrastructure at all**, so the projection cannot be fed
  without building that first.

## Architecture decision

Use a server-side offset-paginated `student-roster` query owned by Admin.
Admin stores a denormalized, non-authoritative projection of the safe student
display fields needed by the roster. IAM remains the source of truth for user
identity/authentication. Admin remains the source of truth for
Program/Class/membership. No service queries another service's database.

This is not optional convenience: `ADMIN_DB_URL` and `IAM_DB_URL` point at
physically separate databases (`services/admin/src/main/resources/application.yml:10`,
`services/iam/src/main/resources/application.yml:10`). A cross-service join is
not expressible.

The endpoint returns one joined page, including unassigned students through a
left join. The UI never downloads the complete tenant roster just to paginate
it. Offset paging is appropriate for an interactive table with page numbers and
total counts; cursor paging remains an export-scale follow-up.

## Verified codebase facts driving this plan

These were confirmed against the repository, not assumed:

- **Admin is publish-only today.** `services/admin/src/main/java/com/pte/admin/messaging/RabbitMqConfig.java:12`
  states "admin only publishes — no listener container factory here". There is
  no `messaging/consumer/` package, no `ProcessedEvent` entity, and no
  `ProcessedEventRepository` — every other consuming service has all three.
  Phase 1 exists solely to close this gap.
- **IAM emits three user events only** — `UserCreated`, `UserSuspended`,
  `UserPasswordReset` (`IamConstants:22-24`). There is no user-updated or
  profile-changed event, and `UserController` exposes no update endpoint. The
  projection's profile fields are therefore effectively immutable; see the
  standing constraint below.
- **`User` has `suspend()` but no reactivate** (`User.java:73-79`), and
  `UserStatus` is a two-value enum. `isSuspended()` is consulted at exactly two
  places, both in `AuthService` (lines 46, 62). Phase 5 closes this.
- **No frontend exists for user suspend either.** `@pte/api-client` has
  `suspendClass`, `suspendProgram`, `suspendOrganization`, and `suspendTenant` —
  nothing for users.
- **`UserCreatedEvent` carries only** `userPublicId`, `email`, `tenantId`,
  `roles`. Every other roster display field must be added.
- **IAM has no internal export endpoint.** Its controllers are `AuthController`,
  `JwksController`, `UserController`. Admin has no `client/` package. The
  backfill path is entirely net-new — Phase 3.
- **`class_memberships` is unique on `student_public_id` globally**
  (`ClassMembership.java:30`), so a student has zero or one membership row. The
  roster left join cannot fan out and `totalElements` is safe. There is no
  active/inactive membership flag — assignment is row presence.
- **`PaginationControls` already exists** in `@pte/ui`. It has previous/next and
  a "Page x / y" label, but no page-size selector and no first/last. Phase 6
  extends it rather than creating a second component.
- **`PageMeta` is declared twice** — `@pte/ui` (4 fields) and `@pte/api-client`
  (8 fields). Phase 5 resolves this to one source.
- **No gateway change needed.** The gateway already routes `Path=/api/admin/**`.
- **`ddl-auto: update` is active** in both admin and iam application.yml, which
  is why an explicit migration is mandatory rather than advisory.

## API contract summary

`GET /api/admin/student-roster` supports `page`, bounded `size`, `search`,
`programPublicId`, `classPublicId`, `assignmentStatus`, `sort`, and `direction`.
The caller tenant is always derived from the JWT. Default is
`createdAt DESC` with a deterministic public-id tie-breaker. Response uses the
existing `ApiResponse` envelope and the established `data` + `meta` paged
shape.

## Phase map

| Phase | Outcome | Depends on |
|---|---|---|
| 1 | Admin inbound messaging: ProcessedEvent, listener factory, queue + DLQ, binding to `outbox.iam.exchange` | — |
| 2 | `UserCreatedEvent` payload extension, `StudentRosterEntry` projection, migration, consumer upsert | 1 |
| 3 | IAM internal user export, Admin internal client, idempotent backfill | 2 |
| 4 | Paged response contract in `pte-common` and `GET /api/admin/student-roster` | 2 |
| 5 | IAM user reactivate: domain method, event, endpoint, consumer branch | 2 |
| 6 | API client contract, `PageMeta` deduplication, tenant-web query state | 4, 5 |
| 7 | Students table UX: default display, sorting, filters, pagination, status actions, lifecycle refresh | 6 |
| 8 | Quality gate, manual/API acceptance, deployment/runbook verification | 1–7 |

Phases 3, 4, and 5 are independent of each other and may be cooked in any order;
all three require Phase 2's projection table to exist.

## Resolved decisions

- **Page size:** default 20, options 20/50/100, hard maximum 100.
- **Class filter:** dependent on Program. Selecting a Program resets Class and
  page; Class options load only for the selected Program.
- **Backfill:** authenticated internal IAM export consumed by an idempotent
  Admin rebuild operation (Phase 3), invoked once after deployment.
- **Suspended students:** the roster returns them with their `status` and the UI
  shows a status badge. No status filter in this version — the roster is where a
  host finds a suspended account in order to act on it.
- **Reactivate (added to scope):** IAM has `suspend()` with no counterpart, so
  suspension is currently a one-way door. Phase 5 adds `reactivate`. Neither
  suspend nor reactivate has any frontend today — `@pte/api-client`'s `suspend*`
  functions cover Class, Program, Organization, and Tenant only — so Phases 6
  and 7 add the client functions and the row actions for both.

## Standing constraint for future work

IAM currently has no user-update endpoint, so the projection's `fullName`,
`studentCode`, and `phone` cannot drift. **Anyone adding a user-update endpoint
to IAM must also emit a `UserUpdated` event and extend the Admin consumer**, or
the roster will silently serve stale profile data. Record this in the IAM
service docs during Phase 2.

## Quality and testing state

- Unit tests: **not requested** (`unitest: ko` from the existing project
  decision). No unit-test execution is implied by this plan.
- Quality audit: **required** (`quality: có`). Run the quality gate per phase
  during cook.
- Manual/API acceptance and build/lint/typecheck verification remain required
  because the feature crosses service and browser boundaries.
- Current state: phases 1–8 implemented locally; quality approved with no
  findings; unit tests skipped by explicit user preference; live VPS release
  verification remains pending.

## Risks and mitigations

- **Eventual consistency:** idempotent projection upserts keyed on
  `(tenant_id, student_public_id)`, a rebuild operation, and bounded
  post-mutation refetch handling in the UI.
- **Tenant leakage:** scope every projection query by JWT tenant and validate
  Program/Class ids in the same query path; add negative acceptance cases.
- **Event contract break:** adding fields to `UserCreatedEvent` must not break
  `notification`'s existing `UserDirectoryConsumer`. Verify explicitly in
  Phase 2 rather than assuming Jackson tolerance.
- **Schema rollout:** do not depend on production `ddl-auto=update`; ship an
  explicit idempotent table/index migration and a rollback note.
- **Misleading class text:** never use IAM `class_name` for assignment filters;
  only `class_memberships` determines Program/Class in this view.
- **Pagination drift:** use deterministic ordering and reset to page 0 when
  search/filter/sort changes.
- **Shared-package regression:** Phase 6 modifies `@pte/ui`, which vendor-web
  also consumes. New props must be optional and defaults must preserve current
  rendering.

## Delivery constraints

- No automatic commit or push.
- Do not modify existing student records as part of the feature.
- Do not expose passwords, login hashes, or internal database ids.
- Preserve current create/import and class assign/transfer APIs. In particular,
  `useClassMemberships()` is reused by `features/classes`' `ImportOrAssignModal`
  and must keep working.
