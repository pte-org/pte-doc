# Plan: AI Provider Contract and OpenAI-Compatible Adapters

**Date:** 2026-09-13
**Status:** Phase 1 complete; provider calibration remains
**Mode:** Hard
**Scope:** `pte-api/services/scoring`

## Objective

Replace the implicit deterministic-only vendor boundary with an explicit,
provider-neutral contract and an opt-in OpenAI-compatible HTTP adapter for the
ten AI-routed task types. Keep `stub` as the safe default so local development
and existing queue tests never make a network call or spend provider credits.

This phase makes the adapter executable when configured, but does not claim
PTE calibration or vendor-specific production approval. Provider selection,
credentials, model choice and rubric validation remain deployment decisions.

## Phases

- [x] Phase 1: Provider contract, configuration and HTTP adapters — validate
  provider results, add essay and speech adapter boundaries, route beans by
  `SCORING_AI_PROVIDER`, and cover request/response/error behavior with unit
  tests. [quality: approved; testing: passed 97/97 reactor tests]

## Design Constraints

- `stub` remains the default and must make no network call.
- `openai-compatible` is the only real-provider mode in this phase. It uses
  an OpenAI-compatible `/chat/completions` endpoint, an environment-provided
  API key, and JSON-only scoring output.
- Speech scoring resolves the answer media through the existing tenant-scoped
  `MediaClient`, downloads the presigned bytes, and sends audio as base64 to
  the provider. The transactional answer API and event/database schemas stay
  unchanged.
- Provider output must contain an integer `rawScore` in 0–100. Invalid JSON,
  missing score, out-of-range score or invalid subscore is a retryable scoring
  error; no fabricated fallback score is allowed.
- Candidate text/audio is untrusted input. Rubric prompts must delimit it and
  instruct the model to return only the scoring JSON object.
- API keys must come only from configuration/environment and must never be
  logged, committed or included in test fixtures.
- Existing RabbitMQ retry/DLQ behavior remains the failure boundary; no retry
  policy or persistence schema redesign is included.

## Success Criteria

- Existing stub mode passes unchanged and creates no HTTP request.
- OpenAI-compatible essay and speech adapters send the expected authenticated
  JSON request and parse a valid `AiScoreResult`.
- HTTP failures and malformed provider responses throw an explicit provider
  exception so the worker retry/DLQ path handles them.
- Both adapter beans are mutually exclusive with stubs through configuration.
- Existing scoring behavior plus new adapter tests pass with no skipped tests.

## Explicitly Deferred

- Vendor-specific speech pronunciation/fluency calibration and official PTE
  score correlation.
- Provider cost/latency benchmarking, rate-limit strategy and secret manager
  integration.
- Score aggregation/reporting and complete authoring seed/content migration.

## Quality and Testing State

- Quality gate: approved. See `quality/phase-01-provider-contract-and-adapters-quality-report.json`.
- Testing: focused adapter tests passed 13/13; clean full scoring reactor passed
  97/97 tests with no failures or skips. See
  `tests/phase-01-provider-contract-and-adapters-test-report.json`.
