# Phase 2: Backend Image-URL Resolution at Pin Time

## Requirements
`SnapshotPinService` resolves a `DESCRIBE_IMAGE` item's `imagePromptRef` into a real, directly-fetchable, tenant-scoped presigned URL exactly once, at pin time — stored on `PinnedItem`, with the same fail-fast guarantees LISTENING's mandatory audio already has.

## Steps
1. Add two new domain exceptions mirroring the existing audio ones exactly: `MissingImagePromptException` (a `DESCRIBE_IMAGE` item with a null `imagePromptRef` — an authoring data problem, HTTP 422) and `ImageResolutionFailedException` (a null presign response, mirrors `AudioResolutionFailedException`'s failure category).
2. Add matching constants to `ExamDeliveryConstants` (`MISSING_IMAGE_PROMPT`, `IMAGE_RESOLUTION_FAILED`).
3. Add `imageUrl` (text column) and `imageUrlExpiresAt` fields to `PinnedItem`, both nullable — matching `audioUrl`/`audioUrlExpiresAt`'s existing shape exactly, to avoid the NOT-NULL-column-on-existing-rows `ddl-auto: update` pitfall.
4. In `SnapshotPinService`, add a `DESCRIBE_IMAGE`-task-type fail-fast check for a null `imagePromptRef` (same string-comparison style already used for `LISTENING_SECTION`), and a private `resolveImageUrl(...)` method mirroring `resolveAudioUrl` (reuses `mediaClient.presignGet(...)` and the existing `audioUrlTtlSeconds` value — no new TTL concept, no duration extraction since images have no duration).
5. Wire the new resolution call into `toPinnedItem` for every item whose `imagePromptRef` is non-null, regardless of task type (mirrors audio's "optional for most types" pattern, mandatory only for `DESCRIBE_IMAGE`).
6. Bring up the local stack against an existing dev database with pre-existing rows and confirm `ddl-auto: update` adds both new nullable columns cleanly, with no manual migration needed.
7. Add tests to `SnapshotPinServiceTest.java` cloning the existing 3 audio-resolution patterns for images: a `DESCRIBE_IMAGE` item with a null `imagePromptRef` throws `MissingImagePromptException`; a non-`DESCRIBE_IMAGE` item with a null `imagePromptRef` pins cleanly with no `imageUrl`; a non-null `imagePromptRef` presign failure throws `ImageResolutionFailedException`; a non-null `imagePromptRef` presign success populates `imageUrl`/`imageUrlExpiresAt`.

## Success Criteria
- A `DESCRIBE_IMAGE` item with a null `imagePromptRef` fails pinning with `MissingImagePromptException` (422).
- A `DESCRIBE_IMAGE` item with a valid `imagePromptRef` pins with `PinnedItem.imageUrl` populated to a real presigned URL and `imageUrlExpiresAt` set.
- A presign failure on any non-null `imagePromptRef` surfaces `ImageResolutionFailedException`.
- `services/exam-delivery` full test suite passes; new tests specifically cover all 4 branches above.
- Local `ddl-auto: update` against an existing dev database adds both new columns without error.

## Risks
- MEDIUM: a NOT-NULL column with no default breaks `ddl-auto: update` against an existing dev DB with rows (this exact pitfall was hit once already this session, in a different table) — mitigated by keeping both new columns nullable from the start (Step 3), verified live in Step 6 rather than assumed.
- LOW: reusing `audioUrlTtlSeconds` for images could read as a naming mismatch to a future reader — mitigated by a short comment at the call site noting it's deliberately media-type-agnostic (per the feature's confirmed design), not a copy-paste oversight.
