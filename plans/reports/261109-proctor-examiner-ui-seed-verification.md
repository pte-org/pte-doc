# Local proctor/examiner UI seed

Verified 2026-11-09, Asia/Bangkok. Scope: additive fixtures in the existing local
Docker PTE database. No reset, production access, commit, push, or deployment.

## Access

- Tenant portal: <http://localhost:3000/login>.
- Organization: E2E Test Organization (`e2e`).
- PROCTOR: `proctor.ui@test.local`; open `/proctor` or `/proctor/sessions`.
- EXAMINER: `examiner.ui@test.local`; open `/examiner/work`.
- Password and student usernames are in the workstation file
  `C:\Users\ADMIN\AppData\Local\PTE\local-role-ui-credentials.json`.
  Passwords/tokens are omitted from this report and Git.
- Both role accounts are ACTIVE, have exactly their intended role, and do not
  require a first-login password change. Thirteen dedicated student accounts
  share the generated local fixture password.

## Fixtures

| Session | State | Data |
|---|---|---|
| UI-WEEK-1 — Live monitoring and attendance | OPEN until 2026-11-16 11:42 ICT | Six enrolled students, three IN_PROGRESS attempts, varied attendance/identity states, reported incidents and fullscreen security evidence |
| UI-WEEK-2 — Upcoming exam | SCHEDULED, 2026-11-10 11:42 through 2026-11-16 11:42 ICT | Three enrolled students |
| UI-WEEK-3 — Examiner marking workspace | CLOSED, manual grading cohort FROZEN | Four submitted attempts; one PENDING, two IN_PROGRESS, one COMPLETED; ten eligible answers per attempt |

Examiner task types: Read Aloud, Repeat Sentence, Describe Image, Re-tell Lecture,
Answer Short Question, Respond to a Situation, Summarize Group Discussion,
Write Essay, Summarize Written Text, Summarize Spoken Text.

One in-progress attempt has a saved draft. Another has a reported grading issue.
The completed attempt was saved and finalized through the actual examiner API,
including per-trait scoring. Its history and report data are available.
The closed marking session intentionally has no future exam opening; grading
work remains accessible independently of the live proctor session's seven-day window.

The full existing exam snapshot is reused within the same tenant. Dedicated
subscriptions avoid schedule-overlap collisions with existing subscriptions.
Existing sessions/accounts are preserved. Re-running the base seed keeps
fixture session dates and user edits; it does not renew their seven-day window.

## UI test checklist

PROCTOR:

- Dashboard, assigned-session list, upcoming/current/past filters, session detail.
- Monitoring roster, students without attempts, attempt activity/history.
- Attendance and identity verification, optimistic-version changes, action history.
- Incident list/detail, creation, NEW to IN_PROGRESS transition, incident history.
- Security audit: synthetic student fullscreen-exit evidence.
- Profile, session navigation and logout.

EXAMINER:

- Dashboard, queue status filters, search, session filter.
- Start the pending attempt; inspect text, audio, prompts, rubric and guidelines.
- Save/edit drafts on the in-progress attempt, report/view issues and history.
- Finalize an attempt after every eligible answer has a valid draft.
- Inspect the completed attempt in read-only mode and its report.
- The completed example provides a reference for valid per-trait values.

Audio responses reuse an existing playable question audio asset as a clearly
synthetic response example. Text responses and scores are synthetic. Local
`ui-fixture` AI references use storage category `REAL` only because machine-trait
editing requires that category; **no AI/Azure assessment was performed**.
Do not interpret these rows as assessment evidence or copy them to production.
The untouched pending sample's reference traits/score are copied from the
same-item synthetic result calculated by the backend during example marking.

## Verification

- Both accounts logged in; `/auth/me` confirmed tenant and exact roles.
- Proctor assignments/overview, monitoring, attendance, incidents, violations
  and security-audit APIs returned HTTP 200.
- All four examiner attempt details returned ten answers each; guidelines,
  issues and history APIs returned HTTP 200.
- Examiner queue/overview/reports returned HTTP 200 with counts
  PENDING=1, IN_PROGRESS=2, COMPLETED=1.
- Actual start, draft save, finalization, grading issue creation, incident
  creation/status update, attendance update and student security-evidence
  commands succeeded.
- Cross-role access to examiner work and proctor assignments returned HTTP 403.
- The sample response audio returned HTTP 200, `audio/mpeg`.
- HTTP GET returned 200 for `/login`, `/proctor`, `/proctor/sessions`,
  `/proctor/attendance`, `/proctor/incidents`, `/proctor/audit-log`,
  `/proctor/profile`, `/examiner`, `/examiner/work`, `/examiner/reports`.
- Repeated base/workflow seed execution preserved the three sessions and
  four assignments; Python syntax validation and `git diff --check` passed.
- Independent read-only code review found no remaining blockers.

Boundary: API/data verification and route rendering only; no browser interaction,
visual review, live STOMP/client heartbeat or every-button UI test. Seeded live
attempts can appear disconnected without a real exam client sending heartbeats.
Score explanation and Confirm AI actions were not exercised separately.
No Java/TypeScript application source changed, so Maven/frontend suites were not run.

## Reuse

Prerequisites: local Docker PTE stack running, Python with `bcrypt`, and the
existing full `test` exam in tenant `e2e`. Scripts require a local Docker socket.

From `pte-api/`:

```powershell
python scripts/seed-local-role-ui-week.py
python scripts/seed-local-role-ui-workflow.py
```

The first script uses one transaction and an advisory lock. The workflow script
uses real API commands and supports resuming missing drafts after interruption.
Keep the local credentials file: if it is missing while fixture accounts already
exist, the base script stops rather than reporting a newly generated unusable password.

The existing local Docker services were started without rebuilding the app image.
The tenant dev server was started with `pnpm --filter tenant-web dev` on port 3000.
