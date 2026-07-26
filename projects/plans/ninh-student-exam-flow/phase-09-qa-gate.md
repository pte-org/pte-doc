# Phase 9: QA Gate

## Requirements

Final sweep of every phase's code (Phase 0 through 8, not just this phase's own output) against every rule in `pte-app/CLAUDE.md` and `docs/CODING_STANDARDS_APP.md`: hardcoded strings/colors, the 300-line file cap, `mounted` checks after every `await`, sealed `Bloc` events, immutable no-boolean-flag `Bloc` states, controller/subscription disposal completeness, `BlocSelector` usage where mandated, and `build()` method length/complexity. Backfill unit-test coverage gaps for `Bloc`s (`bloc_test`) and DAOs/sync-and-upload engines (`mocktail`-mocked `ApiClient`) wherever a prior phase's Steps described a test that wasn't actually written, or wherever this sweep finds an untested branch. Confirm `flutter analyze` + `flutter test` exit zero-issue as Milestone 1's exit criterion, and perform a final contract spot-check against the running `pte-api` instance, since `plan.md`'s Risks note the contracts driving this entire plan were captured via direct code inspection, not a generated OpenAPI spec. This phase must not introduce new features — it is pure hardening, so Milestone 1's diff stays auditable.

Maps to: **FR-13 (coding-standards compliance) + Success Criteria's `flutter analyze`/`flutter test` zero-issue exit gate**

## Design Constraints

