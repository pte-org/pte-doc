# Member 4 — Real AI Vendor Adapter + Dockerize + CI

*[Bản tiếng Việt](tasks.vi.md)*

## Task 1 — Real AI vendor adapter (blocked on an API key)

`scoring`'s `SpeechScoringClient`/`EssayScoringClient` are clean interfaces (`pte-api/services/scoring/src/main/java/com/pte/scoring/vendor/`); the only shipped implementations are `StubSpeechScoringClient`/`StubEssayScoringClient` — deterministic, zero network calls, clearly documented as placeholders. Read `pte-doc/projects/plans/quang-pte-microservice-platform/phase-09-media-speaking-writing-ai-vendor.md` in full before starting — it documents:

- The exact interface seam (implement `SpeechScoringClient`/`EssayScoringClient`, wire via a `scoring.ai.provider` config property, swap the stub bean for your real one).
- **Live-tested findings from evaluating two candidate providers** (OpenRouter, OpenCode) that will apply to whatever provider you end up using if it's also a "reasoning model": the API response separates `message.reasoning` from `message.content` — parse `.content` only, or you'll silently score empty strings. Budget `max_tokens >= 800` (small budgets get consumed entirely by reasoning tokens before any answer content is generated — this actually happened during testing, response came back empty). Use `response_format: {"type":"json_object"}` if the provider supports it, for reliable parsing.
- The scale contract: `AiScoreResult.rawScore()` must be **0–100**, matching `ObjectiveScoringService`'s scale (this was a deliberate fix during Phase 9 — objective scoring used to be 0/1, changed specifically so AI and objective scores could average together correctly in `reporting`'s aggregation). Do not reintroduce a scale mismatch.
- `WRITE_ESSAY` requires human review before becoming visible (`AI_SCORED_PENDING_REVIEW` → host approves → `SCORED`); `READ_ALOUD` doesn't. This routing already exists in `AiScoringWorker` — you're only replacing the vendor call, not the state machine around it.

**You need a real API key/model that actually supports audio input for `READ_ALOUD`** (the two credentials tested in Phase 9 were text-only or payment-blocked) — this is an external dependency on the team lead providing one, not something you can unblock yourself. Start with `WRITE_ESSAY` (text-only, any LLM works) while waiting on a speech-capable credential.

## Task 2 — ~~Dockerize every service~~ ✅ Done (2026-08-05) — nothing left for you here

This is already complete: a single shared multi-stage `pte-api/Dockerfile` (parametrized via a `SERVICE_MODULE` build-arg — one Dockerfile reused by all 11 modules instead of one per service, DRYer than what this task originally called for) + `pte-api/docker-compose.services.yml` (gateway + all 10 backend services, wired to the existing infra services by container name, never `localhost`, keeping the existing `${SERVICE_PORT:-default}` env-var pattern). `docker compose -f docker-compose.yml -f docker-compose.services.yml up --build` brings up all 17 containers (6 infra + gateway + 10 services), all reaching `healthy`. See `pte-api/README.md`'s "Running services locally with Docker Compose" section and `pte-doc/projects/plans/phat-docker-compose-services/plan.md` for the full implementation record.

Also note: the infra list above was stale independent of this task — `docker-compose.yml` runs Postgres, Redis, RabbitMQ, MinIO, Mailpit, Jaeger. Kafka/Schema Registry/Debezium were removed platform-wide on 2026-07-31 (ADR-002's "Superseded-in-part" note) — the event backbone is RabbitMQ + an application-level polling outbox relay, not Kafka/Debezium CDC.

## Task 3 — CI pipeline

- Backend: `mvn install` (compile-only is fine given there's no test suite yet — coordinate with Member 1 once integration tests exist, add `mvn verify` or a dedicated test stage then).
- Frontend: `flutter analyze` + `flutter test` + `dart format --check` (matches `pte-app/README.md`'s documented pre-review checklist).
- Fail the pipeline on either failing — this is the cheapest regression guard available before real test coverage exists.

## Task 4 — Secrets & environment audit

- Audit `pte-api/.env.example` for completeness — every service that reads an env var (internal service key, DB passwords, `MAIL_HOST`, `RABBITMQ_*`, AI vendor key once Task 1 lands) should have a documented placeholder there.
- The internal service key (`INTERNAL_SERVICE_KEY`, used for the `/internal/**` service-to-service trust boundary — ADR-003's mTLS placeholder) is currently a shared dev default across every service's `application.yml`. Confirm it's actually consistent, and flag it clearly as a "rotate before any real deployment" item — it is not currently a secret in any meaningful sense.

## Deliverable

- Real (non-stub) essay scoring working end-to-end, speech scoring working once a capable credential is available.
- `docker compose up` brings up the entire platform — infra AND application services — with zero manual per-service startup. ✅ Already delivered via Task 2 above.
- A CI pipeline that runs on every push/PR for both repos.
