# Alternative research: AI assisted Examiner finalization

Date: 2026-10-11. Read-only research against approved spec; no product edits or executed tests.

## Verdict

Extend the existing immutable `ExaminerAnswerScore` and existing frozen `MANUAL_EXAMINER` cohort. Do not introduce a second decision aggregate or tenant-wide grading policy. Add immutable decision metadata and a narrowly scoped request receipt only if strict tenant/actor request-key reuse requires it. Use a deterministic per-answer review hash and a separate AI reference hash. Keep objective scoring separate and preserve AI_ONLY and published snapshots. Require an established manual cohort before a new decision can commit.

This is smaller than a new policy/version/decision subsystem, but still needs changes to reporting and Host APIs: the current publication endpoint does not enforce cohort mode or coverage. A frontend-only lock is insufficient.

## Evidence from actual lifecycle

Paths below are relative to `pte-api/app/src/main/java/com/pte/` unless noted.

- `scoring/internal/service/GradingCohortService.finalizeCohort`: requires a CLOSED session; freezes candidate membership and markingMode, rejects changing mode/version on an existing cohort; rejects creating AI_ONLY when assignments exist. Mode is not configured on a session at creation.
- `scoring/domain/GradingCohort`: no setter for markingMode; only status transitions FROZEN to COMPLETED. `cohortVersion` remains 1; JPA `lockVersion` changes when completion occurs. Do not mistake either for a complete review version.
- `scoring/internal/service/ExaminerAssignmentService.confirm`: assignments can be committed before cohort creation. It validates batch, current eligible pool and publication, but does not reject an existing AI_ONLY cohort.
- `scoring/internal/service/ExaminerScoringService.submitScore`: checks active Examiner, assignment, tenant and AI eligibility; locks answer then optional publication state; persists immutable score. It does not check cohort or select EXAMINER automatically. Equal actor/score retry succeeds, but has no request intent/version metadata.
- `scoring/internal/service/GradingCompletionEvaluator.evaluate`: evaluates every frozen pinned item. UNSCORED items count satisfied; OBJECTIVE requires SCORED with valid rawScore. MANUAL subjective items require assignment and a publishable Examiner score. Current code checks assignment existence/count, not explicitly score actor versus assigned actor or selected EXAMINER pointer.
- `reporting/internal/service/ReportPublishService.publishSession`: uses current submitted attempts and source-based report readiness, then snapshots. It does not use frozen grading cohort/mode/completion. Current publication can therefore use AI despite a manual cohort or omit expected answers not represented by scoring rows.
- `scoring/internal/service/ScoringReviewReadQueryService.blockingReason`: explicitly preserves publication of missing objective scores by excluding them from aggregation. This differs from cohort completion's objective requirement. For MANUAL publication, the approved spec requires the stricter cohort barrier; preserve AI_ONLY's existing rule rather than silently changing it globally.
- `scoring/internal/service/ScoringCommandService.requestScoring`: AI scoring is Host-triggered, not automatically triggered by submission or manual cohort creation. UI must not promise AI appears automatically; manual decision remains possible while AI is pending/unavailable.
- `scoring/domain/ScoringAnswer.hasPublishableAiScore`: only SCORED, valid 0–100, REAL provider category and nonempty provider are publishable. Mock/unknown provenance must not become AVAILABLE merely because rawScore exists.
- `scoring/internal/service/AiScoringResultPersistenceService`: terminal SCORED/SCORING_FAILED results are not rerun by this persistence path. Late initial AI can still arrive after an Examiner decision. Domain selection is independent, so retaining EXAMINER selection prevents overwrite.

## Alternative comparison

| Decision | Smaller option | Larger option | Recommendation |
|---|---|---|---|
| Grading authority | Existing frozen MANUAL_EXAMINER cohort | New policy/version entity on session | Existing cohort; block finalize before manual policy exists. |
| Human decision | Extend immutable ExaminerAnswerScore | New FinalDecision aggregate plus old score | Extend existing row; existing foreign keys/source pointers already reference it. |
| Review concurrency | Canonical per-answer hash | Expose answer lockVersion alone | Hash including content identity, AI state, decision and policy/publication. |
| AI reference version | Hash AI result/state/provenance | Reuse whole answer lockVersion | Separate AI hash; source selection/teacherScore are not AI changes. |
| Request receipt | Metadata on immutable score | Separate request receipt table | Row metadata if key scope includes answer; strict tenant/actor global key needs separate scoped receipt constraint. |
| Legacy transition | Bounded Flyway/data migration with diagnostic query | Runtime repair during GET/POST/publication | Bounded migration, fail closed on ambiguous cases. |
| Contract | Add optional fields and reject old writes in manual mode | New versioned score endpoint | Additive read DTOs plus explicit server validation; document old manual writes are rejected, not silently interpreted. |

