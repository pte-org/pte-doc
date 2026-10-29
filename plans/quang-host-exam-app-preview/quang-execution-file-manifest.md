# Quang — execution file manifest
Execution inventory and handoff record. Phases 1-4 are completed; Phase 5 is
in progress while final evidence and plan status are recorded.

## Source owner map
API session/controller/preview owns host reads. Assessment owns public snapshot/timing seam.
Attempt consumes public resolved data without exporting internal repositories.
Notification owns enum, listener, inbox, delivery and Flyway allowlist.
App auth owns route selection; exam_preview owns local state/resources; student feature owns persistence.
Web api-client owns types; tenant notifications own existing consumers; common UI owns generic controls.

## Required fill-in columns
For every source/test/docs file: phase, absolute path, exists/new, reason, touched domain owner,
unrelated dirty hunks to preserve, verification command. List every extraction file too.
Identify exact shared assessment resolver DTO/service names, app domain/data/DI/state files,
runtime/timing parity tests, HTTP DTO client types, common UI changes (if any), Flyway next version,
notification controller/repository test cases, and IAM/auth docs needing update.
Do not write a placeholder migration path to code or plan.json.
Existing old phase output lists were seed inventory and must be refined before source writes.

## Baseline checkpoint
Populate each repository HEAD/branch, staged/unstaged/untracked status and relevant baseline checks.
Keep all credentials out.
Record approved five-path cleanup diff/backup/restore evidence in reports/preflight, not here.

## Plan cross references
quang-agent-handoff.md is the normative detailed contract.
quang-acceptance-matrix.md is the verification checklist.
plan.json and phase JSON files track execution status and must be validated after updates.

## Phase 1 checkpoint — 2026-10-29

Baseline branches/HEADs and dirty scopes:

| Repository | Branch / HEAD | Dirty scope to preserve |
|---|---|---|
| `pte-app` | `quang/maintain-v2` / `35ed2ca90e83b6cf24170975c234e3649938fa96` | Reviewed five-path temporary security flag was backed up and discarded; no other dirty path. |
| `pte-api` | `quang/feat/maintain-v2` / `60ea3043504cf47b934ec5f58d2ed10115abd68e` | `db/dev-seed/*`, dirty/untracked V7/V8 work, local seed scripts/reports. |
| `pte-web` | `quang/feat/maintain-v2` / `3275bb2a5133babc8b518ad976dc8f2e496ea1be` | Existing tenant/vendor exam, student-search, score-template, UI and staged test changes. |
| `pte-doc` | `quang/feat/maintain-v2` / `9aa81cec5eb90a8160ecd01045ff7425a8891eab` | This plan bundle and reports. |

The preflight report and recoverable patch are the evidence for the approved
discard. No implementation agent may use `git reset`, `git checkout`, `git
clean`, whole-file restore, database reset, Docker rebuild, commit, push or
deploy as part of this plan.

## Ownership and exact migration reservation

- `assessment` owns the public read-only runtime resolver/DTO; `attempt`
  consumes it; `session` never imports `attempt.internal`.
- `session` owns tenant-owned GET list/detail/preview and answer stripping.
- `exam_preview` owns RAM answers, navigation, local timers, media/recorder
  lifecycle and DI; it has no attempt/outbox/upload dependency.
- `session` emits the public preview-ready event; `notification` owns inbox
  enum/mapping/listener/dedup/migration; recipient is the generating actor.
- `@pte/api-client` owns DTO/union types; the existing common bell/history/read
  transport is reused without a second channel or UI clone.

Migration enumeration found V1 through V8. V7 and V8 are dirty/untracked user
work and must not be edited. The next reserved filename is:

`D:/GitHub/pte-org/pte-api/app/src/main/resources/db/migration/V9__allow_session_preview_ready_notification.sql`

It may only replace the notification type CHECK allowlist with old values plus
`SESSION_PREVIEW_READY`; no V1 edit, data reset or preview table is allowed.

## Exact Phase 1 artifacts

