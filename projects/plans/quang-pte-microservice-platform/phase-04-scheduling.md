# Phase 4: scheduling — Exam Session Orchestration

## Requirements

The bridge between static content (authoring) and live attempts (exam-delivery). A host creates an `ExamSession` referencing a published snapshot, sets its **composition** (full mock, or an optional subset of sections/task types for focused practice), enrolls students manually, and assigns proctors. Also the origin of the host-gated scoring/publish commands. A session has a time window and its own config; one snapshot can back many sessions.

## Design Constraints

- `com.pte.scheduling`, DB `scheduling`, uniform layout.
- References `ExamSnapshot` by `publicId` (copied metadata), never joins to authoring's DB.
- **Composition is config**, not new content: a selected subset of the snapshot's task types + ordering + optional timing overrides. Full mock = all; practice = subset. This is what enables "host optionally chooses what to test."
- Enrollment references student users by `publicId` (from iam); no user table duplication.
- Host commands `ScoringRequested` and `PublishRequested` originate here (host-facing), not in scoring/reporting — those services execute, they don't decide.
- Tenant-scoped; RLS.

## Steps

1. Entities: `ExamSession` (snapshotPublicId, window, status), `SessionComposition` (included task types/sections, order, timing overrides), `Enrollment` (studentPublicId), `ProctorAssignment` (proctorPublicId). Flyway `V1__scheduling.sql`.
2. `SessionService`: create/open/close session referencing a published snapshot. `CompositionService`: host selects included parts (validate subset against snapshot's available task types).
3. `EnrollmentService`: add students manually (by publicId/email lookup), assign proctors.
4. `consumer`: `ExamSnapshotPublished` → cache snapshot ref+composition-available metadata locally (so session creation needs no live authoring call). **Pre-Phase-6 substitute**: Kafka/Debezium isn't wired yet, so this phase implements a guarded sync pull (`client/`, timeout+circuit-breaker) at session-creation time that fetches snapshot metadata and caches it into `SnapshotRef`/`SnapshotRefItem` — the same table shape a real consumer would populate. This is the one allowed create-time sync call (mirrors the exam-delivery precedent in Phase 5); it is replaced by the actual `ExamSnapshotPublished` consumer in Phase 6 with no schema change.
5. Controllers: `SessionController` (create, set composition, open/close), `EnrollmentController` (add student), `ProctorAssignmentController`. Host-command endpoints: `POST /sessions/{id}/score` → emit `ScoringRequested`; `POST /sessions/{id}/publish` → emit `PublishRequested`.
6. `messaging/outbox`+`publisher`: `SessionScheduled`, `StudentEnrolled`, `ScoringRequested`, `PublishRequested`.
7. Tests: composition subset validation (reject task type not in snapshot); enrollment tenant-scoped; scoring/publish commands emitted with correct session+attempt scope.

## Success Criteria

- Host creates a session from a published snapshot, sets a practice subset, enrolls ≥1 student, assigns a proctor — all tenant-isolated.
- Composition rejects task types absent from the referenced snapshot.
- `ScoringRequested`/`PublishRequested` emitted only by host-role callers and scoped to the correct session/attempt.
- Session creation performs no synchronous call to authoring (uses cached snapshot metadata).

## Quality and Testing State

- Quality gate: **approved** (2026-07-24). 1 MEDIUM current-change finding (missing `@EntityGraph` on `findByTenantId` → N+1 in `list()`) — **fixed**. Report + receipt: `pte-api/plans/quang-pte-microservice-platform/quality/phase-04-scheduling-{quality-report,receipt}.json`.
- Testing: not started — **declined by user** (quality-only cook run). Build Gate green: full reactor `mvn install` (pte-common+gateway+iam+admin+authoring+scheduling).

## Implementation notes
- **Pre-Phase-6 substitute implemented**: `AuthoringClient` (RestClient, 2s connect/3s read timeout, resilience4j circuit breaker) does the one guarded sync pull at session-creation on cache miss; `SnapshotRefService.resolve()` caches into `SnapshotRef`/`SnapshotRefItem` — same shape Phase 6's real consumer will populate. Never called outside session creation.
- `taskType`/`section` stored as plain strings in scheduling (not authoring's `PteTaskType`/`PteSection` enums) — no shared business enum across services, matches `AuthoringSnapshotResponse` being scheduling's own wire-contract view, not a shared DTO.
- Host-command authorization split: general session CRUD/composition = `HOST_ADMIN`+`HOST_AUTHOR`; `/score` and `/publish` = `HOST_ADMIN` only (governance-level actions).
- Concurrency: enrollment/proctor-assignment dedup via DB unique constraint + catch `DataIntegrityViolationException`, not check-then-act.

## Runtime-verification TODO
- `docker compose up postgres` + run authoring + scheduling → create session against a published snapshot (first call hits authoring, second session against same snapshot hits cache only); set practice-subset composition; reject a task type not in the snapshot; enroll student; assign proctor; issue score/publish commands as HOST_ADMIN, confirm HOST_AUTHOR is rejected.

## Risks

- **MEDIUM: Composition vs snapshot drift** — snapshot re-published with fewer types after a composition was set. *Mitigation:* composition pins snapshot version; a new version is a new session choice, not a mutation.
- **LOW: Manual enrollment UX** — file import deferred. *Mitigation:* single-add only in Milestone 1 (explicit scope).
