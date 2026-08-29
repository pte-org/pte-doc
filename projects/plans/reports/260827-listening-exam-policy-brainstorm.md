# Brainstorm: Listening Task Delivery & Exam Policy Engine

**Date:** 2026-08-27

## Ideas Explored

**Device-check placement:**
- A. Client-only gate (getUserMedia test in pte-app, no backend) — fastest, but no audit trail.
- B. `exam-delivery` flag (`deviceCheckPassedAt` on `ExamAttempt`) — light, reuses existing attempt state machine.
- C. New session inside `proctor` (reuse `ProctorSession` lifecycle) — correct domain fit for continuous monitoring, but scope creep for a one-time pre-flight check with no current continuous-monitoring requirement.

**Audio delivery:**
- D. Presign once at `StartAttempt`, pin into snapshot (reuses existing `SnapshotPinService`/`PinnedItem`) — consistent with the "sync calls happen once at pin time" pattern already used by `AuthoringClient`/`SchedulingClient`.
- E. Presign on-demand per task view — always fresh, but adds a synchronous outbound call into `media` on the exam-runtime critical path.
- F. Server-side `playCount` enforcement — needed regardless of D/E, since client-reported play state can't be trusted (same trust-boundary problem as task 20).

**Policy configurability** (triggered by user: hosts need practice-mode replay vs. real-exam single-play, plus other host-configurable options):
- Bare `maxPlayCount` field on `CompositionItemRequest` (minimal, mirrors existing `timingOverrideSeconds`).
- Rich `ExamMode` enum + `ExamPolicy` embeddable value object at `ExamSession` level, with preset defaults per mode and host override — chosen because this is a capstone project graded on design depth, not a startup MVP; YAGNI was explicitly overridden by the user for this reason.

## User's Direction

Locked on the rich model:
- `ExamMode` (PRACTICE, MOCK_TEST, REAL_EXAM) resolves to a default `ExamPolicy` (replayPolicy, deviceCheckRequired, proctorRequired, answerIntegrityLevel) at session level in `scheduling`.
- Host can override individual `ExamPolicy` fields after creation, and override `maxPlayCount` per composition item — item-level override wins over session-level default (same precedence as `timingOverrideSeconds`).
- Policy resolved and pinned immutably into `exam-delivery`'s `PinnedExamSnapshot` at `StartAttempt` — no runtime host change affects an attempt already in progress (matches the existing ExamSnapshot-immutable-at-pin invariant).
- `answerIntegrityLevel` field added to `ExamPolicy` as the forward hook connecting this design to task 20 (answer encryption), so both tasks share one policy engine instead of two independent mechanisms.

## Open Questions

- Who can override `ExamPolicy` after session creation — `HOST_ADMIN` only, or also `HOST_AUTHOR` (current `SessionController` mixes both depending on endpoint)?
- When does the policy become immutable for editing purposes — at `session.open()`, or only per-attempt at `StartAttempt` pin time (i.e., can a host still tweak policy after opening but before any student has started)?
- Concrete mechanism behind `answerIntegrityLevel = STRICT` (payload encryption vs. integrity hash vs. both) — belongs to task 20, needs its own brainstorm pass.

## Risks

- **Precedence bugs**: two policy sources (session `ExamPolicy.replayPolicy` default vs. composition-item `maxPlayCount` override) create two sources of truth if the precedence rule isn't enforced consistently everywhere it's read.
- **Presigned URL TTL vs. pinned immutability**: audio URLs resolved once at `StartAttempt` must outlive the longest possible attempt duration, or students on a slow device fail mid-section.
- **Field creep on `ExamPolicy`**: the value-object approach is deliberately chosen to bound this, but every new host-configurable dimension still needs to go through the same template+override pattern to avoid regressing to a flag pile.
