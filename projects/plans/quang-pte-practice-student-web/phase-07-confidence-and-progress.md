# Phase 7 — Confidence Persistence and Progress Read Model

## Objective

Persist confidence with each answered item and expose honest, student-scoped practice Progress without changing correctness semantics or hiding historical data after entitlement revocation.

## Story mapping

- P1: confidence capture, read-only Progress, empty state and history after revoke.
- P2: confidence controls and progress visualizations are responsive/accessibility-reviewed.
- P3: no Leaders or future analytics surfaces.

## Scope

- Verify the `LOW`, `MEDIUM`, `HIGH` confidence enum and additive answer
  persistence/API field defined in Phase 03; this phase must not introduce a
  late runtime contract.
- Require confidence for answered items before advance/submit; skip remains confidence-free.
- Dismissible first-use confidence explanation, separate from answer correctness.
- Progress projection for no history, draft, completed practice and historical results.
- Preserve history after plan expiry/suspension, student deactivation/removal or current organization entitlement loss.

## Exact files/areas likely changed

- Existing attempt answer entity/DTO/service areas associated with `AttemptLifecycleService.java` and `SubmitAnswerRequest.java`; exact entity path is verified during implementation.
- Existing reporting areas `pte-api/app/src/main/java/com/pte/reporting/internal/controller/ReportController.java` and `ReportService.java` only if an adapter is safe; otherwise new practice progress controller/service/read model under the approved practice/reporting ownership.
- Additive `pte-api/app/src/main/resources/db/migration/` migration for confidence/status/progress projection where required.
- `pte-practice` confidence controls, onboarding state, session submit integration, Progress route/cards/charts/empty state.
- `pte-doc` confidence/progress contract and retention matrix.

## Dependencies

- Phase 03 answer/session contract.
- Phase 05 submit/skip shell.
- Phase 06 text/media response lifecycle.
- User confirmation of scoring boundary from Phase 01.

## Implementation steps

1. Verify persisted confidence enum and additive request/response mapping from Phase 03.
2. Verify the server-side confidence policy for answered task types and define timer expiry behavior explicitly.
3. Keep correctness/scoring pipeline independent; write regression tests that vary confidence while holding payload/correctness constant.
4. Build practice progress projection keyed by student and explicit org/session ownership, using `NO_HISTORY`, `IN_PROGRESS`, `COMPLETED_PENDING_SCORE`, `COMPLETED_SCORED` and `SCORING_FAILED`.
5. Preserve completed history after entitlement revoke; block only new practice mutations.
6. Add the dismissible onboarding state and per-answer Low/Medium/High controls.
7. Add reload/resume/duplicate-submit/retry tests proving confidence survives the lifecycle.

## Acceptance criteria

- All three confidence levels persist and reload correctly.
- Answer advance/submit without confidence is rejected with a stable machine state; skip succeeds without confidence.
- Confidence never changes correctness or scorer input semantics.
- Progress is read-only, privacy-scoped, empty when no history exists and historical after revoke/deactivation/removal.
- A draft is not presented as a completed score/report.
- Duplicate submit is idempotent and does not create duplicate progress events.

## Design Constraints

- Confidence is a response signal, not a score, entitlement or completion substitute.
- Do not reuse official published-report semantics for practice unless the adapter proves equivalent ownership/history behavior.
- No client-only confidence persistence as the source of truth.
- Keep historical rows; use forward-compatible projection repair rather than destructive cleanup.

## Quality and Testing State

- Quality: **Not evaluated**.
- Testing: **Not started**.
- Planned evidence: migration/entity tests, confidence contract tests, progress aggregation/ownership tests, revoke-history tests and Playwright confidence/resume/Progress flows.
