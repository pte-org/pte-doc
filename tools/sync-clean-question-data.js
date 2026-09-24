'use strict';

const fs = require('node:fs');
const path = require('node:path');

const DOC_ROOT = path.resolve(__dirname, '..');
const DATA_ROOT = path.join(DOC_ROOT, 'data');
const OUTPUT_ROOT = path.join(DATA_ROOT, 'question-import');
const DEFAULT_SOURCE_ROOT = 'D:/DOCUMENTFPT/SEMESTER_9/data_clean';
const FORCE = process.argv.includes('--force');

const TASK_REQUIREMENTS = {
  READ_ALOUD: { prompt: true },
  REPEAT_SENTENCE: { audio: true },
  DESCRIBE_IMAGE: { image: true },
  RE_TELL_LECTURE: { audio: true },
  ANSWER_SHORT_QUESTION: { audio: true, correctAnswer: true },
  RESPOND_TO_A_SITUATION: { audio: true, prompt: true },
  SUMMARIZE_WRITTEN_TEXT: { prompt: true, wordCount: true },
  WRITE_ESSAY: { prompt: true, wordCount: true },
  MC_READING_SINGLE: { prompt: true, options: true, correctOption: true },
  MC_READING_MULTIPLE: { prompt: true, options: true, correctOption: true },
  RE_ORDER_PARAGRAPHS: { options: true },
  FILL_IN_THE_BLANKS_DRAG_AND_DROP: { prompt: true, options: true, correctOption: true },
  FILL_IN_THE_BLANKS_DROPDOWN: { prompt: true, options: true, correctOption: true },
  SUMMARIZE_SPOKEN_TEXT: { audio: true, wordCount: true },
  MC_LISTENING_SINGLE: { audio: true, options: true, correctOption: true },
  MC_LISTENING_MULTIPLE: { audio: true, options: true, correctOption: true },
  FILL_IN_THE_BLANKS_TYPE_IN: { audio: true, prompt: true, correctAnswer: true },
  HIGHLIGHT_CORRECT_SUMMARY: { audio: true, options: true, correctOption: true },
  SELECT_MISSING_WORD: { audio: true, options: true, correctOption: true },
  HIGHLIGHT_INCORRECT_WORDS: { audio: true, prompt: true, correctAnswer: true },
  WRITE_FROM_DICTATION: { audio: true, correctAnswer: true }
};

const MC_TASK_TYPES = new Set([
  'MC_READING_SINGLE',
  'MC_READING_MULTIPLE',
  'MC_LISTENING_SINGLE',
  'MC_LISTENING_MULTIPLE',
  'HIGHLIGHT_CORRECT_SUMMARY',
  'SELECT_MISSING_WORD'
]);

const CP1252_EXTRA_BYTES = new Map([
  ['€', 0x80], ['‚', 0x82], ['ƒ', 0x83], ['„', 0x84], ['…', 0x85],
  ['†', 0x86], ['‡', 0x87], ['ˆ', 0x88], ['‰', 0x89], ['Š', 0x8a],
  ['‹', 0x8b], ['Œ', 0x8c], ['Ž', 0x8e], ['‘', 0x91], ['’', 0x92],
  ['“', 0x93], ['”', 0x94], ['•', 0x95], ['–', 0x96], ['—', 0x97],
  ['˜', 0x98], ['™', 0x99], ['š', 0x9a], ['›', 0x9b], ['œ', 0x9c],
  ['ž', 0x9e], ['Ÿ', 0x9f]
]);

function getSourceRoot() {
  const index = process.argv.indexOf('--source');
  return path.resolve(index >= 0 && process.argv[index + 1] ? process.argv[index + 1] : DEFAULT_SOURCE_ROOT);
}

function mojibakeScore(value) {
  return (value.match(/(?:Ã|Â|â|ð|æ|å|ç|ï¬|€|™)/g) || []).length;
}

function decodeWindows1252AsUtf8(value) {
  const bytes = [];
  for (const character of value) {
    const codePoint = character.codePointAt(0);
    if (codePoint <= 0xff) {
      bytes.push(codePoint);
      continue;
    }
    const byte = CP1252_EXTRA_BYTES.get(character);
    if (byte === undefined) return null;
    bytes.push(byte);
  }
  const decoded = Buffer.from(bytes).toString('utf8').normalize('NFKC');
  return decoded.includes('\ufffd') ? null : decoded;
}

