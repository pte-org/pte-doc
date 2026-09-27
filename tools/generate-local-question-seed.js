'use strict';

const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');

const PROJECT_ROOT = path.resolve(__dirname, '..');
const DEFAULT_INPUT_ROOT = path.join(PROJECT_ROOT, 'data', 'question-import');
const DEFAULT_OUTPUT = path.join(DEFAULT_INPUT_ROOT, 'local-question-seed.sql');
const DEFAULT_MANIFEST_OUTPUT = path.join(DEFAULT_INPUT_ROOT, 'local-question-seed-manifest.json');
const SEED_TIMESTAMP = '2026-09-23 00:00:00+00';
const SEED_STATUS = 'APPROVED';
const RESERVED_MEDIA_OWNER = '7d1b4c75-2d46-5a4f-8ad8-4c9d9b8f0001';
const UUID_NAMESPACE = Buffer.from('4f0f7f6d2a164c0c8f8e9e3e51b5c2d1', 'hex');
const ALLOWED_WARNINGS = new Set(['EXTERNAL_AUDIO_URL_REQUIRES_BACKEND_SUPPORT']);

// Mirrors the persisted standard task-type requirements in V57 and the
// QuestionValidationHelper contract. This script intentionally fails closed:
// a record that cannot be inserted as an API-valid question is excluded from
// the approved local seed and remains available in by-task-type/*.json.
const CONTRACTS = {
  READ_ALOUD: { section: 'SPEAKING', prompt: true },
  REPEAT_SENTENCE: { section: 'SPEAKING', audio: true },
  DESCRIBE_IMAGE: { section: 'SPEAKING', image: true },
  RE_TELL_LECTURE: { section: 'SPEAKING', audio: true },
  ANSWER_SHORT_QUESTION: { section: 'SPEAKING', audio: true, correctAnswer: true },
  RESPOND_TO_A_SITUATION: { section: 'SPEAKING', audio: true, prompt: true },
  SUMMARIZE_WRITTEN_TEXT: { section: 'WRITING', prompt: true, wordCount: true },
  WRITE_ESSAY: { section: 'WRITING', prompt: true, wordCount: true },
  MC_READING_SINGLE: { section: 'READING', prompt: true, options: true, correctOption: true, singleCorrect: true },
  MC_READING_MULTIPLE: { section: 'READING', prompt: true, options: true, correctOption: true },
  RE_ORDER_PARAGRAPHS: { section: 'READING', options: true, optionOrder: true },
  FILL_IN_THE_BLANKS_DRAG_AND_DROP: { section: 'READING', prompt: true, options: true, correctOption: true },
  FILL_IN_THE_BLANKS_DROPDOWN: { section: 'READING', prompt: true, options: true, correctOption: true },
  SUMMARIZE_SPOKEN_TEXT: { section: 'LISTENING', audio: true, wordCount: true },
  MC_LISTENING_SINGLE: { section: 'LISTENING', audio: true, options: true, correctOption: true, singleCorrect: true },
  MC_LISTENING_MULTIPLE: { section: 'LISTENING', audio: true, options: true, correctOption: true },
  FILL_IN_THE_BLANKS_TYPE_IN: { section: 'LISTENING', audio: true, prompt: true, correctAnswer: true },
  HIGHLIGHT_CORRECT_SUMMARY: { section: 'LISTENING', audio: true, options: true, correctOption: true },
  SELECT_MISSING_WORD: { section: 'LISTENING', audio: true, options: true, correctOption: true },
  HIGHLIGHT_INCORRECT_WORDS: { section: 'LISTENING', audio: true, prompt: true, correctAnswer: true },
  WRITE_FROM_DICTATION: { section: 'LISTENING', audio: true, correctAnswer: true }
};

function argument(name, fallback) {
  const index = process.argv.indexOf(name);
  return index >= 0 && process.argv[index + 1] ? process.argv[index + 1] : fallback;
}

function hasFlag(name) {
  return process.argv.includes(name);
}

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function textOrNull(value) {
  if (value === null || value === undefined) {
    return null;
  }
  const valueAsText = String(value).trim();
  return valueAsText.length === 0 ? null : valueAsText;
}

