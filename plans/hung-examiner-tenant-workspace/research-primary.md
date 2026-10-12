# Examiner AI-assisted final decision — Primary research

Date: 2026-10-11. Read-only source research; no product source, migrations, tests or builds changed/run.
Verdict: reuse the existing Examiner lane, immutable ExaminerAnswerScore and MANUAL_EXAMINER cohort. Extend safe projections and finalize atomically. Host freezes the CLOSED cohort before Examiner can finalize; Host publishes its complete frozen inventory later.

## Verified source anchors

All API paths below are relative to pte-api/app/src/main/java/com/pte unless otherwise stated.

| Concern | Actual source and implication |
| --- | --- |
| Current Examiner ownership | scoring/internal/service/ExaminerScoringService.java:117 listWork, :133 getAttempt, :191 submitScore. Active EXAMINER/tenant/assignment, unpublished session and pinned AI-eligible answer content already enforced. |
| Current submission | ExaminerScoringService.java:212 locks answer, then state; :216 existing immutable score permits same actor/same score retry; :225 saves score but does **not** select EXAMINER. No cohort/mode prerequisite now. |
| Policy lifecycle | scoring/internal/service/GradingCohortService.java:105 finalizeCohort obtains CLOSED session lock; :135 AI_ONLY rejects existing assignments; :143 persists chosen markingMode. Policy is not an ExamSession pre-exam field. |
| Cohort inventory | scoring/domain/GradingCohort.java:66 constructor freezes mode/version; :78 complete only transitions FROZEN→COMPLETED. Members can exclude outstanding attempts with reasons; no public mode-changing setter. |
| Completion coverage | scoring/internal/service/GradingCompletionEvaluator.java:35 evaluates all frozen pinned items; :100 MANUAL_EXAMINER requires assignment and publishable score. It does **not** compare examiner score actor with assignment actor or require selected EXAMINER pointer/audit. |
| AI provenance | scoring/domain/ScoringAnswer.java:161 markAiScored; :173 hasPublishableAiScore requires SCORED, integer0..100, category REAL and nonblank provider. STUB/unknown legacy rawScore must not appear as available AI. |
| AI state and persistence | scoring/domain/enums/ScoringAnswerStatus.java has PENDING, AI_SCORING, SCORING_FAILED, SCORED. scoring/internal/service/AiScoringResultPersistenceService.java:45 result persistence locks answer→state; SCORED/SCORING_FAILED terminal, so no ordinary rescore command exists. Late AI can still arrive after a manual Examiner finalize while AI is pending. |
| Host mutation | scoring/internal/service/ScoreSourceSelectionService.java:84 apply locks session, replay audit then publication check, locks sorted answers and permits AI/EXAMINER. ScoringReviewService.java:138 teacherScore writes answer→state; teacherScore currently is deliberately excluded from reporting. |
| Selected score pointer | scoring/domain/ScoringAnswer.java:178 selectScoreSource sets actor/time and selectedExaminerScorePublicId. Existing foreign keys in db/migration/V59__enforce_examiner_scoring_references.sql enforce score→answer and score→assignment owner scopes. |
| Immutable score | scoring/domain/ExaminerAnswerScore.java:81 constructor; :118 isPublishable; :122/:127 PreUpdate/PreRemove reject JPA changes. Additional decision/audit fields must be supplied at creation, not filled in later. SQL migration is separate from runtime entity updates. |
| Publication | reporting/internal/service/ReportPublishService.java:82 publishSession requires CLOSED, :88 locks scoring, :90 recomputes readiness, :175 submittedAttempts returns all current submitted attempts. It does not consult the frozen grading cohort or require its completion. |
| Current report checks | scoring/internal/service/ScoringReviewReadQueryService.java:137 toReportInput, :149 selectedScore, :170 blockingReason. Subjective selected AI can currently publish even in a MANUAL_EXAMINER cohort. Objective missing score explicitly does not block this old report contract. |
| Publication locking | scoring/internal/service/ScorePublicationLockService.java:35 locks sorted session answers then scoring_session_states, writes state before readiness; rollback protects failed publish. |
| Event lock caveat | scoring/internal/listener/GradingProgressListener.java:19 BEFORE_COMMIT invokes cohort reconciliation; GradingCohortService.java:156/:164/:172 obtains cohort locks; :179 members and ingest. Answer/state locks are held while the event requests cohort locks. |
| Existing migrations | db/migration/V58, V59, V62, V75 establish scoring/session-state/assignments/score source/audit/cohort. Latest current file V91__question_pool.sql; choose next available number at implementation. Never amend applied files. |

## Minimum lifecycle and policy implementation

