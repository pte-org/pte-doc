# Examiner workflow API contracts and execution audit

Proposed design contracts, 2026-10-12. User clarified PLAN ONLY; Java records/services/migrations have not been retained or implemented. The following fields are the future backend/frontend handshake, not available APIs.

All bodies below are raw JSON objects inside existing ApiResponse responses. Paths are under /api/v1/examiner/work; authenticated active EXAMINER, current tenant and immutable assignment owner are required before any detail or receipt disclosure. Never expose student identity or another examiner's records.

## Commands

- POST /{sessionPublicId}/{attemptPublicId}/start: {requestPublicId: UUID, expectedWorkVersion: long}. Missing work revision 0; first persisted revision 1. Explicit successful start moves Pending to In Progress. GET never writes.
- PUT /{sessionPublicId}/{attemptPublicId}/answers/{answerPublicId}/draft: {requestPublicId: UUID, expectedWorkVersion: long, expectedDraftVersion: long, score: integer|null, comment: string|null, decisionKind: MANUAL|CONFIRM_AI|null, expectedReviewVersion: string|null, reviewedAiVersion: string|null}. Score 0..100, comment maximum 2000 characters. Incomplete drafts allowed; save does not select score source or publish. Missing draft revision 0, first save 1. Work version changes only on start/finalize, not individual draft saves.
- POST /{sessionPublicId}/{attemptPublicId}/finalize: {requestPublicId: UUID, expectedWorkVersion: long, answers: [{answerPublicId: UUID, expectedDraftVersion: long, expectedReviewVersion: string|null, reviewedAiVersion: string|null}]}. Manifest must exactly cover the current required eligible pool without duplicates. Legacy immutable finals use draft version 0 and null review/AI versions. New decisions require saved complete draft with exact draft/review/AI identities. Scores/comments come from server drafts, not client manifest.
- GET /{sessionPublicId}/{attemptPublicId}/commands/{requestPublicId}: returns committed receipt or 404. Read authorization precedes receipt lookup. Same UUID with changed operation/payload conflicts (409); exact replay is inspected before publication/completion/version/AI mutable gates.

Command response: {receipt: {requestPublicId, operation: START|SAVE_DRAFT|FINALIZE|REPORT_ISSUE|RESOLVE_ISSUE, committedAt, workVersion, answerPublicId: UUID|null, draftVersion: long|null, childRequests: [{answerPublicId, requestPublicId}]}, current: ExaminerWorkflowView}. Receipt fields are immutable original outcome; current is separately labeled refreshed state. Draft save response also contains draft. Unknown outcome clients retain exact captured body and UUID until receipt lookup or exact retry resolves it.

Child identity algorithm: Java UUID.nameUUIDFromBytes UTF-8 of `examiner-finalize-v1:<parent UUID>:<answer UUID>` (canonical lowercase UUID strings). Parent UUID is used only by aggregate receipt. Each new final score uses its own child UUID and existing ExaminerReviewVersionService per-answer intent fingerprint. Canonical aggregate intent sorts answer UUIDs and length-prefixes every scalar including null markers before SHA-256; object property order and list order do not change intent. Legacy keys are never rewritten. A reused child UUID conflicts and rolls back the entire transaction.

## Read projections

Existing detail response is extended with workflow: {mode: ATOMIC_DRAFT, status: PENDING|IN_PROGRESS|COMPLETED, workVersion, startedAt: Instant|null, finalizedAt: Instant|null, readOnly, canStart, canSaveDraft, canFinalize, blockingReason: string|null, drafts: [{answerPublicId, draftVersion, score, comment, decisionKind, expectedReviewVersion, reviewedAiVersion, savedAt}]}. Existing answers/prompts/media/AI/decision fields remain. Published Completed uses separate authorized read-only projection; mutable publication guard remains on every command. Existing per-answer score endpoint rejects new decisions under atomic capability; existing committed exact receipts remain retrievable after authorization.