function stableUuid(name) {
  const hash = crypto.createHash('sha1')
    .update(UUID_NAMESPACE)
    .update(String(name), 'utf8')
    .digest();
  hash[6] = (hash[6] & 0x0f) | 0x50;
  hash[8] = (hash[8] & 0x3f) | 0x80;
  const hex = hash.subarray(0, 16).toString('hex');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

function sha256(value) {
  return crypto.createHash('sha256').update(value, 'utf8').digest('hex');
}

function sqlText(value) {
  if (value === null || value === undefined) {
    return 'NULL';
  }
  const stringValue = String(value);
  if (stringValue.includes('\u0000')) {
    throw new Error('NUL byte cannot be represented in PostgreSQL text');
  }
  const escaped = stringValue
    .replaceAll('\\', '\\\\')
    .replaceAll("'", "''")
    .replaceAll('\r', '\\r')
    .replaceAll('\n', '\\n')
    .replaceAll('\t', '\\t');
  return `E'${escaped}'`;
}

function sqlUuid(value) {
  return value === null || value === undefined ? 'NULL' : `'${value}'::uuid`;
}

function sqlBoolean(value) {
  return value ? 'TRUE' : 'FALSE';
}

function sqlInteger(value) {
  return value === null || value === undefined ? 'NULL' : String(value);
}

function sqlTimestamp() {
  return `TIMESTAMPTZ '${SEED_TIMESTAMP}'`;
}

function sqlRow(values) {
  return `(${values.join(', ')})`;
}

function chunkedInsert(tableName, columns, rows, chunkSize = 500) {
  const statements = [];
  for (let offset = 0; offset < rows.length; offset += chunkSize) {
    const chunk = rows.slice(offset, offset + chunkSize);
    statements.push([
      `INSERT INTO ${tableName} (${columns.join(', ')}) VALUES`,
      chunk.map((row, index) => `  ${row}${index === chunk.length - 1 ? ';' : ','}`).join('\n')
    ].join('\n'));
  }
  return statements.join('\n\n');
}

function contentTypeFor(url, kind) {
  const pathname = new URL(url).pathname.toLowerCase();
  if (kind === 'image') {
    if (pathname.endsWith('.png')) return 'image/png';
    if (pathname.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
  if (pathname.endsWith('.wav')) return 'audio/wav';
  if (pathname.endsWith('.m4a')) return 'audio/mp4';
  if (pathname.endsWith('.ogg') || pathname.endsWith('.oga')) return 'audio/ogg';
  return 'audio/mpeg';
}

function sourceKeyFor(record, taskTypeKey, fallbackIndex) {
  const source = record.source || {};
  const file = String(source.cleanFile || source.file || 'unknown-source').replaceAll('\\', '/');
  const sourceIdentity = source.id ?? source.num ?? fallbackIndex;
  return `${taskTypeKey}|${file}|${sourceIdentity}`;
}

function mediaEntry(url, kind, mediaByKey) {
  if (!url) {
    return null;
  }
  const parsed = new URL(url);
  if (parsed.protocol !== 'https:') {
    throw new Error('MEDIA_URL_MUST_USE_HTTPS');
  }
  const mediaKey = `${kind}|${url}`;
  if (!mediaByKey.has(mediaKey)) {
    const digest = sha256(mediaKey);
    mediaByKey.set(mediaKey, {
      publicId: stableUuid(`media|${mediaKey}`),
      secureUrl: url,
      contentType: contentTypeFor(url, kind),
      storageKey: `external-seed/${digest}`,
      cloudinaryPublicId: `external-seed/${digest}`,
      cloudinaryResourceType: 'external',
      audioPrompt: kind === 'audio'
    });
  }
  return mediaByKey.get(mediaKey);
}

function normalizedOptions(record) {
  const sourceOptions = Array.isArray(record.options) ? record.options : [];
  const isDropdown = record.taskTypeKey === 'FILL_IN_THE_BLANKS_DROPDOWN';
  return sourceOptions.map((option, index) => ({
    text: textOrNull(option.text),
    correct: Boolean(option.correct),
    // The current QuestionValidationHelper requires orderIndex to be unique
    // across one question. Dropdown source data is grouped by blank and uses
    // local indices, so the SQL seed remaps it to one global sequence while
    // preserving blankIndex and authored array order.
    orderIndex: isDropdown ? index : Number.isInteger(option.orderIndex) ? option.orderIndex : index,
    blankIndex: option.blankIndex === null || option.blankIndex === undefined ? null : Number(option.blankIndex),
    correctGapIndex: option.correctGapIndex === null || option.correctGapIndex === undefined
      ? null : Number(option.correctGapIndex)
  }));
}

function validateAndBuild(record, taskTypeKey, fallbackIndex, mediaByKey) {
  const contract = CONTRACTS[taskTypeKey];
  if (!contract) {
    throw new Error('UNSUPPORTED_TASK_TYPE');
  }

  const sourceKey = sourceKeyFor(record, taskTypeKey, fallbackIndex);
  const title = textOrNull(record.title) || textOrNull(record.source?.nameWithoutNum) || sourceKey;
  if (title.length > 255) {
    throw new Error('TITLE_TOO_LONG');
  }

  const promptText = textOrNull(record.promptText);
  const audioUrl = textOrNull(record.audioPromptUrl);
  const imageUrl = textOrNull(record.imagePromptUrl);
  const referenceAnswerText = textOrNull(record.referenceAnswerText);
  const correctAnswerText = textOrNull(record.correctAnswerText);
  const minWordCount = record.minWordCount === null || record.minWordCount === undefined
    ? null : Number(record.minWordCount);
  const maxWordCount = record.maxWordCount === null || record.maxWordCount === undefined
    ? null : Number(record.maxWordCount);

  if (record.taskTypeSection !== contract.section) {
    throw new Error('TASK_SECTION_MISMATCH');
  }
  if (contract.prompt && !promptText) throw new Error('PROMPT_TEXT_REQUIRED');
  if (contract.audio && !audioUrl) throw new Error('AUDIO_URL_REQUIRED');
  if (contract.image && !imageUrl) throw new Error('IMAGE_URL_REQUIRED');
  if (contract.wordCount && (!Number.isInteger(minWordCount) || !Number.isInteger(maxWordCount)
    || minWordCount < 0 || maxWordCount < minWordCount)) {
    throw new Error('WORD_COUNT_REQUIRED');
  }
  if (contract.correctAnswer && !correctAnswerText) throw new Error('CORRECT_ANSWER_REQUIRED');

  const options = normalizedOptions(record);
  if (contract.options && options.length === 0) throw new Error('OPTIONS_REQUIRED');
  const orderIndexes = new Set();
  for (const option of options) {
    if (!option.text || !Number.isInteger(option.orderIndex) || option.orderIndex < 0
      || orderIndexes.has(option.orderIndex)
      || (option.blankIndex !== null && (!Number.isInteger(option.blankIndex) || option.blankIndex < 0))
      || (option.correctGapIndex !== null
        && (!Number.isInteger(option.correctGapIndex) || option.correctGapIndex < 0))
      || (option.blankIndex !== null && option.correctGapIndex !== null)) {
      throw new Error('INVALID_OPTION_FIELDS');
    }
    orderIndexes.add(option.orderIndex);
  }
  if (contract.correctOption && !options.some(option => option.correct)) {
    throw new Error('CORRECT_OPTION_REQUIRED');
  }
  if (contract.singleCorrect && options.filter(option => option.correct).length !== 1) {
    throw new Error('SINGLE_CORRECT_OPTION_REQUIRED');
  }
  if (taskTypeKey === 'FILL_IN_THE_BLANKS_DROPDOWN') {
    const groups = new Map();
    for (const option of options) {
      if (option.blankIndex === null) throw new Error('DROPDOWN_BLANK_INDEX_REQUIRED');
      if (!groups.has(option.blankIndex)) groups.set(option.blankIndex, []);
      groups.get(option.blankIndex).push(option);
    }
    for (const group of groups.values()) {
      if (group.filter(option => option.correct).length !== 1) {
        throw new Error('DROPDOWN_SINGLE_CORRECT_PER_BLANK_REQUIRED');
      }
    }
  }

  const audioMedia = mediaEntry(audioUrl, 'audio', mediaByKey);
  const imageMedia = mediaEntry(imageUrl, 'image', mediaByKey);
  const questionPublicId = stableUuid(`question|${sourceKey}`);
  return {
    sourceKey,
    questionPublicId,
    taskTypeKey,
    section: contract.section,
    title,
    promptText,
    audioPromptRef: audioMedia?.publicId || null,
    imagePromptRef: imageMedia?.publicId || null,
    referenceAnswerText,
    correctAnswerText,
    minWordCount,
    maxWordCount,
    options: options.map((option, index) => ({
      ...option,
      publicId: stableUuid(`option|${questionPublicId}|${index}`)
    }))
  };
}

function sqlForMedia(media) {
  return sqlRow([
    sqlUuid(media.publicId),
    sqlTimestamp(),
    sqlTimestamp(),
    sqlBoolean(false),
    'NULL',
    sqlUuid(RESERVED_MEDIA_OWNER),
    sqlText(media.contentType),
    sqlText(media.storageKey),
    sqlText('UPLOADED'),
    sqlBoolean(media.audioPrompt),
    'NULL',
    sqlText(media.cloudinaryPublicId),
    sqlText(media.cloudinaryResourceType),
    sqlText(media.secureUrl),
    'NULL',
    'NULL'
  ]);
}

function sqlForQuestion(question) {
  return sqlRow([
    sqlUuid(question.questionPublicId),
    sqlTimestamp(),
    sqlTimestamp(),
    sqlBoolean(false),
    sqlText(question.taskTypeKey),
    sqlText(question.taskTypeKey),
    sqlText(question.section),
    sqlText('SHARED'),
    'NULL',
    sqlText(SEED_STATUS),
    sqlUuid(question.questionPublicId),
    '1',
    'NULL',
    'TRUE',
    '0',
    'NULL',
    sqlText(question.title),
    sqlText(question.promptText),
    sqlUuid(question.audioPromptRef),
    sqlUuid(question.imagePromptRef),
    sqlText(question.referenceAnswerText),
    sqlText(question.correctAnswerText),
    sqlInteger(question.minWordCount),
    sqlInteger(question.maxWordCount)
  ]);
}

function sqlForOption(question, option) {
  return sqlRow([
    sqlUuid(option.publicId),
    sqlUuid(question.questionPublicId),
    sqlTimestamp(),
    sqlTimestamp(),
    sqlBoolean(false),
    sqlText(option.text),
    sqlBoolean(option.correct),
    sqlInteger(option.orderIndex),
    sqlInteger(option.blankIndex),
    sqlInteger(option.correctGapIndex)
  ]);
}

function buildSql(questions, media) {
  const mediaRows = media.map(sqlForMedia);
  const questionRows = questions.map(sqlForQuestion);
  const optionRows = questions.flatMap(question => question.options.map(option => sqlForOption(question, option)));

  const sql = [];
  sql.push('-- LOCAL-ONLY question seed; generated data is not a Flyway migration.');
  sql.push('-- It is intentionally not executed by this generator. Review before running with psql.');
  sql.push(`-- Source: data/question-import/by-task-type/*.json`);
  sql.push(`-- Seed status: ${SEED_STATUS}; questions with unresolved import warnings are excluded.`);
  sql.push(`-- Included questions: ${questions.length}; options: ${optionRows.length}; media: ${media.length}.`);
  sql.push('-- External media URLs are stored in media_objects.secure_url and referenced by UUID.');
  sql.push('');
  sql.push('BEGIN;');
  sql.push('SET LOCAL lock_timeout = \'5s\';');
  sql.push('');
  sql.push('DO $$');
  sql.push('DECLARE missing_columns TEXT;');
  sql.push('BEGIN');
  sql.push("    IF to_regclass('public.questions') IS NULL THEN");
  sql.push("        RAISE EXCEPTION 'questions table is missing; run the application migrations first';");
  sql.push('    END IF;');
  sql.push("    IF to_regclass('public.question_options') IS NULL THEN");
  sql.push("        RAISE EXCEPTION 'question_options table is missing; run the application migrations first';");
  sql.push('    END IF;');
  sql.push("    IF to_regclass('public.media_objects') IS NULL THEN");
  sql.push("        RAISE EXCEPTION 'media_objects table is missing; run the application migrations first';");
  sql.push('    END IF;');
  sql.push("    IF to_regclass('public.question_types') IS NULL THEN");
  sql.push("        RAISE EXCEPTION 'question_types table is missing; run the application migrations first';");
  sql.push('    END IF;');
  sql.push('    SELECT string_agg(required_column.table_name || \'.\' || required_column.column_name, \' , \'');
  sql.push('                       ORDER BY required_column.table_name, required_column.column_name)');
  sql.push('      INTO missing_columns');
  sql.push('      FROM (VALUES');
  sql.push("          ('questions', 'task_type_key'),");
  sql.push("          ('questions', 'task_type_section'),");
  sql.push("          ('questions', 'revision_group_public_id'),");
  sql.push("          ('questions', 'revision_number'),");
  sql.push("          ('questions', 'is_current'),");
  sql.push("          ('questions', 'version'),");
  sql.push("          ('questions', 'audio_prompt_ref'),");
  sql.push("          ('questions', 'image_prompt_ref'),");
  sql.push("          ('question_options', 'blank_index'),");
  sql.push("          ('question_options', 'correct_gap_index'),");
  sql.push("          ('media_objects', 'cloudinary_public_id'),");
  sql.push("          ('media_objects', 'cloudinary_resource_type'),");
  sql.push("          ('media_objects', 'secure_url'),");
  sql.push("          ('media_objects', 'asset_id'),");
  sql.push("          ('media_objects', 'size_bytes'),");
  sql.push("          ('question_types', 'task_type_key')");
  sql.push('      ) AS required_column(table_name, column_name)');
  sql.push('     WHERE NOT EXISTS (');
  sql.push('         SELECT 1');
  sql.push('           FROM information_schema.columns column_info');
  sql.push("          WHERE column_info.table_schema = 'public'");
  sql.push('            AND column_info.table_name = required_column.table_name');
  sql.push('            AND column_info.column_name = required_column.column_name');
  sql.push('     );');
  sql.push('    IF missing_columns IS NOT NULL THEN');
  sql.push("        RAISE EXCEPTION 'Required schema columns are missing: %', missing_columns;");
  sql.push('    END IF;');
  sql.push('END $$;');
  sql.push('');
  sql.push(`CREATE TEMP TABLE _pte_local_seed_media (`);
  sql.push('    public_id UUID PRIMARY KEY,');
  sql.push('    created_at TIMESTAMPTZ NOT NULL,');
  sql.push('    updated_at TIMESTAMPTZ NOT NULL,');
  sql.push('    deleted BOOLEAN NOT NULL,');
  sql.push('    tenant_id UUID,');
  sql.push('    owner_public_id UUID NOT NULL,');
  sql.push('    content_type VARCHAR(255) NOT NULL,');
  sql.push('    storage_key VARCHAR(255) NOT NULL,');
  sql.push('    status VARCHAR(32) NOT NULL,');
  sql.push('    audio_prompt BOOLEAN NOT NULL,');
  sql.push('    duration_seconds INTEGER,');
  sql.push('    cloudinary_public_id VARCHAR(512),');
  sql.push('    cloudinary_resource_type VARCHAR(32),');
  sql.push('    secure_url TEXT,');
  sql.push('    asset_id VARCHAR(255),');
  sql.push('    size_bytes BIGINT');
  sql.push(') ON COMMIT DROP;');
  sql.push('');
  sql.push('CREATE TEMP TABLE _pte_local_seed_questions (');
  sql.push('    question_public_id UUID PRIMARY KEY,');
  sql.push('    created_at TIMESTAMPTZ NOT NULL,');
  sql.push('    updated_at TIMESTAMPTZ NOT NULL,');
  sql.push('    deleted BOOLEAN NOT NULL,');
  sql.push('    pte_task_type VARCHAR(64),');
  sql.push('    task_type_key VARCHAR(64) NOT NULL,');
  sql.push('    task_type_section VARCHAR(16) NOT NULL,');
  sql.push('    visibility VARCHAR(16) NOT NULL,');
  sql.push('    tenant_id UUID,');
  sql.push('    status VARCHAR(16) NOT NULL,');
  sql.push('    revision_group_public_id UUID NOT NULL,');
  sql.push('    revision_number INTEGER NOT NULL,');
  sql.push('    supersedes_public_id UUID,');
  sql.push('    is_current BOOLEAN NOT NULL,');
  sql.push('    version BIGINT NOT NULL,');
  sql.push('    rejection_reason VARCHAR(500),');
  sql.push('    title VARCHAR(255) NOT NULL,');
  sql.push('    prompt_text TEXT,');
  sql.push('    audio_prompt_ref UUID,');
  sql.push('    image_prompt_ref UUID,');
  sql.push('    reference_answer_text TEXT,');
  sql.push('    correct_answer_text TEXT,');
  sql.push('    min_word_count INTEGER,');
  sql.push('    max_word_count INTEGER');
  sql.push(') ON COMMIT DROP;');
  sql.push('');
  sql.push('CREATE TEMP TABLE _pte_local_seed_options (');
  sql.push('    public_id UUID PRIMARY KEY,');
  sql.push('    question_public_id UUID NOT NULL,');
  sql.push('    created_at TIMESTAMPTZ NOT NULL,');
  sql.push('    updated_at TIMESTAMPTZ NOT NULL,');
  sql.push('    deleted BOOLEAN NOT NULL,');
  sql.push('    text TEXT NOT NULL,');
  sql.push('    correct BOOLEAN NOT NULL,');
  sql.push('    order_index INTEGER NOT NULL,');
  sql.push('    blank_index INTEGER,');
  sql.push('    correct_gap_index INTEGER');
  sql.push(') ON COMMIT DROP;');
  sql.push('');

  sql.push(chunkedInsert('_pte_local_seed_media', [
    'public_id', 'created_at', 'updated_at', 'deleted', 'tenant_id', 'owner_public_id',
    'content_type', 'storage_key', 'status', 'audio_prompt', 'duration_seconds',
    'cloudinary_public_id', 'cloudinary_resource_type', 'secure_url', 'asset_id', 'size_bytes'
  ], mediaRows));
  sql.push('');
  sql.push(chunkedInsert('_pte_local_seed_questions', [
    'question_public_id', 'created_at', 'updated_at', 'deleted', 'pte_task_type', 'task_type_key',
    'task_type_section', 'visibility', 'tenant_id', 'status', 'revision_group_public_id',
    'revision_number', 'supersedes_public_id', 'is_current', 'version', 'rejection_reason',
    'title', 'prompt_text', 'audio_prompt_ref', 'image_prompt_ref', 'reference_answer_text',
    'correct_answer_text', 'min_word_count', 'max_word_count'
  ], questionRows));
  sql.push('');
  sql.push(chunkedInsert('_pte_local_seed_options', [
    'public_id', 'question_public_id', 'created_at', 'updated_at', 'deleted', 'text', 'correct',
    'order_index', 'blank_index', 'correct_gap_index'
  ], optionRows));
  sql.push('');
  sql.push('DO $$');
  sql.push('DECLARE missing_task_types TEXT;');
  sql.push('BEGIN');
  sql.push('    SELECT string_agg(seed.task_type_key, \' , \' ORDER BY seed.task_type_key)');
  sql.push('      INTO missing_task_types');
  sql.push('      FROM (SELECT DISTINCT task_type_key FROM _pte_local_seed_questions) seed');
  sql.push('     WHERE NOT EXISTS (');
  sql.push('         SELECT 1 FROM question_types definition');
  sql.push('          WHERE definition.task_type_key = seed.task_type_key AND definition.deleted = FALSE');
  sql.push('     );');
  sql.push('    IF missing_task_types IS NOT NULL THEN');
  sql.push("        RAISE EXCEPTION 'Missing question type catalog row(s): %', missing_task_types;");
  sql.push('    END IF;');
  sql.push('END $$;');
  sql.push('');
  sql.push('INSERT INTO media_objects (');
  sql.push('    public_id, created_at, updated_at, deleted, tenant_id, owner_public_id, content_type,');
  sql.push('    storage_key, status, audio_prompt, duration_seconds, cloudinary_public_id,');
  sql.push('    cloudinary_resource_type, secure_url, asset_id, size_bytes');
  sql.push(')');
  sql.push('SELECT public_id, created_at, updated_at, deleted, tenant_id, owner_public_id, content_type,');
  sql.push('       storage_key, status, audio_prompt, duration_seconds, cloudinary_public_id,');
  sql.push('       cloudinary_resource_type, secure_url, asset_id, size_bytes');
  sql.push('  FROM _pte_local_seed_media');
  sql.push('ON CONFLICT (public_id) DO UPDATE SET');
  sql.push('    updated_at = EXCLUDED.updated_at, deleted = EXCLUDED.deleted, tenant_id = EXCLUDED.tenant_id,');
  sql.push('    owner_public_id = EXCLUDED.owner_public_id, content_type = EXCLUDED.content_type,');
  sql.push('    storage_key = EXCLUDED.storage_key, status = EXCLUDED.status,');
  sql.push('    audio_prompt = EXCLUDED.audio_prompt, duration_seconds = EXCLUDED.duration_seconds,');
  sql.push('    cloudinary_public_id = EXCLUDED.cloudinary_public_id,');
  sql.push('    cloudinary_resource_type = EXCLUDED.cloudinary_resource_type,');
  sql.push('    secure_url = EXCLUDED.secure_url, asset_id = EXCLUDED.asset_id, size_bytes = EXCLUDED.size_bytes;');
  sql.push('');
  sql.push('INSERT INTO questions (');
  sql.push('    public_id, created_at, updated_at, deleted, pte_task_type, task_type_key, task_type_section,');
  sql.push('    visibility, tenant_id, status, revision_group_public_id, revision_number, supersedes_public_id,');
  sql.push('    is_current, version, rejection_reason, title, prompt_text, audio_prompt_ref, image_prompt_ref,');
  sql.push('    reference_answer_text, correct_answer_text, min_word_count, max_word_count');
  sql.push(')');
  sql.push('SELECT question_public_id, created_at, updated_at, deleted, pte_task_type, task_type_key,');
  sql.push('       task_type_section, visibility, tenant_id, status, revision_group_public_id, revision_number,');
  sql.push('       supersedes_public_id, is_current, version, rejection_reason, title, prompt_text,');
  sql.push('       audio_prompt_ref, image_prompt_ref, reference_answer_text, correct_answer_text,');
  sql.push('       min_word_count, max_word_count');
  sql.push('  FROM _pte_local_seed_questions');
  sql.push('ON CONFLICT (public_id) DO UPDATE SET');
  sql.push('    updated_at = EXCLUDED.updated_at, deleted = EXCLUDED.deleted,');
  sql.push('    pte_task_type = EXCLUDED.pte_task_type, task_type_key = EXCLUDED.task_type_key,');
  sql.push('    task_type_section = EXCLUDED.task_type_section, visibility = EXCLUDED.visibility,');
  sql.push('    tenant_id = EXCLUDED.tenant_id, status = EXCLUDED.status,');
  sql.push('    revision_group_public_id = EXCLUDED.revision_group_public_id, revision_number = EXCLUDED.revision_number,');
  sql.push('    supersedes_public_id = EXCLUDED.supersedes_public_id, is_current = EXCLUDED.is_current,');
  sql.push('    version = EXCLUDED.version, rejection_reason = EXCLUDED.rejection_reason, title = EXCLUDED.title,');
  sql.push('    prompt_text = EXCLUDED.prompt_text, audio_prompt_ref = EXCLUDED.audio_prompt_ref,');
  sql.push('    image_prompt_ref = EXCLUDED.image_prompt_ref, reference_answer_text = EXCLUDED.reference_answer_text,');
  sql.push('    correct_answer_text = EXCLUDED.correct_answer_text, min_word_count = EXCLUDED.min_word_count,');
  sql.push('    max_word_count = EXCLUDED.max_word_count;');
  sql.push('');
  sql.push('DELETE FROM question_options existing');
  sql.push(' USING questions question');
  sql.push(' JOIN _pte_local_seed_questions seed ON seed.question_public_id = question.public_id');
  sql.push(' WHERE existing.question_id = question.id;');
  sql.push('');
  sql.push('INSERT INTO question_options (');
  sql.push('    public_id, created_at, updated_at, deleted, question_id, text, correct, order_index,');
  sql.push('    blank_index, correct_gap_index');
  sql.push(')');
  sql.push('SELECT seed_option.public_id, seed_option.created_at, seed_option.updated_at, seed_option.deleted,');
  sql.push('       question.id, seed_option.text, seed_option.correct, seed_option.order_index,');
  sql.push('       seed_option.blank_index, seed_option.correct_gap_index');
  sql.push('  FROM _pte_local_seed_options seed_option');
  sql.push('  JOIN questions question ON question.public_id = seed_option.question_public_id');
  sql.push('ON CONFLICT (public_id) DO UPDATE SET');
  sql.push('    updated_at = EXCLUDED.updated_at, deleted = EXCLUDED.deleted, question_id = EXCLUDED.question_id,');
  sql.push('    text = EXCLUDED.text, correct = EXCLUDED.correct, order_index = EXCLUDED.order_index,');
  sql.push('    blank_index = EXCLUDED.blank_index, correct_gap_index = EXCLUDED.correct_gap_index;');
  sql.push('');
  sql.push('DO $$');
  sql.push('DECLARE question_count BIGINT; option_count BIGINT;');
  sql.push('BEGIN');
  sql.push('    SELECT COUNT(*) INTO question_count');
  sql.push('      FROM questions question JOIN _pte_local_seed_questions seed');
  sql.push('        ON seed.question_public_id = question.public_id;');
  sql.push('    SELECT COUNT(*) INTO option_count');
  sql.push('      FROM question_options option JOIN _pte_local_seed_options seed');
  sql.push('        ON seed.public_id = option.public_id;');
  sql.push(`    IF question_count <> ${questions.length} OR option_count <> ${optionRows.length} THEN`);
  sql.push("        RAISE EXCEPTION 'Local question seed verification failed: questions=%, options=%', question_count, option_count;");
  sql.push('    END IF;');
  sql.push('END $$;');
  sql.push('');
  sql.push('COMMIT;');
  sql.push('');
  return sql.join('\n');
}

function main() {
  const inputRoot = path.resolve(argument('--input', DEFAULT_INPUT_ROOT));
  const outputPath = path.resolve(argument('--output', DEFAULT_OUTPUT));
  const manifestOutput = path.resolve(argument('--manifest-output', DEFAULT_MANIFEST_OUTPUT));
  if (!hasFlag('--force') && fs.existsSync(outputPath)) {
    throw new Error(`Refusing to overwrite ${outputPath}; pass --force to regenerate it`);
  }

  const importManifest = readJson(path.join(inputRoot, 'manifest.json'));
  const mediaByKey = new Map();
  const questions = [];
  const skipped = {};
  const taskCounts = {};
  let skippedRecordCount = 0;
  let fallbackIndex = 0;

  for (const [taskTypeKey, taskMetadata] of Object.entries(importManifest.taskTypes || {})) {
    const filePath = path.join(inputRoot, taskMetadata.file);
    if (!fs.existsSync(filePath) || !CONTRACTS[taskTypeKey]) {
      skipped.UNSUPPORTED_TASK_TYPE = (skipped.UNSUPPORTED_TASK_TYPE || 0) + (taskMetadata.count || 0);
      skippedRecordCount += Number(taskMetadata.count || 0);
      continue;
    }
    const records = readJson(filePath);
    for (const record of records) {
      fallbackIndex += 1;
      const unresolvedWarnings = (record.importWarnings || []).filter(warning => !ALLOWED_WARNINGS.has(warning));
      if (unresolvedWarnings.length > 0) {
        skippedRecordCount += 1;
        for (const warning of unresolvedWarnings) {
          skipped[warning] = (skipped[warning] || 0) + 1;
        }
        continue;
      }
      try {
        const question = validateAndBuild(record, taskTypeKey, fallbackIndex, mediaByKey);
        questions.push(question);
        taskCounts[taskTypeKey] = (taskCounts[taskTypeKey] || 0) + 1;
      } catch (error) {
        skippedRecordCount += 1;
        const reason = error instanceof Error ? error.message : String(error);
        skipped[reason] = (skipped[reason] || 0) + 1;
      }
    }
  }

  questions.sort((left, right) => left.questionPublicId.localeCompare(right.questionPublicId));
  const media = [...mediaByKey.values()].sort((left, right) => left.publicId.localeCompare(right.publicId));
  const optionCount = questions.reduce((sum, question) => sum + question.options.length, 0);
  const inputCanonicalRecords = Object.values(importManifest.taskTypes || {})
    .reduce((sum, taskMetadata) => sum + Number(taskMetadata.count || 0), 0);
  const generatedAt = new Date().toISOString();
  const seedManifest = {
    schemaVersion: 'local-question-seed-v1',
    generatedAt,
    sourceManifest: 'data/question-import/manifest.json',
    outputSql: 'data/question-import/local-question-seed.sql',
    databaseTouched: false,
    seedStatus: SEED_STATUS,
    selection: {
      includedWarningAllowlist: [...ALLOWED_WARNINGS],
      excludedRecordsRemainInCanonicalJson: true,
      unsupportedTaskTypesRemainInQuarantine: true
    },
    counts: {
      inputCanonicalRecords,
      includedQuestions: questions.length,
      includedOptions: optionCount,
      includedMedia: media.length,
      skippedRecords: skippedRecordCount,
      skippedWarningOccurrences: Object.values(skipped).reduce((sum, count) => sum + count, 0)
    },
    taskCounts,
    skipped,
    mediaPolicy: {
      externalUrlsStoredIn: 'media_objects.secure_url',
      mediaReferenceColumn: 'questions.audio_prompt_ref/questions.image_prompt_ref',
      reservedOwnerPublicId: RESERVED_MEDIA_OWNER,
      cloudinaryPublicIdPolicy: 'external-seed/<sha256>',
      contentTypePolicy: 'derived-from-url-extension'
    },
    optionPolicy: {
      dropdownOrderIndex: 'global-per-question',
      reason: 'QuestionValidationHelper currently rejects duplicate orderIndex values within one question'
    }
  };

  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, buildSql(questions, media), 'utf8');
  fs.writeFileSync(manifestOutput, `${JSON.stringify(seedManifest, null, 2)}\n`, 'utf8');
  console.log(JSON.stringify({ outputPath, manifestOutput, ...seedManifest.counts, taskCounts, skipped }, null, 2));
}

try {
  main();
} catch (error) {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
}
