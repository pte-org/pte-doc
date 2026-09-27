# Phase 3: Client BLoC — local navigation, resume re-fetch, `AttemptInProgress` expansion

## Requirements
Replace server-per-navigation round-trips with local list navigation inside `ExamAttemptBloc`. The answer-submit flow (`SyncEngine`, outbox) is unchanged. Resume re-fetches all tasks from server.

## Steps
1. **Expand `AttemptInProgress` state** (`lib/features/exam_attempt/presentation/bloc/exam_attempt_state.dart`):
   - Add `allTasks: List<TaskView>` (the full prefetched list)
   - Add `currentIndex: int`
   - Keep `task: TaskView` but derive it: `task = allTasks[currentIndex]`
   - Keep `timerSnapshot: TimerSnapshot` unchanged
   - Update `copyWith` to handle the new fields
   - Update the constructor and all existing construction sites (grep for `AttemptInProgress(` — expect ~5–10 call sites in BLoC + tests)

2. **Populate `allTasks` on attempt start** (`_onStartAttemptRequested` / `_emitFromResponse`):
   - After `_repository.startAttempt(...)` returns the first task, call `_repository.fetchAllTasks(attemptPublicId)` to get the full list
   - Emit `AttemptInProgress(allTasks: tasks, currentIndex: 0, timerSnapshot: seed)`
   - The first task is `allTasks[0]` — confirm it matches what `startAttempt` returned (same `pinnedItemPublicId`)
   - If `fetchAllTasks` fails: fall back to `allTasks: [firstTask]` and log a warning — the exam can still proceed task-by-task; local navigation will be limited to what's available

3. **`_onNextTaskRequested` — local advance:**
   Replace `await _repository.fetchNextTask(attemptPublicId)` with:
   ```dart
   if (state is! AttemptInProgress) return;
   final next = state.currentIndex + 1;
   if (next >= state.allTasks.length) {
     // Already at end — auto-submit if exam is complete
     add(const ForceSubmitRequested());
     return;
   }
   emit(state.copyWith(currentIndex: next, timerSnapshot: _seedTimer(state.allTasks[next])));
   ```
   `_seedTimer` calls `_timerService.seedFromTask(task)` and returns the initial snapshot.

4. **`_onNavigateTaskRequested` — local jump:**
   Replace `await _repository.navigateTask(...)` with a local index lookup:
   ```dart
   final targetIndex = state.allTasks.indexWhere(
     (t) => t.pinnedItemPublicId == event.fromPinnedItemPublicId,
   ) + (event.direction == TaskNavigationDirection.next ? 1 : -1);
   if (targetIndex < 0 || targetIndex >= state.allTasks.length) return;
   emit(state.copyWith(currentIndex: targetIndex, timerSnapshot: _seedTimer(state.allTasks[targetIndex])));
   ```
   No server call.

5. **`_onAppResumed` — re-fetch all tasks:**
   Add a new event `ResumeTasksRequested` (or extend `_onAppResumed`). On resume:
   - Call `fetchAllTasks(attemptPublicId)`
   - Re-emit `AttemptInProgress` with the fresh list, preserving `currentIndex` (or resetting to the last task the student was on, identified by matching `pinnedItemPublicId` from the old `task`)
   - Re-seed the timer from the resumed task's `prepSeconds`/`responseSeconds`

6. **`totalTasks` in `ExamAppBar`**: currently passed as `widget.task.totalTasks`. In new design, pass `state.allTasks.length` (or keep using `task.totalTasks` which equals `allTasks.length` — confirm both are consistent).

7. **Update BLoC unit tests**: every test constructing `AttemptInProgress` needs `allTasks` and `currentIndex`. Tests for `NextTaskRequested` and `NavigateTaskRequested` now assert local index change, not a repository call. Add tests for: start populates `allTasks`, next increments index, navigate jumps by `pinnedItemPublicId`, resume re-fetches and preserves position.

## Success Criteria
- `NextTaskRequested` emits a new `AttemptInProgress` with `currentIndex + 1` and no call to `fetchNextTask`.
- `NavigateTaskRequested` emits correct index without a server call.
- `_onAppResumed` calls `fetchAllTasks` exactly once and re-seeds the timer.
- `flutter test` for `exam_attempt_bloc_test.dart` passes (updated tests).
- Manual: entering a practice session, pressing Prev/Next navigates instantly with no loading indicator.

## Risks
- **HIGH (from plan)**: Phase 1's `processAnswer` relaxation must be deployed before this phase ships. Without it, TEST mode auto-advance throws `NotCurrentTaskException` after the first task.
- **MEDIUM**: `_seedTimer` for reading tasks will use the prefetched `responseSeconds` (full section budget at start, or live remaining on resume). Since `autoAdvanceOnExpiration = false` for reading and the global timer is shown, a stale per-task timer is harmless — but confirm `TimerService.seedFromTask` does not crash on a reading task (e.g., if `prepSeconds = 0` is valid input).
- **MEDIUM**: `allTasks` fallback path (Phase 1 not deployed or network error during `fetchAllTasks`): the BLoC falls back to single-task mode. This fallback must not break existing behavior — test it explicitly.
- **LOW**: `currentIndex` becomes stale if the user's attempt is modified server-side between sessions (e.g., a task is removed). Resume always re-fetches, so this only affects the in-session index. Within a session, `allTasks` is immutable (no server can add/remove tasks mid-attempt).
