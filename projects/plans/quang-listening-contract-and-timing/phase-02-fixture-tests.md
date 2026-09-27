# Phase 2: Cross-Repo Fixture & Encoder Tests

**Covers:** FR-02 · Fixture consumption and FE encoder contract checks in Dart and Java with contractVersion checking
**Depends on:** Phase 1 (fixture file must exist in pte-doc)

---

## Requirements

Vendor a copy of the Phase 1 fixture JSON into each repo (pte-app and pte-api); both copies must be byte-identical to the pte-doc original. Implement a Dart test in pte-app that asserts the pure answer serializers produce each fixture's canonical `payload` string and that the fixture's `contractVersion` matches a declared constant. Implement a Java fixture-schema/version test in pte-api/scoring. Decoder output assertions for `POSITIONAL_SELECTION` and `WORD_INDICES` belong to Phase 3, after those response shapes exist. Tests must fail obviously if the fixture is missing or the version mismatches (no silent skip).

---

## Design Constraints

- Each repo vendors its own fixture copy (pte-app's and pte-api's are separate files, not symlinks or includes); the fixture lives in that repo's own test resources directory.
- The fixture JSON carries a top-level `contractVersion: 1` field; each repo's test declares a constant `EXPECTED_CONTRACT_VERSION = 1`; the test asserts `fixture.contractVersion == EXPECTED_CONTRACT_VERSION` before consuming fixture data.
- When the contract changes, the process is: (1) update pte-doc's canonical fixture and bump its contractVersion to 2, (2) update both pte-app's and pte-api's vendored copies and bump their constants to 2. A version check catches a repo receiving a new fixture without its test constant, but it cannot detect a stale vendored copy that remains internally consistent; use an explicit copy/hash check or review process for that case.
- Both tests must validate the fixture file's JSON schema (check that all required fields exist) before using it; if a field is missing, the test must fail with a clear error.
- The Dart test must use pte-app's actual pure answer encoders (including `positional_payload.dart`) to generate payloads, not hardcode the expected values; if a Cubit currently combines serialization with outbox/audio side effects, extract a pure serializer first and make the Cubit call it.
- The extracted pte-app helper is `pte-app/lib/features/exam_attempt/domain/listening_payload.dart`; the Listening gap input applies the v1 comma restriction at `pte-app/lib/features/exam_attempt/listening/presentation/widgets/fill_blanks_input_widget.dart` before calling the serializer.
- The Phase 2 Java test validates fixture schema/version only. The Java test that calls `AnswerPayloadDecoder` and asserts the new kinds is owned by Phase 3, so this plan does not require production decoder support before Phase 3.
- Neither test should assert on the fixture file's `description` field (that's for documentation, not executable contract); description changes should never break tests.
- Fixture vectors are plaintext (matching the `AnswerPayloadDecoder` contract) and remain plaintext throughout scoring — this is correct at both ends; `SubmissionDecryptionService` (from `pte-doc/projects/plans/quang-answer-submission-encryption/plan.md`) decrypts inside `exam-delivery` before persistence, so decoder never sees ciphertext.

---

## Steps

1. Copy the Phase 1 fixture from `pte-doc/projects/fixtures/listening-payload-contract.json` into pte-app's test resources: `pte-app/test/fixtures/listening-payload-contract.json`. Verify it is byte-identical to the original (same `contractVersion`, same fixture array content).

2. Copy the same fixture into pte-api's test resources: `pte-api/services/scoring/src/test/resources/fixtures/listening-payload-contract.json`. Verify byte-identical.

3. Implement the Dart test in pte-app (`test/features/exam_attempt/listening/listening_payload_contract_test.dart` or appropriate test directory):
   - Declare a constant `const int EXPECTED_CONTRACT_VERSION = 1`.
   - Load the vendored fixture JSON from the test resources directory.
   - Assert that `fixture['contractVersion'] == EXPECTED_CONTRACT_VERSION`; if not, fail with an error message stating the mismatch (e.g., "Fixture contractVersion is 2 but test expects 1; update test constant or sync fixture with pte-doc").
   - Parse the `fixtures` array from the fixture JSON.
   - For each fixture entry, call the appropriate pure serializer using representative state (e.g., for MC_LISTENING_MULTIPLE, serialize selected option indices; for MC_LISTENING_SINGLE, serialize exactly one orderIndex).
   - Assert that the encoder output exactly matches the fixture's `payload` string (including trailing commas, sorted order, etc.).
   - If mismatch, log the fixture entry's description and the actual output to help diagnose why.

