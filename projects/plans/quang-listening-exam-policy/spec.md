# Spec: Listening Task Delivery & Exam Policy Engine

**Date:** 2026-08-27
**Status:** Ready

---

## Problem Statement

Task 19 requires a Listening API with a pre-exam device-check phase, and hosts need exam sessions to behave differently depending on intent (practice vs. real exam) — e.g., unlimited audio replay in practice mode, single-play in a real exam. There is currently no concept of exam mode or per-session policy anywhere in `scheduling` or `exam-delivery`; every session behaves identically regardless of host intent.

---

## User Stories

- **[P1]** As a host, I want to set an `ExamMode` (PRACTICE, MOCK_TEST, REAL_EXAM) when creating a session, so that sensible defaults (replay policy, device-check requirement, proctor requirement) apply without manual configuration.
  Accepted when: `POST /sessions` with `examMode=REAL_EXAM` produces a session whose resolved policy has `replayPolicy=LIMITED(1)`, `deviceCheckRequired=true`.

- **[P1]** As a student taking a listening task, I am blocked from replaying audio beyond the resolved policy's limit, so that exam integrity matches the host's chosen mode.
  Accepted when: after `playCount` reaches the pinned limit, the audio-serving endpoint returns a rejection (not silently replaying).

- **[P1]** As a student, I must pass a device-check before `StartAttempt` succeeds when the resolved policy requires it, so that listening tasks aren't started on a broken microphone/speaker setup.
  Accepted when: `StartAttempt` with `deviceCheckRequired=true` and no prior device-check call returns a rejection referencing the missing check.

- **[P2]** As a host or host-author, I want to override individual `ExamPolicy` fields after session creation but before it opens, so that I'm not locked into the mode's defaults for edge cases.
  Accepted when: `PATCH /sessions/{id}/policy` changes one field without requiring the whole policy to be resent; the same call after `open()` is rejected regardless of attempt count.

- **[P2]** As a host, I want to override `maxPlayCount` for a specific listening task within composition, independent of the session-level replay policy, so that one unusually hard listening item can allow an extra replay.
  Accepted when: composition-item override value is what `exam-delivery` enforces, even when it differs from the session-level default.

- **[P3]** _(out of scope for this spec)_ Concrete `answerIntegrityLevel` encryption/hash mechanism — belongs to task 20's own spec, only the field hook is reserved here.

---

## Functional Requirements

1. FR-01: `scheduling` adds `ExamMode` enum (PRACTICE, MOCK_TEST, REAL_EXAM) to `CreateSessionRequest`; `SessionService.create()` resolves a default `ExamPolicy` (`replayPolicy`, `deviceCheckRequired`, `proctorRequired`, `answerIntegrityLevel`) from the mode.
2. FR-02: `scheduling` exposes `PATCH /sessions/{id}/policy`, authorized for `HOST_ADMIN` and `HOST_AUTHOR` (matching `create`/`setComposition`), allowing partial override of `ExamPolicy` fields. Rejected once the session has been opened (`SessionStatus` past the pre-open state) — `open()` is the hard lock point, regardless of whether any student has started an attempt.
3. FR-03: `CompositionItemRequest` gains an optional `maxPlayCount` override; when present, it takes precedence over the session-level `ExamPolicy.replayPolicy` for that specific task.
4. FR-04: `exam-delivery`'s internal `SchedulingEntitlementResponse` view is extended to carry the resolved `ExamPolicy` and per-item `maxPlayCount`; both are pinned into `PinnedExamSnapshot`/`PinnedItem` at `StartAttempt` and never re-fetched for the lifetime of the attempt.
5. FR-05: `exam-delivery` adds `deviceCheckPassedAt` to `ExamAttempt`; `StartAttempt` rejects when the pinned policy requires a device check and this field is unset. A new endpoint records the device-check pass before `StartAttempt` is called.
6. FR-06: `exam-delivery` tracks `playCount` per listening task within an attempt; the audio-serving path rejects requests once `playCount` reaches the pinned limit for that task.
7. FR-07: Listening audio URLs are resolved from `media` exactly once, at `StartAttempt`, and pinned with a TTL that exceeds the maximum possible attempt duration for that session.

---

## Non-Functional Requirements

- Security: audio URLs are presigned and tenant-scoped; never enumerable across tenants or sessions.
- Consistency: once `ExamPolicy` is pinned to an attempt, no subsequent host edit to the session's policy affects that attempt (matches the existing ExamSnapshot-immutable-at-pin invariant).
- Data ownership: `exam-delivery` never queries `scheduling`'s or `media`'s database directly; all policy/URL data crosses via DTOs at pin time only.

---

## Success Criteria

- [ ] REAL_EXAM session: second audio-play attempt on the same task is rejected, first is not.
- [ ] PRACTICE session: audio-play is not rejected regardless of replay count (up to a sane operational ceiling, not literally infinite).
- [ ] Editing a session's `ExamPolicy` after a student has already started an attempt does not change that attempt's enforced behavior.
- [ ] `StartAttempt` on a `deviceCheckRequired=true` session without a prior device-check call returns a rejection, not a started attempt.
- [ ] Composition-item `maxPlayCount` override is honored over the session-level default when both are set.

---

## Out of Scope

- Continuous device/environment monitoring during the exam (remains `proctor`'s domain, unchanged by this spec).
- `answerIntegrityLevel` concrete encryption/hashing mechanism (task 20 — separate spec).
- Frontend UI for the device-check flow in `pte-app`/`pte-web`.
- Non-listening task types' delivery mechanics.

---

## Assumptions

- Most real PTE listening tasks are single-play; practice mode allowing unlimited replay is the primary mode distinction driving this spec.
- Composition is set before a session is opened, consistent with the current `SessionController` flow (`create` → `setComposition` → `open`).
- `authoring`'s `audioPromptRef` always resolves to a valid, already-uploaded `media` object; this spec does not handle missing/failed audio uploads.

**Status:** all clarifications resolved — see FR-02.