1. Reuse Host's existing GradingCohortSection and preview/finalize routes. Closing the session and freezing a MANUAL_EXAMINER cohort precede new human final decisions. Cohort can remain FROZEN while assignments or Examiner decisions are outstanding; no need to complete scoring before freezing.
2. Require new Examiner finalize target to be a nondeleted, nonexcluded member of an existing MANUAL_EXAMINER cohort, with matching tenant/session/attempt and owned active assignment. Return a specific conflict for missing policy/cohort; safe detail can explain why finalization is unavailable without exposing other students/members. Do not infer mode from existence of an assignment or a score.
3. Preserve immutability of frozen mode. Existing AI_ONLY restriction on assignments already closes the most obvious mode bypass; additionally reject Examiner finalize in AI_ONLY and publication/source mutation that conflicts with MANUAL_EXAMINER.
4. Do not redefine all session creation flows or add a second policy table. The user asked final authority for this Examiner workflow; existing CLOSED-cohort policy is sufficient with explicit Host freeze-first UX.
5. Legacy assigned but cohort-less session: show setup-required, permit Host to use existing preview/freeze flow with MANUAL_EXAMINER. Do not auto-freeze, silently choose mode or invent outstanding-attempt disposition reasons. Previously committed immutable scores remain available for migration after policy is explicit.

## Persistence and audit

Extend examiner_answer_scores with creation-only decision_kind (CONFIRM_AI/MANUAL/LEGACY_IMPORTED), reviewed_ai_score, reviewed_ai_version, expected_review_version, request_public_id and request_fingerprint. Existing tenant/examiner/submittedAt/score fields already record actor/time/result. Use a unique partial index on (tenant_id, examiner_public_id, request_public_id) where request_public_id IS NOT NULL, preventing cross-answer reuse by an actor. Add DB checks for score range/kind and required modern request metadata. LEGACY_IMPORTED can have null AI/request metadata and is never a client choice.

This avoids a separate duplicate decision table. Score-source audit can remain its Host selection history; the immutable Examiner row is the per-answer decision audit. If product needs Host history to show automatic Examiner selection, add an explicit event category rather than disguise Examiner as a Host selection. Atomic finalize creates Examiner row, assigns EXAMINER via existing domain method and saves answer in the same transaction.

Legacy migration strategy:

- Annotate existing scores LEGACY_IMPORTED without inferring CONFIRM_AI/MANUAL or copying today's AI score into reviewed history.
- Only for unpublished, explicit MANUAL_EXAMINER cohorts and nonexcluded matching members, validate score ownership against assignment/answer then align selectedScoreSource=EXAMINER and selectedExaminerScorePublicId; set source actor/time from actual legacy score provenance.
- Leave AI_ONLY and published states/snapshots untouched. Also check published attempt report snapshots for defensive exclusion, rather than relying solely on missing scoring_session_state in legacy records.
- No cohort/ambiguous policy or inconsistent references means setup/migration blocker, not automatic AI fallback. Earlier freeze-time alignment suggestion is superseded by the approved SQL-only plan: after an explicit Host freeze, pre-cohort legacy scores require operator-reviewed bounded versioned SQL/remediation. No runtime repair in freeze/read/finalize/publication; keep the blocker until remediation.
- Do not reopen completed scores or mutate through JPA after the invariant is enabled. Any runtime import metadata must be separate or already SQL-backfilled; source-pointer alignment may update ScoringAnswer, which is mutable.

## API extension and version semantics

Keep three Examiner routes. Add optional fields to old read DTOs; old myScore/status/submittedAt can be retained as aliases derived from the decision. New finalize requires complete modern intent in MANUAL_EXAMINER. Reject old {score}-only payload there with explicit validation; supporting a blind mutation that omits required snapshot would violate the same-session final-authority contract. Deploy backend/shared-client/UI together or gate write availability until all pieces are installed; do not quietly switch old writes into MANUAL.

AI reference availability mapping based on real state:

- AVAILABLE only hasPublishableAiScore(), expose integer score/scoredAt.
- PENDING for PENDING/AI_SCORING absent a real score.
- FAILED for SCORING_FAILED only.
- UNAVAILABLE for SCORED with invalid/STUB/unknown provenance or an unsupported/malformed reference.

Use an opaque deterministic AI version digest of persisted AI result identity/status/score/scoredAt/provenance, **independent** of answer.lockVersion; selecting the Examiner source increments the answer version but is not a new AI score. Answer reviewVersion digest additionally includes frozen content identity/payload or canonical pinned version, policy/cohortVersion/member disposition, assignment actor, answer lockVersion, AI reference version and immutable decision identity/publication state. Use canonical length-prefixed encoding, as existing ScoringReviewReadQueryService.reviewVersion:233 does; omit presigned URLs.

Finalize ordering inside the transaction:

