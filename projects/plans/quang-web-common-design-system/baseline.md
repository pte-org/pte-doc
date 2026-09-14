# Phase 00 baseline

Ngày đo: 2026-09-14 (Asia/Bangkok)

## Scope and state

- Repository: `pte-web`
- Branch: `work/design-refactor`
- `HEAD`: `79c693d2ac7566692a37102371510c923457b5d6`
- Original implementation SHA: `79c693d2ac7566692a37102371510c923457b5d6`
- Working tree deliberately remains in change state; no commit was created after
  the user's instruction. `packages/ui/src/components/.gitkeep` is a separate
  pre-existing deletion and is excluded from the design scope.
- Tracked changed files at measurement: 164; untracked files: 2
  (`packages/ui/src/styles/design-tokens.css`, `phase00-base-sha.txt`).
- Raw tracked diff against `HEAD`: 1,490 additions / 1,402 deletions.
- `git diff --ignore-all-space`: 1,266 additions / 1,178 deletions. The remaining
  delta includes the pre-existing implementation/refactor work; this report does
  not claim that all of it belongs to the style-only slice.

## Build and static checks

| Check | Result | Full evidence |
|---|---|---|
| `pnpm --filter vendor-web exec next build` | PASS, exit 0 | `baseline-build-vendor.log` |
| `pnpm --filter tenant-web exec next build` | PASS, exit 0 | `baseline-build-tenant.log` |
| `pnpm --filter vendor-web exec eslint .` | PASS, exit 0 | `baseline-lint-vendor.log` |
| `pnpm --filter tenant-web exec eslint .` | PASS, exit 0 | `baseline-lint-tenant.log` |
| `pnpm --filter @pte/ui run typecheck` | PASS, exit 0 | `baseline-typecheck-ui.log` |

The Next build route tables are preserved in full in the two build logs. Both
builds report successful TypeScript and static page generation. The only known
warning is Next's `turbopack.root should be absolute` warning under this local
workspace invocation; it does not change the exit status.

Unit tests were intentionally skipped by user choice (`skipped_by_user`).

## Screenshot comparison method

Chọn **A — semantic checklist**. Stitch exports are 2560px desktop while the
baseline captures are responsive app viewports, so this evidence does not claim
pixel-perfect equality. Phase 05 must compare the same checklist: page/background
surfaces, primary and secondary ink, radius, card/sidebar shadow, spacing,
typography, responsive shell behavior, navigation section grouping, and badge/
alert states.

The capture harness ran the two local dev servers at `localhost:3001` and
`localhost:3002`, with deterministic `pte.session` fixtures. `/api/iam/auth/me`
was fulfilled with the corresponding admin/host role; other API calls returned a
503 fixture so data-dependent routes could render their loading/error-safe UI
without requiring a live backend. These are UI shell baselines, not API/UAT
evidence. Server output is retained in `baseline-dev-vendor.out.log`,
`baseline-dev-vendor.err.log`, `baseline-dev-tenant.out.log`, and
`baseline-dev-tenant.err.log` when present.

## Screenshot manifest

All captures use `fullPage: true` at `1440x900`, `1024x768`, and `390x844`.

Vendor routes (7): `login`, `admin`, `admin-tenants`, `admin-tenant-detail`,
`admin-questions`, `admin-exams`, `admin-licenses`.

Tenant routes (10): `login`, `host-dashboard`, `host-students`, `host-programs`,
`host-program-detail`, `host-class-detail`, `host-exams`, `host-exam-detail`,
`host-audit-log`, `host-roster`.

Expected and captured count: **51 / 51**. Files are under
`baseline-shots/{vendor-web|tenant-web}/{route}/{viewport}.png`.

## Phase 00 completion notes

- `phase00-base-sha.txt` records the original SHA.
- Token choices and all literal token hex mappings are recorded in
  `token-decisions.md`.
- Snapshot/style/IA commit work was converted back to working-tree changes at
  the user's request; no commit is pending on the current branch.
- Quality gate remains required before treating this phase as complete.

## Quality gate

- Verdict: **APPROVED**
- Blocking findings: 0; advisory: 0; noted: 1
- Report: `D:\GitHub\pte-org\pte-web\plans\quang-web-common-design-system\quality\phase-00-baseline-and-diff-hygiene-quality-report.json`
- Receipt: `D:\GitHub\pte-org\pte-web\plans\quang-web-common-design-system\quality\phase-00-baseline-and-diff-hygiene-receipt.json`
- Receipt verification: `VALID`
