# Phase 1: Capstone audio scorer for practice speaking

## Goal

Score the 7 speaking task types of practice by sending the recording itself to Capstone, together with the task's Pearson rubric:

- RA: Read Aloud
- RS: Repeat Sentence
- DI: Describe Image
- RL: Re-tell Lecture
- RTS: Respond to a Situation
- SGD: Summarize Group Discussion
- ASQ: Answer Short Question

Personal Introduction stays unscored. Writing types already go through Capstone as text and are unchanged.

## Work

- `StructuredModelClient` / `OpenAiCompatibleStructuredClient` can send an audio part: `{"type":"input_audio","input_audio":{"data":<base64>,"format":"wav"}}`.
  - Normalize the audio with the existing `AudioNormalizer` / `WavEncoder` (16 kHz mono wav).
  - Images (DI) and audio can go in the same request.
- New package `vendor/gateway/audio/` with an abstract `GatewayAudioSpeakingScorer` and one scorer per task type.
  - Each scorer reuses the rubric catalog (`RubricResolver`, `RubricSchemaBuilder`): prompt sections and the JSON schema per trait.
  - **Every trait** comes from the model: Content, Oral Fluency and Pronunciation, on their Pearson scales.
  - The item score is still computed only by `RubricScorer`, so the `RubricScoreSingleSourceTest` ratchet stays green.
  - The source material for the prompt, per task type:
    - RA / RS: the reference text.
    - DI: the image.
    - RL / SGD: the lecture or discussion transcript.
    - RTS: the situation.
    - ASQ: the accepted answers.
- Silence or no speech: score 0 on every trait without a model call. Detect it with the existing `SilenceChunker`.
- Schema retry is bounded like the Gemini scorers. Out-of-scale values are rejected, never rounded.
- Selection:
  - New setting `scoring.ai.practice-speech-vendor` (`gateway` | `azure`, default `gateway`).
  - `PracticeAiScoringService` picks the gateway audio scorer for practice speaking when it is `gateway`.
  - The exam path (`AiScoringRequest` from the exam worker) never sees these scorers.
- Stored model id: `Capstone(audio)`. The stored detail carries the rubric version public id, as today.
- Errors and messages go in `ScoringConstants`.
  - A gateway failure marks the item FAILED with the existing failure codes.
  - There is **no fallback to Azure**.

## Files

- `scoring/internal/vendor/gemini/OpenAiCompatibleStructuredClient.java`, `StructuredModelClient.java`
- `scoring/internal/vendor/gateway/audio/*` (new)
- `scoring/internal/service/ai/PracticeAiScoringService.java`
- `scoring/internal/config/AiProviderProperties.java`, `application.yml`, `.env.example` (`SCORING_AI_PRACTICE_SPEECH_VENDOR`)

## Tests

- Fake gateway tests, one per task type: valid JSON gives the expected traits and score.
- Schema retry.
- Out-of-scale value is rejected.
- Silence scores 0 without a call.
- The practice route uses the gateway scorer; the exam route still uses Azure.
