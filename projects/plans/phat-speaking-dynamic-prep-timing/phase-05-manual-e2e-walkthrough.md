# Phase 5: Manual E2E walkthrough

**P1 coverage: 3/3** — this phase is the only place all three P1 stories' Accepted-When conditions get verified together, end-to-end, against a real backend (mirrors the prior plan's Phase 4 pattern — human-executed, cannot be delegated to an automated tester).

## Requirements
Against a real local stack with the changes from Phases 1–4 deployed, confirm by ear/eye that the "Playing" progress bar and countdown label finish together for a seeded audio-prompt question of known duration, and that recording starts promptly (not with the old ~10s worst-case lag) for a short-prep task type — plus confirm no regression for an already-verified non-audio-prompt task type.

## Steps
1. **Resolved (user confirmed):** generate a new WAV fixture with a longer, more clearly distinguishable duration (e.g. ~5-6s, versus the existing 2.5s tone) — long enough that "genuinely in sync" is visually/aurally unambiguous from "coincidentally close." Same generation approach as the existing fixture (a synthesized tone via Python's stdlib `wave` module — no speech-recording tool available in this environment, per the prior plan's own precedent). Commit the new fixture alongside (not replacing) the existing one unless there's a reason to retire it, and update the seed script to reference it for this walkthrough.
2. Re-seed a published audio-prompt question (e.g. Repeat Sentence or Answer Short Question) using that fixture against a freshly brought-up local stack with all of this plan's changes deployed.
3. Independently verify (via direct API calls, bypassing the app) that the pinned item's prep window and the resolved audio's duration are consistent with the new dynamic computation, before involving the app.
4. Walk through the seeded question in the app: confirm the "Playing" countdown label and progress bar reach their end at the same real moment, within normal playback tolerance.
5. Walk through a short-prep task type and confirm recording starts within roughly a couple of seconds of the countdown reaching zero, not with the old worst-case lag.
6. Spot-check an already-verified non-audio-prompt task type (e.g. Read Aloud) to confirm no regression in its prep/response timing behavior.
7. Record the outcome (pass/fail per criterion, any new bugs found) in this plan's Session Notes, following the same documentation pattern as the prior plan's manual walkthrough phase.

## Success Criteria
- The "Playing" progress bar reaches 100% within normal playback tolerance of the same real moment the countdown label shows "0 seconds left" (spec.md Success Criteria #1).
- Recording starts within roughly 1–2 seconds of the real server-side prep deadline passing, for a short-prep task type (spec.md Success Criteria #4).
- Read Aloud (or another already-verified task type) shows no regression to its existing prep/response timing behavior (spec.md Success Criteria #5).
- Uploading a non-WAV file and a corrupt WAV file as audio prompts are both confirmed rejected as expected (spec.md Success Criteria #2 and #3), either via this walkthrough's own upload step or by referencing Phase 1's already-passing automated tests if a live re-check isn't practical in this environment.

## Risks
- The existing 2.5s synthetic-tone fixture may be too short to visually distinguish "genuinely in sync" from "coincidentally close" — resolved per Step 1: a new, longer (~5-6s) fixture is generated for this phase rather than reusing the existing one.
- Live-stack issues unrelated to this plan's own changes (env/config drift, as encountered twice in the prior plan's Phase 4) may surface and need fixing before the actual walkthrough can proceed — mitigated by Step 3's independent API-level check before involving the app, isolating whether an issue is this plan's own logic or an environment problem, same pattern the prior plan used successfully.
