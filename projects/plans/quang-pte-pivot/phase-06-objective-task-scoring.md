# Phase 6: Objective Task Scoring (Reading/Listening)

## Requirements

Implement synchronous rule-based scoring for objective Reading and Listening tasks (multiple-choice single/multiple answer, fill-in-blank, re-order paragraphs, highlight correct summary, select-missing-word, write-from-dictation). These tasks have deterministic correct answers known at question-creation time; scoring must happen immediately on submit (no AI vendor, no async queue) so students receive instant feedback during the exam. Scores must be stored on `AttemptAnswer` and integrated into the unified report alongside Speaking (Phase 4) and Writing (Phase 5) scores.

This phase is low-risk and high-value: it unblocks score aggregation (Phase 7) by ensuring all task types (Speaking, Writing, Reading, Listening) have scored results.

## Design Constraints

- Objective-task scoring is **synchronous and deterministic** — result is fully determined at submission time and returned immediately (latency <100ms). No queuing, no vendor dependency, no async retry. This constraint is non-negotiable for student UX (students expect immediate feedback on objective tasks).
- Scoring logic must be **stored on the question**, not hard-coded in the scoring service. Each question of type multiple-choice defines the correct answer(s); the scoring service simply checks student's answer against the definition.
- Fuzzy-matching for fill-in-blank answers must be configurable per question (e.g., accept exact match only, or accept Levenshtein distance ≤2, or accept any answer containing certain substrings). Default is case-insensitive with whitespace stripped, but question authors must be able to override.
- Scoring results must be deterministic across retries and must not depend on time, random state, or external factors. If the same question is graded twice, the score must be identical.
- Results are stored as a simple 0–1 (correct/incorrect) binary score plus metadata (correct_answer, student_answer, rule_fired, confidence) for audit and explanation to students.

## Steps

1. Design the scoring data schema for objective questions: extend the `Question` entity to include `correct_answer` field for single-answer questions (multiple-choice, fill-in-blank), or `correct_answers` list for multi-answer questions (multiple-choice multiple-answer, re-order paragraphs, highlight). For re-order tasks, `correct_answer` is a list of item IDs in correct order. For fuzzy-match tasks, include `matching_rules` (e.g., { "caseSensitive": false, "stripWhitespace": true, "levenshteinThreshold": 2 }).

2. Implement a `ObjectiveTaskScoringService` in Spring: expose a method `scoreObjectiveAnswer(question, studentAnswer) → ObjectiveScoreResult { score (0–1), explanation, auditDetails }`. This service is injected into the exam-delivery handler (when a task is submitted).

3. Implement scoring rules per task type:
   - **Multiple-choice single-answer**: check if student's selected option ID equals `question.correctAnswer`.
   - **Multiple-choice multiple-answer**: check if student's set of selected option IDs equals `question.correctAnswers` (set comparison, order-independent).
   - **Fill-in-blank**: apply fuzzy-match logic (case-insensitive, strip whitespace, optional Levenshtein threshold) to check if student's text matches `question.correctAnswer`.
   - **Re-order paragraphs**: check if student's reordered list equals `question.correctAnswers` (order-dependent list comparison).
   - **Highlight correct summary**: check if student highlighted the correct summary option ID.
   - **Select-missing-word**: student selects the missing word; check if selection matches `question.correctAnswer`.
   - **Write-from-dictation**: student types text from audio; apply strict or fuzzy match to check against `question.correctAnswer` (likely fuzzy with high threshold, e.g., ≤3 Levenshtein distance).

4. In the submission handler (exam-delivery module), add a decision point: when a task is submitted, check `task.questionType`. If it's objective (any of the 6 types above), invoke `ObjectiveTaskScoringService.scoreObjectiveAnswer()` immediately. Store result with `scoring_status = SCORED`, `objective_score = 0 or 1`, `objective_correct_answer = question.correctAnswer`, `objective_student_answer = submitted_answer`, `objective_audit = { rule_fired, confidence, explanation }`.

5. Implement a confidence/explanation system: for each score, generate a human-readable explanation (e.g., "You selected option B. The correct answer was option C." or "Your typed answer 'Hello world' did not match the correct answer 'Hello, world' (1 punctuation difference). Correct answer requires exact punctuation." This explanation is shown to the student on report.

6. Create unit tests for each scoring rule type: test single-answer multiple-choice (correct and incorrect cases), test multi-answer (correct, partially correct, incorrect), test fill-in-blank with and without fuzzy-match, test re-order (correct and scrambled orders), test that scoring is deterministic (same input → same score).

7. Create integration tests: submit an objective task via the exam-delivery API, verify it's scored immediately with `scoring_status = SCORED`, verify the score and explanation are correct, verify the score appears in the exam report without waiting.

8. Implement a backfill/audit feature: ability for admins to re-score all objective tasks in an exam (useful if a question's correct answer is corrected after the exam). Re-scoring updates only the `objective_score` and related fields; it doesn't modify student responses or timestamps.

## Success Criteria

- All 6 objective task types have working rule-based scoring rules implemented and tested: multiple-choice (single/multiple), fill-in-blank, re-order, highlight, select-missing-word.
- Objective task submission is scored synchronously: latency <100ms from submission to SCORED status.
- Scoring is deterministic: identical student answers to the same question always produce identical scores.
- Objective scores are correctly merged into the exam report alongside Speaking and Writing scores (via the unified reporting API).
- Fuzzy-match rules for fill-in-blank and write-from-dictation are configurable per question; default rules are documented.
- All existing `examdelivery`, `proctor`, `examoperations` tests pass unchanged (objective scoring is additive).
- Exam reports correctly display objective scores with explanations (e.g., "Correct: You selected option B.").

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started (Unit tests for each scoring rule, integration tests with exam-delivery API, end-to-end test with sample objective questions; regression tests on existing modules in Phase 9)

## Risks

- **MEDIUM: Fuzzy-Matching False Positives** — Fuzzy-match rules for fill-in-blank may incorrectly accept wrong answers (e.g., Levenshtein distance 2 accepts "world" for "word"). Students may receive credit for incorrect answers. *Mitigation:* Question authors must calibrate matching rules carefully; default rules should be conservative (exact match or very tight fuzzy); implement a manual review workflow for low-confidence scores or allow question authors to flag answers for human review.

- **MEDIUM: Write-from-Dictation Complexity** — Scoring spoken-English responses transcribed by the student (write-from-dictation) requires handling accent variations, typos, punctuation. A single fuzzy-match rule may be insufficient. *Mitigation:* This task type can use a hybrid approach: vendor ASR (from Phase 4 speech-scoring) to auto-transcribe the audio, then compare transcription to student's typed text; or implement a more sophisticated NLP-based matching. If too complex, mark write-from-dictation as requiring manual scoring or hybrid approach in Phase 8/9.

- **MEDIUM: Question Author Confusion** — Extending questions with `correct_answer` fields requires question authors to provide correct answers at creation time. If not provided, questions will have null/missing values, and scoring will fail. *Mitigation:* Make correct_answer fields mandatory during question validation (Phase 1); provide clear UI guidance for question authors in Phase 8.

- **LOW: Scoring Logic Bugs** — Rule-based scoring logic may have edge-case bugs (e.g., off-by-one in list comparison, incorrect set membership check). *Mitigation:* Comprehensive unit tests (Phase 9); consider property-based testing for comparison logic (generate random student answers and correct answers, verify scoring is consistent).

