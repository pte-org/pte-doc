# Phase 01: Common-first durable foundation

Status: completed. Priority: P1 only. Date: 2026-10-03.

## Scope and dependencies

Mapping: FR-13, FR-16, FR-17; all P1 delivery foundations.

Prerequisites: None. Phase owner is the implementer for the owning modules below; final quality review is independent. Do not advance past unmet schema/security/transaction prerequisites.

## Design Constraints

Mandatory common-first: inspect [inventory](common-reuse-inventory.md), reuse existing symbols, extend public contracts minimally, justify any new capability in the phase log. No duplicate common response, pagination, errors, security, transport or UI primitives. No cross-module internal repository imports. Existing email audit/listeners remain separate. All errors use module constants plus shared safe HTTP handling; 400 invalid input, 401 unauthenticated, 403 wrong role, 404 foreign/missing personal target, 409 lifecycle/version conflict.

Use transaction-scoped intent persistence, database-enforced idempotency and bounded recoverable work. Preserve user changes and existing business side effects. No new violation/submission/per-examiner completion notification; no automatic score publication or force submission. P2/P3 work is deferred.

Preflight: inspected NotificationLog/BaseEntity, OrderPersistenceService and existing notification Mockito tests. Reuse BaseEntity, DomainException, existing user/tenant lock repositories and Spring transaction events; no injectable Clock or durable inbox store exists. New notification-owned PostgreSQL operational store is justified for atomic UPSERT, SKIP LOCKED and token fencing. Common Clock bean is the only new shared capability. Repository conventions override generic backend defaults (domain exceptions stay mapped by existing GlobalExceptionHandler). Applicable rules: CORR, DOM, OWN, ERR, SEC, CHG, CONST, TXN, CONC, OBS and DB/EVT adapters. No HTTP or business-trigger changes in Phase 01; later listeners consume their source-module events rather than business modules importing notification.

Gap scan validated: errors, permissions, concurrency and measurable NFR already exist in the master/spec; the four blanket missing-constraint findings are rejected. Semantic checks retain NULL-safe ownership/non-null dedupe, transaction durability, recipient stream commit ordering, lease fencing and unchanged email behavior. Docker is unavailable at preflight; local PostgreSQL Windows service is running and an isolated test connection will be checked without modifying user data.

## Implementation steps

1. Complete the common-first inventory with actual symbols and compatibility checks. Reuse BaseEntity, shared envelopes/exceptions, principal context and audit. Recheck configuration for Clock; if absent add a justified injectable UTC Clock, not scattered static time calls.
2. Add notification-owned immutable content/event payload, announcement, publication audience/recipient intent, recipient inbox, and recipient stream watermark entities. Choose the next available Flyway migration version after inspecting migrations; add foreign keys and indexes for recipient/tenant/read/order and due delivery claims.
3. Enforce uniqueness on non-null logical event identity plus globally unique recipient UUID, without nullable tenant weakening PostgreSQL uniqueness. Query ownership still binds null-safe tenant and recipient. Store typed target identifiers, safe immutable display metadata, attempts, nextAttemptAt, claimToken and leaseUntil.
4. Implement synchronous transactional event consumption BEFORE_COMMIT with fallbackExecution disabled. Source modules publish metadata-rich public events; notification listeners append durable intent while the source transaction is active. Avoid business-to-NotificationService dependencies paired with notification-to-business facades. Confirm ModuleStructureTest has no cycles/internal imports.
5. Implement bounded worker claiming with PostgreSQL SKIP LOCKED or equivalent verified lease-safe SQL. Persist claim lease in a short transaction; process a claimed record using token fencing. Inbox insertion and delivered-state change commit together. Expired leases retry; uniqueness makes replay harmless.
6. Serialize delivery and read-all on a recipient stream row. Assign inbox sequence while holding this row lock until commit, so a later read-all watermark reflects committed arrivals rather than IDs allocated in uncommitted transactions. Multiple recipients are locked in deterministic order where necessary.
7. Add capped backoff, finite attempts, sanitized failure code, suppressed state for now-ineligible recipients, administrative retry, and non-sensitive metrics. Preserve original event identity on retry; no content/recipient rewrite.

## Concrete file targets and ownership

notification/domain proposed entities; notification/internal/repository and service worker/append; notification public event contracts; resources/db/migration next version; shared time configuration only if justified; ModuleStructureTest.

File names for new types are proposed; confirm existing equivalents first. Migration numbering must be resolved from current repository, not guessed.

## Permissions, failures, concurrency and recovery

Bind principal/tenant on every personal operation. Sanitize display errors and logs; never include passwords, signed media, answers or provider secrets. Retry only committed logical work with original identity. Recover expired leases and missed evaluator wake-ups; do not retry invalid authorization/business transitions as delivery successes. Document lock ordering and transactional boundaries for this phase and test overlaps, not just sequential happy paths.

## Tests and acceptance evidence

Rollback after source event leaves no intent; callback wake-up failure does not lose persisted intent; crash after claim recovers; crash during insert rolls back both insert and delivered; duplicate 10-worker processing creates one inbox record; expired worker cannot finalize after a newer claim; admin null-tenant uniqueness; no existing email behavior change.

## Exit criteria

Migration applies on real PostgreSQL; worker lease/uniqueness/recipient serialization contracts documented; module boundaries verified; common reuse log complete.

## Quality and Testing State

- Phase checkpoint (2026-10-03): unit tests=yes (`--tdd`); quality gate=yes (`--hard`). RED preparation precedes production changes. Hard-mode human approval is required before completion or Phase 02.
- Implementation: production implementation complete for this phase; RED_READY artifact was verified before production changes. Phase completion remains blocked only on the hard-mode human checkpoint.
- Common-first evidence: inventory baseline and [reuse record](common-reuse-inventory.md) complete for every new Phase 01 capability.
- Unit/integration testing: passed (`ck:test --tdd --verify`, fresh rerun 2026-10-03); 96 tests, 0 failures/errors/skips. Original RED test hashes unchanged. Report: [Phase 01 test report](tests/phase-01-common-first-durable-foundation-test-report.json).
- PostgreSQL/browser/performance checks: 11 native-store integration tests passed on isolated PostgreSQL at 127.0.0.1:55439, each using its own random schema and actual V71 migration; retry-jitter tests passed; browser/performance, full historical migration-chain and JPA schema validation were not exercised.
- Quality gate: approved in verify mode; no open blocking findings. Report: [Phase 01 quality report](quality/phase-01-common-first-durable-foundation-quality-report.json). Receipt: [Phase 01 quality receipt](quality/phase-01-common-first-durable-foundation-receipt.json).
- Findings/fixes/reverification: `QUAL-NOTIF-001` resolved by bounded exhausted-lease recovery (`LIMIT` + `FOR UPDATE SKIP LOCKED`); receipt fingerprint verified successfully.
- Hard-mode checkpoint: approved by user on 2026-10-03; Phase 01 completion transition recorded before activating Phase 02.
