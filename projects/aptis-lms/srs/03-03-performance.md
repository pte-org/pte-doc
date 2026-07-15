# SRS §3.3 — Performance Requirements
## APTIS LMS
**Version:** 1.0 | **Date:** 2026-06-16 | **Status:** DRAFT

---

NFRs are specified in ISO/IEC 25023 Quality Attribute Scenario format. All Response Measures must be numeric or explicitly marked `[TBD]` with owner and resolve-by milestone.

**Total NFRs: 14 (5 Confirmed / 9 TBD)**

---

#### NFR-01 — Performance Efficiency: Response Time Behavior

| Field | Value |
|-------|-------|
| Source of Stimulus | Student submitting a per-answer write (FR-105) or any user making a REST API call |
| Stimulus | An HTTP REST request is received by the Backend API on any non-media endpoint |
| Environment | System under peak concurrent load (all tenants, peak exam hour) |
| Artifact | Backend REST API (all endpoints except audio streaming) |
| Response | Server processes the request and returns an HTTP response |
| Response Measure | `[TBD: p50 < 200ms, p95 < 500ms, p99 < 1s — TechLead to confirm based on infrastructure sizing \| owner: TechLead \| resolve-by: Architecture session (OI-05)]` |

**Rationale:** Per-answer PATCH requests (FR-105) are sent on every MCQ selection and text input; latency here creates visible lag in the "Saved" indicator and degrades student exam experience. High p95 also impacts the live monitor dashboard (FR-39) responsiveness.

**Measurement method:** Server-side request latency logs at the load balancer level, sampled during load tests that simulate peak concurrent exam traffic.

---

#### NFR-02 — Reliability: Availability (Overall)

| Field | Value |
|-------|-------|
| Source of Stimulus | Any user or scheduled job making a request to the platform |
| Stimulus | A request arrives at the platform during normal operating hours (non-exam, non-maintenance) |
| Environment | Normal operating state; outside active exam sessions |
| Artifact | Entire platform (Vendor Portal, Tenant Portal, Backend API) |
| Response | The system processes and returns a valid response |
| Response Measure | `[TBD: ≥ 99.5% monthly uptime (≤ 3.6 hours downtime/month) — TechLead to confirm SLA tier \| owner: TechLead \| resolve-by: OI-05]` |

**Rationale:** Admin portals and content management can tolerate brief planned downtime windows; the primary concern is exam delivery availability (see NFR-03).

**Measurement method:** External uptime monitoring probe (HTTP health check) hitting the platform every 60 seconds; monthly availability report computed from probe data.

---

#### NFR-03 — Reliability: Availability (Exam Sessions) — **Confirmed**

| Field | Value |
|-------|-------|
| Source of Stimulus | Any student or Exam Coordinator making a request during an active exam session |
| Stimulus | A request arrives during a window where at least one exam session is `in_progress` |
| Environment | Active exam session window; system under peak concurrent exam taker load |
| Artifact | Exam delivery path: Backend API, exam_state DB writes, WebSocket/SSE connection (FR-39), audio CDN (FR-22) |
| Response | The system processes the request within normal response time bounds |
| Response Measure | **≥ 99.9% availability during any active exam session window** (measured per session: ratio of sessions with zero system-side interruptions to total sessions) |

**Rationale:** Explicitly stated as the #1 stakeholder priority. A system outage during a time-limited exam is impossible to fully recover: students lose time, recordings may be lost, and proctor intervention creates exam integrity issues. The 99.9% target translates to ≤ 43 seconds of downtime per exam session.

**Implementation note:** Requires maintenance windows scheduled outside exam hours, circuit breakers on non-critical services, and dedicated exam-serving infrastructure (separate from analytics/admin paths).

---

#### NFR-04 — Performance Efficiency: Capacity (Concurrent Exam Takers)

| Field | Value |
|-------|-------|
| Source of Stimulus | Multiple tenants scheduling exam sessions that overlap in time |
| Stimulus | N students simultaneously active in exam sessions across all tenants |
| Environment | Peak exam hour (end-of-semester, multiple tenants simultaneously); system at full load |
| Artifact | Backend API (exam_state writes), WebSocket server (FR-39), Database write tier |
| Response | All per-answer writes, timer syncs, and live monitor events are processed within NFR-01 latency targets |
| Response Measure | `[TBD: ≥ 500 simultaneous exam takers across all tenants without degradation — TechLead to confirm based on infrastructure and DB write capacity \| owner: TechLead \| resolve-by: OI-05]` |

