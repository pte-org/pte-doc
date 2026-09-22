# Phase 8 — Generation, Snapshot Provenance, Scoring, and History

## Goal

Make exam generation, snapshots, pinned attempts, answer decoding, and scoring
stable for dynamic task keys. A later catalog or contract edit must never
change a published exam or an existing attempt.

## Dependencies

- Phase 3 runtime resolver.
- Phase 5 question-bank task identity.
- Phase 6 template policy and publication pinning.
- Phase 7 app-facing contract shape.

## Exact files/modules likely affected

Database:

- pte-api/app/src/main/resources/db/migration/V54__snapshot_task_contract_provenance.sql

Assessment:

- pte-api/app/src/main/java/com/pte/assessment/domain/SnapshotItem.java
- pte-api/app/src/main/java/com/pte/assessment/dto/response/SnapshotResponse.java
- pte-api/app/src/main/java/com/pte/assessment/dto/response/SnapshotContentResponse.java
- pte-api/app/src/main/java/com/pte/assessment/internal/service/ExamGenerationService.java
- pte-api/app/src/main/java/com/pte/assessment/internal/service/SnapshotPublishService.java
- pte-api/app/src/main/java/com/pte/assessment/internal/service/BlueprintService.java
- pte-api/app/src/main/java/com/pte/assessment/internal/mapper/SnapshotMapper.java

Attempt:

- pte-api/app/src/main/java/com/pte/attempt/domain/PinnedItem.java
- pte-api/app/src/main/java/com/pte/attempt/domain/PinnedExamSnapshot.java
- pte-api/app/src/main/java/com/pte/attempt/internal/service/SnapshotPinService.java
- pte-api/app/src/main/java/com/pte/attempt/internal/service/CapabilityNegotiationService.java
- pte-api/app/src/main/java/com/pte/attempt/internal/dto/response/TaskView.java
- pte-api/app/src/main/java/com/pte/attempt/internal/mapper/AttemptMapper.java

Scoring:

- pte-api/app/src/main/java/com/pte/scoring/internal/service/ObjectiveScoringService.java
- pte-api/app/src/main/java/com/pte/scoring/internal/service/AnswerPayloadDecoder.java
- pte-api/app/src/main/java/com/pte/scoring/internal/service/AiScoringDispatcher.java
- pte-api/app/src/main/java/com/pte/scoring/internal/service/ScoringProfileRegistry.java
- pte-api/app/src/main/java/com/pte/scoring/internal/service/ScoringMethodResolver.java
- pte-api/app/src/main/java/com/pte/scoring/internal/constant/*Constants.java

Tests:

- pte-api/app/src/test/java/com/pte/assessment
- pte-api/app/src/test/java/com/pte/attempt
- pte-api/app/src/test/java/com/pte/scoring

## Implementation steps

1. Reuse the non-null taskTypeKey and nullable legacy enum columns created and
   backfilled in Phase 2. Add only the remaining V54 immutable provenance
   columns (display-label snapshot, screen/contract pin, authoring/scoring
   profile versions, scorer implementation/configuration digest, and required
   capabilities) to snapshot_items and pinned_items. Backfill standard rows
   before making any field required for new snapshots; custom rows keep legacy
   taskType/pteTaskType null and use taskTypeKey. Do not duplicate or postpone
   Phase 2's task-key migration.
2. During snapshot publication, resolve each template item and frozen question
   by logical key and copy the complete contract. Reject incomplete new
   snapshots; keep legacy nullable rows readable.
3. Change exam generation maps/counts from PteTaskType to taskTypeKey. Retain
   the standard adapter for un-migrated fixtures.
4. Pin the same data into PinnedItem at attempt creation. Do not read current
   catalog labels or runtime contracts after pinning.
5. Refactor answer decoding by answerSchemaVersion/behaviorKey and scoring
   dispatch by scoringProfileKey/version. Standard task code maps remain
   compatibility adapters.
6. Persist immutable scorer provenance with each pinned scoring contract:
   scorer implementation/profile version, model version where applicable,
   rubric/prompt configuration version or digest, and the retention status of
   the referenced profile. Retired pinned profiles remain resolvable for
   historical attempts; a newer profile never replaces an old one implicitly.
7. Make scoring provenance visible in internal/admin views without exposing
   implementation classes or formulas to students.
8. Validate the snapshot contract before delivery and let Phase 7 preflight
   compare it with the app manifest.
9. Add regression fixtures where the task type is renamed, retired, its
   contract is superseded, and a new template is activated after the old
   snapshot was generated.

## API/DB contract

New snapshots must contain non-null:

    taskTypeKey
    taskTypeDisplayName
    screenKey
    contractVersion
    behaviorKey
    answerSchemaVersion
    scoringProfileKey
    scoringProfileVersion
    scoringMode (NONE for unscored tasks)
    scoringImplementationVersion
    scoringConfigurationDigest
    runtime mapping status

Legacy snapshot responses keep taskType and old fields for standard rows only;
custom rows expose taskTypeKey and null legacy taskType. New app responses
prefer taskTypeKey and runtime provenance.

Scoring must reject an incomplete pinned profile instead of using the current
catalog profile. A retired but complete pinned profile remains readable. The
error identifies the pinned task and provenance version; it must not silently
substitute a newer scorer.

## Error UX

For an operator-facing generation failure:

“The exam could not be generated because task Read Aloud Plus has an incomplete
runtime contract. Fix the template readiness issues and try again.”

For an attempt-facing historical corruption or unsupported contract:

“This task cannot be opened with the installed app version. Contact the exam
administrator; your attempt has not been advanced.”

Do not expose decoder stack traces or raw enum exceptions.

## Security and ownership

- Snapshot/pinned data remains tenant/session scoped through existing services.
- Student responses never receive correct answers, scoring formulas, or
  registry implementation details.
- Scoring uses the pinned provenance and existing authorization boundaries.
- Historical snapshots are write-once; catalog administrators cannot rewrite
  them through catalog endpoints.

## Design Constraints

- Published snapshot and pinned attempt data are immutable.
- Retired catalog rows and contracts remain readable when explicitly pinned.
- Do not perform per-question runtime registry queries during attempt delivery.
- Do not silently fall back from a custom key to a standard PteTaskType.
- Preserve existing generation seed, algorithm, pool policy, and template
  version provenance.

## Quality and Testing State

Quality: not evaluated.
Testing: not started.

Required tests:

- Standard generation/snapshot regression fixtures.
- Custom task generation with an existing screen contract.
- Snapshot and pinned-item completeness tests.
- Migration/backfill test proving every existing standard snapshot and pinned
  item receives taskTypeKey before the legacy enum columns become nullable.
- Catalog label, order, retirement, and profile-change immutability tests.
- Answer decoder dispatch by schema/behavior.
- Objective and AI scoring dispatch by profile/version.
- Historical retired-contract delivery test.
- Historical scoring after profile retirement and after a newer profile is
  activated, proving the pinned implementation/configuration digest is used.
- Missing/mismatched provenance blocker test.
- No-content-before-open and tenant-scope regression tests.

Mandatory gate:

    /ck:quality --gate D:\GitHub\pte-org\pte-doc\projects\plans\quang-dynamic-task-type-screen-contract\phase-08-generation-snapshot-scoring-and-history.md

## Acceptance criteria

- Standard and custom tasks generate with the correct logical key.
- Old snapshots remain readable after catalog changes.
- New snapshots contain complete runtime and scoring provenance.
- Existing attempts are unaffected by later template activation or catalog
  edits.
- Scoring/decoding uses pinned behavior/schema/profile, not current task code.

## Verification commands

    .\mvnw.cmd -pl app -Dtest=*Snapshot*,*ExamGeneration*,*ObjectiveScoring*,*AnswerPayloadDecoder* test
    .\mvnw.cmd -pl app -DskipTests compile
    git diff --check

Run migration fixture tests and the mandatory quality gate.

## Risks and rollback

Risk: a legacy snapshot has no runtime fields. Keep the existing legacy mapper
and mark it as legacy/incompatible rather than guessing a custom contract.

Risk: a scoring switch still parses PteTaskType. Use repository-wide search and
custom scoring fixtures before enabling strict custom policy.

Rollback: disable custom generation/activation while preserving new provenance
columns and old snapshot delivery. Never rewrite pinned history.