function repairMojibake(value) {
  let current = value;
  for (let attempt = 0; attempt < 2; attempt += 1) {
    const candidate = decodeWindows1252AsUtf8(current);
    if (!candidate || mojibakeScore(candidate) >= mojibakeScore(current)) break;
    current = candidate;
  }
  return current.normalize('NFKC');
}

function cleanText(value) {
  if (value === null || value === undefined) return null;
  const repaired = repairMojibake(String(value))
    .replace(/\ufeff/g, '')
    .replace(/\u00a0/g, ' ')
    .replace(/\r\n?/g, '\n')
    .split('\n')
    .map((line) => line.replace(/[ \t]+$/g, '').trim())
    .join('\n')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
  return repaired || null;
}

function cleanUrl(value) {
  const url = cleanText(value);
  return url && /^https?:\/\//i.test(url) ? url : null;
}

function cleanLabels(labels) {
  return Array.isArray(labels)
    ? labels.map((label) => ({
        label: cleanText(label?.label),
        id: cleanText(label?.id),
        color: cleanText(label?.color)
      }))
    : [];
}

function parseStructuredPrompt(value) {
  const text = cleanText(value);
  if (!text) return { promptText: null, embeddedAnswerText: null };
  const sections = text.split(/-{4,}/g).map((section) => section.trim()).filter(Boolean);
  const questionSection = sections.find((section) => /^Question:\s*/i.test(section));
  const answerSection = sections.find((section) => /^Correct Answer:\s*/i.test(section));
  if (!questionSection && !answerSection) {
    return { promptText: text, embeddedAnswerText: null };
  }
  const passage = cleanText(sections[0]);
  const question = questionSection
    ? cleanText(questionSection.replace(/^Question:\s*/i, ''))
    : null;
  const answer = answerSection
    ? cleanText(answerSection.replace(/^Correct Answer:\s*/i, ''))
    : null;
  return {
    promptText: [passage, question].filter(Boolean).join('\n\n') || null,
    embeddedAnswerText: answer
  };
}

function parseAnswerQuestion(value) {
  const text = cleanText(value);
  if (!text) return { promptText: null, answerText: null };
  const answerMatch = /\bAnswer:\s*/i.exec(text);
  if (!answerMatch) return { promptText: text, answerText: null };
  return {
    promptText: cleanText(text.slice(0, answerMatch.index)),
    answerText: cleanText(text.slice(answerMatch.index + answerMatch[0].length))
  };
}

function parseNumberedAnswers(value) {
  const text = cleanText(value);
  if (!text) return new Map();
  const answers = new Map();
  for (const part of text.split(/\s*,\s*/)) {
    const match = /^(\d+)\s*\.\s*(.+)$/.exec(part.trim());
    if (match) answers.set(Number(match[1]) - 1, cleanText(match[2]));
  }
  return answers;
}

function comparable(value) {
  return (cleanText(value) || '')
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, ' ')
    .trim();
}

function makeOption(text, correct, orderIndex, blankIndex = null, correctGapIndex = null) {
  return {
    text: cleanText(text),
    correct: Boolean(correct),
    orderIndex,
    blankIndex,
    correctGapIndex
  };
}

function relativeDocPath(filePath) {
  return path.relative(DOC_ROOT, filePath).replaceAll(path.sep, '/');
}

function listJsonFiles(directory) {
  const files = [];
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const fullPath = path.join(directory, entry.name);
    if (entry.isDirectory()) files.push(...listJsonFiles(fullPath));
    else if (entry.isFile() && entry.name.toLowerCase().endsWith('.json')) files.push(fullPath);
  }
  return files.sort();
}

function sourceKey(source) {
  return (source?.file || '') + ':' + (source?.id ?? '') + ':' + (source?.num ?? '');
}

