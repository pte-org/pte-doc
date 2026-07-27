# Phase 8: Reporting — CQRS Read Model & Publish Gate

## Requirements

The student-visible endpoint of the whole pipeline: a CQRS read model built entirely from events (`AttemptSubmitted`/`AnswerSubmitted` from exam-delivery, `AnswerScored` from scoring, `PublishRequested` from scheduling), computing the PTE-style 10–90 score report (Overall + 4 communicative + 6 enabling skills) and gating visibility so a student sees **nothing** until the host explicitly publishes (ADR-002 host-gated model). Handles partial data gracefully — a skill with no contributing scored answer reports "insufficient data," the same mechanism whether the gap is a practice-subset composition choice or (Milestone 1's reality) an unimplemented AI scorer for speaking/writing.

## Design Constraints

- **Owns no source-of-truth** — every field is a projection from consumed events. No cross-service DB join, no synchronous call to exam-delivery/scoring/scheduling.
- **Publish is a visibility gate, not a data freeze**: `PublishRequested` (session-level) marks every attempt in that session `published=true`. The report itself is always computed live from current projection state — if more scores arrive after publish (e.g. Phase 9's AI scoring completing later), the already-visible report simply reflects the update. No re-publish action needed.
- **10–90 conversion is a documented simulation, not Pearson's algorithm** (already out-of-scope per spec.md — this is a thesis simulation, not a certified scoring engine). Formula: `scaledScore = round(10 + (correctCount / scoredCount) * 80)` per skill from its contributing objective answers; Overall = average of communicative skills that have data. Simple, defensible, and clearly labeled as a placeholder — not a claim of Pearson equivalence.
- **Config-driven skill mapping, own copy**: reporting carries its own copy of `task-skill-mapping.json` (same content as authoring's) rather than calling authoring for it — config is data, not runtime state, matching the same principle behind exam-delivery's own `task-timing.json`.
- **Scope boundary, explicit**: reporting emits `AttemptPublished` to its own outbox (the contract exists for future consumers) but exam-delivery is NOT touched this phase to consume it and flip its own `AttemptStatus.PUBLISHED` — nothing in Milestone 1 needs exam-delivery's own status field to reach `PUBLISHED` for the report to be visible; that's reporting's `published` flag doing the actual gating. Revisit when a host-side "all my attempts" view needs exam-delivery's status to be accurate too.
- Visibility rule: STUDENT role sees a report only if `published=true` AND the caller is that attempt's own student; HOST_ADMIN/HOST_AUTHOR sees any time, scoped to their own tenant (review-before-publish).

## Steps

1. `AttemptReport` (attemptPublicId, sessionPublicId, studentPublicId, tenantId, published, publishedAt), `AnswerProjection` (answerPublicId, attemptPublicId, taskType, rawScore nullable, scored boolean), `ProcessedEvent`, `OutboxEntry`. Flyway `V1__reporting.sql`.
2. Own copy of `config/task-skill-mapping.json` + loader (mirrors authoring's `PteTaskTypeSkillMapping`).
3. `AttemptIngestConsumer` (topic `outbox.event.ExamAttempt`): `AttemptSubmitted` → upsert `AttemptReport`; `AnswerSubmitted` → insert `AnswerProjection` (unscored).
4. `AnswerScoredConsumer` (topic `outbox.event.ScoringAnswer`): `AnswerScored` → update the matching `AnswerProjection`'s `rawScore`/`scored`.
5. `PublishConsumer` (topic `outbox.event.ExamSession`, event type `PublishRequested`): marks every `AttemptReport` for the session `published=true`; emits `AttemptPublished` per attempt.
6. `ScoreAggregationService`: per-skill scaled score + "insufficient data" flag when no contributing scored answer exists; Overall from communicative skills with data.
7. `ReportController` — `GET /reports/attempts/{publicId}`: STUDENT (own + published only) or HOST_ADMIN/HOST_AUTHOR (own tenant, any time).

## Success Criteria

- A published attempt's report shows a correct scaled score for Reading (from `MC_READING_SINGLE` answers) and "insufficient data" for every enabling skill and for Speaking/Writing/Listening (Milestone 1 has no AI scorer yet).
- An unpublished attempt returns not-found to the student, but is visible to the host (same tenant).
- Re-delivering any consumed event does not double-count a score or corrupt the aggregation.
- No synchronous call to any other service anywhere in reporting.

## Quality and Testing State

- Quality gate: **approved** (2026-07-26). 0 findings. Report + receipt: `pte-api/plans/quang-pte-microservice-platform/quality/phase-08-reporting-publish-gate-{quality-report,receipt}.json`.
- Testing: not started — **declined by user** (quality-only cook run). Build Gate green: full 9-module reactor `mvn install` (pte-common+gateway+iam+admin+authoring+scheduling+exam-delivery+scoring+reporting).

## Runtime-verification TODO (not run here — no live Kafka/Debezium/Postgres cluster in this environment)
- `docker compose up -d` + register connectors (incl. new `reporting-outbox-connector.json`) → complete a full attempt (submit MC_READING_SINGLE answers) → host requests scoring → confirm `reporting.answer_projections` gets scored rows.
- Host requests publish (`/sessions/{id}/publish`) → confirm `reporting.attempt_reports.published=true` for every attempt in that session, and `AttemptPublished` lands on `outbox.event.AttemptReport`.
- As the attempt's own student: `GET /reports/attempts/{id}` → confirm Reading shows a real score, all other skills show "insufficient data," and this only works AFTER publish (404 before).
- As a different student, or before publish: confirm 404 (not 403 — no existence leak).
- As the host (same tenant): confirm the report is visible even before publish (review path).
- As a host from a different tenant: confirm 404.

## Risks

- **LOW: 10–90 formula is a placeholder** — documented, not a defect; revisit if the thesis advisor wants a closer approximation of Pearson's real weighting.
- **LOW: exam-delivery's own `AttemptStatus.PUBLISHED` stays unreached this phase** — documented scope boundary above, not a bug.
