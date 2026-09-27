'use strict';

const fs = require('node:fs');
const path = require('node:path');

const DOC_ROOT = path.resolve(__dirname, '..');
const DATA_ROOT = path.join(DOC_ROOT, 'data');
const OUTPUT_ROOT = path.join(DATA_ROOT, 'question-import');
const FORCE = process.argv.includes('--force');

const SOURCE_MAPPINGS = {
  hiws: { taskTypeKey: 'HIGHLIGHT_INCORRECT_WORDS', section: 'LISTENING' },
  l_fib: { taskTypeKey: 'FILL_IN_THE_BLANKS_TYPE_IN', section: 'LISTENING' },
  l_hcs: { taskTypeKey: 'HIGHLIGHT_CORRECT_SUMMARY', section: 'LISTENING' },
  l_mcm: { taskTypeKey: 'MC_LISTENING_MULTIPLE', section: 'LISTENING' },
  l_mcs: { taskTypeKey: 'MC_LISTENING_SINGLE', section: 'LISTENING' },
  l_smw: { taskTypeKey: 'SELECT_MISSING_WORD', section: 'LISTENING' },
  ssts: { taskTypeKey: 'SUMMARIZE_SPOKEN_TEXT', section: 'LISTENING' },
  wfds: { taskTypeKey: 'WRITE_FROM_DICTATION', section: 'LISTENING' },
  fib_rd: { taskTypeKey: 'FILL_IN_THE_BLANKS_DRAG_AND_DROP', section: 'READING' },
  fib_wr: { taskTypeKey: 'FILL_IN_THE_BLANKS_DROPDOWN', section: 'READING' },
  r_mcm: { taskTypeKey: 'MC_READING_MULTIPLE', section: 'READING' },
  r_mcs: { taskTypeKey: 'MC_READING_SINGLE', section: 'READING' },
  ro: { taskTypeKey: 'RE_ORDER_PARAGRAPHS', section: 'READING' },
  answer_questions: { taskTypeKey: 'ANSWER_SHORT_QUESTION', section: 'SPEAKING' },
  describe_images: { taskTypeKey: 'DESCRIBE_IMAGE', section: 'SPEAKING' },
  read_alouds: { taskTypeKey: 'READ_ALOUD', section: 'SPEAKING' },
  repeat_sentences: { taskTypeKey: 'REPEAT_SENTENCE', section: 'SPEAKING' },
  respond_situations: { taskTypeKey: 'RESPOND_TO_A_SITUATION', section: 'SPEAKING' },
  retell_lectures: { taskTypeKey: 'RE_TELL_LECTURE', section: 'SPEAKING' },
  essays: { taskTypeKey: 'WRITE_ESSAY', section: 'WRITING' },
  swts: { taskTypeKey: 'SUMMARIZE_WRITTEN_TEXT', section: 'WRITING' },
  write_emails: { taskTypeKey: null, sourceTaskTypeKey: 'WRITE_EMAIL', section: 'WRITING' }
};

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

const CP1252_EXTRA_BYTES = new Map([
  ['€', 0x80],
  ['‚', 0x82],
  ['ƒ', 0x83],
  ['„', 0x84],
  ['…', 0x85],
  ['†', 0x86],
  ['‡', 0x87],
  ['ˆ', 0x88],
  ['‰', 0x89],
  ['Š', 0x8a],
  ['‹', 0x8b],
  ['Œ', 0x8c],
  ['Ž', 0x8e],
  ['‘', 0x91],
  ['’', 0x92],
  ['“', 0x93],
  ['”', 0x94],
  ['•', 0x95],
  ['–', 0x96],
  ['—', 0x97],
  ['˜', 0x98],
  ['™', 0x99],
  ['š', 0x9a],
  ['›', 0x9b],
  ['œ', 0x9c],
  ['ž', 0x9e],
  ['Ÿ', 0x9f]
]);

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
    if (byte === undefined) {
      return null;
    }
    bytes.push(byte);
  }

  const decoded = Buffer.from(bytes).toString('utf8').normalize('NFKC');
  return decoded.includes('\ufffd') ? null : decoded;
}

function repairMojibake(value) {
  let current = value;
  for (let attempt = 0; attempt < 2; attempt += 1) {
    const candidate = decodeWindows1252AsUtf8(current);
    if (!candidate || mojibakeScore(candidate) >= mojibakeScore(current)) {
      break;
    }
    current = candidate;
  }
  return current.normalize('NFKC');
}

function cleanText(value) {
  if (value === null || value === undefined) {
    return null;
  }

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
  if (!Array.isArray(labels)) {
    return [];
  }
  return labels.map((label) => ({
    label: cleanText(label?.label),
    id: cleanText(label?.id),
    color: cleanText(label?.color)
  }));
}

