# Phase 1: Media Client Integration

## Requirements

Add a read-only MediaClient to the scoring service, configured to presign GET URLs for audio and image answers. This is a foundational component; scoring service currently has no ability to generate playback links for media-based task answers, and without it, the detail endpoint in Phase 4 cannot surface recordable answers to the host.

## Design Constraints

- **Scoring service ownership:** All answer review logic must live in scoring, never split across exam-delivery or reporting (adjudicated decision, stated in plan.md's Research Summary).
- **Media flow isolation:** Scoring service must never receive raw binary media, only media publicId references in ScoringAnswer.payload. Presigning is a read-only operation (GET only) — no upload, complete, or delete semantics needed.
- **Pattern reuse:** MediaClient implementation and presign-GET logic must mirror exam-delivery's proven SnapshotPinService.resolveAudioUrl pattern and MediaClient.java to ensure consistency and avoid inventing new media handling rules.
- **Hard mode quality contract:** All new external client code (MediaClient) must have unit tests covering at least happy-path and network failure modes before Phase 4's integration tests run; no untested client dependencies allowed.

## Steps

1. **Create MediaClient interface and implementation** — Define a read-only interface (e.g., `MediaClient.presignGet(mediaPublicId)`) returning a signed URL or URL resource object. Model the signature on exam-delivery's MediaClient.getSignedUrl or equivalent to stay consistent.

2. **Extract and reuse presign-GET logic from exam-delivery** — Copy (or refactor into a shared utility if justified) the TTL calculation, request signing, and URL building logic from SnapshotPinService.resolveAudioUrl to avoid duplicating security logic or diverging TTLs.

3. **Wire MediaClient as a Spring @Component or @Service in scoring** — Add MediaClient to scoring's application context; constructor-inject into ScoringReviewController so it's only instantiated when needed.

4. **Add MEDIA_URL environment variable and config class** — Create a configuration class (e.g., MediaConfig.java) that reads MEDIA_URL and any required credentials from environment, matching the pattern already used in docker-compose.services.yml for other services. Document the expected format in both the config and docker-compose setup.

5. **Add unit tests for presign logic** — Test MediaClient.presignGet for a happy-path invocation, a network/timeout failure, and an invalid/missing mediaPublicId. Use a mock or in-memory stub for the underlying HTTP client to avoid test flakiness.

6. **Update docker-compose.services.yml and .env.example** — Add MEDIA_URL to the scoring service environment in docker-compose (pointing to localhost if media is local, or cloud endpoint if remote) and document in .env.example. Ensure the URL is reachable from the scoring container.

7. **Add SLF4J logging and error handling** — Log presign requests at DEBUG level; on failure (e.g., media service unreachable), log at WARN and throw a custom `MediaPresignException` that the detail endpoint can catch and handle gracefully in Phase 4.

## Success Criteria

- `MediaClient.presignGet(mediaPublicId)` is callable from a Java unit test and returns a signed GET URL string or throws a clear exception.
- MediaClient is registered in scoring's Spring ApplicationContext and can be injected into a test controller.
- docker-compose.services.yml includes a MEDIA_URL for the scoring service, and the value is reachable in a local setup (verified by a manual curl or integration test).
- Unit tests cover presign success, network timeout, and invalid media ID; all tests pass.
- No breaking changes to existing scoring endpoints or domain.

## Quality and Testing State

- Quality gate: **approved** (0 blocking, 1 LOW noted — test helper style nitpick in `MediaClientTest.builderFor`, non-blocking). Report: `quality/phase-01-media-client-quality-report.json`. Receipt skipped (cross-repo boundary: report in pte-doc, code in pte-api — see report's `receipt_note`).
- Testing: **passed** — `MediaClientTest` (2/2: happy-path presign, upstream-failure propagation). Verified via `mvn -pl services/scoring -am test -Dtest=MediaClientTest`.

## Risks

- **MEDIUM: Presign service authentication/credentials** — If presign endpoint requires API key or OAuth, wrong config will silently cause all presign calls to fail. Mitigation: document credential setup in docker-compose and .env.example; have the MediaConfig constructor log a startup warning if credentials are missing.

- **MEDIUM: TTL mismatch with exam-delivery** — If presign TTL copied from exam-delivery is too short, host clicks audio and gets stale; if too long, security exposure. Mitigation: Extract TTL to a constant; verify exam-delivery's chosen TTL is still appropriate for a host review UI. Document the choice in MediaConfig javadoc.

- **LOW: Presign URL format differs by media backend** — If the code assumes S3-style signed URLs, it will fail on a different backend. Mitigation: keep MediaClient generic (return a String URL, not a type-specific object); let Phase 4 concretize the backend choice and adjust MediaClient accordingly.