## Suggested smallest safe shape

1. Keep immutable score row authoritative. Add decision kind, reviewed AI score/version, request identifier/fingerprint and expected review version at insert. LEGACY_IMPORTED has unknown AI metadata and cannot be submitted by a client. Never update row through JPA: it has `@PreUpdate` and `@PreRemove` guards.
2. Atomically insert decision, set answer source/pointer to EXAMINER with Examiner actor/time, and write audit. Reuse `ScoringAnswer.selectScoreSource` after score flush; this validates existing score ownership and saved identity. `ScoreSourceAudit` currently models Host bulk scope and does not capture per-answer decision kind or AI snapshot: do not falsely claim it already supplies that audit. Immutable row metadata can hold this audit without duplicating decision score in a new aggregate.
3. Read DTO remains compatible with existing `status/myScore/submittedAt` while new `decision/aiReference/reviewVersion` become authoritative for updated UI. Existing `{score}` writes in MANUAL must return explicit actionable validation failure until updated client is deployed. Silently treating them as MANUAL lacks evidence of the AI snapshot reviewed.
4. Root adjudication chooses the smaller embedded receipt: creation-only metadata plus unique `(tenant, actor, request)` on immutable score rows and a scoped lookup detect cross-answer reuse. A separate table is unnecessary for this one-decision-per-answer model. Cross-session concurrent collisions need rollback-safe reconciliation in either design. Include answer, score, kind and both versions. Current authorization precedes replay; replay precedes stale-version checks. Published access remains denied.
5. Compute length-prefixed canonical SHA-256 hashes (existing `ScoringReviewReadQueryService.reviewVersion` is a local precedent). Use per-answer content identity/pinned item/template plus immutable prompt snapshot identity, relevant AI state/provenance/scoredAt, score decision id, immutable cohort mode/identity and publication state. Exclude media URLs. Avoid borrowing whole-session hash, which would invalidate drafts when unrelated answers change.
6. Map AI availability from actual state: valid REAL score AVAILABLE; PENDING/AI_SCORING PENDING; SCORING_FAILED FAILED; invalid/non-REAL SCORED UNAVAILABLE. Distinguish not-yet-dispatched from provider failure; never infer FAILED from null score alone. AI rawScore/provider data can be exposed only through safe Examiner projection, without Host teacherScore or provider secrets.
7. New commit requires manual cohort and nonexcluded membership; unconfigured assignments may remain readable with explicit policy-pending state, but controls cannot finalize. Host must close session and finalize manual cohort first. Existing assignment-overview workflow needs a link/state, not a new session policy.
8. Host source-selection preview/apply and teacher-score submit reject mutations for MANUAL mode; source is managed by Examiner finalization. Guard all scopes before mutation, including request replays where current permission/policy applies. AI_ONLY remains existing behavior.
9. Manual publication uses frozen nonexcluded cohort and re-evaluates all expected coverage under transaction, validates assignment/score owner/publishable source pointer, then reports EXAMINER. It cannot rely only on a stale COMPLETED flag or count existing rows. Preserve objective aggregation implementation; cohort barrier provides missing-objective blocking only for manual mode. Do not reach across reporting into scoring repositories: add facade/read-model fields or readiness method on `ScoringService`.

## Concurrency decisions the plan must resolve

`ScorePublicationLockService.lockForPublication` locks session answers ordered by id, then state. `AiScoringResultPersistenceService` and current Examiner use answer then state. Host source selection and publication additionally lock the session through `SessionService` first. `GradingProgressListener` reconciles BEFORE_COMMIT, taking cohort then member locks; scheduled reconciliation starts cohort-first and calls ingest. Therefore answer → state is not the whole lock graph.

Two options:

- Acquire a shared session coordination lock on every relevant writer/reconciler before answer/state/cohort locks. Clear and linearizable, but serializes same-session AI completions and broadens changes across scheduling, ingest and adapters.
- Keep answer/state order; make progress reconciliation AFTER_COMMIT in a separate transaction, with scheduler as recovery, and make manual publication authoritative by evaluating actual coverage/decisions under its transaction. Narrower changes, but cohort-first reconcile/ingest still needs an explicit compatible lock strategy. Changing listener timing alone does not prove absence of all deadlocks.

