# Plan: Exam Session Code
Status: ✅ Complete
Date: 2026-10-05
Mode: Hard

## Session Notes
<!-- Updated by cook automatically — do not edit manually -->

**Last active:** 2026-10-05 20:30
**Phase in progress:** none (all complete)
**Status:** Implementation complete, tested (Step 3 PASS), reviewed (Step 4 APPROVED 9/10), manual UI check passed. Awaiting the user's manual commits per repo (pte-api, pte-web, pte-app, pte-doc) using git-manager's suggested commit messages. Pre-existing failing tests (pte-api 11, api-client vitest 4, pte-app 65) are a separate follow-up.

### Decisions made this session
- `sessionCode` is the 2nd component of `SessionResponse` (after `publicId`); legacy 10-arg constructor passes `null`.
- V72 helper is a regular function `v72_random_session_suffix()` dropped at the end of the migration (not `pg_temp`), tenant code read by a correlated subquery.
- V72 verified on the user's docker compose stack (`pte_postgres_data_localtest`), not the stopped native Postgres 18 service; edge cases on a throwaway scratch DB inside `pte-postgres`.
- 11 pre-existing failing tests (ModuleStructureTest module count, assessment/attempt) left untouched.
- Resolve input is validated in the service, not with `@RequestParam` constraints. Reason: `GlobalExceptionHandler` would turn method-validation and missing-param exceptions into 500.
  - Blank, missing or longer than 24 characters gives 400 `INVALID_SESSION_CODE` (new `InvalidSessionCodeException`).
  - Every lookup failure gives 404 `SESSION_NOT_FOUND`.
- `StudentSessionController` calls the `SessionService.resolveSessionCode` facade (returns a `UUID`) and wraps the result in `SessionResolveResponse`.
- The user tests UI by hand only when asked. Manual checks are batched so that one compose rebuild covers Phase 2's API, Phase 3's web and Phase 4's app.
- tenant-web constants were renamed `SESSION_ID_*` → `SESSION_CODE_*` (only `SessionDetailView` used them).
- Two visible session UUIDs are out of scope because their APIs return no code: the student reports page and examiner work items.
- App: the resolve 400 (`INVALID_SESSION_CODE`) maps to the same `SessionResolutionException` as a 404, so a student never sees the raw "Request rejected (400)".
- App: the student sees `ExamAttemptStrings.sessionResolutionFailureMessage` (the bloc maps every `SessionResolutionException` to it), so that constant now carries the "couldn't find that exam code" wording. `ManualSessionEntryRepository` was deleted. Internal `loginSessionId*` names were kept.
- pte-app has 65 failing tests and 4 analyzer errors that predate this work (same on a clean HEAD copy); left untouched.
- Code review (Step 4) APPROVED 9/10: 3 LOW findings all ACCEPTED (existing decisions, no code changes needed). Concurrent-create race (same prefix+day+suffix → DB UNIQUE violation + 500 or overlap error) accepted as ~1/1M per concurrent pair, practically unreachable, deferred (see Review section).

### Next immediate action
User commits per repo (pte-api, pte-web, pte-app, pte-doc) using git-manager's suggested commit messages (Step 5 post-finalize). Pre-existing failing tests remain unaddressed per review decision (separate follow-up).

## Overview
Hosts and students identify an exam session by its 36-char UUID (`ExamSession.publicId`), and students type that UUID into the Flutter app at login. This plan adds an immutable, human-readable `sessionCode` (e.g. `FPT-261010-K7QM`) shown to hosts and typed by students everywhere a person sees or types the session identifier, while the attempt API keeps using the UUID internally.

## Decisions (fixed with the user — not open for change)
- Format `{TENANT}-{YYMMDD}-{RAND4}`, e.g. `FPT-261010-K7QM`.
  - TENANT = `Tenant.code` (`^[a-z0-9-]{3,32}$`) uppercased, hyphens removed, truncated to 8 chars.
  - YYMMDD = `opensAt` at creation time in zone `Asia/Ho_Chi_Minh` (JVM default is UTC; tenants have no timezone field).
  - RAND4 = 4 chars from `ABCDEFGHJKLMNPQRSTUVWXYZ23456789` via `SecureRandom`, same pattern as `LicenseKeyGenerator` (package-private constructor taking `SecureRandom` for tests).
