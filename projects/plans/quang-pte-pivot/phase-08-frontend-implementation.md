# Phase 8: Frontend Implementation

## Requirements

Implement task-type-specific UI and UX for all 20 PTE Academic task types in both pte-app (Flutter mobile) and pte-web (browser). Each task type has unique interaction patterns (e.g., Read Aloud requires audio recording; Multiple Choice requires click/select; Describe Image requires audio recording + optional text note; Re-order Paragraphs requires drag-reorder). This phase delivers the student-facing exam experience: task rendering, per-task timers, task progression, and result display for Speaking/Writing/Objective scores.

This phase directly addresses P1 user story: "I want to take a mock exam covering all 20 official PTE Academic task types (across Speaking & Writing, Reading, Listening) so that the experience matches the real test."

## Design Constraints

**Correction (2026-07-16, discovered during Phase 7 research):** the task-type count is **22**, not 20 — see `spec.md` Assumptions. The 2 added types (`RESPOND_TO_A_SITUATION`, `SUMMARIZE_GROUP_DISCUSSION`) are both Speaking, reusing the same audio-recording interaction pattern as Read Aloud/Repeat Sentence — no new UI widget category needed, just 2 more entries in the task-type renderer.

- Frontend must **faithfully represent the 20 task types** with interactions matching real PTE as closely as possible (read-aloud audio recording, drag-reorder, multiple-choice click, type-in text input, etc.). Shortcuts are acceptable only if documented.
- Per-task **timer display must be accurate and synchronized** with backend timers (same constraints as Phase 2): frontend displays countdown, falls back to local timer if network drops, but backend is source of truth for expiration.
- The frontend **must not assume immediate scoring results** — Writing answers may be PENDING; UI must handle and display PENDING status gracefully (no "score unavailable" spinner that hangs; clear messaging).
- Multi-tenancy and role-based access control (student vs. admin) must be preserved and functional (existing auth/iam layer remains unchanged).
- Accessibility standards must be met for task interaction (WCAG 2.1 AA recommended for exam platform, though this may be a post-release concern depending on project scope).

## Steps

1. Design a shared task-type component architecture: create a task-rendering framework (common UI patterns, timing display, response input, submission) that all 20 task types can reuse. Define a task-type plugin interface or component hierarchy that allows new task types to be added without changing core code (e.g., `TaskTypeRenderer` abstract class, each task type extends it).

2. For pte-app (Flutter): implement task-type UI widgets for all 20 types. Priority high-frequency types first (Read Aloud, Describe Image, Essay, Multiple Choice, Fill-in-Blank) then lower-frequency. Each widget includes:
   - Task prompt display (text, image, audio player as needed).
   - Response input (audio recorder, text input, drag-reorder handle, click options, etc.).
   - Per-task timer countdown display (synchronized with backend via WebSocket).
   - Submit button with validation (e.g., "Audio must be at least 10 seconds").
   - Response preview (show what was recorded/typed before final submit).

3. For pte-web: implement task-type UI components (HTML/CSS/JavaScript or framework equivalent) for all 20 types, mirroring pte-app interactions as closely as feasible (accounting for device differences: desktop has pointer/keyboard, mobile has touch). Ensure responsive design (works on tablet and desktop browsers).

4. Implement per-task timer UI in both apps: display countdown (mm:ss), change color as time runs low (green → yellow → red), update every 1 second. When timer expires, either auto-submit or show an alert ("Time's up, submitting now...") and submit. WebSocket events from backend (Phase 2) drive the countdown; client-side timer continues if connection drops.

5. Implement task progression flow: after submitting a task, show a confirmation/feedback screen (for objective tasks: immediately show score; for Writing/Speaking: show "Scoring in progress..." with estimated completion time). Then show "Next task" button or auto-advance to next task after a brief delay (configurable, e.g., 2 seconds).

6. Implement the exam result screen: display the final PTE score report (Overall, communicative skills, enabling skills) from the backend. For Speaking/Writing tasks, show individual sub-scores (Fluency, Pronunciation for Speaking; Grammar, Vocabulary, etc. for Writing). For objective tasks, show score and explanation (e.g., "You selected Option B. Correct answer: Option C."). Group by task type or skill for readability.

7. Implement audio recording for Speaking tasks (pte-app and pte-web):
   - pte-app: use Flutter audio plugin (e.g., audio_waveforms, flutter_sound) to record audio from microphone, encode as AAC/MP3, upload to backend.
   - pte-web: use Web Audio API (MediaRecorder) to capture audio from microphone, encode as WAV/MP3 blob, upload to backend.
   - Both: provide feedback (waveform display, recording time counter, red "REC" indicator), allow playback before submit, allow re-record.

8. Create end-to-end user flows: define the happy path (student logs in, selects exam, completes all tasks, views results), error cases (network drops, timer expires, submission fails, scoring error), and edge cases (student closes app mid-exam, exam force-submitted by proctor). Document and test each flow.

## Success Criteria

