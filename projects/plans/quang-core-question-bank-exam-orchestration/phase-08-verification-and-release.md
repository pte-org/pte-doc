# Phase 8: End-to-end verification and release handoff

## Goal

Verify the complete capability on the current branches and produce a handoff
that distinguishes source verification from deployed/runtime verification.

## Verification sequence

1. Check worktree/branch and migration version in `pte-api` and `pte-web`.
2. Validate Flyway/Compose configuration with local non-production env files;
   never print secrets or env values.
3. Backend compile from `pte-api`:

   ```powershell
   .\mvnw.cmd -pl app -DskipTests compile
   ```

4. Run focused unit tests and the full backend regression suite; record exact
   counts and any environment-only checks separately.
5. Frontend checks from `pte-web`:

   ```powershell
   corepack pnpm --filter @pte/api-client typecheck
   corepack pnpm --filter tenant-web lint
   corepack pnpm --filter tenant-web build
   corepack pnpm --filter vendor-web lint
   corepack pnpm --filter vendor-web build
   ```

   Use the actual package scripts in the current branch if names differ.
6. Manual/integration matrix:
   - author creates/submits question; admin approves/publishes;
   - author creates/submits template; admin activates;
   - host sees only active eligible templates/packages;
   - insufficient question pool returns all shortages;
   - class + program + individual sources dedupe correctly;
   - reuse policy excludes/blocks exactly the documented prior states;
   - same subscription overlap fails under concurrent requests;
   - different subscriptions overlap successfully within each cap/window;
   - publish recheck catches roster/package changes after preview;
   - shared and unique form modes map correctly;
   - generation retry is idempotent;
   - no answer/seed/raw machine code leaks to host UI;
   - tenant A cannot read or mutate tenant B's sessions/audience/reports.
7. Run `ck:quality --gate` for each completed implementation phase. A blocker,
   high finding, or current-change medium finding blocks handoff.
8. Record exact command output, quality receipts, known environment blockers,
   migration status, and whether browser/runtime verification occurred locally
   or only by source inspection.

## Design Constraints

- No claim of “complete”, “fixed”, or “passing” without reading the actual
  command/quality output.
- A local compile is not a deployment proof. Do not push, commit, deploy, or
  mutate production data as part of this plan.
- Browser positive-path verification requires approved local credentials/data;
  invalid-login smoke does not prove a successful workflow.
- Keep unrelated dirty-worktree changes untouched.

## Quality and Testing State

- Unit-test expansion: enabled per the latest user instruction; focused unit
  tests and full regression passed.
- Quality gate: mandatory and approved for all eight phases; reports and
  receipts are under `quality/`.
- Testing: passed; exact output is recorded in
  `tests/phase-08-verification-test-report.json`.
- Required checks during cook: all phase-specific checks above, at least one
  local browser/manual end-to-end walkthrough, and a final independent quality
  gate receipt.

## Exit criteria

- Every acceptance criterion in `plan.md` has evidence or an explicitly listed
  environment blocker.
- Quality gate is approved for all phases.
- Handoff names remaining product decisions, migration flags, and operational
  rollback steps.
