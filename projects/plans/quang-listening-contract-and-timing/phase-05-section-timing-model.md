# Phase 5: Section-Scoped Listening Timing Model

**Covers:** FR-05 · Section-scoped budget for Listening (except SUMMARIZE_SPOKEN_TEXT)
**Depends on:** Phase 4 (all 7 timing entries must exist)
**Status:** Superseded/deferred — do not cook; use a separately reviewed section-timing plan after the contract/timing unblock

---

## Requirements

Implement section-scoped timing for the LISTENING section in `TimerService`, where all Listening tasks except SUMMARIZE_SPOKEN_TEXT share a single countdown budget (like READING does), while SUMMARIZE_SPOKEN_TEXT keeps its own per-item 10-minute budget. Update SECTION_SCOPED_SECTIONS to include LISTENING with a runtime carve-out for SST; fix `sectionBudgetSeconds()` javadoc (currently claims a "contiguous run" filter, but implementation filters all same-section items without contiguity check) by updating the doc to match reality — no implementation change needed (READING items are grouped by session author, so the current all-same-section scan works despite the overstated javadoc).

---

## Design Constraints

- Section-scoping must NOT be a per-task-type switch in `TimerService`; instead, add a new method or enum (e.g., `LISTENING_SHARED_EXCEPT_SST`) to represent this hybrid model, or inline a carve-out check: `if (item.section().equals("LISTENING") && !item.taskType().equals("SUMMARIZE_SPOKEN_TEXT"))` — the design must remain clear and localized.
- `startTask(item)` must recognize when a new section-scoped section is entered (for LISTENING with mixed types, SST items should NOT reset the `sectionStartedAt` timer unless the student actually leaves the Listening section and comes back). Mitigation: The carve-out check in `startTask()` must ensure `setSectionStartedAt()` is called only for non-SST Listening items.
- `resolveEffectiveResponseSeconds()` must return the live remaining shared budget for non-SST Listening items, and the task's own static `responseSeconds` for SST items (10 min = 600s, never reduced by elapsed time during other Listening tasks).
- The section-scoped model change is an expansion of the existing per-item-only assumption; deployments that only include Reading and Speaking/Writing sections (no Listening) are unaffected (Phase 5 is backward-compatible).
- `sectionBudgetSeconds()` javadoc fix must NOT change the implementation (no contiguity check added, since that would require scanning backward/forward from the item's position); the javadoc update is a documentation-only fix — state that the method filters all items matching the section, without a contiguity requirement (that's a future enhancement if sections become interspersed).

---

## Steps

1. Review the existing `TimerService` class (line 31 has `SECTION_SCOPED_SECTIONS = Set.of("READING")`; line 52-62 has section-switch logic in `startTask()`; line 79-84 has `resolveEffectiveResponseSeconds()` branch). Understand the current model: SECTION_SCOPED_SECTIONS items share a budget, others use per-task static values.

2. Add LISTENING to SECTION_SCOPED_SECTIONS: change line 31 to `Set.of("READING", "LISTENING")`. This naively makes all Listening items (including SST) share a budget — still wrong, so proceed to Step 3 immediately.

3. Update `startTask()` method (lines 51-62) to add a carve-out for SUMMARIZE_SPOKEN_TEXT: when entering LISTENING and the current item is NOT SST, set `sectionStartedAt`; if current item IS SST, don't treat it as section-scoped (leave `activeSection = null` or set a separate flag). Pseudocode: `if ("LISTENING".equals(item.section()) && !"SUMMARIZE_SPOKEN_TEXT".equals(item.taskType())) { attempt.setSectionStartedAt(...); }` else handle SST as per-task.

4. Update `resolveEffectivePrepSeconds()` method (line 75-76) to recognize the SST carve-out: if item is SST, return static `item.prepSeconds()`; if LISTENING but not SST, return 0 (shared budget, no individual prep); otherwise existing logic.

5. Update `resolveEffectiveResponseSeconds()` method (line 79-84) to apply the SST carve-out: if item is SUMMARIZE_SPOKEN_TEXT, return static `item.responseSeconds()` (600s, 10 min, unchanged by elapsed time); if LISTENING but not SST, compute live remaining shared budget; otherwise existing logic.

6. Fix `sectionBudgetSeconds()` javadoc (lines 87-92) to remove the claim about "contiguous run" and "forward/backward scan." Replace with: "Sums prepSeconds + responseSeconds across all items matching item.section() (not just contiguous run). Items are expected to be grouped by section matching real PTE section ordering; if sections become interspersed, this implementation should be revisited to implement true contiguity check." No implementation change.

7. Add unit tests for the new SST carve-out: test that an SST item in LISTENING section gets static 600s responseSeconds (not shared budget); test that non-SST items in LISTENING get live remaining budget; test mixed sessions (SST + MC_LISTENING_MULTIPLE) verifying budgets don't interfere.

8. Add integration test: create a pinned session with 1 SST item (10 min budget) + 2 MC_LISTENING_MULTIPLE items (estimated shared budget). Advance through items, verify each gets the correct timer value (SST unchanged by elapsed, non-SST reduced by elapsed + other items' budgets).

---

## Success Criteria

- LISTENING is added to SECTION_SCOPED_SECTIONS.
- SUMMARIZE_SPOKEN_TEXT items in LISTENING section return static 600s responseSeconds (10 min, not shared budget).
- Non-SST Listening items (MC_LISTENING_MULTIPLE, etc.) return live remaining shared budget (elapsed time subtracted).
- `sectionBudgetSeconds()` javadoc is updated to remove "contiguous run" claim; implementation unchanged.
- Unit tests for SST carve-out pass.
- Integration test with mixed Listening types passes.
- Existing READING section-scoped tests still pass (no regression).

---

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

---

## Risks

- **SST carve-out complexity**: Adding special logic for one task type in a generic section-handling class increases complexity and maintenance burden. Mitigation: Keep the carve-out check localized (same method, clear if-statement); add clear comments; accept that this is a temporary solution until a more general "task-type-specific behavior" framework is built.
- **Interleaved Listening items**: If a future exam layout puts SST items interspersed with other Listening items (not grouped together), the current section-scoped budget logic might misbehave (SST might consume part of the shared pool, or vice versa, depending on the order). Mitigation: Phase 5 assumes SST items are grouped (session author's responsibility). If this assumption breaks, revisit with a more sophisticated model (per-item budget overrides, or task-type-scoped budgets). Document the assumption in code comments.
- **`sectionBudgetSeconds()` javadoc removal is vague**: "Contiguity is a future enhancement" is too weak. Future developers might assume contiguity is implemented. Mitigation: Add a TODO comment with a link to an issue/plan for contiguity implementation (out of scope for this plan).
- **SUMMARIZE_SPOKEN_TEXT 10-minute value might be wrong**: If the actual budget is different (e.g., 8 min or 12 min), Phase 5's static value is wrong. Mitigation: Phase 4 marks this as "secondary confidence"; Phase 5 can change the value later without reworking logic; accept risk, plan to verify during testing.

---

## File Ownership

- `pte-api/services/exam-delivery/src/main/java/com/pte/examdelivery/service/TimerService.java` — Phase 5 owns LISTENING section-scoping logic and javadoc fix
