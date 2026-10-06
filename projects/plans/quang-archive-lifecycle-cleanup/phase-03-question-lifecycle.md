# Phase 03: Question guarded Delete draft và Archive policy

Status: completed (scoped implementation and quality/unit gates); integration evidence in phase05. Stories: P1 authoring/history. Depends on: phase01.

## Tasks

- [x] Add DELETE at existing `/api/v1/questions/{publicId}` to implement current client helper; preserve platform write authorization and test PLATFORM_ADMIN/PLATFORM_AUTHOR separately.
- [x] Check DRAFT + proven never-published + no referenced revision/history/assessment usage under coherent lock/version strategy; deleted=true, current=false, audit. Role checks apply even repeat-delete.
- [x] Treat restored/published-history/UNKNOWN as nondeletable; return specific reason. New revision draft deletion policy conservative in first release: block revision-linked draft instead of automatically rewiring revision graph.
- [x] Write provenance on all create/publish/approve paths; never clear it in reject/archive/unarchive/revision creation incorrectly. Revision has its own provenance but reference relation still blocks deletion under conservative policy.
- [x] Narrow manual Archive to APPROVED or known-history DRAFT per transition table; PENDING and proven-new DRAFT conflict. Keep idempotent ARCHIVED behavior and automatic superseded revision retirement.
- [x] Exclude deleted on list/stats/direct GET/platform write paths, submission/publish/revision/approve/archive/unarchive and trusted freeze, not only frontend lists.
- [x] Review native pool/count queries: add deleted=false where needed for consistency; not just JPQL. Confirm already published snapshots can read their own immutable data independent of live pool.
- [x] Inspect assessment reference writers and locks via public boundary from phase01; no race where new reference commits after delete guard. If provenance/state already guarantees a writer cannot accept draft, prove with tests rather than adding unnecessary locks.
- [x] Batch capabilities on list; include provenance-specific blockers without exposing internals to callers.

## Files / surfaces

`ItembankService`, `QuestionController`, `QuestionRepository`, Question domain/DTO/constants, access policy and audit; assessment public usage facade/port and blueprint/snapshot queries only as required by reference inventory. `QuestionControllerSecurityTest`, `ItembankServiceTest`, `QuestionRepositoryTest` are existing test anchors.

## Design Constraints

Preflight: existing Question @Version serializes lifecycle writes against deletion lock; assessment accepts only APPROVED/current in freeze, and proven NEVER_PUBLISHED drafts cannot acquire blueprint/snapshot refs through public APIs. No reverse assessment dependency. Unknown history is protected; deletion/audit use a dedicated owning service. Tests/quality consent=yes all phases.

- Question has @Version already; do not retrofit BaseEntity optimistic version or bypass check with bulk write.
- DRAFT after unarchive never automatically becomes deletable.
- No hard delete options/media; deletion means removed from authoring, not erased DB rows.
- No Withdraw feature or changing approval permissions; pending review retains Approve/Reject.
- No destructive repair of current revision group; preserve superseded rows and historical snapshot contracts.

## Tests to Write First (đề xuất TDD)

1. New never-published DRAFT delete succeeds; published→archive→unarchive DRAFT delete409.
2. UNKNOWN legacy and revision-linked DRAFT409; PENDING/APPROVED/ARCHIVED delete409.
3. Tombstone can't get/update/freeze/publish/unarchive; repeated authorized delete no duplicate audit.
4. PlatformAuthor allowed only per current access policy; tenant/wrong role403 or scoped404 per contract.
5. Manual archive newDRAFT/pending409; published/known-history archive correct; auto-archive superseded still works.
6. Native pool/list/stats skipdeleted; generated/pinned snapshot renders historical content after retirement.
7. Concurrent delete/submit/publish/revision/usage yields one permitted result, no missing source or multiple-current revision invariant violation.

## Verification / exit

Relevant unit/security/repository/module tests + PostgreSQL commit-based concurrency tests. Test fixtures must cover old DRAFT without proven history and restored DRAFT separately. Do not infer pass from object status before commit.

## Quality and Testing State

- User test choice: yes, all phases; Standard, not TDD.
- Quality: APPROVED; [report](quality/phase-03-question-lifecycle-quality-report.json), [receipt](quality/phase-03-question-lifecycle-receipt.json).
- Testing: original 37 targeted tests passed; current matrix 38 including wrong-tenant tombstone protection. PostgreSQL races, stale-version rejection and snapshot retention are recorded in [test report](test-report.md).
