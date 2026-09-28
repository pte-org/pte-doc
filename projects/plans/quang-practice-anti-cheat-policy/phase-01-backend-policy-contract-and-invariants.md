# Phase 01 — Backend Policy Contract, Invariants, and Legacy Compatibility

**Depends on:** `spec.md` only  
**Enables:** Phases 2, 3, and 4  
**Stories:** P1 Practice configuration; P1 Official strictness; P2 policy visibility

**Status:** Complete after hard-checkpoint confirmation.

## Objective

Make `ExamPolicy.lockdownMode` a complete canonical draft create/update
contract. Store an explicit policy for new canonical sessions, preserve readable
legacy sessions, and prevent any direct API caller or mode transition from
weakening Official policy or assigning `STRICT` to Practice.

## Exact files/packages likely to change

Existing production files:

- `pte-api/app/src/main/java/com/pte/session/internal/dto/request/CreateExamDraftRequest.java`
- `pte-api/app/src/main/java/com/pte/session/internal/dto/request/PatchExamDraftRequest.java`
- `pte-api/app/src/main/java/com/pte/session/internal/dto/request/PatchExamPolicyRequest.java`
- `pte-api/app/src/main/java/com/pte/session/internal/service/ExamOrchestrationService.java`
- `pte-api/app/src/main/java/com/pte/session/internal/service/SessionLifecycleService.java`
- `pte-api/app/src/main/java/com/pte/session/domain/ExamPolicy.java`
- `pte-api/app/src/main/java/com/pte/session/domain/ExamSession.java`
- `pte-api/app/src/main/java/com/pte/session/domain/enums/LockdownMode.java`
- `pte-api/app/src/main/java/com/pte/session/internal/exception/InvalidLockdownModeException.java`
- `pte-api/app/src/main/java/com/pte/session/internal/constant/SessionConstants.java`
- `pte-api/app/src/main/java/com/pte/session/internal/policy/SessionPolicyResolver.java`
- `pte-api/app/src/main/java/com/pte/session/internal/mapper/SessionMapper.java`
- `pte-api/app/src/main/java/com/pte/session/internal/service/EntitlementService.java`
- `pte-api/app/src/main/java/com/pte/session/internal/dto/response/SessionResponse.java`
- `pte-api/app/src/main/java/com/pte/session/dto/response/ExamPolicyResponse.java`

Likely test files:

- `pte-api/app/src/test/java/com/pte/session/internal/service/ExamOrchestrationServiceTest.java`
- `pte-api/app/src/test/java/com/pte/session/internal/service/SessionLifecycleServiceTest.java`
- `pte-api/app/src/test/java/com/pte/attempt/internal/service/SnapshotPinServiceTest.java`
- the owning controller/API contract test location if one already covers
  `/api/v1/sessions/drafts` and `/policy`

No new migration is expected. `lockdown_mode` already exists in the session and
pinned snapshot schema; this phase changes the contract and invariant handling,
not persistence shape.

## Implementation steps

1. Add `LockdownMode lockdownMode` to the canonical create and patch draft
   records while retaining source-compatible constructors for existing Java
   callers. `PatchExamPolicyRequest` already exposes the enum and must retain
   its partial-update semantics.
2. Introduce separate, explicit resolution paths rather than applying one
   null-defaulting helper to every request:

   create:

   ```text
   OFFICIAL_EXAM + null       -> STRICT compatibility default
   OFFICIAL_EXAM + STRICT     -> STRICT
   OFFICIAL_EXAM + other     -> reject
   PRACTICE + null            -> NONE compatibility/default
   PRACTICE + NONE            -> NONE
   PRACTICE + STANDARD       -> STANDARD
   PRACTICE + STRICT         -> reject
   ```

   draft patch:
   mode omitted + lockdownMode omitted/null -> retain current effective policy
   mode unchanged + lockdownMode omitted/null -> retain current effective policy
   mode changed + lockdownMode omitted/null -> derive the new mode default
   explicit lockdownMode -> validate against the effective mode

   policy patch:
   lockdownMode omitted/null -> no lockdown change
   explicit lockdownMode -> validate against the current session mode

3. Update `ExamOrchestrationService` create and update flows so changing
   `examMode` cannot leave a stale policy. A supplied policy is validated with
   the new mode; a missing policy derives the new-mode default only when the
   mode actually changes. An unrelated draft patch must preserve `STANDARD`.
   The result is written to the session before preflight/generation/publish.
4. Update `SessionLifecycleService.patchPolicy` to apply the explicit-value
   invariant helper while treating null as no-op and retaining the existing
   editability/attempt-pinned boundary. A direct policy patch must not bypass
   the exam-mode rules.
5. Centralize new machine-readable validation codes and user-facing text in the
   owning session constants. Preserve existing API error text where extraction
   is needed; do not leak enum parsing exceptions.
