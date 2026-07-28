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

- [ ] Every FR and required success criterion maps to implemented code plus
      test/contract evidence or an explicitly recorded residual block.
- [ ] All implemented Flutter focused tests pass.
- [ ] `flutter analyze` and the complete `flutter test` suite exit zero.
- [ ] Member 2 auth/exam-attempt/sync/media/report regressions pass after Host
      changes.
- [ ] Every Member-3 backend change packages successfully and has role/tenant/
      status/pagination contract evidence.
- [ ] Required runtime path is demonstrated or each blocked dependency is
      recorded without claiming end-to-end completion.
- [ ] New source complies with feature boundaries, state patterns, resource
      lifecycle, hardcoded-resource rules, and size limits.
- [ ] Test and quality artifacts exist for every implemented phase in the team
      plan format.
- [ ] Final working trees contain only approved changes and remain uncommitted
      until Hung's review.

## Quality and Testing State

- Quality gate: not run. Final report belongs at
  `quality/phase-09-qa-gate-quality-report.json` with a corresponding
  implementation-repository receipt.
- Testing: not run. Final consolidated evidence belongs at
  `tests/phase-09-qa-gate-test-report.json`.

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
