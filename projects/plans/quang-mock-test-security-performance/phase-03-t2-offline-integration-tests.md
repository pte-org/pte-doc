# Phase 3 (Track 2): Offline Crash/Resume Integration Tests

**Track:** 2 — Resilience & Auto-Recovery
**Covers:** FR-06 · User story: P1 (auto-save/resume)
**Depends on:** Phase 2 (SyncEngine hardening) — tests validate the hardened behavior.

---

## Design Constraints

- Must cover the 3 failure scenarios named in the spec explicitly: network loss mid-answer, app force-kill mid-attempt, resume-after-restart. Don't substitute weaker proxies (e.g. only testing a graceful app-close) for these.
- Tests must assert on actual data recovery (answers present, correct, and eventually synced), not just "app doesn't crash."
- Use Flutter integration test tooling capable of simulating connectivity loss (`connectivity_plus` test doubles/mocks) and process kill/restart (integration_test package with app restart between test phases, or a documented manual QA checklist if full automation of force-kill isn't feasible in CI).

## Files to Touch

- `aptis-app/integration_test/` (or equivalent existing test directory) — new offline-resilience test suite.
- `aptis-app/test/` — unit tests for `SyncEngine` conflict/retry logic hardened in Phase 2.

## Implementation Steps

1. Scenario 1 — network loss mid-answer: simulate connectivity drop while answering, verify answer is saved locally (Drift) even though sync fails, then verify it syncs once connectivity returns.
2. Scenario 2 — app force-kill mid-attempt: kill the app process after answering some questions but before sync completes, relaunch, verify all previously-answered questions are restored from local storage.
3. Scenario 3 — resume-after-restart: full app restart mid-exam, verify the attempt resumes at the correct question/state with correct remaining time (coordinates with Track 1 Phase 1's server-issued `expiryTime`).
4. Document any scenario that can't be fully automated in CI (e.g. true OS-level force-kill) with a manual QA checklist as a fallback.
5. Wire these tests into CI if feasible; otherwise document the manual run procedure.

## Acceptance Criteria

- [ ] Offline crash/resume integration test passes with 0 answer loss across all 3 simulated failure scenarios (network loss, force-kill, backgrounding).
- [ ] Maps directly to spec success criterion of the same wording.

## Quality and Testing State

- Quality: not evaluated
- Testing: not started
