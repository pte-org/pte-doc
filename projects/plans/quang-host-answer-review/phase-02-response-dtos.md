# Phase 2: Response DTOs and Payload Decoding

## Requirements

Design and implement response DTOs and task-type-aware payload decoders so that ScoringAnswer.payload (raw per-task-type encoding) becomes human-readable answer content (option text, essay body, media IDs for presigning). This phase is a shared foundation: both the list endpoint (Phase 3) and detail endpoint (Phase 4) will use the decoders and DTOs, and Phase 5 (if executed) will reuse them for the enriched approve response.

## Design Constraints

- **Scoring service ownership:** All decoding logic stays in scoring; exam-delivery's encoding is treated as an immutable contract documented in SubmitAnswerRequest (lines 8-36).
- **No cross-service decode verification:** This phase assumes exam-delivery's encoding is correct. If a decode bug is found later, it will be fixed in scoring without re-implementing in exam-delivery.
- **Task-type completeness:** Must support all task types present in the codebase (at minimum: multiple-choice single-select, multi-select, reorder, fill-blanks, essay, free-text, and all audio/image variants). If a task type's encoding is unknown, the decoder must fail gracefully (log and return a fallback like "payload too complex to decode" rather than throw).
- **DTO immutability:** Response DTOs (e.g., AnswerReviewResponse, AnswerPayloadDTO) must be immutable records or final POJOs with no public setters; they are exposed to hosts and must not be accidentally mutated.

## Steps

1. **Review exam-delivery's SubmitAnswerRequest documentation and gather test fixtures** — Confirm the exact encoding for each task type against the live codebase and gather or create test fixtures. Document the encoding in a markdown file in scoring/docs/answer-encoding.md for future reference.

2. **Design the answer review response DTO hierarchy** — Create base AnswerReviewResponse (with answerPublicId, sessionPublicId, taskType, status, rawScore, createdAt, etc.) and task-specific payload DTOs (e.g., OptionSelectionPayload, EssayPayload, AudioPayload) that can be polymorphically serialized to JSON via a @JsonTypeInfo annotation or similar. This allows the detail endpoint to return one response shape with variant content per task type.

3. **Implement payload decoders per task type** — Create an AnswerPayloadDecoder interface with a decode(payload, taskType) method. Implement a switch or strategy-map decoder for each supported task type:
   - Single-select MC: parse decimal index, look up option from optionsJson.
   - Multi-select/reorder: parse comma-joined indices.
   - Fill-blanks: parse positional comma-join (with empty entries).
   - Essay/free-text: return payload as-is (already text).
   - Audio/image: return mediaPublicId from payload (to be presigned in Phase 4).
   Each decoder must handle malformed input gracefully (catch exceptions, log, return a fallback decode result).

4. **Add optionsJson deserialization utility** — ScoringAnswer.optionsJson is a JSON string. Create a utility to deserialize it into a List<OptionDTO> (or similar) with option index, text, and any other metadata. Handle the case where optionsJson is null or malformed.

5. **Create unit tests for all decoders** — For each task type, write a test that verifies correct decoding of a well-formed payload and graceful handling of a malformed one. Use fixtures from exam-delivery if available, or create synthetic ones based on the documented encoding.

6. **Design the list endpoint payload summary** — The list endpoint (Phase 3) will return many answers. Decide whether to include full decoded payloads in the list (verbose, larger response) or a summary (e.g., "answered: option 2", "essay length: 245 chars", "media ID: xyz"). Document this choice in a brief note in this phase's Risks section.

7. **Add exception handling and logging** — Create custom exceptions (e.g., PayloadDecodeException) and catch them in the service layer. Log at WARN if a payload fails to decode (with taskType, answerPublicId, and error message); never expose the raw exception to the host client (return a sanitized message).

## Success Criteria

- AnswerPayloadDecoder interface and implementations for all supported task types are in place and callable.
- All payload decoders have unit test coverage (happy-path and malformed input) with pass rates at 100%.
- optionsJson deserialization utility is testable and handles null/malformed gracefully.
- AnswerReviewResponse DTO (with task-specific payload variants) is defined, serializable to JSON, and used in unit tests.
- Docker-compose and local build complete without errors; no new dependencies introduced that aren't already used elsewhere in pte-api.

## Quality and Testing State

- Quality gate: **approved** (0 blocking, 1 LOW found and fixed inline — `AUDIO_ANSWER_TASK_TYPES.contains(null)` would NPE via `Set.of(...)`'s null-rejecting `contains()`; guarded before the lookup). Design deviation from this file's original suggestion: implemented as one concrete `AnswerPayloadDecoder` service class (mirrors `ObjectiveScoringService`'s shape) + one flat record with mutually-exclusive fields (mirrors `TaskView`'s convention), not a Strategy-map + `@JsonTypeInfo` polymorphic hierarchy — no precedent for the latter anywhere in this codebase. Report: `quality/phase-02-response-dtos-quality-report.json`. Receipt skipped (cross-repo boundary, same as Phase 1).
- Testing: **not started** — user declined unit tests for this phase onward (`ok tiếp tục, k cần viết unitest nhưng phải quality lại chất lượng code`).

## Risks

- **HIGH: Payload encoding format differs from documentation** — If exam-delivery's actual encoding diverges from what's documented in SubmitAnswerRequest, decoders will fail silently or produce garbage. Mitigation: sample real payloads from scoring's ingested data to verify they match the documented format before implementation. Add a property-based test that generates payloads from exam-delivery's encoder and verifies scoring's decoder is an inverse function.

- **MEDIUM: optionsJson structure unknown or inconsistent** — optionsJson might not exist in some ScoringAnswers, or the structure might vary by task type. Mitigation: inspect sample ScoringAnswers' optionsJson; if structure varies, document each shape and handle each in the deserializer. If optionsJson is consistently null, the detail endpoint will fall back to displaying option indices only (acceptable UX, not a blocker).

- **MEDIUM: Decode performance on large essay/free-text answers** — Decoding a 5000-word essay on every list request (if payloads are included in list) could be slow at scale. Mitigation: Implement list endpoint to return payload summary or omit payloads entirely, and decode only on the detail endpoint. This decision is made explicitly in Step 6 and justified in this Risks section.

- **LOW: New task types added later without decoder updates** — If new task types ship (e.g., the remaining 7 unconfigured Listening types once their task-timing gap is separately closed), old decoders won't know how to handle it. Mitigation: AnswerPayloadDecoder must have a clear contract and catch-all for unknown types (log unknown type at WARN, return a safe fallback result, never throw).
