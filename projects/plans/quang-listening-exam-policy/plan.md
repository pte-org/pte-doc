# Plan: Listening Exam Policy Engine & Audio Delivery Enforcement

**Spec:** [spec.md](spec.md)
**Date:** 2026-08-27
**Status:** Completed
**Mode:** Hard
**Created by:** Plan Agent

---

## Overview

This plan delivers a mode-aware exam policy engine for listening tasks, bridging `scheduling` (policy definition and enforcement at session level) and `exam-delivery` (pinned, immutable policy enforcement at attempt level). Hosts can set exam mode (PRACTICE, MOCK_TEST, REAL_EXAM) and get sensible defaults (replay limits, device checks, proctor requirement); students cannot replay audio beyond policy limits; listening tasks are protected from policy edits after session open; and audio delivery is pinned immutably at attempt start, preserving the project's architectural invariant: "exam-delivery never fetches policy data at runtime beyond StartAttempt."

## Phases

- [x] Phase 1: ExamPolicy Foundation & Mode Defaults [quality: approved (manual, no receipt — see Cook-time infra note); testing: skipped_by_user] — Add `ExamMode` enum and `ExamPolicy` value object to scheduling; implement mode → policy resolution in `SessionService.create()` with sensible defaults (REAL_EXAM → LIMITED(1) replay + device+proctor checks + STRICT integrity; PRACTICE → UNLIMITED + no checks + STANDARD integrity; MOCK_TEST → middle ground).
- [x] Phase 2: ExamPolicy Partial Update Endpoint [quality: approved, 0 findings; testing: skipped_by_user] — Add `PATCH /sessions/{id}/policy` in scheduling for `HOST_ADMIN` and `HOST_AUTHOR`; hard-reject once session is past pre-open (session.status > PENDING_COMPOSITION).
- [x] Phase 3: Composition Item Replay Overrides [quality: approved, 1 medium fixed; testing: skipped_by_user] — Extend `CompositionItemRequest` with optional `maxPlayCount`; when set, overrides session-level replay policy for that task only; null means inherit session default.
- [x] Phase 4: Policy Pinning & Immutability at StartAttempt [quality: approved, 1 high + 1 medium fixed; testing: skipped_by_user] — Extend `exam-delivery`'s internal `SchedulingEntitlementResponse` to carry resolved policy and per-item `maxPlayCount`; pin both into `PinnedExamSnapshot`/`PinnedItem` columns at `StartAttempt` and never re-fetch for the attempt's lifetime.
- [x] Phase 5: Device Check Gate & Endpoint [quality: approved, 0 findings, design revised mid-cook (flag on StartAttemptRequest, no separate endpoint); testing: skipped_by_user] — Add `deviceCheckPassedAt` to `ExamAttempt`; implement `POST /attempts/{id}/device-check` endpoint; reject `StartAttempt` if pinned policy requires device check and field is null.
- [x] Phase 6: Play Count Enforcement & Audio URL Resolution [quality: approved, 1 high fixed; scope expanded to media service (new presigned-GET capability); testing: skipped_by_user]

**Plan status: COMPLETED — all 6 phases done.** — Add `playCount` to `TimerState` (reset per task); audio-serving endpoint increments and rejects at limit; resolve listening audio URLs from `media` exactly once at `StartAttempt` with TTL exceeding max session duration.

## Research Summary

Architectural decisions locked during brainstorm + research (applied as-is, no re-derivation):

1. **ExamPolicy as @Embeddable value object** on `scheduling`'s `ExamSession` entity — single-valued, session-scoped (mirrors `SessionComposition`'s per-item override pattern, but ExamPolicy is not one-to-many).

2. **Mode-based defaults** — REAL_EXAM → LIMITED(1) + both booleans true + STRICT; PRACTICE → UNLIMITED + both booleans false + STANDARD; MOCK_TEST → LIMITED(3) + proctor only + STANDARD (middle ground).

