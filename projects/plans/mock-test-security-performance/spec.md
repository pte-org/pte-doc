# Spec: Aptis Mock Test — Security, Performance & Exception Handling Hardening

**Date:** 2026-07-15
**Status:** Draft

---

## Problem Statement

The Aptis mock-test flow (aptis-api + aptis-app + aptis-web) has no anti-cheat enforcement, no server-side timer authority, no rate limiting, no payload-level encryption for exam content, and no audit trail — while offline auto-save/resume exists on mobile but is unverified end-to-end. This work hardens the mock-test flow across all three codebases so a 4-person team can split it into parallel, end-to-end feature tracks.

---

## User Stories

<!-- P1 = MVP (must ship), P2 = nice-to-have, P3 = future/out-of-scope -->

- **[P1]** As a test-taker, I want my exam timer to be enforced by the server, so that I can't extend my time by manipulating the client clock.
  Accepted when: server rejects/auto-submits any `ExamAttempt` where elapsed server-side time exceeds the allotted duration, regardless of client-reported time.

- **[P1]** As a proctor/admin, I want the system to detect and log tab-switch/app-minimize events during an active attempt, so that I can review potential cheating after the fact.
  Accepted when: mobile and web clients emit a blur/visibility-change event to the API, stored against the `ExamAttempt`, visible in an audit view.

- **[P1]** As a proctor/admin, I want only one active device session per exam attempt, and to be alerted in real time with the attempt immediately stopped if a second device tries to join, so that I can act on likely cheating (e.g. shared credentials) while the exam is still running.
  Accepted when: a second login attempt for the same active `ExamAttempt` is rejected server-side, the original attempt is force-stopped (status → `FLAGGED_STOPPED`), and a real-time alert reaches the proctor dashboard within 2s of detection.

- **[P1]** As a test-taker, I want my submitted answers and timing to be immutable after submission, so that no one (including a compromised client) can alter my exam record post-submit.
  Accepted when: `ExamAttemptService` rejects any write to a submitted `ExamAttempt`; attempted tampering is logged.

- **[P1]** As a system operator, I want exam content and answer payloads encrypted at the application layer AND protected by certificate pinning (in addition to TLS), so that intercepting network traffic via proxy/inspection tools (including user-installed CAs) does not leak exam questions or answers.
  Accepted when: exam-delivery request/response bodies for question content and answer submission are encrypted with a session-scoped AES key, not just plaintext-over-TLS; mobile and web clients reject connections that fail certificate pin validation.

- **[P1]** As a test-taker on an unstable connection, I want my answers auto-saved and my session resumable after a crash or disconnect, so that I never lose progress.
  Accepted when: existing offline outbox (Drift + `SyncEngine`) is verified/hardened to recover a full attempt state (answers + remaining time) after force-kill, network loss, or app crash, with automated test coverage.

- **[P1]** As a platform owner, I want the exam-delivery API to survive 100–500 concurrent test-takers without degraded latency or failed submissions, so that scheduled exam sessions don't fail under load.
  Accepted when: load test at 500 concurrent virtual users hitting exam-delivery endpoints (fetch question, submit answer, submit exam) shows p95 latency < 1s and zero failed/lost submissions.

- **[P2]** As a platform owner, I want rate limiting on exam-delivery and auth endpoints, so that abusive or buggy clients can't degrade service for others.
  Accepted when: Resilience4j (or equivalent) rate limiter configured per-endpoint with documented thresholds; excess requests return 429 with retry-after.

- **[P2]** As an admin, I want an audit log of exam access, submission, and anti-cheat events, so that I can investigate disputes.
  Accepted when: append-only audit table records actor, action, `ExamAttempt` id, timestamp for all security-relevant events (login, submit, blur event, multi-device block, tamper attempt).

- **[P3]** _(out of scope — noted for future)_ Live proctoring (webcam/screen-share monitoring), biometric verification, ML-based anomaly detection on answer patterns.

---

## Functional Requirements

