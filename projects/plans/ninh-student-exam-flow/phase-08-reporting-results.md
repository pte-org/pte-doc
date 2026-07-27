# Phase 8: Reporting/Results

## Requirements

Build the report screen backed by `GET /api/reporting/reports/attempts/{id}`: a 404 response renders a "waiting for host to publish" state — never an error banner, never a retry-with-backoff loop — since the contract deliberately cannot distinguish "not yet published" from "not found/not owned," and the client must treat both identically rather than attempt to reverse-engineer which. Nullable per-skill `score` combined with `sufficientData:false` renders an explicit "insufficient data" state, never a blank or zero-valued score — the distinction between "no data" and "a score of zero" matters directly to the student reading it.

Maps to: **P1 Story #8 ("see my report after the host publishes it, and a clear 'not yet published' state before that") | FR-12**

## Design Constraints

- `ReportBloc` is read-only and has no dependency on Phase 2's outbox/sync machinery — reporting is a pure fetch-and-render concern, structurally simpler than every prior phase's `Bloc`.
- States: `ReportLoading`, `ReportNotPublished`, `ReportReady(ReportResponse)`, `ReportError` — four separate immutable classes, no boolean-flag shape. `ReportError` is reserved for genuine failures (network error, 5xx, malformed response) — a 404 is explicitly **not** routed to `ReportError` under any circumstance, per the confirmed backend behavior that `REPORT_NOT_FOUND` covers both "not yet published" and "not owned" indistinguishably (verified directly in `pte-api`'s `reporting` service: a dedicated `ReportNotFoundException` maps to this single 404 code for both cases). Since a student can only ever legitimately query their own attempt's report through this flow, "not owned" is not a case this client needs to handle differently even if it were distinguishable — routing 404 uniformly to `ReportNotPublished` is correct, not a workaround.
- No retry-with-backoff loop on 404 — a "not published yet" state does not imply the client should keep hammering the endpoint. A manual refresh affordance (pull-to-refresh, a refresh button) is appropriate; an automatic exponential-backoff retry loop is not, since 404 is an expected, stable, non-transient response here, unlike the 429/`RateLimitException` backoff logic Phase 7 built for the answer-submission path — do not reuse that backoff pattern here, it solves a different problem.
- Per-skill rendering: `{skill, score (nullable, 10–90), sufficientData (bool)}` — when `sufficientData` is `false`, render "insufficient data" regardless of whatever `score` happens to contain (even if it's non-null but the server still marked insufficient data, treat `sufficientData` as the authoritative signal, not `score`'s nullness, since the two could in principle disagree and the explicit flag is the more direct signal of intent). When `sufficientData` is `true` and `score` is present, render the numeric score plainly — never coerce a present score toward zero/blank for display consistency with the insufficient-data case; the two states must look visually distinct, not just textually different, so a student scanning quickly doesn't mistake one for the other.
- `overall`, `communicativeSkills[]`, and `enablingSkills[]` are rendered as separate sections per `ReportResponse`'s shape — this phase does not need to invent additional grouping/derived metrics beyond what the response already provides.
- `published`/`publishedAt` fields on a successfully-fetched (200) `ReportResponse` are informational display fields only — reaching `ReportReady` at all already implies the report is fetchable; do not build a second not-published check against these fields on top of the 404-based one, since a 200 response reaching the client is already the server's confirmation that it's visible to this student.

## Steps

1. Define the domain `ReportResponse` model matching the full field set (`attemptPublicId, sessionPublicId, published, publishedAt, overall, communicativeSkills[], enablingSkills[]`), each skill entry as `{skill, score (nullable int, 10–90), sufficientData}`.
2. Implement `ReportRepository.fetchReport(attemptPublicId)` → `GET /api/reporting/reports/attempts/{id}`, mapping a 404 to a distinct return signal (e.g. returning `null`/a sealed `ReportFetchResult` rather than throwing an exception the `Bloc` has to inspect and re-classify) so `ReportBloc` doesn't need its own ad hoc "is this 404 actually fine" branching logic duplicated from the repository.
3. Implement `ReportBloc`: sealed events (`ReportRequested`, optionally `ReportRefreshRequested` for the manual-refresh affordance); states `ReportLoading → ReportNotPublished | ReportReady(ReportResponse) | ReportError`, with the 404-signal from Step 2 routing to `ReportNotPublished` and any other failure routing to `ReportError`.
4. Build the report screen: a "waiting for host to publish" view (for `ReportNotPublished`) distinct in tone/content from a generic error view (for `ReportError`) — these must not share a single generic "something went wrong, tap to retry" widget, since one is an expected steady state and the other is not.
5. Build the per-skill rendering widget: given `{skill, score, sufficientData}`, render "insufficient data" when `sufficientData == false` (regardless of `score`'s value), else render the numeric `score`; apply this identically to both `communicativeSkills` and `enablingSkills` sections via one shared widget rather than two near-duplicate implementations.
6. Wire a manual-refresh affordance (pull-to-refresh or a button) dispatching `ReportRefreshRequested`/`ReportRequested` again — no automatic timer-based polling loop.
7. Test: a mocked 404 response from `ReportRepository` produces `ReportNotPublished`, never `ReportError`.
8. Test: a mocked non-404 failure (network error, 500) produces `ReportError`, distinct from `ReportNotPublished`.
9. Test: a skill entry with `sufficientData: false` and a non-null `score` still renders "insufficient data," not the numeric score — this specific edge case (score present despite insufficient data) is the one most likely to be gotten backwards by a naive `score == null` check instead of checking `sufficientData` directly.
10. Test: a skill entry with `sufficientData: true` and a valid `score` renders the numeric value, and is visually/structurally distinguishable in the widget tree from the insufficient-data rendering (not just same widget with different text).

## Success Criteria

- [x] A 404 from the reporting endpoint always renders "waiting for host to publish," never an error banner and never triggers an automatic retry loop.
- [x] `ReportBloc` has zero import of or dependency on Phase 2's `AnswerOutboxDao`/`SyncEngine`.
- [x] Every skill with `sufficientData: false` renders "insufficient data" regardless of the `score` field's value, verified by a test using a non-null `score` alongside `sufficientData: false` specifically.
- [x] `ReportBloc` states are four separate immutable classes with no boolean-flag shape.
- [x] `communicativeSkills` and `enablingSkills` share one skill-rendering widget rather than two divergent implementations.

## Quality and Testing State

- Quality gate: APPROVED (0 findings). Verified: `ReportBloc` has zero import of/dependency on `AnswerOutboxDao`/`SyncEngine`; no `RateLimitException`/backoff logic anywhere in this feature (Phase 7's backoff pattern correctly not reused); `sufficientData` checked directly wherever the insufficient-data rendering decision is made; `communicativeSkills`/`enablingSkills` share one `SkillScoreRow` widget; `published`/`publishedAt` are not used to build a second not-published check on top of the 404 path. Receipt issued.
- Testing: PASSED — Steps 7-10 covered (183 tests total: 158 pre-existing + 25 new across report_response_test.dart, report_repository_impl_test.dart, report_bloc_test.dart, skill_score_row_test.dart, report_screen_test.dart), 0 failures, 0 skipped. Full report: `tests/phase-08-reporting-results-test-report.json`.

## Risks

- **LOW**: Because "not published" and "not owned" are genuinely indistinguishable at the wire level (confirmed by direct inspection of `pte-api`'s `reporting` service — a single `ReportNotFoundException`/`REPORT_NOT_FOUND` code covers both), there is no way for this phase to build a more specific message for the "not owned" case even if a future product decision wanted one; that would require a backend contract change, out of scope for this plan.
- **LOW**: If `pte-api`'s reporting service is extended later to add a distinguishable "not yet published" vs. "not found" response (e.g. a different status code or error body), this phase's uniform 404-handling would need revisiting — noted here rather than built against speculatively, per YAGNI and consistent with this plan's general stance on not building toward unconfirmed future backend behavior (see Phase 4's timer poll-only constraint for the same principle applied elsewhere).
