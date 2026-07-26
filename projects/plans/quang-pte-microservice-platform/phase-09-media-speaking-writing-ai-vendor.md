# Phase 9: Media, Speaking/Writing Delivery & AI Vendor Scoring

## Requirements

Closes the loop on the two remaining Milestone-1 task types: `READ_ALOUD` (audio, no human review — matches Pearson's actual policy) and `WRITE_ESSAY` (text, **human-review-on-top-of-AI required** — one of Pearson's 7 sensitive types per spec.md). Adds `media` (presigned audio upload), activates RabbitMQ for AI-vendor work (Phase 7 deferred it until there was a real slow/unreliable external call to queue — this is that call), and extends scoring with a host-gated human-review step before an AI-scored essay becomes final.

## Design Constraints — vendor status (live-tested this session, decided with the user)

- **No AI vendor is wired to a real model call yet.** The two credentials provided (OpenRouter `tencent/hy3`, OpenCode `mimo-v2.5-free`) are confirmed **text-only** (verified via OpenRouter's model registry — `input_modalities: ["text"]`); OpenCode's audio-capable `gemini-3-flash` returned `CreditsError` (no payment method) when live-tested. **User's explicit direction: build the full framework now, plug in a real vendor adapter later.** `SpeechScoringClient`/`EssayScoringClient` are clean interfaces; the only implementation shipped this phase is a clearly-labeled stub that returns a deterministic placeholder and never calls out to any network vendor. Swapping in a real HTTP adapter later is a drop-in (implement the interface; a `scoring.ai.provider` config property is the seam).
- **Live-tested finding to carry into the real adapter later**: both tested models are reasoning models — the API response separates `message.reasoning` from `message.content`; only `.content` is the answer. `max_tokens` must budget for reasoning tokens too (a 50-token budget truncated the response entirely in testing) — use a generous ceiling (≥800) and `response_format: {"type":"json_object"}` for reliable parsing when a real adapter is built.
- **media is real, not stubbed** — object storage has no vendor-choice blocker (MinIO, self-hosted, no external account needed). Presigned upload only this phase (student → media → object store); a presigned *download* endpoint is deferred until a real vendor adapter actually needs to fetch audio bytes (YAGNI — the stub doesn't analyze audio, so it doesn't need it).
- **RabbitMQ activated** (Phase 7 deferred it here deliberately): AI scoring jobs are queued, not synchronous — a vendor call is slow/unreliable, needs retry/backoff and a DLQ after bounded attempts, unlike Phase 7's fast in-process objective scoring.
- **Human-review gate**: `WRITE_ESSAY` answers land in `AI_SCORED_PENDING_REVIEW` after the (stub) AI pass — host must explicitly approve before `AnswerScored` fires. `READ_ALOUD` does not require this (not one of the 7 sensitive types) — AI (stub) result goes straight to `SCORED`.
- Extends `ScoringAnswerStatus`: adds `AI_SCORING`, `AI_SCORED_PENDING_REVIEW`, `SCORING_FAILED` alongside Phase 7's `PENDING`/`SCORED`.

## Steps

1. `media` module (10th service): `MediaObject` (publicId, contentType, storageKey, status), `PresignService` (MinIO presigned PUT via `io.minio:minio` SDK), `POST /media/objects` (request upload → presigned URL + asset id), `POST /media/objects/{id}/complete` (client confirms upload done). MinIO added to `docker-compose.yml`.
2. exam-delivery: document (no code change needed — `payload` is already opaque) that `READ_ALOUD` submissions carry the uploaded media object's `publicId` as `payload`, matching the existing per-task-type payload contract pattern from Phase 7.
3. scoring: `ScoringAnswerStatus` gains 3 values. `AiScoringDispatcher`: on `ScoringRequested`, for `PENDING` rows with an AI-scorable taskType (`READ_ALOUD`, `WRITE_ESSAY`), transition to `AI_SCORING` and enqueue a RabbitMQ job (never leaves them silently `PENDING` like unsupported-type rows still do).
4. `AiScoringWorker` (RabbitMQ consumer): dispatches to `SpeechScoringClient`/`EssayScoringClient` by task type; on success, `WRITE_ESSAY` → `AI_SCORED_PENDING_REVIEW`, `READ_ALOUD` → `SCORED` (+ `AnswerScored`); on failure, Spring AMQP retry/backoff, then DLQ → `SCORING_FAILED`.
5. `SpeechScoringClient`/`EssayScoringClient` interfaces + `StubSpeechScoringClient`/`StubEssayScoringClient` (deterministic placeholder, clearly documented, no network call).
6. Host review: `ScoringReviewController` (scoring's first human-facing endpoint) — `POST /scoring/answers/{answerPublicId}/review` (HOST_ADMIN/HOST_AUTHOR, tenant-scoped) approves an `AI_SCORED_PENDING_REVIEW` row → `SCORED` + `AnswerScored`.
7. RabbitMQ config: `scoring.ai-scoring-jobs` queue + `scoring.ai-scoring-jobs.dlq`, bounded retry (Spring AMQP `RetryOperationsInterceptor`).

## Success Criteria

- A `READ_ALOUD` answer, after `ScoringRequested`, reaches `SCORED` via the stub adapter with no human step.
- A `WRITE_ESSAY` answer reaches `AI_SCORED_PENDING_REVIEW`, stays there until a host approves, then reaches `SCORED` + `AnswerScored` fires.
- A forced vendor-call failure (stub can simulate) retries with backoff, then lands in the DLQ and `SCORING_FAILED` — never stuck retrying forever.
- media issues a working presigned upload URL against a real MinIO instance; no code changes needed elsewhere to route audio through it.
- No component in this phase makes a real external network call to any AI vendor — confirmed by code inspection, not just intent.

## Quality and Testing State

- Quality gate: **APPROVED** (`ck:quality --gate`). First pass returned CHANGES_REQUIRED with 3 blocking findings, all fixed and verified in a second pass:
  - QUAL-001 (HIGH): `AiScoringWorker.onAiScoringJob`'s redelivery skip-check didn't exclude `AI_SCORED_PENDING_REVIEW`, so a redelivered message could re-call the vendor for an answer already awaiting host review. Fixed by adding it to the skip condition.
  - QUAL-002 (MEDIUM): `onDeadLettered`'s `@RabbitListener` omitted `containerFactory`, so DLQ-handler DB failures had no bounded retry/backoff. Fixed by specifying the same `rabbitListenerContainerFactory` used elsewhere.
  - QUAL-003 (MEDIUM): `PresignService.completeUpload` looked up `MediaObject` by `publicId` only, without a `tenantId` filter (defense-in-depth gap vs. the codebase's established tenant-scoping pattern). Fixed by adding `findByPublicIdAndTenantId` and using it.
  - Two NOTED findings confirmed correct, no action needed: the objective/AI 0-100 scale-consistency math, and the human-review gate's un-bypassable enforcement.
- Testing: skipped by user direction (quality-only cook mode).

## Risks

- **HIGH (carried forward, not resolved): real vendor integration still pending.** User will supply a working credential+model later; the interface seam exists, no architecture rework expected, but the actual scoring quality/cost is unverified until then.
- **MEDIUM: reasoning-model response parsing** — carried finding from live testing (see Design Constraints); must be respected whenever a real adapter is built, or JSON parsing will silently fail on truncated output.
- **LOW: media has no download-url endpoint yet** — deferred until a real vendor adapter needs to fetch audio; documented scope cut, not an oversight.
