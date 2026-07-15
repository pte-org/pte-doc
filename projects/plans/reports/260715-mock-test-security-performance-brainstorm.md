# Brainstorm: Aptis Mock Test — Security, Performance & Exception Handling

**Date:** 2026-07-15

## Ideas Explored

- **Anti-cheat / exam integrity** — server-side timer authority, tab/blur detection, multi-device session lock, post-submit tampering prevention.
- **Resilience & crash recovery** — auto-save/resume already exists in mobile (outbox pattern via Drift + `SyncEngine`), but no verified reconnect/resume guarantees end-to-end, no retry/backoff audit.
- **Performance under load** — no rate limiting, no load tests, no documented concurrency target before this session.
- **Payload encryption** — teacher requirement to encrypt exam content and submitted answers in transit/rest beyond standard HTTPS, to prevent interception of exam questions via proxy/inspection tools (exam-leak risk, not just transport security).
- **Audit logging** — no audit trail currently exists for who accessed/changed what.

## Codebase Findings (scout)

Three independent projects under one org, each with its own CLAUDE.md and standards:
- `aptis-api` — Java 21 / Spring Boot 4.1, JWT auth, PostgreSQL + Flyway, Cloudinary storage. Exam flow in `modules/examdelivery` (`ExamAttempt`, `ExamAttemptService`, outbox-style write pattern). Global exception handling via `GlobalExceptionHandler` + `ApiResponse<T>` + `ErrorCode` enum.
- `aptis-app` — Flutter + BLoC, GetIt DI, Drift (local SQLite), `ExamAttemptBloc` state machine, `SyncEngine` for offline answer queue with backoff.
- `aptis-web` — Next.js 16 monorepo (tenant-web + vendor-web), TanStack Query, no exam-delivery UI yet (admin/roster side only).

Confirmed gaps: no rate limiting (no Resilience4j), no anti-cheat validation, no audit logging, timer is client-side only (server doesn't independently enforce elapsed time), no load/performance tests, no WebSocket/real-time sync confirmation, no payload-level encryption beyond TLS.

## User's Direction

Team of 4, flexible skills (not fixed to one layer) — split by **end-to-end feature track** rather than by tech layer. Full roadmap requested (all identified gaps in scope for this planning round, not just MVP triage). Target load: 100–500 concurrent test-takers. Anti-cheat priority: tab/app-switch detection, multi-device lock, and server-side tamper validation — all three, plus payload encryption for exam content per teacher's requirement.

Four proposed tracks (to be finalized in spec/plan):
1. **Exam Integrity & Anti-Cheat** — server-side timer authority, tab/blur detection, multi-device session lock, tamper-proof submission.
2. **Resilience & Auto-Recovery** — verify/harden existing auto-save + resume + offline sync reliability, exception-handling consistency across API/mobile/web.
3. **Performance & Scalability** — rate limiting, concurrency handling for 100–500 simultaneous test-takers, load testing, caching/query optimization on exam-delivery hot paths.
4. **Payload Security & Audit** — encrypt exam content/answers in transit (beyond TLS) and at rest, audit logging for exam access/changes, secrets hardening.

## Open Questions

- Payload encryption approach not yet decided: app-layer encryption (e.g. encrypt exam JSON payload with a session key) vs. certificate pinning vs. both. `/ck:plan` must pick one based on Flutter + Next.js constraints.
- No fixed deadline/sprint length given for the 4-person split — plan should propose a cadence but confirm with user.
- Whether "multi-device lock" should hard-block second login or just alert/log (affects UX vs. security tradeoff) — leaning hard-block per teacher's anti-cheat intent, needs confirmation in plan.

## Risks

- Client-side timer is currently the sole source of truth — any anti-cheat work must not ship without server-side elapsed-time enforcement, or the rest of the anti-cheat effort is moot.
- Payload encryption adds complexity across 3 codebases simultaneously (API, Flutter, Next.js) — highest coordination risk of the four tracks if not scoped carefully per phase.
- 100–500 concurrent is an estimate, not a measured baseline — performance track should start with a load-test baseline before optimizing blindly.
