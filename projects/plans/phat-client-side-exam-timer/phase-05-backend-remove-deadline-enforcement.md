# Phase 5: Backend contract — remove deadline enforcement and delete TimerState

## Requirements
`pte-api` no longer computes, stores, or checks any per-task deadline; task advancement is driven solely by submitted answers (including empty ones from Phase 4), and `GET /attempts/{id}/timer` no longer exists. No feature flag gates any of this.

## Steps
1. Remove `AttemptService.processAnswer`'s response-window-expiry check and 15s grace-window logic entirely — acceptance depends only on whether the submitted item is still the current one (`NotCurrentTaskException` semantics unchanged).
2. Delete `advanceUntilLiveOrComplete`'s deadline-based catch-up loop; `getNextTask` now simply returns the attempt's current item (tracked on `ExamAttempt` since Phase 1) with no expiry sweep.
3. Delete `TimerController`/`GET /attempts/{id}/timer`, `TimerStateResponse`, and `AttemptMapper.toTimerResponse`.
4. Delete the `TimerState` entity and its repository — confirmed safe only because Phase 1 already relocated the non-deadline fields it held.
5. Delete `TimerService` (java) entirely, or reduce it to whatever non-deadline logic (if any) still has no other home — confirm by search that no caller still depends on any deadline-derived value.
6. Confirm the Reading section's shared-timer budget (today a live `responseDeadline` reused across a section's items) is preserved in whatever per-item form the client now needs — the computed *value* students see for a Reading section must not silently change even though the mechanism producing it does. **(plan-reviewer finding, resolved)** This is a confirmation step only, not a design step — the actual plumbing decision was made and shipped back in Phase 2/3 (see Phase 3 Step 2); if this step finds the value was never actually resolved there, treat it as a blocker on this phase, not something to design fresh here.
7. Remove now-dead exception paths tied only to deadline enforcement (e.g. `ResponseWindowExpiredException` if unreachable elsewhere) and confirm none of this sits behind a configuration flag.

## Success Criteria
- `AttemptService`, `AttemptMapper`, and controller-level tests pass with zero remaining references to `TimerState`/`isResponseWindowExpired`/`advanceUntilLiveOrComplete`.
- `GET /attempts/{id}/timer` returns 404 (route no longer registered) in an integration test.
- A test submits an answer well past the old deadline window and it is still accepted, proving wall-clock elapsed time no longer gates acceptance.
- A grep across the codebase confirms no configuration flag re-enables the deleted deadline check.

## Risks
- HIGH: deploying this phase before Phase 3/4's client cutover is confirmed live for every in-field client breaks any client still polling `/timer` or relying on server-enforced deadlines outright. Mitigate by treating this as a hard release-order gate — confirm via API access-log evidence of zero `/timer` traffic before deploying, not just "the client code merged."
- HIGH **(plan-reviewer finding, resolved)**: this phase is the one that actually removes the anti-cheat enforcement whose entire justification rests on one precondition from `spec.md`'s NFR — that a B2B tenant's exam machines are genuinely OS-locked (kiosk mode), not merely physically screened at the door. Since the plan explicitly rejected a feature-flag fallback (spec P2), there is no code-level safety net if this precondition doesn't hold for a given tenant. Mitigate: before deploying this phase to any B2B tenant, require an explicit operational/contractual sign-off confirming that tenant's exam machines are OS-locked — this is a checklist/ops gate, not something this phase's code can verify or enforce itself. Do not treat "code deployed" as equivalent to "safe to deploy for this tenant."
- MEDIUM: deleting `advanceUntilLiveOrComplete` removes the "catch up past drift" forgiveness `getNextTask` previously had — any attempt whose current-task pointer was already inconsistent (e.g. from an unrelated bug) now surfaces that inconsistency directly instead of being silently patched over. Mitigate with a test for a freshly-resumed, drift-free attempt, and treat any remaining drift found later as a data-integrity bug to fix at its source.
- MEDIUM **(plan-reviewer finding, resolved)**: no rollback-impact discussion existed for this phase — after deploy, code stops creating/maintaining `TimerState` rows for new attempts (table still exists physically until Phase 6). An emergency rollback of Phase 5 alone would run pre-Phase-5 code that expects a `TimerState` row for every attempt; attempts that progressed under Phase 5 code have none, breaking that reverted code. Mitigate: document that safe rollback is only a full Phase 1–5 revert performed before any attempt has progressed under Phase 5 code, never a Phase-5-alone revert.
- LOW: `NotCurrentTaskException` and `AttemptAlreadyCompleteException` must remain completely unaffected per the spec's Compatibility requirement — verify their existing tests still pass unmodified.
