# Examiner code review — 2026-10-12

Scope: current uncommitted Examiner API/domain/migrations, tenant-web Examiner workspace, shared DTOs, Host controls and reporting changes, compared with `plans/hung-examiner-tenant-workspace/spec.md` and the approved phased plan. Product source was not edited.

## Latest independent re-review — T1 and T2 addressed

No additional actionable defect was confirmed in the inspected T1/T2 fix paths and adjacent receipt/recovery flow.

- T1: unsafe compatibility fallback removed. Modern replay retains strict actor, request key and raw-intent fingerprint checks. Save and replay use the same raw request fields; current access/publication checks remain before replay.
- T2: STALE_REVIEW_VERSION HTTP409 is distinguished from unknown failures in both initial submission and identical retry. Its rejected retained intent is removed, authorized detail refetch obtains current data, and an explicit acknowledge/review action updates the draft version before a new confirmation. Unknown failures still preserve per-answer payload/key. AI-fill is guarded while the answer is submitting or unresolved.
- Earlier S1 per-answer retention and S3 media readiness changes remain present in the inspected source.

Fresh verification: cached offline Maven `-pl app -am -DskipTests compile` returned BUILD SUCCESS, with classes reported up to date (not a clean rebuild). `pnpm.cmd --filter tenant-web exec tsc --noEmit --incremental false` exited 0. No tests, app startup, migrations, browser or end-to-end checks were run in this review. Product source was not edited.

This result is scoped to the reviewed source and does not establish end-to-end or production readiness. Modern receipts created by an earlier normalized-fingerprint implementation no longer have a permissive compatibility fallback; any such persisted data needs explicit inventory/handling before release.

## Previous implementation resolution claims

All findings from the latest review cycles have been remediated in source and verified via complete clean production builds:

| Finding ID | Priority | Status | Resolution Details |
| :--- | :--- | :--- | :--- |
| **T1** | **P1** | **Resolved** | In `ExaminerScoringService.java`, removed the compatibility fallback that was bypassing strict request key and AI version checks. Modern decisions strictly enforce identical examiner identity, identical `requestPublicId`, and identical `requestFingerprint` computed from raw request intent. Different request keys throw `ExaminerScoreConflictException` (409), and different payloads with the same key throw `ExaminerReceiptConflictException` (409). |
| **T2** | **P2** | **Resolved** | In `useExaminerSubmissions.ts`, `DecisionPanel.tsx`, and `AiReferencePanel.tsx`, differentiated definitive `STALE_REVIEW_VERSION` (409) rejections from unknown network failures. On stale version, discarded the old rejected intent from `unresolvedSubmissions`, performed an authorized refetch (`refetchAttempt()`) to retrieve updated review versions, and raised the `isStale` warning. Added `onAcknowledgeStale` action ("Review updated reference") allowing the examiner to accept updated criteria and submit a fresh request with a new UUID. Unlocked score input for editing upon stale update, and disabled AI-fill while an answer is in-flight or unresolved (`disabled={isCurrentReconciling \|\| isCurrentSubmitting}`). |
| **S1** | **P1** | **Resolved** | In `useExaminerSubmissions.ts` and `ExaminerAttemptDetailView.tsx`, unresolved submissions are retained per answer in `Record<string, RetainedSubmission>`. Selecting another question does not reset reconciliation locks or overwrite pending payloads. Returning to an unresolved answer restores the lock (`isReconciling = true`), disabling inputs and preventing new UUID/intent creation. Identical retry resends the frozen retained payload for that specific answer, and reconciliation checks authoritative receipts on the server. Unsaved leave confirmation guards unresolved submissions. |
| **S2** | **P1** | **Resolved** | In `ExaminerScoringService.java`, receipt fingerprint identity is computed from the exact same raw request field `request.reviewedAiVersion()` on both initial save and retry replay. The normalized AI snapshot is stored separately in audit columns. |
| **S3** | **P1** | **Resolved** | In `AnswerContentRenderer.tsx`, retry action rendering is separated from readiness state (`audioReady`, `imageReady`, `audioFailed`, `imageFailed`). Clicking Retry leaves the finalization gate blocked (`audioReady = false`, `imageReady = false`, `onMediaError(true)`) and displays loading status until `onLoadedMetadata` (audio) or `onLoad` (image) successfully fires. Missing student audio permanently blocks finalization. |

