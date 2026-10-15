# Phase 01 Output — Cross-Repository Contract Matrix

**Status:** Implemented as planning baseline; production implementation starts in Phase 02.

## Product decisions used by this cook

| Decision | Baseline | Boundary |
|---|---|---|
| Email entry | Passwordless one-time email challenge; existing username/password remains backward compatible. | Identity owns verification and token issuance; the web never invents a student session. |
| Unknown email | Verified shell-only identity with no organization membership and locked practice. | It may see Home/Practice tests/Study-Pack/Progress empty states, but cannot create or reach a practice session. |
| Imported student | Import links the verified identity to one or more canonical organization memberships. | Ambiguous memberships require explicit context; email alone never merges data. |
| Practice unlock | Active imported student + active eligible `EXAM_PACKAGE` product + valid seat/capacity policy. | `STUDENT_CAPACITY` is a seat prerequisite, not a standalone practice product. |
| Practice boundary | `PracticeSession` is the student-facing aggregate; the existing attempt/runtime seams are reused as its execution record with an explicit `PRACTICE` source. | Official exam session/enrollment/report behavior remains unchanged. |
| Unsupported reference rows | `WRITE_EMAIL` and explicit video remain unavailable until canonical contracts exist. | Never map either one to a different task type. |
| Progress | Persist response/confidence; expose correctness only when an existing scorer contract is authoritative. | No fabricated score for draft, skipped-only exit or scoring failure. |
| Entitlement revocation | New practice mutations fail closed; existing progress/history remains readable. | Draft preservation/finish behavior is encoded in the session state machine, not UI state. |

## Transport and persistence decisions

- The isolated web uses a same-origin Next BFF adapter for protected calls.
  Access and refresh tokens are stored only in `HttpOnly`, `Secure` cookies
  (`SameSite=Lax` in production); task renderers never receive either token.
  Mutating BFF routes use a double-submit CSRF cookie/header pair. Local HTTP
  disables `Secure` only through explicit development configuration. The
  backend's existing bearer contract remains the server-to-server compatibility
  boundary. Direct browser CORS is not the normal practice path; any explicit
  allowlist is owned by deployment configuration.
- Practice mutations carry `Idempotency-Key`, request hash and optimistic
  `clientVersion`. The recommended replay window is 24 hours. A reused key with
  a different body is `409 IDEMPOTENCY_KEY_REUSED`; a stale version is
  `409 STALE_SESSION_VERSION`.
- A session is non-empty only after an answer-bearing payload or completed
  recording is persisted. Untouched/skip-only explicit exit is discarded and
  produces no report or zero score.
- Recording binding includes student, practice session, pinned item, purpose,
  MIME, byte size and duration. The initial format is `audio/wav`, client-side
  encoded, with configurable 10 MiB and 120-second limits and 30-day practice
  retention. WebM/transcoding requires a separate ADR owned by the media module.

## Identity/linking model

The current tenant-scoped `User.email` is not made globally unique. Add an
identity/link layer owned by the identity module:

- `practice_identities(public_id, normalized_email_hash, verified_at, status,
  created_at, updated_at)` is global and contains no tenant entitlement.
- `practice_identity_memberships(identity_id, user_public_id, tenant_id,
  status, linked_at)` links the global verified identity to canonical imported
  student users. A unique identity/user pair prevents duplicate links.
- Roster import normalizes the supplied email and links an existing identity;
  missing email does not silently link by generated username. Multiple active
  memberships require an explicit organization context before practice access.
- Shell-only identity is not a tenant user, does not consume a seat and cannot
  call practice mutation endpoints.

## Entitlement truth table

