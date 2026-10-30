# Research: Practice timed / untimed modes

**Date:** 2026-10-24
**Spec:** [../hung-practice-timed-modes/spec.md](../hung-practice-timed-modes/spec.md)
**Inputs:** builder check, Primary researcher, Alternative researcher (read-only code review of `pte-api` and `pte-practice` on `hung/feat/practice-revamp`).

## Verdicts

| Area | Primary | Alternative | Adopted |
|---|---|---|---|
| Question selection | itembank returns candidate IDs (cap 500, existing JPQL), practice queries its own "seen" set, pure `PracticeQuestionPicker` with injected `RandomGenerator`; no SQL `RANDOM()`; batch freeze | Keep eager pick at `begin` (lazy pick breaks totals, idempotency, no-repeat); batch to avoid ~100 queries under the session row lock | Both — eager + batched, picker in Java |
| Timing source | new `config/practice-task-timing.json` loader | **Switch**: active ScoreTemplate (`ScoreTemplateService.getActive()`, V14 seeds all 22) + `preListenSeconds` from existing `config/task-timing.json`; a third copy re-creates drift already removed once | **Alternative** — spec §5.2/§6 updated |
| Mode/state | `timing_mode` nullable column, null → UNTIMED; pinned item timing columns | Keep client-held timers (pte-app precedent); optional unenforced `elapsedMs`/`timedOut` later | Client-held; no server enforcement |
| Deadline removal | stop setting `deadlineAt`; null already means "never" in `isPastDeadline`; V133 nulls `deadline_at` for OVERVIEW/IN_PROGRESS | same, plus prompt-media TTL coupling and catalog `timeLimitSeconds` exposure | Adopted |
| Idempotency | add defaulted `timingMode`, `questionCount` to `startRequestHash` | same, normalise before hashing | Adopted |
| Timed phase engine (FE) | pure reducer `idle → preListen → prompt → prep → recording → done/error`, deadlines from timestamps (no per-tick decrement), `useTimedPhase` hook; `PromptMedia mode="once"`; response countdown starts on `RECORD_STARTED` | mirror pte-app field names (`preListenSeconds`, `prepSeconds`, `responseSeconds`) and recorder vocabulary; wall-clock deadlines | Adopted |
| Waveform | compute from PCM in existing `onaudioprocess`; `stop()` returns `{ blob, peaks, durationSeconds }`; SVG `<rect>` bars coloured by CSS classes (theme-safe, no inline style), `role="slider"` seek | keep WAV ScriptProcessor pipeline (backend only accepts `audio/wav`); AudioWorklet migration deferred | Adopted |

## Risks carried into the plan
1. Autoplay: "play once" needs a user gesture; after reload/resume show a Play gate. Guard single play against StrictMode double effects.
2. Legacy sessions with 60-minute `deadline_at` expire on open unless V133 nulls them.
3. Flyway number collision — confirm the highest `V` on `dev` before naming V133.
4. `PracticeSessionView.tsx` is ~501 lines — extract before adding features.
5. WAV size: 120 s cap stays (backend `MAX_RESPONSE_DURATION_SECONDS = 120`); at 96 kHz still under 25 MB, but prefer a 16–24 kHz `AudioContext` or byte cap.
6. Candidate cap of 500 per task type biases toward low UUIDs if a pool grows beyond it.
7. Student self-playback after reload needs a new owner-checked media link for `STUDENT_RESPONSE_AUDIO`.
