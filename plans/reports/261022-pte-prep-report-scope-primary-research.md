# PTEPrep report scope revision — primary research

**Date:** 22 October 2026  
**Research mode:** Read-only examination of registration, report baseline and selected source.  
**Decision supplied by the user:** Revise Reports 3–6 first; implement or revise practice code afterward. This research does not authorize application changes.

## 1. Recommended approach

Create a documentation-only scope revision plan with a shared requirements baseline before rewriting individual reports. Preserve the original DOCX top-level section order and existing Markdown section files. Expand their content and subordinate headings; do not reorganize the submission into a new report structure.

The key change is to distinguish **required product behavior** from **observed implementation maturity**. Report 3 must retain AI-assisted practice feedback as a requirement because the registration explicitly includes it. Missing code is an implementation gap, not a reason to remove the requirement. Report 4 may define the intended solution with its proposed status clearly stated. Report 5 must describe acceptance scenarios without claiming that they passed. Report 6 must distinguish steps executable in the reviewed build from the intended workflow pending implementation.

Use two separate fields in the shared catalogs: requirement disposition (`In scope`, `Out of scope`, `Decision pending`) and implementation evidence (`Source observed`, `Partial`, `Not evidenced`, `Runtime verified`). Add approval state separately when needed. A requirement can be in scope while its implementation is not evidenced and the registration is awaiting supervisor confirmation.

## 2. Evidence and authority

| Source | Role in the revision | Limit |
|---|---|---|
| Latest user instructions | Governs the order of work, exact title preservation, English documentation and detailed project content | Does not resolve every business policy |
| `template-doc/Generate/FA26SE182_Phieu-dang-ky_v1.2.docx` | Latest registration scope: eight human roles, practice web, educational AI feedback and exclusions | Record of changes says pending supervisor confirmation; do not label approved |
| `pte-doc/plans/reports/261022-pte-prep-current-scope-review.md` | Cross-repository evidence map and identified conflicts | Static inspection, not execution evidence |
| Existing report foundation and original DOCX headings | Stable section structure, IDs, evidence and traceability conventions | Legacy six-role and platform-author restrictions are superseded scope assumptions |
| Current source and deployment configuration | Evidence of existing contracts, constraints and gaps; starting point for compatible design | Existing code must not silently determine all future requirements |

Retain the exact project title: **PTEPrep: An AI-Powered PTE Practice Platform and Realistic Exam Simulator**. Retain the independent-product disclaimer and the separation of organization exam simulation from Student self-practice.

Direct source checks corroborate the review:

- `pte-api/app/src/main/java/com/pte/shared/security/SecurityRoles.java` defines Platform Admin, Platform Manager, Academic Manager, Academic Staff, Host Admin, Proctor, Examiner and Student; canonicalization maps legacy Platform Author to Academic Staff.
- `pte-api/app/src/main/java/com/pte/practice/internal/service/PracticeProgressService.java` reads recent sessions, maps completed responses to `COMPLETED_PENDING_SCORE`, and does not demonstrate completed score production.
- `pte-practice/features/studyPack/StudyPackView.tsx` provides entitlement-dependent opening behavior; it is insufficient evidence for a course-management system or personalized study-plan engine.
- The registration explicitly requires objective or AI-assisted feedback after submission, versioned content/rubric/provider/model/feedback status, and preservation of answers when feedback fails.

## 3. File impact and execution order

| Work package | Files | Concrete content |
|---|---|---|
| Governing baseline | New `pte-doc/projects/plans/quang-pte-prep-report-scope-update/` plan bundle | Explicitly supersede obsolete six-human-role and old channel restrictions for active reports; record user instruction that documentation leads future practice implementation; preserve the completed original plan and its quality/test receipts as history |
| Shared foundation | All seven files in `pte-doc/report/_foundation/` | Eight human actors plus external services; feature IDs for practice; separate requirement and implementation states; task catalogs by channel; stable ID migration; open decisions and source evidence |
| Report 3 | `00-project-report.md`, `00-record-of-changes.md`, `01-overall-description.md`, `02-user-requirements.md`, `03-functional-requirements.md`, `04-non-functional-requirements.md`, `05-requirement-appendix.md` | Three web channels and Windows; permissions; distinct practice and organization exam journeys; complete acceptance conditions, error recovery and AI feedback requirements |
| Report 4 | Existing two metadata files and `01-system-design.md`, `02-database-design.md`, `03-detailed-design.md` | Context and deployment including practice; identity vs membership; practice sessions/items/media; proposed feedback provenance and lifecycle; source-backed vs proposed entities and diagrams |
| Report 5 | Existing metadata and five numbered section files | Role allow/deny cases; practice lifecycle and entitlement; AI success/pending/failure/retry; content versioning; separate documentation validation from product test execution |
| Report 6 | Existing metadata and three numbered section files | New role guides, two Student journeys and authentication contexts; available practice procedures; planned feedback guide clearly marked; actual configuration prerequisites and recovery |
| Assets and validation | Existing `assets/README.md` per report, `_validation/` records | Update diagram manifest, captions, source/status notes, links and cross-report traceability |
| DOCX exports | Existing generator inputs and output locations, if included in parent plan | Export only after Markdown content approval; preserve original section structure, styles and school logo; do not treat stale DOCX as updated automatically |

