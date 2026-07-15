# Plan File 03-03 — Performance Requirements (SRS §3.3)
Project: APTIS LMS  
Date: 2026-06-16

All NFRs with ID, characteristic, target, status, owner, and rationale.

---

## NFR-01: API Response Time

| Field | Value |
|---|---|
| ID | NFR-01 |
| Characteristic | Response Time — REST API (non-media endpoints) |
| Target | [TBD — TechLead to estimate based on architecture] |
| Suggested range | p50 < 200ms, p95 < 500ms, p99 < 1s |
| Status | TBD |
| Owner | TechLead |
| Blocking OI | OI-05 |
| Rationale | Students answering questions send per-answer PATCH requests (FR-105); latency here directly impacts exam UX — high latency causes visible lag between typing and save confirmation |
| Measurement method | Server-side request logs, p95 measured at load balancer level under peak concurrent load |

---

## NFR-02: Overall System Availability

| Field | Value |
|---|---|
| ID | NFR-02 |
| Characteristic | Availability — overall system uptime |
| Target | [TBD — TechLead to define SLA tier] |
| Suggested | ≥ 99.5% monthly (allows ≤ 3.6h downtime/month) |
| Status | TBD |
| Owner | TechLead |
| Blocking OI | OI-05 |
| Rationale | Admin portals (Vendor, Tenant) can tolerate brief planned downtime; exam delivery cannot |
| Measurement method | Uptime monitoring (external health check), monthly availability report |

---

## NFR-03: Exam Hour Availability

| Field | Value |
|---|---|
| ID | NFR-03 |
| Characteristic | Availability — during active exam sessions |
| Target | **≥ 99.9% during any window where a live exam session is in progress** |
| Status | **Confirmed** |
| Owner | TechLead |
| Rationale | Stakeholder explicitly stated as #1 priority. A system outage during an exam is unacceptable — it directly impacts students taking time-limited assessments and is impossible to recover fully. |
| Implementation note | May require: separate exam-serving infrastructure, maintenance windows scheduled to avoid exam hours, circuit breaker patterns |
| Measurement method | Per-session availability: ratio of sessions with zero system-side interruptions vs. total sessions |

---

## NFR-04: Concurrent Exam Takers

| Field | Value |
|---|---|
| ID | NFR-04 |
| Characteristic | Scalability — concurrent active exam sessions |
| Target | [TBD — TechLead to estimate based on tenant scale projections] |
| Suggested initial | Support ≥ 500 concurrent exam takers per session (multiple tenants combined) |
| Status | TBD |
| Owner | TechLead |
| Blocking OI | OI-05 |
| Rationale | Peak load occurs when multiple tenants schedule exams simultaneously (e.g., end-of-semester exam periods); per-answer persistence (FR-105) means write load scales with active takers |
| Measurement method | Load test with simulated concurrent users executing exam-answer-submit loop |

---

## NFR-05: Auto-score Latency (Reading and Listening)

| Field | Value |
|---|---|
| ID | NFR-05 |
| Characteristic | Processing Time — auto-scoring pipeline |
| Target | **Reading and Listening results available within 2 minutes of exam submission** |
| Status | **Confirmed** |
| Owner | TechLead |
| Rationale | Students expect near-instant feedback for auto-scored skills; more than 2 minutes would make the system feel broken |
| Notes | This includes: all answers persisted → scoring job queued → answer matching → band calculation → result available in DB → student UI updated; the 2-minute window is end-to-end |
| Measurement method | Time between exam_attempt.submitted_at and attempt_results.reading_available_at (and listening_available_at) |

---

## NFR-06: Exam State Write Latency

| Field | Value |
|---|---|
| ID | NFR-06 |
| Characteristic | Response Time — per-answer PATCH write (FR-105) |
| Target | [TBD — TechLead estimate] |
| Suggested | p95 < 300ms end-to-end (client sends → server acks) |
| Status | TBD |
| Owner | TechLead |
| Blocking OI | OI-05 |
| Rationale | Every answer change triggers a write (FR-105); if writes are slow, the save-confirmation indicator lags, creating anxiety for students ("is my answer saved?"); also: multiple students answering simultaneously during a session creates write spike |
| Implementation note | Consider write-through cache or optimistic write acknowledgment with async DB flush if needed |

---

## NFR-07: Speaking Audio File Size and Upload Time

| Field | Value |
|---|---|
| ID | NFR-07 |
| Characteristic | Throughput — audio file upload |
| Target | [TBD — TechLead to calculate based on Speaking duration] |
| Input needed | Speaking Part durations from APTIS standard; recording quality (bitrate) |
| Estimated constraint | Each Speaking part: 1–3 minutes of audio at 128kbps MP3 = ~1–3 MB per part; 5 Speaking parts total = ~5–15 MB per student |
| Suggested | Upload of all Speaking audio for one student ≤ 5 minutes on a standard broadband connection |
| Status | TBD |
| Owner | TechLead |
| Blocking OI | OI-05, OI-07 (retention implications) |
| Rationale | Slow upload risks incomplete audio at session close; affects scoring pipeline trigger time |

---

## NFR-08: Listening Audio Delivery Latency (CDN)

| Field | Value |
|---|---|
| ID | NFR-08 |
| Characteristic | Latency — Listening audio start time (CDN delivery) |
| Target | [TBD — TechLead to specify CDN configuration] |
| Suggested | Time-to-first-byte for audio ≤ 500ms; full audio buffered before playback starts (no buffering interruption during playback) |
| Status | TBD |
| Owner | TechLead |
| Blocking OI | OI-05 |
| Rationale | Listening audio plays automatically on part entry (FR-22); if audio takes too long to load, the exam experience degrades and students may lose listening time; Listening has strict play-count limits so a failed first load is critical |
| Implementation note | CDN with edge nodes in Vietnam/Southeast Asia required; pre-cache exam audio assets when session starts |

