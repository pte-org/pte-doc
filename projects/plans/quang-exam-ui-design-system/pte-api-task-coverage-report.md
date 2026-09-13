# PTE Academic Task Coverage Report — `pte-api`

**Date:** 2026-09-12  
**Repository scanned:** `D:\GitHub\pte-org\pte-api`  
**Scope:** `services/**/src/main`, `services/**/src/test`, `pte-common`,
`gateway`  
**Excluded:** `target/**`, generated build output, PTE Core-specific format

## Executive summary

The backend has the complete PTE Academic/UKVI task taxonomy, but it does not
yet provide a complete production-ready exam. The remaining gaps are
production timing verification, production-valid AI scoring, and complete
fixtures/seeds:

In this report, **P0 means a blocker for a complete/full-length exam or
release readiness**. It does not mean that the whole platform is unavailable:
section-scoped sessions can still run when their `includedTaskTypes` exclude
the affected types.

| Capability | Current result | Impact |
|---|---:|---|
| Task taxonomy | 23/23 enum values | No task name is missing from the domain enum |
| Authoring schema and required-field validation | 23/23 accepted by the enum-driven validator | Generic authoring path exists for every task |
| Task timing | 23/23 configured | **All task types have config; 7 Listening values remain non-production placeholders** |
| Delivery transport | Generic attempt/question/answer APIs | Payload transport is generic, not task-complete |
| Objective scoring | 12/22 scored task types | All 5 Reading types and all 7 deterministic Listening types are covered |
| AI scoring route | 10/22 scored task types | All 10 AI-shaped types route through RabbitMQ; provider adapters are opt-in and calibration is pending |
| Scored-task routing | 22/22 scored task types | All scored types have a route; AI output remains non-production |
| Development seed data | 23/23 task types | Opt-in full-exam seed runner covers every task type with validated demo content; media refs remain placeholders |
| Task-specific release tests | Improved | Deterministic scoring and AI route boundaries are covered; full fixtures/provider tests remain |

