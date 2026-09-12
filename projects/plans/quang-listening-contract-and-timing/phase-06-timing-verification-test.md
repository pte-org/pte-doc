# Phase 6: Timing Configuration Verification Test

**Covers:** FR-06 · Guard test for all task-type timing entries
**Depends on:** Phase 4 (all 23 timing entries must exist), Phase 5 (PteTaskType must be in pte-common for import)
**Status:** Deferred follow-up — the active plan uses a focused seven-value guard; this all-23 EnumSource guard requires the separate shared-vocabulary refactor

---

## Requirements

Implement a parameterized guard test (`@ParameterizedTest @EnumSource(PteTaskType.class)`) in pte-api/services/exam-delivery that asserts `TaskTimingConfig.timingFor(taskType)` does not throw `TaskTimingNotConfiguredException` for any of the 23 PTE task types. The test imports `PteTaskType` from pte-common (available after Phase 5). Failure means a new task type was added to the enum but task-timing.json is missing its entry, surfacing the gap at build time before session pinning can encounter it at runtime.

---

## Design Constraints

- The test must use `@ParameterizedTest @EnumSource(PteTaskType.class)` to iterate over all 23 enum constants; this is only possible after Phase 5 moves the enum to pte-common (which is already a dependency of exam-delivery).
- The test must NOT assert anything about the **correctness** of the timing values (e.g., "responseSeconds > prepSeconds" or "responseSeconds < 3600"); it only checks that entries exist and are loadable. Correctness validation is out of scope (no official timing spec to check against yet).
- The test should log or output each task type + its resolved Timing object on success, for visibility into what's configured; on failure, the exception message from `TaskTimingNotConfiguredException` should surface clearly.
- The test must run in `exam-delivery` service (where TaskTimingConfig lives); it is a unit test for TaskTimingConfig.
- The test should be integrated into exam-delivery's standard test suite (run on `mvn test` or equivalent).

---

## Steps

1. Verify that Phase 5 has completed (pte-common now has `PteTaskType` enum and exam-delivery can import it).

2. Create test class in `pte-api/services/exam-delivery/src/test/java/com/pte/examdelivery/config/TaskTimingConfigGuardTest.java`:

   ```java
   package com.pte.examdelivery.config;

   import com.pte.common.domain.enums.PteTaskType;
   import org.junit.jupiter.params.ParameterizedTest;
   import org.junit.jupiter.params.provider.EnumSource;
   import org.springframework.beans.factory.annotation.Autowired;
   import org.springframework.boot.test.context.SpringBootTest;

   import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;

   @SpringBootTest
   class TaskTimingConfigGuardTest {

     @Autowired
     private TaskTimingConfig taskTimingConfig;

     @ParameterizedTest
     @EnumSource(PteTaskType.class)
     void testAllTaskTypesHaveTimingConfiguration(PteTaskType taskType) {
       assertDoesNotThrow(
         () -> taskTimingConfig.timingFor(taskType.name()),
         "Task type " + taskType.name() + " is missing timing configuration in task-timing.json"
       );
     }
   }
   ```

3. Iterate: run the test after Phase 4 is complete. If all 23 task types have entries, the test passes. If any type is missing, the test fails with a clear error stating which task type is unconfigured.

4. Verify the test runs in CI/CD or local `mvn test` (it will run automatically as part of the exam-delivery service's test suite).

5. Add a comment in the test class explaining its purpose: "Guard test to detect when a new task type is added to PteTaskType enum but task-timing.json is missing its entry. Prevents runtime TaskTimingNotConfiguredException at session pinning time. If test fails, add the missing task type to task-timing.json and run again."

---

## Success Criteria

- A parameterized test class exists in exam-delivery (`TaskTimingConfigGuardTest.java`).
- Test uses `@ParameterizedTest @EnumSource(PteTaskType.class)` importing from pte-common.
- Test iterates over all 23 `PteTaskType` enum constants.
- Test passes when all 23 types have timing entries in task-timing.json.
- Test fails obviously (with clear error message) if a task type is missing from task-timing.json (e.g., if Phase 4 accidentally omitted one of the 7 new entries).
- Test runs as part of exam-delivery's standard test suite.

---

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

---

## Risks

- **Test doesn't validate timing correctness**: This test passes even if task-timing.json has wildly wrong values (e.g., responseSeconds=99999). Mitigation: Test scope is limited to "entry exists, not throw"; correctness validation is a separate future task (requires official Pearson sourcing, out of scope); document this limitation in the test javadoc.
- **Enum import fails if Phase 5 not complete**: If Phase 5 is skipped or delayed, this phase cannot compile (PteTaskType not in pte-common). Mitigation: Phase 6 explicitly depends on Phase 5 in the plan; do not run Phase 6 until Phase 5 is done.

---

## File Ownership

- `pte-api/services/exam-delivery/src/test/java/com/pte/examdelivery/config/TaskTimingConfigGuardTest.java` — Phase 6 creates
