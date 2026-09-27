# Phase 1: Provider Contract, Configuration and HTTP Adapters

## Requirements

Make the AI vendor boundary executable without coupling the worker to a
specific provider. Preserve the deterministic stub as the default, while an
explicit OpenAI-compatible configuration enables authenticated essay and
speech requests with strict response validation.

## Steps

1. Add validated provider properties and mutually exclusive Spring bean
   selection for `stub` and `openai-compatible`.
2. Harden `AiScoreResult` and add an explicit provider exception for malformed
   or unsafe results.
3. Implement the OpenAI-compatible chat transport, essay adapter and
   tenant-scoped speech media download/audio adapter.
4. Update the worker/vendor interfaces without changing answer/event/database
   schemas; keep all ten task routes intact.
5. Add unit tests for valid requests, invalid responses, HTTP errors, media
   resolution and safe stub defaults; run focused and full scoring tests.

## Design Constraints

- Do not hardcode credentials or call a provider unless the provider property
  explicitly selects `openai-compatible`.
- Use `max_tokens >= 800` and JSON response format for the text rubric.
- Send audio through a presigned media URL resolved with the job tenant ID;
  never place raw audio bytes in the transactional answer payload.
- Let provider/network exceptions propagate to the existing RabbitMQ retry and
  DLQ handling.

## Files

- `pte-api/services/scoring/src/main/java/com/pte/scoring/config/AiProviderConfig.java`
- `pte-api/services/scoring/src/main/java/com/pte/scoring/config/AiProviderProperties.java`
- `pte-api/services/scoring/src/main/java/com/pte/scoring/client/MediaClient.java`
- `pte-api/services/scoring/src/main/java/com/pte/scoring/messaging/consumer/AiScoringWorker.java`
- `pte-api/services/scoring/src/main/java/com/pte/scoring/vendor/AiProviderException.java`
- `pte-api/services/scoring/src/main/java/com/pte/scoring/vendor/AiScoreResult.java`
- `pte-api/services/scoring/src/main/java/com/pte/scoring/vendor/SpeechScoringClient.java`
- `pte-api/services/scoring/src/main/java/com/pte/scoring/vendor/stub/StubEssayScoringClient.java`
- `pte-api/services/scoring/src/main/java/com/pte/scoring/vendor/stub/StubSpeechScoringClient.java`
- `pte-api/services/scoring/src/main/java/com/pte/scoring/vendor/openai/OpenAiCompatibleChatClient.java`
- `pte-api/services/scoring/src/main/java/com/pte/scoring/vendor/openai/OpenAiCompatibleEssayScoringClient.java`
- `pte-api/services/scoring/src/main/java/com/pte/scoring/vendor/openai/OpenAiCompatibleSpeechScoringClient.java`
- `pte-api/services/scoring/src/main/resources/application.yml`
- `pte-api/services/scoring/src/test/java/com/pte/scoring/messaging/consumer/AiScoringWorkerTest.java`
- `pte-api/services/scoring/src/test/java/com/pte/scoring/vendor/AiScoreResultTest.java`
- `pte-api/services/scoring/src/test/java/com/pte/scoring/vendor/openai/OpenAiCompatibleEssayScoringClientTest.java`
- `pte-api/services/scoring/src/test/java/com/pte/scoring/vendor/openai/OpenAiCompatibleSpeechScoringClientTest.java`

## Quality and Testing State

- Quality gate: approved; no blocker/high/current-change medium findings.
- Testing: focused adapter tests passed 13/13; clean full scoring reactor passed
  97/97 tests with no failures or skips.
