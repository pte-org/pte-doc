# PTEPrep Practice rubric contract v1

**Status:** Contract draft for Academic Manager review  
**Owner:** Academic Manager  
**Channel:** `PRACTICE`  
**Source:** `practice-rubric-v1.md` and `rubric-and-task-matrix.md`

## 1. Contract boundary

This contract describes educational feedback for PTEPrep Practice. It does not represent an official Pearson/PTE Academic score, band, certificate or affiliation. A published revision is the only rubric document that the Practice explanation service may use for a new session.

The contract separates:

- deterministic objective result (`CORRECT`, `PARTIALLY_CORRECT`, `INCORRECT`, `NOT_ASSESSABLE`);
- qualitative criterion level (`NOT_ASSESSABLE`, `NEEDS_SUPPORT`, `DEVELOPING`, `EFFECTIVE`, `STRONG`);
- evidence coverage (`FULL`, `LIMITED`, `NOT_ASSESSABLE`);
- learning advice grounded in the submitted answer.

Writing and Speaking do not produce an AI numeric score in this contract. Personal Introduction is coaching-only and never contributes to a scored practice result.

## 2. Canonical revision document

```json
{
  "rubricKey": "PTEPREP.PRACTICE.WRITE_ESSAY",
  "channel": "PRACTICE",
  "revision": 1,
  "schemaVersion": "1.0",
  "taskTypeKey": "WRITE_ESSAY",
  "runtime": {
    "profileKey": "WRITE_ESSAY",
    "profileVersion": "<pinned-runtime-version>",
    "answerSchemaVersion": "<pinned-answer-schema>",
    "evaluatorVersion": "<pinned-evaluator-or-null>"
  },
  "criteria": [
    {
      "criterionId": "TASK_FULFILMENT",
      "order": 1,
      "required": true,
      "allowedLevels": ["NOT_ASSESSABLE", "NEEDS_SUPPORT", "DEVELOPING", "EFFECTIVE", "STRONG"],
      "evidencePolicy": {
        "requiredTypes": ["PROMPT", "RESPONSE_SPAN"],
        "allowNotAssessable": true,
        "minimumCoverage": "LIMITED"
      },
      "levels": [
        {"key": "NOT_ASSESSABLE", "labelVi": "Chưa thể đánh giá", "labelEn": "Not assessable", "descriptor": "Required evidence is missing, invalid or outside this revision's supported scope; do not infer a weakness or assign a zero."},
        {"key": "NEEDS_SUPPORT", "labelVi": "Cần hỗ trợ", "labelEn": "Needs support", "descriptor": "<approved description>"},
        {"key": "DEVELOPING", "labelVi": "Đang phát triển", "labelEn": "Developing", "descriptor": "<approved description>"},
        {"key": "EFFECTIVE", "labelVi": "Đạt yêu cầu", "labelEn": "Effective", "descriptor": "<approved description>"},
        {"key": "STRONG", "labelVi": "Tốt", "labelEn": "Strong", "descriptor": "<approved description>"}
      ]
    }
  ],
  "policies": {
    "emptyResponse": "return_not_assessable_without_inference",
    "invalidResponse": "return_not_assessable_and_explain_input_issue",
    "offTopicResponse": "use_task_specific_policy_and_quote_only_verified_evidence",
    "unsupportedNumericScore": "reject",
    "officialScoreClaim": "reject"
  },
  "references": [
    {"referenceKey": "<stable-reference-key>", "sourceArtifact": "<approved-artifact>", "sourceRevision": "<source-revision>", "contentHash": "<sha-256>"}
  ],
  "anchors": [
    {"criterionId": "GRAMMAR", "level": "DEVELOPING", "exampleKey": "<stable-example-key>", "sanitizedResponse": "<approved-example>", "evidenceNote": "<why-this-level>", "approvalStatus": "PENDING"}
  ],
  "provenance": {
    "sourceDocument": "practice-rubric-v1.md",
    "sourceRevision": "1.0-draft",
    "academicApprovalRequired": true
  }
}
```

The JSON is a canonical publish projection. Admin editing uses structured fields; it never edits raw provider prompt text or a JSON blob without validation.

## 3. Allowed criteria by task family

