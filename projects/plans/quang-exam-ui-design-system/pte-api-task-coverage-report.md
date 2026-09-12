# PTE Academic Task Coverage Report — `pte-api`

**Date:** 2026-09-12  
**Repository scanned:** `D:\GitHub\pte-org\pte-api`  
**Scope:** `services/**/src/main`, `services/**/src/test`, `pte-common`,
`gateway`  
**Excluded:** `target/**`, generated build output, PTE Core-specific format

## Executive summary

The backend has the complete PTE Academic/UKVI task taxonomy, but it does not
yet provide a complete operational exam. The largest gaps are in delivery
timing and scoring:

In this report, **P0 means a blocker for a complete/full-length exam or
release readiness**. It does not mean that the whole platform is unavailable:
section-scoped sessions can still run when their `includedTaskTypes` exclude
the affected types.

| Capability | Current result | Impact |
|---|---:|---|
| Task taxonomy | 23/23 enum values | No task name is missing from the domain enum |
| Authoring schema and required-field validation | 23/23 accepted by the enum-driven validator | Generic authoring path exists for every task |
| Task timing | 16/23 configured | **Full-length sessions including 7 Listening tasks can fail during snapshot pinning** |
| Delivery transport | Generic attempt/question/answer APIs | Payload transport is generic, not task-complete |
| Objective scoring | 5/22 scored task types | All 5 Reading types are covered |
| AI scoring route | 2/22 scored task types | Only `READ_ALOUD` and `WRITE_ESSAY`; both use deterministic stubs |
| Scored-task routing | 7/22 scored task types | **15 scored types remain `PENDING`** |
| Development seed data | 5/23 task types | Only the 5 Reading types have a dedicated seed runner |
| Task-specific release tests | Incomplete | No dedicated tests were found for the 7 missing-timing Listening types |

