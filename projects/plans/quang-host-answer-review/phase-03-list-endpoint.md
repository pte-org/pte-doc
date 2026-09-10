# Phase 3: List Endpoint

## Requirements

Implement a tenant-scoped, paginated, filterable `GET /answers` endpoint (or similar, following scoring's URI conventions) that allows HOST_ADMIN and HOST_AUTHOR users to list their tenant's submitted answers by session and/or status (PENDING/SCORED). The response is a page of answer summaries (not full payloads) so that hosts can navigate large answer sets efficiently. This endpoint unblocks the host's ability to choose which answer to review in detail.

## Design Constraints

- **Scoring service ownership:** The list endpoint lives in ScoringReviewController, extending the existing review capability (not a separate controller).
- **Tenant isolation enforced in service layer:** Use CurrentUserContext to extract the calling host's tenantId; filter all queries by tenantId in ScoringAnswerRepository, never on the client side. A malicious or misconfigured host must not be able to fetch another tenant's answers.
- **RBAC via @PreAuthorize:** Use `@PreAuthorize("hasAnyRole('HOST_ADMIN','HOST_AUTHOR')")` matching the existing ScoringReviewController pattern.
- **Pagination:** Choose pagination strategy (keyset-based like InternalExportController, or simpler offset-page) and document rationale in the endpoint's javadoc. Keyset is preferred for large datasets (avoids skip-cost); offset-page is simpler but slower at high page numbers.
- **Filter constraints:** At minimum, filter by sessionPublicId (e.g., "show me all answers from exam session XYZ") and/or status (PENDING, SCORED). Additional filters (task type, student name) are out of scope for this phase but DTO must allow extension.

## Steps

1. **Add query methods to ScoringAnswerRepository** — Extend ScoringAnswerRepository with finder methods, e.g., `findBySessionPublicIdAndTenantIdAndStatusOrderByCreatedAtDesc()` and overload variants for different filter combinations. Ensure all queries include `tenantId` in the WHERE clause to prevent cross-tenant leaks. Consider adding a database index on (tenantId, sessionPublicId, status) for query performance.

2. **Implement pagination strategy selection** — Decide between keyset (cursor-based) and offset-page pagination. If keyset, define a cursor object (e.g., "createdAt descending, then answerPublicId"). If offset-page, use Spring's Pageable. Document the choice with a brief rationale.

3. **Create ScoringAnswerListResponse DTO** — Design a lightweight response that includes answerPublicId, sessionPublicId, studentId or studentName (if available in ScoringAnswer), taskType, status, rawScore, and createdAt. Omit the full payload (decoded or raw) to keep the response small and fast. Include pagination metadata (currentPage, totalCount, nextCursor or hasNextPage).

4. **Implement ScoringReviewService.listAnswers()** — Write the service method that calls the repository, passes through the tenantId from CurrentUserContext, and maps the results to the response DTO. Add a log at DEBUG level when a host lists answers (include tenantId, sessionPublicId, filter values, and result count for observability).

5. **Add GET /answers controller endpoint** — Add a method to ScoringReviewController that accepts @RequestParam filters (sessionPublicId, status, pageable or cursor token) and calls ScoringReviewService.listAnswers(). Return HTTP 200 with the paginated list. Document required and optional parameters in the javadoc.

6. **Implement filter validation** — If a host passes an invalid status value (e.g., "INVALID_STATUS"), return HTTP 400 with a clear error message rather than silently ignoring. Add a simple validator (e.g., @Valid @RequestParam Enum<Status> status) or manual validation in the controller.

7. **Add integration tests for tenant isolation and filtering** — Write tests that create ScoringAnswers in two different tenants, then verify that a HOST_ADMIN user from tenant A only sees their own tenant's answers even when listing all answers (no explicit filter). Test that filtering by sessionPublicId and status works correctly.

## Success Criteria

- `GET /answers` returns a 200 response with a list of answers and pagination metadata.
- Endpoint enforces `@PreAuthorize("hasAnyRole('HOST_ADMIN','HOST_AUTHOR')")` and rejects unauthenticated requests with 401.
- Endpoint enforces tenant isolation: a host from tenant A cannot see answers from tenant B even by omitting filters.
- Endpoint supports filters by sessionPublicId and status (optional parameters).
- Response DTO is JSON-serializable and includes all required fields (answerPublicId, taskType, status, score, etc.).
- Integration test suite includes at least one cross-tenant isolation test and one test per supported filter combination.

## Quality and Testing State

- Quality gate: **approved** (0 blocking, 1 LOW found and fixed inline — negative `page` param would 500 via an uncaught `IllegalArgumentException`; clamped via a `boundedPage()` helper mirroring the existing `boundedSize()`). Pagination choice: Spring Data offset `Page`/`Pageable`, not `InternalExportController`'s keyset cursor — different access shape (interactive single-tenant screen vs. system-to-system full-tenant export), not an inconsistency. Report: `quality/phase-03-list-endpoint-quality-report.json`. Receipt skipped (cross-repo boundary).
- Testing: **not started** — user declined unit tests for this phase onward.

## Risks

- **HIGH: Tenant leak through pagination cursor/offset** — If pagination cursor includes encoded data without tenantId, an attacker could forge a cursor for another tenant. Mitigation: If using keyset pagination, cursor must be an opaque token that doesn't need to encode tenantId (tenantId always comes from CurrentUserContext, never trusted from the cursor). If using offset-page, Spring's Pageable is safe, but enforce tenantId in the query regardless.

- **HIGH: Unindexed query on large ScoringAnswer table** — If the new finder method is not indexed, it will do a full table scan on a large tenant's answers. Mitigation: Add database index on (tenantId, sessionPublicId, status, createdAt) before Phase 3's integration tests. Monitor query performance; if >100ms, investigate index stats.

- **MEDIUM: Response size explosion at high pagination limits** — If a host requests a huge page size, the response is large and slow. Mitigation: Cap page_size at 100 (or a configurable limit) in the controller. Document the limit in the API contract.

- **MEDIUM: Status filter accepts invalid enum values** — If validation is missing, a host can pass a typo'd status and the query might silently filter to zero results, confusing the host. Mitigation: Use Spring's enum validation (implicit enum parsing, which throws 400 on invalid value) or manual validation with clear error message.

- **LOW: createdAt timestamp precision** — If two answers have identical createdAt (unlikely but possible at scale), keyset cursor is ambiguous. Mitigation: If using keyset, include answerPublicId in the sort order (createdAt DESC, then answerPublicId DESC) to break ties.
