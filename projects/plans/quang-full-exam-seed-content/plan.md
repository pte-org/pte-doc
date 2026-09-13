# Plan: Full PTE Dev Seed Content

**Date:** 2026-09-13  
**Status:** Phase 1-2 complete; live media upload remains deferred  
**Mode:** Hard  
**Scope:** `pte-api/services/authoring`, `pte-api/services/exam-delivery`, and `pte-app`

## Goal

Make a local authoring profile able to create one structurally valid question
for every one of the 23 PTE Academic/UKVI task types and publish them as one
ordered full-exam blueprint. This is development/demo content only; it does
not claim official Pearson content, timings, audio, images, or scoring
calibration.

## Phases

- [x] Phase 1: Data-driven full-exam seed runner and validation test
  [quality: approved; testing: passed]
- [x] Phase 2: Dev-only mock delivery API and app path override
  [quality: approved; testing: passed]

## Design Constraints

- The runner is active only under `seed-full-exam`; it must never run in the
  default or production profile.
- The fixture is classpath JSON so content edits do not require Java changes.
- Every fixture is passed through the existing `QuestionValidationHelper`
  before persistence, keeping the enum-declared required-field contract as the
  source of truth.
- Audio/image references are deterministic demo UUIDs. They are placeholders
  until matching media objects are uploaded by an E2E/media fixture workflow.
- The seed is idempotent by a stable blueprint name and publishes through the
  existing `SnapshotPublishService` path.
- No API contract, database migration, scoring rule, or production seed is
  changed.
- Mock delivery is opt-in under `mock-exam-delivery`; the app's default API
  base URL and attempt path remain unchanged.

## Success Criteria

- One classpath fixture contains exactly 23 unique task types.
- Every fixture passes current authoring validation.
- The generated blueprint contains all 23 items in PTE section order with
  matching section values and unique order indexes.
- Re-running with an existing sentinel blueprint performs no writes.
- `mvn -pl services/authoring -am clean test` passes for Phase 1.
- `mvn -pl services/exam-delivery -am test -q`, `flutter analyze`, and
  `flutter test` pass for Phase 2.
- Quality review has no blocker/high/current-change medium finding.
- The mock delivery contract returns the app-compatible envelope and serves
  only the two deterministic Repeat Sentence WAV fixtures.

## Quality and Testing State

- Quality gate: approved. See `quality/phase-01-full-exam-seed-content-quality-report.json`.
- Testing: passed. See `tests/phase-01-full-exam-seed-content-test-report.json`.
- Phase 2 quality gate: approved. See `quality/phase-02-mock-delivery-api-quality-report.json`.
- Phase 2 testing: passed. See `tests/phase-02-mock-delivery-api-test-report.json`.

## Local mock run

Start `pte-api/services/exam-delivery` with the `mock-exam-delivery` profile,
then compile the app with:

```text
flutter run -d chrome --target lib/main.dart --dart-define=DEV_SKIP_AUTH=true --dart-define=PTE_API_BASE_URL=http://localhost:8085 --dart-define=PTE_EXAM_ATTEMPTS_PATH=/api/exam-delivery/mock-attempts
```

The dev menu exposes **PTE API mock exam**. The route serves two Repeat
Sentence items, advances through both, and returns local WAV URLs.

## Explicitly Deferred

- Uploading real demo audio/image objects and wiring their public IDs.
- Running the mock route against a live multi-service stack with real auth,
  persistence and gateway routing.
- Production question-bank content, official timing verification, and AI
  provider calibration.
