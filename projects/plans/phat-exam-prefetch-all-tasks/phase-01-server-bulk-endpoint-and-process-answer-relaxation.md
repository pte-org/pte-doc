# Phase 1: Server — `GET /attempts/{id}/tasks` bulk endpoint + relax `processAnswer` sequential check

## Requirements
The server must expose all tasks for an attempt in a single call, and must accept answer submissions for any task in the attempt (not just the sequential "current" one). These two changes are independent but both required before Phase 3 can ship.

## Steps
1. **Add `GET /attempts/{id}/tasks` endpoint** in `AttemptController`. Returns all tasks for the attempt as a list — same shape as the existing `AttemptTaskResponse`, one entry per `PinnedItem` in the `PinnedSnapshot`.
2. **Add `getAllTasks` in `AttemptLifecycleService`**: load the attempt, verify ownership and `IN_PROGRESS` status, call `allItemViews(attempt)`, map each item with `attemptMapper.toTaskResponse(attempt, item, effectivePrep, effectiveResponse, total, encryptionKey)`. For reading items, use `timerService.resolveEffectivePrepSeconds(item)` and `timerService.resolveEffectiveResponseSeconds(attempt, item, allItems)` as usual — this returns `sectionBudget - elapsed` at call time. The client ignores reading `responseSeconds`, so the value is informational only.
3. **`canNavigatePrevious`/`canNavigateNext` in bulk response**: these are already static per item (`isManualNavigationAllowed && orderIndex > 0 / < last`) — no change needed. Mapper already computes them correctly. Each item's flags are stable for the lifetime of the attempt.
4. **Remove the `currentOrderIndex` equality check from `processAnswer`** (`AttemptLifecycleService` around line 316–318). Keep the snapshot-membership filter (`pinnedItemPublicId` belongs to the same `pinnedSnapshotId`) — that is the only security boundary needed. Do NOT remove or change the lock (`lockAttempt`), which guards `currentOrderIndex` updates and play-count counters unrelated to this change.
5. **Keep `navigateTask` and `getNextTask` endpoints unchanged.** The client will stop calling them after Phase 3, but they must still work for any in-flight client that hasn't been updated. Do not gate-delete them in this phase.
6. **Write `AttemptAllTasksResponseTest`**: confirm the new endpoint returns one entry per pinned item, in `orderIndex` order, with correct `prepSeconds`/`responseSeconds`/`canNavigateNext`/`canNavigatePrevious` per section and exam mode. Cover at least: PRACTICE mode (all items have `canNavigateNext=true` except last, `canNavigatePrevious=false` for first), TEST mode reading (manual nav within reading section only), TEST mode speaking (both flags false).
7. **Write regression test for the `processAnswer` relaxation**: `processAnswer_forNonCurrentTask_isAccepted` — create an attempt, start task 0, then call `processAnswer` with a `pinnedItemPublicId` from task 2. Confirm it succeeds (no `NotCurrentTaskException`).

## Success Criteria
- `GET /attempts/{id}/tasks` returns all items for a live attempt, same field shape as the single-task response, ordered by `orderIndex`.
- `POST /attempts/{id}/answers` with a `pinnedItemPublicId` for a non-current task (i.e., `currentOrderIndex != pinnedItem.orderIndex`) succeeds — no longer throws `NotCurrentTaskException`.
- Existing `AttemptLifecycleServiceTest` / `AttemptServiceSubmitAnswerTest` passes without regressions.
- Full `exam-delivery` test suite passes.

## Risks
- **MEDIUM**: removing the `currentOrderIndex` check from `processAnswer` allows a client to submit an answer for a task the student never saw (or submit the same task twice). `AnswerSubmitService.submitIfAbsent` already guards against double-submission idempotently. Out-of-order submission does not affect scoring (each task scored independently). The B2B kiosk model (per `phat-client-side-exam-timer` plan's security posture) means a rogue client is the same risk class as before.
- **LOW**: `getAllTasks` reads `allItemViews(attempt)` — same cache warming path as `getNextTask`. If the cache is cold, this adds a DB read for all items at once. For a typical exam (17–25 items), this is one batch read, not N sequential reads — acceptable.
- **LOW**: reading `resolveEffectiveResponseSeconds` at bulk-fetch time returns `sectionBudget - elapsed` where elapsed = 0 (start) or real elapsed (resume). The client ignores this value for reading tasks (global timer used). Still confirm the value is not zero or negative under any path (clamped in `resolveEffectiveResponseSeconds` already).
