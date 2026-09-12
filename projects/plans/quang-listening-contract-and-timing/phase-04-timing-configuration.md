# Phase 4: 7 Listening Task Timing Entries

**Covers:** FR-04 · Timing configuration for unconfigured Listening types
**Depends on:** nothing — can run in parallel with Phases 1-3

---

## Requirements

Add seven new entries to `pte-api/services/exam-delivery/src/main/resources/config/task-timing.json` for the unconfigured Listening task types: SUMMARIZE_SPOKEN_TEXT, MC_LISTENING_MULTIPLE, FILL_BLANKS_LISTENING, HIGHLIGHT_CORRECT_SUMMARY, SELECT_MISSING_WORD, HIGHLIGHT_INCORRECT_WORDS, WRITE_FROM_DICTATION. Each entry must include integer `prepSeconds` and `responseSeconds` values marked as NON-PRODUCTION PLACEHOLDERS in the file's `_comment` field. The immediate purpose is only to remove `TaskTimingNotConfiguredException` during snapshot pinning; this phase must not claim that the resulting values are valid PTE timing or that full-length delivery is production-ready. Audio-duration ranges may be recorded as research context, but must not be presented as a reliable derivation of prep/response windows.

---

## Design Constraints

- All seven new timing entries must respect the existing config file's format and conventions: JSON object with `prepSeconds` and `responseSeconds` integers (no optional fields like `preListenSeconds`/`preRecordSeconds` for now, unlike the 5 audio-prompt Speaking types which have those fields).
- The `_comment` field (file-level) must be expanded to include explicit statements like "SUMMARIZE_SPOKEN_TEXT: temporary 600s placeholder (confidence SECONDARY — not an official production value)"; "MC_LISTENING_MULTIPLE: temporary placeholder — audio range is context only"; "HIGHLIGHT_INCORRECT_WORDS: temporary placeholder — audio range is context only"; etc.
- Every new timing value must be marked in the comment as "unsourced/placeholder" or "secondary confidence" (no "official" or "verified" labels — they are not yet vetted).
- The file's `_comment` must include a note that TaskTimingConfig.timingFor() will throw TaskTimingNotConfiguredException if an entry is missing, so unconfigured types cannot be used in sessions until entries are added; this phase closes that gap for the 7 types.
- Do NOT add any phase-specific comment fields (e.g., `"_phase4_notes"`); keep the format identical to existing entries.

---

## Steps

1. Review the available research findings and record the audio-duration ranges as context only. Do not derive a prep/response split from an audio range as though it were an official timing rule. The exact response windows remain a separate product/research decision.

2. For each of the 7 types, choose temporary values explicitly labeled for demo/pinning only. Keep the values configurable and document the source, uncertainty and intended non-production scope; do not use generosity as a substitute for verified exam timing.

3. Expand the file's `_comment` field to include a section for each unconfigured type, recording: (a) the audio-duration range or time estimate from research as context, (b) the chosen temporary prep/response values, (c) "unsourced/placeholder — pending official Pearson materials," and (d) a note that these values will be used only for session pinning/demo starting from this phase and must be reviewed before production release.

4. Add the seven new entries to the `timings` object in task-timing.json, one per type, with the chosen temporary `prepSeconds` and `responseSeconds` values; order them by section (Listening types grouped together) for readability, though the order doesn't affect functionality.

5. Add a top-level note in `_comment` that reads: "The 7 Listening types added in Phase 4 (plans/quang-listening-contract-and-timing, 2026-09-12) are TEMPORARY NON-PRODUCTION PLACEHOLDERS. They only prevent missing-config failures during snapshot pinning. Do NOT ship to production until timing semantics and values are verified."

6. Extend `pte-api/services/exam-delivery/src/test/java/com/pte/examdelivery/config/TaskTimingConfigTest.java` with a `@ParameterizedTest` and `@ValueSource(strings = { ... })` covering exactly the 7 newly configured Listening task types. Assert `config.timingFor(taskType)` does not throw; do not assert that placeholder values are correct PTE timing.

7. Verify the JSON is syntactically valid (parse it with a JSON tool); ensure all 23 task types (16 existing + 7 new) are present and have `prepSeconds`/`responseSeconds` values; no missing commas or trailing commas.

---

## Success Criteria

- `task-timing.json` has 23 entries total (16 existing + 7 new, all 7 Listening types now configured).
- Each new entry has `prepSeconds` and `responseSeconds` integer values (no null or string values).
- The file's `_comment` field explicitly labels all 7 new entries as "unsourced/placeholder" with the audio-duration basis recorded.
- JSON is valid (no parsing errors when TaskTimingConfig loads it).
- TaskTimingConfig.timingFor() does not throw for any of the 7 new types, and the focused parameterized guard fails clearly if one is removed. A future shared-task-catalog phase may extend this guard to all 23 values.

---

## Quality and Testing State

- Quality gate: **approved**, 0 blocking findings and 1 NOTED release-risk: the seven timing values remain non-production placeholders. Cryptographic receipt skipped because reviewed files live in the separate `pte-api` repository while the plan/report lives in `pte-doc`. Report: `quality/phase-04-timing-configuration-quality-report.json`.
- Testing: **passed**, 122/122 full exam-delivery reactor tests passed (24 `pte-common` + 98 `exam-delivery`), including the 10/10 focused timing guard and 23-entry JSON validation. Report: `tests/phase-04-timing-configuration-test-report.json`.

---

## Risks

- **Timing values are placeholders, not exam timing**: Without official Pearson materials, the values could be materially wrong. Mitigation: this phase only unblocks pinning, marks every entry NON-PRODUCTION, and keeps timing verification as a release gate.
- **Audio-duration ranges don't directly translate to prep/response splits**: An audio range does not tell us the correct response window. Mitigation: keep the values explicitly non-production and do not infer release timing from these placeholders.
- **SUMMARIZE_SPOKEN_TEXT budget is secondary confidence**: Any per-item value must remain non-production until verified. No section-scoped Listening timer is implemented in this plan.

---

## File Ownership

- `pte-api/services/exam-delivery/src/main/resources/config/task-timing.json` — Phase 4 owns all 7 new entries (read-only for later phases)
- `pte-api/services/exam-delivery/src/test/java/com/pte/examdelivery/config/TaskTimingConfigTest.java` — Phase 4 adds the focused seven-type guard
