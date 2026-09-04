# Phase 2: Frontend — Wire Real Audio-Prompt Playback

## Requirements
`pte-app`'s Speaking screens that carry an audio prompt (`REPEAT_SENTENCE`, `RE_TELL_LECTURE`, `ANSWER_SHORT_QUESTION`, `RESPOND_TO_A_SITUATION`, `SUMMARIZE_GROUP_DISCUSSION`) call the existing on-demand `GET /attempts/{attemptId}/items/{itemId}/audio` endpoint when the "Playing" sub-stage begins, and play the URL it returns — not a URL embedded in the task-fetch response — while handling the endpoint's expected replay-limit/expiry errors gracefully.

## Steps
1. Confirm `task_view.dart`'s existing `audioPromptRef` field is sufficient signal for the client — no new URL field is added to the model, since the resolved URL is intentionally not embedded in `TaskView` responses (Phase 1).
2. Add a repository method for the existing `GET /attempts/{attemptId}/items/{itemId}/audio` endpoint in whatever FE repo layer currently owns attempt-related calls (matching `exam_attempt_repository_impl.dart`'s existing pattern), sending a generated `X-Play-Request-Id` header and parsing `AudioPlayResponse.audioUrl` from the response.
3. **Decision point:** choose when a fresh `X-Play-Request-Id` is generated — default to once per entry into the "Playing" sub-stage; note whether the UI supports an explicit manual replay action (in which case each tap needs its own fresh id) as an open follow-up if the UX turns out to support one.
4. Add a real network-URL playback path to `AudioPlayerServiceImpl` (alongside the existing asset-based `play`), without breaking existing asset-based mock-data callers (Listening screens' bundled sample assets).
5. **Decision resolved (user confirmed):** `AudioListeningPrepCard`'s progress bar for the "Playing" sub-stage must be driven off the real audio player's actual playback position, not `TimerSnapshot` elapsed time — listen to the player's position/duration stream (the `just_audio`-backed service should expose this, e.g. `AudioPlayer.positionStream`/`durationStream`, or an equivalent added to whatever seam `AudioPlayerServiceImpl` exposes) and compute `progress` from that instead. The "Beginning in"/pre-listen and pre-record sub-stages are unaffected — they stay timer-driven as today; only the active "Playing" sub-stage's fill amount changes source. Handle the case where duration isn't yet known (e.g. still buffering) by holding progress at 0 rather than dividing by an unknown/zero duration.
6. `attemptPublicId` is currently only held one level up (a field on each of the 5 Speaking screens — `RepeatSentenceScreen`, `RetellLectureScreen`, `AnswerShortQuestionScreen`, `SummarizeGroupDiscussionScreen`, `RespondToASituationScreen` — sourced from `AttemptInProgress` state) and is not passed into `AudioPromptRecordBody`/`AudioListeningPrepCard` today. Add it as a new required constructor param on both widgets and pass it through from all 5 call sites — the `/audio` call needs both `attemptPublicId` and `task.pinnedItemPublicId` (the latter already available on `TaskView`).
7. Wire `AudioListeningPrepCard` to call the new repository method (guarded on `task.audioPromptRef` being non-null) when entering the "Playing" sub-stage, feed the returned URL into playback, and handle `ReplayLimitExceededException`/`AudioUrlExpiredException` (both HTTP 409, silent server-side per `GlobalExceptionHandler.handleDomain()` — no server log, so FE handling is the only signal these ever fired) with a clear, non-crashing UI state rather than a generic error.
8. Confirm existing Listening screens (still using bundled asset playback, not this new call path) are unaffected; add or extend unit/widget tests covering: the repository call and its header, playback invocation on entering the "Playing" sub-stage, and graceful handling of both 409 cases and a missing `audioPromptRef`.

## Success Criteria
- `flutter analyze` is clean.
- Existing test suite (Listening + Speaking) passes unchanged aside from the tests intentionally added in Step 8.
- A new unit/widget test confirms `AudioListeningPrepCard` calls the `/audio` endpoint with a generated `X-Play-Request-Id` header and plays the returned URL when `task.audioPromptRef` is non-null, and does not call it or crash when it's null.
- A new test confirms `ReplayLimitExceededException`/`AudioUrlExpiredException` (409) are handled with a clear, non-crashing UI state rather than falling through to a generic error path.
- A new unit/widget test confirms the "Playing" sub-stage's progress bar tracks the player's position/duration stream (0 while duration is unknown, fills toward 1.0 as position advances) rather than `TimerSnapshot` elapsed time.
- Manual confirmation in Phase 4 that the app calls the real endpoint and plays a real, audible seeded prompt during prep, with the progress bar visibly tracking actual playback.

## Risks
- `X-Play-Request-Id` generation-timing decision (Step 3) — Mitigation: default chosen and documented here; revisit only if the UX is found to support an explicit manual replay action.
- Progress-bar-vs-real-player-sync (Step 5, resolved as real-player-sync) adds a dependency on the player's position/duration stream actually being reliable (buffering delays, a stream that never emits if the network stalls) — Mitigation: hold progress at 0 rather than divide-by-unknown/zero while duration is unresolved, per Step 5; Phase 4 must observe this doesn't stall visibly on the real network path.
- `attemptPublicId` threading (Step 6) — Mitigation: mechanical, low-risk (the value already exists one level up on every affected screen), but called out explicitly rather than left implicit, since it touches 5 separate call sites.
- `/audio`'s 409 responses are silent server-side (no log) — Mitigation: Step 7/8's dedicated handling and test coverage are the only real verification these are ever hit correctly, not a generic catch-all.
- Network playback can fail (bad/expired URL, unreachable file) in ways asset playback never could — Mitigation: Step 7's guard must degrade gracefully (no crash), not assume the network call always succeeds.

## Testing
Standard automated coverage (unit/widget tests per Step 8, with the repository call mocked) runs as part of the normal Dart test suite. Real, observable playback against a live server and real `/audio` call is confirmed only in Phase 4 — no automated test can substitute for that.
