# Phase 7 — pte-app Screen Registry, Manifest, and Unsupported State

## Goal

Let pte-app resolve a task by the pinned screen contract rather than requiring
every taskTypeKey to be compiled into an enum. Reuse existing screens for
custom task keys, report declarative capabilities during preflight, and stop
unsupported tasks without silently advancing.

## Dependencies

- Phase 1 runtime contract.
- Phase 3 server resolver and semantic registry.
- Phase 6 template/snapshot readiness DTO shape.
- Existing Flutter task screens, dispatcher, and preflight flow.

## Exact files/modules likely affected

- pte-app/lib/core/constants/task_type_meta.dart
- pte-app/lib/features/exam_attempt/presentation/widgets/task_type_dispatcher.dart
- pte-app/lib/features/exam_attempt/presentation/model/task_view_ui_adapter.dart
- pte-app/lib/features/exam_attempt/presentation/model/exam_task_ui_model.dart
- pte-app/lib/features/exam_attempt/domain/client_capability_manifest.dart
- pte-app/lib/features/exam_attempt/domain/attempt_preflight.dart
- pte-app/lib/features/exam_attempt/presentation/pages/session_entry_page.dart
- pte-app/lib/features/exam_attempt/presentation/widgets/exam_task_header_banner.dart
- new unsupported-runtime screen/widget and localized string constants
- existing task renderer/widget registrations under
  pte-app/lib/features/exam_attempt
- pte-app/test/core/constants/task_type_meta_test.dart
- pte-app/test/features/exam_attempt
- pte-api/app/src/main/java/com/pte/attempt/internal/service/CapabilityNegotiationService.java
- pte-api/app/src/main/java/com/pte/attempt/internal/controller/AttemptController.java
- pte-api/app/src/main/java/com/pte/attempt/internal/dto/request/AttemptPreflightRequest.java
- pte-api/app/src/main/java/com/pte/attempt/internal/dto/request/ClientCapabilityManifest.java
- pte-api/app/src/main/java/com/pte/attempt/internal/dto/response/AttemptPreflightResponse.java
- pte-api/app/src/main/java/com/pte/attempt/internal/constant/*Constants.java

## Implementation steps

1. Refactor TaskTypeRendererRegistration so screenKey/rendererKey and
   supported contract/schema/scoring versions are primary. Keep standard task
   metadata as a fallback adapter.
2. Resolve runtime by pinned screenKey and contract version. Use the snapshot's
   displayName, instruction, section, and taskTypeKey for labels; do not require
   a TaskTypeMeta enum entry for a custom key.
3. Allow two custom keys to map to the same existing renderer registration.
4. Extend ClientCapabilityManifest with appVersion and supported runtime
   contract descriptors while keeping the old capabilities list.
5. Extend AttemptPreflight parsing and request serialization with missing
   contracts and unsupportedTasks.
6. Add an explicit terminal unsupported-runtime state/screen with an update or
   configuration action. It must not call the next-task transition.
7. Preserve legacy alias canonicalization for V40 fill-blank values.
8. Validate renderer, schema, scoring version, required capabilities, and
   contract status before opening a task.
9. Keep capability manifest semantic and small; never send widget names,
   source paths, class names, secrets, or answer content.
10. Treat the server's code/release-owned compatibility matrix as the
    platform-readiness source of truth and the installed app manifest as the
    device-readiness claim. Compare appVersion and contract versions with
    strict major.minor.patch semantics; malformed or prerelease versions are
    not considered compatible unless explicitly listed by the release matrix.

## API/DB contract

The app manifest sends semantic capabilities and supported contract versions.
The server compares it against the pinned snapshot contract. A response with
canStart false includes:

    missingCapabilities[]
    unsupportedTasks[]:
      taskTypeKey
      screenKey
      contractVersion
      reasonCode
      userMessage

The manifest cannot create or authorize a new contract. The server registry
must contain the contract and a released-app compatibility entry before a
template can be activated; preflight additionally verifies the actual
installed app and device capabilities.

A custom task that uses an existing READ_ALOUD_V1 contract is supported by an
app that already supports that renderer; no new task enum is required.

## Error UX

Use a non-technical terminal message:

“This exam includes a task screen that this app version does not support.
Update the app or contact your exam administrator. Your attempt was not
advanced past this task.”

For a capability permission/device problem, preserve existing device-check
messaging and distinguish it from an unknown screen contract.

## Security and ownership

- The manifest contains no user secrets or exam answers.
- Server preflight remains authenticated and tenant/session scoped.
- Client must trust only pinned server contracts; it must not execute server
  instructions outside its compiled registry.
- No dynamic code loading is introduced.

## Design Constraints

- Existing PTE screens remain the renderer implementation.
- Unknown renderer, incomplete profile, inactive contract, schema mismatch, or
  missing capability is unsupported, not a fallback to another screen.
- The app can use snapshot display metadata but cannot invent scoring behavior.
- Preserve no-content-before-open and attempt state machine invariants.

## Quality and Testing State

Quality: not evaluated.
Testing: not started.

Required tests:

- Dart unit tests for screen-key resolution and two task keys sharing one
  renderer.
- Legacy enum/task alias regression tests.
- Runtime profile completeness, schema, scoring-version, and capability tests.
- Widget test for terminal unsupported state with no next-task call.
- Preflight JSON round-trip and missing-contract tests.
- Integration test for supported custom key reusing an existing screen.
- Backend capability negotiation tests for old and new manifests.
- Strict semver comparison tests for minimum app versions and contract
  versions, including malformed-version rejection.

Mandatory gate:

    /ck:quality --gate D:\GitHub\pte-org\pte-doc\projects\plans\quang-dynamic-task-type-screen-contract\phase-07-pte-app-screen-registry-and-manifest.md

## Acceptance criteria

- A custom task key using an existing contract opens the existing pte-app
  screen.
- The app sends a truthful capability/contract manifest.
- Unsupported screen or version produces a terminal actionable state.
- The task is never silently skipped or converted to another renderer.
- Existing standard PTE task walkthroughs remain unchanged.

## Verification commands

    cd pte-app
    flutter analyze
    flutter test
    cd ../pte-api
    .\mvnw.cmd -pl app -Dtest=*Capability* test
    .\mvnw.cmd -pl app -DskipTests compile

Run the mandatory quality gate after both repositories pass focused tests.

## Risks and rollback

Risk: renderer metadata currently assumes taskType equals screen identity.
Keep a compatibility adapter and migrate one renderer family at a time.

Risk: app is released after a template becomes active. Keep strict server
activation for registry validity and require attempt preflight for actual app
support; roll out custom policy behind a feature flag.

Rollback: disable custom template delivery and keep legacy task-type
resolution. Do not remove the new unsupported state or corrupt attempts.
