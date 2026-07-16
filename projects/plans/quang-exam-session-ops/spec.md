# Spec: Exam Session Support Operations (Upload, Delivery, Proctoring, Session Settings)

**Date:** 2026-07-15
**Created by:** Quang
**Status:** Draft

---

## Problem Statement

Before the mock-test security/performance work can be built end-to-end, the system needs the supporting operations around an exam session: getting content into the system (Vendor and Host authoring), delivering it to the exam client, giving a proctor visibility and control over a live session, and letting a Host configure what a session actually consists of (skills, timing, retry, proctoring requirement). None of this exists yet — this is the first slice of the full aptis-lms design, going beyond the current MCQ-only MVP.

---

## User Stories

- **[P1]** As a Vendor content admin, I want to author exam questions (MCQ, Listening/Speaking audio, Writing prompts) in a structured UI, so that a canonical shared question bank exists for all tenants.
  Accepted when: Vendor can create a question of each of the 4 skill types, attach audio to Listening/Speaking items, and publish it to the shared bank.

- **[P1]** As a Host, I want to author my own exam questions independently of Vendor review, so that I can create tenant-specific practice content without waiting on approval.
  Accepted when: Host-created questions are immediately usable in that Host's exam sessions, scoped only to their tenant, with no Vendor approval step.

- **[P1]** As a Host, I want to bulk-import flat MCQ questions via Excel/ZIP, so that I can load a large Reading/Listening-MCQ question set quickly instead of authoring one-by-one.
  Accepted when: an Excel file with a defined column schema + a ZIP of referenced audio filenames produces valid questions in one import, with row-level validation errors reported (not a silent partial import).

- **[P1]** As an exam client (student app), I want to fetch only the sections/questions relevant to my session's configured skill subset, so that a Speaking-only practice session never receives Reading/Writing/Listening content.
  Accepted when: the fetch API returns exactly the skills enabled in that session's settings, section by section, without leaking answer keys.

- **[P1]** As a Host, I want to add a proctor account and assign them to an exam session (one proctor per room), so that a real invigilator has a working login before the session starts.
  Accepted when: Host can create/assign a PROCTOR-role user to a specific exam session; that user can log in and see only that session's room.

- **[P1]** As a proctor, I want to see live per-student/per-machine status (in-progress, current section, submitted, disconnected) for my assigned room, so that I know who needs attention without walking the room.
  Accepted when: status updates reach the proctor dashboard within a few seconds of a state change on the student's machine, via WebSocket push.

- **[P1]** As a proctor, I want to force-submit a stuck attempt, extend an individual student's time, flag an integrity violation, and broadcast an announcement to the room, so that I can handle the real situations that come up during a live exam.
  Accepted when: each of these 4 actions is available from the proctor dashboard, takes effect on the student's session within seconds, and is written to an immutable audit log entry (actor, target attempt, action, timestamp).

