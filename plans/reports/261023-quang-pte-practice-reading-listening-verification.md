# PTE Practice — Reading and Listening Verification

**Date:** 23 October 2026  
**Scope:** Reading and Listening practice only  
**Environment:** Local Docker Compose stack  
**Status:** Reading verified; Listening blocked by missing practice content

## 1. Scope decision

This verification intentionally covers only Reading and Listening. Speaking and
Writing are deferred to a later pass because their audio and AI feedback flows
require a longer end-to-end setup.

## 2. Runtime readiness

- `pte-platform-app-1` reported `healthy` after the local backend rebuild; the deterministic answer-key snapshot migration is `V128__practice_objective_options_snapshot.sql`.
- The Student Practice application loaded at `http://localhost:3000/practice-tests`.
- The local practice entitlement and student account were already available.
- A published local rubric for `MC_READING_SINGLE` was created through the Vendor Admin rubric flow so the Reading session could be pinned to a compatible rubric revision.

## 3. Reading verification

### Test case R-01 — Multiple-choice Reading (Single), correct answer

**Session:** `f05c7403-d66e-497e-b3b1-44bc546219fa`

1. Opened Practice tests.
2. Confirmed **Multiple-choice Reading (Single)** was available to start.
3. Created a one-task practice session.
4. Began the session and received the question and four answer options.
5. Selected the answer matching the published option key.
6. Selected **High confidence**.
7. Submitted the answer.
8. Opened Practice review.

**Observed result:**

- Session completed successfully.
- Review showed `ANSWERED`.
- Review showed `Objective result: 100/100`.
- The student response displayed only the safe option data; answer-key flags were not returned to the browser.

### Defect corrected during verification

The first Reading run returned `0/100` for a correct selection because the
student-safe option snapshot intentionally removed the answer key, while the
deterministic scorer still needed that key. The implementation now stores a
separate backend-only objective option snapshot and normalizes the JSON answer
payload before scoring. Migration `V128` adds the backend-only snapshot column.
Legacy unfinished objective sessions are handled through an explicit discard
path rather than being scored with an incomplete answer key.

## 4. Listening verification

### Test case L-01 — Listening catalog and startability boundary

The catalog endpoint returned HTTP `200`, but every Listening task was marked
non-runnable because no persisted practice question content was available.

For example, **Multiple-choice Listening (Single)** returned:

- `availability: VISIBLE`
- `unavailableReason: PRACTICE_UNSUPPORTED_RUNTIME`
- `contentStatus: RUNTIME_ONLY_NO_PERSISTED_CONTENT`
- `provenance: PERSISTED_CANONICAL_CATALOG`

The UI consequently rendered the task as **Unavailable** with a disabled start
button. No Listening session was started because the runtime correctly prevents
a session from being created without practice content.

## 5. Validation evidence

### Backend

```text
./mvnw.cmd -pl app clean -DskipTests compile
./mvnw.cmd -pl app '-Dtest=ModuleStructureTest,PracticeMigrationVersionTest,PracticeQuestionServiceTest,PracticeSessionServiceTest,ObjectiveScoringServiceTest,PracticeRubricBindingServiceTest,RubricDocumentValidatorTest,RubricLifecycleServiceTest' test
./mvnw.cmd -pl app test
```

Results:

- Targeted tests: **71 passed, 0 failed, 0 errors, 0 skipped**.
- Full app suite: **not green in this worktree**. The run reached test
  compilation and reported three unrelated AssertJ generic compilation errors
  in `BillingPlatformOverviewQueriesTest`, `AdminSectionCacheRoundTripTest`,
  and `AdminCommercialSectionsTest`; it reported **2,646 tests discovered, 77
  skipped**, with no Reading/Listening practice test failure. The scoped
  practice suite above remains green.

### Student Practice frontend

```text
npm run typecheck
npm run test:unit
```

Results:

- Typecheck passed.
- Unit tests: **22 passed across 8 files**.

The Next.js development server emitted its known instant-navigation validation
messages for the practice routes. The messages did not prevent catalog loading,
session submission, review rendering, or the Reading score check.

## 6. Remaining work

To verify Listening end to end, the content team must provide at least one
approved question in the practice pool with its audio prompt and a compatible
published rubric. After that data is available, repeat the same session,
answer, deterministic scoring, and review checks used for Reading.

This report records local verification only. It does not claim production
readiness, deployment, or completion of the deferred Speaking and Writing
flows.