**Concrete recommendation after comparing with Primary:** use the existing tenant-scoped `SessionService.lockForScoreReviewMutation` as the canonical session-row mutex, before every cohort/answer/state mutation. It does not require CLOSED, so AI and assignment workflows can retain their current lifecycle. Publication/cohort finalization retain their additional CLOSED checks. Extend locking to AI persistence, Examiner writes, per-event/scheduled reconciliation, and ingest/objective entry points that can mutate independently. This is broader than moving the listener, but it supplies a single order and avoids a partly fixed lock graph. Same-session writers serialize briefly; provider/network calls stay outside the mutex. It does not serialize unrelated sessions.

Keep scheduler transactions bounded to **one session per transaction**: a nontransactional scheduler iterates identifiers and delegates to a separate transactional bean/method, rather than acquiring many session locks in one scheduled transaction. Ensure Spring interception (no self-invocation assumption). BEFORE_COMMIT reconciliation can remain inside the already held session mutex if all entry points participate. AFTER_COMMIT + REQUIRES_NEW is an optional later latency improvement, not required to establish correctness and not a replacement for the shared mutex. Include assignment confirmation, cohort finalization/reconciliation, Host bulk selection, Examiner decision, AI persistence, scoring command and publication in the documented graph.

## Bounded legacy migration

Migration sequence should add schema first, classify unpublished MANUAL sessions, and backfill score metadata/source only where existing score matches answer ownership and assignment. Existing V59 database constraints already bind scores to answer and assignment owner; V58/V59/V62 establish source pointer/audit constraints. Latest migration at inspection was V91; pick the next available version at implementation time.

- Published reports: leave snapshots and source rows unchanged.
- AI_ONLY: leave policy/selection behavior unchanged.
- Unpublished MANUAL with valid old scores: mark LEGACY_IMPORTED, null reviewed AI metadata, set EXAMINER pointer and selection actor/time from stored score. Do not invent CONFIRM_AI versus MANUAL.
- Unpublished MANUAL with missing score: leave pending and block publication.
- Scores/assignments without cohort, inconsistent provenance or excluded attempts: report counts/ids for operator remediation; do not auto-create a manual cohort from mutable live candidates or select AI fallback. Decisions cannot proceed until an explicit manual cohort is established.

Avoid runtime repair in read endpoints: it makes reads mutate published-adjacent state, obscures operator impact, and creates mixed contracts.

## Frontend compatibility and placement

Read `pte-web/AGENTS.md`: local Next.js guide must be read before product code. Current feature root is `apps/tenant-web/features/examiner/ExaminerWorkView.tsx`, with real TanStack hooks in `api.ts`; shared client uses `packages/api-client/src/requests/scoring/examiner.ts`. Existing mutation only sends `{score}` and queue/detail query keys omit actor/tenant.

Use queue view plus separate thin route `app/(dashboard)/examiner/work/[sessionPublicId]/[attemptPublicId]/{page,loading,error}.tsx`. Add actor/tenant to query keys and clear in-memory decision drafts on identity change. Disable automatic mutation retry, refetch-on-focus for detail and score edits during unknown outcome. Preserve entire request fingerprint for explicit same-intent retry. Refetch only updates authoritative AI/decision state; it must not silently replace a draft or the snapshot the user reviewed.

## Contradictions requiring explicit plan decisions

1. Spec says mode before decision; current cohort only after CLOSED. Choose pre-cohort read-only queue, rather than inventing early session policy.
2. Existing publication bypasses cohort and uses live submitted attempts. Manual publication must consume frozen membership and full coverage; preserve legacy AI_ONLY intentionally.
3. Objective readiness differs between cohort and report projection. Apply manual cohort barrier without global objective-contract changes.
4. Existing strict immutable score lacks request metadata; same score is not sufficient proof of same kind/AI snapshot. Receipt scope must match spec, including cross-answer key reuse.
5. API compatibility cannot mean accepting old score-only writes while requiring reviewed versions. Specify read compatibility and deliberate manual-write rejection/deployment ordering.
6. Cohort completion currently checks score validity/count, not selected source or assignment actor equality. Expand manual verification and validate selected score pointer, not just a label.
7. BEFORE_COMMIT reconciliation is part of lock ordering; a plan limited to answer/state locks is incomplete.
8. AI_ONLY cohort already frozen can currently receive assignments later. Reject incompatible assignment confirmation; do not convert it silently.
