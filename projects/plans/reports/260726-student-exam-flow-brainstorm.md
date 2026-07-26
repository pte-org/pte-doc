# Brainstorm: Flutter Student Exam Flow (pte-app) — Member 2, Milestone 1

**Date:** 2026-07-26
**Created by:** Ninh (Member 2)

---

## Ideas Explored

- **Reuse `pte-app/lib/core/` (Dio client, offline outbox, timer, sync engine) and only rewrite `lib/features/*`.** The old scaffold ("Aptis", pre-pivot) has a generically-shaped `core/` layer that's architecturally close to what's needed (offline-resilient, server-authoritative). Rejected: the task doc itself flags this as an unresolved leader decision ("đừng tự đoán"), and on inspection the old contract (`token_refresh_interceptor.dart`, `answer_outbox_table.dart`) doesn't map to the new domain's `pinnedItemPublicId`/`payload` shape or the poll-only timer — reuse would mean rewriting most of the internals anyway while keeping a false sense of "already built."
- **Full rewrite from scratch, including the offline outbox.** Chosen direction — clean slate against the real `pte-api` contract, old code kept only as a *reference pattern* (composite-key outbox, canary-driven sync, single-flight token refresh) rather than reused code.
- **Defer offline-outbox to a post-Milestone-1 follow-up, ship a simple synchronous submit first.** Considered as a way to reduce initial scope. Rejected by user: the task doc names "never lose an answer if the app is killed/loses connectivity mid-exam" as the single most important reliability property of this screen — deferring it would ship the riskiest gap first.
- **Timer: poll vs. subscribe (WebSocket/SSE) for `TimerController`.** Explored via a targeted Explore agent against `exam-delivery`'s actual controller. Resolved as a **hard constraint, not a choice**: the backend only exposes `GET /attempts/{id}/timer` (pure REST poll) — no push/streaming endpoint exists anywhere in the service. Client design: local `Stopwatch`-seeded countdown from `serverNow`/deadlines, periodic resync via poll.

## User's Direction

- Rewrite `pte-app`'s exam-flow code fully; do not reuse old `core/`/`features/` code (old code stays only as a pattern reference).
- Offline-outbox (Drift/SQLite-backed local queue + background sync) ships as part of Milestone 1, not deferred — this is the phase that gates every other task-type screen's submit path.
- Timer is poll-only against the confirmed `TimerStateResponse` contract.
- Planning artifacts (this report, `spec.md`, and the `ck:plan` output) live in the `pte-doc` repo under `projects/plans/`, following the same convention already used by other members' plans (e.g. `quang-exam-session-ops`) — not the default `plans/` folder inside `pte-app`/`pte-api`. Slug folder: `ninh-student-exam-flow`.
- When execution (`ck:cook`) eventually happens, it should run in `--hard` mode and pause after each phase for the user to `git commit` manually before continuing — no unattended multi-phase runs.

## Open Questions

- **How does the student obtain `sessionPublicId` to start an attempt** — self-service session list, or a host-shared ID/link? Explicitly unresolved in the source task doc, pending a decision from Member 3 (host-side scheduling UI owner). Not blocking this plan: Milestone 1 assumes a manually-entered/deep-linked session ID as a placeholder, with the attempt-repository interface shaped so the entry mechanism is swappable later without touching the BLoC/repository contract.

## Risks

- **Outbox front-loaded into Phase 2, before any task-taking UI exists** — increases early-phase effort and risk of over-designing before real usage patterns (MC/essay/audio) are wired against it, but the alternative (retrofitting outbox after building 3 task-type screens against direct API calls) risks missing a submit call-site (e.g. force-submit) that stays unrouted through the queue.
- **Media (READ_ALOUD) upload adds outbox-adjacent complexity that's structurally different from text-payload retries**: the presigned `uploadUrl` expires in 900s, so a long offline period during the deferred-upload retry can invalidate the URL, requiring a fresh presign request rather than a naive "retry the same request" — this needs its own retry path, not the generic outbox retry logic.
- **Session-ID acquisition dependency on Member 3** is a real external blocker for the "real" UI (not the Milestone-1 placeholder) — if Member 3's decision lands very differently (e.g. requires a totally different auth/permission model for browsing sessions), Phase 3's repository contract may need revision.
