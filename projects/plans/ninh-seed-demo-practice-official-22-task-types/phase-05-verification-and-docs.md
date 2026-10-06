# Phase 5: End-to-end verification and docs

**Goal:** Prove both flows work for the student and leave a repeatable one-command seed.

## Tasks

1. Wrapper `scripts/seed-demo-22-task-types.ps1` running Phases 2-4 in order; prints IDs and login names only.
2. Confirm F8: call `POST /api/v1/attempts` with `deviceCheckConfirmed=false` then `true` on the PRACTICE session to establish the cause of the earlier 409; fix `seed-local-exam-ready.ps1` if it is the same cause (it currently passes `false`).
3. For each session, as the student: `POST /attempts/preflight` with the capability manifest taken from `pte-app` (not the 2-contract manifest in the old script) → record `canStart`, `missingCapabilities`, `unsupportedTasks` per task type (R4).
4. Start an attempt in each flow; fetch tasks; spot-check one audio, one image and one option-based task payload; for OFFICIAL confirm STRICT policy fields are pinned (`proctorRequired`, lockdown, replay limit 1).
5a. Portability check: on a fresh clone/DB (no Cloudinary variables set) the wrapper must still seed all 66 questions from `demo22-questions.json`; document the "run on another machine" steps (clone, `.env.local` from `.env.example`, `docker compose up`, bootstrap admin, run wrapper).
5. Idempotency: run the wrapper twice; compare row counts (questions by title, sessions by name, accounts, media) before/after.
6. Docs: add a "Demo data (22 task types, PRACTICE + OFFICIAL)" section to `pte-api/README.md` (the README still points to the non-existent `seed-e2e.ps1`); update the `pte-doc` question-import README if the selection file is added.

## Design Constraints

- No secrets in logs, README or plan files; refer to `PTE_ADMIN_PASSWORD` / `PTE_SEED_PASSWORD` by name only.
- Reset instructions must call out that `docker compose down -v` deletes all local data.
- Verification output saved under this plan's `tests/` folder as a JSON report (same convention as other plans).

## Success Criteria

- All items in the plan's Success Criteria pass; a written list of task types the app cannot yet render (if any) is attached.

## Quality and Testing State

- Quality gate: not evaluated
- Testing: not started
