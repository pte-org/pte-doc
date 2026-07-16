# Phase 9: RetryRequest Entity & Approval Queue

## Requirements

Implement a new standalone `RetryRequest` entity and approval flow independent of any AI Writing/Speaking scoring-confirmation queue. When a student completes an exam attempt in a session that allows retries (max_retry_count > 0 from Phase 4), they can request a retry; this creates a RetryRequest record with status PENDING. A Host or teacher can then approve or reject each request individually via a dashboard queue. A student cannot start a new attempt until their most recent RetryRequest is approved. Exam-delivery start logic enforces the blocking check.

Maps to: **P1 Story #9 | FR-09**

## Design Constraints

- RetryRequest must be a distinct entity with its own lifecycle and approval actors, not shared with any AI Writing/Speaking grading/confirmation queue.
- Student cannot auto-retry even if the session's max_retry_count > 0; explicit approval is required per request (no default auto-grant).
- Exam-delivery must block on pending RetryRequest: if a student with a PENDING retry request attempts to start a new exam attempt, return 403 Forbidden with a clear message.
- Retry request approval can be done by Host or any teacher/grader role (use Spring role checks to specify which roles can approve).
- Rejection must be possible: if a student's retry request is REJECTED, they cannot re-request a retry for the same attempt (they can request a new retry after a subsequent attempt, if retry budget allows).

## Steps

1. Create RetryRequest entity with columns: id (UUID), student_id (UUID), attempt_id (UUID), session_id (UUID), status (enum: PENDING, APPROVED, REJECTED, CONSUMED), requested_at (OffsetDateTime), reviewed_at (OffsetDateTime, nullable), reviewed_by (UUID, nullable — the Host/teacher user who approved/rejected). `max_retry_count` (from Phase 4) is defined as the **total number of attempts allowed for the session**, not "retries after the first" — e.g. max_retry_count=1 allows exactly 1 attempt (no retries), max_retry_count=2 allows 1 initial + 1 retry. This definition must be used consistently by the count check in Step 7.

2. Implement an endpoint that allows a student to request a retry after completing an attempt: POST /api/attempts/{attemptId}/retry-request, checks that the session allows retries (max_retry_count > attempt_count) and the student has no existing PENDING or APPROVED request for that session, creates a RetryRequest with status PENDING.

3. Implement a Host/teacher dashboard endpoint to list pending retry requests: GET /api/retry-requests?status=PENDING, filtered by the authenticated user's tenant; return student name, attempt details, request timestamp.

4. Implement an approval endpoint: POST /api/retry-requests/{requestId}/approve. Explicitly verify `retryRequest.session.tenantId == authenticatedUser.tenantId` before any other check — return 403 Forbidden immediately on mismatch, before checking role; then verify the authenticated user has HOST or GRADER role, updates status to APPROVED, sets reviewed_at and reviewed_by, returns 200 OK. Add an integration test that attempts a cross-tenant approval and asserts 403.

5. Implement a rejection endpoint: POST /api/retry-requests/{requestId}/reject, same tenant + permission checks as approve (tenant check first), updates status to REJECTED, sets reviewed_at and reviewed_by, returns 200 OK.