- All 20 PTE task types have working UI/UX in both pte-app and pte-web: task renders correctly, response input works (audio record, text input, click/select, drag-reorder), submit button is functional.
- Per-task timer display is synchronized with backend: countdown updates every 1 second, WebSocket events update timer, fallback to local timer if connection drops, submission is blocked/warned if timer expires.
- Exam progression works end-to-end: student can move through all 20 task types, submit responses, and reach the final result screen without crashes or null-pointer exceptions.
- Result screen displays PTE score report (Overall + 4 communicative skills + 6 enabling skills) correctly; individual task scores and explanations are visible.
- Audio recording works in both apps (tested on sample Speaking task): audio is captured, playback works, upload succeeds, backend receives audio file correctly.
- All task types work on common device sizes (pte-app: tested on common Android/iOS screen sizes; pte-web: tested on desktop, tablet, mobile browsers).

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started (UI unit tests for component rendering; integration tests with mock backend API; end-to-end tests with backend (Phase 9); manual testing on real devices/browsers)

## Risks

- **HIGH: Audio Recording & Playback Compatibility** — Audio recording APIs vary across browsers and devices (Chrome, Safari, Firefox may behave differently; iOS may have permissions issues). Microphone access is a common UX pain point (app crashes, silent recordings). *Mitigation:* Phase 8 includes comprehensive audio testing across target devices/browsers; fallback to text-description if audio fails (graceful degradation); clear user instructions (grant microphone permission, check levels). Test with real exam-like audio (various accents, volumes).

- **HIGH: Task-Type UI Complexity & Time Pressure** — Implementing 20 unique UI components with task-specific logic (drag-reorder state management, multiple-choice validation, audio upload, text fuzzy-match validation) is high-effort. Risk of incomplete/buggy implementations if timeline is tight. *Mitigation:* Prioritize high-frequency task types first (Read Aloud, Essay, Multiple Choice cover >50% of exam); lower-frequency types can be simplified (e.g., Highlight may use click-to-highlight instead of ideal drag-select if time is short). Test with real users early to catch UX issues.

- **HIGH: Cross-Device & Cross-Browser Inconsistency** — pte-app (Flutter) and pte-web (HTML/JS) are different platforms. Similar behavior on both is not automatic. Bugs that exist only in one platform may be missed until late. *Mitigation:* Establish a shared UI/UX spec early (design mockups for all 20 task types); implement both platforms in parallel if possible (or use a cross-platform web technology like Electron/PWA instead of Flutter if time is tight). Test both platforms with the same test cases.

- **MEDIUM: Timer Synchronization Edge Cases** — Client-side timer and server-side timer may drift if network latency is high or clock skew exists. Student may see "5 seconds left" locally, but server thinks time expired. *Mitigation:* Server is source of truth; if server detects expired timer, submission is rejected and logged, not failed. Client-side timer is hint-only. Use NTP or server-provided current timestamp in WebSocket events to reduce skew. Test with simulated network latency (100ms, 500ms, 1s delays).

- **MEDIUM: Handling Incomplete Scoring in Result Display** — If some Writing/Speaking answers are still PENDING when result screen is shown, display is complex (show "in progress" for PENDING, concrete scores for SCORED, error message for FAILED). *Mitigation:* Implement a "refresh" button on result screen (student can refresh to see updated scores). Implement auto-refresh every 10 seconds if PENDING scores exist. Estimate "typical time to scoring" and display to student ("Scores typically available in 3 minutes, last checked 30 seconds ago").

- **MEDIUM: Microphone Permission Prompts & Retries** — iOS/Android/browsers each have different microphone permission flows. If permission is denied, app must handle gracefully (not crash). Re-requesting permission after denial is tricky. *Mitigation:* Test microphone flow on real iOS and Android devices early. Provide clear instructions and allow users to open Settings to grant permission. Implement graceful error messages ("Microphone access required for Speaking tasks. Open Settings > [App] > Microphone and enable.").

- **LOW: Drag-Reorder UX Across Browsers** — Drag-and-drop works differently on touch (mobile) vs. pointer (desktop/mouse). Desktop libraries (jQuery Sortable, react-beautiful-dnd) may not work well on mobile. *Mitigation:* Use a library with good cross-device support (e.g., react-dnd with touch backend, or native HTML5 drag-drop with mobile polyfills). Test drag-reorder on real touch devices.

## File Ownership (If Parallel Phase Implementation)

(This section applies if Phase 8 is implemented in parallel with other phases by different team members.)

- `pte-app/lib/features/exam/widgets/task_types/` — All task-type UI widgets (one file per type, e.g., `read_aloud_widget.dart`)
- `pte-app/lib/features/exam/services/audio_service.dart` — Audio recording and playback logic
- `pte-app/lib/features/exam/screens/exam_result_screen.dart` — Final score report screen
- `pte-web/src/features/exam/components/TaskType*.tsx` — All task-type UI components (one file per type)
- `pte-web/src/features/exam/services/audioService.ts` — Web Audio API wrapper for recording
- `pte-web/src/features/exam/ExamResultScreen.tsx` — Final score report screen
- `pte-web/src/styles/exam.css` — Shared exam styling (timers, task containers, buttons)

