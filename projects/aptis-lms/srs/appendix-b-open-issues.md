# SRS Appendix B — Open Items
## APTIS LMS
**Version:** 1.0 | **Date:** 2026-06-16 | **Status:** DRAFT

---

All items tagged `[TBD]` throughout this SRS are consolidated here with owner, blocking impact, and resolve-by milestone. No SRS section can be promoted to FINAL status while open items affecting that section remain unresolved.

---

## OI-01: Flutter Platform Split

**Status:** OPEN
**Owner:** TechLead
**Blocking:** FR-18, FR-95, FR-97, FR-102, NFR-07, SI-03 (FCM), front-end effort estimate

**Question:** Which client subsystem is deployed on which Flutter platform target?

| Subsystem | Candidate Platforms | Decision Needed |
|-----------|---------------------|-----------------|
| Vendor Portal | Flutter Web | Confirm |
| Tenant Portal | Flutter Web | Confirm |
| Exam Client (Student) | Flutter Web + Flutter Desktop (Win/macOS) + Flutter Mobile (iOS/Android) | Which platforms for v1? |
| Trial Landing Page | Flutter Web | Confirm |

**Suggested baseline:** Flutter Web for all admin portals; Flutter Desktop (Windows primary, macOS secondary) + Flutter Web for Exam Client; Flutter Mobile deferred to v1.5.

**Impact if unresolved:**
- FR-18 (pre-exam checks — kiosk and microphone API vary by platform) cannot be finalized
- FR-102 (kiosk mode — Desktop only feature) remains Conditional
- FR-84 (push notifications) and SI-03 (FCM) remain Conditional
- NFR-07 (Speaking audio file format depends on platform recording API) cannot be finalized
- Frontend architecture and package selection are blocked

**Resolve by:** Before TechLead architecture session

---

## OI-02: AI Provider Selection

**Status:** OPEN
**Owner:** TechLead
**Blocking:** FR-30, FR-31, NFR-09, SI-04, SI-05

**Questions:**
1. STT provider: OpenAI Whisper API vs. Google Cloud Speech-to-Text vs. Azure Cognitive Services?
2. LLM provider: Claude API (Anthropic) vs. OpenAI GPT-4o vs. Google Gemini?
3. Is English STT accuracy sufficient from each provider for non-native Vietnamese-accented English speech?
4. What are the cost structures per transcription minute and per LLM evaluation request?
5. What are the API rate limits and retry policies for each provider?

**Evaluation criteria (in priority order):**
- English STT accuracy for Vietnamese-accented speakers (primary driver)
- LLM scoring quality against APTIS rubric criteria
- API latency (affects NFR-09)
- Pricing at expected scale (~150,000 Speaking submissions/year at v1 steady state)
- API stability and SLA from provider

**Impact if unresolved:**
- FR-30 (STT transcription) and FR-31 (LLM draft scoring) cannot be implemented
- AI scoring pipeline architecture cannot be designed
- NFR-09 (pipeline latency target) cannot be estimated
- Prompt engineering deliverable (APTIS rubric prompts) cannot begin

**Resolve by:** Before TechLead architecture session; a brief proof-of-concept evaluation is recommended

---

## OI-03: Writing and Speaking Scoring SLA

**Status:** OPEN
**Owner:** Vendor Business + Tenant Representative
**Blocking:** FR-83 (SLA reminder trigger), NFR-09, student-facing result expectation messaging

**Questions:**
1. What is the maximum acceptable time for a Teacher to review and confirm AI draft scores for Writing and Speaking after exam submission?
2. What happens if a Teacher does not review within the SLA — system reminder only, auto-confirm AI draft, or escalation to Tenant Admin?
3. From the student perspective: how long is it acceptable to wait for Writing/Speaking results?

**Suggested approach:**
- SLA = 48 hours from exam submission
- T+24h: reminder email to Teacher
- T+48h: escalation email to Tenant Admin
- No auto-confirm (preserves human oversight per BR-13)

**Impact if unresolved:**
- Cannot implement FR-83 SLA reminder notification (the trigger condition is undefined)
- Cannot write student-facing messaging ("Results available within X hours")
- Cannot set Teacher expectations in onboarding documentation

**Resolve by:** Before spec finalization / development of F-10 cluster

---

## OI-04: Anti-cheat Default Violation Thresholds

**Status:** OPEN
**Owner:** Vendor Business
**Blocking:** FR-100 (threshold enforcement), FR-37 (session creation default values), Tenant Portal UI session creation form

**Questions:**
1. What are the default values for `warning_threshold` and `terminate_threshold`?
2. What is the configurable range for each threshold (min/max)?
3. Should the system prevent setting `terminate_threshold` too low (e.g., = 1, which would terminate on the first tab switch)?

**Suggested defaults:** `warning_threshold = 3`, `terminate_threshold = 5`
**Suggested constraints:** `warning_threshold ≥ 1`, `terminate_threshold ≥ warning_threshold + 1`, `terminate_threshold ≤ 20`