function loadRawSourceIndex() {
  const index = new Map();
  for (const filePath of listJsonFiles(DATA_ROOT)) {
    if (filePath.startsWith(OUTPUT_ROOT + path.sep)) continue;
    const relativeFile = relativeDocPath(filePath);
    const values = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    if (!Array.isArray(values)) continue;
    for (const item of values) {
      index.set(relativeFile + ':' + (item.id ?? '') + ':' + (item.num ?? ''), item);
    }
  }
  return index;
}

function parseReorderOptions(rawItem) {
  const prediction = cleanText(rawItem?.prediction_text);
  const answerText = cleanText(rawItem?.answer_in_text);
  const answerNumbers = answerText
    ?.split(',')
    .map((part) => Number.parseInt(part.trim(), 10))
    .filter((part) => Number.isInteger(part) && part > 0) || [];
  if (!prediction || answerNumbers.length === 0) return { options: [], correctAnswerText: answerText };

  const sections = prediction.split(/-{4,}/g).map((part) => part.trim()).filter(Boolean);
  const body = sections[0] || '';
  const lines = body.split('\n').map((line) => line.trim()).filter(Boolean);
  if (lines[0] && /correct\s+order/i.test(lines[0])) lines.shift();
  const orderedText = answerNumbers.length === lines.length
    ? answerNumbers.map((number) => lines[number - 1]).filter(Boolean)
    : lines;
  return {
    options: orderedText.map((text, index) => makeOption(text, false, index)),
    correctAnswerText: answerText
  };
}

function normalizeFillingOptions(taskTypeKey, item) {
  const sourceOptions = Array.isArray(item.options) ? item.options : [];
  const answers = parseNumberedAnswers(item.correctAnswerText);

  if (taskTypeKey === 'FILL_IN_THE_BLANKS_DRAG_AND_DROP') {
    const usedGaps = new Set();
    return sourceOptions.map((option, orderIndex) => {
      const text = cleanText(option?.text ?? option);
      const match = [...answers.entries()].find(([gapIndex, answer]) =>
        !usedGaps.has(gapIndex) && comparable(answer) === comparable(text));
      if (match) usedGaps.add(match[0]);
      return makeOption(text, Boolean(match), orderIndex, null, match ? match[0] : null);
    });
  }

  const nextOrderByBlank = new Map();
  const usedGaps = new Set();
  return sourceOptions.map((option) => {
    const blankIndex = Number.isInteger(option?.blankIndex) ? option.blankIndex : null;
    const orderIndex = Number.isInteger(option?.orderIndex)
      ? option.orderIndex
      : (nextOrderByBlank.get(blankIndex) || 0);
    nextOrderByBlank.set(blankIndex, orderIndex + 1);
    const match = [...answers.entries()].find(([gapIndex, answer]) =>
      gapIndex === blankIndex
      && !usedGaps.has(gapIndex)
      && comparable(answer) === comparable(option?.text));
    if (match) usedGaps.add(match[0]);
    return makeOption(option?.text, Boolean(match), orderIndex, blankIndex, null);
  });
}

function buildSource(item, cleanFile) {
  const original = item.source || {};
  const source = {
    file: cleanText(original.file),
    cleanFile,
    id: original.id ?? null,
    num: original.num ?? null,
    name: cleanText(original.name),
    nameWithoutNum: cleanText(original.nameWithoutNum),
    kind: cleanText(original.kind),
    examCount: original.examCount ?? null,
    labels: cleanLabels(original.labels)
  };
  if (original.explanation) source.explanation = cleanText(original.explanation);
  if (original.examNote) source.examNote = cleanText(original.examNote);
  if (original.transcript) source.transcript = cleanText(original.transcript);
  return source;
}