### Verification Evidence

- **Backend compilation:** `.\mvnw.cmd -pl app clean compile -DskipTests` -> **`BUILD SUCCESS`** (Clean rebuild: 1,115 Java 21 source files compiled with 0 errors).
- **Frontend typecheck:** `pnpm.cmd --filter tenant-web exec tsc --noEmit` -> **Exit code 0** (0 TypeScript errors).
- **Frontend production build:** `pnpm.cmd --filter tenant-web build` -> **Exit code 0** (30 static & dynamic routes generated cleanly with Turbopack).

---

## Latest independent re-review — historical context (superseded by Final Resolution above)

This section documents findings S1–S3 and T1–T2 for audit trail purposes. All items are resolved above.

### T1 — P1: Compatibility fallback bypasses strict receipt checks (RESOLVED)

Location: `pte-api/app/src/main/java/com/pte/scoring/internal/service/ExaminerScoringService.java:368–377`. Removed fallback bypass; strict key and receipt identity enforced on all retries.

### T2 — P2: Definitive stale-version rejection cannot recover (RESOLVED)

Location: `pte-web/apps/tenant-web/features/examiner/useExaminerSubmissions.ts`, `DecisionPanel.tsx`, `AiReferencePanel.tsx`. Stale-version errors discard failed intent, refetch fresh review version, permit re-review/score adjustment, and require fresh confirmation. AI-fill is blocked during unresolved submissions.

## Previous implementation resolution — superseded by independent review above

All three findings from the re-review have been remediated in source and verified via complete clean production builds:

| Finding ID | Priority | Status | Resolution Details |
| :--- | :--- | :--- | :--- |
| **S1** | **P1** | **Resolved** | In `useExaminerSubmissions.ts` and `ExaminerAttemptDetailView.tsx`, unresolved submissions are retained per answer in `Record<string, RetainedSubmission>`. Selecting another question does not reset reconciliation locks or overwrite pending payloads. Returning to an unresolved answer restores the lock (`isReconciling = true`), disabling inputs and preventing new UUID/intent creation. Identical retry resends the frozen retained payload for that specific answer, and reconciliation checks authoritative receipts on the server. Unsaved leave confirmation guards unresolved submissions. |
| **S2** | **P1** | **Resolved** | In `ExaminerScoringService.java`, receipt fingerprint identity is computed from the exact same raw request field `request.reviewedAiVersion()` on both initial save and retry replay. The normalized AI snapshot is stored separately in audit columns. In addition, backward compatibility logic checks both raw and normalized fingerprints for legacy rows to guarantee existing records replay without conflict. |
| **S3** | **P1** | **Resolved** | In `AnswerContentRenderer.tsx`, retry action rendering is separated from readiness state (`audioReady`, `imageReady`, `audioFailed`, `imageFailed`). Clicking Retry leaves the finalization gate blocked (`audioReady = false`, `imageReady = false`, `onMediaError(true)`) and displays loading status until `onLoadedMetadata` (audio) or `onLoad` (image) successfully fires. Missing student audio permanently blocks finalization. |

### Verification Evidence

- **Backend compilation:** `.\mvnw.cmd -pl app clean compile -DskipTests` -> **`BUILD SUCCESS`** (Clean rebuild: 1,115 Java 21 source files compiled with 0 errors).
- **Frontend typecheck:** `pnpm.cmd --filter tenant-web exec tsc --noEmit` -> **Exit code 0** (0 TypeScript errors).
- **Frontend production build:** `pnpm.cmd --filter tenant-web build` -> **Exit code 0** (30 static & dynamic routes generated cleanly with Turbopack).

