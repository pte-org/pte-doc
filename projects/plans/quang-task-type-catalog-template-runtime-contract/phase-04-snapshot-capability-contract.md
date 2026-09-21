# Phase 4: Snapshot Provenance and Capability Negotiation

## Objective

Make a published exam self-describing and make student delivery fail closed
when the installed app cannot render one of its pinned tasks. Runtime must read
immutable snapshot data, not a mutable catalog join.

## Files

- `pte-api/app/src/main/java/com/pte/assessment/domain/ExamSnapshot.java`
- `pte-api/app/src/main/java/com/pte/assessment/domain/SnapshotItem.java`
- `pte-api/app/src/main/java/com/pte/assessment/internal/service/SnapshotPublishService.java`
- `pte-api/app/src/main/java/com/pte/attempt/domain/PinnedItem.java`
- `pte-api/app/src/main/java/com/pte/attempt/internal/service/AttemptLifecycleService.java`
- `pte-api/app/src/main/java/com/pte/attempt/internal/dto/request/StartAttemptRequest.java`
- `pte-api/app/src/main/java/com/pte/attempt/internal/dto/response/TaskView.java`
- assessment/attempt migrations, controllers, mappers and contract tests

## Implementation steps

1. Extend `SnapshotItem` and the pinned-item projection with the resolved
   `behaviorKey`, `rendererKey`, answer schema version, `scoringProfileKey`,
   scoring profile version and required capabilities. Add a forward migration
   after the current latest migration; do not edit an applied migration.
2. Update snapshot publishing to copy these values from the active template
   item in the same transaction as the snapshot content. Reject publication if
   any item has an unknown or internally inconsistent profile.
3. For the current greenfield database, do not build a destructive or broad
   real-data snapshot rewrite. Define a named historical mapping version, for
   example `LEGACY_PTE_V1`, for fixtures and any rows discovered during
   verification. If such rows exist, persist mapping status on the snapshot
   item (`RESOLVED_LEGACY`, `RESOLVED_CANONICAL` or `INCOMPATIBLE`). A missing
   or ambiguous mapping must be reported and blocked, never resolved from the
   current mutable catalog by guesswork. The mapper must bridge the enum-backed
   `SnapshotItem` and string-backed `PinnedItem` in one place.
4. Extend `TaskView` additively with one nullable nested `runtime` object and
   `taskTypeCode`. Preserve `taskType`, timing, content privacy and old JSON
   parsing. New snapshots always produce the complete nested runtime object;
   legacy responses may omit it and the app falls back to the alias mapper.
5. Add a non-mutating capability preflight at
   `POST /api/v1/attempts/preflight` with `sessionPublicId` and a bounded client
   capability manifest. Return `canStart`, missing capability identifiers and a
   friendly message without question content or answer keys.
6. Add the same manifest as an optional field on the existing
   `POST /api/v1/attempts` request and perform the authoritative check again
   before creating/delivering an attempt. Store only the normalized
   allowlisted capability fingerprint needed for resume/next-task enforcement.
   When an attempt already exists, perform the capability check after the
   existing student/tenant/session ownership lookup and before
   `resumeOrReject`; a GET/next-task path uses the stored normalized fingerprint
   and checks it before returning each pinned task.
7. During the compatibility window, allow missing manifests only for explicitly
   grandfathered legacy snapshots behind a feature flag. New runtime profiles
   require the manifest. Resume and next-task paths must re-use the normalized
   decision and cannot skip an unsupported item.
8. Add stable machine errors such as `EXAM_REQUIRES_APP_UPDATE` and
   `EXAM_CONFIGURATION_NOT_COMPATIBLE`, with human-friendly constants in the
   owning assessment/attempt package and safe API error payloads.

## Acceptance criteria

- New snapshots contain complete runtime provenance for every item.
- Later catalog/profile/template changes cannot alter renderer, answer schema,
  timing or scoring behavior of a published snapshot.
- Preflight is side-effect free; start repeats the check and blocks before an
  unsupported exam begins.
- Existing clients can still parse the old response fields; new clients can
  select a renderer from the additive contract.
- Unknown or unsupported tasks never auto-next, fabricate an answer or change
  `totalTasks`; the user receives an actionable update/configuration message.
- Historical snapshots with a safe mapping remain readable; unsafe snapshots
  fail closed and emit an operator-visible audit event.

## Design Constraints

- Do not resolve runtime behavior from a live catalog lookup at attempt time.
- Do not trust client-provided capability names as executable configuration.
- Do not use a skip policy for a task that belongs to a frozen exam.
- Preserve current attempt locking, student ownership and answer secrecy.
- Additive API fields must remain compatible with the existing web/app clients.
- Machine codes and user-facing messages are separate constants.

## Quality and Testing State

Status at plan creation: testing not started; quality not evaluated.

Required before phase completion:

- Snapshot publish/pin tests, legacy-snapshot compatibility fixtures and
  conditional mapping tests (no real-data rewrite is required for the empty
  local database).
- Preflight/start success, missing-capability, resume and next-task fail-closed
  tests; authorization/privacy/error-contract tests.
- Backend compile/test commands:
  `.\mvnw.cmd -pl app -DskipTests compile` and
  `.\mvnw.cmd -pl app test`.
- Mandatory `ck:quality --gate` receipt covering immutability, TOCTOU handling,
  tenant/student isolation and safe error UX.
