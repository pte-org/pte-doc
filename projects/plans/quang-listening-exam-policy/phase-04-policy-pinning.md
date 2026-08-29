# Phase 4: Policy Pinning & Immutability at StartAttempt

**Covers:** FR-04 · User stories: P1 (immutable policy enforcement)
**Depends on:** Phase 1 (ExamPolicy foundation), Phase 2 (partial update), Phase 3 (composition item overrides)

---

## Requirements

Extend `exam-delivery`'s internal `SchedulingEntitlementResponse` DTO to include the resolved `ExamPolicy` fields (replayPolicy, deviceCheckRequired, proctorRequired, answerIntegrityLevel) and each `CompositionItem`'s `maxPlayCount` override. At `StartAttempt` time, `SnapshotPinService` (or the pin-time logic in `AttemptService`) must copy these policy fields into new immutable columns on `PinnedExamSnapshot` (session-level policy fields) and `PinnedItem` (per-item maxPlayCount). Once pinned, the policy is immutable for the lifetime of the attempt — no subsequent fetch from scheduling updates these values. This preserves the architectural invariant: "exam-delivery never makes runtime calls to scheduling beyond StartAttempt."

Maps to: **P1 Story #4 (policy immutability during attempt)**

---

## Design Constraints

- Create an internal exam-delivery-only DTO for policy snapshot (do not modify or extend pte-common's `SchedulingEntitlementResponse` public contract; use adapter/mapper pattern to convert into internal DTO at the scheduling API boundary).
- Policy pinning must be atomic with attempt creation — fetch policy + insert/update attempt + insert pinned policy in single transaction, or at minimum fetch-then-insert with row-level locking to prevent TOCTOU races.
- No runtime call-backs to scheduling after the pin — exam-delivery must never call scheduling's API during task-serving or play requests; all policy data must come from `PinnedExamSnapshot`/`PinnedItem` columns.
- Audio URL resolution is NOT part of Phase 4 pinning (that's Phase 6); Phase 4 focuses on exam policy fields only.
- `answerIntegrityLevel` is pinned (reserved for task 20) but not acted upon by Phase 4; Phase 4 copies it into the snapshot but does not implement encryption/hashing.

---

## Steps

1. Add columns to `pinned_exam_snapshot` table (or equivalent entity) for session-level policy fields: `replay_policy_type` (enum or string), `replay_policy_count` (int, nullable if UNLIMITED), `device_check_required` (boolean), `proctor_required` (boolean), `answer_integrity_level` (enum or string).

2. Add column to `pinned_item` table (or equivalent entity) for per-item override: `max_play_count_override` (int, nullable — null means inherit session default).

3. Create an internal DTO `SchedulingPolicySnapshot` (or add fields to an existing internal snapshot DTO) that mirrors the pinned columns; this is exam-delivery's-internal representation, not exposed in public APIs.

4. Implement a boundary/adapter that fetches `SchedulingEntitlementResponse` from the scheduling microservice API at StartAttempt time, extracts the policy fields and per-item overrides, and converts them into the internal `SchedulingPolicySnapshot`.

5. Update `SnapshotPinService` (or the equivalent pin-time logic in `StartAttempt` / `AttemptService`) to accept the policy snapshot and persist it alongside the attempt and pinned items in a single transaction.

6. Add query methods (e.g., `getPinnedPolicy(attemptId)`, `getPinnedItemLimit(itemId)`) in the repository layer to retrieve the pinned policy for an attempt without fetching the entire snapshot.

7. Integration test: create a session with a policy, start an attempt (pins the policy), then update the session's policy in scheduling; verify that the attempt's pinned policy is unchanged.

8. Integration test: verify per-item overrides are pinned correctly (item with override shows the override value, item without override shows null in pinned snapshot).

---

## Success Criteria

- `PinnedExamSnapshot` rows contain all session-level policy fields (replay type, count, device check, proctor, integrity level).
- `PinnedItem` rows contain per-item `maxPlayCount` override (null if item has no override).
- Starting an attempt successfully pins the current policy from scheduling.
- Acceptance criterion from spec: "Editing a session's ExamPolicy after a student has already started an attempt does not change that attempt's enforced behavior" — verified by updating session policy post-pin and confirming pinned values do not change.

---

## Quality and Testing State

- Quality: **approved** (report: `quality/phase-04-policy-pinning-quality-report.json`). 1 HIGH (`SessionMapper.toPolicy()` NPE risk on null enum fields — fixed with an explicit fail-loud check instead of a silent weaker-policy fallback) + 1 MEDIUM (`SnapshotPinService.pin()` missing null-check on `entitlement.policy()` — fixed by extending the existing entitlement null-check). No cryptographic receipt (multi-repo limitation, see plan.md).
- Testing: not_started — skipped by user for this phase

---

## Risks

- **Stale policy if StartAttempt fetch fails**: If the fetch of policy from scheduling fails mid-StartAttempt, the transaction rolls back and the attempt is not created (correct). But if the rollback is not clean (e.g., partial pinning), the attempt could be in an inconsistent state. Mitigation: wrap the entire pin transaction in Spring's `@Transactional(rollbackFor = Exception.class)` or use explicit savepoint/rollback; test the failure case (mock scheduling service to throw exception mid-call).
- **DTO version mismatch**: If scheduling adds new policy fields in the future without updating its `SchedulingEntitlementResponse` DTO, exam-delivery won't know about them and will pin null values. Mitigation: add a version or schema-evolution mechanism to `SchedulingPolicySnapshot` (e.g., JSON schema version field); or document that SchedulingEntitlementResponse is a contract and changes require coordination.
- **Oversized pinned snapshots**: If per-item overrides are stored as JSON on each row (rather than separate columns), the snapshots could grow large with many items. Mitigation: use separate `pinned_item` table with FK to snapshot, as described in step 2 (normalized schema, not JSON-heavy).
