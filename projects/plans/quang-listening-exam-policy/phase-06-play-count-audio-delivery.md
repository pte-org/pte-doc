# Phase 6: Play Count Enforcement & Audio URL Resolution

**Covers:** FR-06, FR-07 · User stories: P1 (replay limit enforcement), P2 (infrastructure for audio delivery)
**Depends on:** Phase 4 (policy pinning), Phase 5 (device check gate)

---

## Requirements

Add a `playCount` integer field to `TimerState` (initialized to 0 for each task). Reset `playCount` to 0 whenever `currentOrderIndex` advances to a new task (linear listening flow, no back-navigation). Implement an audio-serving endpoint (e.g., `GET /attempts/{id}/item/{itemId}/audio` or similar) that increments `playCount` and rejects the request (without incrementing further) once `playCount` reaches the pinned `maxPlayCount` for that item (or the pinned session-level `ExamPolicy.replayPolicy` limit if the item has no override). Simultaneously, resolve listening audio URLs from the `media` microservice exactly once at `StartAttempt` time, store the resolved presigned URL on `PinnedItem` with a TTL exceeding the session's maximum possible attempt duration, and never re-fetch it during task-serving or play requests.

Maps to: **P1 Story #2 (replay enforcement), P2 Story #1 (item-level override precedence), Infrastructure (immutable audio URLs)**

---

## Design Constraints

- `playCount` is task-local (per listening item within an attempt), not global — it resets to 0 when the student advances to the next task.
- Limit precedence is: pinned item `maxPlayCount` (if not null) > pinned session `ExamPolicy.replayPolicy` (if item has no override). UNLIMITED never rejects.
- Audio URL is fetched once at StartAttempt, stored on `PinnedItem`, and never re-fetched. There are no runtime calls to `media` service for URL resolution during task-serving.
- Audio URL TTL is derived from the session's own opening window (`closesAt - opensAt`), not a separate per-attempt duration field (none exists on `ExamSession`) — this is deliberately generous (the full window a student could open the session in, not just how long one attempt takes) and therefore always safely exceeds any single attempt's actual duration. TTL failure mid-attempt must be logged and returned as a clear error, not a silent fallback.
- The audio-serving endpoint must be transactional and atomic: check playCount limit, increment if under limit, and return URL (or reject) as a single operation to prevent race conditions (e.g., two concurrent plays both reading playCount=0, both incrementing). This is enforced via a mandatory pessimistic row lock, not left to transaction isolation defaults (see Step 8).
- The audio-serving endpoint requires a client-supplied idempotency key per play attempt so that network retries or client double-taps never increment `playCount` more than once for the same logical play (see Step 7).
- A composition item missing `audioPromptRef` must fail `StartAttempt` outright — there is no partial-attempt state where some listening items have audio and others silently don't (see Step 5).

---

## Steps

1. Add `playCount: int` (default 0) column to `timer_state` table in exam-delivery (or equivalent timer-state entity).

2. Update the `TimerState` entity to include the new field with getter/setter.

3. Update the timer-advancement logic (wherever `currentOrderIndex` is incremented to move to the next task) to reset `playCount = 0` for the new task.

