# Specification: Student Finish/Submit Gate and App-Level Exam Exit Lock

**Status:** Draft for implementation
**Date:** 2026-09-28
**Owner:** PTE platform
**Parent baseline:** `quang-practice-anti-cheat-policy`
**Target client:** `pte-app` Windows desktop student application
**Target mode:** Practice first; compatible with any exam mode that already uses the student attempt shell

## 1. Problem statement

The current Windows release can enter fullscreen for Device Check and the exam, but fullscreen alone is not an exit policy. A student can still attempt to close the window, switch applications, or leave the attempt before the server has accepted a submission. The current UI also needs one explicit, always-visible finish action so a student can intentionally submit and end a practice attempt.

The requested demo behavior is:

1. A `Finish exam` action is visible throughout the task flow.
2. The student may submit even when some or all questions are unanswered. The student accepts the resulting score.
3. The application remains in its app-level locked state until the server confirms that the attempt is submitted.
4. Close, Alt+F4, minimize, and focus-loss attempts before acknowledgement are refused or re-armed where Windows permits, and are recorded as warnings/audit events.
5. After successful submission, the application shows a submitted state and allows the student to exit normally.
6. Windows Assigned Access/Shell Launcher is explicitly deferred. This feature is not an operating-system kiosk and must not claim absolute prevention of Alt+Tab.

## 2. Decisions already made

- Practice keeps its timer.
- Practice may have anti-cheat enabled by the existing policy flag.
- Anti-cheat behavior for this demo is warning plus audit; it does not invalidate the attempt, auto-submit because of a violation, or force a proctor workflow.
- The finish action is always available in the exam task shell.
- Submission is allowed with unanswered tasks.
- A failed submission keeps the attempt locked and exposes retry.
- Successful server acknowledgement is the only normal transition that permits exit.
- OS-level kiosk configuration is out of scope for this release.

## 3. Scope boundary

### In scope

- Student-side finish/submit UI in the shared exam shell.
- Confirmation dialog showing answered and unanswered counts.
- Reuse or hardening of the existing force-submit API and attempt lifecycle.
- A single app-side submission state machine with duplicate-submit protection.
- App-level exit guard for the Windows runner.
- Fullscreen re-arm and warning/audit behavior for focus loss and window commands.
- Retry behavior for timeout, offline, and retryable server failures.
- Release-build validation on Windows using the local demo environment.
- Documentation of the app-level limitation and the future OS-kiosk boundary.

### Out of scope

- Assigned Access, Shell Launcher, Group Policy, registry policy, or any other OS kiosk setup.
- Proctor and host UI changes.
- Scoring algorithm, examiner assignment, report publication, or score visibility.
- A new exam mode or replacement of the existing practice anti-cheat policy contract.
- Auto-invalidation, auto-submit after a violation, or a new violation escalation policy.
- Guaranteeing that Windows itself can never switch applications. App-level hooks can detect and react to focus loss but cannot provide an absolute OS security boundary.

## 4. Actors and user stories

### Student

- **US-01:** As a student, I can see a finish action on every exam task so I do not need to discover a hidden keyboard shortcut or URL.
- **US-02:** As a student, I can review how many tasks are answered and unanswered before submitting.
- **US-03:** As a student, I can submit an incomplete practice attempt after confirming the warning.
- **US-04:** As a student, I receive a retry action if the server does not accept the submission; the app does not silently exit and lose the attempt.
- **US-05:** As a student, after the server accepts my submission, I can leave the exam through the explicit exit action.
- **US-06:** As a student, if I try to close or switch away before submitting, I see a clear warning and my exam remains active.

### Platform/operator

- **US-07:** As an operator, I can distinguish a submitted attempt from a locally completed screen; local UI state alone must never unlock the app.
- **US-08:** As an operator, I can inspect audit events for blocked exit/focus-loss attempts and submission failures without treating them as scoring events.

## 5. Functional requirements

### Finish and confirmation

- **FR-01:** The shared exam task shell renders a finish action on the first, middle, and last task. It must not depend on a task-type-specific screen implementation.
- **FR-02:** The action opens a confirmation surface with answered count, unanswered count, the fact that unanswered tasks will be submitted as unanswered, and explicit `Continue exam` and `Submit exam` actions.
- **FR-03:** `Submit exam` is enabled when zero tasks are answered. The unanswered count is a warning, not a validation blocker.
- **FR-04:** While submission is in progress, the confirmation controls and other competing terminal actions are disabled. Repeated clicks must not create concurrent submit requests.
- **FR-05:** The UI uses the existing shared button, dialog, typography, spacing, and exam chrome components. It must not introduce a second visual language for this flow.

### Submission lifecycle

- **FR-06:** The client uses the existing canonical force-submit/attempt-completion contract where it already satisfies these requirements. A parallel endpoint must not be introduced without evidence that the current contract cannot represent the required terminal state.
- **FR-07:** A successful 2xx response or an equivalent server-confirmed terminal response is the acknowledgement boundary. Emitting a local `AttemptCompleted`-like state before that boundary must not enable exit.
- **FR-08:** A timeout, network error, authentication refresh failure, or retryable server response transitions to a retryable submission failure. The attempt remains locked and the student can retry.
- **FR-09:** A duplicate-submit race is handled deterministically. If the server reports that the attempt is already terminal, the client treats the server-confirmed terminal state as success rather than issuing another submission loop.
- **FR-10:** Existing answer/media synchronization is flushed or reconciled before the terminal submit request according to the current repository contract. A pending speaking recording must not be silently discarded.
- **FR-11:** Existing exam timer behavior remains unchanged. Timer expiry uses the same server-acknowledged terminal path where the current implementation force-submits; it must not create an exit bypass.

