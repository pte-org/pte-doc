# Phase 01 additional test preparation

State: prepared, NOT RUN. Awaiting main build-ready instruction. No RED/GREEN/quality claim for these additional files.

## Files

- `pte-api/app/src/test/java/com/pte/notification/internal/service/InboxRecipientEligibilityTest.java`: seven Mockito tests; exact platform admin/null scope; tenant-first host lock order; inactive tenant/user and wrong role rejection; invalid scope without facade calls.
- `pte-api/app/src/test/java/com/pte/notification/internal/repository/InboxDeliveryStorePostgresIntegrationTest.java`: nine real-PostgreSQL tests; append rollback; proxied MANDATORY append and BEFORE_COMMIT listener/no fallback; ten concurrent appends with two NULL-tenant admins; immutable payload conflict; concurrent SKIP LOCKED claims; expired lease/new token fencing; atomic delivery rollback/sequence rollback; stream commit-order/read-all watermark and later unread arrival; exhausted crash lease/manual retry retaining identity.

Original two RED test files and RED artifact hashes remain unchanged. Read sibling ExaminerAssignmentDatabaseIntegrationTest and ScoringEligibilityQueryServiceTest. Read actual V71 migration and checked fixture FK identities, names and stream defaults against it.

## Runtime safety

Requires `INBOX_TEST_DB_URL`; absence explicitly skips, not a fake pass. If supplied, connection or migration errors fail the test. User defaults to `codex_inbox_test`, password defaults blank. Local supplied endpoint: `jdbc:postgresql://127.0.0.1:55439/postgres`. No Testcontainers or production dependency changes.

Each test creates `inbox_test_<random 32 hex>` schema, sets currentSchema to it, creates only minimal users/tenants identities and executes actual classpath `db/migration/V71__notification_inbox_foundation.sql`. Cleanup rejects any name outside the generated test-schema pattern before DROP SCHEMA CASCADE. No public or user-data schema operation.

## Later verification command (NOT executed in this preparation)

```powershell
$env:INBOX_TEST_DB_URL = 'jdbc:postgresql://127.0.0.1:55439/postgres'
$env:INBOX_TEST_DB_USER = 'codex_inbox_test'
.\mvnw.cmd -pl app "-Dtest=InboxNotificationRequestedTest,InboxDeliveryServiceTest,InboxRecipientEligibilityTest,InboxDeliveryStorePostgresIntegrationTest" test
```

Working directory: pte-api. Full compiler/runtime verification remains pending until main build-ready. Integration fixture config constructs Spring listener/appender beans to exercise annotations; raw store operations always run inside TransactionTemplate. Read-all integration mirrors the later API's SQL watermark boundary; it is not an HTTP authorization/UI test. Eligibility facade lock ordering uses mocks, not actual identity/tenancy persistence evidence.