Queue GET accepts status, sessionPublicId, search (bounded safe attempt/session UUID text), sort: ASSIGNED_ASC|ASSIGNED_DESC, page and size (maximum100). Filter before paging; stable assignment UUID tie-breaker. Overview scope becomes ASSIGNED_WITH_PUBLISHED_COMPLETED: Pending/InProgress unpublished; Completed includes published own finalized work; same counts/progress scope. Zero eligibility or stored-count mismatch is triage, never Completed. Priority remains actionable unpublished outstanding work. No deadline field.

GET /history: same bounded paging and search plus sessionPublicId; returns {items:[{eventPublicId, sessionPublicId, attemptPublicId, answerPublicId:null|UUID, operation, occurredAt, workVersion, draftVersion:null|long}], page,size,totalElements,totalPages}. Own grading event audit only, includes publication history.

GET /{sessionPublicId}/{attemptPublicId}/guidelines: {scaleMin:0, scaleMax:100, limitation:string, templates:[{scoreTemplatePublicId, items:[existing public ScoreTemplateItemResponse]}]}. Resolve only own assigned pinned answer templates through public ScoreTemplateService. Existing weights/runtime are context, not new criterion definitions.

POST /{sessionPublicId}/{attemptPublicId}/issues: {requestPublicId, expectedWorkVersion, answerPublicId:null|UUID, type:AUDIO_UNAVAILABLE|MEDIA_UNAVAILABLE|RESPONSE_DATA|OTHER, description:string}. Nonblank description max2000; all issue types blocking until Host resolves. GET same /issues returns own scoped [{issuePublicId,sessionPublicId,attemptPublicId,answerPublicId,type,description,status:OPEN|RESOLVED,reportedAt,resolvedAt:null|Instant,resolution:null|string}]. Host endpoints under /api/v1/host/examiner/issues (session filter and bounded pagination); POST /{issuePublicId}/resolve: {requestPublicId,resolution:string}, nonblank max2000; HOST_ADMIN and session Host authorization. Resolve audits actor/time, changes no score/publication and supports exact retry. No reopen.

## Source audit and persistence design

No API AGENTS.md found. Preserve existing SessionService and attendance files, including V97. Current maximum rechecked V97; reserve V98 only after Phase1 acceptance and immediately recheck before writing. Existing V58/V59 one owner per attempt, one immutable score per answer and V95 unique tenant/examiner/request remain unchanged. Current read CTE incorrectly treats zero eligibility as Completed and excludes all published records; current detail also rejects published. Both need own read-only path with strict score owner filtering. Current final-score submit already validates exact AI and review fingerprints; extract reusable policy instead of duplicating it.

SessionService.lockForScoreReviewMutation uses pessimistic session row lock. ReportPublishService already obtains same session row via lockClosedForReportPublication before ScorePublicationLockService locks ordered answers/state. New commands use session -> work -> answer locks sorted stable numeric primary key (matching existing publication lock) -> publication state; issue resolution shares session -> work. Host publication readiness must explicitly check aggregate completion, not only selected score sources.

Add examiner_grading_work unique assignment FK, tenant/session/attempt/owner, status, revision, actual nullable start/final timestamps; examiner_answer_drafts unique work+answer FK with revision and bounded draft intent; examiner_grading_events immutable own audit; examiner_grading_commands immutable canonical fingerprint+original receipt JSON unique owner+assignment+request; examiner_grading_issues with Host resolution audit. Comments for new finals retained in immutable event/finalize receipt context; preserve all old score fields.

Legacy backfill only for verified nonempty actual pinned pool with equal stored count and valid owner subset: zero finals Pending, partial InProgress, all finals Completed with MAX(real submitted_at); unknown start remains null. Missing/mismatched pinned template/method, zero pool, foreign final owner or final outside pool prevents mutation and backfill. Resolve actual pinned profile through ScoringEligibilityQueryService/ScoringMethodResolver before every new write. Missing work reads derive effective state; no GET upsert.

Rollback disables new mutation/UI while retaining additive data and old final scores; retain server bypass guards. No production schema execution, flag rollout or database inventory execution authorized here.

## Read-only inventory SQL (not executed)

Run on an authorized safe PostgreSQL copy. This persisted-method inventory is preliminary; application ScoringMethodResolver runtime profile validation must agree before backfill. Null/unknown eligibility is triage.

