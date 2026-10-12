# Phase 04 — Examiner queue, grading routes and exact-intent UI

Status: completed. Dependencies: Phases01–03 authoritative API contracts.
Stories: P1 assigned queue, AI-supported human decision and resilient media/network interactions.
Requirements: FR01–04,06–07,11–16.

## Inputs and output paths

All paths relative to `pte-web/`:

- Read `AGENTS.md`, coding standards and `apps/tenant-web/node_modules/next/dist/docs/01-app/01-getting-started/{03-layouts-and-pages,05-server-and-client-components}.md` before product edits.
- Shared `packages/api-client/src/{requests/scoring/examiner.ts,types/scoring/index.ts}` and existing export barrels. Extract workflow DTOs into `types/scoring/examiner.ts`, re-export public names to avoid extending the manual index beyond the file limit; do not redeclare types in views.
- Existing `apps/tenant-web/features/examiner/{ExaminerWorkView.tsx,api.ts,constants.ts}`.
- Split feature-local queue/detail views and small `components/` navigator, reference panel, decision panel, content renderers; focused draft/intent helper or hook in the existing feature root.
- Thin route `apps/tenant-web/app/(dashboard)/examiner/work/[sessionPublicId]/[attemptPublicId]/{page,loading,error}.tsx`; loading/error at session dynamic segment too.
- Existing queue page/loading/error and Examiner layout; preserve tenant chrome and login role precedence.
- Locale `packages/ui/src/i18n/LocaleProvider.tsx` with actual shared UI exports.

## Design Constraints

- No apps/tenant-web/src; PascalCase components, camelCase hooks, UPPER_SNAKE constants. File≤300/component≤150; no any.
- TanStack API hooks, semantic tokens/Tailwind, locale vi/en and actual shared ConfirmDialog/useToast/empty/error primitives.
- Identity+tenant in query keys; drafts memory-only keyed actor/session/attempt/answer, clear immediately on identity/logout changes.
- New detail route supports real deep links; authorization comes from backend, not cached capability alone.
- No Host review calls/components, fabricated AI feedback, bulk accept, autosave or automatic mutation replay.

## Implementation steps

1. Extend shared client with discriminated AI reference/decision and exact finalize request/response. Preserve read aliases; type legacy mutation rejection as actionable server error.
2. Scope queue/detail query keys by current actor+tenant+filters/targets. Detail disables focus refetch; mutation retry=false. Invalidate only matching targets after authoritative success.
3. Split old monolith into queue and detail. Queue server pagination/filter progress counts human decisions; restore query filter/page when returning. No page-derived KPI or student names.
4. Add nested route wrappers plus loading/error boundaries at each required dynamic segment; deep link refresh and wrong-role Forbidden states work through existing shell.
5. Render frozen prompt and all six returned content kinds without task whitelist; native audio no autoplay, safe existing image convention. Required content/media unavailable disables finalize, allows authorized media refresh and preserves draft.
6. Render AI AVAILABLE/PENDING/FAILED/UNAVAILABLE truthfully. Empty initial score; Use AI fills field only. Manual editing after accepted AI converts kind to MANUAL. Show delta only when both actual numbers valid.
7. Keep draft's viewed reference/version separate from latest fetched reference. AI change marks draft stale and requires explicit renewed review; never silently update intent's reviewed snapshot during refetch.
8. Confirm dialog binds exact target/score/kind/versions; create one requestPublicId once for that confirmed intent. Validate integer0..100, focus errors, prevent duplicate concurrent clicks.
9. Model states editing/submitting/unknown/stale/committed/unavailable. Timeout freezes exact intent; authoritative GET may prove same committed request, but PENDING cannot prove original request canceled. Permit only explicit same-fingerprint resend while unknown.
10. On conflict show actual server state and require re-review; do not replace draft or mark equal score as same request. Access loss locks controls, clears sensitive cache/draft according to identity/access policy and never manufactures success.
11. Saved decision read-only, show actual AI snapshot/kind/time; no auto-next. Human completed progress is distinct from publication. Pre-cohort/excluded capability displays real reason and blocks confirm.
12. Retain drafts across answer navigation/media refresh. Confirm app-managed leave, best-effort beforeunload only; no promise reload persistence. Guard late callbacks against changed actor/target.

## Planned verification

From pte-web: `pnpm --filter @pte/api-client typecheck`; `pnpm --filter tenant-web exec tsc --noEmit`; `pnpm --filter tenant-web lint`; `pnpm --filter tenant-web build`.
If selected: `pnpm --filter @pte/api-client test`; `pnpm --filter tenant-web test` with focused feature state-machine cases.

- 0/100 valid; blank/decimal/-1/101 never POST. AI-fill does not mutate until confirmed.
- Timeout→PENDING retains exact id/fingerprint/value/version; same-intent receipt reconciliation locks genuine result.
- AI change/media refresh leaves draft intact but marks stale snapshot; identity change clears it and stale callback cannot update new actor UI.
- All content kinds, expired media retry, deep-link reload, queue restoration, Forbidden/empty/loading/error states work.
- Keyboard dialog focus, native audio, vi/en and light/dark at320/768/1024 checked with available browser; report unavailable inspection honestly.

## Quality and Testing State

- Quality: not evaluated; user choice pending.
- Testing: not started; user choice pending; no --tdd selected.
- UI artifact/prototype is design only. Commands/manual scenarios above are unexecuted verification requirements.
