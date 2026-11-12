# Phase 4: pte-practice UI

## TASK/SKILL session

- After an AI item is submitted, the item shows a primary **"Chấm điểm"** button, plus "Câu tiếp theo".
- Pressing it calls the item scoring endpoint and shows a scoring state. It polls the item until it is `SCORED` or `FAILED`.
- `SCORED` shows the feedback card:
  - Score: the item score and the trait bands, each with its reason.
  - Transcript: for RA/RS, the reference text with the word marks (omitted, substituted, inserted) highlighted.
  - Tips: one or two concrete tips.
- `FAILED` shows the existing retry action.
- Re-recording or rewriting the item brings the "Chấm điểm" button back.
- Objective items keep their instant result.

## Mock test

- The result page shows the objective part right away.
- AI items show "Chưa chấm" and there is one **"Chấm điểm"** button for the whole test.
- After pressing it: progress (n/N scored), then the full report and a per-item feedback card (the same component as above).

## Review / history

- Items scored earlier show the same feedback card.
- Unscored AI items show "Chưa chấm". In TASK/SKILL they show the button.

## Rules

- Copy goes in `common/i18n` (vi/en). There are no inline strings.
- Components stay under 150 lines and files under 300.
- The feedback card is one shared component under `features/practice`.
- Tests go in `tests/unit/` for:
  - the request and polling logic;
  - feedback rendering, including word marks;
  - the mock test button state.
