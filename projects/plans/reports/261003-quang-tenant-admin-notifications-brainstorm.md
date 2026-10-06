# Brainstorm: Tenant/admin inboxes, announcements, and session milestones

**Date:** 2026-10-03
**Status:** User-narrowed direction; detailed defaults proposed

## User's Direction

The user asked to review source and propose tenant/admin notifications, then refined the proposal through additions and explicit exclusions:

- Remove the proposed host violation notification.
- Remove notifications about submitted exam attempts.
- Add global announcements created by admin and received by hosts, such as upcoming maintenance.
- Prefer broad system/session information over notifications for individual subjects inside an exam; this does not automatically reject other earlier suggestions.
- Use a session approaching its closing time as a relevant automatic host reminder.
- Admin also receives notifications, specifically new organization applications created by a host/applicant.
- Replace examiner-level marking completion with a notice when the entire exam session's required papers have been marked.

The previous revision over-narrowed the proposal by removing application and commercial notices without an explicit rejection. That revision is superseded. User suggestions are additive; remove only explicitly rejected items. Retain earlier application/commercial suggestions and staff-assignment/reminder candidates at their draft priorities. The completion unit is the full exam session, not one examiner, attempt, or answer.

## Ideas Explored

1. **Global platform announcements — selected:** Admin creates maintenance/service notices for all eligible tenant hosts.
2. **Host session-closing reminder — selected direction:** A reminder tied to the scheduled exam window, rather than per-student answer/task timing.
3. **Personal inboxes — retained foundation:** Admin and host each receive an unread count, recent-items panel, history, and independent read state.
4. **Application/commercial notices — retained proposals:** New organization applications reach admin; confirmed payment/redemption, committed order expiry, and revoked exam access reach the appropriate tenant hosts.
5. **Full-session marking completion — selected direction:** Notify hosts only when all required papers in the entire session are marked; retain host review/publication as separate actions.
6. **Explicit exclusions:** Remove violations and student submissions; replace individual examiner completion rather than notifying after each examiner/attempt finishes.
7. **Scheduled/subset announcements — proposed P2:** Publish at a future time or target selected tenants after global immediate publication works.
8. **Other retained P2 candidates:** Subscription-expiry/capacity reminders and committed staff-assignment notices have not been rejected; their detailed scope remains proposed.

## Source Findings Relevant to the Current Scope

- Tenant and vendor DashboardChrome have decorative notification bells with unconditional unread dots: pte-web/apps/tenant-web/features/auth/components/DashboardChrome.tsx:139 and pte-web/apps/vendor-web/features/auth/components/DashboardChrome.tsx:122.
- The notification module already handles email jobs, retry/dead-letter outcomes, and delivery history. NotificationLog has delivery status, not personal inbox read state.
- GET /api/v1/notifications is HOST_ADMIN-only and lists tenant email history. It is not an inbox or admin announcement-management API.
- ExamSession has Instant opensAt and closesAt plus OPEN/CLOSED/CANCELLED states: pte-api/app/src/main/java/com/pte/session/domain/ExamSession.java:104.
- Host session detail already exists at /host/exams/{sessionPublicId}, so a reminder can target the correct tenant's exam detail.
- Existing recipient role lookup needs active/deleted eligibility and global-host audience support via public module contracts.
- Existing AFTER_COMMIT email listeners do not by themselves provide a durable announcement publication/fan-out/read model.

TenantApplicationSubmittedEvent already exists but currently sends the applicant email. Admin inbox delivery needs its own recipient policy. Per-examiner COMPLETED is a derived assignment query state; a full-session marking-completion event/condition does not exist in the inspected scoring flow. Existing billing/scoring source findings remain relevant to retained triggers, especially accurate committed outcomes and complete grading coverage.

## Proposed Product Experience

