# Phase 03: Sidebar functions and assigned-session selectors

Status: pending; dependency01 read contracts. P1 card/sidebar parity; P2 navigation. FR01,12.

## Design Constraints

Reuse current overview/filter/detail routes. Role gates/Proctor flag/login precedence preserved. No invalid UUID placeholder; no automatic monitoring socket. One active nav item; common SidebarNav remains presentation-only.

## Files and steps

- [x] Read pte-web/AGENTS.md, docs/CODING_STANDARDS_WEB.md and installed Next16 routing guides. Extend apps/tenant-web/lib/navigation.tsx and features/auth/components/DashboardChrome.tsx; add focused resolveActiveNavItem utility in the auth feature if needed.
- [x] Proctor entries exactly spec: overview, accessible monitoring, attendance picker, audit picker, profile. Examiner overview plus PENDING/IN_PROGRESS/COMPLETED links. Cards use same route/filter definitions; avoid duplicated link strings and suppressing functions when counts0.
- [x] Query-aware match uses pathname + relevant status/scope only, ignores page/search. Defaults ALL selects overview; most-specific filter wins. Reuse the selected item for sidebar/breadcrumb. Preserve Host nested class/program overrides and account/workspace navigation.
- [x] Detail routes select attendance/audit parent; Examiner detail fromStatus identifies its filtered parent, valid fallback overview. Do not match string href containing '?' against pathname.startsWith. Testable examples documented for direct loads/back/forward/unknown filters.
- [x] Add thin routes app/(dashboard)/proctor/attendance/page.tsx, attendance/[sessionPublicId] wrappers, and audit-log/page.tsx picker; retain existing audit deep links. Feature-local AssignedSessionPicker component uses existing paginated assigned API, no Host listing. Attendance picker shows time eligibility separately from monitoring access; no OPEN-only picker filter hiding pre-open attendance.
- [x] Mobile drawer/search/breadcrumb show same role entries and selected state; locale catalogs contain all new labels. Disabled Proctor flag still shows unavailable/profile per existing policy, never activates automatically.

## Acceptance evidence

All role functions available in sidebar and valid card paths; empty assignment state visible; exactly one query-filter item active, detail parent stable; Host Classes override unchanged; no unauthorized routes/count leakage or extra WebSocket on selector pages.

## Quality and Testing State

Quality not evaluated; testing not started; prior skip. Tenant TypeScript/build planned. Responsive/keyboard/route behavior not claimed tested before actual checks.
