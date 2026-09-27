# Phase 7: Section-Scoped Listening Timing Model

**Covers:** FR-07 · Section-scoped budget for Listening (except SUMMARIZE_SPOKEN_TEXT)
**Depends on:** Phase 4 (all 7 timing entries must exist), Phase 6 (guard test ensures config is sound)
**Status:** Deferred follow-up — do not cook from this plan until Listening timer semantics and official timing policy are separately verified

This draft is intentionally non-executable. In particular, the pseudocode
below is incomplete: merely clearing `sectionPausedAt` does not add elapsed
time to `accumulatedSectionElapsed`, and calculating `now - sectionStartedAt`
would still count time spent inside SST. A future implementation must define
and test the state-transition algorithm before production code is changed.

---

## Requirements

Implement section-scoped timing for the LISTENING section in `TimerService`, where all Listening tasks except SUMMARIZE_SPOKEN_TEXT share a single countdown budget (like READING does), while SUMMARIZE_SPOKEN_TEXT keeps its own per-item 10-minute budget. Update SECTION_SCOPED_SECTIONS to include LISTENING with a runtime carve-out for SST; fix `sectionBudgetSeconds()` javadoc to match its implementation (no contiguity check, just filters all same-section items) without changing the code. Add accumulated-elapsed bookkeeping to ensure the shared clock does NOT run during SST items (SST is its own timed item in real PTE), only paused and resumed when returning to non-SST Listening items.

---

## Design Constraints

- **SST carve-out must be explicit and documented.** Add an inline comment in `startTask()` explaining why SST is treated differently: "SUMMARIZE_SPOKEN_TEXT has its own per-item 10-minute budget in real PTE; it does not consume the shared Listening pool. When entering SST, reset the section-scoped clock; when leaving SST, resume the clock." This carve-out is temporary pending a more general task-type-specific behavior framework.