1. Revalidate active actor/tenant/assignment and current read entitlement (publication blocks access).
2. Look up request key scoped to tenant/actor. If committed, require matching fingerprint answer/score/kind/expectedReviewVersion/reviewedAiVersion and return its decision; do not reject replay because the original write changed reviewVersion.
3. For new intent, require owned nonexcluded MANUAL_EXAMINER cohort member, publication unlocked and no existing immutable score. Verify expected reviewVersion and reviewedAiVersion against the actually reviewed AI snapshot. CONFIRM_AI additionally requires available AI and exact score match; MANUAL may proceed with no available AI.
4. Persist immutable decision and EXAMINER source pointer atomically; flush before computing authoritative response reviewVersion. Publish progress using the existing transactional event mechanism after all data is aligned.

Store request fingerprint, not merely (score, actor), because two kinds or stale AI versions with equal scores are different reviewed intents. Authoritative read reconciliation exposes enough committed request identity or decision identity/metadata to distinguish the exact request outcome; if it does not expose requestPublicId, include it safely in one's own decision projection. Never send provider secrets, Host teacherScore, other examiner data or student identity.

## Concurrency recommendation

Existing answer→state ordering is insufficient once BEFORE_COMMIT cohort reconciliation is included. A new finalize that locks cohort first can deadlock an existing AI transaction holding answer/state then requesting cohort; publication can do the same if it introduces cohort checks after answer locks.

Minimal comprehensible approach: every scoring/publication/cohort mutation first holds the same tenant/session ExamSession row mutex via SessionService, then accesses cohort/members, sorted answer rows and publication state in a documented order. Keep AI vendor network work outside these transactions. Existing ScoreSourceSelectionService, ScoringCommandService.requestScoring:86, ReportPublishService and cohort finalize already acquire the session mutex. Add it before answer writes in ExaminerScoringService, AiScoringResultPersistenceService (success and failure), ScoringReviewService teacherScore, and before cohort lock in reconcile/reconcileIfPresent/reconcileScheduled. Scheduled code must not fetch a locked cohort and then ask for the session mutex. Reentrant same-transaction reconciliation is safe when outer writer already holds it.

ScoringCommandService already locks session before objective scoring/dispatch, so preserve rather than reinvent this path. Review direct ingest call sites as well: reconciliation performs ingest under cohort lock; session-first canonicalization prevents insert/write interactions from bypassing the mutex. Update comments currently claiming answer→state is the whole order. Do not add cohort locks ad hoc after answer/state locks. A separate AFTER_COMMIT reconciliation design is possible but broadens transaction/event ownership and is not the primary minimum.

Throughput tradeoff: one session's brief DB mutations serialize; different sessions remain concurrent. No unmeasured latency promise. Verify actual concurrent same-session scenarios on PostgreSQL, not just Mockito call ordering.

## Publication changes strictly required by this feature

Preserve existing AI_ONLY/legacy no-cohort report behavior. For explicit MANUAL_EXAMINER only:

1. Preflight and transactional publish use the same frozen required inventory of nonexcluded cohort members. Current all-submitted query differs if an outstanding attempt was excluded then submitted after freeze. Do not quietly report that extra attempt or include it in readiness. Matching submitted AttemptSummaryView objects are still fetched through AttemptService; enforce all frozen required attempts exist and are submitted.
2. Re-evaluate pinned coverage/assignment/decision completeness under session mutex instead of trusting a possibly stale COMPLETED flag. The existing evaluator already checks each frozen pinned item and objective scored state; enrich manual branch with assignment actor equality, valid decision provenance and selected EXAMINER pointer identity. A completed cohort flag can be historical, so publication must check current authoritative data.
3. ToReportInputs must reject subjective selected AI/unselected in MANUAL_EXAMINER even when AI exists. Use exact selectedExaminerScorePublicId and owner scope, not merely any score indexed by answer. Do not aggregate teacherScore.
4. Return concrete cohort/assignment/decision blockers in existing readiness response shape. Keep report snapshots immutable and their current codec compatible; adding AI decision provenance fields to snapshot is optional unless auditing requires them. Never regenerate existing published reports.
5. Keep objective/UNSCORED behavior outside manual cohort unchanged. Requiring manual pinned coverage naturally ensures objective scores for those cohorts; do not globally tighten the explicitly permissive old objective publication path.

Necessary regression scenarios: manual missing one subjective answer despite AI ready; assignment actor mismatch; selected AI despite valid Examiner score; excluded-later-submitted attempt; missing pinned item; objective still pending in manual cohort; legitimate AI_ONLY publication unchanged; published snapshots unchanged; concurrent last decision/publication; idempotent replay vs publication removes read entitlement; late AI result after manual decision.

## Frontend integration

