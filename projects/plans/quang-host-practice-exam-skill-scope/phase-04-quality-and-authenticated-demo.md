# Phase 04 — Build verification and authenticated demo walkthrough

## Goal

Prove the real Practice workflow end to end locally and leave a concise handoff that can be repeated for the demo.

## Requirements

- Do not create or run unit tests or a quality gate; the user explicitly declined both for this delivery.
- Require only the relevant build gates: backend production compile, API-client typecheck, tenant-web build, and Flutter Windows debug build. Record results without implying test coverage.
- Check local question stock, template section definitions, subscription window/capacity, host/student accounts, and service health before starting the walkthrough.
- Use existing seed scripts only after verifying their current contents/parameters and database target. Never infer success from a prior syntax check, and do not reset/delete local data as part of this plan.
- Execute the complete authenticated vertical slice and record evidence without storing credentials.

## Walkthrough

1. Confirm current local Docker/API/web/app targets and migration health; confirm the active template has a supported no-microphone skill with sufficient published stock.
2. Sign in to tenant-web as Host and create a Practice exam with one selected skill, an explicit retry count, and one known student. Keep the mode's existing shared-form/reuse defaults unless the host explicitly changes them. Phase 03 automated tests cover retry configuration for Mock Test and Official Exam too.
3. Verify the selected scope in the review step and run preflight. Confirm only selected-scope shortages are considered.
4. Generate and publish/schedule via the wizard's canonical API workflow. Open the scheduled exam according to the current session window rules.
5. Sign in to desktop `pte-app` as the assigned student, open the assigned exam/session, complete all delivered tasks, and submit. If the configured retry count is `1`, verify the app offers one additional independent attempt where practical; otherwise record the observed state without claiming the retry boundary was verified.
6. Return to tenant-web and verify the submitted attempt number and answers are visible in the host exam workflow. Verify the available score review workflow and that only selected-skill scores are present.
7. Stop after host-side answer inspection. Do not close the exam or publish student-facing reports for this demo.
8. Record selected scope, configured limit, exam/session identifier, generated task sections/count, submitted attempt number, host-side evidence, and any prerequisite. Keep secrets out of the report.

## Exit criteria

- Backend production compile, API-client typecheck, tenant-web build, and Flutter Windows debug build pass.
- Unit tests and quality gate remain skipped by explicit user choice; do not describe the feature as test- or quality-approved.
- Manual host → `pte-app` → host path completes using authenticated local accounts without requiring report publication.
- Generated task sections exactly match selected skills, the student can submit within the configured retry policy, and the host sees the answer(s) with attempt number.
- No new regression in full-template Mock/Official behavior or old clients that omit scope.
- Store a short manual walkthrough report under this plan's `tests/` or `quality/` directory; do not include credentials.

## Design Constraints

- Treat this as a local demo verification only; no production data, deployment, pushes, commits, or broad Docker volume cleanup.
- If local content or accounts are missing, stop at the exact prerequisite and report it; do not fabricate successful E2E evidence.
- Preserve existing seeded account credentials and data unless the user separately authorizes a reset.
- Distinguish `submitted` from `scored` and `report published`; record which state was actually reached.

## Quality and Testing State

- Quality: skipped_by_user; decision: user_confirmed_skip.
- Testing: not_started; skipped_by_user. Build gates passed; authenticated walkthrough in progress.
