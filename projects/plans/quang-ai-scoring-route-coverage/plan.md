# Plan: AI Scoring Route Coverage

**Date:** 2026-09-12
**Status:** Phase 3 complete; real AI provider work remains
**Mode:** Hard
**Scope:** `pte-api/services/scoring`

## Objective

Route every remaining AI-shaped PTE task through the existing asynchronous
RabbitMQ scoring pipeline so a `ScoringRequested` command no longer leaves a
known scored task in `PENDING`. This phase expands routing only and keeps the
existing deterministic stub clients explicit; it does not claim production
AI scoring or vendor calibration.

## Phases

- [x] Phase 3: AI route coverage skeleton — classify all ten speech/text
  tasks, route them to the correct modality client, and test the worker/queue
  boundary. [quality: approved; testing: passed 88/88 reactor tests]

## Design Constraints

- Preserve the current non-blocking flow: command consumer marks AI answers
  `AI_SCORING`, publishes `AiScoringJob`, and the worker finalizes them.
- Speech-shaped tasks use `SpeechScoringClient`; text-shaped tasks use
  `EssayScoringClient`. A malformed/unknown job must fail explicitly rather
  than silently falling through to the essay client.
- Keep the client interfaces and `ScoringAnswer`/event/database schemas
  unchanged. Do not send raw audio through the transactional answer API.
- The current clients are deterministic stubs. Every result must remain
  visibly marked as placeholder until a separate provider phase replaces them.
- Personal Introduction is unscored and must not enter the AI catalog.
- The task catalog is the single source of truth for dispatcher support and
  worker modality classification.

## Task Catalog

| Modality | Task types | Current client |
|---|---|---|
| Speech | `READ_ALOUD`, `REPEAT_SENTENCE`, `DESCRIBE_IMAGE`, `RE_TELL_LECTURE`, `ANSWER_SHORT_QUESTION`, `RESPOND_TO_A_SITUATION`, `SUMMARIZE_GROUP_DISCUSSION` | `SpeechScoringClient` stub |
| Text | `WRITE_ESSAY`, `SUMMARIZE_WRITTEN_TEXT`, `SUMMARIZE_SPOKEN_TEXT` | `EssayScoringClient` stub |

## Success Criteria

- All ten catalog task types return true from dispatcher `supports()`.
- Worker routes every speech task to the speech client and every text task
  to the essay client; unsupported task types are rejected explicitly.
- Existing AI status/event/completion behavior remains unchanged.
- Full scoring Maven reactor passes with no skipped tests.
- Coverage report distinguishes complete routing from non-production stub
  scoring.

## Explicitly Deferred

- Real speech/ASR and essay provider adapters, credentials, latency/cost PoC,
  calibration and rubric validation.
- Retry/idempotency redesign for the existing RabbitMQ transaction/publish
  boundary; it remains documented technical debt.
- Score aggregation/reporting and authoring seed/content migration.

## Quality and Testing State

- Quality gate: approved. See `quality/phase-03-ai-route-coverage-quality-report.json`.
- Testing: passed. See `tests/phase-03-ai-route-coverage-test-report.json`.

## File Ownership

- `pte-api/services/scoring/src/main/java/com/pte/scoring/service/AiScoringTaskCatalog.java`
- `pte-api/services/scoring/src/main/java/com/pte/scoring/service/AiScoringDispatcher.java`
- `pte-api/services/scoring/src/main/java/com/pte/scoring/messaging/consumer/AiScoringWorker.java`
- `pte-api/services/scoring/src/test/java/com/pte/scoring/service/AiScoringTaskCatalogTest.java`
- `pte-api/services/scoring/src/test/java/com/pte/scoring/service/AiScoringDispatcherTest.java`
- `pte-api/services/scoring/src/test/java/com/pte/scoring/messaging/consumer/AiScoringWorkerTest.java`
