# Phase 1: media — WAV-only audio-prompt uploads + duration extraction

**P1 coverage: 2/3** — covers "content author gets an immediate, clear error for a corrupt/unreadable WAV" and lays the foundation (real, persisted duration, exposed via the existing audio-URL resolution response) for the prep-timing accuracy story completed in Phase 2. Also covers the P2 story (non-WAV upload rejected with a clear error).

## Requirements
For audio-prompt uploads belonging to the 5 audio-prompt Speaking task types, the media service accepts only `audio/wav`, computes and persists the exact duration (seconds) of the uploaded file from its WAV header at complete-upload time, and fails fast with a distinct, typed error if the file can't be parsed as valid WAV — never silently falling back to a guessed duration. Every other existing use of the same upload endpoint (candidates' own recorded answers, any other caller) is completely unaffected. The persisted duration is exposed to exam-delivery through its existing internal audio-URL resolution call, not a new endpoint.

## Steps
1. Add an explicit way for a caller to signal "this upload is a Speaking audio prompt" on the upload-request call, distinguishing it from every other existing use of the same generic upload endpoint, without narrowing or changing behavior for callers that don't set it.
2. When that signal is present, restrict the accepted content type to WAV only for that upload, independently of the existing broader allow-list used elsewhere.
3. At complete-upload time, read the uploaded object's real bytes and determine its exact duration from the WAV file header — no estimation or approximation.
4. Persist the determined duration on the media object as a new field, available for another service to read afterward.
5. If the file can't be parsed as valid WAV (corrupt, wrong format, truncated), fail the complete-upload call with a distinct, clearly identifiable error — the media object must never end up marked usable without a known duration.
6. Extend the existing internal presigned-download response with the newly persisted duration (populated whenever the media object has one, absent otherwise). **This is two separate record classes, not one** — media-service's own `PresignedDownloadResponse` (the actual server-side response) AND exam-delivery's independently-maintained mirror `MediaPresignedDownloadResponse` (`MediaClient`'s client-side DTO, explicitly documented in its own file as "not a shared class") both need the new field added, or `SnapshotPinService.resolveAudioUrl`'s existing call (Phase 2 Step 1) will find the field simply doesn't exist on its side despite the server sending it. Do **not** add a second internal endpoint/call for this: exam-delivery must be able to get both the URL and the duration from the one existing call site — just make sure both DTOs actually carry the new field.
7. Update `pte-api/scripts/seed-e2e.ps1`'s existing Repeat Sentence audio-prompt upload call to opt into the new signal from Step 1, so re-seeding after this phase lands continues to produce a WAV-validated, duration-computed audio prompt instead of silently skipping both.
8. Add unit test coverage for: a valid WAV upload (duration persisted correctly and reflected in the extended presigned-download response), a corrupt/unreadable WAV (fails with the new distinct error, media object not marked usable), a non-WAV content-type attempt for an audio-prompt upload (rejected up front), and a regression case confirming a non-audio-prompt upload (e.g. a candidate's own recorded answer) is entirely unaffected by any of this.

## Success Criteria
- A valid WAV audio-prompt upload completes successfully and its exact duration is persisted, readable afterward, and returned by the existing internal presigned-download response.
- A corrupt/unreadable WAV audio-prompt upload fails at complete-upload time with a distinct, typed error (spec.md Success Criteria #3), not later and not with a guessed fallback.
- A non-WAV (e.g. MP3) audio-prompt upload attempt is rejected with a clear, typed error at request time (spec.md Success Criteria #2).
- The existing candidate-recorded-answer upload path (and any other non-audio-prompt caller of the same endpoint) shows no behavior change — same unit-test-verified regression case passes.
- No new internal media endpoint is added — the existing presigned-download endpoint's response carries the duration.
- `seed-e2e.ps1` is updated to set the new signal on its audio-prompt upload call and still parses cleanly.
- All new and existing media-service unit tests pass.

## Risks
- No existing signal distinguishes an audio-prompt upload from any other caller of the same generic `/objects` endpoint — resolved by adding an explicit, opt-in signal on the upload-request call (defaults to today's unrestricted behavior when absent), so nothing existing narrows unless a caller explicitly asks for the audio-prompt behavior.
- Reading the uploaded object's real bytes at complete-upload time is a new MinIO round-trip that doesn't exist in this code path today (a suitable, already-configured client exists but is currently unused here) — mitigated by dedicated unit tests against this specific new read, covering both the happy path and a genuinely corrupt file.
- `seed-e2e.ps1` is the only real caller of the audio-prompt upload flow in this codebase (no content-authoring UI exists) — if its upload call isn't updated to opt into the new signal, re-seeding silently skips WAV validation/duration computation and Phase 2's pin-time duration lookup fails at Phase 5's first walkthrough attempt. Mitigated by Step 7 being part of this phase, not deferred to Phase 5.
