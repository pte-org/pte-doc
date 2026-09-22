# Phase 1 — Domain Contract, Compatibility Policy, and ADR Delta

## Goal

Freeze the vocabulary and ownership rules before changing persistence or
runtime code. Turn the approved product direction into one backend/web/app
contract that supports arbitrary taskTypeKey values while retaining the
standard PteTaskType adapter.

## Dependencies

- Prior standard-runtime plan phases 1–8 and their existing API/runtime fields.
- The new bundle spec.md and plan.md.
- No implementation phase in this bundle may change the contract after Phase 1
  without recording an explicit compatibility decision.

## Exact files/modules likely affected

- pte-doc/projects/plans/quang-dynamic-task-type-screen-contract/spec.md
- pte-doc/projects/plans/quang-dynamic-task-type-screen-contract/plan.md
- pte-doc/projects/architecture/ADR-010-dynamic-task-type-screen-contract.md
- pte-doc/projects/architecture/ADR-009-task-type-runtime-contract.md
  (reference/status cross-link only; do not rewrite historical decisions)
- pte-api/app/src/main/java/com/pte/itembank/TaskTypeCodeCompatibility.java
- pte-api/app/src/main/java/com/pte/itembank/TaskRuntimeProfileDescriptor.java
- pte-api/app/src/main/java/com/pte/itembank/internal/constant/ItembankConstants.java
- pte-api/app/src/main/java/com/pte/scoretemplate/internal/constant/ScoreTemplateConstants.java
- pte-web/packages/api-client/src/types/questiontype/index.ts
- pte-app/lib/core/constants/task_type_meta.dart
- new contract DTO/value objects under the owning module packages

## Implementation steps

1. Define one normalizer for taskTypeKey: Unicode NFKC, remove surrounding
   Unicode whitespace, uppercase with Locale.ROOT, reject empty values, and
   validate ^[A-Z][A-Z0-9_]{1,63}$. The normalized key is 2-64 characters;
   internal whitespace is not collapsed and therefore fails the regex. Keep
   raw input out of persistence.
2. Define one display-name normalizer: Unicode NFKC, convert each Unicode
   whitespace run to one ASCII space, trim, lowercase with Locale.ROOT, and
   apply the 1-128 length limit after normalization. Preserve the original
   display label for presentation.
3. Define the logical TaskTypeDefinition contract and RuntimeContract
   descriptor. Separate taskTypeKey from compatibility code, and make the
   runtime descriptor semantic-key-only. Include a versioned authoring
   contract/requirements descriptor; existing requirement flags are derived
   from it and are never client authority.
4. Define STANDARD_PTE and CUSTOM template policies and the exact meaning of
   “published use” for lock calculation.
5. Define the standard alias adapter:
   legacy code or enum values map to taskTypeKey; unknown custom keys never get
   guessed into a PteTaskType. The old /question-types API remains a
   standard-only projection; the new /task-types API carries custom keys.
6. Define stable machine errors and friendly messages in owning constants.
7. Record the architecture decision explaining why the server uses a
   capability registry and manifest instead of scanning an APK/IPA.
8. Add contract fixtures for one standard type, two custom keys sharing one
   screen contract, a missing contract, and a legacy snapshot.

## API/DB contract

Freeze the additive request and response fields from plan.md:
taskTypeKey, screenKey, contractVersion, runtime, readiness, editability, and
templatePolicy. Legacy code, taskType, and runtime fields remain optional for
old clients but are required for all new published snapshots.

Freeze these invariants:

- taskTypeKey is unique and immutable from creation.
- normalized displayName is globally hard unique across active/inactive/
  retired history rows, using the exact normalizer above.
- screenKey plus contractVersion identifies an allowlisted runtime contract.
- runtime behavior, schema, scoring, and authoring values are server-derived.
- STANDARD_PTE still requires the 22 scored standard task types.
- CUSTOM requires explicit policy, common structural validation, contract-
  derived scoring status, and per-row readiness. Unscored items have zero
  weight, use the allowlisted NONE/V1 scoring profile, and a score-producing
  custom template must contain a scored item. All-unscored templates are
  rejected in this score-template domain.

Shared normalization vectors are a checked-in fixture consumed by Java,
TypeScript, Dart, and migration/database tests:

| Input | Field | Expected |
|---|---|---|
| ` read_aloud_plus ` | key | `READ_ALOUD_PLUS` |
| `ｒｅａｄ＿ａｌｏｕｄ＿ｐｌｕｓ` | key | `READ_ALOUD_PLUS` after NFKC |
| `read aloud` | key | reject: internal whitespace |
| `A` | key | reject: minimum length is 2 |
| 65 valid key characters | key | reject: maximum length is 64 |
| `1_READ_ALOUD` | key | reject: first character is not a letter |
| `Read   Aloud` | display name | `read aloud` |
| ` Read\u00A0Aloud ` | display name | `read aloud` |

The fixture is the source of truth for availability checks, unique indexes,
409 conflict mapping, and cross-repository contract tests.

## Error UX

Define messages that explain action rather than expose implementation:

- “Use a key with letters, numbers, and underscores, beginning with a letter.”
- “That task type key is already in use.”
- “That display name is already used. Choose a different name.”
- “This screen contract is not available for new task types.”
- “This task type is used by a published template, so its runtime contract is
  locked.”

Raw codes remain in the response for telemetry and client branching but are not
the primary UI text.

## Security and ownership

- Platform Admin and Platform Author may manage task definitions according to
  the existing role matrix.
- Runtime capability contract content is created/changed only by a coordinated
  backend/pte-app release seed. Platform Admin may activate or retire an
  existing seeded contract and activate a template, but cannot register or
  edit renderer, scorer, schema, or authoring behavior from the UI.
- Tenant/host users consume active definitions only.
- Contract values must not contain class names, source paths, secrets,
  executable expressions, or scoring formulas.

## Design Constraints

- Do not remove or rename PteTaskType values.
- Do not change the existing question-types URL or legacy JSON field names.
- Do not make displayName the identity.
- Do not promise that backend can inspect an installed app binary.
- Public module facades remain the only cross-module dependency.

## Quality and Testing State

Quality: not evaluated.
Testing: not started.

Required tests to write in this phase:

- Java normalizer and alias unit tests.
- Java error-code/message contract tests.
- TypeScript and Dart fixture parsing tests for additive fields.
- Documentation review proving the prior plan is referenced, not overwritten.

Mandatory gate:

    /ck:quality --gate D:\GitHub\pte-org\pte-doc\projects\plans\quang-dynamic-task-type-screen-contract\phase-01-domain-contract-and-compatibility.md

## Acceptance criteria

- The normal forms, regex, uniqueness semantics, lock semantics, and policy
  values are written once and referenced by all later phases.
- A custom task type may reuse a known contract, but cannot define executable
  behavior.
- Existing standard API fields and 22-task behavior are explicitly protected.
- ADR and spec explain the registry/manifest boundary and the no-silent-skip
  rule.

## Verification commands

    .\mvnw.cmd -pl app -DskipTests compile
    .\mvnw.cmd -pl app -Dtest=*TaskType* test
    pnpm --filter vendor-web lint
    cd pte-app; flutter analyze

Run the mandatory quality gate after the focused tests and record its receipt
in this file.

## Risks and rollback

Risk: later implementation discovers that one contract field is still
enum-specific. Mitigation: make the fixture matrix a required review artifact
and block Phase 2 until custom-key fixtures pass the design review.

Rollback: no production state changes. Revert only the new ADR/spec artifacts
or amend the contract before Phase 2 starts.
