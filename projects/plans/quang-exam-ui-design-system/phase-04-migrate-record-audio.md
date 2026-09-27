# Phase 4: Migrate Record-Audio Screens (FR-12, FR-13, FR-14, FR-16)

## Requirements

Migrate all eight speaking record screens to one record-response family while
preserving the current `AutoRecordCubit` state machine, upload handoff and
auto-advance behavior. The screen must show the complete design states, not
only a record button.

## Design Constraints

- `RecordResponseTemplate` may be stateful for subscription lifecycle, but it
  receives an injected timer stream/bridge and does not call
  `context.read<ExamAttemptBloc>()`. Shared widgets remain props-based and do
  not import feature Cubits/BLoCs.
- The feature-layer bridge may read `ExamAttemptBloc`, seed the current state,
  forward timer snapshots and guard on `pinnedItemPublicId`. It must be
  disposed on template teardown.
- Preserve `AutoRecordCubit`, `AutoAdvanceOnUploadReady`, upload tracking and
  current answer/outbox behavior. Do not create a new recording Cubit.
- `CountdownTimer` is display-only: it receives remaining time/snapshot from
  the authoritative timer and never starts `Timer.periodic` itself.
- Support the screen-specific stimulus variants: text, image, audio prompt,
  audio+text and no-stimulus. Use local preview media/fake resolver when API
  media is unavailable.
- Eight migrated pages must not import the timer bridge, upload listener or
  countdown implementation directly.
- Keep the existing `ExamScaffold` lifecycle wiring: `AppResumed` still forces
  the immediate timer re-poll, `ForceSubmitRequested` remains the app-bar path,
  `TaskAdvanceButton` still flushes the answer edit and sync row before asking
  for the next task, and `ViolationWarningBanner` stays mounted. These are
  integration invariants, not new state-machine work.

## Steps

1. Extract `RecordTimerBridge` at
   `lib/features/exam_attempt/speaking_writing/presentation/record_response/record_timer_bridge.dart`.
   It owns initial-state seeding, stream subscription, the
   `pinnedItemPublicId` guard and cancellation. Add
   `record_response_route_builder.dart` beside it as the composition root that
   creates the bridge and injects its snapshot stream into the core template;
   task pages do not import the bridge.
2. Implement `RecordResponseTemplate` with injected timer bridge/stream and
   props-based record response slot. Render the design's preparing, recording,
   recorded, upload, error/retry and auto-advance affordances.
3. Move/refactor `countdown_timer.dart` into the shared component location as a
   display-only widget; delete the old self-ticking implementation only after
   all references are migrated.
   The bridge contract must also be exercised across task replacement and
   `AppResumed`; the next task must never receive the prior task's snapshot.
4. Migrate these exact pages:
   - `speaking_writing/presentation/pages/personal_introduction_screen.dart`
   - `speaking_writing/presentation/pages/read_aloud_screen.dart`
   - `speaking_writing/presentation/pages/repeat_sentence_screen.dart`
   - `speaking_writing/presentation/pages/describe_image_screen.dart`
   - `speaking_writing/presentation/pages/retell_lecture_screen.dart`
   - `speaking_writing/presentation/pages/answer_short_question_screen.dart`
   - `speaking_writing/presentation/pages/summarize_group_discussion_screen.dart`
   - `speaking_writing/presentation/pages/respond_to_a_situation_screen.dart`
5. Render all eight fixture entries through the real screen path and compare
   preparing/recording/recorded/upload states with the available reference or
   approved fallback pattern.
6. Replay deterministic record/submit actions and diff the exact payload and
   media key against the Phase 0 baseline. Test task A → task B replacement
   with the same task type.

## Success Criteria

- [ ] Eight screens use the common record template and render complete design
  chrome, instruction, stimulus, recorder status, waveform/progress,
  countdown, helper/status and navigation regions.
- [ ] `pinnedItemPublicId` guard is covered by a behavior test and present in
  the feature bridge.
- [ ] `AutoAdvanceOnUploadReady` is preserved and upload auto-advance remains
  behaviorally unchanged.
- [ ] Countdown has no independent clock or `Timer.periodic`.
- [ ] No record page imports the bridge/upload listener/countdown implementation.
- [ ] Payload/media key diff is zero for all eight record actions.
- [ ] Visual results are recorded per screen, including the two design-gap
  fallbacks.
- [ ] `flutter analyze` passes except explicitly recorded baseline findings.

## Quality and Testing State

- **Quality gate:** not evaluated. Cook runs `/ck:quality --gate` after this
  phase. Checks lifecycle ownership, stale-task guard, state preservation,
  display-only countdown, visual states and file size.
- **Testing:** not started. Run focused timer-bridge, record/upload,
  auto-advance and stale-task tests plus eight fixture visual smoke tests.

## File Ownership

**Files exclusively owned by this phase:**

- `lib/core/widgets/templates/record_response_template.dart`
- `lib/core/widgets/components/countdown_timer.dart`
- `lib/features/exam_attempt/speaking_writing/presentation/record_response/record_timer_bridge.dart`
- `lib/features/exam_attempt/speaking_writing/presentation/record_response/record_response_route_builder.dart`
- The eight speaking page files listed in Steps 4

**Files affected but not behaviorally redesigned:**

- `lib/features/exam_attempt/speaking_writing/presentation/cubit/read_aloud_cubit.dart`
  only if an import/type seam is required; do not change its state machine.
- `lib/features/exam_attempt/presentation/widgets/task_type_dispatcher.dart`

**The legacy bridge/upload files are deleted only after clean replacement
analysis and are finalized in Phase 7.**

## Cook State

- **Status:** completed.
- **Testing:** record-response widget smoke passed, including compact-panel overflow regression.
- **Quality:** record UI delegates presentation to shared props-based components; recording lifecycle remains feature-owned.
