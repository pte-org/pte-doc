# Phase 6 — Text, Playback and Speaking Media Runtime

## Objective

Add text-entry and media-backed practice behavior with explicit readiness, permission, recording and upload failure states, while keeping unsupported `WRITE_EMAIL`/video behavior visible as a contract gap.

## Story mapping

- P1: entitled student can complete supported text/audio/speaking task flows; locked student remains blocked.
- P2: media controls, countdowns, recording states and responsive task layout are accessible.
- P3: no extra product navigation.

## Scope

- Text families: `SUMMARIZE_WRITTEN_TEXT`, `WRITE_ESSAY`, `SUMMARIZE_SPOKEN_TEXT`, `FILL_IN_THE_BLANKS_TYPE_IN`, `WRITE_FROM_DICTATION`.
- Audio playback/readiness, pre-listen/pre-record timing and countdown behavior for supported profiles.
- Speaking task families: `PERSONAL_INTRODUCTION`, `READ_ALOUD`, `REPEAT_SENTENCE`, `DESCRIBE_IMAGE`, `RE_TELL_LECTURE`, `ANSWER_SHORT_QUESTION`, `RESPOND_TO_A_SITUATION`, `SUMMARIZE_GROUP_DISCUSSION` where content/runtime/media contract is ready.
- Microphone capability/permission/device checks, MediaRecorder MIME negotiation, upload binding, retry and interrupted-recording behavior.
- Use the Phase 01-selected canonical recording format. The default recommendation
  is client-side WAV encoding to preserve the existing backend/media contract;
  accepting `webm/opus` or adding transcoding requires an explicit media ADR.
- Explicit `WRITE_EMAIL` and video rows as deferred/fixture/blocked; no silent conversion.

## Exact files/areas likely changed

- `pte-practice` text, audio, countdown, recording, device-check and media state components under the approved feature structure.
- `pte-practice` browser/media capability adapter and typed media API client.
- Existing `pte-api/app/src/main/java/com/pte/media/internal/controller/MediaController.java` and owning media service/DTO areas for protected binding/validation.
- Existing `pte-api` attempt/task delivery areas for capability/readiness and server deadline checks; exact classes remain those selected in Phase 03.
- `pte-doc` task coverage/fixture provenance notes for premium reference gaps and browser support.

## Dependencies

- Phase 03 media/session contract and protected media ownership.
- Phase 05 shared session shell and serializers.
- Existing device-check precedent `pte-doc/projects/plans/phat-device-check-test-mic-and-sound-ui/` and speaking plans; do not duplicate their established policy.

## Implementation steps

1. Add preflight capability response and client readiness states before playback/recording.
2. Implement audio playback controls and countdown using server-provided timing/capability metadata.
3. Implement microphone permission/device/MIME checks and recording lifecycle.
4. Upload only a bound recording for the authorized student/session/item; validate size, duration and content type server-side.
5. Define retry for upload/network failure, signed URL expiry and browser close; preserve non-empty draft semantics without fabricating an answer.
6. Add text word-count, Unicode, paste and autosave behavior using canonical answer schema.
7. Mark `WRITE_EMAIL` and video unavailable until contract exists; add no silent fallback tests.

## Acceptance criteria

- Audio tasks expose readiness before playback and do not silently continue after failure.
- Recording tasks handle permission denied, no device, busy device, unsupported MIME, interrupted recorder, upload timeout/retry and browser close.
- Server rejects unbound, oversized, wrong-type, wrong-owner or expired media.
- Text tasks preserve draft, word-count and answer schema across reload/retry.
- Timer/deadline remains server-authoritative after reload/clock changes.
- Unsupported `WRITE_EMAIL`/video is clearly represented in catalog/session preflight and never mapped to another renderer.

## Design Constraints

- Never log raw audio, signed URLs, answer text or device permission details beyond safe error categories.
- Do not assume a browser can record merely because it supports the page; readiness is explicit.
- Reuse existing Cloudinary/media infrastructure where appropriate; do not invent a second storage path without an approved ADR.
- A media failure cannot create a completed/empty response accidentally.

## Quality and Testing State

- Quality: **APPROVED for implemented text, WAV recording and media-binding
  scope** after inline senior review; unsupported prompt-media behavior is
  fail-closed and documented rather than approximated.
- Testing: **PASSED**. Cloudinary binding/recording tests, migration checks,
  backend regression, frontend lint/typecheck/unit/build all pass.
- Evidence boundary: live Cloudinary upload, microphone permission/device
  matrix and prompt audio playback remain pending because the current task
  response does not expose protected prompt-media readiness metadata.
