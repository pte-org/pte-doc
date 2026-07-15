# APTIS LMS — SRS Improvement Report
**Version:** 1.0 | **Date:** 2026-06-17 | **Source:** `/sr:improve` after IEEE 830 validation (COMPLIANT, 0 ERRORs, 7 WARNings)

This report is candid. It records what was deferred, what carries implementation risk, which FRs need refinement, which NFRs cannot be tested without additional data, and what process gaps exist. All findings reference specific FR/NFR IDs so they can be triaged in issue tracking.

---

## §1 — Deferred Features (Next Version Candidates)

These features were explicitly placed OUT of scope in `spec.md §4`. Each one was raised during brainstorming and excluded deliberately.

### 1.1 Payment and Billing Automation
**Version:** v2.0 | **Effort:** High

Currently Sales Team manages contracts and invoicing entirely outside the system. The platform only tracks whether a license exists — not how it was paid for. If the Sales team grows to 10+ tenants simultaneously, manual license renewal will become a bottleneck. The system has no invoice generation, no payment gateway, no recurring subscription management.

**When to revisit:** When Sales volume exceeds what manual license creation can handle; or when tenants request self-service license renewal.

**Dependencies to plan now:** The `licenses` entity already carries `seat_count` and `expiry_date`. A payment gateway integration in v2.0 would add `billing_cycle`, `invoice_id`, and `payment_provider_ref` columns. These fields should be reserved (null-allowed) now to avoid a schema migration under pressure.

---

### 1.2 Video Proctoring
**Version:** v3.0 | **Effort:** High

Excluded because of storage costs, privacy implications, and complexity. The current anti-cheat system (F-12: fullscreen enforcement, tab/focus detection, copy-paste blocking, violation thresholds) covers the primary honesty signals available in a browser/desktop environment without recording video.

**Gap this leaves:** Students can speak to someone off-camera during Speaking. Copy-paste blocking does not prevent typing answers dictated by a third party. These are known limitations of software-only anti-cheat that video proctoring would close.

**When to revisit:** If large-enterprise tenants (government agencies, universities with formal exam mandates) require stronger proctoring guarantees as a condition of purchase.

---

### 1.3 LMS External Integrations (Moodle, Canvas, Google Classroom)
**Version:** v2.0 | **Effort:** Medium

No tenant at launch requires this. However, schools that already use Moodle or Google Classroom will want student roster sync so they do not maintain two systems. The current CSV import (FR-47) serves as a manual bridge.

**Practical risk:** If a target tenant school is already on Moodle and finds CSV import insufficient, this becomes a sales blocker.

**When to revisit:** After the first 5 tenant onboardings — their feedback will determine if integration friction is high enough to warrant investment.

---

### 1.4 Tenant-Authored Question Banks
**Version:** v2.0 | **Effort:** Medium

Currently only Vendor Content Managers can create questions (Assumption A-04). Tenants use the shared question bank via exam templates. If a tenant wants to create proprietary practice content (e.g., industry-specific vocabulary sets), they cannot.

**Consideration for planning now:** The `questions` entity uses a `tenant_id`-less approach (questions are global to the Vendor). If tenant-authored questions are added in v2.0, `questions` will need a nullable `tenant_id` and a visibility scope column. The question CRUD FRs (FR-09 through FR-16) would need Actor expansion. Plan the data model with this in mind.

---

### 1.5 Flutter Mobile (Exam Client)
**Version:** v1.5 | **Effort:** Medium

The suggested baseline (OI-01) defers Flutter Mobile to v1.5. The Exam Client on Flutter Desktop + Flutter Web covers the primary use case (supervised exam at school). Mobile covers students studying independently at home on a phone — a different use case that could expand the addressable market significantly.

