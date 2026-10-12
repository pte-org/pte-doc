# Phase 03: Proctor overview on assigned sessions

Status: completed [quality: skipped_by_user; decision: user_confirmed_skip; tests: not_started_user_declined]. Dependencies: 01–02. Covers P1 Proctor and P2; FR02–04, FR09–12.

## Design Constraints

Upgrade `/proctor/sessions`, keep route gate/sidebar/login precedence and existing flag state. Exactly3 cards. No opening monitoring session/subscription until user enters existing task route. Server access flag governs monitoring CTA; Clock/timezone response governs displayed times. All historical work remains reachable in ALL list.

## Files

In `pte-web/apps/tenant-web`: extend `features/proctor/components/AssignedSessionsView.tsx`; add `features/proctor/components/ProctorWorkspaceOverview.tsx`, `features/proctor/components/ProctorPrioritySessions.tsx`, and role-local locale text files `features/proctor/messages/vi.ts`, `messages/en.ts` with `features/proctor/hooks/useProctorWorkspaceText.ts`. Follow `features/examStaff/detail/hooks/useStaffDetailText.ts` and `@pte/ui useLocale` conventions. Existing `app/(dashboard)/proctor/sessions/page.tsx` continues mounting the same feature.

## Steps

- [x] Add cards “Có thể giám sát”, “Ca sắp tới”, “Ca hôm nay” with server counts. Explain overlap and scope “Các ca được phân công cho bạn”. Clicking maps to ACCESSIBLE/UPCOMING/TODAY and resets page0 via URL.
- [x] Add priority section with maximum5 backend rows; accessible CTA “Vào giám sát” links `/proctor/sessions/{publicId}`; upcoming displays start/time/status without falsely permitting monitoring. Existing room/audit secondary links remain safe; no automatic navigation.
- [x] “Xem lịch hôm nay” selects TODAY list filter with browser timezone, not a five-row preview claiming full schedule. Show total from paginated meta and render every page with stable ordering. Ca có opensAt trong ngày của browser xuất hiện; ca mở hôm qua bị loại dù còn đang diễn ra. Closed ca đã mở hôm nay vẫn nằm trong lịch.
- [x] Make main filters/page/sort URL-driven with enum validation and unknown value fallback. Browser back/forward restores selection/page; filter changes reset page; page bounded after list updates. Preserve ALL/history access.
- [x] Replace OPEN-only primary button condition with server `canMonitor`; a status OPEN outside its window is not labelled available now. Show explicit server block reason without predicting session mutation; backend room/open operation rechecks authorization after navigation.
- [x] Resolve browser IANA timezone before requests; do not fetch using SSR timezone. Render list times from its own validated response timezone and active locale; display timezone/asOf/refresh. Overview cards use overview context independently. Server alone computes day boundaries from Clock; client sends zone but never custom asOf. A manual refresh updates overview and active list independently; overview failure has its own retry without hiding list.
- [x] Integrate Phase02 timezone focus re-resolution and visible midnight boundary update. Ca opening yesterday must disappear from TODAY on the next local date without requiring a page reload; its ACCESSIBLE card membership still follows status/window. Preserve filter/page behavior when timezone changes and validate DST day boundaries in documented acceptance cases.
- [x] Loading skeletons don't masquerade as0; successful empty scope displays real zeros and clear no-assignment text. Independent error/loading for priority/cards vs list. Disabled Proctor workspace retains existing unavailable route.
- [x] Use shared PageHeader/Badge/Button/Pagination and semantic theme tokens. Localize touched surface vi/en; testable labels on card links/CTA and section headings. Layout targets320/768/1024, keyboard access and light/dark styling recorded if checked later.

## Acceptance evidence

Three cards only,≤5 priorities, TODAY complete through page navigation; status/window boundaries and browser-local day-opening semantics; timezone change separated in cache; refresh timestamp; errors independent; filters URL round-trip; no monitoring connection from landing page. No feature flag switch or new route.

## Quality and Testing State

Quality: not evaluated; prior preference skip. Testing: not started; prior preference skip tests/E2E. Tenant TypeScript planned. Responsive/browser/keyboard observations remain unverified until explicitly performed; no screenshots fabricated and no test suite introduced automatically.
