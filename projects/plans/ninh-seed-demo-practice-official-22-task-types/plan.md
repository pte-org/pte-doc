# Plan: Seed demo data for PRACTICE and OFFICIAL exam flows (22 task types)

**Date:** 2026-10-06
**Task:** #58 — Seed data demo 2 luồng thi PRACTICE và OFFICIAL dành cho 22 dạng đề
**Status:** Implemented (all 5 phases); see "Implementation outcome and corrections". Not committed.
**Mode:** Hard (multi-file, 5 phases, security-adjacent: proctor/STRICT policy)
**Scope:** `pte-api/scripts` (new seed script) + data under `pte-doc/data/question-import`; no Java/API change planned.

## Goal

After one command on a fresh local stack (`pte-api` docker compose), a developer can:

1. Log in as a host and see an `OPEN` **PRACTICE** exam and an `OPEN` **OFFICIAL_EXAM** exam,
   both generated from the APEUni PTE Score Table V5 template (all 22 scored task types).
2. Log in as the seeded student and start an attempt in each flow from `pte-app`.
3. Re-run the command any number of times without duplicates (idempotent).

## Scope Challenge

```
# Scope Challenge:
#   Exists?     → PARTIAL. Reusable today:
#                 - scripts/seed-local-template-and-question-bank.ps1 + seed-local-exam-ready.ps1
#                   (API-driven, idempotent, but only READ_ALOUD + MC_READING_SINGLE, PRACTICE only)
#                 - pte-doc/data/question-import: 17 of 22 types as APPROVED/SHARED SQL seed
#                   (local-question-seed.sql 14,840 questions / local-question-seed-150.sql subset)
#                 - pte-doc/projects/fixtures/question-media: 34 local wav/png files incl. DI, SGD, SST
#                 - Standard template "APEUni PTE Score Table V5" (22 items, STANDARD_PTE) already in DB, RETIRED
#   Minimum?    → one new idempotent script that (a) loads a small curated question set for all 22 types,
#                 (b) clones+activates the V5 template, (c) creates 1 PRACTICE + 1 OFFICIAL session.
#   Complexity? → Hard — 5 phases, 4 modules touched (itembank, media, scoretemplate, session/attempt)
#
# Mode: Hard
# Test:  default (no --tdd; acceptance is a scripted end-to-end check, see Phase 5)
```

No brainstorm report exists; the request is concrete enough (22 types x 2 flows) to proceed.

## Key findings that shape the plan

| # | Finding | Evidence | Consequence |
|---|---|---|---|
| F1 | The 22 rows of the pasted table map 1:1 to `PteTaskType` minus `PERSONAL_INTRODUCTION` (unscored) | `PteTaskType.java`, `ScoreTemplateActivationValidator.REQUIRED_TASK_TYPES` | Template must contain exactly these 22 keys |
| F2 | The pasted weights already satisfy the validator: Speaking, Writing, Reading, Listening each sum to exactly 100 | Hand-summed from the table | Reuse V5 template; no weight edits |
| F3 | The V5 STANDARD_PTE template (22 items) exists locally with status `RETIRED` | `score_templates` query | Phase 3 = clone RETIRED → DRAFT → activate, not author 22 rows |
| F4 | Approved question seed covers 17 types; missing: `DESCRIBE_IMAGE` (no image URL), `SUMMARIZE_GROUP_DISCUSSION` (no source file), `SUMMARIZE_SPOKEN_TEXT`, `FILL_IN_THE_BLANKS_TYPE_IN`, `HIGHLIGHT_INCORRECT_WORDS` (prompt/answer/word-count missing) | `local-question-seed-manifest.json`, `manifest.json` | 5 types need hand-authored content (Phase 1/2) |
| F5 | 13 task types require an audio prompt, `DESCRIBE_IMAGE` requires an image; both are `UUID` refs to `media_objects` | `PteTaskType`, `CreateQuestionRequest` | Media strategy is the main design decision (Open Q1) |
| F6 | `OFFICIAL_EXAM` forces `LockdownMode.STRICT`, `proctorRequired=true`, replay limit 1, STRICT answer integrity; `PRACTICE` forces lockdown `NONE`, unlimited replay. Both default `deviceCheckRequired=true` | `ExamPolicy`, `SessionPolicyResolver` | OFFICIAL needs proctor assignment; both flows need `deviceCheckConfirmed=true` |
| F7 | Enum value is `OFFICIAL_EXAM` (not `OFFICIAL`). `CreateSessionRequest` javadoc still says `MOCK_TEST` (stale) | `ExamMode.java` | Script must send `OFFICIAL_EXAM` |
| F8 | The earlier `seed-local-exam-ready.ps1` run got HTTP 409 on `POST /attempts` with `deviceCheckConfirmed=false`; the likely cause is F6's device check (not yet confirmed) | Session policy defaults | Confirm in Phase 5; if true, existing script needs `deviceCheckConfirmed=true` |
| F9 | Generation likely needs at least the template item's count of distinct published questions per type (to be confirmed in Phase 3) | Template item min/max counts | **Decision (user): 3 questions per type = 66 questions.** Table maxima above 3 (RA 7, RS 12, DI 6, ASQ 6, R-FIBDD 6, R-FIBDND 5, WFD 4) cannot be met, so the demo template caps `maxCount` (and `minCount`) at 3 for those types |

