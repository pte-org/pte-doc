# Phase 5: PteTaskType to pte-common (Enum Vocabulary Consolidation)

**Covers:** FR-05 · Move task-type vocabulary to shared library, split validation concerns
**Depends on:** nothing — can run in parallel with Phases 1-4
**Status:** Deferred follow-up — not part of the active Listening contract/timing cook order

---

## Requirements

Move the `PteTaskType` enum from `pte-api/services/authoring` to `pte-common`, but split the concerns: the shared enum carries **only** `section` and `scored` fields (platform-wide vocabulary every service needs). Authoring's 6 validation flags (`requiresAudioPrompt`, `requiresImagePrompt`, `requiresPromptText`, `requiresOptions`, `requiresCorrectAnswer`, `requiresWordCount`) remain in authoring as a companion lookup keyed by the shared enum. Update all imports across authoring, exam-delivery, scoring, and reporting to use the shared enum from pte-common. Eliminate triplicated task-type vocabulary (authoring enum + scoring string constants + exam-delivery JSON keys).

---

## Design Constraints

- `PteTaskType` in pte-common must carry only `section` (enum: READING, SPEAKING, WRITING, LISTENING) and `scored` (boolean) fields, plus the 23 enum constants for all task types. NO validation flags — those are authoring's concern.
- Authoring keeps its validation flags in a companion data structure (e.g., `EnumMap<PteTaskType, TaskTypeMetadata>` or a static `Map<String, TaskMetadata>` keyed by enum name) in the authoring module. This companion is NOT shared; it is authoring's internal lookup.
- `PteTaskType` must be a dependency of authoring, exam-delivery, scoring, and reporting; pte-common already is a dependency of exam-delivery and scoring (verified: pom.xml lines ~73 and ~62), so moving the enum doesn't create new circular dependencies.
- The enum constants and their section/scored assignments must be sourced from the existing authoring enum; do not change the constant names or section assignments.
- Every service that currently imports `PteTaskType` from authoring must have that import statement changed to `pte-common` (anticipated ripple: authoring itself, possibly reporting/analytics, possibly other services).

---

## Steps

1. Review the current `pte-api/services/authoring/src/main/java/com/pte/authoring/domain/enums/PteTaskType.java` and document:
   - All 23 enum constants and their current field values (section, scored, and the 6 validation flags).
   - The section assignments (READING, SPEAKING, WRITING, LISTENING).
   - The scored boolean values (e.g., which are scored vs. not).

2. Create `pte-common/src/main/java/com/pte/common/domain/enums/PteTaskType.java` with:
   - All 23 constants.
   - Only `section: PteSection` (enum with 4 values: READING, SPEAKING, WRITING, LISTENING) and `scored: boolean` fields.
   - Javadoc explaining that validation flags are authoring's responsibility, not this shared enum's.
   - A comment linking to the authoring module for validation logic.

3. Create `PteSection` enum in pte-common (if not already present):
   ```java
   public enum PteSection {
     READING, SPEAKING, WRITING, LISTENING
   }
   ```

4. Delete or deprecate (do not delete outright; mark `@Deprecated`) the old `PteTaskType` in authoring's enums, replacing references with the pte-common import. Deprecation warning should say "Moved to pte-common; update imports to com.pte.common.domain.enums.PteTaskType".

5. Create a new companion lookup in authoring (e.g., `TaskTypeMetadataLookup.java` or similar) that holds the validation flags:
   ```java
   public class TaskTypeMetadataLookup {
     private static final Map<PteTaskType, TaskMetadata> METADATA = new EnumMap<>(PteTaskType.class);
     static {
       METADATA.put(PteTaskType.REPEAT_SENTENCE, new TaskMetadata(true, false, true, false, true, null));
       // ... other 22 types
     }
     public static TaskMetadata metadataFor(PteTaskType type) { return METADATA.get(type); }
   }
   ```
   Or use a record `TaskMetadata(boolean requiresAudioPrompt, ...)` to carry the flags. Define this structure in authoring.

6. Update all references in authoring that currently read validation flags from the `PteTaskType` enum to instead call `TaskTypeMetadataLookup.metadataFor(type).requiresAudioPrompt()` (or equivalent).

