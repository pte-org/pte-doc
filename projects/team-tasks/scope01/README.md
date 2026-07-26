# Team Task Division — Post-Backend Handoff

*[Bản tiếng Việt](README.vi.md)*

## Where things stand

`pte-api` (backend) Phases 0–11 are **done and quality-approved** (`ck:quality --gate` APPROVED for every phase — see `../plan.md` and `../quality/phase-*-receipt.json`). 12 services + gateway, all compiling clean as one Maven reactor.

**What "done" does NOT mean:**
- **Never runtime-tested.** Every phase was verified by `mvn install` (compiles + passes quality review) only. Nobody has run `docker compose up` and actually exercised a live request against these services. Real bugs are expected to surface.
- **Zero automated tests.** Cook mode this whole project ran "quality only, no tests" by explicit decision — there is no unit/integration test suite anywhere in `pte-api`.
- **AI vendor scoring is a stub.** `scoring`'s `StubSpeechScoringClient`/`StubEssayScoringClient` return deterministic placeholder scores and make zero network calls. See `../phase-09-media-speaking-writing-ai-vendor.md` for the interface seam and the live-tested findings (reasoning-model response parsing) to reuse when wiring a real vendor.
- **`pte-app` (Flutter) is untouched** — the directory that exists today (`pte-app/`) is a pre-pivot scaffold called `aptis_app`, one commit ("init"), configured against a *different* backend (`api.aptis.example.com`). It shares no contract with `pte-api`. Its `core/` layer (Dio client, Drift offline-outbox, timer service, sync engine) is architecturally generic and may be worth reusing — but this is an **open decision, not yet made**. Resolve it with the team lead before Member 2/3 write app code (see their task files).
- **WebSocket-through-gateway routing (proctor) is unverified** — configured per the documented Spring Cloud Gateway pattern (phase-10) but never actually connected through.

## The 4-way split

| # | Focus | Depends on |
|---|---|---|
| [Member 1](member_1/tasks.md) | Backend runtime verification, bug-fixing, critical-path integration tests | Nothing — start immediately |
| [Member 2](member_2/tasks.md) | Flutter: student exam runner (auth, 3 task types, timer, submit) | Backend must actually run (Member 1); can start UI/local work in parallel against documented contracts |
| [Member 3](member_3/tasks.md) | Flutter: host mini-console (author, compose session, enroll, score, publish, review) | Same as Member 2 |
| [Member 4](member_4/tasks.md) | Real AI vendor adapter + Dockerize services + CI | AI vendor work needs a real API key (external dependency, not Member 1); Dockerize/CI can start immediately |

**Suggested sequencing:** Member 1 should get the stack running and smoke-test the critical path (onboard → author → schedule → attempt → score → publish → report) in the first pass — this is what everyone else's integration testing depends on. Members 2–4 can build in parallel against the documented REST contracts (each phase's controller + DTO files are the source of truth — there is no OpenAPI spec generated yet) and integrate against a live backend once Member 1 confirms it's stable.

## Reference material every member should read first

- `../plan.md` — full phase list, Design Constraints, Risks (esp. the "Red-team findings" section — per-task timing sourcing is still unresolved, and the RLS+PgBouncer risk applies to whoever adds connection pooling).
- `../../architecture/ADR-001-microservice-boundaries.md` / `ADR-002-communication-and-exam-submission-saga.md` / `ADR-003-tenant-isolation-and-infrastructure.md` / `ADR-004-per-service-code-structure.md`.
- Each `../phase-XX-*.md` — "Quality and Testing State" and "Risks" sections list what's been verified vs. deferred, per service.
- `docs/CODING_STANDARDS_MICROSERVICE.md` (pte-api) and `docs/CODING_STANDARDS_APP.md` (pte-app) — enforced conventions, not optional.

## Ground rules

- Don't re-architect what's already quality-approved. If you find a real bug, fix it narrowly and note it in the relevant phase file's "Runtime-verification TODO" / "Risks" section — don't redesign the service around it.
- Don't commit without your own review pass — every phase in this project went through a quality gate before being marked done; keep that bar.
- If you're blocked by a decision only the team lead can make (architecture choice, scope cut, vendor selection), stop and ask — don't guess and build on top of a guess.
