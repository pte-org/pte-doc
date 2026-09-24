# Brainstorm: Host Practice exams with selectable skills

**Date:** 2026-09-24  
**Status:** Direction accepted; detailed behavior has a few explicit defaults to confirm before implementation.

## Problem

The host exam wizard already exposes Practice, Mock Test, and Official Exam modes, but its canonical template-based workflow currently generates every section in the selected template. Hosts need to create a Practice exam focused on the skills their students should work on, then have students take and submit that exam in `pte-app` and see the submission from the host portal.

## Ideas explored

1. Keep **mode** and **skill scope** as separate concepts. Mode controls exam policy; selected skills control which parts of the template are generated. Avoid creating a separate mode for every combination such as Reading Practice or Speaking Practice.
2. Keep the active exam template as the authority for task types, counts, timing, and scoring. Host selects whole skills/sections only; task-type-level composition remains out of this MVP.
3. Generate a scoped snapshot on the server. Do not hide/filter tasks in `pte-app`, because the snapshot is also the source of truth for attempt delivery, scoring, and reports.
4. Preserve the canonical workflow: draft → audience → preflight → generation → publish/schedule → open. Do not re-enable the older skills-only endpoint, which bypasses this orchestration.

## Accepted direction

- Add selectable one-or-more skills to the host's Practice exam setup.
- Persist the chosen scope with the draft and use it consistently for preflight and deterministic generation.
- Generate only template items for selected skills; keep Mock Test and Official Exam full-template by default for this release.
- Keep current Practice policy and host result workflow. The app should take and submit the scoped snapshot through its existing runtime.
- Focus the first manual walkthrough on one no-microphone skill to reduce device-related demo risk, while automated checks cover scope validation and other supported skills.

## Constraints and caveats found during source review

- Practice currently disables device-check, proctor, and lockdown requirements, but still uses template timing.
- `UNLIMITED` currently means unlimited audio replay, not unlimited whole-exam attempts. A submitted attempt cannot be restarted in the same session.
- Partial-skill scoring is supported; the overall score is omitted when not all skills are present.
- Historical sessions may have been created by a prior workflow without a template reference. A migration must not assume those sessions represented every skill or rewrite their existing snapshot.
- The app currently has a completion heading that assumes Reading. It should be neutral if the first release allows other single-skill scopes.

## Deferred pending confirmation

- An untimed Practice option.
- Multiple submissions/restarts within one session, or immediate feedback after each answer.
- Whether the demo must include closing the exam and publishing a student-facing report, beyond confirming the submitted work and score workflow in the host portal.
