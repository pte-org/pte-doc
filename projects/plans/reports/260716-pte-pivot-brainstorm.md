# Brainstorm: Pivot from APTIS to PTE exam simulation

**Date:** 2026-07-16

## Ideas Explored

- **Full architectural rewrite** — considered and rejected. Scouting `pte-api` and `pte-doc` showed the infra layer (iam, tenancy, storage, asset, exam attempt state machine, proctor audit trail) is exam-format-agnostic and does not need to change for PTE.
- **Rebrand-only (string/enum swap)** — explicitly rejected by teacher/advisor and by the user. APTIS separates skills into distinct blocks; PTE integrates skills within tasks (a single task like Read Aloud scores Speaking + Reading + Pronunciation + Fluency simultaneously). The current `Exam` entity's `skill_subset_*` boolean model assumes one skill per question — structurally incompatible with PTE's multi-skill-per-task scoring.
- **MVP subset of PTE task types** — user rejected. Decided to target the full 20 official PTE Academic task types instead of a representative subset.
- **Manual/rubric-based scoring first, AI later** — user rejected. Decided to integrate real AI scoring (speech-to-text + fluency/pronunciation model for Speaking, essay-scoring model for Writing) from the start rather than deferring to a later phase.
- **Dual scoring scale (keep CEFR A1–C1 alongside PTE 10–90)** — considered, user chose the simpler single-scale option instead.
- **Section-level timing (coarse, per Reading/Listening/Speaking&Writing block)** — considered, user rejected in favor of exact per-task timing replication (matching real PTE's per-task prep/response second limits).

## User's Direction

Build a high-fidelity PTE Academic simulation, not an MVP:
- All 20 official PTE task types (Speaking & Writing: Personal Introduction, Read Aloud, Repeat Sentence, Describe Image, Re-tell Lecture, Answer Short Question, Summarize Written Text, Essay Writing; Reading: Multiple Choice Single/Multiple Answer, Re-order Paragraphs, Fill in the Blanks (Reading), Fill in the Blanks (R&W); Listening: Summarize Spoken Text, Multiple Choice Single/Multiple, Fill in the Blanks (Listening), Highlight Correct Summary, Select Missing Word, Highlight Incorrect Words, Write from Dictation).
- Real AI-driven automated scoring for Speaking and Writing tasks (not manual/rubric placeholder).
- Official PTE 10–90 scoring scale (Overall + 4 communicative skills + enabling skills: Grammar, Oral Fluency, Pronunciation, Spelling, Vocabulary, Written Discourse) — replacing the APTIS-era CEFR A1–C1 scale, not running both in parallel.
- Exact per-task timing replication (individual prep-time / response-time limits per task type, not just section-level caps).

Reusable infra confirmed by scouting (not questioned by user): `iam`, `tenancy`, `storage`, `asset`, exam attempt lifecycle state machine, `proctor` audit/broadcast.

## Open Questions

- `/ck:plan` must design the `Exam`/`Question` schema change from single-skill-per-question to multi-skill-per-task scoring — this is the one true architectural change, not just new enum values.
- AI scoring vendor/model choice for speech (fluency/pronunciation) and essay scoring is unresolved — needs a research spike (candidates: Azure Speech Services, a hosted ASR + custom fluency scoring pipeline, LLM-based essay scoring) before implementation, including cost-per-attempt estimation.
- Per-task timing config (20 tasks × prep/response seconds) needs to be sourced from official Pearson PTE documentation and stored as versioned config data — exact values not yet compiled in this session.
- Whether `DifficultyLevel` (currently CEFR-based) is removed entirely or kept as a secondary internal tag now that scoring is 10–90 — not decided, flagged in spec.

## Risks

- **AI scoring accuracy/cost**: real-time or near-real-time speech fluency/pronunciation scoring is the highest-risk, highest-effort component of this pivot — likely the critical path for the whole project given the "as real as possible" bar.
- **Scope size**: 20 task types × full question-bank content + AI scoring + exact timing is substantially larger than the original APTIS MVP scope; this is a thesis/đồ án project, so timeline risk against the advisor's deadline should be checked in `/ck:plan`.
- **Data availability**: exact PTE per-task timing and scoring-scale conversion tables are not yet sourced into the repo — needs to be gathered as a pre-planning research task, not assumed.