**Rationale:** Per-answer persistence (FR-105) means write load scales linearly with active exam takers. Overestimating capacity is preferable; the cost of degraded performance during an exam far exceeds infrastructure over-provisioning cost.

**Measurement method:** Load test with concurrent simulated users executing exam-answer-submit loop at the per-answer write frequency (approximately 1 write per 30 seconds per student across all skills).

---

#### NFR-05 — Performance Efficiency: Time Behavior (Auto-scoring) — **Confirmed**

| Field | Value |
|-------|-------|
| Source of Stimulus | Student completing and submitting an exam attempt (FR-26) |
| Stimulus | `exam_attempt.status` is set to `submitted` |
| Environment | Normal system load; scoring job queue has capacity |
| Artifact | Auto-scoring pipeline: answer matching (FR-27) + band calculation (FR-28) + result write |
| Response | Reading and Listening `attempt_results` records are set to `status = available` and displayed to the student |
| Response Measure | **Reading and Listening results available within 2 minutes of `exam_attempt.submitted_at`** (measured as `attempt_results.reading_available_at − exam_attempt.submitted_at`) |

**Rationale:** Students expect near-instant feedback for auto-scored skills. A delay > 2 minutes creates the impression of a system error. The 2-minute window covers: job queue pickup + answer matching computation + band lookup + DB write + client poll cycle.

---

#### NFR-06 — Performance Efficiency: Response Time (Exam State Writes)

| Field | Value |
|-------|-------|
| Source of Stimulus | Student selecting an MCQ option or completing a text input (FR-105) |
| Stimulus | Client sends `PATCH /api/v1/exam/attempts/{id}/answers` |
| Environment | System under peak concurrent exam load |
| Artifact | Backend API exam state write endpoint + database write |
| Response | Server acknowledges the write and returns HTTP 200 |
| Response Measure | `[TBD: p95 < 300ms end-to-end (client send to HTTP 200 received) \| owner: TechLead \| resolve-by: OI-05]` |

**Rationale:** Slow write acknowledgment causes the "Saved" indicator to lag, creating student anxiety during exams. With 500 concurrent students sending approximately 1 write per 30 seconds, peak write throughput is ~17 writes/second — well within typical database capacity, but the p95 bound must be validated under load.

---

#### NFR-07 — Performance Efficiency: Throughput (Speaking Audio Upload)

| Field | Value |
|-------|-------|
| Source of Stimulus | Student completing a Speaking part recording (FR-23) |
| Stimulus | Client initiates Speaking audio upload to Cloud Storage (presigned URL or proxy, FR-108) |
| Environment | Student on a standard broadband connection (≥ 10 Mbps upload); system under peak load |
| Artifact | Speaking audio upload path: client → Cloud Storage (SI-01) |
| Response | Audio file is fully uploaded and Cloud Storage confirms receipt |
| Response Measure | `[TBD: Total Speaking audio for one student (all 5 parts, estimated 5–15 MB total) uploaded within 5 minutes on a 10 Mbps connection \| owner: TechLead \| resolve-by: OI-05, OI-07]` |

**Rationale:** Slow upload risks incomplete audio at session close. Speaking audio must be uploaded before the session window closes to be included in scoring. The presigned URL upload path (SI-01) bypasses the backend, reducing server load and increasing throughput.

**Measurement method:** Upload timing instrumented at client level; Cloud Storage receipt confirmation timestamp logged per file.

---

#### NFR-08 — Performance Efficiency: Latency (Listening Audio CDN Delivery)

| Field | Value |
|-------|-------|
| Source of Stimulus | Student entering a Listening question (FR-22) |
| Stimulus | Exam client requests the Listening audio file from CDN |
| Environment | Student at a school in Vietnam; CDN edge node serving Southeast Asia |
| Artifact | CDN delivery path for Listening audio files (SI-01, CDN-fronted) |
| Response | Audio file is streamed to the client and begins playing |
| Response Measure | `[TBD: Time-to-first-byte ≤ 500ms; no buffering interruption during playback \| owner: TechLead \| resolve-by: OI-05]` |

