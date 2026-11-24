# Plan: Pearson-style Forward-Only Navigation (slim)
Status: ✅ Implemented and verified by automated checks (manual UI checklist pending, user commits)
Date: 2026-11-22
Mode: Hard (scope trimmed after red-team + user review)

## Overview
Every task in every section (Speaking, Writing, Reading, Listening) gets the same Next button, nobody can go back, and Next on an unfinished task submits whatever exists (partial answer, or blank = 0) and moves on, like the real Pearson PTE exam. Accidental double-taps must never skip an unanswered question. The last task has no Next: the student ends the exam with the existing Submit button in `ExamAppBar` (confirm dialog kept).

Repos: `pte-api` (Spring Boot) and `pte-app` (Flutter). Paths below are relative to `d:\FPT\9thSemester\pte\<repo>\`.

This is the SLIM version. The earlier 5-phase plan (server `/navigate` as the single advance path, completeAttempt backfill, durable navigate queue, PREVIOUS 400, flag changes) was dropped by the user's decision. Navigation stays an app concern; the server only gets one fix.

## Goals / Non-goals
Goals
- Next on all 4 sections; no Previous in the exam attempt UI; Next hidden on the last task.
- Next on an untouched task still advances the server pointer (no more "no outbox row, nothing sent").
- Next while Speaking records stops the recorder and submits the partial recording; Next while Listening/prompt audio plays stops audio and moves on at once; no confirmation dialog.
- One user action or one timer event advances at most one task (id-guarded, cooldown-protected).
- A blank Speaking/Writing answer scores 0 with no Azure/Gemini call.

Non-goals (explicit; see Risks)
- No change to `POST /navigate`, `ManualNavigationPolicy`, `AttemptMapper` flags, `completeAttempt`, `ProctorCommandService`. The app simply ignores `canNavigatePrevious/Next` from the server.
- No offline hardening of the server pointer (durable queue, resume reconciliation).
- No server enforcement of "no going back" (UI contract only).
- Host exam preview (`features/exam_preview`) keeps its own Previous/Next.
- No change to the timer model or the encrypted-answer wire format.

## Success Criteria (measurable)
1. Every task type shows exactly one Next button and no Previous in the attempt UI, except the last task (no Next); host preview unchanged.
2. Two `NextTaskRequested` events for the same task move exactly one task (bloc test); a manual Next within 800 ms of a task becoming active is ignored.
3. Pressing Next on an untouched task (no outbox row) calls `submitAnswer` with a blank payload, so the server pointer moves and the next task's Next is accepted; a task whose draft is already synced is advanced without overwriting its payload.
4. Next during Speaking recording stops the recorder and leaves a media row that eventually uploads and saves as the answer; Next during Listening/prompt audio stops playback.
5. Host scoring of a blank Speaking/Writing answer yields 0 with zero vendor calls (test asserts the Azure/Gemini clients are not invoked).
6. `./mvnw test` (pte-api, Maven) and `flutter analyze` + `flutter test` (pte-app) pass.

## Phases
- [x] Phase 1: Server blank scoring short-circuit — blank payload scores 0, no vendor call (awaiting user approval of the review gate)
- [x] Phase 2: App forward-only Next — one Next path, id-guarded and cooldown-protected, on all screens, no Previous, hidden on last task
- [x] Phase 3: Interrupt recording and audio on Next — stop recorder/player, submit the partial result
- [x] Phase 4: Tests and verification — remaining tests, compose run, manual checklist

Phases 1 and 2 are independent. Phase 3 builds on Phase 2's button hook. Do Phase 2 as one review unit (events + button + 24 screens must compile together).

## Design

### Why a double tap is dangerous
The button's own `_isNavigating` flag is not the problem. The two real problems:
1. Tap lands on the next screen: tap #1 moves to question 2 in ~100 ms; a fast second tap hits question 2's own Next and skips it unread. The old flag lives in question 1's button so it cannot stop this.
2. Several things can say "go next" at once. `NextTaskRequested` today means "current+1" without saying which task it was for. Manual Next, the Speaking upload-ready auto-advance, timer expiry and the "server rejected a task" signal can all fire for the same task and each adds 1.

Fixes: (a) `NextTaskRequested` carries the source task id; the bloc ignores it if the active task differs, so only the first event for task N moves N to N+1. (b) Manual Next is disabled in the UI and ignored in the bloc for 800 ms after a task becomes active (one named constant; not applied on app resume; timer/auto events are not blocked by it, they rely on (a)). (c) The Speaking auto-advance dispatches only for its own still-active task. No dialog anywhere.

### Single Next path (app)
Server facts (read from code): `submitAnswer` = save the answer of the CURRENT task then move the pointer (`AttemptAnswerRecorder.processAnswer`), rejects other items with `NotCurrentTaskException`; `saveAnswer` saves any item and never moves the pointer; `submitAnswer` upserts, so re-sending an existing payload is harmless.
App facts: Reading/Writing Next is currently local-only plus `saveAnswer`, so the pointer never moves there; `SyncEngine.flushOne` returns without any call when the outbox row is missing OR already synced (`row.status != pending`).

New path for every manual or timer Next: flush the cubit's pending edit, then call `submitAnswer` for the source task with (a) the outbox row's payload if one exists (pending or synced), else (b) a blank payload; only after the call returns (or fails with a retryable error) dispatch `NextTaskRequested(fromPinnedItemPublicId)`. The blank case needs a small SyncEngine helper (e.g. `submitForAdvance(pinnedItemPublicId)`) so the logic is in one place, not in 24 screens.

## Risks
- HIGH (accepted, out of scope): offline Next. `submitAnswer` cannot be sent, the app moves on, and when the network returns the next task's `submitAnswer` can hit `NotCurrentTaskException`; that row is marked terminal-rejected (answer lost for that task) and, today, the rejection signal skips one more task. Reopening the app can also land on the earlier server pointer. Mitigation in this plan: the rejection signal carries the task id and is id-guarded (no extra skip). Real fix (durable navigate intent, resume reconciliation) needs its own plan.
- RESOLVED (Phase 1, "Hướng A"): a blank row used to stay examiner-eligible in MANUAL_EXAMINER mode and block finalize. Now `ScoringIngestService` scores blank AI rows 0 at ingest (provider `blank-answer-rule`), the three `isAiEligible` predicates exclude them (`AiEvaluation.isScoredAsBlankAnswer`), and `GradingCompletionEvaluator` counts them as satisfied, like a missing row. The worker guard stays as a backstop. Limit: rows already PENDING before this change are not retro-scored (local data only).
- RESOLVED (Phase 1): the report explanation of a blank AI zero used to say "legacy / old data". `RubricRescoreService.traceOf` now returns the new `ItemTraceKind.BLANK_ANSWER`. No pte-app/pte-web/pte-practice code reads `traceKind` today; a future screen must handle the new value.
- LOW: "blank" means null or whitespace only; a structured empty payload such as `{}` or `[]` would still reach a vendor. No task type was found that sends one.
- Resolved Unresolved-1: a task with no answer row is treated as blank and scored 0 by grading/reporting (`GradingCompletionEvaluator.java:69-73`); the grading-side check is done, the report-aggregation side was not traced.
- MEDIUM: forward-only is a UI contract; `saveAnswer` accepts any item, so a modified client can still edit earlier tasks.
- MEDIUM: tasks never reached when the exam clock runs out have no answer row at all; how scoring treats absent rows is unchecked (blank rows are handled by Phase 1).
- MEDIUM: a partial Speaking recording is saved only if its upload finishes before the attempt is submitted (host/proctor force-submit or exam clock at zero while offline can lose it).
- MEDIUM: server still sends `canNavigatePrevious/Next` (true for Reading/Writing); the app ignores them. A later cleanup should remove the dead flags and `ManualNavigationPolicy`.
- MEDIUM: `SyncEngine.flushOne(advance:true)` callers change meaning (always call the server); verify Speaking media-backed payloads and STRICT (encrypted) attempts go through the same helper.
- LOW (Phase 3 review): if `recorder.stop()` throws inside the Next hook, `AutoRecordCubit.close()` retries `stop()` on the shared recorder; if the next task's recording already started, the old cubit could save that file under the old item key. Unlikely (next recording starts after prep; close runs at dispose). Real fix: remember the started path and ignore a mismatching stop result.
- LOW (Phase 3 review, unverified, Phase 2 area): the Speaking screens may not pass `pinnedItemPublicId` to `TaskAdvanceButton`, which would make its stale-tap check compare the bloc's current task with itself. The captured id and `fromPinnedItemPublicId` on the event still protect the submit.
- LOW (Phase 3 re-review, accepted): (a) `markTerminalRejected` is not payload-guarded, so a rejection of the old blank payload (e.g. `ValidationException`) could mark a newer pending payload rejected; (b) `AutoRecordCubit.close()` awaits an in-flight `recorder.start` with no bound; (c) `_leaving` is not reset if Next aborts after `finalizeForAdvance` (submit throws a non-API error or the bloc ignores the event) while the cubit is still idle, so the timer would not auto-start recording for the rest of that task; (d) a direct `stopRecording()` call bypasses `_stopOnce` (no screen calls it today).
- VERIFIED (Phase 3): `saveAnswer` accepts any item of the attempt and `AnswerSubmitService.submit` overwrites an existing answer, so a late partial recording replaces the blank answer as long as the attempt is still IN_PROGRESS (`AttemptAnswerRecorder.saveAnswerWithoutAdvance`).
- LOW: cooldown feels sluggish; one constant, 800 ms, manual Next only.
- DECIDED (user, 2026-11-22): on the last Speaking task, upload-ready auto-advance keeps auto-submitting the whole exam (existing behavior, like Pearson). No change to `AutoAdvanceOnUploadReady` for the last task. Timer expiry on the last Listening task also auto-submits.
- MEDIUM (Phase 2 review): any retryable Next failure (429, 5xx, timeout, not only offline) leaves the row pending while the UI advances; later background flushes use `saveAnswer`, so the server pointer lags and later `submitAnswer` calls get 409. Same accepted limit as offline Next.
- LOW (Phase 2 review, not fixed): dead code left in pte-app (`SyncEngine.flushOne` has no non-test caller, `navigateTask`, `task_navigation_direction.dart`); `_onTimerTaskAdvancedExternally` dispatches an unguarded `NextTaskRequested()` (dormant path today). Clean up in a later change.
- LOW: 24 screens edited mechanically (8 Speaking, 3 Writing, 5 Reading, 8 Listening); recount with grep, per-family widget tests plus `flutter analyze`.
- LOW: after this change the old phase counts of "26 screens" in earlier drafts are void; use the grep result.

## Dependencies / project rules
- No automatic git commits; the user commits.
- Take a `pg_dump` backup into `D:\FPT\9thSemester\pte\db-backups` before any local DB-touching manual test; ask before any DB write. No migrations needed.
- Run the API via the three-file compose setup only (arm64 Docker target); no host-run fallbacks.
- Do not run real Azure scoring without the credit estimate and user OK.
- The user does UI/API checks themselves; tell them only when a UI check is needed.

## Decisions recorded
- Last task: no Next; Submit in `ExamAppBar` ends the exam (confirm dialog kept).
- Blank scoring short-circuit is in scope (Phase 1).
- Server and app ship together; no app-version gating.
- Cooldown 800 ms for all task types.
- Dropped by user: `/navigate` as single path, completeAttempt/proctor backfill, durable queue, PREVIOUS 400, flag changes.

## Unresolved questions
1. Does `ScoringIngestService` treat a task with NO answer row (never reached) as 0 or error? Only matters for the exam-clock-ends case; check during Phase 1 but do not expand scope.
2. Does `AutoRecordCubit` already expose a safe "stop now and queue upload" call, or does Phase 3 add one? Decide when reading `read_aloud_cubit.dart` / `AutoRecordTimerBridgeMixin`.

## Session Notes
<!-- Updated by cook automatically — do not edit manually -->

**Last active:** 2026-11-22 21:50
**Phase in progress:** phase-04-tests-and-verification (automated checks done; manual checklist with the user)
**Status:** mvnw test 5590 run / 0 fail; flutter test 864 passed; analyze lib clean; API rebuilt via compose and healthy

### Decisions made this session
- Phase 3 review fixes applied (markSyncedIfUnchanged, in-flight start tracking); re-review APPROVED 9/10.
- Late partial recording overwrites the blank answer on the server (verified in `AnswerSubmitService.submit`).
- Remaining LOW items are recorded under Risks, not fixed.

### Next immediate action
User runs the manual checklist; no commit by cook (user commits).