- Immutable after creation (`updatable = false`). If `opensAt` changes later via `updateDraft`, the date part may drift; accepted.
- Globally unique (DB UNIQUE constraint is the final guard).
- Collision handling: pre-check `existsBySessionCode` in a loop (max 5 attempts, then `IllegalStateException`). NOT catch-and-retry: a unique violation marks the `@Transactional` rollback-only, and `SessionLifecycleService` already maps `DataIntegrityViolationException` to an overlap error.
- Tenant code comes only from the existing facade `TenancyService#getTenantCode(tenantPublicId)`; no cross-module JOIN in Java.
- Attempt API is unchanged: `POST /api/v1/attempts/preflight` and `POST /api/v1/attempts` keep `UUID sessionPublicId`. Researched alternative (accept a string reference in attempt requests) rejected: breaking contract plus duplicated resolution.
- Resolution endpoint: `GET /api/v1/student/exam-sessions/resolve?code=...` (STUDENT only) returns `{ sessionPublicId }`. Matches caller's tenant (from the JWT principal only) AND requires enrollment AND excludes soft-deleted sessions; every failure returns the same 404. It does NOT require status OPEN.
- No dedicated rate limit on the resolve route. `RateLimitFilter` keys route buckets by `tenantId + "|route:" + URI` (no user dimension), so a per-route 10/s bucket would be shared by a whole class and 429 most students at exam start. Guessing a code yields nothing: a hit only returns a session the caller is already enrolled in. The route stays on the default tenant bucket, the same one preflight/start already use.
- App handles UUID input locally (backward compatible); the endpoint only accepts codes.

## Phases
Repo per phase (user commits manually, one commit set per repo):

| # | Phase | Repo | Summary |
|---|---|---|---|
| 1 | [Backend: session code](phase-01-backend-session-code.md) | pte-api | `session_code` column + V72 backfill + generator + both creation hooks + `SessionResponse` |
| 2 | [Backend: student resolve endpoint](phase-02-backend-resolve-endpoint.md) | pte-api | Resolve controller + enrollment-only check + soft-delete filter |
| 3 | [Web: show exam code](phase-03-web-exam-code.md) | pte-web | api-client type, tenant-web detail + list, copy/label constants |
| 4 | [App: code resolver](phase-04-app-code-resolver.md) | pte-app | New `SessionEntryRepository` impl + DI + strings + tests |

- [x] Phase 1: Backend: session code — `session_code` column, V72 backfill, generator, creation hooks, response field
- [x] Phase 2: Backend: student resolve endpoint — code to sessionPublicId, tenant + enrollment + not-deleted checked
- [x] Phase 3: Web: show exam code — api-client type, tenant-web detail/list, "Exam code" wording
- [x] Phase 4: App: code resolver — resolve code after login, UUID passthrough, wording, tests

Phase 3 can ship in any order (it falls back to the UUID until Phase 1 is live). Phase 4 needs Phase 2 deployed for codes; pasted UUIDs keep working regardless.

## Research Summary
- Collision strategy: pre-check loop chosen over catch-and-retry because of the rollback-only transaction and the existing overlap translation of `DataIntegrityViolationException` in `SessionLifecycleService`.
- Resolution location: a server-side resolve endpoint plus an app-side seam (`SessionEntryRepository`, already designed as the swap point) was chosen over changing the attempt API (rejected: breaking contract, duplicated resolution).
- Verified codebase facts:
  - Latest migration is `V71__support_ticket.sql`, so new file is `V72__exam_session_code.sql`.
  - Tests do NOT run Flyway: `app/src/test/resources/application.yml` sets `spring.flyway.enabled=false` and `ddl-auto=create-drop` under H2 (`@DataJpaTest`); no Testcontainers. V72 is Postgres-only and is verified manually against a Postgres DB, entity-level uniqueness is covered by H2-derived schema.
  - `new SessionResponse(` is called only in `SessionMapper.toResponse` (full 20-arg form). No test or other main code uses it; the legacy 10-arg constructor currently has no callers but must keep compiling.
  - `NotEntitledException` is HTTP 403 (not 404). Preflight for a non-OPEN or non-enrolled session returns this same 403 `NOT_ENTITLED`.
  - Rate limiting is per tenant + exact route (`request.getRequestURI()`), configured in `SecurityConfig` (not `RateLimitConfig`), default bucket `rate-limit.per-second:40`.
  - Student login collects the session identifier before auth; resolution runs after authentication (`StudentExamGate` -> `SessionResolutionRequested`).

## Dependencies
- Existing `TenancyService#getTenantCode` facade (pte-api).
- Phase 2 needs Phase 1 (column + repository lookup). Phase 4 needs Phase 2 deployed to run end-to-end. Phase 3 shows codes once Phase 1 is deployed (UUID fallback before that).
- Flyway V72 must run on a Postgres DB (backfill uses Postgres functions).

