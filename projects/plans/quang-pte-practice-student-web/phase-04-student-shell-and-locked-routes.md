# Phase 4 — Student Shell, Four Routes and Locked State

## Objective

Build the first usable `pte-practice` shell for Home, Practice tests, Study-Pack and Progress, including authenticated loading, visible catalog preview and a simple non-actionable locked state.

## Story mapping

- P1: all four routes render for authenticated students; locked actions cannot start practice.
- P2: reference-inspired hierarchy, cards, navigation and responsive behavior.
- P3: future navigation is intentionally absent.

## Scope

- Read the relevant Next.js 16.4 guides from the installed package before implementation, as required by `pte-practice/AGENTS.md`.
- Add route/layout structure, auth/session adapter, typed API client and query/loading/error states.
- Add Home/catalog cards, Practice tests and Study-Pack locked/unlocked presentation, and read-only Progress shell.
- Refresh entitlement on initial load, app focus and practice start; fail closed if entitlement is unknown/error.
- Preserve keyboard/focus semantics for disabled/locked controls; no lock-reason modal/upgrade flow.

## Exact files/areas likely changed

- Existing `pte-practice/app/page.tsx`, `app/layout.tsx`, `app/globals.css` — replace scaffold with the approved shell entry/layout/styles.
- New route files under `pte-practice/app/` for `(auth)`, `(student)` or the approved Next route structure: Home, `practice-tests`, `study-pack`, `progress`.
- New `pte-practice/features/`, `components/`, `lib/` or equivalent feature folders for auth state, entitlement query, API client, catalog types and shared shell; exact structure is selected after reading Next guides.
- `pte-practice/package.json`, `package-lock.json` — only for approved client/query/test dependencies and scripts.
- `pte-doc/projects/plans/quang-pte-practice-student-web/` — screenshot/route matrix and visual review evidence.

## Dependencies

- Phase 02 auth/entitlement response.
- Phase 03 catalog DTO and safe practice-start contract.
- Approved decision on isolated local API adapter versus shared package.

## Implementation steps

1. Read and record relevant Next.js 16.4 App Router guidance.
2. Add API base/session handling, request error mapping and auth redirect/session bootstrap.
3. Build the shared shell/navigation and four route boundaries.
4. Render catalog entries from server metadata with explicit locked/unavailable/ready states.
5. Make locked controls non-actionable and ensure deep-link practice routes/API calls are rejected.
6. Build Progress empty/history loading surfaces without invented values.
7. Review screenshots at 390x844, 1024x768 and 1440x900; fix only approved scope issues.

## Acceptance criteria

- Authenticated student reaches all four routes; unauthenticated user cannot load protected data.
- No-entitlement student sees the normal information architecture and visibly locked practice actions.
- Locked action does not navigate into a session, and a direct protected request is rejected by server.
- Entitled student sees enabled entry only after the entitlement response allows it.
- Entitlement error never defaults to unlocked.
- Progress empty state contains no fabricated score/count.
- Visual/keyboard review passes at all required viewport sizes.

## Design Constraints

- This phase is UI shell only; it must not encode plan rules or correctness logic.
- Clone the supplied Pearson PTE Practice reference hierarchy, geometry, spacing, color treatment and icon semantics as closely as possible using project-owned SVG/CSS; do not copy third-party source code or private assets.
- Do not add lock explanation, upgrade, redeem or future navigation features.
- Any server-provided renderer key is mapped through a client allowlist.
- Preflight: `pte-practice` is an isolated Next.js 16.4 App Router app; use Server Components for route/layout composition and keep browser session, entitlement refresh and interactive lock controls inside small Client Components. Existing project conventions use direct Bearer JWT transport with refresh-token rotation; the practice app owns a typed local adapter rather than importing `pte-web` packages across repository boundaries.
- Checkpoint: Unit tests = yes; quality gate = yes, inherited from `/ck:cook --hard --tests --quality`.

## Quality and Testing State

- Quality: **APPROVED** — `quality/phase-04-student-shell-and-locked-routes-quality-report.json`; receipt issued after the reference-faithful SVG/icon and responsive shell review.
- Testing: **PASSED** — `tests/phase-04-student-shell-and-locked-routes-test-report.json`; lint, 4 Vitest contract tests, production build and visible Chromium Playwright flows passed.
- Evidence boundary: Playwright used local entitlement/catalog mocks. The screenshots validate the shell at 390x844, 1024x768 and 1440x900; they do not claim live Pearson or production API parity.