- **The shared clock must NOT run during SST.** Simply storing `sectionStartedAt` is insufficient; if an SST item takes 5 minutes, and the shared Listening pool is 20 minutes for the other items, the current approach would still deduct 5 minutes from the shared budget when SST ends (because elapsed time = now - sectionStartedAt includes SST's duration). Solution: track accumulated elapsed time per section (`accumulatedSectionElapsed`) separately, update it ONLY when a non-SST item advances (not when SST runs). When resolving remaining budget, use accumulated elapsed, not raw elapsed from sectionStartedAt.

- `startTask()` must handle three cases for LISTENING items:
  1. Entering a non-SST Listening item: start/resume the section timer (set `sectionStartedAt` if this is the first non-SST item of this section run; otherwise leave it unchanged).
  2. Entering an SST item: pause the section timer (do NOT update `sectionStartedAt`; instead, record that we're in an SST "pause" state).
  3. Leaving an SST item back to non-SST: accumulate the time SST ran separately, resume the shared clock (resume `sectionStartedAt`).

- `resolveEffectiveResponseSeconds()` must return:
  - For SST items: the static `item.responseSeconds()` (600s, 10 min, unchanged by elapsed time from other items).
  - For non-SST Listening items: the live remaining shared budget (derived from `sectionBudgetSeconds() - accumulatedSectionElapsed`, not from raw elapsed time).

- `sectionBudgetSeconds()` javadoc fix is documentation-only; state that the method filters all items matching the section without a contiguity check (noted as a future enhancement if sections become interspersed). No implementation change.

- The section-scoped model is backward-compatible; deployments without Listening sections are unaffected.

---

## Steps

1. Review the current `TimerService` class (pte-api/services/exam-delivery/src/main/java/com/pte/examdelivery/service/TimerService.java):
   - Line 31: `SECTION_SCOPED_SECTIONS = Set.of("READING")`
   - Lines 45-62: `startTask()` method managing section transitions
   - Lines 75-84: `resolveEffectiveResponseSeconds()` computing live budgets
   - Lines 94-99: `sectionBudgetSeconds()` summing per-item budgets for a section

2. Check the `ExamAttempt` entity to see what fields are available for tracking state; verify it has or can have:
   - `sectionStartedAt: Instant` (exists, used for READING)
   - A new field `accumulatedSectionElapsed: Long` (in seconds) to track how much time has elapsed in the shared section budget, excluding SST pauses.
   - Optionally: `sectionPausedAt: Instant` to mark when an SST item pauses the shared clock (so we know when to accumulate elapsed on SST exit).

3. Add `accumulatedSectionElapsed` field to `ExamAttempt` entity (if not already present); initialize to 0 when a section-scoped section is entered.

4. Add LISTENING to SECTION_SCOPED_SECTIONS: change line 31 to `Set.of("READING", "LISTENING")`. This will be refined with the SST carve-out in subsequent steps.

5. Update `startTask()` method (lines 45-62) to add logic for LISTENING section-scoping with SST carve-out:

   ```java
   if (SECTION_SCOPED_SECTIONS.contains(item.section())) {
     if (!item.section().equals(attempt.getActiveSection())) {
       // Just entered this section-scoped section for the first time.
       attempt.setSectionStartedAt(Instant.now());
       attempt.setAccumulatedSectionElapsed(0L);
     }
     attempt.setActiveSection(item.section());

     // SUMMARIZE_SPOKEN_TEXT carve-out: it runs outside the shared budget.
     // When entering SST, record that the shared clock is paused; when leaving SST, resume.
     if ("SUMMARIZE_SPOKEN_TEXT".equals(item.getTaskType())) {
       // SST item: shared clock is paused. Store sectionPausedAt to mark pause time.
       attempt.setSectionPausedAt(Instant.now());
     } else if ("LISTENING".equals(item.section())) {
       // Non-SST Listening item: shared clock resumes. If just exiting SST, accumulate its duration.
       if (attempt.getSectionPausedAt() != null) {
         // SST just ended; resume the shared clock.
         attempt.setSectionPausedAt(null);  // Clear pause marker.
       }
     }
   } else {
     // Non-section-scoped section (or leaving a section-scoped section).
     attempt.setActiveSection(null);
     attempt.setSectionStartedAt(null);
     attempt.setAccumulatedSectionElapsed(0L);
     attempt.setSectionPausedAt(null);
   }
   ```

   Add a comment explaining the SST carve-out: "SUMMARIZE_SPOKEN_TEXT has its own per-item 10-minute budget; it does not consume the shared Listening pool. When SST runs, the shared clock is paused; when SST ends, the clock resumes. This is temporary until task-type-specific behavior is generalized."

6. Update `resolveEffectivePrepSeconds()` method (line 75-76):

   ```java
   public int resolveEffectivePrepSeconds(PinnedItemView item) {
     if ("SUMMARIZE_SPOKEN_TEXT".equals(item.taskType())) {
       return item.prepSeconds();  // SST has its own budget.
     }
     if (SECTION_SCOPED_SECTIONS.contains(item.section())) {
       return 0;  // Shared section has no individual prep per item.
     }
     return item.prepSeconds();
   }
   ```

7. Update `resolveEffectiveResponseSeconds()` method (line 79-84):

   ```java
   public int resolveEffectiveResponseSeconds(ExamAttempt attempt, PinnedItemView item, List<PinnedItemView> allItems) {
     if ("SUMMARIZE_SPOKEN_TEXT".equals(item.taskType())) {
       return item.responseSeconds();  // SST has its own 10-min budget, never reduced.
     }
     if (!SECTION_SCOPED_SECTIONS.contains(item.section())) {
       return item.responseSeconds();  // Per-task budget for non-section-scoped items.
     }
     // Section-scoped, non-SST: compute live remaining shared budget.
     long totalSectionBudget = sectionBudgetSeconds(item, allItems);
     long newElapsed = Duration.between(attempt.getSectionStartedAt(), Instant.now()).getSeconds();
     long totalElapsed = attempt.getAccumulatedSectionElapsed() + newElapsed;
     return (int) Math.max(0, totalSectionBudget - totalElapsed);
   }
   ```

8. Fix `sectionBudgetSeconds()` javadoc (lines 87-92):

   ```java
   /**
    * Sums {@code prepSeconds + responseSeconds} across all items matching
    * {@code item.section()} — does NOT filter for contiguity. Items are
    * expected to be grouped by section (matching real PTE section ordering);
    * if sections become interspersed in the future, this implementation should
    * be revisited to implement true contiguity checking.
    *
    * TODO: Implement contiguous-run filtering once sections can interleave.
    */
   private long sectionBudgetSeconds(PinnedItemView item, List<PinnedItemView> allItems) {
     return allItems.stream()
       .filter(candidate -> item.section().equals(candidate.section()))
       .mapToLong(candidate -> (long) candidate.prepSeconds() + candidate.responseSeconds())
       .sum();
   }
   ```

9. Add unit tests:
   - Test that an SST item in LISTENING section returns static 600s responseSeconds (not shared budget).
   - Test that non-SST items in LISTENING section return live remaining shared budget (elapsed time subtracted).
   - Test that mixed-type sessions (SST + non-SST) verify budgets don't interfere.

10. Add integration test for interleaved ordering (SST → MC_LISTENING_MULTIPLE → SST):
    - Create a pinned session: SST (10 min) → MC_LISTENING_MULTIPLE (0 prep, 30 response) → SST (10 min) → MC_LISTENING_MULTIPLE (0 prep, 30 response).
    - Shared Listening budget for the 2 MC items should be 60s total.
    - Advance to first item (SST): resolve time, should be 600s (static).
    - Advance to second item (MC): resolve time, should be 60s (shared budget).
    - Simulate 20 seconds passing on the MC item.
    - Advance to third item (SST): resolve time, should be 600s (static).
    - Advance to fourth item (MC): resolve time, should be 40s (60 - 20 already spent on item 2).
    - Assertion: SST items are never affected by elapsed time from other items; the shared clock was paused during SST and resumed after.

---

## Success Criteria

- LISTENING is added to SECTION_SCOPED_SECTIONS.
- `ExamAttempt` entity has `accumulatedSectionElapsed` field (if not already present) and optional `sectionPausedAt` field.
- SUMMARIZE_SPOKEN_TEXT items in LISTENING section return static 600s responseSeconds (10 min, not affected by elapsed time).
- Non-SST Listening items (MC_LISTENING_MULTIPLE, etc.) return live remaining shared budget (accumulated elapsed time subtracted from total section budget).
- `startTask()` contains an inline comment explaining the SST carve-out and why it exists.
- `sectionBudgetSeconds()` javadoc is updated to remove "contiguous run" claim and add TODO comment; implementation unchanged.
- Unit tests for SST carve-out pass (static vs. shared budget).
- Integration test with interleaved ordering (SST → MC → SST → MC) passes, verifying that SST time does not consume the shared budget and the shared clock resumes correctly after SST.
- Existing READING section-scoped tests still pass (no regression).

---

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

---

## Risks

- **Accumulated elapsed tracking adds complexity**: Managing both `sectionStartedAt` (for determining when section started) and `accumulatedSectionElapsed` (for tracking how much of the shared budget was consumed) requires careful bookkeeping. Mitigation: Keep the logic localized in `startTask()` and `resolveEffectiveResponseSeconds()`; add clear comments; accept that this is temporary until a more general framework is built.

- **Interleaved SST ordering edge case**: If an exam layout unexpectedly interleaves SST items non-contiguously (SST → MC → SST → MC → SST), the current implementation assumes only one pause/resume cycle per section entry. Multiple pauses might reveal bugs. Mitigation: Phase 7 integration test must cover at least two SST → non-SST transitions to catch this; if the test passes with 2 transitions, it should work for N transitions (the logic is stateless per transition).

- **`sectionBudgetSeconds()` javadoc TODO is weak**: "Contiguity is a future enhancement" might be ignored by future developers. Mitigation: Add TODO comment with explicit link to a future plan or issue (out of scope for this plan); rely on code review to enforce it.

- **SUMMARIZE_SPOKEN_TEXT 10-minute value might be wrong**: If the actual budget is different (e.g., 8 min or 12 min), Phase 7's static value is incorrect. Mitigation: Phase 4 marks this as "secondary confidence"; Phase 7 can change the value later without reworking logic; accept risk, plan to verify during testing against real exam data.

---

## File Ownership

- `pte-api/services/exam-delivery/src/main/java/com/pte/examdelivery/service/TimerService.java` — Phase 7 owns LISTENING section-scoping logic and javadoc fix
- `pte-api/services/exam-delivery/src/main/java/com/pte/examdelivery/domain/ExamAttempt.java` — Phase 7 may add new fields if needed (accumulatedSectionElapsed, sectionPausedAt)
