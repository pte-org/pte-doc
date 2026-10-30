# PTEPrep Practice Rubric v1

**Project:** PTEPrep: An AI-Powered PTE Practice Platform and Realistic Exam Simulator  
**Rubric ID:** `PTEPREP-PRACTICE-RUBRIC`  
**Version:** `1.0-draft`  
**Status:** Draft — requires Academic Manager approval before publication  
**Owner:** Academic Manager  
**Last updated:** 2026-10-23

This is an internal learning rubric for PTEPrep practice. It is not an official
Pearson/PTE Academic scoring table, does not reproduce a Pearson score
conversion, and must not be presented as a certified examination result.

## 1. Purpose and use

The rubric tells the system what evidence to inspect and how to describe a
Student's performance. It is used for:

- consistent qualitative feedback across repeated practice attempts;
- explaining an objective answer against the approved answer key or reference;
- identifying which part of a Writing or Speaking response needs practice;
- recording when a criterion cannot be assessed from the available evidence;
- giving Academic Staff and the Academic Manager a reviewable versioned policy.

The rubric is not a prompt. Gemini may receive a rubric projection, but the
model cannot change the approved answer, invent source evidence, or create a
new criterion. A new criterion requires a new rubric revision and academic
review.

## 2. Practice scoring policy

| Area | Policy in rubric v1 |
|---|---|
| Reading objective tasks | Use the pinned deterministic evaluator. Return correctness or partial correctness and an evidence-based explanation. |
| Listening objective tasks | Use the pinned deterministic evaluator after the required audio/content evidence is available. Return correctness or partial correctness and an evidence-based explanation. |
| Writing | Return qualitative criterion feedback first. Do not publish an AI numeric score. |
| Speaking | Return qualitative criterion feedback only when the required source and response evidence is available. Do not publish an AI numeric score. |
| Personal Introduction | Coaching only; it is not a scored task. |
| Official result | Practice feedback is never an official PTE score or an exam report. |

The practice result distinguishes four independent concepts:

1. **Correctness:** the deterministic result for an objective task.
2. **Criterion level:** a qualitative description such as `DEVELOPING` or
   `EFFECTIVE`.
3. **Evidence coverage:** `FULL`, `LIMITED`, or `NOT_ASSESSABLE`.
4. **Learning advice:** a concrete next action grounded in the submitted
   response.

The system must not convert a qualitative level into a number merely because
the interface has a score field. Numeric AI scoring requires a later approved
calibration policy, human-rated corpus, agreement target, release decision and
versioned evaluator.

## 3. Common criterion levels

The following labels are used for Writing and Speaking feedback. They are
descriptions, not bands or points.

| Level | Meaning | Required feedback behaviour |
|---|---|---|
| `NOT_ASSESSABLE` | Required evidence is absent, corrupted, ambiguous, or outside the rubric's supported scope. | State the missing evidence and do not infer a weakness or award a zero. |
| `NEEDS_SUPPORT` | The response does not yet satisfy the task requirement or the problem repeatedly blocks understanding. | Identify the exact response evidence and give one practical correction. |
| `DEVELOPING` | The response addresses part of the task, but coverage, control, organization or accuracy is inconsistent. | Name what is working and the highest-value improvement. |
| `EFFECTIVE` | The response fulfils the task and is generally understandable, with some correctable weaknesses. | Give evidence for the successful behaviour and one refinement. |
| `STRONG` | The response fulfils the task clearly and consistently within the available evidence. | Explain the evidence and suggest a stretch improvement; do not claim official proficiency. |

Objective tasks use a separate result vocabulary:

| Result | Meaning |
|---|---|
| `CORRECT` | The submitted answer matches the pinned accepted answer or accepted variant. |
| `PARTIALLY_CORRECT` | The evaluator grants partial credit under the pinned task policy. |
| `INCORRECT` | The submitted answer does not match an accepted answer under the pinned policy. |
| `NOT_ASSESSABLE` | The source, key, or submitted structure is not valid enough to evaluate safely. |

## 4. Evidence and limitation rules

Every criterion feedback item contains:

- `criterionId`: stable identifier from this document;
- `level`: one of the approved qualitative levels;
- `feedback`: short explanation written for the Student;
- `evidence`: the exact response span, paragraph, token, transcript segment,
  option, or source relation supporting the feedback.

The evaluator must follow these rules:

- Do not quote text that is not present in the Student response or approved
  source.
- Do not treat the Student's confidence selection as evidence of quality.
- Do not infer pronunciation, fluency or prosody from a text transcript alone.
- Do not infer image coverage without the pinned image and approved image
  annotations.
- If a recording is missing, silent, clipped, or unavailable to the approved
  assessor, mark the affected criteria `NOT_ASSESSABLE`.
- A broken reference answer is a content-quality issue for Academic review;
  it is not a reason to silently change the answer key or mark the Student
  incorrect.
- AI-generated feedback is educational content and must show its limitation
  when evidence is incomplete.

## 5. Task-family rubric matrix

### 5.1 Reading objective tasks

