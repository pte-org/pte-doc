# Phase 2: ExamPolicy Partial Update Endpoint

**Covers:** FR-02 · User stories: P2 (policy override after creation)
**Depends on:** Phase 1 (ExamPolicy foundation)

---

## Requirements

Add a `PATCH /sessions/{id}/policy` endpoint in scheduling's `SessionController`, authorized for `HOST_ADMIN` and `HOST_AUTHOR` (same roles as `POST /sessions` and `setComposition`), allowing partial override of `ExamPolicy` fields after session creation. The update must use partial-update semantics: omitted fields remain unchanged. The endpoint must reject any update attempt once the session's status has passed pre-open (i.e., once `session.status` has transitioned past PENDING_COMPOSITION), with a clear rejection message. This is the hard lock point — no policy edits after open, regardless of whether students have started attempts.

Maps to: **P2 Story #2 (policy override on edge cases)**

---

## Design Constraints

- Once a session is opened (`SessionStatus` >= OPEN or its equivalent), reject all policy-update requests with a 409 Conflict or 422 Unprocessable Entity, referencing the lock rule ("Cannot modify policy after session is open").
- The lock point is the session state (open/not open), never attempt count — a host cannot say "let this one student get 2 replays retroactively" if the session is already open.
- Partial update semantics: only fields provided in the request body are modified; omitted fields retain their current value.
- Authorization check must run before the lock-point check (so an unauthorized user gets 403, not 409).
- Rejection must be idempotent: attempting the same forbidden update twice returns the same error both times, not a transient failure.
- **`open()` must take the same lock — in scope for this phase**: the row-lock mitigation for the open-vs-patch race only holds if `SessionService.open()` also acquires a pessimistic write lock on the session row before transitioning status. If `open()` currently updates status without one, add it as part of this phase (not deferred) — a step in this file, using the same `SELECT ... FOR UPDATE` / `@Lock(LockModeType.PESSIMISTIC_WRITE)` pattern as `patchPolicy()`.

---

## Steps

1. Add a DTO `PatchExamPolicyRequest` with optional fields for each `ExamPolicy` component (`replayPolicy`, `deviceCheckRequired`, `proctorRequired`, `answerIntegrityLevel`), using Optional or nullable types to distinguish "not provided" from "explicitly set to null/false."

2. Implement `SessionService.patchPolicy(sessionId, patchRequest)` as a single `@Transactional` method that: (a) loads the session row with a pessimistic write lock (`SELECT ... FOR UPDATE`, e.g. `@Lock(LockModeType.PESSIMISTIC_WRITE)` on the repository finder), (b) checks authorization, (c) checks the lock point against the locked row's status, (d) applies the merge and persists — all inside the same transaction. This is REQUIRED, not a suggestion: fetch/check/update as three separate calls without a held lock allows a concurrent `open()` to slip between the status check and the write (see Phase 2 Risks — red-team ACCEPTED finding).

3. Merge the patch onto the current policy: iterate over each field in the patch; if present, update the corresponding `ExamPolicy` field; otherwise leave unchanged. Result is the merged policy object.

4. Persist the updated session and return the updated `ExamPolicy` in the response DTO.

5. Add `PATCH /sessions/{id}/policy` endpoint in `SessionController` that invokes `SessionService.patchPolicy()` and returns 200 OK with the updated policy, or 409 if session is open, or 403 if unauthorized.

6. Add database-level constraint or application-level check to ensure that once `session.status` is no longer PENDING_COMPOSITION, no further updates are accepted (redundant safety against ORM lazy-load surprises).

7. Check `SessionService.open()`'s current implementation; if it does not already take a pessimistic write lock on the session row before transitioning status, add one so it uses the same lock as `patchPolicy()` (Step 2) — required for the concurrency mitigation below to actually hold, not optional hardening.

8. Integration test: create a session, patch its policy pre-open (succeeds), patch again post-open (fails with 409); verify omitted fields remain unchanged after partial patch.

9. Integration test: attempt patch as HOST_AUTHOR on their own session (succeeds), as different-tenant HOST_AUTHOR (fails with 403).

---

## Success Criteria

- `PATCH /sessions/{id}/policy` with valid data pre-open returns 200 and updates only the provided fields.
- Patching after session is opened returns 409 Conflict regardless of how many attempts have started.
- Omitted fields in the patch request remain at their previous values; the patch is truly partial.
- Unauthorized users (non-HOST_ADMIN, non-HOST_AUTHOR for the session's tenant) receive 403.
- Acceptance criterion from spec: "same call after `open()` is rejected regardless of attempt count."

---

## Quality and Testing State

- Quality: **approved** (report: `quality/phase-02-policy-partial-update-quality-report.json`). 0 findings — race-condition closure, lock-point check, and validation all confirmed correct. No cryptographic receipt (multi-repo limitation, see plan.md).
- Testing: not_started — skipped by user for this phase

---

## Risks

- **Race condition at session-open boundary — RESOLVED, not a residual risk**: Step 2 now mandates `SELECT ... FOR UPDATE` on the session row inside a single transaction spanning fetch/check/update, so `open()` (which must take the same row lock to transition status) and `patchPolicy()` cannot interleave — one blocks until the other's transaction commits. Test with concurrent patch + open via integration test to confirm the lock actually serializes them (not just that both individually pass).
- **Unclear semantics for null/omitted in JSON patch**: If a client sends `{"replayPolicy": null}` vs. omitting the field entirely, does null mean "clear to default" or "don't change"? Mitigation: define the DTO carefully — use Optional<T> or a separate "present" flag per field; document that omitting a field means "no change," and sending null (if allowed) clears to a default value (or reject null as invalid for non-nullable enum fields).
- **Authorization scope creep**: If the endpoint later needs to allow PROCTOR or STUDENT roles to patch policies (unlikely but precedent-setting), the current authorization will need refinement. Mitigation: lock authorization to HOST_ADMIN and HOST_AUTHOR only as specified; add explicit note in phase constraints that this is intentionally restrictive.