For the baseline, this report uses Pearson's current PTE Academic/UKVI
format: 9 scored Speaking & Writing question types plus the unscored Personal
Introduction, 5 Reading types and 8 Listening types. That is 23 backend task
types in total, of which 22 are scored. Pearson states that Personal
Introduction is for familiarization and does not contribute to the score. See
[Speaking & Writing](https://www.pearsonpte.com/pte-academic/test-format/speaking-writing/),
[Reading](https://www.pearsonpte.com/pte-academic/test-format/reading/) and
[Listening](https://www.pearsonpte.com/pte-academic/test-format/listening/).

## Immediate missing / incomplete work

### P0 — Full-length sessions are blocked by 7 Listening task types

The following task types are absent from
`services/exam-delivery/src/main/resources/config/task-timing.json`:

- `SUMMARIZE_SPOKEN_TEXT`
- `MC_LISTENING_MULTIPLE`
- `FILL_BLANKS_LISTENING`
- `HIGHLIGHT_CORRECT_SUMMARY`
- `SELECT_MISSING_WORD`
- `HIGHLIGHT_INCORRECT_WORDS`
- `WRITE_FROM_DICTATION`

`SnapshotPinService` filters `content.items()` by `includedTaskTypes` before it
calls `toPinnedItem()`. Inside `toPinnedItem()`, `TaskTimingConfig.timingFor()`
throws when a type is not configured. Therefore the gap is conditional: a
Reading/Speaking-only session, or any section-scoped session that excludes
these seven types, can still pin and run. A session configuration that includes
one of them fails during attempt snapshot pinning. This blocks assembling a
complete three-section/full-length exam; it is not a platform-wide outage.

The timing values currently in the file are also explicitly documented as
approximate placeholders. They must be verified against the authoritative
Pearson timing source before release.

Evidence:

- `services/exam-delivery/src/main/resources/config/task-timing.json:4-20`
- `services/exam-delivery/src/main/java/com/pte/examdelivery/config/TaskTimingConfig.java:34-38`
- `services/exam-delivery/src/main/java/com/pte/examdelivery/service/SnapshotPinService.java:101-114`

### P0 — Scoring is incomplete for 15 scored task types

`ObjectiveScoringService` supports only the 5 Reading types. `AiScoringDispatcher`
supports only `READ_ALOUD` and `WRITE_ESSAY`. The remaining scored types are
left untouched by `ScoringCommandConsumer`, so their rows stay `PENDING`.
`AttemptCompletionService` treats `PENDING` as non-terminal; consequently a
session containing one of these answers cannot reach fully-scored completion.

The 15 currently un-routed scored types are:

- Speaking: `REPEAT_SENTENCE`, `DESCRIBE_IMAGE`, `RE_TELL_LECTURE`,
  `ANSWER_SHORT_QUESTION`, `SUMMARIZE_GROUP_DISCUSSION`,
  `RESPOND_TO_A_SITUATION`
- Writing: `SUMMARIZE_WRITTEN_TEXT`
- Listening: `SUMMARIZE_SPOKEN_TEXT`, `MC_LISTENING_SINGLE`,
  `MC_LISTENING_MULTIPLE`, `FILL_BLANKS_LISTENING`,
  `HIGHLIGHT_CORRECT_SUMMARY`, `SELECT_MISSING_WORD`,
  `HIGHLIGHT_INCORRECT_WORDS`, `WRITE_FROM_DICTATION`

`PERSONAL_INTRODUCTION` is intentionally excluded from this count because it
is unscored by Pearson.

Evidence:

- `services/scoring/src/main/java/com/pte/scoring/service/ObjectiveScoringService.java:18-43`
- `services/scoring/src/main/java/com/pte/scoring/service/AiScoringDispatcher.java:32-44`
- `services/scoring/src/main/java/com/pte/scoring/messaging/consumer/ScoringCommandConsumer.java:92-100`
- `services/scoring/src/main/java/com/pte/scoring/service/AttemptCompletionService.java:24-40`

### P0 — Current AI scoring is a pipeline stub, not real PTE scoring

The two routed AI types are wired to:

- `StubSpeechScoringClient`: returns a fixed score of `65` and does not read
  or analyze audio.
- `StubEssayScoringClient`: returns a fixed score of `60` and does not call an
  LLM or scoring provider.

This is enough to exercise queue/status/event plumbing, but it cannot produce
valid candidate scores. A production-ready implementation still needs real
speech/ASR scoring for the speaking types, real writing evaluation for the
writing types, provider error handling and a verified score mapping.

Evidence:

- `services/scoring/src/main/java/com/pte/scoring/vendor/stub/StubSpeechScoringClient.java:10-32`
- `services/scoring/src/main/java/com/pte/scoring/vendor/stub/StubEssayScoringClient.java:10-33`
- `services/scoring/src/main/java/com/pte/scoring/messaging/consumer/AiScoringWorker.java:87-92`

### P0 — Listening payload contract is not frozen or verified end-to-end

The answer API accepts an opaque `payload`, which is appropriate for a shared
transport contract. However, the scoring review decoder explicitly documents
that the seven Listening types other than the first verified
`MC_LISTENING_SINGLE` path have no implemented/verified task-specific payload
encoding. They fall back to raw text or `UNRECOGNIZED` instead of a reliable
structured answer representation. This is the primary cross-layer contract
gap: FE cannot reliably serialize answers and BE cannot reliably score or
review them until the shapes are frozen.

This affects at least:

- `SUMMARIZE_SPOKEN_TEXT`
- `MC_LISTENING_MULTIPLE`
- `FILL_BLANKS_LISTENING`
- `HIGHLIGHT_CORRECT_SUMMARY`
- `SELECT_MISSING_WORD`
- `HIGHLIGHT_INCORRECT_WORDS`
- `WRITE_FROM_DICTATION`

The contracts need to be specified and tested for option selection, typed
blanks, token selection and positional word scoring before scoring/review is
considered complete.

Evidence:

- `services/exam-delivery/src/main/java/com/pte/examdelivery/dto/request/SubmitAnswerRequest.java:7-30`
- `services/scoring/src/main/java/com/pte/scoring/service/AnswerPayloadDecoder.java:27-38`
- `services/scoring/src/main/java/com/pte/scoring/dto/response/AnswerPayloadKind.java:4-19`

### P1 — Seed data covers only Reading

The only authoring seed runner is
`services/authoring/src/main/java/com/pte/authoring/seed/ReadingTaskSeedRunner.java`.
It creates the 5 Reading task types. There is no dedicated backend seed data
for the 8 Speaking types, 2 Writing types or 8 Listening types, so a complete
local PTE exam cannot be assembled from the existing dev seed alone.

Missing dedicated seed coverage: **18 task types**.

This is a development/content readiness gap, not a domain-schema gap. The
authoring endpoint can accept the types through `PteTaskType` and the generic
request model.

Evidence:

- `services/authoring/src/main/java/com/pte/authoring/seed/ReadingTaskSeedRunner.java:26-27`
- `services/authoring/src/main/java/com/pte/authoring/seed/ReadingTaskSeedRunner.java:100-168`
- `services/authoring/src/main/java/com/pte/authoring/dto/request/CreateQuestionRequest.java:10-23`

## Full task matrix

Legend: `✅` present in the scanned layer; `⚠️` present but partial or stubbed;
`❌` missing/blocking; `N/A` intentionally not applicable.

### Part 1 — Speaking & Writing

| Official task | Backend enum/authoring | Timing | Delivery | Scoring | Overall |
|---|---:|---:|---:|---:|---|
| Personal Introduction | ✅ | ✅ | ✅ | N/A — unscored | Partial: no dedicated seed/test |
| Read Aloud | ✅ | ✅ | ✅ | ⚠️ AI route, fixed stub | Partial |
| Repeat Sentence | ✅ | ✅ | ✅ | ❌ not routed | Incomplete |
| Describe Image | ✅ | ✅ | ✅ | ❌ not routed | Incomplete |
| Retell Lecture | ✅ (`RE_TELL_LECTURE`) | ✅ | ✅ | ❌ not routed | Incomplete |
| Answer Short Question | ✅ | ✅ | ✅ | ❌ not routed | Incomplete |
| Summarize Group Discussion | ✅ | ✅ | ✅ | ❌ not routed | Incomplete |
| Respond to a Situation | ✅ | ✅ | ✅ | ❌ not routed | Incomplete |
| Summarize Written Text | ✅ | ✅ | ✅ | ❌ not routed | Incomplete |
| Write Essay | ✅ | ✅ | ✅ | ⚠️ AI route, fixed stub | Partial |

### Part 2 — Reading

| Official task | Backend enum/authoring | Timing | Delivery | Scoring | Seed |
|---|---:|---:|---:|---:|---:|
| Fill in the Blanks (Dropdown) | ✅ | ✅ | ✅ | ✅ objective | ✅ |
| Multiple Choice, Multiple Answers | ✅ | ✅ | ✅ | ✅ objective | ✅ |
| Reorder Paragraph | ✅ | ✅ | ✅ | ✅ objective | ✅ |
| Fill in the Blanks (Drag and Drop) | ✅ | ✅ | ✅ | ✅ objective | ✅ |
| Multiple Choice, Single Answer | ✅ | ✅ | ✅ | ✅ objective | ✅ |

The backend uses the names `FILL_BLANKS_READING_WRITING` for the dropdown
variant and `FILL_BLANKS_READING` for the drag-and-drop variant.

### Part 3 — Listening

| Official task | Backend enum/authoring | Timing | Delivery | Scoring | Overall |
|---|---:|---:|---:|---:|---|
| Summarize Spoken Text | ✅ | ❌ | ❌ blocked at pin | ❌ not routed | Blocked |
| Multiple Choice, Multiple Answers | ✅ | ❌ | ❌ blocked at pin | ❌ not routed | Blocked |
| Fill in the Blanks (Type In) | ✅ | ❌ | ❌ blocked at pin | ❌ not routed | Blocked |
| Highlight Correct Summary | ✅ | ❌ | ❌ blocked at pin | ❌ not routed | Blocked |
| Multiple Choice, Single Answer | ✅ | ✅ | ✅ | ❌ not routed | Incomplete |
| Select Missing Word | ✅ | ❌ | ❌ blocked at pin | ❌ not routed | Blocked |
| Highlight Incorrect Words | ✅ | ❌ | ❌ blocked at pin | ❌ not routed | Blocked |
| Write from Dictation | ✅ | ❌ | ❌ blocked at pin | ❌ not routed | Blocked |

## What is already sufficient

The following backend foundations are not missing:

1. `PteTaskType` declares all 23 PTE Academic/UKVI task types, including the
   unscored `PERSONAL_INTRODUCTION`.
2. `QuestionValidationHelper` derives required fields from the enum flags,
   rather than having a separate hard-coded validator for each task.
3. Authoring and reporting both contain skill mappings for all 22 scored task
   types. Personal Introduction is intentionally absent from score mappings.
4. `SnapshotContentResponse`, `PinnedItem`, `PinnedItemView` and `TaskView`
   carry the generic prompt, audio, image, reference-answer, word-count,
   option and blank-group fields needed by the frontend families.
5. The endpoint surface is intentionally generic: question CRUD, snapshot
   publish/content, attempt start/next-task, answer submit and audio playback.
   Separate endpoints per task type are not required.

## Recommended implementation order

1. **Freeze the payload contract for the seven Listening types.** Specify and
   version the exact representation for multiple selections, typed blanks,
   highlighted tokens, missing-word choices and dictation text. Add contract
   tests that can be shared by FE serialization and BE decoding/scoring.
2. **Add timing for the seven Listening types.** Add a parameterized guard (for
   example, `EnumSource(PteTaskType.class)`) asserting that `timingFor()` does
   not throw for any enum value. This removes the full-length pinning blocker
   and prevents the gap from recurring when a new task type is added.
3. **Run FE and BE work in parallel after step 1:**
   - FE continues the Token → Component → Template refactor and implements
     `option-select`, `typed-blanks`, `token-selection` and related templates
     against the frozen contract.
   - BE adds scoring routes for the 15 currently un-routed scored types,
     selecting objective or AI strategy and verified partial-credit rules per
     task.
4. **Replace the AI stubs with provider adapters.** Keep this separate from
   the transactional answer API. Speech scoring needs a safe media-byte or
   download path; writing scoring needs a real provider/rubric mapping.
5. Add complete dev seed/fixture content and task-specific integration tests
   for all 23 types. The full-length backend readiness gate is reached after
   the contract, timing, scoring and fixture/test work are all verified.

## Scan limitations

- This is a source/config scan; no live exam was started against deployed
  services and no real media/provider scoring was invoked.
- Values in `task-timing.json` are marked by the repository itself as
  approximate and still require official-source verification.
- PTE Academic/UKVI is the scope. PTE Core has a different Speaking & Writing
  task set and should be audited separately if it becomes a product target.
