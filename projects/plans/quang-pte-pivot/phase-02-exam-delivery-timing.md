# Phase 2: Exam Delivery Timing

## Requirements

Add per-task prep-time and response-time tracking and enforcement to the exam delivery system. Each of the 22 PTE task types has its own official prep-time (e.g., 40 seconds for Describe Image) and response-time (e.g., 40 seconds for Describe Image) limits. This phase sources those values from official Pearson materials, stores them in versioned config, and implements per-task timer enforcement during exam attempts so students experience real PTE pressure.

This phase directly addresses P1 user story: "I want each task timed exactly like the real PTE (individual prep-time and response-time limits per task type)."

## Design Constraints

**Correction (2026-07-16, discovered during Phase 7 research):** the task-type count is **22**, not 20 — Pearson added `RESPOND_TO_A_SITUATION` (prep 10s / response 40s) and `SUMMARIZE_GROUP_DISCUSSION` (prep 10s / response 120s) in an August 2025 update. Every "20 task types" reference below means 22; source both new types' timing from the same official-materials research task in Step 1. See `spec.md` Assumptions and `PteTaskType.java` for the corrected enum.

- Per-task timing must be **exact and immutable per exam version** — if an exam is created with a specific set of task types, the timing for those tasks is locked at exam-creation time (not changed mid-attempt). This ensures fairness and auditability.
- Timing values **must be sourced from official Pearson PTE public materials**, not invented or estimated. If official sources are unavailable, implementation includes a TODO gate (documented in Success Criteria) that blocks release until sources are confirmed.
- The `examdelivery` state machine (NOT_STARTED → IN_PROGRESS → SECTION_SWITCH → SUBMITTED → DISCONNECTED) and the `proctor` module (audit trail, WebSocket broadcast) must remain unchanged; timing enforcement is an additional concern, not a refactor of the state machine.
- Timing enforcement must **not block exam progression if timers malfunction**; graceful degradation (log error, allow submission) is required so a single timer bug does not lock students out of the exam.
- Concurrent timer-state writes (student auto-submit-on-expiry vs. proctor extend-time hitting the same task-timer row at the same moment) must be serialized with optimistic locking (a `version` column on the per-task timer row) so one write doesn't silently overwrite the other.
- An `ExamAttempt` with no client activity (no submission, no timer heartbeat/ping) for longer than a configurable inactivity threshold must be auto-transitioned to `DISCONNECTED` by the server — the state machine's `DISCONNECTED` value must actually be reachable, not dead code.

## Steps

1. Research and document official PTE task-timing values: consult Pearson's public PTE Academic materials (timing is typically published in candidate guides, sample tests, or official FAQs). Create a comprehensive table mapping all 22 task types to their official prep-time (in seconds) and response-time (in seconds). Document sources (URLs, publication dates) for auditability. If official values cannot be found, escalate and document the TODO gate (see Success Criteria).

2. Design a versioned timing-config schema: store task-type timing values as a JSON or YAML file in `src/main/resources/config/pte-task-timings.json` (or as a reference table in the DB). Each entry maps a task type to { prepTimeSeconds, responseTimeSeconds }. Version the config file to track changes across exam versions.