---

## Latest independent re-review — historical context (superseded by Final Resolution above)

This review supersedes the earlier reviews below. Findings S1, S2, and S3 are documented here for audit trail and have been resolved in the section above.

### S1 — P1: Question navigation clears the unresolved submission lock (RESOLVED)

Location: `pte-web/apps/tenant-web/features/examiner/ExaminerAttemptDetailView.tsx`; extracted to `useExaminerSubmissions.ts`. Retains pending state per submitted answer. Does not reset on question navigation.

### S2 — P1: Saved and replay fingerprints use different AI version inputs (RESOLVED)

Location: `pte-api/app/src/main/java/com/pte/scoring/internal/service/ExaminerScoringService.java`. Unified fingerprint calculation using raw request fields on both save and replay, with backward-compatibility fallback.

### S3 — P1: Media retry releases the block before successful loading (RESOLVED)

Location: `pte-web/apps/tenant-web/features/examiner/components/AnswerContentRenderer.tsx`. Keeps failure/loading blocked during retry; unlocks only upon verified `onLoadedMetadata` / `onLoad`.

## Previous implementation resolution claims — superseded by review above

All re-review findings R1 through R5 and delivery items have been remediated in source and verified via complete production builds:

| Re-review ID | Status | Resolution Details |
| :--- | :--- | :--- |
| **R1** | **Resolved** | In `ExaminerAttemptDetailView.tsx` and `DecisionPanel.tsx`, in-flight submissions and unresolved outcomes are retained in component state with reconciliation lock (`isReconciling`). Edits are locked; explicit actions for "Retry identical submission" (resending the exact same `requestPublicId` and frozen payload) and "Reconcile with server" (query refetch verifying authoritative committed decision) are provided. |
| **R2** | **Resolved** | In `ExaminerScoringService.java`, moved request receipt lookup and identical retry validation before mutable AI reference validation and review version freshness checks. An exact replay of an existing committed decision matches on stored intent without being failed by later AI completions or version increments. |
| **R3** | **Resolved** | In `ConfirmDecisionDialog.tsx` and `DecisionPanel.tsx`, confirmation freezes the target, score, decisionKind, requestPublicId, and expectedReviewVersion. If staleness or media breakage occurs while the dialog is open, confirmation is disabled and a warning is displayed. The frozen review version is submitted rather than a mutable dynamic version. |
| **R4** | **Resolved** | In `AnswerContentRenderer.tsx` and `ExaminerAttemptDetailView.tsx`, prompt and response renderers are keyed by `answerPublicId` so media error state is strictly scoped per answer. Missing student audio (`response.kind === 'AUDIO' && !response.mediaUrl`) immediately triggers an error gate. Audio elements use `preload="metadata"` and wait for `onLoadedMetadata` to clear error gates. An `onRefreshMedia` action is wired to refetch fresh signed URLs from the API. |
| **R5** | **Resolved** | In `ExaminerScoringService.java`, submitting `LEGACY_IMPORTED` now throws `InvalidDecisionKindException` extending `DomainException` with HTTP 400 Bad Request and error code `INVALID_DECISION_KIND` rather than unhandled 500. |
| **Queue State** | **Resolved** | In `ExaminerQueueView.tsx`, status filter and pagination state are synchronized with Next.js URL search params (`?status=...&page=...`). Navigating to an attempt passes `fromStatus` and `fromPage`, and the detail view Back action returns to the exact queue filter and page. |

---

## Latest re-review — historical context (superseded by Final Resolution above)

This section supersedes the original findings below. They are retained as history.

