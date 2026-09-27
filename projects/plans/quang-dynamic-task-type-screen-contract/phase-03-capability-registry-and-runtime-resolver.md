# Phase 3 — Capability Registry and Dynamic Runtime Resolver

## Goal

Replace enum-only runtime resolution with a logical task-key to
screen-contract resolver while retaining the existing standard registry as a
compatibility adapter.

## Dependencies

- Phase 1 contract.
- Phase 2 capability registry and task-type binding columns.
- Existing TaskRuntimeProfile registry and scoring profile registry.

## Exact files/modules likely affected

- pte-api/app/src/main/java/com/pte/itembank/TaskRuntimeProfileDescriptor.java
- pte-api/app/src/main/java/com/pte/itembank/TaskRuntimeProfileRegistry.java
- pte-api/app/src/main/java/com/pte/itembank/TaskRuntimeProfileService.java
- pte-api/app/src/main/java/com/pte/itembank/domain/TaskRuntimeProfile.java
- new pte-api/app/src/main/java/com/pte/itembank/domain/TaskRuntimeContract.java
- new pte-api/app/src/main/java/com/pte/itembank/TaskRuntimeContractService.java
- new capability-contract repository and mapper
- pte-api/app/src/main/java/com/pte/itembank/internal/constant/TaskRuntimeProfileConstants.java
- pte-api/app/src/main/java/com/pte/itembank/internal/exception/TaskRuntimeProfileException.java
- pte-api/app/src/main/java/com/pte/scoring/internal/service/ScoringProfileRegistry.java
- pte-api/app/src/test/java/com/pte/itembank/TaskRuntimeProfileRegistryTest.java
- pte-api/app/src/test/java/com/pte/itembank/TaskRuntimeProfileServiceTest.java
- new runtime contract resolver tests

## Implementation steps

1. Introduce a semantic contract descriptor keyed by screenKey and version.
2. Refactor the allowlist from EnumMap<PteTaskType,...> to a registry that can
   resolve a logical task key to a contract binding. Keep a standard adapter
   that maps each PteTaskType to its current profile.
3. Validate database contract rows against code-owned semantic allowlists:
   status, profile version, behavior key, renderer key, schema version,
   scoring profile/version, authoring contract/version, and required
   capabilities.
4. Allow multiple taskTypeKey values to resolve to the same screen and profile.
5. Resolve active contracts for authoring and new templates; resolve retired
   versions only when a published template/snapshot explicitly pins them.
6. Add a batch resolver for template/snapshot validation so 22 or more rows do
   not create N+1 queries.
7. Expose a public itembank facade for scoretemplate, assessment, attempt, and
   scoring. No consumer imports a registry implementation directly.
8. Return a readiness object that distinguishes server registry readiness from
   client manifest support. The server must not claim to have inspected a
   device binary.
9. Define platform readiness as a code/release-owned contract with a released
   app compatibility entry and strict semantic-version comparison. Define
   device readiness separately as the installed app's preflight manifest. A
   client manifest can prove capability presence for delivery, but cannot
   register a new renderer, scoring profile, or authoring contract.

## API/DB contract

The resolver returns:

    taskTypeKey
    screenKey
    contractVersion
    profileKey
    behaviorKey
    rendererKey
    answerSchemaVersion
    scoringProfileKey
    scoringProfileVersion
    authoringContractKey
    authoringContractVersion
    authoringRequirements
    requiredClientCapabilities
    minSupportedAppVersion
    status

Same screen reuse is valid when all contract versions and scoring/schema
provenance match. A different interaction or scoring behavior must use a new
contract version and code-owned allowlist entry.

The registry is seeded and versioned from backend/app release artifacts. The
semantic version grammar is major.minor.patch with numeric components; a
malformed version or a client below minSupportedAppVersion is not ready. The
required capability list is a canonical sorted, duplicate-free TEXT[] of
bounded tokens. The authoringRequirements descriptor is also allowlisted and
versioned; it is the source for the existing question validation flags and is
never supplied as trusted client metadata.

## Error UX

Backend constants and public messages:

- TASK_TYPE_CAPABILITY_NOT_FOUND:
  “The selected task screen is no longer available for new configuration.”
- TASK_RUNTIME_PROFILE_NOT_ACTIVE:
  “This task screen is temporarily unavailable. Existing published exams
  remain protected.”
- UNSUPPORTED_RUNTIME_CONTRACT:
  “This task uses a runtime contract that this platform release does not
  support.”

For readiness APIs, return every invalid contract in a list rather than the
first failure only.

## Security and ownership

- Registry contracts are created only by code/release-owned seeds after the
  backend and pte-app implementation is released. Platform Admin may activate
  or retire an existing seeded contract under the role policy, but cannot
  invent or edit renderer, scorer, schema, or authoring behavior from the UI.
- Platform Author can select active contracts but cannot alter behavior,
  scoring, schema, authoring requirements, or required capabilities.
- Registry endpoints reveal semantic capability keys and versions only.
- Contract resolution must be tenant-independent and cannot expose exam
  content.

## Design Constraints

- A database row cannot introduce an executable implementation.
- Retired contracts remain readable for pinned history but are excluded from
  new authoring.
- Standard PteTaskType resolution remains available until all compatibility
  clients migrate.
- A resolver failure is explicit; never fall back to a different screen.

- Preflight: registry ownership, semantic allowlisting, retired-readable
  resolution, batch resolution, and client contract semantics were reviewed.

## Quality and Testing State

Quality: approved; receipt: quality/phase-03-capability-registry-and-runtime-resolver-receipt.json
Testing: passed; report: tests/phase-03-capability-registry-and-runtime-resolver-test-report.json

Required tests:

- Standard 23-code adapter parity test.
- Two custom task keys resolving to one screen/profile.
- Unknown screen, unknown version, inactive contract, and retired-pinned
  contract tests.
- Batch resolver query-count test.
- Scoring profile mismatch and answer-schema mismatch tests.
- Authoring contract resolves the existing prompt/audio/image/options/correct-
  answer/word-count requirement flags without client override.
- Semantic-version boundary and released-app compatibility matrix tests.
- Canonical capability-token ordering, duplicate rejection, and round-trip
  serialization tests.

Mandatory gate:

    /ck:quality --gate D:\GitHub\pte-org\pte-doc\projects\plans\quang-dynamic-task-type-screen-contract\phase-03-capability-registry-and-runtime-resolver.md

## Acceptance criteria

- Existing standard catalog responses resolve the same runtime behavior as
  before.
- A custom task key can resolve to an existing contract without enum changes.
- Two task keys can share one screen contract.
- Invalid or retired contracts produce structured readiness failures.
- No caller performs an enum parse as the only way to resolve a new task.

## Verification commands

    .\mvnw.cmd -pl app -Dtest=TaskRuntimeProfileRegistryTest,TaskRuntimeProfileServiceTest test
    .\mvnw.cmd -pl app -DskipTests compile
    git diff --check

Run the mandatory quality gate after tests.

## Risks and rollback

Risk: keeping both old and new registries creates divergent truth. Mitigate by
making the canonical contract service the only public resolver and testing
standard adapter parity.

Rollback: retain the old enum registry behind a feature flag, disable custom
task creation/activation, and keep new rows readable as inactive metadata.
