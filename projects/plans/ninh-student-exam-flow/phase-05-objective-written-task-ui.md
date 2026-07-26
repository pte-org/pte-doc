# Phase 5: Objective & Written Task UI

## Requirements

Build the `MC_READING_SINGLE` and `WRITE_ESSAY` task-type screens, rendering inside Phase 4's shared exam shell and wired exclusively through Phase 2's outbox — no call site in this phase may ever call `ApiClient` directly to submit an answer. Every answer-changed event (option selection, keystroke) triggers a debounced local upsert into the outbox, not only navigation-to-next-task, so a kill mid-task loses at most a few hundred milliseconds of the most recent edit rather than the entire in-progress answer. `pinnedItemPublicId` is threaded through unchanged from the current `TaskView` on every write, and word-count bounds are enforced only as client-side UX guidance, never a server-trusted gate.

Maps to: **P1 Story #3 ("answer an MC_READING_SINGLE question by selecting one option") + P1 Story #4 ("write and submit a WRITE_ESSAY response with word-count guidance") | FR-07**

## Design Constraints

- Every write path in this phase ends at `AnswerOutboxDao.upsertAnswer` (Phase 2) — never `ApiClient`. This is the first phase where that rule is actually exercised by real UI, not just stated; treat any direct `ApiClient` import in a Phase 5 file as an automatic defect.
- Debounce, don't batch-on-navigate. A `Timer`-based debounce (e.g. 400–600ms, exact value a build-time tuning decision) restarts on every keystroke for `WRITE_ESSAY` and fires the local upsert on quiet-period expiry; `MC_READING_SINGLE`'s single discrete selection event upserts immediately (no debounce needed for a single tap). Before navigating away from the current task (Phase 4's shell "next" action) or before the screen disposes, any pending debounce timer must be cancelled and its upsert flushed synchronously first — otherwise a fast user (answer, immediately tap next) could lose the last keystroke's debounce window.
- `pinnedItemPublicId` for every `upsertAnswer` call comes from the current `TaskView` in scope at the time of the write, never cached from a previous render — this is the outbox's anti-replay key (Phase 2), and a stale value here would silently misfile an answer against the wrong task.
- Payload construction is the one place task type *is* allowed to matter (per `plan.md`'s Research Summary: the transport/storage layers stay generic, but the call site constructing the payload is exactly where the per-type shape lives). `MC_READING_SINGLE` payload = the selected option's `orderIndex` converted to a decimal string (e.g. `"2"`, not `2` as a number, not `"orderIndex: 2"` — the raw decimal-string form only). `WRITE_ESSAY` payload = the raw typed text, untouched (no trimming/normalization beyond whatever the `TextEditingController` already holds, since the server presumably applies its own word-count validation server-side and any client-side mutation risks silently changing what the student believes they submitted).
- `minWordCount`/`maxWordCount` drive a live word-count display only. Do not block the debounced local upsert, do not block navigation, and do not show a hard error state based on being outside bounds — the server is the authority on whether a submission is acceptable; this phase's word-count UI is guidance, and the Design Constraint against a server-trusted client gate applies here exactly as `plan.md`'s FR-07/word-count language specifies.
- `BlocSelector` (not `BlocBuilder`) for the word-count display, since it depends on only the text-length slice of a larger task/answer state, not the whole task-answer `Bloc`/`Cubit` state — consistent with `CODING_STANDARDS_APP.md`'s partial-state-rebuild rule already exercised in Phase 4's `ExamAppBar`.
- `TextEditingController` (for `WRITE_ESSAY`) is created in `initState`/constructor and disposed in `dispose()` — no controller may be recreated on every rebuild, and none may leak past the widget's lifecycle.
- Both screens render inside Phase 4's shared shell (`ExamAppBar`/`ExamBottomBar`/phase indicator) as the shell's injected content region — this phase does not build its own top/bottom chrome.

## Steps

1. Define a lightweight per-task-type state holder (e.g. `TaskAnswerCubit` or an extension of `ExamAttemptBloc`'s existing state, whichever keeps the 300-line file cap easier to respect — a build-time call, but lean toward a separate `Cubit` per task type given the debounce-timer lifecycle each one owns independently) carrying the current draft (selected `orderIndex` or draft text) and depending on `AnswerOutboxDao` directly for the upsert write path.
2. Implement `McReadingSingleScreen`: render `TaskView.options[{text, orderIndex}]` as a single-select list; on selection, immediately call `upsertAnswer` with `payload = orderIndex.toString()`, no debounce.
3. Implement `WriteEssayScreen`: `TextField`/`TextFormField` bound to a `TextEditingController`; on every text change, restart a debounce `Timer` that calls `upsertAnswer` with `payload = controller.text` on expiry; compute and display live word count against `minWordCount`/`maxWordCount` via a pure, independently-testable word-count utility function.
4. Implement the flush-before-navigate hook: whichever widget/`Bloc` handles Phase 4's shell "advance" action must, for these two task types, cancel any pending debounce `Timer` and perform one final synchronous `upsertAnswer` call before the navigation/next-task request proceeds.
5. Wrap the word-count `Text` widget in a `BlocSelector` scoped to just the text-length-derived value, not the whole draft state.
6. Add a task-type dispatcher (a widget or routing function that switches on `TaskView.taskType` to select `McReadingSingleScreen` vs. `WriteEssayScreen` vs. — placeholder for now — the not-yet-built `READ_ALOUD` screen from Phase 6) so Phase 6 has an established seam to plug into rather than inventing its own dispatch mechanism.
7. Test: payload-shape assertion for `MC_READING_SINGLE` — selecting the option at `orderIndex: 2` produces an outbox row whose `payload` is exactly the string `"2"`, not `2`, not JSON-wrapped, not a different index due to an off-by-one in list-vs-`orderIndex` indexing.
8. Test: payload-shape assertion for `WRITE_ESSAY` — typed text `"hello world"` produces an outbox row whose `payload` is exactly `"hello world"`, with no added trimming/casing/whitespace normalization the student didn't type.
9. Test: debounce behavior using a fake `Timer`/injectable clock (not real `Duration` sleeps) — rapid simulated keystrokes within the debounce window produce zero intermediate `upsertAnswer` calls, exactly one call after the quiet period, and calling the flush-before-navigate hook mid-debounce produces the call immediately without waiting out the remaining debounce window.
10. Test: `TextEditingController` disposal — a test (or lint rule already in place from Phase 0) confirms `dispose()` is called on widget teardown; no `late TextEditingController` is ever reassigned across rebuilds.
11. Test: word-count utility is a pure function tested independently of any widget — verifies word-splitting behavior (e.g. multiple spaces, leading/trailing whitespace) without needing to pump a widget tree.

## Success Criteria

- [ ] No file in this phase's `MC_READING_SINGLE`/`WRITE_ESSAY` feature code imports `ApiClient`.
- [ ] Every answer-changed event (not just navigation) results in a debounced or immediate local outbox upsert, verified via the fake-timer test.
- [ ] `pinnedItemPublicId` on every upsert matches the `TaskView` in scope at write time, never a stale cached value.
- [ ] `MC_READING_SINGLE` payload is the decimal-string `orderIndex`; `WRITE_ESSAY` payload is raw untouched text — both verified by dedicated payload-shape tests, not inferred from a passing integration test alone.
- [ ] Word-count display never blocks submission or navigation, and never shows a hard error purely for being outside `minWordCount`/`maxWordCount`.
- [ ] Word-count widget rebuilds only via `BlocSelector` on the relevant slice of state.
- [ ] `TextEditingController` is disposed on every teardown path.

## Quality and Testing State

- Quality gate: not evaluated.
- Testing: not started.

## Risks

- **MEDIUM (carried from `plan.md`)**: Because `SubmitAnswerRequest{pinnedItemPublicId, payload}` is one generic shape for all task types, a bug in this phase's payload construction (e.g. accidentally sending the option's list-index instead of its `orderIndex`, which only differ when options aren't rendered in `orderIndex` order) would not be caught anywhere below this phase — the outbox stores `payload` opaquely per Phase 2's design, and the transport layer has no way to validate it. Mitigation: Steps 7–8's payload-shape assertion tests are this phase's primary defense; they must assert on the literal string value, not just "an upsert happened."
- **LOW**: A very short debounce interval increases outbox write frequency (and therefore WAL-checkpoint frequency per Phase 2's Risk note) during active typing; a very long debounce interval increases the amount of unsaved-to-disk typing lost on a kill within the debounce window. The exact interval is a tuning tradeoff, not a correctness question — Phase 7's dedicated kill-mid-response hardening test should exercise a kill that lands inside the debounce window specifically, to make this tradeoff's worst case visible rather than theoretical.