Actual paths are pte-web/apps/tenant-web/{app,features,lib}, not src despite older CLAUDE prose. Read AGENTS.md and local Next16 guides before code. Existing features/examiner/ExaminerWorkView.tsx is a monolith with local detail selection; split thin queue/detail views and feature-local helpers. Extend packages/api-client/src/requests/scoring/examiner.ts and types/scoring/index.ts with discriminated reference/decision contracts.

Extend existing hooks features/examiner/api.ts: identity+tenant-scoped query keys, detail refetchOnWindowFocus=false, mutation retry=false, single stable requestPublicId/fingerprint per confirm, retain unknown intent until authoritative reconciliation. Per-answer drafts stay memory-only and survive media refetch but clear on actor/tenant change. Introduce explicit request/unknown/stale/committed state helper rather than scattered submit flags.

New nested route app/(dashboard)/examiner/work/[sessionPublicId]/[attemptPublicId]/page.tsx plus loading/error at each dynamic segment required by standards. Reuse tenant Examiner chrome and locale semantic shared UI. Prompt/response renderers support all six actual kinds. AI-use fills the field only; confirmed intent FINALIZE writes. Content/media unavailable blocks submit without erasing drafts.

Host integration stays in features/exams/components/{GradingCohortSection,HostScoreReviewPanel}. Expose authoritative gradingMarkingMode/selection capability in Host review DTO (currently absent), explain freeze-first when missing, disable AI source/teacher override for MANUAL_EXAMINER and show final EXAMINER read-only. Backend guards remain mandatory. Existing cohort preview only exposes finalized identity/mode, not ongoing completeness details: use an actual grading status projection/reconcile/read endpoint if readiness requires counts, rather than fake completion from preview.

## Plan-sized recommendation

1. Schema/audit/version/policy helper and safe legacy alignment.
2. Atomic Examiner API/reference/idempotency and canonical mutation lock order.
3. MANUAL_EXAMINER report/readiness/Host mutation enforcement, keeping old contracts elsewhere.
4. Shared client, routes and Examiner UI/draft/conflict/media states.
5. Host freeze-first/review/publication UI and integrated validation.

Testing/quality choices remain for the user per ck:plan/ck:cook; previous Proctor opt-out is not Examiner authorization. Security and concurrency regressions above are meaningful minimum verification candidates, not claims they already pass.

## Mutation lock matrix and commands

| Entry point | Current session mutex | Required action |
| --- | --- | --- |
| ScoringCommandService.requestScoring (objective/AI enqueue) | Yes, before ingest | Preserve production constructor path; avoid compatibility-null bypass in production. |
| ScoreSourceSelectionService.apply | Yes | Policy guard and complete replay fingerprint semantics; retain session-first. |
| ReportPublishService.publishSession | Yes | Acquire/check manual cohort before sorted answers/state; report frozen inventory. |
| GradingCohortService.finalizeCohort | Yes | Keep session→cohort→members→ingest; legacy alignment before evaluating manual completion. |
| ExaminerScoringService.submitScore | No | Session mutex before locks; owned cohort/member and publication recheck, atomic decision/source. |
| AiScoringResultPersistenceService.persistAiScore / markScoringFailed | No | Session mutex before answer/state; hold it through BEFORE_COMMIT reconciliation. |
| ScoringReviewService.submitTeacherScore | No | Session mutex before answer/state; MANUAL_EXAMINER reject mutation. |
| GradingCohortService.reconcile / reconcileIfPresent / reconcileScheduled | No | Obtain session mutex before cohort/member locks; scheduled snapshot enumeration must remain unlocked until each session is acquired. |
| ScoringIngestService.ingestForSession callers | Caller-dependent | Ensure every modifying caller takes the session mutex first; no direct answer→session path. |

Proposed commands, not executed:

- API compile from pte-api: `.\mvnw.cmd -pl app -am -DskipTests compile`.
- Focused API tests: `.\mvnw.cmd -pl app -am '-Dtest=ExaminerScoringServiceTest,GradingCohortServiceTest,GradingCompletionEvaluatorTest,GradingCompletionEvaluatorAssignmentCoverageTest,ScoreSourceSelectionServiceTest,AiScoringResultPersistenceServiceTest,ReportPublishServiceTest' -Dsurefire.failIfNoSpecifiedTests=false test`.
- Web from pte-web: `pnpm --filter tenant-web exec tsc --noEmit`; `pnpm --filter tenant-web lint`; `pnpm --filter tenant-web build`.
- Targeted real shared-client and feature Vitest tests can use `pnpm --filter @pte/api-client test` and `pnpm --filter tenant-web test`; confirm shared package's scripts at implementation before invoking.
- Add PostgreSQL concurrency/migration cases with an available project-supported DB harness. Java mock unit tests alone do not prove lock ordering, SQL constraints or the legacy backfill.
