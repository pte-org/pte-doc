# Phase 9: QA Gate

## Requirements

Perform the final Member 3 compliance, regression, contract, and evidence sweep
for every implemented Host phase. Add no new product feature. Required handoff
covers Phase 0–7; if Phase 8 is implemented, the same gate includes its live
runtime evidence.

Maps to: **All P1 stories | FR-01 through FR-18 | Milestone-1 success criteria**

## Design Constraints

- QA fixes defects and standards violations only. New features or contract
  expansion require a separate approved spec/phase revision.
- `pte-app/CLAUDE.md`, `pte-app/docs/CODING_STANDARDS_APP.md`, canonical
  `spec.md`, all implemented phase files, and backend tracking evidence are the
  binding review set.
- Run focused phase tests before the full suite so failures remain attributable.
- `flutter analyze` and `flutter test` must exit zero; timeout, missing tooling,
  or unavailable services are unresolved residuals, not passes.
- Inspect every new Dart file for feature ownership, dependency direction,
  sealed events, immutable states, hardcoded copy/colors, controller/subscription
  disposal, mounted checks, build size, and file size.
- Backend source changes are limited to approved Phase-6 scoring query work and
  must have compile/package plus recorded contract checks.
- Do not commit, push, merge, rebase, or switch branch during QA. Present the
  final uncommitted diff to Hung for review first.

## Steps

1. Build a spec-to-phase traceability table for FR-01 through FR-18 and every
   success criterion; identify the implementing files and tests/evidence.
2. Run `dart format` and verify no formatting delta remains.
3. Run focused tests for core networking/auth, host_console, authoring,
   scheduling, scoring_review, and host_audit; include live_proctor only when
   Phase 8 was implemented.
4. Run the full `flutter analyze` and `flutter test` commands with bounded,
   recorded execution; resolve all deterministic failures.
5. Run static searches for hardcoded `Text` copy, raw `Color(0x...)`, direct Dio
   construction in features, cross-feature implementation imports, missing
   dispose/mounted patterns, and oversized files/build methods; review every hit
   rather than assuming grep alone proves compliance.
6. Re-run existing Member 2 auth, exam-attempt, sync/media, and report tests
   explicitly to isolate regressions from the central Phase-0 transport change.
7. Compile/package every backend service modified by Member 3 and replay
   documented role/tenant/status/pagination contract cases through the gateway.
8. Perform one bounded required-path runtime scenario:
   Host login → create MCQ/READ_ALOUD/WRITE_ESSAY → blueprint/snapshot → session
   composition → enroll/assign → score → review → publish → audit view.
9. Record environment-blocked steps with command, output, expected prerequisite,
   and residual impact. Do not replace missing runtime proof with a passing
   checkbox.
10. Create/update per-phase test reports and quality reports/receipts following
    the same `tests/` and `quality/` structure used by Ninh/Quang.
11. Run `git status --short`, `git diff --stat`, and `git diff --check` in
    `pte-app`, `pte-api`, and `pte-doc`; confirm only approved Member 3 files are
    present.
12. Present architecture summary, changed files, verification matrix, residual
    risks, and the full uncommitted diff to Hung. Commit only after explicit
    approval.

## Success Criteria

- [x] Every FR and required success criterion maps to implemented code plus
      test/contract evidence or an explicitly recorded residual block.
- [x] All implemented Flutter focused tests pass.
- [x] `flutter analyze` and the complete `flutter test` suite exit zero.
- [x] Member 2 auth/exam-attempt/sync/media/report regressions pass after Host
      changes.
- [x] Every Member-3 backend change packages successfully and has role/tenant/
      status/pagination contract evidence.
- [x] Required runtime path is demonstrated or each blocked dependency is
      recorded without claiming end-to-end completion.
- [x] New source complies with feature boundaries, state patterns, resource
      lifecycle, hardcoded-resource rules, and size limits.
- [x] Test and quality artifacts exist for every implemented phase in the team
      plan format.
- [x] Final working trees contain only approved changes and remain uncommitted
      until Hung's review.

## Quality and Testing State

- Quality gate:
  `APPROVED_WITH_RUNTIME_AND_BASELINE_FORMAT_RESIDUALS`. The architecture
  review found and resolved one cross-feature composition violation by moving
  BLoC creation into feature-owned entry pages.
- Focused Phase 6-7 tests: 13 passed.
- Host/core focused regression: 152 passed.
- Explicit Member 2 regression: 195 passed.
- Full Flutter gate: `flutter analyze` passed and 295 tests passed.
- Backend gate: scoring package built successfully; 3 contract/service tests
  passed.
- Runtime: blocked because `docker compose ps` reports no running containers.
  The gateway-backed login-to-audit path is not claimed as end-to-end verified.
- Formatting: all Member 3 source is formatted. The whole-repository dry run
  reports 81 pre-existing unrelated files and they were intentionally not
  rewritten.
- Canonical evidence:
  `quality/phase-09-qa-gate-quality-report.json` and
  `tests/phase-09-qa-gate-test-report.json`.
- Handoff: the Phase 9 repair and evidence remain uncommitted for Hung's
  explicit review.

## Risks

- **HIGH:** The complete runtime stack may be unavailable locally even when
  deterministic Flutter tests pass. Mitigation: capture exact infrastructure
  blockers and do not claim end-to-end success without runtime evidence.
- **HIGH:** Central networking regressions can hide outside new Host tests.
  Mitigation: explicitly rerun Member 2 feature suites in addition to the full
  aggregate command.
- **MEDIUM:** One final uncommitted diff may be large and harder to review.
  Mitigation: provide per-phase diff stats/evidence and let Hung decide final
  branch/commit partitioning after completion.
- **LOW:** Quality artifact generation can become ceremonial. Mitigation: every
  artifact must reference actual commands, outputs, findings, fixes, and
  residuals; empty approval files are not accepted.