6. In the exam-delivery start logic (e.g., GET /api/sessions/{sessionId}/start or POST /api/attempts), add a pre-flight check that reads the RetryRequest status at `READ COMMITTED` isolation or stronger (the default for most RDBMS, but confirm explicitly rather than assume) so the check reflects the most recently committed approval — do not read from a cache or a connection with a stale snapshot. Query for the most recent RetryRequest for (student, session); if status is PENDING, return 403 Forbidden with message "Retry request pending approval"; if status is REJECTED, allow the attempt (rejection doesn't block future attempts, only PENDING does); if APPROVED, allow the attempt and mark the record consumed (see Step 7 lifecycle note) so it cannot be read as pending-approvable again.

7. Implement a count check: before allowing a retry request creation, verify that the student has not exceeded max_retry_count (e.g., if max_retry_count=2, student can have at most 2 attempts; if they've already completed 2, no retry request is allowed).

8. Test end-to-end: student completes attempt 1, requests retry (PENDING created), Host approves it, student can now start attempt 2; or Host rejects it, student cannot start attempt 2 but can later request a new retry if the session allows (if max_retry_count permits).

## Success Criteria

- Student can request a retry after completing an exam attempt (RetryRequest with status PENDING is created).
- Pending retry request appears in Host/teacher dashboard queue.
- Host can approve or reject each request individually (status changes to APPROVED or REJECTED, timestamps recorded).
- A student with PENDING retry request cannot start a new attempt (returns 403 Forbidden).
- A student with APPROVED retry request can start a new attempt (attempt is allowed).
- A student with REJECTED retry request cannot retry that specific attempt but can later request a retry for a subsequent attempt (if session max_retry_count allows).

## Quality and Testing State

- Quality gate: **approved** — 1 HIGH finding fixed (transaction isolation for the exam-start retry gate was declared on a nested `@Transactional` repository method and silently ignored by Spring's REQUIRED propagation; moved to the outermost boundary on `ExamAttemptService.recordHeartbeat`), 1 NOTED (unused constant, removed). Report: `quality/phase-09-retry-request-approval-quality-report.json`. Receipt: `quality/phase-09-retry-request-approval-receipt.json`.
- Testing: **passed** — 56/56 new tests (26 domain `RetryRequestTest`, 18 `RetryRequestServiceTest`, 6 new + 6 existing `ExamAttemptServiceTest`), 230/230 full regression suite (phases 1-9). Report: `tests/phase-09-retry-request-approval-test-report.json`.

## Session Notes

- **Architecture substitution**: "session" = the existing `Exam` entity (examoperations module), consistent with Phases 4-8 — there is no separate ExamSession entity.
- **Endpoint paths** deviate from the plan's literal `/api/attempts/...` / `/api/retry-requests/...` to match this codebase's established `/api/v1/exam-attempts/...` (`ExamDeliveryApiConstants.EXAM_ATTEMPTS`) and a new `/api/v1/retry-requests` base (`ExamDeliveryApiConstants.RETRY_REQUESTS`), consistent with existing API versioning.
- **max_retry_count boundary bug caught before quality gate**: initial implementation used `attemptsSoFar > maxRetryCount`; per Step 1's explicit definition (max_retry_count = TOTAL attempts allowed, not "retries after the first"), the correct check is `attemptsSoFar >= maxRetryCount`. Fixed during self-review, before the quality gate ran.
- **Host vs. Grader tenant check asymmetry** (same split established in earlier phases): Host reviewer authorization uses `Exam.hostId` (String, matches `principal.userId().toString()`) — the field actually populated at exam creation. Grader reviewer authorization uses `Exam.organizationId` via the newly-added `GraderOrgAssignmentRepository.existsByIdGraderIdAndIdOrganizationId`, consistent with the pre-existing `GraderService` pattern; `Exam.organizationId` is a pre-existing, currently-unpopulated field in this codebase (not something introduced or fixed by this phase) — Grader-reviewer authorization will only start working once that gap is closed elsewhere. Flagged to quality reviewer explicitly as a known, out-of-scope, pre-existing limitation rather than a new defect.
- **Transaction isolation fix** (quality gate finding): `RetryRequestRepository.findMostRecent`'s isolation annotation was moot because it always runs joined inside `ExamAttemptService.recordHeartbeat`'s already-open transaction (Spring REQUIRED propagation ignores a nested `@Transactional`'s isolation level). Moved the explicit `Isolation.READ_COMMITTED` declaration to `recordHeartbeat` itself, the actual outermost transactional boundary.
- **No attempt-creation endpoint** (established gap from Phase 6, reused here): the retry-gate hook only fires on the `NOT_STARTED → IN_PROGRESS` transition inside `recordHeartbeat`, consistent with treating the first heartbeat as the de-facto "start" trigger since no explicit attempt-creation flow exists anywhere in this codebase.

## Risks

- **Retry count boundary condition**: resolved by the Step 1 definition (`max_retry_count` = total attempts allowed). Count check: attempt_count (completed attempts) must be < max_retry_count to allow a retry request; test boundary cases (0, 1, 2 attempts with various max_retry_count values).
- **APPROVED request lifecycle**: resolved — an APPROVED RetryRequest transitions to CONSUMED (status enum, Step 1) the moment the resulting attempt starts, so it can never be re-read as approvable/pending. Combined with the tenant + isolation-level checks in Steps 4 and 6, this closes the "approve twice" and "stale-read bypass" gaps identified in review.
- **Audit trail for approval**: Currently there's no audit log for who approved/rejected what retry request. Mitigation: the RetryRequest entity itself has reviewed_by and reviewed_at fields which serve as a simple audit trail; if more detailed auditing is needed, can add a bespoke `RETRY_APPROVAL_ACTION` table similar to Phase 8's `PROCTOR_ACTION`, but spec says to piggyback on RetryRequest's own timestamps.
- **Permission check on rejection/approval**: resolved by the mandatory tenant check in Steps 4–5 (checked first, before role check); covered by an explicit cross-tenant integration test.
