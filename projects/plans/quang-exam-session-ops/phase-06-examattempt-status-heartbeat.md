# Phase 6: ExamAttempt Status Model & Heartbeat Mechanism

## Requirements

Extend `ExamAttempt` entity with an intermediate status enum (NOT_STARTED, IN_PROGRESS, SECTION_SWITCH, SUBMITTED, DISCONNECTED) and a `lastHeartbeatAt` timestamp. Implement a lightweight heartbeat endpoint or STOMP message handler that updates `lastHeartbeatAt` on each ping. Implement server-side timeout detection via a scheduled job or event that marks attempts DISCONNECTED after 3 consecutive missed heartbeats (~30 seconds at 10-second interval), and ensure the status machine handles all state transitions correctly. Foundation for Phase 7 realtime proctor updates.

Maps to: **P1 Story #6 (status part) | FR-05**

## Design Constraints

- Timeout is evaluated as elapsed time since `lastHeartbeatAt` exceeding 35 seconds (not a missed-beat counter); at the standard 10s client interval this tolerates brief jitter equivalent to ~3 missed pings before flipping to DISCONNECTED.
- Status must be the server's source of truth, not derived from WebSocket session state (which can be lost/disconnected).
- Must handle client crash/reconnect scenarios correctly: a reconnecting student should not lose their already-submitted answers.
- Heartbeat endpoint/handler must be lightweight (no expensive operations, only timestamp update).
- Status transitions must follow a defined lifecycle (NOT_STARTED → IN_PROGRESS → SECTION_SWITCH → SUBMITTED or DISCONNECTED).

## Steps

1. Add status enum column to ExamAttempt (values: NOT_STARTED, IN_PROGRESS, SECTION_SWITCH, SUBMITTED, DISCONNECTED) and lastHeartbeatAt OffsetDateTime column; default new attempts to NOT_STARTED, null lastHeartbeatAt.

2. Implement a lightweight heartbeat endpoint (e.g., POST /api/attempts/{attemptId}/heartbeat) that accepts the student's JWT, updates ExamAttempt.lastHeartbeatAt to now, and returns the current status (200 OK with status in response body); no database query beyond the update itself.

3. Add a scheduled task (e.g., every 10 seconds) that scans ExamAttempt records with status IN_PROGRESS or SECTION_SWITCH and checks if lastHeartbeatAt is more than **35 seconds** in the past (the definitive threshold — supersedes the "3 consecutive beats" framing used in early design notes); if so, update status to DISCONNECTED and record the timestamp. Semantics: this is a single check against "now − lastHeartbeatAt > 35s", not a count of missed beats — at a 10s client interval, 35s corresponds to roughly 3 missed pings, but the server only ever evaluates the elapsed-time condition, never a beat counter.

4. Implement status transition logic: when a student starts the exam, transition from NOT_STARTED → IN_PROGRESS and set lastHeartbeatAt to now; on section switch, transition to SECTION_SWITCH; on submit, transition to SUBMITTED (via `SELECT ... FOR UPDATE` on the ExamAttempt row, consistent with Phase 8's force-submit locking, so a concurrent proctor force-submit and student submit cannot both apply); on heartbeat timeout, transition to DISCONNECTED.

5. Test the timeout scenario: create an ExamAttempt, mark it IN_PROGRESS, do not send a heartbeat for 36 seconds, run the scheduled job, verify status is DISCONNECTED; also test at 34 seconds elapsed to verify it is NOT yet marked DISCONNECTED (boundary test).

6. Test reconnect scenario: create an ExamAttempt with submitted answers, mark it SUBMITTED, close WebSocket connection, reconnect on a different IP/device, verify submitted answers are still retrievable (no data loss).

7. Test state-transition validation: attempt to transition SUBMITTED → IN_PROGRESS (invalid), verify it's rejected.

## Success Criteria

- Heartbeat endpoint updates lastHeartbeatAt and returns current status (HTTP 200).
- Scheduled timeout job correctly identifies attempts missing 3+ consecutive heartbeats and marks them DISCONNECTED.
- Status transitions follow the defined lifecycle (no invalid jumps).
- Submitted answers persist across client disconnection/reconnection.
- An attempt that times out to DISCONNECTED cannot be resumed (no transition back to IN_PROGRESS).

## Quality and Testing State

- Quality gate: **approved, first pass, zero findings** (report: `quality/phase-06-examattempt-status-heartbeat-quality-report.json`, receipt issued 2026-07-16).
- Testing: **passed** — 36/36 unit tests (report: `tests/phase-06-examattempt-status-heartbeat-test-report.json`). Repo had zero test infrastructure before this phase; added `spring-boot-starter-test` (test scope) to `aptis-api/pom.xml`, establishing the test package convention (`src/test/java/...` mirroring main) for subsequent phases.

## Session Notes

- Implemented the actual "final submit" flow (`POST /{attemptId}/submit`) for the first time — `ExamDeliveryOperations.submitAttempt` and `SubmitExamRequest`/`ExamAttemptResponse` were pre-existing empty skeletons that nothing in the codebase ever called; `ExamAttempt.submit()` itself existed but was never invoked anywhere before this phase.
- `recordHeartbeat()` doubles as the implicit "start" trigger (first heartbeat = NOT_STARTED→IN_PROGRESS) since no separate attempt-creation/start endpoint exists anywhere in the codebase to hang an explicit start transition off of.
- Kept the pre-existing `isSubmitted: Boolean` field in sync with the new `status` enum rather than replacing it, since `GraderService` still reads it directly.
- Scheduled DISCONNECTED sweep is a single bulk JPQL UPDATE (not per-row load+save), per the phase's scale risk mitigation; added `@EnableScheduling` to the main application class (was not previously enabled anywhere).
- Build Gate: PASS.

## Risks

- **Timeout false positives in high-latency networks**: A student in a region with spotty connectivity might legitimately miss a few heartbeats due to network jitter but is still working. Mitigation: the 35-second elapsed-time threshold (Step 3) is the deliberately conservative, single source of truth — no other threshold value should appear anywhere else in this plan; client should auto-retry heartbeat on transient network errors.
- **Status lifecycle edge cases**: If a student submits the exam while status is SECTION_SWITCH (mid-transition), the submission should succeed but status update might race with a concurrent proctor force-submit (Phase 8). Resolved via the `SELECT ... FOR UPDATE` locking mandated in Step 4; test the race condition explicitly (concurrent heartbeat + submit, and concurrent student-submit + proctor-force-submit).
- **Scheduled job load at scale**: If there are 10,000 in-flight attempts, the 10-second scan job might become a bottleneck. Mitigation: index ExamAttempt by status and lastHeartbeatAt; use a WHERE clause to scan only IN_PROGRESS/SECTION_SWITCH records; implement batched updates to avoid lock contention.
