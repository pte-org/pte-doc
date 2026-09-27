# Phase 03: IAM internal export and projection backfill

## Goal

Populate the projection for students that already exist in IAM, without a
cross-database join and without replaying the historical outbox.

## Why this is its own phase

The original plan compressed this into one line ("an internal API/event
contract"). The repository has none of the required pieces: IAM's controllers
are `AuthController`, `JwksController`, and `UserController` only — there is no
`InternalExportController` like `scoring` and `exam-delivery` have. Admin has no
`client/` package like `reporting` has. Both sides plus their security wiring
are net-new.

## Work items

1. Add `InternalExportController` to IAM exposing a cursor-paged, tenant-batched
   export of STUDENT users with exactly the projection's display fields. Follow
   the existing pattern in
   `services/scoring/src/main/java/com/pte/scoring/controller/InternalExportController.java`.
2. Reuse `pte-common`'s existing internal building blocks rather than writing
   new ones: `InternalServiceAuth`, `InternalExportScope`, `ExportPage`, and
   `KeysetCursor`.
3. Wire the internal scope into IAM's `SecurityConfig`. The internal route must
   be unreachable from the public gateway path and must reject a normal user
   JWT.
4. Add a `client` package to Admin with an internal export client for IAM,
   modeled on `reporting`'s `ScoringExportClient` / `ExamDeliveryExportClient`.
   Configure the IAM base URL through the same mechanism reporting uses.
5. Add an authenticated Admin rebuild endpoint/operation that pages through the
   export and upserts into `student_roster_entries` using the Phase 2
   `(tenant_id, student_public_id)` key. Model the surface on
   `services/reporting/src/main/java/com/pte/reporting/controller/InternalRebuildController.java`
   and `RebuildOrchestrationService`.
6. Make the rebuild resumable and bounded: fixed page size, cursor-based, safe to
   re-run from the start at any time, and safe to run while the live consumer is
   also writing.
7. Document the invocation: exact command, required credentials source, expected
   duration signal, and how to confirm completion by row count per tenant.

## Design constraints

- No SQL that touches another service's database, and no shared datasource.
- The export returns only the projection's safe fields. No password hash, no
  login hash, no IAM internal numeric id, no `date_of_birth` unless the roster
  actually displays it.
- Internal endpoints authenticate as a service, not as a user, and never accept
  a tenant id from an unauthenticated caller.
- Rebuild is idempotent by construction — upsert on the unique key, never
  delete-then-insert, so a rebuild racing the live consumer cannot drop a row.
- Credentials, tokens, and URLs never appear in logs or in the runbook text.

## Quality and testing state

- Unit tests: not started; user preference is `unitest: ko`.
- Quality: approved, 0 findings (report:
  `quality/phase-03-iam-internal-export-and-backfill-quality-report.json`).
- Required non-unit verification: `iam` and `admin` compile; call the internal
  export directly with valid service auth and confirm the payload shape; call it
  with a normal user JWT and confirm rejection; run the rebuild twice against
  the VPS data and compare row counts.

## Acceptance criteria

- The existing VPS student is backfilled and visible in the projection.
- Running the rebuild twice produces identical row counts and no duplicates.
- The internal export rejects a caller without internal service auth.
- The export response contains no credential or internal-id field.
- Running the rebuild while a new student is created concurrently loses neither
  the backfilled rows nor the new one.

## Cook status

- Implemented and verified on 2026-09-15.
- Unit tests skipped by explicit user preference.
- No commit or push created.