function buildRecord(item, cleanFile, rawSourceIndex) {
  const taskTypeKey = cleanText(item.taskTypeKey || item.pteTaskType);
  const section = cleanText(item.taskTypeSection);
  const source = buildSource(item, cleanFile);
  const rawItem = rawSourceIndex.get(sourceKey(source));
  const parsedPrompt = parseStructuredPrompt(item.promptText);
  let promptText = parsedPrompt.promptText;
  let referenceAnswerText = cleanText(item.referenceAnswerText);
  let correctAnswerText = cleanText(item.correctAnswerText) || parsedPrompt.embeddedAnswerText;
  let options = [];
  let minWordCount = Number.isInteger(item.minWordCount) ? item.minWordCount : null;
  let maxWordCount = Number.isInteger(item.maxWordCount) ? item.maxWordCount : null;

  if (MC_TASK_TYPES.has(taskTypeKey)) {
    options = (Array.isArray(item.options) ? item.options : [])
      .map((option, index) => makeOption(option?.text, option?.correct, index))
      .filter((option) => option.text);
    correctAnswerText = options.filter((option) => option.correct).map((option) => option.text).join('\n') || correctAnswerText;
  } else if (
    taskTypeKey === 'FILL_IN_THE_BLANKS_DRAG_AND_DROP'
    || taskTypeKey === 'FILL_IN_THE_BLANKS_DROPDOWN'
  ) {
    options = normalizeFillingOptions(taskTypeKey, item);
  } else if (taskTypeKey === 'RE_ORDER_PARAGRAPHS') {
    const reordered = parseReorderOptions(rawItem);
    options = reordered.options;
    correctAnswerText = reordered.correctAnswerText || correctAnswerText;
    promptText = null;
  }

  if (taskTypeKey === 'ANSWER_SHORT_QUESTION') {
    const parsedAnswer = parseAnswerQuestion(item.promptText || item.referenceAnswerText);
    promptText = parsedAnswer.promptText;
    correctAnswerText = parsedAnswer.answerText || correctAnswerText;
    referenceAnswerText = null;
  } else if (taskTypeKey === 'DESCRIBE_IMAGE') {
    promptText = null;
    referenceAnswerText = correctAnswerText;
    correctAnswerText = null;
  } else if (taskTypeKey === 'RESPOND_TO_A_SITUATION') {
    referenceAnswerText = correctAnswerText;
    correctAnswerText = null;
  } else if (
    taskTypeKey === 'SUMMARIZE_SPOKEN_TEXT'
    || taskTypeKey === 'SUMMARIZE_WRITTEN_TEXT'
    || taskTypeKey === 'WRITE_ESSAY'
    || taskTypeKey === 'WRITE_EMAIL'
  ) {
    referenceAnswerText = correctAnswerText;
    correctAnswerText = null;
  } else if (taskTypeKey === 'REPEAT_SENTENCE' || taskTypeKey === 'RE_TELL_LECTURE') {
    promptText = null;
    referenceAnswerText = referenceAnswerText || cleanText(item.promptText);
  } else if (taskTypeKey === 'WRITE_FROM_DICTATION') {
    promptText = null;
    correctAnswerText = correctAnswerText || cleanText(item.promptText);
  } else if (
    taskTypeKey === 'HIGHLIGHT_INCORRECT_WORDS'
    || taskTypeKey === 'FILL_IN_THE_BLANKS_TYPE_IN'
  ) {
    promptText = cleanText(item.promptText);
  }

  const record = {
    pteTaskType: TASK_REQUIREMENTS[taskTypeKey] ? taskTypeKey : null,
    taskTypeKey: TASK_REQUIREMENTS[taskTypeKey] ? taskTypeKey : null,
    taskTypeSection: section,
    title: cleanText(item.title) || source.nameWithoutNum || source.name || 'Untitled question',
    promptText,
    audioPromptUrl: cleanUrl(item.audioPromptUrl),
    imagePromptUrl: cleanUrl(item.imagePromptUrl),
    referenceAnswerText,
    correctAnswerText,
    minWordCount,
    maxWordCount,
    options,
    source,
    importWarnings: []
  };

  if (!record.taskTypeKey) record.importWarnings.push('UNSUPPORTED_TASK_TYPE');
  const requirements = TASK_REQUIREMENTS[record.taskTypeKey];
  if (requirements?.audio && !record.audioPromptUrl) record.importWarnings.push('AUDIO_URL_MISSING');
  if (requirements?.image && !record.imagePromptUrl) record.importWarnings.push('IMAGE_URL_MISSING');
  if (requirements?.prompt && !record.promptText) record.importWarnings.push('PROMPT_TEXT_MISSING');
  if (requirements?.options && options.length === 0) record.importWarnings.push('OPTIONS_MISSING');
  if (requirements?.correctOption && !options.some((option) => option.correct)) {
    record.importWarnings.push('CORRECT_OPTION_MISSING');
  }
  if (requirements?.correctAnswer && !requirements.correctOption && !cleanText(record.correctAnswerText)) {
    record.importWarnings.push('CORRECT_ANSWER_MISSING');
  }
  if (requirements?.wordCount && (minWordCount === null || maxWordCount === null)) {
    record.importWarnings.push('WORD_COUNT_MISSING');
  }
  if (record.audioPromptUrl) record.importWarnings.push('EXTERNAL_AUDIO_URL_REQUIRES_BACKEND_SUPPORT');
  if (record.imagePromptUrl) record.importWarnings.push('EXTERNAL_IMAGE_URL_REQUIRES_BACKEND_SUPPORT');
  record.importWarnings = [...new Set(record.importWarnings)];
  return record;
}

