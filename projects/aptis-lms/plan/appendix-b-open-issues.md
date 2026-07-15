# Plan File Appendix B — Open Issues (SRS Appendix B)
Project: APTIS LMS  
Date: 2026-06-16

All [TBD] and [NEEDS USER INPUT] items from the plan files, with owner and impact.
These must be resolved before the corresponding SRS section can be finalized.

---

## OI-01: Flutter Platform Split

**Status:** OPEN  
**Owner:** TechLead (architectural decision)  
**Source:** spec §5.1, DC-01, FR-17 to FR-26, FR-93 to FR-111  
**Question:** Which client subsystem is deployed on which Flutter platform?

| Subsystem | Candidate Platforms | Decision |
|---|---|---|
| Vendor Portal | Flutter Web | [TBD] |
| Tenant Portal (Admin, Teacher, Coordinator, Viewer) | Flutter Web | [TBD] |
| Exam Client (Student) | Flutter Web + Flutter Desktop (Win/Mac) + Flutter Mobile (iOS/Android) | [TBD] |
| Trial Landing Page (Guest) | Flutter Web | [TBD] |

**Suggested baseline:** Web for all admin portals; Desktop (Windows primary, macOS secondary) + Web for Exam Client; Mobile as v1.5 scope.

**Impact if unresolved:**
- Cannot finalize FR-18 (pre-exam checks — kiosk capability varies by platform)
- Cannot finalize FR-102 (kiosk mode — Desktop only feature)
- Cannot finalize NFR-07 (audio format depends on platform recording API)
- Frontend effort estimate blocked

**Resolve by:** Before TechLead architecture session

---

## OI-02: AI Provider Selection

**Status:** OPEN  
**Owner:** TechLead  
**Source:** spec §5.5, FR-30, FR-31  
**Questions:**
1. STT provider: OpenAI Whisper API vs Google Cloud Speech-to-Text vs Azure Cognitive Services?
2. LLM provider: Claude API (Anthropic) vs OpenAI GPT-4 vs Google Gemini?
3. Is English STT accuracy sufficient from each provider for non-native Vietnamese accents?
4. What are the cost structures per transcription minute and per LLM evaluation request?

**Evaluation criteria:**
- English STT accuracy for non-native Vietnamese English speakers (primary requirement)
- LLM long-form evaluation quality for APTIS rubric compliance
- API latency (affects NFR-09)
- Pricing at scale (~150,000 Speaking submissions per year at initial scale)
- API rate limits and retry policies

**Impact if unresolved:** FR-30, FR-31 cannot be implemented; AI scoring pipeline cannot be designed; NFR-09 cannot be estimated.

**Resolve by:** Before TechLead architecture session; may require a brief proof-of-concept evaluation

---

## OI-03: Speaking and Writing Scoring SLA

**Status:** OPEN  
**Owner:** Vendor Business + Tenant Representative  
**Source:** FR-83 (SLA reminder notification), NFR-09, BR-06  
**Questions:**
1. What is the maximum acceptable time for a Teacher to review and confirm AI draft scores for Speaking and Writing?
2. What happens if a Teacher does not review within the SLA? (System reminder only? Auto-confirm AI draft? Escalate to Tenant Admin?)
3. From a student perspective: how long is it acceptable to wait for Writing/Speaking results?

**Suggested approach:** SLA = 48 hours from exam submission; system sends reminder email at T+24h if not reviewed; at T+48h, escalation email sent to Tenant Admin; no auto-confirm (preserves human oversight).

**Impact if unresolved:**
- Cannot implement FR-83 SLA reminder notification
- Cannot set student expectation messaging ("Results available within X hours/days")
- Tenant onboarding documentation cannot be written

**Resolve by:** Before spec finalization

---

## OI-04: Anti-cheat Default Violation Thresholds

**Status:** OPEN  
**Owner:** Vendor Business  
**Source:** FR-100, FR-09  
**Questions:**
1. What are the default values for `warning_threshold` and `terminate_threshold`?
2. What range can Tenants set these to? (min/max values)
3. Should the system prevent setting `terminate_threshold` too low (e.g., = 1, which would immediately terminate on first tab switch)?

**Suggested defaults:** warning_threshold = 3, terminate_threshold = 5  
**Suggested constraints:** warning_threshold ≥ 1, terminate_threshold ≥ warning_threshold + 1, terminate_threshold ≤ 20

**Impact if unresolved:**
- FR-100 cannot be implemented with concrete values
- Cannot write test cases for violation threshold enforcement
- Tenant Portal UI cannot show correct default values in session creation form

**Resolve by:** Before development begins on F-12 (Exam Integrity)

---

## OI-05: NFR Numeric Targets

**Status:** OPEN  
**Owner:** TechLead  
**Source:** NFR-01, NFR-02, NFR-04, NFR-06, NFR-07, NFR-08, NFR-09  
**Questions:**
1. API response time target (p95) for REST endpoints?
2. Overall system availability SLA (outside exam hours)?
3. Maximum concurrent exam takers the system must support at v1?
4. Per-answer write latency target (p95)?
5. Speaking audio upload size limit and acceptable upload time?
6. Listening audio CDN latency target?
7. AI scoring pipeline end-to-end time target?

**Context for TechLead estimation:**
- Expected tenants at launch: [NEEDS USER INPUT from Vendor — how many schools initially?]
- Expected students per tenant: ~100–500
- Expected simultaneous peak sessions: [NEEDS USER INPUT]
- Speaking audio length per part: [NEEDS USER INPUT — per APTIS standard speaking time limits]

**Impact if unresolved:**
- Infrastructure sizing cannot be determined
- Load testing scenarios cannot be written
- NFR-01, NFR-02, NFR-04, NFR-06, NFR-07, NFR-08, NFR-09 remain TBD and cannot be verified

