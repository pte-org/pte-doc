# Phase 5 — Session Lifecycle and Objective Interaction Families

## Objective

Implement the shared practice session UX and the non-media objective interaction families using the canonical runtime contract, with correct first-question behavior, skip, save/submit and safe resume.

## Story mapping

- P1: entitled student starts, skips, saves/exits and resumes practice.
- P2: task interaction and session UX are responsive and accessible.
- P3: no future product areas.

## Scope

- Overview → first question → next/skip → save & exit → resume/complete state machine.
- Single choice, multiple choice, dropdown, drag-and-drop/order, drag-to-blank, typed blank and highlight interaction families where the canonical profile supports them.
- Task payload serialization, validation, saved state, idempotent submit and optimistic conflict handling.
- Keyboard alternatives for reorder/drag interactions.
- Coverage matrix rows for `MC_READING_SINGLE`, `MC_READING_MULTIPLE`, `RE_ORDER_PARAGRAPHS`, `FILL_IN_THE_BLANKS_DRAG_AND_DROP`, `FILL_IN_THE_BLANKS_DROPDOWN`, `MC_LISTENING_SINGLE`, `MC_LISTENING_MULTIPLE`, `SELECT_MISSING_WORD`, `HIGHLIGHT_CORRECT_SUMMARY`, `HIGHLIGHT_INCORRECT_WORDS` and `WRITE_FROM_DICTATION` where media is ready.

## Exact files/areas likely changed

- `pte-practice` session route/components and new renderer-family components under the approved feature structure.
- `pte-practice` typed task/answer schemas and serializers under the approved API/client area.
- Backend practice answer/session DTO/controller/service areas from Phase 03; existing `TaskView.java`/`SubmitAnswerRequest.java` only through additive compatible changes.
- Existing backend runtime profile/pinning/answer validation areas only where the practice facade requires an extension; no registry rewrite.
- Fixture files under `pte-practice` or `pte-doc` for approved local content, each marked with canonical task code/profile and provenance.

## Dependencies

- Phase 03 session/task API.
- Phase 04 shell/routes.
- Phase 01 coverage and answer schema decisions.

## Implementation steps

1. Implement session reducer/state machine with server status/version, deadline and resume data.
2. Implement family renderers through an allowlisted `rendererKey` map, not a task-name switch scattered across pages.
3. Implement payload normalizers and validation for each family; reject malformed/stale payloads server-side.
4. Add skip and early-exit behavior; do not require confidence for skipped items.
5. Add answer save/submit idempotency, retry and conflict UI that cannot silently overwrite newer state.
6. Add accessible drag/drop keyboard ordering and transcript highlight semantics.
7. Run first-question acceptance flows for every included row and record unsupported/premium rows separately.

## Acceptance criteria

- Each included objective type opens its intended interaction family and can be skipped/submitted through the common shell.
- Reload resumes non-empty draft with saved answer state; untouched exit discards without a report.
- Double click/retry does not duplicate session/answer; stale tab receives a conflict and cannot overwrite silently.
- Server rejects unauthorized/expired/deadline/stale payloads and never leaks correctness answers.
- Keyboard users can complete choice, confidence-adjacent navigation, reorder and highlight flows.
- No task is silently skipped because a renderer is unsupported.

## Design Constraints

- Reuse canonical runtime/profile/pinning/answer contracts; do not implement 23 bespoke independent engines.
- Keep media-specific preparation in Phase 06; this phase may use media-ready fixtures only.
- Client state is an optimistic view, never the source of status, entitlement or correctness.
- Preflight: shared UI primitives and fixture-facing constants belong at the isolated app root (`common/`), while task/session behavior stays under `features/practice` and route boundaries remain under `app/`. Backend practice ownership remains under `com.pte.practice`; public attempt/runtime contracts are reused through existing services and no official exam session is created for practice.
- Checkpoint: Unit tests = yes; quality gate = yes, inherited from `/ck:cook --hard --tests --quality`.

## Quality and Testing State

- Quality: **Not evaluated**.
- Testing: **Not started**.
- Planned evidence: renderer-family unit tests, serializer/property tests, API integration tests, Playwright first-question/skip/resume/conflict flows and accessibility checks.
