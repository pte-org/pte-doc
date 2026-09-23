'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const ROOT = path.resolve(__dirname, '..');
const DATA_ROOT = path.join(ROOT, 'data');
const OUTPUT_ROOT = path.join(DATA_ROOT, 'question-import');
const EXPECTED_RECORD_KEYS = [
  'pteTaskType',
  'taskTypeKey',
  'taskTypeSection',
  'title',
  'promptText',
  'audioPromptUrl',
  'imagePromptUrl',
  'referenceAnswerText',
  'correctAnswerText',
  'minWordCount',
  'maxWordCount',
  'options',
  'source',
  'importWarnings'
].sort();
const EXPECTED_OPTION_KEYS = [
  'blankIndex',
  'correct',
  'correctGapIndex',
  'orderIndex',
  'text'
].sort();

function listJsonFiles(directory, excludedRoot) {
  const files = [];
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const fullPath = path.join(directory, entry.name);
    if (excludedRoot && (fullPath === excludedRoot || fullPath.startsWith(excludedRoot + path.sep))) {
      continue;
    }
    if (entry.isDirectory()) {
      files.push(...listJsonFiles(fullPath, excludedRoot));
    } else if (entry.isFile() && entry.name.endsWith('.json')) {
      files.push(fullPath);
    }
  }
  return files;
}

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function countRawRecords() {
  return listJsonFiles(DATA_ROOT, OUTPUT_ROOT).reduce((total, filePath) => {
    const value = readJson(filePath);
    assert.ok(Array.isArray(value), 'Raw file is not an array: ' + filePath);
    return total + value.length;
  }, 0);
}

