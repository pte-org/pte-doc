# Phase 7: Cross-repo cleanup and full verification

## Requirements
No stray references to the removed timer mechanism remain in either repo, both test suites pass in full, and the spec's own Success Criteria are demonstrably met.

## Steps
1. Grep both `pte-api` and `pte-app` for any remaining reference to `TimerState`, `TimerController`, `timer_states`, `fetchTimerState`, `/timer`, and `isResponseWindowExpired` — resolve every hit (delete, or confirm it's an unrelated name collision).
2. Re-confirm `pte-api/scripts/seed-e2e.ps1` has no functional dependency on the removed endpoint (only a stale comment was found during planning — verify nothing else surfaced during implementation).
3. Run the full `pte-api` exam-delivery test suite and the full `pte-app` test suite; both must pass with zero regressions.
4. Perform one full manual attempt walkthrough end-to-end on a local stack, capturing network traffic, confirming zero requests to any timer/deadline endpoint and heartbeat firing every ~15s throughout.
5. Update the connectivity-monitoring brainstorm report/spec reference to point at the new heartbeat endpoint instead of `/timer`, if it isn't already current (per the spec's own Assumptions).
6. Re-confirm no feature flag anywhere controls re-enabling the deleted enforcement, closing out the plan's P2 story.

## Success Criteria
- Zero grep hits for the removed symbols/routes outside historical docs/changelogs.
- Full `pte-api` and `pte-app` test suites green.
- Manual walkthrough network capture shows no `/timer` traffic and confirms ~15s heartbeat cadence.
- All 4 spec Success Criteria checkboxes verifiably true.

## Risks
- LOW: a leftover reference caught only at this stage requires a small follow-up patch to an earlier phase's already-"done" code — acceptable given this phase's explicit purpose is to catch exactly that.