**Resolve by:** After TechLead architecture session; requires load model input from Vendor

---

## OI-06: Guest Trial Limits and Lead Capture Policy

**Status:** OPEN  
**Owner:** Vendor Marketing/Product  
**Source:** FR-88, FR-89, FR-90, FR-91, FR-92  
**Questions:**
1. Which APTIS skills are included in the trial? (All 4? Reading only? One skill of user's choice?)
2. How many questions per part in the trial? (Full part? Half? Fixed count?)
3. Is estimated Speaking band included in trial results? (Requires STT + LLM pipeline for trial — cost implication)
4. Is lead capture (FR-91) required for v1 or deferred?
5. If lead capture is included: is email entry mandatory or optional?
6. Is the trial available publicly (no tenant context) or only via a specific Vendor marketing URL?

**Impact if unresolved:**
- FR-88 to FR-92 cannot be fully specified
- Trial exam question set cannot be configured
- AI scoring cost for trial cannot be estimated
- FR-11 (Guest/Trial feature cluster) is Conditional — this OI determines whether it ships in v1

**Resolve by:** Before FR-88–92 development begins; can be deferred if feature is cut from v1

---

## OI-07: Data Retention and Compliance

**Status:** OPEN  
**Owner:** PM + Legal  
**Source:** NFR-10, NFR-11, FR-92, OR-LGL-02, OR-OPS-03, OR-OPS-06  
**Questions:**
1. How long to retain exam answer records (exam_state, attempt_results)?
2. How long to retain Speaking audio recordings in Cloud Storage?
3. How long to retain violation_events and exam_events (audit logs)?
4. How long to retain notification_log entries?
5. How long to retain Guest/Trial session data before purge (FR-92)?
6. Does Vietnamese NĐ 13/2023/NĐ-CP apply and, if so, what obligations does it impose?
7. Is data localization required? (Must data be stored on servers in Vietnam?)
8. Must the system implement a right-to-deletion workflow for students?

**Cost implication note:** Speaking audio at ~5–15 MB per student, 150,000 students/year = 750GB–2.25TB of audio storage per year. Retention duration directly determines storage cost.

**Impact if unresolved:**
- Storage cost cannot be estimated
- Purge jobs (FR-92, scheduled jobs in OR-OPS-04) cannot be implemented
- Compliance risk if NĐ 13 applies and system is not designed accordingly
- NFR-10, NFR-11 remain TBD

**Resolve by:** Before architecture finalization (cloud region decision depends on localization requirement)

---

## OI-08: Exam Continuity Edge Cases — Deep Dive

**Status:** OPEN  
**Owner:** TechLead (technical resolution) + Vendor Business (policy decisions)  
**Source:** FR-104 to FR-111  
**Questions:**
1. **Network drop mid-Speaking record:** If recording is in progress and network drops, which chunk is the "last good chunk" to save? What is the maximum allowed gap in the audio before the recording is considered corrupt?
2. **Audio device disconnect during recording:** After reconnect, does the student re-record from scratch for that part, or are they given partial credit for what was recorded? Who decides (system policy or Teacher manual review)?
3. **Timer expires during Speaking recording:** When server-side timer runs out during a Speaking part, the current recording should be cut and uploaded. Is the cut always at the timer boundary, or does the system allow a brief grace period (e.g., 5 seconds to finish the sentence)?
4. **Force submit during Speaking recording:** When an Exam Coordinator force-submits (FR-41) while a student is recording, is the in-progress audio preserved? What is the expected flow?
5. **Sustained network loss (> 30 minutes):** If a student is offline for longer than the remaining exam time, their attempt is session-expired. What is the UX when they reconnect? Who is responsible for the decision (Teacher, Coordinator, or system auto-policy)?
6. **Power-off during exam (Desktop):** Local audio buffer is lost. Is the policy: (a) attempt is abandoned (no Speaking score for that student), (b) Teacher manually assigns Speaking score based on available partial data, (c) Coordinator can grant a Speaking-only retake? This is a business policy decision.
7. **Microphone permission denied in browser (not device issue):** Different from hardware absence — permission can be granted by the student post-denial. What is the retry flow? How many retries? Is there a timeout after which the student must signal proctor?

**Impact if unresolved:**
- FR-109 (partial recording recovery) and FR-110 (microphone fail handling) cannot be fully specified
- FR-111 (crash recovery) power-off case is unhandled
- Edge cases may cause data loss or unfair exam outcomes if not addressed in implementation

**Resolve by:** TechLead architecture session (technical flows) + Vendor product review (policy decisions); recommend a dedicated edge-case workshop

---

## Additional In-plan [NEEDS USER INPUT] Items

The following items were tagged within plan files and are summarized here:

| Tag Location | Question | Owner |
|---|---|---|
| FR-28 | Confirm band mapping table format (score ranges per skill → band) and edge cases for out-of-range scores | Content Manager + TechLead |
| FR-58 | Should student names be anonymizable in class ranking? (Privacy preference) | Vendor Product + Tenant feedback |
| FR-59 | What is the default "weak student" band threshold? (Suggested: below B1) | Vendor Product |
| OR-OPS-03 | Define specific monitoring alert thresholds (error rate %, queue depth N, CPU %) | TechLead + Ops |
| OR-OPS-04 | Define "peak exam hours" for maintenance window exclusion (suggested: 07:00–22:00 VN time daily) | Vendor Product |
| FR-85 | Which language is the default per tenant? Can Tenant Admin configure language? | Vendor Product |
| DC-09 / FR-39 | Should action audit log attribute to user_id + role? (Determines audit log schema) | TechLead |