7. Search for `import com.pte.authoring.domain.enums.PteTaskType` across the entire codebase (pte-api, pte-app, pte-web, pte-doc, etc.) and update all imports to `import com.pte.common.domain.enums.PteTaskType`. Anticipated ripple points:
   - `pte-api/services/exam-delivery/src/main/java/com/pte/examdelivery/config/TaskTimingConfig.java` (reads enum, uses it in tests)
   - `pte-api/services/scoring/src/main/java/com/pte/scoring/service/AnswerPayloadDecoder.java` (may reference task types by name)
   - `pte-api/services/reporting` (if it exists and references task types)
   - Any other service that references PteTaskType by name or imports the enum.

8. Update `pte-api/services/scoring/src/main/java/com/pte/scoring/constant/ScoringConstants.java` — this file has 14 duplicate `TASK_TYPE_*` string constants (e.g., `TASK_TYPE_READ_ALOUD = "READ_ALOUD"`). These are now redundant with the `PteTaskType.READ_ALOUD.name()` pattern. Mark them as `@Deprecated` and document that callers should use `PteTaskType.READ_ALOUD.name()` instead (do not delete outright to avoid breaking old code).

9. Rebuild authoring, exam-delivery, and scoring services; verify no compilation errors; run existing unit tests to ensure validation behavior is unchanged.

10. Document the change in this plan and in a commit message noting the coupling trade-off: adding a task type now rebuilds all consumers (authoring, exam-delivery, scoring, reporting), which is accepted because the vocabulary is a closed set defined by Pearson, not team-defined, so it does not churn per-service.

---

## Success Criteria

- A new `PteTaskType` enum exists in `pte-common` with all 23 constants, `section` and `scored` fields only (no validation flags).
- A new `PteSection` enum exists in `pte-common` with 4 values (READING, SPEAKING, WRITING, LISTENING).
- Authoring has a companion lookup (e.g., `TaskTypeMetadataLookup`) carrying the 6 validation flags, keyed by the shared enum.
- All imports of `PteTaskType` across the codebase now use `com.pte.common.domain.enums.PteTaskType` (verify with grep).
- The old authoring enum is deprecated (if not deleted outright).
- `ScoringConstants.TASK_TYPE_*` constants are marked `@Deprecated` (if not deleted).
- All services (authoring, exam-delivery, scoring, reporting) rebuild without errors.
- Existing unit tests still pass (validation behavior unchanged).

---

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

---

## Risks

- **Circular dependency if not careful**: If authoring tries to import anything from exam-delivery or scoring (common pitfall), a circular dependency can emerge. Mitigation: authoring must only import from pte-common, not from other services. Check the dependency tree before committing (use `mvn dependency:tree`).
- **Ripple effects across multiple services**: Changing an import in one place may require rebuilds of many consumers. Mitigation: Phase 5 must be deployed as one unit across all affected services (authoring, exam-delivery, scoring, reporting); do not roll out a subset.
- **Companion lookup maintenance**: If someone adds a new task type to `PteTaskType`, they must also add it to the companion lookup or validation will fail silently. Mitigation: Add a TODO comment on the companion lookup saying "Keep in sync with PteTaskType enum"; do not automate (reflection-based lookups are fragile). Rely on code review to catch missing entries.
- **Enum constant name changes**: If the 23 constants are later renamed (e.g., `READ_ALOUD` → `SPEAK_ALOUD`), all consumers break at compile time. Mitigation: This is desired behavior (fail-fast); enum constants are part of the public API and should be stable.

---

## File Ownership

- `pte-common/src/main/java/com/pte/common/domain/enums/PteTaskType.java` — Phase 5 creates
- `pte-common/src/main/java/com/pte/common/domain/enums/PteSection.java` — Phase 5 creates
- `pte-api/services/authoring/src/main/java/com/pte/authoring/domain/enums/PteTaskType.java` — Phase 5 deprecates (or deletes)
- `pte-api/services/authoring/src/main/java/com/pte/authoring/domain/TaskTypeMetadataLookup.java` — Phase 5 creates
- All services (authoring, exam-delivery, scoring, reporting) — Phase 5 updates imports and builds
