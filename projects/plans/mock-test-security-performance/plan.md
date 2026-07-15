# Plan: Aptis Mock Test — Security, Performance & Exception Handling Hardening

**Spec:** [spec.md](spec.md)
**Date:** 2026-07-15
**Status:** Ready
**Mode:** Hard
**Team:** 4 people, flexible skills, end-to-end feature tracks (not siloed by layer)

---

## Overview

Four parallel tracks, one owner each. Each owner works their own phases sequentially (Phase 1 → 2 → 3[→4]); the four tracks run in parallel across the team.

**Timeline: 1 week (user-confirmed, aggressive).** Phase sizing compressed to ~1-1.5 workdays each. To fit this, scope for week 1 is **P1 stories only**; P2 items are deferred to a Week 2+ backlog (see below). This is a tight compression for security-sensitive work — expect reduced test depth in week 1, with a follow-up hardening pass recommended for anything cut.

### Week 1 Scope (P1 only) vs. Week 2+ Backlog (P2, deferred)

| Included in Week 1 | Deferred to backlog |
|---|---|
| Track 1: all 4 phases (timer, multi-device lock+tamper guard, blur detection, proctor alerts) — all P1 | — |
| Track 2: Phase 1 (exception audit, exam-delivery scope only) + Phase 3 (offline integration tests) — P1 | Track 2 Phase 2 full `SyncEngine` hardening polish beyond what's needed for the Phase 3 tests to pass |
| Track 3: Phase 2 (load-test baseline at 500 concurrent) — P1. Phase 3 (optimization) only if baseline already fails target. | Track 3 Phase 1 (rate limiting) — explicitly P2 in spec, deferred |
| Track 4: Phase 1 (audit table, minimal) + Phase 2 (payload encryption, mobile + API) + Phase 3 mobile cert pinning only — P1 | Track 4 Phase 3 web cert pinning, full rotation runbook polish, audit-log viewer UI — P2/polish |

**Infra note:** Track 4 Phase 2 originally specified Redis for session-key storage. Since Redis is **not currently available** in this infra and adding it is out of scope for a 1-week timeline, **switched to storing the encryption key in Postgres** (a new column on `exam_attempt`, TTL enforced by attempt lifecycle rather than a cache TTL). Revisit Redis as a later optimization if scale requires a shared cache across API instances — see phase-02-t4-payload-encryption.md.

