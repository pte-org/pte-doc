# Plan: Listening Payload Contract & Timing Configuration

**Date:** 2026-09-12
**Status:** Completed (active scope; deferred follow-ups remain)
**Mode:** Hard
**Test:** Default (no --tdd)
**Created by:** Plan Agent

---

## Overview

This plan closes two cross-layer gaps preventing the 7 unconfigured PTE Listening task types (SUMMARIZE_SPOKEN_TEXT, MC_LISTENING_MULTIPLE, FILL_BLANKS_LISTENING, HIGHLIGHT_CORRECT_SUMMARY, SELECT_MISSING_WORD, HIGHLIGHT_INCORRECT_WORDS, WRITE_FROM_DICTATION) from being used in a complete/full-length exam: the payload contract is not frozen and timing entries are missing. It delivers a ratified payload contract with vendored JSON fixtures and encoder/decoder tests, extends `AnswerPayloadDecoder` for the two structured payload shapes that need explicit review decoding, and configures seven clearly marked timing placeholders to remove the snapshot-pinning exception. It intentionally does not include scoring-route implementation, real AI providers, the cross-service `PteTaskType` move, or a new section-scoped Listening timer; those are separate follow-up work and must not block FE interaction templates or this contract/timing unblock.

## Phases

- [x] Phase 1: Contract Ratification & Shared Fixture [quality: approved; testing: passed] — Document the payload encoding contract for all 8 Listening types in markdown and JSON; create fixture JSON with contractVersion field, recording FE encoding, optionsJson presence, and trailing-empty semantics as normative; update `SubmitAnswerRequest` javadoc in exam-delivery to document all 8 Listening encodings.
- [x] Phase 2: Cross-Repo Fixture & Encoder Tests [quality: approved; testing: passed] — Vendor the fixture into pte-app and pte-api; test the actual FE serializers and fixture schema/version. Decoder output assertions belong to Phase 3, after the new response shapes exist.
- [x] Phase 3: AnswerPayloadDecoder Enhancements [quality: approved; testing: passed] — Add new `AnswerPayloadKind` values POSITIONAL_SELECTION and WORD_INDICES with correctly typed nullable fields on `DecodedAnswerPayload`; extend decoder to recognize FILL_BLANKS_LISTENING and HIGHLIGHT_INCORRECT_WORDS; add decoder fixture assertions; audit all construction sites and update javadocs.
- [x] Phase 4: 7 Listening Task Timing Entries [quality: approved; testing: passed] — Add task-timing.json entries for the 7 unconfigured types as explicitly non-production placeholders; add a focused parameterized guard for the seven new values and record that placeholder correctness is not verified.

**Deferred follow-up (not part of this cook order):** shared `PteTaskType`
vocabulary consolidation and a section-scoped Listening timer model. The
former is an architectural refactor; the latter changes timer semantics and
requires a separately verified product/timing decision.

## Research Summary

**Official timing (Researcher A — negative result, key input):** Pearson's public test-format page documents only audio-duration ranges per Listening task type, not per-item prep/response windows. No official per-item `responseSeconds` found for 6 of 7 types; SUMMARIZE_SPOKEN_TEXT is stated as 10 minutes per item (confidence SECONDARY, not in official handbook). Existing `MC_LISTENING_SINGLE: {prepSeconds: 0, responseSeconds: 20}` is itself an unsourced placeholder (inline comment already states this in task-timing.json).

**Deferred timing-model finding (Researcher team + direct code reading):** A
future Listening timer may need to distinguish SUMMARIZE_SPOKEN_TEXT from the
other Listening items, but the current source/config scan does not make a new
section-scoped timer part of this unblock. Adding LISTENING to
`SECTION_SCOPED_SECTIONS` would change runtime semantics and must be separately
validated before implementation. `sectionBudgetSeconds()` currently filters
all items matching the section without contiguity verification; that is a
separate follow-up concern.

**Cross-repo fixture handling (Researcher B + coordinator decision):** Payload is an opaque `String` inside a JSON field, so literal fixture vectors express comma-joined positional syntax and trailing-empty semantics without each repo's test author reinterpreting them. Repos have no shared CI pipeline; silent drift is the primary risk. Mitigation: vendor the fixture into both repos with a `contractVersion` field and add explicit sync/hash checking where possible. A version check alone does not prove byte identity when content changes without a version bump.