**Impact if unresolved:**
- FR-100 cannot reference concrete default values
- Test cases for violation threshold behavior cannot be written
- Session creation form cannot show correct defaults in the UI

**Resolve by:** Before development begins on F-12 (Exam Integrity cluster)

---

## OI-05: NFR Numeric Targets

**Status:** OPEN
**Owner:** TechLead
**Blocking:** NFR-01 (API response time), NFR-02 (availability), NFR-04 (concurrent load), NFR-06 (exam state write latency), NFR-07 (audio upload), NFR-08 (CDN latency), NFR-09 (AI pipeline)

**Questions requiring TechLead input:**

| NFR | Question | Suggested value |
|-----|----------|-----------------|
| NFR-01 | API response time target (p95) for REST endpoints? | p95 < 500ms |
| NFR-02 | Overall availability SLA (outside exam hours)? | ≥ 99.5% monthly |
| NFR-04 | Maximum concurrent exam takers at v1? | ≥ 500 concurrent |
| NFR-06 | Per-answer write latency target (p95)? | p95 < 300ms |
| NFR-07 | Speaking audio upload size limit and max acceptable upload time? | 5–15 MB/student, ≤ 5 min |
| NFR-08 | Listening audio CDN latency (TTFB) target? | TTFB ≤ 500ms |
| NFR-09 | AI scoring pipeline end-to-end time target? | ≤ 15 min total |

**Context for TechLead estimation:**
- Expected tenants at launch: `[NEEDS USER INPUT from Vendor]`
- Expected students per tenant: ~100–500
- Expected simultaneous peak sessions: `[NEEDS USER INPUT]`
- Speaking audio length per part: `[NEEDS USER INPUT — per APTIS standard timing]`

**Impact if unresolved:**
- Infrastructure sizing and load testing scenarios cannot be defined
- NFR-01, NFR-02, NFR-04, NFR-06, NFR-07, NFR-08, NFR-09 remain `[TBD]` and cannot be verified in testing

**Resolve by:** After TechLead architecture session; requires load model input from Vendor

---

## OI-06: Guest Trial Scope and Lead Capture Policy

**Status:** OPEN
**Owner:** Vendor Marketing / Product
**Blocking:** FR-88–FR-92 (complete specification), trial question set configuration, AI scoring cost estimate for trial