3. **Partial update with hard lock** — `PATCH /sessions/{id}/policy` allowed for `HOST_ADMIN`/`HOST_AUTHOR` only before session.open(); once status passes pre-open, all edits rejected regardless of attempt count (lock point is the state transition, not attempt count).

4. **Item-level overrides** — `maxPlayCount` on composition items follows the established precedence: if set (not null), overrides session default; null means inherit. No change to `timingOverrideSeconds` pattern.

5. **Pinning immutability** — `exam-delivery`'s `SnapshotPinService` (or StartAttempt logic) copies resolved policy + per-item limits into `PinnedExamSnapshot` and `PinnedItem` columns once at pin time; no runtime callbacks to scheduling — preserves the stated invariant: "dependency runtime chỉ đi VÀO exam-delivery qua event, không đi ra."

6. **Audio URL resolution at pin time** — Single presigned URL fetch from `media` at `StartAttempt`, stored on `PinnedItem` with TTL > max attempt duration; never re-fetched per task-view or play request.

7. **Device check before StartAttempt** — New endpoint records pass; StartAttempt gate checks for null when policy requires it; clear exception message signals the gate.

8. **PlayCount per task, reset on task advance** — `TimerState.playCount` is 0-initialized and incremented on each play request; resets to 0 when `currentOrderIndex` advances (linear listening, no back-navigation).

## Dependencies

- Existing `scheduling` service with `SessionService`, `CompositionService`, `SessionController` and `SessionStatus` enum.
- Existing `exam-delivery` service with `AttemptService`, `SnapshotPinService` (or equivalent pin-time logic), `ExamAttempt` entity, `TimerState`.
- Existing `media` service with audio-resolution capability (via `audioPromptRef` in `AuthoringSnapshotContentResponse`).
- Existing `pte-common` DTOs for `SchedulingEntitlementResponse` and related contracts (do not modify shared; use internal `exam-delivery`-only DTOs for policy fields).

## Risks

