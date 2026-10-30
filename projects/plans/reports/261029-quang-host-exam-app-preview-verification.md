# Quang — host exam app preview verification

Date: 2026-10-29

## Scope and evidence boundary

This report covers the host-only, read-only exam preview and the
`SESSION_PREVIEW_READY` inbox event. The quality gate was explicitly skipped
by Quang. Tests were run and their exact skips/failures are recorded below.

No credentials, tokens, `.env` values, production data, Docker rebuild, DB
reset, commit, push, or deployment was used.

## Verification results

| Area | Command / check | Result |
|---|---|---|
| pte-app | `flutter test` | PASS — 634 tests, 0 failures |
| pte-app | `flutter analyze` | EXIT 1 — one pre-existing `unnecessary_cast` warning at `lib/features/exam_attempt/data/repositories/exam_attempt_repository_impl.dart:63`; no new preview analyzer issue reported |
| pte-app | `flutter build windows --release` | PASS — `build/windows/x64/runner/Release/pte_app.exe` |
| pte-api | `mvnw.cmd -pl app -DskipTests compile` | PASS |
| pte-api | initial `mvnw.cmd -pl app test` | EXIT 1 — 2,916 tests, 1 failure, 1 error, 59 skipped; failure was the 304-line `ExamPublishService`, error was the existing `assessment -> attempt -> assessment` Modulith cycle |
| pte-api | focused rerun after line-limit fix: `SourceFileSizeTest,ExamWorkflowServicesTest,InboxNotificationRequestedTest,ExamPreviewReadyNotificationListenerTest` | PASS — 65 tests, 0 failures/errors/skips |
| pte-api | `mvnw.cmd -pl app -Dtest=ModuleStructureTest test` | EXIT 1 — 3 tests, 1 error; existing cycle and boundary violations remain outside this preview change |
| pte-api | `mvnw.cmd -pl app -Dtest=InboxDeliveryStorePostgresIntegrationTest test` | PASS process, but 12/12 tests SKIPPED because `INBOX_TEST_DB_URL`, `INBOX_TEST_DB_USER`, and `INBOX_TEST_DB_PASSWORD` were unavailable; this is not PostgreSQL/Flyway proof |
| pte-web | `pnpm --filter @pte/api-client test` | PASS — 624 tests |
| pte-web | `pnpm --filter @pte/api-client typecheck` | PASS |
| pte-web | `pnpm --filter @pte/ui test` | PASS — 298 tests |
| pte-web | `pnpm --filter @pte/ui typecheck` | PASS |
| pte-web | tenant/vendor typecheck | PASS — both packages |
| pte-web | tenant/vendor lint | PASS — vendor reports 2 existing `@next/next/no-img-element` warnings in questionbank components; no errors |

Earlier phase evidence remains valid:

- Phase 3 focused app preview suite: 49 pass; full Flutter suite: 634 pass.
- Phase 4 API focused suite: 63 pass; web notification test: 4 pass; API-client,
  tenant-web, and vendor-web typechecks pass.

## Functional evidence

The automated app suite covers host routing, mixed-role host precedence,
student security-coordinator lifecycle, read-only preview repository calls,
temporary audio cleanup, local RAM-only answer/navigation/timer behavior,
widget navigation, and the 22 canonical task codes.

The automated API/web suite covers DRAFT-to-READY event emission, READY replay
without a second event, `SESSION/SESSION` notification mapping, active
HOST_ADMIN tenant scoping, stable notification identity, shared notification
type transport, and existing SESSION target routing.

The tenant-member guard was added after review: a member returned with a
different tenant id cannot receive the preview-ready notification.

## Explicitly unverified boundaries

- No live PostgreSQL/Flyway upgrade was proven because the documented test DB
  environment was absent.
- No live API/network trace or quota delta was collected. Therefore the report
  does not claim actual runtime proof of zero attempt, answer, upload, scoring,
  or quota writes; those properties are covered by source/contract/unit tests
  only.
- Windows packaging was verified, but host READY login, audio playback,
  recording, Next/Finish, logout, and subsequent student login were not
  manually executed because no controlled test identities/session/media
  environment was supplied.
- No student lockdown was activated during verification.

## Handoff decision

Implementation and automated tests are ready for Quang's manual UAT. Before
calling the feature production-ready, run the controlled Postgres/Flyway and
Windows host/student smoke checks listed above, then review the Modulith cycle
and existing analyzer warning separately.