function stripDividers(value) {
  return cleanText(value?.replace(/-{4,}/g, ' '));
}

function parseStructuredPrediction(value) {
  const text = cleanText(value);
  if (!text) {
    return { promptText: null, embeddedAnswerText: null };
  }

  const sections = text
    .split(/-{4,}/g)
    .map((section) => section.trim())
    .filter(Boolean);
  const questionSection = sections.find((section) => /^Question:\s*/i.test(section));
  const answerSection = sections.find((section) => /^Correct Answer:\s*/i.test(section));
  if (!questionSection && !answerSection) {
    return { promptText: text, embeddedAnswerText: null };
  }

  const passage = stripDividers(sections[0]);
  const question = questionSection
    ? stripDividers(questionSection.replace(/^Question:\s*/i, ''))
    : null;
  const embeddedAnswerText = answerSection
    ? stripDividers(answerSection.replace(/^Correct Answer:\s*/i, ''))
    : null;

  return {
    promptText: [passage, question].filter(Boolean).join('\n\n') || null,
    embeddedAnswerText
  };
}

function parseAnswerQuestion(value) {
  const text = cleanText(value);
  if (!text) {
    return { promptText: null, answerText: null };
  }

  const answerMatch = /\bAnswer:\s*/i.exec(text);
  if (!answerMatch) {
    return { promptText: text, answerText: null };
  }

  return {
    promptText: cleanText(text.slice(0, answerMatch.index)),
    answerText: cleanText(text.slice(answerMatch.index + answerMatch[0].length))
  };
}

function parseReorderParagraphs(value) {
  const text = cleanText(value);
  if (!text) {
    return [];
  }

  const lines = text.split('\n').map((line) => line.trim()).filter(Boolean);
  if (lines[0] && /correct\s+order/i.test(lines[0])) {
    lines.shift();
  }
  return lines;
}

