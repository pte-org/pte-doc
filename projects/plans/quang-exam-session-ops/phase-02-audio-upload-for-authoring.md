# Phase 2: Audio Upload Wiring for Listening/Speaking Authoring

## Requirements

Wire question authoring endpoints to the existing `CloudinaryServiceImpl` proxy-upload pattern (multipart file receipt, Cloudinary forwarding, `Asset` record persistence) so that Vendor and Host can attach audio files to Listening and Speaking questions during authoring. Audio files are persisted as `Asset` records with CDN URLs, scoped to the same tenant as the question.

Maps to: **P1 Story #1, #2 (audio) | FR-01 (audio)**

## Design Constraints

- Must reuse the existing `CloudinaryServiceImpl` proxy-upload pattern exactly as-is; do not build direct presigned-URL upload or new storage abstraction.
- Audio must be associated with a Listening or Speaking question, not stored independently.
- Uploaded audio file metadata must be persisted as an `Asset` record, scoped to the same tenant as the question.
- Do not implement web-based audio recording; accept only file upload.

## Steps

1. Update Phase 1 question-authoring UI forms to include a file-input field for Listening and Speaking skill types only; mark this field as required for those skills, hidden for others.

2. Implement a new endpoint (e.g., POST `/api/questions/{questionId}/audio`) that accepts a multipart file, extracts the authenticated user's tenant, **validates the file's MIME type against a whitelist (audio/wav, audio/mpeg, audio/mp4) and rejects anything else with 400 Bad Request, and validates file size against a max limit (50 MB) rejecting oversized files with 400 Bad Request — both checks run before the file is forwarded to Cloudinary**, then calls `CloudinaryServiceImpl.upload()` with the file stream.

3. Persist the returned CDN URL and file metadata as an `Asset` record, linked to the question via a new `audioAssetId: UUID` field on `Question`; set the `Asset.tenantId` to match the question's `tenantId`.

4. Update the question update endpoint to replace the audio asset (delete old `Asset`, upload new file, update `audioAssetId`).

5. Update question detail endpoint (GET) to include the audio CDN URL and optionally the `Asset` metadata (file size, MIME type) in the response.

6. Add validation: if a Listening or Speaking question is published, it must have a non-null `audioAssetId` (enforce in pre-publish check from Phase 1).

7. Test multipart upload end-to-end: upload a .wav or .mp3 file, verify Asset record is created, verify CDN URL is populated, verify question detail endpoint returns playable audio URL.

## Success Criteria

- Vendor can author a Listening question, upload a .wav/.mp3 file via form, and publish it with audio successfully persisted.
- Host can author a Speaking question with audio in their tenant (audio URL is Host-scoped).
- Question detail endpoint returns a valid, playable CDN URL for audio questions.
- Audio file upload respects tenant scoping (Host cannot upload to another tenant's question).
- Pre-publish validation prevents Listening/Speaking questions from being published without audio.

## Quality and Testing State

- Quality gate: **approved** (report: `quality/phase-02-audio-upload-for-authoring-quality-report.json`, receipt issued 2026-07-15). One MEDIUM finding (TXN_NO_EXTERNAL_CALL_INSIDE_TXN — delete-before-upload ordering risk) found and fixed before approval.
- Testing: not started — skipped by user for Phase 2 (policy: unit tests required only for Phase 6-9)

## Session Notes

- Added `Question.audioAssetId`, migration V6, POST `/{id}/audio` endpoint reusing the existing `CloudinaryServiceImpl` proxy pattern, MIME/size validation, and a `toResponse()` helper in `QuestionService` to consistently include the audio asset in all response paths.
- `uploadAudio()` deliberately has no method-level `@Transactional`: new audio is uploaded and attached first, old audio is only removed after the question is durably saved — closes a broken-audio failure mode a mid-upload failure would otherwise cause.
- `deleteQuestion()` (Phase 1) now also cleans up the audio asset (storage + DB) on hard-delete, per this phase's orphaning risk.
- Build Gate: PASS.

## Risks

- **Cloudinary integration failure**: If `CloudinaryServiceImpl` is unavailable during upload, question authoring will fail and user loses the form state. Mitigation: implement graceful error handling in the UI (catch upload error, preserve form data, show user-facing message); add integration test against a test Cloudinary account before Phase 2 completion.
- **File-size or MIME-type validation**: resolved — Step 2 mandates MIME whitelist + size-limit validation before forwarding to Cloudinary, not left as an optional hardening step.
- **Asset record orphaning**: If question deletion doesn't cascade-delete the audio Asset, storage quota will be wasted. Mitigation: add cascade-delete on Question → Asset relationship at database level; audit cleanup logic before Phase 2 completion.