**What gets unlocked by resolving OI-01:**
- FR-84 (push notifications via FCM) moves from Conditional to Essential
- SI-03 (Firebase Cloud Messaging) becomes a required integration
- FR-102 (kiosk mode) remains Desktop-only and stays Conditional
- NFR-07 (Speaking audio upload) gets a concrete file format and size constraint based on mobile recording APIs

---

### 1.6 Marketplace for Exam Content
**Version:** v3.0+ | **Effort:** High

Excluded permanently for v1 because content quality control is not feasible without a Vendor review process, and the business model requires validation. This section is noted for completeness only.

---

## §2 — Technical Risks

### 2.1 Unresolved NFR Numeric Targets

All 9 TBD NFRs block test planning and infrastructure sizing. Each is analyzed below:

| NFR | Risk if Unresolved | Data Needed to Set Target | Suggested Owner Action |
|-----|-------------------|--------------------------|----------------------|
| NFR-01 (p95 API response) | Load test has no pass/fail criterion; infrastructure tier cannot be sized | Run load test against a prototype at 500 concurrent; pick p95 from results | TechLead: run benchmark after OI-01 resolves platform choice |
| NFR-02 (overall availability) | No SLA to commit to tenants in contracts | Commercial decision: what downtime is acceptable outside exam hours? | TechLead + PM: align with contract terms Sales is making verbally today |
| NFR-04 (concurrent exam takers) | Cannot size database write tier; cannot size WebSocket server | Tenant count × expected peak simultaneous sessions per tenant | Vendor Business: provide tenant projection for 12 months |
| NFR-06 (exam state write p95) | "Saved" indicator responsiveness cannot be guaranteed; student anxiety risk | Benchmark DB write latency at target capacity | TechLead: can derive from NFR-04 load model once capacity is known |
| NFR-07 (audio upload time) | Audio may not finish uploading before session close; incomplete Speaking scores | Speaking part durations per APTIS standard (needed from Content Manager) | Content Manager: provide exact speaking duration per part; TechLead: compute file size estimate |
| NFR-08 (CDN TTFB) | Listening audio delay consumes student's limited play count (BR-15) | CDN provider benchmark from a Vietnam edge node | TechLead: can be benchmarked with CDN vendor during infra selection |
| NFR-09 (AI pipeline total time) | Cannot commit Teacher notification timing to tenants | STT latency + LLM latency benchmarks from each provider candidate | TechLead: benchmark during OI-02 proof-of-concept |
| NFR-10 (exam record retention) | Purge jobs cannot be implemented with real parameters | Legal determination on NĐ 13/2023 applicability | PM + Legal: this blocks cloud region selection (OI-07) |
| NFR-11 (audio retention) | Storage cost cannot be estimated; budget cannot be approved | Same legal determination as NFR-10 | PM + Legal: same OI-07 resolution |

**Critical path:** NFR-10 and NFR-11 resolution (OI-07 / Legal) also determines the cloud region (DC-08). Cloud region determines CDN edge placement (NFR-08). This chain means the Legal consultation is the single longest-lead item in the pre-development critical path.

---

### 2.2 AI Provider Integration Risks (SI-04, SI-05)

**Risk: Single-provider dependency.** The system design calls for STT and LLM to be swappable by configuration (SI-05: "Provider switch must be possible via configuration change, not code change"). This constraint is correct and important, but it requires an abstraction layer (adapter pattern over the AI provider API) from day one. If the initial implementation hard-codes the first provider's API structure, a provider switch will require a code change — negating the flexibility spec'd.

**Risk: Vietnamese-accented English STT accuracy.** The primary correctness risk for Speaking scoring. If STT transcribes Vietnamese-accented English poorly, the LLM receives a corrupted transcript and the AI draft score is meaningless — Teacher workload increases because they must re-transcribe or override every draft. OI-02 includes this as an evaluation criterion, but the outcome could be that no provider achieves acceptable accuracy, forcing a fully human scoring pipeline.