**Rationale:** Listening audio auto-plays on part entry (FR-22) and has strict play-count limits (default 1 play). A CDN delivery failure or long buffering delay consumes the student's limited plays without delivering audio — a critical exam fairness issue.

**Implementation note:** CDN edge nodes in Vietnam or Southeast Asia are required. Exam audio assets should be pre-warmed to CDN edge on session start, not fetched cold on first student request.

---

#### NFR-09 — Performance Efficiency: Time Behavior (AI Scoring Pipeline)

| Field | Value |
|-------|-------|
| Source of Stimulus | Student exam submission triggering the AI scoring pipeline (FR-30, FR-31) |
| Stimulus | AI scoring job is queued and begins processing Speaking audio and Writing text |
| Environment | Normal AI provider API availability; job queue not overloaded |
| Artifact | AI scoring pipeline: STT API call (FR-30) + LLM API call (FR-31) + draft score write |
| Response | Teacher receives email notification that draft scores are ready for review |
| Response Measure | `[TBD: STT complete within 5 minutes of submission; LLM draft score generated within 10 minutes of transcript; teacher notified within 15 minutes of exam_attempt.submitted_at \| owner: TechLead \| resolve-by: OI-02 (provider selection), OI-05]` |

**Rationale:** Long AI pipeline delays push back teacher review and student result availability. The suggested 15-minute end-to-end target means teachers can begin reviewing Writing/Speaking scores within one exam session cycle. Actual target is contingent on AI provider API latency (OI-02).

---

#### NFR-10 — Maintainability: Data Retention (Exam Records)

| Field | Value |
|-------|-------|
| Source of Stimulus | Scheduled data retention job |
| Stimulus | Exam answer records, attempt metadata, and scoring records age beyond the configured retention threshold |
| Environment | Normal system operation; background maintenance job |
| Artifact | exam_answers, exam_attempts, attempt_results, ai_score_drafts, final_scores tables |
| Response | Records older than the retention threshold are archived or purged |
| Response Measure | `[TBD: Minimum 2 years from attempt date — PM/Legal to confirm based on NĐ 13/2023/NĐ-CP applicability \| owner: PM + Legal \| resolve-by: OI-07]` |

**Compliance note:** NĐ 13/2023/NĐ-CP (Vietnamese Personal Data Protection Decree) may impose minimum or maximum retention obligations on student personal data (name, email, exam scores). Legal must confirm applicability before this NFR can be finalized.

---

#### NFR-11 — Maintainability: Data Retention (Speaking Audio Recordings)

| Field | Value |
|-------|-------|
| Source of Stimulus | Scheduled audio retention job |
| Stimulus | Speaking audio files in Cloud Storage age beyond the configured retention threshold |
| Environment | Normal system operation |
| Artifact | Cloud Storage (SI-01): Speaking audio files per attempt per part |
| Response | Audio files older than the threshold are deleted from Cloud Storage |
| Response Measure | `[TBD: 90 days post teacher-score-confirmation, then purge — PM/Legal to confirm \| owner: PM + Legal \| resolve-by: OI-07]` |

**Cost note:** Speaking audio estimated at 5–15 MB per student attempt. At 150,000 student attempts/year, storage accumulates at 750 GB–2.25 TB per year. Retention duration is the primary driver of storage cost and must be minimized consistent with legal and audit requirements.

---

#### NFR-12 — Security: Password Storage — **Confirmed**

| Field | Value |
|-------|-------|
| Source of Stimulus | User registering or changing a password; an attacker with read access to the user table |
| Stimulus | A plaintext password is submitted for storage; or a stored hash is exfiltrated |
| Environment | Normal authentication flow; or post-breach scenario |
| Artifact | User credential storage (users table, password_hash column) |
| Response | Password is stored as a one-way adaptive hash; exfiltrated hashes cannot be reversed in practical time |
| Response Measure | **bcrypt with cost factor ≥ 12** (approximately 300ms per hash on current commodity hardware); no plaintext passwords stored in the database at any time |

**Implementation constraint:** The one-time plaintext credential export (FR-48) must generate and transmit the password at account creation time only; it must never be stored in plaintext in the database. The export reads the plaintext from memory at creation time and hashes before writing.

