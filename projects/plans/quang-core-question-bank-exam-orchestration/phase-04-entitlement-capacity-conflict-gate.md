# Phase 4: Entitlement, capacity and student-conflict publish gate

## Goal

Make package and student eligibility rules authoritative at publish/enrollment,
not merely UI filters.

## Rules

1. Subscription must be active and usable at the operation time.
2. Exam window must fit entirely inside subscription start/expiry.
3. Requested capacity and final eligible audience must not exceed
   `maxStudentsPerSession`.
4. The database exclusion constraint remains the final guard against overlap for
   the same `subscriptionId`; different subscription instances may overlap.
5. Student conflict policy is applied after source union/dedupe and before
   capacity reservation.
6. A prior scheduled-but-not-started exam is distinct from a prior started
   attempt. The policy decides which states count.

## Steps

1. Extend the public billing contract only if the publish gate needs more than
   current `SubscriptionView`. Keep plan and subscription repositories inside
   billing; expose a read/lock contract with lane ID, validity, cap and status.
2. Reuse deterministic subscription lock ordering from
   `BillingService.lockSubscriptions`; lock the session and subscription in a
   documented order to avoid deadlocks.
3. Add one batch conflict query returning student ID, prior session ID/name,
   prior status, time window, series key and conflict reason. Add indexes for
   tenant/student/session/time lookups and inspect `EXPLAIN` on representative
   data.
4. Implement policy evaluation:
   - `ALLOW` returns all deduped students.
   - `EXCLUDE_STARTED_IN_SERIES` marks only students with a started attempt in
     the same series.
   - `EXCLUDE_ASSIGNED_IN_SERIES` includes prior audience/enrollment rows.
   - `BLOCK_ON_SCHEDULE_OVERLAP` returns a blocking report for time overlap.
5. Persist exclusion records and reason codes. Do not delete or hide the source
   membership. The host can review the report; only the approved override action
   can change a blocking outcome.
6. Calculate final eligible count, compare with capacity, and reserve/commit
   only under the session lock. The commit materializes eligible audience
   members as the session's canonical enrollments; no separate global quota
   reservation is invented for the current per-session commercial contract.
   On failure, no scheduled state, audience snapshot, or form assignment may
   remain.
7. Keep and verify V27 `no_overlap_per_subscription`. Catch the database
   constraint violation and translate it to a friendly 409 with the conflicting
   session summary.
8. Ensure subscription revocation/expiry behavior follows the existing policy:
   scheduled sessions are cancelled on revocation; open/closed sessions are not
   retroactively destroyed. Explicitly document expiry at publish vs expiry while
   an exam is running.

## Backend locations

- `billing/BillingService.java`, `billing/SubscriptionView.java`
- `session/internal/service/SessionLifecycleService.java`
- `session/internal/service/EnrollmentService.java`
- `session/internal/repository/ExamSessionRepository.java`
- `session/internal/repository/EnrollmentRepository.java`
- new audience/conflict service and constants under `session/internal/`
- new migration after V27 for indexes/constraint support if required.

## Conflict response contract

The publish/preflight response must separate `BLOCKING` from `EXCLUDED` rows and
include only safe public IDs and product-readable fields:

```text
studentPublicId
decision: ELIGIBLE | EXCLUDED | BLOCKED
reason: DUPLICATE_SOURCE | ALREADY_ASSIGNED | ALREADY_STARTED |
        SCHEDULE_OVERLAP | OUTSIDE_TENANT | CAPACITY_EXCEEDED
priorSessionPublicId?
priorSessionName?
priorStatus?
```

The backend decides the reason. The frontend never infers conflict state from
the absence of a student in a list.

## Design Constraints

- UI filtering is never the source of truth.
- Same-lane overlap must remain a database invariant, not just an application
  precheck. Different subscriptions are intentionally allowed to overlap.
- Capacity is calculated after dedupe and exclusions. Rechecking `capacity` on
  every enrollment remains necessary for race safety.
- All conflict detail is safe for the tenant and contains no cross-tenant data.
- Admin override is explicit, permission-protected, reason-required and audited.
- Do not turn the rule into a permanent boolean on `Student`.

## Quality and Testing State

- Unit-test expansion: enabled per the latest user instruction; enrollment
  facade, program/class ownership, capacity and conflict behavior is covered
  by focused tests plus the full backend suite.
- Quality gate: mandatory and approved; report and receipt are stored under
  `quality/phase-04-entitlement-capacity-conflict-gate-*`.
- Testing: passed; the final regression evidence is recorded in
  `tests/phase-08-verification-test-report.json`.
- Required checks during cook: backend compile, schema/index validation,
  concurrent same-lane create/publish review, different-lane overlap check,
  500-student batch conflict path, capacity-after-exclusion walkthrough, and
  friendly 409/422 response verification.

## Exit criteria

- Every publish path evaluates subscription, window, overlap, capacity and
  student policy transactionally.
- A 500-student audience uses batch queries and produces a useful report.
- The same student cannot bypass a configured conflict policy through class,
  program, manual, or legacy enrollment paths.
