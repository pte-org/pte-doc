# Phase 9: Integration Testing & Documentation

## Requirements

Verify the entire PTE platform pivot end-to-end through comprehensive integration and regression testing. A student must be able to complete a full mock exam covering all 22 task types, receive AI-scored Speaking/Writing results, and see a final score report in the official PTE 10–90 scale, all without errors. Simultaneously, update all documentation to reflect PTE Academic scope (replacing APTIS-era content), version the codebase, and prepare for release. This phase includes final security/access-control audits and hand-off to operations.

This is the final quality gate before release; all P1 user stories and Success Criteria from plan.md must be verified to pass.

## Design Constraints

**Correction (2026-07-16, discovered during Phase 7 research):** the task-type count is **22**, not 20 — see `spec.md` Assumptions. `pte-task-types.md` (Step 5) must catalog all 22.

- **Zero regressions:** All existing tests for `iam`, `tenancy`, `proctor`, `examdelivery` must pass unchanged. Any new failures indicate a breaking change in Phases 1–8 (escalate immediately).
- **End-to-end is non-negotiable:** At least one full exam attempt must complete successfully with Speaking, Writing, and objective tasks, resulting in a valid score report.
- Documentation must be **internally consistent** — if docs say "timers enforced per-task" but code doesn't, docs must be updated, not vice versa (code is source of truth).
- APTIS-era content must be **archived, not deleted** — preserve the old spec/SRS/glossary in `pte-doc/legacy/` for historical reference and thesis context.
- **Release readiness** includes: all phases merged to main branch, version tag (e.g., v0.1.0-pte), deployment runbook, ops handoff checklist.
- **Deployment order is mandatory and sequenced, never parallel:** (1) run Flyway schema migrations against the database — blocking, must complete before step 2; (2) deploy `pte-api` (the new schema-dependent code); (3) deploy `pte-app`/`pte-web` (which consume the updated `pte-api` contract). `pte-api` must implement a startup fail-fast check (verify expected schema version/columns exist) so a misordered deploy fails loudly instead of throwing runtime null-pointer errors on missing columns.

## Steps

1. Create a comprehensive integration test suite: write test cases for all major user journeys:
   - Exam creation (admin creates exam with 22 PTE task types).
   - Exam attempt lifecycle: student starts exam → completes all tasks → submits → receives report.
   - Speaking task submission: audio recorded and uploaded → queued for scoring → scored within 1 minute → score appears in report.
   - Writing task submission: essay submitted → queued for scoring → scored within 1 minute → 4 sub-scores appear in report.
   - Objective task submission: multiple-choice/fill-in-blank submitted → immediately scored → score appears in report.
   - Final report generation: Overall + 4 communicative skills + 6 enabling skills all displayed in 10–90 scale.
   - Proctor actions: force-submit, extend-time, flag-violation work correctly on PTE attempts.
   - Multi-tenant isolation: exam data for tenant A is not accessible to tenant B.
   Each test should be self-contained (setup data, execute, assert, teardown).

2. Run all existing regression tests (phases 1–8 new code, plus unchanged modules):
   - `pte-api` unit tests (all modules: questionbank, examoperations, examdelivery, proctor, iam, tenancy, storage, asset).
   - `pte-app` widget and integration tests.
   - `pte-web` component and integration tests.
   - Must achieve >90% pass rate; investigate and fix any failures (or escalate if failures are environment issues, not code).

3. Perform a compatibility audit on the PTE domain model: verify that all 22 task types are correctly stored, retrieved, and rendered without errors. Check that Questions created in Phase 1 can be used to build Exams in Phase 2, submitted in Phase 8, and scored in Phases 4–6. Check that old APTIS question data (if migrated) doesn't interfere with PTE questions.

4. Conduct an end-to-end security audit:
   - Verify multi-tenant isolation: attempt to access exam/question data from another tenant (should fail).
   - Verify role-based access control: student cannot access admin functions; admin cannot take exams as a student (unless role allows).
   - Verify audit trails: all scoring, proctor, and attempt changes are logged with timestamps and user IDs.
   - Verify data encryption: sensitive data (audio files, essays) are encrypted at rest and in transit (HTTPS, DB encryption).

5. Rewrite documentation:
   - Update `pte-doc/architecture.md` to reflect new PTE exam structure, scoring pipeline, multi-skill-per-task model.
   - Create `pte-doc/pte-score-report.md`: explains PTE 10–90 scale, communicative skills, enabling skills, how scores are computed.
   - Create `pte-doc/pte-task-types.md`: catalog of all 22 task types with descriptions, interaction patterns, timing, skills assessed.
   - Create `pte-doc/operations.md`: runbook for running the scoring pollers, handling vendor API issues, manual re-scoring, troubleshooting, and the stuck-scoring-job alert/recovery procedure introduced in Phases 4–5 (alert thresholds, how to trigger the manual `ScoringUnavailable` recovery action).
   - Archive APTIS-era content to `pte-doc/legacy/aptis-lms-spec.md` (move, not delete). Add a note: "APTIS exam format is superseded by PTE Academic (v0.1.0+). This document is retained for historical context."
   - Update `pte-doc/README.md` to explain that this is now a PTE exam simulator, not APTIS.