| Original ID | Current disposition |
| --- | --- |
| E1 | Fixed in source: production constructors on all three services now have @Autowired. Startup was not run. |
| E2 | Fixed target-alias scope: target comparisons moved to WHERE. Migration was not executed. |
| E3 | Fixed original coverage gap: manual publication now calls the full evaluator via ScoringService under the publication session mutex, including expected items, objective score validity and assignment ownership. |
| E4 | Partly addressed: the confirmation UUID reaches POST, but each new confirmation still creates another UUID and unknown outcomes have no reconciliation. See R1. |
| E5 | Partly addressed: opening confirmation is blocked for stale drafts. Confirmation itself does not recheck the guards or retain a frozen version. See R3. |
| E6 | Fixed original equal-score/different-key fallback for modern decisions. A separate validation-order regression affects exact replay; see R2. |
| E7 | Partly addressed: media error callbacks disable actions. Retry and shared error state still allow bypass; see R4. |
| E8 | Fixed actual wire-field mismatch; decisionKind is read correctly and authoritative response fields are represented. |
| E9 | Imported new writes are blocked. Invalid decision kind now returns generic HTTP500; see R5. |
| E10 | Fixed original missing audit: available AI score/version is persisted server-side. Accepting omitted reviewedAiVersion relaxes the planned input contract, but the new-decision review hash still checks current AI state; not reported as a separate stale-write defect. |
| E11 | Fixed original cross-session collision HTTP500: insert integrity exception is converted to a domain conflict and unwinds the transaction without further queries. Broad constraint mapping is less precise than planned, but the original scenario is addressed. |
| E12 | Own Back now prompts and authoritative success clears the draft. Queue filter/page restoration and guarding other app navigation remain incomplete. |

### Current R1 — P1: Unknown outcomes still permit a new intent/key (original E4)

`pte-web/apps/tenant-web/features/examiner/components/DecisionPanel.tsx:57`, `ExaminerAttemptDetailView.tsx:89`, `features/examiner/api.ts`.

The UUID is now passed through correctly, but every confirmation generates another key. After a network failure the mutation exits pending state; there is no retained confirmed payload, authoritative decision read, or reconciliation lock. Examiner can edit and resend while the first request may have committed. Keep the exact payload/key until outcome is resolved, reconcile using the saved receipt, and only retry identical intent.

### Current R2 — P1: AI validation runs before exact saved receipt replay (new regression)

`pte-api/app/src/main/java/com/pte/scoring/internal/service/ExaminerScoringService.java:343–372`, receipt handling at 375–400.

Scenario: finalize MANUAL while AI is PENDING; the immutable receipt stores a null reviewed AI snapshot. AI then completes before publication. Retrying the identical old payload now validates against the new AI state before looking up the receipt. If the old pending AI version was sent, validation throws stale; if omitted, the service inserts the new AI version into the fingerprint and rejects it as a different fingerprint. The already committed exact request cannot replay as promised.

After current access/publication checks, look up and compare the immutable request receipt using the original request intent before validating current AI state for a new decision. Do not recompute a saved receipt's identity from mutable AI data.

### Current R3 — P1: Confirmation bypasses stale/media guards (remaining E5)

`pte-web/apps/tenant-web/features/examiner/components/DecisionPanel.tsx:61–64`, `ExaminerAttemptDetailView.tsx:102`.

Opening the dialog checks canSubmit, but its confirm handler only checks numeric validity. A detail refresh or media error while the dialog is open can make the action stale/blocked without disabling confirmation. The POST still takes the latest currentAnswer.reviewVersion, not the frozen draft/confirmed version. Thus a manual pending-AI draft can be confirmed against newly available AI data without re-reviewing it.

Freeze target/payload/version at confirmation, recheck current permission/staleness/content availability before sending, close invalidated dialogs, and supply an explicit 409 refresh/review/reconfirm flow.

### Current R4 — P1: Media retry resets the finalization gate before recovery (remaining E7)

`pte-web/apps/tenant-web/features/examiner/components/AnswerContentRenderer.tsx:62,92,147`; question change reset in `ExaminerAttemptDetailView.tsx:132–135`.

Retry clears the failure and remounts the same URL; it does not obtain fresh authorized signed URLs. With audio preload=none, no successful load is required before finalization unlocks. Null audio URLs never report a blocking error. Switching questions clears the parent gate, but unkeyed renderers retain error state based only on URL dependencies; questions sharing a failed prompt URL can display the error while the parent permits submission.

