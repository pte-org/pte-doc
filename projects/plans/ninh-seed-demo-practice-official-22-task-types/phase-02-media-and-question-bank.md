# Phase 2: Media and question bank load

**Goal:** All selected questions exist as `PUBLISHED`/shared rows with working audio/image references.

## Tasks

1. **Spike (first, 30 min):** pick 1 audio question with an external CloudFront URL and 1 with a local fixture; wire each as `media_objects` and check `GET /api/v1/objects/{id}/preview-url` and the attempt task payload return a playable URL. Outcome decides Open Q1 and risk R1.
2. **One-time publisher step (run by the plan owner only):** download the selected site/fixture files to a scratch folder, upload each to the user's Cloudinary (folder `pte/demo22`, public delivery, `resource_type=video` for audio) using the credentials in `.env.local`, then write `mediaUrl`, `publicId`, `durationSeconds`, `format` back into `demo22-questions.json`. Implemented as a separate script (`scripts/publish-demo22-media.ps1`) that is **not** part of the teammate path.
3. **Seed step (everyone):** for each entry, register a `media_objects` row from `mediaUrl` (same deterministic UUID policy as `local-question-seed.sql`; HEAD-check the URL first, R9), then create the question through the API with that media UUID. The CloudFront-backed types use their existing external URLs through the same path.
4. Create questions through `POST /api/v1/questions` (reuse `Ensure-PublishedQuestion` pattern from `seed-local-template-and-question-bank.ps1`) so validation, audit and events run; look up by title for idempotence; publish/unarchive as in the existing script.
5. Registering `media_objects` through the API is not possible for an externally uploaded file (the complete endpoint checks ownership); if no API route accepts an external URL, use a small, idempotent SQL step (`ON CONFLICT DO NOTHING`) executed through the stack's Postgres container, and record this choice (R2).
6. Verify bank: `select pte_task_type, count(*) from questions where title like 'DEMO22%' and status in ('APPROVED','PUBLISHED') group by 1` shows 22 rows of exactly 3. With 66 questions the API path is fast enough; the SQL fallback in task 4 is unlikely to be needed.

## Design Constraints

- Admin token only (PLATFORM_ADMIN); credentials from `PTE_ADMIN_USERNAME` / `PTE_ADMIN_PASSWORD`, never written to disk.
- Download and Cloudinary upload are approved by the user (2026-10-06) for the files in the selection only; uploads go to `pte/demo22`, never `pte/authoring`; credentials are read from `.env.local` and never written to the seed file or logs.
- The seed file must contain no secrets and no signed/expiring URLs (the site's Firebase links stay in `sourceUrl` only).
- Script must be safe to re-run: no duplicate titles, no duplicate `media_objects`.
- Keep each script file under ~300 lines; split helpers into `scripts/lib/seed-common.ps1` if needed rather than copying the helper block a third time (DRY rule: 3+ copies of `Invoke-SeedApi`/`Resolve-Secret`).

## Success Criteria

- Spike result recorded; chosen strategy documented.
- 22 task types each have >= target published questions; audio/image questions resolve a playable URL.

## Quality and Testing State

- Quality gate: not evaluated
- Testing: not started
