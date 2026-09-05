# Phase 1: Backend — Resolve Speaking Audio-Prompt URLs

## Requirements
Any item with a non-null `audioPromptRef`, in any section, gets its `PinnedItem.audioUrl`/`audioUrlExpiresAt` resolved by the existing presign logic — so the already-existing on-demand `GET /attempts/{attemptId}/items/{itemId}/audio` endpoint (`AttemptController.playAudio` → `AttemptService.playAudio`) can serve a real playable URL for Speaking items too, exactly as it already does for LISTENING. `TaskView`/`AttemptMapper` are unchanged — the resolved URL is deliberately not embedded in task-fetch responses, since `/audio` already enforces play-limit and expiry rules that a baked-in URL would bypass.

## Steps
1. Split `SnapshotPinService.toPinnedItem`'s presign logic into two explicit, separate branches: keep the existing LISTENING branch's behavior completely unchanged (null `audioPromptRef` → `MissingAudioPromptException`; non-null → presign as today); add a new branch for non-LISTENING sections where a non-null `audioPromptRef` triggers the same presign call (reusing `AudioResolutionFailedException` if the presign call itself fails), and a null `audioPromptRef` is skipped silently — not an error, since Speaking's audio prompt is optional per task type, unlike LISTENING's.
2. Confirm the presign result continues to populate `PinnedItem.audioUrl`/`audioUrlExpiresAt` exactly as before, with no entity or cache-record changes needed, so `AttemptService.playAudio` can already serve these newly-resolved Speaking URLs without any further backend change.
3. Confirm — and keep it that way — that no `TaskView`/`AttemptMapper` changes are made in this phase. `TaskView.audioPromptRef` (raw UUID) remains the only audio-related signal the client receives from task-fetch responses; the resolved playable URL stays reachable only through the existing on-demand `/audio` endpoint.
4. Add or extend unit/service-level tests covering: a LISTENING item with a null `audioPromptRef` still throws `MissingAudioPromptException` (regression); a LISTENING item with a non-null ref still presigns as before (regression); a non-LISTENING item with a non-null ref presigns successfully; a non-LISTENING item with a null ref pins with no exception and no `audioUrl`; a presign failure on a non-LISTENING item with a non-null ref surfaces `AudioResolutionFailedException`.
5. Confirm the full change is verifiable purely by calling the real `/audio` endpoint for a seeded Speaking item once one exists (Phase 4) — no response DTO in this phase needs inspecting for a new field.

## Success Criteria
- Calling the real `GET /attempts/{attemptId}/items/{itemId}/audio` endpoint for a seeded Speaking item (once Phase 3 seeds one), with a valid `X-Play-Request-Id`, returns a non-null `audioUrl` that resolves to a reachable file.
- A LISTENING item with a null `audioPromptRef` still throws `MissingAudioPromptException` exactly as before (regression-proof).
- A non-LISTENING item with a null `audioPromptRef` pins successfully with no exception and no `audioUrl`.
- A forced presign failure on a non-LISTENING item with a non-null `audioPromptRef` surfaces `AudioResolutionFailedException`, not an unhandled error.
- No `TaskView`/`AttemptMapper` diff exists for this phase — `audioPromptRef` remains the only audio-related field in `TaskView`.
- Full `exam-delivery` test suite passes, including the new/extended tests from Step 4.

## Risks
- Merging the LISTENING and non-LISTENING presign logic into one condition instead of two explicit branches could silently change LISTENING's required-audio invariant — Mitigation: implemented and tested as two distinct branches (Step 1), with an explicit regression test for the LISTENING-null case.
- Reusing `AudioResolutionFailedException` for the new non-LISTENING failure path assumes its existing semantics genuinely fit the Speaking case — Mitigation: confirm during implementation that reuse is appropriate before assuming it; adapt only if it isn't.
- Accidentally reintroducing a baked-in `audioUrl` field on `TaskView` (e.g. as a "convenience" during implementation) would let the FE bypass `/audio`'s play-limit/expiry enforcement — Mitigation: explicit success criterion above checks the diff doesn't touch `TaskView`/`AttemptMapper`.

## Testing
Standard automated coverage applies here (unlike the manual-only Phase 4): unit/service-level tests per Step 4, run as part of the normal `exam-delivery` test suite. No live stack needed for this phase's own verification — real end-to-end confirmation via the actual `/audio` HTTP call happens in Phase 4.
