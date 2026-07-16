# Phase 3: AI Scoring Research & Architecture

## Requirements

Evaluate available AI vendors and approaches for automated speech scoring (fluency, pronunciation, accent assessment) and essay scoring (grammar, vocabulary, written discourse, spelling). Select vendors based on accuracy, latency, cost, and availability. Design thin, modality-specific wrapper interfaces that abstract vendor details so later phases (4–5) can plug in actual vendor integrations without rearchitecting the scoring pipeline.

This phase is a research-spike that unblocks Phases 4 and 5; it delivers decision rationale and skeleton wrapper code, not production-grade scoring results.

## Design Constraints

- Wrapper design must be **thin and single-vendor per modality** (one speech-scoring wrapper, one essay-scoring wrapper) — no attempt to support multiple vendors or a generic provider-abstraction layer. Only add multi-vendor support if a second vendor is actually added in the future.
- Vendor selection must prioritize **available APIs / SaaS services**, not self-hosted or offline models (thesis project constraints on compute/deployment budget).
- Wrappers must follow **async design principles**: they return immediately with a job/ticket ID, not block on vendor response. Phases 4–5 handle polling/retry.
- Wrapper interfaces must be **language/framework agnostic at the contract level**: define a clear input schema (audio bytes for speech, essay text for writing) and output schema (fluency score, pronunciation score, etc.). Implementation is Java/Spring, but the interface should be portable.
- **Vendor API credentials must never be stored in source code or committed config files.** All credentials are injected via environment variables or a secrets manager (e.g., a `.env` file excluded from git for local dev, a real secrets manager for any deployed environment) — this is a non-negotiable constraint that applies starting with the skeleton wrappers in this phase, not deferred to Phase 9's deployment checklist.

## Steps

0. Evaluate the API credential the user already has ("opencode", to be provided at phase start) as a candidate first: confirm which underlying provider/API it grants access to, and whether it covers speech fluency/pronunciation scoring, essay scoring, or both. Use it as the default choice for whichever modality it covers (subject to the same PoC quality/latency bar as any other candidate in Steps 3–4); research free-tier alternatives for any modality it doesn't cover.

1. Research available speech-scoring (ASR + fluency/pronunciation assessment) vendors: evaluate OpenAI Whisper (ASR only, quality but no fluency scoring), Google Cloud Speech-to-Text (ASR), Azure Cognitive Services Speech (ASR + fluency), specialized ELT vendors (e.g., Versant by Pearson, ELSA, Speechling, Ivy AI). Document pros/cons (latency, cost, quality, support for accents, PTE alignment). Identify top 2–3 candidates.

2. Research available essay-scoring vendors: evaluate OpenAI GPT (general essay scoring, must calibrate to PTE rubric), AWS Comprehend (basic NLP, not essay-specific), specialized essay-scoring platforms (e.g., Turnitin (now iThenticate), Grammarly API, ETS e-rater proxy, or open-source models like Hugging Face transformers). Document pros/cons.

3. Conduct a latency and quality proof-of-concept: select the top candidate for each modality (speech and essay). Prepare 5–10 sample audio files (read-aloud and speak-to-image) and sample essays. Submit samples to each vendor's API and measure latency (average, p95, p99), cost per submission, and output quality (do scores make intuitive sense?). Document results in a research summary.

4. Select one vendor for speech scoring and one for essay scoring based on PoC results. Document selection rationale: why this vendor over others (latency, cost, accuracy, support, documentation, SLA).

5. Design the speech-scoring wrapper interface: define input contract (audio file URL or base64 bytes, task type, optional reference text) and output contract (json with speechCorrectness, fluencyScore, pronunciationScore, prosodyScore, vocabulary, grammar, errorDetails). Design error handling (timeout, API unavailable, malformed audio).

6. Design the essay-scoring wrapper interface: define input contract (essay text, task type, optional rubric guidelines) and output contract (json with grammarScore, vocabularyScore, writtenDiscourseScore, spellingScore, overallQuality, errorFlags). Design error handling.

7. Implement skeleton wrapper classes in Java/Spring (stub methods that return mock data or placeholder values). These classes should be in a new `scoring.vendor` package with clear abstraction (e.g., `SpeechScoringVendor` interface, `OpenAIWhisperSpeechScoringAdapter` implementation). No actual vendor API calls yet; focus is on the interface and input/output shapes. Wire credential loading through Spring `@Value`/`@ConfigurationProperties` bound to environment variables from the start, even though the skeleton doesn't call a real API yet — this avoids a later refactor once Phase 4/5 add real calls.

8. Write a research report (Markdown, in the pte-doc repo) documenting vendor candidates, PoC results, selection rationale, and skeleton wrapper design. This report is input for thesis advisor review and is referenced in Phase 9 (documentation).

## Success Criteria

- A research report is documented and committed to pte-doc: lists 3+ candidate vendors for each modality, includes PoC latency/cost results, explains selection decision, and is signed off by the implementer (or advisor if applicable).
- Skeleton wrapper classes exist in pte-api (`src/main/java/com/example/pte/scoring/vendor/`) with clear interfaces for speech and essay scoring; no vendor API calls yet.
- Input and output schemas for each wrapper are documented (JSON examples); implementation in later phases must conform to these contracts.
- All skeleton wrappers return mock/placeholder data (e.g., randomized scores between 0–100); they compile and pass a basic unit test (mock data validation).
- Selection decision for speech and essay vendors is documented and agreed (captured in commit message or PR description) by the team/advisor.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started (Unit tests for wrapper interfaces and mock data will be written during implementation; integration tests with actual vendor APIs come in Phase 4–5)

## Risks

- **HIGH: Vendor Availability & Cost** — Selected vendors may have API rate limits, quota restrictions, or unexpected cost at scale. If a vendor is selected and later proves too expensive or unavailable, rework in Phases 4–5 is needed. *Mitigation:* PoC must include cost estimation (cost per call × expected exam volume) and check vendor documentation for rate limits and SLAs; negotiate pilot pricing with vendor if possible; build cost monitoring into the scoring pipeline (Phase 4–5).

- **HIGH: Speech/Essay Scoring Quality Misalignment** — AI vendors may not score in alignment with official PTE rubrics. A vendor's "fluency score" may not correlate with Pearson's scoring model. *Mitigation:* PoC must include manual comparison (hand-score 5 samples with PTE rubric, compare to vendor scores, measure Spearman correlation); if correlation is poor (<0.7), escalate to advisor and consider different vendor or hybrid human+AI approach.

- **MEDIUM: Latency Variability** — PoC latency results (5–10 samples) may not reflect sustained load (100+ exams/day). PoC finds average latency; actual p99 latency under load may be 10x higher. *Mitigation:* PoC should include load testing if possible (vendor provides sandbox); if not, design Phase 4–5 scoring pipeline with retry/backoff to handle latency spikes; document expected latency in Phase 9.

- **MEDIUM: Vendor API Documentation Gaps** — Selected vendor may have poor documentation or unclear error codes. Implementation in Phases 4–5 may hit unexpected API behaviors. *Mitigation:* During vendor selection, review documentation quality and vendor support options; prioritize vendors with good SDKs or community libraries; plan for a spike task in Phase 4–5 to resolve API surprises.

- **LOW: Wrapper Interface Instability** — Skeleton wrappers designed in this phase may need refactoring once actual vendor integration begins. *Mitigation:* Interfaces are documented and reviewed; keep wrappers simple (input → vendor call → output) to minimize rework.