**Mitigation suggestion:** In the OI-02 proof-of-concept, test with 5–10 real Speaking recordings from Vietnamese speakers at B1–B2 level. If STT word error rate > 15%, plan for human-only transcription as a fallback and revise FR-30 accordingly.

**Risk: LLM output consistency.** APTIS rubric scoring requires structured JSON output `{criterion_scores, band_estimate, feedback_narrative}`. LLM outputs are probabilistic — the model may return malformed JSON, refuse to score, or hallucinate band estimates outside A1–C. FR-31 specifies the expected JSON schema but does not specify the system response when the LLM returns invalid output. This is a missing error case (see §3 below).

**Risk: AI provider rate limits.** At 150,000 Speaking submissions/year (~400/day), the system will hit rate limits during peak post-exam periods when all students from multiple tenants submit simultaneously. Rate limit handling (retry with backoff) is implied by the async queue design but not explicitly required by any FR. Latency spikes during peak will push NFR-09 violations.

---

### 2.3 Email Provider Dependency (SI-02)

Email delivery is used for 10 distinct notification triggers covering critical exam operations (session notification, results, SLA reminders, license alerts). The provider (SendGrid / AWS SES — TBD) has not been selected.

**Risk:** If email delivery fails silently (bounce, block), students may not know they have an exam. Teachers may not know they have scoring queue items. The notification log (`FR-87`) records delivery status from provider webhooks, but there is no FR specifying what happens when an email fails permanently (after retries). Add a fallback: in-app notification bell with unread count for missed emails.

**Risk:** Email template localization (Vietnamese + English per OR-I18N-05) requires maintaining two versions of every template. With 10 notification types × 2 languages = 20 templates, template management at launch will be manual. No template versioning is specified.

---

### 2.4 CDN Pre-warming Dependency (SI-01, OR-OPS-04)

The scheduled job "Listening audio CDN pre-warm: 15 minutes before session start_time" is specified in the job inventory. However:

- If a session is created less than 15 minutes before it starts, pre-warming cannot complete.
- The scheduled job implementation requires knowing the session `start_time` in advance, which means querying all sessions starting in the next 15 minutes every minute.
- No FR specifies a minimum advance notice required for session creation (e.g., "sessions must be created at least 30 minutes in advance").

**Mitigation:** Add a validation rule to FR-37 (create exam session) that `start_time ≥ NOW() + 30 minutes`, or specify that CDN pre-warming is best-effort with a fallback to origin pull if the edge has not cached the file.

---

### 2.5 WebSocket Server Scalability (CI-02)

The live exam monitor (FR-39) uses WebSocket (primary) or SSE (fallback). WebSocket connections are stateful and require sticky sessions on the load balancer. At 500 concurrent students + 50 Coordinators monitoring, the WebSocket server must maintain ~550 persistent connections.

**Risk:** Horizontal scaling of WebSocket servers requires a shared pub/sub backend (Redis, etc.) so that a student's state update published on server A reaches the Coordinator connected to server B. This is not specified in the SRS. The architecture must implement this pub/sub layer or WebSocket monitoring will break under horizontal scaling.

**Recommendation:** Add an operational requirement that the WebSocket/SSE server architecture includes a shared pub/sub message broker (Redis Pub/Sub or equivalent). This is an architecture-level decision that should be captured in the architecture session (OI-05 scope).

---

## §3 — FR Refinement Suggestions

### 3.1 FR-28: Band Calculation — Missing Error Branch

**FR-28** specifies band calculation from raw score using the Band Mapping Table but only describes the happy path. The `MAPPING_ERROR` flag is mentioned in the glossary but no FR specifies:
- What happens when a student's raw score falls outside all defined ranges in the mapping table?
- Is the student shown a score of 0, an error indicator, or is the result held pending Content Manager review?
- Who is notified when a MAPPING_ERROR occurs?