| Track | Owner focus | Phases | Codebases touched |
|---|---|---|---|
| [Track 1 — Exam Integrity & Anti-Cheat](#track-1) | Timer, session lock, tamper guard, blur detection, proctor alerts | 4 | aptis-api, aptis-app, aptis-web |
| [Track 2 — Resilience & Auto-Recovery](#track-2) | Offline sync hardening, exception-handling consistency | 3 | aptis-api, aptis-app, aptis-web |
| [Track 3 — Performance & Scalability](#track-3) | Rate limiting, load testing, optimization | 3 | aptis-api |
| [Track 4 — Payload Security & Audit](#track-4) | Audit log, AES payload encryption, cert pinning | 3 | aptis-api, aptis-app, aptis-web |

---

## Architectural Decisions (from research, applied — do not re-litigate mid-implementation)

1. **Timer authority (FR-01):** signed, short-lived time tokens issued at exam start (`{examId, startTime, expiryTime, signature}`), not pure per-request elapsed-time checks. 30-60s offline grace window so the existing offline-first mobile client isn't falsely timed out mid-disconnect. Token revalidated on reconnect/submit.
2. **Multi-device lock (FR-03):** immediate force-stop of the original session on second-device login — **not** a lease/heartbeat grace period. This is an explicit stakeholder requirement (teacher wants instant stop + proctor alert), accepted with the known risk of false positives on flaky networks (see Risks).
3. **Proctor alerts (FR-11):** short-poll (2s interval) from the Next.js proctor dashboard against `/api/admin/exam-sessions?since=<timestamp>`, not WebSocket. Simpler to operate for a 4-person team, no mobile background-lifecycle concerns since the proctor is web-only. Meets the 2s target. Can be upgraded to WebSocket later if polling latency proves insufficient in practice.
4. **Payload encryption + cert pinning (FR-05, FR-10):** AES-256-GCM at the application layer (Google Tink for Spring Boot — misuse-resistant), session-scoped key, layered on top of existing JWT+TLS. Certificate pinning on both Flutter and Next.js/web clients. Non-negotiable per stakeholder request (anti exam-leak). Certificate rotation procedure must be documented (see Track 4 Phase 3).
5. **Rate limiting (FR-08):** Resilience4j `@RateLimiter`, per-student (not just per-IP) on exam-delivery endpoints, stricter separate limits on auth endpoints.
6. **Load testing (FR-07):** Gatling, 500 concurrent virtual users, both a cold-cache and warm-cache pass (Caffeine cache can mask real query performance).

---

## Cross-Track Dependencies

```
Track 4 Phase 1 (audit_log table + AuditLogService)
   │
   ├──> Track 1 Phase 2 (multi-device lock + tamper guard writes audit events)
   ├──> Track 1 Phase 3 (blur detection writes audit events)
   └──> Track 1 Phase 4 (proctor alert endpoint reads audit_log)
```

- **Track 4 Phase 1 should land first** (or at minimum, its `audit_log` table migration + a minimal `AuditLogService.record(...)` stub) since Track 1 phases 2-4 write to it. If Track 4 Phase 1 is delayed, Track 1's owner can stub the audit write behind a no-op interface and wire it once Track 4 Phase 1 merges — don't block Track 1 entirely.
- **Track 2 and Track 3 have no hard dependency on any other track** and can start immediately.
- **Track 1 Phase 1 (timer)** has no dependency and can start immediately in parallel with Track 4 Phase 1.

---

<a id="track-1"></a>
## Track 1 — Exam Integrity & Anti-Cheat

Covers FR-01, FR-02, FR-03, FR-04, FR-11. User stories: all P1.

1. [phase-01-t1-timer-enforcement.md](phase-01-t1-timer-enforcement.md) — server-side signed time-token timer authority
2. [phase-02-t1-multi-device-lock.md](phase-02-t1-multi-device-lock.md) — session lock, force-stop, tamper-proof submission guard
3. [phase-03-t1-blur-detection.md](phase-03-t1-blur-detection.md) — tab/blur/app-background event reporting (mobile + web)
4. [phase-04-t1-proctor-alerts.md](phase-04-t1-proctor-alerts.md) — proctor dashboard short-poll alert delivery (depends on Track 4 Phase 1)

<a id="track-2"></a>
## Track 2 — Resilience & Auto-Recovery

Covers FR-06 and general exception-handling consistency. User stories: P1 (offline resume), supporting NFR (Availability).

1. [phase-01-t2-exception-audit.md](phase-01-t2-exception-audit.md) — audit + fix exception-handling gaps across all 3 codebases
2. [phase-02-t2-sync-engine-hardening.md](phase-02-t2-sync-engine-hardening.md) — harden `SyncEngine` offline queue (retry/backoff edge cases, conflict handling)
3. [phase-03-t2-offline-integration-tests.md](phase-03-t2-offline-integration-tests.md) — integration tests: network loss, force-kill, resume-after-restart

<a id="track-3"></a>
## Track 3 — Performance & Scalability

Covers FR-07, FR-08. User stories: P1 (500 concurrent), P2 (rate limiting).

1. [phase-01-t3-rate-limiting.md](phase-01-t3-rate-limiting.md) — Resilience4j rate limiting on exam-delivery + auth endpoints
2. [phase-02-t3-load-testing.md](phase-02-t3-load-testing.md) — Gatling scenarios, cold + warm baseline at 500 concurrent
3. [phase-03-t3-optimization.md](phase-03-t3-optimization.md) — fix bottlenecks found in Phase 2 until p95 < 1s / 0 lost submissions

<a id="track-4"></a>
## Track 4 — Payload Security & Audit

Covers FR-05, FR-09, FR-10. User stories: P1 (encryption), P2 (audit log).

1. [phase-01-t4-audit-table.md](phase-01-t4-audit-table.md) — append-only audit log schema + service (**blocking dependency for Track 1**)
2. [phase-02-t4-payload-encryption.md](phase-02-t4-payload-encryption.md) — AES-256-GCM application-layer encryption (API + Flutter + Next.js)
3. [phase-03-t4-cert-pinning.md](phase-03-t4-cert-pinning.md) — certificate pinning (Flutter + Next.js) + rotation procedure

---

## Risks

**Red-team review findings (NOTED — acceptable risk, tracked here rather than blocking):**

- **Timer-token transmission scope (T1P1):** the signed time token is issued at attempt start but only its `expiryTime` is used client-side for UI; signature verification happens server-side only at submission time, not on every intermediate request. Documented explicitly in phase-01-t1-timer-enforcement.md's design constraints so implementers don't diverge.
- **Encryption latency budget (T4P2):** no upfront latency budget was set for AES-256-GCM overhead per request. Track 4's owner should micro-benchmark Tink encrypt/decrypt on realistic payload sizes (~10-50KB questions, ~1-5KB answers) before Track 3's Phase 2 load-test baseline, so encryption overhead is accounted for rather than discovered late.
- **Web certificate pinning feasibility (T4P3):** HPKP is deprecated in modern browsers. The actual guarantee achievable on web (vs. mobile) is weaker and not yet proven — Track 4 Phase 3 must produce a proof-of-concept early in the phase and honestly document the achieved guarantee level; if browser-side pinning proves infeasible, that gap must be documented, not silently dropped.
- **Proctor alert clock-skew/dedup (T1P4):** timestamp-based `since=<timestamp>` polling can miss or duplicate events under clock skew between server and proctor browser. Track 1 Phase 4 should add client-side event-ID deduplication; if 2s polling proves insufficient in practice, consider cursor-based pagination instead of timestamp filtering.
- **Offline grace window is a spec extension, not in the original spec text (T1P1):** the 30-60s grace window for offline submission was added during planning to fit the existing offline-first mobile architecture. This is a deliberate deviation from a strict interpretation of FR-01 and should be confirmed acceptable to the stakeholder (some exam-integrity policies may not tolerate any late-arrival grace) before Track 1 Phase 1 ships to production.
- **Pre-cook security test design (all tracks):** all phases currently show "Quality: not evaluated / Testing: not started" per plan template — before track owners start Phase 1 work, do a short shared session (with security-reviewer) to agree on the test strategy for the highest-risk areas: timer-token forgery/replay, multi-device race conditions, encryption key confidentiality, and cert-pinning bypass — so these aren't designed ad hoc per track.

**Original risks:**

- **False positives on multi-device force-stop:** a student's own flaky network reconnecting from the same device could look like a "new session" and trigger a false force-stop. Track 1 Phase 2 must use a stable device/session identifier (not just IP) and a short client-side reconnect retry (using the *same* `sessionToken`) before treating it as a genuine second device. Flagged from research; accepted per explicit stakeholder direction to force-stop immediately rather than use a lease/grace window.
- **Certificate rotation breaks pinned clients:** if aptis-api's TLS cert rotates without a coordinated client update, pinned mobile/web clients will hard-fail all requests. Track 4 Phase 3 must produce a documented rotation runbook (pin the intermediate/root where feasible, or ship a pin-update mechanism) before this ships to production.
- **500 concurrent is an estimate, not a measured baseline** — Track 3 Phase 2 establishes the real baseline before Phase 3 optimizes; don't optimize blind.
- **Short-poll proctor alerts (2s) add per-proctor request load** — acceptable at current scale (100-500 concurrent test-takers, presumably far fewer concurrent proctors), but flag if proctor count ever scales up; WebSocket upgrade path noted in Track 1 Phase 4 design constraints.

---

## Cook Order Recommendation

Track 4 Phase 1 first (or in parallel with Track 1 Phase 1, stubbing the audit write). All other phases can proceed in parallel across the 4 owners from there. Suggested cook invocation per track/phase, e.g.:

```
/ck:cook plans/mock-test-security-performance/phase-01-t4-audit-table.md
/ck:cook plans/mock-test-security-performance/phase-01-t1-timer-enforcement.md
```

...one phase file at a time, per owner.