function writeJson(filePath, value) {
  fs.writeFileSync(filePath, JSON.stringify(value, null, 2) + '\n', 'utf8');
}

function countWarnings(records) {
  const counts = {};
  for (const record of records) {
    for (const warning of record.importWarnings) counts[warning] = (counts[warning] || 0) + 1;
  }
  return Object.fromEntries(Object.entries(counts).sort(([left], [right]) => left.localeCompare(right)));
}

function collectMedia(recordsByTaskType) {
  const media = { audio: new Map(), image: new Map() };
  for (const [taskTypeKey, records] of Object.entries(recordsByTaskType)) {
    for (const record of records) {
      for (const [kind, field] of [['audio', 'audioPromptUrl'], ['image', 'imagePromptUrl']]) {
        const url = record[field];
        if (!url) continue;
        const entry = media[kind].get(url) || { url, host: new URL(url).host, count: 0, taskTypes: [] };
        entry.count += 1;
        if (!entry.taskTypes.includes(taskTypeKey)) entry.taskTypes.push(taskTypeKey);
        media[kind].set(url, entry);
      }
    }
  }
  return {
    audio: [...media.audio.values()].sort((left, right) => left.url.localeCompare(right.url)),
    image: [...media.image.values()].sort((left, right) => left.url.localeCompare(right.url))
  };
}

function resetOutput() {
  if (fs.existsSync(OUTPUT_ROOT)) {
    if (!FORCE) throw new Error('Output exists; rerun with --force: ' + OUTPUT_ROOT);
    for (const generatedPath of [
      path.join(OUTPUT_ROOT, 'by-task-type'),
      path.join(OUTPUT_ROOT, 'quarantine'),
      path.join(OUTPUT_ROOT, 'manifest.json'),
      path.join(OUTPUT_ROOT, 'media-manifest.json')
    ]) {
      if (fs.existsSync(generatedPath)) fs.rmSync(generatedPath, { recursive: true, force: true });
    }
  }
  fs.mkdirSync(path.join(OUTPUT_ROOT, 'by-task-type'), { recursive: true });
  fs.mkdirSync(path.join(OUTPUT_ROOT, 'quarantine'), { recursive: true });
}