6. Conduct a performance and load test: simulate 10–20 concurrent student exams. Measure:
   - Exam submission latency (should be <500ms).
   - Scoring pipeline throughput (can pollers process 20 answers/minute?).
   - Final report generation latency (should be <1s).
   - Database query counts and slow-query logs.
   Document bottlenecks and recommendations for post-release optimization.

7. Create a deployment and release checklist, enforcing the sequenced order from Design Constraints:
   - Step 1 (blocking): database schema migrations applied (Flyway scripts validated) — verify via migration status check before proceeding.
   - Step 2: deploy `pte-api` with the fail-fast schema-version startup check enabled; verify it starts successfully against the migrated schema.
   - Step 3: deploy `pte-app`/`pte-web` only after `pte-api` step 2 is confirmed healthy.
   - Configuration values set (vendor API credentials, timing config, SLA settings) — credentials via environment variables/secrets manager per Phase 3's constraint, never in code or committed config.
   - Secrets (API keys, DB passwords) stored in secure vault (not in code).
   - All environment variables documented.
   - Deployment runbook tested on staging environment, exercising the full sequenced order above (not a parallel/simultaneous deploy).
   - Rollback procedure documented (how to restore to previous version if issues occur), including how to roll back a schema migration safely if `pte-api` step 2 fails its health check.

8. Perform a final manual QA pass: team members manually complete a full exam attempt on both pte-app and pte-web, check that timers work, scores are correct, report is readable. Test on real devices/browsers if possible (not just emulators/dev tools). Document any manual test results.

## Success Criteria

- **End-to-end exam attempt**: A student completes an exam with Speaking, Writing, and objective tasks; all responses are scored correctly; final report displays Overall + 4 communicative skills + 6 enabling skills, all in 10–90 range. No crashes, timeouts, or null-pointer exceptions.
- **Regression tests**: All existing tests for `iam`, `tenancy`, `proctor`, `examdelivery` pass without modification (zero regressions).
- **Integration test coverage**: All major user journeys (exam creation, attempt, scoring, report, proctor actions, multi-tenant isolation) have passing integration tests.
- **Security audit**: Multi-tenant isolation verified, role-based access control verified, audit trails logged, data encrypted.
- **Documentation**: Architecture docs updated to reflect PTE structure, score report documented, task types cataloged, operations runbook provided. APTIS docs archived to `/legacy/`. No contradictions between code and docs.
- **Performance baseline**: Exam submission <500ms, scoring pipeline throughput documented, report generation <1s.
- **Deployment readiness**: Schema migrations tested, configuration and secrets documented, deployment runbook tested on staging.

## Quality and Testing State

- Quality gate: evaluated by Cook's `/ck:quality --gate` after implementation
- Testing: comprehensive (integration tests for all user journeys, regression tests on all modules, security audit, performance test, manual QA)

## Risks

- **HIGH: Integration Test Flakiness** — Integration tests that depend on external vendors (speech/essay scoring APIs) may be flaky if vendor API is slow or unreliable during test runs. Tests may pass on Tuesday and fail on Wednesday without code changes. *Mitigation:* Use vendor sandboxes or mock APIs for integration tests (not production APIs). Implement test retry logic (run test 2x if it fails, fail only if both fail). Log all flaky test results for analysis.

- **HIGH: Performance Not Meeting Requirements** — End-to-end exam may be slower than expected (>5 seconds per submit, report generation >10 seconds). If performance is unacceptable, significant optimization or architecture changes may be needed. *Mitigation:* Performance testing (step 6) must happen early in Phase 9, not at the end. If bottlenecks are found (e.g., N+1 database queries, slow vendor API), address immediately (optimize queries, add caching, reduce vendor calls).

- **MEDIUM: Regression Test Failures on Unchanged Modules** — iam/tenancy/proctor tests may fail due to indirect dependencies or test environment issues (DB cleanup, transaction isolation, timing issues). Difficult to determine if failure is a code regression or test environment issue. *Mitigation:* Run regression tests in clean environment (fresh DB snapshot, no parallel tests). Investigate each failure carefully; don't assume "test is flaky" without evidence. Escalate architectural issues (e.g., "tenancy module doesn't work with PTE questions") to phase review.

- **MEDIUM: Manual QA Coverage Gaps** — Manual QA (step 8) is effort-intensive and may miss rare edge cases. Relying solely on manual testing is risky. *Mitigation:* Prioritize manual testing on high-risk areas (audio recording, timer expiration, scoring PENDING state display). Run automated tests to cover common paths. Document manual test cases so they can be repeated by others or automated later.

- **MEDIUM: Documentation Debt vs. Development Debt** — Updating all documentation takes time and may block release if incomplete. *Mitigation:* Start documentation updates early (in Phases 4–7, not waiting for Phase 9); use living documentation (wiki/markdown in repo) that is updated as code changes; assign documentation owner(s) who stay up-to-date.

- **LOW: Version Control Merge Conflicts** — If Phases 1–8 are developed in parallel branches (e.g., in Parallel mode), merging all changes to main may have conflicts (especially on `Question` schema, `AttemptAnswer` fields, reporting APIs). *Mitigation:* Coordinate branch merges (weekly or bi-weekly integration sessions); use feature flags to avoid breaking main while branches are in progress; test merged code on staging before declaring Phase 9 "done".

