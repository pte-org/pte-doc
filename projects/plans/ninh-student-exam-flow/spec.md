# Spec: Student Exam Flow (pte-app) — Milestone 1

**Date:** 2026-07-26
**Created by:** Ninh (Member 2)
**Status:** Draft

---

## Problem Statement

`pte-app` currently exists only as a pre-pivot scaffold ("Aptis") pointed at a different backend and domain. Member 2 owns building the student-facing exam-taking flow — login, starting an attempt, answering all 3 Milestone-1 task types, a server-authoritative timer, submitting, and viewing the published report — against the real `pte-api` contract, from scratch, so that Milestone 1's critical path (already smoke-tested manually per Member 1's work) has a real client. Without this, no student-facing verification of the backend is possible.

---

## User Stories

- **[P1]** As a student, I want to log in and stay authenticated across a 15-minute access-token lifetime without being kicked out mid-exam, so that a long exam session isn't interrupted by auth failures.
  Accepted when: access token silently refreshes before/at 401 using the refresh token (7-day TTL); student is never shown a login screen mid-attempt due to token expiry alone.

- **[P1]** As a student, I want to start (or resume) an attempt for a given exam session, so that I can begin taking the exam.
  Accepted when: `POST /attempts` with a `sessionPublicId` returns the current/first task; calling it again for an in-progress attempt resumes rather than restarting.

- **[P1]** As a student, I want to answer an `MC_READING_SINGLE` question by selecting one option, so that my choice is recorded correctly.
  Accepted when: submitting sends the selected option's `orderIndex` as a decimal string payload tied to the exact `pinnedItemPublicId` of the current task.

- **[P1]** As a student, I want to write and submit a `WRITE_ESSAY` response with word-count guidance, so that I can complete the writing task within the item's word-count bounds.
  Accepted when: the editor shows live word count against `minWordCount`/`maxWordCount`; submit sends raw text as payload.

- **[P1]** As a student, I want to record and submit a `READ_ALOUD` audio response, so that I can complete the speaking task.
  Accepted when: recording via the `record` package → `POST /objects` → `PUT` presigned URL → `POST /objects/{id}/complete` → the resulting `mediaPublicId` is submitted as the answer payload — never raw audio bytes through the transactional API.

- **[P1]** As a student, I want the exam timer to reflect the server's authoritative deadline, not just my device's clock, so that I can't gain or lose time by manipulating my device.
  Accepted when: countdown is seeded from `TaskView.serverNow`/deadlines and periodically resynced via `GET /attempts/{id}/timer`; a submit attempted past `responseDeadline` is rejected by the server and the UI reflects the terminal state rather than retrying.

- **[P1]** As a student, I want my answer to survive the app being killed or losing network mid-response, so that I never lose work I've already done.
  Accepted when: every answer submission goes through a local Drift-backed outbox first; killing the app after typing/recording an answer but before connectivity resumes still results in the answer being flushed and accepted once the app relaunches and connectivity returns.

- **[P1]** As a student, I want to see my report after the host publishes it, and a clear "not yet published" state before that, so that I'm not confused by a missing or broken-looking score screen.
  Accepted when: `GET /attempts/{id}` (reporting) returning 404 renders a "waiting for host to publish" state, not an error; once published, `overall`/`communicativeSkills`/`enablingSkills` render with `sufficientData:false` skills shown as "insufficient data," not blank or zero.

- **[P2]** As a student, I want a session-ID entry screen (manual or deep-linked) to start my attempt, so that Milestone 1 is usable even before Member 3's session-discovery UI decision lands.
  Accepted when: a placeholder entry screen exists behind a swappable repository interface; replacing it later with a session-list UI requires no change to the attempt BLoC/repository contract.

