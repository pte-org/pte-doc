# Phase 01 scoped TDD preparation

Verdict: RED_READY (missing-implementation compilation RED; not GREEN).

## Scope and conventions

Read ck:test and both canonical report schemas fully; read NotificationDispatchServiceTest and NotificationLogServiceTest before writing. Reused JUnit 5, AssertJ and MockitoExtension. Test choice yes was already recorded. No agents, production changes or phase-state edits.

## Prepared tests

- InboxNotificationRequestedTest: schema/text boundaries, safe HTTP-400 domain exception/code, required fields, defensive immutable recipient list, exact duplicate normalization, cross-tenant ownership rejection, null tenant only for application/admin audience, type/category/target mappings.
- InboxDeliveryServiceTest: property defaults/overrides, exhaust-before-claim, fixed clock, missing/stale fence no writes, eligibility-before-fence lock ordering, eligible delivery, ineligible suppression, exponential capped transient retry, attempt exhaustion, terminal non-transient failure, sanitized constant codes, identity-preserving manual retry, operational records containing no message bodies.

## Exact RED evidence

Working directory: pte-api.

```powershell
.\mvnw.cmd -pl app "-Dtest=InboxNotificationRequestedTest,InboxDeliveryServiceTest" test
```

Exit 1. Production compile completed (847 source files). testCompile attempted 151 source files and reported 28 errors: cannot find symbol for inbox contracts/enums/store/service/properties and missing notification.internal.exception package. Examples: InboxNotificationRequestedTest.java:3 InboxCategory; :28 InboxNotificationRequested; InboxDeliveryServiceTest.java:5 InboxDeliveryProperties; :8 InboxDeliveryStore; :40 InboxDeliveryService. No syntax diagnostic was emitted. JUnit did not run; do not report these as executed assertion failures or passed tests. Java syntax, Mockito calls, parameter sources and existing DomainException accessors were manually reviewed; unresolved symbols prevent complete compiler type verification until implementation exists.

## Implementation handoff choices

- InboxDeliveryProperties is in notification.internal.config.
- Stable failure codes: INBOX_DELIVERY_TRANSIENT_FAILURE and INBOX_DELIVERY_NON_RETRYABLE_FAILURE. No raw exception detail in persisted failureCode.
- Exact duplicates normalize; conflicting same-user tenant scopes reject.
- COMMERCIAL_OUTCOME_CONFIRMED supports ORDER (payment), SUBSCRIPTION (license access), QUOTA (capacity). All are BILLING.
- Terminal fail nextAttemptAt is intentionally not prescribed; tests require FAILED, not PENDING. Retryable first failure schedules +5 seconds; subsequent backoff is capped.
- Hashes in the RED artifact cover exact file bytes; do not weaken/delete assertions during GREEN implementation. If an acceptance criterion changes, document justification rather than silently updating hashes.

## Verification boundaries and next work

Only two test-code files and this phase's test artifacts were added. git diff --check produced no whitespace diagnostics for tracked changes; newly created test files were separately reviewed. No tests passed, no quality approval, no feature completion claim.

Later integration uses the supplied isolated PostgreSQL 18.4 at 127.0.0.1:55439, database postgres, user codex_inbox_test, local trust. Each fixture must create its own random dedicated schema, never mutate/drop public or user-data schemas. Transactions/BEFORE_COMMIT rollback, admin NULL-tenant concurrent dedupe, SKIP LOCKED claims, expired-token fencing, atomic inbox+delivery state and stream serialization remain unverified and require real-PostgreSQL tests after implementation. Eligibility facade-role tests remain deferred until exact public lock signatures arrive.

