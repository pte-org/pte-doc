# PTEPrep Report 3–6 scope revision — Alternative research

Date: 22 October 2026  
Role: ck:plan Hard researcher, Alternative  
Boundary: Planning and local document/source-tool inspection. No report body, application source, or generated DOCX changes. No application or documentation test execution.

## Recommendation

Revise the existing canonical Markdown reports in place under `pte-doc/report/report03` through `report06`, with a new scope-revision plan and dated change records. Keep the old completed plan and its test/quality receipts as historical evidence. Separate the intended product requirements from implementation coverage so that practice code can be changed after the reports, as the user requested.

The minimum safe outcome is one coherent revised report bundle and a practice implementation gap handoff. It includes the shared foundation, diagrams, traceability, validation policy, and generated DOCX review. It does not include implementation of practice features.

## Evidence inspected

- [Current scope review](261022-pte-prep-current-scope-review.md): registration v1.2 scope, source observations, eight roles, practice coverage, and unresolved scope conflicts. Its finding that v1.2 is pending supervisor confirmation must remain visible.
- [Previous completed plan](../../projects/plans/quang-pte-prep-report-documents/plan.md): canonical section/file map, prior six-role model, 23-task catalog rule, and completed documentation validation receipts.
- [Identifier ledger](../../report/_foundation/id-ledger.md): stable IDs, supersession rule, and fixed 23-row assumption.
- [Bundle validator](../../projects/plans/quang-pte-prep-report-documents/tests/validate_report_bundle.py) and sibling phase validators: existing structural checks and obsolete role/task assumptions.
- [DOCX generator](../../tools/generate_report_docx.py) and [DOCX README](../../report/docx/README.md): template-shell reuse, Mermaid rendering, fixed cover metadata, output paths, and fallback behavior.

This research relies on the current scope review for business/source findings; it does not independently certify every implementation finding in that review.

## Alternatives and tradeoffs

| Approach | Advantages | Problems | Verdict |
|---|---|---|---|
| Revise canonical Markdown in place and increment document baseline | Keeps IDE paths and cross-links stable; one authoritative bundle; existing DOCX workflow stays usable. | Requires deliberate status migration, change records, and preservation of historical receipts. | Recommended. |
| Create a parallel `report-v2` tree | Makes old/new comparison easy. | Duplicates IDs, evidence, diagrams, links, and generator configuration; two apparently current reports invite submission mistakes. | Use only if explicitly required by submission policy. |
| Replace all reports with a clean rewrite | Allows a fresh narrative. | Loses detailed requirements and useful tests; increases accidental omission and identifier churn. | Too broad for this change. |
| Only rename roles and add a practice chapter | Small initial edit. | Leaves permission matrices, ERD, test scope, guides, and DOCX stale; misses semantic differences in self-practice and organized exams. | Insufficient. |

In-place revision does not require deleting the old DOCX originals or changing supplied templates. Existing DOCX exports become stale as soon as their Markdown baseline changes; mark their status clearly until regeneration and inspection are complete.

## Intended behavior and existing code need separate treatment

The previous evidence hierarchy puts source before approved requirements. That is appropriate for an implementation claim, but it cannot decide intended business scope. The user's explicit sequence is reports first, practice implementation afterward.

Use two independent dimensions for material capabilities:

1. **Requirement decision:** Included in proposed baseline, awaiting decision/approval, deferred, or excluded.
2. **Implementation evidence:** Present in inspected source, partial, missing/not evidenced, or runtime verified with a dated receipt.

Retain a requirement for AI explanations even though practice currently has no demonstrated complete explanation pipeline. Mark the design as proposed and the test as not executed. Do not remove the requirement to match unfinished code or describe the intended capability as operational.

Preserve the exact registered title: **PTEPrep: An AI-Powered PTE Practice Platform and Realistic Exam Simulator**. Product shorthand must not accidentally replace the full registered title on the cover. No new approval date, supervisor approval, execution result, numeric service guarantee, or retention duration may be inferred.

## Minimum safe phase boundaries

1. **Freeze the change basis:** section map from original DOCX, registered title, source observation date, existing ID inventory, and decision register. Resolve or explicitly gate the three choices below. Record additional pending feedback-target scope separately.
2. **Update shared foundation:** eight human roles plus External Integration Services; role-permission-resource matrix; channel map; intended-versus-present evidence model; catalog segmentation and ID migration map.
3. **Revise Report 3:** plain business language; self-practice login/access, catalog availability, session/answer/recording lifecycle, feedback and progress; both positive and rejection flows; existing organization/exam/scoring obligations remain covered. Trace each material feature to requirements and acceptance conditions.
4. **Revise Report 4:** derive design from the revised requirements; distinguish implemented and proposed components; document practice identity versus organization membership, entitlement checks, content snapshots, audio ownership, proposed AI feedback storage/status, and exam/practice data boundaries. Refresh context, deployment, ERD, sequence, state, and permission diagrams where affected.
5. **Revise Reports 5–6:** test objectives and cases include authorization, tenancy, entitlement revocation, repeat commands, concurrency, media ownership, deadline, AI pending/failure, and history access. User guides separate source-supported steps from future capabilities and never instruct a nonexistent AI action as available.
6. **Validate and publish the document package:** update stale validation policy, run/document structural and semantic checks when authorized during execution, review the vertical flows, regenerate DOCX, inspect template/figures/tables/metadata, and create a gap handoff for later practice planning.

