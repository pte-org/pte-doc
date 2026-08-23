# Phase 7: Score Aggregation & PTE 10–90 Reporting

## Requirements

Implement score aggregation logic that synthesizes individual task scores (Speaking sub-scores from Phase 4, Writing sub-scores from Phase 5, objective task scores from Phase 6) into official PTE Academic final scores: Overall (10–90), 4 communicative skills (Listening, Reading, Speaking, Writing — each 10–90), and 6 enabling skills (Grammar, Oral Fluency, Pronunciation, Spelling, Vocabulary, Written Discourse — each 10–90). Replace APTIS-era CEFR band reporting entirely with PTE 10–90 scale. This phase delivers the final exam report that students and admins see.

This phase directly addresses P1 user story: "I want my final report to show scores on the official PTE 10–90 scale (Overall + Listening/Reading/Speaking/Writing + enabling skills)."

## Design Constraints

- The PTE 10–90 scoring model is the **sole reporting scale** — CEFR bands (A1–C1) are removed entirely, never shown alongside PTE scores. No dual-scale reporting.
- Score aggregation logic must be **deterministic and reproducible** — the same exam attempt always produces identical final scores. No random rounding, no time-dependent calculations.
- Score aggregation must handle **incomplete scoring gracefully**. **Decision locked:** use partial aggregation — compute scores from all `SCORED` answers, and for any `PENDING`/`FAILED` answers, show a clear "pending"/"unavailable" label on that task rather than blocking the whole report. The report includes a banner: "This report includes results only for evaluated answers. Scores for tasks still being evaluated will appear once processing completes." This is non-negotiable for this phase — it directly follows from the async-scoring design constraint established in Phases 4–5 (submission never blocks on scoring, so reports must tolerate incomplete scoring too).
- The aggregation algorithm must be **versioned and configurable** — PTE may update their scoring rubric in the future; the algorithm should be stored as a versioned config (not hard-coded) so future versions can be applied without code changes.
- Scores must be **rounded consistently** — PTE uses specific rounding rules (e.g., round half-up to integer). The rounding logic must be centralized and documented.
- **Every endpoint that returns exam attempt data** (`getExamReport`, `getAttemptDetails`, any score-listing endpoint) must enforce authorization: (1) caller is authenticated via the existing `iam` module, (2) caller's tenant matches the attempt's tenant (existing `tenancy` pattern), (3) caller is either the student who owns the attempt or an admin/proctor in that tenant. This is not optional and must be implemented alongside the endpoints in this phase, not left to Phase 9's audit to discover.

## Steps

1. Research and document the official PTE Academic scoring model: consult Pearson's public documentation on how overall and communicative-skill scores are derived from task scores. Create a reference document (in pte-doc) that explains:
   - Which task types contribute to which communicative skills (e.g., Listening tasks contribute to Listening score; Speaking and Writing tasks contribute to Speaking and Writing scores).
   - How enabling-skill scores are computed from individual task sub-scores (e.g., Oral Fluency from multiple Speaking tasks).
   - The weight/contribution of each task to each skill.
   - How Overall score is computed from the 4 communicative skills (likely equal weight, or per-spec rubric).

2. Design the score aggregation schema in code: create a PTE scoring rubric (JSON or YAML versioned config) that defines:
   - `taskType → skillsContributedTo[]`: mapping of task types to skills they score.
   - `skill → taskTypes[], weights[]`: mapping of skills to the tasks that feed them.
   - `enablingSkill → sourceScores[]`: mapping of enabling skills (e.g., Oral Fluency) to the sub-scores that feed them (e.g., Fluency scores from Read Aloud, Repeat Sentence).
   - Rounding rules (e.g., "Round to nearest integer, half-up").

3. Implement the `ScoreAggregationService` in Spring: expose a method `aggregateExamScores(examAttempt) → PteScoreReport`. This method:
   - Fetches all `AttemptAnswer` rows for the attempt, with their scores (Speaking sub-scores, Writing sub-scores, objective scores).
   - For each communicative skill, computes the skill score by averaging or weighted-averaging the contributing task scores.
   - For each enabling skill, computes the score similarly.
   - Computes Overall score from communicative skills (likely equal weight).
   - Applies rounding rules.
   - Returns a `PteScoreReport` object with all scores.

4. Implement partial aggregation (the locked decision from Design Constraints): compute scores using only `SCORED` answers; for `PENDING`/`FAILED` answers, include a placeholder entry with status and no numeric score. Surface a report-level `scoringComplete: boolean` flag and the banner text so the frontend (Phase 8) can render the "still processing" notice consistently.