**Deferred vocabulary consolidation:** Task-type strings are repeated today
(authoring enum, scoring constants and exam-delivery JSON keys). Consolidating
them in `pte-common` remains desirable, but it is not required to freeze the
Listening payload or add the seven timing entries and therefore is not on this
plan's critical path.

## Dependencies

- Existing `pte-app/lib/features/exam_attempt/domain/positional_payload.dart` (shared FE positional encoder, source to verify; may be changed only if the ratified delimiter policy requires it).
- Existing `pte-app/lib/features/exam_attempt/listening/presentation/cubit/` (7 listening task cubits, FE source of truth for encoders).
- Existing `pte-api/services/exam-delivery/src/main/resources/config/task-timing.json` (target for 7 new entries).
- Existing `pte-api/services/exam-delivery/src/main/java/com/pte/examdelivery/config/TaskTimingConfig.java` (source of truth for timing, target for verification test).
- Existing `pte-api/services/exam-delivery/src/main/java/com/pte/examdelivery/dto/request/SubmitAnswerRequest.java` (target for Listening payload documentation).
- Existing `pte-api/services/scoring/src/main/java/com/pte/scoring/service/AnswerPayloadDecoder.java` (target for decoder enhancements).
- Existing `pte-api/services/scoring/src/main/java/com/pte/scoring/dto/response/AnswerPayloadKind.java` (target for new enum values).
- Existing `pte-api/services/scoring/src/main/java/com/pte/scoring/dto/response/DecodedAnswerPayload.java` (target for new nullable fields).

## Risks

- **HIGH: Every timing value is a placeholder.** This plan does not achieve release-ready timing; it only removes the missing-config exception for pinning. Existing `MC_LISTENING_SINGLE` values are themselves unsourced placeholders; Phase 4 adds 7 more in the same style. Values must be reviewed against real Pearson materials before production release. Mitigation: document every entry as NON-PRODUCTION/PLACEHOLDER in the file comment; Quang owns verification against official Pearson source, with no fixed deadline.

- **HIGH: Timing placeholders are not production timing.** Adding entries only removes the missing-config exception; it does not validate exact PTE windows or section semantics. Mitigation: mark entries non-production and keep official timing verification as a release gate.

- **MEDIUM: Cross-repo fixture staleness (with version guard).** Repos have no shared CI pipeline. Dart test in pte-app could pass on stale fixture; Java test in pte-api could be skipped; contract drifts silently if only the payload string changes while version stays same. Mitigation: fixture carries `contractVersion` field; each repo's constant is independent; a string-only edit without version bump causes one repo's test to fail when they drift (loud failure, not silent). Accepts the limitation: this catches *versioned* changes, not hand-edited strings, so manual code review discipline is still required.

- **MEDIUM: Shared fixture drift.** `contractVersion` alone cannot detect a same-version content edit. Mitigation: add a hash or repository sync check, and review all three copies when changing the contract.

- **MEDIUM: Positional text delimiter ambiguity.** The current FE helper joins free-text gap values with commas. Phase 1 must explicitly decide whether commas are escaped, forbidden or encoded before ratifying the contract; the fixture must not silently bless an ambiguous wire format.

---

## Cook Order Recommendation

1. Phase 1: ratify the exact eight Listening payload encodings, correct the
   `MC_LISTENING_SINGLE` and typed-gap examples, resolve delimiter policy, and
   create the canonical fixture plus API documentation.
2. Phase 2: vendor the fixture and test the actual pure FE serializers. This
   phase may run in parallel with Phase 4 after the contract is ratified.
3. Phase 3: implement and test the two explicit review-decoder shapes using
   the frozen contract. Decoder assertions belong here, after the new response
   fields exist.
4. Phase 4: add the seven timing placeholders and the focused seven-value
   guard. This only removes the pinning exception; it is not a production
   timing approval.

After Phase 1, FE can implement interaction templates in parallel with BE
decoder/scoring work. Real scoring routes and provider adapters are separate
workstreams. Do not cook the deferred enum-consolidation or section-timer
files as part of this plan.

Suggested invocation:

```
/ck:cook pte-doc/projects/plans/quang-listening-contract-and-timing/phase-01-contract-and-fixture.md
/ck:cook pte-doc/projects/plans/quang-listening-contract-and-timing/phase-02-fixture-tests.md
/ck:cook pte-doc/projects/plans/quang-listening-contract-and-timing/phase-03-decoder-enhancements.md
/ck:cook pte-doc/projects/plans/quang-listening-contract-and-timing/phase-04-timing-configuration.md
```

---
