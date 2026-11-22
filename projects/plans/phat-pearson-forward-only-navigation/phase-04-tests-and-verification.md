# Phase 4: Tests and Verification

## Requirements
The forward-only flow is covered by automated tests on both sides and verified through the Docker compose stack plus a short manual checklist.

## Files to touch
- pte-api tests: scoring tests from Phase 1 only (no navigate/policy tests change in the slim plan).
- pte-app tests: `test/unit/features/exam_attempt/exam_attempt_bloc_test.dart`, `test/unit/sync/sync_engine_test.dart`, `test/widget/features/exam_attempt/task_advance_button_test.dart`, plus the cubit/widget tests from Phases 2-3.
- No production code except fixes found by these checks.

## Steps
1. Run the full pte-api test suite; confirm nothing outside scoring changed behaviour.
2. Run `flutter analyze` and the full `flutter test`; fix regressions in screens that referenced removed flags.
3. Fill any gap against the success criteria of Phases 1-3 (blank scoring, idempotent Next, cooldown, rowless/synced Next, recording interrupt).
4. Rebuild and start the API through the three-file compose setup (arm64 target, no host-run) and confirm startup.
5. Give the user a manual checklist (they do UI checks themselves; remind them to take a `pg_dump` into `db-backups` first; ask before any DB write): rapid double-tap Next on each section (no skipped question); Next on an untouched task in each section, then Next on the following task (no error); Next mid-recording; Next mid-audio (Listening and prompt audio); last task shows Submit and no Next; blank Speaking/Writing answer scores 0 with no Azure/Gemini call (mock or credit-approved run only); Reading → Listening transition works.
6. Record results in each phase's Execution Log; do not commit (the user commits).

## Success Criteria
- `./mvnw test` (pte-api, Maven) exits 0.
- `flutter analyze` and `flutter test` (pte-app) exit 0.
- Manual checklist: 0 skipped-question incidents in 20 rapid double-taps per section; partial recording shows as an answer; blank tasks score 0.

## Risks
- Manual checks depend on the seeded flow-test data (23 questions, 1 per type, plus host template, examiner/proctor); do not run real Azure scoring without the credit estimate and user OK.
- Local media may 404 (known parked issue); use items with working media for Speaking/Listening checks.
- Offline behaviour is intentionally not verified (out of scope).

## Execution Log
<!-- Filled by /ck:cook at the end of this phase — leave placeholders when planning -->

### Errors Encountered
- None in Phase 4. Observation: `flutter analyze` (whole project) reports 14 issues (2 warnings, 12 infos) in `test/widget/app_routes_test.dart` and `test/widget/app_shell_test.dart`; neither file is modified in this change set (`git status`), so they predate it. `flutter analyze lib` is clean.

### Root Cause
- N/A (pre-existing lint in two untouched test files).

### Resolution
- N/A; left untouched on purpose (out of scope).

### Test Results After Fix
- `./mvnw test` (pte-api) -> exit 0; surefire totals: 5590 run, 0 failures, 0 errors, 102 skipped. Tests use the H2/test config; local `pte-postgres` still has its 66 public tables.
- `flutter analyze lib` (pte-app) -> No issues found
- `flutter test -r failures-only` (pte-app) -> 864 passed, 0 failed
- Compose (`docker compose -f docker-compose.yml -f docker-compose.services.yml -f docker-compose.local-test.yml up -d --build app`, no migrations in this change, no DB writes) -> `pte-platform-app-1` healthy, `Started PteApplication in 15.2 s`, no ERROR lines in the log.
- Manual UI checklist: handed to the user (not run by me).