For the baseline, this report uses Pearson's current PTE Academic/UKVI
format: 9 scored Speaking & Writing question types plus the unscored Personal
Introduction, 5 Reading types and 8 Listening types. That is 23 backend task
types in total, of which 22 are scored. Pearson states that Personal
Introduction is for familiarization and does not contribute to the score. See
[Speaking & Writing](https://www.pearsonpte.com/pte-academic/test-format/speaking-writing/),
[Reading](https://www.pearsonpte.com/pte-academic/test-format/reading/) and
[Listening](https://www.pearsonpte.com/pte-academic/test-format/listening/).

## Immediate missing / incomplete work

### Resolved — Listening timing coverage (placeholder values)


All 23 task types now have entries in
`services/exam-delivery/src/main/resources/config/task-timing.json`, so the
conditional `SnapshotPinService` failure caused by a missing `timingFor()`
entry is removed. The seven Listening values are explicitly marked
non-production placeholders and still require authoritative timing-source
verification before release.



Evidence:

- `services/exam-delivery/src/main/resources/config/task-timing.json:4-20`
- `services/exam-delivery/src/main/java/com/pte/examdelivery/config/TaskTimingConfig.java:34-38`
- `services/exam-delivery/src/main/java/com/pte/examdelivery/service/SnapshotPinService.java:101-114`

### Resolved — Scored-task routing covers all 22 scored types

`ObjectiveScoringService` covers 12 deterministic types and the centralized
`AiScoringTaskCatalog`/`AiScoringDispatcher` covers the remaining 10 AI-shaped
types. `ScoringCommandConsumer` therefore has a routing path for all 22 scored
types; none is left untouched solely because its task type is unknown to the
current scoring layer. AI routing is not equivalent to production-valid
scoring: those clients remain deterministic stubs until the provider phase.

`PERSONAL_INTRODUCTION` is intentionally excluded from this count because it
is unscored by Pearson.

Evidence:

- `services/scoring/src/main/java/com/pte/scoring/service/ObjectiveScoringService.java:18-43`
- `services/scoring/src/main/java/com/pte/scoring/service/AiScoringTaskCatalog.java:1-42`
- `services/scoring/src/main/java/com/pte/scoring/service/AiScoringDispatcher.java:32-51`
- `services/scoring/src/main/java/com/pte/scoring/messaging/consumer/ScoringCommandConsumer.java:92-100`
- `services/scoring/src/main/java/com/pte/scoring/service/AttemptCompletionService.java:24-40`

### P0 — Current AI scoring is a pipeline stub, not real PTE scoring

All ten routed AI types are wired to a provider boundary:

- `StubSpeechScoringClient`: used for seven speech-shaped tasks, returns a
  fixed score of `65` and does not read or analyze audio.
- `StubEssayScoringClient`: used for three text-shaped tasks in the default
  mode, returns a fixed score of `60` and does not call an LLM or scoring provider.

The opt-in `openai-compatible` adapters now send authenticated text/audio
requests and reject malformed/out-of-range results. This is still not valid
PTE scoring without provider selection, calibration, rate/cost controls and a
verified score mapping.

Evidence:

- `services/scoring/src/main/java/com/pte/scoring/vendor/stub/StubSpeechScoringClient.java:10-32`
- `services/scoring/src/main/java/com/pte/scoring/vendor/stub/StubEssayScoringClient.java:10-33`
- `services/scoring/src/main/java/com/pte/scoring/vendor/openai/OpenAiCompatibleEssayScoringClient.java:1-60`
- `services/scoring/src/main/java/com/pte/scoring/vendor/openai/OpenAiCompatibleSpeechScoringClient.java:1-100`
- `services/scoring/src/main/java/com/pte/scoring/messaging/consumer/AiScoringWorker.java:87-92`

### Resolved — Listening payload contract and timing unblock

The answer API keeps `payload` opaque, while the cross-repo contract is now
frozen and tested in `pte-doc`, `pte-app`, and `pte-api`. The scoring review
decoder now has explicit structured representations for typed gap values and
highlighted transcript indices. The seven Listening timing entries are also
present as clearly marked non-production placeholders, so a complete
Listening configuration no longer fails only because `timingFor()` is missing.

The deterministic/AI routing gap is resolved for the known 22 scored types.
`SUMMARIZE_SPOKEN_TEXT` now has an AI route through the text stub; production
spoken-summary scoring remains separate provider work.

Option-based Listening scoring is implemented through the existing objective
scorer for `MC_LISTENING_SINGLE`, `MC_LISTENING_MULTIPLE`,
`HIGHLIGHT_CORRECT_SUMMARY`, and `SELECT_MISSING_WORD`; typed blanks, token
selection, and dictation partial credit are now implemented as reference-based
objective scoring. Spoken-summary AI scoring remains separate work.

Evidence:

- `services/exam-delivery/src/main/java/com/pte/examdelivery/dto/request/SubmitAnswerRequest.java:7-30`
- `services/scoring/src/main/java/com/pte/scoring/service/AnswerPayloadDecoder.java:27-38`
- `services/scoring/src/main/java/com/pte/scoring/dto/response/AnswerPayloadKind.java:4-19`

### Resolved — Full-exam development seed coverage

`FullExamTaskSeedRunner` now loads a classpath fixture containing one question
for each of the 23 task types, validates every question through the existing
enum-driven `QuestionValidationHelper`, composes the questions in PTE section
order, and publishes one full-exam blueprint. It is idempotent by a stable
blueprint sentinel and runs only under the opt-in `seed-full-exam` profile.

The fixture uses generic demo content and deterministic placeholder audio/image
UUIDs. It provides authoring/snapshot structure for local UI and delivery work,
but does not upload media or claim production question-bank content.

This remains a development/content fixture, not a domain-schema change.

Evidence:

- `services/authoring/src/main/java/com/pte/authoring/seed/FullExamTaskSeedRunner.java:1-191`
- `services/authoring/src/main/resources/seed/full-exam-task-fixtures.json:1-268`
- `services/authoring/src/test/java/com/pte/authoring/seed/FullExamTaskSeedRunnerTest.java:1-150`
- `services/authoring/src/main/java/com/pte/authoring/service/QuestionValidationHelper.java:35-53`

## Baseline task matrix (pre follow-up)

The matrix below is the original scan captured before the contract, timing,
deterministic-scoring and AI-route follow-ups. Use the current implementation
delta and executive summary above for the post-phase status.

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

## Current implementation delta (2026-09-12)

The original Listening matrix above was captured before the contract/timing
follow-up and the deterministic scoring slices. Current status is:

| Listening type | Timing/delivery | Scoring |
|---|---|---|
| `MC_LISTENING_SINGLE` | Unblocked | Objective complete |
| `MC_LISTENING_MULTIPLE` | Unblocked* | Objective complete |
| `HIGHLIGHT_CORRECT_SUMMARY` | Unblocked* | Objective complete |
| `SELECT_MISSING_WORD` | Unblocked* | Objective complete |
| `SUMMARIZE_SPOKEN_TEXT` | Unblocked* | AI route stub; provider pending |
| `FILL_BLANKS_LISTENING` | Unblocked* | Objective complete |
| `HIGHLIGHT_INCORRECT_WORDS` | Unblocked* | Objective complete |
| `WRITE_FROM_DICTATION` | Unblocked* | Objective complete; partial credit |

`*` Unblocked by the contract/timing follow-up, but the seven new timing
values remain explicitly non-production placeholders.

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

1. **Completed — freeze the payload contract for the seven Listening types.** Specify and
   version the exact representation for multiple selections, typed blanks,
   highlighted tokens, missing-word choices and dictation text. Add contract
   tests that can be shared by FE serialization and BE decoding/scoring.
2. **Completed for demo — add timing for the seven Listening types.** Add the seven entries as
   explicitly non-production placeholders and add a parameterized guard for
   those seven values asserting that `timingFor()` does not throw. Once a
   shared `PteTaskType` catalog exists in `pte-common`, upgrade that guard to
   `EnumSource(PteTaskType.class)` for all 23 values; do not make the larger
   vocabulary move a prerequisite for the immediate pinning fix. This removes
   the conditional missing-timing pinning blocker and prevents the known gap from recurring. Production timing verification remains.
3. **Continue FE and BE work in parallel against the frozen contract:**
   - FE continues the Token → Component → Template refactor and implements
     `option-select`, `typed-blanks`, `token-selection` and related templates
     against the frozen contract.
   - BE route coverage is complete for all 22 scored types. The next BE
     scoring step is replacing the ten deterministic AI stubs with provider
     adapters and verified rubric/score mappings.
4. **Completed — deterministic Listening objective scoring.** All seven
   deterministic Listening types are now routed through
   `ObjectiveScoringService` with reference-contract and regression tests.
5. **Next — configure and validate the provider adapters.** Keep this separate
   from the transactional answer API. The OpenAI-compatible text/audio
   boundary now exists behind `SCORING_AI_PROVIDER=openai-compatible`; speech
   calibration, provider reliability and verified rubric mappings remain.
6. **Completed for structural demo coverage — add full dev seed/fixture content.**
   `seed-full-exam` now creates one validated question per type and publishes
   an ordered 23-item blueprint. Media-backed E2E execution and task-specific
   integration tests against a live stack remain separate verification work.

## Scan limitations

- This is a source/config scan; no live exam was started against deployed
  services and no real media/provider scoring was invoked.
- Values in `task-timing.json` are marked by the repository itself as
  approximate and still require official-source verification.
- PTE Academic/UKVI is the scope. PTE Core has a different Speaking & Writing
  task set and should be audited separately if it becomes a product target.
