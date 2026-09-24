# Phase 01 – Scope, all-mode retry contract, and persistence

## Goal

Represent the selected skill scope and all-mode retry count durably on an exam draft, number attempts, and transport both contracts while preserving old-client behavior.

## Requirements

- Add optional `selectedSkills` to create/patch draft requests and return the resolved scope in `SessionResponse` and the TypeScript API client types.
- Add optional `maxRetriesPerStudent` to create/patch draft requests and `SessionResponse`; default omitted values to `0`. It counts retries after the initial attempt, accepts only `0`–`9`, and is configurable in every exam mode.
- Persist the normalized set against new drafts before generation. Use the next migration number after rechecking the current migration head. Do not rewrite historical snapshots or blindly backfill legacy rows whose template reference may be absent; their existing snapshot remains authoritative and scope metadata can remain absent.
- Persist the retry count on `ExamSession` with a database check constraint for `0`–`9`. Add `attemptNumber` to `ExamAttempt` as `NOT NULL` with a positive-value database check; backfill every existing attempt as `1`, replace the `(session_public_id, student_public_id)` uniqueness with `(session_public_id, student_public_id, attempt_number)`, and preserve a single active attempt per student/session through lifecycle locking/validation.
- For create, resolve omitted scope to every section declared by the template/version pinned to the draft. For patch, omitted scope normally preserves the current set; if the template changes, default to all sections in the new pinned template; if mode changes from partial Practice to Mock/Official, reset to full scope.
- A pre-existing DRAFT row with a pinned template but no persisted skill rows resolves to that template's full scope; generated legacy sessions and template-less rows keep their existing snapshot and are not rewritten.
- Accept one or more distinct supported skills for Practice only. Reject empty, duplicate, unsupported, or template-absent selections with a user-actionable validation response.
- For Mock Test and Official Exam, enforce full-template scope in the service even if a client submits a subset.
- Accept retry counts `0`–`9` for `PRACTICE`, `MOCK_TEST`, and `REAL_EXAM`; omission defaults to `0` for legacy clients/sessions.
- On patch, omission preserves the existing retry count, including across a mode change. Changing exam mode still resets partial skill scope to full where required, but does not reset the retry count.
- When a draft changes from partial Practice to Mock/Official and the patch does not explicitly submit a subset, normalize scope to the full template. Reject an explicitly submitted partial set for those modes.
- Preserve draft version checks, tenant checks, exam mode defaults, form/reuse policies, subscription, window, and capacity validation.
- Do not reactivate the legacy `POST /sessions` skills route.

## Likely files

- `pte-api/app/src/main/java/com/pte/session/domain/ExamSession.java`
- `pte-api/app/src/main/java/com/pte/attempt/domain/ExamAttempt.java`
- `pte-api/app/src/main/java/com/pte/session/internal/dto/request/CreateExamDraftRequest.java`
- `pte-api/app/src/main/java/com/pte/session/internal/dto/request/PatchExamDraftRequest.java`
- `pte-api/app/src/main/java/com/pte/session/internal/dto/response/SessionResponse.java`
- `pte-api/app/src/main/java/com/pte/session/internal/mapper/SessionMapper.java`
- `pte-api/app/src/main/java/com/pte/session/internal/service/ExamOrchestrationService.java`
- `pte-api/app/src/main/resources/db/migration/V{next}__exam_session_skill_scope.sql`
- `pte-api/app/src/main/resources/db/migration/V{next}__exam_retry_count_and_attempt_numbering.sql`
- `pte-api/app/src/test/java/com/pte/session/internal/service/ExamOrchestrationServiceTest.java`
- `pte-web/packages/api-client/src/types/scheduling/index.ts`
- Corresponding API-client request functions/types and contract tests.

## Steps

1. Confirm migration head and existing enum/collection persistence conventions; choose a relational mapping that supports an empty legacy skill relation without ambiguity.
2. Add the scope and retry-count fields and additive migrations. Define create and patch resolution separately so an unrelated patch cannot silently widen scope or reset the retry count.
3. Add `attemptNumber` and migrate existing attempts to number `1`; replace the old unique constraint with uniqueness per numbered attempt.
4. Validate mode/scope/retry count before persistence. Persist new drafts with resolved values and preserve expected-version concurrency checks.
5. Update session mapping, response, and API-client types; add request/response serialization and migration tests.

## Tests and exit criteria

- Practice with one skill and with multiple skills persists distinct sections and returns them in the response.
- An omitted scope resolves to the full template scope and matches the previous full-exam behavior.
- Empty/duplicate/unknown/template-absent skills are rejected before generation.
- Mock/Official partial scopes are rejected; full-template scopes are accepted.
- Retry count defaults to `0` for every mode; values below `0`, above `9`, and non-integer inputs are rejected.
- An ordinary draft patch that omits the retry count preserves it, including when changing exam mode.
- Legacy create payloads without scope resolve to the full scope of their pinned template. Existing persisted sessions—including template-less sessions—load without migration failure and retain their existing snapshot unchanged; absent historical scope is represented safely (omitted/null or derived from an existing snapshot query).
- Legacy create payloads and pre-existing DRAFTs without scope resolve to the full scope of their pinned template. Existing generated sessions—including template-less sessions—load without migration failure and retain their existing snapshot unchanged; absent historical scope is represented safely (omitted/null or derived from an existing snapshot query).
- Switching a partial Practice draft to Mock/Official with no explicit partial list restores full scope; explicitly sending a subset in the same patch is rejected.
- Migration runs against the local PostgreSQL schema without changing unrelated rows.
- Draft optimistic-lock conflicts and tenant ownership behavior remain covered.
- All pre-existing attempt rows migrate to `attemptNumber=1`; the schema rejects null/zero/negative attempt numbers, accepts attempt numbers `1` and `2` for one session/student, and still rejects duplicate numbers.
- The database rejects retry counts outside `0`–`9`, matching UI and API validation.

## Design Constraints

- Store a normalized skill set; do not encode it as a comma-separated string or depend on client-only state.
- The pinned template is authoritative for the available skills. Do not accept an arbitrary PTE skill that has no section in that template.
- Additive API compatibility is required. Do not silently change defaults for Mock Test/Official Exam.
- Do not let a request mutate retry counts after the draft has left its editable lifecycle; keep host retry configuration on the session, not client-only state.
- Preserve the user-owned dirty change in `QuestionRepositoryTest.java`.
- Preflight: keep persistence module-owned and additive. Follow `ExamSession`'s explicit JPA table/column mappings, `ExamAttempt`'s relational identity constraints, request validation messages in `SessionConstants`, and hand-written Flyway schema conventions. Current migration head is V64; use the next available version after a final collision check. Store selected skills as normalized rows, not a delimited column. User explicitly selected no unit tests and no quality gate; run the backend compile gate only.

## Quality and Testing State

- Quality: skipped_by_user; decision: user_confirmed_skip.
- Testing: not_started; skipped_by_user per user request. No unit tests created or run.
- Build Gate: passed — `mvnw -pl app -DskipTests clean compile`; API client type-check passed.
