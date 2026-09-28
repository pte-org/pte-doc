# ADR-011: Practice Anti-Cheat Policy and Student Audit Boundary

**Date:** 2026-09-28  
**Status:** Accepted for the current release gate  
**Depends on:** [ADR-001](ADR-001-module-boundaries.md), [ADR-010](ADR-010-dynamic-task-type-screen-contract.md)

## Context

Practice exams need two explicit behaviors:

- `PRACTICE` with anti-cheat disabled must remain windowed and must not arm
  lockdown controls.
- `PRACTICE` with anti-cheat enabled must reuse the existing desktop controls,
  but a violation must warn and create an audit record without pausing,
  force-submitting, invalidating, terminating, or changing scoring behavior.

Official exams retain the existing `STRICT` behavior. The policy is already
represented by `ExamPolicy.lockdownMode`, copied into the immutable attempt
snapshot, so a second persisted boolean would create two sources of truth.

The student desktop app also needs an authenticated audit path. A student event
must not be represented as a fake proctor session because the proctor event
table requires proctor ownership and has different hash-chain semantics.

## Decision

Use the existing policy enum as the canonical contract:

| Exam mode | Host setting | Persisted policy | Desktop behavior |
|---|---|---|---|
| `PRACTICE` | Anti-cheat off | `NONE` | Windowed, no lockdown activation |
| `PRACTICE` | Anti-cheat on | `STANDARD` | Fullscreen, clipboard/shortcut hooks, warning and audit only |
| `OFFICIAL_EXAM` | No practice setting | `STRICT` | Existing strict controls and critical audit |

`pte-app` reads only the pinned attempt policy. Activation happens before sync,
timer startup, or task rendering. Missing or unknown policy data fails closed;
only an explicit `NONE` value is a no-op.

Student audit events use:

```text
POST /api/v1/attempts/{attemptPublicId}/security-violations
```

The request contains only a client event UUID, an allowlisted violation type,
an optional client occurrence time, and bounded detail. The backend derives
student, tenant, attempt ownership, severity, and server receive time. Local
Drift persistence precedes delivery, and `(attempt, clientEventId)` provides
idempotent retry behavior.

## Trust boundaries

1. The session backend validates the mode/policy combination.
2. The attempt snapshot pins the effective policy at attempt creation.
3. The desktop app treats the pinned policy as input, not as a value inferred
   from exam mode.
4. The operating system/native channels own fullscreen, clipboard, shortcut,
   and configured strict forbidden-app controls.
5. The backend is authoritative for identity, severity, timestamps, policy,
   and duplicate suppression.

Practice `STANDARD` remains observational. The warning stream is UI feedback;
it is not a command path into attempt state or scoring.

## Alternatives rejected

### Add `practiceAntiCheatEnabled` to the database

Rejected because it duplicates `ExamPolicy.lockdownMode`, creates mode/boolean
drift, and requires every client to reconcile two fields.

### Send student events to `/api/proctor/violations`

Rejected because that endpoint represents a proctor-owned event and requires a
proctor session. The authenticated attempt endpoint preserves ownership and
keeps the legacy proctor route unchanged.

### Enforce Practice violations by pausing or submitting

Rejected for this release. Practice Standard is explicitly warning/audit-only;
stronger intervention belongs to a separately approved policy and UX decision.

### Fall back unknown app policy to `NONE`

Rejected because malformed or future policy data could silently disable
controls. New attempts fail closed until the contract is understood.

## Migration, retention, and rollback

The student audit table is additive. The selected Flyway chain ends at `V70`
(`V70__attempt_security_events.sql`), with the duplicate unapplied `V68` chain
re-sequenced and documented in Phase 3. Student audit rows are retained for
180 days from server `detectedAt`; Platform Operations owns the setting and a
daily job marks expired rows `deleted=true` without hard deletion. Reads exclude
deleted rows.

Rollback is additive:

- hide or disable creation of new Practice `STANDARD` sessions;
- keep the backend endpoint, table, and idempotency contract available for
  already released clients;
- do not downgrade pinned attempts or delete audit data;
- if the desktop client is rolled back, retain the endpoint so pending events
  remain compatible.

## Release-gate fixture

The app contains a compile-time-only activation failure fixture. It is enabled
only with:

```text
--dart-define=PTE_LOCKDOWN_ACTIVATION_FAILURE_FIXTURE=true
```

It is used only for a non-distributable release validation artifact. The
production build is created without that define (or with it explicitly set to
`false`); `DEV_SKIP_AUTH` is never enabled for a release artifact. The fixture
must not be used in distribution.

## Consequences

Positive consequences:

- one policy source of truth across host, backend, snapshot, and desktop;
- Practice can be controlled without changing exam navigation, timer, answer
  sync, media upload, scoring, or reporting;
- audit delivery survives offline periods and process restarts without
  confusing student and proctor ownership.

Costs and limits:

- native Windows release verification is required; Dart unit tests alone do
  not prove the OS hooks;
- the current release gate does not add continuous recording, screen capture,
  VM detection, multi-monitor controls, or a proctor workflow;
- host/proctor manual walkthrough is a separate scope item from the student
  desktop gate and must not be inferred from local student tests.
