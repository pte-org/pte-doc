# Phase 1: Data-Driven Full-Exam Seed Runner

## Requirements

Add a dev-only authoring seed runner and classpath fixture that create one
valid question for each of the 23 task types, compose them in a single ordered
blueprint, and publish through the existing snapshot path. Keep the existing
Reading-only profile unchanged.

## Steps

1. Add a JSON fixture containing all 23 task types and realistic generic demo
   prompts/answers/options, including the required audio/image placeholder
   references and word-count bounds.
2. Implement `FullExamTaskSeedRunner` under the `seed-full-exam` profile. Load
   the fixture with the repository's Jackson 3 `JsonMapper`, map records to
   `Question`/`QuestionOption`, validate each question, persist it, build the
   blueprint in fixture order, and publish it with the platform seed caller.
3. Add unit coverage for exact 23-type coverage, required-field validity,
   section/order mapping, and idempotent skip behavior.
4. Run the authoring reactor tests and record quality/test evidence.

## Design Constraints

- Reuse `PteTaskType` flags and `QuestionValidationHelper`; do not duplicate
  task-type validation rules in the fixture runner.
- Use `Visibility.SHARED` with a platform author seed caller, matching the
  existing Reading seed convention.
- Keep all generated content clearly marked as demo seed content.
- Do not call media, scheduling, scoring, or external AI services.

## Success Criteria

- The profile is opt-in and idempotent.
- All 23 questions pass validation and are saved exactly once on a fresh run.
- The published blueprint has 23 items covering all task types.
- The test suite passes with no failures or skips.

## Quality and Testing State

- Quality gate: approved; no blocker/high/current-change medium findings.
- Testing: passed; authoring reactor tests pass.
