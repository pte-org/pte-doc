# Plan: PTE Academic Exam Platform Pivot

Status: 🟡 In Progress
Date: 2026-07-16
Mode: Hard

## Overview

This plan pivots the exam-simulation platform from APTIS format (single-skill scoring, CEFR bands) to PTE Academic format (20 official task types, multi-skill-per-task scoring, 10–90 point scale, AI-driven automated speaking/writing assessment). The pivot is structural (domain model redesign, new scoring pipeline, new exam delivery timing) and spans both backend (pte-api) and frontend (pte-app, pte-web) repositories. This is a high-fidelity simulation, not an MVP rebrand.

## Phases

- [ ] Phase 1: Domain Model Redesign — Restructure `Question` and `Exam` entities to support 20 PTE task types with type-specific fields and config-driven multi-skill scoring mapping.
- [ ] Phase 2: Exam Delivery Timing — Add per-task prep-time and response-time enforcement; research and ingest official PTE timing data for all 20 task types.
- [ ] Phase 3: AI Scoring Research & Architecture — Evaluate speech and essay-scoring vendors; design thin modality-specific wrapper interfaces and infrastructure.
- [ ] Phase 4: Speaking Response Scoring — Implement async scoring pipeline for audio submissions; integrate speech vendor; extract Oral Fluency and Pronunciation sub-scores.
- [ ] Phase 5: Writing Response Scoring — Integrate essay-scoring vendor; extract Grammar, Vocabulary, Written Discourse, and Spelling sub-scores; implement rule-based objective-task scoring.
- [ ] Phase 6: Objective Task Scoring (Reading/Listening) — Implement deterministic rule-based scoring for multiple-choice, fill-in-blank, re-order, highlight, and select-missing-word tasks.
- [ ] Phase 7: Score Aggregation & PTE 10–90 Reporting — Compute Overall, 4 communicative skills (Listening, Reading, Speaking, Writing), and 6 enabling skills on the 10–90 scale; replace CEFR band reporting.
- [ ] Phase 8: Frontend Implementation — pte-app (Flutter mobile) and pte-web (browser) task-type UI, timer display, result display, and multi-task progression.
- [ ] Phase 9: Integration Testing & Documentation — End-to-end exam attempt verification; regression tests on iam/tenancy/proctor/examdelivery; update architecture docs; archive APTIS-specific content.

## Research Summary

**Hard-mode research findings (from brainstorm/scouting session):**

1. **Architecture Decisions Baked In** (from codebase scouting, not re-derived here):
   - Task→skill scoring mapping is **config-driven**, not a DB join-table. PTE has exactly 20 fixed task types; each task type gets a static scoring-rubric config defining which skills it contributes to and their weights. Avoids DB schema churn and aligns with the fixed PTE taxonomy.
   - AI scoring uses **thin single-vendor wrappers per modality** (one for speech/fluency, one for essay). No generic multi-provider abstraction; only build that abstraction if a second vendor is actually added.
   - Async scoring pipeline: **no separate job-queue table**. Add `scoring_status` (PENDING/SCORED/FAILED) and `retry_count` columns directly on `AttemptAnswer`; a Spring `@Scheduled` poller picks up PENDING rows.
   - Scoring scale: PTE's official 10–90 (Overall + 4 communicative skills + 6 enabling skills). CEFR A1–C1 is fully replaced, not run in parallel.

2. **Deferred Decisions (Explicit Phase Tasks)**:
   - **AI vendor selection** — No vendor is yet chosen. Phase 3 includes a concrete research-spike task: evaluate OpenAI Whisper + GPT for speech/essay, or Pearson's own ASR API, or alternatives. Results must be documented and decision made before Phase 4/5 start.
   - **Per-task timing values** — Exact prep-time and response-time for all 20 task types are not yet sourced. Phase 2 includes a concrete data-sourcing task: consult official Pearson PTE public materials (timing is typically published) and enter values into versioned config. This task has a TODO gate: if values cannot be sourced, the timing-enforcement code is stubbed with placeholder comments, and the gate must be manually resolved before release.

3. **Codebase Reuse**:
   - `examdelivery` (state machine), `proctor` (audit/WebSocket), `iam`, `tenancy`, `storage`, `asset` are reused as-is. No changes to these modules are in scope; they are validated by scouting to be compatible with PTE structure.
   - `ScoringService` is an unimplemented skeleton — Phase 4 and 5 build this from scratch.
   - Frontend repos `pte-app` (Flutter mobile) and `pte-web` need new screens and task-type rendering logic (Phase 8) but no breaking changes to the auth/navigation layer.

