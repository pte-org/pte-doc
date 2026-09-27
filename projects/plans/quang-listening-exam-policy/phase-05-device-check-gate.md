# Phase 5: Device Check Gate & Endpoint

**Covers:** FR-05 · User stories: P1 (device check gate before StartAttempt)
**Depends on:** Phase 4 (policy pinning)

---

## Requirements

**Design revised during cook** (see Session Notes): the plan's original two-call design (`POST /attempts/{id}/device-check` before `StartAttempt`) is impossible as written — `ExamAttempt` doesn't exist until `AttemptService.startAttempt()`/`createAndPin()` creates it, so there is no `attemptId` to call a pre-attempt device-check endpoint against. Revised design: `StartAttemptRequest` carries a `deviceCheckConfirmed` boolean, checked inline against the pinned policy at the same point `startAttempt()` already creates the attempt.

Add a `deviceCheckPassedAt` field (nullable Instant) to `ExamAttempt` as an audit record — not a pre-condition gate. At attempt creation, once the snapshot is pinned (so `PinnedExamSnapshot.deviceCheckRequired` is known), if the pinned policy requires a device check and `request.deviceCheckConfirmed()` is not `true`, reject before the attempt commits (transaction rolls back — no partial `ExamAttempt` row persists, student can simply retry `StartAttempt` with the flag set). If accepted (either not required, or required and confirmed), set `deviceCheckPassedAt = Instant.now()` on the new attempt for audit/dispute-review purposes.

Maps to: **P1 Story #3 (device check gate before StartAttempt)**

---

## Design Constraints

- No separate `POST /attempts/{id}/device-check` endpoint — the check is a field on `StartAttemptRequest`, evaluated inline in `AttemptService.createAndPin()`, after `snapshotPinService.pin()` returns (that's the earliest point `deviceCheckRequired` is known) and before `attempt.begin()`/the final save.
- The gate only applies to first-time attempt creation (`createAndPin()`), never to resuming an existing in-progress attempt (`resumeOrReject()`) — a student reopening the app mid-exam does not need to reconfirm.
- Server cannot verify a device check actually happened — this is a trust boundary identical to the plan's own acknowledged limitation (client self-attests). The value of gating is UX (reminds/blocks the student from skipping the step), not a security control.
- Rejecting must not leave a partial `ExamAttempt` row: the check happens inside the same `@Transactional` method that creates the attempt, so throwing rolls back the whole operation, including the earlier `attemptRepository.save(attempt)` call used to obtain an id for the pinned-snapshot FK.
- `deviceCheckPassedAt` is written once, at creation, from server time — it is an audit fact ("was this attempt started with a confirmed check"), not something a client ever queries or updates after the fact.

---

## Steps

1. Add `deviceCheckPassedAt: Instant` (nullable) column to `exam_attempts` table / `ExamAttempt` entity.

2. Add `boolean deviceCheckConfirmed` to `StartAttemptRequest` (defaults to `false` when omitted from the JSON body — absent means "not confirmed," never silently treated as confirmed).

3. Add `DeviceCheckRequiredException` (extends `DomainException`, matching `AttemptNotFoundException`'s pattern) mapped to 409 Conflict, with a message clearly indicating "Device check is required" so the client knows to run its local check and resend with the flag set.

4. In `AttemptService.createAndPin(...)`, after `PinnedExamSnapshot pinned = snapshotPinService.pin(...)` and the existing empty-snapshot check, add: if `pinned.isDeviceCheckRequired()` and `!deviceCheckConfirmed`, throw `DeviceCheckRequiredException()`. Thread the `deviceCheckConfirmed` value from `startAttempt(request, caller)` down through `createAndPin(...)`'s parameter list.

5. When the gate passes (or isn't required), set `attempt.setDeviceCheckPassedAt(Instant.now())` before the final `attemptRepository.save(attempt)` in the same method.

6. Integration test: REAL_EXAM session (`deviceCheckRequired=true`) — `StartAttempt` with `deviceCheckConfirmed=false` (or omitted) is rejected, no `ExamAttempt` row persists; `StartAttempt` with `deviceCheckConfirmed=true` succeeds and `deviceCheckPassedAt` is set.

7. Integration test: PRACTICE session (`deviceCheckRequired=false`) — `StartAttempt` succeeds regardless of `deviceCheckConfirmed`'s value.

8. Integration test: resuming an already-`IN_PROGRESS` attempt (second `StartAttempt` call for the same session+student) never re-evaluates the gate, regardless of `deviceCheckConfirmed`.

---

## Success Criteria

- `StartAttempt` on a `deviceCheckRequired=true` session with `deviceCheckConfirmed` false/omitted is rejected, and no `ExamAttempt` row is left behind.
- `StartAttempt` with `deviceCheckConfirmed=true` on the same kind of session succeeds and records `deviceCheckPassedAt`.
- Acceptance criterion from spec (reworded for the revised design): "`StartAttempt` with `deviceCheckRequired=true` and `deviceCheckConfirmed` not true returns a rejection referencing the missing check."
- Resuming an existing attempt never re-triggers the gate.

---

## Quality and Testing State

- Quality: **approved** (report: `quality/phase-05-device-check-gate-quality-report.json`). 0 findings — transactional rollback, retry path, trust-boundary documentation, and redesign scope discipline all confirmed correct. No cryptographic receipt (multi-repo limitation, see plan.md).
- Testing: not_started — skipped by user for this phase

---

## Session Notes

- **Design deviation from the plan's literal wording**: discovered mid-cook that `POST /attempts/{id}/device-check` cannot precede attempt creation, since `ExamAttempt` only comes into existence inside `startAttempt()` itself. Resolved (user-confirmed) by folding the check into `StartAttemptRequest` as a boolean flag rather than inventing a pre-attempt persisted state keyed by (session, student) — the server was only ever going to trust a client self-attestation either way, so a separate endpoint/table added complexity without adding real verification.

---

## Risks

- **Device check false positive**: the flag only reflects a client-side claim, not a verified device test. This backend cannot and does not verify the mic/speaker actually work — out of scope, same limitation as the original design.
- **Retry loop UX**: a student who repeatedly sends `deviceCheckConfirmed=false` gets repeatedly rejected with no persisted attempt — this is correct behavior (not a bug), but the client must surface the rejection clearly enough that the student understands to run their local check first.
- **Clock skew in `Instant.now()`**: use server/UTC time consistently for `deviceCheckPassedAt`; it is an audit fact, not used for any gate logic itself (the gate uses the boolean flag, not the timestamp).
