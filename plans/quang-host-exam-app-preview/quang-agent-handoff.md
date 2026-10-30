# Quang — agent implementation handoff: host exam app preview

Status: PLAN ONLY. No application code, DB, discard, commit, push, or deployment has been performed.
Owner: Quang. Root: D:/GitHub/pte-org. Follow plan.json phase order and this document.
This handoff refines the earlier report where details differ. Read with the acceptance matrix.

## 1. Decisions already authorized; do not reopen routine choices

- Authenticated HOST_ADMIN enters host preview automatically; no pre-login switch, no new password, QR, launch token or deep link.
- STUDENT follows its existing attempt/security flow. PROCTOR, EXAMINER and platform-only roles remain denied by this client.
- HOST_ADMIN + STUDENT defaults to host preview. No student attempt entry from this host home in v1.
- Host selects a tenant-owned exam with an existing snapshot. READY suffices; also allow SCHEDULED, OPEN, CLOSED, CANCELLED if snapshot exists. DRAFT has a disabled preview action.
- Auth and ownership remain server-enforced. JWT decode is UI branching only. A successful authenticated list/preview response is required before displaying content.
- No preview attempt, enrollment, answer submission, scoring, quota debit, answer DB, answer outbox or media upload.
- Text/selection responses are RAM-only per snapshot item. Clear all at preview end/logout; never persist navigation index. Auth token persistence remains existing auth behavior.
- Actual microphone capture is allowed locally to exercise the recording state. No replay/download control is added. File lifetime ends on leaving the current item.
- Next exists on every preview item and is enabled irrespective of prep/audio/recording completion except during an in-flight transition. Previous is preview-only. At last item show Finish preview, which closes the preview without calling finish/submit APIs.
- Timer/audio/recording simulate runtime but never auto-advance the host. New visit to an item resets media/timing; textual responses can remain RAM-only within the same preview.
- UI uses the existing exam layout and real renderer components. Quang's Read Aloud reference: instruction above centered recorder, passage below, Next bottom right. No redesign, sidebar, new cards, waveform decoration, or source content substitutions.
- Small Preview / Answers are not saved indicator is allowed. No login option visible to student.
- Notify on first successful generate DRAFT -> READY, not on draft creation or only after publish. Replaying generation on READY must not generate another notification.
- Recipient = authenticated HOST_ADMIN who successfully executes generation in that transaction. IMPORTANT: inspected ExamSession and BaseEntity contain no creator-user field. Earlier wording 'host tạo kỳ thi' means the generating actor for v1, NOT a hidden creator lookup. Do not add createdBy/migration just for this.
- Preview still uses normal media-download bandwidth; do not claim zero third-party requests. Only upload/scoring/attempt quota is avoided.

## 2. First-agent preflight and safe discard

Read AGENTS.md at workspace root and nearest repo instructions; read full applicable docs before implementation:
docs/CODING_STANDARDS_APP.md, docs/CODING_STANDARDS_API.md, docs/CODING_STANDARDS_WEB.md,
docs/API_RESPONSE_SETUP.md, docs/COMMON_EXCEPTION_SETUP.md, docs/TEST_SCENARIOS_IAM.md.
pte-web/AGENTS.md additionally requires web docs and installed Next guides for relevant usage.
Reuse nearest coding session if the runtime offers it, but this plan is self-contained; never infer prior test counts as current proof.

Record git status, branch, HEAD, staged and unstaged diffs separately in each nested repo. Do not reset pte-org as a whole.
Reviewed app-only temporary flag patch touches EXACTLY:
README.md; lib/core/config/app_config.dart; lib/core/di/security_module.dart;
lib/core/security/lockdown_service.dart; test/unit/core/security/lockdown_service_test.dart.
Snapshot at planning time: 75 additions / 2 deletions, entirely PTE_EXAM_SECURITY_ENABLED false-by-default bypass.
Hash/statistics are evidence, not authorization to overwrite later edits.

