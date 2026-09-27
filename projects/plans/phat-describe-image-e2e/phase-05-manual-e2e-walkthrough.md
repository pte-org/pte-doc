# Phase 5: Manual E2E Walkthrough

## Requirements
Against a real local stack with Phases 1–4 deployed, confirm a real `DESCRIBE_IMAGE` item pins, presents its image correctly in the app, and completes normally — plus confirm `PERSONAL_INTRODUCTION` pins and completes normally with no image/audio work involved.

## Steps
1. Generate a small test image fixture (e.g. `scripts/fixtures/describe_image_sample.png`) — a simple generated image, same spirit as the existing synthesized WAV tone fixtures, no external asset needed.
2. Rebuild/restart the `exam-delivery` service with all of Phases 1–3's changes deployed, and confirm `pte-app` is built/runnable against that local backend.
3. Seed (via direct API calls, following this session's own established ad-hoc-seeding pattern for task types the seed script doesn't yet cover) a published `DESCRIBE_IMAGE` question with a real uploaded image as its `imagePromptRef`, and a published `PERSONAL_INTRODUCTION` question with only `promptText`.
4. **Seed two separate sessions per task type** (one for Step 5's API-level check, one left completely untouched for Step 6's human walkthrough) — reusing the same published question/blueprint, just distinct session names. This mirrors the prior `phat-speaking-dynamic-prep-timing` plan's own Phase 5 fix, applied proactively here (plan-reviewer HIGH finding): starting an attempt for the API-level check begins that session's prep/response countdown immediately, and `DESCRIBE_IMAGE`'s window is short (prepSeconds=25, responseSeconds=40) — reusing the same session for both steps risks the window already expiring by the time the human walkthrough runs, since `ExamAttempt` is one-shot per (student, session) and a second `startAttempt` call against the same session just resumes the same in-progress (or by-then-expired) attempt rather than creating a fresh one.
5. Independently verify via direct API calls (bypassing the app, using the *first* of each pair of sessions from Step 4) that a started attempt's `DESCRIBE_IMAGE` task carries a real, fetchable `imageUrl` in its JSON response, and that `PERSONAL_INTRODUCTION`'s task carries the expected prepSeconds=25/responseSeconds=30.
6. Walk through the *second*, untouched `DESCRIBE_IMAGE` session from Step 4 in the app: confirm the image renders (not a broken-image/fallback state), prep/response timing behaves normally, and the task completes.
7. Walk through the *second*, untouched `PERSONAL_INTRODUCTION` session from Step 4 in the app: confirm it pins and completes normally with no image-related behavior involved.
8. Record the outcome (pass/fail per criterion, any new bugs found) in this plan's Session Notes.

## Success Criteria
- A real `DESCRIBE_IMAGE` attempt's task response contains a non-null, directly-fetchable `imageUrl` (confirmed by direct API call before involving the app).
- The Describe Image screen renders the real image in the app, not the fallback/error state.
- A real `PERSONAL_INTRODUCTION` attempt pins and completes without error, using the values confirmed in Phase 1.
- (Read Aloud regression spot-check skipped per user decision — already extensively verified during `phat-speaking-dynamic-prep-timing`'s own walkthrough this session, and this plan's changes don't touch any code Read Aloud exercises.)

## Risks
- LOW: no image test asset exists anywhere in this repo today — mitigated by Step 1 generating a small synthesized fixture rather than depending on an external asset.
- LOW: the seed script has no existing `DESCRIBE_IMAGE`/`PERSONAL_INTRODUCTION` support — mitigated by seeding ad hoc via direct API calls for this one-off walkthrough (this session's already-established pattern for task types the script doesn't cover), rather than extending the script itself, which is out of scope for this plan.
- HIGH (plan-reviewer finding, resolved): reusing the same session for both the API-level verification (Step 5) and the human walkthrough (Step 6/7) would risk the human walkthrough hitting an already-expired or already-in-progress attempt, since `ExamAttempt` is one-shot per (student, session) and `DESCRIBE_IMAGE`'s prep/response window (25s/40s) is short enough that any delay between the two steps matters. Mitigated by Step 4 explicitly seeding two sessions per task type — one consumed by verification, one kept untouched for the walkthrough — mirroring the exact fix already proven in `phat-speaking-dynamic-prep-timing`'s own Phase 5 this same session.
