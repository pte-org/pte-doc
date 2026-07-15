# Phase 2 (Track 2): SyncEngine Offline-Queue Hardening

**Track:** 2 — Resilience & Auto-Recovery
**Covers:** groundwork for FR-06 · User story: P1 (auto-save/resume)
**Depends on:** Phase 1 (exception audit findings may surface issues to fix here too)

---

## Design Constraints

- `SyncEngine` and the Drift-backed offline outbox already exist — this phase hardens, not rebuilds.
- Must handle: partial sync failure (some answers synced, others not), conflicting writes (same question answered offline then online before sync completes), and retry storms (exponential backoff must actually cap, not retry infinitely at full speed).
- Local-first invariant: an answer is never lost even if sync never succeeds before the exam ends — worst case it's queued locally and flagged for manual reconciliation, not silently dropped.

## Files to Touch

- `aptis-app/lib/features/exam_delivery/data/` — `SyncEngine` implementation and offline answer queue (Drift tables).
- `aptis-app/lib/features/exam_delivery/presentation/bloc/exam_attempt_bloc.dart` — surface sync status (pending/synced/failed) to UI where relevant.

## Implementation Steps

1. Review current `SyncEngine` retry/backoff logic; confirm it caps (max retries or max backoff interval) rather than retrying indefinitely at high frequency.
2. Add explicit handling for partial sync failure — track per-answer sync status, not just an all-or-nothing attempt-level flag.
3. Add conflict resolution rule for the same question answered while offline and then reconciled after reconnect (last-write-wins by local timestamp is acceptable unless a stronger requirement emerges — document the choice).
4. Add a "sync failed, will retry" indicator surfaced to the BLoC/UI so a student isn't left thinking their answer synced when it hasn't.
5. Add structured logging around sync failures (integrates with Track 2 Phase 1's exception-handling pass).

## Acceptance Criteria

- [ ] Retry/backoff has a documented cap; no infinite fast-retry loop possible.
- [ ] Partial sync failures don't block or lose unrelated answers.
- [ ] Sync status is observable (logs and/or UI state), not silent.

## Quality and Testing State

- Quality: not evaluated
- Testing: not started
