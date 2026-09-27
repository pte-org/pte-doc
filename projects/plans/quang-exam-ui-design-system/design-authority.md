# Design Authority and Visual Contract

This file resolves the conflicting layers in the Stitch export before the
implementation starts.

## Authority order

1. Valid task `screen.html` and `screen.png`: visible composition and states.
2. `DESIGN.md`: product semantic roles, application typography and fixed shell.
3. `screens/36-*/tokens.json` and `screens/37-*/tokens.css`: generated
   component tokens and variants.
4. `screens/35-*/component-spec.md`: component behavior and state details.

## Locked values

- Material `primary`: `#004787`.
- Component `brand.primary` and `primary-container`: `#0B5FAE`.
- Header: `56px`.
- Footer: `56px`, matching `DESIGN.md` and valid canonical task HTML. The
  generated `64px` footer value is retained as a documented conflict note and
  is not used by the exam shell.
- Generic assessment content: `960px`.
- Reading workstation frame: `1160px` where the reading reference requires the
  wider layout.
- Visual golden reference: `2560x2048`, DPR 1, scroll `(0,0)`. A smaller runner
  must use one documented fixed scale transform and record it in the report.
- Application typography: the 10 Arimo styles defined in `DESIGN.md`; Arimo
  must be bundled or supplied by an approved offline package, never fetched at
  runtime during an exam.

## Coverage decisions

- There are 23 task types and 34 exported screen directories because the bundle
  also contains lifecycle/transition/completion screens and a duplicate Read
  Aloud asset.
- `01-read-aloud-*` is the canonical Read Aloud source. `12-read-aloud-*` has a
  valid PNG/state reference but invalid Google sign-in HTML.
- `SUMMARIZE_GROUP_DISCUSSION` and `RESPOND_TO_A_SITUATION` have no direct
  asset. They receive complete derived audio-prompt screens using existing
  tokens and are labeled as design-gap fallbacks in every visual report.

## Data and preview policy

- Runtime accepts existing `TaskView` and injected services; no API contract or
  state machine changes are needed.
- `TaskViewUiAdapter` belongs to
  `lib/features/exam_attempt/presentation/model/`. Core widgets consume only
  the resulting UI model/props.
- `ExamUiPreviewCatalog` is deterministic, offline and read-only: local media,
  simulated record timing, no microphone/network/outbox/force-submit side
  effects. It is not a production fallback.

