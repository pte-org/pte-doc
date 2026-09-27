# Phase 6: BE Behavior/Scoring Seam and Future Custom Extension Boundary

## Objective

Make the boundary between data-only template configuration and code-required
behavior explicit in the backend. Existing scoring remains correct and
versioned; a future custom task type has a safe design seam without being
enabled in this release.

## Files

- `pte-api/app/src/main/java/com/pte/itembank/` canonical profile descriptor
  and public task catalog facade
- `pte-api/app/src/main/java/com/pte/scoretemplate/internal/service/TaskTypeScoringMethods.java`
- `pte-api/app/src/main/java/com/pte/scoring/ScoringService.java`
- `pte-api/app/src/main/java/com/pte/scoring/internal/service/ScoringMethodResolver.java`
- `pte-api/app/src/main/java/com/pte/scoring/internal/service/ObjectiveScoringService.java`
- scoring/profile DTOs, snapshot scoring context and focused regression tests

## Implementation steps

1. Consolidate current fixed maps such as `TaskTypeScoringMethods` behind an
   owning, allowlisted behavior/scoring registry. The registry maps canonical
   task/profile versions to a stable `scoringProfileKey` plus executable
   validation/scoring strategies through code, not database class names or
   formulas.
2. Define the immutable scoring contract for each current profile:
   answer payload schema, validation rules, scoring method, raw-score range,
   weighting inputs and version. Keep `PERSONAL_INTRODUCTION` explicitly
   unscored and preserve current 22-task score-template rules.
3. Ensure question authoring, generation, answer submission and scoring all
   normalize the same canonical task code and resolve the same profile version.
   Cross-module consumers use public services/facades; no repository internals
   are imported across module boundaries.
4. Pin scoring profile/version and relevant weight/timing data into the
   snapshot/attempt scoring context. Activating a new scoring profile affects
   only new template/snapshot versions.
5. Add behavior/profile compatibility validation to template activation,
   snapshot publication and attempt preflight. A database row claiming an
   unknown behavior or scorer is invalid even if its task code is standard.
6. Write an extension note for a future custom registry. It must eventually
   define platform ownership, globally unique code, authoring/delivery schema,
   server validation/scoring registration, app capability, versioning,
   security review and immutable snapshot rules. Do not expose custom creation
   UI or tenant-defined executable logic now.

## Acceptance criteria

- Every current standard task resolves to one tested behavior/scoring profile;
  no duplicate hardcoded map can drift from the catalog.
- Existing objective/AI scoring outputs and 22-task weight behavior remain
  compatible for supported profile versions.
- Changing a scoring algorithm or answer schema requires a new profile version
  and cannot mutate old snapshots.
- Activation/publication/preflight rejects unknown behavior, schema or scoring
  keys with structured, friendly diagnostics.
- The documentation clearly states: configuration-only template changes need no
  app code; new interaction or scoring behavior requires BE plus `pte-app`.
- No arbitrary task code, scoring formula, script, class name or dynamic loader
  is persisted or executed.

## Design Constraints

- Keep the current scoring module as the owner of scoring strategy behavior;
  itembank owns task vocabulary/profile descriptors and exposes the public
  catalog facade, and scoretemplate owns template composition. The scoring
  module's executable registry remains internal behind its public service; no
  scoretemplate code imports scoring repositories or implementations.
- Do not weaken existing answer privacy, tenant access or score provenance.
- Do not introduce an `ExamTemplate` parallel to `ScoreTemplate`.
- Do not promise runtime support solely because a catalog row exists.
- Any new interaction/schema/scorer must be released as a coordinated contract
  and capability change, not as an admin-only database edit.

## Quality and Testing State

Status: implemented and verified on 2026-09-22. The BE registry now resolves
scoring by the allowlisted runtime profile key/version, while legacy templates
without a runtime descriptor remain readable through a compatibility adapter.
Template validation and scoring reject a profile/scoring-method mismatch with a
structured friendly diagnostic. Attempt-local snapshot context also retains
the immutable score-template version; existing timing and runtime scoring
profile fields remain pinned per item.

### Future custom-task extension boundary

This release intentionally supports only the standard `PteTaskType` catalog.
If a future product decision introduces a genuinely new interaction or scoring
behavior, the platform must first register a globally unique semantic code and
an immutable profile version in BE and `pte-app`. That profile must define the
answer schema, validation rules, renderer/capability contract, scoring strategy,
raw-score range and versioned test fixtures. Platform ownership, authorization,
security review and snapshot pinning must be approved before any authoring UI
can expose it. Database rows may select an allowlisted key/version only; they
must never contain a Java/Dart class name, formula, script or dynamic loader
instruction. Configuration-only changes to an existing profile continue to be
template data and do not require an app release.

Focused tests: 145 passed. Full backend suite: 774 passed with 0 failures,
errors or skipped tests.

Required before phase completion:

- Backend unit tests for registry allowlisting, canonical normalization,
  scoring-profile version immutability, behavior validation and legacy mapping.
- Regression tests for objective/AI scoring, `PERSONAL_INTRODUCTION`, weights,
  old snapshot scores and unknown-profile rejection.
- Run backend compile/test commands and any focused scoring integration suite.
- Mandatory `ck:quality --gate` receipt covering scoring correctness,
  provenance, module boundaries, security and future-extension containment.