## Phases

- [x] [Phase 1: Content audit and gap fill](phase-01-content-audit-and-gap-fill.md) [quality: audited inline (ck:quality --audit), findings fixed; testing: passed (node --test, 10/10)]
- [x] [Phase 2: Media and question bank load](phase-02-media-and-question-bank.md) [quality: audited inline, findings fixed; testing: passed (seed run twice, row counts stable)]
- [x] [Phase 3: Standard V5 template activation](phase-03-standard-v5-template.md) [quality: audited inline; testing: passed (activate, rerun no-op, weight sums 100)]
- [x] [Phase 4: PRACTICE and OFFICIAL sessions](phase-04-practice-and-official-sessions.md) [quality: audited inline, findings fixed; testing: passed (6 exams OPEN, rerun idempotent)]
- [x] [Phase 5: End-to-end verification and docs](phase-05-verification-and-docs.md) [quality: audited inline; testing: passed, including a run on an empty database]

Dependencies: 1 → 2 → 3 → 4 → 5 (3 only needs 2 for the "enough questions" preflight, not for cloning).

## Implementation outcome and corrections (2026-10-06)

Delivered in one folder, `pte-api/scripts/demo22/` (not committed by the assistant), so it can be deleted as a unit: `seed-demo22.ps1` (one command), `seed-demo22-questions.ps1`, `seed-demo22-template.ps1`, `seed-demo22-sessions.ps1`, `verify-demo22.ps1`, `bootstrap-local-admin.ps1`, `lib/`, `tools/` and `data/`; README section "Demo data: 22 task types". Paths mentioned elsewhere in this plan (`scripts/seed-data/...`, `scripts/tools/...`, `scripts/lib/...`) were written before the move and now live under `scripts/demo22/`.

Corrections to the findings above, discovered while building:

- **F2/F3 were wrong:** the local `PTE_Score_Table`/V5 template is an older table (Speaking weights sum to 101, different Overall). The pasted Official Release table is new, so Phase 3 creates `DEMO22_V5` from `score-table-v5.json` (STANDARD_PTE) instead of reusing the old one. Overall is computed by the API as the average of the 4 skills and matches the pasted column.
- **Personal Introduction:** STANDARD_PTE generation adds an implicit Personal Introduction (unscored) at the start of Speaking, so the bank has 1 extra question (67 total, 23 types).
- **Media:** nothing was taken from `pte.netlify.app`. The repo fixtures are 80 KB / 602 byte placeholders, so Fill in the Blanks (Type In), Highlight Incorrect Words, Summarize Group Discussion audio and the Describe Image charts are self-generated (Windows TTS + Pillow) and uploaded to the user's Cloudinary (`pte/demo22`, public): 9 audio + 3 images. Summarize Spoken Text uses the existing CloudFront audio with word bounds 50-70.
- **SQL instead of API for questions:** the question API only accepts `audio/wav` media, the bank's audio is mp3, so the seed is idempotent SQL (same approach as `local-question-seed.sql`), executed through the Postgres container. Speaking prep timing needs `media_objects.duration_seconds`; external mp3 durations are per-type approximations.
- **R1 resolved:** for public (`UPLOAD`) media the backend returns `secure_url` unchanged, so external links and the user's Cloudinary links play regardless of the local Cloudinary credentials; verified through attempt tasks (audio/image urls present for every audio/image type).
- **Re-order Paragraphs:** the question bank's `orderIndex` is the display order; the API needs it to be the correct position, so the builder recomputes it from `correctAnswerText`. (`local-question-seed*.sql` appears to carry display order; not changed here.)
- **One subscription per exam:** exams sharing a subscription cannot overlap in time, so each of the 6 exams has its own exam package.
- **F8 confirmed:** `POST /attempts` returns 409 with `deviceCheckConfirmed=false` on these exams (they require the device check); with `true` it succeeds.
- **Windows PowerShell 5.1 encoding bug** found by the quality audit: typographic quotes were turned into `?` when piping SQL to `docker exec`; fixed by explicit UTF-8.
- **Clean-database run done (2026-10-06):** after `docker compose down -v` and `up -d`, a single `seed-demo22.ps1` created the admin, 67 questions, the template and 6 OPEN exams, and verification passed. A run on a different physical machine was not done.
- **Not done:** the app's real renderers for all 22 types were not exercised (preflight used a full manifest).

## Decisions from validation (2026-10-06)

- **Bank:** 3 questions per task type = 66 questions.
- **Media (revised again 2026-10-06, user-approved):** self-host. The files selected from `pte.netlify.app` (and the local SGD fixtures) are **downloaded and uploaded to the user's own free Cloudinary account** (credentials already in `.env.local`), folder `pte/demo22`. The user explicitly approved the download and upload. Internal class demo only. Sources are listed in "Media sources" below.
- **Portable seed file:** all 66 questions plus their media URLs are committed as one data file (`pte-api/scripts/seed-data/demo22-questions.json`) so a teammate on another machine runs one script with no Cloudinary credentials: the script registers `media_objects` rows from the file's public `secure_url`s (no upload needed on their side). Hence uploads must use **public delivery** (not `authenticated`), otherwise other machines cannot play the audio. Phase 2 spike must still confirm the backend serves an externally registered `secure_url` (R1).
- **PRACTICE:** both shapes — one full 22-type session **and** four skill-scoped sessions (Speaking, Writing, Reading, Listening) = 5 PRACTICE sessions.
- **OFFICIAL:** real proctor — create a `PROCTOR` account and a proctor assignment on the OFFICIAL session; keep `proctorRequired=true`, lockdown `STRICT`. Phase 4 must first find the valid role/endpoint (R5).

## Media sources

Audio is required by 13 task types (39 audio) and an image by 1 (`DESCRIBE_IMAGE`, 3 images); 8 types need no media.

| Task type(s) | Source | Notes |
|---|---|---|
| 12 audio types already in the approved seed (RS, RL, ASQ, RTS, MC Listening Single/Multiple, HCS, SMW, WFD …) | CloudFront URLs in `pte-doc/data/question-import` (`local-question-seed*.sql`) | Unchanged; no new work |
| Summarize Spoken Text, Fill in the Blanks (Type In) | `https://pte.netlify.app/` (study site; sections "Summarize Spoken Text", "Listen Fill In The Blanks") — audio `<source>` URLs and transcripts read from the page DOM | Transcript on the page is the `promptText`/correct answer; URLs are Firebase signed URLs (`Expires=2524582800`, year 2050) |
| Describe Image | `https://pte.netlify.app/speaking/describe-image` — 3 image URLs | Same site |
| Highlight Incorrect Words | Derived: a site audio that has a transcript (e.g. Repeat Sentence); `promptText` = transcript with 3-5 words altered, correct answer = the altered words | Authored in Phase 1 |
| Summarize Group Discussion | The 2 local fixtures in `pte-doc/projects/fixtures/question-media` + 1 CloudFront/other URL | Site has no group-discussion audio |

URLs are read from the page DOM; the selected files (about 12 audio + 3 images + the SGD fixtures) are then downloaded to a scratch folder, uploaded to `pte/demo22`, and the resulting Cloudinary `secure_url`/`public_id`/duration are written into the seed file. The 12 CloudFront-backed types keep their existing external URLs (not site-owned). The site credits PTE Helper as the original source and is a personal study site, so the files are acceptable only for this internal class demo and the Cloudinary links must not be shared publicly (R8).