5. Implement score caching: the final score report may be requested multiple times. Cache the `PteScoreReport` result (keyed by examAttempt ID) so repeated requests don't re-compute. **Cache invalidation is explicit, not implicit**: `SpeechScoringPoller` and `WritingScoringPoller` (Phases 4–5) call `scoreCache.invalidate(attemptId)` immediately after writing a score update for any answer belonging to that attempt; additionally set a TTL (e.g., 5 minutes) as a backstop so a missed invalidation self-heals. Log every invalidation (attemptId, trigger source) for audit.

6. Implement the `ExamReportService`: expose a method `getExamReport(examAttemptId, callerUser) → ExamReport` that first checks authorization (caller is the owning student, or an admin/proctor in the attempt's tenant — reject with 403 otherwise), then calls score aggregation and formats the report for display. The report includes:
   - Exam metadata (student name, exam date, status).
   - Individual task results (task type, score, explanation).
   - Communicative-skill scores (Listening, Reading, Speaking, Writing).
   - Enabling-skill scores (Grammar, Oral Fluency, Pronunciation, Spelling, Vocabulary, Written Discourse).
   - Overall score.
   - Scoring completion status (if any answers are PENDING, note that).

7. Create unit tests: test score aggregation with sample data (e.g., 10 tasks with known scores, verify aggregation matches hand-calculated expected scores). Test rounding logic. Test handling of PENDING scores. Test that enabling-skill scores are computed correctly from sub-scores. Test cache invalidation (including the poller-triggered invalidation path). Test authorization: a student requesting another student's report gets 403; a cross-tenant admin request gets 403; the owning student and same-tenant admin succeed.

8. Create integration tests: submit an end-to-end exam attempt (mock multiple Speaking, Writing, and objective tasks), wait for async scoring to complete, fetch the exam report, verify all scores are present and correct.

## Success Criteria

- Official PTE Academic scoring model is documented in pte-doc (reference document with weights, skill mappings, rounding rules).
- Score aggregation is implemented and tested: a sample exam with 22 tasks and known scores produces the correct Overall, communicative-skill, and enabling-skill scores.
- Exam report displays only the 10–90 scale (Overall, 4 communicative skills, 6 enabling skills); no CEFR bands.
- Incomplete scoring is handled gracefully: partial aggregation is implemented — reports with PENDING/FAILED answers show clear per-task labels and a report-level "still processing" banner, never a blocked/exception response.
- Score caching works: repeated requests for the same exam report have <10ms latency (after first request); cache is correctly invalidated within one poller cycle of a score update.
- Report endpoints reject unauthorized access: cross-student and cross-tenant report requests return 403; verified by tests.
- All existing `examdelivery`, `proctor`, `examoperations` tests pass unchanged (zero regressions).

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started (Unit tests for aggregation, rounding, enabling-skill computation; integration tests with end-to-end exam attempts; validation against hand-calculated scores; Phase 9 regression tests)

## Risks

- **HIGH: PTE Scoring Model Misalignment** — If the official PTE scoring model cannot be sourced (Pearson keeps it proprietary), this phase cannot be completed accurately. Estimated scoring based on partial information may be incorrect. *Mitigation:* Phase 1 requirements audit (or Phase 7 early research task) must consult Pearson's public candidate guide and published score reports. If official model is unavailable, document assumptions (e.g., "Estimated based on published score examples") and flag for thesis advisor review/validation.

- **HIGH: Enabling-Skill Score Derivation Uncertainty** — How enabling skills (e.g., Oral Fluency, Grammar) are derived from individual task scores is not specified in the spec. If PTE's official model is unavailable, reverse-engineering from score reports may be inaccurate. *Mitigation:* Phase 7 research task must include this as a key question. If official derivation is unavailable, implement a reasonable model (e.g., Oral Fluency is the average of fluency sub-scores from all Speaking tasks) and document clearly; mark for advisor sign-off.

- **MEDIUM: Score Incompleteness UX** — Partial aggregation (locked decision, see Design Constraints) means students may see a report with some tasks still labeled "pending" and no single moment where the report is "final." *Mitigation:* Clearly communicate expected scoring latency to students (e.g., "Scores typically available within 5 minutes, check your dashboard"); Phase 8 frontend must poll or refresh the report until `scoringComplete: true`.

- **MEDIUM: Rounding Edge Cases** — Different rounding strategies (round half-up, banker's rounding, truncate) produce different results on edge cases (e.g., 49.5). Must match PTE's official rounding to be accurate. *Mitigation:* Phase 7 research task includes "what is PTE's official rounding rule?". If unavailable, implement "round half-up" (most common) and document assumption.

- **LOW: Cache Invalidation Complexity** — Cache must be invalidated when new scores arrive (e.g., Writing vendor finishes scoring). If cache invalidation logic is wrong, stale scores may be shown. *Mitigation:* Implement cache invalidation tests; log every cache invalidation event for audit.

