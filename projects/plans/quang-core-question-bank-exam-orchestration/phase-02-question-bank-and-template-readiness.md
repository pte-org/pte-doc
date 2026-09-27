# Phase 2: Question bank and template readiness

## Goal

Make the global approved question pool and template catalog safe inputs for
host-generated exams. Preserve revision immutability and add the minimum slot
metadata required for preflight and deterministic selection.

## Steps

1. Audit `PteTaskType`, persisted question-type catalog and section mapping.
   Ensure inactive task types cannot be added to new questions or template
   slots, while existing snapshots remain readable.
2. Extend the question-pool read facade to expose grouped availability by slot
   constraints without leaking answer content. The initial constraints are
   task type, section, approved/current revision, required media and optional
   difficulty/tag metadata only if those fields are truly persisted.
3. Define `ScoreTemplateItem` slot fields for required/min/max counts, sequence,
   section, and pool policy. Keep draft editing flexible; perform complete
   validation at submit/activation.
4. Add a template feasibility/preflight contract returning every invalid or
   undersupplied slot, not only the first failure. A template cannot activate
   if a slot references an inactive/unknown type or violates section rules.
5. Implement author draft/submit permissions only after the role decision in
   Phase 1. Platform admin remains the sole activation/publish authority.
6. Ensure clone-to-draft is the only way to structurally change active/retired
   templates. Pin template version at exam publish.
7. Add compatibility mapping from current score-template fields to the target
   conceptual exam-template contract; do not create a parallel template table.

## Backend locations

- `app/src/main/java/com/pte/itembank/ItembankService.java`
- `app/src/main/java/com/pte/itembank/domain/Question.java`
- `app/src/main/java/com/pte/itembank/domain/enums/QuestionStatus.java`
- `app/src/main/java/com/pte/itembank/internal/controller/QuestionController.java`
- `app/src/main/java/com/pte/itembank/internal/controller/QuestionTypeController.java`
- `app/src/main/java/com/pte/scoretemplate/ScoreTemplateService.java`
- `app/src/main/java/com/pte/scoretemplate/domain/ScoreTemplate.java`
- `app/src/main/java/com/pte/scoretemplate/domain/ScoreTemplateItem.java`
- `app/src/main/java/com/pte/scoretemplate/internal/controller/ScoreTemplateController.java`
- owning `AssessmentConstants`, `ItembankConstants`, and score-template constants.

## Web locations

- `apps/vendor-web/features/questionbank/`
- `apps/vendor-web/features/scoretemplate/`
- `packages/api-client/src/requests/question/`
- `packages/api-client/src/requests/scoretemplate/`
- `packages/api-client/src/types/`

## Design Constraints

- A question used in a published snapshot is never updated in place; create a
  revision and preserve the old revision for audit.
- A template used by a scheduled/open/closed exam is immutable. Admin changes
  require clone/activate and affect only future exams.
- Generation reads approved/current/shared questions through `ItembankService`,
  never an item-bank repository from assessment/session code.
- Do not invent difficulty/tag values in the API if the current database has no
  source of truth; return “not configured” rather than fake filters.
- Validation must aggregate all slot failures and use stable detail keys so FE
  can render friendly messages without parsing prose.
- TSX must call feature constants for buttons, alerts and confirmation text.

## Quality and Testing State

- Unit-test expansion: enabled per the latest user instruction; template
  approval, catalog validation, deterministic feasibility and security tests
  were added or updated.
- Quality gate: mandatory and approved; report and receipt are stored under
  `quality/phase-02-question-bank-and-template-readiness-*`.
- Testing: passed; the final regression evidence is recorded in
  `tests/phase-08-verification-test-report.json`.
- Required checks during cook: backend compile, API-client typecheck, vendor
  lint/build/typecheck, migration validation, manual role matrix and a seeded
  feasibility walkthrough with both sufficient and insufficient pools.

## Exit criteria

- A published template exposes enough immutable slot data for generation.
- Platform author cannot activate; platform admin can activate; host can only
  read eligible active templates.
- Feasibility returns all shortages and no answer-bearing question content.