Before first code edit:
1. Re-read full staged+unstaged diff of those five paths, confirm same flag-only hunks.
2. Save recoverable git binary diff against HEAD, including staged state, to
   pte-doc/plans/reports/assets/261029-quang-host-exam-app-preview-preflight/pte-app-security-flag-before-discard.patch.
   Use shell-safe native redirection/encoding or an existing tool that preserves patch bytes. No secrets or .env.
3. Validate backup exists/nonempty and is readable as a patch. Record exact paths and original staging; git diff --name-only alone is insufficient.
4. Restore only confirmed paths to HEAD, including index only if those flag hunks were staged.
   If a path now contains additional work, remove flag hunks surgically with apply_patch; never restore whole path.
5. Confirm intended flag is absent; unrelated paths and staging preserved. Run baseline lockdown tests.
6. Record recovery command and artifact path. Build executables are unaffected by source restore until rebuild.

Authorization to discard these reviewed flag-only changes is already given by Quang. Do not ask again for the same scope.
New unexpected overlapping edits require preservation, not silent discard. No git reset --hard, no git clean.
Do not run student Windows lockdown while collecting host screenshots. Baseline security checks use mocks.
Do not retain this global bypass to make preview work.

## 3. Verified source map (paths relative to workspace root)

### API
- pte-api/app/src/main/java/com/pte/session/internal/controller/SessionController.java:
  @RequestMapping /api/v1/sessions, @PreAuthorize HOST_ADMIN.
  GET / -> List<SessionResponse>; GET /{id} -> SessionResponse;
  GET /{id}/exam-preview -> ExamPreviewResponse. All wrapped in ApiResponse.
- session/internal/service/draft/SessionExamPreviewService.java:
  findOwned, require snapshot id, getFullContent via assessment facade, strip answers,
  resolve image/audio URLs via MediaService, current TTL 300 seconds.
- session/internal/dto/response/ExamPreviewResponse.java:
  root snapshotPublicId, name, version, items.
  item orderIndex, section, taskType, taskTypeCode, taskTypeDisplayName, title, promptText,
  audioUrl, imageUrl, minWordCount, maxWordCount, options, sourceQuestionPublicId.
  option orderIndex, blankIndex nullable, text. Preserve these fields.
- assessment/dto/response/SnapshotContentResponse.java:
  includes itemPublicId, frozen runtime, runtimeMappingVersion/status;
  DOES NOT currently include prepSeconds/responseSeconds. Includes secret answers internally; never serialize directly.
- attempt/internal/service/ExamItemLoader.java:
  actual runtime/timing rules, task canonicalization, required-media validation.
  Timing uses definition items and TaskTimingConfig, special audio prompt prep calculation.
  Class is package-private; do not import its internals into session.
- attempt/internal/service/TimerService.java: section-scoped timing reference.
- session/internal/service/draft/ExamPublishService.java: generate/publish; add event only first actual generation.
- notification/InboxNotificationRequested.java: exhaustive type/category/target mapping must include new type.
- notification/internal/service/InboxAppendService.java: Propagation.MANDATORY.
- notification/internal/listener/InboxRequestListener.java and SessionGradingCompletedNotificationListener.java:
  transaction BEFORE_COMMIT; existing durable delivery pipeline.
- notification/internal/repository/InboxDeliveryStore.java:
  unique event_key, payload fingerprint includes recipient list; replay with changed payload is a conflict.
- app/src/main/resources/db/migration/V1__baseline.sql:
  notifications_notification_type_check allowlist excludes new type.
  Flyway files currently V1..V8; allocate NEXT unused version at execution, not blindly V9.
  Do not edit V1 or previously applied migrations.

### App
- lib/main.dart: security setup + LockdownService.initialize before login.
- lib/core/di/security_module.dart: ViolationRetryCoordinator currently starts app-scoped after flag restore.
- lib/core/security/violation_retry_coordinator.dart: start/dispose, retryUnsent.
- lib/core/security/lockdown_service.dart: fullscreen/device-check/attempt exit/clipboard/process/shortcut guards.
- lib/app.dart: AppAuthGate and student device/attempt flow; several dev routes; DEV_SKIP_AUTH must not be used for production host entry.
- lib/features/auth/domain/exam_access_policy.dart, jwt_claims.dart:
  current canTakeExam only STUDENT; decoded claims do not verify signature client-side.