**Suggested addition:** Add an acceptance criterion to FR-28 (or a new FR-28a) specifying: "Given a student's raw score does not fall within any range in the Band Mapping Table, the system shall set the result status to `MAPPING_ERROR`, notify the Content Manager via system alert, and display 'Result pending review' to the student instead of a band score."

---

### 3.2 FR-31: LLM Scoring — Missing Invalid Output Case

**FR-31** specifies the LLM produces structured JSON output. No FR covers what the system does when the LLM returns:
- Malformed JSON (parse failure)
- A `band_estimate` value outside the valid set (A1, A2, B1, B2, C)
- An empty or truncated `feedback_narrative`
- An HTTP 4xx/5xx from the LLM provider

**Suggested addition:** Add to FR-31's acceptance criteria: "And if the LLM response cannot be parsed as valid JSON, or if `band_estimate` is not in the set {A1, A2, B1, B2, C}, the system shall set `ai_score_drafts.status = LLM_FAILED`, queue the attempt for priority human review, and notify the Teacher without delay."

---

### 3.3 FR-33: Score Finalization — Missing Escalation Case

**FR-33** covers Teacher confirming scores. OI-03 adds a scoring SLA reminder at T+24h and escalation at T+48h. However, no FR specifies what the system does if:
- The Teacher never confirms, even after escalation
- The Tenant Admin also does not act

If the SLA resolves to "no auto-confirm" (the suggested approach in OI-03, preserving BR-13), then students could wait indefinitely for Writing/Speaking results. This is an unspecified failure state.

**Suggested addition:** Once OI-03 resolves, add an FR specifying the maximum wait state and what a student sees: "Results pending review — expected within N hours" vs. "Results have been delayed — please contact your teacher."

---

### 3.4 FR-41: Force Submit — Speaking Audio In-Flight

