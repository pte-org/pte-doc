# Brainstorm: PTE Practice Student Web and Entitlement-Locked Preview

**Date:** 2026-10-07

## Ideas Explored

- **A separate student web in `pte-practice`.** The new app is the implementation target, while the existing Pearson PTE AI Practice site is the visual and interaction reference. The first navigation scope is Home, Practice tests, Study-Pack, and Progress.
- **A visible preview shell instead of a hard paywall.** Every authenticated student can see the normal product surfaces. Students without an active organization entitlement see the same cards and information architecture, but practice-entry actions remain locked. Redirecting to an error page or hiding the catalog was rejected for the MVP.
- **Progress remains read-only.** Progress is an evaluation/analytics surface, not an action that consumes practice capacity. It stays accessible with an empty state for students without history and with historical data preserved after access is revoked.
- **Unlock from imported membership plus an active organization plan.** A successfully imported active student in an organization with an active plan is unlocked automatically. A separate per-student assignment workflow is deferred, subject to the plan's capacity/seat check at import.
- **Server-authoritative entitlement.** A disabled button is only a UX state. Practice start, task access, and submission must be protected by the backend entitlement check so a student cannot bypass the lock by calling a route or API directly.
- **Manual authenticated browser inspection.** The reference site was opened in a separately debug-enabled Chrome profile, with the user completing email verification and Cloudflare manually. Playwright then navigated the four reference routes for route/layout inspection without handling credentials or tokens.
- **First-session guidance inspection.** Starting an available Reading and Listening Diagnostic Test opened a pre-session overview before any question or recording: test title, section rows, item types, time allowed, a session timer, `Save & exit`, and `Next`. This overview is part of the entitled-student flow; a locked student must be stopped before reaching the session route.
- **Task-runtime inspection from Home and Quick study.** Home exposes the complete visible task catalog: Speaking (Read Aloud, Repeat Sentence, Describe Image, Respond to a Situation, Answer Short Question), Writing (Summarize Written Text, Write Email, Reading and Writing: Fill in the Blanks, Summarize Spoken Text, Fill in the Blanks, Write from Dictation), Reading (five reading types), and Listening (Multiple Choice, Multiple Answers; Multiple Choice, Single Answer; Select Missing Word). Quick study was used to open the first question without answering it.
- **First-question interaction patterns.** The tested Reading screens include dropdown selection for Reading and Writing: Fill in the Blanks, checkbox multi-select, drag-and-drop Reorder Paragraph, drag words into Fill in the Blanks, and single-choice selection. The tested Listening screens include video/audio countdowns, single/multi-choice selection, Select Missing Word, Highlight Incorrect Words over a transcript, and Write from Dictation with a text box and editing controls.
- **Confidence capture.** After an answer is selected, the runtime exposes three submit actions: Low confidence, Medium confidence, and High confidence. The first-use explanation is an onboarding modal (`Rate your confidence` / `Got it`); it is separate from the per-answer confidence controls. Confidence must be stored with the response rather than treated as correctness.
- **Media prerequisite.** The first Listening task opened an audio playback check before the item could proceed. After confirmation, the task used a ten-second countdown and an audio/video player. Microphone permission and recording UX still require a separate Speaking-session inspection.
- **Reference account boundary.** On the inspected account, Quick study opens the upgrade dialog when Speaking or Writing is selected, and `Summarize Spoken Text` is displayed as premium under Listening. Therefore the actual first-question screens for those task types cannot be verified from this session without changing the account entitlement; they must remain explicitly marked as coverage gaps rather than inferred from screenshots.
- **Early-exit side effect.** Ending an untouched Quick study session created a 0% report with zero completed items and a recommended practice item. This is useful evidence for session lifecycle design, but it should not be silently copied into the MVP until the desired draft/resume/report semantics are decided.

## User's Direction

- Implement the student web in `pte-practice`.
- Start with four tabs: Home, Practice tests, Study-Pack, and Progress.
- Keep the normal basic UI visible for all authenticated students.
- Lock practice functionality for students who are not imported into an organization with an active plan.
- Do not add lock error copy, modal explanations, upgrade prompts, or invite-code flows in the first iteration; the initial behavior is simply locked/disabled.
- Keep Progress available as a read-only evaluation screen. Do not invent progress numbers for students without practice history.
- When an imported student belongs to an organization with an active plan, unlock practice automatically.
- If the plan expires, is suspended, or the student is deactivated/removed, block new practice while preserving historical Progress.

## Open Questions

- **[NEEDS CLARIFICATION]** Does the first implementation include a working exercise runtime and answer submission for entitled students, or only the four-tab/catalog shell plus the guarded entry point?
- **[NEEDS CLARIFICATION]** Does “clone task types” mean implement all visible first-question interaction patterns in the first runtime milestone, or only establish the task catalog and a shared session shell first?
- **[NEEDS CLARIFICATION]** Which existing authentication, student-import, organization-membership, plan-status, and capacity APIs are the canonical source for `pte-practice`, and can one email be active in more than one organization?
- **[NEEDS CLARIFICATION]** How quickly must an import, plan activation, expiry, or removal change the student's effective access: on the next page refresh, on a periodic entitlement refetch, or through a real-time event?
- **[NEEDS CLARIFICATION]** For an unfinished session, should the student resume it, discard it without a report, or intentionally receive a zero-result report like the reference account did? What is the expected behavior after a browser close or media-permission failure?

## Risks

- **Authorization drift:** the UI may show a locked state while an unprotected API or deep link still allows practice. The server-side gate must be treated as the security boundary.
- **Seat/capacity ambiguity:** unlocking every imported student without enforcing the organization's capacity can create access beyond the purchased plan.
- **Historical data semantics:** Progress must remain consistent and privacy-scoped when a student loses current practice access or changes organization.
- **Reference volatility:** the third-party reference UI, labels, and visual details can change; the implementation should reproduce the agreed information architecture without coupling to its private assets or runtime.
- **Runtime breadth:** the visible catalog spans multiple interaction families and media permissions; implementing every type at once may create a large test and content-fixture surface.
- **Confidence correctness:** confidence is a response-level signal and must remain independent from scoring, retries, and skipped items.
- **Media/access coverage:** a free reference account cannot prove the Speaking/Writing premium flows; cloning from assumptions could produce a misleading runtime contract.
