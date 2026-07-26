# Member 1 — Backend Runtime Verification & Hardening

*[Bản tiếng Việt](tasks.vi.md)*

## Why this matters first

Every one of `pte-api`'s 12 services has only ever been verified by `mvn install` (compiles + quality-reviewed). None of it has been run against real Postgres/Kafka/Redis/RabbitMQ/MinIO/Mailpit. This is the highest-leverage work right now — Members 2–4 all need a backend that actually works to integrate against.

## Task 1 — Bring the stack up

- `cd pte-api && docker compose up -d` — brings up Postgres (with `wal_level=logical` for Debezium), Redis, MinIO, RabbitMQ, Kafka (KRaft, single-node), Schema Registry, Debezium Connect, Jaeger, Mailpit.
- Confirm `docker-compose.yml`'s `debezium-connectors-setup` one-shot container registers every connector in `docker/debezium/connectors/*.json` (7 connectors: admin, authoring, exam-delivery, iam, proctor, reporting, scheduling, scoring — 8 actually, recount when you get there). Verify via `curl http://localhost:8092/connectors`.
- Start each of the 12 services (`services/*` + `gateway`) — either `mvn spring-boot:run` per module or run the built jars. Every service's `application.yml` has sane localhost defaults; check `.env`/`.env.example` at `pte-api/` root for anything that needs a real value (internal service key must match across all services — currently a shared dev default, confirm it's consistent).
- Fix whatever doesn't start. Common suspects: Flyway migration ordering, missing DB role/database (should be pre-provisioned by `docker/postgres/init/01-create-databases.sql` — verify all 12 database/role pairs exist, including `proctor` and `notification` which were added late), Kafka topic auto-creation, RabbitMQ queue/exchange declarations (scoring's AI-scoring queue, notification's email queue).

## Task 2 — Smoke-test the critical path end-to-end

Walk the full Milestone-1 user journey manually (Postman/curl/httpie — whatever's fastest for you), in order, using real JWTs from `iam`:

1. `admin` onboards a tenant (org) → confirm `iam` consumes `TenantOnboarded` and the tenant becomes usable.
2. `iam` creates a host user, a proctor user, a student user in that tenant. Log in as each, confirm JWT roles/tenant claim are correct.
3. As host: `authoring` — create a few questions (at least one `MC_READING_SINGLE`, one `READ_ALOUD`, one `WRITE_ESSAY`), build a blueprint, publish a snapshot.
4. As host: `scheduling` — create a session from that snapshot, optionally set a practice-subset composition, enroll the student, assign the proctor.
5. As student: `exam-delivery` — start the attempt (confirm the guarded sync pull to `scheduling`+`authoring` works, snapshot pins correctly), walk through all 3 task types, confirm server-side timers actually enforce (let one expire on purpose), submit answers, submit the attempt.
6. Confirm `AttemptSubmitted`/`AnswerSubmitted` actually reach Kafka (`outbox.event.ExamAttempt` topic) via Debezium — check with a console consumer if needed.
7. As host: `scheduling` — trigger `POST /sessions/{id}/score` (`ScoringRequested`). Confirm `scoring` picks it up: the MC_READING_SINGLE answer scores synchronously; the READ_ALOUD/WRITE_ESSAY answers get queued to RabbitMQ, picked up by the stub vendor, WRITE_ESSAY lands in `AI_SCORED_PENDING_REVIEW`.
8. As host: approve the pending essay review (`POST /scoring/answers/{id}/review`).
9. As host: trigger publish (`POST /sessions/{id}/publish`). Confirm `reporting` marks the attempt report published and emits `AttemptPublished`.
10. As student: `GET /reports/attempts/{id}` — confirm a real scaled score for Reading, "insufficient data" for everything else (no AI vendor yet).
11. Confirm `notification` actually sent an email — check the Mailpit UI (`http://localhost:8025`) for the `StudentEnrolled` and `AttemptPublished` emails.
12. As proctor: connect over STOMP to `proctor`'s `/ws` endpoint (need a STOMP test client — `wscat` won't speak STOMP; use a small script or Postman's WS support with raw STOMP frames), open a `ProctorSession` for the session above, issue a `FORCE_SUBMIT` or `EXTEND_TIME` against the student's attempt, confirm `exam-delivery` actually applies it. Flag a violation, confirm it shows up in `notification`'s audit log and a `HOST_ADMIN` gets an email.

Document every failure you hit and how you fixed it. If a fix is non-trivial (not just a config typo), write it into the relevant `phase-XX-*.md`'s "Runtime-verification TODO" or "Risks" section so the record stays accurate.

## Task 3 — Event backbone resilience checks

- Kill a consumer mid-processing (e.g. stop `scoring` right after it reads a Kafka message but before commit) and restart it — confirm the idempotency ledger (`ProcessedEvent`) actually prevents double-processing on redelivery.
- Same for RabbitMQ: force a scoring vendor call to fail 3 times (stub can be made to throw) and confirm it lands in the DLQ and the answer shows `SCORING_FAILED`, not stuck retrying forever.
- Verify Debezium CDC lag is reasonable under a burst of writes (nothing scientific needed — just confirm nothing silently drops).

## Task 4 — Critical-path integration tests

This project explicitly skipped tests during the cook pipeline (a deliberate scope choice, not an oversight). Now that the code exists and (hopefully) runs, add integration tests for the path that matters most:

- `exam-delivery`: attempt state machine (start → in-progress → submit), timer expiry auto-advance, double-attempt rejection.
- `scoring`: host-gated trigger (never auto-fires on submit), objective scoring correctness, the AI-scoring queue's retry/DLQ behavior.
- Testcontainers (Postgres + Kafka + RabbitMQ) is the natural fit given this stack — check if it's already a dependency anywhere (it isn't, as of this handoff) before introducing it project-wide.

Don't try to reach full coverage across all 12 services solo — this task is explicitly scoped to the critical path. Flag remaining test-coverage gaps for the team rather than attempting all of it.

## Deliverable

- A working `docker compose up` + all 12 services running, with the critical path proven end-to-end.
- Fixes committed with clear messages (small, reviewable commits — not one giant "fix everything" commit).
- Updated "Runtime-verification TODO" sections in the phase docs that had them stubbed (phase-04, phase-05, phase-08 already have this section — fill it in with what you actually found).
- A short written summary (add it to this folder as `findings.md`) of what broke, what you fixed, and what's still risky for the next person.
