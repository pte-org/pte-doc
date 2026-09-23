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

FILL_IN_THE_BLANKS_DROPDOWN keeps orderIndex scoped within each blank, matching
the delivery/scoring option shape. The current API validation code should be
verified for this per-blank identity before a real database import.

## Rebuild

From the pte-doc repository root:

    node tools/sync-clean-question-data.js --source D:/DOCUMENTFPT/SEMESTER_9/data_clean --force

The normalized records are deterministic with respect to the clean source data.
manifest.generatedAt changes on each run, and the script only rewrites
data/question-import.