**Questions:**
1. Which APTIS skills are included in the trial? (All 4? Reading only? One skill of user's choice?)
2. How many questions per part in the trial? (Full part? Reduced count?)
3. Is Speaking band included in trial results? (Requires STT + LLM pipeline for trial — significant cost implication)
4. Is lead capture (FR-91) required for v1 or deferred?
5. If lead capture is included: is email entry mandatory or optional to proceed?
6. Is the trial URL a dedicated Vendor marketing URL or a tenant-selectable URL?

**Impact if unresolved:**
- FR-88 to FR-92 cannot be fully specified or implemented
- Trial question set cannot be configured
- AI scoring cost for trial cannot be estimated (determines whether trial Speaking is feasible)
- F-11 (Guest/Trial) is Conditional — this OI determines whether it ships in v1

**Resolve by:** Before F-11 development begins; can be deferred entirely if F-11 is cut from v1 scope

---

## OI-07: Data Retention, Compliance, and Vietnamese NĐ 13/2023

**Status:** OPEN
**Owner:** PM + Legal
**Blocking:** NFR-10, NFR-11, FR-92, OR-LGL-02, OR-OPS-03, OR-OPS-06, §3.4.4 (retention table), cloud region selection

**Questions:**

| # | Question | Impact |
|---|----------|--------|
| 1 | How long to retain exam answer records (`exam_state`, `attempt_results`)? | NFR-10, purge job specification |
| 2 | How long to retain Speaking audio recordings in Cloud Storage? | NFR-11, storage cost estimate |
| 3 | How long to retain STT transcripts (`ai_score_drafts`)? | Privacy risk, storage cost |
| 4 | How long to retain `violation_events` and `exam_events`? | Integrity audit requirements |
| 5 | How long to retain `notification_log` entries? | NFR-10 |
| 6 | How long to retain Guest/Trial session data before purge (FR-92)? | FR-92 purge job trigger |
| 7 | Does NĐ 13/2023/NĐ-CP apply to APTIS LMS? If yes, what obligations? | OR-LGL-02, consent flows, right-to-deletion |
| 8 | Is data localization required (servers in Vietnam)? | Cloud region selection, DC-08 |
| 9 | Must the system implement a right-to-deletion workflow for students? | New FRs may be required |

**Cost implication note:** Speaking audio at ~5–15 MB per student attempt × 150,000 attempts/year = 750 GB–2.25 TB of audio storage per year. Retention duration is the primary storage cost driver.

**Impact if unresolved:**
- Storage cost estimate for Cloud Storage cannot be computed
- Purge jobs (FR-92, OR-OPS-04) cannot be implemented with concrete parameters
- Cloud region (and therefore deployment cost/latency) cannot be decided
- Compliance risk if NĐ 13 applies and the system is not designed accordingly

**Resolve by:** Before cloud architecture finalization (cloud region decision depends on localization requirement)

---

## OI-08: Exam Continuity Edge Cases

**Status:** OPEN
**Owner:** TechLead (technical resolution) + Vendor Business (policy decisions)
**Blocking:** FR-109 (partial recording recovery), FR-110 (microphone fail handling), FR-111 (crash recovery)

**Unresolved edge cases:**

**8.1 Network drop mid-Speaking recording**
If a recording is in progress and the network drops, which chunk is the "last good chunk" to save? What maximum gap in audio (in seconds) renders the recording corrupt rather than recoverable?

**8.2 Audio device disconnect during recording**
After reconnect, does the student re-record from scratch for that part, or are they given credit for the partial recording? Who decides — system policy or Teacher manual review?

**8.3 Timer expires during Speaking recording**
When the server-side timer for a Speaking part expires while the student is recording, the recording should be cut and uploaded. Is the cut exactly at the timer boundary, or does the system allow a brief grace period (suggested: 5 seconds) for the student to finish their sentence?

**8.4 Force Submit during Speaking recording**
When an Exam Coordinator force-submits (FR-41) while a student is recording, is the in-progress audio preserved? What is the expected flow for partial audio upload?

**8.5 Sustained network loss (> remaining exam time)**
If a student is offline for longer than the remaining exam time, their attempt effectively expires. What UX does the student see on reconnect? Who approves recovery — Teacher, Coordinator, or system auto-policy?

**8.6 Device power-off during exam (Flutter Desktop)**
Local audio buffer is lost. Options: (a) attempt is abandoned with no Speaking score, (b) Teacher manually assigns a Speaking score based on available partial data, (c) Coordinator can grant a Speaking-only retake. This is a business policy decision.

**8.7 Microphone permission denied in browser (not device absence)**
Permission can be re-granted by the student after denial. What is the retry flow? How many retries before the student must signal the proctor? Is there a timeout?

**Impact if unresolved:**
- FR-109 (partial recording recovery) and FR-110 (microphone fail) cannot be fully specified
- FR-111 (crash recovery) power-off case is unhandled
- Edge cases may cause data loss or unfair exam outcomes if not addressed before implementation

**Resolve by:** Dedicated edge-case workshop with TechLead (technical flows) + Vendor Product (policy decisions); before development of F-13 cluster

---

## Additional In-SRS [NEEDS USER INPUT] Items

The following items are tagged inline within SRS sections and require resolution before those sections can be finalized:

| Tag Location | Question | Owner |
|-------------|----------|-------|
| FR-28 | Confirm band mapping table format (score ranges per skill → band) and handling of out-of-range scores | Content Manager + TechLead |
| FR-58 | Should student names be anonymizable in class ranking? (Privacy preference) | Vendor Product + Tenant feedback |
| FR-59 | What is the default "weak student" band threshold? (Suggested: below B1) | Vendor Product |
| FR-85 | Which language is the default per tenant? Can Tenant Admin configure this? | Vendor Product |
| OR-OPS-01 | Define specific monitoring alert thresholds (error rate %, queue depth N, CPU %) | TechLead + Ops |
| OR-OPS-04 | Define "peak exam hours" for maintenance window exclusion (suggested: 07:00–22:00 VNT) | Vendor Product |
| OR-OPS-04 | Define specific scheduled job intervals for SLA reminder check | Vendor Product (OI-03 dependency) |
| OR-OPS-06 | Define log retention period | PM + Legal (OI-07 dependency) |
| OI-05 | Number of tenants at launch and peak concurrent session count (load model inputs) | Vendor Business |

---

## Resolution Tracking

| OI | Owner | Blocking Sections | Status | Resolve By |
|----|-------|------------------|--------|------------|
| OI-01 | TechLead | §3.1, §3.2 (FR-18, FR-95, FR-97, FR-102, FR-84) | OPEN | Architecture session |
| OI-02 | TechLead | §3.2 (FR-30, FR-31), §3.3 (NFR-09) | OPEN | Architecture session |
| OI-03 | Vendor Business | §3.2 (FR-83), §3.3 (NFR-09) | OPEN | Before F-10 dev |
| OI-04 | Vendor Business | §3.2 (FR-100, FR-37) | OPEN | Before F-12 dev |
| OI-05 | TechLead | §3.3 (NFR-01/02/04/06/07/08/09) | OPEN | After architecture session |
| OI-06 | Vendor Marketing | §3.2 (FR-88–92) | OPEN | Before F-11 dev |
| OI-07 | PM + Legal | §3.3 (NFR-10/11), §3.4 §3.7.2 | OPEN | Before architecture |
| OI-08 | TechLead + Vendor | §3.2 (FR-109/110/111) | OPEN | F-13 workshop |
