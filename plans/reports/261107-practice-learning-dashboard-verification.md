# Practice learning dashboard — 2026-11-07

Implemented the approved personal-learning dashboard on the Practice home route.

- Wider home canvas with a welcome panel, real catalog question/answer counts and a resume action.
- At most two recommendation cards, keeping existing session URLs and mock-test mode flow.
- Home now exposes 22 individual task types through the existing task rows and launch dialogs, with All/Speaking/Writing/Reading/Listening tabs. Study-Pack retains aggregate skill practice. Filtering occurs after canonical task ordering to avoid empty groups.
- Sidebar reuses the existing exam-date editor, organization context and real recent-session records.
- Compact device checks reuse the original dialogs and status persistence.
- English/Vietnamese copy and existing light/dark tokens. No fabricated scores, streaks or charts.
- Home stylesheet is scoped to the dashboard and its containing main element; Study-Pack retained its 840px main width in the browser check.
- Follow-up: outer dashboard frame matches Web `DashboardCard` (0.5px shell border, 12px radius, card background, 20px padding; 16px padding on mobile). Reused the existing mirrored shell/card color tokens. Build and 1440px/375px light/dark browser checks passed again after this CSS change.

Readiness: followed `docs/CODING_STANDARDS_WEB.md`, `pte-practice/AGENTS.md`, local Next.js guidance and the UI/UX and code-review skills. No API contract or backend source change.

Validation:

- `npx tsc --noEmit`: passed.
- Scoped ESLint for `features/home/HomeView.tsx`, `DashboardPanels.tsx`, `constants.ts` and the dashboard regression test: passed.
- `npm run test:unit`: latest run 79 files / 688 tests passed, including recommendation and task-type regression checks (locked/loading guards and single-group filtering).
- `npm run build`: passed, all 12 static pages generated.
- `git diff --check`: passed.
- Visible Playwright: authenticated home with live local API; 1440px light/dark, 375px light, Vietnamese; four skills present, no horizontal document overflow, no page errors.
- Existing resume link and skill button navigate to the practice-session route; exam date and reading-device dialogs open.
- Injected progress HTTP 503 produces the controlled history error state.
- Empty progress and mock-test responses produce the onboarding state. Injected LOCKED entitlement leaves zero enabled skill-start buttons and zero recommendation cards, while retaining 2 live history entries in the sidebar.
- With unfinished sessions, recommendation "View all" links to `/progress`, making sessions outside the first two cards reachable; new-mock-only recommendations link to `/practice-tests`.
- Independent code review: APPROVED after fixing the view-all destination and separating authenticated history reads from start-practice entitlement.

Screenshots: [desktop](assets/261107-practice-learning-dashboard/desktop.png), [mobile](assets/261107-practice-learning-dashboard/mobile.png), [dark](assets/261107-practice-learning-dashboard/dark.png), [Vietnamese](assets/261107-practice-learning-dashboard/vietnamese.png).

Boundary: verified navigation and dialog opening, not new answer submissions, device permission outcomes, AI scoring or saving a changed exam date. Existing unrelated worktree changes were preserved. No commit, push or deployment.

Latest task-type screenshots are under `assets/261107-practice-home-task-types/`. Independent re-review APPROVED; production build and scoped lint passed after the task-type changes. User subsequently requested no further Playwright runs and will test the UI personally; no additional browser runs were started after that request.
