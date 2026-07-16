# Spec: Pivot exam simulation platform from APTIS to PTE Academic

**Date:** 2026-07-16
**Status:** Draft

---

## Problem Statement

The platform (`pte-api`, `pte-app`, `pte-web`) was designed and partially built to simulate the APTIS exam. The thesis advisor now requires the project to simulate the **PTE Academic** exam instead — a structurally different format (multi-skill-per-task scoring, 20 official task types, AI-driven automated scoring, 10–90 point scale) — as a high-fidelity simulation, not a rebrand and not an MVP.

---

## User Stories

<!-- P1 = MVP (must ship), P2 = nice-to-have, P3 = future/out-of-scope -->

- **[P1]** As a student, I want to take a mock exam covering all 20 official PTE Academic task types (across Speaking & Writing, Reading, Listening) so that the experience matches the real test.
  Accepted when: an exam attempt can include questions from all 20 task types, each rendered with the correct interaction pattern (record audio, drag-reorder, click-to-select, type-in, etc.).

- **[P1]** As a student, I want each task timed exactly like the real PTE (individual prep-time and response-time limits per task type) so that my practice reflects real exam pressure.
  Accepted when: each of the 20 task types enforces its own prep/response timer values sourced from official PTE timing, not a shared section-level timer.

- **[P1]** As a student, I want my Speaking and Writing responses scored automatically by AI (fluency, pronunciation, grammar, essay quality) so that I get a real PTE-style score without waiting for a human grader.
  Accepted when: submitting a Speaking or Writing response triggers an automated scoring pipeline and returns enabling-skill sub-scores (e.g. Oral Fluency, Pronunciation, Written Discourse) plus a task score.

- **[P1]** As a student, I want my final report to show scores on the official PTE 10–90 scale (Overall + Listening/Reading/Speaking/Writing + enabling skills), so that the report matches a real PTE score report.
  Accepted when: attempt results display Overall, 4 communicative skill scores, and enabling skill scores, all in the 10–90 range, with no CEFR A1–C1 band shown.

- **[P1]** As a content admin (host/vendor), I want to author questions for each of the 20 PTE task types with the fields specific to that type (e.g. audio prompt + reference answer for Read Aloud, image + model response for Describe Image), so that the question bank supports real PTE content.
  Accepted when: the question authoring flow supports type-specific fields for all 20 task types and validates required fields per type before publishing.

- **[P2]** As a proctor, I want the existing force-submit/extend-time/flag-violation actions to work unchanged under the new exam structure, so proctoring doesn't need to be rebuilt.
  Accepted when: proctor actions apply correctly to attempts composed of PTE task types, reusing the existing `proctor` module without modification.

- **[P3]** _(out of scope for this pivot — noted for future)_ Adaptive difficulty / IRT-based question selection matching Pearson's real adaptive algorithm.

---

## Functional Requirements

<!-- Number each. Be specific. -->

1. FR-01: `Question` domain model supports all 20 PTE Academic task types (see Assumptions for the canonical list) with per-type structured fields (prompt media, reference answer/model response, rubric criteria).
2. FR-02: `Exam`/`ExamQuestion` model supports a task contributing scores to **multiple** communicative/enabling skills simultaneously (replacing the current one-skill-per-question `skill_subset_*` boolean model).
3. FR-03: Each task type has its own configurable prep-time and response-time limits, enforced independently during exam delivery (not a single section-level timer).
4. FR-04: Speaking responses (audio) are submitted to an automated scoring pipeline (ASR + fluency/pronunciation model) and return enabling-skill sub-scores.
5. FR-05: Writing responses (essay, summarize-written-text) are submitted to an automated essay-scoring pipeline and return enabling-skill sub-scores (Grammar, Vocabulary, Written Discourse, Spelling).
6. FR-06: Reading/Listening objective task types (multiple choice, fill-in-blank, re-order, highlight, select-missing-word, write-from-dictation) are scored deterministically/rule-based (no AI needed).
7. FR-07: Score aggregation computes Overall (10–90), 4 communicative skills (10–90 each), and enabling skills (10–90 each) per the official PTE scoring model.
8. FR-08: `examdelivery` attempt state machine, `proctor` audit/broadcast, `iam`, `tenancy`, `storage`, `asset` modules are reused without structural change.
9. FR-09: Existing APTIS-specific content (question types, glossary, SRS functional requirements FR-09–FR-28 in `aptis-lms`) is superseded by new PTE-specific specs, not incrementally patched.

---

## Non-Functional Requirements

<!-- Use numbers, not adjectives. -->

