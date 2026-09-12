# Visual Conformance Report

**Date:** 2026-09-12  
**Implementation:** `D:\GitHub\pte-org\pte-app`  
**Preview entrypoint:** `lib/dev/exam_ui_preview_main.dart`

## Automated visual smoke

Command:

```text
$env:NODE_PATH='D:\GitHub\pte-org\.codex\skills\playwright-skill\node_modules'; node D:\tmp\playwright-test-exam-ui-preview.js
```

Result:

- Catalog entries opened: 23.
- Screenshots captured: 23.
- Viewport: `1280x800`, DPR 1, fixed runner scale.
- Screenshot hashes: 23 unique hashes; advancing the footer changed the task
  state for every entry.
- Local-only interaction smoke passed for open, next item and save/exit.
- No API request, microphone access, outbox write or submit side effect is
  created by the preview path.

## Coverage classification

The catalog contains all 23 task types from `design-coverage-matrix.md`:

- 21 entries use the corresponding direct design family/reference.
- `SUMMARIZE_GROUP_DISCUSSION` uses the approved derived audio-prompt fallback.
- `RESPOND_TO_A_SITUATION` uses the approved derived audio-prompt fallback.

The screens expose the shared 56px header/footer, semantic instruction and
metadata blocks, stimulus region, family-specific response region, status or
help state, and local navigation. Record-response previews include preparation
status, progress, audio-level treatment and timing boxes. Free-text previews
include the editor toolbar, textarea and local word metric. Fill-blank,
multi-select, ordering and token-toggle previews expose their corresponding
interactive controls.

## Final engineering gates

| Gate | Result |
|---|---|
| `flutter analyze` | Passed, 0 issues |
| `flutter test --reporter compact` | Passed, 582 tests |
| Preview web release build | Passed |
| Core/shared-widget architecture scan | Passed |
| `git diff --check` | Passed |

The final source recheck after the preview word-tokenization fix repeated
`flutter analyze`, the focused preview tests, the full `582`-test suite, the
preview Web release build and the 23-screen browser smoke.

The full application entrypoint still depends on the repository's existing
native `sqlite3`/`dart:ffi` desktop path. The pure preview entrypoint was used
for browser validation so missing `pte-api` integration and native desktop
dependencies do not block design review.
