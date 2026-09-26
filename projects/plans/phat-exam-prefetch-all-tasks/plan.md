# Plan: Exam Prefetch — Load All Tasks on Attempt Start
Status: 🔵 Planning
Date: 2026-09-26
Mode: Hard

## Overview
Currently the exam app fetches tasks one at a time on each Next/Prev server round-trip (`GET /next-task`, `POST /navigate`), with the server tracking `currentOrderIndex`. This plan switches to **bulk prefetch**: the client fetches all tasks at attempt start/resume in one call, navigates locally, and keeps the answer-submit flow unchanged.

Goals:
- Instant prev/next (no round-trip per tap)
- Header already reloads per task screen rebuild (structural issue, deferred) — prefetch makes this cheaper
- `examEndTime`-based global timer already works; this plan eliminates per-task `fetchNextTask` latency
- Both Practice and Test modes. Resume always re-fetches from server.

Reading timer decision (confirmed with user): reading tasks use the **global header timer only** — per-task `responseSeconds` for reading is ignored by the client. Server returns raw `item.responseSeconds()` for reading tasks in the bulk response (no live-elapsed deduction needed, since client doesn't display it).

## Phases
- [ ] Phase 1: Server — `GET /attempts/{id}/tasks` bulk endpoint + relax `processAnswer` sequential check
- [ ] Phase 2: Client model layer — `TaskView.copyWith`, `AttemptAllTasksResponse`, repository method
- [ ] Phase 3: Client BLoC — local navigation, resume re-fetch, `AttemptInProgress` expansion
- [ ] Phase 4: Client timer/UI cleanup — reading tasks skip per-task timer, reading/writing `autoAdvanceOnExpiration` confirmed
- [ ] Phase 5: Verification

## Research Summary

**Server navigation flow (current):**
- `POST /attempts` (start) → `AttemptLifecycleService.createAndPin` → `timerService.startTask` sets `currentOrderIndex=0` → returns first task
- `GET /{id}/next-task` → `getNextTask` → `timerService.startTask` advances `currentOrderIndex` → returns task at new index
- `POST /{id}/navigate` → `navigateTask(fromPinnedItemPublicId, direction)` → validates source matches `currentOrderIndex` (±1 tolerance for retry) → `timerService.startTask` sets `currentOrderIndex` to target → returns new task

**`processAnswer` and `NotCurrentTaskException`:**
`AttemptLifecycleService.processAnswer` (called by `POST /answers` when `advance=true`) fetches `currentItem(attempt)` via `currentOrderIndex` and throws `NotCurrentTaskException` if `pinnedItemPublicId != currentItem.getPublicId()`. This is the only path that checks `currentOrderIndex` for answer submission. `saveAnswer` (called when `advance=false`) only checks snapshot membership — no `currentOrderIndex` check.

**Who calls `submitAnswer` (advance=true):**
- `TaskAdvanceButton._advanceOnExpiration` (timer expiry auto-advance, TEST mode)
- `AutoAdvanceOnUploadReady._advance` (upload completes, TEST mode speaking/listening — practice mode always uses `TaskAdvanceButton` due to `canNavigateNext=true`)
In the prefetch design, if `fetchNextTask` is no longer called after auto-advance, server's `currentOrderIndex` stays at the prior task. The next auto-advance call fails with `NotCurrentTaskException`. This is the critical server-side change Phase 1 must address.

**`canNavigatePrevious`/`canNavigateNext` are static per task:**
`AttemptMapper.isManualNavigationAllowed = PRACTICE || READING || WRITING`. `canNavigatePrevious = isManualNav && orderIndex > 0`. `canNavigateNext = isManualNav && orderIndex < lastIndex`. These depend only on exam mode and fixed `orderIndex` — safe to prefetch at start, no need to recompute per navigation.

**Reading timer staleness:**
`TimerService.resolveEffectiveResponseSeconds` for READING returns `sectionBudgetSeconds - elapsed`. At t=0 (start), elapsed=0, so all reading tasks get full budget — not the live remaining. This is acceptable: client ignores per-task `responseSeconds` for reading tasks (user confirmed: global timer only for reading).

**`AttemptInProgress` state:**
Currently: `task: TaskView`, `timerSnapshot: TimerSnapshot`. Needs expansion: `allTasks: List<TaskView>`, `currentIndex: int`, `task` derived as `allTasks[currentIndex]`.

**Resume:**
Currently `_onAppResumed` only restarts timer. In new design: dispatch `ResumeTasksRequested` → call `fetchAllTasks` → repopulate `allTasks`. Server recomputes `effectiveResponseSeconds` with live elapsed — speaking/listening get correct values; reading gets fresh remaining budget (which the client ignores anyway).

## Dependencies
- Phase 1 (server relaxation of `processAnswer`) must be deployed before Phase 3 (client removes `fetchNextTask`), otherwise TEST mode auto-advance throws `NotCurrentTaskException` after any navigation in the same session.
- Phase 2 (Dart model/repo) can be developed in parallel with Phase 1 — no runtime dependency until Phase 3 wires it.
- Phase 3 depends on Phase 1 deployed and Phase 2 complete.
- Phase 4 depends on Phase 3 (needs `allTasks` list to iterate section types).
- Phase 5 depends on all prior phases.

## Risks
- **HIGH**: `processAnswer` `currentOrderIndex` check — after local navigation, server's pointer is stale, causing `NotCurrentTaskException` on every auto-advance after the first task. Phase 1 MUST remove this check before Phase 3 ships. There is no safe order to deploy Phase 3 without Phase 1.
- **HIGH**: `AttemptInProgress` state shape change — all test files constructing `AttemptInProgress` must be updated. The state is used in ~30 files. Missing any produces a compile error, which is safe (caught at build), not a silent regression.
- **MEDIUM**: `fetchNextTask` is still used after auto-advance in TEST mode (for server pointer sync). In the new design this call is removed. Server's `currentOrderIndex` stays stale after Phase 3. Phase 1's `processAnswer` relaxation is the mitigation. If Phase 1 is not deployed first, all TEST mode auto-advance breaks.
- **MEDIUM**: Resume consistency — on resume, `fetchAllTasks` returns tasks recomputed with live elapsed. Reading tasks get fresh `sectionBudgetSeconds - elapsed` (accurate, not stale). Speaking/listening get correct `prepSeconds`/`responseSeconds`. This is correct behavior.
- **LOW**: `navigateTask` endpoint becomes vestigial after Phase 3 (client no longer calls it). Leaving it in place is safe; removing it is a separate cleanup.
- **LOW**: `totalTasks` display in `ExamAppBar` — currently comes from `task.totalTasks` (returned by server). With prefetch, this is `allTasks.length`. Must be consistent.

## Plan-Reviewer Pass
_Pending — to be filled after plan-reviewer agent runs._

## Session Notes
<!-- Updated by cook automatically — do not edit manually -->

**Last active:** 2026-09-26 (initial planning)
**Phase in progress:** none — plan created, not yet started
**Status:** Planning complete. Awaiting user approval to begin implementation.
