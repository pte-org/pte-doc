# Alternative research: sidebar and attendance

Date: 2026-10-12. Static source inspection only; no source edits, tests or runtime checks.

Validation update: opensAt minus30minutes is the Proctor lower boundary; initial absence note optional; correcting/resetting status requires reason/history. Final two-table design uses immutable command records as receipts and change log, with no-op commands hidden from status-change history. Research was written before the agent final turn failed due workspace credits; final plan review was direct by root.

## Verdict

Prefer dedicated session-owned current attendance + immutable history, with a roster-derived read model.
Keep existing overview routes and add real sidebar entry points; no second dashboard or new scoring workflow.

## Persistence alternatives

| Option | Benefit | Cost / rejection reason |
| --- | --- | --- |
| Attendance columns on Enrollment | Few joins; familiar roster identity | Physical unenroll removes current data; audit still needs independent storage, versioning and receipts. Cannot meet preservation cleanly with fewer concepts. |
| Attendance on ExamAttempt | Easy to join current activity | Omits students without attempts; multiple attempts duplicate physical attendance. Reject. |
| Dedicated current record + immutable changes | Stable session/student identity, CAS version, independent enrollment deletion | Two focused tables and transactional write coordinator; recommended. |
| Append-only events with no current row | Complete history | Latest-state filtering, paging and CAS require extra query machinery. Unnecessary for this MVP. |

Current identity must be tenant + session + student, not enrollment public ID or attempt ID.
Do not cascade attendance/history deletion from Enrollment; preserve the existing unenroll behavior.
When a student is re-enrolled, the same session/student identity retains prior history; plan must define visible current state explicitly.
UNMARKED may be synthetic for absent current records; resets require retaining a versioned row to avoid ABA/stale-write acceptance.
Histories should retain actor ID/role and server time, old/new state, reason/note, request ID and a canonical intent fingerprint.
Unique request ID and exact payload matching protect timeout reconciliation; equal status alone is insufficient proof of exact retry.
Same-status no-op needs a defined receipt/version outcome even when it creates no status-change history.

## Existing read-model evidence

- `pte-api/app/src/main/java/com/pte/session/domain/Enrollment.java`: unique session/student membership; no attendance fields.
- `pte-api/app/src/main/java/com/pte/session/dto/response/MonitoringEnrollmentView.java`: safe student/enrollment IDs.
- `pte-api/app/src/main/java/com/pte/proctoring/internal/service/MonitoringQueryService.java`: roster page + Identity display names/email + latest Attempt/activity fetched in batches.
- Use these public-facade patterns, not Proctor's internal repository/service from Session.
- Attendance must remain usable SCHEDULED without an ACTIVE STOMP session; monitoring UI eligibility is not attendance authorization.
- Build current-enrollment LEFT JOIN attendance for page/filter and whole-roster aggregate; summary excludes removed enrollment.
- Search safe identity fields server-side before pagination; do not fetch one identity/activity call per student or search only the visible page.
- Return authority capabilities/blocking reasons and snapshot server time; a denied/failed query is not an empty successful count.

## Lock and authorization differences requiring a plan constraint

`EnrollmentService.unassignProctor` already uses `SessionLifecycleService.findOwnedWithLock`.
`EnrollmentService.unenroll` currently uses `findOwned` without session mutex, so attendance taking only a session lock cannot prevent concurrent removal.
Coordinate attendance, close/cancel, assignment revocation and enrollment removal through the same session mutex; change unenroll locking, without changing who may unenroll.
Recheck active assignment/enrollment after locking and lock session before current attendance; the session mutex also serializes first inserts when no row exists.
Version comparison remains necessary even with serialization, so two stale clients do not overwrite silently.
Derive tenant/actor from CurrentUser and distinguish HOST_ADMIN correction from assigned PROCTOR write explicitly, including multi-role users.
If assignment revoked or session closes during UI use, refetch capability and stop writes; 403/409 feedback must not show a false saved result.

## Navigation evidence and minimal change

- `pte-web/apps/tenant-web/lib/navigation.tsx`: Examiner has one queue item; Proctor enabled sessions item plus profile.
- `pte-web/apps/tenant-web/features/auth/components/DashboardChrome.tsx`: local `isActive` only matches pathname prefixes; it is used by sidebar AND breadcrumb selection.
- Query links such as `/examiner/work?status=PENDING` currently never activate because pathname does not include query.
- Add one query-aware active-item resolver shared by sidebar and breadcrumb, with explicit precedence, query defaults and detail ownership; preserve existing Host class/program overrides.
- Overview default ALL and filtered ACCESSIBLE/status entries must have exactly one winner; incidental page/search params should not suppress activity.
- `pte-web/packages/ui/src/components/SidebarNav.tsx` remains presentation-only; do not move Next route/query logic into this package.
- `pte-web/apps/tenant-web/features/proctor/components/AssignedSessionsView.tsx` already reads URL scope/page and `features/proctor/api.ts` exposes assigned paged query hooks.
- Add thin picker routes `/proctor/attendance` and `/proctor/audit-log`, then existing/new detail routes; never use placeholder UUID or link directly to a nonexistent global log.
- Keep empty-assignment functions visible with authorized empty states; preserve `NEXT_PUBLIC_PROCTOR_UI_ENABLED`, layout gate, login precedence and workspace switcher.
- Host placement: `features/exams/components/SessionDetailView.tsx` delegates to `ExamDetailTabs.tsx`; extend tab union, allowlist, items and panel with Attendance.
- Host route already exists at `app/(dashboard)/host/exams/[publicId]/page.tsx`; attendance can use `?tab=attendance` with existing popstate behavior.

## UI and explicit exclusions

Follow `pte-web/AGENTS.md` and `docs/CODING_STANDARDS_WEB.md`: thin routes, feature hooks/locale catalogs, common @pte/ui tables/dialogs/status components.
Keep row saving/error/conflict/unknown-outcome state scoped to session/student; navigation must not erase unresolved correlation and permit a new intent.
Before a confirmed write, recheck current capability/version; backend independently revalidates after locking.
No optimistic success, automatic offline replay, bulk absence, biometric/QR, heartbeat-derived attendance or changes to exam-start/scoring/publication.
