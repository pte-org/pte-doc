# Local Practice question clone verification — 2026-11-07

User authorized cloning the existing 96 approved EXAM questions into independent PRACTICE questions in the local `pte` database (`pte-postgres`). No hosted database was accessed.

- Read `docs/CODING_STANDARDS_API.md`; applied the code-review verification gate.
- Executed [the bounded SQL operation](assets/261107-practice-question-clone/clone-local.sql) first with `commit_clone=false`: 96 question and 264 option inserts, all assertions passed, then ROLLBACK.
- Executed the same operation with `commit_clone=true`: 96 question and 264 option inserts, all assertions passed, then COMMIT.
- Assertions compare every original question row and option to the transaction snapshot, cloned content/answer/media fields, option content including correctness/order/gaps, independent option IDs and question revision groups.
- New questions are APPROVED, current, published, platform owned, `pool=PRACTICE`, `available_for_practice=true`, `available_for_exam=false`, explicit channel flags. Original EXAM rows remain unchanged.
- Prompt and answer text, author, task identity, CEFR, word limits and existing media references are preserved. Media objects are referenced rather than uploaded again. Revision history and AI generation job/slot metadata are not reused.
- The deterministic batch IDs reject duplicate execution; source-count assertions reject a changed dataset. This is a local operation, not a Flyway migration.

Authenticated runtime checks using the student session (no credentials or tokens recorded):

| Check | Result |
|---|---|
| GET student Practice catalog | HTTP 200; all 22 task types RUNNABLE |
| POST catalog/preflight for all 22 task types, declaring their required capabilities | HTTP 200, ready=true, no blocked types or missing capabilities |
| GET student mock-tests | HTTP 200; one published test, 65 items, automatically assembled by existing ensureCapacity behavior |
| Final SQL question totals | 96 EXAM + 96 PRACTICE, all APPROVED/current |
| Final SQL cloned option count | 264 |

Boundary: no application source was changed, so no compile/build suite was run. Session creation, answer submission, microphone/media playback and AI scoring were not exercised; catalog preflight confirms the server content contract, not actual browser device capabilities.
