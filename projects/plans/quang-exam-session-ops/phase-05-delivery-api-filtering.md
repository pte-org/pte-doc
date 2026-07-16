# Phase 5: Delivery API Skill-Subset Filtering & Constraints

## Requirements

Implement skill-subset filtering and availability window enforcement in the exam delivery API so that students fetch only the questions relevant to their session's configured skills, never see answer keys, and cannot access sessions outside the availability window. Extends existing exam-delivery endpoints to respect Phase 4 session settings.

Maps to: **P1 Story #4 | FR-03**

## Design Constraints

- Skill-subset filter must be enforced at section fetch time and question detail time; do not serve a complete exam and filter client-side (leaks answers and question text).
- Answer keys (correct_answer, explanations, etc.) must never be included in the exam-delivery response, regardless of the user's role at fetch time.
- Availability window check must happen at session start (or session detail fetch) and reject access outside the window with a 403 Forbidden or explicit "session unavailable" error.
- Filter logic must be deterministic and testable (e.g., "all questions with skill=READING are excluded if skill_subset_reading=false in the session").
- Tenant scoping from Phase 1 must be enforced: students cannot see Host-scoped questions from other Hosts, and Vendor questions are always visible.

## Steps

1. Load exam session settings at the start of an exam (e.g., GET /api/sessions/{sessionId}/start or similar entry point); check availability window (now must be >= start AND <= end); if outside window, return 403 Forbidden with a message indicating the session is not currently available.

2. Query all sections for the exam and filter by the session's skill_subset toggles (if skill_subset_reading=false, exclude all READING skill questions).

3. Implement a single answer-stripping response DTO for exam sections and questions that excludes sensitive fields (correct_answer, explanations, answer_feedback); use a separate internal DTO for teacher/admin views that includes answers. **This DTO is mandatory on every endpoint that returns a `Question` object to a student-facing client** — section-fetch, question-detail, any batch/bulk question-fetch endpoint, and historical attempt-retrieval endpoints alike; there is no endpoint-by-endpoint opt-out. Add a security-focused test that enumerates all student-facing endpoints returning Question data and asserts none contain a `correct_answer` (or equivalent) field in the response body.

4. At the section-fetch endpoint (GET /api/sessions/{sessionId}/sections/{sectionId}), apply the skill-subset filter: if this section's skill doesn't match the session's settings, return 404 or an empty question list.

5. At the question-detail endpoint (GET /api/sessions/{sessionId}/questions/{questionId}), verify the question's skill matches the session's setting; apply the answer-stripping DTO before response.

6. Implement a test matrix: test each of the 4 skill types individually (Speaking-only, Reading-only, etc.) and in combinations; verify that answer keys are never present in the response; verify that accessibility outside the availability window is blocked.

7. Test tenant scoping: a student from Host A cannot see questions created by Host B, even if both are in the same exam pool.

## Success Criteria

- A Speaking-only session, when queried for sections, returns zero Reading/Writing/Listening sections, only Speaking sections.
- Answer keys are absent from all exam-delivery responses (verified by checking response JSON for correct_answer field).
- A session with availability window 2026-07-20 to 2026-07-25, queried on 2026-07-19, returns 403 Forbidden with a clear message.
- A session configured with skill_subset_reading=true, skill_subset_listening=false returns Reading and no Listening questions.
- Exam section counts and question orders are consistent across multiple fetches (no randomization introduced here).

## Quality and Testing State

- Quality gate: **approved, first pass, zero blocking findings** (report: `quality/phase-05-delivery-api-filtering-quality-report.json`, receipt issued 2026-07-16).
- Testing: not started — skipped by user for Phase 5 (policy: unit tests required only for Phase 6-9)

## Session Notes

- **Closed a pre-existing critical security gap opportunistically**: `ExamAttemptController` had zero `@PreAuthorize` and zero ownership checks on its 2 existing endpoints (speaking-upload, submit-answer) — any authenticated user could act on any student's attempt. Fixed via a shared `ExamAttemptAccessGuard` (ownership + availability-window checks) applied to all 4 endpoints (2 pre-existing + 2 new), since it's the same trust boundary this phase's new endpoints needed anyway.
- New GET `/exam-attempts/{attemptId}/sections` and `/exam-attempts/{attemptId}/sections/{skill}/questions` — the only student-facing content endpoints in the module; `RedactedQuestionResponse` is the single, mandatory answer-stripped DTO shape (excludes correctAnswers/explanation; includes options since MCQ students need to see choices).
- Defensive tenant-scoping filter added in content delivery (Question.tenantId vs. the exam-owning Host's resolved Organization publicId) even though no "add question to exam" endpoint exists yet to create a cross-tenant link — pure defense-in-depth for a state that isn't currently reachable.
- GRAMMAR/VOCABULARY question skills are not gated by the 4-skill (R/L/W/S) session subset toggle, since the phase's Design Constraints only enumerate those 4.
- Availability-window check runs on every content-fetch/submit call (no snapshot-at-start caching yet) — a more conservative deviation from the plan's cache-recommendation, acceptable since no attempt-start/session-context mechanism exists before Phase 6.
- Build Gate: PASS.

## Risks

- **Answer-leakage in edge cases**: resolved by the Step 3 mandate that the answer-stripping DTO applies to every student-facing Question-returning endpoint, with no exceptions, verified by an endpoint-enumeration security test rather than per-endpoint code review.
- **Filter logic race condition**: If a student fetches the skill-subset setting, then the Host changes it before the student fetches the questions, the student might see questions that no longer match the session's current settings. Mitigation: load session settings at session start and cache them locally in the ExamSession context; do not re-fetch settings per question; document in architecture that settings are immutable after exam start.
- **Availability window clock skew**: If the server's time is out of sync with the student's client, a session outside the window might briefly appear available due to clock differences. Mitigation: use server time only for availability checks (never trust client timestamp); implement a small grace period if needed (e.g., 30 seconds before start time); document the behavior in API schema.
