# Question import data

This directory contains the latest normalized question data synchronized from
the fuller clean dataset at D:/DOCUMENTFPT/SEMESTER_9/data_clean.

The raw files under data/listening, data/reading, data/speaking, and
data/writing are preserved unchanged. This synchronization does not connect to
the API, write to PostgreSQL, or touch any real database.

## Output structure

- by-task-type/<TASK_TYPE_KEY>.json: canonical task types used by the API.
- quarantine/WRITE_EMAIL.json: source data whose task type does not exist in
  the current PteTaskType enum.
- manifest.json: record counts, source mapping, and normalization warnings.
- media-manifest.json: unique external media URLs and their task types.
- local-question-seed.sql: explicit local-only PostgreSQL seed, generated but
  never executed by the normalization scripts.
- local-question-seed-manifest.json: seed counts, exclusions, and media policy.

Each normalized record follows the question authoring shape:

    {
      "pteTaskType": "MC_LISTENING_SINGLE",
      "taskTypeKey": "MC_LISTENING_SINGLE",
      "taskTypeSection": "LISTENING",
      "title": "...",
      "promptText": "...",
      "audioPromptUrl": "https://...",
      "imagePromptUrl": null,
      "referenceAnswerText": null,
      "correctAnswerText": "...",
      "minWordCount": null,
      "maxWordCount": null,
      "options": [],
      "source": {},
      "importWarnings": []
    }

source keeps the original source file, source id, source num, labels, clean
dataset file, and available editorial metadata so that records can be traced
back to both datasets.

## Media policy

The current source contains external audio URLs hosted on
dl26yht2ovo33.cloudfront.net. They are retained in audioPromptUrl; no
Cloudinary upload is performed. The current API model still accepts media UUID
references, so records with external audio have the warning
EXTERNAL_AUDIO_URL_REQUIRES_BACKEND_SUPPORT until the backend supports
external URLs.

No image URL was present in the source export. DESCRIBE_IMAGE records are kept
but marked with IMAGE_URL_MISSING.

## Data warnings

Warnings are deliberately not silently repaired by inventing content:

- PROMPT_TEXT_MISSING: the source export has no prompt/transcript.
- CORRECT_ANSWER_MISSING: the source export has no answer.
- WORD_COUNT_MISSING: source data has no min/max response word limits.
- UNSUPPORTED_TASK_TYPE: the source type is not in the current API enum.

These records remain available in their task-type file for review, but should
not be sent to an importer until the warning is resolved.

FILL_IN_THE_BLANKS_DROPDOWN keeps the source option order scoped within each
blank. The local SQL seed remaps that field to a globally unique orderIndex per
question because the current QuestionValidationHelper rejects duplicate
orderIndex values; blankIndex is preserved for delivery/scoring grouping.

## Local SQL seed

The generated `local-question-seed.sql` is not a Flyway migration and is not
run by any script in this repository. It contains only records that satisfy
the current question-type contract: 14,840 questions and 34,135 options. The
2,442 records with unresolved prompt/answer/image/word-count warnings remain
in the canonical JSON for review and are excluded from the approved seed.

The seed inserts deterministic UUIDs, keeps questions `APPROVED`/`SHARED` for
local exam generation, and is idempotent by those UUIDs. Review it before any
explicit local execution. Its external audio URLs are stored in
`media_objects.secure_url` and referenced from `questions.audio_prompt_ref`;
no media is uploaded to Cloudinary. This is a local import compatibility path,
not a change to the current API authoring contract.

Regenerate the artifact after changing the normalized data:

    node tools/generate-local-question-seed.js --force

The generator only reads JSON and writes the two seed artifacts. It does not
connect to PostgreSQL, call the API, or modify the local database.

## Rebuild

From the pte-doc repository root:

    node tools/sync-clean-question-data.js --source D:/DOCUMENTFPT/SEMESTER_9/data_clean --force

The normalized records are deterministic with respect to the clean source data.
manifest.generatedAt changes on each run, and the script only rewrites
data/question-import.
