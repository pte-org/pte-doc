# Sprint Plan — APTIS LMS

## Sprint Overview

| Sprint | Goal | Stories | Story Points | Duration |
|---|---|---|---|---|
| Sprint 1 | Secure multi-tenant API with working auth for all roles | US-001–007 | 32 pts | 2 weeks |
| Sprint 2 | Content Managers build exam templates; Vendor creates tenants and licenses | US-009–014, US-071–076 | 36 pts | 2 weeks |
| Sprint 3 | Tenant Admins manage courses, enroll students, schedule sessions | US-044–051, US-037–038, US-008, US-077–079 | 32 pts | 2 weeks |
| Sprint 4 | Coordinators run live sessions; notifications fire; support staff active | US-039–043, US-080–082, US-083–087 | 46 pts | 2 weeks |
| Sprint 5 | Students complete Reading + Listening under server-authoritative timers | US-017–020, US-022, US-024–025, US-093 | 48 pts | 2 weeks |
| Sprint 6 | Students complete Writing, Speaking, submit; integrity violations recorded | US-021, US-023, US-026, US-094–098 | 48 pts | 2 weeks |
| Sprint 7 | Auto-scores in ≤2 min; AI drafts queued; teacher review queue open | US-027–032, US-099–100 | 48 pts | 2 weeks |
| Sprint 8 | Students see results; violation reports available; analytics data flowing | US-033–036, US-052–053, US-101–103 | 50 pts | 2 weeks |
| Sprint 9 | Full analytics suite live; guest/trial open; bulk imports working | US-015–016, US-054–060, US-088–092 | 46 pts | 2 weeks |
| Sprint 10 | Analytics export working; exam continuity I (resume + network recovery) live | US-061–066, US-104–107 | 48 pts | 2 weeks |
| Sprint 11 | Audio retry pipeline; analytics finalized; security hardened; QA complete | US-067–070, US-108–111 | 48 pts | 2 weeks |

**Total sprints:** 11
**Total story points:** 482 pts (456 story pts + 26 infra/QA pts)
**Estimated duration:** 22 weeks (~5.5 months)
**Sprint velocity:** 44 pts/sprint average (senior team at 110% nominal)
**SP multiplier:** ×0.75 (senior level) — M=2 pts, L=4 pts, XL=6 pts

---

## Sprint 1
**Goal:** Secure multi-tenant API with working auth for all 11 roles. Any actor can log in from the correct tenant subdomain, receive JWT tokens, and have RBAC enforced. Team can develop locally with Docker Compose.

**Stories included:**
- US-001: Email/credential login [Essential] — 2 pts
- US-002: JWT access + refresh token issuance [Essential] — 2 pts
- US-003: Host-based tenant resolution [Essential] — 2 pts
- US-004: Multi-role RBAC union enforcement [Essential] — 2 pts
- US-005: Credential reset via email link [Essential] — 2 pts
- US-006: Force credential change on first login [Essential] — 2 pts
- US-007: Logout + token invalidation [Essential] — 2 pts

