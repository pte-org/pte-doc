# Phase 5: pte-practice Renderers and Score View

Dependencies: Phases 2, 3, 4 (API contract stable). Blocks Phase 6.

## Requirements
In pte-practice a student can complete any of the 23 task types, sees "scoring" right after an AI answer, sees the question score (and sub-scores) when ready or a clear failure with retry, and no explanation UI remains.

## Files
Base: `d:\FPT\9thSemester\pte\pte-practice\` (Next.js 16, npm, port 3014, separate git repo). Read the bundled Next docs under `node_modules/next/dist/docs` before editing, per its AGENTS.md.
- Change: `features/practice/*` task renderers and answer submission (one renderer per exam type; add the missing ones, drop Write Email), the session/answer API client and types (new result and poll shapes from Phase 2), the post-answer screen, the review screen (endpoint from Phase 3).
- Add: score view component (overall score, sub-scores, transcript when present; no fallback notice, decided 2026-10-24), polling hook with interval, timeout and retry, scoring-state and failure components.
- Delete: explanation request/poll UI, hooks, types and translations, and the Write Email renderer.
- Tests add/update: component or unit tests per project convention (confirm test runner with the package scripts first); polling hook test (SCORED, FAILED, timeout); renderer smoke per type.

## Steps
1. Inventory the existing renderers against the 23 types and list the gaps, using the backend catalog response as the source of truth.
2. Update the API types and client for the new answer response and poll endpoint; remove explanation calls.
3. Build or fix renderers so each type captures its answer in the shape the backend canonicalizer accepts, including audio recording upload and prompt media playback.
4. Implement the scoring state, polling with a bounded interval and timeout, and the FAILED state with a retry affordance.
5. Implement the score view for objective (immediate) and AI (after polling) results, including sub-scores. A FALLBACK-status score renders exactly like a normal one (no notice).
6. Remove explanation UI and Write Email, and fix navigation or copy that referred to them.
7. Run type check, lint, build and the available tests; hand the manual walkthrough list to the user (user does UI checks).

## Success Criteria
- Type check, lint and production build pass in pte-practice.
- Every task type returned by the catalog has a renderer; none is shown as unsupported.
- The polling hook test shows it stops on SCORED, FAILED and timeout and never polls indefinitely.
- No remaining references to explanation endpoints or Write Email in the package (search returns nothing).

## Risks
- Renderer answer shape drifts from the backend canonicalizer: share fixtures between the two sides and verify with one request per type in Phase 6.
- Audio recording differences by browser: reuse the existing recorder path, test the primary browser the user uses.
- Poll storms: bounded interval with backoff, stop on unmount.
- Separate git repo: changes need their own commit by the user.
- Rollback: revert the repo changes; backend stays compatible because the old explanation endpoints are already gone, so a rollback requires reverting Phase 3 too.

## Execution Log
<!-- Filled by /ck:cook at the end of this phase — leave placeholders when planning -->

### Errors Encountered
- Client capabilities omitted AUDIO_PLAYBACK, IMAGE_DISPLAY and HIGHLIGHT_SELECTION; the backend would have rejected listening, describe-image and highlight answers as capability mismatches.
- Typecheck failed after the first green test run: leftover explanation imports in api.ts and PracticeReviewView.tsx.
- `npm run build` intermittently stops with a Next.js 16.4.0 security-advisory error; an immediate retry compiles. Upgrading Next is not part of this plan.

### Root Cause
- Capability list was written for the nine old renderers; explanation code was still referenced by the old review view.

### Resolution
- Capabilities now list all eight backend capability sets. api.ts and review view rewritten around getItemResult; review view mounts a ScoreView per answered item.
- Simplify pass: shared TYPE_IN_MAX_LENGTH and stringArray, single parse in TypeInRenderer, memoized task fixture, immediate recheck after timeout, dead CSS and unused gapIndexes removed.
- Skipped (not behavior-neutral or outside this diff): N result requests on the review page (needs itemResult in the review response), visibility-aware polling, moving the default re-order answer out of OrderRenderer, reducer phase for the answered card, renderer variant props, trimming unused PracticeItemResult fields.

### Test Results After Fix
- typecheck clean; vitest 59 passed (12 files); lint 0 errors, 6 pre-existing warnings; build passes. Manual UI walkthrough is handed to the user.
