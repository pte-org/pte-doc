# Phase 7: Scoring — Host-Gated, Objective First

## Requirements

Scoring never auto-triggers on submit (ADR-002). It executes only on the host's `ScoringRequested` command (already emitted by scheduling's `HostCommandService` since Phase 4). Milestone 1 scope is **objective/rule-based scoring only** (`MC_READING_SINGLE`) — speaking/writing (`READ_ALOUD`, `WRITE_ESSAY`) require an AI vendor, deferred to Phase 9. Scoring consumes exam-delivery's `AnswerSubmitted` events to build its own local projection of submitted answers (event-driven, no runtime dependency on exam-delivery being up), then on `ScoringRequested` scores whatever answers in that session it currently knows how to grade, emitting `AnswerScored` per answer and `AttemptScored` once an attempt has nothing left `PENDING`.

## Design Constraints

- **RabbitMQ deferred to Phase 9** (scope revision from plan.md's original one-liner): RabbitMQ's justification throughout this project has been queueing *slow, unreliable* work (AI vendor calls needing retry/backoff/DLQ). Objective scoring is fast, deterministic, in-process compute — queueing it buys nothing and adds an unused broker dependency now. Executes synchronously inside the Kafka listener's transaction. Revisit when Phase 9 adds real vendor calls.
- **Event-carries-state, not a new guarded pull**: exam-delivery's `AnswerSubmittedEvent` (Phase 5, approved) is enriched — additive fields only (`sessionPublicId`, `taskType`, `payload`, `correctAnswerText`, `optionsJson`) — so scoring never calls back to exam-delivery. No existing consumer of this event exists yet, so this is a safe, backward-compatible change to already-shipped code.
- Ingestion (accumulate `AnswerSubmitted` → local `ScoringAnswer`, status `PENDING`) and command execution (`ScoringRequested` → score `PENDING` rows) are two separate consumers on two separate topics — ingestion never blocks on a command, and a `ScoringRequested` arriving before all answers have been ingested just scores what's there so far (host can re-request).
- **Honest completion semantics**: a non-objective answer (`READ_ALOUD`/`WRITE_ESSAY`) stays `PENDING` — there is no `SKIPPED` status that fakes completion. `AttemptScored` only fires when an attempt has zero `PENDING` rows left, which for a mixed-task attempt won't happen until Phase 9 exists. This is correct, not a gap: grading genuinely isn't complete yet. A practice-subset session composed of objective types only DOES reach full completion in this phase — exercises the whole pipeline honestly.
- Idempotent consumers (ADR-002): same `ProcessedEvent` pattern as Phase 6, applied to both topics this service listens to (`outbox.event.ExamAttempt` for `AnswerSubmitted`, `outbox.event.ExamSession` for `ScoringRequested`).
- Database-per-service: `scoring` owns its own DB; no join into exam-delivery's or scheduling's schema.

## Steps

1. exam-delivery touch-up: `AnswerSubmittedEvent` gains `sessionPublicId`, `taskType`, `payload`, `correctAnswerText`, `optionsJson`; `AnswerSubmitService.persist` populates them from `ExamAttempt`/`PinnedItem`.
2. `scoring` module: `ScoringAnswer` entity (the local projection), `ProcessedEvent`, `OutboxEntry` (reuse `AbstractOutboxEntry`/`AbstractOutboxWriter`).
3. `AnswerIngestConsumer` (topic `outbox.event.ExamAttempt`, event type `AnswerSubmitted` only): idempotent upsert into `ScoringAnswer` (status `PENDING`).
4. `ObjectiveScoringService`: task-type-dispatch rule-based scoring. `MC_READING_SINGLE`: parse `optionsJson`, compare the correct option's `orderIndex` against the student's submitted `payload` (contract: payload is the selected option's orderIndex as a string — documented on exam-delivery's `SubmitAnswerRequest`, not previously explicit). Null/unparseable payload scores incorrect, not an error.
5. `ScoringCommandConsumer` (topic `outbox.event.ExamSession`, event type `ScoringRequested` only): loads `PENDING` `ScoringAnswer` rows for the session; scores every objective-type row via `ObjectiveScoringService`; emits `AnswerScored` per scored row; after scoring, for each affected `attemptPublicId` with zero remaining `PENDING` rows, emits `AttemptScored`.
6. Outbox writer for `AnswerScored`/`AttemptScored`. No controllers this phase — scoring has no human-facing surface yet (Phase 8/reporting reads its output via events, not a query API).

## Success Criteria

- An `MC_READING_SINGLE` answer submitted in exam-delivery, then a host `ScoringRequested` command, results in a correct `AnswerScored` event with the right raw score (1 correct / 0 incorrect).
- A `READ_ALOUD`/`WRITE_ESSAY` answer stays `PENDING` after `ScoringRequested` — no fake completion.
- An attempt composed entirely of objective types reaches `AttemptScored`; a mixed attempt does not (yet — correct for Milestone 1).
- Re-delivering the same `AnswerSubmitted` or `ScoringRequested` event does not double-score or double-emit.
- Scoring never calls exam-delivery or scheduling synchronously.

## Quality and Testing State

- Quality gate: **approved** (2026-07-26). 0 findings. Report + receipt: `pte-api/plans/quang-pte-microservice-platform/quality/phase-07-scoring-objective-{quality-report,receipt}.json`.
- Testing: not started — **declined by user** (quality-only cook run). Build Gate green: full 8-module reactor `mvn install` (pte-common+gateway+iam+admin+authoring+scheduling+exam-delivery+scoring).

## Runtime-verification TODO (not run here — no live Kafka/Debezium/Postgres cluster in this environment)
- `docker compose up -d` + register connectors (incl. new `scoring-outbox-connector.json`) → submit an MC_READING_SINGLE answer in exam-delivery → confirm `scoring.scoring_answers` gets a PENDING row.
- Host issues `ScoringRequested` (via scheduling's `/sessions/{id}/score`) → confirm `AnswerScored` fires with correct raw score (test both a correct and incorrect submission).
- Submit answers for all 3 demo task types in one attempt, request scoring → confirm MC_READING_SINGLE answer scores, READ_ALOUD/WRITE_ESSAY stay PENDING, no `AttemptScored` fires (correct, awaits Phase 9).
- Create a practice-subset session (MC_READING_SINGLE only), complete it, request scoring → confirm `AttemptScored` DOES fire.
- Replay the same Kafka message twice → confirm no duplicate `ScoringAnswer` row / no double `AnswerScored`.

## Risks

- **MEDIUM: exam-delivery event-shape change touches Phase 5's approved code.** *Mitigation:* additive fields only, no consumer of the old shape exists yet, re-verified by this phase's own quality gate covering both services' diffs.
- **LOW: `AttemptScored` never fires for mixed-task attempts until Phase 9** — by design, not a defect; documented above to prevent it being mistaken for a bug later.
