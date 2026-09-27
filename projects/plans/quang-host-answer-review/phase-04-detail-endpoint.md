# Phase 4: Detail Endpoint and RBAC Enforcement

## Requirements

Implement a tenant-scoped `GET /answers/{answerPublicId}` endpoint that returns the full answer review DTO with decoded payload, option text (from optionsJson), and presigned media URLs for audio/image answers. This is the host's primary interface for inspecting what a student answered — both to sanity-check the AI score and, per Phase 5, to independently grade it themselves via `teacherScore`. RBAC and tenant isolation must be enforced such that a host can only view answers from their own tenant, and only if they have HOST_ADMIN or HOST_AUTHOR role.

## Design Constraints

- **Scoring service ownership:** Detail endpoint lives in ScoringReviewController; no cross-service calls except MediaClient presigning (which scoring now owns via Phase 1).
- **Tenant isolation enforced in service layer:** ScoringReviewService.getAnswerForReview(answerPublicId) must extract tenantId from CurrentUserContext and verify that the fetched ScoringAnswer.tenantId matches. If mismatch, return 404 (never a 403 that would confirm the answer/tenant exists — mirrors ReportService's own denial-path rule in reporting).
- **Tenant ID is not in the URI:** answerPublicId is just a UUID; tenantId is derived from the authenticated host's context. This prevents a host from trying to access another tenant's answer by guessing a UUID.
- **RBAC via @PreAuthorize:** Use `@PreAuthorize("hasAnyRole('HOST_ADMIN','HOST_AUTHOR')")` matching the existing ScoringReviewController pattern.
- **Media presign fallback:** If MediaClient.presignGet fails (network error, media not found), log at WARN and return the response with mediaPublicId as-is (omit the signed URL field). Do not fail the entire endpoint; media access is a convenience, not a blocker for review.
- **Hard mode quality:** All new integration test paths (especially cross-tenant fetches and 404 scenarios) must pass before this phase is signed off.

## Steps

1. **Implement ScoringReviewService.getAnswerForReview(answerPublicId)** — Service method that fetches the ScoringAnswer by answerPublicId, verifies tenantId matches CurrentUserContext.getTenantId(), and throws a custom exception (e.g., AnswerNotFoundException) if not found or unauthorized. Log at DEBUG the fetch attempt (include answerPublicId, tenantId).

2. **Decode and enrich the answer payload** — Call AnswerPayloadDecoder.decode(answer.payload, answer.taskType) from Phase 2 to convert raw payload to a human-readable DTO. Populate the AnswerReviewResponse with the decoded payload, option text (looked up from optionsJson), correct answer text (if task type supports it), and taskType-specific metadata.

3. **Presign media URLs for audio/image task types** — If payload is a mediaPublicId (detected by taskType), call MediaClient.presignGet(mediaPublicId) and include the signed URL in the response. If MediaClient throws an exception, log at WARN and continue (presigned URL field is omitted or null; host can retry).

4. **Create AnswerReviewDetailResponse DTO** — Design the final response shape with all fields needed for a host to understand the answer: answerPublicId, sessionPublicId, studentIdentifier, taskType, status, rawScore, decodedPayload (variant per task type), optionTexts (if applicable), correctAnswerText, mediaSignedUrl (if applicable), createdAt, etc. Document each field in javadoc.

5. **Add GET /answers/{answerPublicId} controller endpoint** — Add a method to ScoringReviewController that accepts the answerPublicId path variable and calls ScoringReviewService.getAnswerForReview(). Map the exception to HTTP 404 as appropriate. Return HTTP 200 with the AnswerReviewDetailResponse.

6. **Implement cross-tenant access test** — Write an integration test that creates a ScoringAnswer in tenant B, authenticates as a HOST_ADMIN user from tenant A, and attempts to fetch the answer. Verify the endpoint returns 404 and does not leak the answer content or tenant existence.

7. **Implement success path integration test** — Write an integration test that creates a ScoringAnswer in the authenticated user's tenant, fetches it via GET /answers/{answerPublicId}, and verifies the response includes decoded payload, option text, score, and (if audio) a presigned media URL.

8. **Add RBAC denial test** — Write an integration test that authenticates as a user without HOST_ADMIN or HOST_AUTHOR role (e.g., STUDENT), attempts to fetch an answer, and verifies the endpoint returns 401 or 403.

## Success Criteria

- `GET /answers/{answerPublicId}` returns HTTP 200 with AnswerReviewDetailResponse for an authorized host fetching their own tenant's answer.
- Endpoint enforces `@PreAuthorize("hasAnyRole('HOST_ADMIN','HOST_AUTHOR')")` and rejects unauthorized roles with 401/403.
- Endpoint enforces tenant isolation: a host from tenant A cannot fetch an answer from tenant B (cross-tenant test passes with 404).
- Decoded payload is correct for all supported task types (multiple-choice, essay, audio, etc.; verified by integration tests using fixtures from Phase 2).
- Option text is populated from optionsJson where applicable; missing optionsJson is handled gracefully (endpoint returns indices only, no error).
- Media presign is called for audio/image task types; if it succeeds, the response includes a signed URL; if it fails, the response gracefully omits it (WARN logged).
- Integration test suite covers success path, cross-tenant denial, RBAC denial, and presign failure handling.

## Quality and Testing State

- Quality gate: **approved** (0 findings). `getAnswerForReview` reuses the existing `findOwned` helper (already tenant-scoped, already 404-not-403) rather than duplicating denial logic. Report: `quality/phase-04-detail-endpoint-quality-report.json`. Receipt skipped (cross-repo boundary).
- Testing: **not started** — user declined unit tests for this phase onward.

## Risks

- **HIGH: Tenant isolation not enforced in service layer** — If tenantId check is missing from ScoringReviewService.getAnswerForReview, a malicious host can enumerate cross-tenant answers by UUID brute-force. Mitigation: add an explicit assertion or guard clause that checks tenantId before returning; add a cross-tenant integration test that fails if the check is missing.

- **HIGH: Decoded payload exposes sensitive information** — If decoders are not careful, they might expose essay answer text or audio metadata that should be redacted for certain roles. Mitigation: the current design assumes HOST_ADMIN and HOST_AUTHOR can see full answers (their job is to review). If a future role needs list-but-not-view access, that's a separate feature with its own RBAC logic.

- **MEDIUM: MediaClient presign timeout blocks the endpoint** — If the media service is slow or unreachable, the detail endpoint hangs while waiting for MediaClient. Mitigation: Set a timeout on MediaClient.presignGet (e.g., 2 seconds) and catch TimeoutException. Log at WARN and return the response without the signed URL.

- **MEDIUM: optionsJson is null or corrupted** — If optionsJson is missing, the response will have empty or null optionTexts. Mitigation: Document this in the API response (optionTexts field can be null); host client can fall back to displaying indices.

- **MEDIUM: Concurrent approval and detail fetch race condition** — If a host views an answer, then simultaneously another process approves it, the detail response might show status=PENDING while the actual status is APPROVED. Mitigation: ScoringAnswer is eventually consistent (built from the outbox, not real-time). Document in the endpoint's javadoc that status is not a guarantee.

- **LOW: Answer-not-found error message leaks information** — Mitigation: use a generic 404 "Answer not found" message for both "doesn't exist" and "belongs to another tenant" cases.