4. Add `audioUrl: TEXT` (nullable — real presigned URLs with signature query params can run close to 1KB, don't use a short VARCHAR) and `audioUrlExpiresAt: Instant` columns to `pinned_item` table to store the resolved presigned URL and its expiration.

5. At `StartAttempt` time, for each listening item in the composition, first validate that `audioPromptRef` is present and non-null on the `AuthoringSnapshotContentResponse` item — if missing, reject the entire StartAttempt immediately with a clear exception (e.g., "Item {itemId} is missing its audio reference"), without calling `media` at all. For items that do have a reference, resolve the audio URL from the `media` microservice (call `media` API to get presigned URL); calculate TTL as max((session.closesAt - session.opensAt) + grace window, configured minimum); store URL and expiration on `PinnedItem`. If any URL fetch fails (network/4xx/5xx from `media`), reject the entire StartAttempt with a clear exception.

6. Create an internal `PinnedItem` query method `getAudioUrl(itemId)` that returns the stored URL; clients of this method must check expiration before use and log if expired (this should not happen under normal operation).

7. Implement the audio-serving endpoint (e.g., `GET /attempts/{id}/item/{itemId}/audio`) that accepts an authenticated request and a required client-supplied idempotency key (e.g., `X-Play-Request-Id` header, a client-generated UUID per user-initiated play tap). Before doing anything else, check whether this idempotency key was already processed for this attempt+item (e.g., a small `play_request_log` table or a per-item last-seen-key column on `TimerState`); if so, return the previously-computed result (URL or rejection) without incrementing `playCount` again. Otherwise: fetch the current `TimerState` and `PinnedItem` for the current task, check if `audioUrlExpiresAt` is in the future (reject with 410 Gone if expired), check if `playCount < limit` (where limit = pinned item override or session policy), and if so, increment `playCount`, record the idempotency key, and return the audio URL — if at limit, reject with 429 Too Many Requests or 403 Forbidden, referencing the replay limit, and still record the key so a retried rejection stays a rejection.

8. REQUIRED (not optional): the check-and-increment in Step 7 must run inside a single `@Transactional` method that takes a pessimistic write lock on the `TimerState` row (`SELECT ... FOR UPDATE` / `@Lock(LockModeType.PESSIMISTIC_WRITE)`) before reading `playCount`. Do not rely on transaction isolation level alone — two concurrent requests must serialize on this lock so the second one observes the first's incremented value, not a stale read.

9. Integration test: REAL_EXAM mode (LIMITED(1)) — first play succeeds, second play rejects. PRACTICE mode (UNLIMITED) — multiple plays succeed. MOCK_TEST mode (LIMITED(3)) — plays 1–3 succeed, play 4 rejects.

10. Integration test: item with `maxPlayCount=2` override on a REAL_EXAM session (LIMITED(1)) — item allows 2 plays, other items allow 1.

11. Integration test: call audio endpoint after task advance (playCount resets to 0); verify first play of new task succeeds.

12. Integration test: URL expiration — mock the URL to expire and verify the endpoint returns 410 Gone.

---

## Success Criteria

- REAL_EXAM session: second audio-play attempt on the same task is rejected, first is not.
- PRACTICE session: audio-play is not rejected regardless of replay count (up to sane operational ceiling).
- Item-level `maxPlayCount` override is honored over the session-level default when both are set.
- `playCount` resets when the student advances to the next task.
- Audio URL is stored on `PinnedItem` at StartAttempt and never re-fetched.
- Acceptance criteria from spec: "second audio-play attempt on the same task is rejected" (REAL_EXAM), "audio-play is not rejected regardless of replay count" (PRACTICE), "composition-item override is honored."

---

## Quality and Testing State

- Quality: **approved** (report: `quality/phase-06-play-count-audio-delivery-quality-report.json`). 1 HIGH (media's `presignGet()` had no tenant scoping at the data layer — fixed by threading `tenantId` through `InternalMediaController` → `PresignService.presignGet()` → `findByPublicIdAndTenantId`, sourced from `entitlement.tenantId()` on the exam-delivery side). All 7 scrutiny points (trust boundary, TTL cap, concurrency, idempotency scope, sentinel value, exception propagation, dead code) confirmed correct. No cryptographic receipt (multi-repo limitation, see plan.md).
- Testing: not_started — skipped by user for this phase

---

## Session Notes

- **Scope expansion discovered mid-cook**: `media` had no presigned-GET (download) capability at all — only presigned PUT for student upload. Added (user-confirmed): `media`'s first `/internal/**` surface (`InternalMediaController` + `SecurityConfig`'s internal API-key filter chain, mirroring scheduling's identical pattern), `PresignService.presignGet(mediaPublicId, ttlSeconds)` (caps the caller-requested TTL at 24h server-side), and exam-delivery's `MediaClient` to call it. This was necessary for the feature to actually work, not optional polish.
- **Audio requirement scoped by section, not by importing authoring's task-type enum**: rather than importing `authoring`'s `PteTaskType.requiresAudioPrompt()` (would violate the no-cross-service-enum convention), the `audioPromptRef` requirement is gated on `"LISTENING".equals(item.section())`, matching the plain-string-section convention `TimerService` already uses for `SECTION_SCOPED_SECTIONS`.
- **Idempotency implementation**: rather than a separate `play_request_log` table (mentioned as an option in Step 7), used two columns directly on `TimerState` (`lastPlayRequestId`, `lastPlayAllowed`) — sufficient because idempotency only needs to span the current task (already reset alongside `playCount` whenever `TimerService.startTaskTimer` starts a task), not the whole attempt's history.

---

## Risks

- **Concurrency bug in playCount increment — RESOLVED, not a residual risk**: Step 8 now mandates the row lock as a hard requirement rather than a suggestion. Test with concurrent requests (Gatling or JMeter) to confirm the lock actually serializes the two calls rather than both passing the pre-lock read.
- **Audio URL expiration mid-attempt**: If TTL calculation is too short, the URL could expire before the student finishes the task. Mitigation: TTL is derived from `session.closesAt - session.opensAt` (the session's full opening window) plus a 60s grace window — always generous relative to any single attempt's actual duration; log a warning if remaining TTL at play time is less than 5 minutes; add operational monitoring for expired URLs.
- **Media service timeout at StartAttempt**: If fetching audio URLs from `media` takes too long (e.g., DNS resolution, network latency), StartAttempt could timeout. Mitigation: set a reasonable timeout on the HTTP call to `media` (e.g., 5s per URL); if it fails, retry once, then fail the entire StartAttempt; log the failure with the sessionId and itemId for debugging.
- **Stale playCount after crash/restart — RESOLVED, not a residual risk**: Step 7 now requires a client-supplied idempotency key checked before any increment, with the prior result replayed on a duplicate key. This covers both client-side retries and the crash-after-increment-before-response window.
- **Silent ignore of item override**: If the code fetches the pinned session policy but forgets to check the pinned item override, the item override is silently ignored. Mitigation: add explicit test that verifies item override precedence (item override=2 on session default=1); link to Phase 3 in code review to ensure consistency.