4. **Docs Reuse**:
   - `pte-doc/projects/aptis-lms/` (~250KB) contains APTIS-era spec, SRS, glossary. Multi-tenant, licensing, and architecture sections are still valid and should remain; exam-structure and scoring sections must be rewritten in Phase 9.

## Dependencies

- **External vendor availability** for speech and essay scoring (selected in Phase 3). If selected vendors have API delays or quota issues, async retry logic (Phase 4/5) mitigates; fallback is manual scoring or test-mode mocks.
- **AI vendor budget (2026-07-16):** user has an existing API credential ("opencode" — to be provided when Phase 3 starts) they want considered as a candidate/default vendor, rather than a hard monthly budget cap. Phase 3's vendor research must evaluate this credential's underlying provider/capabilities (confirm it actually supports the needed speech fluency/pronunciation scoring AND/OR essay scoring — it may only cover one modality) before committing to it as the selected vendor; fall back to free-tier alternatives for whichever modality it doesn't cover.
- **Official Pearson PTE timing data** must be publicly available or sourced from public materials (Phase 2). If unavailable, timing-enforcement code becomes a stub with a TODO gate, delaying full release.
- **Multi-repo coordination**: pte-api (Phases 1–7), pte-app, pte-web (Phase 8), pte-doc (Phase 9). Teams working in parallel must synchronize schema changes and API contract updates.

## Risks

- **HIGH: Thesis Project Scope Risk** — This is a single-student or small-team thesis; the total phase count (9) and estimated effort (multi-repo backend redesign + dual-platform frontend + integration testing) implies a 4–8 month timeline depending on team size and AI vendor ramp-up. No explicit thesis deadline was provided; if the thesis is due sooner than this, risk is critical. *Mitigation:* Break into MVP (Phases 1–5: domain model + timing + speaking/writing scoring) and post-MVP (Phases 6–9) milestones; phase gate after Phase 5 to reassess deadline.

- **HIGH: AI Vendor Selection & Latency Uncertainty** — Speech and essay scoring APIs are external dependencies with unknown latency, cost, and quality at this stage. If the chosen vendor is slow (>10s per response), async queueing alone may not provide real-time exam-like feedback. *Mitigation:* Phase 3 research-spike must include latency testing on sample data. If latency is unacceptable, fallback to cached model responses or manual scoring for some task types.

- **HIGH: Per-Task Timing Data Sourcing** — Official PTE prep/response times for all 20 task types must be sourced from public Pearson materials. If Pearson's official timings are not publicly available, timing values must be estimated from publicly available sample exams (high risk of inaccuracy). *Mitigation:* Phase 2 includes a formal data-sourcing task with documented sources; if sources are insufficient, implement a TODO gate and defer to Phase 9 or a post-release patch.

- **HIGH: Frontend Complexity Across Two Repos** — Implementing task-type-specific UI for 20 task types across both pte-app (Flutter mobile) and pte-web (browser) is high-effort and high-risk for UI/UX consistency, accessibility, and timing enforcement. *Mitigation:* Phase 8 should start with a shared design system / component library spec (before coding); prioritize 4–5 high-frequency task types first (Read Aloud, Describe Image, Essay, Multiple Choice) for early testing, defer lower-frequency types to a post-MVP release or Phase 9b.

- **MEDIUM: Multi-Repo Coordination & Regression Risk** — Changes to `Question`, `Exam`, and `AttemptAnswer` schemas ripple across pte-api, pte-app, and pte-web. Risk of schema version mismatch, null-pointer exceptions in old code paths, and proctor/iam modules unexpectedly broken. *Mitigation:* End-to-end regression test suite in Phase 9; backward-compatibility layer (dual-field support during migration if needed); coordinate schema deployments as atomic cross-repo releases.

- **MEDIUM: AI Scoring Quality & Fairness** — Automated scoring for Speaking/Writing is sensitive to accent, speech quality, essay format, and rubric calibration. Poor AI scoring may disadvantage certain student populations (accessibility, EFL speakers). *Mitigation:* Phase 4/5 must include a human-review workflow (flag low-confidence scores); Phase 9 must include a comparative accuracy study (sample hand-scored answers vs. AI scores); document limitations in the exam disclaimer.

- **MEDIUM: Async Scoring Pipeline Completeness** — If the Spring `@Scheduled` poller fails to process all queued answers by the time a student requests their report (e.g., next-day report), scores may be incomplete (PENDING status). Affects report accuracy and student expectations. *Mitigation:* Phase 4/5 must guarantee retry logic with exponential backoff; Phase 7 score-aggregation logic must handle PENDING answers gracefully (substitute placeholder score or re-poll); document expected scoring latency (e.g., "typically <5 minutes, guaranteed <1 hour").

