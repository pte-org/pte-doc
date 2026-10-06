# Spec: Tenant and admin notification center

**Date:** 2026-10-03
**Status:** Planning baseline — product decisions confirmed; implementation not started

## Problem Statement

Tenant and admin users need personal inboxes for relevant platform/business events. Admins receive new organization applications and can publish global notices to hosts. Hosts receive commercial updates, platform notices, session-time reminders, and a session-level notice when all required exam marking is complete.

## Confirmed Product Direction

- PLATFORM_ADMIN creates global announcements for tenant HOST_ADMIN recipients.
- PLATFORM_ADMIN also receives notifications, specifically when a host/applicant creates an organization application.
- Hosts receive and read these announcements in their dashboard.
- Hosts receive reminders when an exam session is approaching its closing time.
- Exclude violation alerts and submitted-attempt notifications from this feature.
- Examiner marking completion is notified at session level: all required exam papers in that session are marked. Finishing one examiner's workload or one attempt does not generate this notice.
- Prefer broad system/session information over per-student or per-answer activity.
- User additions do not discard earlier suggestions automatically. Only explicitly rejected triggers are removed; commercial and application notices remain in the proposal. Their detailed priorities below remain draft decisions.

## User Stories

- **[P1]** As a PLATFORM_ADMIN, I want a notification when an organization application is submitted so I can open that application and review it.
  Accepted when: one committed submission creates one personal inbox item per eligible admin; applicant email acknowledgment remains independent.
- **[P1]** As a PLATFORM_ADMIN, I want to create a global maintenance or service announcement so every eligible tenant host receives consistent information.
  Accepted when: the admin can preview content and audience counts, then publish the reviewed version once; still-eligible snapshotted recipients get exactly one inbox item. Recipients deactivated before delivery are terminally suppressed and counted, not replaced.
- **[P1]** As a PLATFORM_ADMIN, I want to manage draft announcements and see published announcements so I can prepare accurate notices and track delivery.
  Accepted when: drafts can be created, edited, deleted, and published; published content is stable; the list/detail shows publication time, delivery progress, and aggregate read counts.
- **[P1]** As a HOST_ADMIN, I want to read global announcements so I know about planned maintenance and service updates.
  Accepted when: a bell shows a real unread count, a panel shows recent items, and the full notice opens in my portal with persistent personal read state.
- **[P1]** As a HOST_ADMIN, I want a reminder before a session's scheduled closing time so I can monitor the exam window.
  Accepted when: an eligible OPEN session approaching closesAt generates one reminder per host and schedule milestone, and the item links to that session.
- **[P1]** As a HOST_ADMIN, I want a notification when every required exam paper in a session has been marked so I can review the session's results.
  Accepted when: the authoritative session-wide grading condition changes from incomplete to complete; no notice is produced for one examiner or one paper finishing while other required work remains.
- **[P1 — retained proposal]** As a HOST_ADMIN, I want confirmed payment/redemption, expired-order, and revoked exam-access notifications so I can inspect the corresponding business outcome.
  Accepted when: notifications use authoritative committed transitions and the correct tenant-owned targets; payment plus entitlement activation is one combined notice.
- **[P1]** As an admin or host inbox recipient, I want independent read state, unread counts, and history so I can track notices addressed to me.
  Accepted when: state persists across login/refresh; one recipient reading a shared notice does not mark another recipient's copy read.
- **[P2]** As a PLATFORM_ADMIN, I want to schedule announcement publication and optionally target selected tenants.
  Accepted when: scheduled notices honor server time, cancellation, and recipient eligibility at publication; subset targeting remains explicit.
- **[P2 — retained proposal]** As a host, I want exam-subscription expiry and roster-capacity reminders. As assigned staff, I may receive assignment notices if that extension is selected.
  Accepted when: reminders use actual entitlement/roster rules and dedupe per milestone; staff assignment notices refer only to committed owned work. These are not notices that an examiner has finished marking.
- **[P3]** Browser/native push, student-app inbox, and advanced notification preferences are future scope.

## Functional Requirements

