# Phase 4: Speaking Response Scoring

## Requirements

Implement an async scoring pipeline for audio submissions (Speaking tasks: Read Aloud, Repeat Sentence, Describe Image, Re-tell Lecture, Answer Short Question). Integrate the speech-scoring vendor selected in Phase 3. Extract enabling-skill sub-scores (Oral Fluency, Pronunciation) from vendor responses and store them on the `AttemptAnswer` row. Students must be able to submit audio and immediately progress to the next task without waiting for scoring to complete (async/non-blocking); scores are populated in the background and available when the student views their report.

This phase directly addresses P1 user story: "I want my Speaking responses scored automatically by AI (fluency, pronunciation, grammar, essay quality)."

## Design Constraints

- Submission must never block on scoring — async is non-negotiable. A student hits submit, the response is immediately queued (status: PENDING), and the student advances to the next task. Scoring happens in the background via a scheduled poller.
- Scoring status and results are stored directly on `AttemptAnswer` rows: add columns `scoring_status` (PENDING/SCORED/FAILED), `retry_count`, `speech_fluency_score`, `speech_pronunciation_score`, `speech_error_details`. No separate job-queue table.
- Retry logic must be robust: transient failures (vendor API timeout, network blip) trigger automatic retry with exponential backoff (first retry at +5s, second at +30s, third at +5min, then give up or escalate to manual). Permanent failures (malformed audio, auth error) log and mark as FAILED immediately.
- Scoring results must respect tenant isolation: an answer scored for tenant A cannot leak scoring results or metadata to tenant B.
- Graceful degradation: if the scoring pipeline is unavailable at exam-submission time, the answer still gets queued (PENDING status); if the pipeline never recovers, a FAILED status is acceptable, but the exam is not locked (student can access report, see "score unavailable, contact support").
- **Poller idempotency is mandatory**: if more than one poller instance is ever running (container restart overlap, future horizontal scaling), only one may process a given PENDING row. Use `SELECT ... FOR UPDATE SKIP LOCKED` (or equivalent pessimistic row-locking) when the poller claims a batch of PENDING rows, so a second poller instance skips rows already claimed instead of double-submitting to the vendor.
- Audio input must be validated **before** it is sent to the vendor: reject (mark FAILED immediately, no vendor call, no retry) if the audio exceeds a size/duration limit or fails a format check. This prevents malformed/oversized payloads from wasting vendor calls or hitting vendor-side errors.

## Steps

1. Extend the `AttemptAnswer` entity schema: add columns for `scoring_status` (ENUM: PENDING, SCORED, FAILED), `retry_count` (INT), `scored_at` (TIMESTAMP), `speech_fluency_score` (DECIMAL 0–100), `speech_pronunciation_score` (DECIMAL 0–100), `speech_error_details` (TEXT, for debugging). Write a Flyway migration script or JPA migration to add these columns.

2. Create a `SpeechScoringPoller` Spring component (using `@Scheduled`) that runs every 5–10 seconds: claim a batch of `AttemptAnswer` rows with `scoring_status = PENDING` and `task_type IN (READ_ALOUD, REPEAT_SENTENCE, DESCRIBE_IMAGE, RETELL_LECTURE, ANSWER_SHORT_QUESTION)` using `SELECT ... FOR UPDATE SKIP LOCKED` (up to a batch size limit, e.g., 10 rows per poll) so concurrent poller instances never claim the same row twice. For each claimed row, invoke the speech-scoring vendor wrapper.

3. Before calling the vendor, validate the audio payload: reject (immediately set `scoring_status = FAILED`, no vendor call) if audio exceeds the configured max size/duration or fails a basic format check (valid codec/container). Otherwise, pass the audio URL/bytes from `AttemptAnswer.response_content` to the speech-scoring vendor (selected in Phase 3). Capture the vendor response and extract fluency and pronunciation scores. Map vendor score ranges to PTE enabling-skill ranges (if vendor returns 0–100, use directly; if vendor uses different scale, implement a calibration function).

4. Implement retry and error handling: on vendor API timeout or 5xx error, increment `retry_count`, set `next_retry_at` timestamp, re-queue for retry. On 4xx error or malformed audio, mark as FAILED immediately (no retry). On successful score, update `scoring_status = SCORED`, store scores, set `scored_at = now()`. All state changes are logged to the audit trail.