- **LOW: Reuse Assumption Validation** — Codebase scouting assumed `iam`, `tenancy`, `proctor`, `examdelivery` are compatible with PTE; a full domain-model pass in Phase 1 may uncover breaking assumptions (e.g., exam state machine doesn't support PTE's section structure). *Mitigation:* Phase 1 includes an explicit "compatibility audit" subtask; if breaking changes are found, escalate to plan review and re-sequence.

- **LOW: Documentation Debt** — APTIS-era docs are extensive (~250KB); superseding them with PTE docs while keeping architecture/multi-tenancy sections valid is error-prone. Risk of contradictory docs in the wild. *Mitigation:* Phase 9 includes doc audit and archival (move APTIS docs to `/legacy/`); version control; CI check for broken internal links.

### Findings from Plan Red-Team Review (2026-07-16, NOTED — not blocking, tracked here)

- **NOTED: Per-Task Timing Data Sourcing Escalation Path** — Phase 2's timing-data-sourcing task lacks an explicit escalation deadline/fallback if official Pearson values can't be located. *Recommendation:* if not sourced within a reasonable window during Phase 2, escalate to thesis advisor with evidence of sources searched, and fall back to estimated values from published PTE sample tests with a visible disclaimer in the exam UI rather than silently blocking.

- **NOTED: AI Vendor Tie-Breaking Criteria** — Phase 3's vendor selection doesn't define what breaks a tie if multiple candidates score similarly on accuracy/latency/cost. *Recommendation:* prefer, in order: (1) lowest cost per call, (2) lowest p99 latency, (3) documentation/SDK quality, (4) thesis advisor's recommendation. Apply during Phase 3 Step 4.

- **NOTED: Phase 8 Frontend MVP Boundary Within 20 Task Types** — Phase 8 covers all 20 task types across two platforms but doesn't sequence which types ship first. *Recommendation:* prioritize highest-frequency real-exam types first (Read Aloud, Repeat Sentence, Describe Image, Summarize Written Text, Essay Writing, Multiple Choice single/multiple, Fill in the Blanks) and treat the remainder (Re-tell Lecture, Answer Short Question, Re-order Paragraphs, Highlight Correct Summary, Select Missing Word, Highlight Incorrect Words, Write from Dictation) as a follow-on batch within Phase 8, not a separate phase.

- **NOTED: API Versioning & Backward-Compatibility Policy** — Schema/API changes in Phases 1, 4, 5 ripple to `pte-app`/`pte-web`; no explicit versioning policy is defined. *Recommendation:* treat `pte-api` changes as within a single pre-release version (no public API contract to preserve yet, per Phase 9's mandatory sequenced-deploy order) rather than building a formal deprecation/versioning scheme prematurely — revisit if the API gets external consumers post-thesis.

- **NOTED: Multi-Repo Integration Checkpoint Before Phase 9** — No explicit checkpoint ensures `pte-app`/`pte-web` are integrated against a live `pte-api` staging build before Phase 9 begins. *Recommendation:* add an informal checkpoint at the end of Phase 8: merge and smoke-test `pte-app`/`pte-web` against `pte-api` staging before declaring Phase 8 done, so Phase 9 doesn't discover contract breaks late.

- **NOTED: Task-Type Definitions in Config vs. Enum** — Already addressed as a Phase 1 Risk (LOW: Task-Type Enum Explosion) — Phase 1 Step 6 stores task-type definitions in config, not hard-coded enums. No further action needed; cross-referenced here per red-team review.

---

## Success Criteria (High-Level)

- A full mock exam attempt end-to-end: student selects exam → progresses through 20 PTE task types with correct per-task timers → submits Speaking/Writing responses (queued for scoring) → completes attempt → receives final report on 10–90 scale. Zero timeout, zero null-pointer exceptions.
- Speaking and Writing scores are populated by AI pipeline within 5 minutes of exam submission (or documented expected latency met); no PENDING scores in final report.
- Final score report displays Overall (10–90), 4 communicative skills (10–90 each), 6 enabling skills (10–90 each); no CEFR bands.
- Proctor actions (force-submit, extend-time, flag-violation) work unchanged on PTE attempts; `proctor` module tests pass without modification.
- `iam`, `tenancy`, `examdelivery` tests pass unchanged (zero regressions).