| Task family | Criteria | Required evidence |
|---|---|---|
| Objective Reading/Listening | `ANSWER_MATCH`, `ANSWER_SET`, `SEQUENCE_RELATION`, `BLANK_MATCH`, `TOKEN_MATCH`, `SUMMARY_MATCH`, `CONTEXT_MATCH` as applicable | Pinned answer/evaluator/reference evidence. |
| Summarize Written Text | `SOURCE_COVERAGE`, `FAITHFULNESS`, `FORM`, `GRAMMAR`, `VOCABULARY` | Prompt/source, submitted text and deterministic form result. |
| Write Essay | `TASK_FULFILMENT`, `DEVELOPMENT_SUPPORT`, `ORGANIZATION_COHERENCE`, `GRAMMAR`, `VOCABULARY`, `SPELLING`, `FORM` | Prompt, response spans, deterministic form result. |
| Speaking content | `TASK_FULFILMENT`, `CONTENT_COVERAGE`, `LANGUAGE_CONTROL`, `REGISTER_APPROPRIATENESS` as applicable | Task source, transcript and response evidence. |
| Speaking audio | `PRONUNCIATION`, `FLUENCY`, `PROSODY` | Response audio and approved audio assessor output; transcript alone is insufficient. |
| Summarize Spoken Text | `SOURCE_COVERAGE`, `FAITHFULNESS`, `ORGANIZATION_COHERENCE`, `GRAMMAR`, `VOCABULARY`, `SPELLING`, `FORM` | Pinned lecture source/transcript, response and deterministic form result. |
| Personal Introduction | none | Optional coaching evidence only; no scored result. |

An unknown criterion ID, a criterion from another task family, or a level not listed in the revision causes provider output rejection. The complete task-to-criterion mapping is machine-readable in `rubric-contract-v1.json`.

## 4. Readiness rules

A revision is publishable only when:

1. The task type exists in the canonical registry.
2. Every required criterion has a stable ID, order, descriptor and applicable levels.
3. Every criterion has an explicit evidence policy and `NOT_ASSESSABLE` rule.
4. Empty, invalid, off-topic and missing-media handling is defined.
5. Reference/evaluator/runtime compatibility is resolved.
6. Required anchors have provenance and Academic Manager approval status.
7. The document serializes deterministically and produces a canonical content hash.
8. Numeric AI score and official-score claims are absent unless a separate approved policy exists.

Practice admission additionally requires a published question revision, published rubric binding, required media/source evidence and compatible runtime contract. A missing rubric makes a new item unavailable; it does not change historical sessions.

## 5. Provider response contract

The provider may return only:

```json
{
  "summary": "<localized educational summary>",
  "criterionFeedback": [
    {
      "criterionId": "GRAMMAR",
      "level": "DEVELOPING",
      "evidenceCoverage": "FULL",
      "feedback": "<Vietnamese by default, English when requested>",
      "evidence": ["submitted_response.sentence_2"]
    }
  ],
  "strengths": ["<verified strength>"],
  "improvements": ["<action grounded in evidence>"],
  "limitations": ["<missing or limited evidence, when applicable>"],
  "rubricVersion": "1",
  "language": "vi"
}
```

The server validates criterion coverage, allowed levels, evidence paths, language, immutable rubric hash and deterministic objective result before persisting an explanation. The canonical v1 shape uses `evidence` as an array of evidence paths. Legacy explanations that contain a single evidence string are read through a compatibility mapper and are never rewritten. Gemini cannot change objective correctness or create a numeric Writing/Speaking score.

## 6. Version and change rules

- Published and retired revisions are immutable.
- Any criterion meaning, descriptor, applicability, evidence policy, provider schema or runtime compatibility change creates a new revision.
- A session item pins revision public ID, revision number, canonical hash and safe snapshot reference.
- Historical explanation reads resolve the pinned revision, never the current published revision.
- The initial `PTEPREP-PRACTICE-RUBRIC` seed remains `DRAFT` until Academic Manager approval.

## 7. Canonical serialization and hash

The publish hash is SHA-256 over the UTF-8 bytes of a canonical JSON document:

1. Recursively sort object keys by Unicode code point.
2. Preserve array order because criterion/level order is meaningful.
3. Normalize every string to Unicode NFC, trim leading/trailing whitespace and normalize line endings to `\\n`.
4. Omit fields with no value instead of serializing `null`.
5. Serialize without insignificant whitespace and encode the resulting JSON as UTF-8.
6. Store the lowercase hexadecimal digest in `canonicalHash`.

Test vector: canonical JSON `{"a":"x","b":1}` produces SHA-256 `cdab067e9f3beb32d1252cfd63e492592fecbf591b0d08cadb24bb17f3864246`.

The runtime compatibility hash covers `profileKey`, `profileVersion`, `screenKey`, `behaviorKey`, `rendererKey`, `answerSchemaVersion`, `scoringProfileKey`, `scoringProfileVersion`, `contractVersion`, `scoringMode`, `minSupportedAppVersion`, `authoringContractKey`, `authoringContractVersion` and required client capabilities. A rubric is incompatible when this hash differs from the pinned question/runtime contract.
