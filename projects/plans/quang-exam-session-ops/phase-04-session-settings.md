# Phase 4: Exam Session Settings & Configuration

## Requirements

Add 5 configurable axes to exam session creation and management: skill subset (toggle for Reading, Listening, Writing, Speaking), per-section time-limit overrides, proctor-required boolean, availability window (start and end datetime), and max retry count. Persist these settings and enforce basic validation (e.g., no future start dates, max retry count >= 0). New session-config fields/entity in examoperations module.

Maps to: **P1 Story #8 | FR-08, FR-10**

## Design Constraints

- Skill-subset toggles must be enforceable at exam-delivery time (Phase 5); storing the config is necessary but not sufficient — do not defer enforcement to Phase 5.
- Per-section time overrides must be nullable (fallback to defaults if not provided); do not implement complex time-calculation logic here (that's Phase 5).
- Proctor-required sessions cannot transition from CREATED to a startable state without an assigned proctor; add a pre-start check but do not implement proctor assignment in this phase (that's Phase 7).
- Availability window dates must be validated (start < end, at least one must be in the future or present).
- Retry count must be a non-negative integer; a session with retry_count=0 means no retries (one-shot).

## Steps

1. Add new columns to ExamSession (or create a new ExamSessionSettings entity, depending on existing schema): skill_subset_reading, skill_subset_listening, skill_subset_writing, skill_subset_speaking (all booleans, default true), proctor_required (boolean, default false), availability_start (OffsetDateTime, nullable), availability_end (OffsetDateTime, nullable), max_retry_count (int, default 0). Per-section time overrides use a **separate `SessionTimeOverride` table** (FK to ExamSession, section_id, override_minutes) — not a JSON blob — decided upfront to give schema validation and a stable target for Phase 8's extend-time action to increment against.

2. Implement POST/PUT endpoints to create/update session settings; apply `@PreAuthorize("hasAuthority('HOST')")` so only Hosts can configure sessions for their tenant.

3. Add validation on create/update: start < end (if both provided), if proctor_required=true then availability_start must be set, max_retry_count >= 0, at least one skill must be enabled.

4. Implement a pre-start check (can be used by Phase 5 exam-delivery): if session is marked proctor_required, query for an assigned proctor; if none exists, return a user-facing error or status code indicating the session cannot start.

5. Update session detail endpoint (GET) to include all 5 axes in the response.

6. Implement CRUD for `SessionTimeOverride` rows (section_id → override_minutes) via the session settings endpoint; a section with no override row falls back to skill-default timing.

7. Test end-to-end: create a Speaking-only session with availability window 2026-07-20 to 2026-07-21, max_retry_count=1; verify all 5 axes are persisted and readable.

8. Test pre-start validation: create a proctor_required=true session with no proctor assigned, attempt to mark it as startable, verify it rejects the transition.

## Success Criteria

- Host can create a session with custom skill subset (e.g., Speaking only), availability window, and retry count.
- Session detail endpoint returns all 5 configured axes.
- Pre-start validation blocks proctor-required sessions without an assigned proctor (error visible to Host).
- Skill-subset toggles persist correctly (can be queried later by Phase 5 delivery code).
- Retry count is respected in data store (Phase 9 will use this value).

## Quality and Testing State

- Quality gate: **approved** (report: `quality/phase-04-session-settings-quality-report.json`, receipt issued 2026-07-16). Two HIGH findings fixed before approval: missing `@Valid` cascade on `timeOverrides`, and a null-skill NPE in `parseSkill()` that would have surfaced as HTTP 500 instead of a validation error.
- Testing: not started — skipped by user for Phase 4 (policy: unit tests required only for Phase 6-9)

## Session Notes

- **Architecture deviation from the plan's literal wording**: no `ExamSession` entity exists in the codebase. The existing `Exam` entity (examoperations module) already plays that role — it's what `ExamAttempt` (examdelivery) references directly by FK, with no separate session layer. The 5 settings axes were added directly to `Exam` rather than inventing a new session entity, which would have required migrating ExamAttempt's FK well beyond this phase's scope.
- `ExamController`/`ExamService`/`ExamOperations`/`CreateExamRequest` were pre-existing empty skeletons (not part of this phase's originally-scoped file list) — implemented them since session settings have no meaningful home without exam creation/detail endpoints to attach to. `CreateExamRequest` originally had a client-suppliable `hostId` field; removed it — hostId is now always resolved server-side from the JWT principal.
- `SessionTimeOverride` keys on (exam_id, skill, part) since no separate "ExamSection" entity exists — Question.skill + Question.part is the closest existing concept of a section.
- `isStartable(Long)` exposed on `ExamOperations` for Phase 5 to call; currently equivalent to `!proctorRequired` since no proctor-assignment mechanism exists before Phase 7.
- Build Gate: PASS.

## Risks

- **Timezone complexity**: If availability window uses local time instead of UTC, a session created in one timezone might be invisible in another. Mitigation: always store and return availability_start/end as OffsetDateTime (UTC); document in API schema; validate in unit tests with multiple timezones.
- **Per-section time override complexity**: resolved — Step 1 commits to a separate `SessionTimeOverride` table with FK constraints rather than a JSON blob, removing the schema-validation gap and giving Phase 8's extend-time action a well-typed target to increment.
- **Proctor-required without proctor assignment flow unclear**: Phase 7 will add proctor assignment, but Phase 4 just checks for presence; if proctor assignment is optional in Phase 7, sessions could stay proctor_required=true indefinitely. Mitigation: document in Phase 4 that proctor-required sessions cannot proceed to "startable" until Phase 7 proctor-assignment endpoint is called; add a warning in the session detail response.