function main() {
  const taskDirectory = path.join(OUTPUT_ROOT, 'by-task-type');
  const quarantineDirectory = path.join(OUTPUT_ROOT, 'quarantine');
  const taskFiles = fs.readdirSync(taskDirectory).filter((name) => name.endsWith('.json')).sort();
  const quarantineFiles = fs.readdirSync(quarantineDirectory).filter((name) => name.endsWith('.json')).sort();
  const manifest = readJson(path.join(OUTPUT_ROOT, 'manifest.json'));
  const canonicalRecords = [];
  const taskCounts = {};
  let duplicateSourceKeys = 0;
  let duplicateOptionOrderIndexes = 0;
  let promptMetadataMarkers = 0;
  let mojibakeRecords = 0;
  let invalidUrlCount = 0;

  for (const file of taskFiles) {
    const taskTypeKey = path.basename(file, '.json');
    const values = readJson(path.join(taskDirectory, file));
    assert.ok(Array.isArray(values), 'Task file is not an array: ' + file);
    const sourceKeys = new Set();

    for (const record of values) {
      assert.deepEqual(Object.keys(record).sort(), EXPECTED_RECORD_KEYS, 'Schema mismatch in ' + file);
      assert.equal(record.pteTaskType, taskTypeKey, 'pteTaskType mismatch in ' + file);
      assert.equal(record.taskTypeKey, taskTypeKey, 'taskTypeKey mismatch in ' + file);
      assert.ok(record.source && typeof record.source.file === 'string', 'Missing source in ' + file);
      assert.ok(fs.existsSync(path.join(ROOT, record.source.file)), 'Missing raw source: ' + record.source.file);
      if (manifest.sourceDataset && record.source.cleanFile && fs.existsSync(manifest.sourceDataset)) {
        assert.ok(
          fs.existsSync(path.join(manifest.sourceDataset, record.source.cleanFile)),
          'Missing clean source: ' + record.source.cleanFile
        );
      }

      const sourceKey = record.source.file + ':' + record.source.id + ':' + record.source.num;
      if (sourceKeys.has(sourceKey)) duplicateSourceKeys += 1;
      sourceKeys.add(sourceKey);

      const optionIndexes = new Set();
      for (const option of record.options) {
        assert.deepEqual(Object.keys(option).sort(), EXPECTED_OPTION_KEYS);
        assert.equal(typeof option.orderIndex, 'number');
        const optionIdentity = record.taskTypeKey === 'FILL_IN_THE_BLANKS_DROPDOWN'
          ? String(option.blankIndex) + ':' + String(option.orderIndex)
          : String(option.orderIndex);
        if (optionIndexes.has(optionIdentity)) duplicateOptionOrderIndexes += 1;
        optionIndexes.add(optionIdentity);
      }
      if (record.taskTypeKey === 'FILL_IN_THE_BLANKS_DRAG_AND_DROP') {
        const correctOptions = record.options.filter((option) => option.correct);
        assert.ok(correctOptions.length > 0, 'DND has no correct options: ' + file);
        assert.equal(
          correctOptions.length,
          new Set(correctOptions.map((option) => option.correctGapIndex)).size,
          'DND correct gaps are not unique: ' + file
        );
        assert.ok(
          correctOptions.every((option) => option.correctGapIndex !== null && option.blankIndex === null),
          'DND option metadata is invalid: ' + file
        );
      }
      if (record.taskTypeKey === 'FILL_IN_THE_BLANKS_DROPDOWN') {
        const groups = new Map();
        for (const option of record.options) {
          const group = groups.get(option.blankIndex) || [];
          group.push(option);
          groups.set(option.blankIndex, group);
        }
        for (const [blankIndex, group] of groups) {
          assert.equal(
            group.filter((option) => option.correct).length,
            1,
            'Dropdown blank does not have exactly one correct option: ' + blankIndex
          );
        }
      }

      const prompt = record.promptText || '';
      if (
        /-{4,}/.test(prompt)
        || /\nQuestion:\s*\n/i.test(prompt)
        || /\nCorrect Answer:/i.test(prompt)
      ) {
        promptMetadataMarkers += 1;
      }

      const serialized = JSON.stringify(record);
      if (
        serialized.includes('ï¬')
        || serialized.includes('â€™')
        || serialized.includes('â€')
        || serialized.includes('æ­')
        || serialized.includes('æ°')
        || serialized.includes('Ã')
        || serialized.includes('Â')
        || serialized.includes('\ufffd')
      ) {
        mojibakeRecords += 1;
      }

      for (const field of ['audioPromptUrl', 'imagePromptUrl']) {
        if (record[field] !== null && !/^https:\/\//.test(record[field])) {
          invalidUrlCount += 1;
        }
      }
      canonicalRecords.push(record);
    }
    taskCounts[taskTypeKey] = values.length;
  }

  let quarantineRecords = 0;
  for (const file of quarantineFiles) {
    const values = readJson(path.join(quarantineDirectory, file));
    assert.ok(Array.isArray(values), 'Quarantine file is not an array: ' + file);
    quarantineRecords += values.length;
    for (const record of values) {
      assert.equal(record.taskTypeKey, null, 'Quarantine record has a canonical task type: ' + file);
    }
  }

  const mediaManifest = readJson(path.join(OUTPUT_ROOT, 'media-manifest.json'));
  const rawRecords = countRawRecords();

  assert.equal(rawRecords, 17362);
  assert.equal(canonicalRecords.length + quarantineRecords, rawRecords);
  assert.equal(manifest.recordCount, rawRecords);
  assert.equal(manifest.canonicalTaskTypeCount, taskFiles.length);
  assert.equal(manifest.unsupportedRecordCount, quarantineRecords);
  assert.equal(manifest.media.audioUrlCount, mediaManifest.audio.length);
  assert.equal(manifest.media.imageUrlCount, mediaManifest.image.length);
  assert.equal(duplicateSourceKeys, 0);
  assert.equal(duplicateOptionOrderIndexes, 0);
  assert.equal(promptMetadataMarkers, 0);
  assert.equal(mojibakeRecords, 0);
  assert.equal(invalidUrlCount, 0);
  assert.equal(manifest.media.audioHostCounts['dl26yht2ovo33.cloudfront.net'], 10610);
  assert.equal(manifest.media.imageUrlCount, 0);
  assert.ok(fs.existsSync(path.join(OUTPUT_ROOT, 'README.md')));

  console.log(JSON.stringify({
    rawFiles: listJsonFiles(DATA_ROOT, OUTPUT_ROOT).length,
    rawRecords,
    canonicalTaskFiles: taskFiles.length,
    canonicalRecords: canonicalRecords.length,
    quarantineFiles: quarantineFiles.length,
    quarantineRecords,
    duplicateSourceKeys,
    duplicateOptionOrderIndexes,
    promptMetadataMarkers,
    mojibakeRecords,
    invalidUrlCount,
    audioUrls: mediaManifest.audio.length,
    imageUrls: mediaManifest.image.length,
    taskCounts
  }, null, 2));
}

main();
