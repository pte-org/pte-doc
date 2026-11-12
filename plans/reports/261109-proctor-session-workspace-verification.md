# Proctor session workspace verification

Date: 2026-11-09. Scope: local tenant-web UI/navigation. No backend/schema
changes, production access, deployment, commit or push.

## Result

- Sidebar: Overview, Assigned sessions, Profile.
- Assigned-session table and overview actions open a session in Attendance.
- Session header keeps the selected session name, status and time window visible.
- Attendance, Monitoring, Incidents and Audit log tabs navigate within that session.
- Existing tool URLs and legacy session pickers remain usable. Nested incident
  detail pages keep the Incidents tab and session context.
- Sidebar remains on Assigned sessions while using a session tool; overview
  stays selected only for the overview route.
- Repeated navigation buttons inside tools were removed where tabs/breadcrumbs
  already provide their destination. Business actions and incident-detail back
  navigation remain available.

The application still has a session-based model. This change does not introduce
a separate physical room entity or a new room-selection step.

## Monitoring and error handling

The frame reads existing monitoring metadata without starting the live transport.
Monitoring availability follows the OPEN state and time window using the server's
snapshot timestamp. Command and assignment authorization remain on the backend.

Direct links to unavailable monitoring redirect to Attendance for the same
session. Monitoring is disabled in the tablist, while an enabled keyboard tab
remains reachable. The live tool mounts only on an available monitoring route.

Metadata polling failures with cached session data show a nonblocking warning
and preserve the active tool. An initial metadata error without session data
does not mount tool content. No raw API error is rendered by the new frame.

## Evidence

- Scoped ESLint: passed.
- TypeScript: passed, including production build type checking.
- Full tenant-web Vitest suite: **103 files, 1,028 tests passed**.
- `pnpm --filter tenant-web build`: passed. Existing warning about a relative
  `turbopack.root` remains; it did not block compilation or route generation.
- `git diff --check`: passed.
- Independent read-only code review: no remaining blockers after fixing stale
  metadata unmounting and unavailable-tab keyboard navigation.

Browser verification with the dedicated local PROCTOR fixture:

1. Open assigned-session list, select Open session, reach Attendance.
2. Switch Attendance → Incidents → Audit log → Attendance; session ID preserved.
3. These read-only tool visits create no proctor WebSocket connection.
4. Open Monitoring on the active session: live transport starts. Switching back
   returns to Attendance.
5. Upcoming session disables Monitoring; its direct monitoring URL opens no live
   connection and returns to Attendance.
6. Mobile viewport 375×812: document fits viewport; session tabs scroll locally.
7. Read of a different, unassigned tenant's monitoring session: HTTP 403.

Added focused tests cover route/session preservation, sidebar selection, exact
OPEN-window boundaries, cached-error content preservation, fatal metadata errors
and keyboard focus when monitoring is unavailable.

Screenshots:

- [Desktop workspace](assets/261109-proctor-session-workspace/desktop.png)
- [Mobile workspace](assets/261109-proctor-session-workspace/mobile.png)

Boundary: this verifies navigation, mounting and existing access checks. It does
not constitute a fresh end-to-end test of every attendance mutation, incident
transition, violation command, force-submit operation or exam-client heartbeat.
