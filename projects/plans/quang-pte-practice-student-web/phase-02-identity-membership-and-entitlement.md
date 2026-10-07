# Phase 2 — Student Identity, Membership and Server-Authoritative Entitlement

## Objective

Allow the new student web to establish a verified email session and expose a safe, student-scoped entitlement state without duplicating canonical identity, import, membership, billing or capacity data.

## Story mapping

- P1: verified email sign-in, locked preview, automatic unlock after valid import/plan, capacity and revocation rules.
- P2: entitlement loading/error states support the responsive shell.
- P3: no future navigation/auth features.

## Scope

- Implement the approved email authentication flow while preserving existing username/password compatibility.
- Reconcile imported student email/profile mapping and verification status.
- Define the distinct cases for unknown, imported-unverified, suspended/removed
  and multi-organization email records. Unknown verified email may receive a
  shell-only identity with no organization membership; it never receives
  practice entitlement.
- Add the public entitlement policy/service and student-facing read contract.
- Enforce tenant/org context and ambiguous multi-org behavior.
- Add server checks that later practice endpoints can call at route/session/content/answer boundaries.
- Freeze the chosen cookie/bearer transport, refresh handling, CORS origins and
  CSRF protection for the isolated app before exposing the first endpoint.

## Exact files/areas likely changed

- Existing identity areas: `pte-api/app/src/main/java/com/pte/identity/internal/controller/AuthController.java`, `AuthService.java`, `LoginRequest.java`, `pte-api/app/src/main/java/com/pte/identity/domain/User.java`, `StudentRosterImportController.java`, `StudentRosterImportService.java`, `UserBulkCreateWriter.java`.
- Existing tenancy/billing areas: `pte-api/app/src/main/java/com/pte/tenancy/TenancyService.java`, `pte-api/app/src/main/java/com/pte/billing/domain/Subscription.java`, `pte-api/app/src/main/java/com/pte/billing/internal/controller/SubscriptionController.java` and their owning public APIs.
- New identity/entitlement DTO/controller/service/repository/migration files under the existing `com.pte.identity`, `com.pte.tenancy`/billing ownership; exact class names and migration number are selected after Phase 01.
- `pte-api/app/src/main/resources/db/migration/` — additive challenge/identity or entitlement projection migration only if required by the approved auth design.
- `pte-doc/projects/plans/quang-pte-practice-student-web/` — contract and authorization test matrix.

## Dependencies

- Phase 01 approved auth, eligible-plan and organization-context decisions.
- Existing notification/email delivery capability; no credentials in code or docs.

## Implementation steps

1. Add normalized-email lookup and explicit organization context without changing the meaning of existing username login.
2. Add short-lived one-time challenge storage/verification, rate limiting, expiry and non-enumerating responses if OTP/magic link is approved.
3. Ensure roster import persists/validates the email identity required by the approved flow; reject or report missing/ambiguous identity safely.
4. Implement entitlement policy through public identity/tenancy/billing services. Include student status, imported membership, plan status/type, capacity policy and organization context.
5. Return locked/ambiguous/unavailable/unlocked state without private plan/capacity details.
6. Add server authorization helpers/interceptors/service checks for future practice start, task, media, answer and progress access.
7. Add audit/metrics for auth abuse and entitlement decisions without logging email challenge secrets.

Eligibility must be verified with a truth table covering at least: active
imported student + sufficient capacity + active eligible product; expired or
suspended product; insufficient capacity; capacity-only purchase; removed
membership; ambiguous organization; and unknown email. The table is an output
of this phase, not an implementation detail hidden in the UI.

## Acceptance criteria

- Verified email can establish the canonical session without exposing whether
  an email was previously known; unknown email receives shell-only locked
  access, while imported membership is linked to the canonical student.
- Existing username/password login remains compatible until a separately approved deprecation.
- A valid imported active student under the approved eligible plan unlocks after the documented refresh boundary.
- Expired/suspended plan, inactive/removed student, capacity failure and ambiguous organization block new practice.
- Progress read access can remain available independently of current entitlement.
- Direct calls with missing/incorrect org/session context are rejected server-side.
- Authorization tests cover cross-tenant IDs, replayed/expired challenges, rate limits and plan revocation.

## Design Constraints

- Preflight: Phase 01 is quality-approved and test-passed; current `pte-api` uses direct Bearer JWT, stateless CORS allowlisting and disabled CSRF, so this phase preserves that existing transport while keeping the future `pte-practice` BFF/cookie decision additive.
- `pte-practice` cannot infer eligibility from JWT claims, cached UI state or email alone.
- Never merge data for an email belonging to multiple organizations.
- Keep challenge values hashed/one-time and omit them from logs, errors and analytics.
- Use existing module public services; do not read another module's repositories directly.
- Additive migrations and forward rollback only.

## Quality and Testing State

- Quality: **APPROVED**. Report: `quality/phase-02-identity-membership-and-entitlement-quality-report.json`; receipt: `quality/phase-02-identity-membership-and-entitlement-receipt.json`.
- Testing: **PASSED**. Report: `tests/phase-02-identity-membership-and-entitlement-test-report.json`.
- Planned evidence: identity unit/integration tests, entitlement truth-table tests, authorization/IDOR tests, rate-limit tests and migration verification.
