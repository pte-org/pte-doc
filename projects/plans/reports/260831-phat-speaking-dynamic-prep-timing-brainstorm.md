# Brainstorm: Dynamic, audio-duration-aware prep timing for Speaking audio-prompt screens

**Date:** 2026-08-31

## Context
Follow-up to `plans/phat-speaking-audio-prompt-e2e` (real audio-prompt playback, verified end-to-end for Repeat Sentence). An ad-hoc spot-check of a second screen (Answer Short Question) surfaced 2 real UX bugs, documented in that plan's "Post-completion exploratory findings" section:

1. The "Playing" sub-stage's countdown label and progress bar are driven by two independent, disagreeing clocks.
2. Recording can start several real seconds late for short-`prepSeconds` task types, due to `TimerService`'s fixed 10s poll interval and phase never self-advancing between polls.

## Ideas Explored

**Bug 1 (label/progress-bar desync):**
- Patch the label to also follow real audio position/duration (mirror the progress bar) — considered first, but doesn't address the deeper mismatch: the fixed elapsed-time sub-stage window (`prepSeconds - preListenSeconds - preRecordSeconds`) has no relationship to the real audio file's actual length, so even a "fixed" patch would still show a dead gap between real-audio-finish and the pre-record sub-stage starting.
- **User's actual mental model (not what the current code does)**: prep = 3s fixed "Beginning" + *exactly as long as the audio actually is* + 3s fixed "Beginning" (pre-record) — i.e. total prep duration should be *derived from the real audio's length*, not a static per-task-type number.
- Reframed the whole bug once this was understood: the real fix is server-side — `prepDeadline` (and therefore `prepSeconds`) should be computed per-item from the audio prompt's actual duration, not looked up from a static `task-timing.json` entry per task *type*. Once that's true, the *existing* label arithmetic (`prepSeconds - preListenSeconds - preRecordSeconds`) automatically equals the real audio duration — no FE display-logic change needed at all, the bug disappears at the source rather than being patched at the symptom.

**Bug 2 (poll-lag-delayed recording start):**
- (a) Lower `TimerService`'s global poll interval — rejected quickly by the user: affects every task type across the whole app, not just these 5 short-prep Speaking screens, for a benefit that's only needed there.
- (b) Schedule one extra one-shot poll timed to fire right when the local countdown is expected to hit zero, on top of the existing fixed-interval polling — user's preferred direction; narrower blast radius, same "trust server exclusively" design principle preserved (still a real poll, not a local phase-advance).

**Audio duration extraction (scouted, not just discussed)** — checked `media` service's `pom.xml` and the shared Dockerfile: no audio-processing library or `ffmpeg`/`ffprobe` exists anywhere in the stack today.
- WAV: computable for free from the file header via JDK-native `javax.sound.sampled` — no new dependency.
- MP3: JDK has no native support; VBR files need either a real parsing library or accept an approximation.
- WebM: JDK has no native support at all; would need `ffprobe` in the media Docker image or an equivalent library.
- User's direction: **restrict audio-prompt uploads to WAV only** going forward, trading upload-format flexibility for a dependency-free, exactly-correct duration read. (Candidates' own recorded *answers* are already WAV-only via `AudioRecorderServiceImpl`, so this doesn't introduce a new asymmetry — it just extends the same constraint to audio *prompts*.)

## User's Direction
Go with the fully dynamic, server-computed-from-real-audio-duration approach for prep timing (not a client-side display patch), restricted to WAV-only audio prompts to keep duration extraction dependency-free and exact. For Bug 2, add a one-shot extra poll timed to the local countdown reaching zero, rather than touching the global poll interval. Duration-extraction failure at upload/question-creation time should fail fast (reject), not silently fall back to a guessed default. Respond to a Situation's existing 20s merged "Beginning" (15s situation-reading + 5s audio-wait, per its own doc comment) stays as-is — only the audio-and-after portion becomes duration-driven.

## Open Questions
- Where exactly should `preListenSeconds`/`preRecordSeconds` (currently 5 different hardcoded pairs, one per Dart screen file) live once they become the server's responsibility too — extended fields on the existing `task-timing.json` per-task-type config, or something new? (Implementation detail for `/ck:plan` to resolve, not a product decision — flagged, not blocking.)
- Exact mechanics of "duration-aware `prepDeadline`" at the `SnapshotPinService`/`PinnedItem` layer (this is the exact code `phat-speaking-audio-prompt-e2e`'s Phase 1 already touched for audio-URL resolution) — needs a real implementation design, left to `/ck:plan`.
- Whether any already-seeded/test audio-prompt `MediaObject`s (e.g. the fixture from the prior plan) need backfill once duration becomes a stored field, or whether re-seeding from scratch is acceptable (dev/test data only — likely the latter, but not explicitly decided).

## Risks
- **Scope creep risk**: this touches 3 layers across 2 services (media: duration extraction + storage; exam-delivery: dynamic `prepDeadline` computation replacing a static per-type lookup for audio-prompt task types; pte-app: read the new server-driven values instead of hardcoded per-screen constants) — meaningfully bigger than the FE-only fix originally scoped for Bug 1.
- **WAV-only restriction is a real product/content constraint**, not just an implementation detail — authors who'd expect to upload MP3/WebM audio prompts can no longer do so. Confirmed acceptable by the user, but worth stating plainly in the spec so it isn't missed during review.
- **`task-timing.json`'s existing static `prepSeconds` for these 5 task types (added by `phat-speaking-audio-prompt-e2e` Phase 1) becomes dead/superseded** for the audio-prompt path once this ships — worth an explicit decision on whether to remove those specific static values or leave them as an unused fallback.