1. FR-01: API enforces exam duration server-side using `ExamAttempt` start timestamp; client-reported `timeRemaining` is advisory only for UI, never authoritative for submission acceptance.
2. FR-02: Mobile and web clients detect visibility/blur/app-background events during an active attempt and POST them to a new anti-cheat event endpoint.
3. FR-03: API enforces single active session per `ExamAttempt` via a session token/lock; a second-device login during an active attempt is rejected server-side AND force-stops the original attempt (status → `FLAGGED_STOPPED`).
4. FR-04: `ExamAttemptService` rejects any mutation (answer edit, resubmit, time adjustment) once an attempt's status is `SUBMITTED` or `FLAGGED_STOPPED`.
5. FR-05: Exam question payloads (GET) and answer submission payloads (POST) are encrypted at the application layer using a per-session AES key, in addition to existing TLS.
6. FR-06: Existing mobile `SyncEngine` offline queue is covered by integration tests simulating: network loss mid-answer, app force-kill mid-attempt, and resume-after-restart, confirming zero answer loss.
7. FR-07: Exam-delivery endpoints (`fetch question`, `submit answer`, `submit exam`) are load-tested at 500 concurrent users with results documented.
8. FR-08: Rate limiting applied to exam-delivery and auth endpoints with per-endpoint thresholds documented in `SecurityConfig`.
9. FR-09: Append-only audit log table records login, submit, anti-cheat, and tamper-attempt events with actor/timestamp/attempt-id.
10. FR-10: Mobile and web clients pin the API's TLS certificate and reject connections failing pin validation.
11. FR-11: A real-time channel (WebSocket or push) delivers multi-device/anti-cheat alerts to a proctor-facing dashboard within 2s of server-side detection.

---

## Non-Functional Requirements

- Performance: p95 latency < 1s for exam-delivery endpoints at 500 concurrent virtual users; zero failed or lost submissions under that load.
- Security: exam content/answers encrypted at application layer AND certificate-pinned in addition to TLS; no plaintext exam payload observable via MITM proxy inspection (including user-installed CAs); tampering of submitted attempts is server-rejected and logged.
- Availability: offline mobile flow recovers 100% of locally-saved answers after crash/disconnect, verified by automated integration test.

---

## Success Criteria

- [ ] Server rejects submission attempts past allotted exam duration, independent of client clock, verified by test.
- [ ] Second-device login on an active attempt is rejected and the original attempt force-stopped in 100% of test cases.
- [ ] Proctor dashboard receives a multi-device/anti-cheat alert within 2s of server-side detection, verified by test.
- [ ] Post-submit mutation attempts return a rejection response and produce an audit log entry.
- [ ] Exam payload captured via network proxy (e.g. mitmproxy) during a manual test is not human-readable plaintext, even with a user-installed CA (cert pinning holds).
- [ ] Load test: 500 concurrent virtual users, p95 latency < 1s, 0 failed/lost submissions.
- [ ] Offline crash/resume integration test passes with 0 answer loss across 3 simulated failure scenarios (network loss, force-kill, backgrounding).
- [ ] Rate limiter returns 429 on excess requests per documented threshold.

---

## Out of Scope

- Live proctoring (webcam/screen recording, human review).
- ML/behavioral anomaly detection on answer patterns.
- Full proctor monitoring dashboard UI (only the real-time alert delivery channel, FR-11, is in scope — a rich dashboard is a future enhancement).

---

## Assumptions

- 100–500 concurrent test-takers is the target scale (user-provided estimate, not a measured production baseline) — performance track should start with a load-test baseline before optimizing.
- Multi-device detection force-stops the original attempt and alerts the proctor in real time; it does not merely block silently — proctors are expected to be actively monitoring a live exam session and can act on the alert.
- Application-layer payload encryption (AES) layers on top of existing JWT/TLS, not replacing it; certificate pinning is applied in addition, on both mobile and web clients.
- The 4-person team will work in parallel end-to-end tracks (each person may touch API + mobile + web as needed for their track), not siloed by tech layer.
- No fixed sprint length was given; plan proposes phases sized for solo completion in ~3-5 workdays per phase, run in parallel across the 4 tracks — confirm cadence with the team before cook.

---

## [NEEDS CLARIFICATION]

- [ ] Sprint/timeline cadence for the 4-person split was not specified — plan proposes ~3-5 day phases per track; confirm or adjust with the team.

---

## Proposed Task Tracks (for 4-person team, end-to-end split)

1. **Exam Integrity & Anti-Cheat owner** — FR-01, FR-02, FR-03, FR-04, FR-11 (server-side timer, blur detection, session lock + force-stop, tamper-proof submit, real-time proctor alert channel). Touches aptis-api (examdelivery module) + aptis-app (bloc/sync) + minor web hooks if web ever gets exam delivery.
2. **Resilience & Auto-Recovery owner** — FR-06 (offline sync hardening/tests), exception-handling consistency audit across all 3 codebases.
3. **Performance & Scalability owner** — FR-07, FR-08 (load testing, rate limiting, caching/query tuning on exam-delivery hot paths).
4. **Payload Security & Audit owner** — FR-05, FR-09, FR-10 (application-layer AES encryption, certificate pinning, audit log system, secrets hardening).