| Task family | Evaluation criteria | Student-facing explanation |
|---|---|---|
| Multiple-choice single | `ANSWER_MATCH` | Show the selected option and the approved option; explain the source phrase or relationship that supports the key. |
| Multiple-choice multiple | `ANSWER_SET` | Identify correct selections and unnecessary selections according to the pinned partial-credit policy. |
| Re-order paragraphs | `SEQUENCE_RELATION` | Explain the paragraph relationship that makes the accepted order coherent. Do not expose internal correct indexes before submission. |
| Fill in the blanks drag and drop | `BLANK_MATCH` | Explain the grammar, collocation or meaning relation for each affected blank. |
| Fill in the blanks dropdown | `BLANK_MATCH` | Explain why the accepted option fits the blank and why the selected option does not, when evidence supports it. |

Reading objective feedback is generated from the pinned passage, options,
answer key and evaluator revision. Gemini may improve the wording of the
explanation, but it cannot override the deterministic result.

### 5.2 Listening objective tasks

| Task family | Evaluation criteria | Student-facing explanation |
|---|---|---|
| Multiple-choice single | `ANSWER_MATCH` | Explain the selected option against the approved audio-derived source or transcript evidence. |
| Multiple-choice multiple | `ANSWER_SET` | Explain correct and incorrect selections under the pinned partial-credit policy. |
| Fill in the blanks type in | `TOKEN_MATCH` | Explain accepted spelling/normalization and identify missing or incorrect tokens. |
| Highlight correct summary | `SUMMARY_MATCH` | Explain the key idea relation supporting the accepted summary. |
| Select missing word | `CONTEXT_MATCH` | Explain the local sentence context and source continuation supporting the accepted option. |
| Highlight incorrect words | `TOKEN_MATCH` | Explain each incorrect token against the pinned transcript/token mapping. |
| Write from dictation | `TOKEN_MATCH` | Identify omitted, substituted or misspelled tokens using the approved normalization policy. |

If the audio source or transcript revision is not available, the system keeps
the answer and reports `NOT_ASSESSABLE` rather than guessing from the Student
selection.

### 5.3 Summarize Written Text

| Criterion ID | What is assessed | `NEEDS_SUPPORT` example | `EFFECTIVE` example |
|---|---|---|---|
| `SOURCE_COVERAGE` | Captures the main idea and the important supporting relationship from the passage. | Misses the main claim or replaces it with an unrelated detail. | Communicates the central idea and the relevant relationship accurately. |
| `FAITHFULNESS` | Does not add unsupported claims or change the source meaning. | Adds a claim that cannot be found in the passage or reverses a relationship. | Uses an accurate paraphrase without unsupported additions. |
| `FORM` | Meets the pinned sentence and word-count rules. | Violates the required sentence/word policy. | Meets the pinned form policy. |
| `GRAMMAR` | Sentence structure, agreement, tense, punctuation and clarity. | Repeated errors make the sentence difficult to understand. | Minor errors do not block the intended meaning. |
| `VOCABULARY` | Appropriate, precise and varied word choice for the source meaning. | Frequent misuse or repetition obscures the idea. | Word choice is generally accurate and suitable. |

Form is checked deterministically from the pinned task policy. Gemini must not
guess a word count or replace the server result.

### 5.4 Write Essay

| Criterion ID | What is assessed | Evidence expected |
|---|---|---|
| `TASK_FULFILMENT` | Answers the prompt and addresses all required parts. | Prompt requirement references and relevant response spans. |
| `DEVELOPMENT_SUPPORT` | Develops claims with relevant reasons, examples or explanation. | Claim-to-support relationship in the response. |
| `ORGANIZATION_COHERENCE` | Logical order, paragraph purpose, transitions and readable progression. | Paragraph and sentence relations, not a generic compliment. |
| `GRAMMAR` | Sentence construction, agreement, tense, articles, punctuation and clarity. | Exact quote, location and suggested correction when applicable. |
| `VOCABULARY` | Accuracy, range, collocation and appropriateness. | Exact word or phrase plus context; do not invent an error. |
| `SPELLING` | Spelling and word-form accuracy. | Exact misspelled token and correction. |
| `FORM` | Pinned word-count and essay-form constraints. | Server-calculated form result and policy version. |

The feedback must separate content quality from language correction. It must
not claim that a suggested rewrite is the only acceptable answer.

### 5.5 Speaking tasks

Speaking criteria are task-specific. A criterion is only applied when its
required evidence is available.

| Criterion ID | Applicable tasks | Evidence requirement |
|---|---|---|
| `TASK_FULFILMENT` | Describe Image, Respond to a Situation, Summarize Group Discussion | Pinned task requirements plus response transcript/audio. |
| `CONTENT_COVERAGE` | Read Aloud, Repeat Sentence, Describe Image, Re-tell Lecture, Answer Short Question, Respond to a Situation, Summarize Group Discussion | Approved source/reference and response transcript. |
| `PRONUNCIATION` | Read Aloud, Repeat Sentence, Answer Short Question and other supported speech tasks | Response audio and an approved speech assessor. Transcript alone is insufficient. |
| `FLUENCY` | All supported scored Speaking tasks | Response audio, timing and pause evidence from an approved assessor. |
| `PROSODY` | Read Aloud and supported speech tasks | Response audio and assessor output; mark unavailable when the assessor cannot provide it. |
| `LANGUAGE_CONTROL` | Describe Image, Re-tell Lecture, Respond to a Situation, Summarize Group Discussion | Transcript plus task-specific language evidence. |
| `REGISTER_APPROPRIATENESS` | Respond to a Situation, Summarize Group Discussion | Situation/discussion requirements plus response evidence. |