function parseOrder(value) {
  const answer = cleanText(value);
  if (!answer) {
    return [];
  }
  return answer
    .split(',')
    .map((part) => Number.parseInt(part.trim(), 10))
    .filter((part) => Number.isInteger(part) && part > 0);
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

function choiceText(choice) {
  if (typeof choice === 'string') {
    return cleanText(choice);
  }
  if (choice && typeof choice.choice === 'string') {
    return cleanText(choice.choice);
  }
  return null;
}

function choiceGroups(choices) {
  if (!Array.isArray(choices)) {
    return [];
  }
  if (choices.every((choice) => typeof choice === 'string')) {
    return [choices.map((choice) => cleanText(choice)).filter(Boolean)];
  }
  return choices.map((group) => {
    if (Array.isArray(group)) {
      return group.map((choice) => cleanText(choice)).filter(Boolean);
    }
    if (group && Array.isArray(group.value)) {
      return group.value.map((choice) => cleanText(choice)).filter(Boolean);
    }
    return [];
  });
}

function makeSource(relativeFile, item) {
  const source = {
    file: relativeFile,
    id: item.id ?? null,
    num: item.num ?? null,
    name: cleanText(item.name),
    nameWithoutNum: cleanText(item.name_without_num),
    kind: cleanText(item.kind),
    examCount: item.exam_count ?? null,
    labels: cleanLabels(item.labels)
  };

  const explanation = cleanText(item.explanation);
  const examNote = cleanText(item.exam_note);
  const transcript = cleanText(item.transcript);
  if (explanation) source.explanation = explanation;
  if (examNote) source.examNote = examNote;
  if (transcript) source.transcript = transcript;
  return source;
}

function buildRecord(item, mapping, sourceCode, relativeFile) {
  const parsed = parseStructuredPrediction(item.prediction_text);
  const rawPrediction = cleanText(item.prediction_text);
  const sourceAnswer = cleanText(item.answer_in_text);
  const embeddedAnswer = parsed.embeddedAnswerText;
  const audioPromptUrl = cleanUrl(item.audio_url);

  let promptText = parsed.promptText;
  let referenceAnswerText = null;
  let correctAnswerText = sourceAnswer || embeddedAnswer;
  let options = [];

  switch (sourceCode) {
    case 'l_hcs':
    case 'l_mcm':
    case 'l_mcs':
    case 'l_smw':
    case 'r_mcm':
    case 'r_mcs': {
      options = (Array.isArray(item.choices) ? item.choices : [])
        .map((choice, index) => makeOption(
          choiceText(choice),
          choice?.correct === true,
          index
        ))
        .filter((option) => option.text);
      if (!correctAnswerText) {
        correctAnswerText = options
          .filter((option) => option.correct)
          .map((option) => option.text)
          .join('\n') || null;
      }
      break;
    }
    case 'fib_rd': {
      const groups = choiceGroups(item.choices);
      const words = groups[0] || [];
      options = words.map((word, index) => makeOption(word, false, index));
      promptText = null;
      break;
    }
    case 'fib_wr': {
      const groups = choiceGroups(item.choices);
      let optionIndex = 0;
      options = groups.flatMap((group, blankIndex) => group.map((word) => {
        const option = makeOption(word, false, optionIndex, blankIndex, null);
        optionIndex += 1;
        return option;
      }));
      promptText = null;
      break;
    }
    case 'ro': {
      const paragraphs = parseReorderParagraphs(item.prediction_text);
      const order = parseOrder(item.answer_in_text);
      const reorderedParagraphs = order.length === paragraphs.length
        ? order.map((paragraphNumber) => paragraphs[paragraphNumber - 1]).filter(Boolean)
        : [];
      const orderedText = reorderedParagraphs.length === paragraphs.length
        ? reorderedParagraphs
        : paragraphs;
      options = orderedText.map((paragraph, index) => makeOption(paragraph, false, index));
      promptText = null;
      correctAnswerText = sourceAnswer || (order.length ? order.join(', ') : null);
      break;
    }
    case 'answer_questions': {
      const parsedAnswer = parseAnswerQuestion(item.prediction_text);
      promptText = parsedAnswer.promptText;
      correctAnswerText = sourceAnswer || parsedAnswer.answerText;
      break;
    }
    case 'describe_images':
      promptText = null;
      referenceAnswerText = sourceAnswer;
      break;
    case 'repeat_sentences':
    case 'retell_lectures':
      promptText = null;
      referenceAnswerText = rawPrediction;
      break;
    case 'respond_situations':
      promptText = rawPrediction;
      referenceAnswerText = sourceAnswer;
      break;
    case 'ssts':
      promptText = rawPrediction;
      referenceAnswerText = sourceAnswer;
      break;
    case 'essays':
    case 'swts':
    case 'write_emails':
      promptText = rawPrediction;
      referenceAnswerText = sourceAnswer;
      break;
    case 'wfds':
      promptText = null;
      correctAnswerText = rawPrediction || sourceAnswer;
      break;
    case 'hiws':
    case 'l_fib':
      promptText = cleanText(item.transcript) || rawPrediction;
      break;
    case 'read_alouds':
      promptText = rawPrediction;
      break;
    default:
      break;
  }

  const taskTypeKey = mapping.taskTypeKey;
  const fallbackTitle = 'Question ' + (item.num ?? item.id ?? '');
  const record = {
    pteTaskType: taskTypeKey,
    taskTypeKey,
    taskTypeSection: mapping.section,
    title: cleanText(item.name_without_num) || cleanText(item.name) || fallbackTitle.trim(),
    promptText,
    audioPromptUrl,
    imagePromptUrl: null,
    referenceAnswerText,
    correctAnswerText,
    minWordCount: null,
    maxWordCount: null,
    options,
    source: makeSource(relativeFile, item),
    importWarnings: []
  };

  if (!taskTypeKey) {
    record.importWarnings.push('UNSUPPORTED_TASK_TYPE');
  }

  const requirements = taskTypeKey ? TASK_REQUIREMENTS[taskTypeKey] : null;
  if (requirements?.audio && !audioPromptUrl) record.importWarnings.push('AUDIO_URL_MISSING');
  if (requirements?.image && !record.imagePromptUrl) record.importWarnings.push('IMAGE_URL_MISSING');
  if (requirements?.prompt && !record.promptText) record.importWarnings.push('PROMPT_TEXT_MISSING');
  if (requirements?.options && options.length === 0) record.importWarnings.push('OPTIONS_MISSING');
  if (requirements?.correctOption && !options.some((option) => option.correct)) {
    record.importWarnings.push('CORRECT_OPTION_MISSING');
  }
  if (requirements?.correctAnswer && !requirements.correctOption && !cleanText(correctAnswerText)) {
    record.importWarnings.push('CORRECT_ANSWER_MISSING');
  }
  if (requirements?.wordCount && (record.minWordCount === null || record.maxWordCount === null)) {
    record.importWarnings.push('WORD_COUNT_MISSING');
  }
  if (audioPromptUrl) record.importWarnings.push('EXTERNAL_AUDIO_URL_REQUIRES_BACKEND_SUPPORT');
  if (record.imagePromptUrl) record.importWarnings.push('EXTERNAL_IMAGE_URL_REQUIRES_BACKEND_SUPPORT');

  record.importWarnings = [...new Set(record.importWarnings)];
  return record;
}

function listJsonFiles(directory) {
  const files = [];
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const fullPath = path.join(directory, entry.name);
    if (fullPath === OUTPUT_ROOT || fullPath.startsWith(OUTPUT_ROOT + path.sep)) {
      continue;
    }
    if (entry.isDirectory()) {
      files.push(...listJsonFiles(fullPath));
    } else if (entry.isFile() && entry.name.toLowerCase().endsWith('.json')) {
      files.push(fullPath);
    }
  }
  return files.sort();
}

