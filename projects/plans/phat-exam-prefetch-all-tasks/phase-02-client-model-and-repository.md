# Phase 2: Client model layer — `TaskView.copyWith`, `AttemptAllTasksResponse`, repository method

## Requirements
Add the Dart-side types and repository method needed to consume the new `GET /attempts/{id}/tasks` endpoint. No BLoC changes in this phase — purely the data layer.

## Steps
1. **Add `copyWith` to `TaskView`** (`lib/features/exam_attempt/domain/task_view.dart`). Every field becomes a named optional param defaulting to `this.field`. Required because Phase 3's BLoC will derive per-task `TimerSnapshot` seeds and may need to patch individual fields (e.g., reading `responseSeconds` with a sentinel if needed).
2. **Add `AttemptAllTasksResponse`** (`lib/features/exam_attempt/data/models/attempt_all_tasks_response.dart`): `List<AttemptTaskResponse> tasks`. `fromJson` mapping. Confirm field names match the Phase 1 server response.
3. **Add `fetchAllTasks(String attemptPublicId)` to `ExamAttemptRepository`** (interface) and **`ExamAttemptRepositoryImpl`** (implementation). Calls `GET /attempts/{id}/tasks`, parses `AttemptAllTasksResponse`, returns `List<TaskView>` (mapped via existing `AttemptTaskResponse → TaskView` conversion).
4. Update the **DI registration** for `ExamAttemptRepositoryImpl` if needed (no new dependencies expected — reuses existing `ApiClient`).
5. **Write unit tests** for `AttemptAllTasksResponse.fromJson` and for the repository method's happy path (mock `ApiClient` returning a list of two tasks, assert both are parsed and returned).

## Success Criteria
- `TaskView.copyWith()` compiles and round-trips all fields correctly (simple snapshot test).
- `ExamAttemptRepository.fetchAllTasks` returns `List<TaskView>` mapped from the server payload.
- `flutter test` passes for affected files.

## Risks
- **LOW**: `TaskView` currently has no `copyWith` — adding one is purely additive and does not affect any existing caller.
- **LOW**: The `AttemptTaskResponse → TaskView` mapping already exists for single-task responses. Reusing it for the list is safe, but confirm the server returns the same DTO shape for bulk vs. single (Phase 1 guarantees this by using the same mapper).
