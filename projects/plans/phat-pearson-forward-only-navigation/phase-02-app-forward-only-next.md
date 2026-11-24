# Phase 2: App Forward-Only Next

## Requirements
Every task screen shows the same Next button (no Previous, hidden on the last task); every Next advances the server pointer exactly once via `submitAnswer`, even for an untouched task; duplicate or too-early Next signals can never skip a task.

## Files to touch (pte-app)
- `lib/features/exam_attempt/presentation/bloc/exam_attempt_event.dart` — `NextTaskRequested` gains `fromPinnedItemPublicId` (value equality updated); `NavigateTaskRequested` removed.
- `lib/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart` — `_onNextTaskRequested` (~l.217): ignore if source id != active task; manual Next ignored inside the cooldown; record activation time when the active task changes (not on resume); `_onTimerTaskAdvancedExternally` (~l.310) and `_onSyncTaskRejectedExternally` (~l.317) pass an id; remove `_onNavigateTaskRequested` (~l.247).
- `lib/core/sync/sync_engine.dart` — add the single "submit for advance" helper (row payload if a row exists in ANY status, else blank; always calls `submitAnswer`/`submitEncryptedAnswer`); `taskRejectedExternally` stream carries the rejected task id (~l.70-81, l.306). Keep `flushOne(advance:false)` for background drafts.
- `lib/features/exam_attempt/presentation/widgets/task_advance_button.dart` — one Next path (flush pending edit → helper → `NextTaskRequested(fromId)`), disabled during cooldown and while in flight; drop Previous, `_navigate`, `forwardOnlyNext`, `forwardOnlyNextEnabled`; keep timer-expiry auto-advance rules (Listening only) going through the same path.
- `lib/features/exam_attempt/speaking_writing/presentation/widgets/auto_advance_on_upload_ready.dart` — dispatch with its own task id; call the same helper; skip if its task is no longer active.
- New constant for the cooldown (e.g. `lib/features/exam_attempt/constants/`), 800 ms.
- `lib/core/widgets/exam/exam_navigation_actions.dart` — option to hide Previous for the attempt (host preview keeps it; check `exam_footer_bar.dart`).
- Speaking screens in `speaking_writing/presentation/pages/`: `read_aloud`, `repeat_sentence`, `describe_image`, `personal_introduction`, `retell_lecture`, `answer_short_question`, `summarize_group_discussion`, `respond_to_a_situation` — always render the shared button; keep the upload-ready auto-advance beside it as an id-guarded extra trigger (screens currently pick one or the other via `canNavigate*`).
- Writing screens (same folder): `summarize_written_text`, `write_essay`, `write_essay_v2`.
- Reading screens in `reading/presentation/pages/` (5) and Listening screens in `listening/presentation/pages/` (8); `summarize_spoken_text_screen.dart` loses its audio-finished gate (Next works while audio plays).
- `lib/features/exam_attempt/presentation/widgets/exam_scaffold.dart` (~l.77) — passes `autoAdvanceOnExpiration:false`; align with the single path.
- `lib/features/exam_attempt/domain/task_navigation_direction.dart`, repository navigate wiring — remove only if nothing else uses it.
- `lib/features/exam_attempt/constants/exam_attempt_strings.dart` — remove strings used only by Previous.

## Steps
1. Add the source id to `NextTaskRequested` and make every dispatcher supply it (button, upload-ready auto-advance, timer expiry, sync rejection).
2. Bloc: drop Next whose source id != active task; drop manual Next within 800 ms of activation; do not start the cooldown on resume.
3. SyncEngine helper: read the outbox row for the task regardless of status; payload = row payload or blank; call the plain or encrypted submit endpoint (STRICT attempts must still encrypt); mark synced on success; on retryable errors leave pending and still let the UI advance (offline is out of scope, see plan Risks); on `NotCurrentTaskException` mark rejected and emit the id-carrying rejection signal.
4. Rejection signal: carries the task id and routes through the guarded Next, so a rejection for a non-active task cannot skip anything.
5. Shared button: single path, disabled in cooldown and while in flight; reset the in-flight guard when the active task id changes; hidden entirely when the active task is the last one (`currentIndex == allTasks.length - 1`); ignore the server's `canNavigatePrevious/Next`.
6. Update the 24 screens to the shared button; delete per-screen flag branching; recount screens with grep before and after.
7. Remove the Navigate event/handler, Previous branch, forward-only flags, now-unused strings/imports; do not refactor further.
8. Update existing widget/bloc tests that referenced Previous, flags or parameterless Next.

## Tests
- `test/unit/features/exam_attempt/exam_attempt_bloc_test.dart`: two Next for the same task move one task; Next for a stale id ignored; manual Next within cooldown ignored and accepted after; timer/auto Next not blocked by cooldown; no cooldown on resume.
- `test/unit/sync/sync_engine_test.dart`: helper sends blank when no row; sends the stored payload when the row is already synced (no overwrite); calls the encrypted endpoint on STRICT; rejection stream emits the task id.
- `test/widget/features/exam_attempt/task_advance_button_test.dart`: Next disabled during cooldown, enabled after; second tap in flight does nothing; Previous absent; absent on the last task.
- Widget test per family (one Speaking, Writing, Reading, Listening incl. Summarize Spoken Text during audio): one Next, no Previous.
- Grep check: no references to `NavigateTaskRequested`, `forwardOnlyNext`, the Previous label in `lib/features/exam_attempt`.

