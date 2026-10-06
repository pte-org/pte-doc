# Phase 2: Media and question bank load

**Goal:** All selected questions exist as `PUBLISHED`/shared rows with working audio/image references.

## Tasks

1. **Spike (first, 30 min):** pick 1 audio question with an external CloudFront URL and 1 with a local fixture; wire each as `media_objects` and check `GET /api/v1/objects/{id}/preview-url` and the attempt task payload return a playable URL. Outcome decides Open Q1 and risk R1.
2. Implement media loading with the **external URL path**: insert `media_objects` rows (same deterministic UUID policy as `local-question-seed.sql`) for the URLs in the Phase 1 selection file. If the spike fails (R1/R8), switch to the **self-host path** only with the user's explicit approval: download the referenced files, then `POST /api/v1/objects` → upload to Cloudinary → `POST /api/v1/objects/{id}/complete`.
3. Create questions through `POST /api/v1/questions` (reuse `Ensure-PublishedQuestion` pattern from `seed-local-template-and-question-bank.ps1`) so validation, audit and events run; look up by title for idempotence; publish/unarchive as in the existing script.
4. If bulk volume makes the API too slow, fall back to a trimmed SQL (derived from `local-question-seed-150.sql`) plus a verification query; record that choice in the plan (risk R2).
5. Verify bank: `select pte_task_type, count(*) from questions where title like 'DEMO22%' and status in ('APPROVED','PUBLISHED') group by 1` shows 22 rows of exactly 3. With 66 questions the API path is fast enough; the SQL fallback in task 4 is unlikely to be needed.

## Design Constraints

- Admin token only (PLATFORM_ADMIN); credentials from `PTE_ADMIN_USERNAME` / `PTE_ADMIN_PASSWORD`, never written to disk.
- No Cloudinary upload and no file download by default; both only on explicit user approval (self-host fallback).
- Script must be safe to re-run: no duplicate titles, no duplicate `media_objects`.
- Keep each script file under ~300 lines; split helpers into `scripts/lib/seed-common.ps1` if needed rather than copying the helper block a third time (DRY rule: 3+ copies of `Invoke-SeedApi`/`Resolve-Secret`).

## Success Criteria

- Spike result recorded; chosen strategy documented.
- 22 task types each have >= target published questions; audio/image questions resolve a playable URL.

## Quality and Testing State

- Quality gate: not evaluated
- Testing: not started
