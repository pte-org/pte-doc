# Phase 2: Backend expand — heartbeat endpoint + relax answer-payload validation

## Requirements
`pte-api` exposes a new heartbeat endpoint fully decoupled from timer/deadline data (for the parallel connectivity-monitoring feature), and accepts an empty/blank answer payload as a valid, processable submission — both additive and non-breaking to the current client.

## Steps
1. Add a new heartbeat endpoint scoped to an in-progress attempt that records/exposes only a minimal "last seen" signal — no task content, no deadline data, no dependency on `TimerState`/`ExamAttempt`'s timing fields.
2. Persist the heartbeat signal (e.g. a last-seen timestamp) on storage separate from any entity used for deadline enforcement, so the future connectivity-monitoring feature never couples to timer internals.
3. Add ownership/status checks to the heartbeat endpoint consistent with the rest of the attempt API (only the owning student, only while the attempt is `IN_PROGRESS`).
4. Relax `SubmitAnswerRequest.payload`'s validation so an empty/null value is accepted as a legitimate "no answer given" submission instead of a 400, without removing validation for other malformed shapes.
5. Confirm the answer-processing path already treats an empty/blank payload as a normal (if content-less) answer end-to-end — adjust only where downstream scoring/storage currently assumes non-blank content.
6. Add tests: heartbeat happy path, wrong-owner rejection, not-in-progress rejection; empty/null/whitespace-only payload accepted and persisted; existing non-blank payload tests unaffected.

## Success Criteria
- New heartbeat endpoint tests pass: success for the owning student on an `IN_PROGRESS` attempt, rejection for a non-owner or a non-`IN_PROGRESS` attempt.
- A `POST /answers` request with an empty/null payload against a running attempt is accepted (no 400) and persisted as a valid empty answer, verified by a new test.
- Existing `SubmitAnswerRequest`/`AttemptService` tests for non-blank payloads pass unchanged.

## Risks
- MEDIUM: relaxing `@NotBlank` broadly could let other kinds of malformed requests slip past validation undetected — mitigate by scoping the relaxation specifically to "blank/empty is allowed," not removing the constraint's other guarantees.
- LOW: a heartbeat write on every ~15s call across many concurrent attempts adds write load — mitigate by keeping the write minimal (single timestamp update); flag any further scaling concern to the connectivity-monitoring feature's own plan, not this one.
