# Phase 3: AI Scoring Route Coverage Skeleton

## Requirements

Extend the existing RabbitMQ AI path to cover the seven Speaking response
types and the three written/free-text types. Centralize the catalog so the
dispatcher and worker cannot disagree about whether a task is supported or
which modality client should receive it.

## Steps

1. Add `AiScoringTaskCatalog` with immutable speech/text sets and null-safe
   `supports`, `isSpeech`, and `isText` helpers.
2. Replace the dispatcher-local two-type set with the catalog and reject
   unsupported dispatch calls before mutating answer state.
3. Update the worker to use explicit modality classification and reject an
   unsupported job instead of defaulting to essay scoring.
4. Add unit tests for all ten task types, the unscored Personal Introduction,
   null/unknown values, dispatcher job publication, and worker modality
   routing/terminal handling.
5. Run compile, focused tests, full scoring reactor and final diff review.

## Quality and Testing State

- Quality gate: approved; no blocker/high/medium findings.
- Testing: focused route tests passed 10/10; clean full scoring reactor passed
  88/88 tests with no failures or skips.
