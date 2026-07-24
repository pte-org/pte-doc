# Plan: PTE Microservice Platform — Milestone 1 (Walking Skeleton + Core Exam Flow)

Status: 🟡 In Progress
Date: 2026-07-24
Mode: Hard
Architecture: ADR-001/002/003/004 (`pte-doc/projects/architecture/`), `docs/CODING_STANDARDS_MICROSERVICE.md`

## Overview

Build the production-grade microservice foundation and the core exam-taking flow as a **walking skeleton**: each phase ships one runnable vertical slice, no big-bang. Milestone 1 delivers, end-to-end: admin onboards an organization → host authors questions + composes a session (full mock or practice subset) + enrolls students/proctors → student takes a timed exam across 3 task types (Multiple Choice Reading, Read Aloud, Write Essay) → host triggers scoring → host publishes → student sees a 10–90 report. Mono-repo, database-per-service, event backbone (Kafka + Debezium outbox), Redis warm cache, host-gated scoring with real AI vendor.

Out of scope for Milestone 1: remaining 19 task types, file-based bulk import, proctor analytics beyond force-submit/extend, notification channels beyond email, adaptive/IRT selection, Vault/Keycloak/service-mesh (deferred infra — see ADR-003 §Consequences; JWT hand-rolled in iam for now, swap to Keycloak later without contract change).

## Build order (walking skeleton)

Foundation → auth → control plane → content → session → **exam core** → backbone → scoring → reporting → media/speaking → proctor → notification → Flutter. Vendor-selection spike runs in parallel (long pole), gated before Phase 9.

## Phases

- [ ] **Phase 0: Mono-repo scaffold + `pte-common` + infra + gateway** — Maven multi-module skeleton, thin shared lib (ApiResponse, DomainException, JWT filter, BaseEntity, event envelope, correlation-id), docker-compose (Postgres/Kafka/Redis/RabbitMQ), Spring Cloud Gateway edge with JWT validation + per-tenant rate-limit.
- [ ] **Phase 1: iam (auth server)** — User/Credential/Role/TenantMembership, login/refresh, RS256 JWT with tenantId+role claims, JWKS endpoint. Host/proctor/student user CRUD. Emits `UserCreated`.
- [ ] **Phase 2: admin (control plane)** — Tenant/Subscription lifecycle; admin onboards/suspends organization. Emits `TenantOnboarded`; iam consumes to seed tenant registry. Management flow: admin adds organization.
- [ ] **Phase 3: authoring** — Question (22 task types, type-specific fields, config-driven skill mapping) + ExamBlueprint + immutable versioned ExamSnapshot. Visibility: admin SHARED bank (`tenant_id=NULL`, host read-only) vs host PRIVATE. Emits `ExamSnapshotPublished`. Management flow: admin/host author questions.
- [ ] **Phase 4: scheduling** — ExamSession + SessionComposition (host optionally selects sections/task types → full mock vs practice) + Enrollment (host adds students + assigns proctors manually). Consumes `ExamSnapshotPublished`. Emits `SessionScheduled`, `StudentEnrolled`, and host commands `ScoringRequested`/`PublishRequested`.
- [ ] **Phase 5: exam-delivery core (objective)** — Attempt state machine, snapshot+composition pinning at start, per-task prep/response timer enforcement, submit-answer/submit-attempt. MCQ Reading end-to-end. Redis warm cache + single-flight snapshot load. Transactional Outbox (`AnswerSubmitted`/`AttemptSubmitted`). Zero outbound sync during attempt.
- [ ] **Phase 6: event backbone integration** — Kafka topics + Debezium CDC wiring outbox→Kafka across services; idempotent consumers (dedup by eventId); schema registry (Avro). Distributed tracing (OpenTelemetry) end-to-end via `pte-common`.
- [ ] **Phase 7: scoring (host-gated, objective first)** — Consumes `ScoringRequested` command → RabbitMQ fan-out → `ObjectiveScoringService` rule-based. State SUBMITTED→SCORING→SCORED. Emits `AnswerScored`/`AttemptScored`. No auto-trigger on submit.
- [ ] **Phase 8: reporting + publish gate** — CQRS read model from event stream; 10–90 aggregation (Overall + 4 communicative + 6 enabling); **partial/practice-subset handled gracefully** (skills with no contributing task report "insufficient data"). Student sees only PUBLISHED; host publishes (`PublishRequested`→`AttemptPublished`).
- [ ] **Phase 9: media + speaking/writing tasks + real AI vendor** — media presigned audio upload; Read Aloud + Write Essay tasks in exam-delivery; scoring speech/essay via **selected vendor** (spike prerequisite), retry/backoff/DLQ; human-review flag for the 7 sensitive task types. Extracts enabling sub-scores.
- [ ] **Phase 10: proctor** — ProctorSession (WebSocket/STOMP), force-submit/extend-time/flag-violation → `ProctorCommand` (exam-delivery consumes); tamper-evident audit log. Emits `ViolationDetected`.
- [ ] **Phase 11: notification** — Consumes `AttemptPublished`/`ViolationDetected`/`StudentEnrolled` → email. Independent retry.
- [ ] **Phase 12: pte-app (Flutter)** — Student exam runner (3 task types + timer UI) + host mini-console (author, compose session, enroll, trigger scoring, publish). Integrates against staging pte-api.

