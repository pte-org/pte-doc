# Phase 1 Contract Draft (for the other 3 devs to code against today)

**Status:** DRAFT — reviewed and owned by Senior 1 (Dev doing Phase 1). Committed to `pte-api` so it compiles; full migration + validation + service layer is still Senior 1's Phase 1 work in progress. Everyone else can start building against these shapes now; expect minor field renames before Phase 1 is fully merged.

**Files added/changed in `pte-api`** (under `src/main/java/com/aptis/modules/questionbank/domain/`):
- `enums/PteTaskType.java` — new enum, 20 scored item types + `PERSONAL_INTRODUCTION` (unscored).
- `enums/Skill.java` — extended from 6 to 10 values (added `ORAL_FLUENCY`, `PRONUNCIATION`, `SPELLING`, `WRITTEN_DISCOURSE`). Existing values unchanged, so nothing that reads `Skill.GRAMMAR` etc. breaks.
- **All 6 enums in the module (`DifficultyLevel`, `QuestionSource`, `QuestionStatus`, `QuestionType`, `Skill`, `PteTaskType`) now live under `domain/enums/`**, not directly in `domain/` — new team-wide convention, see `CODING_STANDARDS_API.md` ("Enum Placement"). If you're importing any of these, the package is `com.aptis.modules.questionbank.domain.enums.*`, not `...domain.*`.
- `PteTaskTypeSkillMapping.java` (stays in `domain/`, not an enum) — new static config class: `PteTaskTypeSkillMapping.skillsFor(PteTaskType)` returns the list of `Skill`s (with placeholder weight 1.0) that task type contributes to. **This is what Phase 4/5/6/7 call instead of reading a single `question.getSkill()` value.**
- `Question.java` — added fields (all additive, nothing removed):
  - `pteTaskType` (`PteTaskType`, nullable for now)
  - `referenceAnswerText` (`String`, TEXT column) — model/reference answer, passed to AI scoring as context
  - `minWordCount` / `maxWordCount` (`Integer`) — for Writing tasks
  - `skill` is now `@Deprecated` — don't set it for new PTE questions, don't read it for scoring. Kept only so archived APTIS rows still load.
  - **Already-existing fields you should reuse, not duplicate:** `part` (Integer), `prepTime` (Integer, seconds) = PTE prep-time, `timeLimit` (Integer, seconds) = PTE response-time, `maxPlayCount` (Integer) = audio replay limit for Listening tasks, `audioAssetId` (UUID) = audio prompt, `assetIds` (List\<UUID\>) = generic media (use for Describe Image's prompt image), `options` (List\<String\>) = MC/dropdown choices, `correctAnswers` (List\<String\>) = objective-task answer key, `questionType` (existing enum: `MULTIPLE_CHOICE`/`FILL_IN_BLANK`/`MATCHING`/`TEXT_INPUT`/`AUDIO_RECORD`/`ORDERING`) = **still valid**, describes the interaction pattern; keep setting it alongside `pteTaskType` (which describes the exam task itself).

---

## How to use the skill mapping (Phase 4/5/6/7)

```java
List<PteTaskTypeSkillMapping.SkillContribution> contributions =
        PteTaskTypeSkillMapping.skillsFor(question.getPteTaskType());

for (var contribution : contributions) {
    Skill skill = contribution.skill();
    float weight = contribution.weight(); // placeholder 1.0 for all — Phase 7 refines
    // ... apply this task's score to `skill`'s running total
}
```

## PteTaskType -> QuestionType (interaction pattern) reference

| PteTaskType | QuestionType | Scored by |
|---|---|---|
| PERSONAL_INTRODUCTION | AUDIO_RECORD | not scored |
| READ_ALOUD, REPEAT_SENTENCE, DESCRIBE_IMAGE, RETELL_LECTURE, ANSWER_SHORT_QUESTION | AUDIO_RECORD | Phase 4 (AI) |
| SUMMARIZE_WRITTEN_TEXT, WRITE_ESSAY | TEXT_INPUT | Phase 5 (AI) |
| READING_FILL_IN_THE_BLANKS, READING_WRITING_FILL_IN_THE_BLANKS, LISTENING_FILL_IN_THE_BLANKS | FILL_IN_BLANK | Phase 6 (rule-based) |
| MULTIPLE_CHOICE_READING_SINGLE_ANSWER, MULTIPLE_CHOICE_READING_MULTIPLE_ANSWER, MULTIPLE_CHOICE_LISTENING_SINGLE_ANSWER, MULTIPLE_CHOICE_LISTENING_MULTIPLE_ANSWER, HIGHLIGHT_CORRECT_SUMMARY, SELECT_MISSING_WORD | MULTIPLE_CHOICE | Phase 6 (rule-based) |
| RE_ORDER_PARAGRAPHS | ORDERING | Phase 6 (rule-based) |
| HIGHLIGHT_INCORRECT_WORDS | MATCHING (closest fit — student selects words within displayed text) | Phase 6 (rule-based) |
| SUMMARIZE_SPOKEN_TEXT | TEXT_INPUT | Phase 5 (AI, mirrors essay scoring) |
| WRITE_FROM_DICTATION | TEXT_INPUT | Phase 6 (rule-based fuzzy-match, per plan.md Phase 6 Step 3) |

---

## Open decisions Senior 1 still needs to make before Phase 1 is "done" (not blocking others from starting today)

1. **`skill` column is currently `nullable = false`** in the DB — but it's deprecated for PTE questions. Either relax the DB constraint to nullable, or have new PTE questions write some placeholder value. Doesn't block Mid/Senior 2 from coding against `pteTaskType` today.
2. **`HIGHLIGHT_INCORRECT_WORDS`** doesn't map cleanly to any existing `QuestionType` — flagged above as a stretch-fit on `MATCHING`. Confirm or add a new `QuestionType` value if this causes friction during Phase 6/8 implementation.
3. Actual Flyway migration script, `correct_answer` mandatory-field validation (per plan.md Phase 1 Step 6), and the legacy-APTIS-data archival script (Phase 1 Step 5) are not in this draft yet — those don't block others' compile-time contract, only the real DB migration.

---

## For Mid 2 (Phase 6 + Phase 8) and Mid 1 (Phase 5) specifically

You can start writing scoring/UI code against `Question.getPteTaskType()`, `getCorrectAnswers()`, `getOptions()`, `getPrepTime()`, `getTimeLimit()` today using hand-built mock `Question` objects in your tests — the entity shape above won't change in a breaking way, only gain a Flyway migration + validation behind it.
