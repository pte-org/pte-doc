# Specification: cập nhật phạm vi Report 3–6 của PTEPrep

Date: 22 October 2026
Status: Draft; D01–D03 awaiting user answers; registration v1.2 pending supervisor confirmation.
Execution boundary: Reports first; practice application implementation belongs to a later work package.
Registered title: **PTEPrep: An AI-Powered PTE Practice Platform and Realistic Exam Simulator**.

## Authority and scope

Latest user instructions govern requested scope. Registration `template-doc/Generate/FA26SE182_Phieu-dang-ky_v1.2.docx` provides the latest written proposal; its pending supervisor confirmation remains visible. Editing document drafts is authorized independently of supervisor approval. Source proves observed contracts and limitations; it does not cap desired requirements.

Revise canonical English reports in `pte-doc/report/report03/` through `report06/`, foundation, affected figures and final DOCX package. Preserve original DOCX major TOC and existing section filenames. No application code, migrations, deployment or production changes.

## Stories and measurable acceptance

| Story | Priority | Need | Acceptance |
|---|---|---|---|
| US-01 | P1 | Leader needs consistent revised project scope | Exact registered title, eight roles, external actor, four channels and two Student journeys agree across all reports. |
| US-02 | P1 | Academic roles need explicit authority | Role-resource-action matrix distinguishes drafting/submission/review/publication/activation; negative permissions documented; legacy Author mappings retain traceability. |
| US-03 | P1 | Student needs practice requirements before implementation | Authentication, organization context, entitlement, task availability, answer/media/session lifecycle, AI explanation and progress each have acceptance and failure paths. |
| US-04 | P1 | Reviewer needs truthful design/testing maturity | Independent requirement decision, implementation evidence and approval fields; proposed design and not-executed cases never presented as current/passed. |
| US-05 | P1 | Leader needs submission documents | Four DOCX preserve template shell/logo/TOC, full title and revised metadata; required figures rendered and visually inspected with evidence. |
| US-06 | P1 | Team needs stable cross-report traceability | Every changed requirement links design, test and guide applicability; changed meaning receives supersession mapping; no dangling references or duplicate definitions. |
| US-07 | P1 | Practice developer needs later implementation handoff | Each missing/partial capability has requirement/design/test IDs, dependency, ownership and acceptance condition. No implementation is included here. |
| US-08 | P1 | Maintainer needs repeatable document publication | Successor validation manifest and generator metadata remove stale role/task/cover assumptions; exact invocation and boundary documented. |
| US-09 | P2 | Reviewer needs efficient comparison | Consolidated human-readable changed-scope summary groups retained, modified and added workflows without changing mandatory traceability. |
| US-10 | P3 | Maintainer may automate noncritical repetition | Optional convenience wrappers reduce repeated document commands after mandatory validation and publication already work. |

P1 outputs are mandatory. P2 summary is useful but may remain concise; P3 convenience automation is optional and outside the minimum scope. Mandatory successor validation, metadata corrections and publication checks remain P1.

## Decision register

| ID | Question and options | Recommendation only | Dependent finalization blocked |
|---|---|---|---|
| D01 | Shared Academic-oriented task families for web/Windows, or separately scoped Core and Academic catalogs? This concerns task families, not a specific question set. | Shared Academic-oriented scope; no separate Core expansion. Not accepted. | Catalog membership, per-channel task support, scoring/timing, task-specific tests and guide screenshots. |
| D02 | One verified email linked to isolated organization memberships with explicit context, or no cross-organization identity linking? | Shared identity, explicit org context and per-org ownership. Not accepted. | Identity/membership wording, context-selection design, ownership tests, access guide. Alternative requires source-gap flag and supervisor clarification of v1.2 exclusion. |
| D03 | Study-Pack quick grouped practice, or curated ordered packs with persisted pack completion? | Quick groups only; no LMS or per-pack progress. Not accepted. | Pack requirements, entities/progress model, pack test cases and operational guide. Expanded option requires extra catalog/admin and progress scope decisions. |
| D04 | Question eligibility is controlled separately for Practice Web and Windows Exam Client; the system selects questions using the corresponding flag. | Confirmed by user on 22 October 2026. Proposed business labels: Available for practice / Available for exam simulation. Technical field names remain design choices. | Propagate channel eligibility through authoring/review, pool selection, generation, design, tests and guides. No application change in this package. |

D01–D03 do not block independent role/channel, existing exam, general AI or structure drafting. Final affected claims and publication cannot be accepted until answered; recommendations must not silently become decisions.

Additional closure items go to the foundation TBD register: AI eligible tasks/output rubric/academic oversight, feedback reporting actors and targets, entitlement revocation/resume/history, and contractual retention/AI-provider data handling. Draft explicit bounded requirements; do not invent unresolved thresholds or permissions.

## Confirmed question selection by usage channel — D04

The question bank records two separate usage flags: eligibility for Student self-practice in `pte-practice`, and eligibility for organized exam delivery in `pte-app`. The system selects from the corresponding eligible pool. These flags classify question content; D01 separately concerns task families and Academic/Core structure. D04 does not settle D01, D02 or D03.

Required target behavior for report elaboration:

- Practice creation selects only questions enabled for practice; organized exam generation selects only questions enabled for exam simulation.
- Channel eligibility is an additional filter alongside publication/approval, supported task type, media/content readiness and the selected composition rules. A flag does not grant Student entitlement or bypass organization/ownership checks.
- If the eligible pool is insufficient, return an explicit content-readiness/generation issue. Do not silently draw from the other channel's excluded pool.
- Preserve selected content and its provenance for an existing session/exam. Later flag changes affect subsequent selection, not the content already fixed for an active attempt.
- Report 3 defines these business rules, Report 4 models the two flags and selection boundaries, Report 5 covers permitted/excluded pools, and Report 6 explains usage classification to authorized academic staff.

Recommended combination semantics, to be recorded as a design proposal rather than an additional user decision: practice-only, exam-only, both, or neither. Both-enabled reuse and the editor/reviewer policy for changing flags must be stated explicitly when elaborating the reports. No per-channel default value or historical-question migration is assumed here.

Acceptance: a practice-only question is excluded from exam generation; an exam-only question is excluded from practice; insufficient eligible content never triggers cross-channel fallback; the reports distinguish shared task definitions from question-level usage flags. Implementation status must be verified separately from this confirmed requirement.

## Shared status model

Each capability has three independent fields:
- Requirement decision: In scope / Out of scope / Decision pending / Deferred.
- Implementation evidence: Source observed / Partial / Not evidenced / Runtime verified, with source/date/limit.
- Approval: User instruction or decision reference / Draft / Pending supervisor confirmation / Approved with genuine receipt.

AI explanations are in the intended scope despite incomplete implementation. A source-observed route does not prove availability, successful end-to-end execution or scoring quality.

## Exclusions

No title change, official Pearson/PTE affiliation or official score equivalence; no research/model training, open chatbot, personalized AI study planner, LMS, Student self-payment or universal sharing across organizations. Organization registration remains separate from package purchase/activation. Existing exam generation, integrity, Examiner assignment and Host publication remain covered.