**Parallel spike (start now): Vendor selection** — evaluate speech (fluency/pronunciation) + essay scoring vendors; test latency/cost on samples; evaluate the user's "opencode" credential's provider; decide before Phase 9. Tie-break: cost → p99 latency → SDK quality → advisor rec.

## Design Constraints (apply to every phase)

- Package root `com.pte.<service>`; uniform layered layout (coding standard §2): `constant/controller/interfaces/service/dto/mapper/domain{enums,event,exception}/repository/messaging{outbox,publisher,consumer}/client/security/config`.
- Database-per-service (own schema + credential; co-located Postgres instance initially). No cross-service FK/join; reference by `publicId` UUID.
- Cross-service state change via Transactional Outbox → Kafka; never publish inside business TX. All consumers idempotent.
- Only iam is an auth server; all others are resource servers validating JWT locally via JWKS.
- Tenant isolation: tenantId param (controller→service→repo from claim) + Postgres RLS + gateway rate-limit.
- exam-delivery has zero synchronous outbound dependency during an attempt.
- `pte-common` stays thin: primitives + contracts only, no business entity/logic.
- Code-quality rules from `CODING_STANDARDS_API.md` still enforced (ApiResponse, @ControllerAdvice, @Valid, no @Data on @Entity, ≤300 lines, ≤5 public methods, constants).

## Dependencies

- Vendor availability (Phase 9) — mitigated by parallel spike + async retry.
- Debezium/Kafka operational before Phase 6 (docker-compose in Phase 0).
- Phase 5 depends on Phase 3 (snapshot) + Phase 4 (session/composition) contracts.

## Risks

- **HIGH: Milestone scope** — 12 phases + Flutter is a full platform. *Mitigation:* walking skeleton means Phase 5 already demoable (MCQ end-to-end) before speaking/vendor; reassess after Phase 8.
- **HIGH: Vendor long pole** — speech/essay latency/cost unknown. *Mitigation:* parallel spike gates Phase 9; objective path (Phases 5,7,8) ships without vendor.
- **MEDIUM: Distributed debugging** — 10 services. *Mitigation:* OpenTelemetry tracing mandatory from Phase 6, correlation-id from Phase 0.
- **MEDIUM: Partial scoring correctness** — practice subset yields incomplete skill profile. *Mitigation:* Phase 8 explicit "insufficient data" handling + tests.
- **LOW: Outbox/CDC complexity** — Debezium setup. *Mitigation:* Phase 6 isolates it; earlier phases write outbox rows, wiring activated in P6.

### Red-team findings (2026-07-24, NOTED)
- **Per-task timing sourcing** — exam-delivery (Phase 5/9) needs exact prep/response seconds for MCQ Reading, Read Aloud, Write Essay from official Pearson materials (unresolved since pivot Phase 2). *Action:* source before Phase 5 timer coding; if unavailable, stub with TODO gate + visible disclaimer, resolve before release.
- **RLS + PgBouncer transaction-pooling leak** — RLS sets `app.current_tenant` per connection; a transaction-mode pooler reuses connections across tenants → cross-tenant leak if the var isn't reset per transaction. *Action:* when PgBouncer is added, `RESET`/`SET LOCAL` the tenant var inside each transaction, or use session-pooling for RLS-bearing services. Not a Milestone-1 blocker (no pooler yet) but must gate the pooler phase.
- **Attempt-create sync pull (Phase 5)** — resolved: exactly one guarded sync pull allowed at attempt-create; invariant is zero sync *during* the attempt. Removed once Phase 6 events let exam-delivery cache locally.

## Success Criteria (Milestone 1)

- Admin onboards org; host authors questions, composes a session (full + practice subset), enrolls students/proctors — all tenant-isolated.
- Student completes a timed attempt across MCQ + Read Aloud + Write Essay; per-task timers enforced; zero outbound sync stall during exam.
- Scoring runs only on host command; student sees no score until host publishes; report shows 10–90 (partial handled for practice).
- No cross-service DB join anywhere; each service owns its DB; all events flow through outbox→Kafka idempotently.
- End-to-end trace visible per `attemptId`.

## Note on phase detail

Phases 0–5 are detailed in their phase files (cooked first). Phases 6–12 are outlined here and will be expanded into full phase files when Phase 5 completes and the skeleton is validated — deliberate, to avoid detailing distributed wiring before the core contracts are proven (YAGNI on speculative detail).
