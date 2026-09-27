# Phase 3: Thread imageUrl Through to the Student-Facing Response

## Requirements
`GET`/`POST` attempt endpoints return `imageUrl` directly in the `task` JSON for any item that has one — no on-demand endpoint, no extra client round-trip — so a real `DESCRIBE_IMAGE` item's response is directly consumable by a client without any further backend work.

## Steps
1. Add an `imageUrl` field to the `PinnedItemView` cache-projection record (not `imageUrlExpiresAt` — nothing downstream needs it, mirrors `audioUrl`/`audioUrlExpiresAt`'s own asymmetric threading).
2. Update `PinnedSnapshotCacheService.toView` (the `PinnedItem` → `PinnedItemView` builder) to pass `item.getImageUrl()` through.
3. Add an `imageUrl` field to the exam-delivery `TaskView` response DTO.
4. Update `AttemptMapper.toTaskResponse` to thread `item.imageUrl()` into the `new TaskView(...)` construction.
5. Do a mechanical arity-fix pass across every existing test that constructs `PinnedItemView`/`TaskView` by position (starting with `AttemptMapperTest.java`'s `toTask` helper) so the suite compiles and passes again.
6. Add a new `AttemptMapperTest` case asserting `imageUrl` flows unchanged from `PinnedItemView` to the returned `TaskView`, and that a null `imageUrl` (any non-image task type) stays null.
7. Confirm the Redis cache round-trip (`PinnedSnapshotCacheService.write`/`read`, JSON-serialized) preserves the new field correctly — either via an existing cache-service test extended for it, or a direct read of the (de)serialization logic confirming it's field-name-driven with no allowlist that would need updating.

## Success Criteria
- `services/exam-delivery` full test suite passes, including the new/updated tests above.
- A `TaskView` built from a `PinnedItemView` with a non-null `imageUrl` carries that exact value through unchanged; one built from a null `imageUrl` carries null through unchanged.
- No other test in the module was left broken by the widened constructors (verified by a full test run, not just the directly-touched files).

## Risks
- MEDIUM: widening two shared DTOs' positional constructors is a mechanical but wide-blast-radius change — mitigated by running the full exam-delivery suite (not just the directly-touched test files) before considering this phase done.
- LOW: the Redis JSON cache round-trip could silently drop an unrecognized/new field if the (de)serializer used an explicit allowlist rather than reflecting the record's fields — mitigated by Step 7's explicit confirmation.