The later practice implementation plan should consume requirement IDs, acceptance criteria, and identified gaps. No application implementation phase belongs inside this report-revision plan.

## Three decisions that must not be silently chosen

| Decision | Evidence conflict | Safe planning handling |
|---|---|---|
| PTE Core versus PTE Academic | Practice source is labeled PTE Core Practice; older reports impose 23 task rows and Academic-style material. | Ask which task families and exam variants apply to each channel. Preserve the registered title. Block final task catalog, task-specific scoring/timing, and related test baselines until answered; continue unaffected role/channel work. |
| Cross-organization identity | Registration excludes cross-organization identity/membership management; source links a verified email to multiple organization memberships. | Ask whether a shared login identity with isolated memberships and explicit organization selection is allowed, or all identity linkage is excluded. Never treat email verification as automatic membership or access. Design tenant-boundary tests for the chosen policy. |
| Study-Pack | Source presents grouped cards that currently return to the catalog; personalized plan generation is excluded. | Ask whether Study-Pack is a navigation/grouping view or includes curated packs, ordered items, and saved completion. Do not add LMS administration or AI personalization implicitly. Mark source limitations separately from any approved intended pack behavior. |

Additional open item: Host support tickets do not by themselves satisfy Student reports linked to questions, attempts, or lessons. Identify sender, target, recipient, response visibility, and scope before claiming that feedback requirement is covered.

## Identifier, matrix, and diagram migration rules

- Keep an existing requirement ID when its meaning remains the same. Add IDs for new practice/role behavior. If meaning changes, record superseded-to-new mapping rather than repurposing an old ID.
- Academic Staff is the canonical successor to Platform Author for authoring. This is not a global text replacement: approval/publication responsibilities need an explicit mapping to Academic Manager and permitted Admin behavior. Platform Manager does not inherit all Admin permissions.
- Distinguish definitions from references when validating IDs; repeated references are expected, duplicate definitions and dangling references are defects.
- Update feature-to-role, requirement-to-design, requirement-to-test, and workflow-to-requirement coverage. Test cases should reference separate access/ownership rejection requirements where material.
- Distinguish Student self-practice sessions from Host-created exam modes called practice. Class membership and exam enrollment remain separate facts.
- Diagrams must show intended versus implemented boundaries and follow report IDs/captions. Existing SVG/PNG assets and inline Mermaid can become stale independently. Audit every consuming link, not only the changed Mermaid source.
- ERD needs relationship cardinalities and ownership constraints. Do not turn the domain model into a flowchart to obtain straight arrows. Rendering style must not change relation semantics.
- A test plan, test case, or source path does not prove execution. Existing GREEN/APPROVED receipts belong to their old baseline and cannot certify the revision.

## Validation scripts need deliberate revision

The existing bundle validator and foundation/SRS/guide phase validators require **Platform Author** and, in several files, **exactly 23 tasks**. Reusing a previous GREEN result is unsafe. Updating these assumptions is part of the execution plan, after scope decisions; editing scripts would be a code change and would first require the applicable coding standard reading gate.

Keep useful file/encoding/link checks. Replace obsolete scope assertions with a shared approved revision manifest containing canonical roles, channel scope, catalog variants, and permitted legacy contexts. Do not pass validation simply by mentioning old/new role names somewhere in combined text. A manual semantic review must verify actor responsibility and negative permissions, because substring checks cannot do so.

No TDD flag should be inherited just because the old plan used it. The current request asks for planning; test and quality execution choices must be recorded explicitly for the new work package. Documentation validation is separate from application tests.

## DOCX-specific stale-output risks

The generator preserves template shell/logo and major section counts, but it currently hardcodes **Version 1.0 · 06 October 2026**, product shorthand, an organization-based summary, and fixed baseline metadata. Regeneration alone would therefore produce a misleading new cover. Plan a metadata update or a validated metadata input before exporting the revised baseline.

Mermaid rendering uses an unpinned `npx --yes @mermaid-js/mermaid-cli` invocation. Rendering failure returns `None`, and the document falls back to a **Diagram source** block. A successful generator process therefore does not prove submission-ready diagrams. A revised publication gate must identify every required figure and fail or explicitly withhold submission status if it is absent/unreadable.

Check all four DOCX exports against the same Markdown baseline: exact registered title, version/date/approval status, TOC hierarchy, school logo, preserved source-template style, updated role tables, all figures, readable long tables, captions, and no generic sample body. Updating Word fields/page numbers and visual layout inspection remain distinct from merely parsing the DOCX package.

Write review/verification reports to `pte-doc/plans/reports/`; retain screenshots or machine-readable publication evidence under the matching `assets/<report-name>/` directory. Do not create new review outputs in the historical `report/_validation/` path merely because the old plan used it.

## Acceptance boundary for the new plan

The plan is ready for report execution when it specifies canonical paths, revision metadata, the eight-role permission map, decision gates, stable ID migration, requirement/evidence separation, full Report 3–6 propagation, documentation validation updates, and DOCX publication checks. It should explicitly wait for answers to the highest-risk scope choices before finalizing dependent requirements. It must not present pending v1.2 supervisor confirmation as approval.

The complete report work package is accepted only when all four reports agree, the revised DOCX artifacts are inspected, and remaining implementation gaps have requirement IDs and acceptance conditions for subsequent practice work. No application runtime readiness claim follows from report completion.