### Exit and app-level lock

- **FR-12:** During an active attempt, the exit guard is active from the point the task shell is entered until successful submission acknowledgement.
- **FR-13:** Before acknowledgement, the app handles the following best-effort events: window close/Alt+F4, minimize/system commands, fullscreen loss, and focus loss/Alt+Tab. The response is to keep or restore the exam window, show a warning without spamming modal dialogs, and emit an audit event.
- **FR-14:** The native runner must have an explicit internal `exitAllowed`/equivalent gate. The close handler must not infer permission from the presence of a local completion page.
- **FR-15:** After successful acknowledgement, the lock is deactivated, fullscreen is released, and the completion surface exposes an explicit exit action. A normal window close is then permitted.
- **FR-16:** If the app is relaunched while the server still reports an active attempt, the client re-enters the guarded state. A stale local flag must not make an active server attempt exitable.
- **FR-17:** The login window remains a normal centered, bounded window. The new exit guard must not make login fullscreen.

### Audit and observability

- **FR-18:** Every blocked close/Alt+F4/minimize/focus-loss event has a stable event type, attempt/session identifier when available, timestamp, and a non-sensitive reason.
- **FR-19:** Submission start, success, retryable failure, and terminal reconciliation are observable through the existing app audit/reporting path or a minimal extension of it.
- **FR-20:** Audit failures do not unlock the application and do not make the student lose the primary submission retry path.

## 6. Client state model

The implementation must have one owner for terminal submission and exit permission. Widget-local booleans may represent presentation state but may not independently unlock the native window.

```text
ACTIVE / LOCKED
    | student taps Finish exam
    v
CONFIRMATION OPEN
    | Continue exam                 | Submit exam
    |                               v
    +-------------------------> SUBMITTING / LOCKED
                                      | server acknowledgement
                         +------------+-------------+
                         |                          |
                         v                          v
                SUBMISSION FAILED              SUBMITTED / EXITABLE
                         |                          |
                         +-- Retry ----------------+
                                                    |
                                                    v
                                            EXIT ACTION / WINDOW CLOSE
```

`SUBMISSION FAILED` is still locked. A local navigation event, route pop, keyboard shortcut, or native close event cannot transition directly from `ACTIVE`, `CONFIRMATION OPEN`, `SUBMITTING`, or `SUBMISSION FAILED` to `EXITABLE`.

## 7. Acceptance criteria

### AC-01: Finish action

Given any task in a configured practice exam, when the shared task shell renders, then the finish action is visible and usable without relying on a task-specific widget.

### AC-02: Incomplete submission

Given an attempt with unanswered tasks, when the student opens Finish exam and confirms Submit exam, then the app sends one terminal submit command, does not reject the action because of unanswered count, and remains locked until the server acknowledges success.

### AC-03: Successful submission

Given a successful server acknowledgement, then the app shows a submitted state, records the success, deactivates the app-level lock/fullscreen, and permits the explicit exit action.

### AC-04: Failed submission

Given a network or retryable server failure, then the app shows retry, keeps the task visible, keeps the app-level lock active, does not mark the attempt submitted locally, and does not permit window close.

### AC-05: Exit attempt before submission

Given an active or failed submission state, when the student uses close/Alt+F4, minimize, or switches focus, then the app does not intentionally exit, restores/retains the guarded exam window where possible, shows a warning, and records an audit event.

### AC-06: Relaunch recovery

Given the server still reports an active attempt after a process restart, then the client restores the guarded attempt state and does not treat the previous process termination as a successful submission.

### AC-07: Release boundary

The Windows release demo proves app-level behavior only. No OS kiosk policy is installed or modified, and the documentation states that absolute Alt+Tab prevention requires a future managed-device deployment.

## 8. Non-functional requirements

- **Reliability:** submission acknowledgement and exit permission are monotonic; an error cannot move the state backward into an unlocked state.
- **Security:** no credentials, access tokens, answer payloads, or audio data are written into anti-cheat audit messages.
- **Accessibility:** confirmation and retry actions are keyboard reachable; disabled/loading states have text labels; warning text is not conveyed by color alone.
- **UX:** do not show repeated modal warnings for a single focus-loss burst; use the existing notification/banner pattern and a cooldown/debounce.
- **Compatibility:** preserve the normal windowed login behavior and existing mobile/non-Windows no-op behavior for native window controls.
- **Performance:** native focus/close handlers must return quickly and not perform network calls on the Windows message thread.

## 9. Open decisions to confirm before implementation

1. Use the visible label `Finish exam` or the more explicit `I want to finish exam`? The internal action/event name should remain stable regardless of copy.
2. After submission acknowledgement, should the completion surface require clicking `Exit application`, or should it close automatically after showing the submitted state? The recommended demo behavior is an explicit `Exit application` button.
3. If the timer expires while the student is inside the confirmation dialog, should the dialog close and submit immediately using the existing auto-submit behavior? The recommended behavior is to preserve the current timer rule and route through the same acknowledgement gate without asking for a second confirmation.