4. Implement the Java fixture schema/version test in pte-api/services/scoring (`src/test/java/com/pte/scoring/service/ListeningPayloadFixtureSchemaTest.java` or similar):
   - Declare a constant `private static final int EXPECTED_CONTRACT_VERSION = 1;`.
   - Load the vendored fixture JSON from `src/test/resources/fixtures/listening-payload-contract.json` using Jackson.
   - Assert that the fixture's `contractVersion` field equals `EXPECTED_CONTRACT_VERSION`; if not, fail with an error message stating the mismatch.
   - Parse the `fixtures` array and assert that all 8 Listening task types appear exactly once.
   - Assert that each entry has the required fields and that `payload` remains a JSON string (including empty strings where the contract permits an unanswered response).
   - Do not call `AnswerPayloadDecoder` here; Phase 3 owns decoder assertions for the new response kinds.

5. Document in both test files (code comments or test class javadoc) why the fixture is vendored (enabling local failure detection without shared CI), the limitation that a stale internally-consistent copy may not fail automatically, and how to update the fixture across both repos (update pte-doc's canonical, copy it to both repos, run the sync/hash check, and bump contractVersion in all three places: pte-doc fixture, pte-app constant, pte-api constant).

6. Do NOT add these tests to a CI/CD pipeline — the repos have no shared pipeline (verified: zero workflow files in pte-api and pte-app). Tests run when developers run `mvn test` or `flutter test` locally or via their own tooling; failure causes immediate local feedback.

---

## Success Criteria

- A vendored fixture copy exists at `pte-app/test/fixtures/listening-payload-contract.json` with `contractVersion: 1`.
- A vendored fixture copy exists at `pte-api/services/scoring/src/test/resources/fixtures/listening-payload-contract.json` with `contractVersion: 1`.
- Both fixture copies are byte-identical to pte-doc's canonical fixture.
- A Dart test exists in pte-app asserting FE encoder output matches fixture payloads for all 8 types, and asserting contractVersion == EXPECTED_CONTRACT_VERSION.
- A Java fixture-schema test exists in pte-api/scoring asserting all 8 entries and contractVersion == EXPECTED_CONTRACT_VERSION; decoder output assertions are covered by Phase 3.
- At least one test is written to demonstrate a concrete encoding contract (e.g., "FILL_BLANKS_LISTENING payload must have trailing commas for unfilled gaps").
- Both tests fail obviously with clear error messages if the fixture is missing or contractVersion mismatches.

---

## Quality and Testing State

- Quality gate: **approved**, 0 blocking findings. Cryptographic receipt skipped because reviewed files span `pte-app`/`pte-api` while the plan/report lives in separate `pte-doc` repository. Report: `quality/phase-02-fixture-tests-quality-report.json`.
- Testing: **passed**, 637/637 checks passed: full `pte-app` suite 585/585, full scoring reactor 52/52, targeted Dart 3/3, targeted Java 1/1, and analyzer clean. Report: `tests/phase-02-fixture-tests-test-report.json`.

---

## Risks

- **Fixture staleness undetected by local tests**: Both tests can pass even if the fixture is outdated, if the FE encoder and decoder both changed together. Mitigation: Human code review discipline — on every PR touching payload encoding, reviewer must inspect the fixture and ask: "Is this fixture still accurate?" This is a process/discipline risk, not a technical one; accept it as documented in plan.md Risks.
- **Fixture copies go out of sync with pte-doc**: If pte-doc's canonical is updated but the vendored copies are forgotten, a developer running tests locally won't know they're stale (tests pass). Mitigation: Process discipline — when editing the fixture, update all three copies (pte-doc, pte-app, pte-api) in the same commit and bump contractVersion in all three. A post-commit hook or pre-push check could enforce this (out of scope for this plan).
- **Contract version collision**: If two features both bump contractVersion in their own branches and merge to main, both would try to be "version 2", causing confusion. Mitigation: contractVersion is owned by the listening contract; it is NOT bumped by unrelated features. Only Quang (owner of this plan) bumps it. Document this ownership in the fixture file itself and in code comments.

---

## File Ownership

- `pte-doc/projects/fixtures/listening-payload-contract.json` — canonical, Phase 1 owns; Phase 2 reads only
- `pte-app/test/fixtures/listening-payload-contract.json` — vendored copy, pte-app owns; must stay in sync with pte-doc
- `pte-app/test/features/exam_attempt/listening/listening_payload_contract_test.dart` — pte-app owns
- `pte-app/lib/features/exam_attempt/domain/listening_payload.dart` — pte-app owns the pure Listening payload serializers used by the cubits and tests
- `pte-app/lib/features/exam_attempt/listening/presentation/widgets/fill_blanks_input_widget.dart` — pte-app owns the v1 delimiter input restriction
- `pte-api/services/scoring/src/test/resources/fixtures/listening-payload-contract.json` — vendored copy, pte-api owns; must stay in sync with pte-doc
- `pte-api/services/scoring/src/test/java/com/pte/scoring/service/ListeningPayloadFixtureSchemaTest.java` — pte-api owns
