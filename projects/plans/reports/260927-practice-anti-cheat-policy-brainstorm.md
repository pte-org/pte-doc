# Brainstorm: Practice Exam Anti-Cheat Policy Flag

**Date:** 2026-09-27
**Status:** Ready for planning

## Ideas Explored

- **Separate boolean (`antiCheatEnabled`)** — easy for the host UI, but duplicates the existing `ExamPolicy.lockdownMode` state and can drift from the actual runtime policy.
- **Reuse the existing lockdown policy as the source of truth** — present a checkbox in Practice, map unchecked to `NONE` and checked to `STANDARD`; keep `STRICT` reserved for Official exams. This avoids a new database column and keeps the app contract unchanged.
- **Expose the full lockdown level selector** — technically flexible, but unnecessarily exposes `STRICT` semantics to a Practice workflow and creates more policy decisions before the demo.
- **Violation response** — pause or force-submit would provide stronger enforcement, but would interrupt Practice testing. The agreed first version warns the student and records an audit event only.
- **Release fullscreen diagnosis** — the Windows native plugin is compiled and registered without a debug-only guard. Practice is not fullscreen because its current backend policy is `NONE`, not because release builds omit the feature.

## User's Direction

- Add a Practice-only host setting to enable anti-cheat restrictions.
- When enabled, Practice uses `STANDARD` lockdown:
  - fullscreen is mandatory;
  - existing shortcut and clipboard controls remain active;
  - violations show a warning and are stored in audit data;
  - the attempt is not paused or force-submitted yet.
- When disabled, Practice keeps `NONE` lockdown and remains a free-practice window.
- Official exams continue to use `STRICT` lockdown.
- Reuse the existing persisted `lockdown_mode` policy rather than adding a parallel boolean column.

## Open Questions

- The existing app reporter posts to `/api/proctor/violations`, while the current backend source exposes violation capture through a STOMP proctor-session mapping. The implementation plan must define the authenticated student-to-audit endpoint/transport before claiming that audit delivery works.
- The host wizard should set the policy atomically when creating/updating a draft; the existing policy patch endpoint can remain the edit-time compatibility path.
- Non-Windows desktop support remains deferred; the first acceptance target is the Windows release binary.

## Risks

- A Practice `STANDARD` policy improves deterrence but is not a complete anti-cheat boundary while the timer remains client-authoritative and violation handling is report-only.
- A stale release binary or backend returning `NONE`/`null` will still appear windowed, so release verification must inspect the attempt response and the native activation log.
- If the audit transport is not repaired, warnings may appear locally while the host/proctor audit remains empty.