- Scope is **all prior phases' code**, not a fresh feature. If this phase's sweep surfaces a genuine correctness bug (not just a style/standards violation), fixing it is in scope, but adding new user-facing capability is not — a bug fix found here should read as "Phase N's code didn't actually do what Phase N's Success Criteria claimed," not as new scope creep.
- The sweep must be systematic against the rule list, not spot-checked by feel: grep-assisted passes for hardcoded string literals in widget `Text(...)`/similar (should route through `app_strings.dart` from Phase 0) and hardcoded `Color(...)`/`Colors.*` literals (should route through `app_colors.dart`), a line-count check per `.dart` file (excluding generated `.g.dart` output) against the 300-line cap, and a grep for `await` followed by any `context`/`BuildContext` use without an intervening `if (!mounted) return;`-equivalent guard.
- `Bloc` sealed-event and immutable-state compliance must be checked per feature (`AuthBloc` from Phase 1, `ExamAttemptBloc` from Phase 3/4/7, any `Cubit`s from Phase 5/6, `ReportBloc` from Phase 8) — not just the most recently touched one, since standards drift is most likely to have crept into the earliest-built features by the time this phase runs.
- Test backfill targets two categories specifically: (a) any Step in Phases 1–8 that described a test but where the actual test file doesn't exist or doesn't assert what the Step described (a written plan step is not the same as an executed one), and (b) any branch this phase's own code-reading surfaces as untested that a reasonable reviewer would expect coverage for (e.g. an error-mapping branch, a terminal-vs-retry decision point). `mocktail` mocks `ApiClient` at its typed-exception boundary (Phase 1/7's `ApiExceptions` hierarchy) rather than mocking `Dio` directly, so tests assert against the same exception types production code branches on.
- `flutter analyze` and `flutter test` must both exit zero-issue as the literal, mechanically-checked exit gate — not "mostly passing" or "passing except a few known flaky tests." If either does not exit clean, this phase is not done, regardless of how much of the standards sweep and test backfill is otherwise complete.
- The contract spot-check runs against an actually-running local `pte-api` instance, not against the transcribed contract in `spec.md`/`plan.md` alone — re-verify at minimum: the exact `ApiResponse` envelope shape, the `NOT_CURRENT_TASK`/`RESPONSE_WINDOW_EXPIRED` 409-body codes Phase 7 hard-coded its mapping against, the media upload three-step flow's exact request/response field names, and the reporting 404 behavior — since these are the highest-blast-radius contract assumptions this plan was built on, per `plan.md`'s own Risk analysis.
- This phase should not silently skip verifying `flutter_secure_storage` behavior (Phase 1's Risk) on at least one real device/emulator per platform in scope, if both Android and iOS are actually in this plan's testing scope — check `plan.md`'s Dependencies/Assumptions for what's actually in scope before treating this as mandatory or waivable.

## Steps

1. Run a project-wide grep for string literals inside `Text(`/similar widget constructors and for `Color(`/`Colors.` literals across `lib/features/*`; for each hit, either move it to the relevant Phase 0 constants file or document why it's a deliberate, standards-compliant exception (e.g. a debug-only label).
2. Run a line-count check across all non-generated `.dart` files under `lib/`; for any file over 300 lines, split it along an existing seam (e.g. extract a widget, split a `Bloc`'s event/state definitions into their own files) rather than mechanically truncating.
3. Grep for every `await` in files under `lib/features/*/presentation/` and manually confirm any subsequent `BuildContext` use is guarded by a `mounted` check; fix any gap found.
4. Review each `Bloc`/`Cubit`'s event and state class definitions (`AuthBloc`, `ExamAttemptBloc`, Phase 5/6's task-answer `Cubit`s, `ReportBloc`) for sealed-class events and separate-immutable-class states; flag and fix any boolean-flag state shape or non-sealed event enum that crept in.
5. Review controller/subscription disposal across every `StatefulWidget`/`Bloc` built in Phases 1–8 (`TextEditingController`s from Phase 5, `StreamSubscription`s from Phase 2's canary/Phase 4's timer, `record`/audio-player controllers from Phase 6) for completeness.
6. Cross-reference every "Test:" line in Phases 1–8's Steps sections against the actual test suite; write any missing test, and add coverage for any untested branch this sweep's code-reading surfaces (particularly Phase 7's typed-exception dispatch and backoff logic, and Phase 2/6's terminal-vs-retry / re-presign decision points, given their outsized correctness importance).
7. Run `flutter analyze`; fix every reported issue (not just errors — warnings/lints too, consistent with Phase 0's zero-issue baseline) until it exits clean.
8. Run `flutter test`; fix every failure until it exits clean, including any flaky test surfaced by re-running the suite more than once.
9. Perform the contract spot-check: with `pte-api` running locally, manually (or via a scratch script) call `POST /api/iam/auth/login`, `POST /api/exam-delivery/attempts`, `GET /api/exam-delivery/attempts/{id}/next-task`, `POST /api/exam-delivery/attempts/{id}/answers` (including one deliberately-stale-`pinnedItemPublicId` call to confirm the `NOT_CURRENT_TASK` 409 body shape matches Phase 7's mapping), the media three-step flow, and `GET /api/reporting/reports/attempts/{id}` (both before and after publish, if a way to trigger publish is available) — record any drift from what Phases 1–8 were built against, and file it as a fix if small or a flagged residual risk if it requires a larger change.
10. If both Android and iOS are in this plan's actual testing scope (confirm against `plan.md`), run at least one manual check per platform of `flutter_secure_storage` behavior across an app restart, per Phase 1's Risk note.
11. Confirm this phase's own diff introduces no new user-facing feature — a final self-review pass distinguishing "hardening/bugfix" changes from anything that reads as new capability.

## Success Criteria

- [ ] `flutter analyze` exits with zero issues across the entire `pte-app` tree.
- [ ] `flutter test` exits 0 with no failing or flaky tests, across all features from Phase 1 through Phase 8.
- [ ] No hardcoded string/color literal remains in `lib/features/*` widget code without a documented exception.
- [ ] No non-generated `.dart` file under `lib/` exceeds 300 lines.
- [ ] Every `Bloc`/`Cubit` in the codebase uses sealed events and separate immutable state classes with no boolean-flag state shape.
- [ ] Every controller/subscription created across Phases 1–8 has a confirmed disposal path.
- [ ] Every "Test:" line described in Phases 1–8's Steps has a corresponding, passing, assertion-matching test in the suite.
- [ ] The contract spot-check against a running `pte-api` instance has been performed and any drift recorded, not skipped as redundant with the original transcription.
- [ ] This phase's diff contains no new user-facing feature beyond bug fixes and standards-compliance changes.

## Quality and Testing State

- Quality gate: not evaluated.
- Testing: not started.

## Risks

- **MEDIUM (carried from `plan.md`)**: Backend contracts were captured via direct controller/DTO inspection, not a generated OpenAPI spec, and could have drifted since this plan's phases were built against them (spanning Phases 0–8's execution window). Mitigation: Step 9's spot-check is this phase's explicit catch-all for that drift — treat any discrepancy found here as a real defect to fix, not a documentation nitpick, since a drifted contract silently breaks whichever phase assumed the old shape.
- **MEDIUM**: A standards sweep this broad (across 8 prior phases' worth of code) risks surfacing more findings than fit comfortably in one pass — if the sweep finds a large volume of 300-line-cap violations or missing tests, this phase may need to be time-boxed and prioritized (fix correctness-affecting gaps first, defer purely cosmetic standards violations) rather than blocking Milestone 1 indefinitely on exhaustive compliance. Flag any deliberately-deferred item explicitly rather than silently leaving it unaddressed and unmentioned.
- **LOW**: Because this phase is explicitly barred from adding new features, any gap it finds that *would* require new capability to fix properly (as opposed to a bugfix within existing scope) should be recorded as a residual risk/follow-up item for post-Milestone-1 work, not quietly worked around within this phase's hardening-only mandate.
