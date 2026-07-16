# Brainstorm: Exam Session Support Operations (Upload đề, Fetch đề, Proctor, Exam Settings)

**Date:** 2026-07-15
**Created by:** Quang

## Context

This brainstorm runs before the `quang-mock-test-security-performance` plan. The user wants the supporting screens/flows in place first: uploading exam content, delivering it to the exam client, adding proctors, and configuring per-session exam settings (e.g. Speaking-only practice sessions).

Scope check surfaced a mismatch with existing docs: aptis-mvp (per memory) is flat-MCQ-only, no audio, no proctor. This work is scoped as the **first slice of the full aptis-lms design**, not an MVP extension — confirmed by user.

## Ideas Explored

**Upload đề thi**
- Vendor-only authoring (shared question bank) — rejected, too centralized for Host's need to make custom practice content.
- Host-only authoring (fully siloed per tenant) — rejected, wastes effort re-authoring standard Aptis-format content per school.
- **Chosen: dual-track.** Vendor authors a shared/canonical question bank; Host can also author tenant-scoped content independently — no Vendor approval gate on Host content (confirmed).
- Upload mechanism: pure Excel/CSV bulk import evaluated and rejected as primary mechanism — Aptis question structure (nested parts, per-question audio for L/S, long-form Writing prompts) doesn't flatten cleanly into spreadsheet rows.
- **Chosen: structured UI builder** (skill → part → question type, audio upload per question) as primary path for all skills; Excel/ZIP bulk import kept as a secondary fast-path for flat MCQ content only (Reading, some Listening).

**Lấy đề thi từ backend**
- Not treated as an independent design problem — it's a consequence of the delivery model already implied by the security/performance plan (server-authoritative timing, section-by-section fetch, no answer-key leakage). Scoped as an FR in the spec rather than a separate direction.

**Host thêm giám thị (proctor)**
- Proctor modeled as a session-scoped role: **1 proctor per exam session/room**, not a cross-session monitoring dashboard — confirmed by user, simplifies the realtime fan-out design (no need for a proctor to subscribe to N concurrent session channels).
- Realtime transport compared:
  - Short-polling — rejected as primary mechanism, too much latency/server load at scale for live per-machine status.
  - SSE — viable, simpler than WebSocket, but one-directional only.
  - **Chosen: WebSocket/STOMP** — user wants headroom for future server→client push actions (e.g. instantly force-submitting a specific machine), which SSE can't do without a secondary channel.
- Proctor action set confirmed: view per-machine/per-student status, force-submit a stuck attempt, extend time for an individual student, flag an integrity violation, broadcast an announcement to the room.
- Codebase reality check (Explore scout): `aptis-api` has zero realtime infrastructure today (no websocket/SSE deps), `ExamAttempt` only tracks `isSubmitted`+`submittedAt` (no in-progress/disconnected states), and there is no proctor/invigilator role anywhere in IAM yet. This is greenfield work, not an extension of an existing mechanism.

**Host setting kỳ thi**
- Confirmed as a multi-axis exam session config, not just a skill toggle:
  - Skill subset (R/L/W/S on/off) — original trigger example (Speaking-only practice).
  - Per-section time limits (override Aptis-standard timing per section).
  - Proctor required vs optional (practice sessions may skip proctoring; official sessions require it).
  - Availability window (exam only accessible within a start/end time range).
  - Retry count, gated by mandatory Host/teacher approval per retry request (not auto-granted) — matches the full-LMS doc's existing retake-approval rule.

## User's Direction

Build this as the first slice of full aptis-lms (not MVP), covering all 4 Aptis skills including audio/Writing content. Prioritize a UI-first authoring flow over bulk import, keep Host content ungated by Vendor review, scope proctor to one room per proctor, and invest in WebSocket now for the proctor dashboard since server→client control actions are already a stated future need.

## Open Questions

- Exact question-bank data model for how Vendor-shared and Host-authored content coexist (shared table with `owner_type` discriminator vs separate tables) — left for `/ck:plan` to resolve against existing `questionbank` module schema.
- Whether force-submit / extend-time are logged as audit events (full-LMS docs mandate immutable audit logs) — likely yes, needs explicit FR in plan phase.
- Retry approval workflow owner: is it the same "teacher confirmation" actor/queue used for AI Writing/Speaking scoring, or a separate approval queue — needs schema/UX decision at plan time.
- WebSocket auth model (JWT handshake, per-room subscription authorization) not yet designed — significant enough to warrant its own plan phase.

## Risks

- **Greenfield realtime infra**: adding WebSocket/STOMP to a stateless JWT REST backend is a real architectural addition (connection state, horizontal scaling/sticky sessions or broker fan-out), not a small feature — likely needs its own phase with explicit ops/scaling design, not just a controller change.
- **Dual-track content ownership**: Host content being ungated increases risk of low-quality/inconsistent practice material reaching students under the Aptis brand promise — worth flagging to product even though the user has decided against a gate for now.
- **Force-submit / extend-time as unaudited privileged actions**: these are exactly the kind of proctor action that needs immutable audit trail per the full-LMS integrity rules; skipping this in the first implementation would create a gap that's expensive to retrofit later.
