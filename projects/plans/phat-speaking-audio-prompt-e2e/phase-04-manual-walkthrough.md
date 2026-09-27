# Phase 4: Manual E2E Walkthrough — Repeat Sentence Audio Playback (human-executed)

## Requirements
A developer-executed pass confirms the full chain against a real, locally-running `pte-api`: a seeded Repeat Sentence question with a real audio prompt, `pte-app` actually calling the real `/audio` endpoint and playing the resolved URL during prep, and the already-proven record → upload → submit leg (from `phat-speaking-api-e2e-verify`) still working for this new task type.

**This phase cannot be delegated to an automated tester agent** — it requires a running Docker stack, a real device/desktop app instance, and direct DB/HTTP inspection, the same category of manual-only phase as `phat-speaking-api-e2e-verify`'s Phase 3.

## Steps
1. Bring up the full `docker compose` stack (or reuse an already-running one) and confirm every service reports healthy, including the fixes already landed by `phat-speaking-api-e2e-verify` (gateway URL, timer-phase, MinIO public endpoint, response-window grace).
2. Run the extended `seed-e2e.ps1` to create or confirm a published Repeat Sentence question and an opened session with the student enrolled.
3. Independently verify URL resolution before touching the app: call the real `GET /attempts/{attemptId}/items/{itemId}/audio` endpoint directly with a valid `X-Play-Request-Id` for the seeded item, and confirm a direct HTTP GET against the returned `audioUrl` succeeds.
4. Log into `pte-app` as the seeded student and start the seeded Repeat Sentence attempt.
5. During the prep "Playing" sub-stage, confirm the app actually calls the `/audio` endpoint and observably plays the returned audio (audibly if the audible fixture was used, or via player-state/duration inspection if the silent fixture was used per Phase 3's decision).
6. Let the flow continue through record → upload → submit as already proven for Read Aloud, confirming this leg still works unchanged for this new task type.
7. Query the exam-delivery/media databases directly to confirm the expected `MediaObject`/`attempt_answers` rows, and record pass/fail against each success criterion below.

## Success Criteria
- Calling the real `GET /attempts/{attemptId}/items/{itemId}/audio` endpoint directly for the seeded Repeat Sentence attempt returns a non-null `audioUrl` that resolves to a reachable file via direct HTTP GET, independent of the app (Step 3).
- `pte-app` actually calls the `/audio` endpoint (not a baked-in URL) and observably plays audio during the prep phase for this task (audible or player-state confirmation, per the fixture chosen in Phase 3).
- Recording, upload, and submission complete successfully for this task type, producing an `UPLOADED` `MediaObject` and a `SUBMITTED` `attempt_answers` row referencing it.
- No regression to the previously-verified Read Aloud flow (spot-checked, not fully re-run).

## Risks
- HIGH: presigned URL resolves to a docker-internal hostname unreachable from the app — this exact bug class was already hit and fixed once in `phat-speaking-api-e2e-verify` (public MinIO endpoint bean) — Mitigation: Step 3 explicitly re-verifies the fix still applies to this new code path rather than assuming it does.
- MEDIUM: if the silent fixture was used in Phase 3, "plays audio" is unverifiable by ear — Mitigation: fall back to player-state/duration inspection, or swap in an audible fixture for this run if needed (developer discretion, per Phase 3's decision point).
- MEDIUM: the progress-bar-vs-real-player-sync default and the `X-Play-Request-Id` generation-timing default from Phase 2 may look visibly wrong only once real audio timing and real replay limits are observed here — Mitigation: this phase is the first real check of both defaults; escalate back to Phase 2 if either needs revisiting.
- LOW: seeded session's `opensAt` window goes stale between seeding and testing — Mitigation: reseed shortly before this phase, same as the prior plan.

## Testing
This entire phase is the test — no automated substitute exists for real device/desktop audio playback against a live multi-service backend.