---

#### NFR-13 — Security: Authentication Token Lifetime — **Confirmed**

| Field | Value |
|-------|-------|
| Source of Stimulus | An authenticated user session; an attacker intercepting an access token |
| Stimulus | Access token is in use; or an access token is captured by an attacker |
| Environment | Normal authenticated session; or active MITM/token theft scenario |
| Artifact | JWT access tokens and refresh tokens (FR-02) |
| Response | Intercepted access tokens expire quickly; refresh tokens rotate on use, invalidating previous tokens |
| Response Measure | **Access token TTL ≤ 15 minutes; Refresh token TTL ≤ 7 days; refresh tokens rotate on every use (old token invalidated upon new token issuance)** |

**Implementation note:** Refresh tokens must be stored server-side (database or Redis) to support forced invalidation (FR-07). Pure stateless JWT refresh tokens cannot be revoked. Refresh tokens are single-use; reusing an old refresh token returns HTTP 401.

---

#### NFR-14 — Reliability: Exam Data Integrity (Exam Continuity) — **Confirmed (#1 Priority)**

| Field | Value |
|-------|-------|
| Source of Stimulus | Any event that interrupts a student's exam attempt: network disconnect, browser crash, app force-close, device power-off, server failover |
| Stimulus | Student's exam client loses connection or terminates unexpectedly during an active attempt |
| Environment | Any network condition; any point during an active exam session |
| Artifact | exam_state (per-answer persistence), local audio buffer (Speaking), server-authoritative timer, resume flow |
| Response | When the student reconnects within the session window, all previously submitted answers are intact; the server timer has continued accurately; Speaking audio is either uploaded or recoverable from local buffer |
| Response Measure | **Exam answer data loss rate = 0%** for any attempt where the student successfully submitted at least one answer before disconnection; measured as the count of attempts where `final_answer_count < student_reported_submitted_count` |

**Rationale:** The stakeholder explicitly designated exam continuity as the #1 product priority. Any answer that was saved to the server by FR-105 must survive any client-side failure. This NFR is the composite outcome of the F-13 cluster (FR-104 through FR-111).

**Measurement method:** Post-session audit comparing per-question answer records in `exam_answers` against the attempt's `exam_state` submission log; Speaking audio delivery rate (files confirmed in Cloud Storage vs. files recorded by client, per attempt).

---

## Performance Requirements Summary

| ID | Characteristic | Response Measure | Status |
|----|----------------|-----------------|--------|
| NFR-01 | API Response Time (p95) | TBD (suggested: p95 < 500ms) | TBD — OI-05 |
| NFR-02 | Overall Availability | TBD (suggested: ≥ 99.5%/month) | TBD — OI-05 |
| NFR-03 | Exam Hour Availability | ≥ 99.9% during active exam sessions | **Confirmed** |
| NFR-04 | Concurrent Exam Takers | TBD (suggested: ≥ 500 concurrent) | TBD — OI-05 |
| NFR-05 | Auto-score Latency | ≤ 2 minutes from submission | **Confirmed** |
| NFR-06 | Exam State Write Latency (p95) | TBD (suggested: p95 < 300ms) | TBD — OI-05 |
| NFR-07 | Speaking Audio Upload | TBD (suggested: ≤ 5 min for full set) | TBD — OI-05 |
| NFR-08 | Listening CDN Delivery | TBD (suggested: TTFB ≤ 500ms) | TBD — OI-05 |
| NFR-09 | AI Scoring Pipeline | TBD (suggested: ≤ 15 min total) | TBD — OI-02, OI-05 |
| NFR-10 | Exam Record Retention | TBD (pending Legal — OI-07) | TBD — OI-07 |
| NFR-11 | Audio Recording Retention | TBD (pending Legal — OI-07) | TBD — OI-07 |
| NFR-12 | Password Hashing | bcrypt cost ≥ 12 | **Confirmed** |
| NFR-13 | JWT Token Lifetime | Access ≤ 15 min; Refresh ≤ 7 days rotating | **Confirmed** |
| NFR-14 | Exam Data Integrity | 0% answer data loss rate | **Confirmed (#1 priority)** |