| Path | State | Purpose / evidence |
|---|---|---|
| `D:/GitHub/pte-org/pte-doc/plans/reports/261029-quang-host-exam-app-preview-preflight.md` | new | Standards, session check, repository baseline, role matrix, discard and mocked baseline tests. |
| `D:/GitHub/pte-org/pte-doc/plans/reports/261029-quang-host-exam-app-preview-contract.md` | new | DTO/timing/nullability/error/role/tenant/actor contract. |
| `D:/GitHub/pte-org/pte-doc/plans/reports/assets/261029-quang-host-exam-app-preview-preflight/pte-app-security-flag-before-discard.patch` | new | 7,819-byte staged+unstaged patch; stat/reverse checks exit 0. |
| `D:/GitHub/pte-org/pte-doc/plans/quang-host-exam-app-preview/quang-execution-file-manifest.md` | modified | This exact inventory. |

## Phase 2 — API/runtime and client inventory

Modify/create only these source/test paths after a fresh phase diff check:

```text
D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/assessment/AssessmentService.java
D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/assessment/dto/response/ResolvedExamItemResponse.java
D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/assessment/internal/config/TaskTimingConfig.java
D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/assessment/internal/service/ExamItemRuntimeResolver.java
D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/assessment/internal/exception/content/TaskTimingNotConfiguredException.java
D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/assessment/internal/constant/AssessmentConstants.java
D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/attempt/internal/config/TaskTimingConfig.java [delete after move]
D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/attempt/TaskTimingCatalog.java
D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/attempt/internal/service/ExamItemLoader.java
D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/session/internal/dto/response/ExamPreviewResponse.java
D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/session/internal/service/draft/SessionExamPreviewService.java
D:/GitHub/pte-org/pte-api/app/src/test/java/com/pte/assessment/internal/config/TaskTimingConfigTest.java [move]
D:/GitHub/pte-org/pte-api/app/src/test/java/com/pte/attempt/internal/config/TaskTimingConfigTest.java [delete after move]
D:/GitHub/pte-org/pte-api/app/src/test/java/com/pte/attempt/internal/service/ExamItemLoaderTest.java
D:/GitHub/pte-org/pte-api/app/src/test/java/com/pte/attempt/internal/service/TimerServiceTest.java [verify/modify only if required]
D:/GitHub/pte-org/pte-api/app/src/test/java/com/pte/assessment/internal/service/ExamItemRuntimeResolverTest.java
D:/GitHub/pte-org/pte-api/app/src/test/java/com/pte/session/internal/service/draft/SessionExamPreviewServiceTest.java
D:/GitHub/pte-org/pte-api/app/src/test/java/com/pte/session/internal/service/draft/HostExamPreviewReadOnlyTest.java
D:/GitHub/pte-org/pte-web/packages/api-client/src/types/scheduling/index.ts
D:/GitHub/pte-org/pte-web/packages/api-client/src/requests/scheduling/sessions.ts [verify; modify only if required]
D:/GitHub/pte-org/pte-doc/plans/reports/261029-quang-host-exam-app-preview-contract.md
```

The moved timing config keeps the current JSON/resource and behavior. The
resolver DTO is application-internal despite its assessment package; it is not
serialized as a public answer-bearing response. The session DTO remains the
only host wire shape and excludes answer keys/correctness.

## Phase 3 — app inventory

Existing files to modify:

```text
D:/GitHub/pte-org/pte-app/lib/main.dart
D:/GitHub/pte-org/pte-app/lib/app.dart
D:/GitHub/pte-org/pte-app/lib/features/auth/domain/exam_access_policy.dart
D:/GitHub/pte-org/pte-app/lib/features/auth/presentation/bloc/auth_bloc.dart
D:/GitHub/pte-org/pte-app/lib/core/di/security_module.dart
D:/GitHub/pte-org/pte-app/lib/core/security/violation_retry_coordinator.dart
D:/GitHub/pte-org/pte-app/test/unit/features/auth/domain/exam_access_policy_test.dart
D:/GitHub/pte-org/pte-app/test/unit/features/auth/auth_bloc_test.dart
D:/GitHub/pte-org/pte-app/test/widget/app_auth_gate_test.dart
```