- lib/features/auth/presentation/bloc/auth_bloc.dart: login, refresh scheduler, logout.
- lib/features/exam_attempt/presentation/widgets/task_type_dispatcher.dart:
  real dispatcher is coupled to outbox/media/sync/attempt. Cannot simply inject fake attempt id.
- lib/features/exam_attempt/presentation/model/exam_task_ui_model.dart,
  task_view_ui_adapter.dart: presentation adaptation; audio uses refs in some branches, must deliberately map playable URLs.
- lib/core/widgets/templates/*.dart, components/*.dart, exam/*.dart: share visual surfaces.
- lib/features/exam_attempt/dev/exam_ui_preview_task_body.dart: seven template families, but dev response controls are NOT proof of fully working live preview.
- lib/features/exam_attempt/presentation/widgets/task_advance_button.dart:
  uses real SyncEngine and attempt events; do not reuse as host navigation.
- speaking_writing/domain/audio_recorder_service.dart: start(filePath), stop(), isRecording(), inputLevels.
- speaking_writing/presentation/widgets/auto_advance_on_upload_ready.dart:
  real upload-triggered progression; never instantiate for host preview.
- lib/core/constants/task_type_meta.dart: canonical registry; map via metadata/runtime allowlist, not arbitrary Dart screen names.

### Web
- pte-web/packages/api-client/src/types/notification/index.ts: InboxNotificationType union.
- pte-web/packages/api-client/src/requests/notification/: shared inbox contract.
- pte-web/apps/tenant-web/features/notifications/components/NotificationBellContainer.tsx:
  target SESSION already routes /host/exams/{targetPublicId}.
- same feature NotificationHistoryView.tsx, api.ts: history and common inbox hooks.
- pte-web/packages/ui/src/components/NotificationCenter.tsx and src/i18n/LocaleProvider.tsx:
  reuse bell; do not build a new notification channel/widget.

## 4. API contract to implement

Reuse existing GET routes; no new public write endpoint, preview token, start-preview table or pretend student id.
All reads must use caller tenant ownership, not tenantId from request body/query.
Server rechecks role and tenant per request; app list gating alone is insufficient.

Extend ExamPreviewResponse additively:
- Each item MUST expose snapshotItemPublicId from itemPublicId (stable across same snapshot).
  sourceQuestionPublicId is not unique for response storage; orderIndex alone is not a cross-snapshot key.
  App response key is (snapshotPublicId, snapshotItemPublicId); reset session if snapshot id changes on refresh.
- Add taskTypeKey, runtime, runtimeMappingVersion, runtimeMappingStatus as required for existing allowlisted dispatch.
  Runtime metadata is not an answer key; do not expose referenceAnswerText, correctAnswerText, options correctness.
- Add prepSeconds, responseSeconds, preListenSeconds?, preRecordSeconds?, audioDurationSeconds?,
  audioUrlExpiresAt? and imageUrlExpiresAt?. Define serialized UTC ISO fields/nullability in contract tests.
- Preserve optional blankIndex and ALL option order; derive grouped blanks in app without losing labels/indices.
- Shared web DTOs are in pte-web/packages/api-client/src/types/scheduling/index.ts; requests in src/requests/scheduling/sessions.ts.
- Keep old constructors/call sites source-compatible as appropriate and update API client ExamPreviewResponse type.
- Root fields remain backward-compatible. No max-score/correctness fields in response.

TIMING DECISION: preserve parity with current student delivery, not an invented claim that timing is frozen in snapshot.
ExamItemLoader currently uses the definition referenced by snapshot plus JSON task timing config.
Extract the reusable read-only content/timing resolver into an assessment-owned public facade/data DTO,
then adapt both the student loader and host preview to that seam. No session -> attempt.internal dependency.
Scope extraction to pure resolution; no changes to student deadline/section-budget semantics.
Prefer resolver returns frozen identifiers + resolved timing; media owner supplies duration via existing public service.
If referenced definition version can be retrieved, use the same pinned source for both callers.
Do not unilaterally fix legacy student version semantics; document discrepancy and preserve parity.
Missing required timing/media must return a common typed error; never replace with fixture audio or 30/40-second guesses.
Audio-speaking prep = preListen + actual audio duration + preRecord per student behavior.
Reading/Writing preview timers are local informational simulation; no student server deadlines or OPEN time checks.

Media URLs: read-only signing uses existing MediaService. No preview upload endpoint.
Initially sign on preview fetch per existing service; app only downloads current item's required media.
Re-fetch authenticated preview once per item/media expiry, validate same snapshot, rebind fresh URL.
On resource 403 after refresh fail, show common media error and keep Next/Previous available.
Do not infinite retry; auth 401 goes through common refresh once, then teardown/logout.
No persistent cache of content/answer; use player transient buffers and clear image/network cache entries on teardown if retained.
List eligibility: examVersionPublicId != null is authoritative; status text alone is not sufficient.
DRAFT/no snapshot: existing GenerationNotReadyException/common error, do not auto-generate.
Tenant inactive/access revoked must use existing guards; no preview-side entitlement/quota mutation.

## 5. Runtime architecture and lifecycle

Proposed feature root: pte-app/lib/features/exam_preview.
Names are implementer choices within standards; required seams:
- HostExamPreviewRepository (domain interface) and authenticated API implementation.
- PreviewSnapshot/PreviewItem DTO parsing and PreviewTaskUiAdapter.
- HostExamListCubit + list screen.
- HostExamPreviewCubit, immutable state, local answer controller.
- PreviewAudioSession with isolated player/recorder, item-generation token, temp-file owner.
- Feature DI registration with session-owned resources, not global host bypass boolean.

Extract or share pure task body and input widgets where production feature screens are coupled.
Student persistence stays in student cubits; host setters mutate RAM only.
Do not create fake outbox, fake attempt id, fake upload-ready states, student BLoC, or NoOp sync used by host.
Both paths consume same templates/components. Changes to shared visual components must preserve student appearance.
Respect renderer registry/contract version/capabilities; unsupported item gets explicit state and skippable Next.

Local state minimum:
mode=hostPreview, authenticatedPrincipal/tenant identity, snapshotId/version, ordered items,
currentIndex, answersBySnapshotItem, itemPhase, remaining time, audio state, recorder state,
isTransitioning, itemEpoch, recoverableError.
No token in logs/state dumps; auth stays existing auth layer.

Transitions:
- loading -> ready first item after authorized fetch.
- enter item -> reset per-item timer; prepare/listen/record according to runtime; attach callbacks tagged itemEpoch.
- choose/type/drag -> RAM-only answer update.
- Next/Previous -> set isTransitioning; invalidate epoch FIRST; cancel timers/subscriptions;
  stop recorder/player awaited; delete current temp file in finally; select valid target; initialize new item.
- If microphone stop/delete fails: keep cleanup diagnostic and sweep own temp later, do not launch a second recorder;
  allow exit, surface short error; no upload fallback.
- expiry -> finish local response, stop capture, show Completed; stay on same question awaiting Next.
- Finish preview/back/logout/401/window-close -> invalidate epoch, teardown, clear RAM, remove owned temp paths.
- repeat Next while transitioning is ignored; late old audio/onComplete/timer callbacks cannot move index/start mic.
- Previous first item disabled. Last item Finish preview returns list. App title and candidate header use real host and exam metadata,
  never invent student id; unavailable optional values have clear fallback.
- Mic denied/unavailable -> record state error, no repeated permission prompt loop, Next enabled.
- One preview can own microphone/player at a time. Do not stop/dispose student-owned singleton resources accidentally.
- Crash cleanup: own temp subdirectory pte-host-preview under OS temp; identify only own files,
  sweep at next app startup (single app process constraint or instance-aware cleanup). Never sweep student recording paths.

Security policy:
- Load forbidden-app config at bootstrap is okay; initialization is not lockdown.
- Native activation, device fullscreen, attempt exit guard, process-kill, clipboard/shortcut monitoring must be unreachable from host routes.
- ViolationRetryCoordinator after removing flag otherwise runs BEFORE auth: move/gate its start by authenticated student context,
  dispose on host/unauthenticated context. Do not drop queued student violations; defer them until correct student identity returns.
- Audit SyncEngine/MediaUploadCoordinator startup too: old student queues must not flush under host token.
  This is queue ownership/scheduling, not deletion of stored legitimate student work.
- On host -> logout -> student, default enforcement and normal student pipeline reactivate.
- Preview client never changes persisted session policy.lockdownMode. Correctness must hold in release without dart-define.

## 6. Notification transaction and DB

New inbox enum: SESSION_PREVIEW_READY; category SESSION; importance INFO; target SESSION + sessionPublicId.
Session module public event proposed:
ExamPreviewReadyEvent(sessionPublicId, tenantPublicId, snapshotPublicId, sessionCode, sessionName,
                     actorUserPublicId, occurredAt).
Use server caller identity; validate active HOST_ADMIN member in that tenant through Identity public facade.
Generate creates event exactly once after snapshot id and READY set, BEFORE method transaction commits.
READY replay returns existing generation and emits no event. Concurrent generate uses existing lock.
Do not trigger notification from web, GET preview, list, app login or publish replay.

Listener @TransactionalEventListener(BEFORE_COMMIT, fallbackExecution=false) -> InboxAppendService.append.
No AFTER_COMMIT -> MANDATORY call. No REQUIRES_NEW. If append fails transaction rolls back per existing durable semantics.
If that rollback leaves a generated assessment artifact, verify generation atomicity; do not notify for rolled-back session.
Dedup event key:
session:{sessionId}:preview-ready:{snapshotId}:{actorId}
Same payload and recipient set on replay. Consumer retries must not recompute changing audience for same key.
Text prepared from event values, no volatile timestamps in title/body. recipients list contains the actor only.
An existing caller cannot replay READY generation to send another notification to themselves.
No notification backfill for old exams in v1; those remain directly visible from host list.

Database change IS REQUIRED in current checkout:
new Flyway V{next}__allow_session_preview_ready_notification.sql replaces
notifications_notification_type_check with complete existing allowlist + SESSION_PREVIEW_READY.
Keep all existing enum values; no drop/truncate/reset, no editing baseline checksum. New version allocated on fresh branch inspection.
No new preview table; no changes to email NotificationType taxonomy.
Update InboxNotificationRequested.validMapping, enums and constants together.
DB test must apply actual Flyway migrations, not only manually created test DDL that could hide missing CHECK changes.

Web:
Add API-client enum variant. Existing SESSION target already opens correct exam route; do not rewrite bell navigation.
Reuse common server body. Add locale constants only where current notification copy layer uses them; server-sent English copy must not be
claimed as translated merely because frontend catalog contains unused keys.
Preferred v1 title/body follow existing inbox language convention; document actual rendered locale in report.
Notify body includes exam name/code and app-login instruction; no signed media URL or token in notification.
Verify bell list, history, unread count and mark read. Reuse existing polling/stream, do not add a second transport.
App may not be installed: instruction is sufficient in v1, no 'open app' button that cannot work.

## 7. Execution order and artifacts

Phase 1: preflight, binary backup+discard, baseline, exact implementation file manifest + DTO contract.
Phase 2: shared read-only timing/content seam, preview response, tenant/role tests, client types, source/contract review.
Phase 3: auth routes, session/queue policy, host list, interactive shared renderers, local media/timer/navigation, app regression.
Phase 4: event+enum+migration+listener, shared web notification compatibility, Postgres transaction/dedup tests.
Phase 5: full relevant checks, Windows smoke, network/DB delta evidence, agent handoff to Quang.

Before edits in each phase, update quang-execution-file-manifest.md with exact files including all extracted shared widgets,
tests, client DTOs, migration filename and docs. Existing output_files are seed inventory, not a license to omit new files;
update phase JSON after new filenames resolved and before writing them. All input paths must already exist or be produced earlier.
No code generation hidden in planning artifacts. Keep all statuses pending until implementation starts.

Artifacts under pte-doc/plans/reports and assets/261029-quang-host-exam-app-preview-*.
Reports contain commands/exits/skips and screenshots/network/DB deltas; no passwords/tokens/.env values.
No commit/push/merge/deploy without separate user request.

## 8. Commands and evidence boundaries

Paths below are relative to indicated repo. Read current package scripts/standards before adapting.
pte-app:
  flutter analyze
  flutter test test/unit/core/security/lockdown_service_test.dart
  flutter test test/unit/features/auth/domain/exam_access_policy_test.dart
  flutter test test/unit/features/auth/auth_bloc_test.dart
  flutter test test/widget/app_auth_gate_test.dart
  flutter test test/widget/features/exam_attempt/task_advance_button_test.dart
  flutter test test/widget/features/exam_attempt/auto_advance_on_upload_ready_test.dart
  flutter test
  flutter build windows --release
Windows build is done only on supported environment. No student fullscreen activation just to inspect host UI.
New feature tests go under test/unit/features/exam_preview and test/widget/features/exam_preview.

pte-api:
  .\mvnw.cmd -pl app -DskipTests compile
  .\mvnw.cmd -pl app test
Read real-Postgres suites' environment requirements; InboxDeliveryStorePostgresIntegrationTest requires
INBOX_TEST_DB_URL / USER / PASSWORD from existing configured environment, not hardcoded production details.
Use dedicated test DB/schema; absent environment means SKIPPED, not PASSED.
Run actual Flyway upgrade test on dedicated DB and preview ownership/security integration.
Any extract of timing must rerun existing ExamItemLoader/runtime/timer tests.

pte-web:
  pnpm --filter @pte/api-client typecheck
  pnpm --filter @pte/ui typecheck
  pnpm --filter tenant-web typecheck
Check scripts exist first; use actual package's lint/test runner and scoped paths. Notification union is shared with vendor:
also typecheck vendor-web when API-client enum/preview types change.
Use pnpm --filter tenant-web exec eslint <actual changed files> and relevant inbox/preview tests.
git diff --check per repo at handoff.

Evidence:
- Run controlled test accounts and session on local/test instance; record immutable identifiers privately, no credentials.
- Compare only rows/quotas belonging to controlled session/account; global counts are noisy if other users work.
- Expected persistent writes: new notification content/recipient/stream/read records and normal auth records.
  'No writes' refers preview answer/attempt/enrollment/upload/scoring, NOT banning notification/login writes.
- Creation/generation/publish may legitimately consume existing billing entitlement. Baseline quota AFTER creation,
  BEFORE host preview; compare after preview. Do not mistake creation cost for preview cost.
- Instrument HTTP method+route/category without sensitive bodies; allow auth, session list/detail/preview, signed media GET.
  Disallow attempt create/start/navigate/submit, answer save, media upload/presign upload, grading/score invocation.
- Instrument Drift writes and native channels: preview must not write answer outbox/media/violations or call guard activation.
- Do not claim 22-task coverage from task count: one template may contain many repeated task types.
  Report unique canonical task codes actually exercised.
- No dependency installation, service restart, Docker rebuild or local DB reset is needed to expand this plan.

## 9. Ready-to-copy prompt for the implementing agent

Implement D:/GitHub/pte-org/pte-doc/plans/quang-host-exam-app-preview/plan.json.
Read quang-agent-handoff.md and quang-acceptance-matrix.md first, then AGENTS and coding standards.
Quang has authorized the feature and exact temporary app-security-flag discard after recoverable backup and fresh diff review.
Finish phase 1 before implementation; preserve all unrelated worktree edits.
Use existing HOST_ADMIN GET sessions/exam-preview contracts and common inbox; preview never creates or submits an attempt.
Host answers are RAM-only, audio temp local only; student enforcement remains normal in release.
Record exact file manifest, tests/evidence and any real blocker. Do not ask again about settled decisions, commit, push or deploy.
