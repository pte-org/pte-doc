# Phase 7: Friendly errors, security, audit and migration hardening

## Goal

Make the core workflow safe to operate, support and migrate across old and new
clients.

## Steps

1. Inventory all new and touched backend exceptions/codes. Move user-facing
   messages and machine codes into the owning module constants. Keep details
   structured: field, slot, student, prior exam, subscription and conflict
   identifiers as safe public IDs only.
2. Inventory all touched tenant/vendor TSX files for literal alerts,
   confirmations and error text. Move them to feature constants and central
   error formatters. Known API codes get friendly text; unknown codes get a
   safe generic message plus support reference, never the raw code.
3. Add audit records for template activation, publish/override, audience
   exclusions, generation retry/failure, package changes and operational state
   transitions. Do not log question answers, seeds, access tokens or passwords.
4. Review tenant authorization on every audience source, session, form and
   report endpoint. Return no cross-tenant conflict data.
5. Add idempotency keys and unique constraints to new state-changing endpoints.
   Define cleanup/retry semantics for jobs left in `RUNNING` after a crash.
6. Add migration/backfill strategy:
   - Existing `SCHEDULED` sessions are treated as legacy shared-form sessions
     with a completed snapshot.
   - Existing enrollments remain valid and receive a compatibility form mapping.
   - No existing published snapshot is regenerated.
   - New non-null fields are introduced nullable/backfilled where needed, then
     tightened only after the compatibility reader is deployed.
7. Add feature flags/configuration for the new host flow and legacy adapter.
   Remove the flag only after current clients and local seed/demo data use the
   new contract.
8. Document rollback: disable new publish UI, stop new jobs, leave immutable
   published sessions deliverable, and replay only failed un-published jobs.

## Design Constraints

- API compatibility must not weaken authorization or validation.
- Friendly messages must remain stable enough for support and localization,
  while structured details carry precise remediation data.
- Migrations are additive and forward-only after the current latest version.
- Audit is append-only and tenant-safe; it is not a replacement for domain
  state or idempotency constraints.
- Existing historical quality receipts do not count as current-branch proof.

## Quality and Testing State

- Unit-test expansion: enabled per the latest user instruction; friendly
  error-formatting, permission and compatibility behavior was tested.
- Quality gate: mandatory and approved; report and receipt are stored under
  `quality/phase-07-errors-security-audit-and-migration-*`.
- Testing: passed; the final regression evidence is recorded in
  `tests/phase-08-verification-test-report.json`.
- Required checks during cook: backend compile, migration upgrade from a local
  baseline, compatibility read/write walkthrough, error-message inventory,
  security review of every new endpoint, and audit redaction review.

## Exit criteria

- No touched product screen renders a raw machine error code.
- Old sessions remain readable/deliverable; new sessions use the canonical flow.
- All new mutations are tenant/role protected, idempotent and auditable.

Implementation note: tenant-scoped exam lifecycle actions are audited. Global
platform template actions are not written to the tenant audit table because
platform users have no tenant ID; a platform-level audit sink should be added
before production compliance sign-off.
