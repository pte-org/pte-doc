# Phase 4: PRACTICE and OFFICIAL sessions

**Goal:** Two OPEN sessions (and their prerequisites) for the seeded tenant/student, one per flow.

## Tasks

1. Reuse tenant, host, student, program, class, plan and subscription from `seed-local-exam-ready.ps1` (`seed-pte-local`, `host.pte-local@test.local`, `student.pte-local@test.local`); extract the shared helpers instead of duplicating them.
2. PRACTICE sessions (user decision: both shapes): `examMode=PRACTICE`, lockdown `NONE`, template = V5 — `DEMO22 PRACTICE` (all 4 skills) plus `DEMO22 PRACTICE Speaking|Writing|Reading|Listening` (skill-scoped via `skills`); 5 sessions total, enrol the same class in each.
3. OFFICIAL session: `examMode=OFFICIAL_EXAM`, lockdown `STRICT`, `proctorRequired=true` (user decision: real proctor); add the class as audience; create a proctor account (find the valid role/endpoint first — only `HOST_ADMIN`, `PLATFORM_ADMIN`, `STUDENT` exist locally today) and assign it via `ProctorAssignmentController`. Fallback only if the role cannot be created: stop and ask, do not silently disable the proctor requirement.
4. Per session: `preflight` → `generate` (idempotency key) → `publish` → `open`; session window `opensAt = now+1 min`, `closesAt` close to subscription expiry (R3), so the demo lasts days rather than 2 hours.
5. Names: `DEMO22 PRACTICE` and `DEMO22 OFFICIAL` (stable, used for lookup on rerun).

## Design Constraints

- Enum value is `OFFICIAL_EXAM`; never send `OFFICIAL` or `MOCK_TEST` (F7).
- `PRACTICE` must not request `STRICT`; `OFFICIAL_EXAM` must request `STRICT` (server rejects otherwise).
- Re-run safe: if a session with the same name is `OPEN`/`SCHEDULED`/`DRAFT`, continue it; if `CLOSED`, create a new one with a timestamp suffix, like the existing script.
- Passwords come from `PTE_SEED_PASSWORD`; never printed.

## Success Criteria

- Both sessions `OPEN`; `GET /sessions/{id}/exam-preview` (or generation view) shows all 22 task types in each form.
- Student enrolled in both.

## Quality and Testing State

- Quality gate: not evaluated
- Testing: not started
