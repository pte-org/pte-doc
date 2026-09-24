# Phase 03 — Practice scope, all-mode retries, and runtime UX

## Goal

Let a host configure/review Practice skill scope and configure retries for every exam mode, enforce independent numbered attempts, and make retries/limit exhaustion understandable in the desktop app and host review.

## Requirements

- Add `selectedSkills` to `CreateExamWorkflowInput` and map it through `useCreateExamWorkflow` to the API.
- Add `maxRetriesPerStudent` to host draft types and API payloads; show an integer control from `0` to `9` for every mode, defaulting to `0` (the initial attempt is not a retry).
- Derive checkbox options from sections actually represented by the selected active template; require at least one selection for Practice.
- Default to all template sections, preserving current behavior unless the host narrows the scope.
- Show section selection for Practice only. For Mock/Official, show the full-template scope as read-only or a clear summary; do not allow the host to create a partial exam in those modes.
- Switching from Practice to another mode resets scope to the complete template scope; the backend applies the same default if the mode patch omits scope. Switching templates refreshes valid options and defaults to the new template's full scope unless the host explicitly chooses a valid new scope.
- Display mode and selected skill names in the review step and session list/detail where those views expose exam configuration.
- Display the configured retry count in review and session detail for every mode so the host can verify how many additional attempts are allowed.
- Keep validation and error copy in feature constants; never show raw machine error codes.
- In `AttemptLifecycleService`, use the existing session-row lock for the complete start/resume/quota/create transaction in every mode. Resume the student's `CREATED`/`IN_PROGRESS` attempt; otherwise allow a new numbered attempt only if submitted count is below `1 + maxRetriesPerStudent`. Count timer-expiry submissions as submitted. Never reopen or overwrite a submitted attempt.
- Keep the generated form immutable and shared across attempts; each new attempt pins its own snapshot from that same form and starts fresh template-defined task timers.
- Update attempt module's public `SessionService` contract rather than reaching into session internals when reading the retry count. Keep one active/resumable attempt per student/session and prevent concurrent starts from exceeding quota.
- Include attempt number and remaining-attempt/retry-availability metadata in the server response used by the completion flow. The client must not be the quota source of truth.
- `pte-app` should offer a clear next-attempt action when allowed and a friendly limit-reached message otherwise. Starting the next try must use the same session and form while creating a new server-side attempt; do not add an untimed toggle.
- Show attempt number in host answer review so answers from separate attempts cannot be confused. Keep the report publication flow out of the demo.
- Replace any hard-coded “Reading Section Completed” heading with neutral completion copy if still present and add a focused widget test.

## Likely files

- `pte-web/apps/tenant-web/features/exams/components/CreateExamWizard.tsx`
- `pte-web/apps/tenant-web/features/exams/types/index.ts`
- `pte-web/apps/tenant-web/features/exams/constants/index.ts`
- `pte-web/apps/tenant-web/features/exams/utils/validateCreateExamWorkflow.ts`
- `pte-web/apps/tenant-web/features/exams/api/index.ts`
- `pte-web/apps/tenant-web/features/exams/components/SessionTable.tsx` and its row/detail model if needed.
- `pte-api/app/src/main/java/com/pte/attempt/internal/service/AttemptLifecycleService.java` and its repository/mapper/tests.
- `pte-api/app/src/main/java/com/pte/attempt/internal/dto/response/AttemptTaskResponse.java` and the Flutter attempt-task response model/parser.
- `pte-api/app/src/main/java/com/pte/session/SessionService.java` and its public attempt-quota response contract.
- `pte-api/app/src/main/java/com/pte/scoring/internal/dto/response/AnswerListItemResponse.java` and host attempt-number query mapping.
- `pte-app/lib/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart`, state, completion screen, user-facing error constants, and focused tests.

## Steps

1. Add typed skill options, retry-count labels, and friendly validation/messages in feature constants; do not hardcode new user messages inside JSX.
2. Implement Practice-only skill selection and all-mode retry-count input, defaults, template-change reconciliation, validation, and review summary.
3. Send the exact scope and retry count reviewed by the host; do not silently widen scope or change retry count in the client.
4. Implement numbered attempt creation and quota enforcement under session lock, preserving resume of an active attempt and mapping exhausted quota to a friendly API error.
5. Add a student retry action/state that is unavailable after the configured limit; ensure duplicate taps resume the active new attempt rather than creating another.
6. Expose attempt numbers in host submitted-answer review and verify host can inspect each attempt without publishing student-facing reports.
7. Keep timer values from the pinned template; make completion copy neutral if still inaccurate.

## Tests and exit criteria

- Practice wizard defaults to all template skills and allows narrowing to one or more.
- Every mode defaults retries to `0`, allows a host to set `0`–`9`, and returns/persists the value through draft updates.
- `PRACTICE`, `MOCK_TEST`, and `REAL_EXAM` all enforce the configured retries; a count of `0` means one total attempt and `1` means two total attempts.
- Empty Practice scope blocks review/submit with a friendly field-level message.
- Skill choices absent from the template are not shown and are removed when template changes.
- Switching to Mock/Official restores the full scope and submits no partial selection.
- Review and host exam row/detail show the actual mode and scope returned from API.
- API request carries exactly the selected skill set.
- An active attempt is resumed and does not consume another retry; after `SUBMITTED`, the next attempt starts only when fewer than `1 + maxRetriesPerStudent` attempts have been submitted; at the limit the app shows friendly copy.
- Two attempts for one student/session are distinct, numbered records using the same generated form and timer contract; concurrent duplicate starts do not create duplicate attempt numbers.
- Host answer review distinguishes attempt numbers. Student-facing report publication is not needed for the walkthrough.
- A non-Reading completion uses neutral copy; template timer behavior and existing task navigation remain intact.
- `tenant-web` lint/build and api-client typecheck/tests pass.

## Design Constraints

- Preserve the existing exam wizard sequence and its audience/reuse settings.
- Do not create separate per-skill exam modes or task-type selectors.
- No hidden assumptions about local microphone availability; app requirements remain defined by each task runtime contract.
- Retry count is per session in every exam mode. Do not add untimed or instant-feedback controls.
- A new attempt is not a replay of the same attempt: keep previous submitted answers/snapshots immutable and use attempt-specific identifiers throughout scoring.
- Preflight: keep the cross-module boundary through `SessionService`; snapshot the resolved retry policy onto each attempt so post-start attempt responses need no session-module call. Follow feature constants for web copy, attempt response/mapper patterns in API, and BLoC/event/state plus `app_strings.dart` conventions in Flutter. Host review should obtain attempt numbers through an attempt public API, not read another module's entity. User selected no unit tests and no quality gate; run production compile/type/build checks only.

## Quality and Testing State

- Quality: skipped_by_user; decision: user_confirmed_skip.
- Testing: not_started; skipped_by_user per user request. Do not create or run unit tests.
- Build Gate: passed — API production compile, API-client typecheck, tenant-web build, and Flutter Windows debug build passed. The authenticated host → app → host walkthrough is tracked in Phase 04.
