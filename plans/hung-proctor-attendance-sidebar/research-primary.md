# Primary research: attendance ownership and transactional boundaries

Date: 2026-10-12. Source: local backend code inspection; no tests or product edits.

Validation update: user subsequently selected Proctor writes only from opensAt minus30minutes, optional initial absence reason, and UNMARKED reset with reason/history. The unrestricted SCHEDULED timing recommendation below is superseded by spec/plan. Research agent wrote this artifact before its final turn failed due workspace credits; root completed planning directly.

## Existing surfaces

- `pte-api/app/src/main/java/com/pte/session/domain/Enrollment.java`: unique session/student; tenant and license metadata; membership is independent of attempts.
- `.../session/internal/repository/EnrollmentRepository.java`: active enrollment page and class-member delete paths.
- `.../session/SessionService.java`: public roster, assigned-session, enrollment/assignment checks and session mutex facades.
- `.../session/internal/service/ProctorMonitoringQueryService.java`: active roster excludes deleted entries; stable pagination and max100.
- `.../proctoring/internal/service/MonitoringQueryService.java`: existing batch composition of roster, Identity display names, latest attempts and activity.
- `.../proctoring/internal/policy/ProctorAccessPolicy.java`: assigned PROCTOR and Host gates; owned ACTIVE monitoring-session gate is inappropriate for pre-opening attendance.
- `.../shared/domain/BaseEntity.java`: internal identity, external UUID, timestamps, deleted flag; attendance needs its own explicit version.
- `.../shared/web/PagedResult.java` and `PageMeta.java`: reuse current page envelope.

## Ownership and query composition

- Session owns attendance identity, current status, historical changes and mutation policy.
- Attendance identity is tenant/session/student, not attempt or STOMP proctor-session UUID.
- Do not import another module's `internal` repositories or policy classes.
- Keep activity enrichment in Proctoring, which already depends on Session, Attempt and Identity public facades.
- Expose session-owned attendance page/summary/receipt DTOs through a public facade; enrich only returned-page student IDs.
- Do not add Session→Proctoring or Session→Attempt dependencies: these modules already call Session.
- Existing Identity display-name facade is batch-only, not a search facade. Name/email search needs an explicit tenant-scoped public Identity query or approved projection; filtering after pagination is incorrect.
- Summary aggregates over current enrollment membership and LEFT JOIN current attendance; missing row means UNMARKED.
- Status/search filters affect page results, not whole-roster attendance counts.
- Use one coherent read snapshot for page, counts and capability; activity remains advisory and cannot determine presence.

## Confirmed lock matrix

| Existing path | Session mutex now | Planning action |
| --- | --- | --- |
| `lifecycle/SessionStateService.close` | `findOwnedWithLock` | Attendance takes same mutex before lifecycle checks. |
| `EnrollmentService.unassignProctor` | `findOwnedWithLock` | Recheck active assignment after lock. |
| `EnrollmentService.unenroll` | **No**, `findOwned` | Change to `findOwnedWithLock`; preserve delete behavior. |
| `SessionClassAssignmentService.unassign` | `requireScheduled` uses locked lookup | Preserve current-member deletion behavior. |
| `EnrollmentService.enrollStudent/bulkEnroll` | Locked lookup | Serialize attendance with re-enrollment too. |
| `EnrollmentService.assignProctor/updateProctorRole` | Unlocked lookup | Prefer same mutex for consistent assignment mutations. |
| `lifecycle/SessionRevocationService` | Subscription then ordered session locks | Attendance takes session only; never request subscription lock afterward. |

- Transaction order: tenant-scoped session mutex → current authorization → request receipt → mutable eligibility → attendance row.
- Session mutex serializes missing-row creation too; keep database unique constraints as final protection.
- Assignment revocation takes effect when its transaction commits; an attendance write already holding the mutex may finish first.
- Proctor new writes: SCHEDULED/OPEN, active membership, before closesAt. No opensAt lower bound for preflight.
- Host new corrections: SCHEDULED/OPEN/CLOSED with required reason; CANCELLED stays read-only.
- Never reuse `lockOpenWithinWindowForProctorOperation`: it excludes SCHEDULED and requires the exam window to have opened.
- Missing/null timing must fail closed with an explicit capability reason, not invent a grace window.

## Version, audit and retry

- Separate immutable command receipt from status-change history if no-op commands must remain exactly retryable without duplicate audit.
- Receipt key includes tenant/actor/request UUID; fingerprint includes session/student/status/expectedVersion/reason/note, with one canonical normalization used for store and retry.
- Reused key with changed actor, target or payload returns conflict, not success based on equal status alone.
- Exact stored retry may return its original receipt before lifecycle/version checks, but only after current read authority is revalidated.
- Revoked Proctor must not recover attendance data through retry; Host can recover their committed receipt after closure under current Host authority.
- Same-status new command is no-op: no status-history append or version increment, but immutable receipt records accepted result.
- Actual changes increment version once and append actor/role/server-time/old/new/reason/correlation atomically.
- Keep current/audit records independent of enrollment FK deletion; never cascade historical attendance from unenroll.
- Explicitly handle re-enrollment: store enrollment generation UUID, show UNMARKED for a new membership, retain prior history/version, and reject stale commands targeting old membership.
- Latest migration observed is V96; choose next free version at implementation time, never edit applied migrations.
- No changes to entitlement/start, heartbeat handlers, scoring cohort, grades, publication snapshot or session lifecycle.

## Validation limits

Static research only. Future checks should cover close/revocation/unenroll races, first-write conflict, exact retry after close, removed/re-added membership, all-roster counts and zero-attempt students. User test/quality preference must be honored at implementation handoff.
