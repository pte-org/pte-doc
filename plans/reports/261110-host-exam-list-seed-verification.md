# Host exam list: local seed correction

Date: 2026-11-10. Local database only; no deployment or application permission changes.

## Cause

Host login succeeded, but `GET /api/v1/sessions` returned HTTP 400 with code `LOCKDOWN_MODE_INVALID_FOR_EXAM_MODE`. Three UI-WEEK fixtures were copied as `OFFICIAL_EXAM` sessions with `STANDARD` lockdown. `SessionPolicyResolver` requires `STRICT` for this exam mode, and mapping one invalid session aborted the whole list response.

## Correction

- Updated the local role UI seed script to create `STRICT` sessions.
- Transactionally corrected only the three non-deleted UI-WEEK-1/2/3 fixtures belonging to organization `e2e`, with the invalid OFFICIAL_EXAM/STANDARD combination.
- Preserved registrations, attempts, incidents and user credentials.

## Verification

Logged in with the user-provided local Host account, without retaining the password in a script or report. Verified the sessions endpoint on both localhost:8091 and localhost:8080 returns HTTP 200 and 11 sessions, including all three UI-WEEK fixtures. No browser/Playwright verification was performed.

The common disclosure components already handle expanding/collapsing content. The tenant CreateExamWizard uses the shared Modal with size `full`; it has no separate maximize/minimize control.