1. **FR-01 — Roles:** PLATFORM_ADMIN receives application notices and manages global announcements. HOST_ADMIN receives global announcements and its tenant's commercial/session notices. PLATFORM_AUTHOR does not gain admin recipients/publishing authority through the shared shell.
2. **FR-02 — Admin entrypoint:** Add an admin personal inbox opened through the bell, plus a separate announcement-management screen/action. The admin's unread count reflects notices addressed to that admin; publishing an announcement does not create a synthetic unread item for the sender.
3. **FR-03 — Announcement content:** Proposed limits: title 150 characters, plain-text body 5,000 characters. Include category SYSTEM_NOTICE or MAINTENANCE, importance INFO or IMPORTANT, and optional affected-service start/end timestamps. Validate that an entered end is later than start. The maintenance period is content metadata, separate from announcement publication time.
4. **FR-04 — Draft lifecycle:** Create, view, edit, and delete drafts. Publishing fixes the announcement content/version and snapshots the recipient audience. Repeated publish requests must return the existing publication without duplicate deliveries. Send a correction as a new announcement referencing the prior notice; published history is retained.
5. **FR-05 — Global audience:** First release targets all eligible active, nondeleted HOST_ADMIN users belonging to active tenants. Admin sees tenant/user counts before publishing. Final audience is resolved and snapshotted at publication, and its final counts are recorded; the preview count is advisory. New hosts do not receive historical notices automatically under this proposed default.
6. **FR-06 — Delivery tracking:** Show publishedAt, audience counts, pending/delivered/failed delivery counts, and aggregate read count. Inbox read state is independent for each recipient. Retrying failed/pending delivery does not create another item for recipients already delivered.
7. **FR-07 — Portal inboxes:** Replace both placeholder bells with recipient-owned recent-items panels showing 5 items and full notification pages with 20-item pages and All/Unread/category filters. Categories include System/Maintenance/Session/Application/Billing as appropriate to role. Badge shows nothing for zero, a number up to 99, and 99+ above 99.
8. **FR-08 — Read behavior:** Opening the panel changes no read state. Reading one notice marks only that recipient's item read. Explicit mark-all-read uses a server cutoff so newly arriving items remain unread. Read state survives refresh and login.
9. **FR-09 — Session reminder:** Use ExamSession.closesAt and server time. Confirmed first-release threshold: 15 minutes before close, once per host/session/schedule. Eligibility requires OPEN status, opensAt <= now, and now < closesAt. This is the session window, not each student's attempt timer.
10. **FR-10 — Reminder wording/target:** Include session name/code and absolute closing time; link to /host/exams/{sessionPublicId}. The detail page shows current session state. Do not change session status, force student submission, or close a session as a side effect of reminder delivery/read.
11. **FR-11 — Schedule changes:** Recheck the session immediately before reminder delivery. Cancel/suppress outdated pending reminders after cancellation, closure, or a changed closesAt. Deduplicate by recipient, tenant, session, closing-time/schedule identity, and threshold. A changed closing time can create one new valid reminder for the new schedule.
12. **FR-12 — Scheduler recovery:** Proposed scheduler tick <= 60 seconds. A restart while an OPEN session is still within the reminder window may deliver the missed reminder once; no late reminder is delivered after closesAt. Prevent concurrent scheduler instances from creating duplicate reminders.
13. **FR-13 — Persistence:** Persist announcements, publication audience/delivery intent, recipient inbox/read state, and reminder identity. An announcement body is shared content; per-user inbox/read records reference it. Creation and publish must have durable, idempotent recovery rather than rely solely on in-memory callbacks.
14. **FR-14 — Access:** Derive identity and tenant from authenticated context. Admins and hosts can list/count/read only their personal inbox; null platform tenant scope never means all platform inboxes. Hosts open only their tenant's targets. Announcement details require a recipient relationship or authorized admin-management access. Management and application-review targets require PLATFORM_ADMIN.
15. **FR-15 — Refresh:** Proposed unread-count refresh every 30 seconds in a visible authenticated tab and on focus. Fetch bodies on panel/history demand. Stop after logout/401; cache identity must change when switching accounts.
16. **FR-16 — Existing email boundary:** Keep the current email delivery audit distinct from this inbox. Existing email dispatch infrastructure is reusable if channels expand later. First release is in-app; it does not add emails for each session reminder.
17. **FR-17 — Content/constants:** Centralize type/status/error codes and UI labels. Announcement content uses plain text and contains no passwords, signed media URLs, answer content, or raw exception details.
18. **FR-18 — Application notices:** A committed TenantApplicationSubmittedEvent creates one item per eligible PLATFORM_ADMIN. Target /admin/applications/{applicationPublicId}. Submission can be from a public applicant without an existing host account. The applicant's existing acknowledgment email does not substitute for the admin inbox notification.
19. **FR-19 — Session-wide grading completion:** Determine the full session grading cohort and every paper's required marking coverage through scoring/attempt module contracts. Incomplete/unassigned required work, missing expected answers/scoring inputs, pending jobs, or failed required marking cannot count as complete. Checking only an examiner's assignments or existing score rows is insufficient. Zero-paper sessions do not emit completion notices.
20. **FR-20 — Completion transition/delivery:** Notify eligible tenant HOST_ADMIN users once when the authoritative full-session condition changes from incomplete to complete after CLOSED and cohort finalization. Suggested text: All required exam papers in session X have been marked. Target /host/exams/{sessionPublicId}. Include every submitted paper/retry; use stable cohort/version identity so concurrent final scores and replayed jobs do not create duplicate notices. P1 rejects reopening a finalized cohort. The proposed engineering mechanism for unfinished attempts is explicit, reasoned, audited cohort-only disposition, not force-submission or silent exclusion.
21. **FR-21 — Review/publication separation:** Marking-complete notification delivery/read does not choose score sources, approve scores, or publish results. Full marking coverage, host review/selection, and reporting publish readiness are separate predicates. Actual selected-source/provider and CLOSED-session publication rules remain authoritative for publication.
22. **FR-22 — Retained commercial notices:** Confirmed payment/redemption, committed order expiry, and exam-subscription revocation remain proposed host triggers. EXAM_PACKAGE activates time-limited exam access; STUDENT_CAPACITY adds roster slots. An unsuccessful webhook is not a FAILED order transition in current source. Emit only after the full authoritative business outcome and deduplicate per recipient/transition.

