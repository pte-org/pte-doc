# Phase 2 (Track 1): Multi-Device Lock, Force-Stop & Tamper-Proof Submission

**Track:** 1 — Exam Integrity & Anti-Cheat
**Covers:** FR-03, FR-04 · User stories: P1 (multi-device), P1 (tamper-proof)
**Depends on:** Track 4 Phase 1 (audit log) — stub the audit write behind a no-op interface if Track 4 isn't merged yet, wire it once it lands. Also depends on Track 1 Phase 1 (`ExamAttempt` status field groundwork).

---

## Design Constraints

- **Immediate force-stop, not lease/heartbeat grace** — this is an explicit stakeholder decision (teacher wants instant stop + proctor alert on second-device detection), accepted despite the false-positive risk on flaky networks.
- **sessionToken generation and scope (fixes red-team CRITICAL/HIGH findings):**
  - `sessionToken` is a UUID generated **server-side only** via `UUID.randomUUID()` at `ExamAttempt` creation, returned once in the attempt-start response. The client MUST NOT generate or choose this value (prevents session-fixation, where a client picks the same token on two devices to masquerade as a reconnect).
  - `sessionToken` is scoped **strictly per-`ExamAttempt`** (not per-student, not reusable across attempts). Server rejects any request whose token does not match the token stored on the specific `ExamAttempt` row being accessed — a token from a prior or different attempt is invalid, never a valid "reconnect."
  - A reconnect from the same device replays the *same* token for the *same* attempt and is not treated as a new device. Only a request bearing a **different** token for the same active `ExamAttempt` triggers force-stop.
- **Atomicity (fixes red-team HIGH race-condition finding):** the token-check-then-force-stop sequence must run inside a single DB transaction using `SELECT ... FOR UPDATE` on the `ExamAttempt` row, so two near-simultaneous requests with different tokens cannot both observe "not yet stopped" and both proceed. The losing request always sees the already-updated `FLAGGED_STOPPED` state.
- **Client reconnect retry policy (fixes red-team HIGH finding):** on a transient failure (network error, timeout — not a `SessionConflictException`), the client retries the *same* `sessionToken` with exponential backoff (e.g. 1s, 2s, 4s, capped at 3 attempts / ~10s total) before surfacing a "session lost" error to the user. The client never silently requests a new `sessionToken` on retry — that would itself look like a second device to the server. Only an explicit `SessionConflictException` (409) is treated as "this session was force-stopped," not a generic network failure.
- New `ExamAttempt` status: `FLAGGED_STOPPED`, distinct from `SUBMITTED`. Both statuses are terminal/immutable for further writes.
- Tamper-proof submission: any mutation attempt (answer edit, resubmit, time adjustment) once status is `SUBMITTED` or `FLAGGED_STOPPED` is rejected AND logged via `AuditLogService` (event type `TAMPER_ATTEMPT`).

## Files to Touch

- `aptis-api/src/main/java/com/aptis/modules/examdelivery/domain/ExamAttempt.java` — add `sessionToken` field, `FLAGGED_STOPPED` status.
- `aptis-api/src/main/java/com/aptis/modules/examdelivery/service/ExamAttemptService.java` — session validation on every write, `forceStopAttempt(attemptId)` method, immutability guard for `SUBMITTED`/`FLAGGED_STOPPED`.
- `aptis-api/src/main/resources/db/migration/` — migration: add `session_token` column + unique constraint on `(student_id, exam_id, status)` where status = `ACTIVE`/`IN_PROGRESS`; DB `CHECK` constraint preventing writes when status is terminal (best-effort at DB layer, primary enforcement in service layer).
- `aptis-api/src/main/java/com/aptis/common/exception/` — new `SessionConflictException` (409), mapped in `GlobalExceptionHandler`.
- `aptis-app/lib/features/exam_delivery/presentation/bloc/exam_attempt_bloc.dart` — handle `SessionConflictException`/`FLAGGED_STOPPED` response by showing a clear "your exam was stopped" state, not a generic error.

## Implementation Steps

1. Add `sessionToken` (UUID) to `ExamAttempt`, generated **server-side** at attempt start via `UUID.randomUUID()`, returned to client, required on all subsequent requests for that specific attempt.
2. Add unique DB constraint ensuring only one `ACTIVE`/`IN_PROGRESS` attempt per `(studentId, examId)`.
3. Wrap the token-check in a transaction using `SELECT ... FOR UPDATE` on the `ExamAttempt` row: if the incoming `sessionToken` doesn't match the stored one (and doesn't match any other attempt — a token is only ever valid for the attempt it was issued for), call `forceStopAttempt(attemptId)` (sets status → `FLAGGED_STOPPED`) within the same transaction, reject the *new* request with `SessionConflictException`, and log `MULTI_DEVICE_BLOCKED` via `AuditLogService`.
4. Add immutability guard in `ExamAttemptService`: any write (`submitAnswer`, edit, resubmit) on an attempt with status `SUBMITTED` or `FLAGGED_STOPPED` is rejected with a 409 and logged as `TAMPER_ATTEMPT`.
5. Update Flutter bloc to implement the reconnect retry policy (same token, exponential backoff, ~3 attempts/10s) on transient errors, and to handle `SessionConflictException` (409) as a distinct "session was stopped" state, not a generic error.
6. Tests: second-device login is rejected + original force-stopped; tamper attempts post-submit are rejected + logged; same-device reconnect (same token, same attempt) is NOT treated as a conflict; a token from a *different* attempt is rejected even for the same student; two near-simultaneous logins with different tokens for the same attempt are tested for the race condition (only one should "win," verified via the `FOR UPDATE` transaction).

## Acceptance Criteria

- [ ] `sessionToken` is proven server-generated only (no client-supplied token path exists in the API).
- [ ] A `sessionToken` valid for one `ExamAttempt` is rejected when used against a different attempt, even for the same student.
- [ ] Concurrent-login race test (two near-simultaneous requests, different tokens) results in exactly one force-stop, not a partial/inconsistent state — verified by test.
- [ ] Second-device login on an active attempt is rejected and the original attempt force-stopped in 100% of test cases.
- [ ] Same-device reconnect (matching `sessionToken`, same attempt) does not trigger a false force-stop.
- [ ] Post-submit mutation attempts return a rejection response and produce an audit log entry (`TAMPER_ATTEMPT`).
- [ ] Maps to spec success criteria: "Second-device login... force-stopped in 100% of test cases" and "Post-submit mutation attempts return a rejection response and produce an audit log entry."

## Quality and Testing State

- Quality: not evaluated
- Testing: not started