**FR-41** (Exam Coordinator force-submits a student's attempt) does not specify the behavior when a Speaking audio recording is in progress at the moment of force-submission:
- Is the recording cut and uploaded immediately?
- Is the partial recording discarded?
- Is the attempt result held as incomplete for Teacher review?

This is one of OI-08's sub-cases (8.4: "Force Submit during Speaking recording"). Until OI-08 resolves, FR-41 has an incomplete post-condition for the Speaking-in-progress state. The acceptance criteria of FR-41 should have a placeholder: "And when force-submit is triggered during an active Speaking recording, the behavior is [TBD — OI-08.4]."

---

### 3.5 FR-68 / FR-69: Item Analysis — Missing Trigger Specification

**FR-68** (difficulty index) and **FR-69** (discrimination index) define what is computed but do not specify when recomputation is triggered:
- Is it on every exam attempt submission (expensive for large datasets)?
- Is it on-demand when the Content Manager views the Item Analysis screen?
- Is it via the nightly scheduled job (OR-OPS-04)?

The scheduled job in OR-OPS-04 says "Nightly" which implies a 24-hour staleness. For a Content Manager viewing item analysis after a morning exam session, afternoon data will not yet be reflected. This is acceptable but should be documented explicitly.

**Suggested addition:** Add to FR-68/FR-69: "Item analysis statistics are recomputed nightly by the scheduled job (OR-OPS-04). Values displayed on screen reflect data from the most recent completed nightly recomputation. The last-updated timestamp is shown on the Item Analysis view."

---

### 3.6 FR-95: Fullscreen Enforcement — Missing Mid-Exam Exit Case

**FR-95** specifies fullscreen enforcement during exam start (pre-exam check). However, a student can exit fullscreen mid-exam (pressing Esc, for example). The current FR cluster handles this via the violation event system (FR-96–FR-100), but no FR explicitly states:
- Does exiting fullscreen mid-exam log a violation event, or a different event type?
- Is the student shown an immediate overlay requiring them to re-enter fullscreen?
- If the student refuses to re-enter fullscreen, does it count toward the violation threshold?

FR-96 and FR-97 cover tab-switch and focus-loss. Fullscreen exit is a distinct browser event (`fullscreenchange`) that needs its own violation type in the `violation_events` entity. Currently the entity has `violation_type` as a free-form field; the set of valid violation types should be enumerated.

**Suggested addition:** Add to FR-95: "And if the student exits fullscreen mode during an active exam part, the system shall: (1) log a `FULLSCREEN_EXIT` violation event, (2) display a non-dismissible overlay requiring the student to re-enter fullscreen mode, (3) increment the violation count toward the session's configured thresholds (FR-100)."

---

### 3.7 FR-105: Per-Answer Write — Missing Conflict Resolution

**FR-105** persists every student answer to the server. If a student rapidly changes an answer (e.g., selects option A, then immediately selects option B), the client may send two PATCH requests in rapid succession. If the requests arrive out-of-order due to network jitter, the server may persist option A as the final state.

**Suggested addition:** Add to FR-105: "And the PATCH request payload shall include a client-side `sequence_number` monotonically incremented per question per attempt; the server shall persist only the response with the highest `sequence_number` for each question, discarding out-of-order responses."

---

### 3.8 Missing FR: Vendor Portal Health Dashboard Auto-refresh

**UI-01** specifies a System health panel (API error rate, queue depth, failed notifications). FR-75 (Vendor audit log) and FR-70 (item analysis) cover analytics. However, no FR specifies real-time refresh behavior of the Vendor Portal health panel — is it polled, SSE-driven, or a manual refresh? During a production incident, a stale health dashboard is dangerous.

**Suggested addition:** Add an FR under F-08 (Vendor Management): "The system shall provide the Super Admin dashboard (UI-01) with health metrics refreshed at most every 30 seconds without manual page reload, using either server-sent events or scheduled polling."

---

## §4 — NFR Gaps

The following NFRs have `[TBD]` Response Measures. Each entry identifies the benchmark test that would produce a real number.

| NFR | Benchmark Test Needed |
|-----|----------------------|
| **NFR-01** (API p95 response) | Load test with k6/Locust: 500 virtual students submitting per-answer PATCHes at 1 write/30s simultaneously; measure p95 at API gateway level. Run after cloud infrastructure is provisioned. |
| **NFR-02** (overall availability) | Monitor the staging environment uptime over 30 days using an external probe (UptimeRobot or Better Uptime); compare against SLA commitment Sales is making verbally to tenants — make the SLA numeric. |
| **NFR-04** (concurrent exam takers) | Requires the load model: (a) projected tenant count at launch × (b) average students per tenant × (c) % taking exams simultaneously. Vendor Business must provide input (a) and (b); TechLead computes (c). |
| **NFR-06** (exam state write p95) | Same load test as NFR-01; add database write latency instrumentation per the exam_state write path specifically. `p95(write_latency) = p95(total_API_latency) − p50(application_logic_time)`. |
| **NFR-07** (Speaking audio upload) | Content Manager must provide Speaking part duration per APTIS standard (the audio lengths determine file size at target bitrate). TechLead then computes: `file_size_MB = duration_minutes × bitrate_kbps / 1024 × 8 × 5_parts`. Test upload time on 10 Mbps (school WiFi baseline). |
| **NFR-08** (CDN TTFB) | Run CDN TTFB test from Vietnam-based client to candidate CDN providers (Cloudflare, AWS CloudFront, Google Cloud CDN) for a cold audio file request. Pick the provider with TTFB ≤ target in Vietnam. |
| **NFR-09** (AI pipeline total) | During OI-02 proof-of-concept: measure STT API latency for a 3-minute audio file (end-to-end, not just TTFB). Measure LLM API latency for a 500-word Writing response + rubric prompt. Sum to get pipeline estimate. |
| **NFR-10** (exam record retention) | Not a benchmark test — requires a Legal determination. Once Legal resolves OI-07, the retention period becomes a configuration value in the purge job (OR-OPS-04), not a system performance target. |
| **NFR-11** (audio retention) | Same as NFR-10. Additionally, compute storage cost projection at each candidate retention period: `retention_years × 150,000_attempts × avg_file_size_MB × cloud_storage_cost_per_GB`. Present to PM/Legal as part of OI-07 discussion. |

---

## §5 — Validation Warnings

These are the 7 WARNings produced by the IEEE 830 validator. Each is assessed for urgency.

| Warning | Location | Recommended Resolution | Urgency |
|---------|----------|----------------------|---------|
| **unresolved-tbd** (1 tag) | `02-overall-description.md` | Likely tied to OI-01 (Flutter platform split). Resolve OI-01 first; then update the description. | Must resolve before dev |
| **unresolved-tbd** (1 tag) | `03-02-functional-requirements.md` | FR-28 band mapping format (§3.1 above). Content Manager + TechLead to confirm mapping table format and out-of-range handling. | Must resolve before F-04 dev |
| **unresolved-tbd** (10 tags) | `03-03-performance.md` | 9 TBD NFR targets + 1 OI-02 reference. See §4 of this report. High-urgency: NFR-07/08 must resolve before F-03 dev; NFR-10/11 must resolve before cloud region decision. | Mixed urgency — see §4 |
| **unresolved-tbd** (8 tags) | `03-04-database.md` | All retention period TBDs (OI-07). Blocking: purge job implementation and Cloud Storage cost estimate. | Must resolve before architecture |
| **unresolved-tbd** (4 tags) | `03-07-other-requirements.md` | OR-OPS monitoring thresholds (OI-05), maintenance window definition, review SLA interval (OI-03), log retention (OI-07). OI-03 is the quickest win — business decision with no technical dependency. | Should resolve before QA |
| **unresolved-tbd** (2 tags) | `appendix-b-open-issues.md` | Load model inputs (tenant count, peak session count) for OI-05. Vendor Business must provide these figures for TechLead to size infrastructure. | Must resolve before architecture |
| **open-items-count** (8 items) | `appendix-b-open-issues.md` | All 8 OI items listed with owners. Resolution order: OI-01 → OI-02 → OI-07 → OI-05 → OI-03 → OI-04 → OI-06 → OI-08. | See below |

**Open item resolution priority:**

1. **OI-01 (Flutter platform split)** — blocks frontend architecture, kiosk mode scoping (FR-102), FCM conditional status (FR-84), and NFR-07 (audio file format per platform recording API). Resolve first; TechLead can decide unilaterally with Vendor alignment.

2. **OI-07 (Data retention + NĐ 13/2023)** — blocks cloud region decision (DC-08), CDN location (NFR-08), storage cost budget, and purge job implementation (OR-OPS-04). Legal consultation has the longest lead time of any open item. Initiate immediately in parallel with OI-01.

3. **OI-02 (AI provider)** — blocks FR-30, FR-31, NFR-09. A 2-week proof-of-concept evaluation is the right approach. Initiate after OI-01 resolves (platform affects audio format for STT evaluation).

4. **OI-05 (NFR numeric targets)** — requires load model inputs (OI-08 via Vendor Business) and platform choice (OI-01). Resolve in TechLead architecture session after OI-01 + OI-07 are known.

5. **OI-03 (Scoring SLA)** — pure business decision. Suggested defaults: T+48h total, T+24h reminder, no auto-confirm. If Vendor agrees to these defaults, OI-03 can be resolved in a single meeting. Fastest open item to close.

6. **OI-04 (Anti-cheat thresholds)** — similar to OI-03, pure business decision. Suggested defaults: warning=3, terminate=5, range [1, 20]. Can be resolved in the same session as OI-03.

7. **OI-06 (Guest trial scope)** — only blocks F-11 (Conditional cluster). Can be deferred if F-11 is cut from v1 scope.

8. **OI-08 (Exam continuity edge cases)** — requires a dedicated technical workshop, not a document review. See §6.1 below.

---

## §6 — Process Recommendations

### 6.1 OI-08 Requires a Workshop, Not a Document Review

OI-08 lists 7 distinct edge cases in exam continuity (network drop mid-recording, power-off, timer-expiry during recording, force-submit during recording, etc.). Each case involves both a technical question (what is recoverable?) and a policy question (what is the correct outcome for the student?).

These cannot be resolved asynchronously via email. The correct process is a 2-hour focused workshop with:
- TechLead (technical limits of each recovery scenario)
- Vendor Product (policy: what outcome is fair to the student?)
- An Exam Coordinator representative (operational reality: what can a proctor actually handle?)

The workshop output is a decision matrix: for each edge case, document the technical response and the student-facing policy. FR-109, FR-110, and FR-111 can then be finalized with concrete acceptance criteria.

**Schedule this before the F-13 cluster is developed.** F-13 is the highest-risk cluster (exam continuity as stated #1 priority) and the most likely to have implementation rework if the edge cases are underdefined.

---

### 6.2 No Security Architect Review

The SRS contains security requirements (NFR-12, NFR-13, SA-SEC-01 through SA-SEC-08, DC-02, DC-03, DC-09, DC-10, DC-12) but no security-focused stakeholder reviewed this document. Specific gaps a security architect would flag:

- **No rate limiting on exam state writes from a single attempt** — CI-01 specifies 120 requests/minute per `attempt_id`, but the enforcement mechanism (WAF rule, API gateway middleware, application code?) is unspecified. A student with a malicious client could flood the exam state table.
- **Presigned URL expiry scope** — SI-01 states presigned URLs expire "within the exam session window." The exam window can be several hours. A presigned URL valid for 4 hours is meaningfully different from one valid for 15 minutes. The expiry should be constrained to the speaking part duration plus a grace period.
- **Cross-tenant data leak as a test criterion** — SA-SEC-02 correctly flags cross-tenant data access as a Critical security defect. However, no test requirement specifies that a tenant isolation test suite (attempting to access data from a different tenant_id using a valid token from tenant A) is a mandatory part of QA before launch.
- **impersonation_log completeness** — FR-76 (Conditional) specifies Support Staff impersonation. The impersonation log must capture: who impersonated, which tenant, start time, end time, and all actions taken during impersonation. The current `impersonation_log` entity captures `impersonator_id`, `target_tenant_id`, `started_at`, and `ended_at` — but not the list of actions taken. Consider logging all API requests made during an impersonation session.

**Recommendation:** Before the architecture session, request a 90-minute security review of §3.6 (System Attributes) and §3.5 (Design Constraints) with a security-focused engineer or external consultant.

---

### 6.3 Speaking Audio Format Not Specified

No FR or DC specifies the audio codec, container format, or bitrate for Speaking recordings. This matters for:
- NFR-07: file size estimate depends on bitrate
- STT accuracy: some STT APIs perform better on WAV/PCM than compressed formats
- Browser compatibility: Flutter Web records in WebM (Opus codec); Flutter Desktop may record in WAV or M4A depending on the recording library

**Recommendation:** Content Manager + TechLead should agree on a target format (recommendation: WebM/Opus for web, WAV for desktop for maximum STT compatibility; transcode server-side if needed) before OI-02 proof-of-concept begins, so that the STT benchmark uses the actual production audio format.

---

### 6.4 No Tenant Representative Reviewed the Requirements

The brainstorm process involved Vendor-side decisions. No actual Teacher, Tenant Admin, or Exam Coordinator from a real school reviewed the functional requirements. As a result, several areas may not reflect real operational workflows:

- **CSV import format (FR-47):** The template column structure is not specified. Schools may have existing spreadsheets in non-standard formats. A template mismatch causes import failures at onboarding — a bad first impression.
- **Score review queue UX (FR-32, UI-06):** The scoring queue design assumes Teachers check it regularly. In practice, Teachers at exam-heavy schools may have 20–30 Speaking submissions to review in a single sitting after a morning exam. The queue design should support batch operations (confirm multiple drafts at once) which is not currently specified.
- **Exam session naming (FR-37):** Schools may have naming conventions for exam sessions (e.g., "APTIS Mock Test - Grade 11 - Semester 1 - 2026"). The free-text name field is sufficient, but character limit is not specified.

**Recommendation:** Before FR freeze and before dev starts, run a 1-hour walkthrough of the Tenant Portal FRs with at least one real Teacher and one Tenant Admin from a target customer school. Their feedback on FR-32, FR-37, FR-47, and FR-58 (student name anonymization in ranking) will catch assumptions that desk-based requirements cannot surface.

---

### 6.5 Assumption A-03 Carries High Invalidation Risk

**A-03 states:** "Each tenant has enough teachers who can review Speaking/Writing within an acceptable time. The system does not auto-complete without human review."

If a tenant runs an exam session with 30 students and has only 1 Teacher available, and that Teacher is sick or unavailable, 30 students will be stuck waiting for their Speaking/Writing scores with no system escalation path.

The SRS's suggested SLA approach (OI-03: T+24h reminder, T+48h escalation to Tenant Admin) mitigates this partially. But the ultimate risk is: if a Tenant has no active Teachers, scores never get confirmed. The system has no mechanism to handle this.

**Recommendation:** Once OI-03 resolves the SLA, add a system-level safeguard: if no Teacher or Admin in a tenant has reviewed a submission after T+72h, Super Admin is alerted. This prevents silent indefinite waits that the Vendor would only discover from a support complaint.

---

### 6.6 The Band Mapping Table is a Single Point of Failure

The glossary defines "Band Mapping Table" as "the only authoritative source of band derivation (Assumption A-10)." FR-28 uses it. If the Content Manager configures the table incorrectly (wrong score ranges, gaps between ranges, overlapping ranges), every student in every exam will receive a wrong band score until the error is discovered and corrected.

No FR specifies:
- Validation of the Band Mapping Table at save time (do ranges cover 0 to max_score without gaps or overlaps?)
- Who can modify the mapping table (Content Manager only? Super Admin approval required?)
- Whether changing the mapping table retroactively affects historical attempts (it should not)

**Recommendation:** Add a validation FR for the Band Mapping Table configuration screen: "The system shall validate that the configured ranges cover the complete score range [0, max_score] without gaps or overlaps before allowing the table to be published. The table shall not be modifiable after any exam attempt has used it — a new version must be created."

---

## Summary

| Category | Count | Highest Priority |
|----------|-------|-----------------|
| Deferred features | 6 | Flutter Mobile (OI-01 decision point) |
| Technical risks | 5 | AI provider STT accuracy for Vietnamese accent; Legal consultation for OI-07 |
| FR refinement items | 8 | FR-31 (LLM invalid output), FR-95 (mid-exam fullscreen exit), FR-105 (sequence conflict) |
| NFR gaps | 9 | All TBD NFRs; NFR-07/08 on critical path for F-03 dev |
| Validation warnings | 7 | 26 [TBD] tags across 6 files; all tied to 8 open items |
| Process recommendations | 6 | OI-08 workshop (exam continuity edge cases); no security architect review |

**Highest-urgency single action:** Schedule the Legal consultation for OI-07 (NĐ 13/2023 + cloud region) now. It has the longest lead time and blocks the most downstream decisions (cloud provider, CDN, storage budget, purge job implementation). Everything else can proceed in parallel.

**Next:** Resolve OI-01 → OI-07 (in parallel) → OI-02 (proof-of-concept) → OI-05 (architecture session) → re-run `/sr:validate` after all open items are resolved to promote SRS from DRAFT to FINAL.