- Performance: AI scoring is **asynchronous** — submitting a Speaking/Writing response advances the student to the next task immediately (matches real PTE behavior of not blocking mid-exam); scoring is queued and processed in the background, with retry on transient failure, and results are available once the full attempt is submitted.
- Security: multi-tenant isolation for question banks and AI scoring results must follow existing `tenancy` module patterns (no new requirement beyond current system).
- Availability: AI scoring dependency (external API) must degrade gracefully — attempt submission should not fail if scoring pipeline is temporarily unavailable (queue + retry, not a hard block).

---

## Success Criteria

<!-- Measurable outcomes. Each must be independently verifiable. -->

- [ ] Question bank supports authoring for all 20 PTE task types: 20/20 types have a working creation form + validation.
- [ ] A full mock exam attempt can be completed end-to-end covering Speaking & Writing, Reading, and Listening sections with correct per-task timers.
- [ ] Speaking and Writing responses are queued for AI scoring on submit without blocking progression to the next task; scored results are available by the time the attempt's final report is generated.
- [ ] Final score report displays Overall + 4 skills + enabling skills on the 10–90 scale, matching official PTE score report structure.
- [ ] Zero regressions in `iam`, `tenancy`, `proctor`, `examdelivery` attempt lifecycle (existing test suites for these modules still pass unchanged).

---

## Out of Scope

- Adaptive/IRT-based question selection (real Pearson algorithm is proprietary and not required for a thesis simulation).
- Official Pearson score equivalence certification/validation — this is a simulation, not a certified scoring engine.
- Dual scoring scale (CEFR A1–C1 shown alongside PTE 10–90) — explicitly decided against; PTE 10–90 only.

---

## Assumptions

- **Corrected during Phase 1 Step 1a verification (2026-07-16):** Personal Introduction is **not** one of the scored item types — it's an unscored warm-up recording, tracked separately.
- **Corrected again (2026-07-16, during Phase 7 research):** Pearson updated PTE Academic on 2025-08-07, adding 2 new item types (**Respond to a Situation**, **Summarize Group Discussion** — both Speaking, purely additive, no existing item type changed). The canonical count is now **22 scored item types**, not 20. Full list: Read Aloud, Repeat Sentence, Describe Image, Re-tell Lecture, Answer Short Question, Respond to a Situation, Summarize Group Discussion (Speaking, 7), Summarize Written Text, Write Essay (Writing, 2), Multiple Choice Reading Single Answer, Multiple Choice Reading Multiple Answer, Re-order Paragraphs, Fill in the Blanks (Reading), Fill in the Blanks (Reading & Writing) (Reading, 5), Summarize Spoken Text, Multiple Choice Listening Single Answer, Multiple Choice Listening Multiple Answer, Fill in the Blanks (Listening), Highlight Correct Summary, Select Missing Word, Highlight Incorrect Words, Write from Dictation (Listening, 8) = 22. Plus Personal Introduction (unscored, 23rd task overall in an attempt). Pearson also added human-review-on-top-of-AI for 7 tasks prone to memorized/scripted answers (Describe Image, Respond to a Situation, Summarize Group Discussion, Summarize Written Text, Re-tell Lecture, Write Essay, Summarize Spoken Text) — relevant to Phase 3/4/5's AI scoring design (may need a human-review fallback path, not just AI-only). See `PteTaskType.java` in `phase-01-contract-draft.md` for the implemented enum. Sources: [Pearson PTE changes 2025](https://www.pearsonpte.com/articles/pte-changes-2025-everything-you-need-to-know/), [PTE Academic Institution Score Guide, July 2025](https://www.pearsonpte.com/content/dam/ELL/pte/pearsonpte/pdfs/Score-Guide-Institution-PTE-Academic-July-2025-web.pdf).
- `iam`, `tenancy`, `storage`, `asset`, `proctor`, and the `examdelivery` attempt state machine require no structural changes — validated by codebase scouting in the brainstorm session, not yet confirmed against a full PTE requirement pass.
- An external AI/ASR vendor will be used for speech and essay scoring rather than a self-hosted model — if the user wants self-hosted/offline scoring, NFR-Performance and cost assumptions change substantially.

---

## Resolved During Planning (2026-07-16)

- AI scoring latency: **async/queued**, decided — see NFR-Performance and FR-04/FR-05.
- AI scoring vendor/model selection: deferred to a dedicated research-spike phase in the implementation plan (not a spec blocker — architecture will use a provider-abstraction so the vendor choice doesn't gate other phases).
- Exact per-task prep-time/response-time values for all 20 task types: deferred to a data-sourcing task in the plan (official Pearson PTE materials → versioned config), not a design decision.