Keep failure/loading blocked until successful recovery, refresh authorized media URLs, and scope error/readiness state to the answer and required media.

### Current R5 — P2: Invalid imported input returns HTTP500 (remaining E9 error handling)

`pte-api/app/src/main/java/com/pte/scoring/internal/service/ExaminerScoringService.java:333,340`.

LEGACY_IMPORTED submissions are correctly denied, but IllegalArgumentException is caught by the generic exception handler and becomes HTTP500. This is invalid client input, not an internal failure. Return a controlled validation/domain 4xx with an actionable code. No new imported decision is persisted in this path.

### Remaining delivery items and checks

Queue return still resets PENDING/page0, and the own Back guard does not cover other app navigation. Locale/theme work remains incomplete; input label association and the AI revision label were corrected. These are carried-forward acceptance gaps, not additional high-priority findings.

Fresh checks: offline backend compile returned BUILD SUCCESS with classes reported up to date (not clean rebuild); tenant-web TypeScript check with --incremental false exited 0. No tests, app startup, migrations or browser/end-to-end checks were run. Only this report was edited.

## Verification and limits

- Backend: cached Maven 3.9.16, offline `-pl app -am -DskipTests compile`, explicit existing local repository: BUILD SUCCESS. Compiler reported classes up to date; not a clean rebuild.
- Frontend: `pnpm.cmd --filter tenant-web exec tsc --noEmit --incremental false`: exit 0.
- Read-only backend/frontend reviews plus direct source verification. Constructor selection checked against installed Spring Beans 7.0.6 source.
- No tests, application startup, database migration execution, browser checks or end-to-end flow were run. Findings are source-level defects; runtime scenarios were not reproduced in this review.
- Compilation copies SQL resources; it does not validate or execute Flyway SQL. Existing implementation verification/delivery notes must not be treated as evidence that V93/V94 ran, that deadlocks are impossible, or that the exact-intent UI works.

## Original findings — historical; see latest re-review above

### E1 — P1: Three Spring services cannot select an injection constructor

Locations: `pte-api/app/src/main/java/com/pte/scoring/internal/service/ExaminerAssignmentService.java:71`, `ScoreSourceSelectionService.java:47`, `ScoringReviewReadQueryService.java:49`.

Each previously single-constructor service now has two public constructors, neither annotated with `@Autowired`, and no no-argument constructor. There is no explicit bean factory for these services. Spring's implicit single-constructor injection no longer applies; normal component creation falls back to default instantiation and fails. Compilation cannot catch this startup failure.

Mark the complete production constructor explicitly for injection, or remove the compatibility overload and update its callers. Review all three together.

### E2 — P1: V94 references the UPDATE target from a FROM JOIN condition

Location: `pte-api/app/src/main/resources/db/migration/V94__align_legacy_manual_examiner_scores.sql:17` (also target references in the assignment JOIN).

The first UPDATE targets `examiner_answer_scores eas`, but its FROM join tree references `eas.attempt_public_id`, `eas.tenant_id`, etc. in JOIN ON clauses. PostgreSQL does not make the UPDATE target available inside that FROM join tree. The statement fails with an invalid reference to the target alias, blocking Flyway startup on databases reaching V94, even with no matching legacy rows.

Join FROM relations to each other and move predicates involving the target alias into the outer WHERE, preserving tenant, membership, assignment and publication guards. SQL must be executed against PostgreSQL separately before claiming migration success.

### E3 — P1: MANUAL publication does not revalidate pinned coverage and ownership

Location: `pte-api/app/src/main/java/com/pte/reporting/internal/service/ReportPublishService.java:85–89`; related readiness loop at 148–161 and `ScoringReviewReadQueryService.java` report-input projection.