| Student/identity | Capacity | Eligible `EXAM_PACKAGE` | Organization context | Result |
|---|---|---|---|---|
| Imported active membership | sufficient | active and within dates | explicit | `UNLOCKED` |
| Imported active membership | sufficient | expired/cancelled/suspended | explicit | `LOCKED` |
| Imported active membership | insufficient/invalid | active | explicit | `LOCKED` |
| Imported active membership | sufficient | only `STUDENT_CAPACITY` | explicit | `LOCKED` |
| Imported inactive/suspended/removed | any | any | explicit | `LOCKED` |
| Multiple active memberships | any | any | absent/ambiguous | `AMBIGUOUS` |
| Shell-only identity | not applicable | not applicable | empty | `LOCKED` |
| Unknown email before verification | not applicable | not applicable | empty | challenge only; no session |

## API error vocabulary

| HTTP | Stable code | UI behavior |
|---:|---|---|
| 401 | `AUTHENTICATION_REQUIRED` | Return to email challenge; do not retry a mutation blindly. |
| 403 | `PRACTICE_LOCKED` / `PRACTICE_CONTEXT_REQUIRED` | Keep preview shell; do not expose plan/capacity internals. |
| 404 | `PRACTICE_RESOURCE_NOT_FOUND` | Remove stale item/session and offer safe reload. |
| 409 | `IDEMPOTENCY_KEY_REUSED` / `STALE_SESSION_VERSION` | Replay or reload current state; never overwrite silently. |
| 410 | `PRACTICE_SESSION_EXPIRED` | Show session ended state and preserve readable history. |
| 422 | `ANSWER_SCHEMA_INVALID` / `CONFIDENCE_REQUIRED` | Keep local input, show field/task guidance, allow correction. |
| 429 | `PRACTICE_RATE_LIMITED` | Back off using server guidance; no tight retry loop. |
| 5xx | `PRACTICE_TEMPORARILY_UNAVAILABLE` | Preserve draft locally only as recovery aid; do not mark answer submitted. |

## Ownership and verification commands

| Area | Owner | Verification |
|---|---|---|
| Identity, membership, entitlement | `pte-api` identity/tenancy/billing public services | `./mvnw.cmd -pl app test` focused package tests |
| Practice/session/answer/progress | `pte-api` practice facade plus existing attempt/runtime seams | Maven unit/integration tests and API contract tests |
| Shell/renderers/media UX | `pte-practice` feature modules | `npm run lint`, `npm run typecheck`, `npm run build`, Vitest/RTL and Playwright |
| Shared client extraction | No extraction in first slice unless Phase 02 proves a stable package boundary | Contract compatibility test before reuse |
| Documentation/coverage | `pte-doc` | Markdown structure/trailing-whitespace validation |

## Common, constants and message ownership

| Concern | Canonical location | Rule |
|---|---|---|
| Practice machine codes and backend user-facing messages | `pte-api/app/src/main/java/com/pte/practice/internal/constant/PracticeConstants.java` | One owner per practice code; DTO validation references constants, never literals. |
| Cross-cutting HTTP/validation fallback | existing `com.pte.shared.constant.SharedConstants` and `GlobalExceptionHandler` | Add only truly cross-module values; practice policy text stays in practice constants. |
| Identity/tenancy/billing messages | existing module `internal/constant/*Constants.java` | Practice calls public policy services and does not duplicate their messages. |
| Web API paths and response codes | `pte-practice/src/shared/api/apiConstants.ts` and feature `constants.ts` | Paths/codes are typed and centralized; no URL/code literals in components. |
| Web copy | `pte-practice/src/features/<feature>/messages.ts` | Copy belongs to the feature; common UI contains no domain error prose. |
| API-to-user mapping | `pte-practice/src/shared/api/errorMapper.ts` | Maps stable codes to feature-safe copy and telemetry categories. |

Required initial web scripts are `lint`, `typecheck`, `test:unit` and
`test:e2e`; backend verification remains Maven/JUnit. A shared `common` package
is limited to tokens, API primitives and reusable UI behavior, not a dumping
ground for feature state or business rules.

## Rollout controls

The backend application owns default-off flags `practice.web.enabled`,
`practice.email-auth.enabled` and `practice.strict-entitlement.enabled`.
Operators enable them in order after migration verification; rollback disables
entry/strict enforcement and preserves additive identities, sessions and
history. The Phase 08 runbook records the exact environment/config mechanism.