function relativePath(filePath) {
  return path.relative(DOC_ROOT, filePath).replaceAll(path.sep, '/');
}

function writeJson(filePath, value) {
  fs.writeFileSync(filePath, JSON.stringify(value, null, 2) + '\n', 'utf8');
}

function countWarnings(records) {
  const counts = {};
  for (const record of records) {
    for (const warning of record.importWarnings) {
      counts[warning] = (counts[warning] || 0) + 1;
    }
  }
  return Object.fromEntries(Object.entries(counts).sort(([left], [right]) => left.localeCompare(right)));
}

function collectMedia(recordsByTaskType) {
  const media = {
    audio: new Map(),
    image: new Map()
  };

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

function resetOutputDirectory() {
  if (fs.existsSync(OUTPUT_ROOT)) {
    if (!FORCE) {
      throw new Error('Output directory already exists. Review it or rerun with --force: ' + OUTPUT_ROOT);
    }
    for (const generatedPath of [
      path.join(OUTPUT_ROOT, 'by-task-type'),
      path.join(OUTPUT_ROOT, 'quarantine'),
      path.join(OUTPUT_ROOT, 'manifest.json'),
      path.join(OUTPUT_ROOT, 'media-manifest.json')
    ]) {
      if (fs.existsSync(generatedPath)) {
        fs.rmSync(generatedPath, { recursive: true, force: true });
      }
    }
  }
  fs.mkdirSync(path.join(OUTPUT_ROOT, 'by-task-type'), { recursive: true });
  fs.mkdirSync(path.join(OUTPUT_ROOT, 'quarantine'), { recursive: true });
}

function main() {
  resetOutputDirectory();

  const recordsByTaskType = {};
  const unsupportedRecords = {};
  const sourceFiles = [];
  const allRecords = [];

  for (const filePath of listJsonFiles(DATA_ROOT)) {
    const sourceCode = path.basename(filePath, '.json');
    const mapping = SOURCE_MAPPINGS[sourceCode] || {
      taskTypeKey: null,
      sourceTaskTypeKey: sourceCode.toUpperCase(),
      section: 'UNKNOWN'
    };
    const raw = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    if (!Array.isArray(raw)) {
      throw new Error('Expected an array in ' + filePath);
    }

    const relativeFile = relativePath(filePath);
    const records = raw
      .map((item) => buildRecord(item, mapping, sourceCode, relativeFile))
      .sort((left, right) =>
        Number(left.source.num ?? Number.MAX_SAFE_INTEGER) - Number(right.source.num ?? Number.MAX_SAFE_INTEGER)
        || Number(left.source.id ?? Number.MAX_SAFE_INTEGER) - Number(right.source.id ?? Number.MAX_SAFE_INTEGER)
      );

    sourceFiles.push({
      file: relativeFile,
      sourceTaskTypeKey: mapping.sourceTaskTypeKey || sourceCode.toUpperCase(),
      taskTypeKey: mapping.taskTypeKey,
      section: mapping.section,
      count: records.length,
      warningCounts: countWarnings(records)
    });
    allRecords.push(...records);

    if (mapping.taskTypeKey) {
      recordsByTaskType[mapping.taskTypeKey] ??= [];
      recordsByTaskType[mapping.taskTypeKey].push(...records);
    } else {
      unsupportedRecords[mapping.sourceTaskTypeKey || sourceCode.toUpperCase()] = records;
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
  for (const [sourceTaskTypeKey, records] of Object.entries(unsupportedRecords).sort(([left], [right]) => left.localeCompare(right))) {
    writeJson(path.join(OUTPUT_ROOT, 'quarantine', sourceTaskTypeKey + '.json'), records);
  }

  const media = collectMedia(recordsByTaskType);
  const manifest = {
    schemaVersion: 'question-import-v1',
    generatedAt: new Date().toISOString(),
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
    outputRoot: relativePath(OUTPUT_ROOT),
    recordCount: allRecords.length,
    canonicalTaskTypeCount: Object.keys(recordsByTaskType).length,
    unsupportedRecordCount: Object.values(unsupportedRecords).flat().length,
    audioUrlCount: media.audio.length,
    imageUrlCount: media.image.length,
    warningCounts: manifest.warningCounts
  }, null, 2));
}

main();