## Risks
- HIGH: Backfill produces duplicate codes or violates NOT NULL/UNIQUE and fails the migration — per-row random evaluation, a post-backfill dedupe loop, and `SET NOT NULL`/UNIQUE only after it. CI does not run Flyway, so Phase 1 requires the saved assertion script to pass on a seeded local Postgres DB (agreed with the user; no prod-copy rehearsal).
- MEDIUM: Date part drifts from the actual exam date after a reschedule (`updateDraft`) — accepted by the user; code stays immutable. Hosts see the real `opensAt` next to the code.
- LOW: Guessing the 32^4 (~1M) suffix — a hit only returns a session the caller is already enrolled in (same tenant, uniform 404 otherwise), so there is nothing to harvest. Bounded by the default tenant bucket.
- NOTED (pre-existing, out of scope): every non-route-limited request of a tenant shares one 40/s bucket (`rate-limit.per-second`). A large class starting together already contends on preflight/start; resolve adds one request per student. Revisit with a per-user key in `RateLimitFilter` if classes exceed that.
- LOW: Old app versions still send the UUID in the login field and keep working (UUID path never touches the endpoint, attempt API unchanged).
- LOW: Adding a constructor dependency to `ExamOrchestrationService`/`SessionLifecycleService` breaks tests that construct them with `new` — update those tests in Phase 1.
- LOW: Entering a valid code for a not-yet-open exam resolves fine, then preflight returns 403 `NOT_ENTITLED`; the message shown is generic (see Phase 2/4 notes).

## Red-Team Review (2026-10-05) — verdict WARN, no blockers
| # | Finding | Severity | Decision |
|---|---|---|---|
| 1 | Per-route resolve limit is a shared tenant bucket → 429s at exam start | HIGH | ACCEPTED — dedicated route limit dropped (see Decisions) |
| 2 | V72: random() rationale imprecise, dedupe must touch only non-first rows with a cap, CI never runs Flyway | MEDIUM | ACCEPTED — Phase 1 Migration Notes + assertion script |
| 3 | Resolve would return soft-deleted sessions | MEDIUM | ACCEPTED — Phase 2 filters `deleted = false` |
| 4 | Tenant must come from the principal; null tenant must be the same 404 | LOW | ACCEPTED — Phase 2 |
| 5 | Wording "Bangkok-zone"; generate code right before save | LOW | ACCEPTED — Phase 1 |
| 6a | App normalization: strip whitespace, map en/em dashes | LOW | ACCEPTED — Phase 4 |
| 6b | Cache the resolved UUID across cold starts | LOW | REJECTED — one cheap request per gate init with no dedicated limit; caching adds stale-session state |
| 6c | Accept codes typed without hyphens | LOW | REJECTED — hosts share the code with hyphens; keep one canonical form |
| 7 | Other tenant-web screens may show the UUID | LOW | ACCEPTED — Phase 3 audit step |
| 8 | Web type required before API deploy | LOW | ACCEPTED — Phase 3 optional field + UUID fallback |

## Review (2026-10-05) — APPROVED 9/10
| # | Finding | Severity | Decision |
|---|---|---|---|
| 1 | Date part can drift from the actual exam date after a reschedule (`updateDraft` changes `opensAt`) | LOW | ACCEPTED (existing decision) — code stays immutable; hosts see the real `opensAt` next to the code |
| 2 | Random suffix can repeat; full code collision exhaustion after 5 attempts → 500 `IllegalStateException` | LOW | ACCEPTED (existing decision) — practically unreachable (32^4 attempts per day); pre-check loop + DB UNIQUE guard final collision |
| 3 | Server does not normalize Unicode dashes (`—` / `–` vs. `-`) in input | LOW | ACCEPTED (existing decision) — app normalizes before sending (Phase 4); one canonical form in DB; hosts share code with hyphens |
| 4 | Concurrent-create race: same prefix+day+suffix collides at DB → second caller sees 500 or overlap error | LOW | ACCEPTED (deferred) — ~1/1M per concurrent pair; `SessionLifecycleService` maps violation; no immediate fix; UX workaround: retry at app level |

## Validation (2026-10-05, confirmed with the user)
- No dedicated rate limit on the resolve route: confirmed.
- V72 verification: seeded local Postgres + `verify-v72.sql`.
- Not-yet-open exam keeps the generic preflight 403 message: confirmed, later UX improvement.
- Web scope: detail view + list column + audit of other UUID displays: confirmed.

## Out of Scope
- QR codes / deep links.
- Regenerating or editing codes on reschedule.
- vendor-web and support-ticket displays of session IDs.
- Changing the attempt API contract.

## Process Notes
- Do not implement from this plan file alone without cook; no commits are made by the agent. The user commits manually per repo (pte-api, pte-web, pte-app); phases are grouped so each repo's changes form a clean commit.
- Plans live in pte-doc only (nothing under pte-api/plans).