---

## NFR-09: AI Scoring Pipeline Turnaround

| Field | Value |
|---|---|
| ID | NFR-09 |
| Characteristic | Processing Time — async AI scoring (STT + LLM) |
| Target | [TBD — depends on AI provider API latency and queue load] |
| Suggested | STT transcription complete within 5 minutes of exam submission; LLM draft score generated within 10 minutes of transcript; teacher notified within 15 minutes of submission |
| Status | TBD |
| Owner | TechLead |
| Blocking OI | OI-02 (provider selection), OI-03 (SLA agreement), OI-05 |
| Rationale | Teachers need to review AI drafts before confirming student results; long AI pipeline delays push back teacher review and student result visibility |

---

## NFR-10: Data Retention — Exam Records

| Field | Value |
|---|---|
| ID | NFR-10 |
| Characteristic | Storage — exam answer records, result records |
| Target | [TBD — PM / Legal decision] |
| Context | Exam records include: student answers per question, attempt metadata, scores, feedback |
| Suggested | Retain for duration of contract + 1 year; or minimum 2 years from attempt date |
| Status | TBD |
| Owner | PM / Legal |
| Blocking OI | OI-07 |
| Compliance note | NĐ 13/2023/NĐ-CP may impose obligations on personal data (student names, scores); Legal must confirm |

---

## NFR-11: Data Retention — Speaking Audio Recordings

| Field | Value |
|---|---|
| ID | NFR-11 |
| Characteristic | Storage — Speaking audio files |
| Target | [TBD — PM / Legal decision] |
| Context | Audio recordings are personal data (voice + identity); they are large files relative to text data; once teacher has reviewed and scored, the audio may no longer be needed for system operation |
| Suggested | Retain for: 90 days post-scoring (for appeals/audit), then purge; or per contract terms |
| Cost implication | Audio storage at scale is significant; retention period directly impacts storage cost |
| Status | TBD |
| Owner | PM / Legal |
| Blocking OI | OI-07 |

---

## NFR-12: Password Security

| Field | Value |
|---|---|
| ID | NFR-12 |
| Characteristic | Security — password hashing |
| Target | **bcrypt with cost factor ≥ 12** |
| Status | **Confirmed** |
| Owner | TechLead |
| Rationale | Industry standard for password storage; cost factor 12 provides sufficient brute-force resistance on current hardware (~300ms per hash) |
| Implementation note | Never store plaintext passwords in the database; one-time plaintext credential export (FR-48) must NOT write to DB — generate at creation time, transmit once |

---

## NFR-13: Token Security

| Field | Value |
|---|---|
| ID | NFR-13 |
| Characteristic | Security — JWT token lifetime |
| Target | **Access token ≤ 15 minutes; Refresh token ≤ 7 days, rotating** |
| Status | **Confirmed** |
| Owner | TechLead |
| Rationale | Short-lived access tokens limit exposure if intercepted; rotating refresh tokens invalidate old tokens on each use, preventing refresh token reuse after theft |
| Implementation note | Refresh tokens stored server-side (database or Redis) for invalidation support; pure stateless JWT is insufficient as it cannot be revoked |

---

## NFR-X: Exam Continuity (Priority #1)

| Field | Value |
|---|---|
| ID | NFR-X |
| Characteristic | Reliability — exam session data integrity |
| Target | **Exam session data loss rate = 0%** (for any in-progress attempt where the student had network at some point) |
| Status | **Confirmed — #1 stakeholder priority** |
| Owner | TechLead |
| Definition | "Data loss" = any answer that the student submitted but is not present in the final submitted attempt record; any Speaking audio that was recorded but neither uploaded nor recoverable from local buffer |
| Implementation note | Achieved via: per-answer server-side persistence (FR-105), server-authoritative timer (FR-104), local audio buffer (FR-108), resume on reconnect (FR-106), crash recovery (FR-111); all these FRs together deliver this NFR |
| Measurement method | Post-session audit: count of attempts where final answer count < answers the student reported submitting; Speaking audio delivery rate (uploaded / recorded attempts) |

---

## Performance Summary

| ID | Characteristic | Target | Status |
|---|---|---|---|
| NFR-01 | API Response Time (p95) | TBD | TBD |
| NFR-02 | Overall Availability | TBD | TBD |
| NFR-03 | Exam Hour Availability | ≥ 99.9% | **Confirmed** |
| NFR-04 | Concurrent Exam Takers | TBD | TBD |
| NFR-05 | Auto-score Latency | ≤ 2 min | **Confirmed** |
| NFR-06 | Exam State Write Latency (p95) | TBD | TBD |
| NFR-07 | Speaking Audio Upload Time | TBD | TBD |
| NFR-08 | Listening CDN Delivery Latency | TBD | TBD |
| NFR-09 | AI Scoring Pipeline Turnaround | TBD | TBD |
| NFR-10 | Data Retention — Exam Records | TBD | TBD |
| NFR-11 | Data Retention — Audio Recordings | TBD | TBD |
| NFR-12 | Password Hashing | bcrypt cost ≥ 12 | **Confirmed** |
| NFR-13 | JWT Token Lifetime | Access ≤ 15m, Refresh ≤ 7d rotating | **Confirmed** |
| NFR-X | Exam Continuity | 0% data loss | **Confirmed (#1 priority)** |