New feature/source/test files:

```text
D:/GitHub/pte-org/pte-app/lib/features/exam_preview/exam_preview_module.dart
D:/GitHub/pte-org/pte-app/lib/features/exam_preview/domain/entities/host_exam_summary.dart
D:/GitHub/pte-org/pte-app/lib/features/exam_preview/domain/entities/preview_snapshot.dart
D:/GitHub/pte-org/pte-app/lib/features/exam_preview/domain/repositories/host_exam_preview_repository.dart
D:/GitHub/pte-org/pte-app/lib/features/exam_preview/data/models/host_exam_summary_model.dart
D:/GitHub/pte-org/pte-app/lib/features/exam_preview/data/models/preview_snapshot_model.dart
D:/GitHub/pte-org/pte-app/lib/features/exam_preview/data/repositories/host_exam_preview_repository_impl.dart
D:/GitHub/pte-org/pte-app/lib/features/exam_preview/data/preview_audio_session.dart
D:/GitHub/pte-org/pte-app/lib/features/exam_preview/presentation/cubit/host_exam_list_cubit.dart
D:/GitHub/pte-org/pte-app/lib/features/exam_preview/presentation/cubit/host_exam_list_state.dart
D:/GitHub/pte-org/pte-app/lib/features/exam_preview/presentation/cubit/host_exam_preview_cubit.dart
D:/GitHub/pte-org/pte-app/lib/features/exam_preview/presentation/cubit/host_exam_preview_state.dart
D:/GitHub/pte-org/pte-app/lib/features/exam_preview/presentation/model/preview_task_ui_model.dart
D:/GitHub/pte-org/pte-app/lib/features/exam_preview/presentation/model/preview_task_ui_adapter.dart
D:/GitHub/pte-org/pte-app/lib/features/exam_preview/presentation/pages/host_exam_list_screen.dart
D:/GitHub/pte-org/pte-app/lib/features/exam_preview/presentation/pages/host_exam_preview_screen.dart
D:/GitHub/pte-org/pte-app/lib/features/exam_preview/presentation/widgets/host_preview_task_dispatcher.dart
D:/GitHub/pte-org/pte-app/lib/features/exam_preview/presentation/widgets/host_preview_navigation.dart
D:/GitHub/pte-org/pte-app/lib/features/exam_preview/presentation/widgets/preview_answer_controller.dart
D:/GitHub/pte-org/pte-app/lib/features/exam_preview/presentation/widgets/preview_media_status.dart
D:/GitHub/pte-org/pte-app/test/unit/core/security/violation_retry_coordinator_test.dart
D:/GitHub/pte-org/pte-app/test/unit/features/exam_preview/data/host_exam_preview_repository_impl_test.dart
D:/GitHub/pte-org/pte-app/test/unit/features/exam_preview/data/preview_audio_session_test.dart
D:/GitHub/pte-org/pte-app/test/unit/features/exam_preview/presentation/model/preview_task_ui_adapter_test.dart
D:/GitHub/pte-org/pte-app/test/unit/features/exam_preview/presentation/cubit/host_exam_list_cubit_test.dart
D:/GitHub/pte-org/pte-app/test/unit/features/exam_preview/presentation/cubit/host_exam_preview_cubit_test.dart
D:/GitHub/pte-org/pte-app/test/widget/features/exam_preview/host_exam_list_screen_test.dart
D:/GitHub/pte-org/pte-app/test/widget/features/exam_preview/host_exam_preview_screen_test.dart
```

The existing common templates/components are read-only dependencies. The new
dispatcher must compose them; if a coupled widget must be extracted, add its
exact path here before editing it and preserve student appearance.

## Phase 4 — event, inbox, Flyway and web inventory

