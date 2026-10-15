# Phase 04 — Regression verification and handoff

**Depends on:** Completed Phases 01–03 and all prior test/quality artifacts

**Status:** Verification passed; awaiting final human checkpoint
**Unit tests:** yes (hard-mode default; deterministic fallback and browser smoke required)
**Quality gate:** yes (hard-mode default)

## Goal

Prove that the maintainability refactor changed ownership only and preserved the approved Create Exam behavior before requesting human checkpoint approval.

## Files owned by this phase

Plan artifacts only:

- `tests/phase-04-verification-test-report.json`
- `quality/phase-04-verification-quality-report.json`
- `quality/phase-04-verification-receipt.json`
- this phase file and `plan.md` status/checkpoint fields

Temporary Playwright scripts and screenshots belong outside the repository (for example `D:/tmp`) and are not committed. Do not modify production source in this phase unless a separately approved defect fix is opened.

## Verification matrix

1. Run `corepack pnpm --filter @pte/ui typecheck`.
2. Run `corepack pnpm --filter tenant-web exec tsc --noEmit`.
3. Run `corepack pnpm --filter tenant-web lint`; distinguish the known pre-existing `CreateTicketModal` warning from new findings.
4. Run `corepack pnpm --filter tenant-web build`.
5. Run `git diff --check` and verify changed paths are limited to the approved tenant exam feature plus plan artifacts.
6. Run authenticated Playwright smoke on desktop and 390px: four-step navigation, back/next retention, audience add/remove and duplicate guard, review submit guard/network count, close/reopen reset, Vietnamese default, English switch, light/dark toggle, no browser errors, and no horizontal overflow.
7. Confirm no vendor-web, session-storage, or LocaleProvider file was edited by this refactor; preserve concurrent-agent edits byte-for-byte.
8. Compare the post-refactor behavior against `tests/phase-01-pre-refactor-baseline.json`:
   serialized payload, mutation/request count, query arguments/enablement, reset and
   mode-transition state, and visible VI/EN/theme labels. Re-check protected hashes.

## Acceptance checks

- All required static checks pass with no new warnings attributable to this refactor.
- Browser smoke shows no intermediate create-session request and final submit invokes the existing callback once for valid input.
- Payload shape, query call shape, locale/theme behavior, reset semantics, and responsive layout match the pre-refactor baseline.
- The baseline artifact and protected-file hashes match, or any difference is an
  explicitly reported blocker rather than silently accepted.
- `ck:quality --gate` returns APPROVED and a receipt is issued.
- Stop and request human inspection; do not declare the overall plan complete until the user confirms the checkpoint.

## Design Constraints

- This phase is verification and reporting, not an opportunity to redesign the workflow.
- Do not hide failures behind screenshots or static checks; report the exact validation boundary.
- Do not expose local credentials, tokens, or response secrets in reports.
- Do not auto-fix unrelated concurrent-agent changes.

## Quality and Testing State

- Quality: APPROVED; `quality/phase-04-verification-handoff-receipt.json` is valid.
- Testing: PASSED; static gates, baseline/hash audit, and authenticated browser smoke matrix passed.
- Required outputs: satisfied. Remaining gate is explicit human checkpoint before closing the overall plan.
