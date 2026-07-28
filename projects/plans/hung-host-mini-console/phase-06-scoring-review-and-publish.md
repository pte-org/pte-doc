# Phase 6: Scoring Review & Publish

## Requirements

Let a Host administrator request scoring for a session, let authorized Host
reviewers list tenant/session-scoped essays in
`AI_SCORED_PENDING_REVIEW`, approve an individual review, and let a Host
administrator publish results after backend gates pass. Add the one confirmed
missing backend contract: the pending-review list query.

Maps to: **P1 Story #7 (score, review, publish) | FR-12, FR-13, FR-14, FR-15,
FR-17, FR-18**

## Design Constraints

- Create a standalone Flutter `scoring_review` feature. It may receive a session
  public ID from scheduling navigation but must not import scheduling BLoCs or
  repository implementations.
- Score request and result publication continue through scheduling-service;
  pending-review list and individual review use scoring-service.
- Score request/publish are `HOST_ADMIN` actions. Individual review retains the
  backend's current `HOST_ADMIN`/`HOST_AUTHOR` authorization.
- Add
  `GET /api/scoring/answers/reviews?sessionPublicId={id}&status=AI_SCORED_PENDING_REVIEW&page={n}&size={n}`
  to the existing `ScoringReviewController`.
- The new service query always constrains session, caller tenant, and exact
  reviewable status. Cross-tenant denial is indistinguishable from no accessible
  result/resource and never leaks ownership.
- Add a scoring-local page response record (`items`, `page`, `size`,
  `totalElements`, `totalPages`) rather than introducing an unreviewed
  cross-service common pagination abstraction.
- Replace the existing non-pageable repository method for this UI path with a
  tenant-aware `Pageable` query; do not load all answers then filter in memory.
- Review approval is not optimistic. On success the Flutter queue reloads from
  the backend.
- Score, review, and publish commands are explicit, single-flight, and never
  automatically retried.

## Steps

1. Re-check scheduling score/publish role annotations and scoring answer status,
   response DTO, review service, repository indexes, and tenant semantics.
2. Reconfirm the backend query contract documented in this phase before Java
   changes; keep this `pte-doc` phase as the single planning source rather than
   duplicating a phase plan inside `pte-api`.
3. Add a scoring-local paginated response record containing
   `List<ScoringAnswerResponse> items`, requested page/size, total elements, and
   total pages.
4. Add a tenant/session/status/pageable Spring Data query to
   `ScoringAnswerRepository`, with deterministic ordering by creation/id fields
   confirmed from the entity.
5. Add a read-only `ScoringReviewService.listPending(...)` path that accepts only
   `AI_SCORED_PENDING_REVIEW`, applies caller tenant scope, maps entities to the
   existing safe response DTO, and returns page metadata.
6. Add the controller GET mapping with validated UUID/status/page/size,
   `ApiResponse` envelope, bounded page size, and existing Host role guard.
7. Compile/package `scoring-service`; verify contract cases for Host admin,
   Host author, cross-tenant session, invalid status, empty page, populated page,
   bounds, and deterministic ordering. Record commands/responses.
8. Define Flutter scoring-review domain entities, page type, repository, and
   use cases for request score, list pending reviews, approve review, and
   publish results.
9. Implement gateway repositories with exact query/body/path tests and
   distinction between forbidden, not found, conflict, validation, and network
   failures.
10. Build score-request/publish command states and a pageable review-queue BLoC
    with loading, empty, loaded, loading-more, refreshing-after-review, and
    failure states.
11. Build the session scoring page: admin-only score/publish actions, pending
    review cards, pagination, review confirmation, post-review reload, and
    backend gate/conflict feedback.
12. Add backend contract evidence plus Flutter model/repository/BLoC/widget
    tests; run scoring-service package, all Flutter regressions, analysis, full
    suite, and a bounded score → list → review → publish runtime check.

## Success Criteria

- [x] The new GET endpoint returns only the caller tenant's answers for the
      requested session and exact pending-review status.
- [x] Pagination has bounded size, deterministic ordering, and correct totals;
      invalid status/bounds are rejected.
- [x] Cross-tenant access leaks no answer/session ownership information.
- [x] `HOST_ADMIN` can request scoring and publish; `HOST_AUTHOR` is not shown
      those admin-only actions.
- [x] Authorized Host reviewers can list and approve pending essays using the
      existing individual review command.
- [x] Successful approval reloads authoritative queue state; no optimistic score
      mutation remains.
- [x] Publish conflicts/gates are displayed without false success or automatic
      retry.
- [ ] Scoring-service package/contract checks, Phase-6 Flutter tests, prior
      regressions, analysis, and full suite pass.

## Quality and Testing State

- Quality gate: deterministic source gates approved; the runtime check remains
  pending because no Docker services are running. The canonical phase summary is
  recorded at
  `quality/phase-06-scoring-review-and-publish-quality-report.json`. Flutter
  source review artifacts belong under
  `pte-app/plans/hung-host-mini-console/quality/`; backend source review
  artifacts belong under `pte-api/plans/hung-host-mini-console/quality/`.
- Testing: backend package/unit contracts, five focused Flutter tests, analysis,
  and the complete 287-test Flutter suite pass. Command evidence is recorded in
  `tests/phase-06-scoring-review-and-publish-test-report.json` in `pte-doc`;
  implementation repositories do not duplicate the test plan/report.

## Risks

- **HIGH:** A session-only repository query can expose another tenant's pending
  reviews. Mitigation: tenant is part of the database predicate, not an
  in-memory after-filter.
- **HIGH:** Publishing before all review-required answers become final can
  release incomplete reports. Mitigation: scheduling/reporting backend gate is
  authoritative; Flutter never bypasses or predicts it.
- **MEDIUM:** No shared pagination response convention currently exists.
  Mitigation: keep the record scoring-local for this requirement and avoid a
  platform-wide abstraction.
- **MEDIUM:** Scoring completion is asynchronous after the scheduling command.
  Mitigation: show request acknowledgement and refreshable review state rather
  than inventing a progress percentage/status endpoint.
