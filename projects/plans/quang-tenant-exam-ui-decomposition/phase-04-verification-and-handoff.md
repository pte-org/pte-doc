# Phase 04 — Verification and handoff

**Plan:** [plan.md](plan.md) · **Spec:** [spec.md](spec.md)
**Depends on:** Phases 01–03
**Outcome:** evidence that the decomposition is presentation-only, theme-safe, and
usable across the approved Host Exam workflows.

## Steps

1. Inspect the final diff and confirm there are no backend, database, API-client,
   authentication, scoring, or unrelated vendor-web changes.
2. Run the tenant-web lint, TypeScript no-emit check, production build, and
   `git diff --check` from the correct workspace.
3. Run a browser smoke pass against the local tenant app with an existing Host account:
   open Exam detail, switch through all six tabs, exercise existing actions that are safe
   for the seeded session, open/close create wizard, and verify return-state retention.
4. Check light/dark mode and Vietnamese default/English switch for tabs, step labels,
   empty/loading/error states, badges, tables, and dialogs.
5. Check desktop and narrow viewport behavior: tab overflow, sticky actions, tables,
   modal/dialog bounds, keyboard focus, and no global loading flash.
6. Record limitations honestly: static/build evidence is not a substitute for live API,
   database, authenticated browser, or production proof.

## Design Constraints

- Do not repair unrelated failures discovered during verification without a new scope
  decision.
- Keep screenshots/logs tied to this phase and do not overwrite existing baseline
  artifacts.
- A passing build does not imply that every tab mutation was live-verified.

## Quality and Testing State

- Preflight: Phases 01–03 are implemented and human-confirmed; the current pte-web
  diff remains presentation-only, and local Host seed data is available for the
  browser smoke pass. No backend, database, API-client, authentication, scoring, or
  vendor-web change is planned.
- Quality: not evaluated.
- Testing: not started.
- Planned final commands:
  - `pnpm --filter tenant-web lint`
  - `pnpm --filter tenant-web exec tsc --noEmit`
  - `pnpm --filter tenant-web build`
  - `git diff --check`
  - Playwright/manual browser smoke where the local server and seeded data are available.

## Acceptance criteria

- All planned checks are recorded with their exact scope and outcome.
- No false claim is made about live browser/database/production behavior.
- Any blocker is reported with the exact command, error, and affected phase.
- The user receives the changed-file summary and the next safe step.

## Verification run (2026-10-08)

- Tenant lint: passed with zero errors; one pre-existing unused `E` warning remains in
  `CreateTicketModal.tsx`.
- Tenant TypeScript no-emit: passed.
- `@pte/ui` typecheck: passed.
- Tenant production build: passed; the existing non-blocking absolute
  `turbopack.root` warning remains.
- `git diff --check`: passed; Git reported only existing LF/CRLF normalization warnings.
- Authenticated browser smoke using the local Host seed: passed for the current seven-tab
  surface, URL state/retention, Questions retention, keyboard navigation, Vietnamese and
  English labels, dark/light toggle, Create Exam wizard open/close, 390px overflow, and
  console/page-error checks.
- Evidence: [phase-04-verification-and-handoff-test-report.json](tests/phase-04-verification-and-handoff-test-report.json).

## Scope reconciliation

The original decomposition plan describes six tabs and the old header lifecycle rail,
while the follow-up `quang-tenant-exam-questions-tab` plan is now the authoritative
scope for seven tabs and Overview-owned lifecycle actions. The verification evidence
therefore covers the current follow-up implementation, not a literal six-tab rollback.
Formal completion of this historical Phase 04 remains pending plan reconciliation and
the quality gate for the superseded contract; no production code was changed during this
verification run.