3. Update the `ExamQuestion` entity to store prep-time and response-time at the time of exam creation (snapshot the config values, don't look them up live). This ensures that an exam's timing is immutable once created.

4. Extend the `ExamAttempt` state tracking to include per-task-instance timing state: for each task, track { taskId, taskStartedAt, prepTimerStartedAt, responseTimerStartedAt, timeElapsedInPrep, timeElapsedInResponse }. Add database columns to `attempt_answer` or a new `attempt_task_timer` table.

5. Implement a timer-enforcement service in the exam-delivery layer: when a student enters a task, validate that prep-time has not expired (if prep-time > 0 and elapsed > prepTime, auto-submit or log warning); when a student submits a response, validate that response-time has not been violated (if elapsed > responseTime + grace_period, log audit event but allow submission for fairness).

6. Extend the WebSocket exam-delivery events to broadcast real-time countdown timers to the frontend: emit { taskType, timeRemaining, timerPhase } events every 1–5 seconds so the frontend can display a live countdown. Ensure WebSocket events gracefully degrade if the network drops (client-side timer fallback).

7. Update the proctor module to support force-submit and extend-time actions on per-task timers (not just exam-level): allow a proctor to extend a student's prep-time or response-time for a specific task if needed (e.g., technical issue, accessibility accommodation). Implement optimistic-locking conflict handling: if a proctor's extend-time write races against a server-side auto-submit-on-expiry write for the same task-timer row, the losing write retries once against the fresh row state, then fails gracefully with a clear message ("Timer was already updated, please retry") rather than silently corrupting timer state.

7a. Implement the `IN_PROGRESS → DISCONNECTED` auto-timeout transition: a scheduled check (or the same poller infrastructure used elsewhere) marks an attempt `DISCONNECTED` and triggers server-side auto-submit with an `auto_submitted_due_to_inactivity` flag if no client activity is recorded for longer than the configured inactivity threshold (default 30 minutes). The student sees "Your exam session timed out" and existing answers are preserved for scoring/reporting.

7b. Define the force-submit-with-PENDING-scores policy for proctor actions: when a proctor force-submits an attempt while some Speaking/Writing answers are still `scoring_status = PENDING`, force-submit is allowed to proceed (submission must never block on scoring — this matches the async design constraint), and the resulting report clearly shows which tasks are still pending AI scoring rather than silently omitting them.

8. Create unit and integration tests: test that a task auto-submits or is flagged if prep-time expires; test that response-time validation works correctly; test that the proctor can extend a task-level timer; test that WebSocket timer events are broadcast correctly; test the optimistic-locking conflict path (simulate concurrent extend-time + auto-submit); test the inactivity auto-timeout transition to `DISCONNECTED`; test force-submit with PENDING scoring answers.

## Success Criteria

- Official PTE task-timing values for all 22 task types are documented in a source-cited config file (either `pte-task-timings.json` or a DB seed script). Each task type has prepTimeSeconds and responseTimeSeconds.
- **TODO Gate (if applicable):** If official Pearson timing sources cannot be located, a TODO comment is added to the config file (e.g., "// TODO: Confirm these values with Pearson's official 2024 PTE Academic candidate guide (source URL: pending)") and the gate blocks release. This gate must be manually resolved in Phase 9 or a post-release patch once sources are confirmed.
- An end-to-end exam attempt with per-task timers can complete without timeout/timer errors: a test student can start, progress through 3+ PTE task types, and see countdown timers for prep and response phases.
- Proctor can extend a task's timer via the proctor dashboard; the extension is logged in the audit trail.
- All existing `examdelivery` state-machine tests pass unchanged (zero regressions); timing validation is additive, not refactoring.
- WebSocket timer events are delivered to the frontend client at <100ms latency (measured in lab environment).

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started (Unit tests for timer validation, proctor actions, WebSocket events will be written during implementation; integration tests in Phase 9)

## Risks

- **HIGH: Pearson Timing Data Sourcing** — Official PTE prep-time and response-time values may not be publicly available (Pearson guards some exam details). If values cannot be sourced with confidence, the implementation is blocked by the TODO gate. *Mitigation:* Start research immediately in this phase; if sources are insufficient, escalate to a thesis advisor or Pearson contact; document assumptions clearly (e.g., "values estimated from publicly available sample tests" if official sources are unavailable).

- **MEDIUM: Timer Synchronization Across Client/Server** — WebSocket timer events are subject to network latency and clock skew. If a student's local client timer and the server timer diverge, a student may submit after the server thinks time has expired (or vice versa). *Mitigation:* Server is the source of truth for timer expiration; if server detects violation, log and allow submission (don't fail the attempt); use NTP or server-provided timestamps to reduce skew on the client.

- **MEDIUM: Graceful Degradation Under Failures** — If the Spring timer service crashes or the WebSocket connection drops, the exam must not lock up. A student must be able to continue and submit answers. *Mitigation:* Client-side fallback timer (JavaScript local timer if server timer stops); server-side graceful error handling (log, allow submission with warning flag); circuit-breaker pattern for timer validation (if too many failures, disable timer enforcement and log to ops).

- **LOW: Timezone/Daylight-Saving Edge Cases** — If the exam duration spans a daylight-saving transition or the server is in a different timezone than the student, timer calculations may be off by 1 hour. *Mitigation:* Use UTC for all timer calculations; store timestamps in UTC; convert to local timezone only for display.

