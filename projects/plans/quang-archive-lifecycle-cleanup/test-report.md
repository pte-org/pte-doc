# Verification report — 2026-10-05

Verdict: scoped lifecycle checks passed; full backend regression FAILED. Phases 01–04 complete; phase 05 executed but incomplete. No release-ready or production verification claim.

## Fresh evidence

| Check | Result |
|---|---|
| Phase 01 policy tests | 3 passed |
| Phase 02 original targeted matrix | 29 passed |
| Phase 03 original matrix | 37 passed; current matrix 38 with wrong-tenant tombstone case |
| Relevant backend unit/HTTP/history/enrollment matrix | 165 passed, 0 failures/errors/skips |
| PostgreSQL lifecycle + legacy migration suites | 12 passed, 0 failures/errors/skips |
| Repeated real-DB race interleavings | 40: 10 issue/archive, 10 issue/entitlement edit, 10 delete/activate, 10 question delete/submit |
| API-client tests | 381 passed, including 4 DELETE/204/conflict/archive contract cases |
| Browser fixtures | 21 checks passed; desktop1440 and mobile375, admin and tenant Remove text |
| Typecheck | API-client, vendor, tenant passed |
| Lint | Vendor/tenant passed; 2 existing image warnings + 1 existing unused-variable warning |
| Production web builds | Vendor and tenant passed; existing absolute turbopack.root warning |
| Backend compile | Passed, release target21; actual test runtime Java24.0.1, not verified on Java21 runtime |
| Final full backend suite with PostgreSQL opt-in | 1124 tests: 1099 passed, 4 assertion failures, 7 errors, 14 skipped; exit1 |
| Clean HEAD comparison | Same 11 failing cases reproduced; 25 tests, 4 failures, 7 errors, 0 skipped |
| Whitespace/diff validation | Backend and web git diff --check passed |

Counts in different rows overlap; do not add them as one unique-test total. The14 full-suite skips belong to existing inbox tests, not lifecycle PostgreSQL suites.

## PostgreSQL evidence

Isolated PostgreSQL17 at loopback55439, database lifecycle_test, schema migration_clean. URL allowlist prevents tests from targeting development/production databases. No existing data was changed.

- Clean Flyway applied migrations1–77; Hibernate schema validate passed against real migrated schema.
- Separate unique legacy schema migrated to76, inserted APPROVED/DRAFT/ARCHIVED fixtures, then migrated77. Legacy APPROVED=true; other states unknown. Status-only old writers and an attempted false reset cannot erase true publication provenance.
- Tombstone and exactly one audit survive commits/repeat DELETE; normal details/batch/list/generation reads hide removed records.
- Cancelled order/expired code references still block draft deletion. Audit failure rolls deletion back.
- A stale detached Question cannot overwrite committed tombstone; existing optimistic version rejects it.
- Subscription expiry/cap/usability and paid receipt amount/currency/status survive Plan retirement.
- Persisted snapshot retains prompt/options/source ID/score-template pin after Question archive; source deletion rejected. Fixture scalar template/blueprint IDs are synthetic: not full publishing/scoring E2E.

## Commands

Backend cwd: pte-api.

~~~powershell
.\mvnw.cmd -pl app '-Dtest=PlanServiceTest,LicenseCodeServiceTest,LicenseCodePersistenceServiceTest,OrderServiceTest,OrderPersistenceServiceTest,SubscriptionActivationServiceTest,ItembankServiceTest,QuestionDeletionServiceTest,QuestionLifecyclePolicyTest,QuestionControllerSecurityTest,PlanControllerTest,DraftDeletionHttpContractTest,ProgramServiceTest,ClassServiceTest,SnapshotPublishServiceTest,SnapshotPromptQueryServiceTest,SnapshotMapperTest,SnapshotPinServiceTest' test
.\mvnw.cmd -pl app -DskipTests compile
# Isolated container must be running and migration_clean already migrated:
.\mvnw.cmd -pl app '-Dtest=ArchiveLifecyclePostgresIntegrationTest,QuestionPublicationMigrationPostgresTest' '-Dlifecycle.test.db.url=jdbc:postgresql://127.0.0.1:55439/lifecycle_test?currentSchema=migration_clean' test
.\mvnw.cmd -pl app '-Dlifecycle.test.db.url=jdbc:postgresql://127.0.0.1:55439/lifecycle_test?currentSchema=migration_clean' test
~~~

