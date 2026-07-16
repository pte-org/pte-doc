# Phase 5: Writing Response Scoring

## Requirements

Implement an async scoring pipeline for written responses (Writing tasks: Summarize Written Text, Essay Writing, Fill in the Blanks—Writing sub-type). Integrate the essay-scoring vendor selected in Phase 3. Extract enabling-skill sub-scores (Grammar, Vocabulary, Written Discourse, Spelling) from vendor responses and store them on the `AttemptAnswer` row. Writing submissions must be non-blocking (submit, queue, advance immediately) and processed by a scheduled poller, similar to Phase 4's Speaking pipeline.

This phase covers P1 user story (Writing auto-scoring) and, combined with Phases 4 and 6, ensures all task types have scored results ready for aggregation in Phase 7.

## Design Constraints

- Writing submission must be async/non-blocking: same as Phase 4 (submit, queue, advance immediately). Write responses are queued with `scoring_status = PENDING` and processed by a scheduled poller.
- Writing scores must be stored in dedicated columns on `AttemptAnswer`: `essay_grammar_score`, `essay_vocabulary_score`, `essay_written_discourse_score`, `essay_spelling_score`, each in the range 0–100.
- Retry logic and vendor error handling must follow the same pattern as Phase 4 (exponential backoff, graceful degradation, audit logging).
- Scoring status and results are visible to students and admins once populated; PENDING vs. FAILED status must be clearly distinguished in reports.
- **Poller idempotency is mandatory**, same as Phase 4: use `SELECT ... FOR UPDATE SKIP LOCKED` when claiming PENDING rows so concurrent poller instances never process the same row twice.
- Essay text must be validated **before** it is sent to the vendor: reject (mark FAILED immediately, no vendor call) if the text exceeds a max length or contains invalid/unsanitizable content, so malformed input never wastes a vendor call.

## Steps

1. Extend the `AttemptAnswer` entity schema: add columns for Writing scores: `essay_grammar_score` (DECIMAL 0–100), `essay_vocabulary_score` (DECIMAL 0–100), `essay_written_discourse_score` (DECIMAL 0–100), `essay_spelling_score` (DECIMAL 0–100). Update the Flyway migration script (started in Phase 4) to include these new columns.

2. Implement a `WritingScoringPoller` Spring component (parallel to Phase 4's `SpeechScoringPoller`): runs every 5–10 seconds, claims `AttemptAnswer` rows with `scoring_status = PENDING` and `task_type IN (SUMMARIZE_WRITTEN_TEXT, ESSAY_WRITING, FILL_IN_BLANKS_WRITING)` using `SELECT ... FOR UPDATE SKIP LOCKED`. Batch process up to a configurable limit (e.g., 10 rows per poll).

3. Validate essay text before calling the vendor: reject (immediately set `scoring_status = FAILED`, no vendor call) if text exceeds the configured max length or fails a sanitization check (strip invalid unicode, reject binary/control characters). Otherwise, extract the essay text from `AttemptAnswer.response_content`, pass it to the essay-scoring vendor (selected in Phase 3) along with the task type and rubric context. Capture vendor response and extract the four enabling-skill scores (Grammar, Vocabulary, Written Discourse, Spelling). Map vendor score ranges to PTE 0–100 range.

4. Implement retry and error handling: on vendor API timeout or 5xx error, increment `retry_count`, set `next_retry_at` timestamp, re-queue for retry (same backoff pattern as Phase 4: 5s, 30s, 5min, then give up). On 4xx error (auth failure, invalid credentials) or malformed essay input, mark as FAILED immediately (no retry). On successful score, update `scoring_status = SCORED`, store the four scores, set `scored_at = now()`.

5. Implement a vendor API error handler and circuit-breaker: if the vendor is consistently unavailable (more than 10 consecutive failures), stop polling and log a critical alert. Implement the same stuck-job monitor as Phase 4: alert if PENDING Writing answers older than a configurable threshold exceed a configurable count, and provide an admin-triggered manual recovery action (mark `FAILED` with `ScoringUnavailable` reason). Document expected recovery procedure for ops (shared runbook with Phase 4, cross-referenced in Phase 9).

6. Implement task-level completion tracking: when a Writing task is scored, update a field on `ExamAttempt` or add a row to a task-scoring-status table to mark the task as complete (helps Phase 7 aggregation know which tasks have results).

7. Implement a `WritingScoreResult` DTO: when fetching scores for a report, include Writing task scores with their status (PENDING: "Scoring in progress"; SCORED: display all 4 sub-scores; FAILED: "Scoring unavailable, contact support").

8. Create integration and unit tests: test that a Writing task submission is queued immediately (latency <100ms), test that the polling loop processes PENDING answers, test vendor wrapper call and score extraction, test retry logic (mock vendor timeout → retry), test error handling (mock vendor auth failure → FAILED), test that scores appear in exam report.

## Success Criteria

- Writing task submission is queued with `scoring_status = PENDING` immediately on submit (latency <100ms); student advances to next task without waiting.
- The scheduled poller runs and processes PENDING Writing answers; within 1 minute, answers are either SCORED (with 4 essay sub-scores) or FAILED (with error details logged).
- Essay vendor wrapper is called, vendor response is parsed, and 4 enabling-skill scores (Grammar, Vocabulary, Written Discourse, Spelling) are extracted and stored correctly.
- Retry logic works: a transient vendor error (simulated timeout) triggers retry within 5–10 seconds; permanent error (simulated 400 Bad Request) marks as FAILED immediately.
- Exam report correctly displays Writing task scores (for SCORED answers) or status (for PENDING/FAILED answers).
- All `examdelivery` and `proctor` tests pass unchanged (zero regressions); Writing scoring is additive.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started (Unit tests for vendor wrapper, poller, retry logic, error handling; integration tests with vendor sandbox API if available; end-to-end test in Phase 9)

## Risks

- **HIGH: Essay Vendor Quality & Calibration** — Essay-scoring vendors may not align with PTE rubrics. A vendor's "grammar score" may not correlate with Pearson's standards. Students may receive scores that feel inaccurate or unfair. *Mitigation:* Phase 3 PoC must have tested vendor essay scores on sample PTE essays (hand-scored benchmark). If correlation is poor, implement a hybrid approach (vendor + manual review for low-confidence scores) or select a different vendor. Document limitations clearly.

- **MEDIUM: Essay Formatting & Encoding Issues** — Student essays may include special characters, unicode, emojis, or unusual formatting that the vendor doesn't handle well. Vendor may return error or produce gibberish scores. *Mitigation:* Sanitize and validate essay input before sending to vendor (strip invalid unicode, enforce max length). Test vendor with diverse character sets during Phase 3 PoC.

- **MEDIUM: Vendor Latency Under Load** — If vendor's API is slow (>10s per essay), the polling loop may fall behind. Essays may show PENDING scores hours after submission. *Mitigation:* Phase 3 PoC must measure vendor latency. If average latency is >5s, implement async vendor calls (submit and poll result later) rather than blocking in the poller. Document expected latency in Phase 9.

- **MEDIUM: Multiple Polling Loops** — Phase 4 has `SpeechScoringPoller`, Phase 5 has `WritingScoringPoller`. If both run frequently, database query load increases. *Mitigation:* Run both pollers on the same schedule (every 5–10s) from a single scheduled task. Monitor database query performance.

- **LOW: Timezone/Timestamp Issues** — Same as Phase 4 (use UTC for all timestamps).

