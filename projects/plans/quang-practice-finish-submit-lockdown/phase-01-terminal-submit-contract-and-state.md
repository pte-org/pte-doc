# Phase 1 — Terminal submission contract and client state model

## Objective

Make the server acknowledgement boundary and client terminal state explicit before changing the UI or native exit behavior. The phase must prove whether the existing force-submit path already supports incomplete attempts and whether its success response is sufficient to gate exit.

## Scope and likely files

### Backend inspection/changes

- `pte-api/app/src/main/java/com/pte/attempt/...` attempt controller, service, repository, domain, and response classes.
- Existing force-submit endpoint and any attempt-status/read endpoint.
- Owning attempt constants for error codes/messages if a new contract error is required.
- Targeted backend tests only where the existing contract is ambiguous or incomplete.

### Student app inspection/changes

- `pte-app/lib/features/exam_attempt/...` event, state, bloc/application owner, repository interface/implementation.
- `pte-app/lib/core/network/api_client.dart` and API exception mapping.
- `pte-app/lib/core/sync/sync_engine.dart` and media upload coordination.
- Existing attempt bloc tests, especially force-submit and timer-expiry cases.

## Steps

1. Trace the current UI event through the app repository/client to the backend force-submit endpoint.
2. Confirm the server behavior for zero answers, partial answers, already-submitted attempts, expired attempts, and retryable failures.
3. Confirm which response/status is authoritative for terminal submission. If the endpoint already returns a successful terminal response, preserve it. If not, add the smallest backward-compatible response/status mapping in the owning attempt module.
4. Define a typed client result/state rather than using a generic boolean. At minimum distinguish:
   - active and locked;
   - confirmation open (presentation state may remain local);
   - submitting;
   - retryable submission failure;
   - server-acknowledged submitted;
   - exit allowed.
5. Add a single in-flight guard around terminal submission. The guard must cover both button double-clicks and repeated native/timer events.
6. Define how the existing timer expiry and normal final-task completion enter the same acknowledgement path. Do not make `AttemptCompleted` itself the unlock signal unless its construction proves server acknowledgement.
7. Define relaunch recovery: when a student session is restored, retrieve server attempt status before allowing an exitable state.
8. Record any contract gap in the phase output before implementation proceeds to UI/native work.

## Design Constraints

- **Preflight:** Attempt lifecycle and response mapping remain owned by `pte-api/app/.../attempt`; the Flutter API client maps transport errors only; `ExamAttemptBloc` owns sync/timer/lockdown orchestration; the existing `AttemptTaskResponse` envelope and `AttemptMapper.toCompletedResponse` are the canonical response shapes. No new cross-module or widget-to-API path is allowed.
- Reuse the canonical force-submit endpoint and existing auth/session plumbing.
- Allow incomplete submission; unanswered count is not a backend validation error for this flow.
- Do not introduce scoring/report behavior.
- Preserve timer semantics and existing answer/media synchronization semantics.
- Do not let a widget or native plugin set `exitAllowed` directly.
- Any new error code/message must live in the owning module constants and preserve external compatibility where possible.
- If no backend change is required, document that fact and keep the phase app-only.

## Quality and Testing State

- **Quality:** APPROVED. The focused review found no blocker, high, medium, or low findings. Receipt: `quality/phase-01-terminal-submit-contract-and-state-receipt.json`.
- **Testing:** PASSED. Backend submit lifecycle test: 3 tests, 0 failures, 0 errors. Flutter exam-attempt bloc test: 29 tests, 0 failures, 0 errors. Build gate also passed: backend production compile and focused Flutter analyzer.
- **Testing commands:** `pte-api/.\mvnw.cmd -pl app -Dtest=AttemptLifecycleServiceSubmitAttemptTest -DfailIfNoTests=true test`; `pte-app/flutter test test/unit/features/exam_attempt/exam_attempt_bloc_test.dart --reporter expanded`; `pte-api/.\mvnw.cmd -pl app -DskipTests compile`; `pte-app/flutter analyze lib/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart lib/features/exam_attempt/presentation/bloc/exam_attempt_state.dart`.

## Acceptance criteria

- A written trace identifies the exact successful response that means “submitted”.
- Zero-answer and partial-answer behavior is known and compatible with the requirement.
- The client has one terminal submission owner and an explicit retryable-failure state.
- No code path can mark exit allowed merely because a local completion widget rendered.
- Timer expiry, final task completion, and manual Finish exam have an agreed common terminal path.
