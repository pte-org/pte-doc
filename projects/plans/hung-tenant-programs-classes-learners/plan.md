# Plan: Tenant Programs / Classes / Learners — Destructive UX Guards + Form/Import Hygiene

**Slug**: `tenant-programs-classes-learners`
**Spec**: `plans/hung/tenant-programs-classes-learners/spec.md`
**Survey**: `plans/hung/tenant-programs-classes-learners/unhappy-cases-survey.md`
**Code branch**: `pte-web` → `hung/feat/classes-entry`
**Plan branch**: `pte-doc` → `hung/tenant-programs-classes-learners`
**Date**: 2026-10-02
**Test mode**: `--tdd` (per user)

---

## Goal (from spec)

Fix the destructive-UX and form-hygiene bugs in `apps/tenant-web` flows:
**Programs (P2/P4/P5/P7)**, **Classes (C2/C7/C8/C9/C10/C13/C14/C17/C19/C31)**, and
**UI dead state (X8)** — plus minor import hygiene (C28).

## Out of scope (deferred)

C25, C32, L4, all 7 "?" items needing backend answers (Q1–Q5 in spec §7),
C27 (bulk import dedup behavior), C28 routing.

## Phases (3)

| # | File | Surface | ACs | P1/P2/P3 | Status |
|---|------|---------|-----|----------|--------|
| 1 | `phase-01-silent-actions.md` | ProgramDetailView, ClassRowActions, ClassRosterTable, TransferStudentModal, MergeClassesModal | AC1, AC2, AC3, AC4, AC5, AC6 | P1 | ✅ completed 2026-10-04 (quality skipped_by_user, tests not started) |
| 2 | `phase-02-validators.md` | validateCreateProgram, CreateProgramModal, validateClassName, validateAddStudentInput, ImportOrAssignModal, api-client error map, TypedConfirmInput primitive | AC7, AC8, AC9, AC11 | P1, P2 | ✅ completed 2026-10-04 (quality skipped_by_user, tests not started) |
| 3 | `phase-03-import-and-ui.md` | ImportOrAssignModal help text, ClassesListView column | AC10, AC12 | P2, P3 | ✅ completed 2026-10-04 (quality skipped_by_user, tests not started) |

**Completed 2026-10-04.** All three phases implemented in `pte-web` @ `hung/feat/classes-entry`.
Build Gate passed for each (`pnpm --filter tenant-web build` + scoped eslint clean).
Testing was **declined by the user** for this run — no unit tests were written or executed,
and the manual smoke checks in each phase's "Verify" section are still outstanding.

> **Verified 2026-10-04 (later pass).** AC1–AC12 were exercised with the MCP browser,
> a Node harness for the pure validators, direct Postgres reads for ground truth, and
> Playwright for the responsive check and the transfer flow. Results, the four bugs
> found, and the fixes applied are in
> [`test-report-and-fixes.md`](./test-report-and-fixes.md).
> Headline: **all twelve AC pass** (one failed first and was fixed), with the four bugs
> documented and remediated. Gates clean: `tsc --noEmit`, scoped eslint, full build.
> Still open: backend questions Q3–Q5, and there is no automated regression coverage.

> **Note**: `TypedConfirmInput` primitive is created in `packages/ui/` as a
> one-time prerequisite in Phase 2 (rationale: only two consumers, both in
> Phase 1's modals). Phase 1's modal work will land AFTER the primitive is
> merged — or, if sequencing forces it, will inline a local copy first and
> migrate once the primitive lands.

## Researcher Verdicts (already in)

- **Researcher A** (Confirm dialog): inline `ConfirmDialog` per location, no
  wrapper. Counts: source from `useProgramDashboard.classes[].studentCount`
  passed as prop to `ClassRowActions`. Multiple `useState` per action; extract
  sub-components when file-size threshold hit.
- **Researcher B** (Validators + typed-confirm): extract `validateClassName`
  in `features/classes/utils/`, loosen `validateCreateProgram` (P2/P4), add
  `useEffect` for P5 (no auto-clear, show error only), mirror
  `validateCreateLecturer` for `validateAddStudentInput`, add
  `DUPLICATE_CLASS_NAME` to `USER_FACING_ERROR_MESSAGES`, add
  `TypedConfirmInput` to `packages/ui/`.

## Quality & Testing State (per phase)

Each phase file has a `## Quality and Testing State` block recording the
user's per-phase check choices — `ck:cook` will fill it in as the work runs.

## Definition of Done

- All AC1–AC12 in spec §5 pass manually + automated (where applicable).
- `pnpm lint`, `pnpm typecheck`, `pnpm build` pass in `apps/tenant-web`.
- `pnpm --filter @pte/ui test` passes (TypedConfirmInput unit tests).
- `pnpm --filter tenant-web test` passes (validator unit tests, hook tests).
- Survey file (`unhappy-cases-survey.md`) updated to mark each fixed item
  with `**[fixed YYYY-MM-DD]**` in the Notes column.
- One PR per phase; spec + plan files committed on `pte-doc` branch.
- No regressions on existing happy-path Program/Class/Learner flows.

## Risks (from spec §8 + research)

1. ConfirmDialog on every status change slows power-user cleanup →
   mitigated by keeping non-destructive transitions friction-free.
2. Typed-name adds 2 clicks in common pattern → only when target is
   non-ACTIVE.
3. Friendly 409 mapping depends on backend Q1 → fallback to generic
   message.
4. P5 re-validation: prefer inline error over auto-clear to avoid
   surprising the user.

## Open Questions

All of Q1–Q3 are now answered empirically (see the test report); the rest are
out of scope. **Q3 is a known backend gap, deferred by decision.**

- **Q1** — backend rejects duplicate Class names within a Program with
  `CLASS_NAME_ALREADY_USED` / HTTP 409. Frontend already mapped it.
- **Q2** — backend accepts `startDate == endDate` and both-null, and persists both.
- **Q3** — `ClassService.transfer` and `ClassService.mergeClasses` check
  ownership/tenant only; neither inspects the target Class's `status`. The backend
  therefore **accepts** a transfer/merge into a `SUSPENDED`/`INACTIVE`/`ARCHIVED`
  Class. The frontend warn + type-the-name guard matches the spec's intent, but the
  real guard belongs server-side. Deferred — backend work is out of scope here.
- Q4, Q5 — not needed for this plan.

## Handoff

Implementation and verification are complete. All twelve acceptance criteria pass and
the gates are clean. See
[`test-report-and-fixes.md`](./test-report-and-fixes.md) for the AC-by-AC evidence,
the four bugs found and fixed, the `ImportOrAssignModal` split, and what remains.