Task-specific requirements:

- **Read Aloud:** compare spoken words with the pinned text. Missing or
  mismatched words affect `CONTENT_COVERAGE`; pronunciation, fluency and
  prosody require audio evidence.
- **Repeat Sentence:** compare the response with the pinned reference. Do not
  mark a semantically similar sentence correct when the task requires the
  reference wording unless the approved policy allows that variant.
- **Describe Image:** assess only relationships and facts supported by the
  pinned image annotations. Do not reward invented values or details.
- **Re-tell Lecture:** assess coverage and faithfulness against the pinned
  lecture transcript/source. Do not penalize a different valid wording merely
  because it differs from an example answer.
- **Answer Short Question:** use the accepted answer and approved variants;
  do not require a long explanation for a short-answer task.
- **Respond to a Situation:** assess whether the response fulfils the situation
  and uses an appropriate register, not whether it copies a sample response.
- **Summarize Group Discussion:** assess the main topic, contributions and
  relationships only when the discussion source and speaker evidence are
  pinned.
- **Personal Introduction:** provide optional coaching and never include it in
  a scored practice result.

### 5.6 Summarize Spoken Text

| Criterion ID | What is assessed |
|---|---|
| `SOURCE_COVERAGE` | Covers the important ideas from the approved lecture transcript. |
| `FAITHFULNESS` | Preserves the source meaning and does not add unsupported claims. |
| `ORGANIZATION_COHERENCE` | Presents the summary in a clear, understandable order. |
| `GRAMMAR` | Uses understandable and appropriately formed sentences. |
| `VOCABULARY` | Uses suitable words and collocations to express the source ideas. |
| `SPELLING` | Uses correct spelling and recognizable word forms. |
| `FORM` | Meets the pinned word-count and response-form policy. |

The lecture transcript is a restricted evaluation reference. It must not be
returned to the Student as a hidden answer key. Feedback should quote only
the minimum approved evidence needed to explain the result.

## 6. Practice AI provider boundary

Rubric v1 intentionally separates the provider used for exam scoring from the
provider used for practice explanations:

- Practice explanation uses Gemini when `PRACTICE_AI_ENABLED=true`.
- Practice Writing receives text-based qualitative feedback.
- Practice Speaking does not send raw audio to the current explanation
  generator. Pronunciation, fluency and prosody therefore remain
  `NOT_ASSESSABLE` until an approved audio assessor is connected to the
  practice evidence pipeline.
- The existing exam scoring configuration may use Azure Speech plus Gemini for
  Exam Speaking, and Gemini for Exam Writing. That configuration does not
  automatically apply to Practice.

## 7. AI explanation output contract

For each applicable criterion, the generated result must contain:

```json
{
  "criterionId": "GRAMMAR",
  "level": "DEVELOPING",
  "feedback": "The main idea is understandable, but verb agreement changes in the second sentence.",
  "evidence": "submitted_response.sentence_2: \"...\""
}
```

The full explanation also contains a summary, strengths, improvements and the
rubric version. The result must:

- preserve the deterministic objective result;
- use the requested language (`vi` by default, `en` when selected);
- identify unavailable evidence instead of fabricating it;
- preserve the model/version and immutable submission hash for later review;
- avoid official score, band, certificate or Pearson-affiliation claims.

## 8. Quality and approval checklist

Academic Manager approval is required before this revision is published as
`PUBLISHED`. Older score-template documentation may use `ACTIVE`; rubric
storage and API responses use `PUBLISHED` as the canonical status.

- [ ] Every in-scope task has an approved reference, answer key or source
  artifact.
- [ ] Criterion descriptors have at least one good, developing and weak anchor
  response.
- [ ] Empty, garbled, off-topic and adversarial responses have an approved
  handling decision.
- [ ] Accepted paraphrases and normalization rules are documented for objective
  tasks.
- [ ] Audio, transcript and image evidence requirements are testable.
- [ ] Human reviewers agree on the qualitative labels for the calibration set.
- [ ] The output schema rejects missing criteria, invented evidence and
  unsupported numeric scores.
- [ ] A new rubric revision has a change reason, reviewer, decision date and
  compatibility statement.

Until all required checks are complete, the rubric remains `DRAFT`, and the
Practice UI must describe feedback as educational guidance rather than a
certified score.

## 9. Versioning rules

- A published rubric revision is immutable.
- A question/session pins the rubric revision used for its explanation.
- Correcting a rubric creates a new revision; it does not rewrite historical
  feedback.
- Retiring a revision prevents it from being selected for new sessions but
  keeps historical reads available under the approved retention policy.
- Changing provider, prompt schema, criterion meaning or evidence policy
  requires a new revision or an explicit compatibility review.
