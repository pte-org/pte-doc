# Phase 2 — Finish exam UI and confirmation

## Objective

Provide one consistent, always-visible finish action in the shared exam chrome and make incomplete submission intentional and understandable.

## Scope and likely files

- `pte-app/lib/core/widgets/exam/exam_header_bar.dart`
- `pte-app/lib/core/widgets/exam/exam_footer_bar.dart`
- `pte-app/lib/core/widgets/exam/exam_navigation_actions.dart`
- `pte-app/lib/core/widgets/confirm_dialog.dart`
- `pte-app/lib/core/widgets/primary_button.dart`
- `pte-app/lib/core/constants/exam_chrome_config.dart`
- `pte-app/lib/app.dart` and the exam attempt shell that injects the shared chrome
- Relevant widget tests under `pte-app/test/widget/features/exam_attempt/`

## Steps

1. Choose one canonical action label and event (`Finish exam` is the recommended concise label; the longer copy can remain in the dialog).
2. Render the action from the shared exam shell so it appears on every task type, including speaking, listening, reading, and writing.
3. Open a shared confirmation dialog containing:
   - answered task count;
   - unanswered task count;
   - explicit statement that unanswered tasks will remain unanswered and be submitted;
   - `Continue exam` secondary action;
   - `Submit exam` primary action.
4. Keep `Submit exam` enabled for zero answered tasks. Do not use per-task validation to block it.
5. Bind the primary action to the Phase 1 terminal submission event. Widgets must not call API clients directly.
6. While submitting, close/disable competing controls, show progress text, and prevent repeat taps.
7. On retryable failure, replace the progress state with a clear retry action and keep the confirmation/task context recoverable.
8. On acknowledged success, show a submitted completion surface and the explicit exit action defined in `spec.md`.
9. Apply existing common button, focus, spacing, and notification styles. Ensure keyboard focus order includes the finish action and both dialog actions.
10. Keep `Save & Exit` semantics separate from terminal submission if that action still exists in preview/dev surfaces; do not silently change a development preview into a real exam exit path.

## Design Constraints

- **Preflight:** `ExamScaffold` is the shared wrapper used by task screens across Speaking, Writing, Reading, and Listening; `ExamAppBar` owns the shared finish affordance; `ExamAttemptBloc` remains the only terminal-submit command owner; `AnswerOutboxDao` is read only for local answered-count presentation; no widget calls an API client.
- Shared exam chrome only; no task-type-specific copies.
- Student may submit incomplete work.
- Dialog copy must be clear without claiming scores are already published.
- Use common UI components and current Pearson/PTE visual language.
- Do not add an exit button that bypasses submission acknowledgement.
- Do not make the login or Device Check window depend on this exam-only action.

## Quality and Testing State

- **Quality:** APPROVED. Review found no blocker, high, medium, or low findings. Receipt: `quality/phase-02-finish-exam-ui-and-confirmation-receipt.json`.
- **Testing:** PASSED. Focused Flutter widget suite: 14 tests, 0 failures, 0 errors; focused analyzer: no issues.
- **Testing commands:** `flutter analyze lib/core/constants/exam_chrome_config.dart lib/core/storage/dao/answer_outbox_dao.dart lib/core/widgets/exam/exam_header_bar.dart lib/features/exam_attempt/constants/exam_attempt_strings.dart lib/features/exam_attempt/presentation/widgets/exam_app_bar.dart lib/features/exam_attempt/presentation/widgets/exam_scaffold.dart lib/features/exam_attempt/presentation/widgets/task_advance_button.dart test/widget/features/exam_attempt/exam_app_bar_test.dart`; `flutter test test/widget/features/exam_attempt/exam_app_bar_test.dart test/widget/features/exam_attempt/exam_scaffold_test.dart test/widget/features/exam_attempt/task_advance_button_test.dart --reporter expanded`.

## Acceptance criteria

- A manual pass through all four skills sees the same finish action.
- A zero-answer attempt reaches confirmation and can submit.
- The UI cannot issue two concurrent terminal commands from repeated taps.
- Failure shows retry and leaves the active exam intact.
- Submitted state has no route/pop/close bypass hidden in the widget tree.