- **[P1]** As a Host, I want to configure an exam session's skill subset, per-section time limits, proctor-required flag, availability window, and retry count, so that I can run anything from a full official exam to a narrow unproctored practice session.
  Accepted when: all 5 axes are settable per session at creation time, and the exam client / delivery API enforces them (wrong-skill content is never served, session is inaccessible outside its window, proctor-required sessions can't start without an assigned proctor).

- **[P1]** As a Host/teacher, I want to approve or reject each student retry request individually, so that retries aren't unlimited-by-default even when a session allows more than one attempt.
  Accepted when: a retry request creates a pending approval item visible to the Host/teacher; the student cannot start a new attempt until approved.

- **[P3]** _(out of scope — noted for future)_ Cross-session proctor dashboards (one proctor monitoring multiple rooms concurrently).

- **[P3]** _(out of scope — noted for future)_ Vendor review/approval gate on Host-authored content.

---

## Functional Requirements

1. FR-01: Vendor and Host each have an authoring UI to create questions for all 4 Aptis skills (Reading, Listening, Writing, Speaking), with audio upload for Listening/Speaking items, scoped to shared bank (Vendor) or tenant-only bank (Host).
2. FR-02: Host has a secondary bulk-import path (Excel + ZIP of audio) limited to flat MCQ question types only; import validates and reports row-level errors rather than partial-failing silently.
3. FR-03: Exam delivery API serves only the question sections enabled by the session's skill-subset setting, fetched section-by-section, with correct answers never included in the payload.
4. FR-04: IAM gains a PROCTOR role; Host can create a proctor account and assign it to exactly one exam session/room.
5. FR-05: `ExamAttempt` gains an intermediate status model (e.g. NOT_STARTED, IN_PROGRESS, SECTION_SWITCH, SUBMITTED, DISCONNECTED) with a heartbeat mechanism updating it.
6. FR-06: A WebSocket/STOMP channel pushes per-attempt status changes to the assigned proctor's dashboard for their room only (authorization scoped to session assignment).
7. FR-07: Proctor dashboard supports 4 privileged actions — force-submit, extend individual time, flag violation, broadcast room announcement — each producing an immutable audit log entry.
8. FR-08: Exam session settings support 5 configurable axes: skill subset (R/L/W/S toggle), per-section time limit override, proctor-required boolean, availability window (start/end datetime), and max retry count.
9. FR-09: Retry requests require explicit Host/teacher approval per request; no auto-granted retries even when the session's retry count > 0.
10. FR-10: Proctor-required sessions cannot transition to "startable" state without an assigned proctor.

---

## Non-Functional Requirements

- Performance: proctor dashboard status updates delivered within 5s p95 of the underlying state change; exam content fetch p95 < 500ms per section.
- Security: tenant isolation enforced on all authoring/delivery/proctor endpoints (Host A cannot see Host B's content, sessions, or proctors); WebSocket connections authenticated via JWT handshake and authorized per session-room subscription.
- Availability: WebSocket disconnection on the student side must not lose already-submitted answers (falls back to REST submit-per-answer, consistent with server-authoritative persistence rule in the full-LMS docs); proctor dashboard reconnect resumes correct current-state, not just a delta stream.

---

## Success Criteria

- [ ] Vendor and Host can each author one full exam covering all 4 skills end-to-end (create → publish → visible in Host's session builder) without engineering intervention.
- [ ] A Speaking-only practice session, configured by a Host, never delivers Reading/Writing/Listening content to the exam client — verified by API-level test asserting section filter.
- [ ] Proctor sees a student's status flip to IN_PROGRESS/DISCONNECTED/SUBMITTED within 5 seconds of the real event during a live test run.
- [ ] Force-submit, extend-time, flag, and broadcast each produce exactly one audit log row with correct actor/target/timestamp.
- [ ] A retry request blocks the student from starting a new attempt until a Host/teacher explicitly approves it.

---

## Out of Scope

- Vendor approval/moderation queue for Host-authored content (explicitly rejected by user for this slice).
- Cross-session/multi-room proctor dashboards (1 proctor : 1 room confirmed as current scope).
- AI-assisted content generation for question authoring.
- Anti-cheat/integrity signal automation beyond manual proctor flagging (e.g. no webcam/browser-lockdown detection in this slice).

---

## Assumptions

- This work proceeds as the first slice of full aptis-lms design (per user confirmation), and is allowed to diverge from the current aptis-mvp flat-MCQ-only scope — if this assumption is wrong, FR-01/02/03 shrink back to MCQ-only and audio/Writing content drops out.
- The existing `iam`, `questionbank`, `examoperations`, `examdelivery` Spring Boot modules in `aptis-api` are the intended home for this work (no separate service split for realtime/proctor) — if wrong, FR-06 (WebSocket) may need to live in a dedicated service instead.
- WebSocket/STOMP is added directly to the existing stateless `aptis-api` Spring Boot app; horizontal scaling/sticky-session or broker-based fan-out strategy is a plan-time decision, not resolved here.

---

## Resolved Decisions

- **Question-bank data model**: single `Question` table, extended with `tenantId: UUID` (nullable — null means Vendor-owned/shared, non-null means Host-scoped) and `source: enum {VENDOR, HOST}`, following the existing `Asset` entity's `tenantId` pattern (`Asset.java:48-49`) for consistency. No separate tables for Vendor vs Host content. Resolved via codebase scout during `/ck:plan` Step 0 (2026-07-15).
- **Retry-approval ownership**: retry requests use a dedicated, independent approval queue — not the same actor/inbox used for AI Writing/Speaking teacher confirmation. FR-09 implies a standalone `RetryRequest` entity/status flow, separate from any scoring-confirmation queue.