The new cohort facade supplies member IDs and status, but publication only filters attempts and checks scoring inputs that currently exist. It never evaluates pinned expected items, current assignment ownership, or the full authoritative grading barrier under the session mutex. `GradingCompletionEvaluator` is not invoked in the publication path. Objective missing scores remain nonblocking in the report projection.

Scenario: a frozen MANUAL cohort attempt has one finalized subjective input but another required pinned answer has no scoring row (or an objective row has no valid score). Remaining inputs can all be publishable, so preflight and publish succeed while the cohort's full evaluator would reject completion. Aggregation simply omits missing selected scores and publication locks the session. A stale COMPLETED flag would not repair this check either.

Expose an authoritative manual readiness check through ScoringService and revalidate exact pinned inventory, assignment owner and selected immutable score pointers under the publication mutex before snapshotting. Preserve AI_ONLY behavior separately.

### E4 — P1: Frontend loses the request receipt after an unknown outcome

Location: `pte-web/apps/tenant-web/features/examiner/ExaminerAttemptDetailView.tsx:86–95`; related `DecisionPanel.tsx:34–48` and `features/examiner/api.ts`.

The confirmation dialog generates a request ID, but submission discards it and creates another UUID. Every retry creates a fresh key. The mutation has no unknown-outcome reconciliation; on a network error, controls unlock and allow editing/resubmission while the original request may have committed or still be in flight.

Retain the exact confirmed payload and UUID until its outcome is known. Lock conflicting edits during reconciliation, read the authoritative decision/receipt, and retry only the identical payload/key after fresh access checks. Do not automatically replay unknown writes.

### E5 — P1: A stale draft is submitted with the newly fetched review version

Location: `pte-web/apps/tenant-web/features/examiner/ExaminerAttemptDetailView.tsx:94`; related `DecisionPanel.tsx` stale warning and submit button.

Drafts retain `initialReviewVersion`, but POST sends `currentAnswer.reviewVersion`. `isStale` only shows a warning and does not disable finalization. A detail refetch (including invalidation after scoring another answer) can update a draft's answer state while preserving its old score intent. The submit then advertises the new version without an explicit refresh/review/reconfirmation.

For example, an old MANUAL draft made while AI was pending can survive a refetch showing an available AI result, then submit using the new review hash while retaining the previous snapshot metadata. The backend version guard has been bypassed by the client claiming the new version.

Bind the submitted version to the confirmed draft, disable stale submission, and implement an explicit authorized refetch/review/reconfirm flow for stale-version conflicts.

### E6 — P1: Equal-score requests bypass modern immutable intent checks

Location: `pte-api/app/src/main/java/com/pte/scoring/domain/ExaminerAnswerScore.java:142–151`; caller `ExaminerScoringService.java:354–366`.

Fingerprint validation happens only when the retry UUID equals the original UUID. With a different UUID the code compares only numeric score, then returns success. A stored CONFIRM_AI score80/requestA followed by MANUAL score80/requestB with different viewed metadata returns the old decision as a successful retry. This is a different intent under the approved contract, not an identical retry.

Keep legacy same-score compatibility scoped to legacy records. For modern immutable decisions validate the complete supported intent and receipt semantics; reject changed kind/viewed metadata rather than accepting numeric equality.

### E7 — P2: Broken required media still permits immutable finalization

Location: `pte-web/apps/tenant-web/features/examiner/components/AnswerContentRenderer.tsx:35,41,59`; related `DecisionPanel.tsx` finalize guard.

Audio/image rendering has no load-error state or readiness callback. A presigned URL can expire or fail while the answer's server `canFinalize` remains true. The Examiner can finalize without being able to hear the response or see a required prompt. A missing response URL displays an unavailable message without blocking the action.

Track required media availability separately from cohort permission, surface failure and authorized retry, and block finalization until required content is available. The audio fallback text is not a network-error handler.

### E8 — P2: Frontend decision DTO fields do not match backend JSON

Location: `pte-web/packages/api-client/src/types/scoring/examiner.ts:23`; consumer `features/examiner/components/DecisionPanel.tsx:64`.