## Existing-Source Integration Dependencies

- Both portal DashboardChrome components need personal inbox controls; admin additionally needs an announcement-management entrypoint.
- NotificationLog and GET /api/v1/notifications represent HOST_ADMIN tenant email delivery history. Add announcement/inbox contracts without interpreting these records as personal unread items.
- ExamSession stores opensAt and closesAt as Instant and has OPEN/CLOSED/CANCELLED lifecycle states: pte-api/app/src/main/java/com/pte/session/domain/ExamSession.java:104.
- Add a scheduler using the session module's public query/API boundary; notification must not import session's internal repository.
- Extend the identity/tenancy module contract as needed to select eligible global host recipients and active tenant membership, including bulk resolution.
- TenantApplicationSubmittedEvent exists; its current notification listener sends the applicant an acknowledgment. Add eligible admin inbox recipients separately.
- ExaminerWorkQueueRepository derives per-assignment COMPLETED from score counts. That predicate does not establish completion of the entire session. Add a scoring-owned session aggregation/transition contract that checks expected required work, including missing/unassigned work.
- ReportPublishService already computes publish readiness. Do not reuse that label for grading completion or infer that notification delivery publishes a result.
- Retained commercial notices need verified billing transition hooks, authorized revocation context, and exact-order/inactive-subscription destinations. Recheck the existing subscription insertion transaction boundary before emitting combined payment/access success.
- No new inbox hooks for violations, submitted attempts, individual answers, or per-examiner completion are part of this feature.
- Published announcements need a fan-out/delivery model with a unique announcement/recipient key and durable retry; large audience publication must not perform external delivery inline.

## Non-Functional Requirements

These are proposed acceptance targets, not measured results.