| Actor | Function | Example |
| --- | --- | --- |
| PLATFORM_ADMIN | Create a global announcement | Planned maintenance on 10 October, 22:00–23:00 |
| PLATFORM_ADMIN | Receive an application notice | Organization A submitted an application; open its review page |
| PLATFORM_ADMIN | Manage drafts and publish | Preview title/body and eligible tenant/host counts, then publish once |
| PLATFORM_ADMIN | View publication progress | Published at, recipient count, delivery progress, aggregate read count |
| HOST_ADMIN | Receive/read platform notices | Open maintenance detail from the bell |
| HOST_ADMIN | Receive session-close reminder | Session X closes at 18:00; open the session |
| HOST_ADMIN | Receive commercial outcomes | Purchased exam access activated, roster slots added, order expired, or exam access revoked |
| HOST_ADMIN | Receive full-session marking completion | All required papers in Session X have been marked; open session review |

Admin publishes shared content, and every recipient has independent inbox/read state. Published content remains stable; a correction is a new notice. Drafts may be edited/deleted. The first-release audience is all eligible active HOST_ADMIN users in active tenants.

Admin and host bells show real personal unread counts and 5 recent items. History uses 20-item pages and role-appropriate All/Unread/category filters. Admin inbox and outgoing-announcement management are separate views/actions. Opening the bell does not mark everything read; clicking a notice marks only that recipient's copy read.

## Session Reminder Proposal

- Initial default: one reminder 15 minutes before the session's closesAt. This threshold still needs product feedback.
- Use server time and the OPEN session's exam window, not the student's attempt/task countdown.
- Notify eligible hosts of that tenant once per session/recipient/closing-time/milestone.
- Recheck schedule/state before delivery; suppress after CLOSED, CANCELLED, or actual closesAt.
- A changed closesAt invalidates pending reminders for the old schedule and may create a new valid reminder.
- Show the absolute closing time so delayed viewing remains understandable; opening the session shows its current state.
- Reminder delivery/read does not close the session or force student submission.

Example: a session closes at 18:00; around 17:45 the host receives “Session X closes at 18:00.” All student submissions and violations continue to be handled through their own existing operational screens.

## Architecture Direction

Keep announcement/publication/inbox state in the notification module. Model one shared announcement and per-recipient delivery/read records. Publish with a durable audience snapshot and idempotent fan-out; enforce uniqueness per announcement and recipient.

Expose admin announcement-management plus recipient inbox contracts for admin and host. Resolve recipients through identity/tenancy public APIs. Query session schedules through a session-owned API/query boundary. Use billing/scoring public events/queries for retained outcomes. Keep the existing email audit separate.

Proposed scheduler interval is at most 60 seconds, with a uniqueness key and restart recovery. Initial inbox count refresh is every 30 seconds in visible authenticated tabs; scope frontend cache to the current identity.

## Full-Session Grading Completion

Example: Session X has 40 required exam papers split between examiners A and B. A completes 20 papers: no marking-complete notice. B completes the remaining 20 and all other required grading coverage is satisfied: each eligible host receives one logical Session X marking-complete notice.

The session-wide query must include all required papers/answers, including work that is still unassigned or lacks scoring inputs. It cannot check only one examiner's queue, only created assignments, or only existing score rows. A zero-paper session does not generate completion. Concurrent final scores and retries must deduplicate notification creation.

Marking completion remains distinct from choosing AI/Examiner sources, approving results, and publish readiness. The reminder does not select scores or publish results. Planning must define the stable grading cohort and how later eligible attempts/reopened grading are handled before claiming all session papers are complete.

## Open Questions

1. Is one 15-minute session reminder appropriate, or should the threshold/milestones change?
2. Should scheduled announcement publication ship in P1? Proposed default: P2; an admin may still immediately publish a notice describing future maintenance.
3. Should grading completion require a CLOSED session/finalized cohort, or support versioned cohorts while eligible papers can still arrive? Recommended draft: finalize the cohort before issuing an all-papers-complete notice.

## Risks

- Audience fan-out retries can duplicate inbox items without database-enforced recipient/event identity.
- Reading shared announcement content must not grant access to another user's read state or another tenant's session.
- Session rescheduling and scheduler downtime can produce obsolete reminders; revalidation and stable schedule identity are required.
- Assignment-only or score-row-only counting can falsely report full-session grading completion when required work is missing/unassigned.

## Verification Boundary

Source review confirmed the session schedule fields and existing header/email structure. This turn revises design documents only; no production code or live notification delivery has been tested. Numeric limits and intervals remain proposed acceptance targets.
