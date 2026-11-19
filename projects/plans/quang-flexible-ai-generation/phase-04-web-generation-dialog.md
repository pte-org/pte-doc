# Phase 4: GenerationDialog (vendor-web)

## Goal
`GenerationDialog` on `@pte/ui` `Modal size="full"`: shared settings, skill/task-type grid with per-type
count/CEFR/topics/imageKind, presets (Full 1 đề ×N, per skill), summary (total, ETA, quota), submit single or batch per U1.

## Stories covered
P1 popup, grid, presets, editor flow (FR-01, FR-02, FR-06); P2 multiplier.

## Files (under `pte-web/apps/vendor-web/features/questiongeneration/`)
Create
- `components/GenerationDialog.tsx` — props `open, onClose, origin: 'editor' | 'batchList', currentTaskType?, isEditorDirty?, onSingleJobCreated?` (≤ 150 lines)
- `components/_GenerationDialogSharedSettings.tsx` (pool, default CEFR, topics)
- `components/_GenerationDialogSkillGrid.tsx`, `components/_GenerationDialogTaskTypeRow.tsx` (tick, count ≥ 1, CEFR, topics, imageKind for Describe Image)
- `components/_GenerationDialogPresets.tsx` (Full ×N 1–10; Cả Speaking/Writing/Reading/Listening; hidden when presets query fails 403/404 or is empty)
- `components/_GenerationDialogSummary.tsx` (total, ETA = items × `estimatedSecondsPerItem`, `remaining` + scope shown only when not unlimited)
- `components/_GenerationDialogFooter.tsx` (sticky footer: Cancel / Submit; L2)
- `components/_GenerationDialogNotices.tsx` (batch disabled; job already running + link to batch; preset over cap)
- `hooks/useGenerationSelection.ts`
- `utils/generationSelection.ts` — pure:
  - `applyPreset(selection, presets, kind, multiplier, maxItemsPerBatch)` → `{ok, selection} | {ok:false, reason:'OVER_CAP', total}` (H5, no silent clamp)
  - `toBatchRows(selection)` 1:1
  - `resolveSubmitMode(selection, origin, currentTaskType)` → `'single' | 'batch'` (U1)
  - `validateSelection(selection, quota)` — each count ≥ 1, total ≤ `quota.maxItemsPerBatch`, total ≤ `quota.remaining` when not unlimited (H2/H3)
  - `estimateSeconds(selection, taskTypes)`
- `constants/generationDialog.ts` (i18n keys, multiplier bounds 1–10, staleTime)

Change
- `api.ts` — `usePresetsQuery` (staleTime ≥ 5 min, `retry: false`, 403/404 → treated as "no presets"); reuse task-types/quota/job hooks; batch-create mutation from `features/batchgeneration/api.ts`

## Steps
1. TDD pure utils (tests below).
2. Selection hook (immutable updates; pre-tick `currentTaskType` count 1 when origin editor).
3. Sub-components, then composition. Modal: Esc/Cancel/X close; **dismiss disabled while submitting** (L2).
4. Submit:
   - `single` → job mutation `saveQuestions=false` → `onSingleJobCreated(job)` (caller keeps today's live/preview path).
   - `batch` → if `origin==='editor' && isEditorDirty` → confirm dialog (`@pte/ui` confirm) → create batch → `router.push` batch detail.
5. Errors: `GENERATION_BATCH_DISABLED` → disable multi-select + notice; `GENERATION_JOB_ALREADY_RUNNING` → notice with link to the open batch (from error details, else batch list filtered to open) (H6); `*_LIMIT_REACHED` → message with server `remaining`.

## Design Constraints
- Preflight: vendor-web vitest runs in node env (renderToStaticMarkup, no DOM) → dialog behaviour tested through pure utils + rendered sub-components; batch-list origin dropped (user request, see phase 5).
- Components ≤ 150, files ≤ 300 lines; no `Drawer`; `Modal` as shipped (body scrolls, sticky footer via layout inside body).
- All copy via constants/i18n — no hardcoded English (L3); no hardcoded colors.
- Server state only via TanStack Query hooks; selection state local; FE never computes `dailyLimit - usedToday`.
- No per-row 10 cap (backend splits).

## Quality and Testing State
- quality: skipped_by_user; decision: user_confirmed_skip [quality: skipped_by_user; decision: user_confirmed_skip]
- testing: passed — generationSelection.test.ts (U1 modes, presets incl. over-cap, validate cap/remaining/unlimited, 10+20 → 1 batch/2 rows/30, single job saveQuestions=false), generationDialogParts.test.tsx (pre-tick, unlimited hides quota, presets hidden, running-batch link/fallback, notice mapping)

## Tests (`tests/unit/features/questiongeneration/`)
- `generationSelection.test.ts`:
  - `resolveSubmitMode`: editor + 1×1 same type → single; editor + 1×1 other type → batch; editor + 1×2 / 2×1 → batch; batchList + 1×1 → batch.
  - Full preset = fixture template; ×3 scales; per-skill preset; Full×10 over cap (e.g. 70×10 > 500) → `OVER_CAP` with total; within cap ok.
  - `validateSelection`: total 500 ok, 501 rejected (cap from quota); remaining 5 → 6 rejected; unlimited → only cap applies.
  - `toBatchRows` 1:1; ETA.
- `GenerationDialog.test.tsx`: pre-ticked type; unlimited hides quota; 2 types (10, 20) → one batch payload, 2 rows, total 30; dirty editor + batch → confirm shown; `GENERATION_JOB_ALREADY_RUNNING` → notice with link; presets 403 → presets hidden; submit in flight → Esc ignored.
- **Regression**: editor 1×1 same type → job endpoint with `saveQuestions=false`.

## Acceptance criteria
- Spec P1/P2 popup criteria met; U1 rules hold; existing single-generation tests green.

## Risks
- Dense grid in max-w-5xl → collapsible skill sections.
- Template types unknown to `/task-types` → ignored, warned in summary.
