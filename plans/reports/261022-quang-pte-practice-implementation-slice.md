# PTE Practice implementation slice

**Date:** 22 October 2026  
**Owner:** Ngô Đăng Quang  
**Scope:** Initial implementation from `quang-pte-practice-completion`

## Implemented

- Added independent practice and exam availability flags for question revisions, with a migration-safe explicit decision marker and legacy pool backfill.
- Added practice session media references and restricted evaluation snapshots for approved reference answers, correct answers and option identities. These fields stay out of student delivery and review responses.
- Added an opt-in practice-only Gemini adapter. The default language is Vietnamese, English is selectable, the rubric version is pinned, and qualitative rubric feedback is returned without an official PTE score.
- Added persisted, language-specific explanation snapshots keyed by the submitted answer hash. Reopening a review reads the stored snapshot instead of calling Gemini again.
- Added Phase 6 durable explanation processing: a database job and outbox are committed with the request, RabbitMQ carries only the durable job id plus its run token and published attempt count, workers claim with a lease token, late workers are fenced, retry attempts are bounded, failed leases are recovered, and idempotency keys are rejected when reused for another student explanation.
- Added attempt-aware DLQ fencing and an effective lease calculation that covers one configured provider call before a worker can be reclaimed; each retry clears the old lease and is scheduled as a new durable attempt.
- Added owner-scoped review and explanation endpoints and a Student review page after session completion.
- Added provider configuration placeholders to `.env.example`; the feature remains disabled unless explicitly enabled.

## Verification

- Backend clean compile: passed after the final lease and DLQ fencing changes.
- Backend full suite: 2,633 tests, 0 failures, 0 errors, 77 skipped.
- Practice focused suite: 56 tests, 0 failures, 0 errors.
- Practice web typecheck: passed.
- Practice web lint: passed with six pre-existing warnings and no errors.
- Practice web unit suite: 22 tests passed.
- Practice web production build: passed; review route generated.
- Docker Compose configuration validation: passed.

## Remaining planned work

The budget reservation/usage ledger is intentionally not enabled because the plan keeps its quota and retention policy behind the pending D08 approval. Deterministic objective evaluation, full rubric governance, expanded task renderers, progress/Study-Pack/feedback workflows and live provider smoke remain in later phases. No Gemini live call was made during this implementation slice.
