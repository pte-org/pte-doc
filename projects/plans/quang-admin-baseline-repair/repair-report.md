# Admin baseline repair

Date:2026-10-05. User approved a separate repair of the11 failures/errors reported by [phase01 baseline](../quang-admin-commercialization-unhappy-cases/tests/phase-01-baseline-contract-coverage-test-report.json). Scope: Assessment ordering test, Attempt capability/audio tests and Support→Notification module contract. No new commercialization feature, unrelated cleanup, commit, push or deployment.

Status: baseline repair verified, quality re-verification and final code review APPROVED; ready for handoff within this repair scope. Initial source HEAD f070e38, clean; current repair is uncommitted. Original baseline1124 tests:4 failures,7 errors,26 skipped. Historical report stays unchanged; new receipts record new execution.

## Diagnosis and bounded changes

- ModuleStructureTest: support publishes public DTO events/enums consumed by notification, but those subpackages had no Modulith exposed interface. Follow existing reporting/session event and itembank enum package convention using narrowly scoped NamedInterface declarations. Do not OPEN the support module or weaken module verification.
- Assessment: commits1e8fe99/3f5329a intentionally changed section order to Speaking→Listening→Reading→Writing. Updated stale expected order/test name; preserved monotonic section/index checks, added exact section/task sequence assertions using reversed input template. Production order unchanged.
- Attempt capability: startAttempt uses latest-attempt query OrderByAttemptNumberDesc; old mocks used a compatibility alias not invoked by the service. Corrected two stubs, retained failure assertions and added wrong-tenant-before-capability/resume test.
- Attempt audio: client-side navigation now checks requested item membership in the attempt snapshot, not pointer index. Corrected per-test findByPublicId stubs, removed obsolete leniency, preserved replay/expiry assertions and added cross-snapshot-before-cached-replay and same-snapshot-navigation coverage. Production authorization/replay protections unchanged.

## Verification and review

Fresh Java21 verification: targeted31/31 passed,0 failures/errors/skips (25.715s); full app1127 tests,1101 passed,0 failures/errors,26 skipped,BUILD SUCCESS (56.919s). Surefire XML aggregate matches console. See [test report](tests/baseline-repair-test-report.json). Independent final [code review](code-review.md) APPROVED after three quality re-verifications; no weakened assertions or blocking findings.

PostgreSQL opt-in suites remain skipped; no atomicity/migration/runtime browser claims from these passes. Remaining phase01 PostgreSQL evidence and hard-mode confirmation are separate checkpoints; this repair does not complete phase01 or authorize phase02.

Changed API files: three test classes above, plus support/dto/event/package-info.java and support/domain/enums/package-info.java. No billing/business service, database migration, web source or existing ModuleStructureTest modification. Backend compile ran javac on961 production sources with release21 and passed15.984s.

Prior receipt freshness: three historical quality receipts covering modified tests were found invalid after current changes. Replacement reports/receipts under this repair folder were issued and verified VALID, retaining original artifacts and unresolved runtime/scale/browser debt:

- [Support handoff](quality/phase-04-validation-and-handoff-quality-report.json).
- [Deterministic generation](quality/phase-05-deterministic-generation-and-forms-quality-report.json).
- [Snapshot capability](quality/phase-04-snapshot-capability-contract-quality-report.json).

Current phase01 reporting-state replacement receipt also verified VALID. Do not treat historical fingerprints as current approval or baseline green as production sign-off. No source changes after final review. Commit proposal only: `fix(test): align baseline fixtures and expose support event contracts`; no commit/push performed.
