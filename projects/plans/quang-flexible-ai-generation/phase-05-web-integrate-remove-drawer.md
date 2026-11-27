# Phase 5: Integrate dialog, remove drawer and standalone create page

## Scope change (user, during implementation)
The batch **list** page `/admin/questions/ai-batches`, `BatchListView`, `/ai-batches/new` and the sidebar entry are **removed**, not redirected. The popup in the question editor is the only entry point; the batch **detail** page stays (its back link and the "already running" fallback go to the question bank `/admin/questions`). `origin: batchList` and the list hook/messages/tests are removed. Steps and rows below that mention the list or `?create=1` are superseded.

## Goal
Editor and batch list open `GenerationDialog`; dirty-form confirm wired; `/ai-batches/new` redirects; drawer + batch-create
code deleted; retained tests moved to `tests/unit`.

## Stories covered
P1 editor entry; P2 batch pages reachable (FR-01, FR-06); U1, U3.

## Files
Change
- `pte-web/apps/vendor-web/features/questionbank/components/QuestionEditorView.tsx` (~:44–49) — `<GenerationDialog origin="editor" currentTaskType={taskType} isEditorDirty={form.formState.isDirty} onSingleJobCreated=…/>`; single job keeps navigation to `generationLiveHref`
- `pte-web/apps/vendor-web/features/batchgeneration/components/BatchListView.tsx` — "Tạo lô mới" opens dialog `origin="batchList"`; `?create=1` opens on load
- `pte-web/apps/vendor-web/app/**/admin/questions/ai-batches/new/page.tsx` — `redirect('/admin/questions/ai-batches?create=1')`
- `pte-web/apps/vendor-web/features/batchgeneration/components/index.ts` — drop `BatchCreateView`; sidebar link if it targets `/new`

Delete
- `features/questiongeneration/components/GenerationDrawer.tsx`, `_GenerationDrawer*Step.tsx` (hardcoded English strings go with them, L3)
- `features/batchgeneration/components/BatchCreateView.tsx`, `_BatchRowFields.tsx` (if unused), `useBatchForm` hook

Test migration (H8; verified current files)
| From | To | Action |
|---|---|---|
| `features/questiongeneration/__tests__/formValidation.test.ts` | `tests/unit/features/questiongeneration/formValidation.test.ts` | keep if `formValidation` still used by dialog, else fold cases into `generationSelection.test.ts` and delete |
| `features/questiongeneration/__tests__/api.test.ts` | `tests/unit/features/questiongeneration/api.test.ts` | move; add presets query cases |
| `features/questiongeneration/__tests__/ReviewPanel.test.ts` | `tests/unit/features/questiongeneration/ReviewPanel.test.ts` | move unchanged |
| `features/questiongeneration/__tests__/failureCodeTranslator.test.ts` | `tests/unit/features/questiongeneration/failureCodeTranslator.test.ts` | move; add `GENERATION_JOB_ALREADY_RUNNING`, `GENERATION_BATCH_DISABLED` |
| `tests/unit/features/batchgeneration/batchForm.test.ts` | same | keep while `batchForm` utils are reused; drop cases for deleted form-only helpers |
| `useBatchForm` tests (if any, find with Glob) | `generationSelection.test.ts` | migrate assertions, then delete |

## Steps
1. Grep imports of `GenerationDrawer`, `BatchCreateView`, `useBatchForm`, `_BatchRowFields`.
2. Migrate tests first (table), then swap usages and delete files; remove empty `__tests__` dir.
3. `grep -r "Drawer" features/questiongeneration` → none; lint, typecheck, test, build.

## Design Constraints
- Preflight: user added scope mid-run — remove the batch list screen, its route, /new and the sidebar entry; keep batch detail; popup in the question editor is the only entry point.
- Same `ACADEMIC_ROLES` gates on entry buttons; no dead exports; components ≤ 150 lines.

## Quality and Testing State
- quality: skipped_by_user; decision: user_confirmed_skip [quality: skipped_by_user; decision: user_confirmed_skip]
- testing: passed — vendor-web 94 files / 703 tests, tsc clean, scoped eslint 0 errors; generationEntryPoints.test.ts (no Drawer/__tests__, list+new routes gone, detail kept, dirty check)

## Tests
- `QuestionEditorView` test: opens dialog with type pre-ticked; existing preview-fill tests pass (**regression**); dirty form + batch → confirm.
- `BatchListView` test: button and `?create=1` open dialog with origin batchList.
- Redirect test or smoke.

## Acceptance criteria
- No `Drawer` import in `features/questiongeneration`; no `__tests__` left there; `/ai-batches/new` redirects; single preview unchanged.

## Risks
- Coverage loss → migrate before delete.
- Editor dirty state source differs (react-hook-form vs custom) → confirm at implementation.
