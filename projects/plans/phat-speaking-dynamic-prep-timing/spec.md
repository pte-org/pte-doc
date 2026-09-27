# Spec: Dynamic, audio-duration-aware prep timing for Speaking audio-prompt screens

**Date:** 2026-08-31
**Status:** Ready

---

## Problem Statement
For the 5 Speaking task types with an audio prompt (Repeat Sentence, Retell Lecture, Answer Short Question, Summarize Group Discussion, Respond to a Situation), prep timing is currently a static per-task-*type* number (`task-timing.json`) that has no relationship to how long the actual uploaded audio prompt runs — causing the "Playing" countdown label and the real-audio-driven progress bar (`phat-speaking-audio-prompt-e2e`) to visibly disagree, and (a separate, compounding issue) recording can start several real seconds late for these short-prep tasks because of `TimerService`'s fixed poll interval. Both were confirmed by direct manual testing against a live backend.

---

## User Stories

- **[P1]** As a student taking a Speaking task with an audio prompt, I want the prep countdown and progress bar to accurately reflect how long the audio prompt actually plays, so nothing visibly disagrees or ends before the audio itself does.
  Accepted when: for a seeded audio-prompt question with a known-duration WAV file, the "Playing" progress bar reaches 100% at the same real moment the countdown label reaches "0 seconds left" (within normal playback tolerance).

- **[P1]** As a content author, when I upload an audio prompt for one of these 5 task types, I want an invalid or unreadable audio file rejected immediately, so a broken prompt can never reach a live exam session.
  Accepted when: uploading a corrupt/unreadable WAV as an audio prompt fails at complete-upload time with a clear, typed error — no silent fallback duration.

- **[P1]** As a student, I want recording to start promptly once my prep time genuinely ends, even for short-prep tasks, so I don't lose real response time waiting for the app to notice.
  Accepted when: for a short-prep task type (e.g. Repeat Sentence, `prepSeconds` ~10–15s), recording starts within a couple of seconds of the real server-side `prepDeadline` passing, not the previous ~10s worst-case poll-interval lag.

- **[P2]** As a content author, I want a clear, immediate error if I try to upload a non-WAV audio prompt (e.g. MP3), so I know to convert the file rather than silently getting rejected later or accepted with wrong timing.
  Accepted when: a non-WAV upload attempt for an audio-prompt task type is rejected with a clear error message.

- **[P3]** _(out of scope — noted for future)_ MP3/WebM audio-prompt support with accurate duration extraction (would need a real audio-parsing dependency or `ffprobe`, deliberately deferred).

---

## Functional Requirements

1. FR-01: Audio-prompt uploads for the 5 audio-prompt Speaking task types accept only `audio/wav` content type — narrower than the media service's existing general `ALLOWED_CONTENT_TYPES` (which still applies as before to candidates' own recorded answers, unaffected by this).
2. FR-02: On upload-complete, the media service computes and persists the uploaded audio file's exact duration (seconds), read from the WAV file's own header (JDK-native, no new dependency).
3. FR-03: If duration cannot be determined (invalid/corrupt WAV), the complete-upload call fails with a distinct, typed error — the media object is never marked usable without a known duration.
4. FR-04: For a pinned item of one of the 5 audio-prompt task types, exam-delivery computes that item's `prepSeconds`/`prepDeadline` dynamically as `preListenSeconds + audioDurationSeconds + preRecordSeconds`, using the specific item's own real audio duration — not a static per-task-type lookup.
5. FR-05: `preListenSeconds`/`preRecordSeconds` per audio-prompt task type move from hardcoded Dart constants (5 different pairs, one per screen file) to server-side configuration, and are exposed to the client so `pte-app`'s existing sub-stage-split UI logic reads them from the task response instead of local hardcoded values.
6. FR-06: Respond to a Situation's existing combined 20s "Beginning" sub-stage (situation-reading + audio-wait, per its own current doc comment) is preserved unchanged as that task type's `preListenSeconds` value — only the post-pre-listen portion (audio-play + pre-record) becomes duration-driven.
7. FR-07: `TimerService` schedules one additional one-shot poll timed to fire when the local countdown is expected to reach zero, alongside its existing fixed-interval polling — the global poll interval itself is unchanged for every other task type.
8. FR-08: Non-audio-prompt task types (Read Aloud, Describe Image, Personal Introduction, all Reading/Writing/Listening types) are entirely unaffected — their `prepSeconds` stays the existing static per-type value.

---

## Non-Functional Requirements

- Reliability: WAV duration extraction must be byte-exact from the file header, not an approximation or estimate.
- Compatibility: zero behavior change for any task type outside the 5 audio-prompt Speaking types.
- Security/Integrity: a corrupt or unreadable audio prompt must be rejected before it can ever be attached to a publishable question — never silently degraded to a guessed duration.

---

## Success Criteria

- [ ] For a seeded audio-prompt question with a real WAV file of known duration N seconds, the app's "Playing" progress bar reaches 100% within normal playback tolerance of the same real moment the countdown label shows "0 seconds left".
- [ ] Uploading a non-WAV file (e.g. MP3) as an audio prompt for one of the 5 task types is rejected with a clear, typed error, not silently accepted.
- [ ] Uploading a corrupt/unreadable WAV file as an audio prompt is rejected at complete-upload time, not later.
- [ ] For a short-prep task type (`prepSeconds` ~10–15s, e.g. Repeat Sentence or Answer Short Question), recording starts within ~1–2 seconds (network-round-trip-bound) of the real server-side `prepDeadline` passing — not the previous ~10s worst-case poll-interval lag.
- [ ] Read Aloud (and every other already-verified task type) shows no regression to its existing prep/response timing behavior.

---

## Out of Scope

- MP3/WebM audio-prompt support (deliberately deferred — WAV-only for now).
- Fixing the pre-existing, unrelated `SectionCompletedScreen` generic-title cosmetic bug (found during the prior plan's manual walkthrough).
- Backfilling stored duration for any audio-prompt `MediaObject`s created before this ships (dev/test data only — expected to be re-seeded, not migrated).
- Describe Image's separate, already-tracked image-content-type gap.
- Any change to `responseSeconds` (the actual recording window) — already correct, untouched by this spec.

---

## Assumptions

- Narrowing audio-prompt uploads to WAV-only does not affect candidates' own recorded-answer uploads, which are already WAV-only via `AudioRecorderServiceImpl` and go through a separate content-type path.
- Dev/test audio-prompt media objects created before this ships (e.g. from `phat-speaking-audio-prompt-e2e`'s manual walkthrough) will be re-seeded fresh rather than migrated in place.
- The exact server-side location for the newly-server-owned `preListenSeconds`/`preRecordSeconds` values (extending `task-timing.json`'s existing schema vs. a new config surface) is an implementation detail for `/ck:plan` to resolve, not a product decision requiring further clarification here.
