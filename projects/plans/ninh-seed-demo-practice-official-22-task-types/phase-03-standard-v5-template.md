# Phase 3: Standard V5 template activation

**Goal:** An ACTIVE 22-item template matching the pasted APEUni PTE Score Table V5.

## Tasks

1. Query `GET /api/v1/score-templates`; find `PTE_Score_Template` ("APEUni PTE Score Table V5", `STANDARD_PTE`, currently `RETIRED`).
2. Find out why it is `RETIRED` (migration default vs side effect of activating `PTE_LOCAL_TEMPLATE`) before touching it; if activating another template retires the standard one, document the one-active-template rule and which flow must use which.
3. Clone (`POST /score-templates/{id}/clone`) → verify the 22 items against the table (prep/answer seconds, 4 skill weight columns, F2: each sums to 100) → `PUT .../items` to cap `minCount`/`maxCount` at 3 for the types whose table max exceeds 3 (RA, RS, DI, ASQ, R-FIBDD, R-FIBDND, WFD) → `POST .../activate`. Confirm in the preflight/generate step that the template count never exceeds the 3 questions available, and whether `minCount` or `maxCount` drives the number picked.
3a. If cloning the standard template cannot be edited (STANDARD_PTE items may be read-only), create a `CUSTOM` template instead with the same 22 rows (needs `TASK_TYPES_CUSTOM_*` flags, already on in `.env.local`).
4. Keep `PTE_LOCAL_TEMPLATE` untouched (used by the earlier 2-task seed) unless Phase 4 shows the two cannot both be ACTIVE.

## Design Constraints

- Do not hardcode weights in the script; the table is the source of truth and the template data is validated server-side by `ScoreTemplateActivationValidator`. The script only asserts the post-activation shape (22 keys, weights sum).
- Task-type custom flags (`TASK_TYPES_CUSTOM_*`) must not be required for the standard template path; if they are, record why.
- Idempotent: if an ACTIVE standard template with 22 items exists, do nothing.

## Success Criteria

- `select count(*) from score_template_items` = 22 for the ACTIVE standard template; activation returns 200; weights per skill = 100.

## Quality and Testing State

- Quality gate: not evaluated
- Testing: not started