```sql
BEGIN TRANSACTION READ ONLY;
WITH pools AS (
 SELECT a.public_id assignment_public_id,a.tenant_id,a.session_public_id,a.attempt_public_id,a.examiner_public_id,
 a.eligible_answer_count,
 COUNT(sa.id) FILTER (WHERE sti.scoring_method IN ('AI_SPEECH','AI_TEXT')) actual_eligible,
 COUNT(sa.id) FILTER (WHERE st.id IS NULL OR sti.id IS NULL OR sti.scoring_method NOT IN ('AI_SPEECH','AI_TEXT','OBJECTIVE','UNSCORED')) unknown_profile,
 COUNT(es.id) FILTER (WHERE sti.scoring_method IN ('AI_SPEECH','AI_TEXT') AND es.examiner_public_id=a.examiner_public_id) own_finals,
 COUNT(es.id) FILTER (WHERE es.examiner_public_id<>a.examiner_public_id OR sti.scoring_method NOT IN ('AI_SPEECH','AI_TEXT')) foreign_or_outside_finals,
 MAX(es.submitted_at) real_last_finalized_at
 FROM examiner_attempt_assignments a
 LEFT JOIN scoring_answers sa ON sa.tenant_id=a.tenant_id AND sa.session_public_id=a.session_public_id AND sa.attempt_public_id=a.attempt_public_id AND NOT sa.deleted
 LEFT JOIN score_templates st ON st.public_id=sa.score_template_public_id AND NOT st.deleted
 LEFT JOIN score_template_items sti ON sti.template_id=st.id AND COALESCE(sti.task_type_key,sti.task_type)=sa.task_type AND NOT sti.deleted
 LEFT JOIN examiner_answer_scores es ON es.answer_public_id=sa.answer_public_id AND es.tenant_id=a.tenant_id AND NOT es.deleted
 WHERE NOT a.deleted
 GROUP BY a.public_id,a.tenant_id,a.session_public_id,a.attempt_public_id,a.examiner_public_id,a.eligible_answer_count
)
SELECT p.*, state.publication_public_id, cohort.marking_mode, cohort.status cohort_status, member.excluded,
 CASE WHEN actual_eligible=0 OR unknown_profile>0 OR eligible_answer_count<>actual_eligible OR foreign_or_outside_finals>0 THEN 'TRIAGE'
 WHEN own_finals=0 THEN 'PENDING' WHEN own_finals<actual_eligible THEN 'IN_PROGRESS' ELSE 'COMPLETED' END verified_state
FROM pools p
LEFT JOIN scoring_session_states state ON state.tenant_id=p.tenant_id AND state.session_public_id=p.session_public_id
LEFT JOIN session_grading_cohorts cohort ON cohort.tenant_id=p.tenant_id AND cohort.session_public_id=p.session_public_id AND NOT cohort.deleted
LEFT JOIN session_grading_cohort_members member ON member.cohort_public_id=cohort.public_id AND member.attempt_public_id=p.attempt_public_id AND NOT member.deleted;
SELECT es.tenant_id,es.session_public_id,es.attempt_public_id,es.answer_public_id
FROM examiner_answer_scores es WHERE NOT es.deleted AND NOT EXISTS (
 SELECT 1 FROM examiner_attempt_assignments a WHERE NOT a.deleted AND a.tenant_id=es.tenant_id AND a.session_public_id=es.session_public_id AND a.attempt_public_id=es.attempt_public_id AND a.examiner_public_id=es.examiner_public_id);
SELECT tenant_id,session_public_id,attempt_public_id,publication_public_id,published_at
FROM attempt_reports WHERE published AND report_snapshot_json IS NOT NULL;
ROLLBACK;
```

Inventory acceptance: no backfill/write for any TRIAGE row; investigate all orphan ownership and snapshot anomalies; preserve published report snapshots. No counts claimed until authorized execution.

Baseline compile: cached Maven 3.9.16, offline app reactor with skipTests and explicit user home/local repository, BUILD SUCCESS on 2026-10-12 20:14 Asia/Saigon. No production database execution; source SQL/profile review only.

