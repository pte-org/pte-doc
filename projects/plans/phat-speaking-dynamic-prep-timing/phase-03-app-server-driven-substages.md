# Phase 3: pte-app — server-driven sub-stage constants

**P1 coverage: 1/3** — completes the client side of the accurate-prep-timing story (P1 #1) by removing the last source of client/server drift (hardcoded sub-stage constants that could silently diverge from server config).

## Requirements
Each of the 5 Speaking audio-prompt screens reads its pre-listen and pre-record sub-stage lengths from the task response Phase 2 now provides, instead of a local hardcoded constant pair — eliminating any possibility of client/server drift on these values. Because the server only ever populates these fields for these 5 task types (Phase 2), the client models them as **nullable**, not required — every other ~20 task type's `TaskView` simply omits them and never reads them.

## Steps
1. Extend the client's task-response model with the two new server-provided sub-stage fields as **nullable (`int?`)** — matching that the server only populates them for the 5 audio-prompt task types (Phase 2); every other task type's response omits them, the same pattern already used for other optional `TaskView` fields like `promptText`/`audioPromptRef`. Do not parse them with a hard non-null cast the way `prepSeconds`/`responseSeconds` are parsed — that would break deserialization for every other task type's response.
2. Update each of the 5 Speaking screens to read their pre-listen/pre-record values from the task response instead of their local hardcoded constants, removing those constants once unused — each screen asserts non-null (or safely unwraps) at its own read site, since only these 5 screens ever read these fields at all and only they can rely on the server always populating them.
3. Confirm Respond to a Situation's screen-specific behavior (its persistent situation-text display, its doc-commented 20s merged sub-stage) is unaffected — only the *source* of the value changes, not its meaning or the screen's layout.
4. Confirm Retell Lecture's interpolated instruction text (which currently references its local pre-record constant directly) still reflects the correct value once sourced from the server.
5. Review and update the existing widget/screen tests for all 5 screens and the shared `AudioPromptRecordBody`/`AudioListeningPrepCard` widgets: since the actual values aren't changing, only their source, confirm each test still stubs/produces the same values via the task-response fixture rather than a hardcoded constant, updating any that assumed the old constant source directly.

## Success Criteria
- All 5 Speaking screens compile and run using server-supplied pre-listen/pre-record values, with no local hardcoded constant remaining for any of them.
- The client task-response model exposes `preListenSeconds`/`preRecordSeconds` as nullable fields; a fixture/test confirms every other (non-audio-prompt) task type's response still deserializes correctly with them absent — no app-wide regression.
- Every existing and updated widget/screen test for these 5 screens passes.
- `flutter analyze` reports no new issues.
- Manually or via test fixture, confirming each screen's displayed sub-stage timing values are identical to their previous hardcoded values when the server supplies the same numbers (Repeat Sentence 3/3, Retell Lecture 3/10, Answer Short Question 3/3, Summarize Group Discussion 5/10, Respond to a Situation 20/10) — no visible regression for a student using the app today.

## Risks
- Many existing widget tests currently assert against the old hardcoded constants directly — mechanical but broad; mitigated by reviewing each of the 5 screens' test files together in one pass rather than one at a time, to catch any shared fixture/helper that needs updating once instead of five times.
- Modeling these fields as required/non-nullable (matching `prepSeconds`/`responseSeconds`) was considered and explicitly rejected during plan review (HIGH finding): since Phase 2 only ever populates them for 5 of ~20 task types, a hard non-null cast would break deserialization for every other task type's `TaskView` the moment this phase ships — an app-wide regression, not a corner case. Resolved by keeping the fields nullable on the client and asserting non-null only at the 5 Speaking screens' own read sites, where it's always true by construction (a screen only exists for a type that always gets these fields).
