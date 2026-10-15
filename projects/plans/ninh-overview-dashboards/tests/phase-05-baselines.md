# Phase 5 baselines (recorded 2026-10-13, before any api-client change)

Environment: Windows, PowerShell, pnpm workspace `D:\FPT-FALL2026\Capstore\pte-web`. No command hung. Pre-existing issues below are NOT attributed to Task #69 and were not fixed.

## Before (tree untouched, except where noted)

| Command | Exit | Result |
|---|---|---|
| `pnpm --filter tenant-web typecheck` | 1 | `ERR_PNPM_RECURSIVE_RUN_NO_SCRIPT`: the script did not exist yet (expected) |
| `pnpm --filter vendor-web typecheck` | 1 | same, no script |
| `pnpm --filter @pte/api-client typecheck` | 0 | clean |
| `pnpm --filter @pte/ui typecheck` | 0 | clean |
| `pnpm --filter tenant-web lint` | 0 | 0 errors, 0 warnings |
| `pnpm --filter vendor-web lint` | 0 | 0 errors, 2 warnings (`@next/next/no-img-element` in `features/questionbank/components/QuestionDetailView.tsx:63` and `QuestionEditorForm.tsx:304`) |
| `pnpm --filter @pte/api-client test` | 0 | 21 files, 435 tests passed |
| `pnpm --filter tenant-web test` | 0 | 2 files, 37 tests passed |

After adding `"typecheck": "tsc --noEmit"` to both apps (still before any other change):

| Command | Exit | Result |
|---|---|---|
| `pnpm --filter tenant-web typecheck` | 0 | 0 errors (about 27 s) |
| `pnpm --filter vendor-web typecheck` | 2 | 28 errors, ALL in the generated file `apps/vendor-web/.next/dev/types/routes.d.ts` (TS1128/TS1005 at lines 61-81) |

### Pre-existing vendor-web typecheck failure (environment, not source)

`apps/vendor-web/.next/dev/types/routes.d.ts` is a corrupted generated Next.js artifact (last written 2026-10-10 08:16; the route-map type is cut off at line 60 and a second fragment follows, which looks like two concurrent dev-server writes). It is pulled into the program by `next-env.d.ts` (`import "./.next/dev/types/routes.d.ts"`). Both `.next/` and `next-env.d.ts` are gitignored, so a clean checkout/CI does not have this file.

Evidence that the source itself is clean: running `tsc` with the same tsconfig but excluding `.next` and `next-env.d.ts` (a throwaway tsconfig kept outside the repo) exits 0 with 0 errors, before and after the Phase 5 changes.

Remedy for the local machine (not done here, it is an unrelated generated file): delete `apps/vendor-web/.next/dev/types/routes.d.ts` or restart `next dev`/run `next typegen` in vendor-web so Next regenerates it; then `pnpm --filter vendor-web typecheck` should be green.

## After Phase 5 steps 1-6

| Command | Exit | Result | vs baseline |
|---|---|---|---|
| `pnpm --filter @pte/api-client test` | 0 | 22 files, 455 tests passed (+16 new dashboard request tests, +4 auto-discovered `DASHBOARD_ENDPOINTS` checks in `endpoints.test.ts`) | no regression |
| `pnpm --filter @pte/api-client typecheck` | 0 | clean | same |
| `pnpm --filter @pte/ui typecheck` | 0 | clean | same |
| `pnpm --filter tenant-web typecheck` | 0 | 0 errors | same |
| `pnpm --filter vendor-web typecheck` | 2 | 28 errors, all in the same corrupted `.next/dev/types/routes.d.ts`; 0 errors elsewhere (0 excluding that file) | same as baseline, no NEW errors |
| `pnpm --filter tenant-web lint` | 0 | 0 errors, 0 warnings | same |
| `pnpm --filter vendor-web lint` | 0 | 0 errors, the same 2 warnings | same |
| `pnpm --filter tenant-web test` | 0 | 2 files, 37 tests passed | same |

Notes: `@pte/api-client` has no lint script, so the new files are only covered by typecheck and by review against `docs/CODING_STANDARDS_WEB.md`.
