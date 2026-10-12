# Phase 07: Verification and handoff

**Status:** Completed — manual/runtime validation pending
**Stories:** US-01..09
**Depends on:** Phase01..06

## Goal

Ghi evidence đúng loại, không đồng nhất test pass với quality approval hay release-ready.

## Work items

1. Review actual changed paths + module dependencies, run git diff --check/conflict scan. Preserve unrelated exam-mode files và changes người khác.
2. Run focused BE repository/service/security/controller tests đã thêm; lựa test name thực tế không dùng wildcard tưởng có coverage. Report H2 vs PostgreSQL distinctly.
3. Run API-client/tenant focused tests; scoped eslint; API-client/UI/tenant/vendor typechecks do shared changes.
4. Run tenant production build; nếu app dev đang chạy thì chọn isolated supported build workflow sau đọc installed docs, không phá .next active hoặc tự kill process.
5. Run backend compile/module architecture checks phù hợp repo; verify no writes GET and bounded SQL/joins bằng test/evidence.
6. Independent code review mandatory trước claim complete; ck:quality nếu user chọn, ghi finding/result/checkpoint không tự approve dựa tests.
7. Handoff manual UI checklist cho user: Learner regression, ExamStaff single/dual roles, suspended read, same-tab/navigation/loading, account edit/errors, Proctor zones, Examiner per-column pagination/published.
8. Update phase statuses individually: implemented/verified/quality approved/manual pending. Final report exact commands/outcomes/skip/blocker; no push/deploy unless separately asked.

## Design Constraints

Preflight: final review resolves the current union of Phase02–06 reviewed production files, not old hashes. Shared outputs changed by later approved phases receive fresh integration coverage; old phase receipts represent their completion-time snapshots. Compile/lint/typecheck/build evidence is separate from tests, live API/PostgreSQL and manual UI. Preserve three unrelated exam-mode files. No migration/start-backend/deploy/commit authorization inferred.

Execution: Standard --no-tests --quality --checks-all-phases, automatic continuation. User explicitly declined tests: work items 2 and test portions of 3/5 are not executed, not claimed passed. Phase01–06 gates approved.

## Files

Final audit production scope is the deduplicated current reviewed_files union of quality/phase-02-backend-projections-and-profile-quality-report.json through phase-06-examiner-overview-and-board-quality-report.json, plus current declared Phase06 production outputs. Includes pte-api owner-module projections/controllers/migrations and pte-web API client, staff/detail, shared Profile/Board, Learner presentation adapters. Excludes unrelated ExamOverviewTab.tsx, ExamSettingsTab.tsx, SessionTable.tsx. Documentation output: handoff.md; phase/master lifecycle files are coordination state, not mutable production receipt inputs.

- User tự check UI; auto Playwright/E2E không mặc định trong scope.
- No pass claims từ unrun tests/build, no production database claim từ H2.
- No logging secrets/token/plaintext credentials.
- Failing required check => fix/retest scope hoặc honest blocker, không mark done.

## Focused verification

- Acceptance traceability mỗi US tới tests hoặc manual checklist owner.
- Build/typecheck failures, forbidden role/cross-tenant/deep-link errors được ghi rõ.
- Regression Learner, shared dropdown/breadcrumb consumers tenant/vendor; staff credential-email actions giữ existing semantics.

## Quality and Testing State

- Implementation: checks and handoff.md complete; US-01..09 mapped to source review and explicit user-owned manual checks.
- Quality: independent APPROVED; carried assertion-rationale advisory resolved, zero open findings. Canonical report and fresh receipt in quality/phase-07-verification-and-handoff-{quality-report,receipt}.json, receipt verified VALID. Separate post-gate final code review APPROVED in quality/final-code-review.md (103 current inputs, source-level proof only).
- Verification: backend compile, API/UI/tenant/vendor typechecks, scoped lint, tenant production build, git diff --check in three repos exit 0. FE3000/3001 login HTTP200 after build. See handoff.md for exact checks/warnings.
- Testing: not_started; user declined tests. No authenticated API/browser/PostgreSQL/migration validation.
- User checkpoint: manual UI pending; automatic continuation authorized, not release approval.
- Remediation: one explanatory comment added to useStaffDetailText.ts for the complete catalog key invariant. Fresh tenant tsc/scoped hook lint and tenant production build exit 0 afterwards; gate receipt and final code review refreshed.
- Không ghi completed/approved chỉ từ static review hay phase trước.

## Acceptance / Blocking gate

Required checks evidenced, remaining manual/quality gaps explicit, no unresolved blocker; user checkpoint not auto-granted.