- **HIGH: Policy state race at session open — RESOLVED in Phase 2**: red-team review confirmed the original mitigation was stated as advice, not a hard requirement; Phase 2 Step 2 now mandates a pessimistic row lock spanning fetch+check+update, with a note that `open()` must take the same lock for the mitigation to actually hold.
- **HIGH: Audio URL TTL miscalculation** — If presigned URL expires before student finishes the task, audio-serving fails mid-attempt. Resolved: TTL is derived from `session.closesAt - session.opensAt` (the session's own opening window, always ≥ any single attempt's duration) plus a grace window, not an invented `maxDurationSeconds` field that doesn't exist on `ExamSession`; log expiration time with the pin; validate TTL >= expected max in integration tests.
- **MEDIUM: Pinning DTO shape collision** — If `SchedulingEntitlementResponse` in pte-common is modified later for other features, this plan's internal `exam-delivery` policy fields risk being exposed unintentionally. Mitigation: create a separate internal DTO (`SchedulingPolicySnapshot`) for exam-delivery's use; map from `SchedulingEntitlementResponse` at the boundary; never return policy fields in public APIs.
- **MEDIUM: Device check endpoint auth** — If `POST /attempts/{id}/device-check` is not properly scoped to the student's own attempt, a student could mark another's device check as passed. Mitigation: validate `attemptId` belongs to authenticated student (or proctor for proctored attempts) before writing; test cross-tenant and cross-student scenarios.
- **LOW: PlayCount overflow** — Unlikely but theoretically possible: a student spams the play endpoint 2^31 times. Mitigation: use int for playCount (Java's signed int, max ~2B), operationally unreachable; if paranoid, add a sane operational ceiling (e.g., log warning at 1000 plays) separate from the policy limit.
- **NOTED (out-of-scope findings):** `AnswerSubmittedEvent` currently leaks `correctAnswerText`/`optionsJson` in plaintext (separate finding). Task 20 (answer submission encryption) will consume the `answerIntegrityLevel` field this plan introduces but does not implement the encryption mechanism.

### Cook-time infra note (applies to all 6 phases)

- `ck:quality`'s receipt mechanism (`scripts/receipt.py`) requires one git repo containing both the quality report and every reviewed file. This project is 4 separate repos (`pte-api`, `pte-app`, `pte-web`, `pte-doc`) under a non-repo parent (`pte-org`); plans live in `pte-doc` but reviewed code lives in `pte-api`. No single root covers both, so receipt issuance always fails here — this is a tooling/structure mismatch, not a finding about the code.
- Decision: skip cryptographic receipts for this plan. Each phase's `## Quality and Testing State` records `quality: approved` (or `changes_required`) directly from the `ck:quality --gate` review result, with the report saved under `quality/{phase}-quality-report.json` in this same plan directory for audit trail — this is a recorded reviewer decision, not a hash-verified one. Do not re-attempt receipt issuance in later phases; it will fail the same way.

### Red-team findings (NOTED — acknowledged, not blocking, watch during implementation)

- **Partial deployment / rollback hazard**: Phases 4–6 add hard schema dependencies across services (Phase 5's `deviceCheckPassedAt` on `exam_attempt`, Phase 6's `playCount` on `timer_state`). Rolling back a single phase while leaving others deployed can break code that expects a column the rollback removed. Mitigation: cook and deploy Phases 4–6 as one unit; never roll back a single phase in isolation — revert all three together if a rollback is needed.
- **Auth-gating pattern left implicit**: Phase 5 and Phase 6 both say "validate the attempt belongs to the caller" without naming the mechanism. Implementation should follow whatever ownership-check pattern `exam-delivery`'s existing `AttemptController`/`AttemptService` already uses for `StartAttempt`/`SubmitAnswer` (there is almost certainly an existing pattern — reuse it, don't invent a new one for these two endpoints).
- **Presigned URL can go invalid before its stated TTL**: if `media` revokes or the underlying object is deleted, the URL fails even though `audioUrlExpiresAt` hasn't passed. Not handled by this plan; if it becomes a real issue in testing, add a client-facing "audio unavailable, contact support" error path rather than a silent failure.
- **"Never re-fetch from scheduling" is a scope boundary, not a permanent constraint**: if a future requirement needs dynamic policy changes mid-attempt (e.g., proctor-granted accommodation), that would require deliberately revisiting this invariant with its own security review — not bolting on a quiet exception.
- **Multi-tenancy isolation is assumed, not restated per-phase**: every new endpoint in this plan must enforce the same tenant-scoping the rest of `scheduling`/`exam-delivery` already enforces. Called out here once rather than repeated in every phase file.
- **Audio URL column sizing**: `PinnedItem.audioUrl` should be `TEXT`, not a short `VARCHAR`, since real presigned URLs can run close to 1KB with signature query params.

---

## Cook Order Recommendation

Phases must be implemented in sequence due to dependency chain:

1. Phase 1 (scheduling policy foundation)
2. Phase 2 (scheduling partial update)
3. Phase 3 (scheduling composition overrides)
4. Phase 4 (exam-delivery pinning) — unblocks Phase 5 & 6
5. Phase 5 (exam-delivery device check gate)
6. Phase 6 (exam-delivery play count + audio delivery)

Suggested invocation:

```
/ck:cook pte-doc/projects/plans/quang-listening-exam-policy/phase-01-exam-policy-foundation.md
/ck:cook pte-doc/projects/plans/quang-listening-exam-policy/phase-02-policy-partial-update.md
/ck:cook pte-doc/projects/plans/quang-listening-exam-policy/phase-03-composition-item-overrides.md
/ck:cook pte-doc/projects/plans/quang-listening-exam-policy/phase-04-policy-pinning.md
/ck:cook pte-doc/projects/plans/quang-listening-exam-policy/phase-05-device-check-gate.md
/ck:cook pte-doc/projects/plans/quang-listening-exam-policy/phase-06-play-count-audio-delivery.md
```
