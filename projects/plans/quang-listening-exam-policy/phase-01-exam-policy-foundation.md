# Phase 1: ExamPolicy Foundation & Mode Defaults

**Covers:** FR-01 · User stories: P1 (mode-based defaults)
**Depends on:** nothing — can start immediately

---

## Requirements

Add an `ExamMode` enum (PRACTICE, MOCK_TEST, REAL_EXAM) to `CreateSessionRequest`; create an `ExamPolicy` embeddable value object with `replayPolicy` (LIMITED count or UNLIMITED), `deviceCheckRequired` (boolean), `proctorRequired` (boolean), and `answerIntegrityLevel` (enum: STANDARD, STRICT); implement mode-based default resolution in `SessionService.create()` so every session gets a sensible policy without manual host configuration. PRACTICE mode allows unlimited replay and no device/proctor checks; REAL_EXAM requires single-play replay, device check, and proctor; MOCK_TEST uses middle defaults. Policy is embedded on `ExamSession` entity (single-valued, not one-to-many).

Maps to: **P1 Story #1 (mode defaults applied automatically)**

---

## Design Constraints

- `ExamPolicy` must be a Hibernate `@Embeddable` value object (not a separate entity or table) to maintain single-session scoping and immutability semantics.
- `replayPolicy` must be a type-safe enum-backed representation (not a string or magic number); a LIMITED policy must carry a count value (e.g. `LIMITED(1)` or `LIMITED(3)`).
- Mode resolution happens exactly once, at `SessionService.create()` time; if a session is created without an explicit `examMode`, it must default to MOCK_TEST (safe middle-ground, not PRACTICE which is permissive, not REAL_EXAM which is strict).
- `answerIntegrityLevel` field is reserved for task 20's future use; Phase 1 only sets the enum value (STANDARD or STRICT), does not implement encryption/hash mechanism.
- No endpoints expose or allow manual tweaking of `ExamPolicy` in Phase 1; that is Phase 2's responsibility (partial update).

---

## Steps

1. Create `ExamMode` enum in scheduling service (PRACTICE, MOCK_TEST, REAL_EXAM) and add `examMode: ExamMode` (nullable with default MOCK_TEST) to `CreateSessionRequest` DTO.

2. Create `ReplayPolicy` type to represent replay limits — design as a sealed type or enum with associated value (e.g., `UNLIMITED` and `LIMITED(count: int)`), allowing strong typing and avoiding magic numbers throughout the codebase.

3. Create `ExamPolicy` Hibernate `@Embeddable` class with fields: `replayPolicy` (custom type mapped to database columns or JSON), `deviceCheckRequired` (boolean), `proctorRequired` (boolean), `answerIntegrityLevel` (enum STANDARD/STRICT).

4. Add database migration to create columns on `exam_session` (or equivalent) for the `ExamPolicy` fields if using column-per-field, or a single `exam_policy_json` column if JSON-embedded (choose the approach that fits the project's existing ORM conventions). **Existing rows**: the migration must set every pre-existing `exam_session` row to the MOCK_TEST defaults (`LIMITED(3), deviceCheckRequired=true, proctorRequired=false, STANDARD`) as part of the same migration script (e.g., `UPDATE exam_session SET ... WHERE <policy columns are null>` after adding the columns) — do not leave pre-existing rows with null policy columns, since Phase 4/5/6 assume a policy always resolves to a concrete value once pinned.

5. Implement `ExamPolicyResolver` service (or function in `SessionService`) that takes an `ExamMode` and returns a default `ExamPolicy`: PRACTICE → `ExamPolicy(UNLIMITED, false, false, STANDARD)`; REAL_EXAM → `ExamPolicy(LIMITED(1), true, true, STRICT)`; MOCK_TEST → `ExamPolicy(LIMITED(3), true, false, STANDARD)`.

6. Update `SessionService.create()` to accept `examMode` from the request, resolve the default policy, and embed it on the new `ExamSession` entity before persisting.

7. Add unit tests for mode-to-policy resolution (each mode produces expected defaults); integration test for session creation with explicit vs. default exam mode.

8. Update existing `GET /sessions/{id}` response DTO to include the resolved `ExamPolicy` fields (for host dashboard visibility), but do not expose these in the student-facing delivery response yet (Phase 4 handles delivery-side pinning).

---

## Success Criteria

- Creating a session with `examMode=REAL_EXAM` produces a session whose `ExamPolicy` has `replayPolicy=LIMITED(1)`, `deviceCheckRequired=true`, `proctorRequired=true`, `answerIntegrityLevel=STANDARD`.
- Creating a session with `examMode=PRACTICE` produces `ExamPolicy` with `replayPolicy=UNLIMITED`, `deviceCheckRequired=false`, `proctorRequired=false`.
- Creating a session without an explicit `examMode` defaults to MOCK_TEST mode and its corresponding defaults.
- `GET /sessions/{id}` for a host returns the session's `ExamPolicy` fields in the response (for dashboard inspection).
- Mode-to-policy resolution is deterministic and covered by unit tests.

---

## Quality and Testing State

- Quality: **approved** (report: `quality/phase-01-exam-policy-foundation-quality-report.json`). One MEDIUM finding (QUAL-001: `ExamPolicyResponse` used primitive `boolean` for fields sourced from nullable `Boolean`s — fixed by switching to boxed `Boolean`), resolved before approval. No cryptographic receipt issued — see plan.md's note on the multi-repo receipt limitation; approval here is a recorded human/reviewer decision, not a hash-verified one.
- Testing: not_started — skipped by user for this phase

---

## Risks

- **Enum value mismatch on database**: If the mode-to-policy mapping is later changed (e.g., MOCK_TEST defaults change), existing sessions' embedded policies will not auto-update. Mitigation: policy is immutable once set at creation time (by design); if defaults need changing, new sessions get new defaults; old sessions keep their original policy (this is correct behavior — don't apply new defaults to old sessions retroactively).
- **Type safety for ReplayPolicy**: If `LIMITED` is represented as separate columns (e.g., `replay_policy_type` and `replay_policy_count`), they can become inconsistent (e.g., type=UNLIMITED but count=5). Mitigation: use a single database column with a custom Hibernate `UserType` that serializes/deserializes the full `ReplayPolicy` object as a unit (or JSON if the project uses JSON columns).
