# Phase 4: Client timer/UI cleanup — reading tasks skip per-task timer, confirm `autoAdvanceOnExpiration`

## Requirements
Ensure reading and writing tasks do not misuse a stale per-task timer, and confirm `autoAdvanceOnExpiration = false` is consistently set where needed. No new user-visible changes — this phase hardens the timer seeding for reading tasks and removes any dead per-task timer display paths.

## Steps
1. **Confirm `autoAdvanceOnExpiration` values across all task types:**
   - Speaking (TEST mode): `autoAdvanceOnExpiration = true` (timer expiry auto-advances) — unchanged
   - Speaking (PRACTICE mode): `TaskAdvanceButton(autoAdvanceOnExpiration: false)` — already set
   - Reading/Writing: `TaskAdvanceButton(autoAdvanceOnExpiration: false)` — already set (grep all reading/writing screens to confirm; these should never auto-advance on timer expiry since the global timer handles the exam deadline)
   - Listening: `autoAdvanceOnExpiration = true` in test mode, `false` in practice mode — confirm unchanged

2. **Reading task timer seeding**: When `_seedTimer(readingTask)` is called in Phase 3's BLoC, `TimerService.seedFromTask` receives a reading task's `prepSeconds=0` and `responseSeconds=sectionBudget` (or raw per-item value). Confirm this does not crash and the resulting `TimerSnapshot` phase transitions normally (prep → response). Since `autoAdvanceOnExpiration = false`, the timer running down is harmless. If the timer shows in any UI component for reading tasks, confirm it is the global `_ExamGlobalTimerLabel` (not the per-task `timerSnapshot.remaining`). The `_ExamGlobalTimerLabel` already ignores `timerSnapshot.remaining` when `examEndTime != null`.

3. **`totalTasks` audit**: `ExamAppBar` takes `totalTasks` as a constructor param. Trace all call sites of `ExamScaffold` (which passes `totalTasks: widget.task.totalTasks`) to confirm `task.totalTasks` equals `allTasks.length` after Phase 3. If they diverge (e.g., server returns `totalTasks` differently), update the relevant screens to pass `state.allTasks.length` explicitly.

4. **Remove dead `timerSnapshot.remaining` reads for reading/writing tasks** (if any exist after global timer refactor). The `_ExamGlobalTimerLabel` was added in a prior session — confirm no reading/writing screen still renders `timerSnapshot.remaining` as a primary time display.

5. **Update any affected tests** for reading/writing screens that check timer display — they should assert the global timer label, not per-task remaining.

## Success Criteria
- All reading and writing screens show only the global header timer — no per-task timer countdown visible.
- `autoAdvanceOnExpiration = false` confirmed for all reading/writing `TaskAdvanceButton` instances (grep check).
- `flutter test` passes for all reading/writing screen widget tests.
- `TimerService.seedFromTask` called with a reading task does not crash and produces a valid snapshot.

## Risks
- **LOW**: This is mostly a verification/hardening phase. The main risk is finding an edge case where a reading screen still reads `timerSnapshot.remaining` — easily fixed inline.
- **LOW**: `totalTasks` mismatch between `task.totalTasks` and `allTasks.length` would cause the item counter ("Item X of Y") to show a wrong Y. Caught by visual inspection in Phase 5.