function main() {
  const sourceRoot = getSourceRoot();
  if (!fs.existsSync(sourceRoot)) throw new Error('Clean source not found: ' + sourceRoot);
  resetOutput();

  const rawSourceIndex = loadRawSourceIndex();
  const recordsByTaskType = {};
  const unsupportedRecords = {};
  const sourceFiles = [];
  const allRecords = [];

  for (const filePath of listJsonFiles(sourceRoot)) {
    const cleanFile = path.relative(sourceRoot, filePath).replaceAll(path.sep, '/');
    const values = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    if (!Array.isArray(values)) throw new Error('Expected an array in ' + filePath);
    const taskKeys = [...new Set(values.map((item) => item.taskTypeKey || item.pteTaskType))];
    if (taskKeys.length !== 1) throw new Error('Mixed task types in ' + filePath);

    const records = values
      .map((item) => buildRecord(item, cleanFile, rawSourceIndex))
      .sort((left, right) =>
        Number(left.source.num ?? Number.MAX_SAFE_INTEGER) - Number(right.source.num ?? Number.MAX_SAFE_INTEGER)
        || Number(left.source.id ?? Number.MAX_SAFE_INTEGER) - Number(right.source.id ?? Number.MAX_SAFE_INTEGER)
      );
    const taskTypeKey = records[0]?.taskTypeKey;
    sourceFiles.push({
      file: cleanFile,
      sourceTaskTypeKey: taskKeys[0] || null,
      taskTypeKey,
      section: records[0]?.taskTypeSection || null,
      count: records.length,
      warningCounts: countWarnings(records)
    });
    allRecords.push(...records);
    if (taskTypeKey) {
      recordsByTaskType[taskTypeKey] ??= [];
      recordsByTaskType[taskTypeKey].push(...records);
    } else {
      unsupportedRecords[taskKeys[0] || path.basename(filePath, '.json')] = records;
    }
  }

  for (const records of Object.values(recordsByTaskType)) {
    records.sort((left, right) =>
      Number(left.source.num ?? Number.MAX_SAFE_INTEGER) - Number(right.source.num ?? Number.MAX_SAFE_INTEGER)
      || Number(left.source.id ?? Number.MAX_SAFE_INTEGER) - Number(right.source.id ?? Number.MAX_SAFE_INTEGER)
    );
  }
  for (const [taskTypeKey, records] of Object.entries(recordsByTaskType).sort(([left], [right]) => left.localeCompare(right))) {
    writeJson(path.join(OUTPUT_ROOT, 'by-task-type', taskTypeKey + '.json'), records);
  }
  for (const [taskTypeKey, records] of Object.entries(unsupportedRecords).sort(([left], [right]) => left.localeCompare(right))) {
    writeJson(path.join(OUTPUT_ROOT, 'quarantine', taskTypeKey + '.json'), records);
  }

  const media = collectMedia(recordsByTaskType);
  const manifest = {
    schemaVersion: 'question-import-v2',
    generatedAt: new Date().toISOString(),
    sourceDataset: sourceRoot,
    sourceRoot: 'data',
    outputRoot: 'data/question-import',
    databaseTouched: false,
    recordCount: allRecords.length,
    canonicalTaskTypeCount: Object.keys(recordsByTaskType).length,
    unsupportedRecordCount: Object.values(unsupportedRecords).flat().length,
    warningCounts: countWarnings(allRecords),
    taskTypes: Object.fromEntries(Object.entries(recordsByTaskType)
      .sort(([left], [right]) => left.localeCompare(right))
      .map(([taskTypeKey, records]) => [
        taskTypeKey,
        {
          section: records[0]?.taskTypeSection || null,
          file: 'by-task-type/' + taskTypeKey + '.json',
          count: records.length,
          warningCounts: countWarnings(records)
        }
      ])),
    sourceFiles,
    unsupported: Object.fromEntries(Object.entries(unsupportedRecords).map(([key, records]) => [
      key,
      { file: 'quarantine/' + key + '.json', count: records.length }
    ])),
    media: {
      audioUrlCount: media.audio.length,
      imageUrlCount: media.image.length,
      audioHostCounts: Object.fromEntries(
        Object.entries(media.audio.reduce((counts, entry) => {
          counts[entry.host] = (counts[entry.host] || 0) + entry.count;
          return counts;
        }, {})).sort(([left], [right]) => left.localeCompare(right))
      )
    }
  };
  writeJson(path.join(OUTPUT_ROOT, 'manifest.json'), manifest);
  writeJson(path.join(OUTPUT_ROOT, 'media-manifest.json'), media);

  console.log(JSON.stringify({
    sourceDataset: sourceRoot,
    outputRoot: relativeDocPath(OUTPUT_ROOT),
    recordCount: allRecords.length,
    canonicalTaskTypeCount: Object.keys(recordsByTaskType).length,
    unsupportedRecordCount: Object.values(unsupportedRecords).flat().length,
    audioUrlCount: media.audio.length,
    imageUrlCount: media.image.length,
    warningCounts: manifest.warningCounts
  }, null, 2));
}

main();
