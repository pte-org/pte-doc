# Phase 4: Client cutover — heartbeat wiring + local-timeout empty-answer resubmission

## Requirements
The app pings the new heartbeat endpoint every 15 seconds throughout an `IN_PROGRESS` attempt regardless of the active task, and a task whose local response countdown reaches zero with no recorded/typed answer is submitted as an empty answer through the existing answer endpoint; the whole-attempt local countdown reaching zero triggers the same force-submit path a manual force-submit uses.

## Steps
1. Add a heartbeat client call on a fixed 15-second interval, started when an attempt becomes `IN_PROGRESS` and stopped only at attempt completion/app teardown — independent of `SyncEngine`'s active-task exclusion and of `TimerService`'s task-scoped lifecycle.
2. Ensure heartbeat failures are silently retried/logged, never surfaced to the student and never affecting the exam flow (mirrors the old timer poll's failure handling).
3. Confirm the existing "flush pending edit then advance" path (used today by `TaskAdvanceButton`'s expiry auto-trigger) already produces an empty/null payload when nothing was answered for a task, per task-type cubit — extend the minimum number of cubits where one currently skips flushing on empty content.
4. Wire the local response-countdown-reaches-zero condition to trigger that same submit-then-advance path for every task type, not just the ones already wired to `TaskAdvanceButton`'s auto-trigger.
5. Wire the whole-attempt local countdown reaching zero to the existing force-submit path, with no server-side deadline check able to block it.
6. Add/adjust tests: heartbeat cadence and non-exclusion from the active task, heartbeat surviving a task transition, empty-answer submission on local task timeout for at least one task type per major category (typed, selected, recorded), and whole-attempt auto-submit on local exam-clock zero.

## Success Criteria
- New/updated unit tests pass for: heartbeat firing every ~15s regardless of active task, timeout-triggered empty-answer submission, and exam-clock-zero force-submit.
- Manual: on a local stack, a task left untouched has its countdown hit zero and the app advances automatically with an empty answer recorded server-side.
- Manual: heartbeat requests are observed firing every ~15s throughout a full attempt, including while a long-response task is actively being recorded.

## Risks
- HIGH: this phase's empty-answer submission depends on Phase 2's `@NotBlank` relaxation already being deployed and confirmed live on `pte-api` — shipping this before that relaxation is live makes every local-timeout submission 400. Mitigate by sequencing this phase's release strictly after Phase 2 is confirmed deployed, never bundled with an unverified backend release.
- MEDIUM: firing heartbeat unconditionally every 15s (unlike `SyncEngine`'s active-task exclusion) during a long recording/upload task could add resource contention on a slow connection. Mitigate by keeping the heartbeat request minimal (no body) and non-blocking, verified in tests to not delay recording/upload code paths.
- LOW: a student who never interacts with a task at all (backgrounds immediately at prep start) exercises the empty-answer path on every subsequent task — confirm this doesn't loop or error differently from a normal single-task timeout.