6. Define and test `resolveEffectiveLockdownMode(examMode, persistedLockdownMode, legacyState)`
   at the session boundary. For a legacy null lockdown value it must resolve
   `PRACTICE -> NONE` and `OFFICIAL_EXAM -> STRICT`; for an invalid
   non-null value it must fail closed with a stable error. Update
   `ExamPolicy.backfillLegacyDefaults()` so it does not assign a
   mode-independent `STANDARD` lockdown value from `mockTestDefault()`.
   Normalize the effective value before both `SessionResponse` mapping and
   snapshot pinning; do not rely on the embeddable's `@PostLoad` alone.
7. Ensure `SessionResponse.policy.lockdownMode` is normalized for new sessions
   and legacy null rows using the documented exam-mode default. Verify snapshot
   pinning copies the resolved policy and that attempt task responses expose the
   pinned value. No attempt should infer the mode from `examMode` after pinning.
8. Leave the legacy `POST /api/v1/sessions` route behavior unchanged. It remains
   a migration/fail-closed route and is not the new UI contract.

## Contract and data flow

```text
CreateExamDraftRequest.lockdownMode
       -> ExamOrchestrationService policy resolver
       -> session.examPolicy.lockdownMode (explicit for new session)
       -> publish/open boundary
       -> SnapshotPinService
       -> pinned_exam_snapshots.lockdown_mode
       -> AttemptTaskResponse.lockdownMode
```

The response policy is the value the host sees. The attempt response is the
value the student app enforces. A later host edit cannot mutate a pinned
attempt.

## Dependencies and handoff

- Uses the existing `LockdownMode` enum and `ExamPolicy` domain object.
- Uses the existing `lockdown_mode` columns in `V8__session.sql` and
  `V9__attempt.sql`; do not add `anti_cheat_enabled`.
- Must complete before tenant-web sends the new field and before app release
  verification relies on `STANDARD` being returned.

## Acceptance criteria

- [x] Canonical draft create and patch accept `lockdownMode` and responses
  return the resolved policy.
- [x] Practice unchecked resolves to `NONE`; Practice controlled resolves to
  `STANDARD`.
- [x] Official always resolves to `STRICT`; explicit `NONE`/`STANDARD` requests
  are rejected with a stable validation result.
- [x] Practice `STRICT` is rejected through both draft and policy patch APIs.
- [x] Mode changes cannot preserve a policy invalid for the new mode.
- [x] A Practice session with `STANDARD` remains `STANDARD` after a patch that
  changes only retry, audience, timing, skills, or another non-policy field.
- [x] A session's policy is pinned into the attempt snapshot before the first
  task response and is immutable thereafter.
- [x] Existing null-policy sessions remain readable with the documented
  mode-aware legacy default, while new canonical writes are explicit.
- [x] The legacy `@PostLoad` path cannot turn a Practice null policy into
  `STANDARD`, and an invalid non-null policy fails closed.
- [x] No new database boolean or migration is introduced in this phase.

## Design Constraints

- **Preflight:** The backend follows Java record DTOs with explicit
  source-compatible overloads, centralizes session validation text in
  `SessionConstants`, mutates session state inside service transactions, and
  maps responses through `SessionMapper`; this phase keeps those conventions
  and limits policy ownership to the session boundary while preserving the
  existing legacy create route.
- `ExamPolicy.lockdownMode` is the only persisted source of truth.
- Backend validation is authoritative; the browser must not be trusted to hide
  `STRICT` or enforce the Practice/Official relationship.
- Preserve the existing endpoint paths and JSON compatibility for callers that
  do not yet send the optional field.
- Keep module boundaries explicit: session orchestration owns session policy;
  attempt snapshot pinning owns the immutable attempt copy.
- Do not change skill selection, retry policy, timer, navigation, generation,
  scoring, or report publication semantics.
- Do not change the old proctoring violation model in this phase.

## Quality and Testing State

**Quality:** approved; no blocking findings. Report: `quality/phase-01-backend-policy-contract-and-invariants-quality-report.json`. Receipt verified: `quality/phase-01-backend-policy-contract-and-invariants-receipt.json`.  
**Testing:** passed; 81 focused tests, 0 failures, 0 errors, 0 skipped. Report: `tests/phase-01-backend-policy-contract-and-invariants-test-report.json`.

Required verification after implementation:

- Unit tests for every mode/policy pair, null compatibility, mode transitions,
  policy patch editability, and Official/Practice negative cases.
- Snapshot pin test proving the resolved value is copied and not inferred later.
- API contract tests proving response shape and stable validation codes.
- Compile the `pte-api` app module and run the focused session/attempt tests;
  record any unrelated dirty-worktree failure instead of suppressing it.