## Success Criteria
- `flutter analyze` clean for touched files; `flutter test test/unit/features/exam_attempt test/unit/sync test/widget/features/exam_attempt` passes.
- A scripted double dispatch of Next for one task leaves state at index+1 and the helper is called once.
- An untouched task's Next results in a blank `submitAnswer` (mock API), and a synced-draft task's Next does not change its payload.
- On a device build: every task type shows one Next and no Previous, last task shows none; host preview still shows Previous/Next.

## Risks
- Behaviour change of `flushOne(advance:true)` callers (timer expiry for Listening, `forceSubmit` flush): audit all call sites.
- Speaking media-backed payloads: verify what the outbox row holds for a recording that has not finished uploading (blank vs media reference) before relying on "row payload".
- Cooldown blocks a legitimately fast student on a very short task: tunable constant, manual Next only.
- Offline behaviour unchanged and still imperfect (plan Risks).

## Execution Log

### Errors Encountered
- Bloc tests: `Stream<void>` vs `Stream<String>` type mismatch for `taskRejectedExternally` after the stream began carrying the task id.
- Widget tests: `task_advance_button_test.dart` referenced the removed `NavigateTaskRequested` and `forwardOnlyNext*` props; `flushOne` stubs no longer matched the new call.
- `auto_advance_on_upload_ready_test.dart` (2 tests) failed: it expected `flushOne` and a bare `NextTaskRequested()`.
- `fill_blanks_dropdown_screen_test.dart` ("advance button still present in the fallback state") found 0 ElevatedButton.
- Process slip: `dart format lib test` reformatted 15 unrelated files.
- Code review (WARNING 7.5/10) fixes, found while fixing:
  - `submitForAdvance` deadlocked (all 5 sync tests timed out at 30 s): `whenComplete(() => map.remove(id))` returned the very future being awaited.
  - After the last-task rule changed to also require `orderIndex + 1 >= totalTasks`, bloc test fixtures were no longer "last by server".
  - `submitForAdvance` tests failed with `type 'Null' is not a subtype of type 'Future<void>'`: they stubbed `upsertAnswer`, the code now calls `insertAnswerIfAbsent`.
  - 3 `task_advance_button_test.dart` tests failed (last task, cooldown, new-task cooldown); the last one also needed a second `pump` for the stream event.

### Root Cause
- The rejection stream now emits the rejected task id (so a stale rejection cannot skip a later task).
- The button is now forward-only: one path `submitForAdvance` then `NextTaskRequested(fromPinnedItemPublicId, userInitiated)`.
- The auto-advance widget now uses the same path.
- A single-task attempt counts as "last task", where Next is intentionally hidden.
- `dart format` was run on the whole tree instead of the touched files.
- `whenComplete` awaits a callback result that is a future, so returning `map.remove(id)` (which returns the stored future) waited on itself.
- Review fixes: blank row uses insert-or-ignore (`insertAnswerIfAbsent`) so it cannot overwrite a real answer; the button reads `ExamAttemptBloc.taskActivatedAt` for its cooldown; last task needs list-last AND the server agreeing.

### Resolution
- Updated bloc tests to `Stream<String>` / `StreamController<String>`; added 5 forward-only guard tests (stale id, 800 ms cooldown with injected clock, no cooldown after start, timer path unblocked, stale rejection id).
- Rewrote `task_advance_button_test.dart`; updated `auto_advance_on_upload_ready_test.dart`; the fallback test now seeds a two-task attempt; other widget tests stub `submitForAdvance`.
- Added 5 `submitForAdvance` tests in `sync_engine_test.dart` (blank row, existing row keeps payload, network failure stays pending, rejection emits id, no running attempt).
- Reverted the 15 unrelated formatted files with `git checkout` on that exact file list (user approved).
- `submitForAdvance` now uses a block body in `whenComplete`; per-task `_advancesInFlight` map so the Next button and Speaking auto-advance share one submit.
- Bloc reloads the task list when the prefetched list is exhausted but the server says more tasks exist (4 new bloc tests); `NavigateTaskRequested` removed.
- Tests: sync tests stub `insertAnswerIfAbsent`, plus a shared-in-flight test; button tests use `orderIndex: 4` for the last task and stub `taskActivatedAt`, plus a stale-tap test; auto-advance test for retry after an error; new `forward_only_next_screens_test.dart` (Reading, Writing, Summarize Spoken Text with audio playing) and a Speaking test in `read_aloud_screen_test.dart`.

### Test Results After Fix
- `flutter test -r failures-only` (whole pte-app, after the review fixes) → 850 passed, 0 failed (was 838 before the fixes).
- `flutter analyze lib` → No issues found. Whole-project analyze: 14 pre-existing infos/warnings, all in `app_routes_test.dart` / `app_shell_test.dart` (untouched).
- Re-review (APPROVED 8.5/10) follow-ups fixed: the Next button now stays locked after dispatching Next until the new task appears (5 s `advanceSettleTimeout` fallback, so a failed reload cannot leave it stuck); `AutoAdvanceOnUploadReady` frees its guard with the same timeout; stray shell-escape text in a bloc doc comment fixed. New button test for the lock.
- 24 screens use `TaskAdvanceButton`; `git status` in pte-app: 24 modified + 2 new files (constants file, forward_only_next_screens_test.dart). `dart format` run on the touched files only.
- Not fixed (reviewer LOW, outside the approved list): dead code (`SyncEngine.flushOne` has no non-test caller, `navigateTask`, `task_navigation_direction.dart`); `_onTimerTaskAdvancedExternally` dispatches an unguarded `NextTaskRequested()` (dormant path).
