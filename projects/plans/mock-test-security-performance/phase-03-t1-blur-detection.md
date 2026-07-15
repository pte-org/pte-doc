# Phase 3 (Track 1): Tab/Blur/App-Background Detection

**Track:** 1 — Exam Integrity & Anti-Cheat
**Covers:** FR-02 · User story: P1 (blur/tab-switch detection)
**Depends on:** Track 4 Phase 1 (audit log) for persisting events; can build client-side detection in parallel and wire the endpoint once the audit log lands.

---

## Design Constraints

- Detective, not preventive — this cannot stop a student from switching devices/apps, only record it for post-hoc review. Don't over-invest in trying to "block" backgrounding (not reliably possible on mobile OSes).
- Must not trip on legitimate OS-level interruptions the student can't avoid (incoming call, OS permission dialog) — log the event but don't auto-penalize; leave adjudication to a human reviewer via the audit trail.
- Event payload: `attemptId`, `eventType` (`BLUR`/`APP_BACKGROUND`/`APP_FOREGROUND`), `timestamp`. Keep it minimal — no screen content capture (out of scope, and a privacy/legal concern).

## Files to Touch

- `aptis-api/src/main/java/com/aptis/modules/examdelivery/controller/ExamAttemptController.java` — new endpoint `POST /api/exams/{attemptId}/anti-cheat-events`.
- `aptis-api/src/main/java/com/aptis/modules/examdelivery/service/ExamAttemptService.java` — validate event belongs to an active attempt owned by the requester, delegate to `AuditLogService`.
- `aptis-app/lib/features/exam_delivery/presentation/` — new lightweight widget/mixin using `WidgetsBindingObserver.didChangeAppLifecycleState()` to detect backgrounding during an active attempt; POST event.
- `aptis-web/apps/tenant-web/` — (if/when web gets exam delivery) `document.addEventListener('visibilitychange')` + `window.onblur` wiring — build the client hook now even if the exam-delivery web UI doesn't exist yet, so it's ready to attach.

## Implementation Steps

1. Add `POST /api/exams/{attemptId}/anti-cheat-events` endpoint — validates attempt ownership + active status, writes `BLUR_EVENT` via `AuditLogService`.
2. Flutter: implement `WidgetsBindingObserver` on the exam-delivery screen; on `AppLifecycleState.paused`/`inactive`, fire the POST (fire-and-forget, don't block the UI).
3. Web: implement a reusable hook/utility for `visibilitychange` + `blur` detection, wired to the same endpoint contract (attach when exam-delivery UI exists on web).
4. Rate-limit/debounce client-side event emission (don't spam the endpoint on rapid focus flicker).
5. Tests: event correctly recorded with attempt/actor/timestamp; endpoint rejects events for attempts not owned by the requester or not active.

## Acceptance Criteria

- [ ] Blur/app-background events during an active attempt are recorded in the audit log, queryable by `attemptId`.
- [ ] Endpoint rejects events for attempts the requester doesn't own or that aren't active.
- [ ] Maps to spec user story: "system detects and logs tab-switch/app-minimize events... visible in an audit view."

## Quality and Testing State

- Quality: not evaluated
- Testing: not started
