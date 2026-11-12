# Practice: AI scoring on demand, Capstone listens to the audio, feedback after scoring

Status: implemented (2026-11-12); verification in `pte-doc/plans/reports/261112-practice-on-demand-ai-scoring-verification.md`
Author: quang

## Context

- Today a practice answer is scored as soon as it is submitted (`PracticeAnswerScoringRouter.scoreOrQueue`). Objective types are scored inline. Speech and writing go to the AI worker queue.
- Speaking is scored by Azure Speech (pronunciation, fluency, words) plus Gemini/Capstone (content, from Azure's transcript).
  - Azure does not take the Pearson rubric. It returns raw 0–100 scores, which the uncalibrated `AzureBandMapping` v1 converts to 0–5 bands.
- Probed on 2026-11-11: the `Capstone` model on the gateway declares `audioInput: true`.
  - `input_audio` (wav base64) through `/v1/chat/completions` works.
  - It transcribes exactly.
  - On a poor Read Aloud (fillers, repetition, a substituted word, omissions) it returned content 2–3, fluency 2 and pronunciation 3, and named every error.
  - Cost is about 2.2k tokens per short answer.

## Decisions (user, 2026-11-11)

1. **Practice speaking is scored by Capstone listening to the audio**, with the task type's Pearson rubric in the prompt. **Exams keep Azure.** Cost is not a constraint.
2. **AI scoring only on demand.** Objective task types are still scored inline on submit. Speech and writing are **not** scored until the student presses "Chấm điểm".
3. **TASK/SKILL:** the "Chấm điểm" button appears on the item right after it is submitted.
4. **MOCK_TEST:** after the test is submitted, one "Chấm điểm" button scores every AI item, then shows the full report with per-item feedback.
5. **One score per answer.** An item can be scored again only after it is re-done (new recording or text). No re-roll of the same answer. The existing retry stays for FAILED.
6. **Feedback after scoring**, from the same model call:
   - every trait as a Pearson band, each with a one-sentence reason;
   - the transcript;
   - word marks (omitted, substituted, inserted) for scripted tasks (RA, RS);
   - one or two concrete tips.

## Phases

| # | Phase | File |
|---|---|---|
| 1 | Capstone audio scorer for practice speaking | [phase-01-capstone-audio-scorer.md](phase-01-capstone-audio-scorer.md) |
| 2 | On-demand scoring in the practice module | [phase-02-on-demand-scoring.md](phase-02-on-demand-scoring.md) |
| 3 | Feedback contract | [phase-03-feedback-contract.md](phase-03-feedback-contract.md) |
| 4 | pte-practice UI | [phase-04-practice-ui.md](phase-04-practice-ui.md) |
| 5 | Verification | [phase-05-verification.md](phase-05-verification.md) |

## Out of scope

- Exam scoring (stays Azure plus Gemini/Capstone as today).
- Calibrating Capstone bands against human raters (to measure later on real student recordings).
- Quotas or cost limits.
