# Phase 8: Rollout, Observability, Cross-Repo Verification, and ADR Handoff

## Objective

Prove the complete contract across fresh/upgrade databases, backend, vendor-web,
API client and Flutter before enabling strict capability enforcement. Record a
reversible rollout and final quality evidence; do not commit, push, deploy or
delete local data as part of this plan.

## Files

- `pte-doc/projects/architecture/ADR-*.md` for the approved runtime-contract
  decision
- `pte-doc/projects/plans/quang-task-type-catalog-template-runtime-contract/`
  verification notes and compatibility matrix
- `pte-api` migration/test reports and operator runbook references
- `pte-web` API-client/vendor-web verification outputs
- `pte-app` analyze/test and renderer compatibility verification outputs

## Implementation steps

1. Add compatibility fixtures representing canonical/legacy FILL codes, an old
   catalog/template response, a new runtime profile, a published snapshot and
   an unsupported renderer/schema.
2. Verify fresh Postgres migrations. If an upgrade fixture contains rows,
   verify it is preserved without destructive cleanup. Confirm the 23 standard
   catalog identities, 22 scored template requirements, preserved labels/order/
   inactive state, profile defaults and no duplicate aliases.
3. Run backend compile/tests, API-client checks, vendor-web typecheck/lint/build,
   Flutter analyze/tests and focused browser/manual flows. Record command,
   result, test count and unrelated failure separately in verification notes.
4. Run the authenticated local walkthrough:
   catalog backfill → draft template → Author submit → Admin activate →
   generate/publish snapshot → app preflight → start → render a canonical and
   FILL task → verify a later catalog/template activation does not change it.
5. Verify the negative flows: tenant/host cannot mutate platform catalog;
   Author cannot activate; inactive/retired task cannot enter a new template;
   missing app capability blocks before start; unknown renderer cannot next.
6. Add metrics/audit checks for backfill counts, alias usage, activation
   failures, unsupported preflight and feature-flag enforcement. Never log
   answer content, credentials or signed URLs.
7. Update the architecture ADR, compatibility matrix and operator runbook with
   the actual migration number, API fields, minimum BE/web/app release,
   feature-flag default, alias-removal condition and rollback steps.
8. Run the final `ck:quality --gate`; fix and rerun after every gate-fix patch.

## Rollout and rollback gate

1. Release the pte-app dual-read compatibility patch and capability manifest;
   it must accept both legacy `taskType` and canonical `taskTypeCode`/`runtime`.
2. Release additive BE migrations/readers and compatibility mapper while
   retaining the old wire field and adding canonical fields.
3. Run/verify the idempotent standard catalog backfill.
4. Release template/profile/snapshot support while retaining old fields.
5. Release vendor-web terminology/readiness UX.
6. Enable strict preflight/start enforcement only after supported-client
   telemetry is acceptable.

If rollback is required, disable the enforcement flag first. Keep additive
columns/readers and snapshot data; use a forward repair migration rather than
rolling back a shared migration or deleting volumes/data.

## Acceptance criteria

- Fresh and upgraded databases pass migration/idempotency verification.
- Old snapshots and old API clients remain readable during the compatibility
  window; canonical writes are consistent across BE/web/app.
- The full role/runtime negative matrix is tested.
- Final quality gate is APPROVED with no unresolved BLOCKER/HIGH/current-change
  MEDIUM finding.
- ADR, compatibility matrix, rollback instructions and phase evidence are
  linked from the plan.
- The final note clearly separates passed, blocked, deferred and out-of-scope
  work, and does not imply deployment or commit.

## Design Constraints

- Do not claim production readiness from compilation alone.
- Do not run `docker compose down -v`, database resets or broad cleanup as
  verification unless separately requested and confirmed.
- Do not hide unrelated dirty-worktree failures.
- Do not remove aliases/fields without an approved breaking-release decision
  and client inventory.
- Do not commit or push unless separately requested.

## Quality and Testing State

Status at plan creation: testing not started; quality not evaluated.

Required before phase completion:

- Full backend, web/API-client, Flutter, migration and browser/manual matrix.
- `git diff --check` in every affected repository.
- Final mandatory `ck:quality --gate` receipt rerun after all fixes.
- Handoff note containing exact passed commands, failures with scope, migration
  evidence, feature-flag state and rollback readiness.
