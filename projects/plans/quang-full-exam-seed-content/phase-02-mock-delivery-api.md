# Phase 2: Dev-Only Mock Delivery API

## Requirements

Expose two deterministic `REPEAT_SENTENCE` questions from `pte-api` so the
Flutter app can exercise the existing attempt response contract before real
authoring/scheduling/media data and AI credentials are available.

## Delivered

- `MockExamController` under the `mock-exam-delivery` Spring profile.
- Start/resume, next-task, answer acknowledgement, submit and audio routes.
- Two generated WAV fixtures served from the exam-delivery classpath.
- CORS limited to the local Flutter web ports for the mock route.
- App build-time `PTE_API_BASE_URL` and `PTE_EXAM_ATTEMPTS_PATH` overrides.
- A dev menu screen that renders API responses through the existing design
  system, supports advancing between the two tasks, and plays the returned
  audio URL through the existing audio player service.

## Design constraints

- The normal `/attempts` controller and JWT security chain remain unchanged.
- No database row, outbox event, scoring call, media upload or AI call is
  created by the mock.
- The profile is absent by default and must be enabled explicitly.
- Audio is synthetic local test speech, not official Pearson content.

## Quality and testing state

- Quality gate: approved; no blocker/high/current-change medium findings.
- Testing: passed; exam-delivery reactor and full Flutter suite are green.
