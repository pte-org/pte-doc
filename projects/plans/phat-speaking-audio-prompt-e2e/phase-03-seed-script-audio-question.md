# Phase 3: Seed Script — Repeat Sentence Audio Question Support

## Requirements
`pte-api/scripts/seed-e2e.ps1` can create (or confirm the prior existence of) a published `REPEAT_SENTENCE` question whose `audioPromptRef` points at a real uploaded media file, reusable by Phase 4's manual walkthrough, following the same get-or-create/idempotency pattern already established for `READ_ALOUD`.

## Steps
1. Read the current `seed-e2e.ps1` to confirm its existing question-creation step and state-file idempotency pattern for `READ_ALOUD`, so the new logic extends it consistently rather than diverging.
2. **Decision resolved (user confirmed):** the fixture must be a short, genuinely audible recording — every existing `.wav` in `pte-app/assets/audio/` is confirmed silent (all-zero PCM, per `phat-windows-audio-playback-fix`), none are usable. No audible fixture exists in either repo today, so one must be added: the developer supplies a short (a few seconds, e.g. one spoken sentence) `.wav`/`.mp3`/`.webm` recording — any simple recorder (Windows Voice Recorder, phone voice memo, etc.) is fine — committed as a new fixture file (e.g. `pte-api/scripts/fixtures/repeat_sentence_sample.wav`), with its path exposed as a script parameter with that file as the default. This is needed so Phase 4 can confirm by ear that the UI plays the actual server-resolved audio, not silence mistaken for success.
3. Add the media-upload sub-flow to the script: `POST /api/media/objects`, `PUT` the fixture bytes to the returned upload URL, `POST` complete, and capture the returned `mediaPublicId`.
4. Extend the script's question-creation call to support a `REPEAT_SENTENCE` question carrying the uploaded `mediaPublicId` as its `audioPromptRef`, following the same get-or-create/state-file idempotency pattern as the existing `READ_ALOUD` path.
5. Reuse the existing blueprint/publish/session steps for this new question, confirming no additional Speaking-specific gap exists there beyond question creation itself.
6. Add a distinct progress message for the new steps, and confirm a deliberate failure at the media-upload sub-step surfaces the real HTTP error detail instead of failing silently.

## Success Criteria
- `seed-e2e.ps1` still parses as valid PowerShell with zero syntax errors after the change.
- Running the extended script against a clean stack creates a published `REPEAT_SENTENCE` question with a non-null `audioPromptRef` pointing at a real `UPLOADED` `MediaObject`.
- Re-running the script is idempotent for the new resources (no duplicates), consistent with the existing `READ_ALOUD` behavior.
- A deliberately-triggered media-upload failure (e.g. bad content type or unreachable endpoint) surfaces the real HTTP error detail, not a swallowed exception.

## Risks
- Media upload request/response shape drift from what's assumed — Mitigation: read the actual media controller/DTO source before implementing, the same approach the original script's Phase 2 used successfully.
- No audible fixture exists in the repo today, so one must be freshly recorded and committed (Step 2) — Mitigation: keep it short (a few seconds) and speech-only to keep the repo addition trivial; must stay within media's `ALLOWED_CONTENT_TYPES` allow-list (`audio/mpeg`, `audio/wav`, `audio/webm`) or the upload sub-flow fails with `UnsupportedContentTypeException`.

## Testing
Same category as the original seed script: no automated suite runs a standalone PowerShell script. Verified by parse-check (Success Criteria) plus real execution against a live stack in Phase 4.