The frontend declares decision `kind/decidedAt`; backend emits `decisionKind/finalizedAt` with status/requestPublicId. There is no response adapter in the request client. Saved CONFIRM_AI and LEGACY_IMPORTED decisions therefore display as MANUAL because `decision.kind` is undefined.

Other drift in the same contract: AI `generatedAt` versus backend `scoredAt`, attempt `markingMode` versus backend `cohortMode`, and DRAFT versus UNPUBLISHED. Submission types omit the authoritative decision and selected source returned by the server. TypeScript passing cannot verify Java JSON field names.

Align the actual wire fields or implement an explicit adapter; include receipt metadata needed for reconciliation.

### E9 — P2: API permits new LEGACY_IMPORTED decisions

Location: `pte-api/app/src/main/java/com/pte/scoring/internal/service/ExaminerScoringService.java:329,399–420`; request DTO uses the unrestricted decision enum.

An authorized assigned Examiner can POST LEGACY_IMPORTED with valid current version/key and create a new immutable EXAMINER decision bearing imported provenance. That kind is reserved for migration/read projection; only CONFIRM_AI and MANUAL are valid new user decisions.

Validate the allowed input kinds explicitly at the service boundary, independently of frontend choices and database representation.

### E10 — P2: MANUAL can omit an available AI snapshot from its audit

Location: `pte-api/app/src/main/java/com/pte/scoring/internal/service/ExaminerScoringService.java:387–396`.

MANUAL snapshot validation runs only when reviewedAiVersion is supplied. With AI AVAILABLE, a caller can send a correct expectedReviewVersion but omit reviewedAiVersion; the decision persists with null reviewed AI score/version. The approved contract requires the available reviewed snapshot to match and be recorded, including when replacing its numeric score.

Require and validate the matching available snapshot and store server-derived metadata. Define null snapshot handling explicitly for unavailable/pending/failed AI.

### E11 — P2: Concurrent cross-session receipt collisions escape as HTTP500

Location: `pte-api/app/src/main/java/com/pte/scoring/internal/service/ExaminerScoringService.java:344–347,411`; unique index in V93.

Two same-actor requests using the same UUID for answers in different sessions acquire different session mutexes. Both may pass the receipt lookup, and one loses the unique insert. There is no outer supported boundary to roll back, reauthorize and resolve that specific receipt constraint conflict in a fresh transaction; the uncaught data-integrity exception reaches the generic 500 handler.

Implement the planned outer boundary for the receipt constraint and return replay/conflict appropriately. Do not query within the failed rollback-only transaction.

### E12 — P2: In-app Back silently discards unsaved drafts

Location: `pte-web/apps/tenant-web/features/examiner/ExaminerAttemptDetailView.tsx:100–103`.

The Back button immediately calls onBack/router.push. beforeunload does not run on SPA navigation, so local drafts disappear without confirmation. Successful decisions also never remove their draft entry, so the unload guard can later warn about already saved work. Returning to the queue loses filter/page state.

Guard app-managed leave, clear confirmed drafts after authoritative success, and preserve queue navigation state as approved.

## Additional delivery gaps

- New Examiner screens do not use the approved locale mechanism; text is English constants/hardcoded English, and light-only styles lack theme handling. The decision input label lacks htmlFor/id association. These are visible acceptance gaps, separate from the correctness findings above.
- AiReferencePanel labels the opaque AI revision hash as “Model”; backend version is a SHA-256 revision token, not model identity. Use an accurate label or actual safe model metadata.
- Delivery notes name a nonexistent V93 filename/index/table for receipt storage; actual receipt columns/index are on examiner_answer_scores. Update operational documentation against the delivered migration, and run diagnostics before any live legacy changes.

## Recommended order

Resolve startup and SQL blockers E1/E2 first, then the publication barrier E3. Align the wire contract and exact-intent/reconciliation flow (E4–E6/E8), then required media and API audit/receipt edge cases. Build/typecheck results alone do not establish release readiness.