**Infrastructure tasks (non-story, counted toward sprint load):**
- TASK-001: Monorepo scaffold (apps/api, apps/worker, libs/domain/*, libs/infra/*)
- TASK-002: PostgreSQL 17 + Prisma 7 baseline schema + RLS transaction middleware
- TASK-003: Redis 7 + BullMQ + Docker Compose + GitHub Actions CI skeleton
- TASK-073: OpenAPI spec skeleton + Flutter/Dart client codegen pipeline

**Sprint total:** 14 story pts + 18 infra pts = **32 pts**

**Definition of Done:**
- `POST /auth/login` returns access+refresh tokens scoped to the correct tenant
- `Host: {slug}.aptis-lms.vn` resolves tenant; wrong/missing host → 404
- RBAC guard rejects out-of-role requests with 403
- JWT refresh rotation works; reused refresh token revokes entire family (ADR-003)
- RLS: cross-tenant data access returns 0 rows in integration tests
- Docker Compose `up` starts full stack; GitHub Actions CI passes on push

---

## Sprint 2
**Goal:** Content Managers can create, version, and preview complete APTIS exam templates (all 16 parts). Vendor can create tenants and issue seat licenses via Vendor Portal scaffold.

**Stories included:**
- US-009: Question CRUD with all APTIS content fields [Essential] — 4 pts
- US-010: Audio upload for Listening questions [Essential] — 4 pts
- US-011: Image upload for Speaking questions [Essential] — 4 pts
- US-012: Exam template builder (skill + part composition) [Essential] — 4 pts
- US-013: Question bank preview mode [Conditional] — 4 pts
- US-014: Question versioning with immutability guard [Essential] — 4 pts
- US-071: Create and activate tenant [Essential] — 2 pts
- US-072: Edit tenant settings and subdomain [Essential] — 2 pts
- US-073: Issue seat license to tenant [Essential] — 2 pts
- US-074: License expiry monitoring and alerts [Conditional] — 2 pts
- US-075: View license seat utilization [Conditional] — 2 pts
- US-076: Deactivate and reactivate tenant [Conditional] — 2 pts

**Sprint total:** **36 pts**

**Definition of Done:**
- Content Manager can create a question with audio/image assets via presigned URL upload
- Published question version is immutable; edit creates a new version child (BR-011)
- Exam template requires all 16 parts before activation
- Preview API renders template in read-only mode with no attempt record created
- Asset upload uses provider-neutral StoragePort (ADR-005 compliant)

---

## Sprint 3
**Goal:** Tenant Admins manage courses and groups, enroll students (individually and bulk), schedule exam sessions. Seat quota enforced against license. Guest/Trial entry exists. Vendor support access available.

**Stories included:**
- US-044: Create course [Essential] — 2 pts
- US-045: Create group and assign teacher [Essential] — 2 pts
- US-046: Enroll individual student into group [Essential] — 2 pts
- US-047: Bulk student import via CSV/Excel [Conditional] — 2 pts
- US-048: Export student credentials after import [Conditional] — 2 pts
- US-049: View and edit student profile [Conditional] — 2 pts
- US-050: Search and filter student list [Conditional] — 2 pts
- US-051: Remove student from group [Conditional] — 2 pts
- US-037: Schedule an exam session [Essential] — 4 pts
- US-038: Edit session schedule and send reminders [Conditional] — 4 pts
- US-008: Guest/Trial exam entry point [Conditional] — 2 pts
- US-077: Support staff read-only tenant access [Conditional] — 2 pts
- US-078: Sales team view tenant pipeline [Optional] — 2 pts
- US-079: Impersonation log entry on support access [Conditional] — 2 pts

**Sprint total:** **32 pts**

**Definition of Done:**
- Seat quota blocks enrollment when license exhausted (HTTP 402)
- Bulk import CSV preview shows row errors before committing
- ExamSession created with `scheduled` status; participants linked
- Guest creates anonymous session without credentials (no tenant_id required)
- Impersonation log is insert-only; no update or delete permitted (BR-016)

---

## Sprint 4
**Goal:** Exam Coordinators run live sessions with real-time monitoring and intervention controls. Notification emails fire for session reminders. Vendor support staff access fully operational.

**Stories included:**
- US-039: Live exam monitor dashboard with real-time student status [Essential] — 4 pts
- US-040: Extend time for individual student [Essential] — 4 pts
- US-041: Force-submit student attempt [Essential] — 4 pts
- US-042: Close exam session early [Essential] — 4 pts
- US-043: Approve student retake [Conditional] — 4 pts
- US-080: Support staff impersonation flow [Conditional] — 2 pts
- US-081: Vendor admin audit log view [Conditional] — 2 pts
- US-082: Sales team exam usage report [Optional] — 2 pts
- US-083: Session invitation email to participants [Essential] — 4 pts
- US-084: Session reminder T-24h email [Conditional] — 4 pts
- US-085: Session reminder T-1h email [Conditional] — 4 pts
- US-086: Score-ready notification to student [Essential] — 4 pts
- US-087: Bulk notification to group [Optional] — 4 pts

**Sprint total:** **46 pts**

**Definition of Done:**
- WebSocket fan-out via Redis pub/sub delivers student status to monitor in ≤1 s
- Time extension updates PartTimer on server; student timer syncs within next poll cycle
- Notification BullMQ jobs delivered with idempotency keys; logged in notification_log
- DLQ alerts configured for failed notification jobs (ADR-004)

---

## Sprint 5
**Goal:** Students complete full Reading and Listening exam. Server-authoritative timers close parts at exactly zero. Each answer persisted per-answer to DB. Deterministic shuffle applied on attempt creation. HIGHEST-RISK SPRINT — critical path.

**Stories included:**
- US-017: Eligibility check before attempt creation [Essential] — 6 pts
- US-018: Pre-exam checks (mic test, fullscreen, instructions ack) [Essential] — 6 pts
- US-019: Server-authoritative part timers with sync endpoint [Essential] — 6 pts
- US-020: Reading parts A–D renderer with answer capture [Essential] — 6 pts
- US-022: Listening parts A–D with CDN audio auto-play [Essential] — 6 pts
- US-024: Part transition screen between skills [Essential] — 6 pts
- US-025: Ordered skill sequencing (Reading → Listening → Writing → Speaking) [Essential] — 6 pts
- US-093: Deterministic question/option shuffle seed stored on attempt [Essential] — 6 pts

**Sprint total:** **48 pts**

**Definition of Done:**
- Timer closes part at server-side zero; late `POST /answers` returns HTTP 409 (BR-004)
- Each answer write is idempotent; accepted only if `sequence_number` > current stored value (BR-005)
- Timer sync endpoint returns remaining seconds; client adjusts within ±2 s
- Reading/Listening renders all item types (MCQ, gap-fill, form-fill, matching)
- Shuffle seed reproducible: same attempt_id always produces same question order (BR-009)

---

## Sprint 6
**Goal:** Students complete Writing and Speaking, submit exam. Integrity violations (fullscreen exit, tab-switch) detected, logged, and can trigger auto-termination at threshold.

**Stories included:**
- US-021: Writing parts A–C with live word count [Essential] — 6 pts
- US-023: Speaking parts A–E 5-stage flow (instruction/image/prep/record/upload) [Essential] — 6 pts
- US-026: Exam final submission with attempt finalization [Essential] — 6 pts
- US-094: Answer option shuffle within questions per attempt [Essential] — 6 pts
- US-095: Fullscreen enforcement and exit detection [Essential] — 6 pts
- US-096: Tab-switch and focus-loss detection [Essential] — 6 pts
- US-097: Violation warning at configurable threshold [Essential] — 6 pts
- US-098: Auto-terminate attempt on violation threshold breach [Essential] — 6 pts

**Sprint total:** **48 pts**

**Definition of Done:**
- Speaking audio buffered in IndexedDB locally; uploaded to presigned URL; status tracked
- Submission triggers transactional outbox in same PostgreSQL transaction as attempt finalization (ADR-004)
- Violation events are append-only; threshold check reads count in real time (BR-016)
- Fullscreen and tab events recorded in violation_events with timestamp and type

---

## Sprint 7
**Goal:** Reading/Listening auto-scores and bands available within 2 minutes of submission. Writing/Speaking AI drafts generated and queued for review. Teacher scoring queue operational. Proctor violation notifications active.

**Stories included:**
- US-027: Auto-score Reading/Listening raw score computation [Essential] — 6 pts
- US-028: Band mapping from raw score to APTIS band [Essential] — 6 pts
- US-029: Results available within 2 minutes of submission [Essential] — 6 pts
- US-030: Speaking audio → STT transcript pipeline [Essential] — 6 pts
- US-031: Writing/Speaking LLM scoring with canonical draft schema [Essential] — 6 pts
- US-032: Teacher scoring queue with AI draft display [Essential] — 6 pts
- US-099: Proctor notification on violation threshold breach [Essential] — 6 pts
- US-100: Violation audit report per session [Essential] — 6 pts

**Sprint total:** **48 pts**

**Definition of Done:**
- Auto-score BullMQ job is idempotent; re-queue produces same result
- Band mapping covers all APTIS bands (A1, A2, B1, B2, C); MAPPING_ERROR stored on lookup failure
- AI draft status is `pending_review`; never surfaced to student-facing APIs (BR-013)
- LLM response validated against canonical schema; invalid → retry 3× then DLQ
- STT_FAILED recorded if transcript unavailable; teacher can override manually

---

## Sprint 8
**Goal:** Students see full 4-skill band results. Teachers confirm scores. Integrity violation reports finalized. Analytics data model populated for student and class views.

**Stories included:**
- US-033: Teacher score confirmation (AI draft → confirmed final) [Essential] — 6 pts
- US-034: Student results dashboard with attempt history [Essential] — 6 pts
- US-035: Four-skill band profile summary per attempt [Essential] — 6 pts
- US-036: Teacher written feedback visible on student result [Conditional] — 6 pts
- US-101: Session integrity summary for Exam Coordinator [Essential] — 6 pts
- US-102: Exam Coordinator intervention log per session [Essential] — 6 pts
- US-103: Tenant Admin overall integrity report [Conditional] — 6 pts
- US-052: Student individual band progression over time [Conditional] — 4 pts
- US-053: Per-skill score history charts [Conditional] — 4 pts

**Sprint total:** **50 pts**

**Definition of Done:**
- Confirmed score triggers results-ready notification to student
- Student result page shows disclaimer: "AI-assisted, confirmed by teacher" (BR-013)
- Band profile renders all 4 skills; pending skills show PENDING label (not hidden)
- Analytics projection job completes within 5 min of scoring completion event

---

## Sprint 9
**Goal:** Full analytics suite operational for class/tenant levels. Guest/Trial exam flow live. Bulk question import and item analysis engine available.

**Stories included:**
- US-054: Class average band per skill per group [Conditional] — 4 pts
- US-055: Attempt count and completion rate by group [Conditional] — 4 pts
- US-056: Score distribution histogram per skill [Conditional] — 4 pts
- US-057: Comparative class performance over time [Conditional] — 4 pts
- US-058: Teacher analytics dashboard (all groups) [Conditional] — 4 pts
- US-059: Tenant-level aggregate analytics for Admin [Conditional] — 4 pts
- US-060: License utilization analytics [Conditional] — 4 pts
- US-015: Bulk question import via CSV/Excel [Conditional] — 4 pts
- US-016: Item analysis — p-value and discrimination index [Optional] — 4 pts
- US-088: Guest creates anonymous trial session [Conditional] — 2 pts
- US-089: Trial exam execution with subset of question bank [Conditional] — 2 pts
- US-090: Trial results with upgrade prompt [Conditional] — 2 pts
- US-091: Lead capture form on trial completion [Optional] — 2 pts
- US-092: Trial session expiry and cleanup [Optional] — 2 pts

**Sprint total:** **46 pts**

**Definition of Done:**
- Analytics read model updated by BullMQ projection worker on each scored attempt
- Trial session uses vendor-privileged DB role (no tenant_id required)
- Bulk question import previews parse errors per row; imports only valid rows
- Item analysis nightly job writes p-value and discrimination_index to question record

---

## Sprint 10
**Goal:** Analytics exports downloadable. Exam continuity Part I: students can resume interrupted attempt from last saved answer state with correct server timer.

**Stories included:**
- US-061: Export student analytics to Excel/CSV [Conditional] — 4 pts
- US-062: Export class analytics report [Conditional] — 4 pts
- US-063: Export tenant analytics summary [Conditional] — 4 pts
- US-064: Item analysis per question visualized [Optional] — 4 pts
- US-065: Auto-flag low-discrimination questions [Optional] — 4 pts
- US-066: Item analysis trends over question versions [Optional] — 4 pts
- US-104: Resume interrupted attempt from last saved answer [Essential] — 6 pts
- US-105: Timer continuity on reconnect (server re-validates remaining time) [Essential] — 6 pts
- US-106: Network disconnect detection and reconnect handler [Essential] — 6 pts
- US-107: Answer state restored from server on reconnect [Essential] — 6 pts

**Sprint total:** **48 pts**

**Definition of Done:**
- Export jobs run as BullMQ tasks; client polls for presigned download URL
- Resume endpoint returns current ExamState rows + PartTimer remaining seconds; client rebuilds UI
- Reconnect handler re-subscribes to WebSocket; timer resyncs within ±2 s of server value
- No answer data lost across disconnect/reconnect cycle (BR-005)

---

## Sprint 11
**Goal:** Speaking audio retry pipeline operational. Advanced analytics export complete. Security hardened. Full E2E regression and load tests pass. System ready for staging deploy.

**Stories included:**
- US-067: Schedule and download analytics report on demand [Conditional] — 4 pts
- US-068: Analytics dashboard date range filter [Conditional] — 4 pts
- US-069: Tenant Admin custom analytics view config [Optional] — 4 pts
- US-070: Analytics notification when report ready [Optional] — 4 pts
- US-108: Speaking audio retry on upload failure [Essential] — 6 pts
- US-109: Partial audio upload recovery from IndexedDB buffer [Essential] — 6 pts
- US-110: STT retry queue for failed transcripts [Essential] — 6 pts
- US-111: Pending-upload status visible to teacher until resolved [Essential] — 6 pts

**Non-story QA/infra tasks:**
- TASK-068: Security hardening (rate limits, RLS hostile-tenant integration tests)
- TASK-069: Performance and load tests (200 concurrent sessions, answer persist p95, WS fan-out)
- TASK-070: E2E regression suite (auth → exam flow → scoring → analytics)
- TASK-071: Observability (Pino structured logging, OpenTelemetry, DLQ/outbox age alerts)
- TASK-072: Deployment runbook (Docker image, env.example, migration plan, staging deploy)

**Sprint total:** 40 story pts + 8 QA/infra pts = **48 pts**

**Definition of Done:**
- Speaking audio buffered in IndexedDB; retry every 30 s until success or session close
- STT_FAILED surfaced in teacher scoring queue as manual-override-required
- Rate limits: 5 auth/min, 20 answer-writes/s per attempt, 100 WS connections/session
- RLS integration: 10 hostile cross-tenant query patterns all return 0 rows
- Load test: 200 concurrent attempts, ≤500 ms p95 answer persist, ≤2 s p95 timer sync
- All E2E tests pass on staging against real PostgreSQL (no mocks in integration layer)
