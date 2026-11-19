# Brainstorm: Flexible AI question generation popup

**Date:** 2026-11-18

## Ideas Explored
- Multi-row table (current batch page) — flexible, but row-by-row entry is slow for a full exam.
- Presets ("Full 1 đề", per-skill) from the active exam template — fast, editable after applying.
- Skill grid with tick + count per task type — one screen covers single type, mixed counts, full exam. **Chosen (with presets).**
- Natural-language request → AI proposes rows — convenient but unpredictable; deferred.
- Generate and auto-assemble into an exam/mock test — rejected for now; items go to the bank only.
- Quota: delete quota code vs "0 = unlimited" — chose 0 = unlimited (re-enable when switching to a paid model).

## User's Direction
- Replace the right drawer with a centered popup on the question editor ("đưa thanh bên phải thành popup ở giữa").
- No quota for generation or the practice chat box ("tôi xài model free").
- Flexible composition: full exam, many of one type, several types with different counts.
- Picks: skill grid + tick + presets; "Full 1 đề" = active template `maxCount`; quota 0 = unlimited; from editor pre-tick current type, 1×1 keeps the preview flow, otherwise batch.

## Open Questions
- Keep a hard safety cap per batch when `ITEMS_PER_BATCH = 0` (e.g. 500) or none at all?
- Remove `/admin/questions/ai-batches/new` page or keep it as a wrapper around the popup?
- Default `QUESTION_GEN_BATCH_ENABLED=true` in all environments?

## Risks
- Full-exam batch runs ~1–1.5 h sequentially; a provider outage stops the whole batch (fatal-code rule).
- Exposing template counts to authors needs a new read endpoint (current `/exam-definitions/active` is HOST_ADMIN only).
- `GenerationDrawer` refactor touches the existing single-question preview flow — regression risk on the editor.
