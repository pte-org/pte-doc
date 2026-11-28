# Attack checklist (run after deploy, on demo accounts only)

Placeholders: `$API` = `https://pte-tenant.duckdns.org/api/v1`, `$T_*` = access tokens of the named demo accounts. Never paste real tokens or passwords into this file.

| # | Attack | Request | Expected |
|---|---|---|---|
| 1-1 | Activate an exam template that was never approved | `PATCH $API/exam-definitions/{id}/status` `{"action":"ACTIVATE"}` with `$T_MANAGER` on a DRAFT that skipped review | 409 `SCORE_TEMPLATE_NOT_APPROVED` |
| 1-3 | Admin approves own question | create as `$T_ADMIN`, submit, then `PATCH .../questions/{id}/status {"action":"APPROVE"}` with `$T_ADMIN` | 403, self-approval refused |
| 1-4 | PUBLISH an Exam-channel question without CEFR | `PATCH .../questions/{id}/status {"action":"PUBLISH"}` with `$T_MANAGER` | 400/409 CEFR required, question stays DRAFT |
| 2-1 | Staff with temporary password calls another API | log in as new proctor, `GET $API/users` | 403 `PASSWORD_CHANGE_REQUIRED`; change-password and logout still work |
| 2-2 | Add a student to an inactive class | `POST .../classes/{inactiveId}/members` with `$T_HOST` | 409 `CLASS_NOT_ACTIVE` |
| 3-1 | Save an answer after exam end + 120 s | `POST $API/attempts/{id}/answers/save` with `$T_STUDENT` after the window | 409 `ATTEMPT_DEADLINE_PASSED`; one `LATE_SYNC_REJECTED` incident; `POST .../submit` still succeeds |
| 3-8 | Publish while an objective answer is unscored | close the exam, skip "Score", `POST .../reports/publish` with `$T_HOST` | blocked; UI lists student, task type, reason `OBJECTIVE_NOT_SCORED` |
| 4-1 | Act on a practice session past its deadline | wait for the sweeper (or set `deadline_at` in the demo DB), then `POST .../practice/sessions/{id}/finish` | 410 `PRACTICE_SESSION_EXPIRED`; session still readable |
| 4-3 | Finish practice in a suspended organization | suspend the org, `POST .../practice/sessions/{id}/finish` with `$T_STUDENT` | 403, practice locked with reason `ORG_SUSPENDED` |

Demo switches (vendor-web → Platform settings → AI): turn a capability off, reproduce DS-01e / DS-03c / DS-04c, turn it back on, retry. Reset every switch and `order_pending_ttl_minutes` (1440) afterwards.