- **Performance:** inbox/count API p95 <= 500 ms with 100,000 inbox records and 20 concurrent test clients; page size capped at 100.
- **Broadcast:** a publication to 1,000 eligible hosts creates a durable delivery job/intent within 1 second; all inbox deliveries complete within 60 seconds under healthy processing.
- **Reminder visibility:** scheduler tick <= 60 seconds; a visible host tab shows the reminder within a further 35 seconds after inbox delivery. These are operational reminders, not an exact countdown.
- **Security:** zero cross-user/cross-tenant inbox disclosure or read-state mutation; hosts and platform authors cannot publish announcements.
- **Recovery:** 10 concurrent publish/delivery/scheduler retries produce one inbox item per logical recipient/event; restart resumes pending broadcast delivery.
- **Accessibility:** bell/panel works by keyboard; Escape closes the panel and returns focus; unread state is conveyed beyond color.

## Success Criteria

- [ ] Admin can create, edit/delete a draft, preview audience, publish, and view delivery/read summaries.
- [ ] A new organization application creates an admin inbox item linked to that exact application.
- [ ] A maintenance notice reaches every eligible snapshotted host exactly once and remains readable after refresh.
- [ ] Two hosts receiving the same announcement have independent read states.
- [ ] Admin and host bell unread counts and histories reflect their own persisted recipient records.
- [ ] An OPEN session entering the proposed 15-minute window generates one host reminder and opens the correct session.
- [ ] No reminder is sent after cancellation, closure, or closesAt; changed schedules suppress obsolete deliveries.
- [ ] No new inbox notification is generated for violations, submitted attempts, individual answers, or an individual examiner completing work.
- [ ] With two examiners handling one session, completion of only examiner A's assigned papers produces no session-complete notification; completion of all required papers by A and B produces one logical session notice per host.
- [ ] Unassigned/missing required grading work prevents a false session-complete notice; the notice neither selects nor publishes scores.
- [ ] Retained commercial notices represent committed outcomes and open the correct tenant-owned target.
- [ ] Role/tenant isolation, account-switch isolation, concurrent retry, and restart recovery meet the targets above.

## Out of Scope

- In-app alerts for violations, student submissions, individual answers, individual AI-job results, or individual examiner marking completion.
- Student desktop/web notifications and native/browser push.
- Automatic session closure, student force-submit, score selection, approval, or report publication.
- Removal/refactoring of existing operational email listeners or email audit history.
- Scheduled publication, selected-tenant targeting, and advanced channel preferences in P1.
- Retained P2 proposals (subscription/capacity reminders and committed staff-assignment notices) are outside P1 until promoted; they are not rejected requirements.

## Assumptions

- One global announcement fans out to eligible HOST_ADMIN accounts; reading is per account, not a shared tenant acknowledgment.
- Admin receives its own notifications and also manages outgoing announcements; hosts receive notifications relevant to their tenant.
- Earlier proposal items remain candidates unless explicitly rejected. Only violation/submission notices are explicitly removed; per-examiner completion is replaced by full-session grading completion.
- Session reminder eligibility uses the exam window's closesAt, not an individual student's task/attempt countdown.
- The 15-minute reminder is confirmed. Polling, pagination, content limits and engineering mechanisms are plan decisions subject to implementation validation.

## Confirmed Planning Decisions (2026-10-03)

- Keep one 15-minute reminder; scheduled publication remains P2.
- Notify grading completion only after CLOSED and a frozen cohort. Include every SUBMITTED paper/retry; do not close automatically or force-submit.
- When manual workflow is configured, examiner-required lanes apply to the whole subjective cohort, not just existing assignments. Optional AI comparison does not block; explicitly required AI and AI-only lanes require valid REAL/nonstub results. Reuse existing mode or add a narrow explicit mode contract.

## Proposed Engineering Mechanisms

- HOST_ADMIN previews and finalizes the cohort. Outstanding CREATED/IN_PROGRESS attempts need explicit reasoned, audited cohort-only exclusions; attempt status remains unchanged. This is the plan's proposed resolution of the current lifecycle gap, not an additional user-confirmed exclusion policy.
- Publication audience is snapshotted: still-eligible recipients are delivered once; recipients deactivated before delivery are terminally suppressed, not replaced or backfilled on reactivation. Track pending + delivered + failed + suppressed = snapshot total.
- The three product validation questions have been answered. These technical mechanisms remain subject to implementation review and tests.