5. Implement task-level scoring cascading: when a Speaking task is scored, immediately update the parent `ExamAttempt` to mark that task as scored (add `task_scoring_status` field to track which tasks have results). If all tasks in an attempt are scored, optionally trigger a notification to the student (if notification service exists).

6. Implement a vendor API error handler: if the vendor is unavailable (circuit-breaker pattern), stop polling and log a critical alert (ops should investigate). If vendor is flaky (intermittent errors), use exponential backoff to avoid hammering the vendor. Implement a stuck-job monitor: if the count of PENDING Speaking answers older than a configurable threshold (e.g., 1 hour) exceeds a configurable count, emit a CRITICAL alert (log-based at minimum; wire to an ops notification channel if one exists). Provide a manual recovery action (admin-triggered) that marks stuck attempts `FAILED` with a `ScoringUnavailable` reason so students can still get a partial report instead of waiting indefinitely. Document the alert threshold and recovery runbook (cross-reference Phase 9 operations doc).

7. Implement a `ScoringResult` DTO: when a student views their exam report, the backend fetches all `AttemptAnswer` rows with their scoring statuses. For SCORED rows, include fluency and pronunciation scores. For PENDING/FAILED rows, include a status message (e.g., "Scoring in progress, please check back in 5 minutes" or "Scoring failed, contact support").

8. Create integration tests: submit a mock Speaking task with sample audio, verify PENDING status immediately, verify polling loop picks it up, verify vendor wrapper is called, verify scores are stored, verify student report shows scores. Test retry logic (mock vendor timeout, verify retry happens). Test error handling (mock vendor auth error, verify FAILED status set immediately).

## Success Criteria

- A Speaking task submission (audio) is queued with `scoring_status = PENDING` immediately on submit (latency <100ms); student advances to next task without waiting.
- The scheduled poller runs and processes PENDING Speaking answers; within 1 minute, answers are either SCORED (with fluency/pronunciation scores) or FAILED (with error details).
- Retry logic works: a transient vendor error (simulated timeout) triggers retry within 5–10 seconds; permanent error (simulated 400 Bad Request) marks as FAILED immediately.
- An exam report correctly displays Speaking task scores (fluency, pronunciation) for SCORED answers; PENDING/FAILED answers are labeled clearly ("scoring in progress" / "error").
- Zero tenant-isolation leaks: a Speaking answer scored for tenant A does not appear in reports for other tenants.
- All `examdelivery` and `proctor` tests pass unchanged (zero regressions); Speaking scoring is additive.
- Multi-repo integration: pte-api changes to `AttemptAnswer` schema and scoring pipeline do not break pte-app/pte-web (frontend can display PENDING/SCORED/FAILED status).

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started (Unit tests for poller, retry logic, vendor wrapper, error handling; integration tests with vendor sandbox API if available; end-to-end test with mock audio in Phase 9)

## Risks

- **HIGH: Vendor Latency Under Load** — If the selected vendor's API is slow (>10s per response), the polling loop may fall behind (more answers queued than can be processed). Exam reports may show PENDING scores hours after submission, disappointing students. *Mitigation:* Phase 3 PoC must have measured vendor latency; if average latency is >5s, implement async vendor calls (don't wait for response in poller, just submit and poll result later). Document expected latency in Phase 9; consider reducing batch-size in poller if latency is high.

- **HIGH: Audio Quality & Vendor Reliability** — Vendor may fail to score 10–30% of submitted audio (e.g., audio too noisy, speech too accented, format unsupported). Students may see FAILED scores without recourse. *Mitigation:* Implement audio validation on client before submission (check duration, bitrate, format); on vendor FAILED scores, implement a human-review workflow or manual re-scoring flag (Phase 5 or later); document limitations in exam disclaimer.

- **MEDIUM: Polling Loop Scalability** — As exam volume grows (100s of exams/day), polling every 5–10 seconds may hammer the database. *Mitigation:* Implement batching and pagination in the poller; consider moving to an async message queue (e.g., RabbitMQ) if polling becomes a bottleneck (post-Phase-9 optimization, not blocking release).

- **MEDIUM: Audit Trail Explosion** — Logging each retry and scoring state change may bloat the audit trail. *Mitigation:* Use a dedicated scoring audit table (separate from the general audit trail); implement log retention/archival.

- **LOW: Timezone/Timestamp Issues** — If server and vendor use different timezones, timestamp comparisons (retry_at, scored_at) may be off. *Mitigation:* Use UTC for all timestamps; convert to local timezone only for display.

