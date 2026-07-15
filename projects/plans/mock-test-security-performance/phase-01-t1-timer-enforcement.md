# Phase 1 (Track 1): Server-Side Timer Authority

**Track:** 1 — Exam Integrity & Anti-Cheat
**Covers:** FR-01 · User story: P1 (server-enforced timer)
**Depends on:** nothing — can start immediately in parallel with Track 4 Phase 1

---

## Design Constraints

- Client-reported `timeRemaining` is advisory-only for UI. It must never be the value that gates submission acceptance.
- Use a **signed, short-lived time token** issued at exam start: `{examId, attemptId, startTime, expiryTime, signature}` (HMAC over the payload using a server secret). Not a naive "compare `now()` to `createdAt` on every request" — that breaks the existing offline-first mobile flow, which continues answering locally while briefly disconnected.
- Allow a **30-60s offline grace window**: if the client reconnects within the grace window past `expiryTime`, the submission is still accepted, but flagged with `submittedAfterGrace: true` in the audit metadata (once Track 4 Phase 1 lands — otherwise log locally and backfill).
- `Exam.duration` must be captured immutably on `ExamAttempt` creation (don't compute from a mutable `Exam` reference — if exam duration changes later, in-progress attempts must not be affected).

## Files to Touch

- `aptis-api/src/main/java/com/aptis/modules/examdelivery/domain/ExamAttempt.java` — add `startTime`, `expiryTime`, `timeToken` fields (or compute token on demand from `startTime`+duration).
- `aptis-api/src/main/java/com/aptis/modules/examdelivery/service/ExamAttemptService.java` — add timer validation before accepting `submitAnswer`/`submitExam`; add token issuance on attempt creation.
- `aptis-api/src/main/java/com/aptis/common/security/TimeTokenService.java` — new: signs/validates time tokens (HMAC-SHA256).
- `aptis-app/lib/features/exam_delivery/presentation/bloc/exam_attempt_bloc.dart` — store/display server-issued `expiryTime` for UI countdown; stop relying on local-only timer as source of truth for submission gating.
- `aptis-api/src/main/java/com/aptis/common/exception/` — new `ExamTimeExpiredException` mapped in `GlobalExceptionHandler`.

## Implementation Steps

1. Implement `TimeTokenService` — issue and validate HMAC-signed tokens containing `attemptId`, `startTime`, `expiryTime`.
2. On `ExamAttempt` creation, capture `startTime` and immutable `durationSeconds` (copied from `Exam` at creation time, not a live reference); compute `expiryTime`.
3. Return the signed time token (or its constituent `expiryTime`, if signature is verified server-side only) in the attempt-start response DTO.
4. In `submitAnswer`/`submitExam`, validate server time against `expiryTime` + grace window; reject with `ExamTimeExpiredException` (409) if past grace window.
5. Add scheduled job (Spring `@Scheduled`) to auto-submit any `IN_PROGRESS` attempt past `expiryTime` + grace window that the client never explicitly submitted.
6. Update Flutter `ExamAttemptBloc` to use server `expiryTime` for its countdown display instead of a purely local timer.
7. Unit + integration tests: submission accepted within duration, rejected past duration + grace, accepted within grace window with `submittedAfterGrace` flag.

## Acceptance Criteria

- [ ] Submitting past `expiryTime` + grace window is rejected server-side regardless of client-reported time — verified by test with a manipulated client timestamp.
- [ ] Submitting within the grace window succeeds but is flagged.
- [ ] Auto-submit job closes out attempts abandoned past expiry + grace.
- [ ] Maps to spec success criterion: "Server rejects submission attempts past allotted exam duration, independent of client clock, verified by test."

## Quality and Testing State

- Quality: not evaluated
- Testing: not started
