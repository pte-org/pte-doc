# Phase 8 — Cross-Repository Hardening, Accessibility and Rollout Evidence

## Objective

Prove the complete locked/unlocked practice journey across `pte-api` and `pte-practice`, document limitations and rollback, and prepare quality evidence without claiming production readiness from local checks alone.

## Story mapping

- P1: full auth → entitlement → catalog → session → answer/confidence → Progress journey and all negative authorization cases.
- P2: visual, responsive, accessibility, media and failure-state review.
- P3: verify out-of-scope routes remain out of the release surface.

## Scope

- Cross-repo contract tests and E2E journeys for unauthenticated, locked, unlocked, revoked, ambiguous-org and history-only states.
- Multi-tab, double-click, retry, offline/reload, stale deadline, media failure and entitlement-revoke race tests.
- 23 canonical runtime coverage report, explicit `WRITE_EMAIL`/video gap report and fixture provenance.
- Accessibility, keyboard, responsive screenshot and browser/media support review.
- Metrics/audit verification, feature-flag rollout order, migration verification and rollback runbook.

## Exact files/areas likely changed

- `pte-practice` test setup/scripts, Playwright specs and test fixtures; exact test framework files selected after Phase 04 dependency decision.
- `pte-api` integration/contract tests alongside owning identity/practice/attempt/media/reporting packages; migration verification outputs.
- `pte-doc/projects/plans/quang-pte-practice-student-web/` coverage matrix, compatibility matrix, operator/rollback notes and final verification report.
- `pte-doc/projects/architecture/ADR-*.md` only if an approved architecture decision is required by Phase 01.
- `pte-web` only if an explicitly approved shared API/client contract extraction was chosen; otherwise no source change.

## Dependencies

- Phases 01–07 implemented and individually gated.
- Local test data/fixtures that contain no credentials or real private user data.
- Approved feature-flag and migration rollout order.

## Implementation steps

1. Run backend compile/tests and the isolated app lint/typecheck/build/test suite with unrelated failures separated.
2. Run contract tests against fresh and upgraded database fixtures; verify additive migrations are rerunnable and preserve history.
3. Run Playwright flows at 390x844, 1024x768 and 1440x900 for locked/unlocked/resume/Progress and supported task families.
4. Exercise API bypass, cross-tenant IDs, ambiguous org, plan revoke, expired session, stale tab, duplicate request and media failure cases.
5. Verify no raw credentials, OTPs, answer content or signed URLs appear in logs/test artifacts.
6. Record metrics/audit/feature flag behavior and the exact unsupported task gaps.
7. Run `ck:quality` for the final cross-repo change set; fix findings before re-running.
8. Update rollback/runbook/ADR evidence and hand off the exact remaining user decisions or external checks.

## Acceptance criteria

- All P1 success criteria are covered by automated or explicitly documented manual evidence.
- Locked direct API/deep-link attempts fail; entitled flows pass; revoke blocks new practice while Progress history remains.
- All included task rows have first-question/skip/submit acceptance evidence; unsupported rows are explicit.
- No high-risk security, tenant-isolation, media-binding, idempotency or confidence findings remain unresolved.
- Fresh/upgrade migration checks pass without destructive reset; rollback is feature-flag/forward-repair based.
- Responsive/accessibility review covers required viewports and interaction families.
- Final report separates passed, blocked, deferred, out-of-scope and deployment-not-run status.

## Design Constraints

- Do not use unauthenticated success, mocked-only routes or compilation as production/E2E proof.
- Do not run destructive volume/database cleanup as verification.
- Do not remove compatibility fields or aliases without a separately approved breaking-release decision.
- Do not commit, push or deploy as part of the plan.

## Quality and Testing State

- Quality: **APPROVED for the local change set after inline final review**;
  no blocking/high finding remains. This is not a production sign-off.
- Testing: **PASSED for local automated gates**. The final record separates
  authenticated browser, media, migration and deployment checks that remain
  pending.
- Evidence: `phase-08-coverage-matrix.md`,
  `phase-08-final-verification.md` and `phase-08-rollout-runbook.md`.