Web cwd: pte-web. Ran api-client typecheck/test, vendor/tenant exec tsc --noEmit, lint and build. Browser script temporary per Playwright skill:

~~~powershell
# cwd: .codex/skills/playwright-skill
node run.js C:/Users/ADMIN/AppData/Local/Temp/playwright-test-archive-lifecycle.js
~~~

Browser mocks cover capability/state matrix, one pending DELETE, Cancel/X/Escape guards, retained409 dialog, retry204 removal, conflict refetch, archive route, Remove labels, no page overflow375 and no uncaught exceptions. No real JWT authorization proof. HTTP standalone MVC tests204/403/404/409 responses, not JWT filters/method security.

## Full regression failures — identical on clean HEAD

Clean detached worktree: C:/Users/ADMIN/AppData/Local/Temp/pte-api-lifecycle-baseline-20261005, HEAD906345c09d13092d4ae310b5f6dfaf15b1b631b8. XML failing-case identities compared, not inferred from file ownership.

- ExamGenerationServiceTest.generate_orderIsSpeakingWritingReadingListening_thenBySequence
- AttemptLifecycleCapabilityTest.existingStart_checksCapabilitiesAfterOwnershipBeforeResume
- AttemptLifecycleCapabilityTest.start_repeatsAuthoritativeCheckAndStoresNormalizedFingerprint
- AttemptLifecycleServicePlayAudioTest.playAudio_replayLimitExceeded_throws
- AttemptLifecycleServicePlayAudioTest.playAudio_audioUrlExpired_throws
- AttemptLifecycleServicePlayAudioTest.playAudio_unlimitedPolicy_neverRejects
- AttemptLifecycleServicePlayAudioTest.playAudio_sameRequestIdReplayed_doesNotIncrementAgain
- AttemptLifecycleServicePlayAudioTest.playAudio_firstPlay_incrementsPlayCount
- AttemptLifecycleServicePlayAudioTest.playAudio_locksExamAttemptRow_neverTouchesTimerService
- AttemptLifecycleServicePlayAudioTest.playAudio_publicLegacyAudio_ignoresStaleExpiryTimestamp
- ModuleStructureTest.modules_have_no_boundary_violations

Observed groups: exam ordering; attempt capability fixture/snapshot/unnecessary stubbing; playAudio NOT_CURRENT_TASK versus expected replay/expiry; notification-to-support non-exposed module types. Fixing them is outside lifecycle scope. No assertions weakened/deleted to obtain green results.

## Browser artifacts / probe exclusions

Temporary screenshots: archive-plans-desktop.png, archive-plans-mobile.png, archive-questions-desktop.png, archive-questions-mobile.png, archive-tenant-remove.png in C:/Users/ADMIN/AppData/Local/Temp. All inspected. Mobile tables retain existing local horizontal scroll.

ui-ux probe widths375/1440 against /admin/plans without session redirected to login. Output: C:/Users/ADMIN/AppData/Local/Temp/archive-lifecycle-ui-probe/report.json. P1 placeholder contrast2.83:1, P2 Forgot password target and P3 password-toggle target are existing login findings outside scope, not dashboard failures. Focus rings preserved.

## Remaining limitations

- No authenticated live browser/API E2E or development DB/app restart performed.
- Question publish/revision/reference-creation races not individually exercised; protected histories conservatively blocked and supported freeze requires published/current content.
- Enrollment semantics/races unchanged; existing Program/Class service regression passed.
- Quality approval inline/source-scoped. Full regression FAILED until separately resolved; phase05 incomplete.
- No commit, push, deployment or production data mutation.
- Temporary test container codex-archive-lifecycle-pg was stopped after identity-label verification; its test data was retained. The clean detached HEAD worktree remains available for comparing failure evidence. Neither is a production environment.
