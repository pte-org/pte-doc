# Phase 3: Composition Item Replay Overrides

**Covers:** FR-03 · User stories: P2 (item-level replay override)
**Depends on:** Phase 1 (ExamPolicy foundation), Phase 2 (partial update endpoint)

---

## Requirements

Extend `CompositionItemRequest` (scheduling service) with an optional nullable `maxPlayCount` field. When set on a composition item, it overrides the session-level `ExamPolicy.replayPolicy` for that specific task only; when null, the item inherits the session default. This allows hosts to grant an extra replay to a particularly challenging listening task without changing the session-wide policy. Precedence follows the established pattern: item override (if not null) > session default.

Maps to: **P2 Story #3 (task-level replay customization)**

---

## Design Constraints

- Item-level `maxPlayCount` overrides only the replay limit, not other policy fields (device check, proctor requirement, integrity level remain session-wide).
- Null `maxPlayCount` means "inherit session default" — it is not the same as `maxPlayCount=0` (which would reject all plays). Be explicit about this distinction.
- The precedence pattern must mirror the existing `SessionComposition`/`timingOverrideSeconds` override behavior (session-level default overridable per-item, with null meaning inherit).
- No change to the session-level `ExamPolicy` itself; this is purely a per-composition-item field addition.
- The override is enforced in exam-delivery at play time (Phase 6), not in scheduling — scheduling stores the value, exam-delivery uses it.

---

## Steps

1. Add `maxPlayCount: Integer` (nullable) to `CompositionItemRequest` and `CompositionItem` entities in scheduling (e.g., as a column on the composition-items table or as part of a JSON override struct, following the project's existing pattern for `timingOverrideSeconds`).

2. Update the database migration to add the nullable column to the composition-items table with default null (inherit session default).

3. Update `SessionComposition` service methods that create or update composition items to accept and persist the `maxPlayCount` value; validate that if non-null, the value is >= 1 (or UNLIMITED equivalent, depending on how UNLIMITED is represented).

4. Update the composition-GET endpoint (`GET /sessions/{id}/composition` or equivalent) to return `maxPlayCount` for each item in the response DTO, making the override visible to hosts in the dashboard.

5. Update the composition-update endpoint (`PUT /sessions/{id}/composition` or `POST /sessions/{id}/composition/items`) to accept `maxPlayCount` in the item requests; allow partial updates where only provided fields change (some items may have overrides, others null/default).

6. No storage-layer validation against the session's `ExamPolicy.replayPolicy` needed here — Phase 6 finalized the precedence rule as unconditional ("item `maxPlayCount`, if not null, always wins — including over an UNLIMITED session policy"), which supersedes this step's original "effectively ignored" language. This phase only persists the value; Phase 6 owns enforcement.

7. Integration test: create a session with REAL_EXAM mode (LIMITED(1)); add composition with one item having `maxPlayCount=2` override; verify dashboard shows the override; phase 6 will test enforcement.

8. Integration test: update composition item to change or clear the override; verify persistence.

---

## Success Criteria

- `CompositionItemRequest` accepts optional `maxPlayCount` field.
- Composition items with `maxPlayCount` set show the override in the GET composition response.
- Composition items without `maxPlayCount` (null) show no override and will inherit session default at play time.
- Acceptance criterion from spec: "composition-item override value is what exam-delivery enforces, even when it differs from the session-level default."

---

## Quality and Testing State

- Quality: **approved** (report: `quality/phase-03-composition-item-overrides-quality-report.json`). 1 MEDIUM (pre-existing duplicate `toItem()` mapper between `SessionMapper` and `EntitlementService`, surfaced by this phase's compile error) — fixed by consolidating onto `SessionMapper.toItem()`. No cryptographic receipt (multi-repo limitation, see plan.md).
- Testing: not_started — skipped by user for this phase

---

## Risks

- **Confusion between null and numeric override**: If the backend conflates "null" with "0" or another sentinel value, an item might reject all plays when the author intended to inherit the default. Mitigation: use explicit Optional or nullable type to distinguish unset from zero; validate in tests that null != 0.
- **Ignorance of override in exam-delivery**: If Phase 6 forgets to check the per-item override and only uses session default, the override is silently ignored, causing acceptance-criteria failure. Mitigation: add detailed acceptance criteria for Phase 6 that explicitly test item override precedence; link phases 3 and 6 in cook order (or at least in code review).
- **Unbounded override values**: If the UI allows entering a very large `maxPlayCount` (e.g., 999999), it won't break Phase 3 but could surprise students in Phase 6. Mitigation: add a sane operational upper bound (e.g., 99 or 100) as a validation rule; document this limit in the endpoint's API contract.
