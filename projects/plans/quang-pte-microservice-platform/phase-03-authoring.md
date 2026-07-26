# Phase 3: authoring — Content

## Requirements

Question bank + exam blueprints + immutable versioned snapshots. Supports all 22 PTE task types with type-specific fields and config-driven multi-skill mapping. Two visibility scopes: admin-created SHARED bank (all hosts read, only platform authors write) and host-created PRIVATE content (that host only). Publishing a blueprint produces an immutable `ExamSnapshot` that downstream services pin — never mutate.

## Design Constraints

- `com.pte.authoring`, DB `authoring`, uniform layout.
- Task-to-skill mapping is **config-driven** (versioned config, not a DB join-table) — fixed 22-type taxonomy (ADR-001; reuse `PteTaskType`/`Skill`/`PteTaskTypeSkillMapping` design from prior quang-pte-pivot Phase 1).
- Visibility: `tenant_id = NULL` = SHARED (admin), `tenant_id = X` = PRIVATE (host). Enforced by RLS + role: host reads SHARED read-only, writes only own PRIVATE; only `PLATFORM_AUTHOR` writes SHARED.
- `ExamSnapshot` is immutable + versioned: publishing copies blueprint+question content into a frozen, addressable-by-publicId artifact. Downstream copies it, never joins to it.
- Objective task types must have `correct_answer(s)` enforced at save (task-type-aware validation).
- Media referenced by `MediaRef.publicId` (from media service), never a binary blob.

## Steps

1. Entities: `Question` (BaseEntity + pteTaskType, type-specific fields, visibility, tenantId nullable), `QuestionOption`, `ExamBlueprint`, `BlueprintItem`, `MediaRef`, `ExamSnapshot` + `SnapshotItem`. `domain/enums`: `PteTaskType`, `Skill`, `QuestionStatus`, `Visibility`. Flyway `V1__authoring.sql`.
2. `QuestionService` + `QuestionValidationHelper`: task-type-aware required-field validation (e.g. Read Aloud needs audio prompt + reference answer; MCQ needs options + correct answer; Essay needs prompt + word bounds).
3. Config-driven skill mapping: `PteTaskTypeSkillMapping` loaded from versioned resource (`resources/config/`).
4. Visibility enforcement: RLS policies + role checks in service; host cannot write SHARED, cannot read other tenants' PRIVATE.
5. `BlueprintService`: assemble blueprint from questions (SHARED and/or own PRIVATE). `SnapshotPublishService`: freeze blueprint → immutable `ExamSnapshot` (deep copy content), assign version + publicId.
6. Controllers: `QuestionController`, `BlueprintController`, `SnapshotController` (`POST /authoring/blueprints/{id}/publish`). `@Valid`, `ApiResponse<T>`.
7. `messaging/outbox`+`publisher`: `ExamSnapshotPublished` (carries snapshot publicId + version + composition metadata).
8. Tests: per-type validation; host blocked from SHARED write + cross-tenant read; publish yields immutable snapshot (later edits to source question do NOT change published snapshot).

## Success Criteria

- All 22 task types persist with type-specific validation; objective types reject missing correct answer.
- Host reads SHARED bank read-only and its own PRIVATE only; cross-tenant read/write blocked (tested).
- Publishing a blueprint produces an immutable snapshot; mutating the source question afterward leaves the snapshot unchanged (tested).
- `ExamSnapshotPublished` written to outbox in same TX as publish.

## Quality and Testing State

- Quality gate: **approved** (2026-07-24). 1 MEDIUM (explicit blueprint save — **fixed**), 1 NOTED (snapshot immutability confirmed well-designed). Report + receipt: `pte-api/plans/quang-pte-microservice-platform/quality/phase-03-authoring-{quality-report,receipt}.json`.
- Testing: not started — **declined by user** (quality-only cook run). Build Gate green: full reactor `mvn install` compiles (incl. pte-common shared additions + retrofitted iam/admin).

## Implementation notes
- **DRY 3rd-occurrence extraction done**: `AbstractOutboxEntry` (@MappedSuperclass) + `AbstractOutboxWriter` + `ResourceServerJwt` moved to pte-common; iam/admin retrofitted to use them (each service keeps a tiny concrete `OutboxEntry`).
- All 22 scored task types + PERSONAL_INTRODUCTION (unscored) in `PteTaskType` with category-driven requirement flags; skill mapping in versioned `config/task-skill-mapping.json`.
- Snapshot immutability via deep-copy in `SnapshotPublishService.freeze()` — `SnapshotItem` self-contained (options serialized to `optionsJson`), no FK to `Question`, referenced only by `sourceQuestionPublicId`.
- MediaRef folded into `audioPromptRef`/`imagePromptRef` UUID columns (cross-service ref to media by publicId; no MediaRef entity).
- Deferred: question update/archive endpoints; full snapshot-detail endpoint (with options/correct answers) for exam-delivery pinning — added in Phase 4/5.

## Runtime-verification TODO
- `docker compose up postgres` + run authoring → Flyway V1 applies; create question per type → validation; publish blueprint → immutable snapshot + `ExamSnapshotPublished` on outbox; host cannot write SHARED / read cross-tenant.

## Risks

- **MEDIUM: Snapshot immutability leak** — accidental shared references between source and snapshot. *Mitigation:* deep copy on publish; test that source edits don't bleed.
- **LOW: 22-type validation breadth.** *Mitigation:* reuse prior pivot Phase 1 validation design; table-driven per-type rules.
