# Examiner workspace — implementation plan

Date: 2026-10-11. Mode: **Hard**. Test flag: **default; --tdd not selected**.
Status: planned; validation answers pending; no product implementation or executed verification claimed.
Inputs: [approved design](spec.md), [Primary research](research-primary.md), [Alternative research](research-alternative.md).

## Scope Challenge

- Exists: real Examiner queue/detail/immutable scoring, AI results, Host review/source selection and cohort publication infrastructure exist.
- Minimum: extend those contracts and UI; reuse immutable ExaminerAnswerScore and frozen MANUAL_EXAMINER policy. No second tenant app or parallel policy aggregate.
- Complexity: Hard because cross-module publication, tenant authorization, immutable decisions, migration and concurrent writers are involved.
- Spec quality: P1/P2/P3 stories, measurable criteria and explicit lifecycle are present; no unresolved NEEDS CLARIFICATION marker. Current spec's draft status is historical; user has approved the AI-assisted Examiner-final design.

## Resulting behavior

Host closes the session and freezes MANUAL_EXAMINER membership. Examiner can read assigned work beforehand, but can finalize only a nonexcluded frozen member. AI remains a reference; explicit CONFIRM_AI or MANUAL creates an immutable human decision and selects EXAMINER atomically. Host publishes the exact frozen inventory only after authoritative coverage checks. AI_ONLY and published snapshots retain current contracts.

## Phases

| Phase | Deliverable | Coverage |
| --- | --- | --- |
| [01 contracts/schema/reference](phase-01-contracts-schema-reference.md) | Safe AI projection, decision/receipt schema, deterministic versions | P1 reference; FR01–03,05–07,10 |
| [02 atomic decisions and coordination](phase-02-atomic-decisions-coordination.md) | Finalize/replay, session-first writers, manual policy guards | P1 finalize/resilience; FR04–08,13–14 |
| [03 publication and legacy alignment](phase-03-publication-legacy-alignment.md) | Frozen report inventory, readiness, bounded SQL legacy backfill | P1 Host publication; FR08–10 |
| [04 Examiner routes/UI](phase-04-examiner-routes-ui.md) | Queue, deep-link grading, exact-intent drafts and shared client | P1 Examiner/resilience; FR01–04,06–07,11–16 |
| [05 Host workflow and delivery verification](phase-05-host-workflow-delivery.md) | Freeze-first Host UX, release sequence, integrated checks/docs | P1 publication; FR08–10,14,16 |

Run in order. Phase output is reviewable source, not permission to deploy. Do not activate flags or deploy automatically. Backend and updated client/UI must co-release for manual writes.

## Architecture decisions

1. Existing immutable score is both decision audit and request receipt: actor/time/score plus kind, viewed AI metadata, request key and full fingerprint stored at creation. Partial unique `(tenant_id, examiner_public_id, request_public_id)` and scoped repository lookup enforce exact replay/cross-answer reuse. No separate receipt entity/table.
2. Canonical SHA-256, length-prefixed encoding; separate AI version and per-answer review version. Exclude signed URLs and unrelated answers. Review hash covers frozen content, assignment, membership/policy, AI, decision and publication.
3. Current authorization precedes receipt replay; matching replay precedes stale-version checks. Different intent with the same key conflicts even across answers. Published or revoked access still denies response.
4. All relevant mutators/reconcilers first obtain the existing tenant/session mutex through SessionService. Network/provider/media signing is outside mutation locks. Scheduler uses one session per proxied transactional call.
5. Reporting consumes manual readiness/inventory through public ScoringService DTOs/facade; no reporting import of scoring internal repositories.
6. Legacy alignment uses immutable versioned SQL only, never repair-on-read or JPA update of immutable scores. Cohort-less/excluded/ambiguous legacy records require explicit remediation before release, not inferred policy.

## Risks and bounded choices

- Session mutex serializes short same-session writes. Verify concurrency on PostgreSQL; do not claim throughput or latency without measurement.
- Existing published snapshots and AI_ONLY behavior are exclusions from source backfill and policy tightening. Manual objective coverage may be stricter because the manual cohort barrier applies.
- A legacy score without an explicit cohort cannot be safely classified. Diagnostics and operator-approved follow-up SQL after explicit cohort creation are required; no runtime import or automatic cohort freeze.
- New MANUAL writes reject old score-only payload with an actionable code. Document co-release and rollback boundary before enabling writes; additive reads alone do not make old mutations compatible.
- A stale COMPLETED flag is not sufficient publication proof. Re-evaluate membership, pinned inventory, assignment ownership and selected immutable score pointer under the mutex.
- P2 AI commentary/rubric is display-only when a real contract exists; P3 reopen/multiple examiners remains excluded.

## Implementation tasks

- [ ] Phase01 — contracts/schema/reference.
- [ ] Phase02 — atomic decisions and session coordination.
- [ ] Phase03 — publication barrier and SQL legacy alignment.
- [ ] Phase04 — Examiner routes/shared client/UI.
- [ ] Phase05 — Host workflow and delivery verification.

## Red-team adjudication

Review: [plan-review.md](plan-review.md), original verdict WARN, no BLOCK.

- F1 ACCEPTED — request receipt embedded on immutable score; separate entity/table removed.
- F2 ACCEPTED — Primary runtime-freeze alignment superseded with explicit SQL-only remediation, no automatic repair.
- F3 ACCEPTED — focused commands include real teacher/read-projection tests and retain existing source-selection test.
- F4 ACCEPTED — lifecycle/immutability already approved; validation limited to remaining execution facts/choices.
- F5 ACCEPTED — keep actual POST preflight/bodyless POST publish; server revalidates under mutex, no invented publication request version.

## Validation questions before cook

1. For all five phases: post-code tests + quality, TDD + quality, or compile/lint only? Recommend --tdd for immutable decisions/publication. Record choices for all phases; Proctor's old choices do not transfer.
2. Are there real MANUAL_EXAMINER sessions with saved scores and unpublished results, or only new/sample sessions? If unknown, inventory with read-only diagnostics before any live data changes.
3. Use isolated local sample data, a trial session in staging, or defer end-to-end smoke until after code/build? No deployment implied by implementation authorization.

## Quality and Testing State

- Quality: not evaluated; optional per-phase choice pending.
- Testing: not started; optional per-phase choice pending.
- No --tdd authorization yet; recommend it for the concurrency/publication acceptance criteria after validation.
- Compilation/typecheck/lint/build are planned verification commands, not reported results.

## Handoff

After validation: `/ck:cook --hard plans/examiner-tenant-workspace/plan.md` from pte-doc context. Add `--tdd` only if selected.
Next skill confirms per-phase optional test/quality choices; acceptance cases remain requirements regardless of check selection.