## Open Questions (answers change Phase 2 and 4)

1. ~~**Media source**~~ — **Resolved:** external URLs (CloudFront data + `pte.netlify.app`); see "Media sources".
2. ~~**Bank size**~~ — **Resolved by user: 3 questions per task type (66 total).** Consequence: the demo template differs from the V5 table in question counts only (capped at 3); weights and timings stay as in the table. Alternative if exact V5 counts are wanted later: raise the bank to the table maxima (≈ 120 questions).
3. ~~**PRACTICE shape**~~ — **Resolved:** both (1 full + 4 skill-scoped).
4. ~~**OFFICIAL proctor**~~ — **Resolved:** real `PROCTOR` account + assignment.

No open questions remain; Phase 4 still has the research item "find the valid proctor role/endpoint".

## Risks

- **R1 (high)** External audio URLs: if the backend preview/presign path rejects non-Cloudinary `secure_url`, audio tasks will not play. Phase 2 must verify playback end-to-end before bulk load.
- **R2 (high)** Direct SQL insert bypasses `QuestionValidationHelper`, audit rows and outbox events. Mitigation: prefer API for questions; if SQL is used, add a post-load validation query and verify generation accepts the rows.
- **R3 (medium)** Session window: license/subscription is 30 days, the older script opened the exam for only 2 hours. Demo sessions must be re-creatable by re-running the script and should close near the subscription expiry.
- **R4 (medium)** `pte-app` may not implement renderers for all 22 screens; capability preflight would then mark tasks unsupported. Phase 5 records which types the app can actually start (informational, not a seed failure).
- **R5 (medium)** No `PROCTOR` role appears in local data; the role/endpoint for proctor accounts is unverified (Open Q4).
- **R6 (low)** Secrets: the script reads `PTE_*` env vars (already in `.env.local`) and must never write passwords/tokens/license codes to disk.
- **R8 (medium)** Copied third-party content: the files come from `pte.netlify.app` (copied from PTE Helper, not licensed) and will be hosted publicly on the user's personal free Cloudinary account (confirmed 2026-10-06), so the risks are ToS takedown/suspension of that account and anyone with the link being able to play the files. Mitigation: dedicated folder `pte/demo22` (not `pte/authoring`), upload only files in the selection, public delivery is required for the portable seed (so no `authenticated`), do not publish the seed file or links outside the class, delete the folder after the demo. The seed file keeps the source URL beside each Cloudinary URL for traceability.
- **R9 (low)** Teammate's machine: media registration needs only the seed file and a running stack; if the Cloudinary links are removed, the seed must fail with a clear message listing the broken URLs (HEAD check before insert).
- **R7 (low)** Existing `quang-full-exam-seed-content` plan targets the retired microservice layout (`services/authoring`); do not reuse its Java runner.

## Success Criteria

- `scripts/seed-demo-22-task-types.ps1` exits 0 on a fresh DB and on a second consecutive run (no duplicate rows: question titles, template, sessions, accounts).
- DB check: 22 distinct `pte_task_type` values, each with exactly 3 `DEMO22` published questions (66 total).
- Demo template ACTIVE with 22 items, `maxCount <= 3`; skill weight sums = 100/100/100/100.
- Two sessions `OPEN`: one `PRACTICE` (lockdown NONE), one `OFFICIAL_EXAM` (lockdown STRICT); each generated form contains all 22 task types.
- Student `POST /attempts/preflight` returns `canStart=true` for both sessions; `POST /attempts` succeeds for both (with `deviceCheckConfirmed=true`).
- On a clean machine with only the repo, `.env.local` and the running stack (no Cloudinary credentials needed), the same script seeds the full demo from `scripts/seed-data/demo22-questions.json`.
- README section documents the one-command flow, accounts (names only), and reset steps.

## Quality and Testing State

- Quality gate: not evaluated
- Testing: not started

## Handoff

```
Ready to cook:
/ck:cook --hard plans/ninh-seed-demo-practice-official-22-task-types/plan.md
```