- **[P3]** _(out of scope — noted for future)_ Student-facing session browsing/discovery UI (depends on Member 3's decision).

---

## Functional Requirements

1. FR-01: `AuthBloc` implements login (`POST /api/iam/auth/login`), proactive token refresh before the 900s access-token TTL expires (not only reactive on 401), and logout (`POST /api/iam/auth/logout`); refresh token persisted via `flutter_secure_storage`, never in-memory-only.
2. FR-02: JWT `roles`/`tenant_id` claims are decoded client-side for UI branching only (student vs host) and never trusted for security-sensitive logic — server re-validates every request.
3. FR-03: `ExamAttemptRepository` wraps `POST /attempts` (start/resume) and `GET /attempts/{id}/next-task` (advance/auto-complete); `AttemptTaskResponse.completed=true` with `task:null` is handled as a first-class terminal state.
4. FR-04: A session-ID entry screen (manual/deep-link input) supplies `sessionPublicId` to FR-03, behind a swappable interface (Member-3 dependency placeholder).
5. FR-05: Every answer submission (`POST /attempts/{id}/answers`) is written to a local Drift-backed outbox first, keyed by `(attemptPublicId, pinnedItemPublicId)`, and flushed by a background sync engine on connectivity restore — no code path submits directly to the API from a widget/BLoC.
6. FR-06: Outbox rows distinguish **retry-pending** from **terminal-rejected** status: `NotCurrentTaskException` (stale/replayed submission) and past-`responseDeadline` rejections mark a row terminal-rejected and stop retrying; transient/network failures remain retry-pending.
7. FR-07: `MC_READING_SINGLE` submit payload = selected option's `orderIndex` as a decimal string (e.g. `"2"`); `WRITE_ESSAY` payload = raw text; `READ_ALOUD` payload = the media service's `mediaPublicId` after a completed presigned upload.
8. FR-08: READ_ALOUD recording uses the `record` package; upload flow is `POST /api/media/objects` → `PUT {uploadUrl}` (direct to MinIO, no Authorization header attached) → `POST /api/media/objects/{id}/complete`; recorded audio persists to a local temp file so a deferred/retried upload survives process death, and an expired (900s) `uploadUrl` triggers a fresh presign request rather than retrying the dead URL.
9. FR-09: `TimerService` seeds a local countdown from `TaskView.serverNow` and `prepDeadline`/`responseDeadline` using `Stopwatch` (not wall-clock `DateTime.now()`), and periodically resyncs via `GET /attempts/{id}/timer`; `phase` (prep vs response) drives which UI is shown.
10. FR-10: `POST /attempts/{id}/submit` (force-submit) is available as an explicit BLoC action.
11. FR-11: 429 (rate-limit) responses are surfaced as a distinct retryable error type with backoff, not conflated with auth or validation failures.
12. FR-12: `ReportBloc` renders `GET /api/reporting/reports/attempts/{id}`: a 404 (published=false-equivalent, since the API can't distinguish "not published" from "not found") renders a "waiting for host to publish" state; per-skill `sufficientData:false` renders "insufficient data," never a blank/zero score.
13. FR-13: All new code follows `pte-app/CLAUDE.md`/`docs/CODING_STANDARDS_APP.md`: feature-first Clean Architecture, sealed-class BLoC events, immutable BLoC states (no boolean flags), `GetIt` DI per feature module, no hardcoded strings/colors, `mounted` checks after every `await`, controller disposal, 300-line file cap.

---

## Non-Functional Requirements

- Performance: timer resync poll interval should not exceed a few seconds of drift from server deadlines (exact interval is a plan-time decision, not fixed here); outbox flush attempts on every connectivity-restore event plus a periodic fallback tick.
- Security: refresh tokens never stored in plain `SharedPreferences`; MinIO presigned `PUT` must not carry the app's bearer auth header; JWT claims never used for authorization decisions client-side.
- Reliability: an answer already accepted by the local outbox must survive app kill / OS termination and be re-flushed on next launch (Drift/SQLite persistence, not in-memory queue) — this is the single most important non-functional requirement of this spec.

---

## Success Criteria

- [ ] Student can complete one full attempt (login → start → all 3 task types → submit) against a real running `pte-api` stack, end-to-end.
- [ ] Killing the app mid-`WRITE_ESSAY` (typed but not yet submitted... and separately, submitted-but-offline) and relaunching results in zero answer loss, verified by a scripted/manual test.
- [ ] A `READ_ALOUD` recording made while offline uploads and submits successfully once connectivity returns, including the case where the presigned URL has expired and must be re-requested.
- [ ] Report screen shows "waiting for host to publish" before publish and correct scaled scores / "insufficient data" per skill after publish, with no case rendering a blank or generic-error state for either.
- [ ] `flutter analyze` and `flutter test` pass with zero issues at Milestone-1 handoff.

---

## Out of Scope

- Student-facing session discovery/browsing UI (depends on Member 3's unresolved decision) — Milestone 1 ships a placeholder manual/deep-link entry only.
- Any AI-vendor-dependent skill scoring beyond what `sufficientData` already communicates (handled entirely server-side by Member 4's work).
- WebSocket/push-based timer updates — confirmed not to exist on the backend; not a future hook to build toward either, per YAGNI.
- Proctor-initiated actions (`FORCE_SUBMIT`, `EXTEND_TIME`) arriving mid-attempt — client must not break if they occur, but building/testing that interaction is Member 1's smoke-test scope, not this spec's build scope (though the attempt BLoC should tolerate a server-driven state change gracefully as a general design property).

---

## Assumptions

- The `record`, `just_audio`, `flutter_bloc`, `dio`, `drift`, `sqlite3`, `get_it` dependencies already in `pte-app/pubspec.yaml` are kept; `flutter_secure_storage`, `sqlite3_flutter_libs`, `bloc_test`, `mocktail` are added as new dependencies — if this assumption is wrong (e.g. a dependency is actually incompatible with the target Flutter/Dart SDK version), Phase 0/1 scope shifts to include a dependency-compatibility spike.
- Backend contracts confirmed via direct controller/DTO inspection (not a generated OpenAPI spec, since none exists yet) are accurate as of 2026-07-26; if `pte-api` contracts change before Milestone-1 handoff, the affected phase(s) need a contract-diff pass.
- Gateway base URL for local dev is `http://localhost:8080/api/...`; production/staging base URL is out of scope for this spec (assumed to be an `AppConfig`-level swap, consistent with the old scaffold's `apiBaseUrl` pattern).

---

## [NEEDS CLARIFICATION]

- [ ] Exact mechanism for student session-ID acquisition (self-service list vs. host-shared link) — blocked on Member 3's decision; Milestone 1 proceeds with a placeholder per FR-04/P2 story, to be revisited once resolved.