Do not edit product code, schemas, role policies, application configuration, deployment, or production data during this documentation revision. A later practice implementation plan must consume the accepted requirement/design/test identifiers and the gap list.

Historical tooling also needs a successor validation strategy: `tests/test_phase01_foundation.py`, `test_phase02_report03.py`, `test_phase05_report06.py` and `validate_report_bundle.py` include legacy Platform Author or fixed task-count assumptions identified by the coordinator. The new plan should specify baseline-aware checks or successor checks, preserving the old receipts instead of making historical passes appear to validate the new scope. These are documentation-tooling changes, distinct from practice product implementation. Review the existing practice brainstorm/spec under `quang-pte-practice-student-web` before choosing rules that may already have a documented decision.

The coordinator has asked the user to resolve the Academic/Core target, multi-organization email identity and Study-Pack depth. Until answers arrive these remain open decisions; no research recommendation constitutes their approval.

## 4. Required practice detail

The SRS should specify each flow using actor, prerequisite, trigger, normal steps, alternate/error paths, postcondition, ownership, retained data and acceptance conditions:

1. Verified-email sign-in, expiry, invalid code, resend limits and signed-out recovery.
2. Organization association and entitlement resolution; no active membership, multiple applicable organizations, inactive organization, exceeded limits and unavailable entitlement service.
3. Home/catalog/Study-Pack navigation, runnable versus visible unavailable task types, valid content and accessibility.
4. Session creation, overview, begin, timer, frozen question content, answering, draft, confidence, submit/skip, save and exit, resume, completion, discard and expiry.
5. Media grant, recording upload, ownership binding, failed upload and safe answer retry.
6. Objective feedback and AI feedback after submission; pending, available, unavailable, failed and retry behavior; preserved answer independent of provider outcome.
7. Educational explanation grounded in question/rubric/answer; provenance/versioning; access control; clearly identified generated content; academic oversight boundaries.
8. Progress and history with truthful distinction between practice activity, self-reported confidence and scored performance; loss of entitlement must not silently redefine retention or ownership.
9. Feedback/content-reporting scope only after defining who may submit, target content, handling role, response visibility and closure; existing Host support tickets are not proof of Student content feedback.

Do not introduce an open chatbot, AI-generated personalized learning plan, model training, Student self-payment, an LMS, official PTE results or universal cross-organization history sharing.

## 5. Decisions to retain explicitly

| Decision | Required treatment before final baseline |
|---|---|
| Global email identity vs cross-organization-management exclusion | Define identity linking separately from organization membership management and data sharing. Preserve isolation; do not silently legalize or delete source behavior. |
| PTE Core practice vs existing Academic-style exam task catalog | Maintain separate channel/task-support matrix; confirm intended task sets before presenting all tasks as available. |
| Entitlement source and revocation behavior | Document current organization-linked gate; resolve exact pause/resume/read-history behavior and future scope without assuming personal subscriptions. |
| AI response shape and responsibility | Define eligible task types, feedback content, provenance, review/escalation, retry and user-visible failure states. Provider names do not establish quality guarantees. |
| Study-Pack meaning | Define curated groups versus independent lessons/courses; do not infer full pack progress from UI cards. |
| Content feedback/reporting | Resolve actors, targets and response workflow separately from operational support tickets. |
| Retention | Keep organization contract as policy source; unresolved durations/export/deletion/AI-provider retention get explicit owners and closure conditions. |
| NFR numbers | Existing report targets are not measured performance. Registration v1.2 uses qualitative wording. Keep justified targets only with workload, method, environment and ownership; otherwise record pending measurement/decision. |
| Registration approval | Draft review can proceed; supervisor confirmation remains visible and must not be fabricated. |

Unresolved decisions need stable IDs, options, recommendation, affected requirements/designs/tests/guides, decision owner and a closure gate. Write independent sections while these remain open; block only the specific claims that depend on a final choice.

## 6. Acceptance criteria for the revision

- Original top-level section order, file boundaries and project title are preserved; no generic template paragraphs replace project content.
- Eight human roles and external services use identical names throughout catalogs, diagrams, workflows, test responsibilities and user guides. Legacy Platform Author is a migration note only.
- Every new practice requirement has explicit acceptance conditions and links to design, planned tests and relevant guide or an explained pending guide.
- Existing IDs remain stable where their meaning remains stable; changed meanings have migration/deprecation entries and no dangling references.
- The Student practice journey remains separate from Host-created organization exams in entities, state diagrams, scoring and publication rules.
- Required AI explanations remain in scope with clear implementation gaps; no statement implies complete integration, validated scoring quality or official result equivalence without evidence.
- No fabricated executed test statuses, screenshots, live deployment assertions, supervisor approvals or operational guarantees appear.
- New/updated diagrams identify requirement coverage, ownership, state transitions, cardinality where relevant and whether they depict existing or proposed behavior.
- All cross-links and assets resolve; shared role and scope statements agree across Reports 3–6; recorded changes describe actual edits and do not assert approval.
- A handoff identifies requirements still absent/partial in code, decision dependencies and verification scenarios for the later practice implementation plan.

## 7. Review boundary

Research performed through UTF-8 file reads, heading inventory, DOCX XML extraction and selected source inspection. No application tests, runtime checks or implementation changes were made. The original DOCX and Report 3–6 remain unchanged by this research artifact.
