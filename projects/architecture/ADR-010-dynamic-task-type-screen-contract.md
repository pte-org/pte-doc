# ADR-010: Dynamic Task-Type Identity and Screen Contract

**Date:** 2026-09-22  
**Status:** Accepted  
**Scope:** `pte-api`, `pte-web`, `pte-app`

## Context

The standard PTE catalog is represented by `PteTaskType`, but the platform
needs to add a new logical task name without shipping a new enum value when
the interaction can reuse an existing screen and scoring contract. A catalog
label must not be allowed to claim arbitrary executable behavior.

## Decision

`taskTypeKey` is a normalized, globally unique, never-reused logical identity.
The platform author selects an allowlisted `(screenKey, contractVersion)` from
a release-owned capability registry. The registry derives renderer, answer
schema, scoring, capability and authoring requirements. It does not accept
class names, scripts, formulas or client-supplied implementation metadata.

The backend cannot inspect an installed APK or IPA. Server readiness is proven
by the release-owned registry and compatibility matrix; device readiness is
proven by the authenticated pte-app manifest/preflight request. A task key is
metadata, so two keys may reuse one screen contract. A genuinely new
interaction or scoring behavior still requires a coordinated backend and
pte-app release with a new immutable contract version.

`/api/v1/question-types` remains a standard-only compatibility projection.
`/api/v1/task-types` is the canonical dynamic surface. Published use appends a
usage record and permanently locks runtime fields, including after retirement.

## Consequences

- Standard enum aliases remain readable and standard template validation keeps
  its existing 22 scored-task rule.
- Custom keys can be authored and configured without fabricating an enum value.
- App support is explicit and unsupported tasks stop before delivery; they are
  never silently skipped.
- Runtime behavior changes require a release, while display metadata can be
  corrected without changing historical snapshots.

## Compatibility and rollout

The contract is additive and forward-only. Existing rows, snapshots, pinned
attempts, endpoint names and legacy fields remain readable. Custom creation and
strict activation are rolled out behind safe defaults after migration,
manifest, audit and compatibility checks. The previous runtime decision is
retained in [ADR-009](ADR-009-task-type-runtime-contract.md); this ADR
supersedes only its standard-only vocabulary assumption.
