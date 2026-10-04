# Phase 06 code review

Date: 2026-10-04
Mode: hard
Verdict: APPROVED for the hard-mode checkpoint; Phase 06 is not marked complete until the user confirms the checkpoint.

## Review scope

- Shared `@pte/api-client` notification, announcement, and grading-cohort contracts.
- Shared `@pte/ui` notification bell, panel, history, focus, keyboard, loading, empty, and retry presentation.
- Tenant notification adapter/routes and closed-session grading-cohort confirmation UI.
- Vendor notification adapter/routes, platform-admin announcement CRUD, and portal shell/navigation integration.
- Existing auth/session/query-client usage, protected-cache cleanup, target allowlists, and safe error rendering.

## Review checks

- No direct `fetch`, token parsing, duplicate response envelope, or feature-owned error formatter was introduced.
- Query keys include authenticated user and tenant identity for unread, recent, history, announcement, and notification-detail data. Account changes remove the notification query root; unauthorized responses clear protected cache.
- Polling is limited to authenticated eligible roles, visible tabs, and the 30-second unread-count interval. Recent data is fetched on demand when the panel opens.
- The shared presentation does not own application routes or auth. Target navigation is allowlisted by target type, with readable notification-detail fallback and no arbitrary HTML or external redirect.
- Admin announcement mutations use existing versioned API contracts, confirmations, conflict feedback, safe errors, and immutable publication delivery counts.
- Host grading cohort actions are session-scoped, available after `CLOSED`, retain all submitted attempts, require reasons for outstanding attempts, and do not change attempt status or publish scores.
- Existing `Dropdown` was not duplicated; the new rich notification popover is justified by focus return, Escape, outside-click, and unread semantics not provided by that action-only primitive.

## Verification evidence

- API client: 14 test files, 357 tests passed.
- API client/UI/portal TypeScript checks passed.
- Vendor and tenant lint passed; vendor retained two pre-existing QuestionBank `<img>` warnings and zero errors.
- Vendor and tenant production builds passed, including the new announcement, notification, and host exam routes.
- `git diff --check` passed; only line-ending conversion warnings were emitted.

## Non-blocking limits

Live browser interaction, HTTP authorization, PostgreSQL execution, restart recovery, and performance measurement were not run. They remain Phase 07 acceptance evidence and are not represented as completed by this review.
