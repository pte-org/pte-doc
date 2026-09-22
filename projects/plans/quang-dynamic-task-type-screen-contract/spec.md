# Spec: Dynamic Task Type and Screen Contract

Status: Draft for implementation planning
Date: 2026-09-22
Scope: pte-api, pte-web, pte-app, pte-doc
Relationship: Follow-on/superseding design for the completed standard-runtime plan

## Problem

The existing catalog UI says “Create task type”, but the backend accepts only
the 23 values of PteTaskType. The current runtime registry, question entity,
template validator, scoring switches, and Flutter dispatcher are all keyed by
that enum. A genuinely new task type is therefore impossible even when it
could reuse an existing screen and scoring contract.

The prior plan at
pte-doc/projects/plans/quang-task-type-catalog-template-runtime-contract/
completed the standard PTE runtime foundation and intentionally kept arbitrary
task types out of scope. This spec changes that boundary without deleting the
standard compatibility path.

## Approved direction

Platform Admin or Platform Author can create a task type with:

- taskTypeKey: typed by the user, normalized uppercase, format-validated,
  immutable identity, and hard unique.
- displayName: user-facing label, normalized by trim plus collapsed
  whitespace and hard unique without case sensitivity.
- shortName: user-facing compact label.
- section: one of the existing platform sections.
- screenKey: selected from an allowlisted capability registry; never an
  arbitrary class name, script, JSON formula, or executable identifier.
- lifecycle and display-order fields as required by the existing catalog.

The selected screen/capability contract supplies behavior, answer schema,
scoring profile, required client capabilities, and supported app versions.
Creating a task type that reuses an existing contract must not require a new
pte-app implementation.

A genuinely new interaction, answer schema, capability, or scoring behavior
requires a coordinated backend and pte-app release plus a new immutable,
allowlisted contract version.

## Template and runtime rules

- The backend does not scan an installed APK or IPA. It validates the
  server-side capability registry and receives a declarative pte-app manifest
  during preflight.
- Draft templates may be saved with runtime readiness problems.
- Submit or activation must stop with a friendly, actionable list of missing or
  incompatible contracts.
- STANDARD_PTE templates retain the existing requirement for the 22 scored
  standard PTE task types.
- CUSTOM templates use selected task types and do not inherit that global
  22-task completeness rule.
- CUSTOM templates may mix scored and unscored tasks. Unscored contracts use
  the allowlisted scoring profile NONE/V1 and have zero weight; scored entries
  must have an active scoring profile. Each represented skill column's scored
  weights must sum to 100.00, unrepresented skill columns must sum to 0.00,
  every weight must be 0.00–100.00 with at most two decimals, and overall
  weights need only have a positive total. An all-unscored CUSTOM template is
  rejected for this score-template domain.
- Every published template item, generated snapshot, and pinned attempt item
  stores task key, screen key, contract/profile versions, scoring provenance,
  and the display-label snapshot.
- A task type identity is never reused after publication.
- After a task type appears in any template version that was ever published or
  active, taskTypeKey and all runtime-integrated fields are immutable forever.
  Archive, retire, or unpublish does not unlock them.
- Before first published use, screenKey and its runtime binding may change to
  another valid registry contract. taskTypeKey remains immutable after create
  to protect references and cache keys.
- Display metadata may remain editable because published snapshots retain old
  values.

## Compatibility and ownership

- Keep /api/v1/question-types, its table, legacy request fields, legacy
  response fields, and the 23 standard behavior adapters. That legacy API is
  a standard-only projection and never exposes a custom key through an
  enum-valued field.
- Add /api/v1/task-types as the canonical dynamic catalog API, with
  taskTypeKey, runtime contract, readiness, and editability fields. Use
  additive columns and dual-read/dual-write migration seams.
- code remains a storage/compatibility alias equal to taskTypeKey for new rows,
  while the legacy endpoint projects standard rows only; taskTypeKey becomes
  the canonical logical identity. A legacy client requesting a custom key gets
  a stable compatibility error rather than a fabricated enum value.
- Platform roles own task-type and runtime-contract writes. Tenant and host
  roles consume active templates and cannot mutate platform definitions.
- Machine error codes remain stable for clients and telemetry; user-facing
  messages are centralized and friendly.

## Minimum acceptance set

1. read_aloud_plus, padded input, and lowercase variants normalize to one key;
   duplicate creation returns HTTP 409 even under concurrent requests.
2. A normalized duplicate display name is rejected independently of key, with
   the exact NFKC/Unicode-whitespace/Locale.ROOT normalization shared by Java,
   the availability endpoint, and the web form.
3. Two custom task keys can reuse one screen, behavior, and scoring contract.
4. A custom task can be authored and used in a CUSTOM template without adding
   an enum value or pte-app screen code.
5. A draft persists while its runtime contract is missing or unsupported;
   activation returns all actionable readiness failures.
6. A standard 22-task template still activates under STANDARD_PTE.
7. A published task type remains runtime-locked after template retirement.
8. Old snapshots and attempts render from pinned provenance after catalog
   labels, profiles, or task rows change.
9. pte-app reports unsupported screen/schema/version as a terminal update state
   and never silently advances to the next task.
10. Tenant and host callers cannot create, edit, activate, or replace platform
    task-type definitions.

11. Custom questions can persist with a non-null taskTypeKey and nullable
    legacy enum columns; custom create/list/count/random/freeze/generation
    paths do not dereference the enum.
12. Runtime contracts include a versioned authoring contract; question
    requirement flags are derived from it and cannot be supplied as authority
    by the client.

The normalization fixture must cover NFKC full-width input, surrounding
Unicode padding, lowercase input, the 2-character minimum, the 64-character
maximum, overlength, internal key whitespace, invalid leading characters, and
display-name whitespace/case folding. Java, TypeScript, Dart, and migration
tests consume the same expected vectors.

## Explicit non-goals

No tenant-defined executable scoring formulas, uploaded renderer scripts,
dynamic class loading, arbitrary answer schemas, binary APK/IPA inspection,
automatic migration of unknown historical codes, or removal of the existing
standard PTE enum adapters.
