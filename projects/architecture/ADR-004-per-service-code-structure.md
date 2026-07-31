# ADR-004: Per-Service Code Structure

**Date:** 2026-07-24
**Status:** Accepted
**Depends on:** ADR-001/002/003, `docs/CODING_STANDARDS_MICROSERVICE.md`

Mono-repo (`pte-api/`), Maven multi-module, database-per-service. Every service uses the uniform layered layout from the coding standard §2. This file lists each service's **concrete** content: owned entities (= DB tables), key endpoints, events emitted/consumed, sync deps.

Legend: **emits** = publishes via outbox→RabbitMQ (polling relay, was Kafka — see ADR-002's "Superseded-in-part" note, 2026-07-31); **consumes** = RabbitMQ listener; **sync→** = guarded REST call (timeout+CB).

---

## gateway  (Spring Cloud Gateway — no domain layers)
- Route + filter only. JWT validation at edge, per-tenant rate-limit (Redis token bucket), correlation-id propagation.
- No DB, no business logic.

---

## iam  (auth server — the only one)
**Owns (db `iam`):** `User`, `Credential`, `Role`, `TenantMembership`, `RefreshToken`, JWT signing keys.
- **Package:** `com.pte.iam`
- **controller:** `AuthController` (login, refresh, logout), `UserController` (CRUD host/proctor/student), `JwksController` (public keys).
- **service:** `AuthService`, `UserService`, `TokenService` (RS256/EdDSA sign), `JwksService`.
- **domain.enums:** `Role` (PLATFORM_ADMIN, PLATFORM_AUTHOR, HOST_ADMIN, HOST_AUTHOR, PROCTOR, STUDENT).
- **Tenant registry lives here**: `tenantId` + status embedded into JWT claims → data plane reads from token, no runtime call to admin.
- **emits:** `UserCreated`, `UserSuspended`.
- **sync deps:** none (root of trust).

## admin  (control plane — low traffic, high privilege)
**Owns (db `admin`):** `Tenant`, `Subscription`, `PlatformConfig`, `FeatureFlag`, `KillSwitch`.
- **Package:** `com.pte.admin`
- **controller:** `TenantController` (onboard/suspend org), `SubscriptionController`, `PlatformConfigController`.
- **service:** `TenantLifecycleService`, `SubscriptionService`, `FeatureFlagService`.
- **emits:** `TenantOnboarded`, `TenantSuspended` (iam consumes to update registry/claims).
- **Not on any critical runtime path.** Does not own tenant *identity* (that's iam) — owns tenant *governance*.
- **sync deps:** none critical.

## authoring  (content — data plane, multi-tenant)
**Owns (db `authoring`):** `Question`, `QuestionOption`, `ExamBlueprint`, `BlueprintItem`, `MediaRef`, `ExamSnapshot` (published immutable version).
- **Package:** `com.pte.authoring`
- **controller:** `QuestionController`, `BlueprintController`, `SnapshotController` (publish).
- **service:** `QuestionService` + `QuestionValidationHelper` (task-type-aware required-field validation), `BlueprintService`, `SnapshotPublishService`.
- **domain.enums:** `PteTaskType` (22 scored + 1 unscored), `Skill`, `QuestionStatus`, `Visibility` (PRIVATE tenant / SHARED global).
- **Visibility model:** `tenant_id = NULL` = admin-created SHARED bank (host reads, only PLATFORM_AUTHOR writes); `tenant_id = X` = host PRIVATE. Enforced by RLS + role.
- **emits:** `ExamSnapshotPublished` (immutable, versioned — scheduling/exam-delivery consume).
- **Per-tenant quota** on writes; bulk create later goes through RabbitMQ (deferred).
- **sync deps:** media (presign) — guarded.

## scheduling  (exam session orchestration)
**Owns (db `scheduling`):** `ExamSession`, `SessionComposition` (which sections/task-types included — full mock vs practice subset), `Enrollment`, `SessionWindow`, `ProctorAssignment`.
- **Package:** `com.pte.scheduling`
- **controller:** `SessionController` (create session, set composition, open/close), `EnrollmentController` (add students manually), `ProctorAssignmentController`.
- **service:** `SessionService`, `CompositionService` (host picks optional parts), `EnrollmentService`.
- **Composition is config**: references a published `ExamSnapshot` + a selected subset of task types + ordering + timing overrides. Pinned into the attempt by exam-delivery.
- **emits:** `SessionScheduled`, `StudentEnrolled`, `ScoringRequested` (host command), `PublishRequested` (host command).
- **consumes:** `ExamSnapshotPublished` (cache snapshot ref).
- **Host-facing scoring/publish commands originate here** (not in scoring service).
- **sync deps:** authoring (fetch snapshot metadata) — guarded.

## exam-delivery  (critical path — most protected)
**Owns (db `exam_delivery`):** `ExamAttempt`, `AttemptAnswer`, `TimerState`, `PinnedExamSnapshot` (denormalized copy), `OutboxEntry`.
- **Package:** `com.pte.examdelivery`
- **controller:** `AttemptController` (start, get-next-task, submit-answer, submit-attempt), `TimerController` (heartbeat).
- **service:** `AttemptService` (state machine), `TimerService` (per-task prep/response enforcement), `SnapshotPinService`, `AnswerSubmitService`.
- **domain.enums:** `AttemptStatus` (CREATED, IN_PROGRESS, SUBMITTED, SCORING, SCORED, PUBLISHED), `AnswerStatus`.
- **Self-contained during exam:** pins snapshot + composition at start; **zero outbound sync calls** while a student is testing.
- **messaging.outbox:** `AnswerSubmitted`, `AttemptSubmitted` written in same TX as the answer.
- **consumes:** `ProctorCommand` (force-submit/extend-time), `AnswerScored` (update score), `AttemptPublished` (flip to PUBLISHED).
- **Resource-isolated:** own connection pool + compute; Redis warm cache + single-flight for snapshot load.
- **sync deps:** media (presigned upload URL for audio) — guarded, off the timer-critical path.

## proctor  (supervision — WebSocket)
**Owns (db `proctor`):** `ProctorSession`, `ViolationEvent`, `AuditLog` (tamper-evident, hash-chained).
- **Package:** `com.pte.proctor`
- **controller:** `ProctorWsController` (STOMP/WebSocket), `ProctorActionController` (force-submit/extend/flag REST).
- **service:** `ProctorSessionService`, `ViolationService`, `AuditService`.
- **emits:** `ProctorCommand` (exam-delivery consumes), `ViolationDetected` (notification consumes).
- **consumes:** `AttemptSubmitted` (close session).
- **Separate scaling profile** (long-lived WS) — its own deployable is justified independent of blast-radius.

## scoring  (assessment — async, host-gated)
**Owns (db `scoring`):** `ScoringJob`, `AnswerScore`, `SkillScore`, `VendorResult`, dedup keys.
- **Package:** `com.pte.scoring`
- **service:** `ObjectiveScoringService` (rule-based), `SpeechScoringService` (vendor wrapper), `EssayScoringService` (vendor wrapper), `ScoringOrchestrator`.
- **domain.enums:** `ScoringStatus` (PENDING, SCORED, FAILED), `EnablingSkill`.
- **messaging.consumer:** consumes `ScoringRequested` (host command) → fan-out `ScoringJob` to **RabbitMQ** worker queue → call AI vendor async → retry/backoff → DLQ.
- **emits:** `AnswerScored`, `AttemptScored`.
- **Executes only on command** — never auto-triggers on `AttemptSubmitted`. Does not own the publish decision.
- **sync deps:** media (fetch audio) — guarded; external AI vendor (timeout + CB).

## reporting  (read model — CQRS)
**Owns (db `reporting`, read-optimized / replica):** `AttemptReport`, `SkillScoreProjection`, `ScoreAggregate` (10–90).
- **Package:** `com.pte.reporting`
- **controller:** `ReportController` (student sees only PUBLISHED; host sees SCORED+).
- **service:** `ReportProjectionService`, `ScoreAggregationService` (Overall + 4 communicative + 6 enabling; **handles partial/practice subset gracefully** — reports "insufficient data" for skills with no contributing task).
- **consumes:** `AttemptSubmitted`, `AnswerScored`, `AttemptScored`, `AttemptPublished` → builds projection.
- **Owns no source-of-truth.** Reads from replica where possible.
- **sync deps:** none.

## notification  (outbound messaging)
**Owns (db `notification`):** `NotificationLog`, `DeliveryStatus`, `Template`.
- **Package:** `com.pte.notification`
- **service:** `EmailService`, `PushService`, `NotificationDispatcher`.
- **consumes:** `ViolationDetected`, `AttemptScored`, `AttemptPublished`, `ImportCompleted`, `StudentEnrolled`.
- **Independent vendor + retry**; never blocks a producer.
- **sync deps:** external email/push provider (timeout + CB).

## media  (binary storage)
**Owns (db `media` + object store MinIO/S3):** `MediaObject`, `UploadTicket`.
- **Package:** `com.pte.media`
- **controller:** `MediaController` (request presigned upload/download URL), `MediaCallbackController` (upload complete).
- **service:** `PresignService`, `MediaValidationService` (type/size), `TranscodeService` (async, deferred).
- **Short-TTL presigned URLs**; watermark hook (deferred). Binary never in Postgres.
- **sync deps:** object store.

---

## Cross-service reference rule (reminder)
A service stores another service's key as a plain `UUID publicId` column and resolves it via API/event — **never** a JPA relationship across service boundaries. Example: `exam-delivery.PinnedExamSnapshot.snapshotPublicId` references `authoring.ExamSnapshot.publicId`, copied at pin time, never joined.

## Build order (walking skeleton — see conversation)
gateway + iam → exam-delivery (end-to-end w/ pinned snapshot) → authoring + scheduling → event backbone (Kafka+Debezium) → scoring + RabbitMQ + real vendor → reporting → notification/media → pte-app Flutter. Vendor selection runs as a parallel spike (long pole).
