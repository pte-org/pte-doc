# Phase 3: Client cutover — pte-app TimerService rewrite (local countdown + auto-advance)

## Requirements
The exam countdown and prep→response phase transition run entirely on-device from the per-task durations delivered once at task start, with zero periodic or one-shot network polling to any timer/deadline endpoint.

## Steps
1. Remove `TimerService`'s periodic poll loop, one-shot poll, and its dependency on `TimerRepository`/`GET .../timer` entirely.
2. Derive phase (prep vs. response) and remaining time purely from the task's own `prepSeconds`/`responseSeconds` (and `preListenSeconds`/`preRecordSeconds` where applicable), anchored to a local monotonic clock at task start — no server reconciliation step remains.
   - **(plan-reviewer HIGH finding, resolved)** Before writing this logic, confirm concretely (do not assume) whether the per-item `responseSeconds` the server already returns for a Reading task reflects the *live remaining* shared section budget at that item's start (i.e. server-side value already accounts for time spent on earlier items in the same contiguous Reading run), or whether it's a static per-item value that would double-count/reset once computed client-side. If the server value already is the correct live-remaining figure, this step needs no special-casing beyond using it as-is. If it is not, this is a response-shape gap that must be closed in Phase 2 (additive, backend) — the server adds/adjusts the field so the client never has to reconstruct cross-item shared-budget math itself — and Phase 3 cannot ship until that field exists. This must be resolved here, not deferred to Phase 5's confirmation step, since Phase 5 only deletes server code and cannot design new client-facing plumbing.
3. Keep the existing local sub-second tick loop (for smooth UI countdown) and the existing stream contracts (`ticks`, `taskAdvancedExternally`) so downstream consumers (`ExamAttemptBloc`, `AutoRecordTimerBridgeMixin`, `TaskAdvanceButton`, the 5 audio-prompt Speaking cubits) need no interface changes.
4. Redesign what `AppResumed` does now that there is no server poll to reconcile against — recompute remaining time from a wall-clock task-start anchor (not a possibly-stalled `Stopwatch`) so backgrounding the app can't leave the countdown stuck or drifted.
5. Confirm prep-to-response and response-to-next-task auto-advance timing still fires at the correct instant using only local computation, matching today's dynamic per-item timing (audio-duration-aware prep, per the prior plan).
6. Remove now-dead client code paths that existed solely to reconcile against a server-provided phase/current-item pointer, and explicitly flag (for spec/product sign-off) that proctor-initiated external task advances have no remaining detection signal once polling is gone.
7. Rewrite `timer_service_test.dart` to cover local-only computation instead of the removed polling behavior.
8. Spot-check all 5 audio-prompt Speaking screens plus Read Aloud (which share this `TimerService`) still transition prep→record→stop→next at the expected instant.

## Success Criteria
- `flutter analyze` clean; full unit/widget test suite passes, including the rewritten `timer_service_test.dart`.
- No test or manual run makes any HTTP call to `GET /attempts/{id}/timer` — verified via a request-log/mock-verification assertion in tests and a manual network capture during a full attempt walkthrough.
- Manual: one full attempt across at least 2 task types (one audio-prompt Speaking type, one non-Speaking type) auto-advances at the correct local time with no visible desync from server-configured durations.

## Risks
- HIGH **(plan-reviewer finding, resolved)**: the Reading section-scoped shared countdown had no concrete client-side mechanism specified anywhere — Step 2 now requires confirming/closing this before Phase 3 ships (see Step 2's added sub-bullet), rather than leaving it as a Phase-5-time confirmation of something never actually designed.
- HIGH: removing server reconciliation removes the only mechanism that previously corrected client/server drift after the app is backgrounded/suspended — mitigate by making `AppResumed` recompute from a wall-clock anchor rather than trusting elapsed `Stopwatch` time, verified by a test simulating a backgrounded gap.
- MEDIUM: `TimerTaskAdvancedExternally` (proctor-initiated advance) currently relies on the poll detecting a changed current-item pointer — with no poll, this signal disappears. Mitigate by explicitly surfacing this capability gap to product/spec for a decision (defer, or wire to the new heartbeat response) rather than silently dropping it.
- LOW: the 5 audio-prompt screens assume `TimerSnapshot.phase` only ever comes from a trusted server source — verify local-only phase computation doesn't change edge-case behavior (e.g. zero-prep tasks starting directly in response phase).
