# ADR — Practice Boundary and Compatibility

## Context

The current attempt APIs are designed around host-created exam sessions,
enrollment and official reports. The new student web needs self-selected
practice while preserving the official exam lifecycle.

## Decision

Use a student-facing `PracticeSession` aggregate/facade for product lifecycle,
entitlement and progress. Reuse the existing attempt execution seams for pinned
items, runtime profiles, timing, answer validation, heartbeat and protected
media. Every execution is explicitly marked as `PRACTICE`; official
`ExamSession` enrollment and published-report paths are not used as the
practice authorization boundary.

The aggregate owns:

- product/catalog selection and organization context;
- empty/discarded versus resumable draft state;
- idempotency and optimistic version checks;
- practice progress/history ownership.

The reused execution layer owns:

- immutable task pinning and safe task delivery;
- runtime profile allowlisting and answer schema validation;
- deadline/heartbeat primitives;
- media access and scoring seams where compatible.

The Phase 02 schema is fixed at the contract level as follows:

```text
practice_sessions
  public_id (unique), identity_id, tenant_id, product_code,
  status, version, started_at, deadline_at, completed_at, discarded_at
        1 ─────────────── 0..1
practice_session_attempts
  practice_session_id, exam_attempt_id, source_type = PRACTICE
        1 ─────────────── 0..*
exam_attempts / attempt_answers / pinned snapshot
```

`PracticeSession` owns product lifecycle, entitlement re-check, empty/discard
semantics, idempotency and Progress ownership. The reused execution record owns
task pinning, current item, answer payload and runtime timing. `source_type` and
the practice-session link are additive and are excluded from official report
queries unless an explicit practice projection asks for them. A practice
session may have no execution record until preflight succeeds; it never creates
an official host enrollment.

## Consequences

- A new facade and additive persistence are required; this is intentionally not
  a frontend-only feature.
- Existing official exam APIs remain backward compatible.
- Phase 02 implements the fixed relationship above with additive migrations and
  the repository's next versioned migration number; no repository crossing is
  allowed.
- A practice result cannot automatically become an official report.

## Rejected alternatives

- Reusing host-created exam sessions directly: couples self-practice to codes and enrollment.
- Implementing task selection/scoring in `pte-practice`: bypasses authorization and duplicates canonical runtime behavior.
- Creating a completely separate question engine: duplicates pinning, timing, media and schema contracts.