```text
D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/session/dto/event/ExamPreviewReadyEvent.java
D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/session/internal/service/draft/ExamPublishService.java
D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/notification/domain/enums/InboxNotificationType.java
D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/notification/InboxNotificationRequested.java
D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/notification/internal/constant/InboxConstants.java
D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/notification/internal/listener/ExamPreviewReadyNotificationListener.java
D:/GitHub/pte-org/pte-api/app/src/main/resources/db/migration/V9__allow_session_preview_ready_notification.sql
D:/GitHub/pte-org/pte-api/app/src/test/java/com/pte/session/internal/service/ExamWorkflowServicesTest.java
D:/GitHub/pte-org/pte-api/app/src/test/java/com/pte/notification/InboxNotificationRequestedTest.java
D:/GitHub/pte-org/pte-api/app/src/test/java/com/pte/notification/internal/listener/ExamPreviewReadyNotificationListenerTest.java
D:/GitHub/pte-org/pte-api/app/src/test/java/com/pte/notification/internal/repository/InboxDeliveryStorePostgresIntegrationTest.java
D:/GitHub/pte-org/pte-web/packages/api-client/src/types/notification/index.ts
D:/GitHub/pte-org/pte-web/packages/api-client/src/requests/notification/inbox.test.ts
```

`NotificationBellContainer.tsx`, `NotificationHistoryView.tsx`,
`features/notifications/api.ts`, `packages/ui/src/components/NotificationCenter.tsx`
and `packages/ui/src/i18n/LocaleProvider.tsx` are audited read-only consumers;
edit them only if typecheck proves an exhaustive map requires it, then record
the path before writing. Existing SESSION target routing must remain unchanged.

## Phase 5 — documentation and evidence inventory

```text
D:/GitHub/pte-org/AGENTS.md
D:/GitHub/pte-org/pte-app/README.md
D:/GitHub/pte-org/pte-doc/plans/reports/261029-quang-host-exam-app-preview-verification.md
D:/GitHub/pte-org/pte-doc/plans/quang-host-exam-app-preview/quang-acceptance-matrix.md
```

README/AGENTS updates must describe HOST_ADMIN preview separately from normal
student delivery and must not restore a global release security bypass.

## Verification boundary

API: Maven compile, focused resolver/preview/notification tests, full default
suite, and actual Flyway/Postgres suites when the documented test DB exists.
App: `flutter analyze`, focused tests, `flutter test`, and Windows release
build only on supported tooling. Web: api-client/UI/tenant/vendor typechecks,
actual scoped lint and notification tests. Run `git diff --check` per repo.
Quality gate is explicitly skipped by Quang; unit tests remain required and
their exact exit codes/skips must be recorded. No credentials, tokens or `.env`
values may enter source or reports.

## Phase 5 actual outputs

| Path | State | Purpose / evidence |
|---|---|---|
| `D:/GitHub/pte-org/AGENTS.md` | modified | Documents authenticated HOST_ADMIN read-only preview separately from student delivery. |
| `D:/GitHub/pte-org/pte-app/README.md` | modified | Documents preview boundaries, local-only answers/audio, role/tenant enforcement, and student lockdown preservation. |
| `D:/GitHub/pte-org/pte-doc/plans/reports/261029-quang-host-exam-app-preview-verification.md` | new | Exact Phase 5 command results, skips, failures, and handoff boundary. |
| `D:/GitHub/pte-org/pte-doc/plans/quang-host-exam-app-preview/quang-acceptance-matrix.md` | modified | Acceptance status/evidence ledger and explicit 22-code fixture-vs-live boundary. |
| `D:/GitHub/pte-org/pte-api/app/src/main/java/com/pte/notification/internal/listener/ExamPreviewReadyNotificationListener.java` | modified | Final tenant-member guard; never accepts a recipient returned for another tenant. |
| `D:/GitHub/pte-org/pte-api/app/src/test/java/com/pte/notification/internal/listener/ExamPreviewReadyNotificationListenerTest.java` | modified | Unit test for wrong-tenant member rejection. |
