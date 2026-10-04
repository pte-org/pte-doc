# Phase 04: Worker rollout, regression, browser, and release-boundary validation

**Status:** Partially verified; handoff blocked  
**Priority:** P1  
**Prerequisites:** Phases 01-03  
**Stories:** All P1/P2 stories and success criteria

## Design Constraints

- Verification must distinguish migration-chain checks, worker/delivery tests,
  real PostgreSQL transaction tests, frontend type checks, browser behavior,
  and deployment/runtime checks. One is not evidence for another.
- Do not dispatch a workflow, push, commit, or deploy as part of this phase
  unless the user separately authorizes it.
- Preserve unrelated dirty-worktree changes and report any unrelated failure
  instead of hiding it.
- A local green build does not prove the hosted API, Caddy routing, or live
  database migration. Record those boundaries explicitly.

## Implementation and verification steps

1. Run targeted backend tests for inbox API/read isolation, support service
   events, support type/mapping validation, recipient eligibility, worker
   delivery, and notification listener mapping.
2. Run a real PostgreSQL migration/transaction suite in an isolated schema for:
   - the reconciled Flyway chain with exactly one migration per version;
   - duplicate event insertion;
   - rollback/no-intent behavior;
   - concurrent admin fan-out;
   - worker claim/retry and intent-to-item materialization;
   - mark-all racing a new delivery; and
   - snapshot pagination with arrivals between pages.
3. Verify `NOTIFICATION_INBOX_ENABLED` remains false by default in local/test
   configuration, then enable it only in a controlled environment after the
   valid migration chain is applied. Confirm pending support intents become
   visible inbox items and that retry/suppression metrics remain safe.
4. Run the full backend gates from the repository instructions:

   ```powershell
   .\mvnw.cmd -pl app -DskipTests compile
   .\mvnw.cmd -pl app test
   ```

5. Run web package gates:

   ```powershell
   corepack pnpm --filter @pte/api-client test
   corepack pnpm --filter @pte/api-client typecheck
   corepack pnpm --filter tenant-web exec tsc --noEmit
   corepack pnpm --filter vendor-web exec tsc --noEmit
   ```

   Run the relevant lint/build commands if the changed branch supports them;
   existing unrelated lint failures must be reported separately.
6. Execute the browser flow with two authenticated roles:
   - tenant submits a feedback ticket and the platform admin sees one unread
     bell item;
   - admin opens the item, changes status and adds a note;
   - tenant sees one notification for each committed action, opens the exact
     ticket, and sees the existing note/status;
   - invalid/rolled-back operations create no item; and
   - a second tenant/admin account cannot read or mutate another user's item.
7. Recheck the final diff and nested repository status. Confirm that no
   email-log endpoint, unrelated trigger family, deployment workflow, or
   credential file changed.

## Acceptance and tests

- Every success criterion in `spec.md` has a recorded test or an explicit
  verification gap.
- Backend, migration constraints, and frontend contracts agree on all support
  enum values and fields.
- The worker is enabled in the tested environment; a green intent test with a
  disabled worker is not evidence that the bell displays the notification.
- Bell visibility is within the existing 30-second polling boundary for a
  visible tab; no realtime guarantee is claimed.
- The support ticket remains the source of truth; the notification is only a
  pointer and read-state record.
- Any failed migration, browser, full-suite, or hosted check is reported with
  its exact scope and is not converted into a generic "passed" claim.

## Exit criteria

The feature is ready for a separately authorized implementation handoff only
after backend/frontend tests and the authorized browser/runtime checks have
fresh evidence. Until then, the plan remains a plan and no release claim is
made.

## Quality and Testing State

- Quality: reviewed for the Phase 04 diff; no blocker/high/medium finding.
  The quality receipt records environment and release-boundary notes.
- Testing: targeted and PostgreSQL-backed checks pass; full backend regression
  is not green because of four unrelated failures and six unrelated errors;
  authenticated browser CRUD and a controlled worker-enabled run remain open.

## Validation record (2026-10-04)

The detailed evidence is in:

- [Phase 04 test report](tests/phase-04-validation-and-handoff-test-report.json)
- [Phase 04 quality report](quality/phase-04-validation-and-handoff-quality-report.json)
- [Phase 04 quality receipt](quality/phase-04-validation-and-handoff-receipt.json)

Recorded results:

| Gate | Result |
| --- | --- |
| Java compile | Passed |
| Support/inbox backend and module-boundary tests | 89/89 passed |
| Isolated PostgreSQL delivery/read/announcement integration | 14/14 passed |
| Isolated Flyway chain | 76/76 migrations validated and applied; V71-V76 each present once |
| Full backend suite | 1089 tests: 4 failures, 6 errors, 14 skipped; failures are assessment/attempt baseline cases |
| API-client suite | 377/377 passed after accepting the valid admin route namespace |
| Tenant/vendor typecheck, build, lint | Passed; three non-blocking existing lint warnings |
| Browser smoke | Passed for unauthenticated login/redirect routes only |
| Worker-enabled runtime | Not verified; local app defaults `NOTIFICATION_INBOX_ENABLED` to false and the running app container is at Flyway V70 |

No release or deployment claim is made. The remaining handoff requires valid
tenant/platform-admin test accounts and a controlled app runtime with the
current V71-V76 chain applied and `NOTIFICATION_INBOX_ENABLED=true`.
