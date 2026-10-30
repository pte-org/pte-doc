# Free plan checkout: missing order sequence

Date: 2026-10-31 (Asia/Bangkok).

## Cause

Production checkout failed with PostgreSQL SQLState `42P01`: relation
`order_code_seq` did not exist. `OrderRepository.nextOrderCode()` uses a native
`nextval` query. The consolidated baseline did not create that sequence, and
Hibernate schema validation did not check this non-entity object. The request
failed before reaching the zero-price activation branch; PayOS was not involved.

## Source correction

Added `pte-api/app/src/main/resources/db/migration/V15__restore_order_code_sequence.sql`.
It creates the sequence if absent, uses a 1,000,000,000 floor and chooses an
unused next code above existing orders and previous allocations. A transactional
sequence lock prevents concurrent allocations during the state read/restart.
Existing V1 and earlier migration files are unchanged.

Independent review identified a race in an initial `setval` implementation.
The final SQL uses a sequence lock and transactional `ALTER SEQUENCE RESTART`;
re-review reported no remaining concrete blockers.

## Verification

- PostgreSQL regression: empty DB gets the expected first code.
- PostgreSQL regression: prior sequence allocations are not reused.
- PostgreSQL regression: existing order codes raise the next value.
- PostgreSQL regression: replay remains monotonic.
- Parallel connection regression: `nextval` blocks while the sequence is locked
  and resumes without code reuse after release.
- `mvnw.cmd -pl app -DskipTests compile`: passed.
- `mvnw.cmd -pl app -Dtest=OrderServiceTest,OrderPersistenceServiceTest test`:
  11 passed, 0 failures/errors/skips.

## Production repair

Created and verified a custom-format pre-repair dump at:
`/home/ubuntu/pte-db-backups/pte-before-order-sequence-repair-20261030T190142Z.dump`.

Under the shared deployment lock, applied the same V15 SQL using
`psql -X -1 -v ON_ERROR_STOP=1 -f -`. Confirmed the sequence exists and
`nextval` returned the expected first value. The backend actuator remained `UP`;
no restart or unrelated data modification was required.

This was an immediate DB repair. The running application image still contains
the migrations through V14, so no Flyway history entry was manually fabricated.
Publish V15 with the next API deployment; Flyway can safely apply it over the
already repaired sequence without reusing allocated codes.

No new production order or subscription was created for verification. The user
can retry Activate plan; the full checkout interaction has not been claimed as
browser-tested in this fix.
