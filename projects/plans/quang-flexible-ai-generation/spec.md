# Spec: Flexible AI question generation popup

**Date:** 2026-11-18
**Status:** Ready

---

## Problem Statement
Authors can only generate one task type per run (≤10 items, side drawer) or use a separate batch page, and daily quotas
block bulk work even though the AI model is free. Authors need one place to generate any mix — a full exam set, many
items of one task type, or several task types with different counts — without quota friction.

---

## User Stories

- **[P1]** As an author, I want the "Tạo bằng AI" button in the question editor to open a centered popup instead of a right drawer so that the larger form is easier to use.
  Accepted when: the popup uses `@pte/ui` `Modal` (`size="full"`), the right `Drawer` is no longer used by question generation, and Esc / Cancel / X close it.

- **[P1]** As an author, I want to pick skills, tick task types and set a count per ticked type so that I can generate any mix in one run.
  Accepted when: the popup lists the 4 skills, each with its task types (from `GET /question-generation/task-types`); each ticked type has a count input (≥1) and its own CEFR (default = shared CEFR) and optional topics; Describe Image shows image kind; a summary shows total items and estimated time.

- **[P1]** As an author, I want a "Full 1 đề" preset so that one click fills every task type with the count of the active exam template.
  Accepted when: the preset ticks every task type in the active template with count = `maxCount`; values remain editable afterwards. Presets per skill ("Cả Speaking", "Cả Writing", "Cả Reading", "Cả Listening") tick that skill's types the same way.

- **[P1]** As an author opening the popup from the editor of one task type, I want that type pre-ticked so that the old one-question flow still works.
  Accepted when: opening from `QuestionEditorView` pre-ticks the current task type with count 1; if the final selection is exactly 1 type × 1 item the popup submits the existing single job (`saveQuestions=false`, preview fills the form, as today); any larger selection submits a batch and navigates to the batch detail page.

- **[P1]** As an operator, I want quotas to be disable-able so that free-model deployments are not limited.
  Accepted when: value `0` means "unlimited" for `ITEMS_PER_USER_PER_DAY`, `ITEMS_PER_DAY`, `ITEMS_PER_BATCH` (platform setting and `QUESTION_GEN_*` env) and `CHAT_AI_DAILY_LIMIT`; defaults in this deployment are 0; the generation quota endpoint and the practice chat quota report "unlimited" and the UIs hide remaining-count notices and client-side quota checks when unlimited; setting a non-zero value restores today's behaviour.

- **[P2]** As an author, I want to choose "N đề" with the Full preset so that I can fill the bank for several exams at once.
  Accepted when: a multiplier 1–10 scales every preset count.

- **[P2]** As an author, I want the batch pages to stay reachable from the popup's success state and the sidebar.
  Accepted when: after submit the user lands on `/admin/questions/ai-batches/{id}`; the list page links "Tạo lô mới" to the same popup (standalone page `/ai-batches/new` removed or redirected).

- **[P3]** _(out of scope)_ Natural-language request → AI proposes rows; auto-assemble generated items into an exam/mock test; parallel execution of children.

---

## Functional Requirements

1. FR-01: `GenerationDrawer` is replaced by `GenerationDialog` built on `@pte/ui` `Modal size="full"`; steps reorganised into: shared settings (pool, default CEFR, topics), skill/task-type selection grid with per-type count/CEFR/topics/imageKind, presets, summary, actions.
2. FR-02: Selection maps to batch rows 1:1 (one row per ticked task type); a row count may exceed 10 (backend already splits rows into children of ≤10).
3. FR-03: Preset data comes from the active exam template; the API exposes it to platform authors (today `GET /exam-definitions/active` is `HOST_ADMIN` only → add an author-accessible read, e.g. `GET /question-generation/presets` returning `{taskType, section, maxCount}[]`).
4. FR-04: Quota "0 = unlimited": billing `QuestionGenerationLimit` min bound for the three item limits becomes 0; `QuestionGenerationProperties` `@Min(0)`; `checkCaps`, `BatchRequestValidator` skip a check whose limit is 0; batch cap 0 falls back to the hard safety cap only if one is kept (decide in plan; default: no cap). `GenerationQuotaResponse` gains `unlimited: boolean` (or `dailyLimit = 0` documented as unlimited).
5. FR-05: Chat: `ChatAiPropertiesValidator` accepts 0; `ChatQuotaService.consume` skips counting when limit = 0; snapshot exposes `unlimited`; pte-practice `ChatQuotaNotice` hides when unlimited.
6. FR-06: Single path preserved: exactly 1 type × 1 item from the editor → existing job endpoint with `saveQuestions=false`; everything else → batch endpoint.
7. FR-07: `QUESTION_GEN_BATCH_ENABLED` defaults to true where the popup ships (or the popup hides multi-select when the server returns `GENERATION_BATCH_DISABLED`).

---

## Non-Functional Requirements

- Performance: popup opens < 300 ms after task types/presets are cached; presets/task types fetched once per session (TanStack Query, staleTime ≥ 5 min).
- Security: unchanged role gates (`ACADEMIC_ROLES` for the popup; preset endpoint same roles as generation).
- Availability: full-exam batch (~70 items) runs sequentially; UI states the estimated duration (items × `estimatedSecondsPerItem`) before submit.
- Code: pte-api `CODING_STANDARDS_API.md`, pte-web `CODING_STANDARDS_WEB.md` (≤300 lines/file, ≤150 lines/component, constants/i18n, `@pte/ui` as shipped).

---

## Success Criteria

- [ ] "Full 1 đề" preset produces rows matching the active template's task types and `maxCount` exactly (unit test against fixture template).
- [ ] A selection of 2 task types with counts 10 and 20 submits one batch of 2 rows totalling 30 and completes on the local stack.
- [ ] With all limits = 0, a 70-item batch and 50 chat messages in one day are accepted (no `*_LIMIT_REACHED`).
- [ ] Setting `ITEMS_PER_USER_PER_DAY=5` again rejects a 6-item batch (regression).
- [ ] Opening from the editor and generating 1 item still fills the editor form (existing preview flow) — existing tests pass.
- [ ] No `Drawer` import remains in `features/questiongeneration`.

---

## Out of Scope

- Natural-language composition, auto-assembling exams from generated items, parallel children per batch.
- Changing the generation pipeline, prompts or the image provider (PICTURE stays behind `QUESTION_GEN_PICTURE_ENABLED`).
- Concurrency cap (`CONCURRENT_JOBS`) and `CALLS_PER_ITEM` stay as they are.

---

## Assumptions

- The model in use is free, so removing quotas has no cost impact; a paid model later re-enables limits via settings.
- One active exam template exists; if none, presets are disabled with a message.
- Sequential batches of ~70 items (≈1–1.5 h) are acceptable.
